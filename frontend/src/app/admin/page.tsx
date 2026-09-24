"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { ShieldAlert, Trash2, Users, AlertCircle, Loader2, LogOut, Lock, Unlock, Plus, X, Menu, Calendar, Briefcase, User, MapPin, Camera, Check, ChevronDown } from "lucide-react";
import { COUNTRIES, STATES_BY_COUNTRY } from "../../services/locationData";

const MultiSelectDropdown = ({ label, options, values, onChange, placeholder }: { label: string, options: string[], values: string[], onChange: (v: string[]) => void, placeholder: string }) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = React.useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const toggleOption = (opt: string) => {
    if (values.includes(opt)) {
      onChange(values.filter(v => v !== opt));
    } else {
      onChange([...values, opt]);
    }
  };

  return (
    <div className="relative mb-3" ref={dropdownRef}>
      <label className="text-[10px] uppercase text-gray-500 font-bold block mb-1">{label}</label>
      <div 
        className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white cursor-pointer flex justify-between items-center"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className={values.length === 0 ? "text-gray-500" : "truncate pr-2"}>
          {values.length > 0 ? values.join(', ') : placeholder}
        </span>
        <ChevronDown className={`w-4 h-4 text-gray-500 transition-transform flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
      </div>
      
      {isOpen && (
        <div className="absolute z-10 w-full mt-2 bg-[#1A202C] border border-white/10 rounded-xl shadow-xl max-h-60 overflow-y-auto">
          {options.map(opt => (
            <div 
              key={opt}
              className="flex items-center gap-3 px-4 py-3 hover:bg-white/5 cursor-pointer border-b border-white/5 last:border-0"
              onClick={() => toggleOption(opt)}
            >
              <div className={`w-4 h-4 rounded border flex items-center justify-center flex-shrink-0 ${values.includes(opt) ? 'bg-[#D4AF37] border-[#D4AF37]' : 'border-white/20'}`}>
                {values.includes(opt) && <Check className="w-3 h-3 text-black" strokeWidth={3} />}
              </div>
              <span className="text-xs text-gray-300">{opt}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default function AdminDashboard() {
  const router = useRouter();
  // Helper: resolve relative image URLs (like /uploads/...) to absolute using backend base URL
  const resolveImageUrl = (url: string | undefined | null): string => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) return url;
    const base = process.env.NEXT_PUBLIC_API_URL || '';
    return `${base}${url}`;
  };
  const [users, setUsers] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  
  // Add User State
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [newEmail, setNewEmail] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [newFirstName, setNewFirstName] = useState("");
  const [newLastName, setNewLastName] = useState("");
  const [newDateOfBirth, setNewDateOfBirth] = useState("");
  const [newOccupation, setNewOccupation] = useState("");
  const [newReligion, setNewReligion] = useState("");
  const [newBio, setNewBio] = useState("");
  const [newResidenceCountry, setNewResidenceCountry] = useState("");
  const [newResidenceState, setNewResidenceState] = useState("");
  const [newResidenceCity, setNewResidenceCity] = useState("");
  const [newOriginCountry, setNewOriginCountry] = useState("");
  const [newOriginState, setNewOriginState] = useState("");
  const [newOriginCity, setNewOriginCity] = useState("");
  const [newMaritalStatus, setNewMaritalStatus] = useState("");
  const [newSmoking, setNewSmoking] = useState("");
  const [newDrinking, setNewDrinking] = useState("");
  const [newChildrenStatus, setNewChildrenStatus] = useState("");
  const [newMarriageTimeline, setNewMarriageTimeline] = useState("");
  const [newWillingToRelocate, setNewWillingToRelocate] = useState("");
  const [newChildrenPreference, setNewChildrenPreference] = useState("");
  
  // Extra Fields
  const [newEducation, setNewEducation] = useState("");
  const [newCulturalBackground, setNewCulturalBackground] = useState("");
  const [newCareerGoals, setNewCareerGoals] = useState("");
  const [newMarriageExpectations, setNewMarriageExpectations] = useState("");
  const [newLanguagesSpoken, setNewLanguagesSpoken] = useState<string[]>([]);
  const [newIdealPartnerTraits, setNewIdealPartnerTraits] = useState<string[]>([]);
  const [newProfilePhoto, setNewProfilePhoto] = useState<string | null>(null);

  const [isCreating, setIsCreating] = useState(false);
  const [createError, setCreateError] = useState("");

  const MAJOR_LANGUAGES = ['English', 'Spanish', 'French', 'German', 'Mandarin', 'Hindi', 'Arabic', 'Portuguese', 'Yoruba', 'Igbo', 'Hausa', 'Swahili', 'Other', 'Chinese'];
  const MAJOR_TRAITS = ['Kind', 'Ambitious', 'Family-oriented', 'Honest', 'Humorous', 'Intelligent', 'Empathetic', 'Adventurous', 'Loyal', 'Spiritual', 'Confident', 'Other'];

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setNewProfilePhoto(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  // Location selector lists for Add User form
  const newResidenceStates = STATES_BY_COUNTRY[newResidenceCountry] || [];
  const newOriginStates = STATES_BY_COUNTRY[newOriginCountry] || [];

  const fetchUsers = async () => {
    let remoteUsers: any[] = [];
    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL;
      const token = localStorage.getItem('knot_token');
      if (token) {
        const res = await fetch(`${API_URL}/users`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
          const data = await res.json();
          if (Array.isArray(data)) remoteUsers = data;
        }
      }
    } catch (err) {
      console.warn("Web admin fetchUsers network error, using local registry data:", err);
    }

    // Merge with locally stored profile
    let localProfile: any = null;
    try {
      const stored = localStorage.getItem('knot_userProfile');
      if (stored) localProfile = JSON.parse(stored);
    } catch { /* ignore */ }

    if (remoteUsers.length > 0) {
      if (localProfile && !remoteUsers.some((u: any) => u.email === localProfile.email)) {
        remoteUsers = [localProfile, ...remoteUsers];
      }
      setUsers(remoteUsers);
    } else {
      // Fallback data for admin dashboard
      const fallbackUsers = [
        localProfile || { firstName: "Admin", lastName: "User", email: "admin@knot.com", occupation: "Registry Administrator", isVerified: true, isPremium: true, residenceCity: "Lagos", residenceCountry: "Nigeria" },
        { id: "mock-1", firstName: "Sarah", lastName: "Jane", email: "sarah@example.com", occupation: "Teacher", age: 27, isVerified: true, isPremium: true, residenceCity: "San Francisco", residenceCountry: "USA" },
        { id: "mock-2", firstName: "Emily", lastName: "Chen", email: "emily@example.com", occupation: "Designer", age: 26, isVerified: true, isPremium: false, residenceCity: "San Francisco", residenceCountry: "USA" },
        { id: "mock-3", firstName: "Jessica", lastName: "Taylor", email: "jessica@example.com", occupation: "Software Engineer", age: 29, isVerified: true, isPremium: true, residenceCity: "New York", residenceCountry: "USA" },
        { id: "mock-4", firstName: "David", lastName: "Okonkwo", email: "david@example.com", occupation: "Architect", age: 31, isVerified: true, isPremium: true, residenceCity: "Lagos", residenceCountry: "Nigeria" },
      ];
      setUsers(fallbackUsers);
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newEmail || !newPassword || !newFirstName || !newLastName) {
      setCreateError("First name, last name, email and password are required.");
      return;
    }
    
    setIsCreating(true);
    setCreateError("");
    
    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL;
      const res = await fetch(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: newEmail,
          password: newPassword,
          firstName: newFirstName,
          lastName: newLastName,
          dateOfBirth: newDateOfBirth,
          occupation: newOccupation,
          religion: newReligion,
          bio: newBio,
          residenceCountry: newResidenceCountry,
          residenceState: newResidenceState,
          residenceCity: newResidenceCity,
          originCountry: newOriginCountry,
          originState: newOriginState,
          originCity: newOriginCity,
          maritalStatus: newMaritalStatus,
          smoking: newSmoking,
          drinking: newDrinking,
          childrenStatus: newChildrenStatus,
          marriageTimeline: newMarriageTimeline,
          willingToRelocate: newWillingToRelocate,
          childrenPreference: newChildrenPreference,
          education: newEducation,
          culturalBackground: newCulturalBackground,
          careerGoals: newCareerGoals,
          marriageExpectations: newMarriageExpectations,
          languagesSpoken: newLanguagesSpoken,
          idealPartnerTraits: newIdealPartnerTraits,
          profilePhoto: newProfilePhoto,
        })
      });
      
      const data = await res.json();
      
      if (!res.ok) {
        throw new Error(data.message || "Failed to add user.");
      }
      
      // Successfully created, close modal and refresh list
      setIsCreateModalOpen(false);
      setNewEmail(""); setNewPassword(""); setNewFirstName(""); setNewLastName("");
      setNewDateOfBirth(""); setNewOccupation(""); setNewReligion(""); setNewBio("");
      setNewResidenceCountry(""); setNewResidenceState(""); setNewResidenceCity("");
      setNewOriginCountry(""); setNewOriginState(""); setNewOriginCity("");
      setNewMaritalStatus(""); setNewSmoking(""); setNewDrinking("");
      setNewChildrenStatus(""); setNewMarriageTimeline("");
      setNewWillingToRelocate(""); setNewChildrenPreference("");
      setNewBio(""); setNewEducation(""); setNewCulturalBackground("");
      setNewCareerGoals(""); setNewMarriageExpectations("");
      setNewLanguagesSpoken([]); setNewIdealPartnerTraits([]);
      setNewProfilePhoto(null);
      fetchUsers();
      
    } catch (err: any) {
      setCreateError(err.message || "An error occurred while adding the user.");
    } finally {
      setIsCreating(false);
    }
  };

  const handleDelete = async (id: string) => {
    const token = localStorage.getItem('knot_token');
    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL;
        
      const res = await fetch(`${API_URL}/admin/users/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      if (res.ok) {
        setUsers(users.filter(u => u.id !== id));
      } else {
        alert("Failed to delete user.");
      }
    } catch (err) {
      console.error(err);
      alert("Failed to delete user.");
    } finally {
      setDeleteConfirmId(null);
    }
  };

  const toggleSuspend = async (id: string, currentStatus: boolean) => {
    const token = localStorage.getItem('knot_token');
    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL;
      const res = await fetch(`${API_URL}/admin/users/${id}/suspend`, {
        method: 'PATCH',
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ isSuspended: !currentStatus })
      });
      
      if (res.ok) {
        const data = await res.json();
        setUsers(users.map(u => u.id === id ? { ...u, isSuspended: data.isSuspended } : u));
      } else {
        alert("Failed to update suspension status.");
      }
    } catch (err) {
      console.error(err);
      alert("Failed to update suspension status.");
    }
  };

  return (
    <div className="min-h-screen bg-[#0A0D14] flex">
      {/* Sidebar Backdrop for Mobile */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 z-30 bg-black/60 backdrop-blur-sm md:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-[#121721] border-r border-white/5 flex flex-col p-6 transition-transform duration-300 md:static md:translate-x-0 ${isSidebarOpen ? "translate-x-0" : "-translate-x-full"}`}>
        <div className="flex items-center justify-between mb-12">
          <Link href="/" className="flex items-center gap-2">
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
        <div className="text-[10px] uppercase tracking-widest text-gray-500 font-bold mb-4">Admin Hub</div>
        <nav className="space-y-2 flex-1">
          <Link href="/admin" className="flex items-center gap-3 px-4 py-3 rounded-xl bg-white/5 text-[#D4AF37] font-semibold text-sm" onClick={() => setIsSidebarOpen(false)}>
            <Users className="w-4 h-4" /> Users
          </Link>
        </nav>
        <div className="mt-auto space-y-2">
          <Link href="/dashboard" className="flex items-center gap-3 px-4 py-3 text-xs font-semibold text-gray-400 hover:text-white transition-colors">
            &larr; Back to Dashboard
          </Link>
          <button onClick={() => { localStorage.removeItem('knot_token'); router.push('/login'); }} className="flex items-center gap-3 px-4 py-3 rounded-xl text-red-400/70 hover:text-red-400 hover:bg-red-500/10 transition-colors font-semibold text-sm w-full text-left">
            <LogOut className="w-4 h-4" /> Log Out
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-6 sm:p-10 relative overflow-hidden">
        {/* Background Orbs */}
        <div className="absolute top-0 right-0 w-[500px] h-[500px] rounded-full bg-[#E27D8D]/5 blur-[120px] pointer-events-none" />

        <header className="mb-10 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button 
              onClick={() => setIsSidebarOpen(true)}
              className="p-2 -ml-2 text-gray-400 hover:text-white md:hidden"
              aria-label="Open sidebar"
            >
              <Menu className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-2xl sm:text-3xl font-serif font-black text-white flex items-center gap-3">
                <ShieldAlert className="w-8 h-8 text-[#E27D8D]" /> Admin Control
              </h1>
              <p className="text-sm text-gray-400 mt-1">Manage platform users and data.</p>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setIsCreateModalOpen(true)}
              className="px-4 py-2 rounded-xl text-sm font-bold bg-[#D4AF37]/10 text-[#D4AF37] border border-[#D4AF37]/30 hover:bg-[#D4AF37]/20 transition-colors flex items-center gap-2"
            >
              <Plus className="w-4 h-4" /> Add User
            </button>
          </div>
        </header>

        {isLoading ? (
          <div className="flex items-center justify-center py-20 text-[#D4AF37]">
            <Loader2 className="w-8 h-8 animate-spin" />
          </div>
        ) : error ? (
          <div className="p-4 bg-red-500/10 border border-red-500/20 rounded-xl text-red-400 flex items-center gap-3">
            <AlertCircle className="w-5 h-5" /> {error}
          </div>
        ) : (
          <div className="glass-card rounded-[24px] border border-white/5 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-white/5 text-[10px] uppercase tracking-widest text-gray-400 font-bold">
                    <th className="p-4 border-b border-white/5">User</th>
                    <th className="p-4 border-b border-white/5">Email</th>
                    <th className="p-4 border-b border-white/5">Occupation</th>
                    <th className="p-4 border-b border-white/5">Subscription</th>
                    <th className="p-4 border-b border-white/5">Location</th>
                    <th className="p-4 border-b border-white/5">Marriage Status</th>
                    <th className="p-4 border-b border-white/5 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5">
                  {users.map(user => {
                    const displayName = `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.name || 'User';
                    const avatarInitials = encodeURIComponent(displayName);
                    const userPhoto = (
                      user.profileImages?.[0]?.url ||
                      user.profileImageUrls?.[0] ||
                      user.selfieUrl ||
                      user.photoUrl ||
                      `https://ui-avatars.com/api/?name=${avatarInitials}&background=1A202C&color=D4AF37&size=80`
                    );
                    return (
                    <tr key={user.id} className="hover:bg-white/[0.02] transition-colors">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full overflow-hidden flex-shrink-0 border border-white/10">
                            <img src={userPhoto} alt={displayName} className="w-full h-full object-cover" />
                          </div>
                          <div>
                            <div className="font-bold text-white text-sm flex items-center gap-2">
                              {displayName}
                              {user.role === 'ADMIN' && <span className="text-[9px] font-black uppercase bg-[#D4AF37]/20 text-[#D4AF37] px-1.5 py-0.5 rounded">Admin</span>}
                              {user.isSuspended && <span className="text-[9px] font-black uppercase bg-red-500/20 text-red-400 px-1.5 py-0.5 rounded">Suspended</span>}
                            </div>
                            {user.isVerified && <span className="text-[9px] text-emerald-400 font-bold">✓ Verified</span>}
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="text-xs text-gray-300">{user.email || '—'}</div>
                      </td>
                      <td className="p-4">
                        <div className="text-xs text-gray-400">{user.occupation || '—'}</div>
                      </td>
                      <td className="p-4">
                        {user.isPremium ? (
                          <span className="text-xs font-bold text-emerald-400 flex items-center gap-1">Yes <span className="text-gray-500 font-normal">($49/mo)</span></span>
                        ) : (
                          <span className="text-xs text-gray-500">No</span>
                        )}
                      </td>
                      <td className="p-4">
                        <div className="text-xs text-gray-400">
                          {user.residenceCity || "Unknown"}, {user.residenceCountry || "Unknown"}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="text-xs text-gray-400">
                          {user.maritalStatus || "Not Specified"}
                        </div>
                      </td>
                      <td className="p-4 text-right">
                        {deleteConfirmId === user.id ? (
                          <div className="flex items-center justify-end gap-2">
                            <span className="text-xs text-red-400 font-bold">Confirm?</span>
                            <button onClick={() => handleDelete(user.id)} className="px-3 py-1.5 rounded-lg bg-red-500/20 hover:bg-red-500/40 text-red-400 text-xs font-bold transition-colors">
                              Yes
                            </button>
                            <button onClick={() => setDeleteConfirmId(null)} className="px-3 py-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-white text-xs font-bold transition-colors">
                              No
                            </button>
                          </div>
                        ) : (
                          <div className="flex items-center justify-end gap-2">
                            <button 
                              onClick={() => toggleSuspend(user.id, user.isSuspended)}
                              disabled={user.role === 'ADMIN'}
                              className={`p-2 rounded-lg transition-colors disabled:opacity-30 disabled:cursor-not-allowed ${user.isSuspended ? 'bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400' : 'bg-orange-500/10 hover:bg-orange-500/20 text-orange-400'}`}
                              title={user.isSuspended ? "Unsuspend User" : "Suspend User"}
                            >
                              {user.isSuspended ? <Unlock className="w-4 h-4" /> : <Lock className="w-4 h-4" />}
                            </button>
                            <button 
                              onClick={() => setDeleteConfirmId(user.id)}
                              disabled={user.role === 'ADMIN'}
                              className="p-2 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                              title="Delete Account"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                  })}
                  {users.length === 0 && (
                    <tr>
                      <td colSpan={7} className="p-8 text-center text-gray-500 text-sm">No users found.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </main>

      {/* Add User Modal */}
      {isCreateModalOpen && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-[60] flex items-center justify-center p-4">
          <div className="w-full max-w-2xl bg-[#121721] rounded-[24px] border border-white/10 shadow-2xl overflow-hidden relative max-h-[90vh] flex flex-col">
            <div className="p-6 border-b border-white/5 flex items-center justify-between flex-shrink-0">
              <h2 className="text-xl font-serif font-black text-white">Add New User</h2>
              <button 
                onClick={() => setIsCreateModalOpen(false)}
                className="text-gray-400 hover:text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <form onSubmit={handleCreateUser} className="p-6 space-y-5 overflow-y-auto flex-1">
              {createError && (
                <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-xl text-xs text-red-400">
                  {createError}
                </div>
              )}

              {/* Account Credentials */}
              <div className="space-y-3">
                <span className="text-[10px] uppercase tracking-widest text-[#D4AF37] font-black block">Account Credentials</span>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Email Address *</label>
                    <input type="email" value={newEmail} onChange={e => setNewEmail(e.target.value)} placeholder="user@email.com" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Password *</label>
                    <input type="password" value={newPassword} onChange={e => setNewPassword(e.target.value)} placeholder="Min 6 characters" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                </div>
              </div>

              {/* Personal Details */}
              <div className="space-y-3 pt-3 border-t border-white/5">
                <span className="text-[10px] uppercase tracking-widest text-[#D4AF37] font-black block">Personal Details</span>
                
                {/* Profile Photo */}
                <div className="mb-4 flex items-center gap-4">
                  <div className="w-16 h-16 rounded-full bg-[#0A0D14] border border-white/10 flex items-center justify-center overflow-hidden flex-shrink-0">
                    {newProfilePhoto ? (
                      <img src={newProfilePhoto} alt="Profile" className="w-full h-full object-cover" />
                    ) : (
                      <Camera className="w-6 h-6 text-gray-500" />
                    )}
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-[#D4AF37] font-bold block mb-1">Profile Photo</label>
                    <input type="file" accept="image/*" onChange={handlePhotoUpload} className="text-xs text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-xs file:font-bold file:bg-[#D4AF37]/10 file:text-[#D4AF37] hover:file:bg-[#D4AF37]/20" />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">First Name *</label>
                    <input type="text" value={newFirstName} onChange={e => setNewFirstName(e.target.value)} placeholder="John" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Last Name *</label>
                    <input type="text" value={newLastName} onChange={e => setNewLastName(e.target.value)} placeholder="Doe" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Date of Birth</label>
                    <input type="date" value={newDateOfBirth} onChange={e => setNewDateOfBirth(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Occupation</label>
                    <input type="text" value={newOccupation} onChange={e => setNewOccupation(e.target.value)} placeholder="e.g. Software Engineer" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Religion / Faith</label>
                  <select value={newReligion} onChange={e => setNewReligion(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select Religion</option>
                    <option value="Christian">Christian</option>
                    <option value="Muslim">Muslim</option>
                    <option value="Jewish">Jewish</option>
                    <option value="Hindu">Hindu</option>
                    <option value="Buddhist">Buddhist</option>
                    <option value="Atheist">Atheist</option>
                    <option value="Agnostic">Agnostic</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Bio</label>
                  <textarea value={newBio} onChange={e => setNewBio(e.target.value)} rows={2} placeholder="Short bio about this user..." className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50 resize-none" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Education</label>
                    <input type="text" value={newEducation} onChange={e => setNewEducation(e.target.value)} placeholder="e.g. BSc Computer Science" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Cultural Background</label>
                    <input type="text" value={newCulturalBackground} onChange={e => setNewCulturalBackground(e.target.value)} placeholder="e.g. Hispanic, Yoruba" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                </div>
              </div>

              {/* Current Residence */}
              <div className="space-y-3 pt-3 border-t border-white/5">
                <span className="text-[10px] uppercase tracking-widest text-[#D4AF37] font-black block">Current Residence</span>
                <div className="grid grid-cols-3 gap-3">
                  <div>
                    <label className="text-[9px] uppercase text-gray-500 font-bold block mb-1">Country</label>
                    <select value={newResidenceCountry} onChange={e => { setNewResidenceCountry(e.target.value); setNewResidenceState(""); setNewResidenceCity(""); }} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="text-[9px] uppercase text-gray-500 font-bold block mb-1">State / Province</label>
                    {newResidenceStates.length > 0 ? (
                      <select value={newResidenceState} onChange={e => setNewResidenceState(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50">
                        <option value="">Select</option>
                        {newResidenceStates.map(s => <option key={s} value={s}>{s}</option>)}
                      </select>
                    ) : (
                      <input type="text" value={newResidenceState} onChange={e => setNewResidenceState(e.target.value)} placeholder="State" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50" />
                    )}
                  </div>
                  <div>
                    <label className="text-[9px] uppercase text-gray-500 font-bold block mb-1">City / Town</label>
                    <input type="text" value={newResidenceCity} onChange={e => setNewResidenceCity(e.target.value)} placeholder="City" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                </div>
              </div>

              {/* Heritage & Origin */}
              <div className="space-y-3 pt-3 border-t border-white/5">
                <span className="text-[10px] uppercase tracking-widest text-[#D4AF37] font-black block">Heritage & Origin</span>
                <div className="grid grid-cols-3 gap-3">
                  <div>
                    <label className="text-[9px] uppercase text-gray-500 font-bold block mb-1">Country</label>
                    <select value={newOriginCountry} onChange={e => { setNewOriginCountry(e.target.value); setNewOriginState(""); setNewOriginCity(""); }} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="text-[9px] uppercase text-gray-500 font-bold block mb-1">State / Province</label>
                    {newOriginStates.length > 0 ? (
                      <select value={newOriginState} onChange={e => setNewOriginState(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50">
                        <option value="">Select</option>
                        {newOriginStates.map(s => <option key={s} value={s}>{s}</option>)}
                      </select>
                    ) : (
                      <input type="text" value={newOriginState} onChange={e => setNewOriginState(e.target.value)} placeholder="State" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50" />
                    )}
                  </div>
                  <div>
                    <label className="text-[9px] uppercase text-gray-500 font-bold block mb-1">City / Town</label>
                    <input type="text" value={newOriginCity} onChange={e => setNewOriginCity(e.target.value)} placeholder="City" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                </div>
                <MultiSelectDropdown 
                  label="Languages Spoken" 
                  options={MAJOR_LANGUAGES} 
                  values={newLanguagesSpoken} 
                  onChange={setNewLanguagesSpoken} 
                  placeholder="Select languages..." 
                />
              </div>

              {/* Lifestyle & Preferences */}
              <div className="space-y-3 pt-3 border-t border-white/5">
                <span className="text-[10px] uppercase tracking-widest text-[#D4AF37] font-black block">Lifestyle & Preferences</span>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Marital Status</label>
                    <select value={newMaritalStatus} onChange={e => setNewMaritalStatus(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      <option value="Never Married">Never Married</option>
                      <option value="Divorced">Divorced</option>
                      <option value="Widowed">Widowed</option>
                      <option value="Separated">Separated</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Children Status</label>
                    <select value={newChildrenStatus} onChange={e => setNewChildrenStatus(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      <option value="No kids">No kids</option>
                      <option value="Has kids">Has kids</option>
                    </select>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Smoking</label>
                    <select value={newSmoking} onChange={e => setNewSmoking(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      <option value="Non-smoker">Non-smoker</option>
                      <option value="Occasional">Occasional</option>
                      <option value="Regular">Regular</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Drinking</label>
                    <select value={newDrinking} onChange={e => setNewDrinking(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      <option value="Never">Never</option>
                      <option value="Social">Social</option>
                      <option value="Regular">Regular</option>
                    </select>
                  </div>
                </div>
                <div className="grid grid-cols-3 gap-3">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Marriage Timeline</label>
                    <select value={newMarriageTimeline} onChange={e => setNewMarriageTimeline(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      <option value="ASAP">ASAP</option>
                      <option value="1-2 years">1-2 years</option>
                      <option value="3-5 years">3-5 years</option>
                      <option value="Not sure">Not sure</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Willing to Relocate</label>
                    <select value={newWillingToRelocate} onChange={e => setNewWillingToRelocate(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      <option value="Yes">Yes</option>
                      <option value="No">No</option>
                      <option value="Maybe">Maybe</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Children Pref.</label>
                    <select value={newChildrenPreference} onChange={e => setNewChildrenPreference(e.target.value)} className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      <option value="Open to children">Open to children</option>
                      <option value="Want children">Want children</option>
                      <option value="Don't want children">Don&apos;t want children</option>
                    </select>
                  </div>
                </div>
                <MultiSelectDropdown 
                  label="Ideal Partner Traits" 
                  options={MAJOR_TRAITS} 
                  values={newIdealPartnerTraits} 
                  onChange={setNewIdealPartnerTraits} 
                  placeholder="Select traits..." 
                />
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Marriage Expectations</label>
                    <input type="text" value={newMarriageExpectations} onChange={e => setNewMarriageExpectations(e.target.value)} placeholder="e.g. Traditional, Equal Partners" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Career Goals</label>
                    <input type="text" value={newCareerGoals} onChange={e => setNewCareerGoals(e.target.value)} placeholder="e.g. Become CEO, Travel" className="w-full bg-[#0A0D14] border border-white/10 rounded-xl py-2.5 px-3 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                </div>
              </div>

              <div className="pt-4 flex items-center justify-end gap-3 border-t border-white/5">
                <button 
                  type="button"
                  onClick={() => setIsCreateModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-gray-400 hover:text-white transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  disabled={isCreating}
                  className="px-5 py-2.5 rounded-xl text-xs font-black bg-[#D4AF37] text-black hover:bg-[#F2CD5C] transition-colors disabled:opacity-50 flex items-center gap-2"
                >
                  {isCreating ? <Loader2 className="w-4 h-4 animate-spin" /> : "Add User"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
