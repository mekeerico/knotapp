"use client";

import React, { useState } from "react";
import Link from "next/link";
import { 
  Sparkles, ShieldCheck, HeartHandshake, Bot, ShieldAlert, CheckCircle2, 
  ArrowRight, Users, Star, Award, Shield, UserCheck, MessageSquare
} from "lucide-react";

export default function Home() {
  const [activeTab, setActiveTab] = useState("compatibility");

  return (
    <div className="flex flex-col min-h-screen">
      {/* Premium Header */}
      <header className="fixed top-0 left-0 right-0 z-50 glass-nav">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 h-16 md:h-20 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <span className="text-xl md:text-2xl font-serif font-black tracking-wider text-[#F5F5F1] flex items-center gap-1">
              KNOT<span className="text-[#E11D48]">.</span>
            </span>
          </Link>
          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-gray-300">
            <Link href="#features" className="hover:text-[#E11D48] transition-colors">Platform</Link>
            <Link href="#trust" className="hover:text-[#E11D48] transition-colors">Trust Architecture</Link>
            <Link href="#coach" className="hover:text-[#E11D48] transition-colors">AI Coach</Link>
          </nav>
          <div className="flex items-center gap-3 md:gap-4">
            <Link href="/login" className="text-sm font-semibold hover:text-[#E11D48] transition-colors">
              Sign In
            </Link>
            <Link href="/login" className="px-4 py-2 md:px-5 md:py-2.5 rounded-full text-xs md:text-sm font-black rose-glow-btn text-white">
              Join Registry
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative pt-24 pb-16 md:pt-48 md:pb-36 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-16 items-center">
          <div className="lg:col-span-7 space-y-8 text-left">
            <div className="inline-flex items-center gap-2 px-3 py-1 sm:px-4 sm:py-1.5 rounded-full bg-white/5 border border-white/10 text-[10px] sm:text-xs font-semibold tracking-wider text-[#E11D48] uppercase">
              <Sparkles className="w-3.5 h-3.5" /> ANTI-FRAUD | AI MATCHMAKING | HIGH-TRUST
            </div>
            <h1 className="text-3xl sm:text-5xl md:text-7xl font-serif font-black text-[#F5F5F1] leading-tight">
              Where Compatibility <br />
              Becomes <span className="gold-gradient-text">Commitment.</span>
            </h1>
            <p className="text-base md:text-xl text-gray-400 font-sans max-w-xl leading-relaxed">
              KNOT is the world's most trusted relationship intelligence ecosystem built exclusively for verified singles seeking marriage and permanent partnership. No shallow swipes. No superficial games. Just real love.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 pt-4">
              <Link href="/onboarding" className="px-8 py-4 rounded-full text-base font-black rose-glow-btn text-white text-center flex items-center justify-center gap-2">
                Begin AI Guided Interview <ArrowRight className="w-4 h-4" />
              </Link>
              <Link href="#trust" className="px-8 py-4 rounded-full text-base font-bold bg-white/5 border border-white/10 hover:bg-white/10 text-[#F5F5F1] text-center flex items-center justify-center gap-2 transition-all">
                Our Verification System
              </Link>
            </div>
            <div className="flex flex-wrap items-center gap-4 sm:gap-8 pt-6 border-t border-white/5">
              <div>
                <h4 className="text-2xl font-black text-white">100%</h4>
                <p className="text-xs text-gray-500 uppercase tracking-widest mt-1">Verified Users</p>
              </div>
              <div className="hidden sm:block h-8 w-px bg-white/10" />
              <div>
                <h4 className="text-2xl font-black text-[#E11D48]">94%</h4>
                <p className="text-xs text-gray-500 uppercase tracking-widest mt-1">Success Match Index</p>
              </div>
              <div className="hidden sm:block h-8 w-px bg-white/10" />
              <div>
                <h4 className="text-2xl font-black text-white">0%</h4>
                <p className="text-xs text-gray-500 uppercase tracking-widest mt-1">Superficial Swiping</p>
              </div>
            </div>
          </div>

          {/* Cinematic Interactive Core Visual Mockup */}
          <div className="lg:col-span-5 relative flex justify-center items-center">
            {/* Pulsing Orb Background Glow */}
            <div className="absolute w-72 h-72 rounded-full bg-[#2D1B4E]/50 blur-3xl -z-10 orb-pulse-animation" />
            
            {/* Custom Interactive Mockup Card */}
            <div className="w-full max-w-sm rounded-[36px] glass-card p-6 relative overflow-hidden border border-white/10 hover:border-[#E11D48]/30 transition-all duration-500">
              <div className="relative aspect-[4/5] rounded-[24px] overflow-hidden mb-6">
                <img 
                  src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80" 
                  alt="Profile" 
                  className="w-full h-full object-cover grayscale-[20%] brightness-90"
                />
                <div className="absolute top-4 right-4 trust-badge px-3 py-1 rounded-full text-xs font-black flex items-center gap-1.5">
                  <ShieldCheck className="w-3.5 h-3.5" /> ID & Selfie Verified
                </div>
                <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/90 to-transparent">
                  <div className="flex items-end justify-between">
                    <div>
                      <h3 className="text-xl font-bold text-white">Gabriel, 29</h3>
                      <p className="text-xs text-[#E11D48]">Architect • Intentional Builder</p>
                    </div>
                    <div className="bg-[#E11D48]/20 border border-[#E11D48] px-2.5 py-1 rounded-lg text-center">
                      <div className="text-[9px] uppercase tracking-wider text-gray-300 font-bold">Match Score</div>
                      <div className="text-base font-black text-[#E11D48]">96%</div>
                    </div>
                  </div>
                </div>
              </div>
              <div className="space-y-4">
                <div className="flex flex-wrap gap-2">
                  <span className="px-3 py-1 rounded-full bg-white/5 border border-white/5 text-xs text-gray-300">✔ Family-Oriented</span>
                  <span className="px-3 py-1 rounded-full bg-[#2D1B4E]/30 border border-[#E11D48]/20 text-xs text-[#E11D48]">✔ Secure Attachment</span>
                  <span className="px-3 py-1 rounded-full bg-white/5 border border-white/5 text-xs text-gray-300">✔ Marriage-Focused</span>
                </div>
                
                {/* AI Explanation Explanation */}
                <div className="p-4 rounded-2xl bg-white/5 border border-white/5 space-y-2">
                  <div className="flex items-center gap-1.5 text-xs text-[#E11D48] font-bold">
                    <Bot className="w-3.5 h-3.5" /> Why You Matched
                  </div>
                  <p className="text-xs text-gray-400 leading-relaxed">
                    "Both value career milestones and solid family foundations. Your complementary conflict-resolution styles (Secure-Collaborative) suggest high capability for long-term marital success."
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Feature Section (Deep Intelligence Platforms) */}
      <section id="features" className="py-24 bg-black/40 relative">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center max-w-2xl mx-auto mb-16 space-y-4">
            <h2 className="text-4xl md:text-5xl font-serif font-black text-white">Relationship Intelligence Technology</h2>
            <p className="text-gray-400">Our four foundational layers engineered specifically to ensure maximum security, safety, and compatibility.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div className="p-8 rounded-[28px] glass-card space-y-6 hover:translate-y-[-4px] transition-transform duration-300">
              <div className="w-12 h-12 rounded-2xl bg-[#E11D48]/10 flex items-center justify-center text-[#E11D48] border border-[#E11D48]/20">
                <HeartHandshake className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold text-white">Compatibility AI</h3>
              <p className="text-sm text-gray-400 leading-relaxed">
                Calculates values, lifestyle alignments, attachment archetypes, and marriage timelines. We match on psychological depth, not surface appearances.
              </p>
            </div>

            <div className="p-8 rounded-[28px] glass-card space-y-6 hover:translate-y-[-4px] transition-transform duration-300">
              <div className="w-12 h-12 rounded-2xl bg-[#10B981]/10 flex items-center justify-center text-[#10B981] border border-[#10B981]/20">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold text-white">Identity Verification</h3>
              <p className="text-sm text-gray-400 leading-relaxed">
                Dual government ID and real-time biometric selfie verification. Keeps 100% of romance scammers, catfishers, and malicious bad actors out.
              </p>
            </div>

            <div className="p-8 rounded-[28px] glass-card space-y-6 hover:translate-y-[-4px] transition-transform duration-300">
              <div className="w-12 h-12 rounded-2xl bg-[#E27D8D]/10 flex items-center justify-center text-[#E27D8D] border border-[#E27D8D]/20">
                <Bot className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold text-white">AI Relationship Coach</h3>
              <p className="text-sm text-gray-400 leading-relaxed">
                An empathetic relationship therapist in your pocket. Offers icebreakers, conversation analysis, first date strategies, and marital readiness checkpoints.
              </p>
            </div>

            <div className="p-8 rounded-[28px] glass-card space-y-6 hover:translate-y-[-4px] transition-transform duration-300">
              <div className="w-12 h-12 rounded-2xl bg-red-500/10 flex items-center justify-center text-red-400 border border-red-500/20">
                <ShieldAlert className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold text-white">Anti-Fraud Engine</h3>
              <p className="text-sm text-gray-400 leading-relaxed">
                Real-time conversation safety shields monitor indicators of financial coercion, catfish speech patterns, and manipulation to protect your emotional safety.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Trust Architecture Details */}
      <section id="trust" className="py-24 relative overflow-hidden">
        <div className="max-w-7xl mx-auto px-6 grid grid-cols-1 lg:grid-cols-12 gap-16 items-center">
          <div className="lg:col-span-5 relative flex justify-center">
            {/* Visual trust shield element */}
            <div className="w-full max-w-sm rounded-[36px] glass-card p-8 border border-[#10B981]/20 space-y-6">
              <div className="flex justify-between items-center">
                <div className="inline-flex items-center gap-1.5 text-xs text-[#10B981] font-black uppercase tracking-wider">
                  <ShieldCheck className="w-4 h-4" /> KNOT Trust Profile
                </div>
                <div className="text-2xl font-black text-[#10B981]">98%</div>
              </div>
              <div className="space-y-4">
                <div className="flex justify-between items-center py-2 border-b border-white/5">
                  <span className="text-xs text-gray-400">Government ID Verified</span>
                  <CheckCircle2 className="w-4 h-4 text-[#10B981]" />
                </div>
                <div className="flex justify-between items-center py-2 border-b border-white/5">
                  <span className="text-xs text-gray-400">Liveness Selfie Verified</span>
                  <CheckCircle2 className="w-4 h-4 text-[#10B981]" />
                </div>
                <div className="flex justify-between items-center py-2 border-b border-white/5">
                  <span className="text-xs text-gray-400">Phone & Account Authenticity</span>
                  <CheckCircle2 className="w-4 h-4 text-[#10B981]" />
                </div>
                <div className="flex justify-between items-center py-2">
                  <span className="text-xs text-gray-400">Clean Communication History</span>
                  <CheckCircle2 className="w-4 h-4 text-[#10B981]" />
                </div>
              </div>
              <p className="text-xs text-gray-500 leading-relaxed text-center">
                This trust profile resides on our high-performance ledger, preventing malicious duplicates and fake identities.
              </p>
            </div>
          </div>

          <div className="lg:col-span-7 space-y-8">
            <h2 className="text-4xl md:text-5xl font-serif font-black text-white leading-tight">
              An Impenetrable Network <br />
              of <span className="text-[#10B981]">Verified Real Humans.</span>
            </h2>
            <p className="text-lg text-gray-400 leading-relaxed">
              Casual dating apps optimize for bot density, fake profiles, and scams to increase endless swiping loops. At KNOT, we completely removed scams. Every member undergoes strict, AI-validated identity screening before interacting with the registry.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div className="flex gap-4">
                <div className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center text-[#10B981] flex-shrink-0">
                  <UserCheck className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-white">0% Catfishing</h4>
                  <p className="text-xs text-gray-500 mt-1">Biometric face-matching guarantees profiles correspond to actual human images.</p>
                </div>
              </div>
              <div className="flex gap-4">
                <div className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center text-[#10B981] flex-shrink-0">
                  <Shield className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-white">Duplicate Elimination</h4>
                  <p className="text-xs text-gray-500 mt-1">One unique verified account per SSN/ID parameters to restrict fake loops.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* AI Relationship Coach Showcase */}
      <section id="coach" className="py-24 bg-black/20">
        <div className="max-w-7xl mx-auto px-6 text-center space-y-16">
          <div className="max-w-2xl mx-auto space-y-4">
            <h2 className="text-4xl md:text-5xl font-serif font-black text-white">Meet Your Relationship Coach</h2>
            <p className="text-gray-400">
              Not sure how to break the ice or navigate differences? KNOT's real-time AI Coach assists couples in communicating securely and with high emotional intelligence.
            </p>
          </div>

          <div className="max-w-4xl mx-auto rounded-[36px] glass-card overflow-hidden border border-white/5 grid grid-cols-1 md:grid-cols-12">
            <div className="md:col-span-5 bg-[#2D1B4E]/20 p-8 flex flex-col justify-between text-left space-y-8">
              <div className="space-y-4">
                <div className="w-12 h-12 rounded-2xl bg-[#E11D48]/10 flex items-center justify-center text-[#E11D48] border border-[#E11D48]/20">
                  <Bot className="w-6 h-6" />
                </div>
                <h3 className="text-2xl font-serif font-bold text-white">Empathetic Intelligence</h3>
                <p className="text-sm text-gray-400 leading-relaxed">
                  Our coach does not just spit generic advice. It evaluates both user's profile dimensions, attachment style dynamics, and conversational milestones to offer highly tailored guidance.
                </p>
              </div>
              <div className="flex items-center gap-3">
                <div className="flex -space-x-2">
                  <img className="w-8 h-8 rounded-full object-cover border border-[#0A0E14]" src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&q=80" alt="" />
                  <img className="w-8 h-8 rounded-full object-cover border border-[#0A0E14]" src="https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&q=80" alt="" />
                </div>
                <span className="text-xs text-gray-500 font-bold">Assisted 12,000+ matches to commitment</span>
              </div>
            </div>

            <div className="md:col-span-7 p-8 bg-black/60 space-y-6 text-left">
              {/* Fake Coach chat history interface mockup */}
              <div className="space-y-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-[#E11D48]/10 flex items-center justify-center text-[#E11D48] flex-shrink-0 text-xs font-bold border border-[#E11D48]/20">AI</div>
                  <div className="p-4 rounded-[22px] rounded-tl-none bg-white/5 border border-white/5 text-xs text-gray-300 max-w-sm">
                    "I noticed both of you value travel and family traditions. Would you like a prompt to start the conversation?"
                  </div>
                </div>
                <div className="flex items-start gap-3 justify-end">
                  <div className="p-4 rounded-[22px] rounded-tr-none bg-[#E27D8D]/15 border border-[#E27D8D]/20 text-xs text-[#F5F5F1] max-w-sm">
                    "Yes, please suggest an elegant icebreaker."
                  </div>
                  <div className="w-8 h-8 rounded-full bg-[#E27D8D] flex items-center justify-center text-white flex-shrink-0 text-xs font-bold">ME</div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-[#E11D48]/10 flex items-center justify-center text-[#E11D48] flex-shrink-0 text-xs font-bold border border-[#E11D48]/20">AI</div>
                  <div className="p-4 rounded-[22px] rounded-tl-none bg-white/5 border border-white/5 text-xs text-gray-300 max-w-sm space-y-2">
                    <p>"Here is a custom icebreaker based on your high values alignment:"</p>
                    <p className="italic text-[#E11D48] font-semibold font-serif">
                      "Since you both love exploring historical towns, what is one memory from a childhood trip that inspired your current love for history?"
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-black/60 border-t border-white/5 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 flex flex-col md:flex-row items-center justify-between gap-6 text-sm text-gray-500">
          <div className="flex flex-col sm:flex-row items-center gap-2 text-center sm:text-left">
            <span className="text-lg font-serif font-black text-white">KNOT.</span>
            <span className="text-xs">© 2026 KNOT AI Relationship Systems.</span>
          </div>
          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 text-xs font-medium text-gray-400">
            <Link href="/terms" className="hover:text-[#E11D48] transition-colors">Terms of Service</Link>
            <Link href="/privacy" className="hover:text-[#E11D48] transition-colors">Privacy Policy</Link>
            <Link href="/community-guidelines" className="hover:text-[#E11D48] transition-colors">Community Guidelines & Safety Standards</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
