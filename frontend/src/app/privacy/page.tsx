import React from 'react';
import Link from 'next/link';

export default function PrivacyPolicyPage() {
  return (
    <div className="min-h-screen bg-[#0A0D14] text-white p-8 md:p-16 font-sans">
      <div className="max-w-4xl mx-auto bg-[#121721] p-8 md:p-12 rounded-2xl shadow-xl border border-[#2A3143]">
        <Link href="/" className="inline-flex items-center gap-2 text-sm text-gray-400 hover:text-[#E11D48] transition-colors mb-8">
          <span>←</span> Back to Home
        </Link>
        <h1 className="text-3xl md:text-5xl font-bold text-[#E11D48] mb-4 text-center">
          Privacy Policy
        </h1>
        <p className="text-center text-gray-500 mb-12">Last Updated: July 17, 2026</p>

        <div className="space-y-10 text-gray-300 leading-relaxed">
          <p>Knot (&quot;Knot,&quot; &quot;we,&quot; &quot;us,&quot; or &quot;our&quot;) is a matchmaking and relationship platform operated by Clean Connect (&quot;Company&quot;).</p>
          <p>This Privacy Policy explains how we collect, use, disclose, store, protect, and otherwise process personal information when you use the Knot mobile application, website, and related services (collectively, the &quot;Services&quot;).</p>
          <p>By using Knot, you acknowledge that you have read and understood this Privacy Policy.</p>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">1. Information We Collect</h3>
            <p className="mb-2">The information we collect depends on how you use the Services.</p>

            <h4 className="font-semibold text-white mt-4 mb-2">1.1 Account and Registration Information</h4>
            <p className="mb-2">When you create an account, we may collect:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Name or display name</li><li>Email address</li><li>Telephone number</li><li>Password or authentication credentials</li><li>Date of birth or age information</li><li>Gender and relationship preferences</li><li>Account identifiers</li><li>Login and authentication information</li>
            </ul>
            <p className="mb-4">You are responsible for ensuring that the information you provide is accurate and truthful.</p>

            <h4 className="font-semibold text-white mt-4 mb-2">1.2 Profile Information</h4>
            <p className="mb-2">You may voluntarily provide information for your Knot profile, including:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Profile photographs</li><li>Biography and personal description</li><li>Location or general area</li><li>Education</li><li>Profession or occupation</li><li>Interests and hobbies</li><li>Relationship preferences</li><li>Lifestyle preferences</li><li>Religious or cultural information, where voluntarily provided</li><li>Other information you choose to include in your profile</li>
            </ul>
            <p className="mb-4">Some information may be visible to other users depending on your privacy settings and the functionality of the Services.</p>

            <h4 className="font-semibold text-white mt-4 mb-2">1.3 Identity Verification Information</h4>
            <p className="mb-2">Knot may provide identity verification features designed to improve trust, authenticity, fraud prevention, and platform safety. Where you choose or are required to complete verification, we may collect:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>A selfie or verification photograph</li><li>Images of identity documents</li><li>Information extracted from identity documents</li><li>Verification results</li><li>Information used to compare a selfie with an identity document photograph</li><li>Fraud-prevention and authenticity signals</li>
            </ul>
            <p className="mb-2">Depending on the technology used, identity verification may involve automated systems, artificial intelligence, facial comparison, document analysis, or third-party verification service providers.</p>
            <p className="mb-2">We process verification information for purposes including: confirming that an account is associated with a real person, detecting fraudulent or manipulated identity documents, preventing impersonation, preventing duplicate or fraudulent accounts, protecting users and platform integrity, and determining whether a profile may become publicly visible or receive a verification status.</p>
            <p className="mb-2">Verification does not guarantee that a user is completely safe, truthful, trustworthy, or suitable for a relationship.</p>
            <p className="text-sm italic mb-4">We retain verification information only for as long as reasonably necessary for the purposes described in this Privacy Policy, applicable legal requirements, fraud prevention, dispute resolution, and legitimate platform-safety purposes.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">2. Artificial Intelligence Features</h3>
            <p className="mb-2">Knot may use artificial intelligence and automated technologies to provide certain features.</p>

            <h4 className="font-semibold text-white mt-4 mb-2">2.1 AI Matching and Recommendations</h4>
            <p className="mb-2">Knot may process information such as profile information, preferences, interests, interaction information, compatibility information, and user-provided preferences to generate recommendations, compatibility suggestions, and potential matches.</p>
            <p className="mb-4">AI-generated recommendations are suggestions only. Knot does not guarantee that a recommended person is compatible, trustworthy, safe, truthful, or suitable for a relationship.</p>

            <h4 className="font-semibold text-white mt-4 mb-2">2.2 AI Coach</h4>
            <p className="mb-2">Knot may provide an AI Coach to assist with matters such as profile improvement, communication suggestions, conversation guidance, relationship-related general guidance, dating suggestions, questions about using Knot, and general interpersonal advice.</p>
            <p className="mb-4">The AI Coach is an automated software system. It is not a human being and does not provide professional medical, psychological, legal, financial, or other regulated professional advice. AI responses may be incomplete, inaccurate, outdated, or unsuitable for your particular circumstances. You remain responsible for your own decisions.</p>

            <h4 className="font-semibold text-white mt-4 mb-2">2.3 AI Chat Assistant</h4>
            <p className="mb-2">Knot may provide an AI Chat Assistant that allows users to interact with an artificial intelligence system. The AI Chat Assistant:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Is not a human user</li><li>Is not a romantic partner</li><li>Is not a real member of the Knot community</li><li>Does not represent an actual person</li><li>May generate inaccurate or inappropriate responses</li>
            </ul>
            <p>Information submitted to AI features may be processed by Knot and, where applicable, authorized third-party AI technology providers to generate responses, recommendations, moderation results, or other requested functionality.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">3. Third-Party AI and Technology Providers</h3>
            <p className="mb-2">Knot may use third-party service providers to provide certain technologies, including:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Artificial intelligence services</li><li>Identity verification</li><li>Cloud hosting</li><li>Database infrastructure</li><li>Security services</li><li>Analytics</li><li>Communication services</li><li>Email and SMS services</li><li>Customer support tools</li>
            </ul>
            <p>Where information is sent to a third-party provider, it is processed for the relevant service or business purpose, subject to applicable contractual, technical, and legal safeguards.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">4. Information from Communications and Interactions</h3>
            <p className="mb-2">If you communicate with other users through Knot, we may process information associated with those interactions, including messages, reports, block information, content submitted for moderation, safety complaints, and metadata associated with interactions.</p>
            <p className="mb-2">We may process communications and related information to provide the messaging service, detect fraud and scams, investigate reports, enforce Community Guidelines, prevent harassment/abuse/exploitation/illegal activity, protect users and the platform, and comply with legal obligations.</p>
            <p>We do not guarantee that every harmful, fraudulent, or illegal activity will be detected.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">5. Device and Technical Information</h3>
            <p className="mb-2">When you use Knot, we may automatically collect information such as device type, operating system, app version, IP address, device identifiers, crash information, log information, network information, general location information, usage information, and security and fraud-prevention signals.</p>
            <p>We use this information to operate, secure, improve, and troubleshoot the Services.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">6. Location Information</h3>
            <p className="mb-2">Knot may process location information where you provide it or where it is technically collected with appropriate permission.</p>
            <p className="mb-2">Location information may be used for showing approximate location or distance, improving match recommendations, providing location-related features, security and fraud prevention, and improving the Services.</p>
            <p>We do not publicly display your exact residential address unless you voluntarily provide such information in a manner that makes it visible.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">7. How We Use Information</h3>
            <p className="mb-2">We may use information to:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Create and manage accounts</li><li>Provide matchmaking services</li><li>Generate recommendations</li><li>Provide AI features</li><li>Conduct identity verification</li><li>Prevent fraud and impersonation</li><li>Protect users</li><li>Moderate content and activity</li><li>Process reports and complaints</li><li>Provide customer support</li><li>Improve and develop the Services</li><li>Communicate with users</li><li>Detect security incidents</li><li>Comply with applicable laws</li><li>Enforce our Terms of Service and Community Guidelines</li>
            </ul>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">8. How We Share Information</h3>
            <h4 className="font-semibold text-white mt-4 mb-2">Service Providers</h4>
            <p className="mb-4">Companies that help us operate the Services, including providers of hosting, databases, AI technology, identity verification, security, analytics, communications, and customer support.</p>
            <h4 className="font-semibold text-white mt-4 mb-2">Other Users</h4>
            <p className="mb-4">Information that you choose to place on your public or discoverable profile may be visible to other users.</p>
            <h4 className="font-semibold text-white mt-4 mb-2">Legal and Safety Authorities</h4>
            <p className="mb-4">We may disclose information where we reasonably believe disclosure is necessary to comply with law, respond to valid legal processes, protect users, prevent fraud, investigate suspected criminal conduct, address threats to safety, or protect our rights or property.</p>
            <h4 className="font-semibold text-white mt-4 mb-2">Business Transfers</h4>
            <p className="mb-2">Information may be transferred in connection with a merger, acquisition, restructuring, financing, sale of assets, or similar transaction.</p>
            <p>We do not sell personal information in the ordinary sense of selling user databases to third parties for their independent marketing purposes.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">9. Data Retention</h3>
            <p className="mb-2">We retain information for as long as reasonably necessary for providing the Services, maintaining accounts, safety and fraud prevention, legal compliance, dispute resolution, enforcing agreements, and legitimate business purposes.</p>
            <p>When information is no longer reasonably necessary, we may delete, anonymize, or securely dispose of it, subject to legal, security, and fraud-prevention requirements.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">10. Data Security</h3>
            <p className="mb-2">We use reasonable technical and organizational safeguards designed to protect information from unauthorized access, alteration, disclosure, or destruction.</p>
            <p className="mb-2">However, no internet transmission or storage system can be guaranteed to be completely secure.</p>
            <p>You are responsible for protecting your account credentials and should immediately report suspected unauthorized access.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">11. Your Rights and Choices</h3>
            <p className="mb-2">Depending on applicable law, you may have rights to:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Access personal information</li><li>Request correction of inaccurate information</li><li>Request deletion</li><li>Request restriction of processing</li><li>Object to certain processing</li><li>Request data portability</li><li>Withdraw consent where processing is based on consent</li>
            </ul>
            <p>Some requests may be subject to legal limitations or verification requirements. To exercise applicable rights, contact: <a href="mailto:cleanconnectng@gmail.com" className="text-[#E11D48] hover:underline">cleanconnectng@gmail.com</a></p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">12. Children and Minors</h3>
            <p className="mb-2">Knot is not intended for children or users who are below the minimum age permitted under applicable law.</p>
            <p className="mb-2">We do not knowingly permit children to create accounts or use adult matchmaking services.</p>
            <p className="mb-2">Users must not use Knot to groom minors, exploit minors, facilitate sexual exploitation of minors, contact minors for illegal or abusive purposes, or upload or distribute child sexual abuse material.</p>
            <p>Any suspected child exploitation or abuse may be reported to appropriate authorities where required or permitted by law.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">13. International Data Processing</h3>
            <p className="mb-2">Depending on where our service providers are located, information may be processed in countries other than the country in which you live.</p>
            <p>Where required by applicable law, we will use appropriate safeguards for international transfers.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">14. Third-Party Links and Services</h3>
            <p className="mb-2">Knot may contain links to third-party services.</p>
            <p className="mb-2">We are not responsible for the privacy practices of third-party websites or services that we do not control.</p>
            <p>You should review the privacy policies of third-party services before providing information to them.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">15. Changes to This Privacy Policy</h3>
            <p className="mb-2">We may update this Privacy Policy from time to time.</p>
            <p className="mb-2">When we make material changes, we may provide notice through the Services or other appropriate means.</p>
            <p>The &quot;Last Updated&quot; date indicates when this Privacy Policy was most recently revised.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">16. Contact Us</h3>
            <p className="mb-2">For privacy questions or requests:</p>
            <p className="mb-2">Company: Clean Connect</p>
            <p>Email: <a href="mailto:cleanconnectng@gmail.com" className="text-[#E11D48] hover:underline">cleanconnectng@gmail.com</a></p>
          </section>
        </div>
      </div>
    </div>
  );
}
