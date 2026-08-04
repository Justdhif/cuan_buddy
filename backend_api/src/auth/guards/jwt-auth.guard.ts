import { ExecutionContext, Injectable, Inject, UnauthorizedException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { DATABASE_CONNECTION } from '../../database/database.module';
import { eq } from 'drizzle-orm';
import { userProfiles, users } from '../../database/schema';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
  ) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest();
    const waPhoneNumber = request.headers['x-wa-phone-number'];

    if (waPhoneNumber) {
      return this.validateWaConnection(request, String(waPhoneNumber));
    }

    return super.canActivate(context);
  }

  private async validateWaConnection(request: any, phoneNumber: string): Promise<boolean> {
    const profile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.phoneNumber, phoneNumber),
    });

    if (!profile) {
      throw new UnauthorizedException('Nomor WhatsApp belum terhubung ke akun CuanBuddy.');
    }

    const user = await this.db.query.users.findFirst({
      where: eq(users.id, profile.userId),
    });

    if (!user) {
      throw new UnauthorizedException('User tidak ditemukan.');
    }

    if (user.isActive !== true) {
      throw new UnauthorizedException('Akun belum aktif atau telah dinonaktifkan.');
    }

    request.user = { userId: user.id, email: user.email };
    return true;
  }
}

