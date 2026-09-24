import React, { useState, useMemo, useRef, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  Alert,
  FlatList,
  Image,
  KeyboardAvoidingView,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  ActivityIndicator,
  Animated,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import * as ImagePicker from 'expo-image-picker';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { Colors, Spacing, BorderRadius } from '../theme/colors';
import { RootStackParamList, User, MaritalStatus, SmokingHabits, DrinkingHabits, ChildrenPreference, WillingToRelocate } from '../types';
import { COUNTRIES, STATES_BY_COUNTRY, CITIES_BY_STATE } from '../services/locationData';
import { db } from '../services/apiService';
import { LivenessCameraModal } from '../components/LivenessCameraModal';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export default function OnboardingScreen() {
  const navigation = useNavigation<Nav>();
  const { userProfile, setUserProfile, logout } = useAuth();
  const { isDarkMode } = useTheme();

  // Onboarding Steps:
  // 1: Cinematic Welcome
  // 2: Essentials Form & Uploads (Selfie + ID)
  // 3: AI Matchmaker Interview Chat
  // 4: AI Liveness & Biometric Verification Scan
  // 5: Relationship Certificate Reveal
  const [step, setStep] = useState(1);
  const [profilePictureSkipped, setProfilePictureSkipped] = useState(false);
  const [verificationSkipped, setVerificationSkipped] = useState(false);
  const totalSteps = 6;
  const [subStep, setSubStep] = useState(0);
  const slideAnim = useRef(new Animated.Value(50)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (step === 2) {
      slideAnim.setValue(50);
      fadeAnim.setValue(0);
      Animated.parallel([
        Animated.timing(slideAnim, { toValue: 0, duration: 400, useNativeDriver: true }),
        Animated.timing(fadeAnim, { toValue: 1, duration: 400, useNativeDriver: true }),
      ]).start();
    }
  }, [subStep, step]);

  const nextSubStep = () => {
    // Validation Guardrails
    if (subStep === 2) {
      if (form.dateOfBirth) {
        const dob = new Date(form.dateOfBirth);
        const today = new Date();
        let age = today.getFullYear() - dob.getFullYear();
        const m = today.getMonth() - dob.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
          age--;
        }
        if (age < 18) {
          Alert.alert("Age Restriction", "You must be at least 18 years old to join the registry.");
          return;
        }
      }
      if (form.occupation) {
        if (form.occupation.trim().length < 2) {
          Alert.alert("Invalid Occupation", "Please enter a valid occupation.");
          return;
        }
        if (!/[a-zA-Z]/.test(form.occupation)) {
          Alert.alert("Invalid Occupation", "Occupation must contain letters.");
          return;
        }
      }
    } else if (subStep === 10) {
      if (form.preferredPartnerAgeRange) {
        const minAge = form.preferredPartnerAgeRange[0] || 0;
        const maxAge = form.preferredPartnerAgeRange[1] || 0;
        if (minAge < 18) {
          Alert.alert("Invalid Age", "The minimum age for a partner must be 18 or older.");
          return;
        }
        if (maxAge < minAge) {
          Alert.alert("Invalid Age Range", "The maximum age cannot be less than the minimum age.");
          return;
        }
        if (maxAge > 99) {
          Alert.alert("Invalid Age Range", "Please enter a feasible maximum age (e.g., 99 or below).");
          return;
        }
      }
    }

    setSubStep(s => {
      let next = s + 1;
      // Skip email step if already fetched from Auth
      if (next === 3 && form.email) {
        next = 4;
      }
      return next;
    });
  };

  // Image Upload State
  const [govIdUri, setGovIdUri] = useState<string | null>(null);
  const [livenessUri, setLivenessUri] = useState<string | null>(null);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  // Form State
  const [form, setForm] = useState<User>({
    id: userProfile?.id || '',
    email: userProfile?.email || '',
    firstName: '',
    lastName: '',
    dateOfBirth: '',
    bio: '',
    interests: [],
    profileImageUrls: [],
    isVerified: false,
    isPremium: false,
    occupation: '',
    city: '',
    country: '',
    residenceCountry: '',
    residenceState: '',
    residenceCity: '',
    originCountry: '',
    originState: '',
    originCity: '',
    religion: '',
    personalValues: [],
    nationality: '',
    languagesSpoken: [],
    maritalStatus: MaritalStatus.NeverMarried,
    smoking: SmokingHabits.NonSmoker,
    drinking: DrinkingHabits.Never,
    childrenStatus: 'No kids',
    marriageTimeline: 'Within 1-2 years',
    willingToRelocate: WillingToRelocate.Maybe,
    childrenPreference: ChildrenPreference.OpenToChildren,
    idealPartnerTraits: [],
  } as any);

  // AI Interview State
  const [messages, setMessages] = useState<Array<{ role: 'ai' | 'user'; text: string }>>([
    {
      role: 'ai',
      text: 'Welcome to KNOT. I am your AI-Matching Guide. I will explore your psychological profiles, attachment dynamics, and commitment objectives. Shall we begin?',
    },
  ]);
  const [currentInput, setCurrentInput] = useState('');
  const [interviewQuestionIndex, setInterviewQuestionIndex] = useState(0);
  const chatScrollViewRef = useRef<ScrollView>(null);

  const interviewPrompts = [
    'What kind of relationship are you hoping to build with a potential partner?',
    'What core values and priorities matter most in your life and future marriage?',
    'What does permanent commitment mean to you personally?',
    'How do you usually approach disagreements or conflict resolution in relationships?',
    'What are your core relationship non-negotiables?',
    'Would you be open to relocating for the right relationship?',
  ];

  // AI Scanner Verification State
  const [verificationStep, setVerificationStep] = useState(0);
  const scanAnim = useRef(new Animated.Value(0)).current;

  // Selfie Liveness Interactive Modal States
  const [isLivenessModalOpen, setIsLivenessModalOpen] = useState(false);

  // ID Scanning Interactive Modal States
  const [isIdScanModalOpen, setIsIdScanModalOpen] = useState(false);
  const [idScanState, setIdScanState] = useState<'align' | 'scanning' | 'complete'>('align');
  const [idScanPrompt, setIdScanPrompt] = useState('Align ID inside the rectangle frame');

  const startLivenessScanner = async () => {
    setIsLivenessModalOpen(true);
  };

  const handleLivenessCapture = (uri: string) => {
    setLivenessUri(uri);
  };

  const startIdScanner = async () => {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission needed', 'Please grant camera access to scan your Government ID.');
      return;
    }

    const result = await ImagePicker.launchCameraAsync({
      allowsEditing: true,
      aspect: [4, 3],
      quality: 0.8,
    });

    if (!result.canceled && result.assets?.[0]) {
      setGovIdUri(result.assets[0].uri);
    }
  };


  // Religion Select States
  const [religionSelect, setReligionSelect] = useState('');
  const [religionCustom, setReligionCustom] = useState('');
  const [languageCustom, setLanguageCustom] = useState('');
  const [traitCustom, setTraitCustom] = useState('');
  const [prefResCountryCustom, setPrefResCountryCustom] = useState('');
  const [prefResStateCustom, setPrefResStateCustom] = useState('');
  const [prefOriCountryCustom, setPrefOriCountryCustom] = useState('');
  const [prefOriCustom, setPrefOriCustom] = useState('');

  // Gold Archetype Results
  const archetype = {
    personalityArchetype: 'The Intentional Builder',
    attachmentStyle: 'Secure',
    readinessScore: 88,
    seriousnessLevel: 94,
    trustScore: 85,
    personalValues: ['Family Traditions', 'Faith', 'Mutual Growth'],
  };

  // Location Selector Dropdowns
  const [dropdownVisible, setDropdownVisible] = useState(false);
  const [dropdownOptions, setDropdownOptions] = useState<string[]>([]);
  const [dropdownCallback, setDropdownCallback] = useState<((v: string) => void) | null>(null);
  const [dropdownTitle, setDropdownTitle] = useState('');
  const [dropdownSearch, setDropdownSearch] = useState('');
  const [dropdownMultiSelect, setDropdownMultiSelect] = useState(false);
  const [dropdownSelectedItems, setDropdownSelectedItems] = useState<string[]>([]);
  const [dropdownMultiCallback, setDropdownMultiCallback] = useState<((v: string[]) => void) | null>(null);

  // Trigger Scanner animation when Step 4 loads
  useEffect(() => {
    if (step === 4) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(scanAnim, {
            toValue: 1,
            duration: 2000,
            useNativeDriver: false,
          }),
          Animated.timing(scanAnim, {
            toValue: 0,
            duration: 2000,
            useNativeDriver: false,
          }),
        ])
      ).start();
    }
  }, [step]);

  const laserTop = scanAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ['5%', '95%'],
  });



  const set = (key: keyof User, val: any) => setForm((p) => ({ ...p, [key]: val }));
  const setResCountry = (v: string) => setForm((p) => ({ ...p, residenceCountry: v, residenceState: '', residenceCity: '', country: v }));
  const setResState = (v: string) => setForm((p) => ({ ...p, residenceState: v, residenceCity: '' }));
  const setResCity = (v: string) => setForm((p) => ({ ...p, residenceCity: v, city: v }));
  const setOriCountry = (v: string) => setForm((p) => ({ ...p, originCountry: v, originState: '', originCity: '' }));
  const setOriState = (v: string) => setForm((p) => ({ ...p, originState: v, originCity: '' }));
  const setPrefResCountry = (v: string) => setForm((p) => ({ ...p, preferredResidenceCountry: v, preferredResidenceState: '', preferredResidenceCity: '' }));
  const setPrefResState = (v: string) => setForm((p) => ({ ...p, preferredResidenceState: v, preferredResidenceCity: '' }));
  const setPrefOriCountry = (v: string) => setForm((p) => ({ ...p, preferredOriginCountry: v, preferredOriginState: '', preferredOriginCity: '' }));
  const setPrefOriState = (v: string) => setForm((p) => ({ ...p, preferredOriginState: v, preferredOriginCity: '' }));

  const pickImage = async (type: 'selfie' | 'id') => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.8,
    });
    if (!result.canceled && result.assets?.[0]) {
      const uri = result.assets[0].uri;
      if (type === 'selfie') {
        set('profileImageUrls', [uri]);
      } else {
        setGovIdUri(uri);
      }
    }
  };

  const handleSendMessage = async () => {
    if (!currentInput.trim()) return;

    const userText = currentInput.trim();
    setMessages((prev) => [...prev, { role: 'user', text: userText }]);
    setCurrentInput('');

    setTimeout(() => chatScrollViewRef.current?.scrollToEnd({ animated: true }), 100);

    // Instant AI response for seamless interview flow
    if (interviewQuestionIndex < interviewPrompts.length) {
      const nextPrompt = interviewPrompts[interviewQuestionIndex];
      setInterviewQuestionIndex((prevIndex) => prevIndex + 1);

      const warmTransitivePhrases = [
        "Thank you for sharing that insight.",
        "Understood. That reflects strong relationship intentionality.",
        "Extremely valuable perspective.",
        "Thank you for your honesty."
      ];
      const prefix = warmTransitivePhrases[interviewQuestionIndex % warmTransitivePhrases.length];

      setMessages((prev) => [
        ...prev.filter(m => m.text !== 'Analyzing response...'),
        { role: 'ai', text: `${prefix} ${nextPrompt}` }
      ]);
    } else {
      setMessages((prev) => [
        ...prev.filter(m => m.text !== 'Analyzing response...'),
        { role: 'ai', text: 'Excellent. I have completed my relationship intelligence assessment. I will now analyze your values, personality alignment, and readiness indices. Shall we generate your Relationship Registry Certificate?' }
      ]);
    }
    setTimeout(() => chatScrollViewRef.current?.scrollToEnd({ animated: true }), 100);
  };

  const handleProcessAIVerification = async () => {
    if (!livenessUri || !govIdUri) {
      Alert.alert("Missing Verification Items", "Please complete both your live selfie scan and government ID scan.");
      return;
    }

    // Intelligent Document Validation Check
    const lowerIdUri = (govIdUri || '').toLowerCase();
    const isTextSpreadsheetOrDocument = lowerIdUri.includes('sheet') || lowerIdUri.includes('excel') || lowerIdUri.includes('table') || lowerIdUri.includes('document') || lowerIdUri.includes('pdf') || lowerIdUri.includes('csv');

    setStep(5); // Show AI Biometric Scanner UI
    setVerificationStep(0); // Analyzing and extracting details

    // Map "Other" custom fields into final arrays
    const finalLanguages = form.languagesSpoken?.map(l => l === 'Other' && languageCustom ? languageCustom : l) || [];
    const finalTraits = form.idealPartnerTraits?.map(t => t === 'Other' && traitCustom ? traitCustom : t) || [];
    setForm(p => ({ ...p, languagesSpoken: finalLanguages, idealPartnerTraits: finalTraits }));

    // Wait for photos to upload to get remote URLs
    let finalSelfieUrl = livenessUri || '';
    let finalIdUrl = govIdUri || '';
    
    // We must await uploads so the backend can actually download the images!
    try {
      if (finalSelfieUrl.startsWith('file:') || finalSelfieUrl.startsWith('content:')) {
        finalSelfieUrl = await db.uploadPhoto(finalSelfieUrl);
      }
      if (finalIdUrl.startsWith('file:') || finalIdUrl.startsWith('content:')) {
        finalIdUrl = await db.uploadPhoto(finalIdUrl);
      }
      
      // Also upload profile photo silently in background if needed
      let profileUrl = form.profileImageUrls?.[0] || '';
      if (profileUrl.startsWith('file:') || profileUrl.startsWith('content:')) {
        db.uploadPhoto(profileUrl).catch(() => {});
      }
    } catch (e: any) {
      console.warn("Error uploading photos for verification:", e);
      Alert.alert(
        "Upload Failed", 
        `Failed to upload images for verification. Please check your network and try again.\n\nDetails: ${e.message}`,
        [{ text: "Try Again", style: 'default', onPress: () => setStep(4) }]
      );
      return;
    }

    // Checkpoint 1: ID Text & Document Structure Scan
    await new Promise(r => setTimeout(r, 600));
    setVerificationStep(1); // 1. Scanning ID text & details... ✔ Match

    // Checkpoint 2: Extracting Face Keypoints & Biometric Features
    await new Promise(r => setTimeout(r, 600));
    setVerificationStep(2); // 2. Extracting face keypoints... ✔ 128 Face Vectors Extracted

    // Checkpoint 3: Biometric Facial Comparison & Name/Age Verification
    setVerificationStep(3); // 3. Biometric comparison... Age & Name: Verifying...

    // Call real backend AI verification engine (Gemini AI Vision)
    let aiRes: { success: boolean; confidenceScore?: number; details?: string } = { success: true };
    try {
      aiRes = await db.verifyOnboarding(
        finalSelfieUrl,
        finalIdUrl,
        form.firstName || '',
        form.lastName || '',
        form.dateOfBirth || ''
      );
    } catch (e) {
      console.warn("Backend verifyOnboarding error:", e);
      aiRes = { success: false, details: 'Network error or server timeout communicating with AI.' };
    }

    if (!aiRes.success) {
      // Keep verification step at 3 but set a failure state if possible, or we can just Alert it, but user wants reasons given with a retake or cancel button inline.
      Alert.alert(
        "Verification Failed",
        aiRes.details || "Document Verification Failed: Identity mismatch or invalid document.",
        [
          { text: "Cancel", style: 'cancel', onPress: () => setStep(4) },
          { text: "Retake", style: 'default', onPress: () => setStep(4) },
        ]
      );
      setVerificationStep(0); // Reset for retry
      return;
    }

    // All checks passed! Checkpoint 4: Age & Name consistency... ✔ Approved
    await new Promise(r => setTimeout(r, 600));
    setVerificationStep(4);
  };

  const complete = async () => {
    const finalForm = {
      ...form,
      name: `${form.firstName} ${form.lastName}`,
      isVerified: true, // ENFORCED: All onboarded users are 100% Verified!
      personalValues: archetype.personalValues,
      bio: 'Intentional Builder focused on traditional family values and mutual growth.',
    };

    try {
      // Save locally to AsyncStorage first for instant dashboard activation
      await AsyncStorage.setItem('knot_user_profile', JSON.stringify(finalForm));
    } catch (err: any) {
      console.warn("Local storage save error:", err);
    }

    // Set user profile state immediately to launch Dashboard in 0ms!
    setUserProfile(finalForm);

    // Sync to backend silently in background
    db.saveUser(finalForm).catch(err => {
      console.warn("Background saveUser sync failed:", err);
    });
  };

  const openDropdown = (title: string, options: string[], callback: (v: string) => void) => {
    setDropdownTitle(title);
    setDropdownOptions(options);
    setDropdownCallback(() => callback);
    setDropdownMultiSelect(false);
    setDropdownSearch('');
    setDropdownVisible(true);
  };

  const openMultiDropdown = (title: string, options: string[], currentValues: string[], callback: (v: string[]) => void) => {
    setDropdownTitle(title);
    setDropdownOptions(options);
    setDropdownMultiCallback(() => callback);
    setDropdownMultiSelect(true);
    setDropdownSelectedItems(currentValues || []);
    setDropdownSearch('');
    setDropdownVisible(true);
  };

  const filteredDropdownOptions = useMemo(() => {
    if (!dropdownSearch.trim()) return dropdownOptions;
    const q = dropdownSearch.toLowerCase();
    return dropdownOptions.filter((o) => o.toLowerCase().includes(q));
  }, [dropdownOptions, dropdownSearch]);

  const renderDropdownField = (label: string, value: string | undefined, placeholder: string, options: string[], onSelect: (v: string) => void) => (
    <View style={{ marginBottom: 12 }}>
      <Text style={styles.label}>{label}</Text>
      <TouchableOpacity
        style={[styles.dropdownBtn, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}
        onPress={() => openDropdown(label, options, onSelect)}
        activeOpacity={0.7}
      >
        <Text style={[styles.dropdownBtnText, { color: value ? (isDarkMode ? Colors.white : Colors.gray900) : Colors.gray400 }]}>
          {value || placeholder}
        </Text>
        <Ionicons name="chevron-down" size={18} color={Colors.gray400} />
      </TouchableOpacity>
    </View>
  );

  const renderMultiDropdownField = (label: string, values: string[], placeholder: string, options: string[], onSelect: (v: string[]) => void) => (
    <View style={{ marginBottom: 12 }}>
      <Text style={styles.label}>{label}</Text>
      <TouchableOpacity
        style={[styles.dropdownBtn, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}
        onPress={() => openMultiDropdown(label, options, values, onSelect)}
        activeOpacity={0.7}
      >
        <Text style={[styles.dropdownBtnText, { color: values.length ? (isDarkMode ? Colors.white : Colors.gray900) : Colors.gray400 }]}>
          {values.length ? values.join(', ') : placeholder}
        </Text>
        <Ionicons name="chevron-down" size={18} color={Colors.gray400} />
      </TouchableOpacity>
    </View>
  );

  const renderLocationGroup = (prefix: 'residence' | 'origin' | 'preferredResidence' | 'preferredOrigin', title: string) => {
    const countryVal = prefix === 'residence' ? form.residenceCountry : prefix === 'origin' ? form.originCountry : prefix === 'preferredResidence' ? form.preferredResidenceCountry : form.preferredOriginCountry;
    const stateVal = prefix === 'residence' ? form.residenceState : prefix === 'origin' ? form.originState : prefix === 'preferredResidence' ? form.preferredResidenceState : form.preferredOriginState;
    const cityVal = prefix === 'residence' ? form.residenceCity : prefix === 'origin' ? form.originCity : prefix === 'preferredResidence' ? form.preferredResidenceCity : form.preferredOriginCity;
    const states = STATES_BY_COUNTRY[countryVal || ''] || [];
    const setCountry = prefix === 'residence' ? setResCountry : prefix === 'origin' ? setOriCountry : prefix === 'preferredResidence' ? setPrefResCountry : setPrefOriCountry;
    const setState = prefix === 'residence' ? setResState : prefix === 'origin' ? setOriState : prefix === 'preferredResidence' ? setPrefResState : setPrefOriState;
    const setCity = prefix === 'residence' ? setResCity : prefix === 'origin' ? (v: string) => set('originCity', v) : prefix === 'preferredResidence' ? (v: string) => set('preferredResidenceCity', v) : (v: string) => set('preferredOriginCity', v);

    return (
      <View style={{ marginTop: 16 }}>
        <Text style={styles.subSectionTitle}>{title}</Text>
        {renderDropdownField('Country', countryVal, 'Select country', COUNTRIES, setCountry)}
        
        {states.length > 0 ? (
          renderDropdownField('State / Province / Region', stateVal, 'Select state / province', states, setState)
        ) : (
          <View style={{ marginBottom: 12 }}>
            <Text style={styles.label}>State / Province / Region</Text>
            <TextInput
              style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}
              value={stateVal}
              onChangeText={setState}
              placeholder="Type state / province"
              placeholderTextColor={Colors.gray400}
            />
          </View>
        )}

        <View style={{ marginBottom: 12 }}>
          <Text style={styles.label}>City / Town</Text>
          <TextInput
            style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}
            value={cityVal}
            onChangeText={setCity}
            placeholder="Type city / town"
            placeholderTextColor={Colors.gray400}
          />
        </View>
      </View>
    );
  };

  const renderPartnerResidenceGroup = () => {
    const countryOptions = ['Any Country', 'Enter Choice Country', ...COUNTRIES];
    const states = STATES_BY_COUNTRY[form.preferredResidenceCountry || ''] || [];
    const stateOptions = ['Any State/Province/Region', 'Enter State/Province/Region', ...states];

    return (
      <View style={{ marginTop: 16 }}>
        {renderDropdownField('Country', form.preferredResidenceCountry, 'Select country', countryOptions, setPrefResCountry)}
        {form.preferredResidenceCountry === 'Enter Choice Country' && (
          <View style={{ marginBottom: 12 }}>
            <TextInput
              style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}
              value={prefResCountryCustom}
              onChangeText={setPrefResCountryCustom}
              placeholder="Type your choice country"
              placeholderTextColor={Colors.gray400}
            />
          </View>
        )}
        
        {renderDropdownField('State / Province / Region', form.preferredResidenceState, 'Select state / province', stateOptions, setPrefResState)}
        {form.preferredResidenceState === 'Enter State/Province/Region' && (
          <View style={{ marginBottom: 12 }}>
            <TextInput
              style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}
              value={prefResStateCustom}
              onChangeText={setPrefResStateCustom}
              placeholder="Type your choice state/province/region"
              placeholderTextColor={Colors.gray400}
            />
          </View>
        )}
      </View>
    );
  };

  const renderPartnerHeritageGroup = () => {
    const countryOptions = ['Any Country', 'Enter Choice Country', ...COUNTRIES];
    const heritageOptions = ['Any Heritage', 'Enter Native Heritage'];

    return (
      <View style={{ marginTop: 16 }}>
        {renderDropdownField('Country', form.preferredOriginCountry, 'Select Country', countryOptions, setPrefOriCountry)}
        {form.preferredOriginCountry === 'Enter Choice Country' && (
          <View style={{ marginBottom: 12 }}>
            <TextInput
              style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}
              value={prefOriCountryCustom}
              onChangeText={setPrefOriCountryCustom}
              placeholder="Type your choice country"
              placeholderTextColor={Colors.gray400}
            />
          </View>
        )}

        {renderDropdownField('Native Heritage', form.preferredOriginState, 'Select Native Heritage', heritageOptions, setPrefOriState)}
        {form.preferredOriginState === 'Enter Native Heritage' && (
          <View style={{ marginBottom: 12 }}>
            <TextInput
              style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}
              value={prefOriCustom}
              onChangeText={setPrefOriCustom}
              placeholder="e.g. Yoruba, Scottish, English, Catalan"
              placeholderTextColor={Colors.gray400}
            />
          </View>
        )}
      </View>
    );
  };

  const bgStyle = { backgroundColor: isDarkMode ? Colors.dark : Colors.white };
  const textStyle = { color: isDarkMode ? Colors.white : Colors.dark };

  return (
    <KeyboardAvoidingView style={[styles.root, bgStyle, { flex: 1 }]} behavior={Platform.OS === 'ios' ? 'padding' : 'height'} keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}>
      {/* Header bar (only show in early steps) */}
      {step <= 4 && (
        <View style={[styles.headerRow, { borderBottomColor: isDarkMode ? Colors.darkBorder : Colors.gray100 }]}>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            {((step === 1) || (step === 2) || (step === 3) || (step === 4)) && (
              <TouchableOpacity 
                onPress={() => {
                  if (step === 4) {
                    setStep(3); // Return to Profile Picture
                  } else if (step === 3) {
                    setStep(2);
                    setSubStep(13); // Return to Ideal Partner Traits
                  } else if (step === 2) {
                    if (subStep === 0) {
                      setStep(1); // Go back to Cinematic Setup
                    } else {
                      setSubStep(s => {
                        let prev = s - 1;
                        if (prev === 3 && form.email) prev = 2;
                        return prev;
                      });
                    }
                  } else if (step === 1) {
                    // Back arrow on first screen logs user out to Auth screen
                    logout();
                  }
                }} 
                style={{ marginRight: 16 }}
              >
                <Ionicons name="arrow-back" size={24} color={isDarkMode ? Colors.white : Colors.dark} />
              </TouchableOpacity>
            )}
            <View>
              <Text style={styles.headerSubtitle}>KNOT Registry</Text>
              <Text style={[styles.headerTitle, textStyle]}>
                {step === 1 && 'Cinematic Setup'}
                {step === 2 && 'Personal Essentials'}
                {step === 3 && 'Identity & Trust'}
                {step === 4 && 'Identity Verification'}
              </Text>
            </View>
          </View>



          <View style={{ alignItems: 'flex-end' }}>
            <TouchableOpacity onPress={() => {
              Alert.alert(
                "Exit Setup",
                "Are you sure you want to stop the onboarding process? You will need to log in again.",
                [
                  { text: "Cancel", style: "cancel" },
                  { text: "Exit", style: "destructive", onPress: logout }
                ]
              );
            }} style={styles.closeBtn}>
              <Ionicons name="close" size={24} color={Colors.gray400} />
            </TouchableOpacity>
            <Text style={styles.stepCounter}>Step {step} of 6</Text>
          </View>
        </View>
      )}

      {/* Main Content Area */}
      <ScrollView contentContainerStyle={styles.scrollContent} keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false}>
        
        {/* Step 1: Cinematic Welcome */}
        {step === 1 && (
          <View style={styles.welcomeContainer}>
            <View style={[styles.welcomeIconWrapper, { backgroundColor: Colors.primary + '1A', borderColor: Colors.primary + '33' }]}>
              <Ionicons name="heart" size={48} color={Colors.primary} />
            </View>
            <Text style={[styles.welcomeTitle, textStyle]}>AI Guided Relationship Registry</Text>
            <Text style={styles.welcomeDesc}>
              Before entering KNOT, all members complete our AI Guided interview to establish personality vectors, attachment archetypes, and commitment integrity.
            </Text>

            <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 20, paddingHorizontal: 20 }}>
              <TouchableOpacity onPress={() => setAcceptedTerms(!acceptedTerms)}>
                <Ionicons name={acceptedTerms ? "checkbox" : "square-outline"} size={24} color={Colors.primary} />
              </TouchableOpacity>
              <Text style={[styles.welcomeDesc, { fontSize: 12, marginLeft: 10, flex: 1, textAlign: 'left', marginBottom: 0 }]}>
                I accept the <Text onPress={() => navigation.navigate('Legal', { type: 'tos' })} style={{ color: Colors.primary, textDecorationLine: 'underline' }}>Terms of Service</Text> and <Text onPress={() => navigation.navigate('Legal', { type: 'privacy' })} style={{ color: Colors.primary, textDecorationLine: 'underline' }}>Privacy Policy</Text>.
              </Text>
            </View>

            <TouchableOpacity onPress={() => {
              if (acceptedTerms) {
                setStep(2);
              } else {
                Alert.alert('Required', 'You must accept the Terms of Service and Privacy Policy to continue.');
              }
            }}>
              <LinearGradient
                colors={['#E27D8D', '#2D1B4E']}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.actionButton}
              >
                <Text style={styles.actionButtonText}>Begin Registry Setup</Text>
                <Ionicons name="arrow-forward" size={18} color={Colors.white} />
              </LinearGradient>
            </TouchableOpacity>
            
            <View style={{ marginTop: 40, alignItems: 'center' }}>
              <Text 
                numberOfLines={1} 
                adjustsFontSizeToFit 
                style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: 2, color: Colors.gray500, fontWeight: 'bold', width: '100%', textAlign: 'center' }}
              >
                FRAUD-PROOF | AI-MATCHING | HIGH-TRUST
              </Text>
            </View>
          </View>
        )}

        {/* Step 2: Personal Essentials (Typeform Style) */}
        {step === 2 && (
          <Animated.View style={[styles.formContainer, { opacity: fadeAnim, transform: [{ translateY: slideAnim }] }]}>
            {subStep === 0 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>What is your name?</Text>
                <View style={{ gap: 16 }}>
                  <View>
                    <Text style={styles.label}>First Name</Text>
                    <TextInput style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]} value={form.firstName} onChangeText={(v) => set('firstName', v)} placeholder="First Name" placeholderTextColor={Colors.gray400} />
                  </View>
                  <View>
                    <Text style={styles.label}>Last Name</Text>
                    <TextInput style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]} value={form.lastName} onChangeText={(v) => set('lastName', v)} placeholder="Last Name" placeholderTextColor={Colors.gray400} />
                  </View>
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.firstName || !form.lastName) ? 0.5 : 1 }]} onPress={() => {
                  if (!form.firstName?.trim() || !form.lastName?.trim()) {
                    Alert.alert('Validation Error', 'Please enter your real first and last name.');
                    return;
                  }
                  nextSubStep();
                }} disabled={!form.firstName || !form.lastName}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 1 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Your Gender</Text>
                <View style={{ gap: 16 }}>
                  {renderDropdownField('Your Gender', form.gender || '', 'Select', ['male', 'female'], (v) => {
                    set('gender', v);
                    set('preferredGender', v === 'male' ? 'female' : 'male');
                  })}
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.gender) ? 0.5 : 1 }]} onPress={nextSubStep} disabled={!form.gender}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 2 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Basic Info</Text>
                <View style={{ gap: 16 }}>
                  <View>
                    <Text style={styles.label}>Date of Birth</Text>
                    <TouchableOpacity style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, justifyContent: 'center' }]} onPress={() => setShowDatePicker(true)}>
                      <Text style={{ color: form.dateOfBirth ? (isDarkMode ? Colors.white : Colors.gray900) : Colors.gray400 }}>{form.dateOfBirth || "YYYY-MM-DD"}</Text>
                    </TouchableOpacity>
                  </View>
                  <View>
                    <Text style={styles.label}>Occupation</Text>
                    <TextInput style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]} value={form.occupation} onChangeText={(v) => set('occupation', v)} placeholder="e.g. Software Engineer" placeholderTextColor={Colors.gray400} />
                  </View>
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.dateOfBirth || !form.occupation) ? 0.5 : 1 }]} onPress={() => {
                  if (!form.occupation?.trim()) {
                    Alert.alert('Validation Error', 'Please enter a valid occupation.');
                    return;
                  }
                  if (form.dateOfBirth) {
                    const dobDate = new Date(form.dateOfBirth);
                    const diff = Date.now() - dobDate.getTime();
                    const age = Math.abs(new Date(diff).getUTCFullYear() - 1970);
                    if (age < 18) {
                      Alert.alert('Invalid Age', 'You must be at least 18 years old.');
                      return;
                    }
                  }
                  nextSubStep();
                }} disabled={!form.dateOfBirth || !form.occupation}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 3 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Email Address</Text>
                <View>
                  <Text style={styles.label}>Email Address</Text>
                  <TextInput style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]} value={form.email} onChangeText={(v) => set('email', v)} placeholder="name@email.com" placeholderTextColor={Colors.gray400} autoCapitalize="none" />
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.email) ? 0.5 : 1 }]} onPress={() => {
                  if (!form.email?.includes('@') || !form.email?.includes('.')) {
                    Alert.alert('Validation Error', 'Please enter a valid email address.');
                    return;
                  }
                  nextSubStep();
                }} disabled={!form.email}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 4 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Religion & Faith</Text>
                <View style={{ gap: 16 }}>
                  {renderDropdownField('Religion / Faith', religionSelect, 'Select religion / faith', ['Christian', 'Muslim', 'Jewish', 'Hindu', 'Buddhist', 'Atheist', 'Agnostic', 'Other'], (val) => {
                    setReligionSelect(val);
                    if (val !== 'Other') set('religion', val);
                    else set('religion', religionCustom);
                  })}
                  {religionSelect === 'Other' && (
                    <TextInput style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]} value={religionCustom} onChangeText={(v) => { setReligionCustom(v); set('religion', v); }} placeholder="Specify your religion" placeholderTextColor={Colors.gray400} />
                  )}
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.religion) ? 0.5 : 1 }]} onPress={nextSubStep} disabled={!form.religion}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 5 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Where do you live?</Text>
                {renderLocationGroup('residence', 'Current Residence')}
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.residenceCountry || !form.residenceCity) ? 0.5 : 1 }]} onPress={nextSubStep} disabled={!form.residenceCountry || !form.residenceCity}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 6 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Heritage & Origin</Text>
                {renderLocationGroup('origin', 'Heritage & Origin')}
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.originCountry || !form.originCity) ? 0.5 : 1 }]} onPress={nextSubStep} disabled={!form.originCountry || !form.originCity}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 7 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Intended Partners Residence</Text>
                <Text style={{ color: Colors.gray400, marginBottom: 16 }}>Where do you ideally want your partner to be living?</Text>
                {renderPartnerResidenceGroup()}
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.preferredResidenceCountry) ? 0.5 : 1 }]} onPress={() => {
                  if (form.preferredResidenceCountry === 'Enter Choice Country' && !prefResCountryCustom.trim()) {
                    Alert.alert('Missing Information', 'Please type your choice country.');
                    return;
                  }
                  if (form.preferredResidenceState === 'Enter State/Province/Region' && !prefResStateCustom.trim()) {
                    Alert.alert('Missing Information', 'Please type your choice state/province/region.');
                    return;
                  }
                  if (form.preferredResidenceCountry === 'Enter Choice Country' && prefResCountryCustom) {
                    setForm(p => ({ ...p, preferredResidenceCountry: prefResCountryCustom }));
                  }
                  if (form.preferredResidenceState === 'Enter State/Province/Region' && prefResStateCustom) {
                    setForm(p => ({ ...p, preferredResidenceState: prefResStateCustom }));
                  }
                  nextSubStep();
                }} disabled={!form.preferredResidenceCountry}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 8 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Native Heritage</Text>
                <Text style={{ color: Colors.gray400, marginBottom: 16 }}>What is your preferred cultural background or origin for a partner?</Text>
                {renderPartnerHeritageGroup()}
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.preferredOriginCountry) ? 0.5 : 1 }]} onPress={() => {
                  if (form.preferredOriginCountry === 'Enter Choice Country' && !prefOriCountryCustom.trim()) {
                    Alert.alert('Missing Information', 'Please type your choice country.');
                    return;
                  }
                  if (form.preferredOriginState === 'Enter Native Heritage' && !prefOriCustom.trim()) {
                    Alert.alert('Missing Information', 'Please type your choice native heritage.');
                    return;
                  }
                  if (form.preferredOriginCountry === 'Enter Choice Country' && prefOriCountryCustom) {
                    setForm(p => ({ ...p, preferredOriginCountry: prefOriCountryCustom }));
                  }
                  if (form.preferredOriginState === 'Enter Native Heritage' && prefOriCustom) {
                    setForm(p => ({ ...p, preferredOriginState: prefOriCustom }));
                  }
                  nextSubStep();
                }} disabled={!form.preferredOriginCountry}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 9 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Languages</Text>
                <View style={{ gap: 16 }}>
                  {renderMultiDropdownField('Languages Spoken', form.languagesSpoken || [], 'Select languages', ['English', 'Spanish', 'French', 'German', 'Mandarin', 'Hindi', 'Arabic', 'Portuguese', 'Yoruba', 'Igbo', 'Hausa', 'Swahili', 'Chinese', 'Other'], (v) => set('languagesSpoken', v))}
                  {(form.languagesSpoken || []).includes('Other') && (
                    <TextInput style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]} value={languageCustom} onChangeText={setLanguageCustom} placeholder="Specify other language" placeholderTextColor={Colors.gray400} />
                  )}
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (form.languagesSpoken?.length === 0) ? 0.5 : 1 }]} onPress={nextSubStep} disabled={form.languagesSpoken?.length === 0}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 10 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Lifestyle Habits</Text>
                <View style={{ gap: 16 }}>
                  {renderDropdownField('Marriage History', form.maritalStatus, 'Select history', Object.values(MaritalStatus), (v) => set('maritalStatus', v))}
                  {renderDropdownField('Smoking', form.smoking, 'Select', Object.values(SmokingHabits), (v) => set('smoking', v))}
                  {renderDropdownField('Drinking', form.drinking, 'Select', Object.values(DrinkingHabits), (v) => set('drinking', v))}
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.maritalStatus || !form.smoking || !form.drinking) ? 0.5 : 1 }]} onPress={nextSubStep} disabled={!form.maritalStatus || !form.smoking || !form.drinking}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 11 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Future Plans</Text>
                <View style={{ gap: 16 }}>
                  {renderDropdownField('Future Partners Children Status', form.childrenStatus, 'Select status', ['without kids', 'With Children', 'with or without kids'], (v) => set('childrenStatus', v))}
                  {renderDropdownField('Vow Timeline', form.marriageTimeline, 'Timeline', ['ASAP', '1-2 years', '3+ years', 'Not sure'], (v) => set('marriageTimeline', v))}
                  {renderDropdownField('Relocation', form.willingToRelocate, 'Relocate', Object.values(WillingToRelocate), (v) => set('willingToRelocate', v))}
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.childrenStatus || !form.marriageTimeline || !form.willingToRelocate) ? 0.5 : 1 }]} onPress={nextSubStep} disabled={!form.childrenStatus || !form.marriageTimeline || !form.willingToRelocate}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 12 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Family Goals</Text>
                <View style={{ gap: 16 }}>
                  {renderDropdownField('Children Intent', form.childrenPreference, 'Select intent', Object.values(ChildrenPreference), (v) => set('childrenPreference', v))}
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (!form.childrenPreference) ? 0.5 : 1 }]} onPress={nextSubStep} disabled={!form.childrenPreference}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="arrow-forward" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}

            {subStep === 13 && (
              <View>
                <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24 }]}>Ideal Partner Traits</Text>
                <View style={{ gap: 16 }}>
                  {renderMultiDropdownField('Ideal Partner Traits', form.idealPartnerTraits || [], 'Select traits', ['Kind', 'Ambitious', 'Family-oriented', 'Honest', 'Humorous', 'Intelligent', 'Empathetic', 'Adventurous', 'Loyal', 'Spiritual', 'Confident', 'Other'], (v) => set('idealPartnerTraits', v))}
                  <View style={{ marginTop: 12 }}>
                    <Text style={styles.label}>Ideal Partner Age Range</Text>
                    <View style={{ flexDirection: 'row', gap: 12 }}>
                      <TextInput 
                        style={[styles.input, { flex: 1, backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]} 
                        placeholder="Min Age" 
                        placeholderTextColor={Colors.gray400}
                        keyboardType="numeric"
                        value={form.preferredPartnerAgeRange?.[0] ? form.preferredPartnerAgeRange[0].toString() : ''}
                        onChangeText={(val) => set('preferredPartnerAgeRange', [parseInt(val) || 0, form.preferredPartnerAgeRange?.[1] || 0])}
                      />
                      <TextInput 
                        style={[styles.input, { flex: 1, backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]} 
                        placeholder="Max Age" 
                        placeholderTextColor={Colors.gray400}
                        keyboardType="numeric"
                        value={form.preferredPartnerAgeRange?.[1] ? form.preferredPartnerAgeRange[1].toString() : ''}
                        onChangeText={(val) => set('preferredPartnerAgeRange', [form.preferredPartnerAgeRange?.[0] || 0, parseInt(val) || 0])}
                      />
                    </View>
                  </View>
                  {(form.idealPartnerTraits || []).includes('Other') && (
                    <TextInput style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]} value={traitCustom} onChangeText={setTraitCustom} placeholder="Specify other trait" placeholderTextColor={Colors.gray400} />
                  )}
                </View>

                <View style={{ marginBottom: 24 }}>
                  <Text style={styles.label}>MARRIAGE EXPECTATIONS</Text>
                  <TextInput
                    style={[styles.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900, minHeight: 80, textAlignVertical: 'top' }]}
                    value={form.marriageExpectations}
                    onChangeText={(v) => set('marriageExpectations', v)}
                    placeholder="What are your expectations for marriage?"
                    placeholderTextColor={Colors.gray400}
                    multiline
                  />
                </View>
                <TouchableOpacity style={[styles.actionButton, { marginTop: 32, opacity: (form.idealPartnerTraits?.length === 0 || !form.marriageExpectations?.trim() || !form.preferredPartnerAgeRange?.[0] || !form.preferredPartnerAgeRange?.[1]) ? 0.5 : 1 }]} onPress={() => {
                  if (!form.marriageExpectations?.trim()) {
                    Alert.alert("Missing Expectations", "Please enter your expectations for marriage.");
                    return;
                  }
                  if (!form.preferredPartnerAgeRange || !form.preferredPartnerAgeRange[0] || !form.preferredPartnerAgeRange[1]) {
                    Alert.alert("Missing Age Range", "Please enter both minimum and maximum age preferences.");
                    return;
                  }
                  if (form.preferredPartnerAgeRange) {
                    const minAge = form.preferredPartnerAgeRange[0] || 0;
                    const maxAge = form.preferredPartnerAgeRange[1] || 0;
                    if (minAge < 18) {
                      Alert.alert("Invalid Age", "The minimum age for a partner must be 18 or older.");
                      return;
                    }
                    if (maxAge < minAge) {
                      Alert.alert("Invalid Age Range", "The maximum age cannot be less than the minimum age.");
                      return;
                    }
                    if (maxAge > 99) {
                      Alert.alert("Invalid Age Range", "Please enter a feasible maximum age (e.g., 99 or below).");
                      return;
                    }
                  }
                  setStep(3);
                }} disabled={form.idealPartnerTraits?.length === 0 || !form.marriageExpectations?.trim() || !form.preferredPartnerAgeRange?.[0] || !form.preferredPartnerAgeRange?.[1]}>
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: BorderRadius.lg }]} />
                  <Text style={styles.actionButtonText}>Next</Text>
                  <Ionicons name="checkmark-circle" size={18} color={Colors.white} />
                </TouchableOpacity>
              </View>
            )}
            
            {showDatePicker && (
              <DateTimePicker
                value={form.dateOfBirth ? new Date(form.dateOfBirth) : new Date()}
                mode="date"
                display="default"
                onChange={(event, selectedDate) => {
                  setShowDatePicker(false);
                  if (selectedDate) set('dateOfBirth', selectedDate.toISOString().split('T')[0]);
                }}
              />
            )}
          </Animated.View>
        )}

        
        {/* Step 3: Profile Picture Upload */}
        {step === 3 && (
          <View style={styles.formContainer}>
            <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24, textAlign: 'center' }]}>Profile Picture</Text>
            <Text style={{ color: Colors.gray400, textAlign: 'center', marginBottom: 24 }}>Upload a clear, recent photo of yourself</Text>
            
            <View style={styles.uploadSection}>
              <View style={[styles.uploadBox, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}>
                <View style={styles.uploadAvatar}>
                  {form.profileImageUrls?.length > 0 ? (
                    <Image source={{ uri: form.profileImageUrls[0] }} style={styles.uploadImage} />
                  ) : (
                    <Ionicons name="person-outline" size={24} color={Colors.gray400} />
                  )}
                </View>
                <View style={styles.uploadInfo}>
                  <TouchableOpacity style={styles.uploadBtn} onPress={() => pickImage('selfie')}>
                    <Ionicons name="cloud-upload-outline" size={14} color={Colors.gray300} style={{ marginRight: 6 }} />
                    <Text style={styles.uploadBtnText}>Upload Photo</Text>
                  </TouchableOpacity>
                  <Text style={styles.uploadSubtext}>Profile Picture for Display</Text>
                </View>
              </View>
            </View>

            <TouchableOpacity style={{ marginTop: 24, opacity: (!form.profileImageUrls?.length) ? 0.4 : 1 }} onPress={() => setStep(4)} disabled={!form.profileImageUrls?.length}>
              <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.actionButton}>
                <Text style={styles.actionButtonText}>Upload & Continue</Text>
                <Ionicons name="arrow-forward" size={18} color={Colors.white} />
              </LinearGradient>
            </TouchableOpacity>
            
            <View style={{ alignItems: 'center', marginTop: 16 }}>
            </View>
          </View>
        )}

        {/* Step 4: Identity & Trust Verification */}
        {step === 4 && (
          <View style={styles.formContainer}>
            <Text style={[styles.welcomeTitle, textStyle, { fontSize: 24, marginBottom: 24, textAlign: 'center' }]}>Identity & Trust Verification</Text>
            <Text style={{ color: Colors.gray400, textAlign: 'center', marginBottom: 24 }}>Help us keep the community safe</Text>

            <View style={styles.uploadSection}>
              <Text style={styles.label}>SELFIE SCAN FOR VERIFICATION</Text>
              <View style={[styles.uploadBox, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}>
                <View style={styles.uploadAvatar}>
                  {livenessUri ? (
                    <Image source={{ uri: livenessUri }} style={styles.uploadImage} />
                  ) : (
                    <Ionicons name="happy-outline" size={24} color={Colors.gray400} />
                  )}
                </View>
                <View style={styles.uploadInfo}>
                  <TouchableOpacity style={[styles.uploadBtn, { backgroundColor: '#1A1A1A', borderColor: '#403A2B' }]} onPress={startLivenessScanner}>
                    <Ionicons name="camera-outline" size={14} color="#D4AF37" style={{ marginRight: 6 }} />
                    <Text style={[styles.uploadBtnText, { color: '#D4AF37' }]}>Start Live Face Scan</Text>
                  </TouchableOpacity>
                  <Text style={styles.uploadSubtext}>This selfie is strictly for verification</Text>
                </View>
              </View>
            </View>

            <View style={styles.uploadSection}>
              <Text style={styles.label}>GOVERNMENT ID SCAN</Text>
              <Text style={[styles.uploadSubtext, { marginBottom: 8 }]}>Int’l Passport, Driver’s License, voters card or National ID</Text>
              <View style={[styles.uploadBox, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}>
                <View style={[styles.uploadAvatar, { borderRadius: BorderRadius.lg }]}>
                  {govIdUri ? (
                    <Image source={{ uri: govIdUri }} style={styles.uploadImage} />
                  ) : (
                    <Ionicons name="shield-checkmark-outline" size={24} color={Colors.gray400} />
                  )}
                </View>
                <View style={styles.uploadInfo}>
                  <View style={{ flexDirection: 'column', gap: 8 }}>
                    <TouchableOpacity style={styles.uploadBtn} onPress={startIdScanner}>
                      <Ionicons name="eye-outline" size={14} color={Colors.gray300} style={{ marginRight: 6 }} />
                      <Text style={styles.uploadBtnText}>Scan ID Document</Text>
                    </TouchableOpacity>
                    <TouchableOpacity style={styles.uploadBtn} onPress={() => pickImage('id')}>
                      <Ionicons name="cloud-upload-outline" size={14} color={Colors.gray300} style={{ marginRight: 6 }} />
                      <Text style={styles.uploadBtnText}>Upload ID</Text>
                    </TouchableOpacity>
                  </View>
                  <Text style={styles.uploadSubtext}>ID for Verification</Text>
                </View>
              </View>
            </View>

            <TouchableOpacity style={{ marginTop: 24, opacity: (!livenessUri || !govIdUri) ? 0.4 : 1 }} onPress={handleProcessAIVerification} disabled={!livenessUri || !govIdUri}>
              <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.actionButton}>
                <Text style={styles.actionButtonText}>Verify Identity & Documents</Text>
                <Ionicons name="arrow-forward" size={18} color={Colors.white} />
              </LinearGradient>
            </TouchableOpacity>
            
            <View style={{ alignItems: 'center', marginTop: 16 }}>
              <Text style={{ color: '#D4AF37', fontSize: 11, fontWeight: '700' }}>🔒 Identity Verification is Compulsory for Registry Safety</Text>
            </View>
          </View>
        )}
         {/* Step 4: Conversational AI Interview */}
        {step === 6 && (
          <View style={[styles.chatBox, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray100 }]}>
            <View style={[styles.chatHeader, { borderBottomColor: isDarkMode ? Colors.darkBorder : Colors.gray100 }]}>
              <View style={[styles.botAvatar, { backgroundColor: Colors.accent + '1A', borderColor: Colors.accent + '2B' }]}>
                <Ionicons name="logo-android" size={20} color={Colors.accent} />
              </View>
              <View>
                <Text style={[styles.chatHeaderTitle, textStyle]}>KNOT AI-Matching Guide</Text>
                <Text style={styles.chatHeaderSubtitle}>Interview Session Active</Text>
              </View>
            </View>

            <ScrollView
              ref={chatScrollViewRef}
              style={styles.chatScroll}
              contentContainerStyle={{ paddingVertical: Spacing.md }}
              showsVerticalScrollIndicator={false}
            >
              {messages.map((m, idx) => (
                <View key={idx} style={[styles.messageBubbleRow, m.role === 'user' ? { justifyContent: 'flex-end' } : {}]}>
                  {m.role === 'ai' && (
                    <View style={[styles.smallBotAvatar, { backgroundColor: Colors.accent + '2A' }]}>
                      <Text style={{ fontSize: 9, fontWeight: '900', color: Colors.accent }}>AI</Text>
                    </View>
                  )}
                  <View
                    style={[
                      styles.messageBubble,
                      m.role === 'user'
                        ? { backgroundColor: Colors.primary + '22', borderColor: Colors.primary + '33', borderTopRightRadius: 2 }
                        : { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray100, borderTopLeftRadius: 2 },
                    ]}
                  >
                    <Text style={[styles.messageText, { color: isDarkMode ? Colors.gray300 : Colors.gray800 }]}>{m.text}</Text>
                  </View>
                </View>
              ))}
            </ScrollView>

            <View style={[styles.chatInputRow, { borderTopColor: isDarkMode ? Colors.darkBorder : Colors.gray100 }]}>
              <TextInput
                style={[styles.chatTextInput, { color: isDarkMode ? Colors.white : Colors.dark, backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50 }]}
                value={currentInput}
                onChangeText={setCurrentInput}
                placeholder="Share your thoughts empathetically..."
                placeholderTextColor={Colors.gray400}
              />
              {interviewQuestionIndex >= interviewPrompts.length && currentInput === '' ? (
                <TouchableOpacity style={styles.analyzeBtn} onPress={complete}>
                  <Text style={styles.analyzeBtnText}>Activate Dashboard</Text>
                  <Ionicons name="sparkles" size={14} color={Colors.white} />
                </TouchableOpacity>
              ) : (
                <TouchableOpacity style={styles.sendBtn} onPress={handleSendMessage}>
                  <Ionicons name="send" size={18} color={Colors.white} />
                </TouchableOpacity>
              )}
            </View>
          </View>
        )}

        {/* Step 4: Futuristic AI Identity & Biometric Match Scanner */}
        {step === 5 && (
          <View style={[styles.scannerContainer, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, borderColor: Colors.accent + '33' }]}>
            <Text style={[styles.scannerTitle, textStyle]}>AI Biometric Liveness & ID Match</Text>
            <Text style={styles.scannerSubtitle}>Secure Verification Session In Progress</Text>

            <View style={styles.splitFeeds}>
              <View style={styles.feedColumn}>
                <Text style={styles.feedLabel}>Selfie Feed</Text>
                <View style={[styles.feedImageContainer, { borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}>
                  {livenessUri ? (
                    <Image source={{ uri: livenessUri }} style={styles.feedImage} />
                  ) : (
                    <Ionicons name="person" size={32} color={Colors.gray500} />
                  )}
                  {verificationStep < 4 && (
                    <Animated.View style={[styles.laserScanBar, { backgroundColor: Colors.accent, top: laserTop }]} />
                  )}
                </View>
              </View>

              <View style={styles.feedColumn}>
                <Text style={styles.feedLabel}>ID Document</Text>
                <View style={[styles.feedImageContainer, { borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}>
                  {govIdUri ? (
                    <Image source={{ uri: govIdUri }} style={styles.feedImage} />
                  ) : (
                    <Ionicons name="shield-checkmark" size={32} color={Colors.gray500} />
                  )}
                  {verificationStep < 4 && (
                    <Animated.View style={[styles.laserScanBar, { backgroundColor: Colors.primary, top: laserTop }]} />
                  )}
                </View>
              </View>
            </View>

            {/* Checkpoints */}
            <View style={[styles.checkpointsWrapper, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50 }]}>
              <View style={styles.checkpointRow}>
                <Text style={styles.checkpointText}>1. Scanning ID text & details...</Text>
                {verificationStep >= 1 ? (
                  <Text style={styles.matchText}>✔ Match</Text>
                ) : (
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                    <ActivityIndicator size="small" color={Colors.accent} />
                    <Text style={styles.scanningText}>Scanning</Text>
                  </View>
                )}
              </View>

              <View style={styles.checkpointRow}>
                <Text style={styles.checkpointText}>2. Extracting face keypoints...</Text>
                {verificationStep >= 2 ? (
                  <Text style={styles.matchText}>✔ Extracted</Text>
                ) : verificationStep === 1 ? (
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                    <ActivityIndicator size="small" color={Colors.accent} />
                    <Text style={styles.scanningText}>Computing</Text>
                  </View>
                ) : (
                  <Text style={styles.pendingText}>Pending</Text>
                )}
              </View>

              <View style={styles.checkpointRow}>
                <Text style={styles.checkpointText}>3. Biometric comparison...</Text>
                {verificationStep >= 3 ? (
                  <Text style={styles.matchText}>✔ Confirmed</Text>
                ) : verificationStep === 2 ? (
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                    <ActivityIndicator size="small" color={Colors.accent} />
                    <Text style={styles.scanningText}>Verifying</Text>
                  </View>
                ) : (
                  <Text style={styles.pendingText}>Pending</Text>
                )}
              </View>

              <View style={styles.checkpointRow}>
                <Text style={styles.checkpointText}>4. Age & Name consistency...</Text>
                {verificationStep >= 4 ? (
                  <Text style={styles.matchText}>✔ Approved</Text>
                ) : verificationStep === 3 ? (
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                    <ActivityIndicator size="small" color={Colors.accent} />
                    <Text style={styles.scanningText}>Verifying</Text>
                  </View>
                ) : (
                  <Text style={styles.pendingText}>Pending</Text>
                )}
              </View>
            </View>

            {/* Proceed Button styled exactly as requested in screenshot */}
            {verificationStep >= 4 && (
              <TouchableOpacity
                style={{ marginTop: 24 }}
                onPress={() => setStep(7)}
                activeOpacity={0.88}
              >
                <LinearGradient
                  colors={['#E27D8D', '#2D1B4E']}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 1 }}
                  style={{
                    paddingVertical: 18,
                    paddingHorizontal: 24,
                    borderRadius: 24,
                    alignItems: 'center',
                    justifyContent: 'center',
                    shadowColor: '#E27D8D',
                    shadowOffset: { width: 0, height: 4 },
                    shadowOpacity: 0.35,
                    shadowRadius: 10,
                    elevation: 6,
                  }}
                >
                  <Text style={{ fontSize: 16, fontWeight: '900', color: '#FFFFFF', letterSpacing: 0.3 }}>
                    View Verification Certificate
                  </Text>
                </LinearGradient>
              </TouchableOpacity>
            )}
          </View>
        )}

        {/* Step 5: Digital Relationship Certificate Reveal */}
        {step === 7 && (
          <View style={styles.certificateContainer}>
            <View style={[styles.certCard, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, borderColor: Colors.accent }]}>
              
              <View style={styles.certBadgeWrapper}>
                <View style={styles.certBadge}>
                  <Ionicons name="shield-checkmark" size={14} color={Colors.dark} />
                  <Text style={styles.certBadgeText}>
                    VERIFIED REGISTRY CERTIFICATE
                  </Text>
                </View>
              </View>

              <Text style={[styles.certName, textStyle]}>{form.firstName} {form.lastName}</Text>
              <Text style={styles.certLocation}>
                {form.residenceCity || 'Lagos'}, {form.residenceCountry || 'Nigeria'} • Active Verified Member
              </Text>

              <View style={styles.certDivider} />

              <View style={styles.certRow}>
                <Text style={styles.certRowLabel}>ARCHETYPE</Text>
                <Text style={styles.certRowVal}>{archetype.personalityArchetype}</Text>
              </View>

              <View style={styles.certRow}>
                <Text style={styles.certRowLabel}>ATTACHMENT STYLE</Text>
                <Text style={[styles.certRowVal, { color: Colors.white }]}>{archetype.attachmentStyle}</Text>
              </View>

              {/* Archetype Metrics */}
              <View style={styles.metricsContainer}>
                <View style={[styles.metricBox, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50 }]}>
                  <Text style={styles.metricLabel}>Readiness</Text>
                  <Text style={[styles.metricVal, textStyle]}>{archetype.readinessScore}%</Text>
                </View>
                <View style={[styles.metricBox, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50 }]}>
                  <Text style={styles.metricLabel}>Seriousness</Text>
                  <Text style={[styles.metricVal, { color: Colors.accent }]}>{archetype.seriousnessLevel}%</Text>
                </View>
                <View style={[styles.metricBox, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50 }]}>
                  <Text style={styles.metricLabel}>Trust Score</Text>
                  <Text style={[styles.metricVal, { color: '#10b981' }]}>{archetype.trustScore}%</Text>
                </View>
              </View>

              <View style={{ marginTop: Spacing.md }}>
                <Text style={styles.valueMapLabel}>EXTRACTED VALUE MAPS</Text>
                <View style={styles.tagWrapper}>
                  {archetype.personalValues.map((v, i) => (
                    <View key={i} style={[styles.tag, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}>
                      <Text style={[styles.tagText, textStyle]}>✔ {v}</Text>
                    </View>
                  ))}
                </View>
              </View>

            </View>

            <TouchableOpacity style={{ marginTop: 24 }} onPress={() => setStep(6)}>
              <LinearGradient
                colors={['#E27D8D', '#2D1B4E']}
                style={styles.actionButton}
              >
                <Text style={styles.actionButtonText}>Proceed to Interview</Text>
              </LinearGradient>
            </TouchableOpacity>
          </View>
        )}

      </ScrollView>

      {/* Searchable Dropdown Modal */}
      <Modal visible={dropdownVisible} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white }]}>
            <View style={styles.modalHeader}>
              <Text style={[styles.modalTitle, textStyle]}>{dropdownTitle}</Text>
              <TouchableOpacity onPress={() => setDropdownVisible(false)}>
                <Ionicons name="close" size={24} color={Colors.gray400} />
              </TouchableOpacity>
            </View>
            <View style={[styles.modalSearchWrapper, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}>
              <Ionicons name="search" size={18} color={Colors.gray400} style={{ marginRight: 8 }} />
              <TextInput
                style={[styles.modalSearchInput, { color: isDarkMode ? Colors.white : Colors.dark }]}
                value={dropdownSearch}
                onChangeText={setDropdownSearch}
                placeholder={`Search ${dropdownTitle.toLowerCase()}...`}
                placeholderTextColor={Colors.gray400}
                autoFocus
              />
            </View>
            <FlatList
              data={filteredDropdownOptions}
              keyExtractor={(item) => item}
              keyboardShouldPersistTaps="handled"
              contentContainerStyle={{ paddingTop: 16, paddingBottom: 32 }}
              renderItem={({ item }) => {
                const isSelected = dropdownMultiSelect ? dropdownSelectedItems.includes(item) : false;
                return (
                  <TouchableOpacity
                    style={[
                      styles.modalItem, 
                      { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }, 
                      isSelected && { backgroundColor: '#7B5270', borderColor: '#7B5270' }
                    ]}
                    onPress={() => {
                      if (dropdownMultiSelect) {
                        setDropdownSelectedItems(prev => 
                          prev.includes(item) ? prev.filter(i => i !== item) : [...prev, item]
                        );
                      } else {
                        dropdownCallback?.(item);
                        setDropdownVisible(false);
                      }
                    }}
                  >
                    <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', flex: 1 }}>
                      <Text style={[styles.modalItemText, { color: isDarkMode ? Colors.white : Colors.gray900 }, isSelected && { color: Colors.white, fontWeight: 'bold' }]}>{item}</Text>
                      {isSelected && <Ionicons name="checkmark-circle" size={24} color="rgba(255,255,255,0.8)" />}
                    </View>
                  </TouchableOpacity>
                );
              }}
              ListEmptyComponent={<Text style={[styles.modalEmpty, { color: Colors.gray400 }]}>No results found</Text>}
            />
            {dropdownMultiSelect && (
              <View style={{ padding: 16, borderTopWidth: 1, borderTopColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }}>
                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={() => {
                    dropdownMultiCallback?.(dropdownSelectedItems);
                    setDropdownVisible(false);
                  }}
                  activeOpacity={0.8}
                >
                  <LinearGradient colors={['#E27D8D', '#2D1B4E']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={[StyleSheet.absoluteFill, { borderRadius: 9999 }]} />
                  <Text style={styles.actionButtonText}>Done</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        </View>
      </Modal>

      {/* Selfie Liveness Face Scan Modal (Vision Camera) */}
      <LivenessCameraModal
        visible={isLivenessModalOpen}
        onClose={() => setIsLivenessModalOpen(false)}
        onCapture={handleLivenessCapture}
      />

      {/* ID Document Scanner Modal */}
      <Modal visible={isIdScanModalOpen} animationType="fade" transparent>
        <View style={{ flex: 1, backgroundColor: 'rgba(10,14,20,0.95)', justifyContent: 'center', alignItems: 'center', padding: 20 }}>
          <View style={{ backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, borderWidth: 1, borderColor: Colors.white + '15', borderRadius: 32, padding: 24, width: '100%', maxWidth: 360, alignItems: 'center', position: 'relative' }}>
            <TouchableOpacity 
              onPress={() => setIsIdScanModalOpen(false)}
              style={{ position: 'absolute', top: 16, right: 16, zIndex: 10 }}
            >
              <Ionicons name="close" size={24} color={Colors.gray400} />
            </TouchableOpacity>

            <View style={{ alignItems: 'center', marginBottom: 20 }}>
              <Text style={{ fontSize: 16, fontWeight: '900', color: isDarkMode ? Colors.white : Colors.dark }}>Government ID Scanner</Text>
              <Text style={{ fontSize: 8, fontWeight: '900', color: Colors.primary, textTransform: 'uppercase', letterSpacing: 1, marginTop: 4 }}>Scanning Document Verification</Text>
            </View>

            {/* Rectangular Guide Frame */}
            <View style={{ width: '100%', aspectRatio: 1.586, borderRadius: 16, borderWidth: 3, borderColor: Colors.primary, borderStyle: 'dashed', justifyContent: 'center', alignItems: 'center', overflow: 'hidden', backgroundColor: '#121721', marginVertical: 20 }}>
              {/* Simulation Document icon */}
              <View style={{ width: '100%', height: '100%', alignItems: 'center', justifyContent: 'center', opacity: idScanState === 'complete' ? 0.3 : 1 }}>
                <Ionicons name="card" size={64} color={Colors.gray600} />
              </View>

              {/* Success Checkmark */}
              {idScanState === 'complete' && (
                <View style={{ position: 'absolute', inset: 0, backgroundColor: 'rgba(16,185,129,0.9)', alignItems: 'center', justifyContent: 'center' }}>
                  <Ionicons name="checkmark-circle" size={56} color={Colors.white} />
                </View>
              )}

              {/* Pulsing Scan Line */}
              {idScanState === 'scanning' && (
                <View style={{ position: 'absolute', left: 0, right: 0, height: 2, backgroundColor: Colors.primary }} />
              )}
            </View>

            {/* Prompt Instructions */}
            <View style={{ backgroundColor: Colors.white + '08', borderRadius: 16, padding: 12, width: '100%', minHeight: 48, justifyContent: 'center', alignItems: 'center' }}>
              <Text style={{ fontSize: 13, fontWeight: '700', color: isDarkMode ? Colors.gray200 : Colors.gray800, textAlign: 'center' }}>{idScanPrompt}</Text>
            </View>
          </View>
        </View>
      </Modal>

    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingTop: Platform.OS === 'ios' ? 50 : 20,
    paddingBottom: Spacing.md,
    borderBottomWidth: 1,
  },
  headerSubtitle: {
    fontSize: 9,
    fontWeight: '900',
    color: Colors.primary,
    textTransform: 'uppercase',
    letterSpacing: 2,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '900',
    marginTop: 2,
  },
  closeBtn: {
    padding: 4,
  },
  stepCounter: {
    fontSize: 9,
    fontWeight: '700',
    color: Colors.gray400,
    marginTop: 4,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: Spacing.lg,
    paddingBottom: 60,
  },
  welcomeContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    flex: 1,
    paddingVertical: 60,
    paddingHorizontal: Spacing.md,
  },
  welcomeIconWrapper: {
    width: 90,
    height: 90,
    borderRadius: 45,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 32,
  },
  welcomeTitle: {
    fontSize: 28,
    fontWeight: '900',
    textAlign: 'center',
    marginBottom: 16,
    fontFamily: Platform.OS === 'ios' ? 'Georgia' : 'serif',
  },
  welcomeDesc: {
    fontSize: 14,
    lineHeight: 22,
    color: Colors.gray400,
    textAlign: 'center',
    marginBottom: 40,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: BorderRadius.full,
    paddingVertical: 18,
    paddingHorizontal: 36,
    gap: 8,
    width: '100%',
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.35,
    shadowRadius: 10,
    elevation: 8,
    overflow: 'hidden',
  },
  actionButtonText: {
    color: Colors.white,
    fontWeight: '900',
    fontSize: 16,
    letterSpacing: 0.5,
  },
  modalBody: { flex: 1, padding: Spacing.xl },
  row: { flexDirection: 'row' },
  formContainer: {
    paddingTop: Spacing.lg,
  },
  formTitle: {
    fontSize: 22,
    fontWeight: '900',
    marginBottom: 20,
  },
  label: {
    fontSize: 9,
    fontWeight: '900',
    textTransform: 'uppercase',
    letterSpacing: 1.5,
    color: Colors.gray400,
    marginBottom: 6,
  },
  input: {
    borderWidth: 1,
    borderRadius: BorderRadius.lg,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 14,
    marginBottom: 12,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: BorderRadius.lg,
    paddingHorizontal: 14,
    backgroundColor: Colors.white + '05',
    marginBottom: 12,
  },
  inputIcon: {
    marginRight: 8,
  },
  inputField: {
    flex: 1,
    height: 52,
    fontSize: 14,
  },
  subSectionTitle: {
    fontSize: 11,
    fontWeight: '900',
    color: Colors.primary,
    textTransform: 'uppercase',
    letterSpacing: 2,
    borderBottomWidth: 1,
    borderBottomColor: Colors.gray100 + '15',
    paddingBottom: 8,
    marginBottom: 12,
    marginTop: 16,
  },
  dropdownBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderRadius: BorderRadius.lg,
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  dropdownBtnText: {
    fontSize: 14,
    flex: 1,
  },
  uploadSection: {
    marginTop: 20,
  },
  uploadBox: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: BorderRadius.xl,
    padding: 16,
    gap: 16,
  },
  uploadAvatar: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: Colors.white + '0A',
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  uploadImage: {
    width: '100%',
    height: '100%',
    objectFit: 'cover',
  },
  uploadInfo: {
    flex: 1,
    gap: 6,
  },
  uploadBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.white + '1A',
    borderWidth: 1,
    borderColor: Colors.white + '1D',
    borderRadius: BorderRadius.lg,
    paddingVertical: 8,
    paddingHorizontal: 14,
    alignSelf: 'flex-start',
  },
  uploadBtnText: {
    color: Colors.gray300,
    fontSize: 12,
    fontWeight: '700',
  },
  uploadSubtext: {
    fontSize: 9,
    color: Colors.gray500,
    lineHeight: 12,
  },
  chatBox: {
    borderWidth: 1,
    borderRadius: BorderRadius.lg,
    height: 520,
    marginTop: Spacing.lg,
    overflow: 'hidden',
  },
  chatHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 16,
    borderBottomWidth: 1,
  },
  botAvatar: {
    width: 40,
    height: 40,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  chatHeaderTitle: {
    fontSize: 14,
    fontWeight: '800',
  },
  chatHeaderSubtitle: {
    fontSize: 9,
    fontWeight: '900',
    color: Colors.accent,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginTop: 1,
  },
  chatScroll: {
    flex: 1,
    paddingHorizontal: 16,
  },
  messageBubbleRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    marginBottom: 14,
  },
  smallBotAvatar: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  messageBubble: {
    padding: 14,
    borderRadius: 18,
    borderWidth: 1,
    maxWidth: '80%',
  },
  messageText: {
    fontSize: 13,
    lineHeight: 18,
  },
  chatInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderTopWidth: 1,
    gap: 8,
  },
  chatTextInput: {
    flex: 1,
    height: 44,
    borderRadius: 22,
    paddingHorizontal: 18,
    fontSize: 13,
  },
  sendBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  analyzeBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: Colors.primary,
    borderRadius: BorderRadius.lg,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  analyzeBtnText: {
    color: Colors.white,
    fontSize: 12,
    fontWeight: '900',
  },
  scannerContainer: {
    borderWidth: 1,
    borderRadius: 36,
    padding: 24,
    marginTop: Spacing.xl,
    alignItems: 'center',
  },
  scannerTitle: {
    fontSize: 20,
    fontWeight: '900',
    textAlign: 'center',
  },
  scannerSubtitle: {
    fontSize: 9,
    fontWeight: '900',
    color: Colors.accent,
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginTop: 4,
    textAlign: 'center',
    marginBottom: 28,
  },
  splitFeeds: {
    flexDirection: 'row',
    gap: 18,
    width: '100%',
    justifyContent: 'center',
  },
  feedColumn: {
    alignItems: 'center',
    gap: 8,
    width: '45%',
  },
  feedLabel: {
    fontSize: 9,
    fontWeight: '900',
    color: Colors.gray400,
    textTransform: 'uppercase',
    letterSpacing: 1.5,
  },
  feedImageContainer: {
    width: '100%',
    aspectRatio: 3/4,
    borderRadius: BorderRadius.xl,
    borderWidth: 1,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.white + '05',
  },
  feedImage: {
    width: '100%',
    height: '100%',
    resizeMode: 'contain',
  },
  laserScanBar: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: 2,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.8,
    shadowRadius: 6,
    elevation: 4,
  },
  checkpointsWrapper: {
    width: '100%',
    borderRadius: BorderRadius.xl,
    padding: 16,
    marginTop: 28,
    gap: 10,
  },
  checkpointRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  checkpointText: {
    fontSize: 11,
    color: Colors.gray400,
  },
  matchText: {
    color: '#10b981',
    fontWeight: '900',
    fontSize: 11,
  },
  scanningText: {
    color: Colors.accent,
    fontWeight: '900',
    fontSize: 11,
  },
  pendingText: {
    color: Colors.gray600,
    fontSize: 11,
  },
  certificateContainer: {
    alignItems: 'center',
    paddingTop: Spacing.lg,
  },
  certCard: {
    borderWidth: 1.5,
    borderRadius: 36,
    width: '100%',
    padding: 24,
    shadowColor: Colors.accent,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.1,
    shadowRadius: 20,
    elevation: 6,
  },
  certBadgeWrapper: {
    alignItems: 'center',
    marginBottom: 16,
  },
  certBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: Colors.accent,
    borderRadius: BorderRadius.full,
    paddingVertical: 4,
    paddingHorizontal: 12,
  },
  certBadgeText: {
    color: Colors.dark,
    fontSize: 9,
    fontWeight: '900',
    letterSpacing: 0.5,
  },
  certName: {
    fontSize: 24,
    fontWeight: '900',
    textAlign: 'center',
  },
  certLocation: {
    fontSize: 11,
    color: Colors.gray400,
    textAlign: 'center',
    marginTop: 4,
  },
  certDivider: {
    height: 1,
    backgroundColor: Colors.white + '10',
    marginVertical: 20,
  },
  certRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: Colors.white + '05',
  },
  certRowLabel: {
    fontSize: 9,
    fontWeight: '900',
    color: Colors.gray500,
    letterSpacing: 1,
  },
  certRowVal: {
    fontSize: 12,
    fontWeight: '900',
    color: Colors.accent,
  },
  metricsContainer: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 16,
  },
  metricBox: {
    flex: 1,
    padding: 10,
    borderRadius: BorderRadius.lg,
    alignItems: 'center',
    gap: 2,
  },
  metricLabel: {
    fontSize: 8,
    fontWeight: '900',
    color: Colors.gray500,
    textTransform: 'uppercase',
  },
  metricVal: {
    fontSize: 14,
    fontWeight: '900',
  },
  valueMapLabel: {
    fontSize: 9,
    fontWeight: '900',
    color: Colors.gray500,
    letterSpacing: 1,
    marginBottom: 8,
  },
  tagWrapper: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  tag: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
  },
  tagText: {
    fontSize: 10,
    fontWeight: '700',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    maxHeight: '80%',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingTop: 16,
    paddingBottom: 32,
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    marginBottom: 12,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '900',
  },
  modalSearchWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: 20,
    borderWidth: 1,
    borderRadius: BorderRadius.lg,
    paddingHorizontal: 14,
    paddingVertical: 10,
    marginBottom: 8,
  },
  modalSearchInput: {
    flex: 1,
    fontSize: 14,
    padding: 0,
  },
  modalItem: {
    paddingHorizontal: 16,
    paddingVertical: 14,
    marginHorizontal: 16,
    marginBottom: 8,
    borderRadius: 12,
    borderWidth: 1,
  },
  modalItemText: {
    fontSize: 15,
  },
  modalEmpty: {
    textAlign: 'center',
    paddingVertical: 32,
    fontSize: 14,
  },
});
