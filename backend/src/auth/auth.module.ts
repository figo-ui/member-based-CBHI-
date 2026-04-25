import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { SmsModule } from '../sms/sms.module';
import { User } from '../users/user.entity';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { PasskeyCredential } from './passkey-credential.entity';
import { PasskeyController } from './passkey.controller';
import { PasskeyService } from './passkey.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Beneficiary, PasskeyCredential]),
    SmsModule,
    JwtModule.registerAsync({
      useFactory: () => {
        const isProduction = process.env.NODE_ENV === 'production';
        const privateKey = process.env.AUTH_JWT_PRIVATE_KEY;

        if (isProduction && privateKey) {
          return {
            privateKey: privateKey.replace(/\\n/g, '\n'), // handle escaped newlines in env vars
            signOptions: {
              algorithm: 'RS256',
              expiresIn: Number(process.env.AUTH_ACCESS_TOKEN_TTL_SECONDS ?? 86400),
            },
          };
        }

        // Development/test fallback: HS256
        return {
          secret: process.env.AUTH_JWT_SECRET ?? 'maya-city-cbhi-secret',
          signOptions: {
            expiresIn: Number(process.env.AUTH_ACCESS_TOKEN_TTL_SECONDS ?? 86400),
          },
        };
      },
    }),
  ],
  controllers: [AuthController, PasskeyController],
  providers: [AuthService, PasskeyService],
  exports: [AuthService, PasskeyService, JwtModule],
})
export class AuthModule {}
