/// Curated global location and onboarding options data for KNOT Mobile.
library;

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class KnotLocationData {
  /// Full world dataset (country -> states/provinces/regions) loaded from
  /// `assets/data/states_by_country.json` at app start-up.
  static Map<String, List<String>> _worldStates = const {};
  static List<String> _allCountries = countries;

  /// Loads the bundled world states dataset. Safe to call multiple times.
  static Future<void> load() async {
    if (_worldStates.isNotEmpty) return;
    try {
      final raw = await rootBundle.loadString('assets/data/states_by_country.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _worldStates = decoded.map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      );
      final merged = <String>{...countries, ..._worldStates.keys}.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      _allCountries = merged;
    } catch (_) {
      // Fall back to curated data only.
    }
  }

  /// Every selectable country (curated + full world dataset).
  static List<String> get allCountries => _allCountries;

  /// States / provinces / regions for [country]. Curated lists take priority
  /// so values already saved on existing profiles keep matching.
  static List<String> statesFor(String country) {
    return statesByCountry[country] ?? _worldStates[country] ?? const <String>[];
  }

  static const List<String> countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Argentina', 'Armenia', 'Australia',
    'Austria', 'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 'Belgium',
    'Belize', 'Benin', 'Bermuda', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil',
    'Bulgaria', 'Cameroon', 'Canada', 'Chile', 'China', 'Colombia', 'Costa Rica', 'Croatia', 'Cuba',
    'Cyprus', 'Czech Republic', 'Denmark', 'Dominican Republic', 'Ecuador', 'Egypt', 'Estonia',
    'Ethiopia', 'Fiji', 'Finland', 'France', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Guatemala',
    'Haiti', 'Honduras', 'Hong Kong', 'Hungary', 'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq',
    'Ireland', 'Israel', 'Italy', 'Jamaica', 'Japan', 'Jordan', 'Kazakhstan', 'Kenya', 'Kuwait',
    'Latvia', 'Lebanon', 'Lithuania', 'Luxembourg', 'Malaysia', 'Maldives', 'Malta', 'Mexico',
    'Monaco', 'Morocco', 'Namibia', 'Nepal', 'Netherlands', 'New Zealand', 'Nigeria', 'Norway',
    'Oman', 'Pakistan', 'Panama', 'Peru', 'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania',
    'Russia', 'Rwanda', 'Saudi Arabia', 'Senegal', 'Serbia', 'Singapore', 'Slovakia', 'Slovenia',
    'South Africa', 'South Korea', 'Spain', 'Sri Lanka', 'Sweden', 'Switzerland', 'Taiwan',
    'Tanzania', 'Thailand', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Uganda', 'Ukraine',
    'United Arab Emirates', 'United Kingdom', 'United States of America', 'Uruguay', 'Uzbekistan',
    'Venezuela', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe'
  ];

  static const Map<String, List<String>> statesByCountry = {
    'United States of America': [
      'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware',
      'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
      'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi',
      'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico',
      'New York', 'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania',
      'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
      'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming', 'District of Columbia'
    ],
    'Nigeria': [
      'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 'Borno',
      'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'Federal Capital Territory (Abuja)',
      'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos',
      'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto', 'Taraba',
      'Yobe', 'Zamfara'
    ],
    'United Kingdom': [
      'England', 'Scotland', 'Wales', 'Northern Ireland', 'Greater London', 'Greater Manchester',
      'West Midlands', 'West Yorkshire', 'Merseyside', 'South Yorkshire', 'Tyne and Wear',
      'Bristol', 'Leicestershire', 'Nottinghamshire', 'Surrey', 'Hampshire', 'Kent', 'Essex'
    ],
    'Canada': [
      'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick', 'Newfoundland and Labrador',
      'Northwest Territories', 'Nova Scotia', 'Nunavut', 'Ontario', 'Prince Edward Island',
      'Quebec', 'Saskatchewan', 'Yukon'
    ],
    'Ghana': [
      'Greater Accra', 'Ashanti', 'Central', 'Eastern', 'Western', 'Volta', 'Northern',
      'Upper East', 'Upper West', 'Bono', 'Bono East', 'Ahafo', 'Oti', 'Savannah', 'North East', 'Western North'
    ],
    'South Africa': [
      'Gauteng', 'Western Cape', 'KwaZulu-Natal', 'Eastern Cape', 'Free State',
      'Limpopo', 'Mpumalanga', 'North West', 'Northern Cape'
    ],
    'Kenya': [
      'Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret', 'Kiambu', 'Machakos', 'Kilifi', 'Uasin Gishu'
    ],
    'Australia': [
      'New South Wales', 'Victoria', 'Queensland', 'Western Australia', 'South Australia',
      'Tasmania', 'Australian Capital Territory', 'Northern Territory'
    ],
    'Germany': [
      'Baden-Württemberg', 'Bavaria', 'Berlin', 'Brandenburg', 'Bremen', 'Hamburg', 'Hesse',
      'Lower Saxony', 'Mecklenburg-Vorpommern', 'North Rhine-Westphalia', 'Rhineland-Palatinate',
      'Saarland', 'Saxony', 'Saxony-Anhalt', 'Schleswig-Holstein', 'Thuringia'
    ],
    'United Arab Emirates': [
      'Abu Dhabi', 'Dubai', 'Sharjah', 'Ajman', 'Umm Al Quwain', 'Ras Al Khaimah', 'Fujairah'
    ],
    'India': [
      'Delhi', 'Maharashtra', 'Karnataka', 'Tamil Nadu', 'Telangana', 'Uttar Pradesh',
      'Gujarat', 'West Bengal', 'Kerala', 'Punjab', 'Rajasthan', 'Haryana'
    ],
    'Switzerland': [
      'Zurich', 'Bern', 'Lucerne', 'Uri', 'Schwyz', 'Geneva', 'Vaud', 'Basel-City', 'Zug', 'Neuchâtel'
    ],
  };

  static const List<String> majorLanguages = [
    'English', 'Spanish', 'French', 'German', 'Mandarin', 'Hindi', 'Arabic',
    'Portuguese', 'Yoruba', 'Igbo', 'Hausa', 'Swahili', 'Chinese', 'Other'
  ];

  static const List<String> majorTraits = [
    'Kind', 'Ambitious', 'Family-oriented', 'Honest', 'Humorous', 'Intelligent',
    'Empathetic', 'Adventurous', 'Loyal', 'Spiritual', 'Confident', 'Other'
  ];

  static const List<String> maritalStatusOptions = [
    'Never married', 'Divorced', 'Widowed', 'Annulled'
  ];

  static const List<String> smokingOptions = [
    'Non-smoker', 'Occasional', 'Regular smoker', 'Trying to quit'
  ];

  static const List<String> drinkingOptions = [
    'Non-drinker', 'Socially', 'Regularly'
  ];

  static const List<String> partnerChildrenStatusOptions = [
    'No Kid(s)', 'With Kid(s)', 'With or Without Kid(s)'
  ];

  static const List<String> vowTimelineOptions = [
    'ASAP', '1-2 years', '3+ years', 'Not sure'
  ];

  static const List<String> relocationOptions = [
    'Yes', 'No', 'Maybe'
  ];

  static const List<String> childrenIntentOptions = [
    'Want children', 'Don\'t want children', 'Open to children'
  ];

  static const List<String> educationOptions = [
    "Bachelor's Degree (B.Sc. / B.A. / LL.B)",
    "Master's Degree (M.Sc. / M.A. / MBA)",
    'Doctorate (Ph.D. / MD / JD)',
    'Postgraduate Diploma (PGD)',
    'Higher National Diploma (HND)',
    'Associate Degree / OND / NCE',
    'Professional Certification',
    'High School / Secondary Certificate',
    'Other',
  ];
}
