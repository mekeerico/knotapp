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
      valuesScore += 4;
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
    const isUserMale = userGenderRaw === 'male' || userGenderRaw === 'man' || userGenderRaw === 'm';
    const isUserFemale = userGenderRaw === 'female' || userGenderRaw === 'woman' || userGenderRaw === 'f';

    let targetGender: 'Male' | 'Female';

    if (isUserFemale) {
      targetGender = 'Male';
    } else if (isUserMale) {
      targetGender = 'Female';
    } else {
      const prefRaw = (user.preferredGender || '').trim().toLowerCase();
      targetGender = (prefRaw === 'male' || prefRaw === 'man' || prefRaw === 'm') ? 'Male' : 'Female';
    }

    const userEmail = (user.email || '').trim().toLowerCase();
    const userFirstName = (user.firstName || '').trim().toLowerCase();
    const userLastName = (user.lastName || '').trim().toLowerCase();
    const userFullName = `${userFirstName} ${userLastName}`.trim();

    // Query opposite-sex candidates excluding current user ID and current user email
    const allCandidates = await this.prisma.user.findMany({
      where: {
        id: { not: userId },
        ...(userEmail ? { email: { not: userEmail } } : {}),
        gender: { equals: targetGender, mode: 'insensitive' },
      },
      orderBy: [
        { isVerified: 'desc' },
        { trustScore: 'desc' },
      ],
      take: 25,
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
      const isCandMale = cGender === 'male' || cGender === 'man' || cGender === 'm';
      const isCandFemale = cGender === 'female' || cGender === 'woman' || cGender === 'f';

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
      const isClosestAvailable = match.compatibilityScore < 80;
      let explanation = match.aiExplanation;

      if (isClosestAvailable) {
        explanation = `Closest Available Alignment: ${partner.firstName} is currently your closest matching partner in the registry while we search for your exact marriage timeline & preference alignment. ${explanation} Your recommendations will continuously update as closer candidates join.`;
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
