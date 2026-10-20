import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../discovery/providers/discovery_provider.dart';

class PartnerPreferencesScreen extends ConsumerStatefulWidget {
  const PartnerPreferencesScreen({super.key});

  @override
  ConsumerState<PartnerPreferencesScreen> createState() => _PartnerPreferencesScreenState();
}

class _PartnerPreferencesScreenState extends ConsumerState<PartnerPreferencesScreen> {
  RangeValues _ageRange = const RangeValues(22, 42);
  String _childrenStatus = 'Open to either';
  String _childrenPreference = 'Open to children';
  String _marriageTimeline = '1-2 Years';
  String _willingToRelocate = 'Maybe';
  String _religion = 'Christian';

  late TextEditingController _originCountryController;
  late TextEditingController _residenceCountryController;
  late TextEditingController _residenceCityController;

  final List<String> _availableTraits = [
    'Emotionally mature',
    'Family-oriented',
    'Faith-driven',
    'Ambitious & Driven',
    'Loyal & Devoted',
    'Health-conscious',
    'Kind & Empathetic',
    'Financial Wisdom',
    'Honest & Direct',
  ];

  List<String> _selectedTraits = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;

    // Parse age range from marriageExpectations if present (e.g. "Age 24-36")
    final exp = user?.marriageExpectations ?? '';
    final ageMatch = RegExp(r'(\d{2})\s*-\s*(\d{2})').firstMatch(exp);
    if (ageMatch != null) {
      final minA = double.tryParse(ageMatch.group(1)!) ?? 22;
      final maxA = double.tryParse(ageMatch.group(2)!) ?? 42;
      _ageRange = RangeValues(minA.clamp(18, 70), maxA.clamp(18, 70));
    }

    if (exp.toLowerCase().contains('no kids') || exp.toLowerCase().contains('no children')) {
      _childrenStatus = 'No children yet';
    } else if (exp.toLowerCase().contains('has kids') || exp.toLowerCase().contains('has children')) {
      _childrenStatus = 'Has children';
    }

    _childrenPreference = user?.childrenPreference.isNotEmpty ?? false ? user!.childrenPreference : 'Open to children';
    _marriageTimeline = user?.marriageTimeline.isNotEmpty ?? false ? user!.marriageTimeline : '1-2 Years';
    _willingToRelocate = user?.willingToRelocate.isNotEmpty ?? false ? user!.willingToRelocate : 'Maybe';
    _religion = user?.religion.isNotEmpty ?? false ? user!.religion : 'Christian';

    _originCountryController = TextEditingController(text: user?.preferredOriginCountry ?? '');
    _residenceCountryController = TextEditingController(text: user?.preferredResidenceCountry ?? '');
    _residenceCityController = TextEditingController(text: user?.preferredResidenceCity ?? '');

