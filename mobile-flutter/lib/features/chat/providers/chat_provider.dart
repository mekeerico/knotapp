import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_message.dart';

class ChatState {
  final Map<String, List<ChatMessage>> messagesByMatch;
  final bool isConnected;
  final String? activeMatchId;
  final String? errorMessage;
  final bool hasReachedMessageLimit;
  final bool showUpgradeFlier;

  const ChatState({
    this.messagesByMatch = const {},
    this.isConnected = false,
    this.activeMatchId,
    this.errorMessage,
    this.hasReachedMessageLimit = false,
    this.showUpgradeFlier = false,
  });

  List<ChatMessage> get activeMessages =>
      activeMatchId != null ? (messagesByMatch[activeMatchId] ?? []) : [];

  ChatState copyWith({
    Map<String, List<ChatMessage>>? messagesByMatch,
    bool? isConnected,
    String? activeMatchId,
    String? errorMessage,
    bool clearError = false,
    bool? hasReachedMessageLimit,
    bool? showUpgradeFlier,
  }) {
    return ChatState(
      messagesByMatch: messagesByMatch ?? this.messagesByMatch,
      isConnected: isConnected ?? this.isConnected,
      activeMatchId: activeMatchId ?? this.activeMatchId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasReachedMessageLimit: hasReachedMessageLimit ?? this.hasReachedMessageLimit,
      showUpgradeFlier: showUpgradeFlier ?? this.showUpgradeFlier,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Dio _dio;
  final Ref _ref;
  IO.Socket? _socket;
  String _socketUserId = '';
  Timer? _pollTimer;

  ChatNotifier(this._dio, this._ref) : super(const ChatState());

  String get _currentUserId => _ref.read(authProvider).user?.id ?? '';

  /// Connect (or reconnect) the realtime socket once we know who the user is.
  Future<void> _ensureSocket() async {
    final userId = _currentUserId;
    if (userId.isEmpty) return;
    if (_socket != null && _socketUserId == userId) return;

    _socket?.dispose();
    _socketUserId = userId;

    final token = await _ref.read(secureStorageProvider).getToken();
    try {
      _socket = IO.io(
        ApiEndpoints.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'userId': userId})
            .setAuth({'token': token ?? '', 'userId': userId})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.onConnect((_) => state = state.copyWith(isConnected: true));
      _socket?.onDisconnect((_) => state = state.copyWith(isConnected: false));
      _socket?.on('receiveMessage', _handleIncoming);
      _socket?.on('messageReceived', _handleIncoming);
      _socket?.connect();
    } catch (_) {
      // Polling below keeps chat working even if the socket can't connect.
    }
  }

  void _handleIncoming(dynamic data) {
    if (data is! Map) return;
    final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data), _currentUserId);
    final partnerId = msg.senderId == _currentUserId ? msg.receiverId : msg.senderId;
    if (partnerId.isEmpty) return;
    _mergeMessages(partnerId, [msg]);
  }

  /// Merge messages by id, keeping chronological order and dropping optimistic duplicates.
  void _mergeMessages(String partnerId, List<ChatMessage> incoming) {
    final existing = [...(state.messagesByMatch[partnerId] ?? <ChatMessage>[])];
    for (final msg in incoming) {
      if (msg.id.isNotEmpty && existing.any((m) => m.id == msg.id)) continue;
      // Replace a pending local copy with the same text from the server
      final pendingIdx = existing.indexWhere((m) =>
          m.id.startsWith('local-') && m.text == msg.text && m.senderId == msg.senderId);
      if (pendingIdx >= 0) {
        existing[pendingIdx] = msg;
      } else {
        existing.add(msg);
      }
    }
    existing.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    state = state.copyWith(
      messagesByMatch: {...state.messagesByMatch, partnerId: existing},
    );
  }

  void setActiveMatch(String partnerId) {
    state = state.copyWith(activeMatchId: partnerId, clearError: true);
    _ensureSocket();
    loadMessageHistory(partnerId);

    // Fallback refresh so messages arrive even if the websocket is blocked
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final active = state.activeMatchId;
      if (active != null) loadMessageHistory(active);
    });
  }

  void leaveChat() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> loadMessageHistory(String partnerId) async {
    try {
      final res = await _dio.get('${ApiEndpoints.messages}/$partnerId');
      if (res.data is List) {
        final history = (res.data as List)
            .whereType<Map>()
            .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item), _currentUserId))
            .toList();
        _mergeMessages(partnerId, history);
      }
    } catch (_) {
      // Keep whatever is already on screen; next poll will retry.
    }
  }

  Future<void> sendMessage(String text) async {
    final partnerId = state.activeMatchId;
    final content = text.trim();
    if (partnerId == null || content.isEmpty) return;

    final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: localId,
      text: content,
      senderId: _currentUserId,
      receiverId: partnerId,
      timestamp: DateTime.now(),
    );
    _mergeMessages(partnerId, [optimistic]);

    // Single source of truth: persist through REST (one row per message).
    try {
      final res = await _dio.post(
        '${ApiEndpoints.messages}/$partnerId',
        data: {'content': content},
      );
      final data = res.data;
      if (data is Map && data['id'] != null) {
        _mergeMessages(partnerId, [ChatMessage.fromJson(Map<String, dynamic>.from(data), _currentUserId)]);
        state = state.copyWith(clearError: true);
        // Trigger fast follow-up fetches so the matched candidate's reply appears immediately
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) loadMessageHistory(partnerId);
        });
        Future.delayed(const Duration(milliseconds: 3600), () {
          if (mounted) loadMessageHistory(partnerId);
        });
      } else {
        throw Exception('Message was not saved');
      }
    } on DioException catch (e) {
      _removeLocal(partnerId, localId);
      final body = e.response?.data;
      final code = body is Map ? (body['error'] ?? body['message']) : null;
      final isLimit = code == 'FREE_TIER_LIMIT' || (body is Map && body['message']?.toString().contains('FREE_TIER_LIMIT') == true);
      state = state.copyWith(
        hasReachedMessageLimit: isLimit ? true : state.hasReachedMessageLimit,
        showUpgradeFlier: isLimit ? true : state.showUpgradeFlier,
        errorMessage: isLimit
            ? 'Free tier messaging limit reached. Upgrade to continue conversations.'
            : 'Message not sent. Check your connection and try again.',
      );
    } catch (_) {
      _removeLocal(partnerId, localId);
      state = state.copyWith(errorMessage: 'Message not sent. Please try again.');
    }
  }

  void dismissUpgradeFlier() {
    state = state.copyWith(showUpgradeFlier: false);
  }

  void triggerUpgradeFlier() {
    state = state.copyWith(showUpgradeFlier: true);
  }

  void _removeLocal(String partnerId, String localId) {
    final list = [...(state.messagesByMatch[partnerId] ?? <ChatMessage>[])]
      ..removeWhere((m) => m.id == localId);
    state = state.copyWith(messagesByMatch: {...state.messagesByMatch, partnerId: list});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatNotifier(dio, ref);
});
