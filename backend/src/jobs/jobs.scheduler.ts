import { InjectQueue } from '@nestjs/bull';
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import type { Queue } from 'bull';
import { CBHI_JOBS_QUEUE, JOB_DAILY } from './jobs.processor';

/**
 * JobsScheduler — uses Bull cron scheduling so only one instance in a
 * multi-container deployment runs the job at any given time.
 *
 * Gracefully degrades when Redis is unavailable (dev without Redis).
 */
@Injectable()
export class JobsScheduler implements OnModuleInit {
  private readonly logger = new Logger(JobsScheduler.name);

  constructor(
    @InjectQueue(CBHI_JOBS_QUEUE)
    private readonly jobsQueue: Queue,
  ) {}

  async onModuleInit(): Promise<void> {
    // Skip scheduling if Redis is not configured
    if (!process.env.REDIS_HOST) {
      this.logger.warn(
        'REDIS_HOST not set — Bull job scheduling disabled. ' +
        'Set REDIS_HOST to enable background jobs.',
      );
      return;
    }

    try {
      // Remove stale repeatable jobs from previous deployments
      const repeatableJobs = await this.jobsQueue.getRepeatableJobs();
      for (const job of repeatableJobs) {
        await this.jobsQueue.removeRepeatableByKey(job.key);
      }

      // Schedule daily job at 00:05 UTC
      await this.jobsQueue.add(
        JOB_DAILY,
        {},
        {
          repeat: { cron: '5 0 * * *' },
          removeOnComplete: 10,
          removeOnFail: 20,
          attempts: 3,
          backoff: { type: 'exponential', delay: 60_000 },
        },
      );

      this.logger.log('Daily job scheduled via Bull (cron: 5 0 * * *)');

      // Run once on startup after 30s to catch up on missed jobs
      await this.jobsQueue.add(
        JOB_DAILY,
        { reason: 'startup' },
        { delay: 30_000, removeOnComplete: true, attempts: 2 },
      );

      this.logger.log('Startup job queued (runs in 30s)');
    } catch (err) {
      this.logger.error(
        `Failed to schedule Bull jobs (Redis may be unavailable): ${(err as Error).message}`,
      );
      // Don't crash the app — jobs will be scheduled on next restart
    }
  }
}
