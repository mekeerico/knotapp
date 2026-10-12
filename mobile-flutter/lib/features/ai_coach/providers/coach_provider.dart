import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/coach_message.dart';

class CoachState {
  final List<CoachMessage> messages;
  final bool isTyping;

  const CoachState({
    this.messages = const [],
    this.isTyping = false,
  });

  CoachState copyWith({
    List<CoachMessage>? messages,
    bool? isTyping,
  }) {
    return CoachState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class CoachNotifier extends StateNotifier<CoachState> {
  final Dio _dio;
  final Ref _ref;

  CoachNotifier(this._dio, this._ref)
      : super(
          CoachState(
            messages: [
              CoachMessage(
                id: 'welcome',
                role: 'ai',
                text:
                    'Greetings. I am your KNOT Relationship & Marital Intelligence Coach. How can I assist your courtship and emotional alignment today?',
                timestamp: DateTime.now(),
              ),
            ],
          ),
        );

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = CoachMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    try {
      final user = _ref.read(authProvider).user;
      final history = state.messages
          .map((m) => {'role': m.role, 'text': m.text})
          .toList();

      final response = await _dio.post(
        ApiEndpoints.aiCoach,
        data: {
          'conversation_history': history,
          'user_profile': user?.toJson() ?? {},
          'current_message': text,
        },
      );

      final reply = response.data['response'] ??
          'Focus on clear, emotionally safe boundaries and transparent mutual vision.';

      final aiMsg = CoachMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'ai',
        text: reply,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isTyping: false,
      );
    } catch (_) {
      // Intelligent behavioral guidance fallback
      await Future.delayed(const Duration(milliseconds: 1000));
      final fallbackReply = _getEmpatheticFallback(text);
      final aiMsg = CoachMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'ai',
        text: fallbackReply,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isTyping: false,
      );
    }
  }

  String _getEmpatheticFallback(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('timeline') || lower.contains('marriage')) {
      return 'When discussing marriage timelines, lead with vulnerability rather than pressure: "My intention is building a permanent family within the next 18 months—what does your ideal path toward commitment look like?"';
    } else if (lower.contains('attachment') || lower.contains('anxious')) {
      return 'A secure attachment is cultivated by expressing needs directly rather than testing your partner. State your emotions with calm clarity: "I value staying connected when plans change."';
    } else if (lower.contains('first date') || lower.contains('meet')) {
      return 'For a first meeting, choose a quiet, low-pressure venue that encourages deep conversation over sensory distraction—a refined tea lounge or botanical garden walk.';
    }
    return 'Marital longevity is anchored in mutual emotional safety, shared life goals, and unwavering integrity. What specific boundary or goal would you like to clarify?';
  }
}

final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>((ref) {
  final dio = ref.watch(dioProvider);
  return CoachNotifier(dio, ref);
});
