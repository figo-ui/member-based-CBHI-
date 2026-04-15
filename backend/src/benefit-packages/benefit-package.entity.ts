import { Column, Entity, ManyToOne, OneToMany } from 'typeorm';
import { AuditableEntity } from '../common/entities/auditable.entity';

@Entity('benefit_packages')
export class BenefitPackage extends AuditableEntity {
  @Column({ length: 120 })
  name!: string;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @Column({ default: true })
  isActive!: boolean;

  /** Annual premium per member in ETB */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: '120.00' })
  premiumPerMember!: string;

  /** Annual benefit ceiling per household in ETB (0 = unlimited) */
  @Column({ type: 'decimal', precision: 12, scale: 2, default: '0.00' })
  annualCeiling!: string;

  @OneToMany(() => BenefitItem, (item) => item.package, { cascade: true, eager: true })
  items!: BenefitItem[];
}

@Entity('benefit_items')
export class BenefitItem extends AuditableEntity {
  @Column({ length: 160 })
  serviceName!: string;

  /** ICD-10 or local service code */
  @Column({ type: 'varchar', length: 32, nullable: true })
  serviceCode?: string | null;

  /** Service category: outpatient, inpatient, pharmacy, lab, surgery, etc. */
  @Column({ length: 64 })
  category!: string;

  /** Max reimbursable amount per claim in ETB (0 = no limit) */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: '0.00' })
  maxClaimAmount!: string;

  /** Co-payment percentage (0-100) */
  @Column({ type: 'int', default: 0 })
  coPaymentPercent!: number;

  /** Max claims per year (0 = unlimited) */
  @Column({ type: 'int', default: 0 })
  maxClaimsPerYear!: number;

  @Column({ default: true })
  isCovered!: boolean;

  @Column({ type: 'text', nullable: true })
  notes?: string | null;

  @ManyToOne(() => BenefitPackage, (pkg) => pkg.items, { onDelete: 'CASCADE' })
  package!: BenefitPackage;
}
