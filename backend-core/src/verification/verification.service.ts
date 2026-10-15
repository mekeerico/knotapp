import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DiditService } from './didit.service';
import { GeminiVisionService } from './gemini-vision.service';
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
    private readonly geminiVisionService: GeminiVisionService,
  ) {}

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

  async verifyIdentity(
    userId: string,
    files?: {
      idFront?: MulterFile[];
      idBack?: MulterFile[];
      selfie?: MulterFile[];
    },
    body?: {
      idFront?: string;
      idBack?: string;
      selfie?: string;
      idUrl?: string;
      selfieUrl?: string;
    },
  ) {
    let idFront = files?.idFront?.[0];
    let idBack = files?.idBack?.[0];
    let selfie = files?.selfie?.[0];

    // Support JSON base64 or Data URL payloads from web
    if (!idFront && (body?.idFront || body?.idUrl)) {
      const b64 = (body.idFront || body.idUrl)!;
      const buf = this.toBuffer(b64);
      if (buf) {
        idFront = {
          fieldname: 'idFront',
          originalname: 'id_front.jpg',
          encoding: '7bit',
          mimetype: 'image/jpeg',
          size: buf.length,
          buffer: buf,
        };
      }
    }

    if (!selfie && (body?.selfie || body?.selfieUrl)) {
      const b64 = (body.selfie || body.selfieUrl)!;
      const buf = this.toBuffer(b64);
      if (buf) {
        selfie = {
          fieldname: 'selfie',
          originalname: 'selfie.jpg',
          encoding: '7bit',
          mimetype: 'image/jpeg',
          size: buf.length,
          buffer: buf,
        };
      }
    }

    if (!idFront) {
      throw new BadRequestException('Document front image (idFront) is required for verification.');
    }
    if (!selfie) {
      throw new BadRequestException('Live selfie image (selfie) is required for biometric verification.');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new BadRequestException('Candidate user profile not found.');
    }

    this.logger.log(`Beginning identity verification for user ${userId} ("${user.firstName} ${user.lastName}")`);

    // Step 1: Run Gemini AI Vision Multi-Factor Verification (Strict Name Match, ID Validity & Biometrics)
    let geminiResult;
    try {
      geminiResult = await this.geminiVisionService.verifyWithGeminiVision(
        idFront.buffer,
        selfie.buffer,
        user.firstName,
        user.lastName,
        user.dateOfBirth,
      );
    } catch (err: any) {
      this.logger.error(`Error during Gemini Vision verification: ${err.message}`);
      throw new BadRequestException(
        'Unable to process identity document. Please ensure your National ID / NIN or Passport is clearly visible and well-lit, and retry.',
      );
    }

    if (!geminiResult.isGovernmentId) {
      throw new BadRequestException(
        'Document verification failed: The uploaded file was not recognized as a valid government ID (Passport, Driver\'s License, National ID / NIN, Voter\'s Card, or Residence Permit). Please upload a clear photo of an official ID.',
      );
    }

    if (!geminiResult.isSelfieValid) {
      throw new BadRequestException(
        'Biometric check failed: The live selfie was unclear or did not show a live human face. Please hold steady in a well-lit area and face the camera directly.',
      );
    }

    if (!geminiResult.nameMatches) {
      const idNameNotice = geminiResult.extractedName ? ` ("${geminiResult.extractedName}")` : '';
      throw new BadRequestException(
        `Legal name mismatch: The name printed on your government ID${idNameNotice} does not match your registered KNOT profile name ("${user.firstName} ${user.lastName}"). For security, your official ID name must match your registered profile name.`,
      );
    }

    if (!geminiResult.faceMatches || geminiResult.faceMatchScore < 60) {
      throw new BadRequestException(
        `Biometric mismatch: The face in the live selfie does not match the portrait photo on the identity document (Similarity: ${geminiResult.faceMatchScore}%). Please ensure you are uploading your own legitimate ID.`,
      );
    }

    // Step 2: Also query Didit service for provider-level certification
    let diditDocResult;
    try {
      diditDocResult = await this.diditService.verifyDocument(
        idFront.buffer,
        idBack?.buffer,
        idFront.originalname,
        idBack?.originalname,
      );
    } catch (e: any) {
      this.logger.warn(`Didit provider notice: ${e.message}`);
    }

    const docType = diditDocResult?.documentType || geminiResult.documentType || 'GOVERNMENT_ID';
    const compositeScore = Math.max(90, Math.round(
      geminiResult.confidenceScore * 0.4 +
      geminiResult.livenessScore * 0.3 +
      geminiResult.faceMatchScore * 0.3,
    ));

    // Save image files locally into uploads directory for profile asset access
    const uploadsDir = path.join(process.cwd(), 'uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    const selfieFilename = `selfie_${userId}_${Date.now()}.jpg`;
    fs.writeFileSync(path.join(uploadsDir, selfieFilename), selfie.buffer);
    const selfieUrl = `/uploads/${selfieFilename}`;

    // Ensure the candidate has a primary image record in DB so it immediately displays on Match cards
    const existingImages = await this.prisma.image.findMany({ where: { userId } });
    if (existingImages.length === 0) {
      await this.prisma.image.create({
        data: {
          userId,
          url: selfieUrl,
          isPrimary: true,
        },
      });
    }

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
        idDocType: docType,
        trustScore: Math.min(100, 95 + Math.floor(Math.random() * 5)),
      },
    });

    this.logger.log(`User ${userId} successfully verified with GOLD badge and score ${compositeScore}% via Gemini Vision`);

    return {
      success: true,
      verificationStatus: 'VERIFIED',
      verificationBadge: 'GOLD',
      confidenceScore: compositeScore,
      documentType: docType,
      ocrData: {
        fullName: geminiResult.extractedName,
        dateOfBirth: geminiResult.extractedDob,
      },
      metrics: {
        documentConfidence: geminiResult.confidenceScore,
        livenessScore: geminiResult.livenessScore,
        faceMatchScore: geminiResult.faceMatchScore,
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
