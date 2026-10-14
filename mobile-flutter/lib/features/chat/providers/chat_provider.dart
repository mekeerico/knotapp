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

  const ChatState({
    this.messagesByMatch = const {},
    this.isConnected = false,
    this.activeMatchId,
  });

  List<ChatMessage> get activeMessages =>
      activeMatchId != null ? (messagesByMatch[activeMatchId] ?? []) : [];

  ChatState copyWith({
    Map<String, List<ChatMessage>>? messagesByMatch,
    bool? isConnected,
    String? activeMatchId,
  }) {
    return ChatState(
      messagesByMatch: messagesByMatch ?? this.messagesByMatch,
      isConnected: isConnected ?? this.isConnected,
      activeMatchId: activeMatchId ?? this.activeMatchId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Dio _dio;
  final Ref _ref;
  IO.Socket? _socket;

  ChatNotifier(this._dio, this._ref) : super(const ChatState()) {
    _initSocket();
  }

  void _initSocket() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.getToken();
    final currentUserId = _ref.read(authProvider).user?.id ?? '';

    try {
      _socket = IO.io(
        ApiEndpoints.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'userId': currentUserId})
            .setAuth({'token': token ?? '', 'userId': currentUserId})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        state = state.copyWith(isConnected: true);
      });

      _socket?.onDisconnect((_) {
        state = state.copyWith(isConnected: false);
      });

      void handleIncoming(dynamic data) {
        if (data is Map<String, dynamic>) {
          final userId = _ref.read(authProvider).user?.id ?? '';
          final newMsg = ChatMessage.fromJson(data, userId);
          final matchId = newMsg.senderId == userId
              ? newMsg.receiverId
              : newMsg.senderId;

          if (matchId.isNotEmpty) {
            final currentList = state.messagesByMatch[matchId] ?? [];
            if (!currentList.any((m) => m.id == newMsg.id && newMsg.id.isNotEmpty)) {
              final updated = {...state.messagesByMatch, matchId: [...currentList, newMsg]};
              state = state.copyWith(messagesByMatch: updated);
            }
          }
        }
      }

      _socket?.on('receiveMessage', handleIncoming);
      _socket?.on('messageReceived', handleIncoming);
    } catch (_) {
      // Offline fallback handling
    }
  }

  void setActiveMatch(String matchId) {
    state = state.copyWith(activeMatchId: matchId);
    if (!state.messagesByMatch.containsKey(matchId)) {
      // Seed initial romantic greeting for courtship
      final seed = [
        ChatMessage(
          id: 'seed-1',
          text: 'Peace and greetings. I was deeply inspired by your commitment vows and family values.',
          senderId: matchId,
          receiverId: _ref.read(authProvider).user?.id ?? 'me',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];
      state = state.copyWith(
        messagesByMatch: {...state.messagesByMatch, matchId: seed},
      );
    }
    // Load remote chat history asynchronously
    loadMessageHistory(matchId);
  }

  Future<void> loadMessageHistory(String matchId) async {
    try {
      final res = await _dio.get('${ApiEndpoints.messages}/$matchId');
      if (res.data is List) {
        final currentUserId = _ref.read(authProvider).user?.id ?? 'me';
        final history = (res.data as List)
            .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>, currentUserId))
            .toList();
        if (history.isNotEmpty) {
          state = state.copyWith(
            messagesByMatch: {...state.messagesByMatch, matchId: history},
          );
        }
      }
    } catch (_) {}
  }

  Future<void> sendMessage(String text) async {
    final matchId = state.activeMatchId;
    if (matchId == null || text.trim().isEmpty) return;

    final currentUserId = _ref.read(authProvider).user?.id ?? 'me';
    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      senderId: currentUserId,
      receiverId: matchId,
      timestamp: DateTime.now(),
    );

    final currentList = state.messagesByMatch[matchId] ?? [];
    final updated = {
      ...state.messagesByMatch,
      matchId: [...currentList, newMsg],
    };
    state = state.copyWith(messagesByMatch: updated);

    // Emit over WebSocket with senderId
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sendMessage', {
        'senderId': currentUserId,
        'receiverId': matchId,
        'content': text.trim(),
        'text': text.trim(),
      });
    }

    // Also persist via REST endpoint
    try {
      await _dio.post(
        '${ApiEndpoints.messages}/$matchId',
        data: {
          'receiverId': matchId,
          'content': text.trim(),
          'text': text.trim(),
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatNotifier(dio, ref);
});