    _selectedTraits = List.from(user?.idealPartnerTraits ?? [
      'Emotionally mature',
      'Family-oriented',
      'Loyal & Devoted',
    ]);
  }

  @override
  void dispose() {
    _originCountryController.dispose();
    _residenceCountryController.dispose();
    _residenceCityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      final minA = _ageRange.start.round();
      final maxA = _ageRange.end.round();
      final expectations = 'Age $minA-$maxA | $_childrenStatus | Seeking intentional marriage alignment';

      final data = {
        'preferredOriginCountry': _originCountryController.text.trim(),
        'preferredResidenceCountry': _residenceCountryController.text.trim(),
        'preferredResidenceCity': _residenceCityController.text.trim(),
        'childrenPreference': _childrenPreference,
        'marriageTimeline': _marriageTimeline,
        'willingToRelocate': _willingToRelocate,
        'religion': _religion,
        'idealPartnerTraits': _selectedTraits,
        'marriageExpectations': expectations,
      };

      await ref.read(authProvider.notifier).updateProfile(data);
      // Reload daily candidates to reflect new algorithm weighting
      await ref.read(discoveryProvider.notifier).loadCandidates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.darkSlate,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.champagneGold, width: 1.2),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.emeraldVerified, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Partner preferences saved! AI matching updated ✨',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: const KnotAppBar(
        title: 'PARTNER PREFERENCES',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGold.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: AppColors.champagneGold, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Matrimonial Matchmaker',
                            style: AppTypography.headingMedium.copyWith(
                              fontSize: 14,
                              color: AppColors.champagneGold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Adjust your future spouse criteria. Our matching engine will reprioritize candidates according to your latest standards.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Partner Age Range
              _buildSectionHeader('Preferred Partner Age Range', Icons.cake_outlined),
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Age Range: ${_ageRange.start.round()} - ${_ageRange.end.round()} Years',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.champagneGold, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.champagneGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGold),
                          ),
                          child: Text(
                            '${_ageRange.end.round() - _ageRange.start.round()} Yr Window',
                            style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.champagneGold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 70,
                      divisions: 52,
                      activeColor: AppColors.champagneGold,
                      inactiveColor: AppColors.borderSubtle,
                      onChanged: (values) {
                        setState(() => _ageRange = values);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Partner Children Status
              _buildSectionHeader('Partner Children Status', Icons.family_restroom_outlined),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRadioTile(
                      title: 'No children yet',
                      subtitle: 'Prefer someone who has not yet had children',
                      value: 'No children yet',
                      groupValue: _childrenStatus,
                      onChanged: (v) => setState(() => _childrenStatus = v!),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildRadioTile(
                      title: 'Has children',
                      subtitle: 'Open and welcoming to candidates with children',
                      value: 'Has children',
                      groupValue: _childrenStatus,
                      onChanged: (v) => setState(() => _childrenStatus = v!),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildRadioTile(
                      title: 'Open to either',
                      subtitle: 'No restriction—character and alignment matter most',
                      value: 'Open to either',
                      groupValue: _childrenStatus,
                      onChanged: (v) => setState(() => _childrenStatus = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Desire for Future Children
              _buildSectionHeader('Openness to Future Children', Icons.child_care_outlined),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Wants children',
                    'Open to children',
                    'Does not want children',
                  ].map((option) {
                    final isSelected = _childrenPreference == option;
                    return ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      selectedColor: AppColors.champagneGold,
                      backgroundColor: AppColors.darkSlate,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _childrenPreference = option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Marriage Timeline
              _buildSectionHeader('Marriage Horizon & Timeline', Icons.access_time_rounded),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'ASAP (Within 6 months)',
                    'Within 1 year',
                    '1-2 Years',
                    '2+ Years',
                  ].map((option) {
                    final isSelected = _marriageTimeline == option;
                    return ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      selectedColor: AppColors.champagneGold,
                      backgroundColor: AppColors.darkSlate,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _marriageTimeline = option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // 5. Origin & Heritage Preference
              _buildSectionHeader('Preferred Heritage & Origin Country', Icons.public_outlined),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Partner Ancestry / Heritage Country',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSubtle, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _originCountryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. Nigeria, Ghana, United States, Jamaica, Any',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.darkSlate,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.champagneGold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 6. Residence Location Preference
              _buildSectionHeader('Preferred Partner Residence Location', Icons.location_on_outlined),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _residenceCountryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Country',
                        labelStyle: const TextStyle(color: AppColors.champagneGold, fontSize: 12),
                        hintText: 'e.g. United States, United Kingdom, Canada, Nigeria',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.darkSlate,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.champagneGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _residenceCityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'City / Region',
                        labelStyle: const TextStyle(color: AppColors.champagneGold, fontSize: 12),
                        hintText: 'e.g. London, Boston, Atlanta, Lagos, Toronto',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.darkSlate,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.champagneGold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 7. Ideal Partner Traits
              _buildSectionHeader('Key Partner Traits (Multi-select)', Icons.stars_rounded),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTraits.map((trait) {
                    final isSelected = _selectedTraits.contains(trait);
                    return FilterChip(
                      label: Text(trait),
                      selected: isSelected,
                      selectedColor: AppColors.champagneGold.withOpacity(0.25),
                      checkmarkColor: AppColors.champagneGold,
                      backgroundColor: AppColors.darkSlate,
                      side: BorderSide(
                        color: isSelected ? AppColors.champagneGold : AppColors.borderSubtle,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.champagneGold : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTraits.add(trait);
                          } else {
                            _selectedTraits.remove(trait);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              GoldButton(
                text: _isSaving ? 'Saving Preferences...' : 'Save Match Preferences ✨',
                icon: Icons.save_rounded,
                onPressed: _isSaving ? null : _handleSave,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.champagneGold),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.textPure,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppColors.champagneGold,
              onChanged: onChanged,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.champagneGold : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
