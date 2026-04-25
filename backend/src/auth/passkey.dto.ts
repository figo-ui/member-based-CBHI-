import { IsOptional, IsString } from 'class-validator';

export class PasskeyRegisterDto {
  @IsString()
  credentialId!: string;

  /** base64url-encoded clientDataJSON */
  @IsString()
  clientDataJSON!: string;

  /** base64url-encoded attestationObject */
  @IsString()
  attestationObject!: string;

  @IsOptional()
  @IsString()
  deviceName?: string;
}

export class PasskeyAuthOptionsDto {
  /** Phone number or user ID used to look up registered credentials */
  @IsString()
  identifier!: string;
}

export class PasskeyAuthenticateDto {
  @IsString()
  credentialId!: string;

  /** base64url-encoded clientDataJSON */
  @IsString()
  clientDataJSON!: string;

  /** base64url-encoded authenticatorData */
  @IsString()
  authenticatorData!: string;

  /** base64url-encoded ECDSA signature */
  @IsString()
  signature!: string;

  @IsOptional()
  @IsString()
  userHandle?: string;
}
