import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DiditService } from './didit.service';
import * as fs from 'fs';
import * as path from 'path';

export interface MulterFile {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
  destination?: string;
  filename?: string;
  path?: string;
}

@Injectable()
export class VerificationService {
  private readonly logger = new Logger(VerificationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly diditService: DiditService,
  ) {}

  async verifyIdentity(
    userId: string,
    files: {
      idFront?: MulterFile[];
      idBack?: MulterFile[];
      selfie?: MulterFile[];
    },
  ) {
    const idFront = files.idFront?.[0];
    const idBack = files.idBack?.[0];
    const selfie = files.selfie?.[0];

    if (!idFront) {
      throw new BadRequestException('Document front image (idFront) is required for verification.');
    }
    if (!selfie) {
      throw new BadRequestException('Live selfie image (selfie) is required for biometric verification.');
    }

    this.logger.log(`Beginning Didit identity verification sequence for user ${userId}`);

    // Step 1: Verify Document Legitimacy & Extract OCR Data
    const docResult = await this.diditService.verifyDocument(
      idFront.buffer,
      idBack?.buffer,
      idFront.originalname,
      idBack?.originalname,
    );

    if (!docResult.isValid) {
      const errorDetail = docResult.errorMessage ||
        (docResult.checks.blurDetected ? 'Document image is too blurry. Please upload a clear photo.' :
         docResult.checks.glareDetected ? 'Glare detected on document. Please avoid flash or direct light reflections.' :
         docResult.checks.tamperingDetected ? 'Document failed authenticity checks.' :
         'Government ID is invalid or cannot be verified.');
      throw new BadRequestException(`Verification failed: ${errorDetail}`);
    }

    // Step 2: Passive Liveness Analysis on Selfie
    const livenessResult = await this.diditService.checkPassiveLiveness(
      selfie.buffer,
      selfie.originalname,
    );

    if (!livenessResult.isLive || livenessResult.spoofDetected) {
      throw new BadRequestException(
        `Biometric check failed: Passive liveness check could not confirm a live human subject. ${livenessResult.details || 'Please hold steady and face the camera directly.'}`,
      );
    }

    // Step 3: 1:1 Biometric Face Match between Selfie and Document Photo
    const faceMatchResult = await this.diditService.checkFaceMatch(
      selfie.buffer,
      idFront.buffer,
    );

    if (!faceMatchResult.isMatch || faceMatchResult.similarityScore < 70) {
      throw new BadRequestException(
        `Biometric mismatch: The face in the live selfie does not match the photo on the identity document (Similarity: ${faceMatchResult.similarityScore}%).`,
      );
    }

    // Calculate aggregated high-trust score (0 - 100)
    const compositeScore = Math.round(
      docResult.confidenceScore * 0.35 +
      livenessResult.livenessScore * 0.3 +
      faceMatchResult.similarityScore * 0.35,
    );

    // Save image files locally into uploads directory for profile asset access
    const uploadsDir = path.join(process.cwd(), 'uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    const selfieFilename = `selfie_${userId}_${Date.now()}.jpg`;
    fs.writeFileSync(path.join(uploadsDir, selfieFilename), selfie.buffer);
    const selfieUrl = `/uploads/${selfieFilename}`;

    // Update user record in PostgreSQL via Prisma
    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        isVerified: true,
        idVerified: true,
        selfieVerified: true,
        selfieUrl: selfieUrl,
        verifiedAt: new Date(),
        verificationBadge: 'GOLD',
        verificationScore: compositeScore,
        idDocType: docResult.documentType,
        trustScore: Math.min(100, 95 + Math.floor(Math.random() * 5)),
      },
    });

    this.logger.log(`User ${userId} successfully verified with GOLD badge and score ${compositeScore}%`);

    return {
      success: true,
      verificationStatus: 'VERIFIED',
      verificationBadge: 'GOLD',
      confidenceScore: compositeScore,
      documentType: docResult.documentType,
      ocrData: docResult.extractedData,
      metrics: {
        documentConfidence: docResult.confidenceScore,
        livenessScore: livenessResult.livenessScore,
        faceMatchScore: faceMatchResult.similarityScore,
      },
      message: 'Identity verified successfully. Gold Trust Badge granted.',
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        firstName: updatedUser.firstName,
        lastName: updatedUser.lastName,
        isVerified: updatedUser.isVerified,
        verificationBadge: updatedUser.verificationBadge,
        trustScore: updatedUser.trustScore,
        selfieUrl: updatedUser.selfieUrl,
      },
    };
  }
}
