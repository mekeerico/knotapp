import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Put,
  Delete,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { VerificationService } from '../verification/verification.service';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly verificationService: VerificationService,
  ) {}

  @UseGuards(JwtAuthGuard)
  @Post('verify-identity')
  @UseInterceptors(
    FileFieldsInterceptor([
      { name: 'idFront', maxCount: 1 },
      { name: 'idBack', maxCount: 1 },
      { name: 'selfie', maxCount: 1 },
    ]),
  )
  async verifyIdentity(
    @Request() req: any,
    @UploadedFiles()
    files: {
      idFront?: Express.Multer.File[];
      idBack?: Express.Multer.File[];
      selfie?: Express.Multer.File[];
    },
    @Body() body?: any,
  ) {
    return this.verificationService.verifyIdentity(req.user.id, files as any, body);
  }

  @UseGuards(JwtAuthGuard)
  @Get('verification-session')
  async getVerificationSession(@Request() req: any) {
    return this.verificationService.createDiditSession(req.user.id);
  }

  @Get()
  async getAll() {
    return this.usersService.findAll();
  }

  @Post('seed')
  async seedUsers(@Body('users') users: any[]) {
    return this.usersService.seedUsers(users);
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  async getProfile(@Request() req: any) {
    return this.usersService.findOne(req.user.id);
  }

  @Get(':id')
  async getById(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Delete(':id')
  async deleteUser(@Param('id') id: string) {
    return this.usersService.deleteUser(id);
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() dto: any) {
    return this.usersService.updateProfile(id, dto);
  }

  @Post(':id/onboarding')
  async completeOnboarding(@Param('id') id: string, @Body('transcript') transcript: any) {
    return this.usersService.completeOnboarding(id, transcript);
  }

  @Post(':id/selfie')
  async submitSelfie(@Param('id') id: string, @Body('selfieUrl') selfieUrl: string) {
    return this.usersService.submitSelfie(id, selfieUrl);
  }

  @Get(':id/insights')
  async getInsights(@Param('id') id: string) {
    return this.usersService.getInsights(id);
  }

  @Post('onboarding/validate-answer')
  async validateAnswer(@Body('question') question: string, @Body('answer') answer: string) {
    return this.usersService.validateOnboardingAnswer(question, answer);
  }

  @Post('onboarding/verify')
  async verifyDocuments(
    @Body('selfieUrl') selfieUrl: string,
    @Body('idUrl') idUrl: string,
    @Body('firstName') firstName: string,
    @Body('lastName') lastName: string,
    @Body('dateOfBirth') dateOfBirth: string,
  ) {
    return this.usersService.verifyOnboardingDocuments(selfieUrl, idUrl, firstName, lastName, dateOfBirth);
  }
}
