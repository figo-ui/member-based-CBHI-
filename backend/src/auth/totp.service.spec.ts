import { Test, TestingModule } from '@nestjs/testing';
import { TotpService } from './totp.service';

describe('TotpService', () => {
  let service: TotpService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [TotpService],
    }).compile();

    service = module.get<TotpService>(TotpService);
  });

  describe('generateSecret', () => {
    it('returns a non-empty base32 string', () => {
      const secret = service.generateSecret();
      expect(secret).toBeTruthy();
      expect(secret.length).toBeGreaterThan(10);
      // Base32 alphabet only
      expect(/^[A-Z2-7]+$/.test(secret)).toBe(true);
    });

    it('generates unique secrets each time', () => {
      const s1 = service.generateSecret();
      const s2 = service.generateSecret();
      expect(s1).not.toBe(s2);
    });
  });

  describe('generateQrUri', () => {
    it('returns a valid otpauth URI', () => {
      const secret = service.generateSecret();
      const uri = service.generateQrUri(secret, 'admin@example.com');
      expect(uri).toMatch(/^otpauth:\/\/totp\//);
      expect(uri).toContain(secret);
      expect(uri).toContain('Maya%20City%20CBHI');
      expect(uri).toContain('digits=6');
      expect(uri).toContain('period=30');
    });
  });

  describe('generateToken', () => {
    it('generates a 6-digit string', () => {
      const secret = service.generateSecret();
      const token = service.generateToken(secret);
      expect(token).toMatch(/^\d{6}$/);
    });

    it('generates the same token for the same counter', () => {
      const secret = service.generateSecret();
      const counter = Math.floor(Date.now() / 1000 / 30);
      const t1 = service.generateToken(secret, counter);
      const t2 = service.generateToken(secret, counter);
      expect(t1).toBe(t2);
    });

    it('generates different tokens for different counters', () => {
      const secret = service.generateSecret();
      const counter = 1000;
      const t1 = service.generateToken(secret, counter);
      const t2 = service.generateToken(secret, counter + 1);
      expect(t1).not.toBe(t2);
    });
  });

  describe('verifyToken', () => {
    it('accepts a valid current token', () => {
      const secret = service.generateSecret();
      const counter = Math.floor(Date.now() / 1000 / 30);
      const token = service.generateToken(secret, counter);
      expect(service.verifyToken(secret, token)).toBe(true);
    });

    it('accepts a token from the previous window (clock drift tolerance)', () => {
      const secret = service.generateSecret();
      const counter = Math.floor(Date.now() / 1000 / 30);
      const prevToken = service.generateToken(secret, counter - 1);
      expect(service.verifyToken(secret, prevToken)).toBe(true);
    });

    it('accepts a token from the next window (clock drift tolerance)', () => {
      const secret = service.generateSecret();
      const counter = Math.floor(Date.now() / 1000 / 30);
      const nextToken = service.generateToken(secret, counter + 1);
      expect(service.verifyToken(secret, nextToken)).toBe(true);
    });

    it('rejects a token from 2 windows ago', () => {
      const secret = service.generateSecret();
      const counter = Math.floor(Date.now() / 1000 / 30);
      const oldToken = service.generateToken(secret, counter - 2);
      expect(service.verifyToken(secret, oldToken)).toBe(false);
    });

    it('rejects an invalid token', () => {
      const secret = service.generateSecret();
      expect(service.verifyToken(secret, '000000')).toBe(false);
    });

    it('rejects a token with wrong length', () => {
      const secret = service.generateSecret();
      expect(service.verifyToken(secret, '12345')).toBe(false);
      expect(service.verifyToken(secret, '1234567')).toBe(false);
    });

    it('rejects a non-numeric token', () => {
      const secret = service.generateSecret();
      expect(service.verifyToken(secret, 'abcdef')).toBe(false);
    });

    it('handles tokens with spaces (strips whitespace)', () => {
      const secret = service.generateSecret();
      const counter = Math.floor(Date.now() / 1000 / 30);
      const token = service.generateToken(secret, counter);
      // Token with spaces should still verify
      expect(service.verifyToken(secret, `${token.slice(0, 3)} ${token.slice(3)}`)).toBe(true);
    });
  });
});
