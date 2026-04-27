import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { User } from '../users/user.entity';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
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

  describe('tokenVersion session invalidation', () => {
    it('should increment tokenVersion after setPassword and reject old JWTs', async () => {
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

      await service.setPassword('user-sp-test', 'NewPassword456!');

      expect(savedUser).not.toBeNull();
      expect((savedUser as Partial<User>).tokenVersion).toBe(3);

      (jwtService.verify as jest.Mock).mockReturnValueOnce({
        sub: 'user-sp-test',
        role: UserRole.HOUSEHOLD_HEAD,
        tokenVersion: 2,
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

    it('should accept JWT with matching tokenVersion', async () => {
      (jwtService.verify as jest.Mock).mockReturnValueOnce({
        sub: 'user-new-token',
        role: UserRole.HOUSEHOLD_HEAD,
        tokenVersion: 1,
      });

      userRepo.findOne.mockResolvedValueOnce({
        id: 'user-new-token',
        isActive: true,
        tokenVersion: 1,
        role: UserRole.HOUSEHOLD_HEAD,
      });

      await expect(
        service.requireUserFromAuthorization('Bearer new.jwt.token'),
      ).resolves.toBeDefined();
    });

    it('should reject JWT when tokenVersion is undefined but DB has tokenVersion > 0', async () => {
      (jwtService.verify as jest.Mock).mockReturnValueOnce({
        sub: 'user-legacy',
        role: UserRole.HOUSEHOLD_HEAD,
      });

      userRepo.findOne.mockResolvedValueOnce({
        id: 'user-legacy',
        isActive: true,
        tokenVersion: 1,
        role: UserRole.HOUSEHOLD_HEAD,
      });

      await expect(
        service.requireUserFromAuthorization('Bearer legacy.jwt.token'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('loginWithPassword', () => {
    it('throws UnauthorizedException for unknown identifier', async () => {
      const qb = userRepo.createQueryBuilder();
      qb.getOne.mockResolvedValue(null);

      await expect(
        service.loginWithPassword({ identifier: '+251911111111', password: 'pass' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException for wrong password', async () => {
      const hash = service.hashPassword('correct');
      const qb = userRepo.createQueryBuilder();
      qb.getOne.mockResolvedValue({
        id: 'u1',
        passwordHash: hash,
        totpEnabled: false,
        isActive: true,
        tokenVersion: 0,
      });

      await expect(
        service.loginWithPassword({ identifier: '+251911111111', password: 'wrong' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('issues session on correct password', async () => {
      const password = 'correct123';
      const hash = service.hashPassword(password);
      const mockUser: Partial<User> = {
        id: 'u1',
        passwordHash: hash,
        totpEnabled: false,
        isActive: true,
        tokenVersion: 0,
        role: UserRole.HOUSEHOLD_HEAD,
        firstName: 'Test',
        phoneNumber: '+251911111111',
        email: null,
        preferredLanguage: PreferredLanguage.ENGLISH,
      };

      const qb = userRepo.createQueryBuilder();
      qb.getOne.mockResolvedValue(mockUser);
      userRepo.findOne.mockResolvedValue(mockUser);
      userRepo.save.mockResolvedValue(mockUser);

      const result = await service.loginWithPassword({
        identifier: '+251911111111',
        password,
      });

      expect(result).toHaveProperty('accessToken');
    });
  });
});
