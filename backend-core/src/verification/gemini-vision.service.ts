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
  private readonly apiKey =
    process.env.GEMINI_API_KEY || 'AIzaSyByETAV2oLw--t0U2FWsVEtaXbYf_FkfAM';
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

    const prompt = `
You are KNOT Sovereign Registry's Lead AI Fraud Prevention & Identity Verification Officer.
Your mandate is strict: authenticate legitimate marriage candidates and firmly REJECT fraudulent, mismatched, or invalid submissions.

Candidate's Claimed Profile Name: "${claimedFirstName} ${claimedLastName}".
Candidate's Claimed Date of Birth: "${claimedDob || 'Not specified'}".

You are provided with two images:
Image 1: The candidate's uploaded Government-issued ID document (Passport, Driver's License, National ID Card / NIN slip, Voter's Card, or Residence Permit).
Image 2: The candidate's live biometric selfie.

Strictly perform and evaluate these 4 checks:
1. ID Legitimacy: Is Image 1 a real, recognizable government-issued ID (Passport, Driver's License, National ID / NIN slip, Voter's Card, Residence Permit)? Not a random photo, screenshot, piece of paper, or object.
2. Selfie Legitimacy: Is Image 2 a clear, genuine photo of a living human face looking toward the camera?
3. Biometric 1:1 Face Match: Compare the face in Image 2 (selfie) with the portrait photograph on Image 1 (ID). Do they belong to the same person?
4. Strict Legal Name Verification: Read the official name printed on Image 1 (ID). Does it match the candidate's claimed name ("${claimedFirstName} ${claimedLastName}")?
   - CRITICAL: If the name printed on the ID is completely different from the candidate's claimed name (for example, if the ID belongs to someone else), you MUST set "nameMatches": false and "isValid": false.
   - Minor middle name additions or "Lastname, Firstname" ordering differences are acceptable as long as the legal first and last names match the person on the document.

You must respond ONLY with a raw JSON object (no markdown, no backticks, no extra text) with this exact schema:
{
  "isValid": boolean, // true ONLY if all 4 checks pass. false if ANY check fails.
  "documentType": string, // e.g. "INTERNATIONAL_PASSPORT", "DRIVERS_LICENSE", "NATIONAL_ID_NIN", "VOTERS_CARD", "UNKNOWN"
  "confidenceScore": number, // 0 to 100
  "extractedName": string, // The exact full name as printed on the ID document
  "extractedDob": string, // DOB from the ID or empty string if not visible
  "faceMatchScore": number, // 0 to 100 estimated face similarity
  "livenessScore": number, // 0 to 100
  "nameMatches": boolean, // true if the name on the ID corresponds to the claimed candidate name
  "faceMatches": boolean, // true if the selfie face matches the ID photo
  "isGovernmentId": boolean, // true if Image 1 is a valid government ID
  "isSelfieValid": boolean, // true if Image 2 is a valid selfie
  "details": string // Clear explanation of your findings. If failed, specify why (e.g. name mismatch or biometric mismatch).
}
`;

    try {
      this.logger.log(
        `Invoking Gemini Vision AI to verify ID and selfie for candidate "${claimedFirstName} ${claimedLastName}"`,
      );

      const response = await axios.post(
        this.baseUrl,
        {
          model: 'gemini-2.5-flash',
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
          timeout: 40000,
        },
      );

      const rawContent = response.data?.choices?.[0]?.message?.content || '{}';
      const cleanJson = this.cleanJsonResponse(rawContent);
      const parsed = JSON.parse(cleanJson);

      // Programmatic double-check on name matching
      const extractedName = (parsed.extractedName || '').trim();
      const claimedFullName = `${claimedFirstName} ${claimedLastName}`.trim();
      const programmaticNameMatch = this.checkNameConsistency(
        claimedFirstName,
        claimedLastName,
        extractedName,
      );

      const finalNameMatch = parsed.nameMatches && programmaticNameMatch;
      const finalIsValid =
        Boolean(parsed.isValid) &&
        Boolean(parsed.faceMatches) &&
        Boolean(parsed.isGovernmentId) &&
        Boolean(parsed.isSelfieValid) &&
        finalNameMatch;

      this.logger.log(
        `Gemini Vision Result for "${claimedFullName}": Valid=${finalIsValid}, ExtractedName="${extractedName}", NameMatch=${finalNameMatch}, FaceMatch=${parsed.faceMatches}`,
      );

      return {
        isValid: finalIsValid,
        documentType: parsed.documentType || 'GOVERNMENT_ID',
        confidenceScore: parsed.confidenceScore || (finalIsValid ? 95 : 25),
        extractedName: extractedName || claimedFullName,
        extractedDob: parsed.extractedDob || '',
        faceMatchScore: parsed.faceMatchScore || (parsed.faceMatches ? 94 : 30),
        livenessScore: parsed.livenessScore || (parsed.isSelfieValid ? 96 : 30),
        nameMatches: finalNameMatch,
        faceMatches: Boolean(parsed.faceMatches),
        isGovernmentId: Boolean(parsed.isGovernmentId),
        isSelfieValid: Boolean(parsed.isSelfieValid),
        details:
          parsed.details ||
          (finalIsValid
            ? 'Identity and biometrics verified by Gemini Vision AI.'
            : 'Verification failed authenticity or name match checks.'),
      };
    } catch (error: any) {
      this.logger.error(
        `Gemini Vision verification error: ${error.response?.data?.error?.message || error.message}`,
      );
      throw error;
    }
  }

  /**
   * Programmatic token matching to ensure candidate name is contained in the extracted ID name
   */
  private checkNameConsistency(
    firstName: string,
    lastName: string,
    extractedName: string,
  ): boolean {
    if (!extractedName || extractedName.length < 2) return false;
    const lowerExtracted = extractedName.toLowerCase();
    const f = firstName.trim().toLowerCase();
    const l = lastName.trim().toLowerCase();

    // Both first and last name (or a significant part of them) must appear in the extracted ID name
    const hasFirst = f.length > 2 ? lowerExtracted.includes(f) : true;
    const hasLast = l.length > 2 ? lowerExtracted.includes(l) : true;

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
