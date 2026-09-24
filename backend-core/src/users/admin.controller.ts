import { Controller, Get, Delete, Patch, Body, Param, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '@prisma/client';

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
        profileImages: { select: { url: true, isPrimary: true } },
        selfieUrl: true,
      },
      orderBy: { email: 'asc' } // No createdAt currently in User, so order by email
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
}
