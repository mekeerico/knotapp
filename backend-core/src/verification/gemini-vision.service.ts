import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

export interface GeminiVerificationResult {
  isValid: boolean;
  documentType: string;
  selectedDocumentCategory: string;
  documentTypeMatches: boolean;
  confidenceScore: number;
  extractedName: string;
  extractedIdNumber: string;
  hasValidIdNumber: boolean;
  extractedDob: string;
  hasExpiryDate: boolean;
  extractedExpiryDate: string;
  isExpired: boolean;
  estimatedSelfieAge: number;
  ageMatches: boolean;
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
   * Normalize human-readable or raw document type strings into canonical categories:
   * NATIONAL_ID_NIN | INTERNATIONAL_PASSPORT | DRIVERS_LICENSE | VOTERS_CARD | RESIDENCE_PERMIT | UNKNOWN
   */
  normalizeDocumentCategory(raw?: string): string {
    const val = (raw || '').toUpperCase().trim();
    if (!val) return '';
    // IMPORTANT: Check 'PASS' BEFORE 'NATIONAL' because "INTERNATIONAL_PASSPORT" contains "NATIONAL"!
    if (val.includes('PASS')) {
      return 'INTERNATIONAL_PASSPORT';
    }
    if (val.includes('DRIV') || val.includes('LICEN') || val.includes('FRSC')) {
      return 'DRIVERS_LICENSE';
    }
    if (val.includes('VOTE') || val.includes('PVC') || val.includes('INEC')) {
      return 'VOTERS_CARD';
    }
    if (
      val.includes('RESID') ||
      val.includes('PERMIT') ||
      val.includes('GREEN CARD') ||
      val.includes('STATE ID') ||
      val.includes('STATE_ID')
    ) {
      return 'RESIDENCE_PERMIT';
    }
    if (val.includes('NIN') || val.includes('NATIONAL') || val.includes('NIMC')) {
      return 'NATIONAL_ID_NIN';
    }
    return 'UNKNOWN';
  }

  humanDocumentLabel(category: string): string {
    switch (category) {
      case 'NATIONAL_ID_NIN':
        return 'National ID (NIN)';
      case 'INTERNATIONAL_PASSPORT':
        return 'International Passport';
      case 'DRIVERS_LICENSE':
        return "Driver's License";
      case 'VOTERS_CARD':
        return "Voter's Card (PVC)";
      case 'RESIDENCE_PERMIT':
        return 'Residence Permit / State ID';
      default:
        return 'Unrecognized Document';
    }
  }

