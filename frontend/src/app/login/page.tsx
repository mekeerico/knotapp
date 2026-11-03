"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Loader2, ArrowRight, Eye, EyeOff, Check, ShieldCheck, X, RefreshCw } from "lucide-react";
import { getApiUrl } from "../../services/api";

export default function Login() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [isLogin, setIsLogin] = useState(true);
  const [rememberMe, setRememberMe] = useState(true);

  // 6-Digit OTP Modal State
  const [showOtpModal, setShowOtpModal] = useState(false);
  const [otpDigits, setOtpDigits] = useState<string[]>(["", "", "", "", "", ""]);
  const [otpError, setOtpError] = useState("");
  const [isVerifyingOtp, setIsVerifyingOtp] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);
  const otpInputRefs = useRef<Array<HTMLInputElement | null>>([]);

  // Pre-load saved credentials on mount if Remember Me was enabled, and check ?mode=signup
  useEffect(() => {
    try {
      const params = new URLSearchParams(window.location.search);
      if (params.get("mode") === "signup") {
        setIsLogin(false);
      }

      const storedRemember = localStorage.getItem("knot_remember_me");
      const isRemember = storedRemember === null || storedRemember === "true";
      setRememberMe(isRemember);

      if (isRemember) {
        const savedEmail = localStorage.getItem("knot_saved_email");
        const savedPass = localStorage.getItem("knot_saved_password");
        if (savedEmail) setEmail(savedEmail);
        if (savedPass) setPassword(savedPass);
      }
    } catch (_) {
      // In case localStorage is blocked in some environments
    }
  }, []);

  // Resend cooldown timer
  useEffect(() => {
    if (resendCooldown <= 0) return;
    const timer = setInterval(() => {
      setResendCooldown((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(timer);
  }, [resendCooldown]);

  const sendOtpCode = async () => {
    const API_URL = getApiUrl();
    const res = await fetch(`${API_URL}/auth/send-otp`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: email.trim(), password }),
    });
    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.message || "Failed to send verification code.");
    }
    setResendCooldown(60);
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Please enter both email and password.");
      return;
    }

    if (!isLogin && password.length < 6) {
      setError("Password must be at least 6 characters long.");
      return;
    }

    setIsLoading(true);
    setError("");

    // Persist or clear saved credentials based on Remember Me preference
    try {
      if (rememberMe) {
        localStorage.setItem("knot_saved_email", email.trim());
        localStorage.setItem("knot_saved_password", password);
        localStorage.setItem("knot_remember_me", "true");
      } else {
        localStorage.removeItem("knot_saved_email");
        localStorage.removeItem("knot_saved_password");
        localStorage.setItem("knot_remember_me", "false");
      }
    } catch (_) {}

    if (!isLogin) {
      try {
        await sendOtpCode();
        setOtpDigits(["", "", "", "", "", ""]);
        setOtpError("");
        setShowOtpModal(true);
        setTimeout(() => otpInputRefs.current[0]?.focus(), 100);
      } catch (err: any) {
        setError(err.message || "Could not send verification code. Please try again.");
      } finally {
        setIsLoading(false);
      }
      return;
    }

    try {
      const API_URL = getApiUrl();
        
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

  const handleOtpChange = (index: number, value: string) => {
    const digit = value.replace(/\D/g, "").slice(-1);
    const updated = [...otpDigits];
    updated[index] = digit;
    setOtpDigits(updated);
    setOtpError("");

    if (digit && index < 5) {
      otpInputRefs.current[index + 1]?.focus();
    }
  };

  const handleOtpKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace" && !otpDigits[index] && index > 0) {
      otpInputRefs.current[index - 1]?.focus();
    } else if (e.key === "Enter" && otpDigits.join("").length === 6) {
      handleVerifyOtp();
    }
  };

  const handleOtpPaste = (e: React.ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 6);
    if (!pasted) return;
    const updated = ["", "", "", "", "", ""];
    for (let i = 0; i < pasted.length; i++) {
      updated[i] = pasted[i];
    }
    setOtpDigits(updated);
    setOtpError("");
    const focusIndex = Math.min(pasted.length, 5);
    otpInputRefs.current[focusIndex]?.focus();
  };

  const handleVerifyOtp = async () => {
    const code = otpDigits.join("");
    if (code.length !== 6) {
      setOtpError("Please enter all 6 digits sent to your email.");
      return;
    }

    setIsVerifyingOtp(true);
    setOtpError("");

    try {
      const API_URL = getApiUrl();
      const res = await fetch(`${API_URL}/auth/verify-otp`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim(), code }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Invalid verification code.");
      }

      sessionStorage.setItem("onboard_email", email.trim());
      sessionStorage.setItem("onboard_password", password);
      sessionStorage.setItem("onboard_otp_verified", "true");
      if (data.signupToken) {
        sessionStorage.setItem("onboard_signup_token", data.signupToken);
      }
      setShowOtpModal(false);
      router.push("/onboarding?step=2");
    } catch (err: any) {
      setOtpError(err.message || "Verification failed. Please check the code and try again.");
    } finally {
      setIsVerifyingOtp(false);
    }
  };

  const handleResendOtp = async () => {
    if (resendCooldown > 0) return;
    setOtpError("");
    try {
      await sendOtpCode();
      setOtpDigits(["", "", "", "", "", ""]);
      otpInputRefs.current[0]?.focus();
    } catch (err: any) {
      setOtpError(err.message || "Could not resend code.");
    }
  };

  return (
    <main className="min-h-screen bg-[#0A0D14] flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background Orbs */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] rounded-full bg-[#E27D8D]/15 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[600px] h-[600px] rounded-full bg-[#E27D8D]/15 blur-[120px] pointer-events-none" />

      <div className="w-full max-w-md z-10 relative">
        <Link href="/" className="inline-flex items-center gap-3 mb-10 group">
          <img 
            src="/knot-icon.png?v=4" 
            alt="KNOT Logo" 
            className="w-10 h-10 rounded-2xl shadow-xl border border-white/10 group-hover:scale-105 transition-transform" 
          />
          <span className="text-3xl font-serif font-black tracking-wider text-[#F5F5F1] flex items-center gap-1">
            KNOT<span className="text-[#E27D8D]">.</span>
          </span>
        </Link>

        <div className="glass-card rounded-[36px] p-8 sm:p-10 border border-white/10 shadow-2xl relative">
          <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-[#E27D8D]/15 to-transparent rounded-bl-full pointer-events-none" />
          
          <h1 className="text-2xl font-serif font-black text-white mb-2">
            {isLogin ? "Welcome Back" : "Join the Registry"}
          </h1>
          <p className="text-sm text-gray-300 mb-8">
            {isLogin ? "Sign in to access your curated matches and AI coach." : "Enter your email and a secure password to receive your 6-digit verification code."}
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
                className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#E27D8D]/60 transition-colors"
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
                  className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 pl-4 pr-12 text-sm text-white focus:outline-none focus:border-[#E27D8D]/60 transition-colors"
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

            {/* Remember Me Checkbox */}
            <div 
              onClick={() => setRememberMe(!rememberMe)}
              className="flex items-center gap-2.5 cursor-pointer select-none py-1 group overflow-hidden"
            >
              <div className={`w-5 h-5 rounded-md flex-shrink-0 flex items-center justify-center border transition-all ${
                rememberMe 
                  ? "bg-[#E27D8D] border-[#E27D8D] text-white" 
                  : "bg-[#121721] border-white/20 text-transparent group-hover:border-white/40"
              }`}>
                <Check className="w-3.5 h-3.5 stroke-[3]" />
              </div>
              <span className="text-xs text-slate-200 font-medium whitespace-nowrap overflow-hidden text-ellipsis">
                Remember my Email &amp; Password on this device
              </span>
            </div>

            <button 
              type="submit"
              disabled={isLoading || !email || !password}
              className="w-full mt-2 py-4 rounded-full text-sm font-black rose-glow-btn text-white disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <><Loader2 className="w-4 h-4 animate-spin" /> {isLogin ? 'Authenticating...' : 'Sending Verification Code...'}</>
              ) : (
                <>{isLogin ? 'Access Registry' : 'Apply Here'} <ArrowRight className="w-4 h-4" /></>
              )}
            </button>
          </form>

          <div className="mt-8 pt-6 border-t border-white/5 text-center space-y-3">
            <p className="text-xs text-gray-400">
              {isLogin ? (
                <>Not on the registry yet? <button type="button" onClick={() => { setIsLogin(false); setError(""); }} className="text-[#E27D8D] font-bold hover:underline">Apply here</button></>
              ) : (
                <>Already a member? <button type="button" onClick={() => { setIsLogin(true); setError(""); }} className="text-[#E27D8D] font-bold hover:underline">Access Registry</button></>
              )}
            </p>
            <div>
              <Link 
                href="/" 
                className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#E27D8D] hover:text-white transition-colors"
              >
                ← Return to Welcome Page • Read All About KNOT
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* 6-Digit Email OTP Pop-up Modal */}
      {showOtpModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 animate-in fade-in duration-200">
          <div className="glass-card rounded-[32px] p-6 sm:p-8 border border-[#E27D8D]/30 max-w-md w-full shadow-2xl relative text-center space-y-6">
            <button
              type="button"
              onClick={() => setShowOtpModal(false)}
              className="absolute top-5 right-5 text-gray-400 hover:text-white transition-colors"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="w-14 h-14 rounded-2xl bg-[#E27D8D]/10 border border-[#E27D8D]/30 flex items-center justify-center mx-auto text-[#E27D8D]">
              <ShieldCheck className="w-7 h-7" />
            </div>

            <div className="space-y-2">
              <h2 className="text-2xl font-serif font-black text-white">Verify Your Email</h2>
              <p className="text-xs text-gray-300 leading-relaxed">
                We sent a 6-digit verification code to <span className="text-[#E27D8D] font-bold">{email.trim()}</span>. Enter the code below to confirm you are human and continue onboarding.
              </p>
            </div>

            {otpError && (
              <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-xs font-semibold text-red-400">
                {otpError}
              </div>
            )}

            {/* 6 Number Input Boxes */}
            <div className="flex items-center justify-center gap-2 sm:gap-3">
              {otpDigits.map((digit, idx) => (
                <input
                  key={idx}
                  ref={(el) => {
                    otpInputRefs.current[idx] = el;
                  }}
                  type="text"
                  inputMode="numeric"
                  maxLength={1}
                  value={digit}
                  onChange={(e) => handleOtpChange(idx, e.target.value)}
                  onKeyDown={(e) => handleOtpKeyDown(idx, e)}
                  onPaste={handleOtpPaste}
                  disabled={isVerifyingOtp}
                  className="w-11 h-14 sm:w-12 sm:h-14 rounded-2xl bg-[#121721] border border-white/15 text-center text-xl font-black text-white focus:outline-none focus:border-[#E27D8D] focus:ring-2 focus:ring-[#E27D8D]/30 transition-all"
                />
              ))}
            </div>

            <div className="space-y-3 pt-2">
              <button
                type="button"
                onClick={handleVerifyOtp}
                disabled={isVerifyingOtp || otpDigits.join("").length !== 6}
                className="w-full py-4 rounded-full text-sm font-black rose-glow-btn text-white disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {isVerifyingOtp ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" /> Verifying Code...
                  </>
                ) : (
                  <>
                    Verify &amp; Continue to Onboarding <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>

              <div className="text-xs text-gray-400 pt-1">
                Didn&apos;t receive the code?{" "}
                {resendCooldown > 0 ? (
                  <span className="text-gray-500 font-semibold">Resend in {resendCooldown}s</span>
                ) : (
                  <button
                    type="button"
                    onClick={handleResendOtp}
                    className="text-[#E27D8D] font-bold hover:underline inline-flex items-center gap-1"
                  >
                    <RefreshCw className="w-3 h-3" /> Resend Code
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}

