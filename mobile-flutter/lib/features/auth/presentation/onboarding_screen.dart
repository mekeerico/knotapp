import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _religionController = TextEditingController();

  String _gender = 'Female';
  String _preferredGender = 'Male';
  String _marriageTimeline = '1-2 years';
  String _willingToRelocate = 'Yes';
  String _childrenPreference = 'Open to children';
  final List<String> _selectedValues = ['Faith', 'Family', 'Integrity'];

  final List<String> _availableValues = [
    'Faith',
    'Family',
    'Integrity',
    'Growth',
    'Ambition',
    'Loyalty',
    'Communication',
    'Adventure',
    'Empathy',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _occupationController.dispose();
    _religionController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your legal first and last name.')),
        );
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Finalize Onboarding & Save
      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'gender': _gender,
        'preferredGender': _preferredGender,
        'occupation': _occupationController.text.trim().isEmpty
            ? 'Professional'
            : _occupationController.text.trim(),
        'religion': _religionController.text.trim().isEmpty
            ? 'Christian'
            : _religionController.text.trim(),
        'marriageTimeline': _marriageTimeline,
        'willingToRelocate': _willingToRelocate,
        'childrenPreference': _childrenPreference,
        'personalValues': _selectedValues,
        'personalityArchetype': 'The Intentional Builder',
        'attachmentStyle': 'Secure',
        'readinessScore': 92,
        'seriousnessLevel': 96,
      };

      await ref.read(authProvider.notifier).updateProfile(updateData);
      if (mounted) {
        // Invite to Didit verification or discovery
        context.go('/verification');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'ONBOARDING (${_currentStep + 1}/4)',
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.champagneGold, size: 18),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Line
              LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: AppColors.darkSlate,
                valueColor: const AlwaysStoppedAnimation(AppColors.champagneGold),
                minHeight: 3,
              ),
              const SizedBox(height: 28),

              if (_currentStep == 0) _buildIdentityStep(),
              if (_currentStep == 1) _buildVocationStep(),
              if (_currentStep == 2) _buildMarriageTimelineStep(),
              if (_currentStep == 3) _buildValuesStep(),

              const SizedBox(height: 36),
              GoldButton(
                text: _currentStep == 3 ? 'Complete & Verify Identity' : 'Continue',
                onPressed: _nextStep,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legal Candidate Identity', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Must match your Government ID for Didit biometric verification.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _firstNameController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'First Name (e.g. Sophia)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'Last Name (e.g. Al-Mansoor)'),
          ),
          const SizedBox(height: 20),
          Text('Gender Identity', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildChoiceChip('Female', _gender == 'Female', () => setState(() => _gender = 'Female')),
              const SizedBox(width: 12),
              _buildChoiceChip('Male', _gender == 'Male', () => setState(() => _gender = 'Male')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Seeking (Preferred Partner)', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildChoiceChip('Male', _preferredGender == 'Male', () => setState(() => _preferredGender = 'Male')),
              const SizedBox(width: 12),
              _buildChoiceChip('Female', _preferredGender == 'Female', () => setState(() => _preferredGender = 'Female')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVocationStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vocation & Faith', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text('Core foundations for marital alignment.', style: AppTypography.bodySmall),
          const SizedBox(height: 24),
          TextField(
            controller: _occupationController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'Occupation (e.g. Software Architect)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _religionController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'Religion / Faith (e.g. Christian)'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarriageTimelineStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commitment Intention', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text('KNOT is strictly for candidates ready for marriage.', style: AppTypography.bodySmall),
          const SizedBox(height: 20),
          Text('Marriage Timeline', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['ASAP', '1-2 years', '2-3 years'].map((t) {
              return _buildChoiceChip(t, _marriageTimeline == t, () => setState(() => _marriageTimeline = t));
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Willing to Relocate?', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: ['Yes', 'Maybe', 'No'].map((r) {
              return _buildChoiceChip(r, _willingToRelocate == r, () => setState(() => _willingToRelocate = r));
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Children Preferences', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: ['Wants children', 'Open to children', 'Does not want children'].map((c) {
              return _buildChoiceChip(c, _childrenPreference == c, () => setState(() => _childrenPreference = c));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildValuesStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sacred Core Values', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text('Select values that define your life philosophy.', style: AppTypography.bodySmall),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableValues.map((v) {
              final isSelected = _selectedValues.contains(v);
              return _buildChoiceChip(
                v,
                isSelected,
                () {
                  setState(() {
                    if (isSelected) {
                      _selectedValues.remove(v);
                    } else {
                      _selectedValues.add(v);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.champagneGold.withOpacity(0.2) : AppColors.darkCardElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.champagneGold : AppColors.borderSubtle,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.champagneGold : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
