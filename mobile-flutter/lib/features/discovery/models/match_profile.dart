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
    List<String> photoList = [];
    if (json['profileImageUrls'] is List) {
      photoList = (json['profileImageUrls'] as List).map((e) => e.toString()).toList();
    } else if (json['profileImages'] is List) {
      photoList = (json['profileImages'] as List)
          .map((img) => (img is Map ? img['url'] : img).toString())
          .toList();
    }

    if (photoList.isEmpty) {
      photoList = [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800',
      ];
    }

    return MatchProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          (json['firstName'] != null
              ? '${json['firstName']} ${json['lastName'] ?? ''}'.trim()
              : 'Candidate'),
      age: json['age'] is num
          ? (json['age'] as num).toInt()
          : (json['dateOfBirth'] != null ? 27 : 26),
      city: json['city']?.toString() ?? json['residenceCity']?.toString() ?? 'London',
      country: json['country']?.toString() ?? json['residenceCountry']?.toString() ?? 'United Kingdom',
      occupation: json['occupation']?.toString() ?? 'Executive',
      education: json['education']?.toString() ?? 'Master of Science',
      religion: json['religion']?.toString() ?? 'Christian',
      culturalBackground: json['culturalBackground']?.toString() ?? 'Heritage',
      marriageTimeline: json['marriageTimeline']?.toString() ?? '1-2 years',
      willingToRelocate: json['willingToRelocate']?.toString() ?? 'Yes',
      childrenPreference: json['childrenPreference']?.toString() ?? 'Open to children',
      bio: json['bio']?.toString() ?? 'Intentional candidate seeking lifelong partnership.',
      personalValues: (json['personalValues'] as List?)?.map((e) => e.toString()).toList() ??
          ['Faith', 'Family', 'Integrity'],
      personalityArchetype: json['personalityArchetype']?.toString() ?? 'The Intentional Builder',
      attachmentStyle: json['attachmentStyle']?.toString() ?? 'Secure',
      compatibilityScore: json['compatibilityScore'] is num
          ? (json['compatibilityScore'] as num).toInt()
          : 92,
      emotionalAlignment: json['emotionalAlignment'] is num
          ? (json['emotionalAlignment'] as num).toInt()
          : 88,
      valuesAlignment: json['valuesAlignment'] is num
          ? (json['valuesAlignment'] as num).toInt()
          : 94,
      lifestyleCompatibility: json['lifestyleCompatibility'] is num
          ? (json['lifestyleCompatibility'] as num).toInt()
          : 90,
      aiExplanation: json['aiExplanation']?.toString() ??
          'High emotional safety and mutual vision for permanent family building.',
      isVerified: json['isVerified'] == true,
      verificationBadge: json['verificationBadge']?.toString() ?? 'GOLD',
      photos: photoList,
    );
  }
}
