import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, readFile, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { validateRequest, validatePlan, fallbackPlan, cacheKey } from '../dist/domain.js';
import { ActivityJobs } from '../dist/activities.js';
import { GoogleProvider } from '../dist/provider.js';
import { Relay, waitingMessage, validMessage } from '../dist/protocol.js';
import { app } from '../dist/server.js';
const request = { childAge: '4–5', interests: ['Movement'], activityCategory: 'MOVE', educationalGoal: 'Count five together', durationMinutes: 3 };
async function ready(jobs, job) { for (let i = 0; i < 100 && !['READY', 'FAILED'].includes(job.state); i++) await new Promise(r => setTimeout(r, 5)); assert.equal(job.state, 'READY'); return job; }
async function directory(t) { const dir = await mkdtemp(join(tmpdir(), 'companion-test-')); t.after(() => rm(dir, { recursive: true, force: true })); return dir; }
const fakeBytes = Uint8Array.from(Buffer.concat([Buffer.from([0, 0, 0, 24]), Buffer.from('ftyp'), Buffer.alloc(24)]));

test('input validation and safe duration-matched fallback for all categories', () => {
  for (const category of ['MOVE', 'LEARN', 'IMAGINE', 'CALM']) for (const minutes of [3, 5, 10]) {
    const r = validateRequest({ ...request, activityCategory: category, durationMinutes: minutes });
    assert.equal(validatePlan(fallbackPlan(r), r).steps.reduce((n, s) => n + s.durationSeconds, 0), minutes * 60);
  }
  for (const r of [null, { ...request, childAge: '2' }, { ...request, educationalGoal: 'climb' }, { ...request, interests: [] }]) assert.throws(() => validateRequest(r));
});
test('strict plan rejects extra keys, missing rest, duplicate step ids and unsafe instructions', () => {
  for (const mutate of [p => p.key = 'secret', p => p.steps[1].instruction = 'Jump off a chair',
    p => p.steps[2].instruction = 'Count again', p => p.steps[1].id = p.steps[0].id, p => p.steps[0].durationSeconds = 1]) {
    const plan = fallbackPlan(request); mutate(plan); assert.throws(() => validatePlan(plan, request));
  }
});
test('missing key produces honest fallback without any video success', async t => {
  const jobs = new ActivityJobs(await directory(t)); await jobs.initialize();
  const job = await ready(jobs, jobs.create(request)); assert.equal(job.source, 'fallback');
  assert.ok(job.message.includes('No provider key')); assert.ok(job.segments.every(s => s.state === 'FAILED' && !s.videoUrl));
  assert.equal(jobs.create(request), job);
});
test('invalid Gemini output retries exactly once then falls back', async t => {
  let calls = 0; const jobs = new ActivityJobs(await directory(t), { plan: async () => { calls++; return {}; },
    video: async () => { throw Error('should not call'); }, download: async () => fakeBytes }); await jobs.initialize();
  const job = await ready(jobs, jobs.create(request)); assert.equal(calls, 2); assert.equal(job.source, 'fallback');
});
test('second valid planning attempt succeeds, video failures remain safe', async t => {
  let calls = 0; const jobs = new ActivityJobs(await directory(t), { plan: async () => ++calls === 1 ? {} : fallbackPlan(request),
    video: async () => { throw Error('failed'); }, download: async () => fakeBytes }); await jobs.initialize();
  const job = await ready(jobs, jobs.create(request)); assert.equal(calls, 2); assert.equal(job.source, 'ai');
  assert.ok(job.segments.every(s => s.state === 'FAILED' && !s.videoUrl));
});
test('mocked video results are stored, review-gated, reused from disk, and model keys differ', async t => {
  const dir = await directory(t); let videoCalls = 0;
  const provider = { plan: async () => fallbackPlan(request), video: async () => { videoCalls++; return 'https://provider.invalid/video'; }, download: async () => fakeBytes };
  const jobs = new ActivityJobs(dir, provider, 'veo-test'); await jobs.initialize(); const job = await ready(jobs, jobs.create(request));
  assert.equal(videoCalls, 3); assert.ok(job.segments.every(s => s.state === 'READY' && s.videoUrl === ''));
  assert.equal(await jobs.videoPath(job.segments[0].id), undefined);
  const again = new ActivityJobs(dir, provider, 'veo-test', false); await again.initialize(); const cached = await ready(again, again.create(request));
  assert.equal(videoCalls, 3); assert.ok(cached.segments[0].videoUrl.startsWith('/videos/'));
  assert.ok((await readFile(await again.videoPath(cached.segments[0].id))).length > 16);
  assert.notEqual(cacheKey(job.id, job.plan.steps[0], 'a'), cacheKey(job.id, job.plan.steps[0], 'b'));
});
test('progressive generation exposes PLAYABLE before final clip is finished', async t => {
  let release; let calls = 0; const held = new Promise(r => release = r);
  const jobs = new ActivityJobs(await directory(t), { plan: async () => fallbackPlan(request), video: async () => {
    if (++calls === 2) await held; return 'https://provider.invalid/video'; }, download: async () => fakeBytes }, 'veo-test', false);
  await jobs.initialize(); const job = jobs.create(request);
  for (let i = 0; i < 100 && calls < 2; i++) await new Promise(r => setTimeout(r, 5));
  assert.equal(job.state, 'PLAYABLE'); assert.equal(job.segments[0].state, 'READY'); release(); await ready(jobs, job);
});
test('adult approval updates active job metadata and permits video serving', async t => {
  const dir = await directory(t); const jobs = new ActivityJobs(dir, { plan: async () => fallbackPlan(request),
    video: async () => 'https://mock.invalid/video', download: async () => fakeBytes }); await jobs.initialize();
  const job = await ready(jobs, jobs.create(request)); const segment = job.segments[0];
  const file = join(dir, 'videos', segment.id + '.json'); const metadata = JSON.parse(await readFile(file, 'utf8'));
  metadata.reviewed = true; await writeFile(file, JSON.stringify(metadata)); await jobs.refreshReview(job);
  assert.equal(segment.reviewed, true); assert.equal(segment.videoUrl, '/videos/' + segment.id);
  assert.ok(await jobs.videoPath(segment.id));
});
test('video download follows trusted redirect without forwarding provider key to storage', async () => {
  const requests = []; const provider = new GoogleProvider('test-only-key', 'model', 'veo', async (url, init) => {
    requests.push({ url: String(url), init });
    if (requests.length === 1) return new Response(null, { status: 302, headers: { location: 'https://storage.googleapis.com/test/video.mp4' } });
    return new Response(fakeBytes);
  });
  assert.equal((await provider.download('https://generativelanguage.googleapis.com/v1beta/files/test')).length, fakeBytes.length);
  assert.equal(requests[0].init.headers['x-goog-api-key'], 'test-only-key'); assert.equal(requests[1].init.headers['x-goog-api-key'], undefined);
  const unsafe = new GoogleProvider('test', 'model', 'veo', async () => new Response(null, { status: 302, headers: { location: 'https://evil.invalid/video' } }));
  await assert.rejects(unsafe.download('https://generativelanguage.googleapis.com/v1beta/files/test'));
});
test('Google REST provider uses structured plan and real Veo operation shape with mocked HTTP', async () => {
  const seen = []; const responses = [
    { candidates: [{ content: { parts: [{ text: JSON.stringify(fallbackPlan(request)) }] } }] },
    { name: 'models/veo-3.1-generate-preview/operations/test' },
    { done: false }, { done: true, response: { generateVideoResponse: { generatedSamples: [{ video: { uri: 'https://generativelanguage.googleapis.com/v1beta/files/test' } }] } } }
  ];
  const provider = new GoogleProvider('test-only-not-a-real-key', 'gemini-test', 'veo-3.1-generate-preview', async (url, init) => {
    seen.push({ url: String(url), init }); return new Response(JSON.stringify(responses.shift()), { status: 200 });
  }, async () => {});
  assert.equal((await provider.plan(request)).title, 'Dino Movement Adventure');
  assert.ok((await provider.video('safe prompt')).startsWith('https://generativelanguage'));
  assert.ok(JSON.parse(seen[0].init.body).generationConfig.responseJsonSchema);
  assert.equal(JSON.parse(seen[1].init.body).parameters.aspectRatio, '16:9');
  assert.equal(JSON.parse(seen[1].init.body).parameters.resolution, '720p');
});
test('provider network error, operation failure and untrusted video download fail explicitly', async () => {
  const failure = new GoogleProvider('test', 'model', 'veo', async () => new Response('{}', { status: 403 }));
  await assert.rejects(failure.plan(request));
  const timeout = new GoogleProvider('test', 'model', 'veo', async () => { throw new DOMException('timeout', 'TimeoutError'); });
  await assert.rejects(timeout.plan(request));
  const responses = [{ name: 'models/veo/operations/id' }, { error: { code: 1 } }];
  const operation = new GoogleProvider('test', 'model', 'veo', async () => new Response(JSON.stringify(responses.shift())), async () => {});
  await assert.rejects(operation.video('safe')); await assert.rejects(operation.download('http://127.0.0.1/private'));
});
test('relay validates all command types, detects disconnect and restores full state', () => {
  const relay = new Relay(); const m = waitingMessage(); m.sessionId = 'phone-session'; m.phase = 'running'; m.remaining = 180;
  for (const type of ['PING', 'HELLO', 'STATE_SYNC', 'START', 'PAUSE', 'RESUME', 'NEXT_STEP', 'PREVIOUS_STEP', 'CANCEL', 'COMPLETE', 'VIDEO_READY', 'VIDEO_BUFFERING', 'VIDEO_FAILED']) {
    relay.send('family-demo', { ...m, type }, 1000);
  }
  assert.equal(relay.status('family-demo', true, 1001).connected, true);
  assert.equal(relay.status('family-demo', false, 8000).connected, false);
  relay.send('family-demo', m, 9000); assert.equal(relay.status('family-demo', true, 9001).message.remaining, 180);
  relay.disconnect('family-demo'); assert.equal(relay.status('family-demo', true, 9002).connected, false);
  for (const value of [null, {}, { ...m, type: 'UNKNOWN' }, { ...m, stepIndex: 99 }, { ...m, videoUrl: 'file:///private' }]) assert.equal(validMessage(value), false);
});
test('actual local HTTP endpoints: generation, relay, invalid input and video byte ranges (mock bytes)', async t => {
  const jobs = new ActivityJobs(await directory(t), { plan: async () => fallbackPlan(request), video: async () => 'https://mock.invalid/video', download: async () => fakeBytes }, 'mock-model', false);
  const server = await app(jobs); await new Promise(r => server.listen(0, '127.0.0.1', r)); t.after(() => new Promise(r => server.close(r)));
  const root = `http://127.0.0.1:${server.address().port}`;
  assert.equal((await fetch(root + '/health')).status, 200);
  const response = await fetch(root + '/activities/generate', { method: 'POST', body: JSON.stringify(request) }); assert.equal(response.status, 202);
  const job = await ready(jobs, jobs.get((await response.json()).id));
  assert.equal((await fetch(root + `/activities/${job.id}/status`)).status, 200);
  const video = await fetch(root + job.segments[0].videoUrl, { headers: { Range: 'bytes=0-7' } }); assert.equal(video.status, 206); assert.equal((await video.arrayBuffer()).byteLength, 8);
  assert.equal((await fetch(root + '/videos/' + 'a'.repeat(64))).status, 404);
  assert.equal((await fetch(root + '/activities/generate', { method: 'POST', body: '{}' })).status, 400);
  assert.equal((await fetch(root + '/tv/rooms/family-demo/phone', { method: 'POST', body: JSON.stringify(waitingMessage()) })).status, 200);
  const state = await (await fetch(root + '/tv/rooms/family-demo/state?receiver=true')).json(); assert.equal(state.connected, true);
});
