import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { BadRequestException } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { ChapaService } from './chapa.service';
import { Coverage } from '../coverages/coverage.entity';
import { Payment } from '../payments/payment.entity';
import { Household } from '../households/household.entity';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { CoverageStatus, PaymentStatus } from '../common/enums/cbhi.enums';
import { User } from '../users/user.entity';

const mockRepo = () => ({
  create: jest.fn(),
  save: jest.fn(),
  findOne: jest.fn(),
  createQueryBuilder: jest.fn().mockReturnValue({
    update: jest.fn().mockReturnThis(),
    set: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    execute: jest.fn().mockResolvedValue({}),
  }),
});

const mockChapaService = () => ({
  initiatePayment: jest.fn(),
  verifyPayment: jest.fn(),
  verifyWebhookSignature: jest.fn(),
});

describe('PaymentService', () => {
  let service: PaymentService;
  let chapaService: ReturnType<typeof mockChapaService>;
  let householdRepo: ReturnType<typeof mockRepo>;
  let coverageRepo: ReturnType<typeof mockRepo>;
  let paymentRepo: ReturnType<typeof mockRepo>;

  const mockUser: Partial<User> = {
    id: 'user-1',
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    phoneNumber: '+251912345678',
  };

  const mockHousehold: Partial<Household> = {
    id: 'hh-1',
    householdCode: 'HH-TEST',
    headUser: mockUser as User,
  };

  const mockCoverage: Partial<Coverage> = {
    id: 'cov-1',
    coverageNumber: 'CVG-TEST',
    status: CoverageStatus.PENDING_RENEWAL,
    household: mockHousehold as Household,
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentService,
        { provide: ChapaService, useFactory: mockChapaService },
        { provide: getRepositoryToken(Coverage), useFactory: mockRepo },
        { provide: getRepositoryToken(Payment), useFactory: mockRepo },
        { provide: getRepositoryToken(Household), useFactory: mockRepo },
        { provide: getRepositoryToken(Beneficiary), useFactory: mockRepo },
      ],
    }).compile();

    service = module.get<PaymentService>(PaymentService);
    chapaService = module.get(ChapaService);
    householdRepo = module.get(getRepositoryToken(Household));
    coverageRepo = module.get(getRepositoryToken(Coverage));
    paymentRepo = module.get(getRepositoryToken(Payment));
  });

  describe('initiatePayment', () => {
    it('throws if no household found', async () => {
      householdRepo.findOne.mockResolvedValue(null);
      await expect(service.initiatePayment(mockUser as User, 500)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('throws if no coverage found', async () => {
      householdRepo.findOne.mockResolvedValue(mockHousehold);
      coverageRepo.findOne.mockResolvedValue(null);
      await expect(service.initiatePayment(mockUser as User, 500)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('throws if Chapa initiation fails', async () => {
      householdRepo.findOne.mockResolvedValue(mockHousehold);
      coverageRepo.findOne.mockResolvedValue(mockCoverage);
      (chapaService.initiatePayment as jest.Mock).mockResolvedValue({
        success: false,
        message: 'Chapa error',
      });
      await expect(service.initiatePayment(mockUser as User, 500)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('returns checkout URL on success', async () => {
      householdRepo.findOne.mockResolvedValue(mockHousehold);
      coverageRepo.findOne.mockResolvedValue(mockCoverage);
      (chapaService.initiatePayment as jest.Mock).mockResolvedValue({
        success: true,
        checkoutUrl: 'https://checkout.chapa.co/test',
        message: 'Hosted Link',
      });
      paymentRepo.create.mockReturnValue({});
      paymentRepo.save.mockResolvedValue({});

      const result = await service.initiatePayment(mockUser as User, 500);
      expect(result.checkoutUrl).toBe('https://checkout.chapa.co/test');
      expect(result.amount).toBe(500);
      expect(result.currency).toBe('ETB');
    });
  });

  describe('verifyPayment', () => {
    it('throws if payment not found', async () => {
      paymentRepo.findOne.mockResolvedValue(null);
      await expect(service.verifyPayment('CBHI-NOTFOUND')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('activates coverage on successful verification', async () => {
      const mockPayment = {
        id: 'pay-1',
        transactionReference: 'CBHI-TEST',
        status: PaymentStatus.PENDING,
        amount: '500.00',
        coverage: {
          ...mockCoverage,
          startDate: new Date(),
          endDate: new Date(),
          household: {
            ...mockHousehold,
            headUser: { id: 'user-1' },
          },
        },
      };
      paymentRepo.findOne.mockResolvedValue(mockPayment);
      paymentRepo.save.mockResolvedValue(mockPayment);
      coverageRepo.save.mockResolvedValue({});
      householdRepo.save.mockResolvedValue({});

      (chapaService.verifyPayment as jest.Mock).mockResolvedValue({
        status: 'success',
        amount: 500,
        currency: 'ETB',
        paymentMethod: 'telebirr',
        paidAt: new Date().toISOString(),
        message: 'Payment verified',
      });

      const result = await service.verifyPayment('CBHI-TEST');
      expect(result.coverageActivated).toBe(true);
      expect(result.status).toBe('success');
    });
  });
});
