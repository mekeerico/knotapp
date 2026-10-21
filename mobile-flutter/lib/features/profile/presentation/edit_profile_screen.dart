import 'dart:convert';
import 'dart:io';
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

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _bioController;
  late TextEditingController _occupationController;
  late TextEditingController _educationController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  String _timeline = '1-2 years';

  final ImagePicker _picker = ImagePicker();
  String _primaryPhoto = '';
  List<String> _allPhotos = [];
  bool _hasChangedPhoto = false;
  bool _headerVisible = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _bioController = TextEditingController(text: user?.bio ?? '');
    _occupationController = TextEditingController(text: user?.occupation ?? '');
    _educationController = TextEditingController(
      text: (user?.education.isNotEmpty ?? false)
          ? user!.education
          : "Bachelor's Degree (B.Sc. / B.A. / LL.B)",
    );
    _cityController = TextEditingController(text: user?.residenceCity ?? '');
    _countryController = TextEditingController(text: user?.residenceCountry ?? '');
    _timeline = user?.marriageTimeline ?? '1-2 years';

    _allPhotos = List.from(user?.profileImageUrls ?? []);
    if (_allPhotos.isNotEmpty) {
      _primaryPhoto = _allPhotos.first;
    } else if (user?.selfieUrl != null && user!.selfieUrl!.isNotEmpty) {
      _primaryPhoto = user.selfieUrl!;
    } else {
      _primaryPhoto = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800';
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
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

  Future<void> _pickNewPrimaryPhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _primaryPhoto = dataUrl;
          _hasChangedPhoto = true;
          if (_allPhotos.isNotEmpty) {
            _allPhotos[0] = dataUrl;
          } else {
            _allPhotos.add(dataUrl);
          }
        });

        // Save immediately to backend so it displays on Match screen right away
        await ref.read(authProvider.notifier).updateProfile({
          'profileImageUrls': _allPhotos,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Primary photo updated and set for Match screen display!'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking primary photo: $e');
    }
  }

  void _save() async {
    final Map<String, dynamic> updateData = {
      'bio': _bioController.text.trim(),
      'occupation': _occupationController.text.trim(),
      'education': _educationController.text.trim(),
      'residenceCity': _cityController.text.trim(),
      'residenceCountry': _countryController.text.trim(),
      'marriageTimeline': _timeline,
    };

    if (_hasChangedPhoto) {
      updateData['profileImageUrls'] = _allPhotos;
    }

    await ref.read(authProvider.notifier).updateProfile(updateData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'EDIT CANDIDATE PROFILE',
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
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // PROFILE PICTURE & MATCH DISPLAY SECTION
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.champagneGold, width: 2.5),
                            image: DecorationImage(
                              image: _resolveImageProvider(_primaryPhoto),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickNewPrimaryPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.goldGradient,
                              ),
                              child: const Icon(Icons.camera_alt, color: AppColors.obsidianBlack, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Match Screen Display Image',
                      style: AppTypography.titleMedium.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This photo will be displayed on the Discovery & Match screen for eligible candidates.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickNewPrimaryPhoto,
                          icon: const Icon(Icons.photo_camera, size: 16, color: AppColors.champagneGold),
                          label: Text(
                            'Change Profile Picture',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.champagneGold, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.champagneGold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/manage-photos'),
                          icon: const Icon(Icons.collections, size: 16, color: AppColors.textPure),
                          label: Text(
                            'Portfolio (Add up to 4 more)',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.textPure, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vocation & Career', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _occupationController,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                      decoration: const InputDecoration(hintText: 'Occupation'),
                    ),
                    const SizedBox(height: 18),

                    Text('Highest Educational Qualification', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _educationController,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                      decoration: const InputDecoration(hintText: "e.g. Bachelor's Degree, Master's Degree, Ph.D."),
                    ),
                    const SizedBox(height: 18),

                    Text('Residence Location', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                            decoration: const InputDecoration(hintText: 'City'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _countryController,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                            decoration: const InputDecoration(hintText: 'Country'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Text('Marriage Timeline', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['ASAP', '1-2 years', '2-3 years'].map((t) {
                        final isSelected = _timeline == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          selectedColor: AppColors.champagneGold.withValues(alpha: 0.2),
                          backgroundColor: AppColors.darkCardElevated,
                          labelStyle: AppTypography.bodySmall.copyWith(
                            color: isSelected ? AppColors.champagneGold : AppColors.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => setState(() => _timeline = t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    Text('Candidate Bio & Commitment Vision', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      maxLines: 4,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                      decoration: const InputDecoration(
                        hintText: 'Share your personal values, faith, and marriage vision...',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GoldButton(
                text: 'Save Changes',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
