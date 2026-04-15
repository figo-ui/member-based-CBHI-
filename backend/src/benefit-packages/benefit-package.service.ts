import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BenefitItem, BenefitPackage } from './benefit-package.entity';

@Injectable()
export class BenefitPackageService {
  constructor(
    @InjectRepository(BenefitPackage)
    private readonly packageRepo: Repository<BenefitPackage>,
    @InjectRepository(BenefitItem)
    private readonly itemRepo: Repository<BenefitItem>,
  ) {}

  async listPackages() {
    return this.packageRepo.find({
      where: { isActive: true },
      relations: ['items'],
      order: { createdAt: 'DESC' },
    });
  }

  async getActivePackage() {
    const pkg = await this.packageRepo.findOne({
      where: { isActive: true },
      relations: ['items'],
      order: { createdAt: 'DESC' },
    });
    if (!pkg) {
      // Return a default package if none configured
      return this.getDefaultPackage();
    }
    return pkg;
  }

  async getPackageById(id: string) {
    const pkg = await this.packageRepo.findOne({
      where: { id },
      relations: ['items'],
    });
    if (!pkg) throw new NotFoundException(`Benefit package ${id} not found.`);
    return pkg;
  }

  async createPackage(dto: {
    name: string;
    description?: string;
    premiumPerMember: number;
    annualCeiling?: number;
    items?: Array<{
      serviceName: string;
      serviceCode?: string;
      category: string;
      maxClaimAmount?: number;
      coPaymentPercent?: number;
      maxClaimsPerYear?: number;
      notes?: string;
    }>;
  }) {
    const pkg = await this.packageRepo.save(
      this.packageRepo.create({
        name: dto.name,
        description: dto.description,
        premiumPerMember: dto.premiumPerMember.toFixed(2),
        annualCeiling: (dto.annualCeiling ?? 0).toFixed(2),
        isActive: true,
      }),
    );

    if (dto.items?.length) {
      for (const item of dto.items) {
        await this.itemRepo.save(
          this.itemRepo.create({
            package: pkg,
            serviceName: item.serviceName,
            serviceCode: item.serviceCode,
            category: item.category,
            maxClaimAmount: (item.maxClaimAmount ?? 0).toFixed(2),
            coPaymentPercent: item.coPaymentPercent ?? 0,
            maxClaimsPerYear: item.maxClaimsPerYear ?? 0,
            notes: item.notes,
            isCovered: true,
          }),
        );
      }
    }

    return this.getPackageById(pkg.id);
  }

  async updatePackage(id: string, dto: Partial<{
    name: string;
    description: string;
    premiumPerMember: number;
    annualCeiling: number;
    isActive: boolean;
  }>) {
    const pkg = await this.getPackageById(id);
    if (dto.name) pkg.name = dto.name;
    if (dto.description !== undefined) pkg.description = dto.description;
    if (dto.premiumPerMember !== undefined) pkg.premiumPerMember = dto.premiumPerMember.toFixed(2);
    if (dto.annualCeiling !== undefined) pkg.annualCeiling = dto.annualCeiling.toFixed(2);
    if (dto.isActive !== undefined) pkg.isActive = dto.isActive;
    await this.packageRepo.save(pkg);
    return this.getPackageById(id);
  }

  async addItem(packageId: string, dto: {
    serviceName: string;
    serviceCode?: string;
    category: string;
    maxClaimAmount?: number;
    coPaymentPercent?: number;
    maxClaimsPerYear?: number;
    notes?: string;
  }) {
    const pkg = await this.getPackageById(packageId);
    const item = await this.itemRepo.save(
      this.itemRepo.create({
        package: pkg,
        serviceName: dto.serviceName,
        serviceCode: dto.serviceCode,
        category: dto.category,
        maxClaimAmount: (dto.maxClaimAmount ?? 0).toFixed(2),
        coPaymentPercent: dto.coPaymentPercent ?? 0,
        maxClaimsPerYear: dto.maxClaimsPerYear ?? 0,
        notes: dto.notes,
        isCovered: true,
      }),
    );
    return item;
  }

  async updateItem(itemId: string, dto: Partial<{
    serviceName: string;
    serviceCode: string;
    category: string;
    maxClaimAmount: number;
    coPaymentPercent: number;
    maxClaimsPerYear: number;
    isCovered: boolean;
    notes: string;
  }>) {
    const item = await this.itemRepo.findOne({ where: { id: itemId } });
    if (!item) throw new NotFoundException(`Benefit item ${itemId} not found.`);
    if (dto.serviceName) item.serviceName = dto.serviceName;
    if (dto.serviceCode !== undefined) item.serviceCode = dto.serviceCode;
    if (dto.category) item.category = dto.category;
    if (dto.maxClaimAmount !== undefined) item.maxClaimAmount = dto.maxClaimAmount.toFixed(2);
    if (dto.coPaymentPercent !== undefined) item.coPaymentPercent = dto.coPaymentPercent;
    if (dto.maxClaimsPerYear !== undefined) item.maxClaimsPerYear = dto.maxClaimsPerYear;
    if (dto.isCovered !== undefined) item.isCovered = dto.isCovered;
    if (dto.notes !== undefined) item.notes = dto.notes;
    return this.itemRepo.save(item);
  }

  async removeItem(itemId: string) {
    await this.itemRepo.delete(itemId);
    return { message: 'Item removed.' };
  }

  /** Check if a service is covered and return limits */
  async checkServiceCoverage(serviceName: string, packageId?: string) {
    const pkg = packageId
      ? await this.getPackageById(packageId)
      : await this.getActivePackage();

    const normalizedName = serviceName.trim().toLowerCase();
    const item = pkg.items?.find(
      (i) => i.isCovered && i.serviceName.toLowerCase().includes(normalizedName),
    );

    return {
      isCovered: !!item,
      item: item ?? null,
      packageName: pkg.name,
      packageId: pkg.id,
    };
  }

  private getDefaultPackage(): Partial<BenefitPackage> {
    return {
      id: 'default',
      name: 'Standard CBHI Package',
      description: 'Default benefit package — configure in Admin > Benefit Packages',
      premiumPerMember: '120.00',
      annualCeiling: '0.00',
      isActive: true,
      items: [],
    } as Partial<BenefitPackage>;
  }
}
