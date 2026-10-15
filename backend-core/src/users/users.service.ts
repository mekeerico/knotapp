import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AIService } from '../ai/ai.service';
import { DiditService } from '../verification/didit.service';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly aiService: AIService,
    private readonly diditService: DiditService,
  ) {}

  async findAll() {
    return this.prisma.user.findMany({
      include: { profileImages: true },
    });
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { profileImages: true },
    });
    if (!user) throw new NotFoundException('User not found.');
    return user;
  }

  async updateProfile(id: string, dto: any) {
    const allowedKeys = [
      'firstName', 'lastName', 'gender', 'preferredGender', 'dateOfBirth', 'bio', 'occupation', 'education', 'religion', 'culturalBackground', 'languagesSpoken',
      'smoking', 'drinking', 'maritalStatus', 'childrenStatus', 'marriageTimeline', 'willingToRelocate',
      'childrenPreference', 'idealPartnerTraits', 'personalValues', 'marriageExpectations', 'careerGoals',
      'residenceCountry', 'residenceState', 'residenceCity', 'originCountry', 'originState', 'originCity',
      'preferredResidenceCountry', 'preferredResidenceState', 'preferredResidenceCity', 'preferredOriginCountry', 'preferredOriginState', 'preferredOriginCity',
      'personalityArchetype', 'attachmentStyle', 'readinessScore', 'seriousnessLevel', 'trustScore',
      'isVerified', 'isPremium', 'idVerified', 'selfieVerified', 'selfieUrl', 'moderationFlags',
      'pushToken', 'subscriptionTier', 'subscriptionAmount', 'subscriptionPeriod', 'subscriptionDate'
    ];

    const data: any = {};
    for (const key of allowedKeys) {
      if (dto[key] !== undefined) {
        if (key === 'readinessScore' || key === 'seriousnessLevel' || key === 'trustScore' || key === 'moderationFlags') {
          data[key] = Number(dto[key]) || 0;
        } else if (key === 'isVerified' || key === 'isPremium' || key === 'idVerified' || key === 'selfieVerified') {
          data[key] = Boolean(dto[key]);
        } else {
          data[key] = dto[key];
        }
      }
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedUser = await tx.user.update({
        where: { id },
        data,
      });

      if (dto.profileImageUrls && Array.isArray(dto.profileImageUrls)) {
        await tx.image.deleteMany({ where: { userId: id } });
        if (dto.profileImageUrls.length > 0) {
          const uploadsDir = path.join(process.cwd(), 'uploads');
          if (!fs.existsSync(uploadsDir)) {
            fs.mkdirSync(uploadsDir, { recursive: true });
          }

          const processedUrls = dto.profileImageUrls.map((rawUrl: string, index: number) => {
            if (rawUrl.startsWith('data:image') || (rawUrl.length > 500 && !rawUrl.startsWith('http'))) {
              try {
                const base64Data = rawUrl.includes('base64,') ? rawUrl.split('base64,')[1] : rawUrl;
                const buffer = Buffer.from(base64Data, 'base64');
                const filename = `photo_${id}_${Date.now()}_${index}.jpg`;
                fs.writeFileSync(path.join(uploadsDir, filename), buffer);
                return `/uploads/${filename}`;
              } catch (e) {
                return rawUrl;
              }
            }
            return rawUrl;
          });

          await tx.image.createMany({
            data: processedUrls.map((url: string, index: number) => ({
              userId: id,
              url,
              isPrimary: index === 0,
            })),
          });
        }
      }

      return tx.user.findUnique({
        where: { id },
        include: { profileImages: true },
      });
    });
  }

  async completeOnboarding(id: string, transcript: Array<{ role: string; text: string }>) {
    const user = await this.findOne(id);

    // Call Python FastAPI AI microservice to extract structured psychological profiles
    const aiData = await this.aiService.extractInterviewData(transcript);
    if (!aiData) {
      throw new Error('AI failed to process conversational onboarding transcript.');
    }

    // Save extracted parameters into PostgreSQL database
    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: {
        occupation: aiData.occupation || user.occupation,
        education: aiData.education || user.education,
        religion: aiData.religion || user.religion,
        maritalStatus: aiData.maritalStatus || user.maritalStatus,
        willingToRelocate: aiData.willingToRelocate || user.willingToRelocate,
        marriageTimeline: aiData.marriageTimeline || user.marriageTimeline,
        childrenPreference: aiData.childrenPreference || user.childrenPreference,
        smoking: aiData.smoking || user.smoking,
        drinking: aiData.drinking || user.drinking,
        
        // AI Metrics
        personalityArchetype: aiData.personalityArchetype,
        attachmentStyle: aiData.attachmentStyle,
        readinessScore: aiData.readinessScore || 70,
        seriousnessLevel: aiData.seriousnessLevel || 80,
        trustScore: 85, // Set base trust score upon verified conversational completion
        personalValues: aiData.values || [],
        isVerified: true, // Auto verify upon conversational AI verification
      },
    });

    return updatedUser;
  }

  async submitSelfie(id: string, selfieUrl: string) {
    return this.prisma.user.update({
      where: { id },
      data: {
        selfieUrl,
        selfieVerified: true,
        trustScore: {
          increment: 10, // Increment trust score by 10 points upon selfie upload
        },
      },
    });
  }

  async getInsights(id: string) {
    const user = await this.findOne(id);
    return {
      readinessScore: user.readinessScore,
      seriousnessLevel: user.seriousnessLevel,
      trustScore: user.trustScore,
      actionableAdvice: [
        'Complete your bio to improve matching by 40%.',
        'Verify your ID to unlock the Verified badge.',
        'Upload 2 more photos for a complete profile.'
      ],
    };
  }

  async validateOnboardingAnswer(question: string, answer: string) {
    return this.aiService.validateOnboardingAnswer(question, answer);
  }

  private toBuffer(val: string): Buffer | null {
    try {
      if (!val) return null;
      if (val.includes('base64,')) {
        return Buffer.from(val.split('base64,')[1], 'base64');
      }
      return Buffer.from(val, 'base64');
    } catch {
      return null;
    }
  }

  async verifyOnboardingDocuments(selfieUrl: string, idUrl: string, firstName: string, lastName: string, dateOfBirth: string) {
    try {
      if (selfieUrl && idUrl) {
        const idBuf = this.toBuffer(idUrl);
        const selfieBuf = this.toBuffer(selfieUrl);

        if (idBuf && selfieBuf) {
          const docResult = await this.diditService.verifyDocument(idBuf);
          const livenessResult = await this.diditService.checkPassiveLiveness(selfieBuf);
          const faceMatchResult = await this.diditService.checkFaceMatch(selfieBuf, idBuf);

          if (docResult.isValid && livenessResult.isLive && faceMatchResult.isMatch) {
            return {
              success: true,
              confidenceScore: Math.round(faceMatchResult.similarityScore),
              ocrName: docResult.extractedData.fullName || `${firstName} ${lastName}`,
              ocrAge: docResult.extractedData.dateOfBirth || dateOfBirth,
              details: 'Biometric verification authenticated successfully via Didit Sovereign KYC.',
            };
          }
        }
      }
    } catch (e: any) {
      this.logger.warn(`Didit onboarding verification note: ${e.message}`);
    }

    // AI Service fallback
    return this.aiService.verifyOnboardingDocuments(selfieUrl, idUrl, firstName, lastName, dateOfBirth);
  }

  async deleteUser(id: string) {
    try {
      await this.prisma.user.delete({ where: { id } });
      return { success: true };
    } catch (error) {
      throw new NotFoundException('User not found or could not be deleted.');
    }
  }

  async seedUsers(users: any[]) {
    // If the mock array is empty, this just returns success.
    for (const u of users) {
      const existing = await this.prisma.user.findUnique({ where: { email: u.email || `${u.id}@mock.com` } });
      if (!existing) {
        await this.prisma.user.create({
          data: {
            id: u.id,
            email: u.email || `${u.id}@mock.com`,
            passwordHash: 'mock',
            firstName: u.firstName || u.name || 'Mock',
            lastName: u.lastName || '',
            dateOfBirth: u.dateOfBirth || new Date(new Date().setFullYear(new Date().getFullYear() - (u.age || 25))).toISOString(),
            isVerified: true,
            isPremium: true,
            profileImages: u.profileImageUrls?.length > 0 ? {
              create: u.profileImageUrls.map((url: string, index: number) => ({
                url,
                isPrimary: index === 0
              }))
            } : undefined
          }
        });
      }
    }
    return { success: true };
  }
}
