import React, { useState, useEffect, useRef } from 'react';
import {
  FlatList, Image, KeyboardAvoidingView, Platform, StyleSheet, Text,
  TextInput, TouchableOpacity, View, Alert
} from 'react-native';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useTheme } from '../contexts/ThemeContext';
import { useToast } from '../contexts/ToastContext';
import { Colors, Spacing, BorderRadius } from '../theme/colors';
import { RootStackParamList, Message } from '../types';
import { db } from '../services/apiService';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type ChatRoute = RouteProp<RootStackParamList, 'Chat'>;

export default function ChatScreen() {
  const navigation = useNavigation<Nav>();
  const { params } = useRoute<ChatRoute>();
  const { isDarkMode } = useTheme();
  const { addToast } = useToast();
  const insets = useSafeAreaInsets();
  const { match, user } = params;

  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState('');
  const [aiChatTip, setAiChatTip] = useState(
    'AI Message Assistant: You both value travel and family traditions. Ask about her favorite childhood memory.'
  );
  const flatListRef = useRef<FlatList>(null);

  useEffect(() => {
    const unsub = db.subscribeToMessages(match.id, setMessages);
    return () => unsub();
  }, [match.id]);

  useEffect(() => {
    if (messages.length > 0) {
      setTimeout(() => flatListRef.current?.scrollToEnd({ animated: true }), 100);
    }
  }, [messages]);

  const handleOptions = () => {
    Alert.alert('Options', 'Select an action for this profile', [
      { text: 'Block', style: 'destructive', onPress: () => { addToast('User blocked successfully', 'success'); navigation.goBack(); } },
      { text: 'Report', style: 'destructive', onPress: () => addToast('Report submitted', 'success') },
      { text: 'Cancel', style: 'cancel' }
    ]);
  };

  const send = async () => {
    const msg = text.trim();
    if (!msg) return;
    setText('');
    setAiChatTip('AI Coach is typing...');
    try {
      await db.sendMessage(match.id, user.id, msg);
      
      const updatedHistory = [...messages, { id: 'tmp', text: msg, senderId: user.id, timestamp: Date.now() }];
      const formattedHistory = updatedHistory.map(m => ({
        role: m.senderId === user.id ? 'user' : 'match',
        text: m.text
      }));

      const coachData = await db.getCoachResponse(formattedHistory, user, msg);
      if (coachData && coachData.response) {
        setAiChatTip(`AI Coach: ${coachData.response}`);
      } else {
        setAiChatTip('');
      }
    } catch (err: any) {
      console.error(err);
      if (err.message && err.message.includes('FREE_TIER_LIMIT')) {
        addToast('Free tier limit reached. Upgrade to chat with more matches.', 'error');
        navigation.navigate('Payment', { user });
      } else {
        addToast('Failed to send message', 'error');
      }
      setText(msg);
      setAiChatTip('');
    }
  };

  const photo = match.profileImageUrls?.[0] || 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=400';

  const renderMsg = ({ item }: { item: Message }) => {
    const isMine = item.senderId === user.id;
    return (
      <View style={[s.msgRow, isMine && s.msgRowMine]}>
        {!isMine && <Image source={{ uri: photo }} style={s.msgAvatar} />}
        <View style={s.bubbleContainer}>
          <View style={[s.bubble, isMine ? s.bubbleMine : [s.bubbleTheirs, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.white, borderColor: isDarkMode ? Colors.darkBorder : Colors.gray200 }]]}>
            <Text style={[s.bubbleText, isMine ? { color: Colors.white } : { color: isDarkMode ? Colors.white : Colors.gray900 }]}>
              {item.text}
            </Text>
          </View>
          <Text style={[s.msgTime, isMine ? { alignSelf: 'flex-end' } : { alignSelf: 'flex-start' }]}>
            {new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </Text>
        </View>
      </View>
    );
  };

  return (
    <KeyboardAvoidingView
      style={[s.root, { backgroundColor: isDarkMode ? Colors.dark : Colors.light + '50' }]}
      behavior={Platform.OS === 'ios' ? 'padding' : 'padding'}
      keyboardVerticalOffset={0}
    >
      {/* Header */}
      <View style={[s.header, { paddingTop: insets.top + 8, backgroundColor: isDarkMode ? Colors.darkCard : Colors.white }]}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={s.headerBack}>
          <Ionicons name="chevron-back" size={24} color={isDarkMode ? Colors.white : Colors.gray600} />
        </TouchableOpacity>
        <Image source={{ uri: photo }} style={s.headerAvatar} />
        <View style={{ flex: 1, marginLeft: 12 }}>
          <Text style={[s.headerName, { color: isDarkMode ? Colors.white : Colors.dark }]}>{match.name}</Text>
          <Text style={s.headerSub}>Online</Text>
        </View>
        <View style={{ flexDirection: 'row', alignItems: 'center' }}>
          <TouchableOpacity onPress={handleOptions}>
            <Ionicons name="ellipsis-vertical" size={24} color={isDarkMode ? Colors.gray400 : Colors.gray600} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Messages */}
      <FlatList
        ref={flatListRef}
        data={messages}
        keyExtractor={(m) => m.id}
        renderItem={renderMsg}
        style={{ flex: 1 }}
        contentContainerStyle={s.listContent}
        onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
        onLayout={() => flatListRef.current?.scrollToEnd({ animated: false })}
        ListEmptyComponent={
          <View style={s.emptyWrap}>
            <Text style={s.emptyText}>Start of conversation</Text>
          </View>
        }
      />

      {/* AI Guided Chat Tip Prompt Bar */}
      {aiChatTip ? (
        <View style={[s.tipBar, { backgroundColor: isDarkMode ? 'rgba(212,175,55,0.08)' : 'rgba(212,175,55,0.03)', borderTopColor: isDarkMode ? 'rgba(212,175,55,0.15)' : 'rgba(212,175,55,0.2)', borderBottomColor: isDarkMode ? 'rgba(212,175,55,0.15)' : 'rgba(212,175,55,0.2)' }]}>
          <Ionicons name="sparkles" size={14} color={Colors.accent} style={{ marginRight: 8 }} />
          <Text style={[s.tipText, { color: Colors.accent }]}>{aiChatTip}</Text>
        </View>
      ) : null}

      {/* Input */}
      <View style={[s.inputBar, { paddingBottom: insets.bottom + 8, backgroundColor: isDarkMode ? Colors.darkCard : Colors.white }]}>
        <TextInput
          value={text}
          onChangeText={setText}
          placeholder="Type a message..."
          placeholderTextColor={Colors.gray400}
          style={[s.input, { backgroundColor: isDarkMode ? Colors.darkSurface : Colors.gray50, color: isDarkMode ? Colors.white : Colors.gray900 }]}
          onSubmitEditing={send}
          returnKeyType="send"
        />
        <TouchableOpacity style={s.sendBtn} onPress={send}>
          <Ionicons name="send" size={20} color={Colors.white} />
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const s = StyleSheet.create({
  root: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12, paddingBottom: 12, borderBottomWidth: 1, borderBottomColor: Colors.gray100, elevation: 2 },
  headerBack: { padding: 4, marginRight: 4 },
  headerAvatar: { width: 40, height: 40, borderRadius: 20 },
  headerName: { fontSize: 16, fontWeight: '700' },
  headerSub: { fontSize: 11, color: Colors.gray500 },
  listContent: { padding: Spacing.md, paddingBottom: 24, flexGrow: 1 },
  emptyWrap: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 80 },
  emptyText: { fontSize: 11, fontWeight: '700', color: Colors.gray400, textTransform: 'uppercase', letterSpacing: 2 },
  msgRow: { flexDirection: 'row', alignItems: 'flex-end', gap: 8, marginBottom: 12 },
  msgRowMine: { justifyContent: 'flex-end' },
  msgAvatar: { width: 24, height: 24, borderRadius: 12 },
  bubbleContainer: { maxWidth: '75%' },
  bubble: { paddingHorizontal: 16, paddingVertical: 10, borderRadius: 18 },
  bubbleMine: { backgroundColor: Colors.primary, borderBottomRightRadius: 4 },
  bubbleTheirs: { backgroundColor: Colors.white, borderBottomLeftRadius: 4, borderWidth: 1, borderColor: Colors.gray200 },
  bubbleText: { fontSize: 14, fontWeight: '500' },
  msgTime: { fontSize: 10, color: Colors.gray400, marginTop: 4, marginHorizontal: 4 },
  inputBar: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingHorizontal: 12, paddingTop: 8, borderTopWidth: 1, borderTopColor: Colors.gray100 },
  input: { flex: 1, borderRadius: 24, paddingHorizontal: 16, paddingVertical: 10, fontSize: 14 },
  sendBtn: { backgroundColor: Colors.primary, borderRadius: 22, padding: 10 },
  tipBar: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 10, borderTopWidth: 1, borderBottomWidth: 1 },
  tipText: { fontSize: 11, fontWeight: '700', flex: 1, lineHeight: 16 },
});
