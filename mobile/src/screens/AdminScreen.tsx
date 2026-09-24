import React, { useState, useEffect, useMemo } from 'react';
import {
  ActivityIndicator, Alert, FlatList, Image, StyleSheet, Text,
  TextInput, TouchableOpacity, View,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';

import { useTheme } from '../contexts/ThemeContext';
import { useToast } from '../contexts/ToastContext';
import { Colors, Spacing, BorderRadius } from '../theme/colors';
import { RootStackParamList, User } from '../types';
import { useAuth } from '../contexts/AuthContext';
import { db } from '../services/apiService';
import { MATCHES_DATA } from '../constants';
import { AdminAddUserModal } from '../components/AdminAddUserModal';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type AdminTab = 'all' | 'pending' | 'verified' | 'subscribers';

export default function AdminScreen() {
  const navigation = useNavigation<Nav>();
  const { isDarkMode } = useTheme();
  const { addToast } = useToast();
  const { logout } = useAuth();

  const [members, setMembers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<AdminTab>('all');
  const [search, setSearch] = useState('');
  const [isAddUserModalOpen, setIsAddUserModalOpen] = useState(false);

  const load = async () => {
    setLoading(true);
    let data = await db.getAllUsers();
    
    // Also include current logged in user if available so they see themselves in Admin
    try {
      const currentUserStr = await AsyncStorage.getItem('knot_user_profile');
      if (currentUserStr) {
        const currentUser = JSON.parse(currentUserStr);
        if (currentUser && currentUser.name) {
          const exists = data.some((m) => m.email?.toLowerCase() === currentUser.email?.toLowerCase() || m.id === currentUser.id);
          if (!exists) {
            data = [currentUser, ...data];
          }
        }
      }
    } catch { /* ignore */ }

    setMembers(data);
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const handleSeed = async () => {
    setLoading(true);
    try {
      await db.seedMockData(MATCHES_DATA);
      addToast('Registry seeded with mock data.', 'success');
      await load();
    } catch {
      addToast('Seeding failed.', 'error');
    }
    setLoading(false);
  };

  const handleDelete = async (id: string) => {
    Alert.alert('Confirm', 'Purge this member? This cannot be undone.', [
      { text: 'Cancel' },
      {
        text: 'Purge', style: 'destructive', onPress: async () => {
          try {
            await db.deleteUser(id);
            setMembers((p) => p.filter((m) => m.id !== id));
            addToast('Member purged.', 'success');
          } catch { addToast('Purge failed.', 'error'); }
        }
      },
    ]);
  };

  const toggleVerify = async (member: User) => {
    const updated = { ...member, isVerified: !member.isVerified };
    await db.saveUser(updated);
    setMembers((p) => p.map((m) => (m.id === member.id ? updated : m)));
    addToast(updated.isVerified ? 'Identity verified.' : 'Verification revoked.', 'success');
  };

  const filtered = useMemo(() => {
    let list = [...members];
    if (tab === 'pending') list = list.filter((m) => !m.isVerified);
    if (tab === 'verified') list = list.filter((m) => m.isVerified);
    if (tab === 'subscribers') list = list.filter((m) => m.isPremium);
    if (search) {
      const q = search.toLowerCase();
      list = list.filter((m) =>
        (m.name || '').toLowerCase().includes(q) ||
        (m.occupation && m.occupation.toLowerCase().includes(q)) ||
        (m.email && m.email.toLowerCase().includes(q))
      );
    }
    return list;
  }, [members, tab, search]);

  const revenue = members.reduce((s, m) => s + (m.subscriptionAmount || 0), 0);

  return (
    <View style={[s.root, { backgroundColor: isDarkMode ? Colors.dark : Colors.gray50 }]}>
      {/* Header */}
      <View style={s.header}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
          <Ionicons name="shield-checkmark" size={28} color="#D4AF37" />
          <View>
            <Text style={[s.headerTitle, { color: '#D4AF37' }]}>Management Panel</Text>
            <Text style={s.headerSub}>Registry Administration</Text>
          </View>
        </View>
        <View style={{ flexDirection: 'row', alignItems: 'center' }}>
          {navigation.canGoBack() ? (
            <TouchableOpacity style={s.closeBtn} onPress={() => navigation.goBack()}>
              <Ionicons name="close" size={24} color={Colors.white} />
            </TouchableOpacity>
          ) : (
            <TouchableOpacity style={[s.seedBtn, { backgroundColor: '#1A1A1A', borderColor: '#333', borderWidth: 1, paddingHorizontal: 16 }]} onPress={() => logout()}>
              <Ionicons name="log-out-outline" size={16} color={Colors.error} style={{ marginBottom: 2 }} />
              <Text style={[s.seedBtnText, { color: Colors.error, fontSize: 10 }]}>LOGOUT</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* Action Buttons Row */}
      <View style={{ flexDirection: 'row', paddingHorizontal: Spacing.md, gap: 12, marginBottom: 16, marginTop: 4 }}>
        <TouchableOpacity style={[s.seedBtn, { flex: 1, backgroundColor: '#1A1A1A', borderColor: '#333', borderWidth: 1, alignItems: 'center' }]} onPress={() => setIsAddUserModalOpen(true)}>
          <Text style={[s.seedBtnText, { color: '#D4AF37' }]}>+ ADD USER</Text>
        </TouchableOpacity>
        <TouchableOpacity style={[s.seedBtn, { flex: 1, backgroundColor: '#1A1A1A', borderColor: '#333', borderWidth: 1, alignItems: 'center' }]} onPress={handleSeed} disabled={loading}>
          <Text style={[s.seedBtnText, { color: Colors.gray300 }]}>{loading ? 'SEEDING...' : 'SEED MOCK DATA'}</Text>
        </TouchableOpacity>
      </View>

      {/* Stats */}
      <View style={s.statsRow}>
        <View style={s.statCard}><Text style={s.statLabel}>Total</Text><Text style={[s.statValue, { color: Colors.white }]}>{members.length}</Text></View>
        <View style={s.statCard}><Text style={s.statLabel}>Revenue</Text><Text style={[s.statValue, { color: Colors.white }]}>${revenue.toFixed(2)}</Text></View>
      </View>

      {/* Search */}
      <View style={{ paddingHorizontal: Spacing.md }}>
        <TextInput
          value={search}
          onChangeText={setSearch}
          placeholder="Search directory..."
          placeholderTextColor={Colors.gray400}
          style={[s.searchInput, { backgroundColor: isDarkMode ? Colors.darkCard : Colors.white, color: isDarkMode ? Colors.white : Colors.gray900 }]}
        />
      </View>

      {/* Tabs */}
      <View style={s.tabRow}>
        {(['all', 'subscribers'] as AdminTab[]).map((t) => (
          <TouchableOpacity key={t} style={[s.tab, tab === t && s.tabActive]} onPress={() => setTab(t)}>
            <Text style={[s.tabText, tab === t && s.tabTextActive]}>{t}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* List */}
      {loading ? (
        <ActivityIndicator size="large" color={Colors.primary} style={{ marginTop: 60 }} />
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(m) => m.id}
          contentContainerStyle={{ padding: Spacing.md, paddingBottom: 24, gap: 12 }}
          renderItem={({ item }) => {
            const displayName = item.name || [item.firstName, item.lastName].filter(Boolean).join(' ') || 'User';
            const avatarName = encodeURIComponent(displayName);
            const photo = item.profileImages?.[0]?.url || item.profileImageUrls?.[0] || item.selfieUrl || item.photoUrl || `https://ui-avatars.com/api/?name=${avatarName}&background=1E1E1E&color=FFFFFF&size=200`;
            return (
              <TouchableOpacity 
                style={[s.memberCard, { backgroundColor: '#1A1A1A', borderColor: '#333' }]}
                onPress={() => navigation.navigate('ProfileDetail' as any, { match: item })}
                activeOpacity={0.8}
              >
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 14 }}>
                  <Image source={{ uri: photo }} style={s.memberAvatar} />
                  <View style={{ flex: 1 }}>
                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                      <Text style={[s.memberName, { color: Colors.white }]}>{item.name || displayName}{item.age ? `, ${item.age}` : ''}</Text>
                      {item.isVerified && <Ionicons name="checkmark-circle" size={16} color="#D4AF37" />}
                    </View>
                    {item.occupation ? <Text style={s.memberOcc}>{item.occupation}</Text> : null}
                    {item.email ? <Text style={s.memberEmail}>{item.email}</Text> : null}
                  </View>
                  <View style={{ flexDirection: 'row', gap: 8 }}>
                    <TouchableOpacity onPress={() => navigation.navigate('EditProfile', { user: item })} style={{ padding: 8, backgroundColor: '#3B82F62A', borderRadius: 12 }}>
                      <Ionicons name="pencil" size={18} color="#3b82f6" />
                    </TouchableOpacity>
                    <TouchableOpacity onPress={() => handleDelete(item.id)} style={{ padding: 8, backgroundColor: '#EF44442A', borderRadius: 12 }}>
                      <Ionicons name="trash" size={18} color="#ef4444" />
                    </TouchableOpacity>
                  </View>
                </View>
              </TouchableOpacity>
            );
          }}
          ListEmptyComponent={
            <View style={{ alignItems: 'center', paddingVertical: 60 }}>
              <Text style={{ color: Colors.gray500, fontWeight: '600' }}>No members found.</Text>
            </View>
          }
        />
      )}

      <AdminAddUserModal
        visible={isAddUserModalOpen}
        onClose={() => setIsAddUserModalOpen(false)}
        onUserAdded={() => {
          setIsAddUserModalOpen(false);
          load();
        }}
        isDarkMode={isDarkMode}
      />
    </View>
  );
}

const s = StyleSheet.create({
  root: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', backgroundColor: Colors.dark, paddingHorizontal: Spacing.md, paddingVertical: 14, paddingTop: 50 },
  headerTitle: { fontSize: 16, fontWeight: '900', color: Colors.white, textTransform: 'uppercase', letterSpacing: -0.5 },
  headerSub: { fontSize: 8, fontWeight: '700', color: Colors.accent, textTransform: 'uppercase', letterSpacing: 3, marginTop: 2 },
  seedBtn: { backgroundColor: Colors.accent, paddingHorizontal: 12, paddingVertical: 8, borderRadius: 10 },
  seedBtnText: { fontSize: 10, fontWeight: '900', color: Colors.dark, textTransform: 'uppercase', letterSpacing: 1 },
  closeBtn: { padding: 8, backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: 16 },
  statsRow: { flexDirection: 'row', gap: 8, padding: Spacing.md },
  statCard: { flex: 1, backgroundColor: '#1A1A1A', padding: 14, borderRadius: BorderRadius.lg, borderWidth: 1, borderColor: '#333' },
  statLabel: { fontSize: 10, fontWeight: '900', color: Colors.gray400, textTransform: 'uppercase', letterSpacing: 1 },
  statValue: { fontSize: 20, fontWeight: '900', marginTop: 4 },
  searchInput: { borderWidth: 1, borderColor: '#333', borderRadius: BorderRadius.lg, paddingHorizontal: 16, paddingVertical: 14, fontSize: 14, marginBottom: 16, backgroundColor: '#121212', color: Colors.white },
  tabRow: { flexDirection: 'row', marginHorizontal: Spacing.md, backgroundColor: '#121212', borderRadius: BorderRadius.lg, padding: 4, gap: 4, marginBottom: 4, borderWidth: 1, borderColor: '#333' },
  tab: { flex: 1, paddingVertical: 10, borderRadius: BorderRadius.md, alignItems: 'center' },
  tabActive: { backgroundColor: '#222', elevation: 1, borderWidth: 1, borderColor: '#444' },
  tabText: { fontSize: 10, fontWeight: '900', color: Colors.gray500, textTransform: 'uppercase', letterSpacing: 1 },
  tabTextActive: { color: '#D4AF37' },
  memberCard: { padding: 16, borderRadius: 20, borderWidth: 1, borderColor: Colors.gray100, elevation: 1 },
  memberAvatar: { width: 56, height: 56, borderRadius: 28, borderWidth: 2, borderColor: Colors.white },
  memberName: { fontSize: 16, fontWeight: '900' },
  memberOcc: { fontSize: 10, color: Colors.gray400, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 1 },
  memberEmail: { fontSize: 10, color: Colors.gray500, marginTop: 2 },
  memberActions: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 16, paddingTop: 12, borderTopWidth: 1, borderTopColor: Colors.gray50 },
  verifyBtn: { backgroundColor: Colors.primary, paddingHorizontal: 16, paddingVertical: 10, borderRadius: 10, elevation: 2 },
  verifyBtnRevoke: { backgroundColor: Colors.gray100, elevation: 0 },
  verifyBtnText: { fontSize: 10, fontWeight: '900', color: Colors.white, textTransform: 'uppercase', letterSpacing: 1 },
});
