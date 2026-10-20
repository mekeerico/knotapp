import React from 'react';
import Link from 'next/link';

export default function CommunityGuidelinesPage() {
  return (
    <div className="min-h-screen bg-[#0A0D14] text-white p-8 md:p-16 font-sans">
      <div className="max-w-4xl mx-auto bg-[#121721] p-8 md:p-12 rounded-2xl shadow-xl border border-[#2A3143]">
        <Link href="/" className="inline-flex items-center gap-2 text-sm text-gray-400 hover:text-[#E11D48] transition-colors mb-8">
          <span>←</span> Back to Home
        </Link>
        <h1 className="text-3xl md:text-5xl font-bold text-[#E11D48] mb-4 text-center">
          Community Guidelines & Safety Standards
        </h1>
        <p className="text-center text-gray-500 mb-12">Last Updated: July 17, 2026</p>

        <div className="space-y-10 text-gray-300 leading-relaxed">
          <p>Knot is designed to help people connect in a respectful, authentic, and safer environment.</p>
          <p>These Community Guidelines apply to all users, profiles, messages, photographs, interactions, and content on Knot.</p>
          <p>Violations may result in content removal, account restrictions, suspension, permanent termination, or referral to appropriate authorities where necessary.</p>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">1. Be Authentic</h3>
            <p className="mb-2">Users must:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Use their real identity;</li><li>Use recent and authentic photographs;</li><li>Provide truthful information;</li><li>Accurately represent their age;</li><li>Avoid impersonation;</li><li>Avoid creating fake accounts;</li><li>Avoid creating accounts for other people without authorization.</li>
            </ul>
            <p>You must not use another person&apos;s photographs or identity to mislead users.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">2. Respect Other Users</h3>
            <p className="mb-2">Treat other people with respect. Prohibited conduct includes:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Harassment</li><li>Threats</li><li>Bullying</li><li>Intimidation</li><li>Stalking</li><li>Persistent unwanted contact</li><li>Abusive or degrading conduct</li><li>Targeted humiliation</li><li>Blackmail</li><li>Extortion</li>
            </ul>
            <p>A user may block or report another user at any time.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">3. No Fraud or Scams</h3>
            <p className="mb-2">Knot must not be used to:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Request money through deception;</li><li>Run investment scams;</li><li>Promote fake financial opportunities;</li><li>Impersonate officials or organizations;</li><li>Obtain passwords or financial information fraudulently;</li><li>Manipulate users for financial gain;</li><li>Conduct romance scams;</li><li>Promote fraudulent schemes.</li>
            </ul>
            <p className="mb-2">Users should be extremely cautious if another user:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Quickly asks for money;</li><li>Claims to have an emergency;</li><li>Requests cryptocurrency or financial transfers;</li><li>Requests banking information;</li><li>Avoids video or other reasonable identity confirmation;</li><li>Pressures you to move to another platform immediately.</li>
            </ul>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">4. No Illegal Activities</h3>
            <p className="mb-2">Users may not use Knot to:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Promote criminal activity;</li><li>Buy or sell illegal goods;</li><li>Facilitate trafficking;</li><li>Promote terrorism;</li><li>Promote violent criminal activity;</li><li>Facilitate fraud;</li><li>Promote illegal drugs;</li><li>Arrange illegal services;</li><li>Engage in other unlawful conduct.</li>
            </ul>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">5. Sexual Exploitation and Minor Safety</h3>
            <p className="mb-2">Knot does not tolerate:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Sexual exploitation of minors;</li><li>Grooming;</li><li>Sexual solicitation involving minors;</li><li>Child sexual abuse material;</li><li>Sexual trafficking;</li><li>Sexual coercion;</li><li>Sexual blackmail;</li><li>Attempts to arrange sexual exploitation.</li>
            </ul>
            <p>Users must not use Knot to target, exploit, groom, or sexually abuse minors. We may take immediate action and report suspected child exploitation or abuse to appropriate authorities where required or appropriate.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">6. Sexual Content and Services</h3>
            <p className="mb-2">Users must not use Knot to:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Solicit prostitution;</li><li>Promote sexual services;</li><li>Arrange sexual exploitation;</li><li>Share intimate content without consent;</li><li>Threaten to distribute intimate content;</li><li>Use sexual content to harass or exploit another person.</li>
            </ul>
            <p>Users should respect consent and personal boundaries.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">7. Hate and Discriminatory Abuse</h3>
            <p className="mb-2">Knot does not permit targeted abuse or threats against people based on protected characteristics.</p>
            <p className="mb-2">Content intended to promote hatred, dehumanization, violence, or targeted abuse is prohibited.</p>
            <p>Respectful discussion of differences is not the same as targeted harassment or hate-based abuse.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">8. AI Safety and Transparency</h3>
            <p className="mb-2">Knot&apos;s AI Coach and AI Chat Assistant are artificial intelligence features. They are not human users, real romantic partners, or real members of the Knot community.</p>
            <p className="mb-2">Users must not:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Present AI-generated content as the identity of a real person;</li><li>Use AI to impersonate another person;</li><li>Use AI to create scams;</li><li>Use AI to manipulate users for fraud;</li><li>Use AI to generate prohibited abusive content;</li><li>Use AI to circumvent safety systems;</li><li>Use AI to facilitate illegal activities.</li>
            </ul>
            <p>AI-generated advice may be inaccurate and should be assessed using independent judgment.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">9. Authentic Photographs and Content</h3>
            <p className="mb-2">Users must not upload:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Stolen photographs;</li><li>Impersonation content;</li><li>Fraudulent identity documents;</li><li>Misleading identity materials;</li><li>Content designed to deceive users.</li>
            </ul>
            <p>Manipulated or AI-generated images may not be used to impersonate a real person or mislead others about identity.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">10. Privacy and Personal Information</h3>
            <p className="mb-2">Do not publish another person&apos;s private information without authorization. This includes:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Home addresses;</li><li>Private telephone numbers;</li><li>Passwords;</li><li>Financial information;</li><li>Private identity documents;</li><li>Private communications;</li><li>Sensitive personal information.</li>
            </ul>
            <p>Do not attempt to obtain another user&apos;s personal information through deception or unauthorized means.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">11. Safe Meetings</h3>
            <p className="mb-2">If you decide to meet someone you met through Knot:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Take reasonable precautions;</li><li>Consider meeting in an appropriate public place;</li><li>Tell someone you trust about your plans;</li><li>Avoid sharing unnecessary sensitive information;</li><li>Do not send money to someone you have only met online;</li><li>Leave if you feel unsafe or pressured.</li>
            </ul>
            <p>Knot cannot guarantee the safety or conduct of any user.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">12. Reporting and Blocking</h3>
            <p className="mb-2">If you believe that a user or content violates these Guidelines, use the available reporting tools.</p>
            <p className="mb-2">Reports may relate to: fraud, harassment, threats, impersonation, illegal activity, exploitation, suspicious conduct, safety concerns, or prohibited content.</p>
            <p className="mb-2">You may block users whose communications or conduct you do not wish to receive.</p>
            <p>Knot may investigate reports using automated systems, AI-assisted systems, human review, or a combination of methods.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">13. Enforcement</h3>
            <p className="mb-2">Depending on the circumstances, enforcement may include:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Warning;</li><li>Content removal;</li><li>Reduced visibility;</li><li>Feature restrictions;</li><li>Required identity verification;</li><li>Temporary suspension;</li><li>Permanent account termination;</li><li>Preservation of relevant information;</li><li>Referral to law enforcement or other authorities where appropriate.</li>
            </ul>
            <p className="mb-2">The severity of enforcement may depend on the seriousness of the violation, whether the conduct was repeated, whether a user attempted to evade enforcement, whether another person&apos;s safety was threatened, and applicable legal requirements.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">14. False Reports and Abuse of Safety Systems</h3>
            <p className="mb-2">Users must not knowingly submit false reports designed to harass, defraud, or improperly remove another user.</p>
            <p>However, users are encouraged to report genuine safety concerns in good faith.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">15. Our Safety Approach</h3>
            <p className="mb-2">Knot may use a combination of:</p>
            <ul className="list-disc pl-6 mb-4 space-y-1">
              <li>Identity verification;</li><li>Automated systems;</li><li>Artificial intelligence;</li><li>Human review;</li><li>User reports;</li><li>Account security controls;</li><li>Content moderation;</li><li>Fraud-prevention systems.</li>
            </ul>
            <p>No safety system can prevent every harmful action. Users should continue to exercise reasonable judgment and personal safety precautions.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">16. Changes to These Guidelines</h3>
            <p>We may update these Guidelines as the Services, technology, laws, and safety risks evolve. Continued use of Knot after updated Guidelines take effect may constitute acceptance of the updated rules where permitted by law.</p>
          </section>

          <section className="mb-6">
            <h3 className="text-xl font-semibold text-[#E11D48] mb-2">17. Contact and Reporting</h3>
            <p className="mb-2">For safety concerns or policy questions:</p>
            <p className="mb-2">Company: Clean Connect</p>
            <p className="mb-4">Email: <a href="mailto:cleanconnectng@gmail.com" className="text-[#E11D48] hover:underline">cleanconnectng@gmail.com</a></p>
            <p className="text-sm italic">If you are in immediate danger, contact the appropriate emergency services in your location.</p>
          </section>
        </div>
      </div>
    </div>
  );
}
