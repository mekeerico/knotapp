import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;
  static const _storageKey = 'knot_stored_notifications';

  NotificationsNotifier(this._ref) : super(const NotificationsState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    state = state.copyWith(isLoading: true);
    try {
      final storage = _ref.read(secureStorageProvider);
      final raw = await storage.storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        final list = decoded
            .map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        state = state.copyWith(notifications: list, isLoading: false);
        return;
      }
    } catch (_) {}

    // Initial default notifications if brand new
    final initial = [
      AppNotification(
        id: 'notif_welcome',
        title: 'Welcome to Sovereign Matrimony',
        body: 'Your profile has been registered in the Knot global marriage registry. Review curated candidates matching your core values.',
        category: NotificationCategory.system,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        actionRoute: '/discovery',
        actionLabel: 'View Matches',
      ),
      AppNotification(
        id: 'notif_kyc',
        title: 'Verify Your Identity for Gold Seal',
        body: 'Didit 3D Liveness and Government ID verification increases candidate response rates by 4.2x.',
        category: NotificationCategory.verification,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        actionRoute: '/verification',
        actionLabel: 'Verify ID',
      ),
      AppNotification(
        id: 'notif_membership',
        title: 'Daily Curated Registry Ready',
        body: '3 AI-curated marriage candidates are available in your deck today. Upgrade for 15-100 matches daily.',
        category: NotificationCategory.tierLimit,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
        actionRoute: '/paywall',
        actionLabel: 'View Tiers',
      ),
    ];
    state = state.copyWith(notifications: initial, isLoading: false);
    _saveToStorage(initial);
  }

  Future<void> _saveToStorage(List<AppNotification> list) async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final encoded = jsonEncode(list.map((n) => n.toJson()).toList());
      await storage.storage.write(key: _storageKey, value: encoded);
    } catch (_) {}
  }

  void addNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    String? actionRoute,
    String? actionLabel,
    Map<String, dynamic>? metadata,
  }) {
    final newNotif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      category: category,
      timestamp: DateTime.now(),
      isRead: false,
      actionRoute: actionRoute,
      actionLabel: actionLabel,
      metadata: metadata,
    );
    final updated = [newNotif, ...state.notifications];
    state = state.copyWith(notifications: updated);
    _saveToStorage(updated);
  }

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
    _saveToStorage(updated);
  }

  void markAllAsRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
    _saveToStorage(updated);
  }

  void clearAll() {
    state = state.copyWith(notifications: []);
    _saveToStorage([]);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});
