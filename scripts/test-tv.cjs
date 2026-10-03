// Host tests of actual ArkTS logic; no real TV, Gemini or video provider is used.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const ts = require(path.resolve(process.argv[2]));
const cache = new Map();
function load(relative) {
  const file = path.resolve(__dirname, '../entry/src/main/ets', relative + '.ets');
  if (cache.has(file)) return cache.get(file);
  const box = { exports: {}, Date, Math, Number, JSON, Array, Promise, Error,
    require: name => name === '@companion/protocol' ? require('./load-protocol.cjs')(ts) : load(path.relative(path.resolve(__dirname, '../entry/src/main/ets'), path.resolve(path.dirname(file), name))) };
  vm.runInNewContext(ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021 }
  }).outputText, box);
  cache.set(file, box.exports); return box.exports;
}
const { ActivitySession, ACTIVITIES, Snapshot, Completion, addCompletion, restoreSnapshot } = load('model/Companion');
const { LocalDemoTvTransport, HarmonyDistributedTvTransport, TvFrame } = load('services/TvSessionTransport');
const { MockAiActivityService, ActivityPlanRequest, TV_CATEGORIES, activityFromPlan } = load('services/AiActivityService');
let passed = 0;
async function test(name, run) { await run(); passed++; console.log(`PASS ${name}`); }
(async () => {
  await test('three-minute pause preserves milliseconds and background does not resume paused activity', () => {
    const session = new ActivitySession(); session.start(1000, 3, false); session.pause(2500);
    assert.equal(session.remaining(999999), 179); session.resume(999999); assert.equal(session.phase, 'paused');
    assert.equal(session.tick(999999, true), false); session.continueActivity(999999);
    assert.equal(session.remaining(999999), 179); assert.equal(session.tick(1178499, true), true);
    assert.equal(session.tick(1178500, true), false);
  });
  await test('expired timer cannot be paused and paused cancellation cannot be resumed', () => {
    const session = new ActivitySession(); session.start(0, 3, true); session.pause(10000);
    assert.equal(session.tick(10000, true), true);
    session.start(20000, 3, false); session.pause(21000); session.cancel(); session.continueActivity(22000);
    assert.equal(session.phase, 'cancelled');
  });
  await test('local receiver mirrors start pause resume step cancel completion and disconnect', async () => {
    const events = []; const frames = [];
    const transport = new LocalDemoTvTransport((event, frame) => { events.push(event); frames.push(frame); });
    await transport.connect(); const frame = new TvFrame(); frame.sessionId = 'phone-owned'; frame.remaining = 180;
    transport.startActivity(ACTIVITIES[0], frame); frame.phase = 'paused'; transport.pauseActivity(frame);
    transport.resumeActivity(frame); transport.nextStep(frame); transport.cancelActivity(frame);
    frame.phase = 'completed'; transport.synchronize(frame); transport.disconnect();
    const length = events.length; transport.synchronize(frame); assert.equal(events.length, length);
    assert.equal(events.join(','), 'connected,activityStarted,activityPaused,activityResumed,stepChanged,activityCancelled,activityCompleted,disconnected');
    assert.equal(frames[1].sessionId, 'phone-owned');
  });
  await test('real transport adapter delegates to injected channel without claiming a connection', async () => {
    const sent = []; let closed = false;
    const transport = new HarmonyDistributedTvTransport({ connect: async () => {}, close: () => { closed = true; }, send: (event, frame) => sent.push(event) });
    await transport.connect(); const frame = new TvFrame(); transport.startActivity(ACTIVITIES[0], frame);
    transport.pauseActivity(frame); transport.resumeActivity(frame); transport.cancelActivity(frame); transport.nextStep(frame);
    frame.phase = 'completed'; transport.synchronize(frame); transport.disconnect();
    assert.equal(sent.join(','), 'activityStarted,activityPaused,activityResumed,activityCancelled,stepChanged,activityCompleted'); assert.equal(closed, true);
  });
  await test('all four mock categories are deterministic, duration matched and video-free', async () => {
    for (const category of TV_CATEGORIES) for (const duration of [3, 5, 10]) {
      const request = new ActivityPlanRequest(); request.category = category; request.durationMinutes = duration;
      const service = new MockAiActivityService(); const plan = await service.generateActivityPlan(request);
      assert.equal(JSON.stringify(plan), JSON.stringify(await service.generateActivityPlan(request)));
      const activity = activityFromPlan(plan, request); assert.equal(activity.generatedByAI, false);
      assert.equal(activity.category, category); assert.equal(activity.activitySteps.reduce((n, step) => n + step.durationSeconds, 0), duration * 60);
      assert.equal(activity.activitySteps.every(step => !step.videoUrl && step.fallbackVisual), true);
    }
  });
  await test('unsupported mock requests and invalid future output fail safely', async () => {
    const request = new ActivityPlanRequest(); request.category = 'UNSAFE';
    await assert.rejects(new MockAiActivityService().generateActivityPlan(request));
    request.category = 'MOVE'; const plan = await new MockAiActivityService().generateActivityPlan(request);
    plan.steps[0].videoUrl = 'http://unsafe'; assert.throws(() => activityFromPlan(plan, request));
  });
  await test('TV record duplicate protection and old records coexist after restart serialization', () => {
    const old = new Completion(); old.id = 'old'; old.activityId = 'penguin'; old.title = 'Penguin Walk'; old.completedAt = 1000;
    let data = addCompletion(new Snapshot(), old); const record = new Completion(); record.id = 'tv';
    record.activityId = 'tv-move'; record.title = 'Dino Movement Adventure'; record.completedAt = 2000;
    data = addCompletion(data, record); data = addCompletion(data, record);
    const restored = restoreSnapshot(JSON.stringify(data)); assert.equal(restored.total, 2);
    assert.equal(restored.records[1].activityId, 'penguin');
  });
  console.log(`${passed} TV/AI host checks passed`);
})().catch(error => { console.error(error); process.exitCode = 1; });
