import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../../auth/providers/auth_provider.dart';

class ManagePhotosScreen extends ConsumerStatefulWidget {
  const ManagePhotosScreen({super.key});

  @override
  ConsumerState<ManagePhotosScreen> createState() => _ManagePhotosScreenState();
}

class _ManagePhotosScreenState extends ConsumerState<ManagePhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _photos = List.from(user?.profileImageUrls ?? [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800',
    ]);
  }

  void _addPhoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _photos.add(file.path);
      });
      // In production, upload to backend or CDN
      ref.read(authProvider.notifier).updateProfile({
        'profileImageUrls': _photos,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'MANAGE PHOTOS',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.champagneGold),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Candidate Portfolio',
                style: AppTypography.displayMedium.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload clear, dignified photos that authentically represent your character.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),

              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _photos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _photos.length) {
                      return GestureDetector(
                        onTap: _addPhoto,
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.champagneGold),
                                const SizedBox(height: 10),
                                Text('Add Photo', style: AppTypography.labelLarge),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final photo = _photos[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderGold, width: 1),
                              image: DecorationImage(
                                image: NetworkImage(photo),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.obsidianBlack.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.champagneGold, width: 0.8),
                              ),
                              child: Text(
                                'PRIMARY',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: AppColors.champagneGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              GoldButton(
                text: 'Save Portfolio',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
