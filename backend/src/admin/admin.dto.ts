import {
  IsDateString,
  IsBoolean,
  IsEmail,
  IsEnum,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { ClaimStatus, IndigentApplicationStatus } from '../common/enums/cbhi.enums';

export class ReviewClaimDto {
  @IsEnum(ClaimStatus)
  status!: ClaimStatus;

  @IsOptional()
  @IsNumber()
  approvedAmount?: number;

  @IsOptional()
  @IsString()
  decisionNote?: string;
}

export class ReviewIndigentApplicationDto {
  @IsEnum(IndigentApplicationStatus)
  status!: IndigentApplicationStatus;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class UpdateSystemSettingDto {
  @IsOptional()
  @IsString()
  label?: string;

  @IsOptional()
  @IsString()
  description?: string;

  value!: Record<string, unknown>;

  @IsOptional()
  isSensitive?: boolean;
}

export class ReportsQueryDto {
  @IsOptional()
  @IsDateString()
  @Transform(({ value }: { value: unknown }) => (value === '' ? undefined : value))
  from?: string;

  @IsOptional()
  @IsDateString()
  @Transform(({ value }: { value: unknown }) => (value === '' ? undefined : value))
  to?: string;
}

export class ExportQueryDto {
  @IsOptional()
  @IsIn(['households', 'claims', 'payments', 'indigent'])
  type?: 'households' | 'claims' | 'payments' | 'indigent';

  @IsOptional()
  @IsDateString()
  @Transform(({ value }: { value: unknown }) => (value === '' ? undefined : value))
  from?: string;

  @IsOptional()
  @IsDateString()
  @Transform(({ value }: { value: unknown }) => (value === '' ? undefined : value))
  to?: string;
}

// ── Facility management DTOs ────────────────────────────────────────────────

export class CreateFacilityDto {
  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  facilityCode?: string;

  @IsOptional()
  @IsString()
  licenseNumber?: string;

  @IsOptional()
  @IsString()
  serviceLevel?: string;

  @IsOptional()
  @IsString()
  phoneNumber?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  addressLine?: string;
}

export class UpdateFacilityDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  serviceLevel?: string;

  @IsOptional()
  @IsString()
  phoneNumber?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  addressLine?: string;

  @IsOptional()
  @IsBoolean()
  isAccredited?: boolean;
}

export class AddFacilityStaffDto {
  @IsString()
  identifier!: string;

  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;
}
