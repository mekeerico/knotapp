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

  async getDailyMatches(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new BadRequestException('User not found.');

    // Strictly enforce opposite-sex matching only (Male <-> Female)
    const userGender = user.gender?.toLowerCase() || '';
    const targetGender = userGender === 'female' ? 'Male' : (user.preferredGender || 'Female');

    // Step 1: Query verified opposite-sex candidates first
    const verifiedCandidates = await this.prisma.user.findMany({
      where: {
        id: { not: userId },
        isVerified: true,
        gender: { equals: targetGender, mode: 'insensitive' },
      },
      take: 20,
      include: { profileImages: true },
    });

    // Step 2: If verified pool is small, supplement with unverified opposite-sex candidates
    // so the user's Matches screen is NEVER left empty as long as opposite-sex candidates exist in registry!
    const allCandidates = [...verifiedCandidates];
    if (allCandidates.length < 15) {
      const remainingNeeded = 15 - allCandidates.length;
      const unverifiedCandidates = await this.prisma.user.findMany({
        where: {
          id: { notIn: [userId, ...allCandidates.map(c => c.id)] },
          gender: { equals: targetGender, mode: 'insensitive' },
        },
        take: remainingNeeded,
        include: { profileImages: true },
      });
      allCandidates.push(...unverifiedCandidates);
    }

    const matchesList: any[] = [];

    for (const cand of allCandidates) {
      // Check if we already have calculated their compatibility
      let match = await this.prisma.match.findUnique({
        where: {
          userAId_userBId: {
            userAId: userId < cand.id ? userId : cand.id,
            userBId: userId < cand.id ? cand.id : userId,
          },
        },
      });

      if (!match) {
        // Run deep Gemini AI mathematical compatibility calculations
        const aiScore = await this.aiService.calculateCompatibility(user, cand);

        match = await this.prisma.match.create({
          data: {
            userAId: userId < cand.id ? userId : cand.id,
            userBId: userId < cand.id ? cand.id : userId,
            compatibilityScore: aiScore.compatibilityScore,
            emotionalAlignment: aiScore.emotionalAlignment,
            communicationStyle: aiScore.communicationStyle,
            valuesAlignment: aiScore.valuesAlignment,
            lifestyleCompatibility: aiScore.lifestyleCompatibility,
            aiExplanation: aiScore.aiExplanation,
            status: MatchStatus.PENDING,
          },
        });
      }

      const partner = cand;
      const isClosestAvailable = match.compatibilityScore < 80;
      let explanation = match.aiExplanation;

      if (isClosestAvailable) {
        explanation = `Closest Available Alignment: ${partner.firstName} is currently your closest matching partner in the registry while we search for your exact marriage timeline & preference alignment. ${explanation} Your recommendations will continuously update as closer candidates join.`;
      }

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
          profileImages: partner.profileImages,
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

    return matches.map((m) => {
      const partner = m.userAId === userId ? m.userB : m.userA;
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
          profileImages: partner.profileImages,
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
