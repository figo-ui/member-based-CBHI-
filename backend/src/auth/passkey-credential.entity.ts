import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { AuditableEntity } from '../common/entities/auditable.entity';
import { User } from '../users/user.entity';

@Entity('passkey_credentials')
export class PasskeyCredential extends AuditableEntity {
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  /** base64url-encoded credential ID */
  @Column({ type: 'varchar', length: 512 })
  credentialId!: string;

  /** COSE-encoded public key (base64url) */
  @Column({ type: 'text' })
  publicKey!: string;

  /** Replay attack prevention counter */
  @Column({ type: 'bigint', default: 0 })
  signCount!: number;

  /** Relying party ID (domain) */
  @Column({ type: 'varchar', length: 255 })
  rpId!: string;

  /** User-friendly device label */
  @Column({ type: 'varchar', length: 255, nullable: true })
  deviceName?: string | null;

  /** Last time this credential was used for authentication */
  @Column({ type: 'timestamptz', nullable: true })
  lastUsedAt?: Date | null;
}
