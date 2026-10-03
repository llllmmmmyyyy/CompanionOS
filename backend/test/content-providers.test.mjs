import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { HuaweiMaaSClient, HuaweiMaaSActivityProvider, HuaweiMaaSVideoProvider, GeminiActivityProvider, GeminiVideoProvider, ProviderAdapter } from '../dist/content-providers.js';
import { GoogleProvider } from '../dist/provider.js';
import { fallbackPlan, validateRequest, validatePlan } from '../dist/domain.js';
import { ActivityJobs } from '../dist/activities.js';
import { app } from '../dist/server.js';
import { Relay, waitingMessage, validMessage } from '../dist/protocol.js';
const request = { childAge: '6–8', interests: ['Movement'], activityCategory: 'MOVE', educationalGoal: 'Count gently', durationMinutes: 3 };
const json = value => new Response(JSON.stringify(value), { headers: { 'content-type': 'application/json' } });
test('existing Gemini client is reused by activity/video adapters (mock HTTP)', async () => {
  const urls = []; const google = new GoogleProvider('test-only', 'gemini-test', 'veo-test', async (url) => {
    urls.push(String(url));
    if (String(url).includes('generateContent')) return json({ candidates: [{ content: { parts: [{ text: JSON.stringify(fallbackPlan(request)) }] } }] });
    if (String(url).includes('predictLongRunning')) return json({ name: 'models/veo-test/operations/test' });
    return json({ done: true, response: { generateVideoResponse: { generatedSamples: [{ video: { uri: 'https://generativelanguage.googleapis.com/file' } }] } } });
  }, async () => {});
  const adapter = new ProviderAdapter(new GeminiActivityProvider(google), new GeminiVideoProvider(google));
  assert.equal((await adapter.plan(request)).title, 'Dino Movement Adventure');
  assert.match(await adapter.video('safe illustration'), /^https:/); assert.equal(urls.length, 3);
});
test('Huawei structured chat and Wan text-to-video task use documented REST shapes (mock HTTP)', async () => {
  const calls = [];
  const client = new HuaweiMaaSClient('test-only', async (url, options) => {
    calls.push({ url: String(url), options });
    if (String(url).endsWith('/chat/completions')) return json({ choices: [{ message: { content: JSON.stringify(fallbackPlan(request)) } }] });
    if (options.method === 'POST') return json({ task_id: 'task-123' });
    return json({ status: 'succeeded', content: { result_url: 'https://storage.invalid/clip.mp4' } });
  });
  const activity = new HuaweiMaaSActivityProvider(client, 'enabled-model');
  assert.equal((await activity.generateActivity(request)).steps.length, 3);
  const video = new HuaweiMaaSVideoProvider(client, 'Wan2.2-T2V-A14B', async () => {});
  assert.equal((await video.generateVideo('safe calm cloud')).uri, 'https://storage.invalid/clip.mp4');
  assert.match(calls[0].url, /v2\/chat\/completions$/);
  const body = JSON.parse(calls[1].options.body); assert.ok(body.input.prompt.startsWith('safe calm cloud')); assert.match(body.input.prompt, /No violence/);
  assert.equal(body.parameters.size, '1280x720'); assert.equal(body.parameters.duration, 5);
  await assert.rejects(client.download('http://127.0.0.1/secret'));
  await assert.rejects(new HuaweiMaaSActivityProvider(client, '').generateActivity(request));
});
test('Huawei errors/invalid task and unsafe plans fail; no generated-success claim', async () => {
  const bad = new HuaweiMaaSClient('test-only', async () => json({ choices: [{ message: { content: '{}' } }] }));
  assert.throws(() => validatePlan({}, request));
  await assert.rejects(new HuaweiMaaSVideoProvider(bad, 'model', async () => {}).generateVideo('safe'));
  assert.throws(() => validateRequest({ ...request, provider: 'FAKE' }));
});
test('actual HTTP provider selection, missing-key fallbacks, normalized result and imported MP4/ranges', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'companion-content-'));
  const server = await app(new ActivityJobs(directory), new Relay(), new ActivityJobs(directory, undefined, 'HUAWEI:wan', true, 'HUAWEI'));
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    for (const provider of ['GEMINI', 'HUAWEI']) {
      const initial = await (await fetch(base + '/activities/generate', { method: 'POST', body: JSON.stringify({ ...request, provider }) })).json();
      const job = await (await fetch(`${base}/activities/${initial.id}/status`)).json();
      assert.equal(job.source, 'fallback'); assert.equal(job.provider, provider);
      assert.ok(job.plan.steps[0].videoPrompt); assert.equal(job.plan.steps[0].videoUrl, '');
    }
    const bytes = Buffer.alloc(24); bytes.write('ftyp', 4);
    const uploaded = await (await fetch(base + '/media/import', { method: 'POST', headers: { 'Content-Type': 'video/mp4' }, body: bytes })).json();
    assert.equal(uploaded.source, 'USER_VIDEO'); assert.match(uploaded.videoUrl, /^\/videos\/[a-f0-9]{64}$/);
    const media = await fetch(base + uploaded.videoUrl, { headers: { Range: 'bytes=0-11' } });
    assert.equal(media.status, 206); assert.equal((await media.arrayBuffer()).byteLength, 12);
    assert.equal((await fetch(base + '/media/import', { method: 'POST', headers: { 'Content-Type': 'video/mp4' }, body: 'bad' })).status, 400);
  } finally { await new Promise(resolve => server.close(resolve)); await rm(directory, { recursive: true, force: true }); }
});
test('all content types share validated TV messages; private paths and mismatched URIs rejected', () => {
  for (const sourceType of ['GEMINI_AI', 'HUAWEI_AI', 'BUILT_IN', 'USER_VIDEO']) {
    for (const type of ['START', 'PAUSE', 'RESUME', 'NEXT_STEP', 'PREVIOUS_STEP', 'CANCEL', 'COMPLETE']) {
      const message = { ...waitingMessage(), type, content: { sourceType, uri: '', title: 'Test', activityId: '' } };
      assert.equal(validMessage(message), true);
      assert.equal(validMessage({ ...message, content: { ...message.content, uri: 'file:///private' } }), false);
    }
  }
});
