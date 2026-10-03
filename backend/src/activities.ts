import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile, rename, stat } from 'node:fs/promises';
import { join } from 'node:path';
import { cacheKey, fallbackPlan, validatePlan, type GenerateRequest, type Plan } from './domain.js';
import type { ActivityProvider } from './provider.js';

export interface Segment { id: string; state: 'QUEUED' | 'GENERATING' | 'READY' | 'FAILED'; cacheState: string;
  videoUrl: string; reviewed: boolean; error: string; }
export interface ActivityJob { id: string; state: string; source: 'ai' | 'fallback'; message: string; request: GenerateRequest; provider?: string;
  plan?: Plan; segments: Segment[]; }
export class ActivityJobs {
  private jobs = new Map<string, ActivityJob>();
  private inFlight = new Map<string, Promise<void>>();
  constructor(private directory: string, private provider?: ActivityProvider, private model = 'veo-3.1-generate-preview', private review = true,
    private providerName = 'GEMINI') {}
  async initialize(): Promise<void> { await mkdir(join(this.directory, 'videos'), { recursive: true }); }
  create(request: GenerateRequest): ActivityJob {
    const id = createHash('sha256').update(JSON.stringify([request, this.providerName, this.model, 'plan-v1'])).digest('hex').slice(0, 32);
    const existing = this.jobs.get(id); if (existing) return existing;
    if (this.jobs.size >= 100) throw new Error('Job limit reached; restart demo backend to clear inactive jobs');
    const job: ActivityJob = { id, state: 'PLANNING', source: 'fallback', provider: this.providerName, message: 'Planning activity...', request, segments: [] };
    this.jobs.set(id, job); void this.generate(job).catch(() => {
      job.state = 'FAILED'; job.message = 'Generation failed. Offline activities remain available.';
    }); return job;
  }
  get(id: string): ActivityJob | undefined { return this.jobs.get(id); }
  async refreshReview(job: ActivityJob): Promise<void> {
    for (const segment of job.segments) {
      if (segment.state !== 'READY' || segment.videoUrl) continue;
      try {
        const metadata = JSON.parse(await readFile(join(this.directory, 'videos', `${segment.id}.json`), 'utf8'));
        if (metadata.reviewed === true) { segment.reviewed = true; segment.videoUrl = `/videos/${segment.id}`; segment.error = ''; }
      } catch { /* Unreviewed or unavailable clips retain the safe fallback. */ }
    }
  }
  private async generate(job: ActivityJob): Promise<void> {
    if (this.provider) {
      for (let attempt = 0; attempt < 2; attempt++) {
        try { job.plan = validatePlan(await this.provider.plan(job.request), job.request); job.source = 'ai'; break; }
        catch { job.message = attempt === 0 ? 'Retrying validated planning once...' : 'AI planning failed. Safe fallback plan.'; }
      }
    }
    if (!job.plan) {
      job.plan = fallbackPlan(job.request); job.source = 'fallback'; job.state = 'READY';
      job.message = this.provider ? 'AI unavailable or invalid. Safe fallback visuals ready.' : 'No provider key configured. Safe fallback visuals ready.';
      job.segments = job.plan.steps.map((s) => ({ id: cacheKey(job.id, s, this.model), state: 'FAILED', cacheState: 'FAILED',
        videoUrl: '', reviewed: false, error: 'Fallback visual; no generated video' })); return;
    }
    job.segments = job.plan.steps.map(s => ({ id: cacheKey(job.id, s, this.model), state: 'QUEUED', cacheState: 'GENERATING',
      videoUrl: '', reviewed: false, error: '' }));
    job.state = 'GENERATING';
    // Sequential provider jobs bound cost/concurrency; first approved clip unlocks play while later clips continue.
    for (let index = 0; index < job.plan.steps.length; index++) {
      job.message = `Generating video ${index + 1} / ${job.plan.steps.length}...`;
      const segment = job.segments[index];
      const prior = this.inFlight.get(segment.id);
      if (prior) await prior;
      else {
        const work = this.generateSegment(segment, job.plan.steps[index].veoPrompt);
        this.inFlight.set(segment.id, work); try { await work; } finally { this.inFlight.delete(segment.id); }
      }
      if (index === 0) job.state = 'PLAYABLE';
    }
    job.state = 'READY';
    job.message = job.segments.some(s => s.state === 'READY' && s.reviewed) ? 'Ready to play. Approved cached videos and safe fallbacks.' :
      'Ready with safe visuals. Generated videos may require review or have failed.';
  }
  private async generateSegment(segment: Segment, prompt: string): Promise<void> {
    const metadata = join(this.directory, 'videos', `${segment.id}.json`);
    try {
      const cached = JSON.parse(await readFile(metadata, 'utf8')) as { reviewed?: boolean; model?: string };
      await stat(join(this.directory, 'videos', `${segment.id}.mp4`));
      if (cached.model === this.model) {
        segment.state = 'READY'; segment.cacheState = 'LOCAL_READY'; segment.reviewed = cached.reviewed === true;
        segment.videoUrl = !this.review || segment.reviewed ? `/videos/${segment.id}` : ''; return;
      }
    } catch { /* cache miss or damaged metadata */ }
    segment.state = 'GENERATING';
    try {
      if (!this.provider) throw new Error('Provider unavailable');
      const uri = await this.provider.video(prompt); const bytes = await this.provider.download(uri);
      const file = join(this.directory, 'videos', `${segment.id}.mp4`);
      await writeFile(`${file}.tmp`, bytes); await rename(`${file}.tmp`, file);
      await writeFile(metadata, JSON.stringify({ model: this.model, reviewed: false, generatedAt: Date.now() }));
      segment.state = 'READY'; segment.cacheState = 'LOCAL_READY'; segment.reviewed = false;
      segment.videoUrl = this.review ? '' : `/videos/${segment.id}`;
      if (this.review) segment.error = 'Adult video review required before child playback';
    } catch {
      segment.state = 'FAILED'; segment.cacheState = 'FAILED'; segment.videoUrl = ''; segment.error = 'Video unavailable. Safe fallback visual.';
    }
  }
  async videoPath(id: string): Promise<string | undefined> {
    if (!/^[a-f0-9]{64}$/.test(id)) return undefined;
    try {
      const metadata = JSON.parse(await readFile(join(this.directory, 'videos', `${id}.json`), 'utf8'));
      if (this.review && metadata.reviewed !== true) return undefined;
      const file = join(this.directory, 'videos', `${id}.mp4`); await stat(file); return file;
    } catch { return undefined; }
  }
  async importVideo(bytes: Uint8Array): Promise<string> {
    if (bytes.length < 16 || bytes.length > 40 * 1024 * 1024 || Buffer.from(bytes.subarray(4, 8)).toString() !== 'ftyp') throw new Error('Import requires an MP4 up to 40 MiB');
    const id = createHash('sha256').update(bytes).digest('hex');
    const file = join(this.directory, 'videos', `${id}.mp4`);
    await writeFile(`${file}.tmp`, bytes); await rename(`${file}.tmp`, file);
    await writeFile(join(this.directory, 'videos', `${id}.json`), JSON.stringify({ source: 'USER_VIDEO', reviewed: true, importedAt: Date.now() }));
    return `/videos/${id}`;
  }
}
