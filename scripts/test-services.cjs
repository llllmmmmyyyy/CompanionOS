// Host integration tests with mocked HarmonyOS services. No device/real AI verification.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
if (!process.argv[2]) throw new Error('Supply the SDK typescript.js path');
const ts = require(path.resolve(process.argv[2]));
const root = path.join(__dirname, '../entry/src/main/ets');
function load(file, mocks = {}, extra = {}) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  const js = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021 } }).outputText;
  const box = { exports: {}, require: id => { if (!(id in mocks)) throw new Error(`Unexpected dependency ${id}`); return mocks[id]; },
    Date, JSON, Number, Math, Array, setTimeout, clearTimeout, ...extra };
  vm.runInNewContext(js, box); return box.exports;
}
const model = load('model/Companion.ets');
let passed = 0;
async function test(name, run) { await run(); passed++; console.log(`PASS ${name}`); }
async function main() {
  let networkMode = 'success', destroyed = 0, calls = 0, timeoutMs = 0;
  const settings = new model.ParentSettings(); settings.aiEndpoint = 'https://example.com/recommend';
  const payload = { source: 'ai', activityId: 'penguin', ageGroup: '4–5', minutes: 3, adultRequired: true };
  const network = { http: { RequestMethod: { POST: 'POST' }, HttpDataType: { STRING: 'STRING' }, createHttp: () => ({
    request: async () => {
      calls++;
      if (networkMode === 'failure') throw new Error('network failed');
      if (networkMode === 'timeout') return new Promise(() => {});
      return { responseCode: networkMode === 'status' ? 503 : 200,
        result: networkMode === 'invalid' ? '{bad json' : JSON.stringify(payload) };
    }, destroy: () => { destroyed++; }
  }) } };
  const ai = load('services/AiService.ets', { '@kit.NetworkKit': network, '../model/Companion': model }, {
    setTimeout: (fn, ms) => { timeoutMs = ms; return setTimeout(fn, networkMode === 'timeout' ? 0 : ms); }
  });
  await test('unconfigured AI returns honest offline recommendation without a request', async () => {
    const s = new model.ParentSettings(); const result = await ai.AiService.recommend(s);
    assert.equal(result.source, 'offline'); assert.equal(calls, 0);
  });
  await test('validated service recommendation accepted', async () => {
    const result = await ai.AiService.recommend(settings); assert.equal(result.source, 'ai'); assert.equal(result.activityId, 'penguin');
  });
  await test('AI rejects wrong age, time, adult flag, source, interest and unknown activity', async () => {
    for (const change of [{ ageGroup: '6–8' }, { minutes: 10 }, { adultRequired: false }, { source: 'preset' }, { activityId: 'sounds' }, { activityId: 'knife' }]) {
      assert.equal(ai.validateRecommendation(JSON.stringify({ ...payload, ...change }), settings), '');
    }
  });
  await test('network error, bad status and malformed response fall back offline', async () => {
    for (const mode of ['failure', 'status', 'invalid']) {
      networkMode = mode; const result = await ai.AiService.recommend(settings); assert.equal(result.source, 'offline');
    }
  });
  await test('ten-second timeout falls back and destroys the request', async () => {
    networkMode = 'timeout'; const before = destroyed;
    const result = await ai.AiService.recommend(settings);
    assert.equal(timeoutMs, 10000); assert.equal(result.source, 'offline'); assert.equal(destroyed, before + 1);
  });
  await test('HTTP initialization failure still returns offline fallback', async () => {
    const broken = load('services/AiService.ets', { '../model/Companion': model,
      '@kit.NetworkKit': { http: { createHttp: () => { throw new Error('not supported'); } } } });
    assert.equal((await broken.AiService.recommend(settings)).source, 'offline');
  });
  let enabled = false, denied = false, publishFailure = false, published = 0;
  const notifications = load('services/Notifications.ets', { '@kit.NotificationKit': { notificationManager: {
    ContentType: { NOTIFICATION_CONTENT_BASIC_TEXT: 0 },
    isNotificationEnabled: async () => enabled,
    requestEnableNotification: async () => { if (denied) throw new Error('denied'); enabled = true; },
    publish: async () => { if (publishFailure) throw new Error('unavailable'); published++; }
  } } });
  await test('notification permission denial is handled', async () => {
    denied = true; assert.match(await notifications.Notifications.enable({}), /denied or unavailable/);
    assert.match(await notifications.Notifications.publish('Penguin Walk', () => true), /disabled/); assert.equal(published, 0);
  });
  await test('enabled foreground notification submits exactly one request', async () => {
    denied = false; await notifications.Notifications.enable({});
    assert.match(await notifications.Notifications.publish('Penguin Walk', () => true), /submitted/); assert.equal(published, 1);
  });
  await test('notification failure does not throw; stale session does not publish', async () => {
    publishFailure = true; assert.match(await notifications.Notifications.publish('Penguin Walk', () => true), /could not be sent/);
    publishFailure = false; assert.equal(await notifications.Notifications.publish('Penguin Walk', () => false), ''); assert.equal(published, 1);
  });
  const values = new Map(); let failFlush = false;
  const prefs = { MAX_VALUE_LENGTH: 8192, getPreferencesSync: () => ({
    getSync: (key, fallback) => values.has(key) ? values.get(key) : fallback,
    putSync: (key, value) => values.set(key, value),
    flush: async () => { if (failFlush) throw new Error('disk unavailable'); }
  }) };
  const { LocalStore } = load('services/LocalStore.ets', { '@kit.ArkData': { preferences: prefs }, '../model/Companion': model });
  await test('Preferences save and fresh store restore settings and records', async () => {
    const store = new LocalStore({}); const data = new model.Snapshot(); data.settings.minutes = 5;
    const r = new model.Completion(); r.id = 'one'; r.title = 'Penguin Walk'; r.completedAt = Date.now();
    await store.save(model.addCompletion(data, r));
    const restored = new LocalStore({}).load(); assert.equal(restored.settings.minutes, 5); assert.equal(restored.records.length, 1);
  });
  await test('corrupt Preferences data recovers safely', async () => {
    values.set('mvp', '{broken'); const store = new LocalStore({}); assert.equal(store.load().total, 0); assert.equal(store.recovered, true);
  });
  await test('previous homepage records and larger daily count migrate without loss', async () => {
    values.set('mvp', '');
    values.set('records', JSON.stringify([{ id: 'legacy-1', title: 'Penguin Walk', animal: 'Penguin', completedAt: Date.now() }]));
    values.set('countDay', model.dayKey(Date.now())); values.set('todayCount', 5);
    const data = new LocalStore({}).load();
    assert.equal(data.records[0].id, 'legacy-1'); assert.equal(data.todayCount, 5); assert.equal(data.total, 5);
  });
  await test('failed Preferences flush is reported to caller for retry', async () => {
    failFlush = true; await assert.rejects(new LocalStore({}).save(new model.Snapshot()));
  });
  console.log(`${passed} mocked-service checks passed; actual platform behavior remains unverified.`);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
