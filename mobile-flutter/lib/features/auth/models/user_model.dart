class UserModel {
  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String gender;
  final String preferredGender;
  final String dateOfBirth;
  final String bio;
  final String occupation;
  final String education;
  final String religion;
  final String culturalBackground;
  final List<String> languagesSpoken;
  
  // Lifestyle & Commitment
  final String smoking;
  final String drinking;
  final String maritalStatus;
  final String childrenStatus;
  final String marriageTimeline;
  final String willingToRelocate;
  final String childrenPreference;
  final List<String> idealPartnerTraits;
  final List<String> personalValues;
  final String marriageExpectations;
  final String careerGoals;

  // Location
  final String residenceCountry;
  final String residenceState;
  final String residenceCity;
  final String originCountry;
  final String originState;
  final String originCity;
  final String preferredResidenceCountry;
  final String preferredResidenceState;
  final String preferredResidenceCity;
  final String preferredOriginCountry;
  final String preferredOriginState;
  final String preferredOriginCity;

  // AI Indices
  final String? personalityArchetype;
  final String? attachmentStyle;
  final int readinessScore;
  final int seriousnessLevel;
  final int trustScore;

  // Verification & Status
  final bool isVerified;
  final String? verifiedAt;
  final String? verificationBadge;
  final int? verificationScore;
  final bool idVerified;
  final bool selfieVerified;
  final String? selfieUrl;
  final bool isPremium;
  final String subscriptionTier;
  final List<String> profileImageUrls;

  UserModel({
    required this.id,
    required this.email,
    this.role = 'USER',
    this.firstName = '',
    this.lastName = '',
    this.gender = '',
    this.preferredGender = '',
    this.dateOfBirth = '',
    this.bio = '',
    this.occupation = '',
    this.education = '',
    this.religion = '',
    this.culturalBackground = '',
    this.languagesSpoken = const [],
    this.smoking = 'Non-smoker',
    this.drinking = 'Never',
    this.maritalStatus = 'Never Married',
    this.childrenStatus = 'No kids',
    this.marriageTimeline = 'ASAP',
    this.willingToRelocate = 'Maybe',
    this.childrenPreference = 'Open to children',
    this.idealPartnerTraits = const [],
    this.personalValues = const [],
    this.marriageExpectations = '',
    this.careerGoals = '',
    this.residenceCountry = '',
    this.residenceState = '',
    this.residenceCity = '',
    this.originCountry = '',
    this.originState = '',
    this.originCity = '',
    this.preferredResidenceCountry = '',
    this.preferredResidenceState = '',
    this.preferredResidenceCity = '',
    this.preferredOriginCountry = '',
    this.preferredOriginState = '',
    this.preferredOriginCity = '',
    this.personalityArchetype,
    this.attachmentStyle,
    this.readinessScore = 0,
    this.seriousnessLevel = 0,
    this.trustScore = 60,
    this.isVerified = false,
    this.verifiedAt,
    this.verificationBadge = 'GOLD',
    this.verificationScore = 0,
    this.idVerified = false,
    this.selfieVerified = false,
    this.selfieUrl,
    this.isPremium = false,
    this.subscriptionTier = 'Essential',
    this.profileImageUrls = const [],
  });

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return 'Candidate';
    return '$firstName $lastName'.trim();
  }

  int get age {
    if (dateOfBirth.isEmpty) return 26;
    try {
      final dob = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age > 0 ? age : 26;
    } catch (_) {
      return 26;
    }
  }

  String get primaryPhoto {
    String? raw;
    if (profileImageUrls.isNotEmpty) {
      raw = profileImageUrls.first;
    }
    if (raw != null && raw.isNotEmpty) {
      if (raw.startsWith('/uploads/')) {
        const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://knotconnect.duckdns.org:8080');
        return '$baseUrl$raw';
      }
      return raw;
    }
    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['profileImages'] is List) {
      images = (json['profileImages'] as List)
          .map((img) => (img is Map ? img['url'] : img).toString())
          .toList();
    } else if (json['profileImageUrls'] is List) {
      images = (json['profileImageUrls'] as List).map((e) => e.toString()).toList();
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      preferredGender: json['preferredGender']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      occupation: json['occupation']?.toString() ?? '',
      education: json['education']?.toString() ?? '',
      religion: json['religion']?.toString() ?? '',
      culturalBackground: json['culturalBackground']?.toString() ?? '',
      languagesSpoken: (json['languagesSpoken'] as List?)?.map((e) => e.toString()).toList() ?? [],
      smoking: json['smoking']?.toString() ?? 'Non-smoker',
      drinking: json['drinking']?.toString() ?? 'Never',
      maritalStatus: json['maritalStatus']?.toString() ?? 'Never Married',
      childrenStatus: json['childrenStatus']?.toString() ?? 'No kids',
      marriageTimeline: json['marriageTimeline']?.toString() ?? 'ASAP',
      willingToRelocate: json['willingToRelocate']?.toString() ?? 'Maybe',
      childrenPreference: json['childrenPreference']?.toString() ?? 'Open to children',
      idealPartnerTraits: (json['idealPartnerTraits'] as List?)?.map((e) => e.toString()).toList() ?? [],
      personalValues: (json['personalValues'] as List?)?.map((e) => e.toString()).toList() ?? [],
      marriageExpectations: json['marriageExpectations']?.toString() ?? '',
      careerGoals: json['careerGoals']?.toString() ?? '',
      residenceCountry: json['residenceCountry']?.toString() ?? '',
      residenceState: json['residenceState']?.toString() ?? '',
      residenceCity: json['residenceCity']?.toString() ?? '',
      originCountry: json['originCountry']?.toString() ?? '',
      originState: json['originState']?.toString() ?? '',
      originCity: json['originCity']?.toString() ?? '',
      preferredResidenceCountry: json['preferredResidenceCountry']?.toString() ?? '',
      preferredResidenceState: json['preferredResidenceState']?.toString() ?? '',
      preferredResidenceCity: json['preferredResidenceCity']?.toString() ?? '',
      preferredOriginCountry: json['preferredOriginCountry']?.toString() ?? '',
      preferredOriginState: json['preferredOriginState']?.toString() ?? '',
      preferredOriginCity: json['preferredOriginCity']?.toString() ?? '',
      personalityArchetype: json['personalityArchetype']?.toString(),
      attachmentStyle: json['attachmentStyle']?.toString(),
      readinessScore: json['readinessScore'] is num ? (json['readinessScore'] as num).toInt() : 0,
      seriousnessLevel: json['seriousnessLevel'] is num ? (json['seriousnessLevel'] as num).toInt() : 0,
      trustScore: json['trustScore'] is num ? (json['trustScore'] as num).toInt() : 60,
      isVerified: json['isVerified'] == true,
      verifiedAt: json['verifiedAt']?.toString(),
      verificationBadge: json['verificationBadge']?.toString() ?? 'GOLD',
      verificationScore: json['verificationScore'] is num ? (json['verificationScore'] as num).toInt() : 0,
      idVerified: json['idVerified'] == true,
      selfieVerified: json['selfieVerified'] == true,
      selfieUrl: json['selfieUrl']?.toString(),
      isPremium: json['isPremium'] == true,
      subscriptionTier: json['subscriptionTier']?.toString() ?? 'Essential',
      profileImageUrls: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'preferredGender': preferredGender,
      'dateOfBirth': dateOfBirth,
      'bio': bio,
      'occupation': occupation,
      'education': education,
      'religion': religion,
      'culturalBackground': culturalBackground,
      'languagesSpoken': languagesSpoken,
      'smoking': smoking,
      'drinking': drinking,
      'maritalStatus': maritalStatus,
      'childrenStatus': childrenStatus,
      'marriageTimeline': marriageTimeline,
      'willingToRelocate': willingToRelocate,
      'childrenPreference': childrenPreference,
      'idealPartnerTraits': idealPartnerTraits,
      'personalValues': personalValues,
      'marriageExpectations': marriageExpectations,
      'careerGoals': careerGoals,
      'residenceCountry': residenceCountry,
      'residenceState': residenceState,
      'residenceCity': residenceCity,
      'originCountry': originCountry,
      'originState': originState,
      'originCity': originCity,
      'preferredResidenceCountry': preferredResidenceCountry,
      'preferredResidenceState': preferredResidenceState,
      'preferredResidenceCity': preferredResidenceCity,
      'preferredOriginCountry': preferredOriginCountry,
      'preferredOriginState': preferredOriginState,
      'preferredOriginCity': preferredOriginCity,
      'personalityArchetype': personalityArchetype,
      'attachmentStyle': attachmentStyle,
      'readinessScore': readinessScore,
      'seriousnessLevel': seriousnessLevel,
      'trustScore': trustScore,
      'isVerified': isVerified,
      'verifiedAt': verifiedAt,
      'verificationBadge': verificationBadge,
      'verificationScore': verificationScore,
      'idVerified': idVerified,
      'selfieVerified': selfieVerified,
      'selfieUrl': selfieUrl,
      'isPremium': isPremium,
      'subscriptionTier': subscriptionTier,
      'profileImageUrls': profileImageUrls,
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? gender,
    String? preferredGender,
    String? dateOfBirth,
    String? bio,
    String? occupation,
    String? education,
    String? religion,
    String? culturalBackground,
    List<String>? languagesSpoken,
    String? smoking,
    String? drinking,
    String? maritalStatus,
    String? childrenStatus,
    String? marriageTimeline,
    String? willingToRelocate,
    String? childrenPreference,
    List<String>? idealPartnerTraits,
    List<String>? personalValues,
    String? marriageExpectations,
    String? careerGoals,
    String? residenceCountry,
    String? residenceState,
    String? residenceCity,
    String? originCountry,
    String? originState,
    String? originCity,
    String? personalityArchetype,
    String? attachmentStyle,
    int? readinessScore,
    int? seriousnessLevel,
    int? trustScore,
    bool? isVerified,
    String? verifiedAt,
    String? verificationBadge,
    int? verificationScore,
    bool? idVerified,
    bool? selfieVerified,
    String? selfieUrl,
    bool? isPremium,
    String? subscriptionTier,
    List<String>? profileImageUrls,
  }) {
    return UserModel(
      id: id,
      email: email,
      role: role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      preferredGender: preferredGender ?? this.preferredGender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bio: bio ?? this.bio,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      religion: religion ?? this.religion,
      culturalBackground: culturalBackground ?? this.culturalBackground,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      smoking: smoking ?? this.smoking,
      drinking: drinking ?? this.drinking,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      childrenStatus: childrenStatus ?? this.childrenStatus,
      marriageTimeline: marriageTimeline ?? this.marriageTimeline,
      willingToRelocate: willingToRelocate ?? this.willingToRelocate,
      childrenPreference: childrenPreference ?? this.childrenPreference,
      idealPartnerTraits: idealPartnerTraits ?? this.idealPartnerTraits,
      personalValues: personalValues ?? this.personalValues,
      marriageExpectations: marriageExpectations ?? this.marriageExpectations,
      careerGoals: careerGoals ?? this.careerGoals,
      residenceCountry: residenceCountry ?? this.residenceCountry,
      residenceState: residenceState ?? this.residenceState,
      residenceCity: residenceCity ?? this.residenceCity,
      originCountry: originCountry ?? this.originCountry,
      originState: originState ?? this.originState,
      originCity: originCity ?? this.originCity,
      personalityArchetype: personalityArchetype ?? this.personalityArchetype,
      attachmentStyle: attachmentStyle ?? this.attachmentStyle,
      readinessScore: readinessScore ?? this.readinessScore,
      seriousnessLevel: seriousnessLevel ?? this.seriousnessLevel,
      trustScore: trustScore ?? this.trustScore,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      verificationScore: verificationScore ?? this.verificationScore,
      idVerified: idVerified ?? this.idVerified,
      selfieVerified: selfieVerified ?? this.selfieVerified,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      isPremium: isPremium ?? this.isPremium,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      profileImageUrls: profileImageUrls ?? this.profileImageUrls,
    );
  }
}
