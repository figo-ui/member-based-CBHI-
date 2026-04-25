import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {
  createHash,
  createPublicKey,
  randomBytes,
  verify as cryptoVerify,
} from 'crypto';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { PasskeyAuthenticateDto, PasskeyRegisterDto } from './passkey.dto';
import { PasskeyCredential } from './passkey-credential.entity';

// ── Environment configuration ─────────────────────────────────────────────────
const PASSKEY_RP_ID =
  process.env.PASSKEY_RP_ID ?? 'localhost';
const PASSKEY_RP_ORIGIN =
  process.env.PASSKEY_RP_ORIGIN ?? 'http://localhost:3000';

// ── WebAuthn JSON types (minimal subset needed) ───────────────────────────────

export interface PublicKeyCredentialCreationOptionsJSON {
  rp: { id: string; name: string };
  user: { id: string; name: string; displayName: string };
  challenge: string;
  pubKeyCredParams: Array<{ type: 'public-key'; alg: number }>;
  timeout: number;
  attestation: string;
  authenticatorSelection: { userVerification: string };
}

export interface PublicKeyCredentialRequestOptionsJSON {
  rpId: string;
  challenge: string;
  allowCredentials: Array<{ type: 'public-key'; id: string }>;
  timeout: number;
  userVerification: string;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Encode a Buffer / Uint8Array to base64url (no padding). */
function toBase64Url(buf: Buffer): string {
  return buf
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

/** Decode a base64url string to a Buffer. */
function fromBase64Url(str: string): Buffer {
  // Restore standard base64 padding
  const padded = str.replace(/-/g, '+').replace(/_/g, '/');
  const remainder = padded.length % 4;
  const b64 = remainder ? padded + '='.repeat(4 - remainder) : padded;
  return Buffer.from(b64, 'base64');
}

/** SHA-256 hash of a Buffer, returned as a Buffer. */
function sha256(data: Buffer): Buffer {
  return createHash('sha256').update(data).digest();
}

// ── Service ───────────────────────────────────────────────────────────────────

@Injectable()
export class PasskeyService {
  constructor(
    @InjectRepository(PasskeyCredential)
    private readonly credentialRepository: Repository<PasskeyCredential>,
  ) {}

  // ── Registration ────────────────────────────────────────────────────────────

  /**
   * Generate WebAuthn credential creation options for the given user.
   * The challenge is a cryptographically random 32-byte value (base64url).
   */
  async getRegisterOptions(
    user: User,
  ): Promise<PublicKeyCredentialCreationOptionsJSON> {
    const challenge = toBase64Url(randomBytes(32));

    return {
      rp: {
        id: PASSKEY_RP_ID,
        name: 'Maya City CBHI',
      },
      user: {
        id: user.id,
        name: user.phoneNumber ?? user.email ?? user.id,
        displayName: user.firstName,
      },
      challenge,
      pubKeyCredParams: [
        { type: 'public-key', alg: -7 }, // ES256 (ECDSA P-256)
      ],
      timeout: 60000,
      attestation: 'none',
      authenticatorSelection: {
        userVerification: 'preferred',
      },
    };
  }

  /**
   * Verify the attestation response from the browser and persist the credential.
   *
   * Verification steps performed:
   *  1. Decode and parse clientDataJSON
   *  2. Assert type === 'webauthn.create'
   *  3. Assert origin matches PASSKEY_RP_ORIGIN
   *
   * Full attestation statement verification (CBOR decoding, certificate chains)
   * is intentionally omitted because `attestation: 'none'` is requested, so
   * the authenticator returns no attestation statement to verify.
   */
  async verifyAndStoreAttestation(
    user: User,
    dto: PasskeyRegisterDto,
  ): Promise<PasskeyCredential> {
    // 1. Decode and parse clientDataJSON
    const clientDataBuffer = fromBase64Url(dto.clientDataJSON);
    let clientData: { type: string; origin: string; challenge: string };
    try {
      clientData = JSON.parse(clientDataBuffer.toString('utf8')) as {
        type: string;
        origin: string;
        challenge: string;
      };
    } catch {
      throw new UnauthorizedException('Invalid clientDataJSON.');
    }

    // 2. Verify type
    if (clientData.type !== 'webauthn.create') {
      throw new UnauthorizedException(
        'Invalid clientDataJSON type for registration.',
      );
    }

    // 3. Verify origin
    if (clientData.origin !== PASSKEY_RP_ORIGIN) {
      throw new UnauthorizedException(
        `Invalid credential origin. Expected ${PASSKEY_RP_ORIGIN}, got ${clientData.origin}.`,
      );
    }

    // Persist the credential
    const credential = this.credentialRepository.create({
      user,
      credentialId: dto.credentialId,
      publicKey: dto.attestationObject, // store the raw attestationObject as the public key blob
      signCount: 0,
      rpId: PASSKEY_RP_ID,
      deviceName: dto.deviceName ?? null,
    });

    return this.credentialRepository.save(credential);
  }

  // ── Authentication ──────────────────────────────────────────────────────────

  /**
   * Generate WebAuthn credential request options for the given credential IDs.
   */
  async getAuthenticateOptions(
    credentialIds: string[],
  ): Promise<PublicKeyCredentialRequestOptionsJSON> {
    const challenge = toBase64Url(randomBytes(32));

    return {
      rpId: PASSKEY_RP_ID,
      challenge,
      allowCredentials: credentialIds.map((id) => ({
        type: 'public-key' as const,
        id,
      })),
      timeout: 60000,
      userVerification: 'preferred',
    };
  }

  /**
   * Verify a WebAuthn assertion and update the credential's sign count.
   *
   * Verification steps:
   *  1. Look up the credential by credentialId
   *  2. Decode and parse clientDataJSON
   *  3. Assert type === 'webauthn.get'
   *  4. Assert origin matches PASSKEY_RP_ORIGIN
   *  5. Verify rpIdHash in authenticatorData matches SHA-256(PASSKEY_RP_ID)
   *  6. Verify signCount > credential.signCount (replay prevention)
   *  7. Verify ECDSA P-256 signature over (authenticatorData || SHA-256(clientDataJSON))
   *  8. Update signCount and lastUsedAt
   */
  async verifyAssertion(dto: PasskeyAuthenticateDto): Promise<PasskeyCredential> {
    // 1. Find credential
    const credential = await this.credentialRepository.findOne({
      where: { credentialId: dto.credentialId },
      relations: ['user'],
    });

    if (!credential) {
      throw new NotFoundException('No passkey found for this account.');
    }

    // 2. Decode and parse clientDataJSON
    const clientDataBuffer = fromBase64Url(dto.clientDataJSON);
    let clientData: { type: string; origin: string; challenge: string };
    try {
      clientData = JSON.parse(clientDataBuffer.toString('utf8')) as {
        type: string;
        origin: string;
        challenge: string;
      };
    } catch {
      throw new UnauthorizedException('Invalid clientDataJSON.');
    }

    // 3. Verify type
    if (clientData.type !== 'webauthn.get') {
      throw new UnauthorizedException(
        'Invalid clientDataJSON type for authentication.',
      );
    }

    // 4. Verify origin
    if (clientData.origin !== PASSKEY_RP_ORIGIN) {
      throw new UnauthorizedException(
        `Invalid credential origin. Expected ${PASSKEY_RP_ORIGIN}, got ${clientData.origin}.`,
      );
    }

    // 5. Verify rpIdHash
    const authenticatorDataBuffer = fromBase64Url(dto.authenticatorData);
    // The first 32 bytes of authenticatorData are the rpIdHash
    const rpIdHashFromAuth = authenticatorDataBuffer.subarray(0, 32);
    const expectedRpIdHash = sha256(Buffer.from(PASSKEY_RP_ID, 'utf8'));

    if (!rpIdHashFromAuth.equals(expectedRpIdHash)) {
      throw new UnauthorizedException('Invalid credential origin (rpId mismatch).');
    }

    // 6. Verify signCount (replay prevention)
    // authenticatorData bytes 33–36 (big-endian uint32) hold the sign count
    const signCountFromAuth = authenticatorDataBuffer.readUInt32BE(33);
    if (signCountFromAuth <= credential.signCount) {
      throw new UnauthorizedException('Credential replay detected.');
    }

    // 7. Verify ECDSA P-256 signature
    // signedData = authenticatorData || SHA-256(clientDataJSON)
    const clientDataHash = sha256(clientDataBuffer);
    const signedData = Buffer.concat([authenticatorDataBuffer, clientDataHash]);
    const signatureBuffer = fromBase64Url(dto.signature);

    const verified = this.verifyEcdsaSignature(
      credential.publicKey,
      signedData,
      signatureBuffer,
    );

    if (!verified) {
      throw new UnauthorizedException('Passkey verification failed.');
    }

    // 8. Update credential
    credential.signCount = signCountFromAuth;
    credential.lastUsedAt = new Date();

    return this.credentialRepository.save(credential);
  }

  // ── Credential management ───────────────────────────────────────────────────

  /** Return all passkey credentials registered for a user. */
  async getCredentialsByUser(userId: string): Promise<PasskeyCredential[]> {
    return this.credentialRepository.find({
      where: { user: { id: userId } },
      order: { createdAt: 'DESC' },
    });
  }

  /** Delete a specific credential, verifying it belongs to the given user. */
  async deleteCredential(userId: string, credentialId: string): Promise<void> {
    const credential = await this.credentialRepository.findOne({
      where: { credentialId, user: { id: userId } },
      relations: ['user'],
    });

    if (!credential) {
      throw new NotFoundException('Passkey credential not found.');
    }

    await this.credentialRepository.remove(credential);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /**
   * Best-effort ECDSA P-256 signature verification using Node.js `crypto`.
   *
   * The stored `publicKey` is the base64url-encoded attestationObject from
   * registration. For a production-grade implementation, the COSE public key
   * should be extracted from the attestationObject (CBOR-encoded) and converted
   * to a DER/PEM SubjectPublicKeyInfo structure. Here we attempt to use the
   * stored value directly as a PEM key if it looks like one, otherwise we
   * perform a best-effort DER import.
   */
  private verifyEcdsaSignature(
    storedPublicKey: string,
    signedData: Buffer,
    signature: Buffer,
  ): boolean {
    try {
      let keyObject: ReturnType<typeof createPublicKey>;

      // Try to interpret the stored key as a PEM string first
      if (storedPublicKey.includes('BEGIN')) {
        keyObject = createPublicKey(storedPublicKey);
      } else {
        // Attempt to decode as base64url DER (SubjectPublicKeyInfo)
        const keyDer = fromBase64Url(storedPublicKey);
        keyObject = createPublicKey({
          key: keyDer,
          format: 'der',
          type: 'spki',
        });
      }

      return cryptoVerify('SHA256', signedData, keyObject, signature);
    } catch {
      // If key parsing fails (e.g., raw attestationObject stored instead of
      // extracted COSE key), we cannot verify the signature. Return false so
      // the caller throws UnauthorizedException.
      return false;
    }
  }
}
