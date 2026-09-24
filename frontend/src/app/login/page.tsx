"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Loader2, ArrowRight, Eye, EyeOff } from "lucide-react";

export default function Login() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [isLogin, setIsLogin] = useState(true);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Please enter both email and password.");
      return;
    }

    setIsLoading(true);
    setError("");

    if (!isLogin) {
      // For onboarding, store credentials temporarily and go directly to step 2 (Personal Details)
      sessionStorage.setItem('onboard_email', email);
      sessionStorage.setItem('onboard_password', password);
      router.push('/onboarding?step=2');
      return;
    }

    try {


      const API_URL = process.env.NEXT_PUBLIC_API_URL;
        
      const res = await fetch(`${API_URL}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password })
      });

      const data = await res.json();
      
      if (!res.ok) {
        throw new Error(data.message || "Invalid credentials.");
      }

      if (data.token) {
        localStorage.setItem('knot_token', data.token);
        if (data.user?.role === 'ADMIN') {
          router.push('/admin');
        } else {
          router.push('/dashboard');
        }
      }
    } catch (err: any) {
      setError(err.message || "Failed to sign in. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-[#0A0D14] flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background Orbs */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] rounded-full bg-[#D4AF37]/10 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[600px] h-[600px] rounded-full bg-[#E27D8D]/10 blur-[120px] pointer-events-none" />

      <div className="w-full max-w-md z-10 relative">
        <Link href="/" className="inline-block mb-10">
          <span className="text-3xl font-serif font-black tracking-wider text-[#F5F5F1] flex items-center gap-1">
            KNOT<span className="text-[#D4AF37]">.</span>
          </span>
        </Link>

        <div className="glass-card rounded-[36px] p-8 sm:p-10 border border-white/10 shadow-2xl relative">
          <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-[#D4AF37]/10 to-transparent rounded-bl-full pointer-events-none" />
          
          <h1 className="text-2xl font-serif font-black text-white mb-2">
            {isLogin ? "Welcome Back" : "Join the Registry"}
          </h1>
          <p className="text-sm text-gray-400 mb-8">
            {isLogin ? "Sign in to access your curated matches and AI coach." : "Enter your email and a secure password to begin."}
          </p>

          <form onSubmit={handleLogin} className="space-y-5">
            {error && (
              <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-xs font-semibold text-red-400">
                {error}
              </div>
            )}

            <div>
              <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1.5">Email Address</label>
              <input 
                type="email" 
                value={email} 
                onChange={e => setEmail(e.target.value)}
                placeholder="name@email.com" 
                className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50 transition-colors"
                disabled={isLoading}
                autoComplete="username"
              />
            </div>

            <div>
              <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1.5">Password</label>
              <div className="relative">
                <input 
                  type={showPassword ? "text" : "password"} 
                  value={password} 
                  onChange={e => setPassword(e.target.value)}
                  placeholder="Enter your password" 
                  className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 pl-4 pr-12 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50 transition-colors"
                  disabled={isLoading}
                  autoComplete={isLogin ? "current-password" : "new-password"}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white transition-colors"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <button 
              type="submit"
              disabled={isLoading || !email || !password}
              className="w-full mt-2 py-4 rounded-full text-sm font-black rose-glow-btn text-white disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <><Loader2 className="w-4 h-4 animate-spin" /> {isLogin ? 'Authenticating...' : 'Processing...'}</>
              ) : (
                <>{isLogin ? 'Access Registry' : 'Apply Here'} <ArrowRight className="w-4 h-4" /></>
              )}
            </button>
          </form>

          <div className="mt-8 pt-6 border-t border-white/5 text-center">
            <p className="text-xs text-gray-500">
              {isLogin ? (
                <>Not on the registry yet? <button type="button" onClick={() => setIsLogin(false)} className="text-[#D4AF37] font-bold hover:underline">Apply here</button></>
              ) : (
                <>Already a member? <button type="button" onClick={() => setIsLogin(true)} className="text-[#D4AF37] font-bold hover:underline">Access Registry</button></>
              )}
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}
