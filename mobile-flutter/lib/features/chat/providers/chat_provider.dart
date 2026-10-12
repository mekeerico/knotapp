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

    try {
      _socket = IO.io(
        ApiEndpoints.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        state = state.copyWith(isConnected: true);
      });

      _socket?.onDisconnect((_) {
        state = state.copyWith(isConnected: false);
      });

      _socket?.on('receiveMessage', (data) {
        if (data is Map<String, dynamic>) {
          final currentUserId = _ref.read(authProvider).user?.id ?? '';
          final newMsg = ChatMessage.fromJson(data, currentUserId);
          final matchId = newMsg.senderId == currentUserId
              ? newMsg.receiverId
              : newMsg.senderId;

          final currentList = state.messagesByMatch[matchId] ?? [];
          final updated = {...state.messagesByMatch, matchId: [...currentList, newMsg]};
          state = state.copyWith(messagesByMatch: updated);
        }
      });
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

    // Emit over WebSocket
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sendMessage', {
        'receiverId': matchId,
        'content': text.trim(),
      });
    }

    // Also persist via REST endpoint
    try {
      await _dio.post(
        ApiEndpoints.messages,
        data: {
          'receiverId': matchId,
          'content': text.trim(),
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
