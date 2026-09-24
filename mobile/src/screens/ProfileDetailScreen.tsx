import React, { useState, useEffect } from 'react';
import {
  Dimensions, Image, ScrollView, StyleSheet, Text, TouchableOpacity, View, ActivityIndicator, Alert
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { db } from '../services/apiService';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { useToast } from '../contexts/ToastContext';
import { Colors, Spacing, BorderRadius } from '../theme/colors';
import { RootStackParamList, Match } from '../types';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type DetailRoute = RouteProp<RootStackParamList, 'ProfileDetail'>;
const { width: SCREEN_W } = Dimensions.get('window');

/* ── Reusable sub-components ──────────────────────────────── */

function DataItem({ label, value, isDark }: { label: string; value?: string | null; isDark: boolean }) {
  return (
    <View style={st.dataItem}>
      <Text style={st.dataLabel}>{label}</Text>
      {value ? (
        <Text style={[st.dataValue, { color: isDark ? Colors.gray200 : Colors.black }]}>{value}</Text>
      ) : (
        <Text style={[st.dataValue, { color: isDark ? Colors.gray600 : Colors.gray300, fontStyle: 'italic' }]}>Not specified</Text>
      )}
    </View>
  );
}

function Chip({ text, variant, isDark }: { text: string; variant: 'neutral' | 'brand'; isDark: boolean }) {
  const bg = variant === 'brand'
    ? (isDark ? 'rgba(244,196,48,0.1)' : Colors.light)
    : (isDark ? Colors.gray800 : Colors.gray100);
  const fg = variant === 'brand'
    ? (isDark ? Colors.accent : Colors.primary)
    : (isDark ? Colors.gray300 : Colors.gray700);
  const border = variant === 'brand'
    ? (isDark ? 'rgba(244,196,48,0.2)' : 'rgba(74,13,103,0.1)')
    : 'transparent';
  return (
    <View style={[st.chip, { backgroundColor: bg, borderColor: border, borderWidth: variant === 'brand' ? 1 : 0 }]}>
      <Text style={[st.chipText, { color: fg }]}>{text}</Text>
    </View>
  );
}

function SectionHeader({ title, isDark }: { title: string; isDark: boolean }) {
  return (
    <View style={[st.sectionHeaderWrap, { borderBottomColor: isDark ? Colors.gray800 : Colors.gray100 }]}>
      <Text style={[st.sectionHeader, { color: isDark ? Colors.white : Colors.dark }]}>{title}</Text>
    </View>
  );
}

function Divider({ isDark }: { isDark: boolean }) {
  return <View style={[st.divider, { backgroundColor: isDark ? Colors.gray800 : Colors.gray200 }]} />;
}

/* ── Main Screen ──────────────────────────────────────────── */

export default function ProfileDetailScreen() {
  const navigation = useNavigation<Nav>();
  const { params } = useRoute<DetailRoute>();
  const { userProfile } = useAuth();
  const { isDarkMode } = useTheme();
  const { addToast } = useToast();
  const insets = useSafeAreaInsets();
  const match: Match = params.match;

  const [photoIdx, setPhotoIdx] = useState(0);
  const photos = match.profileImageUrls?.length
    ? match.profileImageUrls
    : (match as any).selfieUrl
    ? [(match as any).selfieUrl]
    : [`https://ui-avatars.com/api/?name=${encodeURIComponent((match as any).name || (match as any).firstName || 'User')}&background=1E1E1E&color=FFFFFF&size=800`];

  const [metrics, setMetrics] = useState<any>(null);
  const [isCalculating, setIsCalculating] = useState(true);

  useEffect(() => {
    async function fetchMetrics() {
      if (!userProfile || !match) return;
      try {
        const result = await db.calculateCompatibility(userProfile, match as any);
        setMetrics({
          trustScore: 95, 
          valuesAlignment: result.valuesAlignment || 0,
          emotionalSynergy: result.emotionalAlignment || 0,
          communicationMatch: result.communicationStyle || 0,
          archetype: 'The Intentional Match',
          attachment: 'Secure',
          aiExplanation: result.aiExplanation || "An excellent foundation based on shared goals and emotional readiness."
        });
      } catch (err) {
        console.error('Failed to load compatibility metrics:', err);
        setMetrics({
          valuesAlignment: 85,
          emotionalSynergy: 80,
          communicationMatch: 88,
          aiExplanation: "We couldn't connect to KNOT AI for deep insights, but based on your profiles, you share a strong foundation."
        });
      } finally {
        setIsCalculating(false);
      }
    }
    fetchMetrics();
  }, [match.id, userProfile?.id]);

  const handleOptions = () => {
    Alert.alert('Options', 'Select an action for this profile', [
      { text: 'Block', style: 'destructive', onPress: () => addToast('User blocked successfully', 'success') },
      { text: 'Report', style: 'destructive', onPress: () => addToast('Report submitted', 'success') },
      { text: 'Cancel', style: 'cancel' }
    ]);
  };

  const isAdmin = userProfile?.role === 'ADMIN' || userProfile?.id === 'user_0';
  const bothDisabled = userProfile?.isPremium === true && !match.isPremium;

  const locationDisplay = match.residenceCity && match.residenceState
    ? `${match.residenceCity}, ${match.residenceState}, ${match.residenceCountry}`
    : match.residenceCountry || '';

  const nextPhoto = () => setPhotoIdx((i) => Math.min(i + 1, photos.length - 1));
  const prevPhoto = () => setPhotoIdx((i) => Math.max(i - 1, 0));

  return (
    <View style={[st.root, { backgroundColor: isDarkMode ? Colors.dark : Colors.white }]}>
      <ScrollView contentContainerStyle={{ paddingBottom: 120 }}>

        {/* ─── Photo carousel ─── */}
        <View style={{ width: SCREEN_W, aspectRatio: 0.85 }}>
          <Image source={{ uri: photos[photoIdx] }} style={StyleSheet.absoluteFillObject} />
          <LinearGradient
            colors={['transparent', 'rgba(0,0,0,0.2)', 'rgba(0,0,0,0.75)']}
            style={StyleSheet.absoluteFillObject}
            pointerEvents="none"
          />

          {/* Indicators */}
          <View style={[st.indicatorRow, { top: insets.top + 12 }]}>
            {photos.map((_, i) => (
              <View key={i} style={[st.indicator, i === photoIdx && st.indicatorActive]} />
            ))}
          </View>

          {/* Back button */}
          <TouchableOpacity
            style={[st.backBtn, { top: insets.top + 8 }]}
            onPress={() => navigation.goBack()}
          >
            <Ionicons name="chevron-back" size={24} color={Colors.white} />
          </TouchableOpacity>

          <TouchableOpacity
            style={[st.optionsBtn, { top: insets.top + 8 }]}
            onPress={handleOptions}
          >
            <Ionicons name="ellipsis-horizontal" size={24} color={Colors.white} />
          </TouchableOpacity>

          {/* Tap zones */}
          <View style={[StyleSheet.absoluteFillObject, { flexDirection: 'row', zIndex: 10 }]}>
            <TouchableOpacity style={{ flex: 1 }} onPress={prevPhoto} activeOpacity={1} />
            <TouchableOpacity style={{ flex: 1 }} onPress={nextPhoto} activeOpacity={1} />
          </View>
        </View>

        {/* ─── Info overlay card (rounded top, overlaps image) ─── */}
        <View style={[st.infoCard, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white }]}>
          <View style={st.nameRow}>
            <Text style={[st.name, { color: isDarkMode ? Colors.white : Colors.dark }]}>
              {match.name}, {match.age}
            </Text>
            {match.isVerified && (
              <View style={st.verifiedBadge}>
                <Ionicons name="checkmark" size={14} color={Colors.dark} />
              </View>
            )}
          </View>
          <Text style={st.location}>{locationDisplay.toUpperCase()}</Text>
        </View>



        {/* ─── Profile content sections ─── */}
        <View style={st.content}>

          {/* ══ COMPATIBILITY MAP ══ */}
          <SectionHeader title="Relationship Intelligence" isDark={isDarkMode} />
          
          {isCalculating ? (
            <View style={[st.sectionCardInline, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200, padding: 32, borderRadius: 16, borderWidth: 1, marginBottom: 16, alignItems: 'center', justifyContent: 'center' }]}>
              <ActivityIndicator size="large" color={Colors.accent} />
              <Text style={{ marginTop: 16, fontSize: 12, color: Colors.gray400, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 1.5 }}>AI is analyzing compatibility...</Text>
            </View>
          ) : (
            <>
              <View style={[st.sectionCardInline, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200, padding: 16, borderRadius: 16, borderWidth: 1, marginBottom: 16 }]}>
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
              {/* AI Explanation Glow Box */}
              <View style={[st.glowCard, { backgroundColor: isDarkMode ? 'rgba(212,175,55,0.05)' : 'rgba(212,175,55,0.02)', borderColor: 'rgba(212,175,55,0.3)', borderWidth: 1, padding: 16, borderRadius: 16, marginBottom: 24 }]}>
                <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 6 }}>
                  <Ionicons name="sparkles" size={16} color={Colors.accent} style={{ marginRight: 6 }} />
                  <Text style={{ fontSize: 12, fontWeight: '900', color: Colors.accent, textTransform: 'uppercase', letterSpacing: 1.5 }}>Why You Matched</Text>
                </View>
                <Text style={{ fontSize: 12, lineHeight: 18, color: isDarkMode ? Colors.gray300 : Colors.gray700 }}>
                  {metrics?.aiExplanation || 'The AI found deep synergy between your values and lifestyle.'}
                </Text>
              </View>
            </>
          )}

          {/* ══ IDENTITY & ROOTS ══ */}
          <SectionHeader title="Identity & Roots" isDark={isDarkMode} />

          <View style={st.row2}>
            <View style={st.col}>
              <DataItem label="Marital Status" value={match.maritalStatus} isDark={isDarkMode} />
            </View>
            <View style={st.col}>
              <DataItem label="Occupation" value={match.occupation} isDark={isDarkMode} />
            </View>
          </View>

          {/* Location card */}
          <View style={[st.locationCard, {
            backgroundColor: isDarkMode ? 'rgba(0,0,0,0.25)' : Colors.gray50,
            borderColor: isDarkMode ? Colors.gray800 : Colors.gray100,
          }]}>
            <Text style={[st.locationLabel, { color: isDarkMode ? Colors.accent : Colors.primary }]}>Current Residence</Text>
            <View style={st.row3}>
              <View style={st.col3}><DataItem label="Country" value={match.residenceCountry} isDark={isDarkMode} /></View>
              <View style={st.col3}><DataItem label="State" value={match.residenceState} isDark={isDarkMode} /></View>
              <View style={st.col3}><DataItem label="City" value={match.residenceCity} isDark={isDarkMode} /></View>
            </View>

            <Divider isDark={isDarkMode} />

            <Text style={[st.locationLabel, { color: isDarkMode ? Colors.accent : Colors.primary }]}>Heritage & Origin</Text>
            <View style={st.row3}>
              <View style={st.col3}><DataItem label="Country" value={match.originCountry} isDark={isDarkMode} /></View>
              <View style={st.col3}><DataItem label="State" value={match.originState} isDark={isDarkMode} /></View>
              <View style={st.col3}><DataItem label="City" value={match.originCity} isDark={isDarkMode} /></View>
            </View>
            <DataItem label="Cultural Identity" value={match.culturalBackground} isDark={isDarkMode} />
          </View>

          <DataItem label="Registry Bio" value={match.bio} isDark={isDarkMode} />

          <View style={st.row2}>
            <View style={st.col}><DataItem label="Nationality" value={match.nationality} isDark={isDarkMode} /></View>
            <View style={st.col}><DataItem label="Languages" value={match.languagesSpoken?.join(', ')} isDark={isDarkMode} /></View>
          </View>

          <Divider isDark={isDarkMode} />

          {/* ══ LIFESTYLE & BELIEFS ══ */}
          <SectionHeader title="Lifestyle & Beliefs" isDark={isDarkMode} />

          <View style={st.row2}>
            <View style={st.col}><DataItem label="Faith/Religion" value={match.religion} isDark={isDarkMode} /></View>
            <View style={st.col}><DataItem label="Smoking" value={match.smoking} isDark={isDarkMode} /></View>
          </View>
          <View style={st.row2}>
            <View style={st.col}><DataItem label="Drinking" value={match.drinking} isDark={isDarkMode} /></View>
            <View style={st.col}><DataItem label="Children" value={match.childrenStatus || 'None'} isDark={isDarkMode} /></View>
          </View>


          <Divider isDark={isDarkMode} />
          {/* ══ MARRIAGE EXPECTATIONS ══ */}
          <SectionHeader title="Marriage Expectations" isDark={isDarkMode} />

          <View style={st.row2}>
            <View style={st.col}><DataItem label="Vow Timeline" value={match.marriageTimeline} isDark={isDarkMode} /></View>
            <View style={st.col}><DataItem label="Relocation" value={match.willingToRelocate} isDark={isDarkMode} /></View>
          </View>
          <View style={st.row2}>
            <View style={st.col}><DataItem label="Children Intent" value={match.childrenPreference} isDark={isDarkMode} /></View>
            <View style={st.col}>
              <DataItem
                label="Partner Age"
                value={match.preferredPartnerAgeRange
                  ? `${match.preferredPartnerAgeRange[0]} - ${match.preferredPartnerAgeRange[1]} years`
                  : undefined}
                isDark={isDarkMode}
              />
            </View>
          </View>
          
          <View style={[st.dataItem, { marginTop: 8, marginBottom: 16, backgroundColor: isDarkMode ? 'rgba(255,255,255,0.03)' : Colors.gray50, padding: 12, borderRadius: 12 }]}>
            <Text style={[st.locationLabel, { color: isDarkMode ? Colors.accent : Colors.primary, marginBottom: 8 }]}>Preferred Partner Origin & Residence</Text>
            <DataItem label="Target Residence" value={[match.preferredResidenceCity, match.preferredResidenceState, match.preferredResidenceCountry].filter(Boolean).join(', ') || 'Anywhere'} isDark={isDarkMode} />
            <View style={{ marginTop: 8, borderTopWidth: 1, borderTopColor: isDarkMode ? Colors.darkBorder : Colors.gray200, paddingTop: 8 }}>
              <DataItem label="Target Heritage / Origin" value={[match.preferredOriginCity, match.preferredOriginState, match.preferredOriginCountry].filter(Boolean).join(', ') || 'Any Background'} isDark={isDarkMode} />
            </View>
          </View>

          <View style={st.dataItem}>
            <Text style={st.dataLabel}>Ideal Partner Traits</Text>
            <View style={st.chipRow}>
              {(match.idealPartnerTraits?.length ?? 0) > 0 ? (
                match.idealPartnerTraits.map(t => <Chip key={t} text={t} variant="brand" isDark={isDarkMode} />)
              ) : (
                <Text style={[st.dataValue, { color: Colors.gray300, fontStyle: 'italic' }]}>Not listed</Text>
              )}
            </View>
          </View>

          <DataItem label="Marriage Expectations" value={match.marriageExpectations} isDark={isDarkMode} />

        </View>
      </ScrollView>

      {/* ─── Bottom action bar ─── */}
      {!isAdmin && (
        <View style={[st.actionBar, { 
          paddingBottom: insets.bottom + 16,
          backgroundColor: isDarkMode ? Colors.darkCard : Colors.white,
          borderTopColor: isDarkMode ? Colors.darkBorder : Colors.gray100,
        }]}>
          <TouchableOpacity
            style={{ flex: 1 }}
            disabled={bothDisabled}
            onPress={async () => {
              if (userProfile?.isPremium) {
                navigation.navigate('Chat', { match, user: userProfile! });
                return;
              }
              try {
                const freeMatchId = await AsyncStorage.getItem('freeMatchId');
                if (!freeMatchId) {
                  await AsyncStorage.setItem('freeMatchId', match.id);
                  navigation.navigate('Chat', { match, user: userProfile! });
                } else if (freeMatchId === match.id) {
                  navigation.navigate('Chat', { match, user: userProfile! });
                } else {
                  navigation.navigate('Payment', { user: userProfile! });
                }
              } catch (e) {
                navigation.navigate('Payment', { user: userProfile! });
              }
            }}
          >
            <LinearGradient
              colors={bothDisabled ? [Colors.gray200, Colors.gray200] : [Colors.primary, '#8C52FF']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={[st.chatBtn, bothDisabled && st.disabledBtn]}
            >
              <Ionicons name="chatbubbles" size={22} color={bothDisabled ? Colors.gray400 : Colors.white} />
              <Text style={[st.chatBtnText, bothDisabled && { color: Colors.gray400 }]}>Chats</Text>
            </LinearGradient>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

/* ── Styles ───────────────────────────────────────────────── */

const st = StyleSheet.create({
  root: { flex: 1 },

  /* Photo carousel */
  indicatorRow: { position: 'absolute', left: 16, right: 16, zIndex: 20, flexDirection: 'row', gap: 6 },
  indicator: { flex: 1, height: 4, borderRadius: 2, backgroundColor: 'rgba(255,255,255,0.4)' },
  indicatorActive: { backgroundColor: Colors.white },
  backBtn: { position: 'absolute', left: 16, zIndex: 30, backgroundColor: 'rgba(0,0,0,0.4)', borderRadius: 22, padding: 10 },
  optionsBtn: { position: 'absolute', right: 16, zIndex: 30, backgroundColor: 'rgba(0,0,0,0.4)', borderRadius: 22, padding: 10 },

  /* Info overlay */
  infoCard: { marginTop: -48, borderTopLeftRadius: 40, borderTopRightRadius: 40, paddingHorizontal: 32, paddingTop: 32, paddingBottom: 16 },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  name: { fontSize: 32, fontWeight: '900', letterSpacing: -1 },
  verifiedBadge: { backgroundColor: Colors.accent, borderRadius: 14, padding: 4, elevation: 4 },
  location: { fontSize: 12, fontWeight: '700', color: Colors.gray400, textTransform: 'uppercase', letterSpacing: 2, marginTop: 4 },

  /* Restricted banner */
  restrictedBox: { marginHorizontal: 32, padding: 16, borderRadius: 20, borderWidth: 1, alignItems: 'center', marginBottom: 16 },
  restrictedTitle: { fontSize: 10, fontWeight: '900', color: Colors.primary, textTransform: 'uppercase', letterSpacing: 2, marginBottom: 8 },
  restrictedBody: { fontSize: 12, textAlign: 'center', marginBottom: 12, lineHeight: 18 },
  upgradeBtn: { paddingHorizontal: 28, paddingVertical: 10, borderRadius: 24, elevation: 4, shadowColor: Colors.primary, shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.2, shadowRadius: 8 },
  upgradeBtnText: { color: Colors.white, fontSize: 10, fontWeight: '900', textTransform: 'uppercase', letterSpacing: 2 },

  /* Content area */
  content: { paddingHorizontal: 32 },

  /* Section header */
  sectionHeaderWrap: { paddingTop: 8, paddingBottom: 16, borderBottomWidth: 1, marginBottom: 16 },
  sectionHeader: { fontSize: 18, fontWeight: '900', letterSpacing: -0.5, textTransform: 'uppercase' },

  /* Data items */
  dataItem: { marginBottom: 16 },
  dataLabel: { fontSize: 10, fontWeight: '900', color: Colors.gray400, textTransform: 'uppercase', letterSpacing: 2, marginBottom: 4 },
  dataValue: { fontSize: 14, fontWeight: '500', lineHeight: 22 },

  /* Grid rows */
  row2: { flexDirection: 'row', gap: 24, marginBottom: 16 },
  row3: { flexDirection: 'row', gap: 8, marginBottom: 12 },
  col: { flex: 1 },
  col3: { flex: 1 },

  /* Location card */
  locationCard: { padding: 16, borderRadius: 16, borderWidth: 1, marginBottom: 16 },
  locationLabel: { fontSize: 9, fontWeight: '900', textTransform: 'uppercase', letterSpacing: 2, marginBottom: 8 },

  /* Chips */
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 8 },
  chip: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 999 },
  chipText: { fontSize: 10, fontWeight: '900', textTransform: 'uppercase', letterSpacing: 1.5 },

  /* Divider */
  divider: { height: 1, marginVertical: 8 },

  /* Bottom action bar */
  actionBar: { position: 'absolute', bottom: 0, left: 0, right: 0, flexDirection: 'row', gap: 16, paddingHorizontal: 24, paddingTop: 16, borderTopWidth: 1 },
  chatBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 12, paddingVertical: 16, borderRadius: 20, elevation: 6, shadowColor: Colors.primary, shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.2, shadowRadius: 8 },
  chatBtnText: { color: Colors.white, fontSize: 18, fontWeight: '900' },
  disabledBtn: { elevation: 0, shadowOpacity: 0 },
  sectionCardInline: { marginBottom: 16 },
  glowCard: {},
  barContainer: { marginBottom: 12 },
  barLabelRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 },
  barLabel: { fontSize: 11, fontWeight: '700', color: Colors.gray400 },
  barVal: { fontSize: 11, fontWeight: '900' },
  barBg: { height: 6, borderRadius: 3, overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 3 },
});
