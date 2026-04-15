import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { Coverage } from '../coverages/coverage.entity';
import {
  CoverageStatus,
  IndigentEmploymentStatus,
  MembershipType,
  PaymentMethod,
  PaymentStatus,
} from '../common/enums/cbhi.enums';
import { Household } from '../households/household.entity';
import { Payment } from '../payments/payment.entity';
import { User } from '../users/user.entity';
import { RenewCoverageDto, RegistrationStepTwoDto } from './cbhi.dto';
import { randomBytes } from 'crypto';

export type EligibilityDecision = {
  score: number;
  approved: boolean;
  reason: string;
};

/**
 * FIX ME-2: CoverageService extracted from the god CbhiService.
 * Handles coverage lifecycle: creation, renewal, status resolution, premium calculation.
 */
@Injectable()
export class CoverageService {
  private readonly premiumPerMember = Number(process.env.CBHI_PREMIUM_PER_MEMBER ?? 120);

  constructor(
    @InjectRepository(Coverage)
    private readonly coverageRepository: Repository<Coverage>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(Household)
    private readonly householdRepository: Repository<Household>,
    @InjectRepository(Beneficiary)
    private readonly beneficiaryRepository: Repository<Beneficiary>,
  ) {}

  resolveRegistrationEligibility(dto: RegistrationStepTwoDto, householdSize: number): EligibilityDecision {
    if (dto.membershipType === MembershipType.PAYING) {
      return this.evaluateEligibility(dto.membershipType, dto.eligibilitySignals.employmentStatus, householdSize);
    }
    const proofs = dto.indigentProofUploads ?? [];
    if (proofs.length < 1) {
      throw new BadRequestException('Indigent membership requires at least one supporting document.');
    }
    return { score: 100, approved: true, reason: 'Indigent pathway: supporting documents submitted.' };
  }

  evaluateEligibility(
    membershipType: MembershipType,
    employmentStatus: IndigentEmploymentStatus,
    householdSize: number,
  ): EligibilityDecision {
    if (membershipType === MembershipType.PAYING) {
      return { score: 100, approved: true, reason: 'Paying membership selected; indigent screening bypassed.' };
    }

    let score = 0;
    const reasons: string[] = [];

    switch (employmentStatus) {
      case IndigentEmploymentStatus.UNEMPLOYED: score += 40; reasons.push('unemployed'); break;
      case IndigentEmploymentStatus.DAILY_LABORER: score += 35; reasons.push('daily laborer'); break;
      case IndigentEmploymentStatus.FARMER: score += 30; reasons.push('smallholder farmer'); break;
      case IndigentEmploymentStatus.HOMEMAKER: score += 28; reasons.push('homemaker'); break;
      case IndigentEmploymentStatus.PENSIONER: score += 26; reasons.push('pensioner'); break;
      case IndigentEmploymentStatus.STUDENT: score += 24; reasons.push('student'); break;
      case IndigentEmploymentStatus.MERCHANT: score += 10; reasons.push('merchant'); break;
      case IndigentEmploymentStatus.EMPLOYED: reasons.push('formally employed'); break;
      default: throw new BadRequestException('Unsupported employment status');
    }

    if (householdSize >= 6) { score += 15; reasons.push('large household'); }
    else if (householdSize >= 4) { score += 8; reasons.push('mid-size household'); }

    const approved = score >= 40;
    return {
      score,
      approved,
      reason: approved
        ? `Zero-touch indigent approval: ${reasons.join(', ')}`
        : `Zero-touch indigent rejection: ${reasons.join(', ')}`,
    };
  }

  resolveCoverageStatus(membershipType: MembershipType, eligibility: EligibilityDecision): CoverageStatus {
    if (membershipType === MembershipType.PAYING) return CoverageStatus.PENDING_RENEWAL;
    return eligibility.approved ? CoverageStatus.ACTIVE : CoverageStatus.REJECTED;
  }

  resolvePremiumAmount(
    householdSize: number,
    membershipType: MembershipType,
    requestedPremium: number | undefined,
    eligibility: EligibilityDecision,
  ): number {
    if (membershipType === MembershipType.INDIGENT && eligibility.approved) return 0;
    if (membershipType === MembershipType.PAYING && requestedPremium !== undefined && requestedPremium >= 0) return requestedPremium;
    return Math.max(householdSize, 1) * this.premiumPerMember;
  }

