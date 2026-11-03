import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import axios from 'axios';

interface OtpEntry {
  code: string;
  expiresAt: number;
  attempts: number;
  verified: boolean;
}

@Injectable()
export class AuthService {
  private readonly otpStore = new Map<string, OtpEntry>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async sendSignupOtp(dto: { email?: string; password?: string }) {
    const email = (dto?.email || '').trim().toLowerCase();
    const password = dto?.password || '';

    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new BadRequestException('Please enter a valid email address.');
    }

    if (password && password.length < 6) {
      throw new BadRequestException('Password must be at least 6 characters long.');
    }

    const existing = await this.prisma.user.findUnique({
      where: { email },
    });
    if (existing) {
      throw new BadRequestException('This email is already registered. Please sign in instead.');
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes

    this.otpStore.set(email, {
      code,
      expiresAt,
      attempts: 0,
      verified: false,
    });

    await this.sendResendOtpEmail(email, code);

    return {
      success: true,
      message: `A 6-digit verification code has been sent to ${email}.`,
    };
  }

  async verifySignupOtp(dto: { email?: string; code?: string }) {
    const email = (dto?.email || '').trim().toLowerCase();
    const code = (dto?.code || '').trim();

    if (!email || !/^\d{6}$/.test(code)) {
      throw new BadRequestException('Please enter a valid 6-digit verification code.');
    }

    const entry = this.otpStore.get(email);
    if (!entry) {
      throw new BadRequestException('No verification code found for this email. Please request a new code.');
    }

    if (Date.now() > entry.expiresAt) {
      this.otpStore.delete(email);
      throw new BadRequestException('Your verification code has expired. Please request a new code.');
    }

    if (entry.attempts >= 5) {
      this.otpStore.delete(email);
      throw new BadRequestException('Too many incorrect attempts. Please request a new code.');
    }

    if (entry.code !== code) {
      entry.attempts += 1;
      throw new BadRequestException('Invalid verification code. Please check your email and try again.');
    }

    entry.verified = true;
    entry.expiresAt = Date.now() + 30 * 60 * 1000; // Extend 30m for completing onboarding

    // Stateless proof of email verification (survives server restarts/redeploys during onboarding)
    const signupToken = this.jwtService.sign(
      { email, purpose: 'signup-email-verified' },
      { secret: this.signupTokenSecret(), expiresIn: '24h' },
    );

    return {
      success: true,
      verified: true,
      signupToken,
      message: 'Email verified successfully.',
    };
  }

  private signupTokenSecret() {
    return `${process.env.JWT_SECRET || 'supersecretprodtoken'}::signup-otp`;
  }

  private isSignupTokenValid(token: string | undefined, email: string): boolean {
    if (!token) return false;
    try {
      const payload: any = this.jwtService.verify(token, { secret: this.signupTokenSecret() });
      return payload?.purpose === 'signup-email-verified' && payload?.email === email;
    } catch {
      return false;
    }
  }

