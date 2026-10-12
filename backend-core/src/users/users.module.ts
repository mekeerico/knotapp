import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { AdminController } from './admin.controller';
import { PrismaService } from '../prisma/prisma.service';
import { AIService } from '../ai/ai.service';
import { VerificationModule } from '../verification/verification.module';

@Module({
  imports: [VerificationModule],
  controllers: [UsersController, AdminController],
  providers: [UsersService, PrismaService, AIService],
  exports: [UsersService],
})
export class UsersModule {}
