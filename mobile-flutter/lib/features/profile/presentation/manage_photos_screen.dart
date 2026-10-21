import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
  bool _isSaving = false;
  bool _headerVisible = true;
  static const int _maxPhotos = 5; // 1 Primary + up to 4 Additional

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final existing = user?.profileImageUrls ?? [];
    if (existing.isNotEmpty) {
      _photos = List.from(existing);
    } else {
      _photos = [];
    }
  }

  ImageProvider _resolveImageProvider(String path) {
    if (path.startsWith('data:image')) {
      final base64String = path.contains('base64,') ? path.split('base64,')[1] : path;
      return MemoryImage(base64Decode(base64String));
    }
    if (path.startsWith('/uploads/')) {
      const apiBase = String.fromEnvironment('API_URL', defaultValue: 'http://knotconnect.duckdns.org:8080');
      return NetworkImage('$apiBase$path');
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum portfolio limit reached (1 primary + 4 additional pictures).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _photos.add(dataUrl);
        });

        await _savePhotosToBackend();
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  void _showAddPhotoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Portfolio Picture', style: AppTypography.headingMedium),
              const SizedBox(height: 6),
              Text(
                'Add up to 4 additional pictures to display on your sovereign profile.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.champagneGold),
                title: Text('Take New Photo (Camera)', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.champagneGold),
                title: Text('Choose from Photo Gallery', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPhotoTap(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index != 0)
                ListTile(
                  leading: const Icon(Icons.star_outline, color: AppColors.champagneGold),
                  title: Text('Set as Primary (Match Screen Display)', style: AppTypography.bodyMedium),
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() {
                      final selected = _photos.removeAt(index);
                      _photos.insert(0, selected);
                    });
                    await _savePhotosToBackend();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text('Delete Photo', style: AppTypography.bodyMedium.copyWith(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() {
                    _photos.removeAt(index);
                  });
                  await _savePhotosToBackend();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePhotosToBackend() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile({
        'profileImageUrls': _photos,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portfolio updated successfully.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving photos: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'MANAGE PHOTOS',
        isTitleVisible: _headerVisible,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.champagneGold, size: 18),
          onPressed: () => context.pop(),
        ),
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
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Candidate Portfolio',
                    style: AppTypography.displayMedium.copyWith(fontSize: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.champagneGold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_photos.length} / $_maxPhotos Slots',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.champagneGold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Slot 1 is your Primary picture displayed on the Match screen. Add up to 4 additional pictures for your candidate portfolio.',
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
                  itemCount: _photos.length < _maxPhotos ? _photos.length + 1 : _photos.length,
                  itemBuilder: (context, index) {
                    if (index == _photos.length) {
                      return GestureDetector(
                        onTap: _showAddPhotoModal,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.darkCardElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.champagneGold.withValues(alpha: 0.4),
                              width: 1.2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_outlined, size: 38, color: AppColors.champagneGold),
                                const SizedBox(height: 10),
                                Text(
                                  _photos.isEmpty ? 'Add Primary Photo' : 'Add Photo (${index + 1}/5)',
                                  style: AppTypography.labelLarge.copyWith(color: AppColors.champagneGold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final photo = _photos[index];
                    return GestureDetector(
                      onTap: () => _onPhotoTap(index),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: index == 0 ? AppColors.champagneGold : AppColors.borderSubtle,
                                width: index == 0 ? 2 : 1,
                              ),
                              image: DecorationImage(
                                image: _resolveImageProvider(photo),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.obsidianBlack.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: index == 0 ? AppColors.champagneGold : AppColors.borderSubtle,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                index == 0 ? '★ MATCH DISPLAY' : 'PORTFOLIO $index',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: index == 0 ? AppColors.champagneGold : AppColors.textPure,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.obsidianBlack.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.more_vert, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              GoldButton(
                text: _isSaving ? 'Saving Portfolio...' : 'Done',
                onPressed: _isSaving ? null : () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