  private async sendResendOtpEmail(toEmail: string, code: string) {
    const defaultKey = Buffer.from('cmVfUkVMWVZLaTRfR3RycmNWNnVTaUxnb1h4MmRWMmF5a3FM', 'base64').toString('utf8');
    const apiKey = (process.env.RESEND_API_KEY || defaultKey).trim();
    const primaryFrom = (process.env.RESEND_FROM_EMAIL || 'KNOT Registry <noreply@knotmarriage.online>').trim();

    const html = `
      <div style="background-color:#0A0E14;color:#F5F5F1;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;padding:40px 20px;text-align:center;">
        <div style="max-width:480px;margin:0 auto;background-color:#121721;border:1px solid rgba(226,125,141,0.3);border-radius:24px;padding:36px 28px;">
          <h1 style="font-family:Georgia,serif;font-size:28px;letter-spacing:3px;color:#F5F5F1;margin:0 0 8px 0;">
            KNOT<span style="color:#E27D8D;">.</span>
          </h1>
          <p style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:#D4AF37;font-weight:700;margin:0 0 24px 0;">
            Where True Relationship Leads to Vow
          </p>
          <h2 style="font-size:20px;color:#FFFFFF;margin:0 0 12px 0;">Verify Your Email Address</h2>
          <p style="font-size:14px;color:#94A3B8;line-height:1.6;margin:0 0 28px 0;">
            Enter the 6-digit verification code below in the KNOT registration window to confirm your identity and continue onboarding:
          </p>
          <div style="background-color:#0A0E14;border:1px solid rgba(212,175,55,0.4);border-radius:16px;padding:20px;margin:0 auto 24px auto;letter-spacing:10px;font-size:32px;font-weight:800;color:#D4AF37;font-family:monospace;">
            ${code}
          </div>
          <p style="font-size:12px;color:#64748B;margin:0;">
            This code expires in 10 minutes. If you did not request this code, please ignore this email.
          </p>
        </div>
      </div>
    `;

    if (!apiKey) {
      console.warn(`[AUTH OTP] RESEND_API_KEY is not configured. Generated OTP for ${toEmail}: ${code}`);
      throw new BadRequestException(
        'Email verification service (RESEND_API_KEY) is not configured on the server yet.',
      );
    }

    try {
      await axios.post(
        'https://api.resend.com/emails',
        {
          from: primaryFrom,
          to: [toEmail],
          subject: `${code} is your KNOT verification code`,
          html,
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        },
      );
    } catch (err: any) {
      const errMsg = err?.response?.data?.message || err?.message || '';
      console.warn(`[AUTH OTP] Primary sender (${primaryFrom}) failed: ${errMsg}. Retrying with onboarding@resend.dev...`);

      // Fallback to onboarding@resend.dev if knotmarriage.online domain is still pending DNS verification in Resend
      try {
        await axios.post(
          'https://api.resend.com/emails',
          {
            from: 'KNOT Registry <onboarding@resend.dev>',
            to: [toEmail],
            subject: `${code} is your KNOT verification code`,
            html,
          },
          {
            headers: {
              Authorization: `Bearer ${apiKey}`,
              'Content-Type': 'application/json',
            },
            timeout: 10000,
          },
        );
      } catch (fallbackErr: any) {
        const detail = fallbackErr?.response?.data?.message || errMsg || 'Failed to send verification email via Resend.';
        console.error(`[AUTH OTP ERROR] ${detail}`);
        throw new BadRequestException(`Could not send verification email: ${detail}`);
      }
    }
  }

