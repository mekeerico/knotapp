import React, { useState } from 'react';
import {
  StyleSheet, Text, TouchableOpacity, View, SafeAreaView, ScrollView, Dimensions, Alert
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import Purchases from 'react-native-purchases';

import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { useToast } from '../contexts/ToastContext';
import { Colors, Spacing, BorderRadius } from '../theme/colors';
import { RootStackParamList, SubscriptionTier } from '../types';
import { formatTierPrice, getTierPriceUSD, formatLocalPrice, AFRICAN_COUNTRIES } from '../services/currencyService';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type PayRoute = RouteProp<RootStackParamList, 'Payment'>;

const { width } = Dimensions.get('window');

const TIERS = [

  {
    id: SubscriptionTier.Premium,
    title: 'Knot Premium',
    subtitle: 'For Serious Active Users',
    features: [
      '15 AI-Curated Matches / Day',
      'Unlimited Messaging',
      'AI Relationship Coach',
      'Advanced Filters',
      'Detailed Compatibility Breakdowns',
      'AI-Powered Profile Optimization',
    ],
    colors: ['#3A1C71', '#D76D77', '#FFAF7B'] as [string, string, string],
  },
  {
    id: SubscriptionTier.Elite,
    title: 'Knot Elite',
    subtitle: 'The Luxury Tier for Professionals',
    features: [
      '25 Elite-Curated Matches / Day',
      'Elite Verification Badge',
      'Deep Relationship Intelligence',
      'Highest Trust Visibility',
      'Invisible & Incognito Mode',
      'Priority Matchmaking Placement',
    ],
    colors: ['#0F2027', '#203A43', '#2C5364'] as [string, string, string],
  },
  {
    id: SubscriptionTier.Executive,
    title: 'Knot Executive',
    subtitle: 'VIP Concierge Service',
    features: [
      'Unlimited Concierge Matches',
      'Human Matchmaking Assistance',
      'Private Relationship Advisors',
      'White-Glove Onboarding',
      'Psychological Compatibility Reviews',
    ],
    colors: ['#000000', '#434343', '#000000'] as [string, string, string],
  }
];

export default function PaymentScreen() {
  const navigation = useNavigation<Nav>();
  const { params } = useRoute<PayRoute>();
  const { setUserProfile } = useAuth();
  const { isDarkMode } = useTheme();
  const { addToast } = useToast();
  const user = params.user;

  const [activeTierIdx, setActiveTierIdx] = useState(0);
  const [processing, setProcessing] = useState(false);
  const [isYearly, setIsYearly] = useState(false);
  const [rcPackages, setRcPackages] = useState<any[]>([]);

  const country = user.residenceCountry || 'Nigeria';
  
  const tierOrder: Record<string, number> = {
    [SubscriptionTier.Essential]: 0,
    [SubscriptionTier.Premium]: 1,
    [SubscriptionTier.Elite]: 2,
    [SubscriptionTier.Executive]: 3,
  };
  const currentUserTierVal = tierOrder[user.subscriptionTier || SubscriptionTier.Essential] || 0;

  React.useEffect(() => {
    const fetchOfferings = async () => {
      try {
        const offerings = await Purchases.getOfferings();
        if (offerings.current !== null && offerings.current.availablePackages.length !== 0) {
          setRcPackages(offerings.current.availablePackages);
        }
      } catch (e) {
        console.warn("RevenueCat Error: ", e);
      }
    };
    fetchOfferings();
  }, []);

  const getTierPriceDisplay = (tierId: string) => {
    // Search for a loaded RevenueCat package matching this tier
    const pkg = rcPackages.find(p => p.identifier.toLowerCase().includes(tierId.toLowerCase()));
    
    // If we found the package from RevenueCat, return the exact localized price string from the store!
    if (pkg && pkg.product && pkg.product.priceString) {
      return pkg.product.priceString;
    }

    // Fallback if RevenueCat packages haven't loaded yet
    const baseUsd = getTierPriceUSD(tierId as any, country);
    const finalUsd = isYearly ? baseUsd * 10 : baseUsd;
    const isAfrica = AFRICAN_COUNTRIES.includes(country);
    if (isAfrica) {
       return formatLocalPrice(finalUsd, country);
    }
    return `$${finalUsd.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  const activeTier = TIERS[activeTierIdx];

  const handleSubscribe = async (tierIdx: number) => {
    setActiveTierIdx(tierIdx);
    const selectedTier = TIERS[tierIdx];
    const tierUsdVal = getTierPriceUSD(selectedTier.id as any, country) * (isYearly ? 10 : 1);
    
    // Attempt to find the matching RevenueCat package based on entitlement or identifier.
    // Assuming you set up packages corresponding to tiers in RevenueCat.
    const pkgToBuy = rcPackages.find(p => p.identifier.toLowerCase().includes(selectedTier.id.toLowerCase()));

    setProcessing(true);
    try {
      if (pkgToBuy) {
        const { customerInfo } = await Purchases.purchasePackage(pkgToBuy);
        
        // If purchase successful, verify the entitlement is active
        const isPremiumActive = 
          customerInfo.entitlements.active['Premium'] !== undefined ||
          customerInfo.entitlements.active['Elite'] !== undefined ||
          customerInfo.entitlements.active['Executive'] !== undefined ||
          customerInfo.entitlements.active['premium_tier'] !== undefined;
          
        if (isPremiumActive) {
          // Make backend call in real production, for now just update local state
          setUserProfile({
            ...user,
            subscriptionTier: selectedTier.id as SubscriptionTier,
            subscriptionAmount: tierUsdVal,
            subscriptionPeriod: isYearly ? 'annual' : 'monthly',
            subscriptionDate: new Date().toISOString(),
            isPremium: true,
          });
          addToast(`Welcome to ${selectedTier.title}!`, 'success');
          navigation.goBack();
        } else {
          addToast('Purchase completed, but premium access not active.', 'error');
        }
      } else {
        // Fallback for development if no packages exist
        setUserProfile({
          ...user,
          subscriptionTier: selectedTier.id as SubscriptionTier,
          subscriptionAmount: tierUsdVal,
          subscriptionPeriod: isYearly ? 'annual' : 'monthly',
          subscriptionDate: new Date().toISOString(),
          isPremium: true,
        });
        addToast(`Welcome to ${selectedTier.title}!`, 'success');
        navigation.goBack();
      }
    } catch (e: any) {
      if (!e.userCancelled) {
        Alert.alert('Error', e.message || 'Failed to complete subscription');
      }
    } finally {
      setProcessing(false);
    }
  };

  return (
    <SafeAreaView style={[s.root, { backgroundColor: isDarkMode ? Colors.dark : Colors.gray100 }]}>
      <View style={[s.header, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white }]}>
        <Text style={[s.headerTitle, { color: isDarkMode ? Colors.white : Colors.dark }]}>Upgrade Registry</Text>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Ionicons name="close" size={24} color={Colors.gray400} />
        </TouchableOpacity>
      </View>

      <View style={[s.billingToggleWrap, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white }]}>
        <TouchableOpacity 
          style={[s.billingToggleBtn, !isYearly && s.billingToggleBtnActive]} 
          onPress={() => setIsYearly(false)}
        >
          <Text style={[s.billingToggleText, !isYearly && s.billingToggleTextActive]}>Monthly</Text>
        </TouchableOpacity>
        <TouchableOpacity 
          style={[s.billingToggleBtn, isYearly && s.billingToggleBtnActive]} 
          onPress={() => setIsYearly(true)}
        >
          <Text style={[s.billingToggleText, isYearly && s.billingToggleTextActive]}>Yearly (Save 17%)</Text>
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 40 }}>
        {TIERS.map((tier, idx) => (
          <View key={tier.id} style={{ padding: Spacing.md, paddingBottom: 16 }}>
            <LinearGradient
              colors={tier.colors}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={s.premiumCard}
            >
              <View style={s.premiumBadge}>
                <Text style={s.premiumBadgeText}>{tier.id} TIER</Text>
              </View>
              <Text style={s.premiumTitle}>{tier.title}</Text>
              <Text style={s.premiumSub}>{tier.subtitle}</Text>
              
              <View style={s.priceBox}>
                <Text style={s.priceLabel}>{isYearly ? 'Annual Investment' : 'Monthly Investment'}</Text>
                <Text style={s.priceAmount}>{getTierPriceDisplay(tier.id)}</Text>
                <Text style={s.priceSub}>Billed securely via Apple/Google</Text>
              </View>
            </LinearGradient>

            <View style={[s.benefitsCard, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white }]}>
              <Text style={s.benefitsTitle}>{tier.id} Features</Text>
              {tier.features.map((f, i) => (
                <View key={i} style={s.benefitRow}>
                  <Ionicons name="checkmark-circle" size={20} color={Colors.primary} />
                  <Text style={[s.benefitText, { color: isDarkMode ? Colors.gray300 : Colors.gray700 }]}>{f}</Text>
                </View>
              ))}
            </View>

            <View style={{ alignItems: 'center', marginTop: 8 }}>
              {(() => {
                const tierVal = tierOrder[tier.id] || 0;
                const isCurrent = tierVal === currentUserTierVal;
                const isLower = tierVal < currentUserTierVal;
                const isDisabled = isCurrent || isLower;

                return (
                  <TouchableOpacity 
                    style={{ width: '100%' }} 
                    onPress={() => { handleSubscribe(idx); }} 
                    disabled={isDisabled || processing}
                  >
                    <LinearGradient
                      colors={(isDisabled || (processing && activeTierIdx === idx)) ? [Colors.gray400, Colors.gray400] : [Colors.primary, '#8C52FF']}
                      start={{ x: 0, y: 0 }}
                      end={{ x: 1, y: 0 }}
                      style={s.payBtn}
                    >
                      {processing && activeTierIdx === idx ? (
                        <Text style={s.payBtnText}>Processing...</Text>
                      ) : (
                        <>
                          {!isDisabled && <Ionicons name="logo-apple" size={18} color={Colors.white} />}
                          <Text style={s.payBtnText}>
                            {isCurrent ? 'Current Plan' : isLower ? 'Included in Current Plan' : `Subscribe to ${tier.id}`}
                          </Text>
                        </>
                      )}
                    </LinearGradient>
                  </TouchableOpacity>
                );
              })()}
              <Text style={s.secureNote}>Secure In-App Purchase</Text>
            </View>
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const s = StyleSheet.create({
  root: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: Spacing.md, paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: Colors.gray200 },
  headerTitle: { fontSize: 16, fontWeight: '900', textTransform: 'uppercase', letterSpacing: -0.5 },
  premiumCard: { borderRadius: 32, padding: 32, alignItems: 'center', marginBottom: 16, overflow: 'hidden' },
  premiumBadge: { backgroundColor: 'rgba(255,255,255,0.2)', paddingHorizontal: 16, paddingVertical: 4, borderRadius: 20, marginBottom: 16 },
  premiumBadgeText: { fontSize: 10, fontWeight: '900', color: Colors.white, textTransform: 'uppercase', letterSpacing: 2 },
  premiumTitle: { fontSize: 30, fontWeight: '900', color: Colors.white, letterSpacing: -1 },
  premiumSub: { fontSize: 12, fontWeight: '700', color: 'rgba(255,255,255,0.8)', marginTop: 4, marginBottom: 24, textAlign: 'center' },
  priceBox: { backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: 24, padding: 20, width: '100%', alignItems: 'center', borderWidth: 1, borderColor: 'rgba(255,255,255,0.2)' },
  priceLabel: { fontSize: 10, fontWeight: '900', color: 'rgba(255,255,255,0.7)', textTransform: 'uppercase', letterSpacing: 2, marginBottom: 8 },
  priceAmount: { fontSize: 36, fontWeight: '900', color: Colors.white },
  priceSub: { fontSize: 9, fontWeight: '600', color: 'rgba(255,255,255,0.5)', marginTop: 4, textTransform: 'uppercase' },
  benefitsCard: { padding: 20, borderRadius: 24, marginBottom: 16, borderWidth: 1, borderColor: Colors.gray200 },
  benefitsTitle: { fontSize: 11, fontWeight: '900', color: Colors.primary, textTransform: 'uppercase', letterSpacing: 2, borderBottomWidth: 1, borderBottomColor: Colors.gray50, paddingBottom: 8, marginBottom: 16 },

  benefitRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 12, gap: 12 },
  benefitText: { fontSize: 13, fontWeight: '500' },
  payBtn: { paddingVertical: 18, borderRadius: BorderRadius.full, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8 },
  payBtnText: { color: Colors.white, fontSize: 14, fontWeight: '900', textTransform: 'uppercase', letterSpacing: 1 },
  secureNote: { fontSize: 10, color: Colors.gray400, marginTop: 12, fontWeight: '600' },
  billingToggleWrap: { flexDirection: 'row', padding: 4, marginHorizontal: Spacing.md, borderRadius: BorderRadius.full, marginBottom: 16 },
  billingToggleBtn: { flex: 1, paddingVertical: 10, alignItems: 'center', borderRadius: BorderRadius.full },
  billingToggleBtnActive: { backgroundColor: Colors.primary },
  billingToggleText: { fontSize: 13, fontWeight: '700', color: Colors.gray400 },
  billingToggleTextActive: { color: Colors.white },
});
