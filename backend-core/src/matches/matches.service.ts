import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AIService } from '../ai/ai.service';
import { MatchStatus } from '@prisma/client';
import { NotificationsService } from '../services/notifications.service';

@Injectable()
export class MatchesService {
  private readonly logger = new Logger(MatchesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly aiService: AIService,
    private readonly notificationsService: NotificationsService,
  ) {}

  private formatPartnerMedia(partner: any) {
    const formattedImages = Array.isArray(partner.profileImages)
      ? partner.profileImages.map((img: any) => ({
          ...img,
          url: img.url && typeof img.url === 'string' && img.url.startsWith('data:image')
            ? `/uploads/db-image/${img.id}`
            : img.url,
        }))
      : [];

    const formattedSelfie =
      partner.selfieUrl && typeof partner.selfieUrl === 'string' && partner.selfieUrl.startsWith('data:image')
        ? `/uploads/db-selfie/${partner.id}`
        : partner.selfieUrl;

    return {
      profileImages: formattedImages,
      selfieUrl: formattedSelfie,
    };
  }

  private computeFastCompatibility(user: any, cand: any) {
    let valuesScore = 84;
    if (user.religion && cand.religion && user.religion.toLowerCase() === cand.religion.toLowerCase()) {
      valuesScore += 8;
    }
    if (user.childrenPreference && cand.childrenPreference && user.childrenPreference === cand.childrenPreference) {
      valuesScore += 6;
    }

    let lifestyleScore = 82;
    if (user.marriageTimeline && cand.marriageTimeline && user.marriageTimeline === cand.marriageTimeline) {
      lifestyleScore += 8;
    }
    if (user.smoking && cand.smoking && user.smoking === cand.smoking) {
      lifestyleScore += 3;
    }
    if (user.drinking && cand.drinking && user.drinking === cand.drinking) {
      lifestyleScore += 3;
    }

    // Dynamic Partner Location & Heritage Preferences
    if (user.preferredResidenceCountry && cand.residenceCountry && user.preferredResidenceCountry.toLowerCase() === cand.residenceCountry.toLowerCase()) {
      lifestyleScore += 8;
    }
    if (user.preferredOriginCountry && cand.originCountry && user.preferredOriginCountry.toLowerCase() === cand.originCountry.toLowerCase()) {
      valuesScore += 8;
    }

    // Dynamic Partner Age Range & Kids Status Check (from marriageExpectations or profile)
    let candAge: number | null = null;
    if (cand.dateOfBirth) {
      const d = new Date(cand.dateOfBirth);
      if (!isNaN(d.getTime())) {
        const diffMs = Date.now() - d.getTime();
        candAge = Math.floor(diffMs / (1000 * 60 * 60 * 24 * 365.25));
      }
    }

    // Check for age range in expectations string or JSON (e.g. "Age 24-35" or {minAge, maxAge})
    const expText = (user.marriageExpectations || '').toLowerCase();
    const ageMatch = expText.match(/(\d{2})\s*-\s*(\d{2})/);
    let minAge = 20;
    let maxAge = 55;
    if (ageMatch) {
      minAge = parseInt(ageMatch[1], 10);
      maxAge = parseInt(ageMatch[2], 10);
    }
    if (candAge !== null) {
      if (candAge >= minAge && candAge <= maxAge) {
        lifestyleScore += 6;
      } else if (candAge < minAge - 3 || candAge > maxAge + 5) {
        lifestyleScore -= 6;
      }
    }

    // Partner Kids Preference Check
    if (expText.includes('no kids') || expText.includes('no children')) {
      if (cand.childrenStatus && cand.childrenStatus.toLowerCase().includes('no')) {
        valuesScore += 6;
      }
    } else if (expText.includes('has kids') || expText.includes('has children')) {
      if (cand.childrenStatus && !cand.childrenStatus.toLowerCase().includes('no')) {
        valuesScore += 6;
      }
    }

    // Ideal Partner Traits Alignment
    if (Array.isArray(user.idealPartnerTraits) && user.idealPartnerTraits.length > 0 && Array.isArray(cand.idealPartnerTraits)) {
      const matched = user.idealPartnerTraits.filter((t: string) => cand.idealPartnerTraits.includes(t));
      if (matched.length > 0) {
        valuesScore += Math.min(8, matched.length * 3);
      }
    }

    let emotionalScore = 85;
    if (cand.attachmentStyle?.toLowerCase().includes('secure')) {
      emotionalScore += 6;
    }
    if ((cand.readinessScore || 0) >= 80) {
      emotionalScore += 4;
    }

    let commScore = 84;
    if (user.residenceCountry && cand.residenceCountry && user.residenceCountry.toLowerCase() === cand.residenceCountry.toLowerCase()) {
      commScore += 6;
    }
    if ((cand.seriousnessLevel || 0) >= 80) {
      commScore += 4;
    }

    const valuesAlignment = Math.min(98, Math.max(76, valuesScore));
    const lifestyleCompatibility = Math.min(97, Math.max(75, lifestyleScore));
    const emotionalAlignment = Math.min(97, Math.max(78, emotionalScore));
    const communicationStyle = Math.min(96, Math.max(78, commScore));
    const compatibilityScore = Math.round(
      valuesAlignment * 0.3 +
      emotionalAlignment * 0.3 +
      lifestyleCompatibility * 0.2 +
      communicationStyle * 0.2,
    );

    const archetype = cand.personalityArchetype || 'Intentional Partner';
    const timeline = cand.marriageTimeline || '1-2 Years';
    const city = cand.residenceCity || cand.residenceCountry || 'the registry';
    const aiExplanation = `${cand.firstName} demonstrates strong matrimonial alignment (${compatibilityScore}%) as ${archetype} based in ${city}, sharing harmonious family values and a ${timeline} marriage horizon.`;

    return {
      compatibilityScore,
      emotionalAlignment,
      communicationStyle,
      valuesAlignment,
      lifestyleCompatibility,
      aiExplanation,
    };
  }

