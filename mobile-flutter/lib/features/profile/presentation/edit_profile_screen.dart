import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  String _timeline = '1-2 years';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _bioController = TextEditingController(text: user?.bio ?? '');
    _occupationController = TextEditingController(text: user?.occupation ?? '');
    _cityController = TextEditingController(text: user?.residenceCity ?? '');
    _countryController = TextEditingController(text: user?.residenceCountry ?? '');
    _timeline = user?.marriageTimeline ?? '1-2 years';
  }

  @override
  void dispose() {
    _bioController.dispose();
    _occupationController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _save() async {
    final updateData = {
      'bio': _bioController.text.trim(),
      'occupation': _occupationController.text.trim(),
      'residenceCity': _cityController.text.trim(),
      'residenceCountry': _countryController.text.trim(),
      'marriageTimeline': _timeline,
    };

    await ref.read(authProvider.notifier).updateProfile(updateData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.champagneGold),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
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
                          selectedColor: AppColors.champagneGold.withOpacity(0.2),
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
    );
  }
}
