import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../discovery/providers/discovery_provider.dart';

class MessagesListScreen extends ConsumerWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryState = ref.watch(discoveryProvider);
    final candidates = discoveryState.candidates;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: const KnotAppBar(
        title: 'SOVEREIGN MESSAGES',
      ),
      body: SafeArea(
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
                                image: DecorationImage(
                                  image: NetworkImage(candidate.photos.first),
                                  fit: BoxFit.cover,
                                ),
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
    );
  }
}