  async getDailyMatches(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new BadRequestException('User not found.');

    // Strictly enforce opposite-sex matching only (Male <-> Female)
    const userGenderRaw = (user.gender || '').trim().toLowerCase();
    let isUserMale = userGenderRaw === 'male' || userGenderRaw === 'man' || userGenderRaw === 'm';
    let isUserFemale = userGenderRaw === 'female' || userGenderRaw === 'woman' || userGenderRaw === 'f';

    const maleNames = [
      'michael', 'alex', 'david', 'john', 'james', 'daniel', 'liam', 'chen',
      'robert', 'william', 'joseph', 'charles', 'thomas', 'christopher', 'matthew',
      'anthony', 'mark', 'steven', 'paul', 'andrew', 'joshua', 'kevin', 'brian',
      'george', 'edward', 'jason', 'ryan', 'jacob', 'nicholas', 'eric', 'emeke',
      'jonathan', 'stephen', 'justin', 'brandon', 'benjamin', 'samuel', 'alexander',
      'patrick', 'jack', 'tyler', 'aaron', 'adam', 'nathan', 'henry', 'zachary',
      'peter', 'kyle', 'ethan', 'jeremy', 'christian', 'noah', 'sean', 'austin',
      'arthur', 'jesse', 'dylan', 'bryan', 'jordan', 'gabriel', 'logan', 'alan',
      'juan', 'vincent', 'louis', 'philip', 'bradley', 'mike', 'tunde', 'femi',
      'chidi', 'obi', 'kofi', 'kwame', 'ahmed', 'ali', 'hassan', 'omar', 'ibrahim', 'musa', 'ajajwjwjw'
    ];
    const femaleNames = [
      'sarah', 'emily', 'sophia', 'zainab', 'priya', 'amina', 'chloe', 'emma',
      'olivia', 'ava', 'isabella', 'mia', 'charlotte', 'amelia', 'harper', 'evelyn',
      'abigail', 'elizabeth', 'sofia', 'avery', 'ella', 'scarlett', 'grace',
      'victoria', 'riley', 'aria', 'lily', 'aubrey', 'zoey', 'penelope', 'layla',
      'lillian', 'nora', 'camila', 'hannah', 'mila', 'eleanor', 'maya', 'stella',
      'hazel', 'leah', 'violet', 'aurora', 'savannah', 'audrey', 'brooklyn',
      'claire', 'skylar', 'ellie', 'lucy', 'anna', 'caroline', 'nova', 'genesis',
      'emilia', 'kennedy', 'samantha', 'allison', 'madelyn', 'adeline', 'hailey',
      'elena', 'cora', 'vivian', 'natalie', 'zoe', 'katelyn', 'fatima', 'aisha',
      'maryam', 'khadija', 'nour', 'huda', 'yasmin', 'iman', 'asma', 'mariam',
      'amara', 'chioma', 'ngozi', 'ada', 'adaora', 'blessing', 'mercy', 'joy',
      'chiamaka', 'yetunde', 'folake', 'funke'
    ];

    const userEmail = (user.email || '').trim().toLowerCase();
    const userFirstName = (user.firstName || '').trim().toLowerCase();
    const userLastName = (user.lastName || '').trim().toLowerCase();
    const userFullName = `${userFirstName} ${userLastName}`.trim();

    if (!isUserMale && !isUserFemale) {
      const prefRaw = (user.preferredGender || '').trim().toLowerCase();
      if (prefRaw === 'male' || prefRaw === 'man' || prefRaw === 'm') isUserFemale = true;
      else if (prefRaw === 'female' || prefRaw === 'woman' || prefRaw === 'f') isUserMale = true;
    }
    if (!isUserMale && !isUserFemale) {
      if (maleNames.includes(userFirstName)) isUserMale = true;
      else if (femaleNames.includes(userFirstName)) isUserFemale = true;
    }
    if (!isUserMale && !isUserFemale && userEmail) {
      const emailPrefix = userEmail.split('@')[0];
      if (maleNames.some(m => emailPrefix.includes(m))) isUserMale = true;
      else if (femaleNames.some(f => emailPrefix.includes(f))) isUserFemale = true;
    }

    let targetGender: 'Male' | 'Female';
    if (isUserFemale) {
      targetGender = 'Male';
    } else {
      // Default to Female for male users or unassigned users
      targetGender = 'Female';
    }

    const femaleVariants = ['female', 'woman', 'lady', 'f', 'she', 'girl'];
    const maleVariants = ['male', 'man', 'gentleman', 'm', 'he', 'boy'];
    const targetVariants = targetGender === 'Male' ? maleVariants : femaleVariants;

    // Query opposite-sex candidates excluding current user ID, current user email, and any mock/test accounts
    const allCandidates = await this.prisma.user.findMany({
      where: {
        id: { not: userId },
        ...(userEmail ? { email: { not: userEmail } } : {}),
        passwordHash: { startsWith: '$2' }, // Strictly only real humans with bcrypt password hashes
        NOT: [
          { email: { contains: 'mock', mode: 'insensitive' } },
          { email: { contains: 'test', mode: 'insensitive' } },
          { email: { contains: 'knotconnect.org', mode: 'insensitive' } },
          { email: { contains: 'zainab', mode: 'insensitive' } },
          { id: { startsWith: 'match_' } },
          { id: { startsWith: 'mock_' } },
          { id: { startsWith: 'user_' } },
          { firstName: { in: ['Amara', 'Dr. Amara', 'Zainab'], mode: 'insensitive' } },
          { lastName: { in: ['Okonkwo', 'Balogun'], mode: 'insensitive' } },
        ],
        profileImages: {
          some: {}, // Strictly only real humans who have uploaded at least one profile photo
        },
        OR: [
          { gender: { in: targetVariants, mode: 'insensitive' } },
          { gender: '' },
        ],
      },
      orderBy: [
        { isVerified: 'desc' },
        { trustScore: 'desc' },
      ],
      take: 50,
      include: { profileImages: true },
    });

    // Hard guarantee filter:
    // 1. A user can NEVER be matched to themselves (by ID, email, or identical full name).
    // 2. Strict Opposite-Sex matching only (Male <-> Female). Candidates of the same sex or ambiguous sex are discarded.
    const strictlyOppositeCandidates = allCandidates.filter((c) => {
      // 1. Strict Self-Exclusion
      if (c.id === userId) return false;
      if (userEmail && c.email && c.email.trim().toLowerCase() === userEmail) return false;

      const candFirstName = (c.firstName || '').trim().toLowerCase();
      const candLastName = (c.lastName || '').trim().toLowerCase();
      const candFullName = `${candFirstName} ${candLastName}`.trim();
      if (userFullName.length > 2 && candFullName === userFullName) return false;
      if (userFirstName.length > 1 && candFirstName === userFirstName && userLastName.length > 1 && candLastName === userLastName) return false;

      // 2. Strict Opposite-Sex Enforcement
      const cGender = (c.gender || '').trim().toLowerCase();
      let isCandMale = maleVariants.includes(cGender);
      let isCandFemale = femaleVariants.includes(cGender);

      // If gender was not explicitly specified, infer from candidate's preferredGender
      if (!isCandMale && !isCandFemale) {
        const cPref = (c.preferredGender || '').trim().toLowerCase();
        if (femaleVariants.includes(cPref)) isCandMale = true;
        if (maleVariants.includes(cPref)) isCandFemale = true;
      }

      // Name-based inference for candidates with unset gender
      if (!isCandMale && !isCandFemale) {
        if (maleNames.includes(candFirstName)) isCandMale = true;
        if (femaleNames.includes(candFirstName)) isCandFemale = true;
      }

      if (!isCandMale && !isCandFemale) return false;

      if (targetGender === 'Male') {
        if (!isCandMale || isCandFemale) return false;
      } else {
        if (!isCandFemale || isCandMale) return false;
      }

      // Mutual exclusivity guard: user and candidate must never have the same gender
      if (isUserMale && isCandMale) return false;
      if (isUserFemale && isCandFemale) return false;

      return true;
    });

    if (strictlyOppositeCandidates.length === 0) {
      return [];
    }

    const candIds = strictlyOppositeCandidates.map((c) => c.id);

    // Batch fetch all existing Match records in ONE single query instead of N queries
    const existingMatches = await this.prisma.match.findMany({
      where: {
        OR: [
          { userAId: userId, userBId: { in: candIds } },
          { userBId: userId, userAId: { in: candIds } },
        ],
      },
    });

    const matchMap = new Map<string, any>();
    for (const m of existingMatches) {
      matchMap.set(`${m.userAId}_${m.userBId}`, m);
    }

    const newMatchesToCreate: any[] = [];
    const matchesList: any[] = [];

    for (const cand of strictlyOppositeCandidates) {
      const uA = userId < cand.id ? userId : cand.id;
      const uB = userId < cand.id ? cand.id : userId;
      const pairKey = `${uA}_${uB}`;

      let match = matchMap.get(pairKey);

      if (!match) {
        const fastScore = this.computeFastCompatibility(user, cand);
        match = {
          id: `${uA}_${uB}`,
          userAId: uA,
          userBId: uB,
          compatibilityScore: fastScore.compatibilityScore,
          emotionalAlignment: fastScore.emotionalAlignment,
          communicationStyle: fastScore.communicationStyle,
          valuesAlignment: fastScore.valuesAlignment,
          lifestyleCompatibility: fastScore.lifestyleCompatibility,
          aiExplanation: fastScore.aiExplanation,
          status: MatchStatus.PENDING,
        };
        newMatchesToCreate.push({
          userAId: uA,
          userBId: uB,
          compatibilityScore: fastScore.compatibilityScore,
          emotionalAlignment: fastScore.emotionalAlignment,
          communicationStyle: fastScore.communicationStyle,
          valuesAlignment: fastScore.valuesAlignment,
          lifestyleCompatibility: fastScore.lifestyleCompatibility,
          aiExplanation: fastScore.aiExplanation,
          status: MatchStatus.PENDING,
        });
      }

      const partner = cand;
      const isClosestAvailable = match.compatibilityScore < 85 ||
        (user.preferredResidenceCountry && user.preferredResidenceCountry.toLowerCase() !== 'any country' && cand.residenceCountry && user.preferredResidenceCountry.toLowerCase() !== cand.residenceCountry.toLowerCase()) ||
        (user.religion && cand.religion && user.religion.toLowerCase() !== cand.religion.toLowerCase());
      let explanation = match.aiExplanation;

      if (isClosestAvailable) {
        explanation = `Closest Available Alignment: ${partner.firstName} is currently your closest matching partner in the registry for now. ${explanation} You will be matched appropriately as closer candidates become available.`;
      }

      const media = this.formatPartnerMedia(partner);

      matchesList.push({
        matchId: match.id,
        partner: {
          id: partner.id,
          firstName: partner.firstName,
          lastName: partner.lastName,
          gender: partner.gender,
          dateOfBirth: partner.dateOfBirth,
          bio: partner.bio,
          occupation: partner.occupation,
          education: partner.education,
          religion: partner.religion,
          culturalBackground: partner.culturalBackground,
          languagesSpoken: partner.languagesSpoken,
          smoking: partner.smoking,
          drinking: partner.drinking,
          maritalStatus: partner.maritalStatus,
          childrenStatus: partner.childrenStatus,
          marriageTimeline: partner.marriageTimeline,
          willingToRelocate: partner.willingToRelocate,
          childrenPreference: partner.childrenPreference,
          idealPartnerTraits: partner.idealPartnerTraits,
          personalValues: partner.personalValues,
          marriageExpectations: partner.marriageExpectations,
          careerGoals: partner.careerGoals,
          residenceCountry: partner.residenceCountry,
          residenceState: partner.residenceState,
          residenceCity: partner.residenceCity,
          originCountry: partner.originCountry,
          originState: partner.originState,
          originCity: partner.originCity,
          preferredResidenceCountry: partner.preferredResidenceCountry,
          preferredResidenceState: partner.preferredResidenceState,
          preferredResidenceCity: partner.preferredResidenceCity,
          preferredOriginCountry: partner.preferredOriginCountry,
          preferredOriginState: partner.preferredOriginState,
          preferredOriginCity: partner.preferredOriginCity,
          personalityArchetype: partner.personalityArchetype,
          attachmentStyle: partner.attachmentStyle,
          readinessScore: partner.readinessScore,
          seriousnessLevel: partner.seriousnessLevel,
          trustScore: partner.trustScore,
          isVerified: partner.isVerified,
          idVerified: partner.idVerified,
          verificationBadge: partner.verificationBadge,
          selfieUrl: media.selfieUrl,
          profileImages: media.profileImages,
        },
        scores: {
          compatibilityScore: match.compatibilityScore,
          emotionalAlignment: match.emotionalAlignment,
          communicationStyle: match.communicationStyle,
          valuesAlignment: match.valuesAlignment,
          lifestyleCompatibility: match.lifestyleCompatibility,
        },
        aiExplanation: explanation,
        status: match.status,
        isClosestAvailable,
      });
    }

    if (newMatchesToCreate.length > 0) {
      // Persist newly calculated match pairs asynchronously without blocking response
      this.prisma.match
        .createMany({ data: newMatchesToCreate, skipDuplicates: true })
        .catch((err) => this.logger.warn(`Failed batch match insert: ${err.message}`));
    }

    // Sort by compatibilityScore descending so the highest/closest matches are always presented first
    matchesList.sort((a, b) => b.scores.compatibilityScore - a.scores.compatibilityScore);

    return matchesList;
  }

