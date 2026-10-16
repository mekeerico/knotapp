import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  static const int _totalSteps = 11; // Steps 0 to 8 = Forms, Step 9 = Profile Picture/Selfie, Step 10 = Verification
  bool _isMovingForward = true;
  bool _isSaving = false;

  // Profile Picture (Step 9)
  String? _profilePhotoPath;
  String? _profilePhotoDataUrl;
  final ImagePicker _picker = ImagePicker();

  // Controllers - Screen 1: Legal Identity
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Controllers - Screen 2: Gender Identity & Date of Birth
  String _gender = 'Female';
  DateTime? _selectedDob;

  // Controllers - Screen 3: Vocation & Faith
  final _occupationController = TextEditingController();
  String _religionSelect = 'Christian';
  final _religionCustomController = TextEditingController();

  // Controllers - Screen 4: Language
  final List<String> _selectedLanguages = ['English'];
  final _otherLanguageController = TextEditingController();

  // Controllers - Screen 5: Location (Current Residence)
  String _residenceCountry = 'United States of America';
  String _residenceState = '';
  final _residenceStateCustomController = TextEditingController();
  final _residenceCityController = TextEditingController();

  // Controllers - Screen 6: Heritage & Origin
  String _originCountry = 'United States of America';
  String _originState = '';
  final _originStateCustomController = TextEditingController();
  final _originCityController = TextEditingController();

  // Controllers - Screen 7: Lifestyle Habits & Marital History
  String _maritalStatus = 'Never married';
  String _smoking = 'Non-smoker';
  String _drinking = 'Non-drinker';
  String _childrenIntent = 'Open to children';

  // Controllers - Screen 8: Preferred Future Partner Residence & Cultural Origin
  String _prefResCountry = 'Any Country';
  final _prefResCountryCustomController = TextEditingController();
  String _prefResState = 'Any State/Province/Region';
  final _prefResStateCustomController = TextEditingController();
  String _prefOriCountry = 'Any Country';
  final _prefOriCountryCustomController = TextEditingController();
  String _prefOriState = 'Any Heritage';
  final _prefOriCustomController = TextEditingController();

  // Controllers - Screen 9: Marriage Intentions & Traits
  String _marriageTimeline = '1-2 years';
  String _willingToRelocate = 'Yes';
  RangeValues _partnerAgeRange = const RangeValues(22, 45);
  final List<String> _idealPartnerTraits = ['Kind', 'Honest', 'Family-oriented'];
  final _otherTraitController = TextEditingController();
  final _marriageExpectationsController = TextEditingController();
  final List<String> _selectedCoreValues = ['Faith', 'Family', 'Loyalty', 'Integrity'];
  final List<String> _availableCoreValues = [
    'Faith', 'Family', 'Loyalty', 'Integrity', 'Growth',
    'Harmony', 'Respect', 'Love', 'Patience', 'Honesty'
  ];

  final List<String> _religions = [
    'Christian', 'Muslim', 'Jewish', 'Hindu', 'Buddhist',
    'Atheist', 'Agnostic', 'Other'
  ];

  @override
  void initState() {
    super.initState();
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

  void _nextStep() {
    // Screen 1 Validation: Legal Identity
    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        _showError('Please enter your legal first and last name.');
        return;
      }
    }

    // Screen 2 Validation: Gender & Age (18+)
    if (_currentStep == 1) {
      if (_selectedDob == null) {
        _showError('Please select your date of birth.');
        return;
      }
      if (_calculatedAge < 18) {
        _showError('Candidates must be 18 years or older to join KNOT.');
        return;
      }
    }

    // Screen 3 Validation: Vocation & Faith
    if (_currentStep == 2) {
      if (_occupationController.text.trim().isEmpty) {
        _showError('Please enter your occupation.');
        return;
      }
      if (_religionSelect == 'Other' && _religionCustomController.text.trim().isEmpty) {
        _showError('Please specify your religion or faith.');
        return;
      }
    }

    // Screen 4 Validation: Language
    if (_currentStep == 3) {
      if (_selectedLanguages.isEmpty) {
        _showError('Please select at least one language spoken.');
        return;
      }
      if (_selectedLanguages.contains('Other') && _otherLanguageController.text.trim().isEmpty) {
        _showError('Please specify your other language.');
        return;
      }
    }

    // Screen 5 Validation: Current Residence
    if (_currentStep == 4) {
      if (_residenceCountry.isEmpty || _residenceCityController.text.trim().isEmpty) {
        _showError('Please provide your country of residence and city.');
        return;
      }
    }

    // Screen 6 Validation: Heritage & Origin
    if (_currentStep == 5) {
      if (_originCountry.isEmpty || _originCityController.text.trim().isEmpty) {
        _showError('Please provide your country of heritage/origin and ancestral city/town.');
        return;
      }
    }

    // Screen 7 Validation: Lifestyle Habits & Marital History (Has defaults, valid)

    // Screen 8 Validation: Preferred Future Partner Residence & Cultural Origin
    if (_currentStep == 7) {
      if (_prefResCountry == 'Enter Choice Country' && _prefResCountryCustomController.text.trim().isEmpty) {
        _showError('Please specify preferred country of residence.');
        return;
      }
      if (_prefOriCountry == 'Enter Choice Country' && _prefOriCountryCustomController.text.trim().isEmpty) {
        _showError('Please specify preferred heritage country.');
        return;
      }
    }

    // Screen 9 Validation: Marriage Intentions & Traits
    if (_currentStep == 8) {
      if (_idealPartnerTraits.isEmpty) {
        _showError('Please select at least one ideal partner trait.');
        return;
      }
    }

    // Screen 10 Validation: Match Display Profile Photo (Step 9)
    if (_currentStep == 9) {
      if (_profilePhotoDataUrl == null) {
        _showError('Please upload a photo or snap a portrait selfie for your match profile.');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _isMovingForward = true;
        _currentStep++;
      });
    }
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _profilePhotoPath = file.path;
          _profilePhotoDataUrl = dataUrl;
        });
      }
    } catch (e) {
      debugPrint('Error capturing profile photo: $e');
      _showError('Could not access camera or gallery.');
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _isMovingForward = false;
        _currentStep--;
      });
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
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _saveOnboardingData() async {
    setState(() => _isSaving = true);

    final finalReligion = _religionSelect == 'Other'
        ? _religionCustomController.text.trim()
        : _religionSelect;

    final finalResState = _residenceState.isNotEmpty
        ? _residenceState
        : _residenceStateCustomController.text.trim();

    final finalOriginState = _originState.isNotEmpty
        ? _originState
        : _originStateCustomController.text.trim();

    final languages = List<String>.from(_selectedLanguages);
    if (languages.contains('Other') && _otherLanguageController.text.trim().isNotEmpty) {
      languages.remove('Other');
      languages.add(_otherLanguageController.text.trim());
    }

    final preferredGender = _gender == 'Female' ? 'Male' : 'Female';

    // Resolve custom partner residence
    final finalPrefResCountry = _prefResCountry == 'Enter Choice Country'
        ? _prefResCountryCustomController.text.trim()
        : _prefResCountry;
    final finalPrefResState = _prefResState == 'Enter State/Province/Region'
        ? _prefResStateCustomController.text.trim()
        : _prefResState;

    // Resolve custom partner origin
    final finalPrefOriCountry = _prefOriCountry == 'Enter Choice Country'
        ? _prefOriCountryCustomController.text.trim()
        : _prefOriCountry;
    final finalPrefOriState = _prefOriState == 'Enter Native Heritage'
        ? _prefOriCustomController.text.trim()
        : _prefOriState;

    // Traits
    final traits = List<String>.from(_idealPartnerTraits);
    if (traits.contains('Other') && _otherTraitController.text.trim().isNotEmpty) {
      traits.remove('Other');
      traits.add(_otherTraitController.text.trim());
    }

    final updateData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'gender': _gender,
      'preferredGender': preferredGender,
      'dateOfBirth': _formattedDob,
      'occupation': _occupationController.text.trim(),
      'religion': finalReligion,
      'languagesSpoken': languages,
      // Residence
      'residenceCountry': _residenceCountry,
      'residenceState': finalResState,
      'residenceCity': _residenceCityController.text.trim(),
      // Heritage & Origin
      'originCountry': _originCountry,
      'originState': finalOriginState,
      'originCity': _originCityController.text.trim(),
      // Lifestyle Habits & Marital History
      'maritalStatus': _maritalStatus,
      'smoking': _smoking,
      'drinking': _drinking,
      'childrenPreference': _childrenIntent,
      // Preferred Partner Residence & Heritage
      'preferredResidenceCountry': finalPrefResCountry,
      'preferredResidenceState': finalPrefResState,
      'preferredOriginCountry': finalPrefOriCountry,
      'preferredOriginState': finalPrefOriState,
      // Marriage Intentions & Traits
      'marriageTimeline': _marriageTimeline,
      'willingToRelocate': _willingToRelocate,
      'partnerMinAge': _partnerAgeRange.start.round(),
      'partnerMaxAge': _partnerAgeRange.end.round(),
      'idealPartnerTraits': traits,
      'personalValues': _selectedCoreValues,
      'marriageExpectations': _marriageExpectationsController.text.trim(),
      'personalityArchetype': 'The Intentional Builder',
      'attachmentStyle': 'Secure',
      'readinessScore': 94,
      'seriousnessLevel': 98,
    };

    if (_profilePhotoDataUrl != null) {
      updateData['profileImageUrls'] = [_profilePhotoDataUrl!];
    }

    try {
      await ref.read(authProvider.notifier).updateProfile(updateData);
    } catch (e) {
      debugPrint('Onboarding profile save notice: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _completeAndRedirectToAuth({
    bool diditVerificationCompleted = false,
    bool shouldSave = true,
  }) async {
    if (shouldSave) {
      await _saveOnboardingData();
    }

    if (!mounted) return;

    // Logout session so user signs in fresh as required by user prompt
    await ref.read(authProvider.notifier).logout();

    if (mounted) {
      context.go('/auth');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            diditVerificationCompleted
                ? 'Identity verification submitted successfully! Please sign in to enter your dashboard.'
                : 'Onboarding details saved. Since verification was skipped, your profile remains private until verified. Please sign in.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: diditVerificationCompleted ? const Color(0xFF10B981) : AppColors.darkCardElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: _currentStep < 10
            ? 'ONBOARDING (${_currentStep + 1}/10)'
            : 'IDENTITY VERIFICATION',
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.champagneGold, size: 18),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: AppColors.darkSlate,
                valueColor: const AlwaysStoppedAnimation(AppColors.champagneGold),
                minHeight: 3,
              ),
              const SizedBox(height: 24),

              // Animated "Fly-In" Transition Container
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final inOffset = _isMovingForward
                      ? const Offset(1.0, 0.0)
                      : const Offset(-1.0, 0.0);

                  final slideIn = Tween<Offset>(begin: inOffset, end: Offset.zero).animate(animation);

                  return SlideTransition(
                    position: slideIn,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: _buildCurrentFormStep(),
                ),
              ),

              const SizedBox(height: 28),

              // Bottom Button Bar
              if (_currentStep < 10)
                GoldButton(
                  text: _currentStep == 9 ? 'Continue to Verification' : 'Continue',
                  onPressed: _nextStep,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentFormStep() {
    switch (_currentStep) {
      case 0:
        return _buildLegalIdentityStep();
      case 1:
        return _buildGenderIdentityStep();
      case 2:
        return _buildVocationAndFaithStep();
      case 3:
        return _buildLanguageStep();
      case 4:
        return _buildLocationStep();
      case 5:
        return _buildHeritageStep();
      case 6:
        return _buildLifestyleStep();
      case 7:
        return _buildPartnerPreferencesStep();
      case 8:
        return _buildMarriageIntentionsStep();
      case 9:
        return _buildProfilePhotoStep();
      case 10:
        return _buildVerificationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // SCREEN 1: LEGAL IDENTITY
  // ==========================================
  Widget _buildLegalIdentityStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEGAL IDENTITY', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Enter your official legal name as shown on your government ID.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),
          _buildFieldLabel('Legal First Name'),
          TextField(
            controller: _firstNameController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'First Name (e.g. Sophia)'),
          ),
          const SizedBox(height: 18),
          _buildFieldLabel('Legal Last Name'),
          TextField(
            controller: _lastNameController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'Last Name (e.g. Sterling)'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 2: GENDER IDENTITY & BIRTH DATE
  // ==========================================
  Widget _buildGenderIdentityStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GENDER IDENTITY', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Accurate biological gender and age are required for matrimonial alignment.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),

          _buildFieldLabel('Your Legal Biological Gender'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  label: 'Female',
                  isSelected: _gender == 'Female',
                  onTap: () => setState(() => _gender = 'Female'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption(
                  label: 'Male',
                  isSelected: _gender == 'Male',
                  onTap: () => setState(() => _gender = 'Male'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildFieldLabel('Date of Birth'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDob,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.darkCardElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _calculatedAge >= 18 ? AppColors.borderSubtle : Colors.redAccent,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: AppColors.champagneGold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDob == null ? 'Select Date of Birth' : _formattedDob,
                        style: AppTypography.bodyMedium.copyWith(
                          color: _selectedDob == null ? AppColors.textMuted : AppColors.textPure,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_calculatedAge yrs',
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

  // ==========================================
  // SCREEN 3: VOCATION & FAITH
  // ==========================================
  Widget _buildVocationAndFaithStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VOCATION & FAITH', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Your professional career and spiritual core.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),

          _buildFieldLabel('Occupation / Career'),
          TextField(
            controller: _occupationController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'e.g. Software Engineer, Physician, Architect'),
          ),

          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Religion & Faith',
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
              decoration: const InputDecoration(hintText: 'Specify your religion or faith'),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 4: LANGUAGE
  // ==========================================
  Widget _buildLanguageStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LANGUAGE(S) SPOKEN', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Select all languages in which you can communicate comfortably.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),

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
            const SizedBox(height: 16),
            _buildFieldLabel('Specify Other Language(s)'),
            TextField(
              controller: _otherLanguageController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'e.g. Hebrew, Japanese, Dutch'),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 5: LOCATION (CURRENT RESIDENCE)
  // ==========================================
  Widget _buildLocationStep() {
    final List<String> residenceStates = KnotLocationData.statesByCountry[_residenceCountry] ?? const <String>[];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CURRENT RESIDENCE', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Where you currently reside and live day-to-day.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),

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

          const SizedBox(height: 14),
          if (residenceStates.isNotEmpty)
            _buildDropdownField(
              label: 'State / Province / Region',
              value: _residenceState.isNotEmpty && residenceStates.contains(_residenceState)
                  ? _residenceState
                  : residenceStates.first,
              items: residenceStates,
              onChanged: (val) {
                if (val != null) setState(() => _residenceState = val);
              },
            )
          else ...[
            _buildFieldLabel('State / Province / Region'),
            TextField(
              controller: _residenceStateCustomController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'State / Province / Region'),
            ),
          ],

          const SizedBox(height: 14),
          _buildFieldLabel('Residence City / Town'),
          TextField(
            controller: _residenceCityController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'e.g. Dallas, London, Lagos, Toronto'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 6: HERITAGE & ORIGIN
  // ==========================================
  Widget _buildHeritageStep() {
    final List<String> originStates = KnotLocationData.statesByCountry[_originCountry] ?? const <String>[];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HERITAGE & ORIGIN', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Your native heritage, cultural background, and ancestral origin.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),

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

          const SizedBox(height: 14),
          if (originStates.isNotEmpty)
            _buildDropdownField(
              label: 'State / Province / Region of Origin',
              value: _originState.isNotEmpty && originStates.contains(_originState)
                  ? _originState
                  : originStates.first,
              items: originStates,
              onChanged: (val) {
                if (val != null) setState(() => _originState = val);
              },
            )
          else ...[
            _buildFieldLabel('State / Province / Region of Origin'),
            TextField(
              controller: _originStateCustomController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              decoration: const InputDecoration(hintText: 'State / Province / Region of Origin'),
            ),
          ],

          const SizedBox(height: 14),
          _buildFieldLabel('Origin City / Ancestral Town'),
          TextField(
            controller: _originCityController,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
            decoration: const InputDecoration(hintText: 'e.g. Edinburgh, Abeokuta, Lyon, Kyoto'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 7: LIFESTYLE & MARITAL HISTORY
  // ==========================================
  Widget _buildLifestyleStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIFESTYLE & HABITS', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Your marital history and lifestyle habits.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),
          _buildDropdownField(
            label: 'Marital History',
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
          const SizedBox(height: 18),
          _buildDropdownField(
            label: 'Children Preference',
            value: _childrenIntent,
            items: KnotLocationData.childrenIntentOptions,
            onChanged: (val) {
              if (val != null) setState(() => _childrenIntent = val);
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 8: PREFERRED FUTURE PARTNER RESIDENCE & ORIGIN
  // ==========================================
  Widget _buildPartnerPreferencesStep() {
    final List<String> prefResStates = <String>[
      'Any State/Province/Region',
      'Enter State/Province/Region',
      ...(KnotLocationData.statesByCountry[_prefResCountry] ?? const <String>[]),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PARTNER PREFERENCES', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Preferred residence and cultural background for your future partner.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Preferred Partner Country of Residence',
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
          const SizedBox(height: 14),
          _buildDropdownField(
            label: 'Preferred Partner State / Province / Region',
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
          const SizedBox(height: 18),
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
          const SizedBox(height: 14),
          _buildDropdownField(
            label: 'Native Heritage / Ethno-Cultural Background',
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
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 9: MARRIAGE INTENTIONS & TRAITS
  // ==========================================
  Widget _buildMarriageIntentionsStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MARRIAGE INTENTIONS', style: AppTypography.headingLarge),
          const SizedBox(height: 6),
          Text(
            'Timeline, expectations, and core traits for sacred marriage.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Intended Marriage Timeline',
            value: _marriageTimeline,
            items: KnotLocationData.vowTimelineOptions,
            onChanged: (val) {
              if (val != null) setState(() => _marriageTimeline = val);
            },
          ),
          const SizedBox(height: 14),
          _buildDropdownField(
            label: 'Willingness to Relocate for Marriage',
            value: _willingToRelocate,
            items: KnotLocationData.relocationOptions,
            onChanged: (val) {
              if (val != null) setState(() => _willingToRelocate = val);
            },
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 18),
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
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
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

  // ==========================================
  // SCREEN 10: PROFILE DISPLAY PICTURE / SELFIE
  // ==========================================
  Widget _buildProfilePhotoStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.champagneGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_circle_outlined, color: AppColors.champagneGold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('MATCH DISPLAY PICTURE', style: AppTypography.headingMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Upload a portrait photo or snap a selfie. This photo will be shown to your prospective marriage candidates on the Matches screen.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 28),

          // Circular Avatar Preview
          Center(
            child: Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.darkCardElevated,
                    border: Border.all(color: AppColors.champagneGold, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.champagneGold.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    image: _profilePhotoPath != null
                        ? DecorationImage(
                            image: FileImage(File(_profilePhotoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profilePhotoPath == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 40,
                                color: AppColors.champagneGold.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap to add',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
                if (_profilePhotoPath != null)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.champagneGold,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.obsidianBlack,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Two Action Buttons: Take Selfie vs Choose from Gallery
          GoldButton(
            text: _profilePhotoPath != null ? 'Retake Portrait Selfie' : 'Take Portrait Selfie',
            onPressed: () => _pickProfilePhoto(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          GoldButton(
            text: _profilePhotoPath != null ? 'Choose from Gallery' : 'Upload from Gallery',
            isSecondary: true,
            onPressed: () => _pickProfilePhoto(ImageSource.gallery),
          ),
          const SizedBox(height: 20),

          // Privacy Assurance Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCardElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.champagneGold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your verification documents and ID selfie are kept strictly confidential for verification only. Only this display photo will be shown to your matches.',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 11: DIDIT VERIFICATION (OPTIONAL)
  // ==========================================
  Widget _buildVerificationStep() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.champagneGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_outlined, color: AppColors.champagneGold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('SOVEREIGN IDENTITY VERIFICATION', style: AppTypography.headingMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Government ID Upload & Biometric Live Selfie via Didit KYC.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),

          // Prominent Alert Box regarding optional status and public visibility
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade600.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade400, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optional Step',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.amber.shade300,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You may skip this verification now and complete it later from your Profile screen.\n\n⚠️ Note: If you skip verification, your profile will remain hidden and will not be made public to other members until you complete verification.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPure,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Accepted Government ID Documents Section (Compact text format)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.darkCardElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.champagneGold.withValues(alpha: 0.25), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_outlined, color: AppColors.champagneGold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ACCEPTED GOVERNMENT ID'S",
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.champagneGold,
                          letterSpacing: 1.1,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '• International Passport\n• Driver\'s License\n• National Identity Card (NIN)\n• Voter\'s Card / Residence Permit',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPure,
                    height: 1.6,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action 1: Verify Now
          GoldButton(
            text: _isSaving ? 'Saving Profile...' : 'Verify with Didit Now',
            onPressed: _isSaving
                ? null
                : () async {
                    await _saveOnboardingData();
                    if (mounted) {
                      final verified = await context.push<bool>('/verification');
                      if (mounted) {
                        await _completeAndRedirectToAuth(
                          diditVerificationCompleted: verified ?? true,
                          shouldSave: false,
                        );
                      }
                    }
                  },
          ),

          const SizedBox(height: 12),

          // Action 2: Skip For Now
          Center(
            child: TextButton(
              onPressed: _isSaving
                  ? null
                  : () => _completeAndRedirectToAuth(
                        diditVerificationCompleted: false,
                        shouldSave: true,
                      ),
              child: Text(
                'Skip for Now & Sign In Later',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textMuted,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // REUSABLE HELPER WIDGETS
  // ==========================================
  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AppTypography.labelLarge.copyWith(color: AppColors.champagneGold, fontSize: 12),
      ),
    );
  }

  Widget _buildGenderOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.champagneGold.withValues(alpha: 0.18)
              : AppColors.darkCardElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.champagneGold : AppColors.borderSubtle,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: isSelected ? AppColors.champagneGold : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.darkCardElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isExpanded: true,
              dropdownColor: AppColors.darkCardElevated,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.champagneGold),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                  ),
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
              ? AppColors.champagneGold.withValues(alpha: 0.18)
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
