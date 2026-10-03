import { WorldRelay, Command, Status, Result } from './world-relay.js';
import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { ActivityJobs, type ActivityJob } from './activities.js';
import { validateRequest } from './domain.js';
import { GoogleProvider } from './provider.js';
import { GeminiActivityProvider, GeminiVideoProvider, HuaweiMaaSClient, HuaweiMaaSActivityProvider, HuaweiMaaSVideoProvider, ProviderAdapter } from './content-providers.js';
import { Relay, GameCommand } from './protocol.js';

async function body(req: IncomingMessage, limit = 16384): Promise<unknown> {
  let raw = ''; for await (const chunk of req) { raw += chunk; if (raw.length > limit) throw new Error('Request too large'); }
  return JSON.parse(raw);
}
function json(res: ServerResponse, value: unknown, code = 200) {
  res.writeHead(code, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' }); res.end(JSON.stringify(value));
}
function publicJob(job: ActivityJob) {
  return job.plan ? { ...job, plan: { ...job.plan, steps: job.plan.steps.map((step, index) => ({
    id: step.id, instruction: step.instruction, durationSeconds: step.durationSeconds, learningGoal: step.learningGoal,
    videoPrompt: step.veoPrompt, videoUrl: job.segments[index]?.videoUrl || '' })) } } : job;
}
export async function app(jobs: ActivityJobs, relay = new Relay(), huawei?: ActivityJobs) {
  const worldRelay = new WorldRelay();
  await jobs.initialize();
  await huawei?.initialize();
  return createServer(async (req, res) => {
    try {
      const url = new URL(req.url || '/', 'http://localhost'); const route = url.pathname;
      if (req.method === 'GET' && route === '/health') return json(res, { status: 'ok', protocolVersion: 1 });
      if (req.method === 'POST' && route === '/activities/generate') {
        const request = validateRequest(await body(req));
        if (request.provider === 'HUAWEI' && !huawei) return json(res, { error: 'Huawei provider unavailable. Choose Gemini or Built-in Video.' }, 503);
        return json(res, publicJob((request.provider === 'HUAWEI' ? huawei! : jobs).create(request)), 202);
      }
      if (req.method === 'POST' && route === '/media/import') {
        if (req.headers['content-type'] !== 'video/mp4') throw new Error('MP4 required');
        const chunks: Buffer[] = []; let size = 0;
        for await (const chunk of req) { size += chunk.length; if (size > 40 * 1024 * 1024) throw new Error('Video too large'); chunks.push(chunk); }
        return json(res, { videoUrl: await jobs.importVideo(Buffer.concat(chunks)), source: 'USER_VIDEO' }, 201);
      }
      const activity = /^\/activities\/([a-f0-9]{32})(\/status)?$/.exec(route);
      if (req.method === 'GET' && activity) { const owner = jobs.get(activity[1]) ? jobs : huawei; const job = owner?.get(activity[1]); if (job) await owner?.refreshReview(job);
        const result = job ? publicJob(job) : undefined;
        return json(res, result || { error: 'Not found' }, job ? 200 : 404); }
      const video = /^\/videos\/([a-f0-9]{64})$/.exec(route);
      if (req.method === 'GET' && video) {
        const file = await jobs.videoPath(video[1]); if (!file) return json(res, { error: 'Video missing or review required' }, 404);
        const size = (await stat(file)).size; const range = req.headers.range;
        const parts = typeof range === 'string' ? /^bytes=(\d+)-(\d*)$/.exec(range) : null;
        const start = parts ? Number(parts[1]) : 0; const end = parts && parts[2] ? Math.min(Number(parts[2]), size - 1) : size - 1;
        if (range && (!parts || start >= size || start > end)) { res.writeHead(416, { 'Content-Range': `bytes */${size}` }); return res.end(); }
        res.writeHead(parts ? 206 : 200, { 'Content-Type': 'video/mp4', 'Content-Length': end - start + 1, 'Accept-Ranges': 'bytes',
          ...(parts ? { 'Content-Range': `bytes ${start}-${end}/${size}` } : {}), 'Cache-Control': 'private, max-age=3600' });
        const stream = createReadStream(file, { start, end }); stream.on('error', () => res.destroy()); stream.pipe(res); return;
      }
      const world = /^\/world\/rooms\/([a-zA-Z0-9_-]{4,32})\/(phone|tablet|command)$/.exec(route);
      if (world) {
        if (req.method === 'GET') return json(res, worldRelay.poll(world[1],world[2]));
        if(req.method === 'POST' && world[2] === 'command'){worldRelay.command(world[1],await body(req,262144) as Command);return json(res,{ok:true});}
        if(req.method === 'POST' && world[2] === 'tablet'){worldRelay.tablet(world[1],await body(req,262144) as {status:Status;results:Result[]});return json(res,worldRelay.poll(world[1],'tablet'));}
      }
      const room = /^\/tv\/rooms\/([a-zA-Z0-9_-]{4,32})\/(phone|state|feedback|disconnect|game)$/.exec(route);
      if (room) {
        if (req.method === 'POST' && room[2] === 'phone') { relay.send(room[1], await body(req)); return json(res, relay.status(room[1], false)); }
        if (req.method === 'GET' && room[2] === 'state') return json(res, relay.status(room[1], url.searchParams.get('receiver') === 'true'));
        if (req.method === 'POST' && room[2] === 'game') { relay.game(room[1], await body(req) as GameCommand); return json(res, { ok: true }); }
        if (req.method === 'POST' && room[2] === 'feedback') { const value = await body(req) as { status: string }; relay.feedback(room[1], value.status); return json(res, { ok: true }); }
        if (req.method === 'POST' && room[2] === 'disconnect') { relay.disconnect(room[1]); return json(res, { ok: true }); }
      }
      json(res, { error: 'Not found' }, 404);
    } catch { if (!res.headersSent) json(res, { error: 'Invalid request or service failure' }, 400); else res.destroy(); }
  });
}
if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  const key = process.env.GEMINI_API_KEY;
  const gemini = process.env.GEMINI_MODEL || 'gemini-2.5-flash'; const veo = process.env.VEO_MODEL || 'veo-3.1-generate-preview';
  const google = key ? new GoogleProvider(key, gemini, veo) : undefined;
  const jobs = new ActivityJobs(resolve('data'), google ? new ProviderAdapter(new GeminiActivityProvider(google), new GeminiVideoProvider(google)) : undefined, veo, process.env.REQUIRE_VIDEO_REVIEW !== 'false');
  const huaweiClient = process.env.HUAWEI_MAAS_API_KEY ? new HuaweiMaaSClient(process.env.HUAWEI_MAAS_API_KEY) : undefined;
  const huaweiModel = process.env.HUAWEI_MAAS_MODEL || ''; const huaweiVideo = process.env.HUAWEI_MAAS_VIDEO_MODEL || 'Wan2.2-T2V-A14B';
  const huawei = new ActivityJobs(resolve('data'), huaweiClient && huaweiModel ? new ProviderAdapter(new HuaweiMaaSActivityProvider(huaweiClient, huaweiModel), new HuaweiMaaSVideoProvider(huaweiClient, huaweiVideo)) : undefined,
    `HUAWEI:${huaweiVideo}`, process.env.REQUIRE_VIDEO_REVIEW !== 'false', 'HUAWEI');
  const server = await app(jobs, new Relay(), huawei); const host = process.env.HOST || '127.0.0.1'; const port = Number(process.env.PORT || 18080);
  server.listen(port, host, () => console.log(`CompanionOS backend http://${host}:${port}; provider ${key ? 'configured (not yet verified)' : 'unconfigured; safe fallback'}`));
}