  async upsertCoverage(
    household: Household,
    membershipType: MembershipType,
    requestedPremium: number | undefined,
    eligibility: EligibilityDecision,
  ) {
    const current = await this.coverageRepository.findOne({
      where: { household: { id: household.id } },
      relations: ['household'],
      order: { createdAt: 'DESC' },
    });

    const coverage = current ?? this.coverageRepository.create({
      coverageNumber: this.generateCode('CVG'),
      household,
    });

    const startDate = new Date();
    const endDate = this.addMonths(startDate, 12);
    const premiumAmount = this.resolvePremiumAmount(household.memberCount, membershipType, requestedPremium, eligibility);

    coverage.startDate = startDate;
    coverage.endDate = endDate;
    coverage.nextRenewalDate = endDate;
    coverage.status = this.resolveCoverageStatus(membershipType, eligibility);
    coverage.premiumAmount = premiumAmount.toFixed(2);
    coverage.paidAmount = coverage.paidAmount ?? '0.00';

    return this.coverageRepository.save(coverage);
  }

  async renewCoverage(userId: string, household: Household, beneficiary: Beneficiary, user: User, dto: RenewCoverageDto) {
    const membershipType = household.membershipType;
    if (!membershipType) throw new BadRequestException('Household membership type is not configured yet.');

    const coverage = await this.coverageRepository.findOne({
      where: { household: { id: household.id } },
      order: { createdAt: 'DESC' },
    });
    if (!coverage) throw new NotFoundException(`Coverage for household ${household.householdCode} not found.`);

    const eligibility: EligibilityDecision = {
      score: beneficiary.isEligible ? 100 : 0,
      approved: beneficiary.isEligible,
      reason: beneficiary.isEligible ? 'Household remains eligible.' : 'Household is not eligible.',
    };

    const premiumAmount = this.resolvePremiumAmount(household.memberCount, membershipType, dto.amount, eligibility);

    if (premiumAmount > 0 && !dto.paymentMethod) {
      throw new BadRequestException('A payment method is required to renew a paying household coverage.');
    }

    const renewedAt = new Date();
    coverage.startDate = renewedAt;
    coverage.endDate = this.addMonths(renewedAt, 12);
    coverage.nextRenewalDate = coverage.endDate;
    coverage.status = CoverageStatus.ACTIVE;
    coverage.premiumAmount = premiumAmount.toFixed(2);
    coverage.paidAmount = premiumAmount.toFixed(2);
    await this.coverageRepository.save(coverage);

    household.coverageStatus = CoverageStatus.ACTIVE;
    await this.householdRepository.save(household);

    await this.beneficiaryRepository
      .createQueryBuilder()
      .update(Beneficiary)
      .set({ isEligible: true })
      .where('householdId = :householdId', { householdId: household.id })
      .execute();

    if (premiumAmount > 0 && dto.paymentMethod) {
      await this.paymentRepository.save(
        this.paymentRepository.create({
          transactionReference: this.generateCode('PAY'),
          amount: premiumAmount.toFixed(2),
          method: dto.paymentMethod,
          status: PaymentStatus.SUCCESS,
          providerName: dto.providerName ?? null,
          receiptNumber: dto.receiptNumber ?? null,
          paidAt: renewedAt,
          coverage,
          processedBy: user,
        }),
      );
    }

    return coverage;
  }

  async loadLatestCoverage(householdId: string) {
    return this.coverageRepository.findOne({
      where: { household: { id: householdId } },
      order: { createdAt: 'DESC' },
    });
  }

  toCoverageSummary(coverage: Coverage) {
    return {
      coverageNumber: coverage.coverageNumber,
      status: coverage.status,
      startDate: coverage.startDate?.toISOString() ?? null,
      endDate: coverage.endDate?.toISOString() ?? null,
      nextRenewalDate: coverage.nextRenewalDate?.toISOString() ?? null,
      premiumAmount: Number(coverage.premiumAmount ?? 0),
      paidAmount: Number(coverage.paidAmount ?? 0),
    };
  }

  private addMonths(date: Date, months: number) {
    const result = new Date(date);
    result.setMonth(result.getMonth() + months);
    return result;
  }

  private generateCode(prefix: string) {
    return `${prefix}-${randomBytes(4).toString('hex').toUpperCase()}`;
  }
}
