import {
  Injectable,
  Inject,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { eq } from 'drizzle-orm';
import * as bcrypt from 'bcrypt';
import { DATABASE_CONNECTION } from '../database/database.module';
import { users, userProfiles } from '../database/schema';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    const hashedPassword = await bcrypt.hash(registerDto.password, 10);

    try {
      // Optimized: rely on DB unique constraint instead of a separate findFirst query
      const newUser = await this.db.transaction(async (tx) => {
        const [insertedUser] = await tx
          .insert(users)
          .values({
            email: registerDto.email,
            passwordHash: hashedPassword,
          })
          .returning({ id: users.id, email: users.email });

        const avatarValue =
          registerDto.avatar ||
          `https://api.dicebear.com/8.x/avataaars/svg?seed=${registerDto.fullName.replace(/\s+/g, '')}`;

        await tx.insert(userProfiles).values({
          userId: insertedUser.id,
          fullName: registerDto.fullName,
          avatar: avatarValue,
        });

        return insertedUser;
      });

      return this.generateTokens(newUser.id, newUser.email);
    } catch (err: any) {
      // PostgreSQL unique violation error code: 23505
      if (err?.code === '23505' || err?.message?.includes('unique')) {
        throw new ConflictException('Email already exists');
      }
      throw err;
    }
  }

  async login(loginDto: LoginDto) {
    // Optimized: only select fields we actually need, not SELECT *
    const [user] = await this.db
      .select({
        id: users.id,
        email: users.email,
        passwordHash: users.passwordHash,
      })
      .from(users)
      .where(eq(users.email, loginDto.email))
      .limit(1);

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(
      loginDto.password,
      user.passwordHash,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Fire-and-forget: update lastLoginAt without blocking the response
    void this.db
      .update(users)
      .set({ lastLoginAt: new Date() })
      .where(eq(users.id, user.id));

    return this.generateTokens(user.id, user.email);
  }

  async refresh(userId: string, email: string) {
    return this.generateTokens(userId, email);
  }

  private generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };

    return {
      accessToken: this.jwtService.sign(payload),
      refreshToken: this.jwtService.sign(payload, { expiresIn: '7d' }),
    };
  }
}
