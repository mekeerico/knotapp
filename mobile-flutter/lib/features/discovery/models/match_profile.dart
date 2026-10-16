class MatchProfile {
  final String id;
  final String name;
  final int age;
  final String city;
  final String country;
  final String occupation;
  final String education;
  final String religion;
  final String culturalBackground;
  final String marriageTimeline;
  final String willingToRelocate;
  final String childrenPreference;
  final String bio;
  final List<String> personalValues;
  final String personalityArchetype;
  final String attachmentStyle;
  final int compatibilityScore;
  final int emotionalAlignment;
  final int valuesAlignment;
  final int lifestyleCompatibility;
  final String aiExplanation;
  final bool isVerified;
  final String verificationBadge;
  final List<String> photos;

  MatchProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.country,
    required this.occupation,
    this.education = 'University Degree',
    this.religion = 'Christian',
    this.culturalBackground = 'Global Heritage',
    this.marriageTimeline = '1-2 years',
    this.willingToRelocate = 'Yes',
    this.childrenPreference = 'Open to children',
    this.bio = 'Devoted to personal growth, intentional living, and building a lifelong marriage.',
    this.personalValues = const ['Faith', 'Family', 'Integrity', 'Ambition'],
    this.personalityArchetype = 'The Intentional Builder',
    this.attachmentStyle = 'Secure',
    this.compatibilityScore = 92,
    this.emotionalAlignment = 89,
    this.valuesAlignment = 95,
    this.lifestyleCompatibility = 91,
    this.aiExplanation =
        'Strong synergy in permanent family orientation, communication integrity, and shared marriage timeline.',
    this.isVerified = true,
    this.verificationBadge = 'GOLD',
    required this.photos,
  });

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
          .map((img) => (img is Map ? img['url'] : img).toString())
          .toList();
    } else if (partner['profileImageUrls'] is List) {
      photoList = (partner['profileImageUrls'] as List).map((e) => e.toString()).toList();
    } else if (partner['photoUrls'] is List) {
      photoList = (partner['photoUrls'] as List).map((e) => e.toString()).toList();
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

    final firstName = partner['firstName']?.toString() ?? '';
    final lastName = partner['lastName']?.toString() ?? '';
    final fullName = partner['name']?.toString() ??
        (firstName.isNotEmpty ? '$firstName $lastName'.trim() : 'Candidate');

    return MatchProfile(
      id: partner['id']?.toString() ?? json['matchId']?.toString() ?? '',
      name: fullName,
      age: partner['age'] is num
          ? (partner['age'] as num).toInt()
          : (partner['dateOfBirth'] != null ? 27 : 26),
      city: partner['city']?.toString() ?? partner['residenceCity']?.toString() ?? 'London',
      country: partner['country']?.toString() ?? partner['residenceCountry']?.toString() ?? 'United Kingdom',
      occupation: partner['occupation']?.toString() ?? 'Executive',
      education: partner['education']?.toString() ?? 'University Degree',
      religion: partner['religion']?.toString() ?? 'Christian',
      culturalBackground: partner['culturalBackground']?.toString() ?? 'Global Heritage',
      marriageTimeline: partner['marriageTimeline']?.toString() ?? '1-2 years',
      willingToRelocate: partner['willingToRelocate']?.toString() ?? 'Yes',
      childrenPreference: partner['childrenPreference']?.toString() ?? 'Open to children',
      bio: partner['bio']?.toString() ?? 'Intentional candidate seeking lifelong partnership.',
      personalValues: (partner['personalValues'] as List?)?.map((e) => e.toString()).toList() ??
          ['Faith', 'Family', 'Integrity'],
      personalityArchetype: partner['personalityArchetype']?.toString() ?? 'The Intentional Builder',
      attachmentStyle: partner['attachmentStyle']?.toString() ?? 'Secure',
      compatibilityScore: (scores['compatibilityScore'] ?? partner['compatibilityScore'] ?? json['compatibilityScore'] ?? 92) is num
          ? ((scores['compatibilityScore'] ?? partner['compatibilityScore'] ?? json['compatibilityScore'] ?? 92) as num).toInt()
          : 92,
      emotionalAlignment: (scores['emotionalAlignment'] ?? partner['emotionalAlignment'] ?? 88) is num
          ? ((scores['emotionalAlignment'] ?? partner['emotionalAlignment'] ?? 88) as num).toInt()
          : 88,
      valuesAlignment: (scores['valuesAlignment'] ?? partner['valuesAlignment'] ?? 94) is num
          ? ((scores['valuesAlignment'] ?? partner['valuesAlignment'] ?? 94) as num).toInt()
          : 94,
      lifestyleCompatibility: (scores['lifestyleCompatibility'] ?? partner['lifestyleCompatibility'] ?? 90) is num
          ? ((scores['lifestyleCompatibility'] ?? partner['lifestyleCompatibility'] ?? 90) as num).toInt()
          : 90,
      aiExplanation: json['aiExplanation']?.toString() ??
          partner['aiExplanation']?.toString() ??
          'High emotional safety and mutual vision for permanent family building.',
      isVerified: partner['isVerified'] == true || partner['idVerified'] == true,
      verificationBadge: partner['verificationBadge']?.toString() ?? 'GOLD',
      photos: photoList,
    );
  }
}
