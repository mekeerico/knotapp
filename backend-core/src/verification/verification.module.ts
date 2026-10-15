import { Module } from '@nestjs/common';
import { DiditService } from './didit.service';
import { GeminiVisionService } from './gemini-vision.service';
import { VerificationService } from './verification.service';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  providers: [DiditService, GeminiVisionService, VerificationService, PrismaService],
  exports: [DiditService, GeminiVisionService, VerificationService],
})
export class VerificationModule {}
