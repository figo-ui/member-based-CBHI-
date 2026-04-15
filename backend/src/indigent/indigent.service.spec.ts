import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { BadRequestException } from '@nestjs/common';
import { IndigentService } from './indigent.service';
import { IndigentApplication } from './indigent.entity';
import {
  IndigentApplicationStatus,
  IndigentEmploymentStatus,
} from '../common/enums/cbhi.enums';
import { CreateIndigentApplicationDto } from './indigent.dto';

const mockRepo = () => ({
  create: jest.fn(),
  save: jest.fn(),
  findOne: jest.fn(),
  find: jest.fn(),
});

describe('IndigentService', () => {
  let service: IndigentService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        IndigentService,
        { provide: getRepositoryToken(IndigentApplication), useFactory: mockRepo },
      ],
    }).compile();

    service = module.get<IndigentService>(IndigentService);
    // Reset env thresholds for deterministic tests
    process.env.INDIGENT_INCOME_THRESHOLD = '1000';
    process.env.INDIGENT_FAMILY_SIZE_THRESHOLD = '5';
    process.env.INDIGENT_APPROVAL_THRESHOLD = '70';
  });

  describe('evaluateIndigentApplication', () => {
    const base: CreateIndigentApplicationDto = {
      income: 500,
      employmentStatus: IndigentEmploymentStatus.UNEMPLOYED,
      familySize: 6,
      hasProperty: false,
      disabilityStatus: false,
      documents: [],
    };

    it('approves a clearly indigent applicant', () => {
      const result = service.evaluateIndigentApplication(base);
      // income(40) + unemployed(30) + large family(20) + no property(10) = 100
      expect(result.score).toBeGreaterThanOrEqual(70);
      expect(result.status).toBe(IndigentApplicationStatus.APPROVED);
    });

    it('rejects a non-indigent applicant', () => {
      const dto: CreateIndigentApplicationDto = {
        income: 5000,
        employmentStatus: IndigentEmploymentStatus.EMPLOYED,
        familySize: 2,
        hasProperty: true,
        disabilityStatus: false,
        documents: [],
      };
      const result = service.evaluateIndigentApplication(dto);
      expect(result.score).toBeLessThan(70);
      expect(result.status).toBe(IndigentApplicationStatus.REJECTED);
    });

    it('adds disability bonus', () => {
      const withDisability = { ...base, disabilityStatus: true };
      const without = { ...base, disabilityStatus: false };
      const scoreWith = service.evaluateIndigentApplication(withDisability).score;
      const scoreWithout = service.evaluateIndigentApplication(without).score;
      expect(scoreWith).toBe(scoreWithout + 10);
    });

    it('adds property penalty (no property = +10)', () => {
      const noProperty = { ...base, hasProperty: false };
      const hasProperty = { ...base, hasProperty: true };
      const scoreNo = service.evaluateIndigentApplication(noProperty).score;
      const scoreHas = service.evaluateIndigentApplication(hasProperty).score;
      expect(scoreNo).toBe(scoreHas + 10);
    });

    it('scores daily laborer correctly', () => {
      const dto = { ...base, employmentStatus: IndigentEmploymentStatus.DAILY_LABORER };
      const result = service.evaluateIndigentApplication(dto);
      // income(40) + daily_laborer(25) + large family(20) + no property(10) = 95
      expect(result.score).toBe(95);
      expect(result.status).toBe(IndigentApplicationStatus.APPROVED);
    });

    it('scores farmer correctly', () => {
      const dto = { ...base, employmentStatus: IndigentEmploymentStatus.FARMER };
      const result = service.evaluateIndigentApplication(dto);
      // income(40) + farmer(20) + large family(20) + no property(10) = 90
      expect(result.score).toBe(90);
    });

    it('scores mid-size household (4 members)', () => {
      const dto = { ...base, familySize: 4 };
      const result = service.evaluateIndigentApplication(dto);
      // income(40) + unemployed(30) + mid family(10) + no property(10) = 90
      expect(result.score).toBe(90);
    });

    it('scores small household (2 members) — no family bonus', () => {
      const dto = { ...base, familySize: 2 };
      const result = service.evaluateIndigentApplication(dto);
      // income(40) + unemployed(30) + no property(10) = 80
      expect(result.score).toBe(80);
    });

    it('respects configurable approval threshold', () => {
      process.env.INDIGENT_APPROVAL_THRESHOLD = '90';
      const dto: CreateIndigentApplicationDto = {
        income: 500,
        employmentStatus: IndigentEmploymentStatus.UNEMPLOYED,
        familySize: 4,
        hasProperty: false,
        disabilityStatus: false,
        documents: [],
      };
      // score = 80, threshold = 90 → rejected
      const result = service.evaluateIndigentApplication(dto);
      expect(result.status).toBe(IndigentApplicationStatus.REJECTED);
    });

    it('respects configurable income threshold', () => {
      process.env.INDIGENT_INCOME_THRESHOLD = '200';
      const dto = { ...base, income: 300 }; // above new threshold
      const result = service.evaluateIndigentApplication(dto);
      // no income bonus → unemployed(30) + large family(20) + no property(10) = 60 < 70
      expect(result.score).toBe(60);
      expect(result.status).toBe(IndigentApplicationStatus.REJECTED);
    });
  });

  describe('applyApplication', () => {
    it('rejects application with expired documents', async () => {
      const dto: CreateIndigentApplicationDto = {
        income: 500,
        employmentStatus: IndigentEmploymentStatus.UNEMPLOYED,
        familySize: 6,
        hasProperty: false,
        disabilityStatus: false,
        documents: [],
        documentMeta: [{ documentType: 'Income Certificate', isExpired: true }],
      };

      await expect(service.applyApplication(dto)).rejects.toThrow(BadRequestException);
    });

    it('saves and returns application for valid data', async () => {
      const repo = (service as any).indigentRepository;
      const mockApp = { id: 'test-id', status: IndigentApplicationStatus.APPROVED };
      repo.create.mockReturnValue(mockApp);
      repo.save.mockResolvedValue(mockApp);

      const dto: CreateIndigentApplicationDto = {
        income: 500,
        employmentStatus: IndigentEmploymentStatus.UNEMPLOYED,
        familySize: 6,
        hasProperty: false,
        disabilityStatus: false,
        documents: [],
      };

      const result = await service.applyApplication(dto);
      expect(result).toEqual(mockApp);
      expect(repo.save).toHaveBeenCalledTimes(1);
    });
  });
});