  /**
   * Multi-factor AI Vision KYC check:
   * 1. Document Type Recognition & Match against user-selected document type
   * 2. Official ID / Document Number extraction & legibility check
   * 3. Expiration Date extraction & strict non-expired enforcement
   * 4. Strict Legal Name verification against onboarding profile
   * 5. 1:1 Biometric Face Match between ID portrait and live selfie
   * 6. Age / Date of Birth consistency between ID, profile DOB, and live selfie
   */
  async verifyWithGeminiVision(
    idBuffer: Buffer,
    selfieBuffer: Buffer,
    claimedFirstName: string,
    claimedLastName: string,
    claimedDob?: string,
    selectedDocumentType?: string,
  ): Promise<GeminiVerificationResult> {
    const idBase64 = idBuffer.toString('base64');
    const selfieBase64 = selfieBuffer.toString('base64');
    const claimedFullName = `${claimedFirstName} ${claimedLastName}`.trim();
    const expectedCategory = this.normalizeDocumentCategory(selectedDocumentType);
    const todayIso = new Date().toISOString().split('T')[0];

    const prompt = `
You are KNOT Sovereign Registry's Lead AI Fraud Prevention & Biometric Identity Verification Officer.
Today's Current Date (ISO): "${todayIso}".

Candidate's Claimed Profile Name: "${claimedFirstName} ${claimedLastName}".
Candidate's Claimed Date of Birth: "${claimedDob || 'Not specified'}".
Candidate's Selected Document Type in App: "${selectedDocumentType || 'Not specified'}" (Canonical Category: "${expectedCategory || 'ANY'}").

You are provided with two images:
- Image 1: The candidate's uploaded Government ID document.
- Image 2: The candidate's live biometric selfie.

PERFORM ALL 6 MANDATORY VERIFICATION CHECKS STRICTLY:

1. EXACT DOCUMENT CLASSIFICATION & SELECTED TYPE MATCH:
   - Identify what type of document Image 1 ACTUALLY is and set "documentType" to EXACTLY ONE of:
     * "INTERNATIONAL_PASSPORT" — International Passport booklet or bio-data page (says "PASSPORT" / "PASSEPORT", has Passport No., Date of Issue, Date of Expiry, or Machine Readable Zone lines starting with "P<").
       CRITICAL NOTE FOR PASSPORTS: Many modern passports (such as Nigerian e-Passports) also print the holder's NIN / Personal Number on the passport bio-data page. If the document is a Passport bio-data page, you MUST classify it as "INTERNATIONAL_PASSPORT" — NEVER classify a Passport page as "NATIONAL_ID_NIN"!
     * "NATIONAL_ID_NIN" — Standalone National Identity Card (NIMC card) OR standalone NIMC National Identification Number (NIN) Slip (with 11-digit NIN and Tracking ID, NOT a passport booklet).
     * "DRIVERS_LICENSE" — Official Driver's License (FRSC or national/state driver's license).
     * "VOTERS_CARD" — Official Voter's Card / INEC Permanent Voter's Card (PVC) with VIN.
     * "RESIDENCE_PERMIT" — Official Residence Permit, Green Card, Biometric Residence Permit, or State ID Card.
     * "UNKNOWN" — If Image 1 is not one of the 5 official government ID categories above.
   - Compare "documentType" with the Candidate's Selected Document Category ("${expectedCategory}").
   - Set "documentTypeMatches": true ONLY if "documentType" === "${expectedCategory}" (or if "${expectedCategory}" is empty). Otherwise set "documentTypeMatches": false and "isValid": false.

2. OFFICIAL ID / DOCUMENT NUMBER EXTRACTION ("extractedIdNumber" & "hasValidIdNumber"):
   - Locate and transcribe the primary official document number printed on Image 1:
     * For INTERNATIONAL_PASSPORT: Passport Number (e.g. A01234567, B12345678).
     * For NATIONAL_ID_NIN: 11-digit NIN (or national ID number).
     * For DRIVERS_LICENSE: License Number.
     * For VOTERS_CARD: Voter Identification Number (VIN).
     * For RESIDENCE_PERMIT: Permit / Card Number.
   - If the ID number is missing, covered, or unreadable, set "hasValidIdNumber": false and "isValid": false.

3. EXPIRATION DATE VERIFICATION ("hasExpiryDate", "extractedExpiryDate", "isExpired"):
   - Carefully read the expiration date on Image 1 from BOTH:
     a) The printed field ("Date of Expiry", "Date d'expiration", "Expiry Date", "Valid Until", "EXP"), e.g. "14 MAY 2022" or "14 MAY/MAI 22".
     b) For an INTERNATIONAL_PASSPORT, ALSO check the 2nd MRZ line at the bottom (positions 22-27 immediately after the sex 'M'/'F' character encode the expiry date as YYMMDD).
   - Convert the expiration date you read into strict "YYYY-MM-DD" format and place it in "extractedExpiryDate" (for example, "14 MAY 2022" or "14 MAY/MAI 22" -> "2022-05-14").
   - Note:
     * INTERNATIONAL_PASSPORT, DRIVERS_LICENSE, and RESIDENCE_PERMIT ALWAYS have an expiration date ("hasExpiryDate": true).
     * Standalone Nigerian NIN Slips and INEC Voter's Cards (PVC) generally do NOT have an expiration date ("hasExpiryDate": false, "extractedExpiryDate": "", "isExpired": false).
   - Compare "extractedExpiryDate" against Today's Date ("${todayIso}"):
     * If "extractedExpiryDate" is earlier than "${todayIso}", the document is EXPIRED! You MUST set "isExpired": true and "isValid": false!
     * For an INTERNATIONAL_PASSPORT or DRIVERS_LICENSE, if the expiration date is cut off, blurred, or cannot be read, set "isExpired": true and "isValid": false.

4. STRICT LEGAL NAME VERIFICATION ("extractedName" & "nameMatches"):
   - Transcribe the full legal name printed on Image 1 into "extractedName".
   - Verify whether it matches "${claimedFirstName} ${claimedLastName}" (allowing Surname-first or Firstname-first order and additional middle names on the ID).
   - If the name on the ID belongs to a different person, set "nameMatches": false and "isValid": false.

5. STRICT 1:1 BIOMETRIC FACE MATCH ("faceMatches" & "faceMatchScore"):
   - Compare the portrait photograph on the ID document (Image 1) with the live selfie (Image 2).
   - Examine facial bone structure, eye spacing, nose shape, mouth, ears, and gender.
   - Only if you are confident both images show the EXACT SAME human being, set "faceMatches": true and provide a "faceMatchScore" >= 75.
   - If they appear to be different people, set "faceMatches": false, "faceMatchScore" < 60, and "isValid": false.

6. AGE & DATE OF BIRTH CONSISTENCY ("extractedDob", "estimatedSelfieAge", "ageMatches"):
   - Read the Date of Birth on the ID into "extractedDob" (in "YYYY-MM-DD" format if visible).
   - Estimate the visual age of the person in the live selfie (Image 2) as an integer in "estimatedSelfieAge".
   - Check that:
     a) The person in the selfie looks reasonably close in age to the person born on "extractedDob" (within ~12 years).
     b) If the candidate's claimed profile DOB ("${claimedDob || ''}") is provided and valid, the birth year on the ID must match the claimed birth year (within ±1 year).
   - If the ID's DOB/age conflicts with the profile DOB or the selfie person's apparent age, set "ageMatches": false and "isValid": false.

Respond ONLY with a raw JSON object (no markdown, no backticks) matching this exact schema:
{
  "isValid": boolean,
  "documentType": "NATIONAL_ID_NIN" | "INTERNATIONAL_PASSPORT" | "DRIVERS_LICENSE" | "VOTERS_CARD" | "RESIDENCE_PERMIT" | "UNKNOWN",
  "documentTypeMatches": boolean,
  "confidenceScore": number,
  "extractedName": string,
  "extractedIdNumber": string,
  "hasValidIdNumber": boolean,
  "extractedDob": string,
  "hasExpiryDate": boolean,
  "extractedExpiryDate": string,
  "isExpired": boolean,
  "estimatedSelfieAge": number,
  "ageMatches": boolean,
  "faceMatchScore": number,
  "livenessScore": number,
  "nameMatches": boolean,
  "faceMatches": boolean,
  "isGovernmentId": boolean,
  "isSelfieValid": boolean,
  "details": string
}
`;

    const modelsToTry = ['gemini-3.5-flash', 'gemini-3.5-flash-lite'];

    for (const model of modelsToTry) {
      try {
        this.logger.log(
          `Invoking Gemini Vision AI (${model}) for "${claimedFullName}", expectedDoc="${expectedCategory}"`,
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
            temperature: 0.0,
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

        const detectedDocType = this.normalizeDocumentCategory(parsed.documentType) || 'UNKNOWN';
        const extractedName = (parsed.extractedName || '').trim();
        const extractedIdNumber = (parsed.extractedIdNumber || '').trim();
        const extractedDob = (parsed.extractedDob || '').trim();
        const rawExpiry = (parsed.extractedExpiryDate || '').trim();
        const normalizedExpiry = this.normalizeDateString(rawExpiry) || rawExpiry;

        const programmaticNameMatch = this.checkNameConsistency(
          claimedFirstName,
          claimedLastName,
          extractedName,
        );

        // 1. Government ID check
        const finalIsGovId = Boolean(parsed.isGovernmentId) && detectedDocType !== 'UNKNOWN';

        // 2. Document type matches user selection
        const finalDocTypeMatches =
          !expectedCategory ||
          expectedCategory === 'UNKNOWN' ||
          detectedDocType === expectedCategory;

        // 3. Valid ID number check
        const finalHasIdNumber =
          Boolean(parsed.hasValidIdNumber) && extractedIdNumber.replace(/[^a-zA-Z0-9]/g, '').length >= 5;

        // 4. Expiration check (programmatic + AI)
        const requiresExpiry =
          detectedDocType === 'INTERNATIONAL_PASSPORT' ||
          detectedDocType === 'DRIVERS_LICENSE';
        const programmaticExpired = this.isDateExpired(normalizedExpiry);
        const missingRequiredExpiry = requiresExpiry && !normalizedExpiry;
        const finalIsExpired =
          Boolean(parsed.isExpired) || programmaticExpired || missingRequiredExpiry;

        // 5. Name match
        const finalNameMatch = Boolean(parsed.nameMatches) && programmaticNameMatch;

        // 6. Face match (strict >= 75%)
        const faceScore = typeof parsed.faceMatchScore === 'number' ? parsed.faceMatchScore : 0;
        const finalFaceMatch = Boolean(parsed.faceMatches) && faceScore >= 75;

        // 7. Age & DOB match
        const programmaticDobMatch = this.checkDobConsistency(claimedDob, extractedDob);
        const finalAgeMatch = Boolean(parsed.ageMatches ?? true) && programmaticDobMatch;

        // 8. Selfie validity
        const finalIsSelfie = Boolean(parsed.isSelfieValid);

        const finalIsValid =
          finalIsGovId &&
          finalDocTypeMatches &&
          finalHasIdNumber &&
          !finalIsExpired &&
          finalIsSelfie &&
          finalNameMatch &&
          finalFaceMatch &&
          finalAgeMatch;

        this.logger.log(
          `Gemini Vision (${model}) for "${claimedFullName}": Valid=${finalIsValid}, Selected=${expectedCategory}, Detected=${detectedDocType}, DocMatch=${finalDocTypeMatches}, IDNo="${extractedIdNumber}", Expiry="${normalizedExpiry}", Expired=${finalIsExpired}, NameMatch=${finalNameMatch}, FaceMatch=${finalFaceMatch} (${faceScore}%), AgeMatch=${finalAgeMatch}`,
        );

        return {
          isValid: finalIsValid,
          documentType: detectedDocType,
          selectedDocumentCategory: expectedCategory,
          documentTypeMatches: finalDocTypeMatches,
          confidenceScore: parsed.confidenceScore || (finalIsValid ? 96 : 30),
          extractedName,
          extractedIdNumber,
          hasValidIdNumber: finalHasIdNumber,
          extractedDob,
          hasExpiryDate: Boolean(parsed.hasExpiryDate) || Boolean(normalizedExpiry),
          extractedExpiryDate: normalizedExpiry,
          isExpired: finalIsExpired,
          estimatedSelfieAge: parsed.estimatedSelfieAge || 0,
          ageMatches: finalAgeMatch,
          faceMatchScore: faceScore,
          livenessScore: parsed.livenessScore || (finalIsSelfie ? 95 : 35),
          nameMatches: finalNameMatch,
          faceMatches: finalFaceMatch,
          isGovernmentId: finalIsGovId,
          isSelfieValid: finalIsSelfie,
          details:
            parsed.details ||
            (finalIsValid
              ? 'Identity document, ID number, expiration date, age, and biometric face match verified.'
              : 'Document verification failed one or more security checks.'),
        };
      } catch (err: any) {
        this.logger.warn(
          `Gemini Vision model ${model} failed (${err.response?.status || err.message}). Attempting fallback.`,
        );
      }
    }

    this.logger.error(
      `Gemini Vision unavailable for candidate "${claimedFullName}". Verification NOT approved.`,
    );
    throw new Error(
      'Our identity checker is temporarily busy. Your documents were not rejected — please retry in a few minutes.',
    );
  }

  /**
   * Parse various passport/ID date formats (e.g. "2022-05-14", "14/05/2022",
   * "14 MAY 2022", "14 MAY/MAI 22", "14-05-2022") into "YYYY-MM-DD".
   */
  private normalizeDateString(raw: string): string {
    if (!raw) return '';
    const cleaned = raw.trim().toUpperCase();

    // 1. Already YYYY-MM-DD
    const isoMatch = cleaned.match(/^(\d{4})-(\d{1,2})-(\d{1,2})/);
    if (isoMatch) {
      const y = isoMatch[1];
      const m = isoMatch[2].padStart(2, '0');
      const d = isoMatch[3].padStart(2, '0');
      return `${y}-${m}-${d}`;
    }

    // 2. DD/MM/YYYY or DD-MM-YYYY
    const dmyNumeric = cleaned.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})$/);
    if (dmyNumeric) {
      const d = dmyNumeric[1].padStart(2, '0');
      const m = dmyNumeric[2].padStart(2, '0');
      let y = dmyNumeric[3];
      if (y.length === 2) {
        const yNum = parseInt(y, 10);
        y = yNum > 50 ? `19${y}` : `20${y}`;
      }
      return `${y}-${m}-${d}`;
    }

    // 3. Passport alphanumeric dates e.g. "14 MAY 2022", "14 MAY/MAI 22", "14 MAY / MAI 2022"
    const months: Record<string, string> = {
      JAN: '01',
      FEB: '02',
      FEV: '02',
      MAR: '03',
      APR: '04',
      AVR: '04',
      MAY: '05',
      MAI: '05',
      JUN: '06',
      JUI: '06',
      JUL: '07',
      AUG: '08',
      AOU: '08',
      SEP: '09',
      OCT: '10',
      NOV: '11',
      DEC: '12',
    };
    const dayMatch = cleaned.match(/^(\d{1,2})\b/);
    const yearMatch = cleaned.match(/\b(\d{4}|\d{2})$/);
    let foundMonth = '';
    for (const [abbr, num] of Object.entries(months)) {
      if (cleaned.includes(abbr)) {
        foundMonth = num;
        break;
      }
    }
    if (dayMatch && foundMonth && yearMatch) {
      const d = dayMatch[1].padStart(2, '0');
      let y = yearMatch[1];
      if (y.length === 2) {
        const yNum = parseInt(y, 10);
        y = yNum > 50 ? `19${y}` : `20${y}`;
      }
      return `${y}-${foundMonth}-${d}`;
    }

    return '';
  }

  /**
   * Programmatically verify if an extracted date string is expired.
   */
  private isDateExpired(dateStr: string): boolean {
    if (!dateStr) return false;
    const normalized = this.normalizeDateString(dateStr) || dateStr.trim();
    const parsed = new Date(normalized);
    if (!isNaN(parsed.getTime())) {
      const now = new Date();
      const expiryEndOfDay = new Date(
        parsed.getFullYear(),
        parsed.getMonth(),
        parsed.getDate(),
        23,
        59,
        59,
      );
      if (expiryEndOfDay.getTime() < now.getTime()) {
        return true;
      }
    }
    const yearMatch = normalized.match(/\b(19\d{2}|20\d{2})\b/);
    if (yearMatch) {
      const expYear = parseInt(yearMatch[1], 10);
      const currentYear = new Date().getFullYear();
      if (expYear < currentYear) {
        return true;
      }
    }
    return false;
  }

  /**
   * Check that the birth year on the ID matches the candidate's claimed DOB (within ±1 year).
   */
  private checkDobConsistency(claimedDob?: string, extractedDob?: string): boolean {
    if (!claimedDob || !extractedDob) return true;
    const claimedYearMatch = claimedDob.match(/\b(19\d{2}|20\d{2})\b/);
    const extractedYearMatch = extractedDob.match(/\b(19\d{2}|20\d{2})\b/);
    if (claimedYearMatch && extractedYearMatch) {
      const cYear = parseInt(claimedYearMatch[1], 10);
      const eYear = parseInt(extractedYearMatch[1], 10);
      return Math.abs(cYear - eYear) <= 1;
    }
    return true;
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
