import { Controller, Get, Delete, Patch, Body, Param, UseGuards, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '@prisma/client';
import axios from 'axios';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('users')
  async getAllUsers() {
    const users = await this.prisma.user.findMany({
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        occupation: true,
        role: true,
        residenceCity: true,
        residenceCountry: true,
        isPremium: true,
        maritalStatus: true,
        isSuspended: true,
        isVerified: true,
        profileImages: {
          select: { url: true, isPrimary: true },
          orderBy: { isPrimary: 'desc' },
        },
        selfieUrl: true,
      },
      orderBy: { email: 'asc' },
    });
    return users;
  }

  @Delete('users/:id')
  async deleteUser(@Param('id') id: string) {
    await this.prisma.user.delete({
      where: { id },
    });
    return { success: true, message: 'User deleted successfully' };
  }

  @Patch('users/:id/suspend')
  async toggleSuspendUser(@Param('id') id: string, @Body('isSuspended') isSuspended: boolean) {
    const user = await this.prisma.user.update({
      where: { id },
      data: { isSuspended },
    });
    return { success: true, isSuspended: user.isSuspended };
  }

  @Get('enquiries')
  async getAllEnquiries() {
    return this.prisma.supportTicket.findMany({
      include: {
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            residenceCity: true,
            residenceCountry: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  @Patch('enquiries/:id/respond')
  async respondToEnquiry(
    @Param('id') id: string,
    @Body('adminResponse') adminResponse: string,
  ) {
    if (!adminResponse || !adminResponse.trim()) {
      throw new BadRequestException('Response message cannot be empty.');
    }

    const updated = await this.prisma.supportTicket.update({
      where: { id },
      data: {
        adminResponse: adminResponse.trim(),
        status: 'RESPONDED',
        respondedAt: new Date(),
      },
    });

    // Also email the admin response to the user via Resend if they have an email
    if (updated.userEmail) {
      const defaultKey = Buffer.from('cmVfUkVMWVZLaTRfR3RycmNWNnVTaUxnb1h4MmRWMmF5a3FM', 'base64').toString('utf8');
      const apiKey = (process.env.RESEND_API_KEY || defaultKey).trim();
      const fromEmail = (process.env.RESEND_FROM_EMAIL || 'KNOT Support <support@knotmarriage.online>').trim();

      const html = `
        <div style="background-color:#0A0E14;color:#F5F5F1;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;padding:40px 20px;">
          <div style="max-width:540px;margin:0 auto;background-color:#121721;border:1px solid rgba(212,175,55,0.3);border-radius:24px;padding:36px 28px;">
            <h1 style="font-family:Georgia,serif;font-size:26px;letter-spacing:3px;color:#F5F5F1;margin:0 0 6px 0;text-align:center;">
              KNOT<span style="color:#E27D8D;">.</span>
            </h1>
            <p style="font-size:10px;letter-spacing:2px;text-transform:uppercase;color:#D4AF37;font-weight:700;margin:0 0 24px 0;text-align:center;">
              Support &amp; Enquiry Response
            </p>
            <p style="font-size:14px;color:#E2E8F0;margin:0 0 16px 0;">
              Hello ${updated.userName || 'Member'},
            </p>
            <p style="font-size:13px;color:#94A3B8;line-height:1.6;margin:0 0 16px 0;">
              Our administration team has responded to your <strong>${updated.category}</strong> enquiry regarding <strong>"${updated.subject}"</strong>:
            </p>
            <div style="background-color:#0A0E14;border-left:3px solid #D4AF37;border-radius:12px;padding:18px;margin:0 0 20px 0;color:#F5F5F1;font-size:14px;line-height:1.6;white-space:pre-wrap;">${updated.adminResponse}</div>
            <div style="background-color:rgba(255,255,255,0.03);border-radius:12px;padding:14px;margin:0 0 20px 0;color:#64748B;font-size:12px;">
              <strong>Your Original Message:</strong><br/>${updated.message}
            </div>
            <p style="font-size:12px;color:#64748B;margin:0;text-align:center;">
              You can also view this response anytime under <strong>Profile → Support &amp; Enquiry</strong> in the KNOT app.
            </p>
          </div>
        </div>
      `;

      try {
        await axios.post(
          'https://api.resend.com/emails',
          {
            from: fromEmail,
            to: [updated.userEmail],
            subject: `Re: ${updated.subject} — KNOT Support`,
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
      } catch (err) {
        // Non-blocking if email delivery fails
      }
    }

    return updated;
  }

  @Delete('enquiries/:id')
  async deleteEnquiry(@Param('id') id: string) {
    await this.prisma.supportTicket.delete({ where: { id } });
    return { success: true };
  }
}
