import { SAFETY_PROMPT, planSchema, type GenerateRequest, type Plan } from './domain.js';

export interface ActivityProvider {
  plan(request: GenerateRequest): Promise<unknown>;
  video(prompt: string): Promise<string>;
  download(uri: string): Promise<Uint8Array>;
}
const base = 'https://generativelanguage.googleapis.com/v1beta';
export class GoogleProvider implements ActivityProvider {
  constructor(private key: string, private gemini: string, private veo: string, private request: typeof fetch = fetch,
    private sleep: (ms: number) => Promise<void> = ms => new Promise(resolve => setTimeout(resolve, ms))) {}
  private async json(url: string, body?: unknown): Promise<Record<string, any>> {
    const response = await this.request(url, { method: body ? 'POST' : 'GET', headers: {
      'x-goog-api-key': this.key, ...(body ? { 'Content-Type': 'application/json' } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(45000) });
    if (!response.ok) throw new Error(`Provider HTTP ${response.status}`);
    const raw = await response.text(); if (raw.length > 1000000) throw new Error('Provider response too large');
    return JSON.parse(raw);
  }
  async plan(request: GenerateRequest): Promise<Plan> {
    const result = await this.json(`${base}/models/${encodeURIComponent(this.gemini)}:generateContent`, {
      systemInstruction: { parts: [{ text: SAFETY_PROMPT }] }, contents: [{ role: 'user', parts: [{ text: JSON.stringify(request) }] }],
      generationConfig: { responseMimeType: 'application/json', responseJsonSchema: planSchema, temperature: 0.3 }
    });
    const raw = result.candidates?.[0]?.content?.parts?.filter((p: { text?: string }) => p.text).map((p: { text: string }) => p.text).join('');
    if (!raw || raw.length > 16000) throw new Error('No structured provider plan'); return JSON.parse(raw);
  }
  async video(prompt: string): Promise<string> {
    const operation = await this.json(`${base}/models/${encodeURIComponent(this.veo)}:predictLongRunning`, {
      instances: [{ prompt }], parameters: { aspectRatio: '16:9', resolution: '720p', durationSeconds: 8, sampleCount: 1,
        personGeneration: 'dont_allow', negativePrompt: 'violence, weapons, frightening imagery, flashing, strobe, dangerous movement' }
    });
    if (typeof operation.name !== 'string' || !/^models\/[a-zA-Z0-9._-]+\/operations\/[a-zA-Z0-9._-]+$/.test(operation.name)) throw new Error('Invalid operation');
    const deadline = Date.now() + 12 * 60 * 1000;
    while (Date.now() < deadline) {
      await this.sleep(10000); const status = await this.json(`${base}/${operation.name}`);
      if (status.error) throw new Error('Video generation failed');
      if (status.done) {
        const uri = status.response?.generateVideoResponse?.generatedSamples?.[0]?.video?.uri;
        if (typeof uri !== 'string') throw new Error('No video result'); return uri;
      }
    }
    throw new Error('Video generation timed out');
  }
  async download(uri: string): Promise<Uint8Array> {
    const url = new URL(uri);
    if (url.protocol !== 'https:' || url.hostname !== 'generativelanguage.googleapis.com') throw new Error('Untrusted provider download');
    let target = url;
    let response: Response | undefined;
    for (let hop = 0; hop < 4; hop++) {
      if (target.protocol !== 'https:' || !['generativelanguage.googleapis.com', 'storage.googleapis.com'].includes(target.hostname)) throw new Error('Untrusted download redirect');
      response = await this.request(target, { headers: target.hostname === 'generativelanguage.googleapis.com' ? { 'x-goog-api-key': this.key } : {},
        redirect: 'manual', signal: AbortSignal.timeout(60000) });
      if (![301, 302, 303, 307, 308].includes(response.status)) break;
      const location = response.headers.get('location'); if (!location) throw new Error('Invalid download redirect');
      target = new URL(location, target); response = undefined;
    }
    if (!response) throw new Error('Too many download redirects');
    if (!response.ok) throw new Error('Video download failed');
    const reader = response.body?.getReader(); if (!reader) throw new Error('Empty video response');
    const chunks: Uint8Array[] = []; let size = 0;
    while (true) {
      const part = await reader.read(); if (part.done) break; size += part.value.length;
      if (size > 40 * 1024 * 1024) { await reader.cancel(); throw new Error('Video exceeds size limit'); }
      chunks.push(part.value);
    }
    const bytes = new Uint8Array(Buffer.concat(chunks));
    if (bytes.length < 16 || bytes.length > 40 * 1024 * 1024 || Buffer.from(bytes.subarray(4, 8)).toString() !== 'ftyp') throw new Error('Invalid or oversized MP4');
    return bytes;
  }
}
