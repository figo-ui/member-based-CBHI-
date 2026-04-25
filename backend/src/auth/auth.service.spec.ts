import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { BadRequestException, HttpException, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { User } from '../users/user.entity';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { SmsService } from '../sms/sms.service';
import { UserRole, PreferredLanguage } from '../common/enums/cbhi.enums';

const mockRepo = () => ({
  create: jest.fn(),
  save: jest.fn(),
  findOne: jest.fn(),
  createQueryBuilder: jest.fn().mockReturnValue({
    addSelect: jest.fn().mockReturnThis(),
    leftJoinAndSelect: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    getOne: jest.fn(),
  }),
});

const mockSmsService = () => ({
  sendOtp: jest.fn().mockResolvedValue(undefined),
});

const mockJwtService = () => ({
  sign: jest.fn().mockReturnValue('mock.jwt.token'),
  verify: jest.fn().mockReturnValue({ sub: 'user-id', role: UserRole.HOUSEHOLD_HEAD }),
});

describe('AuthService', () => {
  let service: AuthService;
  let userRepo: ReturnType<typeof mockRepo>;
  let jwtService: ReturnType<typeof mockJwtService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: getRepositoryToken(User), useFactory: mockRepo },
        { provide: getRepositoryToken(Beneficiary), useFactory: mockRepo },
        { provide: SmsService, useFactory: mockSmsService },
        { provide: JwtService, useFactory: mockJwtService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    userRepo = module.get(getRepositoryToken(User));
    jwtService = module.get(JwtService);
  });

  describe('normalizePhoneNumber', () => {
    it('normalizes +251 format', () => {
      expect(service.normalizePhoneNumber('+251912345678')).toBe('+251912345678');
    });

    it('normalizes 09 format', () => {
      expect(service.normalizePhoneNumber('0912345678')).toBe('+251912345678');
    });

    it('normalizes 9 format', () => {
      expect(service.normalizePhoneNumber('912345678')).toBe('+251912345678');
    });

    it('normalizes 251 without + format', () => {
      expect(service.normalizePhoneNumber('251912345678')).toBe('+251912345678');
    });

    it('throws for invalid phone', () => {
      expect(() => service.normalizePhoneNumber('123')).toThrow(BadRequestException);
    });

    it('returns undefined for empty input', () => {
      expect(service.normalizePhoneNumber('')).toBeUndefined();
      expect(service.normalizePhoneNumber(null)).toBeUndefined();
    });
  });

  describe('normalizeEmail', () => {
    it('lowercases and trims email', () => {
      expect(service.normalizeEmail('  Test@Example.COM  ')).toBe('test@example.com');
    });

    it('returns undefined for empty', () => {
      expect(service.normalizeEmail('')).toBeUndefined();
    });
  });

  describe('hashPassword / verifyPassword', () => {
    it('hashes and verifies a password correctly', () => {
      const password = 'SecurePass123!';
      const hash = service.hashPassword(password);
      expect(hash).toContain(':');
      // Access private method for testing
      const verify = (service as any).verifyPassword(password, hash);
      expect(verify).toBe(true);
    });

    it('rejects wrong password', () => {
      const hash = service.hashPassword('correct');
      const verify = (service as any).verifyPassword('wrong', hash);
      expect(verify).toBe(false);
    });
  });

  describe('issueSession', () => {
    it('calls jwtService.sign with correct payload', async () => {
      const mockUser: Partial<User> = {
        id: 'user-123',
        firstName: 'Test',
        role: UserRole.HOUSEHOLD_HEAD,
        preferredLanguage: PreferredLanguage.ENGLISH,
        isActive: true,
        phoneNumber: '+251912345678',
        email: null,
        tokenVersion: 0,
      };

      userRepo.findOne.mockResolvedValue(mockUser);
      const qb = userRepo.createQueryBuilder();
      qb.getOne.mockResolvedValue({ ...mockUser, refreshTokenHash: null });

      const result = await service.issueSession('user-123');

      expect(jwtService.sign).toHaveBeenCalledWith(
        expect.objectContaining({
          sub: 'user-123',
          role: UserRole.HOUSEHOLD_HEAD,
          tokenVersion: 0,
        }),
        expect.any(Object),
      );
      expect(result.accessToken).toBe('mock.jwt.token');
      expect(result.tokenType).toBe('Bearer');
    });
  });

  describe('requireUserFromAuthorization', () => {
    it('throws for missing token', async () => {
      await expect(service.requireUserFromAuthorization(undefined)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('throws for invalid token', async () => {
      (jwtService.verify as jest.Mock).mockImplementationOnce(() => {
        throw new Error('invalid token');
      });
      await expect(
        service.requireUserFromAuthorization('Bearer bad.token.here'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws for inactive user', async () => {
      userRepo.findOne.mockResolvedValue({ id: 'user-id', isActive: false });
      await expect(
        service.requireUserFromAuthorization('Bearer valid.token'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  // Feature: member-app-ux-overhaul, Property 6: OTP rate limiting rejects requests beyond the threshold
  describe('OTP rate limiting', () => {
    /**
     * Validates: Requirements 14.1
     *
     * For any phone number, after exactly 3 OTP send requests within a 10-minute
     * window, any subsequent OTP send request SHALL be rejected with HTTP 429.
     */
    it('should allow 3 OTP sends within a 10-minute window and reject the 4th', async () => {
      // Test with several different phone numbers to verify the property holds universally
      const phoneNumbers = [
        '+251911111111',
        '+251922222222',
        '+251933333333',
      ];

      for (const phoneNumber of phoneNumbers) {
        // Reset mocks for each phone number
        jest.clearAllMocks();

        // Base user returned by findUserByTarget
        const baseUser: Partial<User> = {
          id: 'user-rate-limit-test',
          firstName: 'Test',
          role: UserRole.HOUSEHOLD_HEAD,
          isActive: true,
          phoneNumber,
          email: null,
          tokenVersion: 0,
          oneTimeCodeHash: null,
          oneTimeCodePurpose: null,
          oneTimeCodeTarget: null,
          oneTimeCodeExpiresAt: null,
        };

        // findUserByTarget uses createQueryBuilder
        const qbForTarget = {
          addSelect: jest.fn().mockReturnThis(),
          leftJoinAndSelect: jest.fn().mockReturnThis(),
          where: jest.fn().mockReturnThis(),
          andWhere: jest.fn().mockReturnThis(),
          getOne: jest.fn().mockResolvedValue(baseUser),
        };

        // Simulate state: window started now, count already at 3 (threshold reached)
        const userWithRateLimit: Partial<User> = {
          ...baseUser,
          otpRateLimitWindowStart: new Date(), // within the 10-minute window
          otpRateLimitCount: 3,                // already at the limit
        };

        // The second createQueryBuilder call (for rate limit check) returns the rate-limited user
        const qbForRateLimit = {
          addSelect: jest.fn().mockReturnThis(),
          leftJoinAndSelect: jest.fn().mockReturnThis(),
          where: jest.fn().mockReturnThis(),
          andWhere: jest.fn().mockReturnThis(),
          getOne: jest.fn().mockResolvedValue(userWithRateLimit),
        };

        // First call → findUserByTarget, second call → rate limit check
        let callCount = 0;
        userRepo.createQueryBuilder.mockImplementation(() => {
          callCount++;
          return callCount === 1 ? qbForTarget : qbForRateLimit;
        });

        // The 4th request (count already at 3) should throw HTTP 429
        await expect(
          service.sendOtp({ phoneNumber, purpose: 'login' }),
        ).rejects.toThrow(HttpException);

        // Verify it's specifically a 429
        try {
          await service.sendOtp({ phoneNumber, purpose: 'login' });
        } catch (err) {
          expect(err).toBeInstanceOf(HttpException);
          expect((err as HttpException).getStatus()).toBe(429);
          expect((err as HttpException).message).toBe(
            'Too many OTP requests. Try again later.',
          );
        }
      }
    });

    it('should allow OTP sends when window has expired', async () => {
      const phoneNumber = '+251911111111';

      const baseUser: Partial<User> = {
        id: 'user-expired-window',
        firstName: 'Test',
        role: UserRole.HOUSEHOLD_HEAD,
        isActive: true,
        phoneNumber,
        email: null,
        tokenVersion: 0,
        oneTimeCodeHash: null,
        oneTimeCodePurpose: null,
        oneTimeCodeTarget: null,
        oneTimeCodeExpiresAt: null,
      };

      const qbForTarget = {
        addSelect: jest.fn().mockReturnThis(),
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(baseUser),
      };

      // Window started 15 minutes ago (expired)
      const expiredWindowStart = new Date(Date.now() - 15 * 60 * 1000);
      const userWithExpiredWindow: Partial<User> = {
        ...baseUser,
        otpRateLimitWindowStart: expiredWindowStart,
        otpRateLimitCount: 3, // count was at limit, but window expired
      };

      const qbForRateLimit = {
        addSelect: jest.fn().mockReturnThis(),
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(userWithExpiredWindow),
      };

      let callCount = 0;
      userRepo.createQueryBuilder.mockImplementation(() => {
        callCount++;
        return callCount === 1 ? qbForTarget : qbForRateLimit;
      });

      userRepo.save.mockResolvedValue(undefined);

      // Should NOT throw — window expired, so counter resets
      await expect(
        service.sendOtp({ phoneNumber, purpose: 'login' }),
      ).resolves.toBeDefined();
    });

    it('should reset window and allow sends after expiry (property: count resets)', async () => {
      // Property: for any count >= 3, if windowStart is > 10 min ago, the request succeeds
      const testCases = [
        { count: 3, windowAgeMs: 11 * 60 * 1000 }, // 11 min ago — expired
        { count: 5, windowAgeMs: 20 * 60 * 1000 }, // 20 min ago — expired
        { count: 10, windowAgeMs: 60 * 60 * 1000 }, // 1 hour ago — expired
      ];

      for (const { count, windowAgeMs } of testCases) {
        jest.clearAllMocks();

        const baseUser: Partial<User> = {
          id: 'user-reset-test',
          firstName: 'Test',
          role: UserRole.HOUSEHOLD_HEAD,
          isActive: true,
          phoneNumber: '+251911111111',
          email: null,
          tokenVersion: 0,
          oneTimeCodeHash: null,
          oneTimeCodePurpose: null,
          oneTimeCodeTarget: null,
          oneTimeCodeExpiresAt: null,
        };

        const qbForTarget = {
          addSelect: jest.fn().mockReturnThis(),
          leftJoinAndSelect: jest.fn().mockReturnThis(),
          where: jest.fn().mockReturnThis(),
          andWhere: jest.fn().mockReturnThis(),
          getOne: jest.fn().mockResolvedValue(baseUser),
        };

        const userWithOldWindow: Partial<User> = {
          ...baseUser,
          otpRateLimitWindowStart: new Date(Date.now() - windowAgeMs),
          otpRateLimitCount: count,
        };

        const qbForRateLimit = {
          addSelect: jest.fn().mockReturnThis(),
          leftJoinAndSelect: jest.fn().mockReturnThis(),
          where: jest.fn().mockReturnThis(),
          andWhere: jest.fn().mockReturnThis(),
          getOne: jest.fn().mockResolvedValue(userWithOldWindow),
        };

        let callCount = 0;
        userRepo.createQueryBuilder.mockImplementation(() => {
          callCount++;
          return callCount === 1 ? qbForTarget : qbForRateLimit;
        });

        userRepo.save.mockResolvedValue(undefined);

        // Should succeed — window expired
        await expect(
          service.sendOtp({ phoneNumber: '+251911111111', purpose: 'login' }),
        ).resolves.toBeDefined();
      }
    });
  });

  // Feature: member-app-ux-overhaul, Property 9: Password change invalidates all prior sessions via tokenVersion
  describe('tokenVersion session invalidation', () => {
    /**
     * Validates: Requirements 14.7
     *
     * After resetPassword() or setPassword(), tokenVersion is incremented and
     * any JWT with the old tokenVersion fails requireUserFromAuthorization().
     */
    it('should increment tokenVersion after resetPassword and reject old JWTs', async () => {
      // 1. Create a mock user with tokenVersion = 0
      const mockUser: Partial<User> = {
        id: 'user-tv-test',
        firstName: 'Test',
        role: UserRole.HOUSEHOLD_HEAD,
        isActive: true,
        phoneNumber: '+251911111111',
        email: null,
        tokenVersion: 0,
        oneTimeCodeHash: 'some-hash',
        oneTimeCodePurpose: 'password_reset',
        oneTimeCodeTarget: '+251911111111',
        oneTimeCodeExpiresAt: new Date(Date.now() + 10 * 60 * 1000),
      };

      // 2. Mock findUserByTarget to return the user with OTP fields
      const qbForTarget = {
        addSelect: jest.fn().mockReturnThis(),
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(mockUser),
      };
      userRepo.createQueryBuilder.mockReturnValue(qbForTarget);

      // Capture the saved user to verify tokenVersion increment
      let savedUser: Partial<User> | null = null;
      userRepo.save.mockImplementation((u: Partial<User>) => {
        savedUser = { ...u };
        return Promise.resolve(u);
      });

      // Stub assertOtp to pass (we test the tokenVersion increment, not OTP logic)
      // We need to provide a valid OTP hash — use the service's hashValue
      const hashValue = (service as any).hashValue.bind(service);
      const code = '123456';
      (mockUser as any).oneTimeCodeHash = hashValue(`password_reset:${code}`);

      // 3. Call resetPassword — this should increment tokenVersion
      await service.resetPassword({
        identifier: '+251911111111',
        code,
        newPassword: 'NewPassword123!',
      });

      // Verify tokenVersion was incremented to 1
      expect(savedUser).not.toBeNull();
      expect((savedUser as Partial<User>).tokenVersion).toBe(1);

      // 4. Simulate requireUserFromAuthorization with old JWT (tokenVersion: 0)
      // The JWT payload has tokenVersion: 0, but DB user now has tokenVersion: 1

      // First call — verify it throws UnauthorizedException
      (jwtService.verify as jest.Mock).mockReturnValueOnce({
        sub: 'user-tv-test',
        role: UserRole.HOUSEHOLD_HEAD,
        tokenVersion: 0, // old token — before password change
      });
      userRepo.findOne.mockResolvedValueOnce({
        ...mockUser,
        tokenVersion: 1,
        isActive: true,
      });

      await expect(
        service.requireUserFromAuthorization('Bearer old.jwt.token'),
      ).rejects.toThrow(UnauthorizedException);

      // Second call — verify the exact error message
      (jwtService.verify as jest.Mock).mockReturnValueOnce({
        sub: 'user-tv-test',
        role: UserRole.HOUSEHOLD_HEAD,
        tokenVersion: 0, // old token — before password change
      });
      userRepo.findOne.mockResolvedValueOnce({
        ...mockUser,
        tokenVersion: 1,
        isActive: true,
      });

      await expect(
        service.requireUserFromAuthorization('Bearer old.jwt.token'),
      ).rejects.toThrow('Session invalidated. Please sign in again.');
    });

    it('should increment tokenVersion after setPassword and reject old JWTs', async () => {
      // 1. User with tokenVersion = 2
      const mockUser: Partial<User> = {
        id: 'user-sp-test',
        firstName: 'Test',
        role: UserRole.HOUSEHOLD_HEAD,
        isActive: true,
        tokenVersion: 2,
      };

      userRepo.findOne.mockResolvedValueOnce(mockUser);

      let savedUser: Partial<User> | null = null;
      userRepo.save.mockImplementationOnce((u: Partial<User>) => {
        savedUser = { ...u };
        return Promise.resolve(u);
      });

      // 2. Call setPassword
      await service.setPassword('user-sp-test', 'NewPassword456!');

      // tokenVersion should be incremented to 3
      expect(savedUser).not.toBeNull();
      expect((savedUser as Partial<User>).tokenVersion).toBe(3);

      // 3. Old JWT with tokenVersion: 2 should be rejected
      (jwtService.verify as jest.Mock).mockReturnValueOnce({
        sub: 'user-sp-test',
        role: UserRole.HOUSEHOLD_HEAD,
        tokenVersion: 2, // old token
      });

      userRepo.findOne.mockResolvedValueOnce({
        ...mockUser,
        tokenVersion: 3,
        isActive: true,
      });

      await expect(
        service.requireUserFromAuthorization('Bearer old.jwt.token'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should accept JWT with matching tokenVersion after password change', async () => {
      // After password change, a newly issued JWT (tokenVersion: 1) should be accepted
      (jwtService.verify as jest.Mock).mockReturnValueOnce({
        sub: 'user-new-token',
        role: UserRole.HOUSEHOLD_HEAD,
        tokenVersion: 1, // new token — matches DB
      });

      userRepo.findOne.mockResolvedValueOnce({
        id: 'user-new-token',
        isActive: true,
        tokenVersion: 1, // DB matches JWT
        role: UserRole.HOUSEHOLD_HEAD,
      });

      // Should NOT throw
      await expect(
        service.requireUserFromAuthorization('Bearer new.jwt.token'),
      ).resolves.toBeDefined();
    });

    it('should reject JWT when tokenVersion is undefined but DB has tokenVersion > 0', async () => {
      // Legacy JWT without tokenVersion claim — should be rejected if DB version > 0
      (jwtService.verify as jest.Mock).mockReturnValueOnce({
        sub: 'user-legacy',
        role: UserRole.HOUSEHOLD_HEAD,
        // tokenVersion: undefined — old JWT without the claim
      });

      userRepo.findOne.mockResolvedValueOnce({
        id: 'user-legacy',
        isActive: true,
        tokenVersion: 1, // DB has been incremented
        role: UserRole.HOUSEHOLD_HEAD,
      });

      await expect(
        service.requireUserFromAuthorization('Bearer legacy.jwt.token'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });
});

