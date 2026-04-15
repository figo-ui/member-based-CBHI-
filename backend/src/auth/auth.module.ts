import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { SmsModule } from '../sms/sms.module';
import { User } from '../users/user.entity';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { TotpService } from './totp.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Beneficiary]),
    SmsModule,
    // FIX QW-6: Use @nestjs/jwt instead of hand-rolled HMAC-SHA256 JWT.
    // Secret is read at runtime so it picks up the env var after bootstrap.
    JwtModule.registerAsync({
      useFactory: () => ({
        secret: process.env.AUTH_JWT_SECRET ?? 'maya-city-cbhi-secret',
        signOptions: {
          expiresIn: `${process.env.AUTH_ACCESS_TOKEN_TTL_SECONDS ?? 86400}s`,
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, TotpService],
  exports: [AuthService, JwtModule],
})
export class AuthModule {}
