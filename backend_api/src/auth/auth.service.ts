import { Injectable, Inject, UnauthorizedException, ConflictException } from '@nestjs/common';
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
    const existingUser = await this.db.query.users.findFirst({
      where: eq(users.email, registerDto.email),
    });

    if (existingUser) {
      throw new ConflictException('Email already exists');
    }

    const hashedPassword = await bcrypt.hash(registerDto.password, 10);

    const newUser = await this.db.transaction(async (tx) => {
      const [insertedUser] = await tx
        .insert(users)
        .values({
          email: registerDto.email,
          passwordHash: hashedPassword,
        })
        .returning();

      const avatarValue = registerDto.avatar 
        || `https://api.dicebear.com/8.x/avataaars/svg?seed=${registerDto.fullName.replace(/\s+/g, '')}`;

      await tx.insert(userProfiles).values({
        userId: insertedUser.id,
        fullName: registerDto.fullName,
        avatar: avatarValue,
      });

      return insertedUser;
    });

    return this.generateTokens(newUser.id, newUser.email);
  }

  async login(loginDto: LoginDto) {
    const user = await this.db.query.users.findFirst({
      where: eq(users.email, loginDto.email),
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(loginDto.password, user.passwordHash);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    await this.db.update(users)
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
      // In a real app, you might want to use a different secret/expiration for refresh tokens
      refreshToken: this.jwtService.sign(payload, { expiresIn: '7d' }), 
    };
  }
}
