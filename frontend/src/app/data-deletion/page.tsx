"use client";

import React, { useState } from 'react';

export default function DataDeletionPage() {
  const [email, setEmail] = useState("");
  const [reason, setReason] = useState("");
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    
    // In a production environment, this would call a backend API endpoint
    // e.g., fetch('/api/users/deletion-request', { method: 'POST', body: JSON.stringify({ email, reason }) })
    
    setSubmitted(true);
  };

  return (
    <main className="min-h-screen bg-[#0A0E14] text-[#F5F5F1] font-sans pt-24 pb-12 px-6">
      <div className="max-w-3xl mx-auto glass-card rounded-2xl p-8 md:p-12 relative overflow-hidden">
        {/* Decorative elements */}
        <div className="absolute -top-32 -right-32 w-64 h-64 bg-[#E27D8D] rounded-full blur-[100px] opacity-20"></div>
        <div className="absolute -bottom-32 -left-32 w-64 h-64 bg-[#E11D48] rounded-full blur-[100px] opacity-10"></div>
        
        <div className="relative z-10">
          <h1 className="text-3xl md:text-4xl font-serif mb-2 gold-gradient-text">Account Data Deletion Request</h1>
          <p className="text-gray-400 mb-8">
            As per Google Play Store policies and global privacy regulations, you have the right to request the complete deletion of your Knot account and all associated personal data.
          </p>

          {submitted ? (
            <div className="bg-emerald-900/20 border border-emerald-500/30 rounded-xl p-6 text-center">
              <svg className="w-12 h-12 text-emerald-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <h2 className="text-2xl font-serif text-emerald-400 mb-2">Request Received</h2>
              <p className="text-gray-300">
                Your data deletion request for <strong>{email}</strong> has been successfully submitted. 
                Our support team will process your request within 7-14 business days. You will receive a confirmation email once your data has been permanently erased.
              </p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="bg-red-900/10 border border-red-500/20 rounded-xl p-5 mb-8">
                <h3 className="text-red-400 font-semibold mb-2 flex items-center gap-2">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                  Warning: Irreversible Action
                </h3>
                <p className="text-red-300/80 text-sm">
                  Submitting this request will permanently delete your profile, photos, matches, chat history, and identity verification records. This action cannot be undone.
                </p>
              </div>

              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-300 mb-2">
                  Account Email Address *
                </label>
                <input
                  type="email"
                  id="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full bg-[#121721] border border-gray-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#E11D48] focus:ring-1 focus:ring-[#E11D48] transition-colors"
                  placeholder="name@example.com"
                />
              </div>

              <div>
                <label htmlFor="reason" className="block text-sm font-medium text-gray-300 mb-2">
                  Reason for Deletion (Optional)
                </label>
                <textarea
                  id="reason"
                  rows={4}
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  className="w-full bg-[#121721] border border-gray-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#E11D48] focus:ring-1 focus:ring-[#E11D48] transition-colors resize-none"
                  placeholder="Tell us why you're leaving..."
                />
              </div>

              <div className="pt-4">
                <button
                  type="submit"
                  className="w-full sm:w-auto px-8 py-3 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg transition-colors shadow-lg shadow-red-900/20"
                >
                  Submit Deletion Request
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </main>
  );
}
