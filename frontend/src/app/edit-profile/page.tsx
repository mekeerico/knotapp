"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, Save, Camera, X } from "lucide-react";

export default function EditProfile() {
  const router = useRouter();
  const [profile, setProfile] = useState<any>(null);
  const [photos, setPhotos] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    const fetchProfile = async () => {
      const token = localStorage.getItem('knot_token');
      if (!token) {
        router.push('/login');
        return;
      }
      try {
        const API_URL = process.env.NEXT_PUBLIC_API_URL;
        const res = await fetch(`${API_URL}/users/profile`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
          const data = await res.json();
          setProfile(data);
          if (data.profileImages && data.profileImages.length > 0) {
            setPhotos(data.profileImages.map((img: any) => img.url));
          } else if (data.photoUrls && data.photoUrls.length > 0) {
            setPhotos(data.photoUrls);
          }
        }
      } catch (err) {
        console.error("Error fetching profile", err);
      } finally {
        setIsLoading(false);
      }
    };
    fetchProfile();
  }, [router]);

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    if (photos.length >= 6) {
      alert("Maximum 6 photos allowed.");
      return;
    }
    
    setUploading(true);
    const file = e.target.files[0];
    const formData = new FormData();
    formData.append('photo', file);

    const token = localStorage.getItem('knot_token');
    const API_URL = process.env.NEXT_PUBLIC_API_URL;

    try {
      const res = await fetch(`${API_URL}/upload`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` },
        body: formData
      });
      const data = await res.json();
      if (res.ok && data.url) {
        setPhotos(prev => [...prev, `${API_URL}${data.url}`]);
      } else {
        alert("Upload failed: " + (data.error || "Unknown error"));
      }
    } catch (err) {
      console.error("Upload error", err);
      alert("Error uploading photo.");
    } finally {
      setUploading(false);
      e.target.value = '';
    }
  };

  const removePhoto = (index: number) => {
    setPhotos(photos.filter((_, i) => i !== index));
  };

  const handleSave = async () => {
    setIsSaving(true);
    const token = localStorage.getItem('knot_token');
    const API_URL = process.env.NEXT_PUBLIC_API_URL;
    
    try {
      const updatedData = { ...profile, profileImageUrls: photos };
      const res = await fetch(`${API_URL}/users/${profile.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(updatedData)
      });
      
      if (res.ok) {
        router.push('/dashboard');
      } else {
        alert("Failed to save profile.");
      }
    } catch (err) {
      console.error("Save error", err);
      alert("Error saving profile.");
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#0A0E14] flex items-center justify-center text-white">
        <p>Loading profile...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0A0E14] text-white font-sans selection:bg-[#D4AF37] selection:text-black pb-20">
      <header className="sticky top-0 z-50 bg-[#0A0E14]/80 backdrop-blur-xl border-b border-white/5 px-6 py-4 flex items-center justify-between">
        <button onClick={() => router.push('/dashboard')} className="text-gray-400 hover:text-white flex items-center gap-2 transition-colors">
          <ArrowLeft className="w-5 h-5" /> Back
        </button>
        <h1 className="text-lg font-bold">Edit Profile Data</h1>
        <button 
          onClick={handleSave} 
          disabled={isSaving}
          className="px-4 py-2 bg-[#D4AF37] text-black rounded-lg font-bold text-sm hover:bg-[#F3E5AB] transition-colors disabled:opacity-50 flex items-center gap-2"
        >
          {isSaving ? "Saving..." : <><Save className="w-4 h-4" /> Save</>}
        </button>
      </header>

      <main className="max-w-2xl mx-auto mt-8 p-6 space-y-12">
        {/* Photos Section */}
        <section className="glass-card p-6 rounded-[24px] border border-white/10 space-y-4">
          <h2 className="text-sm font-black uppercase tracking-widest text-gray-400">Registry Photos</h2>
          <p className="text-xs text-gray-500">Upload up to 6 photos. The first photo will be your primary profile picture.</p>
          
          <div className="grid grid-cols-3 gap-4">
            {photos.map((url, idx) => (
              <div key={idx} className="relative aspect-square rounded-xl overflow-hidden border border-white/10 group">
                <img src={url} alt={`Photo ${idx+1}`} className="w-full h-full object-cover" />
                {idx === 0 && (
                  <div className="absolute top-2 left-2 bg-[#D4AF37] px-2 py-0.5 rounded-md text-[8px] font-black uppercase text-black z-10">
                    Primary
                  </div>
                )}
                <button 
                  onClick={() => removePhoto(idx)}
                  className="absolute top-2 right-2 p-1.5 bg-black/60 rounded-full text-white opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-500/80 z-10"
                >
                  <X className="w-3 h-3" />
                </button>
              </div>
            ))}
            
            {photos.length < 6 && (
              <label className={`aspect-square rounded-xl border-2 border-dashed border-white/20 flex flex-col items-center justify-center gap-2 hover:border-[#D4AF37]/50 hover:bg-[#D4AF37]/5 transition-all cursor-pointer ${uploading ? 'opacity-50 pointer-events-none' : ''}`}>
                <input type="file" accept="image/*" className="hidden" onChange={handlePhotoUpload} disabled={uploading} />
                <Camera className="w-6 h-6 text-gray-400" />
                <span className="text-[9px] font-bold text-gray-400 uppercase tracking-wider">
                  {uploading ? 'Uploading...' : 'Add Photo'}
                </span>
              </label>
            )}
          </div>
        </section>

        {/* Basic Info */}
        <section className="glass-card p-6 rounded-[24px] border border-white/10 space-y-6">
          <h2 className="text-sm font-black uppercase tracking-widest text-gray-400">Basic Information</h2>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="text-[10px] uppercase tracking-widest text-gray-500 font-bold">First Name</label>
              <input 
                type="text" 
                value={profile?.firstName || ''} 
                onChange={e => setProfile({...profile, firstName: e.target.value})}
                className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:border-[#D4AF37]/50 outline-none" 
              />
            </div>
            <div className="space-y-2">
              <label className="text-[10px] uppercase tracking-widest text-gray-500 font-bold">Last Name</label>
              <input 
                type="text" 
                value={profile?.lastName || ''} 
                onChange={e => setProfile({...profile, lastName: e.target.value})}
                className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:border-[#D4AF37]/50 outline-none" 
              />
            </div>
            <div className="space-y-2 col-span-2">
              <label className="text-[10px] uppercase tracking-widest text-gray-500 font-bold">Occupation</label>
              <input 
                type="text" 
                value={profile?.occupation || ''} 
                onChange={e => setProfile({...profile, occupation: e.target.value})}
                className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:border-[#D4AF37]/50 outline-none" 
              />
            </div>
            <div className="space-y-2 col-span-2">
              <label className="text-[10px] uppercase tracking-widest text-gray-500 font-bold">Bio</label>
              <textarea 
                value={profile?.bio || ''} 
                onChange={e => setProfile({...profile, bio: e.target.value})}
                className="w-full h-24 bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:border-[#D4AF37]/50 outline-none resize-none" 
              />
            </div>
          </div>
        </section>

        {/* Location Info */}
        <section className="glass-card p-6 rounded-[24px] border border-white/10 space-y-6">
          <h2 className="text-sm font-black uppercase tracking-widest text-gray-400">Location Details</h2>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="text-[10px] uppercase tracking-widest text-gray-500 font-bold">City</label>
              <input 
                type="text" 
                value={profile?.residenceCity || ''} 
                onChange={e => setProfile({...profile, residenceCity: e.target.value})}
                className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:border-[#D4AF37]/50 outline-none" 
              />
            </div>
            <div className="space-y-2">
              <label className="text-[10px] uppercase tracking-widest text-gray-500 font-bold">Country</label>
              <input 
                type="text" 
                value={profile?.residenceCountry || ''} 
                onChange={e => setProfile({...profile, residenceCountry: e.target.value})}
                className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:border-[#D4AF37]/50 outline-none" 
              />
            </div>
          </div>
        </section>

      </main>
    </div>
  );
}
