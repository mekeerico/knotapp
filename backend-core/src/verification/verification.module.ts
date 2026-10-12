import { Module } from '@nestjs/common';
import { DiditService } from './didit.service';
import { VerificationService } from './verification.service';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  providers: [DiditService, VerificationService, PrismaService],
  exports: [DiditService, VerificationService],
})
export class VerificationModule {}
