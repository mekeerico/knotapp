"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, HeartHandshake, Send, CheckCircle2, AlertTriangle } from "lucide-react";
import { getApiUrl } from "../../services/api";

export default function SupportPage() {
  const [userName, setUserName] = useState("");
  const [userEmail, setUserEmail] = useState("");
  const [userId, setUserId] = useState<string | undefined>(undefined);
  const [category, setCategory] = useState("General Enquiry");
  const [subject, setSubject] = useState("");
  const [message, setMessage] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    try {
      const savedUser = localStorage.getItem("knot_user");
      if (savedUser) {
        const parsed = JSON.parse(savedUser);
        if (parsed.id) setUserId(parsed.id);
        if (parsed.firstName) setUserName(parsed.firstName);
        if (parsed.email) setUserEmail(parsed.email);
      }
    } catch {
      // ignore
    }
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!subject.trim() || !message.trim()) {
      setError("Please fill out both the subject and message.");
      return;
    }
    setSubmitting(true);
    setError("");
    setSuccess("");
    try {
      const token = localStorage.getItem("knot_token");
      const res = await fetch(`${getApiUrl()}/users/support`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({
          userId,
          userName: userName.trim() || undefined,
          userEmail: userEmail.trim() || undefined,
          category,
          subject: subject.trim(),
          message: message.trim(),
        }),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || "Failed to submit enquiry");
      }
      setSubject("");
      setMessage("");
      setSuccess("Your enquiry has been sent to the Admin dashboard! We will respond shortly.");
    } catch (err: any) {
      setError(err.message || "Could not submit your enquiry. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0A0E14] text-white flex flex-col">
      <header className="border-b border-white/5 bg-black/40 backdrop-blur-md">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <Link href="/dashboard" className="flex items-center gap-2 text-xs font-semibold text-gray-400 hover:text-white transition-colors">
            <ArrowLeft className="w-4 h-4" /> Back
          </Link>
          <Link href="/" className="text-xl font-serif font-black tracking-wider text-white">
            KNOT<span className="text-[#D4AF37]">.</span>
          </Link>
          <div className="w-12" />
        </div>
      </header>

      <main className="flex-1 flex items-center justify-center p-4 sm:p-8">
        <div className="w-full max-w-xl bg-[#121721] rounded-[28px] border border-[#D4AF37]/40 p-6 sm:p-8 shadow-2xl space-y-6">
          <div className="flex items-center gap-3.5 pb-4 border-b border-white/10">
            <div className="w-12 h-12 rounded-full bg-[#D4AF37]/15 border border-[#D4AF37]/40 flex items-center justify-center text-[#D4AF37]">
              <HeartHandshake className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-xl font-serif font-bold text-white">Support & Enquiry</h1>
              <p className="text-xs text-gray-400">
                Submit an enquiry to the KNOT Concierge & Admin Dashboard for review and response.
              </p>
            </div>
          </div>

          {success && (
            <div className="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-medium flex items-center gap-2.5">
              <CheckCircle2 className="w-4 h-4 flex-shrink-0" />
              <span>{success}</span>
            </div>
          )}

          {error && (
            <div className="p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-xs font-medium flex items-center gap-2.5">
              <AlertTriangle className="w-4 h-4 flex-shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-[11px] font-bold uppercase tracking-widest text-[#D4AF37] mb-1.5">
                  Your Name
                </label>
                <input
                  type="text"
                  value={userName}
                  onChange={(e) => setUserName(e.target.value)}
                  placeholder="Enter your name"
                  className="w-full p-3.5 rounded-xl bg-white/5 border border-white/10 text-sm text-white placeholder-gray-500 focus:border-[#D4AF37] focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-[11px] font-bold uppercase tracking-widest text-[#D4AF37] mb-1.5">
                  Your Email
                </label>
                <input
                  type="email"
                  required
                  value={userEmail}
                  onChange={(e) => setUserEmail(e.target.value)}
                  placeholder="you@example.com"
                  className="w-full p-3.5 rounded-xl bg-white/5 border border-white/10 text-sm text-white placeholder-gray-500 focus:border-[#D4AF37] focus:outline-none"
                />
              </div>
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-widest text-[#D4AF37] mb-1.5">
                Category of Enquiry
              </label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full p-3.5 rounded-xl bg-white/5 border border-white/10 text-sm text-white focus:border-[#D4AF37] focus:outline-none"
              >
                <option value="General Enquiry" className="bg-[#121721]">General Enquiry</option>
                <option value="Account & Verification" className="bg-[#121721]">Account & Verification</option>
                <option value="Subscription & Billing" className="bg-[#121721]">Subscription & Billing</option>
                <option value="Matchmaking & AI Coach" className="bg-[#121721]">Matchmaking & AI Coach</option>
                <option value="Technical Issue" className="bg-[#121721]">Technical Issue</option>
                <option value="Safety & Report" className="bg-[#121721]">Safety & Report</option>
                <option value="Other" className="bg-[#121721]">Other</option>
              </select>
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-widest text-[#D4AF37] mb-1.5">
                Subject
              </label>
              <input
                type="text"
                required
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                placeholder="Brief summary of your enquiry..."
                className="w-full p-3.5 rounded-xl bg-white/5 border border-white/10 text-sm text-white placeholder-gray-500 focus:border-[#D4AF37] focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-widest text-[#D4AF37] mb-1.5">
                Message
              </label>
              <textarea
                rows={5}
                required
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Describe your question or enquiry in detail..."
                className="w-full p-3.5 rounded-xl bg-white/5 border border-white/10 text-sm text-white placeholder-gray-500 focus:border-[#D4AF37] focus:outline-none resize-none"
              />
            </div>

            <div className="pt-2 flex justify-end">
              <button
                type="submit"
                disabled={submitting}
                className="w-full sm:w-auto px-8 py-3.5 rounded-full bg-gradient-to-r from-[#D4AF37] to-[#B8860B] text-black font-black text-xs uppercase tracking-wider shadow-lg shadow-[#D4AF37]/20 hover:opacity-95 transition-opacity flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
              >
                <Send className="w-4 h-4" />
                {submitting ? "Sending..." : "Submit Enquiry"}
              </button>
            </div>
          </form>
        </div>
      </main>
    </div>
  );
}
