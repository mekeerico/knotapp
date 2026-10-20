class MatchProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String city;
  final String residenceState;
  final String country;
  final String originCity;
  final String originState;
  final String originCountry;
  final String preferredResidenceCountry;
  final String preferredResidenceState;
  final String preferredOriginCountry;
  final String preferredOriginState;
  final String occupation;
  final String education;
  final String religion;
  final String culturalBackground;
  final List<String> languagesSpoken;
  final String maritalStatus;
  final String childrenStatus;
  final String smoking;
  final String drinking;
  final String marriageTimeline;
  final String willingToRelocate;
  final String childrenPreference;
  final String marriageExpectations;
  final String careerGoals;
  final String bio;
  final List<String> personalValues;
  final List<String> idealPartnerTraits;
  final String personalityArchetype;
  final String attachmentStyle;
  final int compatibilityScore;
  final int emotionalAlignment;
  final int communicationStyle;
  final int valuesAlignment;
  final int lifestyleCompatibility;
  final int trustScore;
  final String aiExplanation;
  final bool isVerified;
  final String verificationBadge;
  final List<String> photos;

  MatchProfile({
    required this.id,
    required this.name,
    required this.age,
    this.gender = '',
    required this.city,
    this.residenceState = '',
    required this.country,
    this.originCity = '',
    this.originState = '',
    this.originCountry = '',
    this.preferredResidenceCountry = 'Any Country',
    this.preferredResidenceState = 'Any State/Province/Region',
    this.preferredOriginCountry = 'Any Country',
    this.preferredOriginState = 'Any Heritage',
    required this.occupation,
    this.education = 'University Degree',
    this.religion = 'Christian',
    this.culturalBackground = '',
    this.languagesSpoken = const ['English'],
    this.maritalStatus = 'Never married',
    this.childrenStatus = 'No kids',
    this.smoking = 'Non-smoker',
    this.drinking = 'Non-drinker',
    this.marriageTimeline = '1-2 years',
    this.willingToRelocate = 'Yes',
    this.childrenPreference = 'Open to children',
    this.marriageExpectations = '',
    this.careerGoals = '',
    this.bio = 'Devoted to personal growth, intentional living, and building a lifelong marriage.',
    this.personalValues = const ['Faith', 'Family', 'Integrity', 'Ambition'],
    this.idealPartnerTraits = const ['Kind', 'Honest', 'Family-oriented'],
    this.personalityArchetype = 'The Intentional Builder',
    this.attachmentStyle = 'Secure',
    this.compatibilityScore = 92,
    this.emotionalAlignment = 89,
    this.communicationStyle = 91,
    this.valuesAlignment = 95,
    this.lifestyleCompatibility = 91,
    this.trustScore = 95,
    this.aiExplanation =
        'Strong synergy in permanent family orientation, communication integrity, and shared marriage timeline.',
    this.isVerified = true,
    this.verificationBadge = 'GOLD',
    required this.photos,
  });

  static int _parseAge(dynamic ageVal, dynamic dobVal) {
    if (ageVal is num && ageVal > 17 && ageVal < 100) {
      return ageVal.toInt();
    }
    final dobStr = dobVal?.toString().trim() ?? '';
    if (dobStr.isNotEmpty) {
      final parsed = DateTime.tryParse(dobStr);
      if (parsed != null) {
        final now = DateTime.now();
        int age = now.year - parsed.year;
        if (now.month < parsed.month || (now.month == parsed.month && now.day < parsed.day)) {
          age--;
        }
        if (age >= 18 && age < 100) return age;
      }
      final yearMatch = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(dobStr);
      if (yearMatch != null) {
        final birthYear = int.tryParse(yearMatch.group(1)!);
        if (birthYear != null) {
          final age = DateTime.now().year - birthYear;
          if (age >= 18 && age < 100) return age;
        }
      }
    }
    return 27;
  }

  static String _nonEmpty(dynamic primary, [String fallback = '']) {
    final s = primary?.toString().trim() ?? '';
    return s.isNotEmpty ? s : fallback;
  }

  static List<String> _parseStringList(dynamic raw, List<String> fallback) {
    if (raw is List) {
      final list = raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
    return fallback;
  }

  static String _resolveGender(Map<String, dynamic> partner, Map<String, dynamic> root) {
    final direct = _nonEmpty(partner['gender'], _nonEmpty(root['gender'], _nonEmpty(partner['sex'], _nonEmpty(root['sex']))));
    if (direct.isNotEmpty) return direct;

    final pref = _nonEmpty(partner['preferredGender'], _nonEmpty(root['preferredGender'])).toLowerCase();
    if (pref == 'male' || pref == 'man' || pref == 'm') return 'Female';
    if (pref == 'female' || pref == 'woman' || pref == 'f') return 'Male';

    final name = _nonEmpty(partner['firstName'], _nonEmpty(partner['name'], _nonEmpty(root['name']))).toLowerCase();
    const maleNames = ['michael', 'alex', 'david', 'john', 'james', 'daniel', 'liam', 'chen', 'robert', 'william', 'joseph', 'charles', 'thomas', 'christopher', 'matthew', 'anthony', 'mark', 'steven', 'paul', 'andrew', 'joshua', 'kevin', 'brian', 'george', 'edward', 'jason', 'ryan', 'jacob', 'nicholas', 'eric', 'jonathan', 'stephen', 'justin', 'brandon', 'benjamin', 'samuel', 'alexander', 'patrick', 'jack', 'tyler', 'aaron', 'adam', 'nathan', 'henry', 'zachary', 'peter', 'kyle', 'ethan', 'jeremy', 'christian', 'noah', 'sean', 'austin', 'arthur', 'jesse', 'dylan', 'bryan', 'jordan', 'gabriel', 'logan', 'alan', 'juan', 'vincent', 'louis', 'philip', 'bradley'];
    const femaleNames = ['sarah', 'emily', 'sophia', 'zainab', 'priya', 'amina', 'chloe', 'emma', 'olivia', 'ava', 'isabella', 'mia', 'charlotte', 'amelia', 'harper', 'evelyn', 'abigail', 'elizabeth', 'sofia', 'avery', 'ella', 'scarlett', 'grace', 'victoria', 'riley', 'aria', 'lily', 'aubrey', 'zoey', 'penelope', 'layla', 'lillian', 'nora', 'camila', 'hannah', 'mila', 'eleanor', 'maya', 'stella', 'hazel', 'leah', 'violet', 'aurora', 'savannah', 'audrey', 'brooklyn', 'claire', 'skylar', 'ellie', 'lucy', 'anna', 'caroline', 'nova', 'genesis', 'emilia', 'kennedy', 'samantha', 'allison', 'madelyn', 'adeline', 'hailey', 'elena', 'cora', 'vivian', 'natalie', 'zoe', 'katelyn', 'fatima', 'aisha', 'maryam', 'khadija', 'nour', 'huda', 'yasmin', 'iman', 'asma', 'mariam'];

    final firstWord = name.split(' ').first.toLowerCase();
    if (maleNames.contains(firstWord)) return 'Male';
    if (femaleNames.contains(firstWord)) return 'Female';

    return '';
  }

  factory MatchProfile.fromJson(Map<String, dynamic> json) {
    // If backend wrapped match in { matchId, partner, scores }, unwrap partner!
    final partner = json['partner'] is Map<String, dynamic>
        ? json['partner'] as Map<String, dynamic>
        : json;
    final scores = json['scores'] is Map<String, dynamic>
        ? json['scores'] as Map<String, dynamic>
        : json;

    List<String> photoList = [];
    if (partner['profileImages'] is List) {
      final sorted = [...(partner['profileImages'] as List)];
      sorted.sort((a, b) =>
          ((b is Map && b['isPrimary'] == true) ? 1 : 0) -
          ((a is Map && a['isPrimary'] == true) ? 1 : 0));
      photoList = sorted
          .map((img) => (img is Map ? img['url'] : img).toString().trim())
          .where((u) => u.isNotEmpty)
          .toList();
    } else if (partner['profileImageUrls'] is List) {
      photoList = (partner['profileImageUrls'] as List)
          .map((e) => e.toString().trim())
          .where((u) => u.isNotEmpty)
          .toList();
    } else if (partner['photoUrls'] is List) {
      photoList = (partner['photoUrls'] as List)
          .map((e) => e.toString().trim())
          .where((u) => u.isNotEmpty)
          .toList();
    }

    // Resolve relative /uploads/ URLs to absolute URLs using API base domain
    const apiBase = String.fromEnvironment('API_URL', defaultValue: 'http://knotconnect.duckdns.org:8080');
    photoList = photoList.map((url) {
      if (url.startsWith('/uploads/')) {
        return '$apiBase$url';
      }
      return url;
    }).toList();

    if (photoList.isEmpty) {
      photoList = [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800',
      ];
    }

    final firstName = partner['firstName']?.toString().trim() ?? '';
    final lastName = partner['lastName']?.toString().trim() ?? '';
    final fullName = _nonEmpty(
      partner['name'],
      firstName.isNotEmpty ? '$firstName $lastName'.trim() : 'Candidate',
    );

    final residenceCity = _nonEmpty(partner['city'], _nonEmpty(partner['residenceCity'], 'London'));
    final residenceState = _nonEmpty(partner['residenceState']);
    final residenceCountry = _nonEmpty(partner['country'], _nonEmpty(partner['residenceCountry'], 'United Kingdom'));

    final originCountry = _nonEmpty(partner['originCountry'], residenceCountry);
    final originState = _nonEmpty(partner['originState']);
    final originCity = _nonEmpty(partner['originCity']);

    final preferredResidenceCountry = _nonEmpty(
      partner['preferredResidenceCountry'],
      'Any Country',
    );
    final preferredResidenceState = _nonEmpty(
      partner['preferredResidenceState'],
      'Any State/Province/Region',
    );
    final preferredOriginCountry = _nonEmpty(
      partner['preferredOriginCountry'],
      'Any Country',
    );
    final preferredOriginState = _nonEmpty(
      partner['preferredOriginState'],
      'Any Heritage',
    );

    return MatchProfile(
      id: _nonEmpty(partner['id'], _nonEmpty(json['matchId'])),
      name: fullName,
      age: _parseAge(partner['age'], partner['dateOfBirth']),
      gender: _resolveGender(partner, json),
      city: residenceCity,
      residenceState: residenceState,
      country: residenceCountry,
      originCity: originCity,
      originState: originState,
      originCountry: originCountry,
      preferredResidenceCountry: preferredResidenceCountry,
      preferredResidenceState: preferredResidenceState,
      preferredOriginCountry: preferredOriginCountry,
      preferredOriginState: preferredOriginState,
      occupation: _nonEmpty(partner['occupation'], 'Professional'),
      education: _nonEmpty(partner['education']),
      religion: _nonEmpty(partner['religion'], 'Christian'),
      culturalBackground: _nonEmpty(partner['culturalBackground']),
      languagesSpoken: _parseStringList(partner['languagesSpoken'], const ['English']),
      maritalStatus: _nonEmpty(partner['maritalStatus'], 'Never married'),
      childrenStatus: _nonEmpty(partner['childrenStatus'], 'No kids'),
      smoking: _nonEmpty(partner['smoking'], 'Non-smoker'),
      drinking: _nonEmpty(partner['drinking'], 'Non-drinker'),
      marriageTimeline: _nonEmpty(partner['marriageTimeline'], '1-2 years'),
      willingToRelocate: _nonEmpty(partner['willingToRelocate'], 'Open to relocation'),
      childrenPreference: _nonEmpty(partner['childrenPreference'], 'Open to children'),
      marriageExpectations: _nonEmpty(partner['marriageExpectations']),
      careerGoals: _nonEmpty(partner['careerGoals']),
      bio: _nonEmpty(
        partner['bio'],
        'Intentional candidate seeking a covenant marriage built on shared values, emotional safety, and mutual growth.',
      ),
      personalValues: _parseStringList(
        partner['personalValues'],
        const ['Faith', 'Family', 'Integrity'],
      ),
      idealPartnerTraits: _parseStringList(
        partner['idealPartnerTraits'],
        const ['Kind', 'Honest', 'Family-oriented'],
      ),
      personalityArchetype: _nonEmpty(partner['personalityArchetype'], 'The Intentional Builder'),
      attachmentStyle: _nonEmpty(partner['attachmentStyle'], 'Secure'),
      compatibilityScore: (scores['compatibilityScore'] ?? partner['compatibilityScore'] ?? json['compatibilityScore'] ?? 92) is num
          ? ((scores['compatibilityScore'] ?? partner['compatibilityScore'] ?? json['compatibilityScore'] ?? 92) as num).toInt()
          : 92,
      emotionalAlignment: (scores['emotionalAlignment'] ?? partner['emotionalAlignment'] ?? 88) is num
          ? ((scores['emotionalAlignment'] ?? partner['emotionalAlignment'] ?? 88) as num).toInt()
          : 88,
      communicationStyle: (scores['communicationStyle'] ?? partner['communicationStyle'] ?? 90) is num
          ? ((scores['communicationStyle'] ?? partner['communicationStyle'] ?? 90) as num).toInt()
          : 90,
      valuesAlignment: (scores['valuesAlignment'] ?? partner['valuesAlignment'] ?? 94) is num
          ? ((scores['valuesAlignment'] ?? partner['valuesAlignment'] ?? 94) as num).toInt()
          : 94,
      lifestyleCompatibility: (scores['lifestyleCompatibility'] ?? partner['lifestyleCompatibility'] ?? 90) is num
          ? ((scores['lifestyleCompatibility'] ?? partner['lifestyleCompatibility'] ?? 90) as num).toInt()
          : 90,
      trustScore: (partner['trustScore'] ?? 95) is num
          ? (partner['trustScore'] as num).toInt()
          : 95,
      aiExplanation: _nonEmpty(
        json['aiExplanation'],
        _nonEmpty(
          partner['aiExplanation'],
          'High emotional safety and mutual vision for permanent family building.',
        ),
      ),
      isVerified: partner['isVerified'] == true || partner['idVerified'] == true,
      verificationBadge: _nonEmpty(partner['verificationBadge'], 'GOLD'),
      photos: photoList,
    );
  }
}
