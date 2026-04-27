import {
  IsString,
  MinLength,
  Matches,
} from 'class-validator';

export class RefreshTokenDto {
  @IsString()
  refreshToken!: string;
}

export class PasswordLoginDto {
  @IsString()
  identifier!: string;

  @IsString()
  password!: string;
}

export class SetPasswordDto {
  @IsString()
  @MinLength(6)
  password!: string;
}

export class TotpActivateDto {
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Token must be a 6-digit number.' })
  token!: string;
}

export class TotpVerifyDto {
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Token must be a 6-digit number.' })
  token!: string;
}
