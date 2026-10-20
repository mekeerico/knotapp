import React from 'react';
import Link from 'next/link';

export default function TermsOfServicePage() {
  return (
    <div className="min-h-screen bg-[#0A0D14] text-white p-8 md:p-16 font-sans">
      <div className="max-w-4xl mx-auto bg-[#121721] p-8 md:p-12 rounded-2xl shadow-xl border border-[#2A3143]">
        <Link href="/" className="inline-flex items-center gap-2 text-sm text-gray-400 hover:text-[#E11D48] transition-colors mb-8">
          <span>←</span> Back to Home
        </Link>
        <h1 className="text-3xl md:text-5xl font-bold text-[#E11D48] mb-4 text-center">
          Terms of Service
        </h1>
        <p className="text-center text-gray-500 mb-12">Last Updated: July 17, 2026</p>

        <div className="space-y-10 text-gray-300 leading-relaxed">
          <p>These Terms of Service (&quot;Terms&quot;) govern your access to and use of the Knot application, website, and related services.</p>
          <p>By creating an account or using Knot, you agree to these Terms, our Privacy Policy, and our Community Guidelines.</p>
          <p>If you do not agree to these Terms, you must not use the Services.</p>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">1. About Knot</h3>
            <p className="mb-2">Knot is a technology platform designed to help users discover, connect with, communicate with, and learn about potential matches.</p>
            <p className="mb-2">Knot may provide:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>User profiles</li><li>Matchmaking features</li><li>AI-powered recommendations</li><li>Identity verification</li><li>Messaging</li><li>AI Coach features</li><li>AI Chat Assistant features</li><li>Safety tools</li><li>Reporting and blocking tools</li>
            </ul>
            <p>Knot does not guarantee that any user is truthful, safe, compatible, trustworthy, or suitable for a relationship.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">2. Eligibility</h3>
            <p className="mb-2">You may use Knot only if:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>You meet the minimum legal age required to use the Services in your jurisdiction;</li>
              <li>You are legally capable of entering into these Terms;</li>
              <li>You are not prohibited from using the Services under applicable law;</li>
              <li>You provide accurate information.</li>
            </ul>
            <p className="mb-2">Knot is not intended for children.</p>
            <p>You may not create an account for another person without authorization.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">3. Your Account</h3>
            <p className="mb-2">You are responsible for:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Providing accurate information</li><li>Maintaining the security of your account</li><li>Keeping your login credentials confidential</li><li>All activity occurring through your account</li>
            </ul>
            <p className="mb-2">You must notify us if you believe your account has been compromised.</p>
            <p className="mb-2">You may not:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Create fraudulent accounts</li><li>Create multiple accounts to evade enforcement</li><li>Impersonate another person</li><li>Use another person&apos;s identity</li><li>Misrepresent your age</li><li>Sell, transfer, or rent your account</li>
            </ul>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">4. Identity Verification</h3>
            <p className="mb-2">Knot may offer or require identity verification. Verification may involve:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>A selfie</li><li>Identity documents</li><li>Automated identity analysis</li><li>Facial comparison</li><li>Document authenticity checks</li><li>Fraud detection</li>
            </ul>
            <p className="mb-2">Knot may restrict profile visibility or access to certain features until verification is completed.</p>
            <p className="mb-2">A verified account does not mean that Knot guarantees the user&apos;s character, honesty, safety, relationship intentions, criminal history, financial reliability, or compatibility.</p>
            <p>Users should exercise independent judgment when interacting with others.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">5. Public Profile Visibility</h3>
            <p className="mb-2">Knot may allow users to create profiles that can be discovered by other users.</p>
            <p className="mb-2">Knot may restrict public visibility until required information is provided, identity verification is completed, safety checks are completed, or other applicable requirements are satisfied.</p>
            <p>Knot may remove, restrict, suspend, or limit profile visibility where we believe doing so is necessary for safety, fraud prevention, policy enforcement, or legal compliance.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">6. AI Features</h3>
            <p className="mb-2">Knot may provide AI Coach, AI Chat Assistant, AI matching, recommendation, moderation, and other automated features.</p>
            <p className="mb-2 font-semibold text-white">AI is not human.</p>
            <p className="mb-2">Knot&apos;s AI features are artificial intelligence systems. They are not human users, romantic partners, real members of the Knot community, or licensed professionals unless expressly stated otherwise.</p>
            <p className="mb-2">AI-generated information may be inaccurate, incomplete, inappropriate, outdated, or misleading.</p>
            <p className="mb-2">You are responsible for evaluating AI-generated content before relying on it.</p>
            <p>AI output does not constitute professional medical, psychological, legal, financial, or other regulated advice. You must not rely solely on AI output in emergencies or other situations requiring professional assistance.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">7. User Content</h3>
            <p className="mb-2">You retain ownership of content that you submit to Knot, subject to the rights necessary for us to operate the Services.</p>
            <p className="mb-2">By submitting content, you grant Knot a limited, non-exclusive, worldwide license to host, store, process, reproduce, display, transmit, and technically modify that content as reasonably necessary to provide, secure, moderate, and improve the Services.</p>
            <p className="mb-2">This license ends when the content is deleted, except where retention is reasonably necessary for legal, security, fraud-prevention, dispute-resolution, or backup purposes.</p>
            <p className="mb-2">You represent that:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>You own or have permission to submit your content;</li>
              <li>Your content is accurate where you represent it as factual;</li>
              <li>Your content does not violate applicable law;</li>
              <li>Your content does not violate these Terms or the Community Guidelines.</li>
            </ul>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">8. Prohibited Uses</h3>
            <p className="mb-2">You may not use Knot to:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Commit fraud</li><li>Scam or deceive users</li><li>Impersonate another person</li><li>Create fake identities</li><li>Harass, threaten, stalk, or intimidate</li><li>Promote terrorism or violent criminal activity</li><li>Facilitate trafficking or exploitation</li><li>Promote prostitution or sexual services</li><li>Exploit minors</li><li>Groom minors</li><li>Distribute child sexual abuse material</li><li>Share non-consensual intimate material</li><li>Threaten or encourage violence</li><li>Promote illegal drugs or illegal activities</li><li>Circumvent safety systems</li><li>Attempt to access another user&apos;s account</li><li>Introduce malware or malicious code</li><li>Scrape or collect user information without authorization</li><li>Use bots or automated systems to abuse the Services</li><li>Use Knot for unauthorized commercial solicitation</li><li>Use AI features to create scams, impersonation content, harassment, or illegal content</li>
            </ul>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">9. User-to-User Interactions</h3>
            <p className="mb-2">You are solely responsible for your interactions with other users. Knot does not guarantee the identity, intentions, safety, or honesty of any user.</p>
            <p className="mb-2">You should:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Avoid sending money to people you have only met online;</li><li>Be cautious about sharing sensitive information;</li><li>Use blocking and reporting tools where necessary;</li><li>Exercise caution before meeting anyone in person;</li><li>Tell a trusted person about planned meetings;</li><li>Seek help if you feel threatened or unsafe.</li>
            </ul>
            <p>Knot does not conduct a complete background investigation of every user.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">10. Reporting and Moderation</h3>
            <p className="mb-2">Users may report content or behavior that violates these Terms or our Community Guidelines.</p>
            <p className="mb-2">We may review reports, remove content, restrict visibility, limit account functionality, require verification, suspend or permanently terminate accounts, preserve information for safety or legal purposes, and report conduct to appropriate authorities.</p>
            <p>We do not guarantee that every violation will be detected or prevented.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">11. Suspension and Termination</h3>
            <p className="mb-2">We may suspend or terminate your account if you violate these Terms, the Community Guidelines, provide false or fraudulent information, create a safety risk, engage in illegal activity, attempt to evade enforcement, we are legally required to do so, or we reasonably believe action is necessary to protect users or the Services.</p>
            <p>You may stop using Knot at any time. Certain provisions of these Terms may survive termination.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">12. Intellectual Property</h3>
            <p className="mb-2">The Services and their content, excluding user content, may be owned by or licensed to Knot. This includes software, branding, logos, designs, text, graphics, AI interfaces, features, and technology.</p>
            <p>You may not copy, modify, distribute, sell, reverse engineer, or commercially exploit the Services except as permitted by law or with our written permission.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">13. Disclaimers</h3>
            <p className="mb-2">To the maximum extent permitted by law, the Services are provided on an &quot;as available&quot; basis.</p>
            <p>Knot does not guarantee continuous availability, error-free operation, that all users are genuine, that all information is accurate, that matches will be successful, that users will be safe, that AI outputs will be accurate, or that the Services will meet every individual expectation. Knot is a technology platform and does not guarantee personal, romantic, financial, physical, or emotional outcomes.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">14. Limitation of Liability</h3>
            <p className="mb-2">To the maximum extent permitted by applicable law, Knot and its operators, employees, affiliates, contractors, and service providers will not be liable for indirect, incidental, special, consequential, or punitive damages arising from your use of the Services.</p>
            <p>Nothing in these Terms excludes liability that cannot legally be excluded.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">15. Indemnification</h3>
            <p>To the extent permitted by applicable law, you agree to defend, indemnify, and hold harmless Knot and its representatives from claims, losses, liabilities, damages, and expenses arising from your violation of these Terms, your violation of applicable law, your user content, your interactions with other users, and your misuse of the Services.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">16. Changes to the Services</h3>
            <p>We may modify, suspend, or discontinue features or Services. We may introduce new features, including new AI features, security features, or verification methods. Material changes to these Terms may be communicated through appropriate means.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">17. Governing Law and Disputes</h3>
            <p>These Terms shall be governed by the laws of the applicable jurisdiction, subject to applicable mandatory consumer-protection laws. Disputes shall be handled in the courts or dispute-resolution forum legally applicable to the relevant jurisdiction, unless applicable law requires otherwise.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">18. Contact</h3>
            <p className="mb-2">Company: Clean Connect</p>
            <p>Email: <a href="mailto:cleanconnectng@gmail.com" className="text-[#E11D48] hover:underline">cleanconnectng@gmail.com</a></p>
          </section>
        </div>
      </div>
    </div>
  );
}
