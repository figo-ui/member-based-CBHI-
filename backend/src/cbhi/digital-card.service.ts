import { Injectable } from '@nestjs/common';
import { createCipheriv, createHash, randomBytes } from 'crypto';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { Coverage } from '../coverages/coverage.entity';
import { Household } from '../households/household.entity';
import { EligibilityDecision } from './coverage.service';

/**
 * FIX ME-2: DigitalCardService extracted from the god CbhiService.
 * Handles encrypted QR token generation and digital card building.
 */
@Injectable()
export class DigitalCardService {
  private readonly cardSecret = process.env.DIGITAL_CARD_SECRET ?? 'cbhi-card';

  issueDigitalCard(input: {
    household: Household;
    beneficiary: Beneficiary;
    coverage: Coverage;
    eligibility: EligibilityDecision;
  }) {
    const payload = {
      cardId: this.generateCode('CARD'),
      householdCode: input.household.householdCode,
      coverageNumber: input.coverage.coverageNumber,
      memberName: input.beneficiary.fullName,
      membershipId: input.beneficiary.memberNumber,
      memberCount: input.household.memberCount,
      membershipType: input.household.membershipType,
      coverageStatus: input.coverage.status,
      eligibilityApproved: input.eligibility.approved,
      validUntil: input.coverage.endDate?.toISOString() ?? null,
      issuedAt: new Date().toISOString(),
    };

    return {
      token: this.signPayload(payload),
      qrPayload: payload,
    };
  }

  buildDigitalCards(household: Household, coverage: Coverage, beneficiaryId?: string) {
    const members = beneficiaryId
      ? household.beneficiaries.filter((m) => m.id === beneficiaryId)
      : household.beneficiaries;

    return members.map((member) => {
      const eligibility: EligibilityDecision = {
        score: member.isEligible ? 100 : 0,
        approved: member.isEligible,
        reason: member.isEligible
          ? 'Member is eligible for covered services.'
          : 'Member is not currently eligible for covered services.',
      };
      const card = this.issueDigitalCard({ household, beneficiary: member, coverage, eligibility });
      return {
        memberId: member.id,
        membershipId: member.memberNumber,
        memberName: member.fullName,
        relationshipToHouseholdHead: member.relationshipToHouseholdHead,
        coverageStatus: coverage.status,
        token: card.token,
        qrPayload: card.qrPayload,
      };
    });
  }

  private signPayload(payload: Record<string, unknown>): string {
    const json = JSON.stringify(payload);
    const key = createHash('sha256').update(this.cardSecret).digest();
    const iv = randomBytes(16);
    const cipher = createCipheriv('aes-256-cbc', key, iv);
    const encrypted = Buffer.concat([cipher.update(json, 'utf8'), cipher.final()]);
    return `${iv.toString('hex')}.${encrypted.toString('hex')}`;
  }

  private generateCode(prefix: string) {
    return `${prefix}-${randomBytes(4).toString('hex').toUpperCase()}`;
  }
}
