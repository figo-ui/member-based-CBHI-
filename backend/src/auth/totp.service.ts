import { Injectable } from '@nestjs/common';
import { createHmac, randomBytes } from 'crypto';

/**
 * TOTP (Time-based One-Time Password) service for admin 2FA.
 * Implements RFC 6238 without external dependencies.
 * Compatible with Google Authenticator, Authy, and any TOTP app.
 *
 * Usage:
 *   1. generateSecret() → store encrypted in DB
 *   2. generateQrUri()  → show QR code to admin once
 *   3. verifyToken()    → verify on every admin login
 */
@Injectable()
export class TotpService {
  private readonly issuer = 'Maya City CBHI';
  private readonly digits = 6;
  private readonly period = 30; // seconds
  private readonly algorithm = 'sha1';

  /** Generate a new random base32 secret for a user */
  generateSecret(): string {
    const bytes = randomBytes(20);
    return this.base32Encode(bytes);
  }

  /**
   * Generate an otpauth:// URI for QR code display.
   * Pass this to a QR code library to render the setup QR.
   */
  generateQrUri(secret: string, accountName: string): string {
    const encoded = encodeURIComponent(accountName);
    const issuerEncoded = encodeURIComponent(this.issuer);
    return (
      `otpauth://totp/${issuerEncoded}:${encoded}` +
      `?secret=${secret}&issuer=${issuerEncoded}` +
      `&algorithm=SHA1&digits=${this.digits}&period=${this.period}`
    );
  }

  /**
   * Verify a 6-digit TOTP token.
   * Accepts tokens from the current window ±1 (90-second tolerance).
   */
  verifyToken(secret: string, token: string): boolean {
    const normalizedToken = token.replace(/\s/g, '');
    if (!/^\d{6}$/.test(normalizedToken)) return false;

    const now = Math.floor(Date.now() / 1000);
    const counter = Math.floor(now / this.period);

    // Check current window and ±1 adjacent windows
    for (const offset of [-1, 0, 1]) {
      const expected = this.generateToken(secret, counter + offset);
      if (this.timingSafeEqual(normalizedToken, expected)) {
        return true;
      }
    }
    return false;
  }

  /** Generate a TOTP token for a given counter value (for testing) */
  generateToken(secret: string, counter?: number): string {
    const c = counter ?? Math.floor(Date.now() / 1000 / this.period);
    const secretBytes = this.base32Decode(secret);

    // Pack counter as 8-byte big-endian
    const counterBuffer = Buffer.alloc(8);
    let remaining = c;
    for (let i = 7; i >= 0; i--) {
      counterBuffer[i] = remaining & 0xff;
      remaining = Math.floor(remaining / 256);
    }

    const hmac = createHmac(this.algorithm, secretBytes);
    hmac.update(counterBuffer);
    const hash = hmac.digest();

    // Dynamic truncation
    const offset = hash[hash.length - 1] & 0x0f;
    const code =
      ((hash[offset] & 0x7f) << 24) |
      ((hash[offset + 1] & 0xff) << 16) |
      ((hash[offset + 2] & 0xff) << 8) |
      (hash[offset + 3] & 0xff);

    return String(code % Math.pow(10, this.digits)).padStart(this.digits, '0');
  }

  private timingSafeEqual(a: string, b: string): boolean {
    if (a.length !== b.length) return false;
    let result = 0;
    for (let i = 0; i < a.length; i++) {
      result |= a.charCodeAt(i) ^ b.charCodeAt(i);
    }
    return result === 0;
  }

  private base32Encode(buffer: Buffer): string {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    let result = '';
    let bits = 0;
    let value = 0;

    for (const byte of buffer) {
      value = (value << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        result += alphabet[(value >>> (bits - 5)) & 31];
        bits -= 5;
      }
    }

    if (bits > 0) {
      result += alphabet[(value << (5 - bits)) & 31];
    }

    return result;
  }

  private base32Decode(input: string): Buffer {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    const cleaned = input.toUpperCase().replace(/=+$/, '');
    const bytes: number[] = [];
    let bits = 0;
    let value = 0;

    for (const char of cleaned) {
      const idx = alphabet.indexOf(char);
      if (idx === -1) continue;
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        bytes.push((value >>> (bits - 8)) & 255);
        bits -= 8;
      }
    }

    return Buffer.from(bytes);
  }
}
