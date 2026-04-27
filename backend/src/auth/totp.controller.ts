import {
  BadRequestException,
  Body,
  Controller,
  Post,
} from '@nestjs/common';
import { IsString } from 'class-validator';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../users/user.entity';
import { AuthService } from './auth.service';
import { TotpService } from './totp.service';
import { TotpActivateDto } from './auth.dto';

class TotpVerifyBodyDto {
  @IsString()
  token!: string;

  @IsString()
  pendingToken!: string;
}

/**
 * TOTP (Time-based One-Time Password) endpoints for admin 2FA.
 *
 * Flow:
 *   1. POST /auth/totp/setup    — requires JWT auth; generates secret + QR URI
 *   2. POST /auth/totp/activate — requires JWT auth; verifies first token, enables TOTP
 *   3. POST /auth/totp/verify   — PUBLIC; exchanges { pendingToken, token } for full session
 */
@Controller('auth/totp')
export class TotpController {
  constructor(
    private readonly authService: AuthService,
    private readonly totpService: TotpService,
  ) {}

  /**
   * Initiate TOTP setup for the currently authenticated user.
   * Returns { secret, qrUri } — display the QR URI to the user once.
   * Requires a valid JWT (user must be logged in with a full session).
   */
  @Post('setup')
  async setup(@CurrentUser() user: User) {
    return this.authService.setupTotp(user.id, this.totpService);
  }

  /**
   * Activate TOTP after the user scans the QR and enters the first token.
   * Requires a valid JWT (user must be logged in with a full session).
   */
  @Post('activate')
  async activate(
    @CurrentUser() user: User,
    @Body() dto: TotpActivateDto,
  ) {
    return this.authService.activateTotp(user.id, dto.token, this.totpService);
  }

  /**
   * Verify TOTP during login (second factor).
   *
   * This endpoint is @Public because the pending token is NOT a full session token
   * and would be rejected by the standard JwtAuthGuard.
   *
   * Body: { pendingToken: string, token: string }
   *   - pendingToken: the short-lived JWT returned by POST /auth/login when TOTP is required
   *   - token: the 6-digit TOTP code from the authenticator app
   *
   * Returns a full session (accessToken, refreshToken, user profile) on success.
   */
  @Public()
  @Post('verify')
  async verify(@Body() body: TotpVerifyBodyDto) {
    if (!body.pendingToken) {
      throw new BadRequestException('pendingToken is required.');
    }
    if (!body.token) {
      throw new BadRequestException('token is required.');
    }
    return this.authService.verifyTotpLogin(
      body.pendingToken,
      body.token,
      this.totpService,
    );
  }
}
