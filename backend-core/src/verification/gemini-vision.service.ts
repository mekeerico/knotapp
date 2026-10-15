import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

export interface GeminiVerificationResult {
  isValid: boolean;
  documentType: string;
  confidenceScore: number;
  extractedName: string;
  extractedDob: string;
  faceMatchScore: number;
  livenessScore: number;
  nameMatches: boolean;
  faceMatches: boolean;
  isGovernmentId: boolean;
  isSelfieValid: boolean;
  details: string;
}

@Injectable()
export class GeminiVisionService {
  private readonly logger = new Logger(GeminiVisionService.name);
  
  private get apiKey(): string {
    return process.env.GEMINI_API_KEY || '';
  }

  private readonly baseUrl =
    'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions';

  /**
   * Verify government ID, live selfie, face matching, and name consistency using Gemini Vision AI
   */
  async verifyWithGeminiVision(
    idBuffer: Buffer,
    selfieBuffer: Buffer,
    claimedFirstName: string,
    claimedLastName: string,
    claimedDob?: string,
  ): Promise<GeminiVerificationResult> {
    const idBase64 = idBuffer.toString('base64');
    const selfieBase64 = selfieBuffer.toString('base64');
    const claimedFullName = `${claimedFirstName} ${claimedLastName}`.trim();

    const prompt = `
You are KNOT Sovereign Registry's Lead AI Fraud Prevention & Identity Verification Officer.
Your mandate is strict: authenticate legitimate marriage candidates and firmly REJECT fraudulent, spoofed, or mismatched submissions.

Candidate's Claimed Profile Name: "${claimedFirstName} ${claimedLastName}".
Candidate's Claimed Date of Birth: "${claimedDob || 'Not specified'}".

You are provided with two images:
Image 1: The candidate's uploaded Government-issued ID document.
Image 2: The candidate's live biometric selfie.

CRITICAL DOCUMENT VERIFICATION RULES:
1. SPECIALIZED RECOGNITION FOR NIGERIAN NATIONAL ID (NIN) & AFRICAN/GLOBAL DOCUMENTS:
   - You MUST fully recognize and accept Nigerian National Identification Number (NIN) documents in ALL official formats:
     a) NIMC National Identity Card (plastic card with coat of arms, photo, NIN, names).
     b) NIMC National Identification Number Slip (NINS / NIN Slip, green/blue header, "FEDERAL REPUBLIC OF NIGERIA", "NATIONAL IDENTITY MANAGEMENT COMMISSION", Surname, First Name, Middle Name, 11-digit NIN number, Tracking ID, and photo).
     c) Federal Republic of Nigeria Driver's License (FRSC).
     d) Nigerian International Passport.
     e) Independent National Electoral Commission (INEC) Voter's Card (PVC).
   - Also accept all legitimate International Passports, National ID Cards, Driver's Licenses, and Residence Permits from ALL sovereign countries.
   - REJECT only if Image 1 is completely unreadable, a blank paper, a cartoon, an animal/object, a meme, or a handwritten note.

2. BIOMETRIC 1:1 FACE MATCH:
   - Compare the face in Image 2 (live selfie) with the portrait photograph on Image 1 (ID/NIN).
   - Account for standard variations in lighting, selfie angle, expression, or slight age difference.
   - If they are clearly the same human being, set "faceMatches": true.
   - If the faces belong to two clearly different individuals, set "faceMatches": false and "isValid": false.

3. STRICT LEGAL NAME VERIFICATION:
   - Read the official Surname/Last Name and First/Given Name printed on Image 1 (ID/NIN).
   - Check if they correspond to the candidate's registered name ("${claimedFirstName} ${claimedLastName}").
   - ACCEPT standard name permutations:
     a) Surname first or Lastname first (e.g., Nigerian documents typically list "SURNAME: [LastName], FIRST NAME: [FirstName]").
     b) Middle names included on the ID that the candidate omitted in their profile (e.g. ID has "Meke Eric Chukwudi" while profile is "Eric Meke").
     c) Minor spelling or typographical differences.
   - REJECT if the name on the ID belongs to an entirely different person (e.g. ID name is "Oluwaseun Adeyemi" but profile is "Emeka Okafor").

You must respond ONLY with a raw JSON object (no markdown, no backticks, no extra text) with this exact schema:
{
  "isValid": boolean, // true ONLY if all checks pass. false if ANY check fails.
  "documentType": string, // "NATIONAL_ID_NIN", "INTERNATIONAL_PASSPORT", "DRIVERS_LICENSE", "VOTERS_CARD", "RESIDENCE_PERMIT", or "UNKNOWN"
  "confidenceScore": number, // 0 to 100
  "extractedName": string, // The exact full name as printed on the ID document
  "extractedDob": string, // DOB from the ID or empty string if not visible
  "faceMatchScore": number, // 0 to 100 estimated face similarity
  "livenessScore": number, // 0 to 100
  "nameMatches": boolean, // true if the name on the ID corresponds to the claimed candidate name
  "faceMatches": boolean, // true if the selfie face matches the ID photo
  "isGovernmentId": boolean, // true if Image 1 is a valid government ID or NIN
  "isSelfieValid": boolean, // true if Image 2 is a valid selfie
  "details": string // Clear explanation of your findings. If failed, specify why.
}
`;

    // Try primary model gemini-3.5-flash first, then fallback to gemini-3.5-flash-lite
    const modelsToTry = ['gemini-3.5-flash', 'gemini-3.5-flash-lite'];

    for (const model of modelsToTry) {
      try {
        this.logger.log(
          `Invoking Gemini Vision AI (${model}) for candidate "${claimedFullName}"`,
        );

        const response = await axios.post(
          this.baseUrl,
          {
            model,
            messages: [
              {
                role: 'user',
                content: [
                  { type: 'text', text: prompt },
                  {
                    type: 'image_url',
                    image_url: { url: `data:image/jpeg;base64,${idBase64}` },
                  },
                  {
                    type: 'image_url',
                    image_url: { url: `data:image/jpeg;base64,${selfieBase64}` },
                  },
                ],
              },
            ],
            temperature: 0.1,
          },
          {
            headers: {
              Authorization: `Bearer ${this.apiKey}`,
              'Content-Type': 'application/json',
            },
            timeout: 45000,
          },
        );

        const rawContent = response.data?.choices?.[0]?.message?.content || '{}';
        const cleanJson = this.cleanJsonResponse(rawContent);
        const parsed = JSON.parse(cleanJson);

        const extractedName = (parsed.extractedName || '').trim();
        const programmaticNameMatch = this.checkNameConsistency(
          claimedFirstName,
          claimedLastName,
          extractedName,
        );

        // Both the AI judgement and the programmatic token check must agree
        const finalNameMatch = Boolean(parsed.nameMatches) && programmaticNameMatch;
        const finalFaceMatch = Boolean(parsed.faceMatches) && (parsed.faceMatchScore ?? 80) >= 65;
        const finalIsGovId = Boolean(parsed.isGovernmentId);
        const finalIsSelfie = Boolean(parsed.isSelfieValid);

        const finalIsValid =
          finalIsGovId &&
          finalIsSelfie &&
          finalNameMatch &&
          finalFaceMatch;

        this.logger.log(
          `Gemini Vision (${model}) Result for "${claimedFullName}": Valid=${finalIsValid}, ExtractedName="${extractedName}", NameMatch=${finalNameMatch}, FaceMatch=${finalFaceMatch}`,
        );

        return {
          isValid: finalIsValid,
          documentType: parsed.documentType || 'NATIONAL_ID_NIN',
          confidenceScore: parsed.confidenceScore || (finalIsValid ? 96 : 30),
          extractedName: extractedName || claimedFullName,
          extractedDob: parsed.extractedDob || '',
          faceMatchScore: parsed.faceMatchScore || (finalFaceMatch ? 92 : 35),
          livenessScore: parsed.livenessScore || (finalIsSelfie ? 95 : 35),
          nameMatches: finalNameMatch,
          faceMatches: finalFaceMatch,
          isGovernmentId: finalIsGovId,
          isSelfieValid: finalIsSelfie,
          details:
            parsed.details ||
            (finalIsValid
              ? 'Identity document and biometric match successfully verified.'
              : 'Document verification failed legal name or facial match requirements.'),
        };
      } catch (err: any) {
        this.logger.warn(
          `Gemini Vision model ${model} failed (${err.response?.status || err.message}). Attempting fallback.`,
        );
      }
    }

    // Fail closed: never auto-approve identity when the AI checker could not run.
    this.logger.error(
      `Gemini Vision unavailable for candidate "${claimedFullName}". Verification NOT approved.`,
    );
    throw new Error(
      'Our identity checker is temporarily busy. Your documents were not rejected — please retry in a few minutes.',
    );
  }

  /**
   * Flexible token-based name matching supporting reverse order (e.g. SURNAME, Firstname)
   * and middle names.
   */
  private checkNameConsistency(
    firstName: string,
    lastName: string,
    extractedName: string,
  ): boolean {
    if (!extractedName || extractedName.length < 2) return false;
    const lowerExtracted = extractedName.toLowerCase().replace(/[^a-z0-9 ]/g, ' ');
    const f = firstName.trim().toLowerCase().replace(/[^a-z0-9 ]/g, '');
    const l = lastName.trim().toLowerCase().replace(/[^a-z0-9 ]/g, '');

    const extractedTokens = lowerExtracted.split(/\s+/).filter(t => t.length > 1);

    // Exact token match, any order (handles "SURNAME Firstname Middlename" layouts)
    const hasFirst = f.length < 2 || extractedTokens.includes(f);
    const hasLast = l.length < 2 || extractedTokens.includes(l);

    return hasFirst && hasLast;
  }

  private cleanJsonResponse(text: string): string {
    let clean = text.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }
}
