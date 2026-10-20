import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../../../core/widgets/knot_image.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../discovery/providers/discovery_provider.dart';

class MessagesListScreen extends ConsumerStatefulWidget {
  const MessagesListScreen({super.key});

  @override
  ConsumerState<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends ConsumerState<MessagesListScreen> {
  bool _headerVisible = true;
  static const Color _pearlGrey = Color(0xFFD1D5DC);

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final candidates = discoveryState.candidates;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'SOVEREIGN MESSAGES',
        titleColor: _pearlGrey,
        isTitleVisible: _headerVisible,
        showNotificationBell: true,
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (_headerVisible) {
            setState(() => _headerVisible = false);
          }
        },
        onPointerUp: (_) {
          if (!_headerVisible) {
            setState(() => _headerVisible = true);
          }
        },
        onPointerCancel: (_) {
          if (!_headerVisible) {
            setState(() => _headerVisible = true);
          }
        },
        child: SafeArea(
          child: candidates.isEmpty
              ? Center(
                  child: Text('No active conversations yet.', style: AppTypography.bodyMedium),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () {
                        context.push('/chat/${candidate.id}', extra: candidate);
                      },
                    child: Row(
                      children: [
                        // Avatar with Gold Border
                        Stack(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.champagneGold, width: 1.5),
                              ),
                              child: KnotImage(
                                imageUrl: candidate.photos.isNotEmpty ? candidate.photos.first : null,
                                width: 54,
                                height: 54,
                                isCircle: true,
                              ),
                            ),
                            if (candidate.isVerified)
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: VerifiedBadge(size: 16),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Message Preview Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                candidate.name,
                                style: AppTypography.titleMedium.copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to open conversation',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }
}
