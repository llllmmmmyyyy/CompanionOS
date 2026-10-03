import { GoogleProvider, type ActivityProvider } from './provider.js';
import { SAFETY_PROMPT, planSchema, type GenerateRequest, type Plan } from './domain.js';

export interface AiActivityProvider { generateActivity(request: GenerateRequest): Promise<Plan>; }
export interface GeneratedVideo { uri: string; }
export interface VideoGenerationProvider { generateVideo(prompt: string): Promise<GeneratedVideo>; download(uri: string): Promise<Uint8Array>; }
// Adapt the existing Gemini/Veo client; validation, queues, review and caching remain shared.
export class GeminiActivityProvider implements AiActivityProvider {
  constructor(private google: GoogleProvider) {}
  async generateActivity(request: GenerateRequest): Promise<Plan> { return await this.google.plan(request) as Plan; }
}
export class GeminiVideoProvider implements VideoGenerationProvider {
  constructor(private google: GoogleProvider) {}
  async generateVideo(prompt: string): Promise<GeneratedVideo> { return { uri: await this.google.video(prompt) }; }
  download(uri: string): Promise<Uint8Array> { return this.google.download(uri); }
}
export class ProviderAdapter implements ActivityProvider {
  constructor(private activity: AiActivityProvider, private media: VideoGenerationProvider) {}
  plan(request: GenerateRequest): Promise<Plan> { return this.activity.generateActivity(request); }
  async video(prompt: string): Promise<string> { return (await this.media.generateVideo(prompt)).uri; }
  download(uri: string): Promise<Uint8Array> { return this.media.download(uri); }
}

export class HuaweiMaaSClient {
  constructor(private key: string, private request: typeof fetch = fetch) {}
  async json(path: string, body?: unknown): Promise<Record<string, any>> {
    const response = await this.request(`https://api.modelarts-maas.com${path}`, {
      method: body ? 'POST' : 'GET', headers: { Authorization: `Bearer ${this.key}`, 'Content-Type': 'application/json' },
      ...(body ? { body: JSON.stringify(body) } : {}), redirect: 'error', signal: AbortSignal.timeout(45000)
    });
    if (!response.ok) throw new Error(`Huawei provider HTTP ${response.status}`);
    const raw = await response.text(); if (raw.length > 1000000) throw new Error('Provider response too large');
    return JSON.parse(raw);
  }
  async download(uri: string): Promise<Uint8Array> {
    const url = new URL(uri);
    // Explicit operator-configured host list; never send the MaaS key to storage or follow redirects.
    const allowed = (process.env.HUAWEI_VIDEO_DOWNLOAD_HOSTS || '').split(',').map(v => v.trim()).filter(Boolean);
    if (url.protocol !== 'https:' || url.username || url.password || !allowed.includes(url.hostname)) throw new Error('Untrusted Huawei video download');
    const response = await this.request(url, { redirect: 'error', signal: AbortSignal.timeout(60000) });
    if (!response.ok || !response.body) throw new Error('Video download failed');
    const reader = response.body.getReader(); const chunks: Uint8Array[] = []; let size = 0;
    while (true) { const part = await reader.read(); if (part.done) break; size += part.value.length;
      if (size > 40 * 1024 * 1024) { await reader.cancel(); throw new Error('Video too large'); } chunks.push(part.value); }
    const bytes = Buffer.concat(chunks);
    if (bytes.length < 16 || bytes.subarray(4, 8).toString() !== 'ftyp') throw new Error('Invalid MP4');
    return bytes;
  }
}
export class HuaweiMaaSActivityProvider implements AiActivityProvider {
  constructor(private client: HuaweiMaaSClient, private model: string) {}
  async generateActivity(request: GenerateRequest): Promise<Plan> {
    if (!this.model) throw new Error('Huawei chat model not configured');
    const result = await this.client.json('/v2/chat/completions', { model: this.model, stream: false, temperature: 0.3,
      messages: [{ role: 'system', content: `${SAFETY_PROMPT}\nJSON schema: ${JSON.stringify(planSchema)}` },
        { role: 'user', content: JSON.stringify(request) }] });
    const raw = result.choices?.[0]?.message?.content;
    if (typeof raw !== 'string' || raw.length > 16000) throw new Error('No structured Huawei plan');
    return JSON.parse(raw) as Plan;
  }
}
export class HuaweiMaaSVideoProvider implements VideoGenerationProvider {
  constructor(private client: HuaweiMaaSClient, private model: string,
    private sleep: (ms: number) => Promise<void> = ms => new Promise(resolve => setTimeout(resolve, ms))) {}
  async generateVideo(prompt: string): Promise<GeneratedVideo> {
    if (!this.model) throw new Error('Huawei video model not configured');
    const created = await this.client.json('/v1/video/generations', { model: this.model,
      input: { prompt: `${prompt.slice(0, 750)} Gentle steady camera, soft colors, 16:9. No violence, weapons, frightening imagery, flashing, strobe or risky challenges. Adult accompanied.` },
      parameters: { size: '1280x720', fps: 16, duration: 5 } });
    if (typeof created.task_id !== 'string' || !/^[a-zA-Z0-9_-]{1,100}$/.test(created.task_id)) throw new Error('Invalid Huawei task ID');
    const deadline = Date.now() + 12 * 60 * 1000;
    while (Date.now() < deadline) {
      await this.sleep(10000); const status = await this.client.json(`/v1/video/generations/${created.task_id}`);
      if (status.status === 'failed') throw new Error('Huawei video failed');
      if (status.status === 'succeeded') {
        if (typeof status.content?.result_url !== 'string') throw new Error('No Huawei video result');
        return { uri: status.content.result_url };
      }
      if (!['queued', 'running'].includes(status.status)) throw new Error('Invalid Huawei video status');
    }
    throw new Error('Huawei video timed out');
  }
  download(uri: string): Promise<Uint8Array> { return this.client.download(uri); }
}
