import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../../../core/widgets/auto_hiding_floating_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../discovery/providers/discovery_provider.dart';

class PartnerPreferencesScreen extends ConsumerStatefulWidget {
  const PartnerPreferencesScreen({super.key});

  @override
  ConsumerState<PartnerPreferencesScreen> createState() => _PartnerPreferencesScreenState();
}

class _PartnerPreferencesScreenState extends ConsumerState<PartnerPreferencesScreen> {
  static const Color _pearlGrey = Color(0xFFD1D5DC);  // Soft Off-White / Pearl Grey
  static const Color _mutedSlate = Color(0xFF94A3B8); // Muted Slate Grey / Cool Slate Blue
  static const Color _trustGold = Color(0xFFD4AF37);  // Golden accent

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
      body: SafeArea(
        child: AutoHidingFloatingBar(
          bottomOffset: 0,
          topOffset: 0,
          topFloatingContent: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.obsidianBlack,
                  AppColors.obsidianBlack.withOpacity(0.95),
                  AppColors.obsidianBlack.withOpacity(0.72),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.55, 0.85, 1.0],
              ),
            ),
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 16,
              left: 8,
              right: 20,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.champagneGold),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    'PARTNER PREFERENCES',
                    textAlign: TextAlign.center,
                    style: AppTypography.headingMedium.copyWith(
                      letterSpacing: 1.5,
                      color: AppColors.textPure,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          floatingContent: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.obsidianBlack.withOpacity(0.75),
                  AppColors.obsidianBlack.withOpacity(0.96),
                  AppColors.obsidianBlack,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.25, 0.65, 1.0],
              ),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: GoldButton(
              text: _isSaving ? 'Saving Preferences...' : 'Save Match Preferences ✨',
              icon: Icons.save_rounded,
              onPressed: _isSaving ? null : _handleSave,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52), // offset for top floating bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlate,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGold.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_outlined, color: _trustGold, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI MATRIMONIAL MATCHMAKER',
                              style: AppTypography.headingMedium.copyWith(
                                fontSize: 14,
                                color: _pearlGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Adjust your future spouse criteria. Our matching engine will reprioritize candidates according to your latest standards.',
                              style: AppTypography.bodySmall.copyWith(color: _mutedSlate, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Partner Age Range
                _buildSectionHeader('Preferred Partners Age', Icons.cake_outlined, titleColor: _mutedSlate),
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Age Range: ${_ageRange.start.round()} - ${_ageRange.end.round()} Years',
                            style: AppTypography.titleMedium.copyWith(color: _pearlGrey, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.darkSlate,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _pearlGrey.withOpacity(0.4)),
                            ),
                            child: Text(
                              '${_ageRange.end.round() - _ageRange.start.round()} Yr Window',
                              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: _pearlGrey),
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
                        activeColor: const Color(0xFFE27D8D),
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
                _buildSectionHeader('Preferred Children Status', Icons.family_restroom_outlined, titleColor: _mutedSlate),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildRadioTile(
                        title: 'No Children Yet',
                        subtitle: 'Prefer someone who has not yet had children',
                        value: 'No children yet',
                        groupValue: _childrenStatus,
                        onChanged: (v) => setState(() => _childrenStatus = v!),
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 16),
                      _buildRadioTile(
                        title: 'Has Children',
                        subtitle: 'Open and welcoming to candidates with children',
                        value: 'Has children',
                        groupValue: _childrenStatus,
                        onChanged: (v) => setState(() => _childrenStatus = v!),
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 16),
                      _buildRadioTile(
                        title: 'Open to Either',
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
                _buildSectionHeader('Open to Future Children', Icons.child_care_outlined, titleColor: _mutedSlate),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      'Wants children',
                      'Open to children',
                      'Does not want children',
                    ].map((option) {
                      final isSelected = _childrenPreference == option;
                      return _buildSelectableChip(
                        label: option,
                        isSelected: isSelected,
                        onTap: () => setState(() => _childrenPreference = option),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Marriage Timeline
                _buildSectionHeader('Marriage Horizon & Timeline', Icons.access_time_rounded, titleColor: _mutedSlate),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      'ASAP (Within 6 months)',
                      'Within 1 year',
                      '1-2 Years',
                      '2+ Years',
                    ].map((option) {
                      final isSelected = _marriageTimeline == option;
                      return _buildSelectableChip(
                        label: option,
                        isSelected: isSelected,
                        onTap: () => setState(() => _marriageTimeline = option),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Origin & Heritage Preference
                _buildSectionHeader('Preferred Heritage & Origin Country', Icons.public_outlined, titleColor: _pearlGrey),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Partner Ancestry / Heritage Country',
                        style: AppTypography.bodySmall.copyWith(color: _pearlGrey.withOpacity(0.7), fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _originCountryController,
                        style: const TextStyle(color: _pearlGrey),
                        decoration: InputDecoration(
                          hintText: 'e.g. Nigeria, Ghana, United States, Jamaica, Any',
                          hintStyle: TextStyle(color: _pearlGrey.withOpacity(0.4), fontSize: 13),
                          filled: true,
                          fillColor: AppColors.darkSlate,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _pearlGrey.withOpacity(0.3)),
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
                _buildSectionHeader('Preferred Partners Residence Location', Icons.location_on_outlined, titleColor: _pearlGrey),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _residenceCountryController,
                        style: const TextStyle(color: _pearlGrey),
                        decoration: InputDecoration(
                          labelText: 'Country',
                          labelStyle: const TextStyle(color: _pearlGrey, fontSize: 12),
                          hintText: 'e.g. United States, United Kingdom, Canada, Nigeria',
                          hintStyle: TextStyle(color: _pearlGrey.withOpacity(0.4), fontSize: 13),
                          filled: true,
                          fillColor: AppColors.darkSlate,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _pearlGrey.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.champagneGold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _residenceCityController,
                        style: const TextStyle(color: _pearlGrey),
                        decoration: InputDecoration(
                          labelText: 'City / Region',
                          labelStyle: const TextStyle(color: _pearlGrey, fontSize: 12),
                          hintText: 'e.g. London, Boston, Atlanta, Lagos, Toronto',
                          hintStyle: TextStyle(color: _pearlGrey.withOpacity(0.4), fontSize: 13),
                          filled: true,
                          fillColor: AppColors.darkSlate,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _pearlGrey.withOpacity(0.3)),
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

                // 7. Ideal Partner Traits
                _buildSectionHeader('Key Partner Traits (Multi-Select)', Icons.stars_rounded, titleColor: _mutedSlate),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableTraits.map((trait) {
                      final isSelected = _selectedTraits.contains(trait);
                      return _buildSelectableChip(
                        label: trait,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTraits.remove(trait);
                            } else {
                              _selectedTraits.add(trait);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 100), // padding above floating save button
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected ? AppColors.goldGradient : null,
          color: isSelected ? null : AppColors.darkSlate,
          border: isSelected
              ? null
              : Border.all(color: _pearlGrey.withOpacity(0.45), width: 1.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE27D8D).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _pearlGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? titleColor, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? _trustGold),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: titleColor ?? _mutedSlate,
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
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFFE27D8D),
              onChanged: onChanged,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _pearlGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: _pearlGrey.withOpacity(0.55), fontSize: 11),
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
