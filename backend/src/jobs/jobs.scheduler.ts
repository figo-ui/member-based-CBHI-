import { InjectQueue } from '@nestjs/bull';
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Queue } from 'bull';
import { CBHI_JOBS_QUEUE, JOB_DAILY } from './jobs.processor';

/**
 * FIX ME-7: JobsScheduler replaces the old setInterval approach.
 * Uses Bull's built-in cron scheduling so only one instance in a
 * multi-container deployment runs the job at any given time.
 *
 * Schedule: daily at 00:05 UTC (5 minutes after midnight to avoid
 * contention with other midnight tasks).
 */
@Injectable()
export class JobsScheduler implements OnModuleInit {
  private readonly logger = new Logger(JobsScheduler.name);

  constructor(
    @InjectQueue(CBHI_JOBS_QUEUE)
    private readonly jobsQueue: Queue,
  ) {}

  async onModuleInit(): Promise<void> {
    // Remove any stale repeatable jobs from previous deployments
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
        removeOnComplete: 10,  // Keep last 10 completed jobs for debugging
        removeOnFail: 20,      // Keep last 20 failed jobs for investigation
        attempts: 3,           // Retry up to 3 times on failure
        backoff: {
          type: 'exponential',
          delay: 60_000,       // Start with 1 minute, then 2, then 4
        },
      },
    );

    this.logger.log('Daily job scheduled via Bull (cron: 5 0 * * *)');

    // Also run once on startup after a 30-second delay to catch up
    // on any missed jobs (e.g., after a deployment)
    await this.jobsQueue.add(
      JOB_DAILY,
      { reason: 'startup' },
      {
        delay: 30_000,
        removeOnComplete: true,
        attempts: 2,
      },
    );

    this.logger.log('Startup job queued (runs in 30s)');
  }
}
