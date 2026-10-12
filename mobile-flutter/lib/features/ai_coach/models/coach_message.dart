class CoachMessage {
  final String id;
  final String role; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;

  CoachMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => role == 'user';
}
