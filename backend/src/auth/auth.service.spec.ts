import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
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
      };

      userRepo.findOne.mockResolvedValue(mockUser);
      const qb = userRepo.createQueryBuilder();
      qb.getOne.mockResolvedValue({ ...mockUser, refreshTokenHash: null });

      const result = await service.issueSession('user-123');

      expect(jwtService.sign).toHaveBeenCalledWith(
        expect.objectContaining({ sub: 'user-123', role: UserRole.HOUSEHOLD_HEAD }),
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
});
