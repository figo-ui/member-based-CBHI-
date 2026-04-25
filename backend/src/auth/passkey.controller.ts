import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Post,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import { User } from '../users/user.entity';
import { AuthService } from './auth.service';
import { PasskeyAuthenticateDto, PasskeyAuthOptionsDto, PasskeyRegisterDto } from './passkey.dto';
import { PasskeyService } from './passkey.service';

@Controller('auth/passkey')
export class PasskeyController {
  constructor(
    private readonly passkeyService: PasskeyService,
    private readonly authService: AuthService,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  /**
   * POST /api/v1/auth/passkey/register-options
   * Returns WebAuthn credential creation options for the authenticated user.
   * Requires JWT auth.
   */
  @Post('register-options')
  getRegisterOptions(@CurrentUser() user: User) {
    return this.passkeyService.getRegisterOptions(user);
  }

  /**
   * POST /api/v1/auth/passkey/register
   * Verifies the attestation response and stores the new PasskeyCredential.
   * Requires JWT auth.
   * Returns the saved credential (without sensitive fields).
   */
  @Post('register')
  async register(
    @CurrentUser() user: User,
    @Body() dto: PasskeyRegisterDto,
  ) {
    const credential = await this.passkeyService.verifyAndStoreAttestation(user, dto);
    // Return credential without sensitive fields
    return {
      id: credential.id,
      credentialId: credential.credentialId,
      rpId: credential.rpId,
      deviceName: credential.deviceName ?? null,
      lastUsedAt: credential.lastUsedAt ?? null,
      createdAt: credential.createdAt,
    };
  }

  /**
   * POST /api/v1/auth/passkey/authenticate-options
   * Returns WebAuthn credential request options for the given identifier.
   * Public — no JWT required.
   */
  @Public()
  @Post('authenticate-options')
  async getAuthenticateOptions(@Body() dto: PasskeyAuthOptionsDto) {
    // Normalize the identifier (phone or email) and look up the user's credentials
    let user: User | null = null;

    const identifier = dto.identifier.trim();
    const isEmail = identifier.includes('@');

    if (isEmail) {
      user = await this.userRepository
        .createQueryBuilder('user')
        .where('LOWER(user.email) = :email', { email: identifier.toLowerCase() })
        .getOne();
    } else {
      // Normalize phone number via AuthService
      const normalizedPhone = this.authService.normalizePhoneNumber(identifier);
      if (normalizedPhone) {
        user = await this.userRepository
          .createQueryBuilder('user')
          .where('user.phoneNumber = :phone', { phone: normalizedPhone })
          .getOne();
      }
    }

    if (!user) {
      throw new NotFoundException('No account found for that identifier.');
    }

    const credentials = await this.passkeyService.getCredentialsByUser(user.id);
    const credentialIds = credentials.map((c) => c.credentialId);

    return this.passkeyService.getAuthenticateOptions(credentialIds);
  }

  /**
   * POST /api/v1/auth/passkey/authenticate
   * Verifies the WebAuthn assertion and issues a JWT session.
   * Public — no JWT required.
   */
  @Public()
  @Post('authenticate')
  async authenticate(@Body() dto: PasskeyAuthenticateDto) {
    const credential = await this.passkeyService.verifyAssertion(dto);
    // Issue a session for the credential's associated user
    return this.authService.issueSession(credential.user);
  }

  /**
   * DELETE /api/v1/auth/passkey/:credentialId
   * Deletes a specific passkey credential belonging to the authenticated user.
   * Requires JWT auth.
   */
  @Delete(':credentialId')
  async deleteCredential(
    @CurrentUser() user: User,
    @Param('credentialId') credentialId: string,
  ) {
    await this.passkeyService.deleteCredential(user.id, credentialId);
    return { success: true };
  }

  /**
   * GET /api/v1/auth/passkey/credentials
   * Returns all passkey credentials registered for the authenticated user.
   * Requires JWT auth.
   */
  @Get('credentials')
  getCredentials(@CurrentUser() user: User) {
    return this.passkeyService.getCredentialsByUser(user.id);
  }
}
