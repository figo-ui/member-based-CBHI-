import { BadRequestException, Injectable, Optional } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomBytes } from 'crypto';
import { Repository } from 'typeorm';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { Coverage } from '../coverages/coverage.entity';
import { CoverageStatus, PaymentMethod, PaymentStatus } from '../common/enums/cbhi.enums';
import { Household } from '../households/household.entity';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { Payment } from '../payments/payment.entity';
import { User } from '../users/user.entity';
import { ChapaService } from './chapa.service';

/**
 * FIX ME-3: Extracted PaymentService from PaymentGatewayController.
 * All business logic (coverage activation, beneficiary eligibility update,
 * WebSocket push) lives here. The controller is now a thin HTTP adapter.
 */
@Injectable()
export class PaymentService {
  constructor(
    private readonly chapaService: ChapaService,
    @InjectRepository(Coverage)
    private readonly coverageRepository: Repository<Coverage>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(Household)
    private readonly householdRepository: Repository<Household>,
    @InjectRepository(Beneficiary)
    private readonly beneficiaryRepository: Repository<Beneficiary>,
    @Optional() private readonly wsGateway?: NotificationsGateway,
  ) {}

  async initiatePayment(user: User, amount: number, description?: string) {
    const household = await this.householdRepository.findOne({
      where: { headUser: { id: user.id } },
      relations: ['headUser'],
    });

    if (!household) {
      throw new BadRequestException('No household found for this account.');
    }

    const coverage = await this.coverageRepository.findOne({
      where: { household: { id: household.id } },
      order: { createdAt: 'DESC' },
    });

    if (!coverage) {
      throw new BadRequestException('No coverage record found for this household.');
    }

    const txRef = `CBHI-${household.householdCode}-${randomBytes(6).toString('hex').toUpperCase()}`;

    const result = await this.chapaService.initiatePayment({
      amount,
      currency: 'ETB',
      email: user.email ?? undefined,
      phoneNumber: user.phoneNumber ?? undefined,
      firstName: user.firstName,
      lastName: user.lastName ?? 'Member',
      txRef,
      description: description ?? `CBHI premium for household ${household.householdCode}`,
      metadata: {
        householdCode: household.householdCode,
        coverageId: coverage.id,
        userId: user.id,
      },
    });

    if (!result.success) {
      throw new BadRequestException(result.message);
    }

    await this.paymentRepository.save(
      this.paymentRepository.create({
        transactionReference: txRef,
        amount: amount.toFixed(2),
        method: PaymentMethod.MOBILE_MONEY,
        status: PaymentStatus.PENDING,
        providerName: 'Chapa',
        coverage,
        processedBy: user,
      }),
    );

    const isTestMode =
      (process.env.CHAPA_SECRET_KEY ?? '').includes('TEST') ||
      !process.env.CHAPA_SECRET_KEY;

    return {
      txRef,
      checkoutUrl: result.checkoutUrl,
      amount,
      currency: 'ETB',
      message: result.message,
      isTestMode,
    };
  }

  async verifyPayment(txRef: string) {
    const payment = await this.paymentRepository.findOne({
      where: { transactionReference: txRef },
      relations: ['coverage', 'coverage.household', 'coverage.household.headUser'],
    });

    if (!payment) {
      throw new BadRequestException(`Payment ${txRef} not found.`);
    }

    const result = await this.chapaService.verifyPayment(txRef);

    if (result.status === 'success' && payment.status !== PaymentStatus.SUCCESS) {
      await this.activateCoverageAfterPayment(payment, txRef);
    } else if (result.status === 'failed') {
      payment.status = PaymentStatus.FAILED;
      await this.paymentRepository.save(payment);
    }

    return {
      txRef,
      status: result.status,
      amount: result.amount,
      currency: result.currency,
      paymentMethod: result.paymentMethod,
      paidAt: result.paidAt,
      message: result.message,
      coverageActivated: result.status === 'success',
    };
  }

  async handleWebhook(txRef: string, status: string) {
    const payment = await this.paymentRepository.findOne({
      where: { transactionReference: txRef },
      relations: ['coverage', 'coverage.household', 'coverage.household.headUser'],
    });

    if (!payment) return;

    if (status === 'success' && payment.status !== PaymentStatus.SUCCESS) {
      await this.activateCoverageAfterPayment(payment, txRef);
    }
  }

  /**
   * FIX ME-3: Single shared method for coverage activation — eliminates
   * the duplication that existed between verifyPayment and chapaWebhook.
   */
  private async activateCoverageAfterPayment(payment: Payment, txRef: string) {
    payment.status = PaymentStatus.SUCCESS;
    payment.paidAt = new Date();
    payment.receiptNumber = txRef;
    await this.paymentRepository.save(payment);

    if (!payment.coverage) return;

    const coverage = payment.coverage;
    const renewedAt = new Date();
    coverage.status = CoverageStatus.ACTIVE;
    coverage.paidAmount = payment.amount;
    coverage.startDate = renewedAt;
    coverage.endDate = new Date(
      renewedAt.getFullYear() + 1,
      renewedAt.getMonth(),
      renewedAt.getDate(),
    );
    coverage.nextRenewalDate = coverage.endDate;
    await this.coverageRepository.save(coverage);

    if (coverage.household) {
      coverage.household.coverageStatus = CoverageStatus.ACTIVE;
      await this.householdRepository.save(coverage.household);

      await this.beneficiaryRepository
        .createQueryBuilder()
        .update()
        .set({ isEligible: true })
        .where('householdId = :id', { id: coverage.household.id })
        .execute();

      const headUserId = coverage.household.headUser?.id;
      if (headUserId) {
        this.wsGateway?.pushCoverageSync(headUserId, {
          coverageNumber: coverage.coverageNumber,
          status: coverage.status,
          endDate: coverage.endDate.toISOString(),
          paidAmount: payment.amount,
        });
      }
    }
  }
}