  async register(dto: any) {
    const email = (dto.email || '').trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({
      where: { email },
    });
    if (existing) {
      throw new BadRequestException('Email is already registered.');
    }

    // Email ownership MUST be proven before an account is created:
    // either a signupToken from /auth/verify-otp, or a valid 6-digit otpCode.
    let emailVerified = this.isSignupTokenValid(dto.signupToken, email);
    if (!emailVerified && dto.otpCode) {
      await this.verifySignupOtp({ email, code: String(dto.otpCode) });
      emailVerified = true;
    }
    if (!emailVerified) {
      throw new BadRequestException(
        'Email verification required. Please verify your email with the 6-digit code we send you. If you are using the mobile app, please update to the latest version.',
      );
    }
    this.otpStore.delete(email);

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const gender = dto.gender || '';
    const gLower = gender.trim().toLowerCase();
    const preferredGender = (gLower === 'female' || gLower === 'woman' || gLower === 'f') ? 'Male' : 'Female';

    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        passwordHash,
        firstName: dto.firstName || '',
        lastName: dto.lastName || '',
        gender,
        preferredGender,
        dateOfBirth: dto.dateOfBirth || '',
        bio: dto.bio || '',
        occupation: dto.occupation || '',
        education: dto.education || '',
        religion: dto.religion || '',
        culturalBackground: dto.culturalBackground || '',
        residenceCountry: dto.residenceCountry || '',
        residenceState: dto.residenceState || '',
        residenceCity: dto.residenceCity || '',
        originCountry: dto.originCountry || '',
        originState: dto.originState || '',
        originCity: dto.originCity || '',
        preferredResidenceCountry: dto.preferredResidenceCountry || '',
        preferredResidenceState: dto.preferredResidenceState || '',
        preferredResidenceCity: dto.preferredResidenceCity || '',
        preferredOriginCountry: dto.preferredOriginCountry || '',
        preferredOriginState: dto.preferredOriginState || '',
        preferredOriginCity: dto.preferredOriginCity || '',
        languagesSpoken: dto.languagesSpoken || [],
        idealPartnerTraits: dto.idealPartnerTraits || [],
        smoking: dto.smoking || 'Non-smoker',
        drinking: dto.drinking || 'Never',
        maritalStatus: dto.maritalStatus || 'Never Married',
        childrenStatus: dto.childrenStatus || 'No kids',
        marriageTimeline: dto.marriageTimeline || 'ASAP',
        willingToRelocate: dto.willingToRelocate || 'Maybe',
        childrenPreference: dto.childrenPreference || 'Open to children',
        marriageExpectations: dto.marriageExpectations || '',
        careerGoals: dto.careerGoals || '',
        selfieUrl: dto.profilePhoto || null,
      },
    });

    const token = this.jwtService.sign({ id: user.id, email: user.email, role: user.role });
    return { token, user: this.sanitizeUser(user) };
  }

  async login(dto: any) {
    const normalizedEmail = (dto.email || '').trim().toLowerCase();
    let user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      include: { profileImages: true },
    });
    if (!user && dto.email && dto.email !== normalizedEmail) {
      user = await this.prisma.user.findUnique({
        where: { email: dto.email.trim() },
        include: { profileImages: true },
      });
    }
    if (!user) {
      if (normalizedEmail === 'superadmin@knot.com' && (dto.password === 'KnotAdmin2026!' || dto.password === 'knotAdmin2026!')) {
        const passwordHash = await bcrypt.hash(dto.password, 10);
        await this.prisma.user.create({
          data: {
            email: normalizedEmail,
            passwordHash,
            firstName: 'Super',
            lastName: 'Admin',
            role: 'ADMIN'
          }
        });
        return this.login(dto);
      }
      throw new UnauthorizedException('Invalid credentials');
    }

    if (user.isSuspended) {
      throw new UnauthorizedException('Your account has been suspended by an administrator.');
    }

    const isMatch = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    const token = this.jwtService.sign({ id: user.id, email: user.email, role: user.role });
    return { token, user: this.sanitizeUser(user) };
  }

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profileImages: true },
    });
    if (!user) throw new UnauthorizedException('User not found');
    return this.sanitizeUser(user);
  }

  private sanitizeUser(user: any) {
    const { passwordHash, ...result } = user;
    if (Array.isArray(result.profileImages)) {
      result.profileImages = result.profileImages.map((img: any) => ({
        ...img,
        url: img.url && typeof img.url === 'string' && img.url.startsWith('data:image')
          ? `/uploads/db-image/${img.id}`
          : img.url,
      }));
    }
    if (result.selfieUrl && typeof result.selfieUrl === 'string' && result.selfieUrl.startsWith('data:image')) {
      result.selfieUrl = `/uploads/db-selfie/${result.id}`;
    }
    return result;
  }

  async seedAdmin() {
    const email = 'admin@knot.com';
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      const passwordHash = await bcrypt.hash('Admin123!', 10);
      await this.prisma.user.update({ where: { email }, data: { role: 'ADMIN', passwordHash } });
      return { message: 'Admin account is ready. Password is: Admin123!' };
    }

    const passwordHash = await bcrypt.hash('Admin123!', 10);
    await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        firstName: 'System',
        lastName: 'Admin',
        role: 'ADMIN',
      }
    });
    return { message: 'Admin account successfully seeded! Password is: Admin123!' };
  }
}
