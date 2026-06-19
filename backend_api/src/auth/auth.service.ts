import {
  Injectable,
  Inject,
  UnauthorizedException,
  ForbiddenException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { eq } from 'drizzle-orm';
import * as bcrypt from 'bcrypt';
import { DATABASE_CONNECTION } from '../database/database.module';
import { users, userProfiles } from '../database/schema';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { EmailService } from '../email/email.service';

@Injectable()
export class AuthService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly jwtService: JwtService,
    private readonly emailService: EmailService,
  ) {}

  async register(registerDto: RegisterDto) {
    const hashedPassword = await bcrypt.hash(registerDto.password, 10);

    try {
      // Optimized: rely on DB unique constraint instead of a separate findFirst query
      const [insertedUser] = await this.db
        .insert(users)
        .values({
          email: registerDto.email,
          passwordHash: hashedPassword,
        })
        .returning({ id: users.id, email: users.email });

      const avatarValue =
        registerDto.avatar ||
        `https://api.dicebear.com/8.x/avataaars/png?seed=${insertedUser.id}`;

      await this.db.insert(userProfiles).values({
        userId: insertedUser.id,
        fullName: registerDto.fullName,
        avatar: avatarValue,
      });

      const newUser = insertedUser;

      return {
        message: 'Registration successful. Please verify your email to log in.',
      };
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
        isActive: users.isActive,
      })
      .from(users)
      .where(eq(users.email, loginDto.email))
      .limit(1);

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isActive) {
      throw new ForbiddenException('Account is not active. Please check your email for verification.');
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

  async checkStatus(email: string) {
    const [user] = await this.db
      .select({ isActive: users.isActive })
      .from(users)
      .where(eq(users.email, email))
      .limit(1);

    if (!user) {
      throw new BadRequestException('User not found');
    }

    return { isActive: user.isActive };
  }

  async sendVerificationEmail(email: string) {
    const [user] = await this.db
      .select({ id: users.id, isActive: users.isActive, email: users.email })
      .from(users)
      .where(eq(users.email, email))
      .limit(1);

    if (!user) {
      throw new BadRequestException('User not found');
    }

    if (user.isActive) {
      throw new BadRequestException('Account is already verified');
    }

    // Generate a verification token
    const verificationToken = this.jwtService.sign(
      { sub: user.id, purpose: 'verify_email' },
      { expiresIn: '1h' },
    );

    // Send the email
    await this.emailService.sendVerificationEmail(user.email, verificationToken);

    return { message: 'Verification email sent successfully.' };
  }

  async verifyEmail(token: string) {
    try {
      const payload = this.jwtService.verify(token);
      if (payload.purpose !== 'verify_email') {
        throw new BadRequestException('Invalid verification token');
      }

      const [updatedUser] = await this.db
        .update(users)
        .set({ isActive: true, updatedAt: new Date() })
        .where(eq(users.id, payload.sub))
        .returning();

      if (!updatedUser) {
        throw new BadRequestException('User not found');
      }

      return { message: 'Your account has been successfully verified. Please log in.' };
    } catch (error) {
      throw new BadRequestException('Verification token is invalid or has expired.');
    }
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    // 1. Check if user exists
    const [user] = await this.db
      .select({ id: users.id, email: users.email })
      .from(users)
      .where(eq(users.email, dto.email))
      .limit(1);

    // To prevent email enumeration, always return success even if not found
    if (!user) {
      return { message: 'If the email is registered, an OTP code has been sent.' };
    }

    // 2. Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString(); // Always 6 digits

    // 3. Set expiration (15 minutes from now)
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 15);

    // 4. Update DB (fire-and-forget logic for speed, but here we wait to ensure it's saved)
    await this.db
      .update(users)
      .set({
        resetOtp: otp,
        resetOtpExpiresAt: expiresAt,
        updatedAt: new Date(),
      })
      .where(eq(users.id, user.id));

    // 5. Send Email
    void this.emailService.sendPasswordResetOtp(user.email, otp);

    return { message: 'If the email is registered, an OTP code has been sent.' };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const [user] = await this.db
      .select({
        id: users.id,
        resetOtp: users.resetOtp,
        resetOtpExpiresAt: users.resetOtpExpiresAt,
      })
      .from(users)
      .where(eq(users.email, dto.email))
      .limit(1);

    if (!user || user.resetOtp !== dto.otp) {
      throw new BadRequestException('Invalid OTP or incorrect email.');
    }

    if (!user.resetOtpExpiresAt || new Date() > user.resetOtpExpiresAt) {
      throw new BadRequestException('OTP code has expired.');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);

    // Update password and clear OTP
    await this.db
      .update(users)
      .set({
        passwordHash: hashedPassword,
        resetOtp: null,
        resetOtpExpiresAt: null,
        updatedAt: new Date(),
      })
      .where(eq(users.id, user.id));

    return { message: 'Password changed successfully. Please log in with your new password.' };
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const [user] = await this.db
      .select({
        id: users.id,
        passwordHash: users.passwordHash,
      })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new BadRequestException('User not found');
    }

    const isPasswordValid = await bcrypt.compare(dto.oldPassword, user.passwordHash);

    if (!isPasswordValid) {
      throw new BadRequestException('Incorrect old password');
    }

    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);

    await this.db
      .update(users)
      .set({
        passwordHash: hashedPassword,
        updatedAt: new Date(),
      })
      .where(eq(users.id, user.id));

    return { message: 'Password changed successfully' };
  }

  private generateTokens(userId: string, email: string) {
    // We embed isActive: true in the token because if they reached here, they are active.
    // The JwtStrategy will check this payload.
    const payload = { sub: userId, email, isActive: true };

    return {
      accessToken: this.jwtService.sign(payload),
      refreshToken: this.jwtService.sign(payload, { expiresIn: '7d' }),
    };
  }
}
