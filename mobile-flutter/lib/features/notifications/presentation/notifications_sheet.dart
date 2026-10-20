import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/app_notification.dart';
import '../providers/notifications_provider.dart';

class NotificationsSheet extends ConsumerStatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  ConsumerState<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<NotificationsSheet> {
  NotificationCategory? _selectedCategory;

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _getCategoryIcon(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.match:
        return Icons.favorite;
      case NotificationCategory.message:
        return Icons.chat_bubble_outline_rounded;
      case NotificationCategory.tierLimit:
        return Icons.stars_rounded;
      case NotificationCategory.verification:
        return Icons.verified_user_outlined;
      case NotificationCategory.system:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getCategoryColor(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.match:
        return AppColors.roseGlow;
      case NotificationCategory.message:
        return AppColors.champagneGold;
      case NotificationCategory.tierLimit:
        return AppColors.champagneGold;
      case NotificationCategory.verification:
        return const Color(0xFF10B981);
      case NotificationCategory.system:
        return AppColors.champagneGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    final filtered = _selectedCategory == null
        ? state.notifications
        : state.notifications.where((n) => n.category == _selectedCategory).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.obsidianBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderGold, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSubtle.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: AppColors.champagneGold, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: AppTypography.displayMedium.copyWith(fontSize: 20),
                    ),
                    if (state.unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.roseGlow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.unreadCount}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (state.notifications.isNotEmpty)
                      TextButton(
                        onPressed: () => notifier.markAllAsRead(),
                        child: Text(
                          'Mark All Read',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.champagneGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSubtle, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', null),
                _buildFilterChip('Matches', NotificationCategory.match),
                _buildFilterChip('Messages', NotificationCategory.message),
                _buildFilterChip('Tiers & Limits', NotificationCategory.tierLimit),
                _buildFilterChip('Verification', NotificationCategory.verification),
              ],
            ),
          ),
          const Divider(color: AppColors.borderSubtle, height: 1),

          // Notifications List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.darkSlate,
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 30,
                              color: AppColors.textSubtle,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications in this category',
                            style: AppTypography.headingMedium.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'We will alert you on candidate activity, matches, and registry updates.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSubtle),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildNotificationCard(context, item, notifier);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: AppColors.champagneGold,
        backgroundColor: AppColors.darkSlate,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : AppColors.textPure,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.champagneGold : AppColors.borderSubtle,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification item,
    NotificationsNotifier notifier,
  ) {
    final iconColor = _getCategoryColor(item.category);

    return GestureDetector(
      onTap: () {
        notifier.markAsRead(item.id);
        if (item.actionRoute != null) {
          Navigator.pop(context);
          context.push(item.actionRoute!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.darkCard : AppColors.darkSlate,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? AppColors.borderSubtle
                : AppColors.borderGold.withOpacity(0.5),
            width: item.isRead ? 0.8 : 1.2,
          ),
          boxShadow: item.isRead
              ? null
              : [
                  BoxShadow(
                    color: AppColors.champagneGold.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.15),
                border: Border.all(color: iconColor.withOpacity(0.4)),
              ),
              child: Icon(_getCategoryIcon(item.category), size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTypography.headingMedium.copyWith(
                            fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: item.isRead ? AppColors.textPure : AppColors.champagneGold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(item.timestamp),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSubtle,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  if (item.actionLabel != null && item.actionRoute != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.champagneGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGold.withOpacity(0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.actionLabel!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.champagneGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9,
                              color: AppColors.champagneGold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!item.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.champagneGold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
