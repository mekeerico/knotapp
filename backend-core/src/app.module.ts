import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { MatchesModule } from './matches/matches.module';
import { MessagesModule } from './messages/messages.module';
import { AIModule } from './ai/ai.module';
import { PaymentsModule } from './payments/payments.module';
import { VerificationModule } from './verification/verification.module';

@Module({
  imports: [
    AuthModule,
    UsersModule,
    MatchesModule,
    MessagesModule,
    AIModule,
    PaymentsModule,
    VerificationModule,
  ],
  controllers: [AppController],
  providers: [AppService, PrismaService],
})
export class AppModule {}
