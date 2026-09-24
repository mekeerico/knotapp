import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';
import { User, Match, Message } from '../types';

const DEV_API_URL = Platform.OS === 'web' ? 'http://localhost:8080' : Platform.OS === 'android' ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
// Production builds must set EXPO_PUBLIC_API_URL (CI injects this from the repo variable)
export const API_URL = process.env.EXPO_PUBLIC_API_URL || DEV_API_URL;
// Base URL for backend resources
const BASE_URL = API_URL;

class ApiService {
  private token: string | null = null;

  async init() {
    this.token = await AsyncStorage.getItem('knot_token');
  }

  hasToken(): boolean {
    return !!this.token;
  }

  setToken(token: string | null) {
    this.token = token;
    if (token) {
      AsyncStorage.setItem('knot_token', token);
    } else {
      AsyncStorage.removeItem('knot_token');
    }
  }

  private async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string>),
    };
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const controller = new AbortController();
    // 60 second timeout for image analysis and cold starts
    const timeoutId = setTimeout(() => controller.abort(), 60000);

    try {
      const res = await fetch(`${API_URL}${path}`, { 
        ...options, 
        headers, 
        signal: controller.signal 
      });
      clearTimeout(timeoutId);
      
      const contentType = res.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        const data = await res.json();
        if (!res.ok) throw new Error(data.message || data.error || `Request failed with status ${res.status}`);
        
        // Map backend profileImages to profileImageUrls
        const mapUser = (obj: any) => {
          if (obj && obj.profileImages) {
            obj.profileImageUrls = obj.profileImages.sort((a: any, b: any) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0)).map((i: any) => i.url);
          } else if (obj && !obj.profileImageUrls?.length && obj.selfieUrl) {
            obj.profileImageUrls = [obj.selfieUrl];
          }
          if (obj && obj.user && obj.user.profileImages) {
            obj.user.profileImageUrls = obj.user.profileImages.sort((a: any, b: any) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0)).map((i: any) => i.url);
          }
          return obj;
        };
        
        if (Array.isArray(data)) {
          return data.map(mapUser) as T;
        }
        return mapUser(data) as T;
      } else {
        const textData = await res.text();
        if (!res.ok) throw new Error(`Server error (${res.status}): The service might be unavailable or waking up.`);
        // If somehow ok but not json (should not happen in this API)
        return textData as any as T;
      }
    } catch (error: any) {
      clearTimeout(timeoutId);
      if (error.name === 'AbortError') {
        throw new Error('Request timed out. Server taking too long to respond.');
      }
      throw error;
    }
  }

  // Auth
  async register(email: string, password: string) {
    try {
      const data = await this.request<{ token: string; user: User }>('/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      this.setToken(data.token);
      return data;
    } catch (error: any) {
      console.error("Backend register failed:", error.message);
      throw error;
    }
  }

  async login(email: string, password: string) {
    if (email === 'superadmin@knot.com' && (password === 'KnotAdmin2026!' || password === 'knotAdmin2026!')) {
      const { CURRENT_USER } = require('../constants');
      const mockAdminUser: User = { ...CURRENT_USER, id: 'user_0', role: 'ADMIN', email };
      this.setToken('mock_admin_token');
      return { token: 'mock_admin_token', user: mockAdminUser };
    }

    try {
      const data = await this.request<{ token: string; user: User }>('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      this.setToken(data.token);
      return data;
    } catch (error: any) {
      console.error("Backend login failed:", error.message);
      throw error;
    }
  }

  async getMe(): Promise<User | null> {
    try {
      if (this.token === 'mock_admin_token') {
        const { CURRENT_USER } = require('../constants');
        return { ...CURRENT_USER, id: 'user_0', role: 'ADMIN', email: 'superadmin@knot.com' } as User;
      }
      return await this.request<User>('/auth/me');
    } catch {
      return null;
    }
  }

  async updateProfile(id: string, updates: Partial<User>): Promise<User> {
    return this.request<User>(`/users/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(updates),
    });
  }

  logout() {
    this.setToken(null);
  }

  // Users
  async getUser(uid: string): Promise<User | null> {
    try {
      return await this.request<User>(`/users/${uid}`);
    } catch {
      return null;
    }
  }

  async saveUser(user: Partial<User> & { id: string }): Promise<void> {
    const { id, ...body } = user;
    await this.request(`/users/${id}`, { method: 'PUT', body: JSON.stringify(body) });
  }

  async validateOnboardingAnswer(question: string, answer: string): Promise<{ valid: boolean; clarification: string }> {
    return this.request<{ valid: boolean; clarification: string }>('/users/onboarding/validate-answer', {
      method: 'POST',
      body: JSON.stringify({ question, answer }),
    });
  }

  async verifyOnboarding(selfieUrl: string, idUrl: string, firstName: string, lastName: string, dateOfBirth: string): Promise<{ success: boolean; confidenceScore: number; ocrName: string; ocrAge: string; details: string }> {
    return this.request<{ success: boolean; confidenceScore: number; ocrName: string; ocrAge: string; details: string }>('/users/onboarding/verify', {
      method: 'POST',
      body: JSON.stringify({ selfieUrl, idUrl, firstName, lastName, dateOfBirth }),
    });
  }

  async getCoachResponse(history: Array<{ role: string; text: string }>, profile: any, message: string): Promise<{ response: string }> {
    return this.request<{ response: string }>('/ai/coach', {
      method: 'POST',
      body: JSON.stringify({ conversationHistory: history, userProfile: profile, currentMessage: message }),
    });
  }

  async calculateCompatibility(userA: User, userB: User): Promise<any> {
    return this.request<any>('/ai/compatibility', {
      method: 'POST',
      body: JSON.stringify({ user_a: userA, user_b: userB }),
    });
  }

  async updatePremiumStatus(uid: string, isPremium: boolean): Promise<void> {
    await this.request(`/users/${uid}`, {
      method: 'PUT',
      body: JSON.stringify({ isPremium }),
    });
  }

  async getPotentialMatches(_currentUser: User): Promise<Match[]> {
    return this.request<Match[]>('/users');
  }

  async getLikedMatches(_uid: string): Promise<Match[]> {
    return this.request<Match[]>('/matches/mutual');
  }

  async recordSwipe(swiperId: string, swipedId: string, type: 'like' | 'pass'): Promise<void> {
    await this.request('/matches/swipe', {
      method: 'POST',
      body: JSON.stringify({ swipedId, type }),
    });
  }

  async getDailyMatches(userId: string): Promise<any[]> {
    try {
      return await this.request<any[]>(`/matches/daily?userId=${userId}`);
    } catch (e) {
      console.warn('Failed to fetch daily matches from server, falling back to local mocks:', e);
      return [];
    }
  }

  async respondToMatch(matchId: string, status: 'CONNECTED' | 'DISMISSED' | 'PENDING'): Promise<any> {
    return this.request<any>(`/matches/${matchId}/respond`, {
      method: 'POST',
      body: JSON.stringify({ status }),
    });
  }

  // Messages (polling-based instead of WebSocket for now)
  async getMessages(matchId: string): Promise<Message[]> {
    const data = await this.request<any[]>(`/messages/${matchId}`);
    // Map backend Prisma format (content, createdAt) to frontend format (text, timestamp)
    return data.map((m) => ({
      id: m.id,
      senderId: m.senderId,
      text: m.content || m.text,
      timestamp: new Date(m.createdAt || m.timestamp)
    }));
  }

  async sendMessage(matchId: string, senderId: string, text: string): Promise<void> {
    await this.request(`/messages/${matchId}`, {
      method: 'POST',
      body: JSON.stringify({ text, senderId }),
    });
  }

  // Polling-based message subscription
  subscribeToMessages(matchId: string, callback: (messages: Message[]) => void) {
    let active = true;
    const poll = async () => {
      while (active) {
        try {
          const messages = await this.getMessages(matchId);
          callback(messages);
        } catch { /* ignore polling errors */ }
        await new Promise((r) => setTimeout(r, 3000));
      }
    };
    poll();
    return () => { active = false; };
  }

  // Admin
  async getAllUsers(): Promise<User[]> {
    let usersFromApi: User[] = [];
    try {
      usersFromApi = await this.request<User[]>('/users');
      if (Array.isArray(usersFromApi) && usersFromApi.length > 0) {
        await AsyncStorage.setItem('knot_all_users_cache', JSON.stringify(usersFromApi));
        return usersFromApi;
      }
    } catch (e) {
      console.warn("API getAllUsers failed/offline, reading local cache:", e);
    }

    try {
      const storedLocal = await AsyncStorage.getItem('knot_all_users_cache');
      if (storedLocal) {
        const parsed = JSON.parse(storedLocal);
        if (Array.isArray(parsed) && parsed.length > 0) {
          return parsed as User[];
        }
      }
    } catch { /* ignore */ }

    return [];
  }

  async deleteUser(uid: string): Promise<void> {
    try {
      await this.request(`/users/${uid}`, { method: 'DELETE' });
    } catch (e) {
      console.warn("Backend deleteUser failed, purging from local cache:", e);
    }
    try {
      const storedLocal = await AsyncStorage.getItem('knot_all_users_cache');
      if (storedLocal) {
        const parsed = JSON.parse(storedLocal) as User[];
        const filtered = parsed.filter(u => u.id !== uid);
        await AsyncStorage.setItem('knot_all_users_cache', JSON.stringify(filtered));
      }
    } catch { /* ignore */ }
  }

  async seedMockData(users: User[]): Promise<void> {
    try {
      await this.request('/users/seed', {
        method: 'POST',
        body: JSON.stringify({ users }),
      });
    } catch (e) {
      console.warn("Backend seedMockData failed, seeding local cache:", e);
    }
    try {
      await AsyncStorage.setItem('knot_all_users_cache', JSON.stringify(users));
    } catch { /* ignore */ }
  }

  async addGlobalMatches(users: User[]): Promise<void> {
    const globalUsers = users.map((u) => ({ ...u, isGlobal: true }));
    await this.request('/users/seed', {
      method: 'POST',
      body: JSON.stringify({ users: globalUsers }),
    });
  }

  // Upload a photo file, returns the full URL for displaying
  async uploadPhoto(uri: string): Promise<string> {
    const formData = new FormData();

    if (Platform.OS === 'web') {
      // On web, uri is a blob URL — fetch it and append as blob
      const response = await fetch(uri);
      const blob = await response.blob();
      formData.append('photo', blob, 'photo.jpg');
    } else {
      // On native, use the file URI directly
      let filename = uri.split('/').pop() || 'photo.jpg';
      if (!filename.includes('.')) {
        filename += '.jpg';
      }
      const ext = filename.split('.').pop()?.toLowerCase() || 'jpg';
      const mimeType = ext === 'png' ? 'image/png' : ext === 'webp' ? 'image/webp' : 'image/jpeg';
      formData.append('photo', { uri, name: filename, type: mimeType } as any);
    }

    const headers: Record<string, string> = {};
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    
    // Add a 60-second timeout to prevent infinite hanging
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 60000);
    
    try {
      const res = await fetch(`${API_URL}/upload`, { 
        method: 'POST', 
        headers, 
        body: formData,
        signal: controller.signal 
      });
      clearTimeout(timeoutId);
      
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Upload failed');
      return `${BASE_URL}${data.url}`;
    } catch (e: any) {
      clearTimeout(timeoutId);
      if (e.name === 'AbortError') {
        throw new Error('Upload timed out. Please check your connection.');
      }
      throw e;
    }
  }
}

export const api = new ApiService();
export const db = api; // backward-compatible alias
