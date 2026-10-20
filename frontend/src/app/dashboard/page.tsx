"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { 
  Sparkles, ShieldCheck, Heart, User, Bot, MessageSquare, 
  Settings, LogOut, Send, AlertTriangle, Shield, CheckCircle2,
  TrendingUp, Award, Activity, Compass, BrainCircuit, HeartHandshake,
  Menu, X, ArrowLeft, ChevronLeft, ChevronRight, Image as ImageIcon, Camera, Loader2,
  Star, Briefcase, MapPin, RefreshCw, Lock, Bell, Sliders
} from "lucide-react";
import { getApiUrl } from "../../services/api";

export default function Dashboard() {
  // Helper: resolve relative image URLs (like /uploads/...) to absolute using backend base URL
  const resolveImageUrl = (url: string | undefined | null): string => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) return url;
    const base = getApiUrl();
    return `${base}${url}`;
  };

  const formatAgeOrDob = (dob: any): string => {
    if (!dob) return '';
    if (typeof dob === 'number') return `${dob}`;
    const str = String(dob).trim();
    if (/^\d{1,2}$/.test(str)) return str;
    const d = new Date(str);
    if (!isNaN(d.getTime())) {
      const ageDiffMs = Date.now() - d.getTime();
      const ageDate = new Date(ageDiffMs);
      const age = Math.abs(ageDate.getUTCFullYear() - 1970);
      if (age > 0 && age < 120) return `${age}`;
    }
    return str;
  };
  const [activeTab, setActiveTab] = useState("matches"); // matches, insights, coach, messages, profile
  const [isPremium, setIsPremium] = useState(false);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [activeChatId, setActiveChatId] = useState<string | null>(null);
  const [showMatchModal, setShowMatchModal] = useState(false);
  const [matchCompatibility, setMatchCompatibility] = useState<any>(null);
  const [isCalculatingMatch, setIsCalculatingMatch] = useState(false);
  const [connectedMatchName, setConnectedMatchName] = useState("");

  const router = useRouter();
  const [userProfile, setUserProfile] = useState<any>(null);
  const [matches, setMatches] = useState<any[]>([]);
  const [isLoadingMatches, setIsLoadingMatches] = useState(true);
  const [matchesViewedToday, setMatchesViewedToday] = useState(() => {
    if (typeof window !== 'undefined') {
      const todayKey = 'knot_daily_views_' + new Date().toISOString().slice(0, 10);
      return parseInt(localStorage.getItem(todayKey) || '0', 10);
    }
    return 0;
  });
  const [isMessageLimitReached, setIsMessageLimitReached] = useState(false);
  const [showSubscriptionModal, setShowSubscriptionModal] = useState(false);
  const [limitNoticeMessage, setLimitNoticeMessage] = useState<string | null>(null);
  const [showPreferencesModal, setShowPreferencesModal] = useState(false);
  const [prefSaving, setPrefSaving] = useState(false);
  const [prefAgeMin, setPrefAgeMin] = useState(22);
  const [prefAgeMax, setPrefAgeMax] = useState(42);
  const [prefChildrenStatus, setPrefChildrenStatus] = useState("Open to either");
  const [prefChildrenDesire, setPrefChildrenDesire] = useState("Open to children");
  const [prefTimeline, setPrefTimeline] = useState("1-2 Years");
  const [prefOrigin, setPrefOrigin] = useState("");
  const [prefResidence, setPrefResidence] = useState("");
  const [prefCity, setPrefCity] = useState("");
  const [prefReligion, setPrefReligion] = useState("Christian");
  const [prefTraits, setPrefTraits] = useState<string[]>(["Emotionally mature", "Family-oriented", "Loyal & Devoted"]);
  const [exchangeRates, setExchangeRates] = useState<Record<string, number> | null>(null);

  // In-App Notification Center States
  const [showNotificationsModal, setShowNotificationsModal] = useState(false);
  const [notifCategoryFilter, setNotifCategoryFilter] = useState<string | null>(null);
  const [notifications, setNotifications] = useState<any[]>([
    {
      id: 'notif_welcome',
      title: 'Welcome to Sovereign Matrimony',
      body: 'Your profile is active in the Knot global marriage registry. Review verified candidates matching your marital values.',
      category: 'matches',
      timestamp: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
      isRead: false,
      actionTab: 'matches',
      actionLabel: 'View Curated Matches',
    },
    {
      id: 'notif_kyc',
      title: 'Verify Your Identity for Gold Seal',
      body: 'Didit 3D Liveness and Government ID verification increases candidate response rates by 4.2x.',
      category: 'verification',
      timestamp: new Date(Date.now() - 60 * 60 * 1000).toISOString(),
      isRead: false,
      actionModal: 'didit',
      actionLabel: 'Verify ID Now',
    },
    {
      id: 'notif_membership',
      title: 'Daily Curated Registry Ready',
      body: '3 AI-curated marriage candidates are available in your deck today. Upgrade for 15-100 matches daily.',
      category: 'tiers',
      timestamp: new Date(Date.now() - 180 * 60 * 1000).toISOString(),
      isRead: false,
      actionModal: 'subscription',
      actionLabel: 'View Membership Tiers',
    },
  ]);

  const unreadNotifsCount = notifications.filter(n => !n.isRead).length;

  const handleMarkAllNotifsAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
  };

  const handleNotificationClick = (notif: any) => {
    setNotifications(prev => prev.map(n => n.id === notif.id ? { ...n, isRead: true } : n));
    setShowNotificationsModal(false);
    if (notif.actionTab) {
      setActiveTab(notif.actionTab);
    } else if (notif.actionModal === 'subscription') {
      setShowSubscriptionModal(true);
    } else if (notif.actionModal === 'didit') {
      setShowDiditModal(true);
    }
  };

  // Didit Verification Modal States
  const [showDiditModal, setShowDiditModal] = useState(false);
  const [diditIdFile, setDiditIdFile] = useState<File | null>(null);
  const [diditSelfieFile, setDiditSelfieFile] = useState<File | null>(null);
  const [diditLoading, setDiditLoading] = useState(false);
  const [diditError, setDiditError] = useState("");

  const handleDiditVerify = async () => {
    if (!diditIdFile || !diditSelfieFile) {
      setDiditError("Please select both your Government ID and a Live Selfie.");
      return;
    }
    setDiditLoading(true);
    setDiditError("");
    try {
      const API_URL = getApiUrl() || 'http://localhost:8080';
      const token = localStorage.getItem('knot_token');
      const formData = new FormData();
      formData.append('idFront', diditIdFile);
      formData.append('selfie', diditSelfieFile);

      const res = await fetch(`${API_URL}/users/verify-identity`, {
        method: "POST",
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData,
      });

      const data = await res.json();
      if (!res.ok || data.success === false) {
        setDiditError(data.message || data.error || "Didit verification failed. Please ensure your ID is clear and your selfie is well lit.");
        setDiditLoading(false);
        return;
      }

      setUserProfile((prev: any) => ({
        ...prev,
        isVerified: true,
        idVerified: true,
        selfieVerified: true,
        verificationBadge: 'GOLD',
        trustScore: data.trustScore || 95,
      }));
      setShowDiditModal(false);
      setDiditLoading(false);
      alert("🎉 Identity verified successfully via Didit Sovereign KYC! Your Gold Trust Seal has been activated.");
    } catch (e: any) {
      setDiditError(e.message || "Network error connecting to Didit verification service.");
      setDiditLoading(false);
    }
  };

  const loadMatchesAndProfile = async () => {
    const token = localStorage.getItem('knot_token');
    if (!token) {
      router.push('/login');
      return;
    }

    setIsLoadingMatches(true);
    try {
      const API_URL = getApiUrl();
      const headers = { 'Authorization': `Bearer ${token}` };

      // Fetch profile and daily matches in parallel for maximum speed
      const [profileRes, matchesRes] = await Promise.all([
        fetch(`${API_URL}/users/profile`, { headers }),
        fetch(`${API_URL}/matches/daily`, { headers }),
      ]);

      let profileData: any = userProfile;
      if (profileRes.ok) {
        profileData = await profileRes.json();
        setUserProfile(profileData);
        if (profileData.preferredOriginCountry) setPrefOrigin(profileData.preferredOriginCountry);
        if (profileData.preferredResidenceCountry) setPrefResidence(profileData.preferredResidenceCountry);
        if (profileData.preferredResidenceCity) setPrefCity(profileData.preferredResidenceCity);
        if (profileData.childrenPreference) setPrefChildrenDesire(profileData.childrenPreference);
        if (profileData.marriageTimeline) setPrefTimeline(profileData.marriageTimeline);
        if (profileData.religion) setPrefReligion(profileData.religion);
        if (profileData.idealPartnerTraits && Array.isArray(profileData.idealPartnerTraits) && profileData.idealPartnerTraits.length > 0) {
          setPrefTraits(profileData.idealPartnerTraits);
        }
        if (profileData.marriageExpectations) {
          const ageM = profileData.marriageExpectations.match(/(\d{2})\s*-\s*(\d{2})/);
          if (ageM) {
            setPrefAgeMin(parseInt(ageM[1], 10));
            setPrefAgeMax(parseInt(ageM[2], 10));
          }
          if (profileData.marriageExpectations.toLowerCase().includes('no kids') || profileData.marriageExpectations.toLowerCase().includes('no children')) {
            setPrefChildrenStatus("No children yet");
          } else if (profileData.marriageExpectations.toLowerCase().includes('has kids') || profileData.marriageExpectations.toLowerCase().includes('has children')) {
            setPrefChildrenStatus("Has children");
          }
        }
        if (profileData.profileImages && profileData.profileImages.length > 0) {
          const sorted = [...profileData.profileImages].sort((a: any, b: any) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
          setUserPhotos(sorted.map((img: any) => resolveImageUrl(img.url)));
        } else if (profileData.profileImageUrls && profileData.profileImageUrls.length > 0) {
          setUserPhotos(profileData.profileImageUrls.map((u: string) => resolveImageUrl(u)));
        } else if (profileData.photoUrls && profileData.photoUrls.length > 0) {
          setUserPhotos(profileData.photoUrls.map((u: string) => resolveImageUrl(u)));
        } else if (profileData.selfieUrl) {
          setUserPhotos([resolveImageUrl(profileData.selfieUrl)]);
        }
      }

      const matchesData = matchesRes.ok ? await matchesRes.json() : [];
      const normalizedMatches = (Array.isArray(matchesData) ? matchesData : []).map((m: any) => {
        const partner = m.partner || {};
        let rawImages = partner.profileImages || m.profileImages || [];
        let imageUrls: string[] = [];
        if (Array.isArray(rawImages) && rawImages.length > 0) {
          const sorted = [...rawImages].sort((a: any, b: any) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
          imageUrls = sorted.map((img: any) => resolveImageUrl(img.url || img));
        } else if (partner.profileImageUrls?.length > 0) {
          imageUrls = partner.profileImageUrls.map((u: string) => resolveImageUrl(u));
        } else if (m.profileImageUrls?.length > 0) {
          imageUrls = m.profileImageUrls.map((u: string) => resolveImageUrl(u));
        } else if (partner.selfieUrl) {
          imageUrls = [resolveImageUrl(partner.selfieUrl)];
        } else if (m.selfieUrl) {
          imageUrls = [resolveImageUrl(m.selfieUrl)];
        }

        const primaryPhoto = imageUrls[0] || (partner.photoUrl ? resolveImageUrl(partner.photoUrl) : (m.photoUrl ? resolveImageUrl(m.photoUrl) : ''));

        return {
          ...partner,
          ...m,
          partner: {
            ...partner,
            photoUrl: primaryPhoto,
            imageUrls,
          },
          photoUrl: primaryPhoto,
          imageUrls,
          firstName: partner.firstName || m.firstName || 'Match',
          lastName: partner.lastName || m.lastName || '',
          bio: partner.bio || m.bio || '',
          occupation: partner.occupation || m.occupation || '',
          residenceCity: partner.residenceCity || m.residenceCity || '',
          residenceCountry: partner.residenceCountry || m.residenceCountry || '',
          archetype: partner.personalityArchetype || m.archetype || '',
          attachment: partner.attachmentStyle || m.attachment || '',
          trustScore: partner.trustScore || m.trustScore || 95,
          compatibilityScore: m.scores?.compatibilityScore || m.compatibilityScore || 92,
        };
      });

      // Strict self-exclusion and opposite-gender filtering to mirror mobile app & backend constraints
      const currentUserId = (profileData?.id || '').trim();
      const currentUserEmail = (profileData?.email || '').trim().toLowerCase();
      const userFirstName = (profileData?.firstName || '').trim().toLowerCase();
      const userLastName = (profileData?.lastName || '').trim().toLowerCase();
      const currentUserFullName = `${userFirstName} ${userLastName}`.trim();
      const userGender = (profileData?.gender || '').trim().toLowerCase();
      const isUserMale = userGender === 'male' || userGender === 'man' || userGender === 'm';
      const isUserFemale = userGender === 'female' || userGender === 'woman' || userGender === 'f';

      const filteredMatches = normalizedMatches.filter((m: any) => {
        const partner = m.partner || {};
        const partnerId = (partner.id || m.id || '').trim();
        const partnerEmail = (partner.email || m.email || '').trim().toLowerCase();
        const pFirst = (partner.firstName || m.firstName || '').trim().toLowerCase();
        const pLast = (partner.lastName || m.lastName || '').trim().toLowerCase();
        const partnerFullName = `${pFirst} ${pLast}`.trim();

        // 1. Strict Self-Exclusion: User should NEVER be matched to themselves
        if (currentUserId && partnerId === currentUserId) return false;
        if (currentUserEmail && partnerEmail && partnerEmail === currentUserEmail) return false;
        if (currentUserFullName && partnerFullName && currentUserFullName === partnerFullName) return false;
        if (userFirstName && pFirst && userFirstName === pFirst && userLastName && pLast && userLastName === pLast) return false;

        // 2. Strict Opposite-Gender Enforcement: Only opposite sex (Male <-> Female)
        const candGender = (partner.gender || m.gender || '').trim().toLowerCase();
        const isCandMale = candGender === 'male' || candGender === 'man' || candGender === 'm';
        const isCandFemale = candGender === 'female' || candGender === 'woman' || candGender === 'f';

        if (isUserMale) {
          return isCandFemale && !isCandMale;
        } else if (isUserFemale) {
          return isCandMale && !isCandFemale;
        }

        if (candGender && userGender && candGender === userGender) {
          return false;
        }

        return true;
      });

      setMatches(filteredMatches);
      setCurrentMatchIndex(0);
      setActiveMatchImageIndex(0);
      setIsLoadingMatches(false);

      // Fetch dynamic exchange rates asynchronously in background without blocking UI
      if (!exchangeRates) {
        fetch('https://open.er-api.com/v6/latest/USD')
          .then((r) => (r.ok ? r.json() : null))
          .then((d) => {
            if (d?.rates) setExchangeRates(d.rates);
          })
          .catch(() => {});
      }
    } catch (err) {
      console.error("Error fetching data", err);
      setMatches([]);
      setIsLoadingMatches(false);
    }
  };

  useEffect(() => {
    loadMatchesAndProfile();
  }, [router]);

  const [currentMatchIndex, setCurrentMatchIndex] = useState(0);
  const activeMatch = matches[currentMatchIndex];
  const [activeMatchImageIndex, setActiveMatchImageIndex] = useState(0);

  // User Photos State
  const [userPhotos, setUserPhotos] = useState<string[]>([]);
  const [primaryPhotoIndex, setPrimaryPhotoIndex] = useState(0);

  // AI Coach State
  const [coachMessages, setCoachMessages] = useState([
    { role: "ai", text: "Hello! I am your KNOT Relationship Coach. Ask me anything about attachment styles, conflict resolution, or first-date suggestions." }
  ]);
  const [coachInput, setCoachInput] = useState("");

  // Messaging State
  const [chatMessages, setChatMessages] = useState<{sender: string, text: string}[]>([]);
  const [chatInput, setChatInput] = useState("");
  const [aiChatTip, setAiChatTip] = useState("");

  // Chat currently open in the Messages inbox (independent of the match browsing carousel)
  const activeChatMatch = matches.find(m => m.partner?.id === activeChatId);

  // Load real message history with the selected chat partner and poll for new ones
  useEffect(() => {
    const partnerId = activeChatId;
    if (!partnerId || activeTab !== "messages") return;

    let active = true;
    const loadMessages = async () => {
      const token = localStorage.getItem('knot_token');
      if (!token) return;
      try {
        const API_URL = getApiUrl();
        const res = await fetch(`${API_URL}/messages/${partnerId}`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!res.ok || !active) return;
        const data = await res.json();
        setChatMessages((Array.isArray(data) ? data : []).map((m: any) => ({
          sender: m.senderId === userProfile?.id ? "me" : "them",
          text: m.content,
        })));
      } catch (err) {
        console.error("Failed to load messages", err);
      }
    };

    loadMessages();
    const intervalId = setInterval(loadMessages, 3000);
    return () => { active = false; clearInterval(intervalId); };
  }, [activeChatId, activeTab, userProfile?.id]);

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const scrollToBottom = () => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: "smooth", block: "end" });
    }
  };
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      if (activeTab === "coach" || activeTab === "messages") {
        scrollToBottom();
      }
    }, 100);
    return () => clearTimeout(timeoutId);
  }, [coachMessages, chatMessages, activeTab]);

  const handleSendCoachMessage = async () => {
    if (!coachInput.trim()) return;
    
    const userQ = coachInput;
    const updatedMessages = [...coachMessages, { role: "user", text: userQ }];
    setCoachMessages(updatedMessages);
    setCoachInput("");

    // Optional: Set a typing state if desired, here we just await fetch
    try {
      const res = await fetch(`${getApiUrl() || 'http://localhost:8080'}/ai/coach`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          conversationHistory: updatedMessages.slice(0, -1),
          userProfile: { 
            firstName: userProfile?.firstName || "Web", 
            lastName: userProfile?.lastName || "User", 
            dateOfBirth: userProfile?.dateOfBirth || "1990-01-01", 
            bio: "Seeking a serious partner." 
          },
          currentMessage: userQ,
        })
      });
      const data = await res.json();
      if (data.response) {
        setCoachMessages(prev => [...prev, { role: "ai", text: data.response }]);
      } else {
        throw new Error("No response");
      }
    } catch (e) {
      setCoachMessages(prev => [...prev, { role: "ai", text: "I'm having a little trouble connecting with my insights right now." }]);
    }
  };

  const handleSendChatMessage = async () => {
    if (!chatInput.trim()) return;
    const msg = chatInput.trim();
    const partnerId = activeChatId;
    setChatMessages(prev => [...prev, { sender: "me", text: msg }]);
    setChatInput("");
    setAiChatTip("AI Coach is analyzing...");

    try {
      const token = localStorage.getItem('knot_token');
      if (partnerId && token) {
        const API_URL = getApiUrl();
        const res = await fetch(`${API_URL}/messages/${partnerId}`, {
          method: "POST",
          headers: { "Content-Type": "application/json", 'Authorization': `Bearer ${token}` },
          body: JSON.stringify({ text: msg }),
        });
        if (!res.ok) {
          const errData = await res.json().catch(() => ({}));
          const isLimit = errData.error === 'FREE_TIER_LIMIT' || errData.message === 'FREE_TIER_LIMIT' || res.status === 403;
          if (isLimit) {
            setIsMessageLimitReached(true);
            setShowSubscriptionModal(true);
            setAiChatTip("🔒 Free tier messaging limit reached. Upgrade to continue unlimited conversations.");
            return;
          }
        }
      }

      const history = chatMessages.map(m => ({ role: m.sender === "me" ? "user" : "match", text: m.text }));
      const res = await fetch(`${getApiUrl()}/ai/coach`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          conversationHistory: history,
          userProfile: { firstName: userProfile?.firstName || "Web", lastName: userProfile?.lastName || "User", dateOfBirth: userProfile?.dateOfBirth || "1990-01-01", bio: "Seeking a serious partner." },
          currentMessage: msg,
        })
      });
      const data = await res.json();
      if (data.response) {
        setAiChatTip(`AI Coach: ${data.response}`);
      } else {
        setAiChatTip("");
      }
    } catch (e) {
      if (e instanceof Error && e.message.includes('FREE_TIER_LIMIT')) {
        setIsMessageLimitReached(true);
        setShowSubscriptionModal(true);
        setAiChatTip("Free tier limit reached. Upgrade to message more matches.");
      } else {
        setAiChatTip("AI Coach is currently unavailable.");
      }
    }
  };

  const handleSavePreferences = async () => {
    setPrefSaving(true);
    try {
      const token = localStorage.getItem('knot_token');
      const API_URL = getApiUrl();
      const expectations = `Age ${prefAgeMin}-${prefAgeMax} | ${prefChildrenStatus} | Seeking intentional marriage alignment`;
      const updated = {
        ...userProfile,
        preferredOriginCountry: prefOrigin,
        preferredResidenceCountry: prefResidence,
        preferredResidenceCity: prefCity,
        childrenPreference: prefChildrenDesire,
        marriageTimeline: prefTimeline,
        religion: prefReligion,
        idealPartnerTraits: prefTraits,
        marriageExpectations: expectations,
      };
      const res = await fetch(`${API_URL}/users/${userProfile?.id}`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`,
        },
        body: JSON.stringify(updated),
      });
      if (res.ok) {
        setUserProfile(updated);
        setShowPreferencesModal(false);
        alert("✨ Partner Preferences Saved! Matchmaking algorithm has updated your recommendations.");
        loadMatchesAndProfile();
      } else {
        alert("Could not save preferences. Please check your network connection.");
      }
    } catch (err) {
      console.error("Save preferences error", err);
      alert("Error saving preferences.");
    } finally {
      setPrefSaving(false);
    }
  };

  const getDailyLimit = () => {
    switch (userProfile?.subscriptionTier) {
      case 'Executive': return 100;
      case 'Elite': return 25;
      case 'Premium': return 15;
      default: return 3; // Essential / Free
    }
  };

  const checkLimitAndProceed = (action: () => void) => {
    const limit = getDailyLimit();
    const nextCount = matchesViewedToday + 1;
    setMatchesViewedToday(nextCount);
    if (typeof window !== 'undefined') {
      const todayKey = 'knot_daily_views_' + new Date().toISOString().slice(0, 10);
      localStorage.setItem(todayKey, String(nextCount));
    }
    // Always execute the action so user can freely view and loop their matches
    action();

    // Check once-a-day reminder across all tiers
    if (typeof window !== 'undefined' && nextCount >= limit) {
      const reminderKey = 'knot_upgrade_notice_shown_' + new Date().toISOString().slice(0, 10);
      const alreadyShown = localStorage.getItem(reminderKey);
      if (!alreadyShown) {
        localStorage.setItem(reminderKey, 'true');
        const tier = (userProfile?.subscriptionTier || 'Free').trim();
        let msg = `You have reviewed your ${limit} daily matches. Upgrade your tier to unlock 15+ verified candidates daily.`;
        if (tier.toLowerCase().includes('executive')) {
          msg = `You have completed your 100 daily Executive matches. Your curated deck refreshes at midnight.`;
        } else if (tier.toLowerCase().includes('elite')) {
          msg = `You have completed your 25 daily Elite matches. Upgrade to Executive for 100 candidates daily.`;
        } else if (tier.toLowerCase().includes('premium')) {
          msg = `You have completed your 15 daily Premium matches. Upgrade to Elite or Executive for 25 to 100 candidates daily.`;
        }
        setLimitNoticeMessage(msg);
      }
    }
  };

  const handlePass = () => {
    checkLimitAndProceed(() => {
      if (matches.length > 0) {
        setCurrentMatchIndex(prev => (prev + 1) % matches.length);
        setActiveMatchImageIndex(0);
      }
    });
  };

  const handleConnect = () => {
    checkLimitAndProceed(async () => {
      const token = localStorage.getItem('knot_token');
      if (token && activeMatch) {
        fetch(`${getApiUrl()}/matches/action`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${token}`,
          },
          body: JSON.stringify({
            matchId: activeMatch.matchId,
            partnerId: activeMatch.partner?.id || activeMatch.id,
            action: "like",
          }),
        }).catch(() => {});
      }

      setConnectedMatchName(`${activeMatch?.firstName || 'Partner'} ${activeMatch?.lastName || ''}`.trim());
      setMatchCompatibility({
        compatibilityScore: activeMatch?.scores?.compatibilityScore || activeMatch?.compatibilityScore || 92,
        emotionalAlignment: activeMatch?.scores?.emotionalAlignment || 91,
        communicationStyle: activeMatch?.scores?.communicationStyle || 88,
        valuesAlignment: activeMatch?.scores?.valuesAlignment || 95,
        aiExplanation: activeMatch?.aiExplanation || "You share a strong foundational alignment based on matrimonial values and life vision.",
      });
      setIsCalculatingMatch(false);
      setShowMatchModal(true);
    });
  };

  const handlePaystackCheckout = (tierName: string, amount: number, currency: string) => {
    const paystack = (window as any).PaystackPop;
    if (!paystack) {
      const script = document.createElement("script");
      script.src = "https://js.paystack.co/v1/inline.js";
      script.async = true;
      script.onload = () => {
        const loadedPaystack = (window as any).PaystackPop;
        if (loadedPaystack) {
          triggerPaystackPopup(loadedPaystack, tierName, amount, currency);
        } else {
          alert("Error: Paystack payment gateway could not be loaded. Please disable any active adblockers and try again.");
        }
      };
      script.onerror = () => {
        alert("Error: Connection to secure payment gateway failed. Please check your internet connection.");
      };
      document.body.appendChild(script);
    } else {
      triggerPaystackPopup(paystack, tierName, amount, currency);
    }
  };

  const triggerPaystackPopup = (paystack: any, tierName: string, amount: number, currency: string) => {
    try {
      const handler = paystack.setup({
        key: "pk_live_b2c985a001f4c23b6bd1a19af4193f57c901446c",
        email: userProfile?.email || "gabriel@knot.com",
        amount: amount * 100, // Paystack requires amount in kobo/cents
        currency: currency,
        ref: "KNOT-WEB-" + Date.now(),
        callback: function(response: any) {
          console.log("Paystack payment successful! Reference:", response.reference);
          // Run async logic inside a standard function to prevent Paystack type-check errors
          (async () => {
            try {
              const verifyRes = await fetch(`${getApiUrl() || 'http://localhost:8080'}/payments/verify`, {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                },
                body: JSON.stringify({
                  reference: response.reference,
                  userId: userProfile?.id,
                  months: 1,
                }),
              });
              const verifyData = await verifyRes.json();
              if (verifyData && verifyData.success) {
                setIsPremium(true);
                setUserProfile({ ...userProfile, subscriptionTier: tierName });
                setShowSubscriptionModal(false);
                alert(`🌟 ${tierName} Registry Activated!\n\nWelcome to ${tierName} Alignment. You now have expanded access to matches, advanced compatibility analysis, and our 24/7 AI Relationship Coach.`);
              } else {
                alert("Verification Pending: Payment is being processed. Please refresh your profile in a few moments.");
              }
            } catch (err) {
              console.error("Verification error:", err);
              alert("Verification Connection Issue: Your payment was successful, but we couldn't connect to the verification server. Our webhook will automatically verify and upgrade your profile shortly.");
            }
          })();
        },
        onClose: () => {
          console.log("Checkout closed.");
        }
      });
      handler.openIframe();
    } catch (err) {
      console.error("Paystack popup error:", err);
      alert("Error: Secure payment setup failed. Please try again.");
    }
  };

  const getFormattedPrice = (tier: string, country: string | undefined) => {
    const isAfrica = ['Nigeria', 'Ghana', 'Kenya', 'South Africa'].includes(country || '');
    
    // Helper to dynamically calculate local price based on live exchange rates
    const calcDynamic = (usd: number, currencyCode: string, symbol: string) => {
      if (exchangeRates && exchangeRates[currencyCode]) {
        const rate = exchangeRates[currencyCode];
        let rawAmount = usd * rate;
        
        // Make the numbers look cleaner based on the currency magnitude
        if (currencyCode === 'NGN') rawAmount = Math.ceil(rawAmount / 100) * 100;
        else if (currencyCode === 'KES') rawAmount = Math.ceil(rawAmount / 10) * 10;
        else rawAmount = Math.ceil(rawAmount);

        return { symbol, amount: rawAmount.toLocaleString(), currency: currencyCode, rawAmount, usdAmount: usd };
      }
      return null;
    };

    if (tier === 'Premium') {
      const usdAmount = isAfrica ? 12 : 14.99;
      if (!isAfrica) return { symbol: '$', amount: '14.99', currency: 'USD', rawAmount: 14.99, usdAmount };
      switch (country) {
        case 'Nigeria': return calcDynamic(usdAmount, 'NGN', '₦') || { symbol: '₦', amount: '18,000', currency: 'NGN', rawAmount: 18000, usdAmount };
        case 'Ghana': return calcDynamic(usdAmount, 'GHS', 'GH₵') || { symbol: 'GH₵', amount: '168', currency: 'GHS', rawAmount: 168, usdAmount };
        case 'Kenya': return calcDynamic(usdAmount, 'KES', 'KSh') || { symbol: 'KSh', amount: '1,560', currency: 'KES', rawAmount: 1560, usdAmount };
        case 'South Africa': return calcDynamic(usdAmount, 'ZAR', 'R') || { symbol: 'R', amount: '228', currency: 'ZAR', rawAmount: 228, usdAmount };
        default: return { symbol: '$', amount: '12.00', currency: 'USD', rawAmount: 12, usdAmount };
      }
    }
    if (tier === 'Elite') {
      const usdAmount = isAfrica ? 25 : 39.99;
      if (!isAfrica) return { symbol: '$', amount: '39.99', currency: 'USD', rawAmount: 39.99, usdAmount };
      switch (country) {
        case 'Nigeria': return calcDynamic(usdAmount, 'NGN', '₦') || { symbol: '₦', amount: '37,500', currency: 'NGN', rawAmount: 37500, usdAmount };
        case 'Ghana': return calcDynamic(usdAmount, 'GHS', 'GH₵') || { symbol: 'GH₵', amount: '350', currency: 'GHS', rawAmount: 350, usdAmount };
        case 'Kenya': return calcDynamic(usdAmount, 'KES', 'KSh') || { symbol: 'KSh', amount: '3,250', currency: 'KES', rawAmount: 3250, usdAmount };
        case 'South Africa': return calcDynamic(usdAmount, 'ZAR', 'R') || { symbol: 'R', amount: '475', currency: 'ZAR', rawAmount: 475, usdAmount };
        default: return { symbol: '$', amount: '25.00', currency: 'USD', rawAmount: 25, usdAmount };
      }
    }
    if (tier === 'Executive') {
      const usdAmount = 199;
      if (!isAfrica) return { symbol: '$', amount: '199', currency: 'USD', rawAmount: 199, usdAmount };
      switch (country) {
        case 'Nigeria': return calcDynamic(usdAmount, 'NGN', '₦') || { symbol: '₦', amount: '298,500', currency: 'NGN', rawAmount: 298500, usdAmount };
        case 'Ghana': return calcDynamic(usdAmount, 'GHS', 'GH₵') || { symbol: 'GH₵', amount: '2,786', currency: 'GHS', rawAmount: 2786, usdAmount };
        case 'Kenya': return calcDynamic(usdAmount, 'KES', 'KSh') || { symbol: 'KSh', amount: '25,870', currency: 'KES', rawAmount: 25870, usdAmount };
        case 'South Africa': return calcDynamic(usdAmount, 'ZAR', 'R') || { symbol: 'R', amount: '3,781', currency: 'ZAR', rawAmount: 3781, usdAmount };
        default: return { symbol: '$', amount: '199.00', currency: 'USD', rawAmount: 199, usdAmount };
      }
    }
    return { symbol: '$', amount: '0', currency: 'USD', rawAmount: 0, usdAmount: 0 };
  };

  return (
    <div className="flex h-screen bg-[#0A0E14] text-white overflow-hidden">
      
      {/* Sidebar Backdrop for Mobile */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 z-30 bg-black/60 backdrop-blur-sm md:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Activity & Notifications Modal */}
      {showNotificationsModal && (
        <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="relative w-full max-w-xl bg-[#121721] rounded-[28px] border border-[#D4AF37]/40 p-6 shadow-2xl animate-in fade-in zoom-in-95 duration-200">
            {/* Header */}
            <div className="flex items-center justify-between pb-4 border-b border-white/10">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-full bg-[#D4AF37]/15 border border-[#D4AF37]/40 flex items-center justify-center text-[#D4AF37]">
                  <Bell className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white font-serif">Notifications & Activity</h3>
                  <p className="text-[11px] text-gray-400">Real-time matrimonial matches and registry updates</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {unreadNotifsCount > 0 && (
                  <button
                    onClick={handleMarkAllNotifsAsRead}
                    className="text-xs font-semibold text-[#D4AF37] hover:underline px-2 py-1 cursor-pointer"
                  >
                    Mark All Read
                  </button>
                )}
                <button
                  onClick={() => setShowNotificationsModal(false)}
                  className="w-8 h-8 rounded-full bg-white/5 hover:bg-white/10 flex items-center justify-center text-gray-400 hover:text-white transition-colors cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Category Filter Pills */}
            <div className="flex items-center gap-2 py-3 overflow-x-auto no-scrollbar">
              {[
                { label: 'All', value: null },
                { label: 'Matches', value: 'matches' },
                { label: 'Messages', value: 'messages' },
                { label: 'Tiers & Limits', value: 'tiers' },
                { label: 'Verification', value: 'verification' },
              ].map((tab, idx) => {
                const isActive = notifCategoryFilter === tab.value;
                return (
                  <button
                    key={idx}
                    onClick={() => setNotifCategoryFilter(tab.value)}
                    className={`px-3 py-1 rounded-full text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
                      isActive
                        ? 'bg-[#D4AF37] text-black shadow-sm shadow-[#D4AF37]/40'
                        : 'bg-white/5 text-gray-400 hover:text-white border border-white/5'
                    }`}
                  >
                    {tab.label}
                  </button>
                );
              })}
            </div>

            {/* Notification Cards */}
            <div className="space-y-2.5 max-h-[420px] overflow-y-auto pr-1">
              {notifications
                .filter(n => !notifCategoryFilter || n.category === notifCategoryFilter)
                .map((notif) => (
                  <div
                    key={notif.id}
                    onClick={() => handleNotificationClick(notif)}
                    className={`p-4 rounded-2xl border transition-all cursor-pointer flex items-start gap-3.5 group ${
                      notif.isRead
                        ? 'bg-white/[0.02] border-white/5 hover:border-white/10'
                        : 'bg-[#18202F] border-[#D4AF37]/40 shadow-sm shadow-[#D4AF37]/5 hover:border-[#D4AF37]'
                    }`}
                  >
                    <div className="w-9 h-9 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 flex items-center justify-center text-[#D4AF37] flex-shrink-0 mt-0.5">
                      {notif.category === 'verification' && <ShieldCheck className="w-4 h-4 text-emerald-400" />}
                      {notif.category === 'tiers' && <Sparkles className="w-4 h-4 text-[#D4AF37]" />}
                      {notif.category === 'messages' && <MessageSquare className="w-4 h-4 text-rose-400" />}
                      {(notif.category === 'matches' || notif.category === 'system') && <Heart className="w-4 h-4 text-[#D4AF37]" />}
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between gap-2">
                        <h4 className={`text-xs font-bold truncate ${notif.isRead ? 'text-gray-200' : 'text-white'}`}>
                          {notif.title}
                        </h4>
                        <span className="text-[10px] text-gray-500 whitespace-nowrap">
                          {Math.max(1, Math.round((Date.now() - new Date(notif.timestamp).getTime()) / 60000))}m ago
                        </span>
                      </div>
                      <p className="text-xs text-gray-400 mt-1 leading-relaxed">
                        {notif.body}
                      </p>
                      {notif.actionLabel && (
                        <div className="mt-2.5 flex items-center gap-1 text-[11px] font-bold text-[#D4AF37] group-hover:underline">
                          <span>{notif.actionLabel}</span>
                          <ChevronRight className="w-3.5 h-3.5" />
                        </div>
                      )}
                    </div>

                    {!notif.isRead && (
                      <span className="w-2 h-2 rounded-full bg-[#D4AF37] flex-shrink-0 mt-1 shadow-[0_0_8px_#D4AF37]" />
                    )}
                  </div>
                ))}
            </div>
          </div>
        </div>
      )}

      {/* Subscription Overlay Modal */}
      {showSubscriptionModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/80 backdrop-blur-md overflow-y-auto">
          <div className="relative w-full max-w-7xl bg-[#121721] rounded-[32px] border border-white/10 p-8 shadow-2xl my-auto">
            <button 
              onClick={() => setShowSubscriptionModal(false)}
              className="absolute top-6 right-6 w-10 h-10 bg-white/5 hover:bg-white/10 rounded-full flex items-center justify-center text-gray-400 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
            
            <div className="text-center space-y-4 mb-12">
              <h2 className="text-4xl font-black font-serif text-white">Daily Match Limit Reached</h2>
              <p className="text-gray-400 max-w-xl mx-auto">You've reached the maximum number of highly-curated matches for your current plan today. Upgrade to a premium tier to unlock more daily matches and exclusive relationship intelligence features.</p>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {/* Essential Plan */}
              <div className="glass-card rounded-[24px] p-6 border border-white/5 relative flex flex-col opacity-80 hover:opacity-100 transition-opacity">
                <h3 className="text-xl font-black text-white mb-2">Knot Essential</h3>
                <div className="flex items-end gap-1 mb-6">
                  <span className="text-3xl font-black text-white">Free</span>
                </div>
                <ul className="space-y-4 flex-1 mb-8">
                  <li className="flex items-start gap-2 text-sm text-gray-400">
                    <CheckCircle2 className="w-4 h-4 text-gray-500 flex-shrink-0 mt-0.5" />
                    <span className="font-bold text-white text-xs">3 AI-Curated Matches/Day</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-400">
                    <CheckCircle2 className="w-4 h-4 text-gray-500 flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Basic Matchmaking & Messaging</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-400">
                    <CheckCircle2 className="w-4 h-4 text-gray-500 flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Identity Verification</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-400">
                    <CheckCircle2 className="w-4 h-4 text-gray-500 flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Basic Compatibility Score</span>
                  </li>
                </ul>
                <button 
                  onClick={() => setShowSubscriptionModal(false)}
                  className="w-full py-3 rounded-xl bg-white/5 hover:bg-white/10 border border-white/10 text-white font-bold transition-all text-sm"
                >
                  Current Plan
                </button>
              </div>

              {/* Premium Plan */}
              <div className="glass-card rounded-[24px] p-6 border border-white/5 relative flex flex-col">
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-[#2D1B4E] text-[#D4AF37] px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest border border-[#D4AF37]/20 whitespace-nowrap">
                  Most Popular
                </div>
                <h3 className="text-xl font-black text-white mb-2">Knot Premium</h3>
                <div className="flex items-end gap-1 mb-6">
                  <span className="text-3xl font-black text-[#D4AF37]">{getFormattedPrice('Premium', userProfile?.residenceCountry).symbol}{getFormattedPrice('Premium', userProfile?.residenceCountry).amount}</span>
                  <span className="text-xs text-gray-500 font-bold mb-1">/mo</span>
                </div>
                <ul className="space-y-4 flex-1 mb-8">
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="font-bold text-white text-xs">15 AI Matches/Day</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Unlimited Messaging</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="text-xs">AI Relationship Coach</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Detailed Compatibility Breakdowns</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Advanced Filters</span>
                  </li>
                </ul>
                <button 
                  onClick={() => handlePaystackCheckout(
                    'Premium', 
                    getFormattedPrice('Premium', userProfile?.residenceCountry).usdAmount, 
                    'USD'
                  )}
                  className="w-full py-3 rounded-xl bg-white/5 hover:bg-[#2D1B4E]/50 border border-white/10 hover:border-[#D4AF37]/30 text-white font-bold transition-all text-sm"
                >
                  Select Premium
                </button>
              </div>

              {/* Elite Plan */}
              <div className="glass-card rounded-[24px] p-6 border border-[#D4AF37]/30 relative flex flex-col shadow-lg shadow-[#D4AF37]/5 bg-[#D4AF37]/5">
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-[#D4AF37] text-black px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest whitespace-nowrap">
                  Elite Verification
                </div>
                <h3 className="text-xl font-black text-white mb-2">Knot Elite</h3>
                <div className="flex items-end gap-1 mb-6">
                  <span className="text-3xl font-black text-[#D4AF37]">{getFormattedPrice('Elite', userProfile?.residenceCountry).symbol}{getFormattedPrice('Elite', userProfile?.residenceCountry).amount}</span>
                  <span className="text-xs text-gray-500 font-bold mb-1">/mo</span>
                </div>
                <ul className="space-y-4 flex-1 mb-8">
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="font-bold text-white text-xs">25 Elite Matches/Day</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Deep Emotional Compatibility Map</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Highest Trust Visibility</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Invisible & Incognito Mode</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-[#D4AF37] flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Priority Matchmaking Placement</span>
                  </li>
                </ul>
                <button 
                  onClick={() => handlePaystackCheckout(
                    'Elite', 
                    getFormattedPrice('Elite', userProfile?.residenceCountry).usdAmount, 
                    'USD'
                  )}
                  className="w-full py-3 rounded-xl rose-glow-btn text-white font-black transition-all text-sm"
                >
                  Select Elite
                </button>
              </div>

              {/* VIP Executive */}
              <div className="glass-card rounded-[24px] p-6 border border-white/5 relative flex flex-col bg-black">
                <h3 className="text-xl font-black text-white mb-2">Knot Executive</h3>
                <div className="flex items-end gap-1 mb-6">
                  <span className="text-3xl font-black text-white">{getFormattedPrice('Executive', userProfile?.residenceCountry).symbol}{getFormattedPrice('Executive', userProfile?.residenceCountry).amount}</span>
                  <span className="text-xs text-gray-500 font-bold mb-1">/mo</span>
                </div>
                <ul className="space-y-4 flex-1 mb-8">
                  <li className="flex items-start gap-2 text-sm text-gray-400">
                    <CheckCircle2 className="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" />
                    <span className="font-bold text-white text-xs">Unlimited Concierge Matches</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-400">
                    <CheckCircle2 className="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Human Matchmaking Assistance</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-400">
                    <CheckCircle2 className="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Private Relationship Advisors</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-400">
                    <CheckCircle2 className="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" />
                    <span className="text-xs">White-Glove Onboarding</span>
                  </li>
                  <li className="flex items-start gap-2 text-sm text-gray-400">
                    <CheckCircle2 className="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" />
                    <span className="text-xs">Psychological Reviews</span>
                  </li>
                </ul>
                <button 
                  onClick={() => handlePaystackCheckout(
                    'Executive', 
                    getFormattedPrice('Executive', userProfile?.residenceCountry).usdAmount, 
                    'USD'
                  )}
                  className="w-full py-3 rounded-xl bg-white text-black font-black hover:bg-gray-200 transition-all text-sm"
                >
                  Apply for Executive
                </button>
              </div>
            </div>
            
            <p className="text-center text-xs text-gray-500 mt-8">Secure payments processed safely. Cancel anytime.</p>
          </div>
        </div>
      )}

      {/* Sidebar Navigation */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-[#121721] border-r border-white/5 flex flex-col justify-between p-6 transition-transform duration-300 md:static md:translate-x-0 ${isSidebarOpen ? "translate-x-0" : "-translate-x-full"}`}>
        <div className="space-y-8">
          <div className="flex items-center justify-between">
            <Link href="/" className="flex items-center gap-2" onClick={() => setIsSidebarOpen(false)}>
              <span className="text-2xl font-serif font-black tracking-wider text-[#F5F5F1] flex items-center gap-1">
                KNOT<span className="text-[#D4AF37]">.</span>
              </span>
            </Link>
            <button 
              onClick={() => setIsSidebarOpen(false)}
              className="p-1 text-gray-400 hover:text-white md:hidden"
              aria-label="Close sidebar"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <nav className="space-y-2">
            <button 
              onClick={() => { setActiveTab("matches"); setIsSidebarOpen(false); }}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-sm font-semibold transition-all ${activeTab === "matches" ? "bg-[#2D1B4E] text-[#D4AF37] border-l-2 border-[#D4AF37]" : "text-gray-400 hover:text-white hover:bg-white/5"}`}
            >
              <Compass className="w-4 h-4" /> Daily Matches
            </button>
            <button 
              onClick={() => { setActiveTab("insights"); setIsSidebarOpen(false); }}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-sm font-semibold transition-all ${activeTab === "insights" ? "bg-[#2D1B4E] text-[#D4AF37] border-l-2 border-[#D4AF37]" : "text-gray-400 hover:text-white hover:bg-white/5"}`}
            >
              <BrainCircuit className="w-4 h-4" /> Insights Dashboard
            </button>
            <button 
              onClick={() => { setActiveTab("coach"); setIsSidebarOpen(false); }}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-sm font-semibold transition-all ${activeTab === "coach" ? "bg-[#2D1B4E] text-[#D4AF37] border-l-2 border-[#D4AF37]" : "text-gray-400 hover:text-white hover:bg-white/5"}`}
            >
              <Bot className="w-4 h-4" /> AI Coach
            </button>
            <button 
              onClick={() => { setActiveTab("messages"); setIsSidebarOpen(false); }}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-sm font-semibold transition-all ${activeTab === "messages" ? "bg-[#2D1B4E] text-[#D4AF37] border-l-2 border-[#D4AF37]" : "text-gray-400 hover:text-white hover:bg-white/5"}`}
            >
              <MessageSquare className="w-4 h-4" /> Messages
            </button>
            <button 
              onClick={() => { setActiveTab("profile"); setIsSidebarOpen(false); }}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-sm font-semibold transition-all ${activeTab === "profile" ? "bg-[#2D1B4E] text-[#D4AF37] border-l-2 border-[#D4AF37]" : "text-gray-400 hover:text-white hover:bg-white/5"}`}
            >
              <User className="w-4 h-4" /> My Profile
            </button>
            {userProfile?.role === 'ADMIN' && (
              <Link href="/admin" className="w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-sm font-semibold text-gray-400 hover:text-[#D4AF37] hover:bg-white/5 transition-all">
                <Shield className="w-4 h-4" /> Admin Panel
              </Link>
            )}
          </nav>
        </div>

        <div className="space-y-4">
          <div className="flex items-center gap-3 p-3 rounded-2xl bg-white/5 border border-white/5">
            <div className="w-8 h-8 rounded-full overflow-hidden flex-shrink-0 border border-white/10">
              {userPhotos.length > 0 ? (
                <img src={userPhotos[0]} alt={userProfile?.firstName || 'Profile'} className="w-full h-full object-cover" />
              ) : userProfile?.selfieUrl ? (
                <img src={userProfile.selfieUrl} alt={userProfile?.firstName || 'Profile'} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full bg-[#10B981]/20 flex items-center justify-center text-[#10B981]">
                  <ShieldCheck className="w-4 h-4" />
                </div>
              )}
            </div>
            <div>
              <h5 className="text-xs font-bold text-white leading-none">{userProfile?.firstName || userProfile?.name || "User"}</h5>
              <span className="text-[9px] text-[#10B981] font-bold">Base Trust 98%</span>
            </div>
          </div>
          <Link href="/" className="w-full flex items-center gap-3 px-4 py-3 text-sm font-semibold text-red-400 hover:bg-red-500/5 rounded-2xl transition-colors">
            <LogOut className="w-4 h-4" /> Log Out
          </Link>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 bg-[#0A0E14] relative overflow-y-auto flex flex-col">
        
        {/* Top Navbar */}
        <header className="h-16 md:h-20 border-b border-white/5 flex items-center justify-between px-4 md:px-8 bg-[#0A0E14]/50 backdrop-blur-md sticky top-0 z-10">
          <div className="flex items-center gap-2 md:gap-3">
            <button 
              onClick={() => setIsSidebarOpen(true)}
              className="p-2 -ml-2 text-gray-400 hover:text-white md:hidden"
              aria-label="Open sidebar"
            >
              <Menu className="w-6 h-6" />
            </button>
            <h2 className="text-base md:text-xl font-serif font-black text-white capitalize truncate max-w-[180px] sm:max-w-none">
              {activeTab === "matches" && "Your AI Curated Match"}
              {activeTab === "insights" && "Relationship Intelligence Dashboard"}
              {activeTab === "coach" && "AI Relationship Counselor"}
              {activeTab === "messages" && "Secure Messenger"}
              {activeTab === "profile" && "My Identity Registry"}
            </h2>
          </div>
          <div className="flex items-center gap-3">
            {/* Notification Bell Button */}
            <button
              type="button"
              onClick={() => setShowNotificationsModal(true)}
              className="relative p-2 md:p-2.5 rounded-full bg-white/5 hover:bg-white/10 border border-white/10 hover:border-[#D4AF37]/50 text-gray-300 hover:text-[#D4AF37] transition-all flex items-center justify-center cursor-pointer"
              title="Activity & Notifications"
            >
              <Bell className="w-4 h-4" />
              {unreadNotifsCount > 0 && (
                <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-[#E11D48] text-white text-[9px] font-black flex items-center justify-center shadow-md">
                  {unreadNotifsCount}
                </span>
              )}
            </button>

            <div className="trust-badge px-2.5 py-1.5 md:px-3.5 rounded-full text-[9px] md:text-[10px] font-black uppercase tracking-wider flex items-center gap-1 md:gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5 flex-shrink-0" />
              <span className="hidden sm:inline">Biometric Identity Active</span>
              <span className="sm:hidden">Active</span>
            </div>
          </div>
        </header>

        {/* Tab Components */}
        <div className="flex-1 p-4 sm:p-8 max-w-4xl mx-auto w-full">

          {/* TAB 1: DAILY MATCHES */}
          {activeTab === "matches" && isLoadingMatches && (
            <div className="flex flex-col items-center justify-center h-64 space-y-4">
              <Compass className="w-8 h-8 text-[#D4AF37] animate-spin" />
              <p className="text-sm text-gray-400">Curating your AI matches...</p>
            </div>
          )}
          {activeTab === "matches" && !isLoadingMatches && matches.length === 0 && (
            <div className="glass-card rounded-[32px] p-10 sm:p-12 border border-white/10 text-center space-y-5 flex flex-col items-center justify-center max-w-lg mx-auto">
              <div className="w-18 h-18 rounded-full bg-[#D4AF37]/12 border border-[#D4AF37]/40 flex items-center justify-center text-[#D4AF37] mb-2 p-4">
                <Compass className="w-9 h-9" />
              </div>
              <h3 className="text-2xl font-serif font-bold text-white">Curating Sovereign Matches</h3>
              <p className="text-sm text-gray-400 max-w-md leading-relaxed">
                The Knot Registry is actively scanning for verified {userProfile?.gender?.toLowerCase() === 'male' ? 'eligible ladies' : userProfile?.gender?.toLowerCase() === 'female' ? 'eligible gentlemen' : 'compatible candidates'} who align with your matrimonial values and marital vision.
              </p>
              <button
                type="button"
                onClick={loadMatchesAndProfile}
                className="mt-2 px-8 py-3.5 rounded-full text-xs uppercase tracking-widest font-black bg-[#D4AF37] text-black hover:bg-[#E5C158] transition-all flex items-center gap-2 shadow-lg shadow-[#D4AF37]/20 cursor-pointer"
              >
                <RefreshCw className="w-4 h-4" /> Check for New Candidates
              </button>
            </div>
          )}
          {activeTab === "matches" && !isLoadingMatches && activeMatch && (
            <div className="space-y-4">

              <div className="grid grid-cols-1 md:grid-cols-12 gap-8 items-start">
              {/* Profile Card & Mobile-Style Circular Action Buttons */}
              <div className="md:col-span-7 flex flex-col items-center space-y-5">
                <div className="w-full glass-card rounded-[32px] overflow-hidden border border-[#D4AF37]/30 p-3 sm:p-4 shadow-2xl">
                  <div className="relative aspect-[4/5] rounded-[24px] overflow-hidden bg-gray-900 flex items-center justify-center group">
                    {activeMatch.imageUrls?.[activeMatchImageIndex] || activeMatch.photoUrl ? (
                      <img 
                        src={activeMatch.imageUrls?.[activeMatchImageIndex] || activeMatch.photoUrl} 
                        alt={activeMatch.firstName} 
                        className="w-full h-full object-cover brightness-95 transition-all duration-300" 
                      />
                    ) : (
                      <User className="w-24 h-24 text-gray-700" />
                    )}

                    {/* Multi-photo indicators if more than 1 image */}
                    {activeMatch.imageUrls?.length > 1 && (
                      <>
                        <button 
                          type="button"
                          onClick={(e) => { 
                            e.stopPropagation(); 
                            setActiveMatchImageIndex(prev => prev > 0 ? prev - 1 : activeMatch.imageUrls.length - 1); 
                          }} 
                          className="absolute left-3 top-1/2 -translate-y-1/2 p-2 rounded-full bg-black/50 text-white hover:bg-black/80 transition-all z-20"
                          title="Previous photo"
                        >
                          <ChevronLeft className="w-4 h-4" />
                        </button>
                        <button 
                          type="button"
                          onClick={(e) => { 
                            e.stopPropagation(); 
                            setActiveMatchImageIndex(prev => prev < activeMatch.imageUrls.length - 1 ? prev + 1 : 0); 
                          }} 
                          className="absolute right-3 top-1/2 -translate-y-1/2 p-2 rounded-full bg-black/50 text-white hover:bg-black/80 transition-all z-20"
                          title="Next photo"
                        >
                          <ChevronRight className="w-4 h-4" />
                        </button>
                        <div className="absolute top-3 left-0 right-0 flex justify-center gap-1.5 px-5 z-20">
                          {activeMatch.imageUrls.map((_: any, i: number) => (
                            <div 
                              key={i} 
                              onClick={(e) => { e.stopPropagation(); setActiveMatchImageIndex(i); }}
                              className={`h-1 flex-1 rounded-full cursor-pointer transition-all ${i === activeMatchImageIndex ? 'bg-[#D4AF37] shadow-md shadow-[#D4AF37]/60' : 'bg-white/35'}`} 
                            />
                          ))}
                        </div>
                      </>
                    )}

                    {/* Top Compatibility Pill & Gold Verified Badge */}
                    <div className={`absolute ${activeMatch.imageUrls?.length > 1 ? 'top-6' : 'top-4'} left-4 right-4 flex items-center justify-between z-20`}>
                      <div className="px-3 py-1.5 rounded-full bg-[#0A0D14]/80 backdrop-blur-md border border-[#D4AF37] shadow-[0_0_10px_rgba(212,175,55,0.25)] flex items-center gap-1.5">
                        <Heart className="w-3.5 h-3.5 text-[#E11D48] fill-[#E11D48]" />
                        <span className="text-[11px] font-bold tracking-wider text-[#D4AF37]">
                          {(activeMatch.compatibilityScore || 92) >= 80
                            ? `${activeMatch.compatibilityScore || 92}% ALIGNED`
                            : `${activeMatch.compatibilityScore || 75}% CLOSEST MATCH`}
                        </span>
                      </div>

                      <div className="flex items-center gap-1.5">
                        {activeMatch.imageUrls?.length > 1 && (
                          <span className="px-2.5 py-1 rounded-full bg-[#0A0D14]/80 backdrop-blur-md border border-[#D4AF37]/40 text-[10px] font-bold text-[#D4AF37]">
                            {activeMatchImageIndex + 1}/{activeMatch.imageUrls.length}
                          </span>
                        )}
                        <div className="px-2.5 py-1 rounded-full bg-[#0A0D14]/80 backdrop-blur-md border border-[#D4AF37]/50 flex items-center gap-1.5">
                          <span className="w-4 h-4 rounded-full bg-gradient-to-br from-[#F3E5AB] via-[#D4AF37] to-[#AA7C11] flex items-center justify-center text-black text-[10px] font-black">
                            ✓
                          </span>
                          <span className="text-[10px] font-bold tracking-wider text-[#D4AF37] border border-[#D4AF37]/40 rounded px-1.5 py-0.5">
                            GOLD
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Clean Unclustered Bottom Info Overlay (No Archetype or Timeline chips on card) */}
                    <div 
                      onClick={() => setActiveTab("matchProfile")}
                      className="absolute bottom-0 left-0 right-0 pt-24 pb-5 px-5 bg-gradient-to-t from-black/95 via-black/55 to-transparent z-10 cursor-pointer group/title"
                    >
                      <div className="flex items-center gap-2">
                        <h3 className="text-2xl font-serif font-bold text-white group-hover/title:text-[#D4AF37] transition-colors truncate">
                          {activeMatch.firstName} {activeMatch.lastName}{formatAgeOrDob(activeMatch.dateOfBirth) ? `, ${formatAgeOrDob(activeMatch.dateOfBirth)}` : ''}
                        </h3>
                        <span className="w-5 h-5 rounded-full bg-gradient-to-br from-[#F3E5AB] via-[#D4AF37] to-[#AA7C11] flex items-center justify-center text-black text-xs font-black shrink-0 shadow-sm">
                          ✓
                        </span>
                      </div>

                      <div className="flex items-center gap-1.5 text-xs text-gray-300 font-medium mt-1 truncate">
                        <Briefcase className="w-3.5 h-3.5 text-[#D4AF37] shrink-0" />
                        <span className="truncate">{activeMatch.occupation || 'Professional'}</span>
                        <span className="text-gray-500 mx-1">•</span>
                        <MapPin className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                        <span className="text-gray-400 truncate">
                          {[activeMatch.residenceCity, activeMatch.residenceCountry].filter(Boolean).join(', ') || 'Global Registry'}
                        </span>
                      </div>

                      <div className="mt-2.5 flex items-center justify-between text-xs font-semibold text-[#D4AF37] group-hover/title:underline">
                        <span>View Psychological Compatibility & Vows</span>
                        <ChevronRight className="w-4 h-4" />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Mobile-Matched Circular Action Buttons (X, Star, and Love) */}
                <div className="flex items-center justify-center gap-6 pt-1 pb-2">
                  {/* Pass Button (X) */}
                  <button
                    type="button"
                    onClick={handlePass}
                    title="Pass Candidate"
                    className="w-14 h-14 rounded-full bg-[#121721] border-[1.5px] border-gray-500/40 shadow-[0_4px_14px_rgba(107,114,128,0.25)] flex items-center justify-center text-gray-400 hover:text-white hover:border-gray-300 hover:scale-105 active:scale-95 transition-all cursor-pointer"
                  >
                    <X className="w-6 h-6 stroke-[2.2]" />
                  </button>

                  {/* View Compatibility & Full Profile Button (Star) */}
                  <button
                    type="button"
                    onClick={() => setActiveTab("matchProfile")}
                    title="View Psychological Compatibility & Vows"
                    className="w-16 h-16 rounded-full bg-[#121721] border-[1.5px] border-[#D4AF37]/60 shadow-[0_4px_18px_rgba(212,175,55,0.3)] flex items-center justify-center text-[#D4AF37] hover:border-[#D4AF37] hover:scale-105 active:scale-95 transition-all cursor-pointer"
                  >
                    <Star className="w-7 h-7 fill-[#D4AF37] text-[#D4AF37]" />
                  </button>

                  {/* Like & Connect Button (Love / Heart) */}
                  <button
                    type="button"
                    onClick={handleConnect}
                    title="Connect & Initiate Marriage Conversation"
                    className="w-14 h-14 rounded-full bg-[#121721] border-[1.5px] border-[#E11D48]/50 shadow-[0_4px_16px_rgba(225,29,72,0.3)] flex items-center justify-center text-[#E11D48] hover:border-[#E11D48] hover:scale-105 active:scale-95 transition-all cursor-pointer"
                  >
                    <Heart className="w-6 h-6 fill-[#E11D48] text-[#E11D48]" />
                  </button>
                </div>
              </div>

              {/* Match Details & AI Explanations */}
              <div className="md:col-span-5 space-y-6">
                <div className="glass-card rounded-[28px] p-6 border border-white/10 space-y-6">
                  <h4 className="text-xs uppercase tracking-widest text-[#D4AF37] font-black">Compatibility Profile</h4>
                  
                  <div className="space-y-3">
                    <div>
                      <div className="flex justify-between text-xs font-bold mb-1">
                        <span className="text-gray-400">Values Alignment</span>
                        <span className="text-[#D4AF37]">{activeMatch.scores?.valuesAlignment || 95}%</span>
                      </div>
                      <div className="h-1.5 bg-white/5 rounded-full overflow-hidden">
                        <div className="h-full bg-[#D4AF37]" style={{ width: `${activeMatch.scores?.valuesAlignment || 95}%` }} />
                      </div>
                    </div>
                    <div>
                      <div className="flex justify-between text-xs font-bold mb-1">
                        <span className="text-gray-400">Emotional Synergy</span>
                        <span className="text-[#E27D8D]">{activeMatch.scores?.emotionalAlignment || 91}%</span>
                      </div>
                      <div className="h-1.5 bg-white/5 rounded-full overflow-hidden">
                        <div className="h-full bg-[#E27D8D]" style={{ width: `${activeMatch.scores?.emotionalAlignment || 91}%` }} />
                      </div>
                    </div>
                    <div>
                      <div className="flex justify-between text-xs font-bold mb-1">
                        <span className="text-gray-400">Communication Match</span>
                        <span className="text-white">{activeMatch.scores?.communicationStyle || 88}%</span>
                      </div>
                      <div className="h-1.5 bg-white/5 rounded-full overflow-hidden">
                        <div className="h-full bg-white" style={{ width: `${activeMatch.scores?.communicationStyle || 88}%` }} />
                      </div>
                    </div>
                  </div>
                </div>

                {/* AI Explanation Glow Box */}
                <div className="glass-card rounded-[28px] p-6 border border-[#D4AF37]/30 shadow-lg shadow-[#D4AF37]/5 space-y-4">
                  <div className="flex items-center gap-2 text-sm text-[#D4AF37] font-black">
                    <Bot className="w-5 h-5 animate-pulse" /> Why You Matched
                  </div>
                  <p className="text-xs text-gray-300 leading-relaxed font-sans">
                    {activeMatch.aiExplanation}
                  </p>
                </div>
              </div>
            </div>
          </div>
          )}

          {/* TAB: MATCH PROFILE DETAIL */}
          {activeTab === "matchProfile" && activeMatch && (
            <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
              <button 
                onClick={() => setActiveTab("matches")}
                className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors"
              >
                <ArrowLeft className="w-5 h-5" /> Back to Curated Match
              </button>
              
              <div className="glass-card rounded-[32px] overflow-hidden border border-[#D4AF37]/30">
                <div className="relative h-[400px] md:h-[500px] group">
                  {activeMatch.imageUrls?.[activeMatchImageIndex] || activeMatch.photoUrl ? (
                    <img src={activeMatch.imageUrls?.[activeMatchImageIndex] || activeMatch.photoUrl} alt={activeMatch.firstName} className="w-full h-full object-cover object-center transition-all duration-500" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-gray-900">
                      <User className="w-16 h-16 text-gray-700" />
                    </div>
                  )}
                  
                  {activeMatch.imageUrls?.length > 1 && (
                    <>
                      <button onClick={() => setActiveMatchImageIndex(prev => prev > 0 ? prev - 1 : activeMatch.imageUrls.length - 1)} className="absolute left-4 top-1/2 -translate-y-1/2 p-2 rounded-full bg-black/40 text-white opacity-0 group-hover:opacity-100 transition-opacity hover:bg-black/60 z-20">
                        <ChevronLeft className="w-5 h-5" />
                      </button>
                      <button onClick={() => setActiveMatchImageIndex(prev => prev < activeMatch.imageUrls.length - 1 ? prev + 1 : 0)} className="absolute right-4 top-1/2 -translate-y-1/2 p-2 rounded-full bg-black/40 text-white opacity-0 group-hover:opacity-100 transition-opacity hover:bg-black/60 z-20">
                        <ChevronRight className="w-5 h-5" />
                      </button>
                      <div className="absolute top-4 left-0 right-0 flex justify-center gap-2 px-8 z-10">
                        {activeMatch.imageUrls.map((_: any, i: number) => (
                          <div key={i} className={`h-1.5 flex-1 rounded-full ${i === activeMatchImageIndex ? 'bg-white shadow-lg shadow-white/50' : 'bg-white/30'}`} />
                        ))}
                      </div>
                    </>
                  )}

                  <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent pointer-events-none z-0" />
                  <div className="absolute bottom-0 left-0 p-8 z-10">
                    <h2 className="text-4xl font-black text-white">{activeMatch.firstName} {activeMatch.lastName}, {activeMatch.dateOfBirth}</h2>
                    <p className="text-gray-400 font-bold tracking-widest uppercase text-sm mt-2">{activeMatch.occupation} • {activeMatch.residenceCity}, {activeMatch.residenceCountry}</p>
                  </div>
                </div>

                <div className="p-8 space-y-8">
                  {/* Tags */}
                  <div className="flex flex-wrap gap-2">
                    <span className="px-4 py-2 rounded-full bg-white/5 border border-white/10 text-xs font-bold text-gray-300">Archetype: {activeMatch.archetype}</span>
                    <span className="px-4 py-2 rounded-full bg-[#2D1B4E]/30 border border-[#D4AF37]/20 text-xs font-bold text-[#D4AF37]">Attachment: {activeMatch.attachment}</span>
                    <span className="px-4 py-2 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-xs font-bold text-emerald-400">Trust Score: {activeMatch.trustScore}%</span>
                    <span className="px-4 py-2 rounded-full bg-blue-500/10 border border-blue-500/20 text-xs font-bold text-blue-400">Readiness: {activeMatch.readiness}%</span>
                  </div>

                  {/* Bio */}
                  <div>
                    <h3 className="text-sm font-black text-gray-400 uppercase tracking-widest mb-3">About Me</h3>
                    <p className="text-gray-200 leading-relaxed font-serif text-lg italic">"{activeMatch.bio}"</p>
                  </div>

                  {/* ══ IDENTITY & ROOTS ══ */}
                  <div className="space-y-4 mt-8">
                    <h3 className="text-sm font-black text-white uppercase tracking-widest border-b border-white/10 pb-2">Identity & Roots</h3>
                    <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Marital Status</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.maritalStatus || 'Not specified'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Occupation</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.occupation || 'Not specified'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Current Residence</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.residenceCity}, {activeMatch.residenceCountry}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Heritage & Origin</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.originCity}, {activeMatch.originCountry}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Cultural Identity</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.culturalBackground || 'Not specified'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Nationality</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.nationality || 'Not specified'}</p>
                      </div>
                      <div className="col-span-2 md:col-span-3">
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Languages Spoken</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.languagesSpoken?.join(', ') || 'Not specified'}</p>
                      </div>
                    </div>
                  </div>

                  {/* ══ LIFESTYLE & BELIEFS ══ */}
                  <div className="space-y-4 mt-8">
                    <h3 className="text-sm font-black text-white uppercase tracking-widest border-b border-white/10 pb-2">Lifestyle & Beliefs</h3>
                    <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Faith / Religion</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.religion || 'Not specified'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Smoking</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.smoking || 'Not specified'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Drinking</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.drinking || 'Not specified'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Children</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.childrenStatus || 'None'}</p>
                      </div>

                    </div>
                  </div>

                  {/* ══ PARTNER PREFERENCES ══ */}
                  <div className="space-y-4 mt-8">
                    <h3 className="text-sm font-black text-white uppercase tracking-widest border-b border-white/10 pb-2">Partner Preferences</h3>
                    <div className="grid grid-cols-2 gap-6">
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Preferred Partner Country of Residence</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.preferredResidenceCountry || 'Any Country'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Preferred Partner State / Province / Region</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.preferredResidenceState || 'Any State/Province/Region'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Preferred Partner Heritage Country</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.preferredOriginCountry || 'Any Country'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Native Heritage / Ethno-Cultural Background</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.preferredOriginState || 'Any Heritage'}</p>
                      </div>
                    </div>
                  </div>

                  {/* ══ MARRIAGE EXPECTATIONS ══ */}
                  <div className="space-y-4 mt-8">
                    <h3 className="text-sm font-black text-white uppercase tracking-widest border-b border-white/10 pb-2">Marriage Expectations</h3>
                    <div className="grid grid-cols-2 gap-6">
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Vow Timeline</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.marriageTimeline || 'Not specified'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Relocation</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.willingToRelocate || 'Not specified'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Children Intent</h4>
                        <p className="text-sm text-white font-medium">{activeMatch.childrenPreference || 'Not specified'}</p>
                      </div>
                      <div>
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Partner Age</h4>
                        <p className="text-sm text-white font-medium">
                          {activeMatch.preferredPartnerAgeRange ? `${activeMatch.preferredPartnerAgeRange[0]} - ${activeMatch.preferredPartnerAgeRange[1]} years` : 'Not specified'}
                        </p>
                      </div>
                      <div className="col-span-2">
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-3">Ideal Partner Traits</h4>
                        <div className="flex flex-wrap gap-2">
                          {activeMatch.idealPartnerTraits?.map((t: string) => (
                            <span key={t} className="px-3 py-1.5 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/20 text-xs font-bold text-[#D4AF37]">{t}</span>
                          )) || <p className="text-sm text-gray-500 italic">Not listed</p>}
                        </div>
                      </div>
                      <div className="col-span-2">
                        <h4 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Registry Expectations</h4>
                        <p className="text-sm text-white leading-relaxed">{activeMatch.marriageExpectations || 'Not specified'}</p>
                      </div>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="pt-6 border-t border-white/10 flex gap-4">
                    <button 
                      onClick={() => {
                        setActiveChatId(activeMatch.partner?.id || null);
                        setActiveTab("messages");
                      }}
                      className="flex-1 py-4 rounded-xl text-sm font-black rose-glow-btn text-white flex items-center justify-center gap-2"
                    >
                      <MessageSquare className="w-5 h-5" /> Start Chat
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: INSIGHTS DASHBOARD */}
          {activeTab === "insights" && (
            <div className="space-y-8">
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
                <div className="p-6 rounded-[24px] glass-card border border-[#D4AF37]/20 text-center space-y-2">
                  <Award className="w-8 h-8 text-[#D4AF37] mx-auto" />
                  <div className="text-[10px] text-gray-500 uppercase tracking-widest font-black">Readiness Index</div>
                  <div className="text-3xl font-serif font-black text-white">88%</div>
                  <span className="text-[9px] text-[#10B981] font-bold uppercase">Highly Marriage Ready</span>
                </div>
                <div className="p-6 rounded-[24px] glass-card border border-white/5 text-center space-y-2">
                  <TrendingUp className="w-8 h-8 text-white mx-auto" />
                  <div className="text-[10px] text-gray-500 uppercase tracking-widest font-black">Seriousness index</div>
                  <div className="text-3xl font-serif font-black text-white">94%</div>
                  <span className="text-[9px] text-gray-400 uppercase">Elite Intention Index</span>
                </div>
                <div className="p-6 rounded-[24px] glass-card border border-[#10B981]/20 text-center space-y-2">
                  <ShieldCheck className="w-8 h-8 text-[#10B981] mx-auto" />
                  <div className="text-[10px] text-gray-500 uppercase tracking-widest font-black">Safety trust</div>
                  <div className="text-3xl font-serif font-black text-white">98%</div>
                  <span className="text-[9px] text-[#10B981] font-bold uppercase">Authentic Signature</span>
                </div>
              </div>

              {/* Attachment styles */}
              <div className="glass-card rounded-[32px] p-8 border border-white/10 space-y-6">
                <h3 className="text-xl font-serif font-bold">Psychological Alignment Map</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div className="space-y-4">
                    <h4 className="text-sm font-semibold text-[#D4AF37]">Personality Archetype</h4>
                    <p className="text-xs text-gray-400 leading-relaxed">
                      You are registered as an **Intentional Builder**. You approach relationship milestones deliberately, prioritizing family values, structural boundaries, and joint growth curves.
                    </p>
                  </div>
                  <div className="space-y-4">
                    <h4 className="text-sm font-semibold text-[#E27D8D]">Attachment Profile</h4>
                    <p className="text-xs text-gray-400 leading-relaxed">
                      Your attachment is **Secure**. You comfortably express intimacy, manage boundaries with high collaborative intelligence, and recover from relationship friction smoothly.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: AI RELATIONSHIP COACH */}
          {activeTab === "coach" && (
            <div className="glass-card rounded-[32px] border border-white/10 flex flex-col h-[550px] overflow-hidden">
              <div className="p-4 bg-[#121721]/90 border-b border-white/5 flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-[#D4AF37]/10 flex items-center justify-center text-[#D4AF37] border border-[#D4AF37]/20">
                  <Bot className="w-6 h-6" />
                </div>
                <div>
                  <h4 className="text-sm font-bold">Counselor KNOT</h4>
                  <p className="text-[9px] uppercase tracking-wider text-[#D4AF37] font-bold">Active Coaching Session</p>
                </div>
              </div>

              <div className="flex-1 p-6 overflow-y-auto space-y-4">
                {coachMessages.map((m, idx) => (
                  <div key={idx} className={`flex items-start gap-3 ${m.role === "user" ? "justify-end" : ""}`}>
                    {m.role === "ai" && (
                      <div className="w-8 h-8 rounded-full bg-[#D4AF37]/15 flex items-center justify-center text-[#D4AF37] text-xs font-bold flex-shrink-0">AI</div>
                    )}
                    <div className={`p-4 rounded-[22px] text-xs leading-relaxed max-w-[80%] ${
                      m.role === "user" 
                        ? "bg-[#E27D8D]/15 border border-[#E27D8D]/25 rounded-tr-none text-white"
                        : "bg-white/5 border border-white/5 rounded-tl-none text-gray-300"
                    }`}>
                      {m.text}
                    </div>
                  </div>
                ))}
                <div ref={messagesEndRef} />
              </div>

              <div className="p-4 bg-[#121721]/90 border-t border-white/5 flex items-center gap-2">
                <input 
                  type="text" 
                  value={coachInput}
                  onChange={e => setCoachInput(e.target.value)}
                  onKeyDown={e => e.key === "Enter" && handleSendCoachMessage()}
                  placeholder="Ask for advice on attachment, relocation, timelines..."
                  className="flex-1 bg-white/5 border border-white/5 rounded-full py-3 px-6 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50"
                />
                <button 
                  onClick={handleSendCoachMessage}
                  className="w-10 h-10 rounded-full bg-[#2D1B4E] flex items-center justify-center text-white hover:bg-[#D4AF37] hover:text-black transition-colors"
                >
                  <Send className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}

          {/* TAB 4: MESSAGES */}
          {activeTab === "messages" && (
            <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-stretch h-[550px] md:h-[550px]">
              
              {/* Inbox Lists */}
              <div className={`md:col-span-4 glass-card rounded-[28px] border border-white/5 p-4 overflow-y-auto space-y-2 h-full ${activeChatId ? "hidden md:block" : "block"}`}>
                <h4 className="text-[10px] uppercase tracking-widest text-gray-500 font-black px-2 mb-3">Chats</h4>
                {matches.length > 0 ? (
                  matches.map((m) => (
                    <button 
                      key={m.partner?.id}
                      onClick={() => setActiveChatId(m.partner?.id || null)}
                      className={`w-full flex items-center gap-3 p-3 rounded-2xl border text-left transition-all ${activeChatId === m.partner?.id ? "bg-[#2D1B4E]/30 border-[#D4AF37]/20" : "bg-white/[0.02] border-white/5 hover:bg-white/5"}`}
                    >
                      <div className="w-10 h-10 rounded-full bg-gray-800 overflow-hidden flex-shrink-0">
                        {m.partner?.photoUrl ? (
                          <img className="w-full h-full object-cover" src={m.partner.photoUrl} alt="" />
                        ) : (
                          <User className="w-full h-full p-2 text-gray-500" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <h5 className="text-xs font-bold text-white truncate">{m.partner?.firstName || "Match"}</h5>
                        <p className="text-[10px] text-gray-400 truncate">Tap to start conversation</p>
                      </div>
                    </button>
                  ))
                ) : (
                  <div className="flex flex-col items-center justify-center h-40 text-center px-4">
                    <MessageSquare className="w-8 h-8 text-gray-600 mb-2" />
                    <p className="text-xs text-gray-500">No active conversations yet.</p>
                  </div>
                )}
              </div>

              {/* Chat View */}
              <div className={`md:col-span-8 glass-card rounded-[28px] border border-white/5 flex flex-col overflow-hidden h-full ${!activeChatId ? "hidden md:flex" : "flex"}`}>
                <div className="p-4 bg-[#121721]/90 border-b border-white/5 flex items-center gap-3">
                  <button 
                    onClick={() => setActiveChatId(null)}
                    className="p-2 -ml-2 text-gray-400 hover:text-white md:hidden"
                    aria-label="Back to chats"
                  >
                    <ArrowLeft className="w-5 h-5" />
                  </button>
                  <div className="w-8 h-8 rounded-full bg-gray-800 overflow-hidden flex-shrink-0">
                    {activeChatMatch?.partner?.photoUrl ? (
                      <img className="w-full h-full object-cover" src={activeChatMatch.partner.photoUrl} alt="" />
                    ) : (
                      <User className="w-full h-full p-1.5 text-gray-500" />
                    )}
                  </div>
                  <div>
                        <h5 className="text-xs font-bold text-white">{activeChatMatch?.partner?.firstName || "Match"}</h5>
                    <span className="text-[9px] text-[#10B981] font-bold">Verified Real Human</span>
                  </div>
                </div>

                {/* Chat Messages */}
                <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4">
                  {chatMessages.map((msg, idx) => (
                    <div key={idx} className={`flex ${msg.sender === "me" ? "justify-end" : "justify-start"} animate-in fade-in slide-in-from-bottom-2`}>
                      {msg.sender !== "me" && (
                        <img src={activeChatMatch?.partner?.photoUrl || ""} alt="Match" className="w-8 h-8 rounded-full object-cover mr-2 self-end" />
                      )}
                      <div className={`max-w-[80%] rounded-2xl px-4 py-3 text-sm ${
                        msg.sender === "me" 
                          ? "bg-[#2D1B4E] text-white border border-white/10 rounded-br-none" 
                          : "bg-white/5 text-gray-300 border border-white/5 rounded-bl-none"
                      }`}>
                        {msg.text}
                      </div>
                    </div>
                  ))}
                  <div ref={messagesEndRef} />
                </div>

                {/* AI Safety/Prompt Indicator */}
                {aiChatTip && (
                  <div className="p-3 bg-[#D4AF37]/10 border-t border-[#D4AF37]/20 text-[10px] text-[#D4AF37] font-semibold flex items-center gap-2">
                    <Bot className="w-4 h-4 flex-shrink-0 animate-bounce" /> {aiChatTip}
                  </div>
                )}

                {isMessageLimitReached ? (
                  <div className="p-4 bg-[#121721]/95 border-t border-[#D4AF37]/40 flex flex-col sm:flex-row items-center justify-between gap-3">
                    <div className="flex items-center gap-2.5 text-xs text-gray-300">
                      <Lock className="w-4 h-4 text-[#D4AF37] flex-shrink-0" />
                      <span>Free tier messaging limit reached. Upgrade to continue unlimited conversations.</span>
                    </div>
                    <button 
                      type="button"
                      onClick={() => setShowSubscriptionModal(true)}
                      className="px-4 py-2 rounded-xl bg-[#D4AF37] text-black text-xs font-black uppercase tracking-wider hover:bg-[#E5C158] transition-all flex items-center gap-1.5 shadow-md shadow-[#D4AF37]/20 flex-shrink-0 cursor-pointer"
                    >
                      <Sparkles className="w-3.5 h-3.5" />
                      <span>Upgrade Plan</span>
                    </button>
                  </div>
                ) : (
                  <div className="p-4 bg-[#121721]/90 border-t border-white/5 flex items-center gap-2">
                    <input 
                      type="text" 
                      value={chatInput}
                      onChange={e => setChatInput(e.target.value)}
                      onKeyDown={e => e.key === "Enter" && handleSendChatMessage()}
                      placeholder="Type an emotionally authentic message..."
                      className="flex-1 bg-white/5 border border-white/5 rounded-full py-3 px-6 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50"
                    />
                    <button 
                      onClick={handleSendChatMessage}
                      className="w-10 h-10 rounded-full bg-[#2D1B4E] flex items-center justify-center text-white"
                    >
                      <Send className="w-4 h-4" />
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* TAB 5: MY PROFILE */}
          {activeTab === "profile" && (
            <div className="glass-card rounded-[32px] p-6 sm:p-8 border border-white/10 space-y-8">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 pb-6 border-b border-white/5">
                {/* Profile User Info & Edit Card */}
                <div className="p-6 rounded-2xl bg-white/5 border border-white/5 space-y-4 flex flex-col justify-center">
                  <div className="flex flex-col sm:flex-row items-center sm:items-start text-center sm:text-left gap-4 sm:gap-6">
                    <div className="relative group w-20 h-20 flex-shrink-0">
                      <div className="w-20 h-20 rounded-full bg-[#2D1B4E] border border-white/10 flex items-center justify-center text-gray-300 text-3xl font-black overflow-hidden relative">
                        {userPhotos.length > 0 ? (
                          <img src={userPhotos[primaryPhotoIndex]} alt="Profile" className="w-full h-full object-cover" />
                        ) : (
                          "G"
                        )}
                      </div>
                      <div className="absolute inset-0 bg-black/60 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer">
                        <label className="cursor-pointer flex flex-col items-center justify-center w-full h-full">
                          <input type="file" accept="image/*" className="hidden" onChange={(e) => {
                            if (e.target.files && e.target.files[0]) {
                              const newPhotoUrl = URL.createObjectURL(e.target.files[0]);
                              const newPhotos = [...userPhotos];
                              newPhotos[primaryPhotoIndex] = newPhotoUrl;
                              setUserPhotos(newPhotos);
                            }
                          }} />
                          <span className="text-[9px] font-bold text-white uppercase tracking-wider text-center">Update<br/>Photo</span>
                        </label>
                      </div>
                    </div>
                    <div>
                      <h3 className="text-xl font-bold">{userProfile ? `${userProfile.firstName}, 29` : "Gabriel, 29"}</h3>
                      <p className="text-xs text-gray-400">{userProfile?.occupation || "Software Engineer"} • {userProfile?.residenceCity || "Boston"}, {userProfile?.residenceCountry || "MA"}</p>
                      {userProfile?.isVerified === false ? (
                        <div className="mt-2">
                          <span className="inline-block px-3 py-1 rounded-full bg-red-500/20 border border-red-500/30 text-[9px] font-black text-red-400 uppercase tracking-wider">Unverified Profile</span>
                          <p className="text-[10px] text-gray-400 mt-1">Please verify your ID and Selfie to become visible to the public.</p>
                        </div>
                      ) : (
                        <span className="inline-block mt-2 px-3 py-1 rounded-full bg-[#10B981]/25 border border-[#10B981]/30 text-[9px] font-black text-[#10B981] uppercase tracking-wider">Verified Registry Member</span>
                      )}
                    </div>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-2">
                    <button 
                      onClick={() => setShowPreferencesModal(true)}
                      className="w-full py-2.5 px-3 rounded-xl bg-[#D4AF37]/15 border border-[#D4AF37]/40 text-xs font-bold text-[#D4AF37] hover:bg-[#D4AF37]/25 transition-colors flex items-center justify-center gap-2 cursor-pointer shadow-sm"
                    >
                      <Sliders className="w-3.5 h-3.5" /> Match Preferences
                    </button>
                    <button 
                      onClick={() => router.push('/edit-profile')}
                      className="w-full py-2.5 px-3 rounded-xl bg-white/10 border border-white/10 text-xs font-bold text-gray-300 hover:bg-white/20 transition-colors flex items-center justify-center gap-2 cursor-pointer"
                    >
                      <Settings className="w-3.5 h-3.5" /> Edit My Profile
                    </button>
                  </div>
                </div>

                {/* Identity Verification */}
                <div className="p-6 rounded-2xl bg-white/5 border border-white/5 space-y-3 flex flex-col justify-center">
                  <div className="flex items-center justify-between">
                    <h4 className="text-xs text-gray-400 uppercase tracking-widest font-black mb-1">Identity Verification</h4>
                    <span className="text-[10px] text-[#D4AF37] font-bold">Didit Sovereign KYC</span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span>Government ID Scan</span>
                    <span className={userProfile?.isVerified === false ? "text-red-400 font-bold" : "text-[#10B981] font-bold"}>{userProfile?.isVerified === false ? "Pending" : "Approved"}</span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span>Liveness Selfie Match</span>
                    <span className={userProfile?.isVerified === false ? "text-red-400 font-bold" : "text-[#10B981] font-bold"}>{userProfile?.isVerified === false ? "Pending" : "Approved"}</span>
                  </div>
                  {userProfile?.isVerified === false ? (
                    <button
                      onClick={() => setShowDiditModal(true)}
                      className="mt-3 py-2.5 px-4 rounded-xl text-xs font-black bg-[#D4AF37] text-black hover:bg-[#E5C158] transition flex items-center justify-center gap-2 shadow-lg cursor-pointer"
                    >
                      <ShieldCheck className="w-4 h-4" /> Verify with Didit
                    </button>
                  ) : (
                    <div className="mt-3 p-2.5 rounded-xl text-[10px] font-black text-center uppercase tracking-wide bg-[#10B981]/10 border border-[#10B981]/20 text-[#10B981]">
                      Identity Verified via Didit
                    </div>
                  )}
                </div>
              </div>

              {/* My Photos Section */}
              <div className="pt-6 border-t border-white/5 space-y-4">
                <div className="flex items-center justify-between">
                  <h4 className="text-xs text-gray-400 uppercase tracking-widest font-black">My Photos</h4>
                  <span className="text-[10px] text-gray-500 font-bold">{userPhotos.length} / 5 Uploaded</span>
                </div>
                <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
                  {userPhotos.map((photo, idx) => (
                    <div key={idx} className="relative aspect-square rounded-xl overflow-hidden border border-white/10 group">
                      <img src={photo} alt={`Photo ${idx + 1}`} className="w-full h-full object-cover" />
                      {idx === primaryPhotoIndex ? (
                        <div className="absolute top-2 left-2 bg-[#D4AF37] px-2 py-0.5 rounded-md text-[8px] font-black uppercase text-black z-10">
                          Primary
                        </div>
                      ) : (
                        <button
                          onClick={() => setPrimaryPhotoIndex(idx)}
                          className="absolute bottom-2 left-2 bg-black/70 hover:bg-[#D4AF37] hover:text-black text-[8px] font-black uppercase text-white px-2 py-1 rounded-md opacity-0 group-hover:opacity-100 transition-opacity z-10"
                        >
                          Set Primary
                        </button>
                      )}
                      <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-2">
                        <button onClick={() => {
                          const newPhotos = userPhotos.filter((_, i) => i !== idx);
                          setUserPhotos(newPhotos);
                          if (primaryPhotoIndex === idx) setPrimaryPhotoIndex(0);
                          else if (primaryPhotoIndex > idx) setPrimaryPhotoIndex(prev => prev - 1);
                        }} className="text-[9px] font-bold text-red-400 hover:text-red-300 uppercase tracking-wider">
                          Remove
                        </button>
                      </div>
                    </div>
                  ))}
                  {userPhotos.length < 5 && (
                    <button onClick={() => router.push('/edit-profile')} className="aspect-square rounded-xl border-2 border-dashed border-white/20 flex flex-col items-center justify-center gap-2 hover:border-[#D4AF37]/50 hover:bg-[#D4AF37]/5 transition-all">
                      <Camera className="w-6 h-6 text-gray-400" />
                      <span className="text-[9px] font-bold text-gray-400 uppercase tracking-wider">Add Photo</span>
                    </button>
                  )}
                </div>
              </div>

              {/* Full Profile Detail Section */}
              <div className="pt-6 border-t border-white/5 space-y-8">
                {/* 1. Psychological Profile (Requested to keep) */}
                <div className="space-y-4">
                  <h4 className="text-xs text-gray-400 uppercase tracking-widest font-black">Psychological Profile</h4>
                  <div className="flex flex-wrap gap-2">
                    <span className="px-3 py-1.5 rounded-full bg-white/5 border border-white/5 text-xs text-gray-300 font-medium">✔ The Intentional Builder</span>
                    <span className="px-3 py-1.5 rounded-full bg-[#2D1B4E]/30 border border-[#D4AF37]/20 text-xs text-[#D4AF37] font-medium">✔ Secure Attachment</span>
                  </div>
                </div>

                {/* 2. Identity & Roots */}
                <div className="space-y-4">
                  <h4 className="text-xs text-gray-400 uppercase tracking-widest font-black border-b border-white/5 pb-2">Identity & Roots</h4>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Marriage History</div>
                      <div className="text-sm text-white font-bold">{userProfile?.maritalStatus || "Not specified"}</div>
                    </div>
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Occupation</div>
                      <div className="text-sm text-white font-bold">{userProfile?.occupation || "Not specified"}</div>
                    </div>
                  </div>

                  <div className="p-5 rounded-2xl bg-[#121721] border border-white/10">
                    <h5 className="text-[10px] text-[#D4AF37] uppercase tracking-widest font-black mb-3">Current Residence</h5>
                    <div className="grid grid-cols-3 gap-2 mb-4">
                      <div><div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Country</div><div className="text-sm text-white font-bold">{userProfile?.residenceCountry || "USA"}</div></div>
                      <div><div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">State</div><div className="text-sm text-white font-bold">{userProfile?.residenceState || "MA"}</div></div>
                      <div><div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">City</div><div className="text-sm text-white font-bold">{userProfile?.residenceCity || "Boston"}</div></div>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Languages Spoken</div>
                      <div className="text-sm text-white font-bold">{userProfile?.languagesSpoken?.join(", ") || "English"}</div>
                    </div>
                  </div>
                </div>

                {/* 3. Lifestyle & Beliefs */}
                <div className="space-y-4">
                  <h4 className="text-xs text-gray-400 uppercase tracking-widest font-black border-b border-white/5 pb-2">Lifestyle & Beliefs</h4>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Faith/Religion</div>
                      <div className="text-sm text-white font-bold">Christian</div>
                    </div>
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Smoking</div>
                      <div className="text-sm text-white font-bold">Never</div>
                    </div>
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Drinking</div>
                      <div className="text-sm text-white font-bold">Socially</div>
                    </div>
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Children</div>
                      <div className="text-sm text-white font-bold">No kids</div>
                    </div>
                  </div>
                  

                </div>

                {/* 4. Marriage Expectations */}
                <div className="space-y-4">
                  <h4 className="text-xs text-gray-400 uppercase tracking-widest font-black border-b border-white/5 pb-2">Marriage Expectations</h4>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Vow Timeline</div>
                      <div className="text-sm text-white font-bold">1-2 years</div>
                    </div>
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Relocation</div>
                      <div className="text-sm text-white font-bold">Maybe</div>
                    </div>
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Children Intent</div>
                      <div className="text-sm text-white font-bold">Wants children</div>
                    </div>
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Partner Age</div>
                      <div className="text-sm text-white font-bold">25 - 30 years</div>
                    </div>
                  </div>

                  <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                    <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-2">Ideal Partner Traits</div>
                    <div className="flex flex-wrap gap-2">
                      <span className="px-3 py-1.5 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 text-[#D4AF37] text-[10px] font-bold uppercase tracking-wider">Emotionally Available</span>
                      <span className="px-3 py-1.5 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 text-[#D4AF37] text-[10px] font-bold uppercase tracking-wider">Loyal</span>
                      <span className="px-3 py-1.5 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 text-[#D4AF37] text-[10px] font-bold uppercase tracking-wider">Driven</span>
                    </div>
                  </div>

                  <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                    <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Registry Expectations</div>
                    <div className="text-sm text-white leading-relaxed">Looking for someone who is ready to settle down, has done their emotional work, and is excited to build a legacy based on mutual respect and shared faith.</div>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4 mt-4">
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Readiness</div>
                      <div className="text-sm text-[#10B981] font-bold">94% (Elite)</div>
                    </div>
                    <div className="p-4 rounded-2xl bg-white/5 border border-white/5">
                      <div className="text-[9px] text-gray-500 uppercase tracking-widest font-black mb-1">Trust Score</div>
                      <div className="text-sm text-[#10B981] font-bold">98% (Verified)</div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Membership Subscription (Moved to Bottom) */}
              <div className="pt-6 border-t border-white/5">
                <div className="p-6 rounded-2xl bg-white/5 border border-white/5 space-y-3">
                  <h4 className="text-xs text-gray-400 uppercase tracking-widest font-black mb-2">Membership Subscription</h4>
                  {isPremium ? (
                    <div className="space-y-2">
                      <div className="flex items-center justify-between text-xs">
                        <span>Active Plan</span>
                        <span className="text-[#D4AF37] font-bold">Premium Alignment (Live)</span>
                      </div>
                      <div className="flex items-center justify-between text-xs">
                        <span>Renews On</span>
                        <span className="text-gray-400">June 16, 2026</span>
                      </div>
                      <div className="mt-2 p-2.5 rounded-xl bg-[#D4AF37]/10 border border-[#D4AF37]/20 text-[10px] text-[#D4AF37] font-black text-center uppercase tracking-wide">
                        🌟 Premium Membership Active
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      <div className="flex items-center justify-between text-xs">
                        <span>Active Plan</span>
                        <span className="text-gray-400 font-bold">Base Member</span>
                      </div>
                      <button
                        onClick={() => setShowSubscriptionModal(true)}
                        className="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-[#D4AF37] to-[#AA7C11] text-[#0A0E14] font-black text-xs uppercase tracking-wider hover:opacity-90 transition-opacity flex items-center justify-center gap-2"
                      >
                        <Sparkles className="w-4 h-4" /> Upgrade to Premium
                      </button>
                    </div>
                  )}
                </div>
              </div>

            </div>
          )}

        </div>
      </main>

      {/* Mutual Match Modal */}
      {showMatchModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4">
          <div className="glass-card rounded-[36px] max-w-sm w-full p-8 border border-[#D4AF37]/30 text-center space-y-6 animate-in fade-in zoom-in duration-300">
            <div className="w-20 h-20 mx-auto rounded-full bg-[#D4AF37]/15 flex items-center justify-center text-[#D4AF37] animate-bounce">
              <Heart className="w-10 h-10 fill-current" />
            </div>
            
            <div className="space-y-2">
              <h3 className="text-2xl font-serif font-black text-white">Mutual Match!</h3>
              <p className="text-xs text-gray-300 font-sans">
                Congratulations! You and <span className="text-[#D4AF37] font-bold">{connectedMatchName}</span> are mutually aligned and marriage ready.
              </p>
            </div>

            <div className="p-4 rounded-2xl bg-white/5 border border-white/5 space-y-2">
              <div className="text-[10px] text-gray-400 uppercase tracking-widest font-black">Compatibility Score</div>
              <div className="text-3xl font-serif font-black text-[#D4AF37]">
                {isCalculatingMatch ? <span className="text-xl animate-pulse text-gray-400">Analyzing...</span> : `${matchCompatibility?.compatibilityScore || 94}%`}
              </div>
            </div>
            {!isCalculatingMatch && matchCompatibility?.aiExplanation && (
              <div className="text-xs text-gray-300 italic">
                {matchCompatibility.aiExplanation}
              </div>
            )}

            <div className="flex flex-col gap-3">
              <button 
                onClick={() => {
                  setShowMatchModal(false);
                  setActiveTab("messages");
                }}
                className="w-full py-4 rounded-full text-xs font-black rose-glow-btn text-white"
              >
                Start Secure Conversation
              </button>
              <button 
                onClick={() => {
                  setShowMatchModal(false);
                  if (currentMatchIndex < matches.length - 1) {
                    setCurrentMatchIndex(prev => prev + 1);
                    setActiveMatchImageIndex(0);
                  }
                }}
                className="w-full py-3 rounded-full text-xs font-bold bg-white/5 border border-white/10 hover:bg-white/10 text-gray-400"
              >
                Keep Exploring Matches
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Didit Sovereign KYC Verification Modal */}
      {showDiditModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4">
          <div className="glass-card rounded-[32px] max-w-md w-full p-6 sm:p-8 border border-[#D4AF37]/40 text-center space-y-5 animate-in fade-in zoom-in duration-300 relative">
            <button
              onClick={() => {
                setShowDiditModal(false);
                setDiditError("");
              }}
              className="absolute top-5 right-5 text-gray-400 hover:text-white"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="w-14 h-14 mx-auto rounded-2xl bg-[#D4AF37]/15 border border-[#D4AF37]/30 flex items-center justify-center text-[#D4AF37]">
              <ShieldCheck className="w-8 h-8" />
            </div>

            <div className="space-y-2">
              <h3 className="text-xl font-serif font-black text-white">Didit Sovereign Identity Verification</h3>
              <p className="text-xs uppercase tracking-widest text-[#D4AF37] font-bold">
                Completed Exclusively on KNOT Mobile App
              </p>
            </div>

            <p className="text-xs leading-relaxed text-gray-300 text-left">
              To guarantee 100% cryptographic liveness assurance, prevent synthetic media, and comply with sovereign registry safety, Didit 3D face liveness scanning and official government ID capture are conducted exclusively via the <strong className="text-white">KNOT Mobile App</strong> (iOS & Android).
            </p>

            <div className="bg-[#121721] border border-white/10 rounded-2xl p-4 text-left space-y-3">
              <div className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 flex items-center justify-center text-[#D4AF37] text-xs font-bold shrink-0 mt-0.5">
                  1
                </div>
                <div className="text-xs text-gray-300">
                  <span className="font-bold text-white">Open KNOT Mobile App:</span> Launch the mobile application on your iOS or Android smartphone.
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 flex items-center justify-center text-[#D4AF37] text-xs font-bold shrink-0 mt-0.5">
                  2
                </div>
                <div className="text-xs text-gray-300">
                  <span className="font-bold text-white">Sign In:</span> Log in using your registered account credentials.
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 flex items-center justify-center text-[#D4AF37] text-xs font-bold shrink-0 mt-0.5">
                  3
                </div>
                <div className="text-xs text-gray-300">
                  <span className="font-bold text-white">Verify in Profile:</span> Navigate to <span className="text-[#D4AF37] font-semibold">Profile &gt; Sovereign Identity Verification</span> to complete the 60-second ID scan and selfie liveness check.
                </div>
              </div>
            </div>

            <div className="p-3 rounded-xl bg-[#D4AF37]/10 border border-[#D4AF37]/20 text-[11px] text-gray-300 text-left">
              🔒 Once verified on the mobile app, your verified Gold Trust Seal and public visibility will sync automatically to this web dashboard.
            </div>

            <div className="pt-2 flex flex-col gap-2">
              <button
                onClick={() => setShowDiditModal(false)}
                className="w-full py-3.5 rounded-xl text-xs font-black bg-[#D4AF37] text-black hover:bg-[#E5C158] transition flex items-center justify-center gap-2 cursor-pointer shadow-lg"
              >
                <CheckCircle2 className="w-4 h-4" /> I Understand — Proceed on Mobile
              </button>
            </div>
          </div>
        </div>
      )}

            {/* Partner Match Preferences & Settings Modal */}
      {showPreferencesModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md overflow-y-auto">
          <div className="relative w-full max-w-2xl bg-[#0F141C] border border-[#D4AF37]/40 rounded-[28px] p-6 sm:p-8 shadow-2xl space-y-6 my-8 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-white/10">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-[#D4AF37]/15 border border-[#D4AF37]/40 flex items-center justify-center text-[#D4AF37]">
                  <Sliders className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-serif font-bold text-white">Partner Match Preferences</h3>
                  <p className="text-xs text-gray-400">Customize what you desire in a future spouse to recalibrate your AI recommendations.</p>
                </div>
              </div>
              <button 
                onClick={() => setShowPreferencesModal(false)}
                className="p-1.5 rounded-full bg-white/5 hover:bg-white/10 text-gray-400 hover:text-white transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-6 text-left">
              {/* Age Range */}
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs">
                  <label className="font-bold text-gray-300 uppercase tracking-wider text-[11px]">Partner Age Range</label>
                  <span className="text-[#D4AF37] font-bold">{prefAgeMin} - {prefAgeMax} Years Old</span>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <span className="text-[10px] text-gray-500 uppercase tracking-widest">Min Age</span>
                    <input 
                      type="number"
                      min="18"
                      max="70"
                      value={prefAgeMin}
                      onChange={(e) => setPrefAgeMin(Math.min(parseInt(e.target.value) || 18, prefAgeMax))}
                      className="w-full mt-1 bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-sm text-white focus:border-[#D4AF37] outline-none"
                    />
                  </div>
                  <div>
                    <span className="text-[10px] text-gray-500 uppercase tracking-widest">Max Age</span>
                    <input 
                      type="number"
                      min="18"
                      max="75"
                      value={prefAgeMax}
                      onChange={(e) => setPrefAgeMax(Math.max(parseInt(e.target.value) || 45, prefAgeMin))}
                      className="w-full mt-1 bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-sm text-white focus:border-[#D4AF37] outline-none"
                    />
                  </div>
                </div>
              </div>

              {/* Partner Children Status */}
              <div className="space-y-2">
                <label className="font-bold text-gray-300 uppercase tracking-wider text-[11px]">Partner Children Status</label>
                <div className="grid grid-cols-3 gap-2">
                  {["No children yet", "Has children", "Open to either"].map((status) => (
                    <button
                      key={status}
                      type="button"
                      onClick={() => setPrefChildrenStatus(status)}
                      className={`py-2 px-3 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${prefChildrenStatus === status ? 'bg-[#D4AF37] text-black border-[#D4AF37] font-black' : 'bg-white/5 border-white/10 text-gray-300 hover:bg-white/10'}`}
                    >
                      {status}
                    </button>
                  ))}
                </div>
              </div>

              {/* Openness to Future Children */}
              <div className="space-y-2">
                <label className="font-bold text-gray-300 uppercase tracking-wider text-[11px]">Desire for Future Children</label>
                <div className="grid grid-cols-3 gap-2">
                  {["Wants children", "Open to children", "Does not want children"].map((desire) => (
                    <button
                      key={desire}
                      type="button"
                      onClick={() => setPrefChildrenDesire(desire)}
                      className={`py-2 px-3 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${prefChildrenDesire === desire ? 'bg-[#D4AF37] text-black border-[#D4AF37] font-black' : 'bg-white/5 border-white/10 text-gray-300 hover:bg-white/10'}`}
                    >
                      {desire}
                    </button>
                  ))}
                </div>
              </div>

              {/* Marriage Timeline */}
              <div className="space-y-2">
                <label className="font-bold text-gray-300 uppercase tracking-wider text-[11px]">Marriage Horizon / Vow Timeline</label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {["ASAP (Within 6 months)", "Within 1 year", "1-2 Years", "2+ Years"].map((time) => (
                    <button
                      key={time}
                      type="button"
                      onClick={() => setPrefTimeline(time)}
                      className={`py-2 px-3 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${prefTimeline === time ? 'bg-[#D4AF37] text-black border-[#D4AF37] font-black' : 'bg-white/5 border-white/10 text-gray-300 hover:bg-white/10'}`}
                    >
                      {time}
                    </button>
                  ))}
                </div>
              </div>

              {/* Location & Heritage */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="font-bold text-gray-300 uppercase tracking-wider text-[11px]">Preferred Heritage / Origin</label>
                  <input 
                    type="text"
                    placeholder="e.g. Nigeria, Ghana, USA, Jamaica, Any"
                    value={prefOrigin}
                    onChange={(e) => setPrefOrigin(e.target.value)}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-sm text-white focus:border-[#D4AF37] outline-none"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="font-bold text-gray-300 uppercase tracking-wider text-[11px]">Preferred Residence Country</label>
                  <input 
                    type="text"
                    placeholder="e.g. United States, United Kingdom, Canada"
                    value={prefResidence}
                    onChange={(e) => setPrefResidence(e.target.value)}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-sm text-white focus:border-[#D4AF37] outline-none"
                  />
                </div>
              </div>

              {/* Ideal Partner Traits */}
              <div className="space-y-2">
                <label className="font-bold text-gray-300 uppercase tracking-wider text-[11px]">Key Partner Traits</label>
                <div className="flex flex-wrap gap-2">
                  {["Emotionally mature", "Family-oriented", "Faith-driven", "Ambitious & Driven", "Loyal & Devoted", "Health-conscious", "Kind & Empathetic", "Financial Wisdom", "Honest & Direct"].map((trait) => {
                    const isSelected = prefTraits.includes(trait);
                    return (
                      <button
                        key={trait}
                        type="button"
                        onClick={() => {
                          if (isSelected) {
                            setPrefTraits(prefTraits.filter(t => t !== trait));
                          } else {
                            setPrefTraits([...prefTraits, trait]);
                          }
                        }}
                        className={`py-1.5 px-3 rounded-full text-xs font-semibold border transition-all cursor-pointer ${isSelected ? 'bg-[#D4AF37]/20 border-[#D4AF37] text-[#D4AF37] font-bold' : 'bg-white/5 border-white/10 text-gray-400 hover:text-white'}`}
                      >
                        {isSelected ? '✓ ' : '+ '}{trait}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            <div className="pt-4 border-t border-white/10 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowPreferencesModal(false)}
                className="px-5 py-2.5 rounded-full text-xs font-bold text-gray-400 hover:text-white transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={prefSaving}
                onClick={handleSavePreferences}
                className="px-7 py-3 rounded-full text-xs font-black uppercase tracking-wider bg-[#D4AF37] text-black hover:bg-[#E5C158] transition-all flex items-center gap-2 shadow-lg shadow-[#D4AF37]/25 cursor-pointer disabled:opacity-50"
              >
                <Sparkles className="w-4 h-4" /> {prefSaving ? "Saving..." : "Save Preferences & Recalibrate Matches ✨"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Auto-Dismissing Daily Limit Notice Toast */}
      {limitNoticeMessage && (
        <div className="fixed bottom-6 right-6 z-50 max-w-md bg-[#121721] border border-[#D4AF37] text-white px-5 py-4 rounded-2xl shadow-2xl flex items-center gap-3 animate-fade-in">
          <Sparkles className="w-5 h-5 text-[#D4AF37] flex-shrink-0" />
          <span className="text-xs text-gray-200">{limitNoticeMessage}</span>
          <button
            onClick={() => {
              setLimitNoticeMessage(null);
              setShowSubscriptionModal(true);
            }}
            className="ml-auto px-3.5 py-1.5 rounded-full bg-[#D4AF37] text-black text-[10px] font-black uppercase tracking-wider hover:bg-[#E5C158] whitespace-nowrap cursor-pointer transition shadow-md"
          >
            Upgrade ✨
          </button>
          <button
            onClick={() => setLimitNoticeMessage(null)}
            className="p-1 rounded-full text-gray-400 hover:text-white transition-colors cursor-pointer"
            title="Dismiss notice"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}
    </div>
  );
}
