import { Column, Entity, ManyToOne } from 'typeorm';
import { AuditableEntity } from '../common/entities/auditable.entity';
import { Claim } from './claim.entity';
import { User } from '../users/user.entity';

export enum AppealStatus {
  PENDING = 'PENDING',
  UNDER_REVIEW = 'UNDER_REVIEW',
  UPHELD = 'UPHELD',
  OVERTURNED = 'OVERTURNED',
}

@Entity('claim_appeals')
export class ClaimAppeal extends AuditableEntity {
  @ManyToOne(() => Claim, { onDelete: 'CASCADE' })
  claim!: Claim;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  appellant!: User;

  @Column({ type: 'text' })
  reason!: string;

  @Column({ type: 'enum', enum: AppealStatus, default: AppealStatus.PENDING })
  status!: AppealStatus;

  @Column({ type: 'text', nullable: true })
  reviewNote?: string | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  reviewedBy?: User | null;

  @Column({ type: 'timestamptz', nullable: true })
  reviewedAt?: Date | null;
}
