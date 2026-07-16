import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Strategy khusus untuk memverifikasi Refresh Token.
 * Menggunakan JWT_REFRESH_SECRET yang berbeda dari access token,
 * sehingga refresh token tidak bisa dipakai sebagai access token
 * dan sebaliknya.
 */
@Injectable()
export class RefreshJwtStrategy extends PassportStrategy(Strategy, 'jwt-refresh') {
  constructor(private configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_REFRESH_SECRET')!,
    });
  }

  async validate(payload: any) {
    // Pastikan token ini memang refresh token (bukan access token)
    if (payload.tokenType !== 'refresh') {
      throw new UnauthorizedException('Token tidak valid untuk operasi refresh.');
    }
    return { userId: payload.sub, email: payload.email };
  }
}
