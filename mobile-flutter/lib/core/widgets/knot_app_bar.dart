import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/notifications/presentation/widgets/notification_bell_button.dart';

class KnotAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Color? titleColor;
  final bool isTitleVisible;
  final bool showLogo;
  final bool showNotificationBell;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const KnotAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.titleColor,
    this.isTitleVisible = true,
    this.showLogo = false,
    this.showNotificationBell = false,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> resolvedActions = [
      ...?actions,
      if (showNotificationBell) const NotificationBellButton(),
    ];

    Widget? renderedTitle;
    if (showLogo) {
      renderedTitle = Row(
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
      );
    } else if (titleWidget != null) {
      renderedTitle = titleWidget;
    } else if (title != null) {
      renderedTitle = Text(
        title!,
        style: AppTypography.headingMedium.copyWith(
          color: titleColor,
        ),
      );
    }

    if (renderedTitle != null) {
      renderedTitle = AnimatedSlide(
        offset: isTitleVisible ? Offset.zero : const Offset(0, -0.4),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isTitleVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: renderedTitle,
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: renderedTitle,
      actions: resolvedActions.isNotEmpty ? resolvedActions : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
