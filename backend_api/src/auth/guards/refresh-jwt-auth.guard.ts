import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Guard khusus untuk endpoint /auth/refresh.
 * Menggunakan strategy 'jwt-refresh' yang memverifikasi dengan
 * JWT_REFRESH_SECRET — bukan JWT_SECRET biasa.
 * 
 * Ini memastikan endpoint refresh hanya bisa diakses dengan
 * refresh token yang valid, bukan access token.
 */
@Injectable()
export class RefreshJwtAuthGuard extends AuthGuard('jwt-refresh') {}
