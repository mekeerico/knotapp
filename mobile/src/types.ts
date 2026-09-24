// Navigation param list for all screens
export type RootStackParamList = {
  Auth: undefined;
  Onboarding: undefined;
  MainTabs: undefined;
  ProfileDetail: { match: Match };
  Chat: { match: Match; user: User };
  VideoCall: { match: Match; user: User };
  Verification: { user: User };
  EditProfile: { user: User };
  ManagePhotos: { user: User };
  Payment: { user: User };
  Admin: undefined;
  Legal: { type: 'tos' | 'privacy' | 'community' };
};

export type TabParamList = {
  Home: undefined;
  Insights: undefined;
  AICoach: undefined;
  Messages: undefined;
  Profile: undefined;
};

// Enums
export enum SubscriptionTier {
  Essential = 'Essential',
  Premium = 'Premium',
  Elite = 'Elite',
  Executive = 'Executive',
}

export enum SmokingHabits {
  NonSmoker = 'Non-smoker',
  Occasional = 'Occasional',
  Regular = 'Regular',
  TryingToQuit = 'Trying to quit',
}

export enum DrinkingHabits {
  Never = 'Never',
  Socially = 'Socially',
  Frequently = 'Frequently',
  Sober = 'Sober',
}

export enum MaritalStatus {
  NeverMarried = 'Never Married',
  Divorced = 'Divorced',
  Widowed = 'Widowed',
  Annulled = 'Annulled',
}

export enum WillingToRelocate {
  Yes = 'Yes',
  No = 'No',
  Maybe = 'Maybe',
}

export enum ChildrenPreference {
  WantsChildren = 'Wants children',
  DoesNotWantChildren = "Doesn't want children",
  OpenToChildren = 'Open to children',
  HasChildren = 'Has children',
}

export enum TravelFrequency {
  Often = 'Often',
  Sometimes = 'Sometimes',
  Rarely = 'Rarely',
  Never = 'Never',
}

export enum SocialActivity {
  Introvert = 'Introvert',
  Extrovert = 'Extrovert',
  Ambivert = 'Ambivert',
}

export interface User {
  id: string;
  role?: string;
  email?: string;
  name?: string;
  age?: number;
  firstName?: string;
  lastName?: string;
  gender?: string;
  preferredGender?: string;
  dateOfBirth?: string;
  bio: string;
  interests: string[];
  profileImageUrls: string[];
  isVerified: boolean;
  isPremium: boolean;
  occupation: string;
  city: string;

  
  // Preferred Partner Location Details
  preferredResidenceCountry?: string;
  preferredResidenceState?: string;
  preferredResidenceCity?: string;
  preferredOriginCountry?: string;
  preferredOriginState?: string;
  preferredOriginCity?: string;
  country: string;
  residenceCountry: string;
  residenceState: string;
  residenceCity: string;
  originCountry: string;
  originState: string;
  originCity: string;
  education: string;
  languagesSpoken: string[];
  religion: string;
  culturalBackground: string;
  personalValues: string[];
  smoking: SmokingHabits;
  drinking: DrinkingHabits;
  maritalStatus: MaritalStatus;
  childrenStatus: string;
  marriageTimeline: string;
  willingToRelocate: WillingToRelocate;
  preferredMarryFrom: string;
  childrenPreference: ChildrenPreference;
  idealPartnerTraits: string[];
  marriageExpectations: string;
  preferredPartnerAgeRange: [number, number];
  nationality: string;
  careerGoals: string;
  subscriptionDate?: string;
  subscriptionAmount?: number;
  subscriptionPeriod?: string;
  subscriptionTier?: SubscriptionTier;
  matchesViewedToday?: number;
  lastMatchViewDate?: string;
  readinessScore?: number;
  seriousnessLevel?: number;
  trustScore?: number;
  personalityArchetype?: string;
  attachmentStyle?: string;
  selfieUrl?: string;
  pushToken?: string;
  photoUrl?: string;
  profileImages?: { url: string; isPrimary?: boolean }[];
}

export interface Match extends User {
  compatibilityScore?: number;
  compatibilityInsight?: string;
}

export interface Message {
  id: string;
  senderId: string;
  text: string;
  timestamp: Date;
}

export interface Resource {
  id: string;
  title: string;
  description: string;
  category: string;
  imageUrl: string;
  link: string;
}

export interface FilterState {
  ageRange: [number, number];
  location: string;
  showVerifiedOnly: boolean;
}
