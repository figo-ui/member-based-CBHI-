import { Process, Processor } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import { Job } from 'bull';
import { JobsService } from './jobs.service';

export const CBHI_JOBS_QUEUE = 'cbhi-jobs';
export const JOB_DAILY = 'daily';

/**
 * FIX ME-7: Bull queue processor — handles job execution.
 * Multi-instance safe: only one instance processes each job even when
 * multiple backend containers are running.
 */
@Processor(CBHI_JOBS_QUEUE)
export class JobsProcessor {
  private readonly logger = new Logger(JobsProcessor.name);

  constructor(private readonly jobsService: JobsService) {}

  @Process(JOB_DAILY)
  async handleDailyJobs(job: Job): Promise<void> {
    this.logger.log(`Processing daily jobs (job id: ${job.id})`);
    try {
      await this.jobsService.runDailyJobs();
      this.logger.log(`Daily jobs completed (job id: ${job.id})`);
    } catch (error) {
      this.logger.error(
        `Daily jobs failed (job id: ${job.id}): ${(error as Error).message}`,
      );
      throw error; // Re-throw so Bull marks the job as failed and retries
    }
  }
}
