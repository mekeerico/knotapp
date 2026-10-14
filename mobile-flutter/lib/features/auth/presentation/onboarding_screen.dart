import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/location_data.dart';
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
  static const int _totalSteps = 6;

  // Controllers - Step 1: Legal Identity & Age
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _selectedDob;
  String _gender = 'Female';

  // Controllers - Step 2: Vocation, Faith & Languages
  final _occupationController = TextEditingController();
  String _religionSelect = 'Christian';
  final _religionCustomController = TextEditingController();
  final List<String> _selectedLanguages = ['English'];
  final _otherLanguageController = TextEditingController();

  // Controllers - Step 3: Where You Live & Heritage
  String _residenceCountry = 'United States of America';
  String _residenceState = '';
  final _residenceStateCustomController = TextEditingController();
  final _residenceCityController = TextEditingController();

  String _originCountry = 'United States of America';
  String _originState = '';
  final _originStateCustomController = TextEditingController();
  final _originCityController = TextEditingController();

  // Controllers - Step 4: Lifestyle Habits
  String _maritalStatus = 'Never married';
  String _smoking = 'Non-smoker';
  String _drinking = 'Non-drinker';

  // Controllers - Step 5: Future Partner Preferences
  String _prefResCountry = 'Any Country';
  final _prefResCountryCustomController = TextEditingController();
  String _prefResState = 'Any State/Province/Region';
  final _prefResStateCustomController = TextEditingController();

  String _prefOriCountry = 'Any Country';
  final _prefOriCountryCustomController = TextEditingController();
  String _prefOriState = 'Any Heritage';
  final _prefOriCustomController = TextEditingController();

  String _partnerChildrenStatus = 'No Kid(s)';
  String _marriageTimeline = '1-2 years';
  String _willingToRelocate = 'Yes';

  // Controllers - Step 6: Family Goals, Traits & Expectations
  String _childrenIntent = 'Want children';
  final List<String> _idealPartnerTraits = ['Kind', 'Family-oriented', 'Faith'];
  final _otherTraitController = TextEditingController();
  RangeValues _partnerAgeRange = const RangeValues(22, 38);
  final _marriageExpectationsController = TextEditingController();
  final List<String> _selectedCoreValues = ['Faith', 'Family', 'Integrity'];

  final List<String> _availableCoreValues = [
    'Faith', 'Family', 'Integrity', 'Growth', 'Ambition',
    'Loyalty', 'Communication', 'Adventure', 'Empathy', 'Respect'
  ];

  final List<String> _religions = [
    'Christian', 'Muslim', 'Jewish', 'Hindu', 'Buddhist',
    'Atheist', 'Agnostic', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Default DOB to 26 years ago
    _selectedDob = DateTime.now().subtract(const Duration(days: 365 * 26));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _occupationController.dispose();
    _religionCustomController.dispose();
    _otherLanguageController.dispose();
    _residenceStateCustomController.dispose();
    _residenceCityController.dispose();
    _originStateCustomController.dispose();
    _originCityController.dispose();
    _prefResCountryCustomController.dispose();
    _prefResStateCustomController.dispose();
    _prefOriCountryCustomController.dispose();
    _prefOriCustomController.dispose();
    _otherTraitController.dispose();
    _marriageExpectationsController.dispose();
    super.dispose();
  }

  int get _calculatedAge {
    if (_selectedDob == null) return 26;
    final now = DateTime.now();
    int age = now.year - _selectedDob!.year;
    if (now.month < _selectedDob!.month ||
        (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
      age--;
    }
    return age;
  }

  String get _formattedDob {
    if (_selectedDob == null) return '';
    return '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}';
  }

  void _nextStep() async {
    // Step 0 Validation: Identity & Age
    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty) {
        _showError('Please enter your legal first and last name.');
        return;
      }
      if (_calculatedAge < 18) {
        _showError('Candidates must be 18 years or older to join KNOT.');
        return;
      }
    }

    // Step 1 Validation: Vocation & Faith
    if (_currentStep == 1) {
      if (_occupationController.text.trim().isEmpty) {
        _showError('Please enter your occupation.');
        return;
      }
      if (_religionSelect == 'Other' && _religionCustomController.text.trim().isEmpty) {
        _showError('Please specify your religion / faith.');
        return;
      }
      if (_selectedLanguages.isEmpty) {
        _showError('Please select at least one language spoken.');
        return;
      }
    }

    // Step 2 Validation: Locations
    if (_currentStep == 2) {
      if (_residenceCountry.isEmpty || _residenceCityController.text.trim().isEmpty) {
        _showError('Please provide your Country of residence and City.');
        return;
      }
      if (_originCountry.isEmpty || _originCityController.text.trim().isEmpty) {
        _showError('Please provide your Country of heritage/origin and City.');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Step 6: Finalize Onboarding & Save
      final finalReligion = _religionSelect == 'Other'
          ? _religionCustomController.text.trim()
          : _religionSelect;

      final finalResState = _residenceState.isNotEmpty
          ? _residenceState
          : _residenceStateCustomController.text.trim();

      final finalOriginState = _originState.isNotEmpty
          ? _originState
          : _originStateCustomController.text.trim();

      final finalPrefResCountry = _prefResCountry == 'Enter Choice Country'
          ? _prefResCountryCustomController.text.trim()
          : _prefResCountry;

      final finalPrefResState = _prefResState == 'Enter State/Province/Region'
          ? _prefResStateCustomController.text.trim()
          : _prefResState;

      final finalPrefOriCountry = _prefOriCountry == 'Enter Choice Country'
          ? _prefOriCountryCustomController.text.trim()
          : _prefOriCountry;

      final finalPrefOriState = _prefOriState == 'Enter Native Heritage'
          ? _prefOriCustomController.text.trim()
          : _prefOriState;

      // Languages
      final languages = List<String>.from(_selectedLanguages);
      if (languages.contains('Other') && _otherLanguageController.text.trim().isNotEmpty) {
        languages.remove('Other');
        languages.add(_otherLanguageController.text.trim());
      }

      // Traits
      final traits = List<String>.from(_idealPartnerTraits);
      if (traits.contains('Other') && _otherTraitController.text.trim().isNotEmpty) {
        traits.remove('Other');
        traits.add(_otherTraitController.text.trim());
      }

      // Opposite sex automatically derived
      final preferredGender = _gender == 'Female' ? 'Male' : 'Female';

      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'gender': _gender,
        'preferredGender': preferredGender,
        'dateOfBirth': _formattedDob,
        'occupation': _occupationController.text.trim(),
        'religion': finalReligion,
        'languagesSpoken': languages,
        // Lifestyle
        'maritalStatus': _maritalStatus,
        'smoking': _smoking,
        'drinking': _drinking,
        // Residence
        'residenceCountry': _residenceCountry,
        'residenceState': finalResState,
        'residenceCity': _residenceCityController.text.trim(),
        // Heritage
        'originCountry': _originCountry,
        'originState': finalOriginState,
        'originCity': _originCityController.text.trim(),
        // Preferred Partner Location & Heritage
        'preferredResidenceCountry': finalPrefResCountry,
        'preferredResidenceState': finalPrefResState,
        'preferredOriginCountry': finalPrefOriCountry,
        'preferredOriginState': finalPrefOriState,
        // Future Marriage Plans
        'childrenStatus': _partnerChildrenStatus,
        'marriageTimeline': _marriageTimeline,
        'willingToRelocate': _willingToRelocate,
        'childrenPreference': _childrenIntent,
        // Traits & Expectations
        'idealPartnerTraits': traits,
        'personalValues': _selectedCoreValues,
        'marriageExpectations': _marriageExpectationsController.text.trim(),
        'personalityArchetype': 'The Intentional Builder',
        'attachmentStyle': 'Secure',
        'readinessScore': 92,
        'seriousnessLevel': 96,
      };

      await ref.read(authProvider.notifier).updateProfile(updateData);
      if (mounted) {
        context.go('/verification');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? now.subtract(const Duration(days: 365 * 25));
    final firstDate = DateTime(1940);
    final lastDate = now.subtract(const Duration(days: 365 * 18));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.champagneGold,
              onPrimary: AppColors.obsidianBlack,
              surface: AppColors.darkCardElevated,
              onSurface: AppColors.textPure,
            ),
            dialogBackgroundColor: AppColors.obsidianBlack,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'ONBOARDING (${_currentStep + 1}/$_totalSteps)',
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.champagneGold, size: 18),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Line
              LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: AppColors.darkSlate,
                valueColor: const AlwaysStoppedAnimation(AppColors.champagneGold),
                minHeight: 3,
              ),
              const SizedBox(height: 24),

              if (_currentStep == 0) _buildIdentityStep(),
              if (_currentStep == 1) _buildVocationAndFaithStep(),
              if (_currentStep == 2) _buildResidenceAndOriginStep(),
              if (_currentStep == 3) _buildLifestyleHabitsStep(),
              if (_currentStep == 4) _buildPartnerPlansStep(),
              if (_currentStep == 5) _buildFamilyGoalsAndExpectationsStep(),

              const SizedBox(height: 32),
              GoldButton(
                text: _currentStep == _totalSteps - 1
                    ? 'Complete & Verify Identity'
                    : 'Continue',
                onPressed: _nextStep,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 1: Legal Identity & Age (No seeking option, strict opposite-sex)
  Widget _buildIdentityStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legal Candidate Identity', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Must match your Government ID for biometric verification.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Legal First Name'),
          TextField(
            controller: _firstNameController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'First Name (e.g. Sophia)'),
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Legal Last Name'),
          TextField(
            controller: _lastNameController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'Last Name (e.g. Al-Mansoor)'),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Gender Identity'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceChip(
                'Female',
                _gender == 'Female',
                () => setState(() => _gender = 'Female'),
              ),
              const SizedBox(width: 14),
              _buildChoiceChip(
                'Male',
                _gender == 'Male',
                () => setState(() => _gender = 'Male'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFieldLabel('Date of Birth & Age'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDob,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.darkCardElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.champagneGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDob != null ? _formattedDob : 'Select Date of Birth',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.champagneGold.withOpacity(0.5)),
                    ),
                    child: Text(
                      'Age $_calculatedAge',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.champagneGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Vocation, Faith & Languages
  Widget _buildVocationAndFaithStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vocation, Faith & Languages', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text('Core foundations for mutual alignment.', style: AppTypography.bodySmall),
          const SizedBox(height: 20),
          _buildFieldLabel('Occupation'),
          TextField(
            controller: _occupationController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'e.g. Software Architect, Physician'),
          ),
          const SizedBox(height: 18),
          _buildDropdownField(
            label: 'Religion / Faith',
            value: _religionSelect,
            items: _religions,
            onChanged: (val) {
              if (val != null) setState(() => _religionSelect = val);
            },
          ),
          if (_religionSelect == 'Other') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _religionCustomController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'Specify your religion or belief'),
            ),
          ],
          const SizedBox(height: 20),
          _buildFieldLabel('Languages Spoken'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: KnotLocationData.majorLanguages.map((lang) {
              final isSelected = _selectedLanguages.contains(lang);
              return _buildChoiceChip(
                lang,
                isSelected,
                () {
                  setState(() {
                    if (isSelected) {
                      _selectedLanguages.remove(lang);
                    } else {
                      _selectedLanguages.add(lang);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedLanguages.contains('Other')) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otherLanguageController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'Specify other language(s)'),
            ),
          ],
        ],
      ),
    );
  }

  // STEP 3: Where You Live & Heritage
  Widget _buildResidenceAndOriginStep() {
    final List<String> residenceStates = KnotLocationData.statesByCountry[_residenceCountry] ?? const <String>[];
    final List<String> originStates = KnotLocationData.statesByCountry[_originCountry] ?? const <String>[];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location & Heritage', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text('Where you reside and your native origin.', style: AppTypography.bodySmall),
          const SizedBox(height: 20),

          // Residence Section
          Text('CURRENT RESIDENCE', style: AppTypography.titleMedium.copyWith(color: AppColors.champagneGold)),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Country of Residence',
            value: _residenceCountry,
            items: KnotLocationData.countries,
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _residenceCountry = val;
                  _residenceState = '';
                });
              }
            },
          ),
          const SizedBox(height: 12),
          if (residenceStates.isNotEmpty)
            _buildDropdownField(
              label: 'State / Province',
              value: _residenceState.isNotEmpty && residenceStates.contains(_residenceState)
                  ? _residenceState
                  : residenceStates.first,
              items: residenceStates,
              onChanged: (val) {
                if (val != null) setState(() => _residenceState = val);
              },
            )
          else ...[
            _buildFieldLabel('State / Province'),
            TextField(
              controller: _residenceStateCustomController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'State / Province / Region'),
            ),
          ],
          const SizedBox(height: 12),
          _buildFieldLabel('City / Town'),
          TextField(
            controller: _residenceCityController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'City of residence (e.g. New York, London)'),
          ),

          const SizedBox(height: 28),

          // Heritage / Origin Section
          Text('HERITAGE & ORIGIN', style: AppTypography.titleMedium.copyWith(color: AppColors.champagneGold)),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Country of Heritage / Origin',
            value: _originCountry,
            items: KnotLocationData.countries,
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _originCountry = val;
                  _originState = '';
                });
              }
            },
          ),
          const SizedBox(height: 12),
          if (originStates.isNotEmpty)
            _buildDropdownField(
              label: 'State / Province / Region',
              value: _originState.isNotEmpty && originStates.contains(_originState)
                  ? _originState
                  : originStates.first,
              items: originStates,
              onChanged: (val) {
                if (val != null) setState(() => _originState = val);
              },
            )
          else ...[
            _buildFieldLabel('State / Province / Region'),
            TextField(
              controller: _originStateCustomController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'State / Province / Native region'),
            ),
          ],
          const SizedBox(height: 12),
          _buildFieldLabel('Origin City / Ancestral Town'),
          TextField(
            controller: _originCityController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'Ancestral town or city of origin'),
          ),
        ],
      ),
    );
  }

  // STEP 4: Lifestyle Habits
  Widget _buildLifestyleHabitsStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lifestyle Habits', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text('Transparency for meaningful lifelong partnership.', style: AppTypography.bodySmall),
          const SizedBox(height: 24),
          _buildDropdownField(
            label: 'Marriage History',
            value: _maritalStatus,
            items: KnotLocationData.maritalStatusOptions,
            onChanged: (val) {
              if (val != null) setState(() => _maritalStatus = val);
            },
          ),
          const SizedBox(height: 18),
          _buildDropdownField(
            label: 'Smoking Habits',
            value: _smoking,
            items: KnotLocationData.smokingOptions,
            onChanged: (val) {
              if (val != null) setState(() => _smoking = val);
            },
          ),
          const SizedBox(height: 18),
          _buildDropdownField(
            label: 'Drinking Habits',
            value: _drinking,
            items: KnotLocationData.drinkingOptions,
            onChanged: (val) {
              if (val != null) setState(() => _drinking = val);
            },
          ),
        ],
      ),
    );
  }

  // STEP 5: Future Partner Preferences & Marriage Plans
  Widget _buildPartnerPlansStep() {
    final List<String> prefResStates = <String>[
      'Any State/Province/Region',
      'Enter State/Province/Region',
      ...(KnotLocationData.statesByCountry[_prefResCountry] ?? const <String>[]),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Future Partner Plans', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text('Your vision for your intended partner.', style: AppTypography.bodySmall),
          const SizedBox(height: 20),

          // Partner Residence
          Text('FUTURE PARTNER RESIDENCE', style: AppTypography.titleMedium.copyWith(color: AppColors.champagneGold)),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Partner Country of Residence',
            value: _prefResCountry,
            items: ['Any Country', 'Enter Choice Country', ...KnotLocationData.countries],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _prefResCountry = val;
                  _prefResState = 'Any State/Province/Region';
                });
              }
            },
          ),
          if (_prefResCountry == 'Enter Choice Country') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _prefResCountryCustomController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'Type choice country'),
            ),
          ],
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'State / Province / Region',
            value: prefResStates.contains(_prefResState) ? _prefResState : prefResStates.first,
            items: prefResStates,
            onChanged: (val) {
              if (val != null) setState(() => _prefResState = val);
            },
          ),
          if (_prefResState == 'Enter State/Province/Region') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _prefResStateCustomController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'Type choice state/province/region'),
            ),
          ],

          const SizedBox(height: 24),

          // Partner Native Heritage
          Text('PARTNER NATIVE HERITAGE', style: AppTypography.titleMedium.copyWith(color: AppColors.champagneGold)),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Preferred Partner Heritage Country',
            value: _prefOriCountry,
            items: ['Any Country', 'Enter Choice Country', ...KnotLocationData.countries],
            onChanged: (val) {
              if (val != null) setState(() => _prefOriCountry = val);
            },
          ),
          if (_prefOriCountry == 'Enter Choice Country') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _prefOriCountryCustomController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'Type choice heritage country'),
            ),
          ],
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Native Heritage / Tribe / Ethno-Cultural Background',
            value: _prefOriState,
            items: const ['Any Heritage', 'Enter Native Heritage'],
            onChanged: (val) {
              if (val != null) setState(() => _prefOriState = val);
            },
          ),
          if (_prefOriState == 'Enter Native Heritage') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _prefOriCustomController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'e.g. Yoruba, Scottish, English, Catalan'),
            ),
          ],

          const SizedBox(height: 24),

          // Marriage Plans
          Text('MARRIAGE PLANS', style: AppTypography.titleMedium.copyWith(color: AppColors.champagneGold)),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Partner Children Status',
            value: _partnerChildrenStatus,
            items: KnotLocationData.partnerChildrenStatusOptions,
            onChanged: (val) {
              if (val != null) setState(() => _partnerChildrenStatus = val);
            },
          ),
          const SizedBox(height: 14),
          _buildDropdownField(
            label: 'Vow Timeline',
            value: _marriageTimeline,
            items: KnotLocationData.vowTimelineOptions,
            onChanged: (val) {
              if (val != null) setState(() => _marriageTimeline = val);
            },
          ),
          const SizedBox(height: 14),
          _buildDropdownField(
            label: 'Willing to Relocate?',
            value: _willingToRelocate,
            items: KnotLocationData.relocationOptions,
            onChanged: (val) {
              if (val != null) setState(() => _willingToRelocate = val);
            },
          ),
        ],
      ),
    );
  }

  // STEP 6: Family Goals, Traits & Expectations
  Widget _buildFamilyGoalsAndExpectationsStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Family Goals & Vision', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text('Expectations and alignment for lifelong marriage.', style: AppTypography.bodySmall),
          const SizedBox(height: 20),

          // Children Intent / Family Goals
          _buildDropdownField(
            label: 'Family Goal: Children Intent',
            value: _childrenIntent,
            items: KnotLocationData.childrenIntentOptions,
            onChanged: (val) {
              if (val != null) setState(() => _childrenIntent = val);
            },
          ),

          const SizedBox(height: 20),

          // Ideal Partner Traits
          _buildFieldLabel('Ideal Partner Traits'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: KnotLocationData.majorTraits.map((trait) {
              final isSelected = _idealPartnerTraits.contains(trait);
              return _buildChoiceChip(
                trait,
                isSelected,
                () {
                  setState(() {
                    if (isSelected) {
                      _idealPartnerTraits.remove(trait);
                    } else {
                      _idealPartnerTraits.add(trait);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_idealPartnerTraits.contains('Other')) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _otherTraitController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'Specify custom partner trait'),
            ),
          ],

          const SizedBox(height: 24),

          // Ideal Partner Age Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Ideal Partner Age Range'),
              Text(
                '${_partnerAgeRange.start.round()} - ${_partnerAgeRange.end.round()} yrs',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.champagneGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _partnerAgeRange,
            min: 18,
            max: 65,
            divisions: 47,
            activeColor: AppColors.champagneGold,
            inactiveColor: AppColors.darkSlate,
            labels: RangeLabels(
              '${_partnerAgeRange.start.round()}',
              '${_partnerAgeRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() => _partnerAgeRange = values);
            },
          ),

          const SizedBox(height: 20),

          // Marriage Expectations
          _buildFieldLabel('Marriage Expectations'),
          const SizedBox(height: 8),
          TextField(
            controller: _marriageExpectationsController,
            maxLines: 3,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(
              hintText: 'What are your core expectations for communication, commitment, and married life?',
            ),
          ),

          const SizedBox(height: 24),

          // Sacred Core Values
          _buildFieldLabel('Sacred Core Values'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCoreValues.map((v) {
              final isSelected = _selectedCoreValues.contains(v);
              return _buildChoiceChip(
                v,
                isSelected,
                () {
                  setState(() {
                    if (isSelected) {
                      _selectedCoreValues.remove(v);
                    } else {
                      _selectedCoreValues.add(v);
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

  // --- REUSABLE LUXURY UI HELPERS ---

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Deduplicate and ensure value exists in items
    final safeItems = items.toSet().toList();
    final safeValue = safeItems.contains(value) ? value : safeItems.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.darkCardElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              dropdownColor: AppColors.darkCardElevated,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.champagneGold),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              items: safeItems.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.champagneGold.withOpacity(0.18)
              : AppColors.darkCardElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.champagneGold : AppColors.borderSubtle,
            width: isSelected ? 1.4 : 1.0,
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
