import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/notifications/presentation/widgets/notification_bell_button.dart';

class KnotAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool showNotificationBell;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const KnotAppBar({
    super.key,
    this.title,
    this.showLogo = false,
    this.showNotificationBell = false,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> resolvedActions = [
      if (actions != null) ...actions!,
      if (showNotificationBell) const NotificationBellButton(),
    ];

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KNOT',
                  style: AppTypography.displayMedium.copyWith(
                    fontSize: 22,
                    letterSpacing: 3.0,
                  ),
                ),
                Text(
                  '.',
                  style: AppTypography.displayMedium.copyWith(
                    fontSize: 22,
                    color: AppColors.champagneGold,
                  ),
                ),
              ],
            )
          : title != null
              ? Text(title!, style: AppTypography.headingMedium)
              : null,
      actions: resolvedActions.isNotEmpty ? resolvedActions : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
