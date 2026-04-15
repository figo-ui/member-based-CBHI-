import { Column, Entity, ManyToOne } from 'typeorm';
import { AuditableEntity } from '../common/entities/auditable.entity';
import { User } from '../users/user.entity';

export enum GrievanceType {
  CLAIM_REJECTION = 'CLAIM_REJECTION',
  FACILITY_DENIAL = 'FACILITY_DENIAL',
  ENROLLMENT_ISSUE = 'ENROLLMENT_ISSUE',
  PAYMENT_ISSUE = 'PAYMENT_ISSUE',
  INDIGENT_REJECTION = 'INDIGENT_REJECTION',
  OTHER = 'OTHER',
}

export enum GrievanceStatus {
  OPEN = 'OPEN',
  UNDER_REVIEW = 'UNDER_REVIEW',
  RESOLVED = 'RESOLVED',
  CLOSED = 'CLOSED',
}

@Entity('grievances')
export class Grievance extends AuditableEntity {
  @Column({ type: 'enum', enum: GrievanceType })
  type!: GrievanceType;

  @Column({ type: 'enum', enum: GrievanceStatus, default: GrievanceStatus.OPEN })
  status!: GrievanceStatus;

  @Column({ length: 200 })
  subject!: string;

  @Column({ type: 'text' })
  description!: string;

  /** Reference to the entity being grieved (claim ID, application ID, etc.) */
  @Column({ type: 'varchar', length: 36, nullable: true })
  referenceId?: string | null;

  @Column({ type: 'varchar', length: 80, nullable: true })
  referenceType?: string | null;

  @Column({ type: 'text', nullable: true })
  resolution?: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  resolvedAt?: Date | null;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  submittedBy!: User;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  assignedTo?: User | null;
}