  async respondToMatch(matchId: string, status: MatchStatus) {
    const updatedMatch = await this.prisma.match.update({
      where: { id: matchId },
      data: { status },
      include: { userA: true, userB: true }
    });

    if (status === MatchStatus.CONNECTED) {
      if (updatedMatch.userA.pushToken) {
        await this.notificationsService.sendPushNotification(
          updatedMatch.userA.pushToken,
          `New Connection!`,
          `You and ${updatedMatch.userB.firstName} are now connected.`,
          { url: `knot://chat/${updatedMatch.userB.id}` }
        );
      }
      if (updatedMatch.userB.pushToken) {
        await this.notificationsService.sendPushNotification(
          updatedMatch.userB.pushToken,
          `New Connection!`,
          `You and ${updatedMatch.userA.firstName} are now connected.`,
          { url: `knot://chat/${updatedMatch.userA.id}` }
        );
      }
    }

    return updatedMatch;
  }

  async getConnectedMatches(userId: string) {
    const matches = await this.prisma.match.findMany({
      where: {
        OR: [
          { userAId: userId, status: MatchStatus.CONNECTED },
          { userBId: userId, status: MatchStatus.CONNECTED },
        ],
      },
      include: {
        userA: { include: { profileImages: true } },
        userB: { include: { profileImages: true } },
      },
    });

    const validMatches = matches.filter((m) => {
      if (m.userAId === m.userBId) return false;
      const partner = m.userAId === userId ? m.userB : m.userA;
      return partner && partner.id !== userId;
    });

    return validMatches.map((m) => {
      const partner = m.userAId === userId ? m.userB : m.userA;
      const media = this.formatPartnerMedia(partner);
      return {
        matchId: m.id,
        partner: {
          id: partner.id,
          firstName: partner.firstName,
          lastName: partner.lastName,
          gender: partner.gender,
          dateOfBirth: partner.dateOfBirth,
          bio: partner.bio,
          occupation: partner.occupation,
          education: partner.education,
          religion: partner.religion,
          culturalBackground: partner.culturalBackground,
          languagesSpoken: partner.languagesSpoken,
          smoking: partner.smoking,
          drinking: partner.drinking,
          maritalStatus: partner.maritalStatus,
          childrenStatus: partner.childrenStatus,
          marriageTimeline: partner.marriageTimeline,
          willingToRelocate: partner.willingToRelocate,
          childrenPreference: partner.childrenPreference,
          idealPartnerTraits: partner.idealPartnerTraits,
          personalValues: partner.personalValues,
          marriageExpectations: partner.marriageExpectations,
          careerGoals: partner.careerGoals,
          residenceCountry: partner.residenceCountry,
          residenceState: partner.residenceState,
          residenceCity: partner.residenceCity,
          originCountry: partner.originCountry,
          originState: partner.originState,
          originCity: partner.originCity,
          preferredResidenceCountry: partner.preferredResidenceCountry,
          preferredResidenceState: partner.preferredResidenceState,
          preferredResidenceCity: partner.preferredResidenceCity,
          preferredOriginCountry: partner.preferredOriginCountry,
          preferredOriginState: partner.preferredOriginState,
          preferredOriginCity: partner.preferredOriginCity,
          personalityArchetype: partner.personalityArchetype,
          attachmentStyle: partner.attachmentStyle,
          readinessScore: partner.readinessScore,
          seriousnessLevel: partner.seriousnessLevel,
          trustScore: partner.trustScore,
          isVerified: partner.isVerified,
          idVerified: partner.idVerified,
          verificationBadge: partner.verificationBadge,
          selfieUrl: media.selfieUrl,
          profileImages: media.profileImages,
        },
        scores: {
          compatibilityScore: m.compatibilityScore,
          emotionalAlignment: m.emotionalAlignment,
          communicationStyle: m.communicationStyle,
          valuesAlignment: m.valuesAlignment,
          lifestyleCompatibility: m.lifestyleCompatibility,
        },
        aiExplanation: m.aiExplanation,
      };
    });
  }
}
