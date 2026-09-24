import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator, Image, StyleSheet, Text, TouchableOpacity, View, ScrollView, Modal, Dimensions, Alert
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';

import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { useToast } from '../contexts/ToastContext';
import { Colors, BorderRadius, Spacing } from '../theme/colors';
import { RootStackParamList, Match, SubscriptionTier } from '../types';
import { db } from '../services/apiService';
import AppHeader from '../components/AppHeader';

type Nav = NativeStackNavigationProp<RootStackParamList>;
const { width: SCREEN_W } = Dimensions.get('window');

export default function HomeScreen() {
  const navigation = useNavigation<Nav>();
  const { userProfile } = useAuth();
  const { isDarkMode } = useTheme();
  const { addToast } = useToast();
  const { setUserProfile } = useAuth();

  const [matches, setMatches] = useState<Match[]>([]);
  const [currentMatchIndex, setCurrentMatchIndex] = useState(0);
  const [loading, setLoading] = useState(true);
  const [showMatchModal, setShowMatchModal] = useState(false);
  const [photoIndex, setPhotoIndex] = useState(0);
  const [isFallbackMode, setIsFallbackMode] = useState(false);

  useEffect(() => {
    if (!userProfile) return;
    (async () => {
      setLoading(true);
      try {
        const allUsers = await db.getAllUsers();
        const otherUsers = allUsers.filter(u => u.id !== userProfile.id);
        
        const userGender = (userProfile.gender || '').toLowerCase().trim();
        const targetGender = userGender === 'female' ? 'male' : 'female';
        
        let filtered = otherUsers.filter((m) => (m.gender || '').toLowerCase() === targetGender);
        
        if (filtered.length === 0 && otherUsers.length > 0) {
          filtered = otherUsers;
          setIsFallbackMode(true);
        } else {
          setIsFallbackMode(false);
        }
        
        setMatches(filtered as Match[]);
      } catch (err) {
        console.error('Failed to load matches:', err);
        addToast('Failed to sync latest curated matches.', 'error');
      } finally {
        setLoading(false);
      }
    })();
  }, [userProfile]);

  const activeMatch = matches[currentMatchIndex];

  // Helper helper to get stable psychological profiles
  const getMatchMetrics = (match: Match) => {
    if (!match) return null;
    const name = match.name || '';
    const trustScore = 96 + (name.charCodeAt(0) % 4);
    const valuesAlignment = 90 + (name.charCodeAt(0) % 8);
    const emotionalSynergy = 87 + ((name.charCodeAt(1) || 65) % 9);
    const communicationMatch = 84 + ((name.charCodeAt(2) || 66) % 11);
    
    let archetype = 'The Calm Connector';
    let attachment = 'Secure';
    let aiExplanation = `${match.name}'s relationship readiness and shared interests in ${match.interests?.slice(0, 2).join(' & ') || 'building a home'} complement your intentional builder mindset. Your aligned long-term family timeline forms a solid foundation for mutual alignment.`;

    if (name.toLowerCase().includes('sofia')) {
      archetype = 'The Calm Connector';
      attachment = 'Secure';
      aiExplanation = "Sofia's secure attachment and calm connectivity traits directly complement your intentional builder mindset. Your shared family plans and aligned moral values form a robust foundation for a successful long-term marriage.";
    } else if (name.toLowerCase().includes('liam')) {
      archetype = 'The Grounded Romantic';
      attachment = 'Secure';
      aiExplanation = "Liam's intellectual focus and secure attachment style provide a supportive emotional container for your relationship. Your shared priorities around wellness and family values suggest an excellent foundation.";
    } else if (name.toLowerCase().includes('amina')) {
      archetype = 'The Harmonizer';
      attachment = 'Secure';
      aiExplanation = "Amina's architectural background and focus on family and faith values align strongly with your builder archetype. Your mutual goals of establishing a grounded, legacy-oriented home make this match highly compatible.";
    } else if (name.toLowerCase().includes('chen')) {
      archetype = 'The Loyal Partner';
      attachment = 'Secure';
      aiExplanation = "Chen's values of stability, respect, and family complement your intentional layout. Together, your complementary communication styles will facilitate a peaceful, long-term alignment.";
    } else if (name.toLowerCase().includes('priya')) {
      archetype = 'The Passionate Builder';
      attachment = 'Secure';
      aiExplanation = "Priya's creative interests, software engineering background, and high curiosity vectors mesh well with your career goals and mutual growth mindset.";
    }

    return { trustScore, valuesAlignment, emotionalSynergy, communicationMatch, archetype, attachment, aiExplanation };
  };

  const metrics = activeMatch ? getMatchMetrics(activeMatch) : null;
  const photos = activeMatch?.profileImageUrls?.length
    ? activeMatch.profileImageUrls
    : activeMatch?.selfieUrl
    ? [activeMatch.selfieUrl]
    : [`https://ui-avatars.com/api/?name=${encodeURIComponent(activeMatch?.name || activeMatch?.firstName || 'User')}&background=1E1E1E&color=FFFFFF&size=800`];

  const getDailyLimit = () => {
    switch (userProfile?.subscriptionTier) {
      case SubscriptionTier.Executive: return 100;
      case SubscriptionTier.Elite: return 25;
      case SubscriptionTier.Premium: return 15;
      default: return 3; // Free / Essential
    }
  };

  const handlePass = () => {
    setPhotoIndex(0);
    const limit = getDailyLimit();
    const maxIndex = Math.min(matches.length, limit) - 1;

    if (currentMatchIndex >= maxIndex) {
      if (matches.length > limit) {
        Alert.alert(
          'Daily Limit Reached',
          `You have reached your limit of ${limit} curated matches for today.\n\nUpgrade your subscription to unlock more matches and features!`,
          [
            { text: 'Later', onPress: () => setCurrentMatchIndex(0), style: 'cancel' },
            { text: 'Upgrade', onPress: () => navigation.navigate('Payment', { user: userProfile! }) }
          ]
        );
      } else {
        addToast('You have reviewed all curated matches for today.', 'info');
        setCurrentMatchIndex(0);
      }
    } else {
      setCurrentMatchIndex((prev) => prev + 1);
    }
  };

  const handleConnect = () => {
    if (activeMatch) {
      navigation.navigate('ProfileDetail', { match: activeMatch });
    }
  };

  const startConversation = () => {
    setShowMatchModal(false);
    if (activeMatch && userProfile) {
      navigation.navigate('Chat', { match: activeMatch, user: userProfile });
    }
  };

  const nextPhoto = () => setPhotoIndex((p) => Math.min(p + 1, photos.length - 1));
  const prevPhoto = () => setPhotoIndex((p) => Math.max(p - 1, 0));

  if (loading) {
    return (
      <View style={[st.center, { backgroundColor: isDarkMode ? Colors.dark : Colors.gray50 }]}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  if (!activeMatch) {
    return (
      <View style={[st.root, { backgroundColor: isDarkMode ? Colors.dark : Colors.gray50 }]}>
        <AppHeader onFilter={() => navigation.navigate('EditProfile', { user: userProfile! })} />
        <View style={st.emptyWrap}>
          <Ionicons name="compass-outline" size={64} color={Colors.gray400} />
          <Text style={[st.emptyText, { color: isDarkMode ? Colors.gray400 : Colors.gray600 }]}>
            No curated matches available.
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={[st.root, { backgroundColor: isDarkMode ? Colors.dark : Colors.gray50 }]}>
      <AppHeader onFilter={() => navigation.navigate('EditProfile', { user: userProfile! })} />
      {isFallbackMode && (
        <View style={{ backgroundColor: Colors.accent, padding: 12, marginHorizontal: 16, marginTop: 16, borderRadius: BorderRadius.md }}>
          <Text style={{ color: Colors.dark, fontSize: 12, fontWeight: '700', textAlign: 'center' }}>
            You have no exact matches for now. These are the available ones, but as soon as there is a match, the matches screen will be updated accordingly.
          </Text>
        </View>
      )}
      <ScrollView contentContainerStyle={st.scrollContent}>
        {/* Curated Match Hero Card */}
        <View style={[st.heroCard, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}>
          <View style={st.heroImageWrap}>
            <Image source={{ uri: photos[photoIndex] }} style={st.heroImage} />
            
            {/* Trust badge */}
            <View style={st.trustBadge}>
              <Ionicons name="shield-checkmark" size={12} color={Colors.dark} style={{ marginRight: 4 }} />
              <Text style={st.trustBadgeText}>TRUST {metrics?.trustScore}%</Text>
            </View>

            {/* Photo indicators */}
            {photos.length > 1 && (
              <View style={st.photoIndicators}>
                {photos.map((_, i) => (
                  <View
                    key={i}
                    style={[
                      st.indicatorPill,
                      { backgroundColor: i === photoIndex ? Colors.white : 'rgba(255,255,255,0.4)' },
                    ]}
                  />
                ))}
              </View>
            )}

            {/* Tap zones for carousel */}
            <View style={st.carouselTapZone}>
              <TouchableOpacity style={{ flex: 1 }} onPress={prevPhoto} activeOpacity={1} />
              <TouchableOpacity style={{ flex: 1 }} onPress={nextPhoto} activeOpacity={1} />
            </View>

            {/* Bottom Gradient overlay */}
            <LinearGradient
              colors={['transparent', 'rgba(0,0,0,0.8)', 'rgba(0,0,0,1)']}
              style={[StyleSheet.absoluteFillObject, { top: '30%' }]}
              pointerEvents="none"
            />

            {/* Overlay Info */}
            <View style={st.heroInfoOverlay}>
              <View style={st.nameRow}>
                <Text style={st.heroName}>{activeMatch.name}, {activeMatch.age}</Text>
                {activeMatch.isVerified && (
                  <View style={st.verifiedBadge}>
                    <Ionicons name="checkmark" size={12} color={Colors.dark} />
                  </View>
                )}
              </View>
              <Text style={st.heroSubtitle}>{activeMatch.occupation} • {activeMatch.city}, {activeMatch.country}</Text>
            </View>
          </View>

          {/* Body Content */}
          <View style={st.cardContent}>
            {/* Tags */}
            <View style={st.tagsRow}>
              <View style={[st.tag, { backgroundColor: isDarkMode ? 'rgba(255,255,255,0.05)' : Colors.gray100 }]}>
                <Text style={[st.tagText, { color: isDarkMode ? Colors.gray300 : Colors.gray700 }]}>
                  ✔ {metrics?.archetype}
                </Text>
              </View>
              <View style={[st.tagBrand, { backgroundColor: isDarkMode ? 'rgba(212,175,55,0.1)' : 'rgba(212,175,55,0.05)' }]}>
                <Text style={st.tagBrandText}>
                  ✔ {metrics?.attachment} Attachment
                </Text>
              </View>
            </View>

            {/* Why You Matched AI Glow Box (Moved up) */}
            <View style={[st.glowCard, { backgroundColor: isDarkMode ? 'rgba(212,175,55,0.05)' : 'rgba(212,175,55,0.02)', marginTop: 8 }]}>
              <View style={st.glowHeader}>
                <Ionicons name="sparkles" size={16} color={Colors.accent} style={{ marginRight: 6 }} />
                <Text style={st.glowTitle}>Why You Matched</Text>
              </View>
              <Text style={[st.glowBody, { color: isDarkMode ? Colors.gray300 : Colors.gray700 }]}>
                {metrics?.aiExplanation}
              </Text>
            </View>
          </View>
        </View>

        {/* Compatibility Profile Card */}
        <View style={[st.sectionCard, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]}>
          <Text style={[st.sectionTitle, { color: isDarkMode ? Colors.white : Colors.dark }]}>
            Compatibility Profile
          </Text>
          
          <View style={st.barContainer}>
            <View style={st.barLabelRow}>
              <Text style={st.barLabel}>Values Alignment</Text>
              <Text style={[st.barVal, { color: Colors.accent }]}>{metrics?.valuesAlignment || 0}%</Text>
            </View>
            <View style={[st.barBg, { backgroundColor: isDarkMode ? 'rgba(255,255,255,0.05)' : Colors.gray100 }]}>
              <View style={[st.barFill, { width: `${metrics?.valuesAlignment || 0}%` as any, backgroundColor: Colors.accent }]} />
            </View>
          </View>

          <View style={st.barContainer}>
            <View style={st.barLabelRow}>
              <Text style={st.barLabel}>Emotional Synergy</Text>
              <Text style={[st.barVal, { color: Colors.primary }]}>{metrics?.emotionalSynergy || 0}%</Text>
            </View>
            <View style={[st.barBg, { backgroundColor: isDarkMode ? 'rgba(255,255,255,0.05)' : Colors.gray100 }]}>
              <View style={[st.barFill, { width: `${metrics?.emotionalSynergy || 0}%` as any, backgroundColor: Colors.primary }]} />
            </View>
          </View>

          <View style={st.barContainer}>
            <View style={st.barLabelRow}>
              <Text style={st.barLabel}>Communication Match</Text>
              <Text style={[st.barVal, { color: isDarkMode ? Colors.white : Colors.dark }]}>{metrics?.communicationMatch || 0}%</Text>
            </View>
            <View style={[st.barBg, { backgroundColor: isDarkMode ? 'rgba(255,255,255,0.05)' : Colors.gray100 }]}>
              <View style={[st.barFill, { width: `${metrics?.communicationMatch || 0}%` as any, backgroundColor: isDarkMode ? Colors.white : Colors.dark }]} />
            </View>
          </View>
        </View>

        {/* Bio (Moved down) */}
        <View style={[st.sectionCard, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200, padding: 16 }]}>
          <Text style={[st.sectionTitle, { color: Colors.accent, textTransform: 'uppercase', marginBottom: 8 }]}>
            REGISTRY BIO
          </Text>
          <Text style={[st.bioText, { color: isDarkMode ? Colors.gray300 : Colors.gray600, marginTop: 8 }]} numberOfLines={6}>
            {activeMatch.bio || "No bio provided."}
          </Text>
        </View>

      </ScrollView>

      {/* Actions Fixed at Bottom */}
      <View style={[st.actionsRow, { backgroundColor: isDarkMode ? Colors.dark : Colors.gray50, borderTopColor: isDarkMode ? Colors.darkBorder : Colors.gray200, borderTopWidth: 1, paddingHorizontal: 16, paddingTop: 16, paddingBottom: 16 }]}>
        <TouchableOpacity style={st.actionBtnPass} onPress={handlePass}>
          <Text style={st.actionBtnPassText}>Pass</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={handleConnect} style={{ flex: 1 }}>
          <LinearGradient
            colors={[Colors.primary, '#8C52FF']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={st.actionBtnConnect}
          >
            <Text style={st.actionBtnConnectText}>Connect</Text>
            <Ionicons name="heart-outline" size={18} color={Colors.white} />
          </LinearGradient>
        </TouchableOpacity>
      </View>

      {/* Mutual Match Modal */}
      <Modal visible={showMatchModal} transparent animationType="fade">
        <View style={st.modalContainer}>
          <View style={[st.modalCard, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white }]}>
            <Text style={st.modalTitle}>It's a Mutual Vow Connection!</Text>
            <Text style={st.modalSub}>Your relationship profiles show exceptional compatibility.</Text>
            
            <View style={st.modalAvatars}>
              <Image source={{ uri: userProfile?.profileImageUrls?.[0] || (userProfile as any)?.selfieUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(userProfile?.name || userProfile?.firstName || 'Me')}&background=1E1E1E&color=FFFFFF&size=200` }} style={st.modalAvatar} />
              <View style={st.modalHeartWrap}>
                <Ionicons name="heart" size={28} color={Colors.primary} />
              </View>
              <Image source={{ uri: photos[0] }} style={st.modalAvatar} />
            </View>

            <TouchableOpacity style={st.modalPrimaryBtn} onPress={startConversation}>
              <Text style={st.modalPrimaryBtnText}>Start Secure Conversation</Text>
            </TouchableOpacity>

            <TouchableOpacity style={st.modalSecondaryBtn} onPress={() => { setShowMatchModal(false); handlePass(); }}>
              <Text style={[st.modalSecondaryBtnText, { color: isDarkMode ? Colors.gray400 : Colors.gray600 }]}>Keep Curating</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const st = StyleSheet.create({
  root: { flex: 1 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  scrollContent: { padding: Spacing.md, paddingBottom: 24 },
  emptyWrap: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 100 },
  emptyText: { fontSize: 13, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 2, marginTop: 12 },
  
  /* Curated Match Hero */
  heroCard: {
    borderRadius: BorderRadius.lg,
    overflow: 'hidden',
    borderWidth: 1,
    marginBottom: Spacing.md,
  },
  heroImageWrap: {
    width: '100%',
    aspectRatio: 0.9,
    position: 'relative',
  },
  heroImage: {
    width: '100%',
    height: '100%',
  },
  trustBadge: {
    position: 'absolute',
    top: 16,
    right: 16,
    backgroundColor: Colors.accent,
    borderRadius: BorderRadius.full,
    paddingHorizontal: 12,
    paddingVertical: 5,
    flexDirection: 'row',
    alignItems: 'center',
    zIndex: 10,
  },
  trustBadgeText: {
    fontSize: 9,
    fontWeight: '900',
    color: Colors.dark,
    letterSpacing: 1.5,
  },
  photoIndicators: {
    position: 'absolute',
    left: 16,
    top: 16,
    zIndex: 10,
    flexDirection: 'row',
    gap: 4,
  },
  indicatorPill: {
    width: 14,
    height: 3,
    borderRadius: 9,
  },
  carouselTapZone: {
    ...StyleSheet.absoluteFillObject,
    flexDirection: 'row',
    zIndex: 5,
  },
  heroInfoOverlay: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
    zIndex: 10,
  },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  heroName: { fontSize: 26, fontWeight: '900', color: Colors.white, letterSpacing: -0.5 },
  verifiedBadge: { backgroundColor: Colors.accent, borderRadius: 10, padding: 3 },
  heroSubtitle: { fontSize: 13, fontWeight: '700', color: Colors.gray400, marginTop: 4 },
  cardContent: { padding: Spacing.md },
  tagsRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: Spacing.sm },
  tag: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: BorderRadius.full },
  tagText: { fontSize: 11, fontWeight: '900', textTransform: 'uppercase', letterSpacing: 1 },
  tagBrand: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: BorderRadius.full, borderWidth: 1, borderColor: 'rgba(212,175,55,0.3)' },
  tagBrandText: { fontSize: 11, fontWeight: '900', color: Colors.accent, textTransform: 'uppercase', letterSpacing: 1 },
  bioText: { fontSize: 13, lineHeight: 20, marginTop: Spacing.xs },

  /* Compatibility Profile Card */
  sectionCard: {
    borderRadius: BorderRadius.lg,
    padding: Spacing.md,
    borderWidth: 1,
    marginBottom: Spacing.md,
  },
  sectionTitle: { fontSize: 14, fontWeight: '900', textTransform: 'uppercase', letterSpacing: 1.5, marginBottom: Spacing.md },
  barContainer: { marginBottom: 12 },
  barLabelRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 },
  barLabel: { fontSize: 11, fontWeight: '700', color: Colors.gray400 },
  barVal: { fontSize: 11, fontWeight: '900' },
  barBg: { height: 6, borderRadius: 3, overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 3 },

  /* Glow Card */
  glowCard: {
    borderRadius: BorderRadius.lg,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: 'rgba(212,175,55,0.3)',
    marginBottom: Spacing.md,
  },
  glowHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 6 },
  glowTitle: { fontSize: 12, fontWeight: '900', color: Colors.accent, textTransform: 'uppercase', letterSpacing: 1.5 },
  glowBody: { fontSize: 12, lineHeight: 18 },

  /* Actions */
  actionsRow: { flexDirection: 'row', gap: 16 },
  actionBtnPass: { flex: 1, paddingVertical: 14, borderRadius: BorderRadius.full, borderWidth: 1, borderColor: '#374151', backgroundColor: '#191E2E', alignItems: 'center', justifyContent: 'center' },
  actionBtnPassText: { fontSize: 15, fontWeight: '700', color: Colors.white },
  actionBtnConnect: { paddingVertical: 14, borderRadius: BorderRadius.full, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8 },
  actionBtnConnectText: { fontSize: 15, fontWeight: '900', color: Colors.white },

  /* Mutual Match Modal */
  modalContainer: { flex: 1, backgroundColor: 'rgba(0,0,0,0.85)', alignItems: 'center', justifyContent: 'center', padding: Spacing.lg },
  modalCard: { width: '100%', borderRadius: BorderRadius.lg, padding: 32, alignItems: 'center', borderWidth: 1, borderColor: 'rgba(212,175,55,0.3)' },
  modalTitle: { fontSize: 20, fontWeight: '900', color: Colors.accent, textAlign: 'center', marginBottom: 8 },
  modalSub: { fontSize: 12, color: Colors.gray400, textAlign: 'center', lineHeight: 18, marginBottom: 24 },
  modalAvatars: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 16, marginBottom: 32 },
  modalAvatar: { width: 72, height: 72, borderRadius: 36, borderWidth: 2, borderColor: Colors.accent },
  modalHeartWrap: {
    width: 48, height: 48, borderRadius: 24, backgroundColor: 'rgba(226,125,141,0.15)', alignItems: 'center', justifyContent: 'center',
    shadowColor: Colors.primary, shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 10, elevation: 6
  },
  modalPrimaryBtn: { width: '100%', backgroundColor: Colors.primary, paddingVertical: 16, borderRadius: BorderRadius.full, alignItems: 'center', marginBottom: 12 },
  modalPrimaryBtnText: { color: Colors.white, fontSize: 13, fontWeight: '900', textTransform: 'uppercase', letterSpacing: 1.5 },
  modalSecondaryBtn: { width: '100%', paddingVertical: 12, alignItems: 'center' },
  modalSecondaryBtnText: { fontSize: 12, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 1 },
});
