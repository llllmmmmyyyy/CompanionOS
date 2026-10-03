// Executes the actual pure ArkTS model through the TypeScript compiler shipped with the SDK.
// This is a host logic check, not an ArkUI/device test.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const compilerPath = process.argv[2];
if (!compilerPath) throw new Error('Usage: node scripts/test-domain.cjs <SDK typescript.js>');
const ts = require(path.resolve(compilerPath));
const source = fs.readFileSync(path.join(__dirname, '../entry/src/main/ets/model/Companion.ets'), 'utf8');
const js = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021 } }).outputText;
const box = { exports: {}, Date, Math, Number, JSON, Array };
vm.runInNewContext(js, box);
const { Snapshot, ParentSettings, Completion, ActivitySession, restoreSnapshot, addCompletion, countToday, validSettings, validEndpoint } = box.exports;
let passed = 0;
function test(name, run) { run(); passed++; console.log(`PASS ${name}`); }
const now = new Date(2026, 9, 3, 12).getTime();
function completion(id, time = now) { const r = new Completion(); r.id = id; r.title = 'Penguin Walk'; r.activityId = 'penguin'; r.completedAt = time; return r; }
test('settings and records survive serialization', () => {
  const data = addCompletion(new Snapshot(), completion('one'));
  data.settings.age = '6–8'; data.settings.minutes = 10; data.settings.interests = ['Nature'];
  const restored = restoreSnapshot(JSON.stringify(data));
  assert.equal(restored.settings.minutes, 10); assert.equal(restored.settings.age, '6–8');
  assert.equal(restored.records[0].id, 'one'); assert.equal(restored.total, 1);
});
test('missing, malformed, null and invalid structures recover', () => {
  for (const value of ['', '{broken', 'null', '{}', '[]', '{"version":1}']) assert.equal(restoreSnapshot(value).total, 0);
});
test('invalid settings and records recover', () => {
  const data = addCompletion(new Snapshot(), completion('one'));
  data.settings.minutes = 999; assert.equal(restoreSnapshot(JSON.stringify(data)).total, 0);
  data.settings.minutes = 3; data.records[0].completedAt = -1; assert.equal(restoreSnapshot(JSON.stringify(data)).total, 0);
});
test('daily count increments and resets on another date', () => {
  let data = addCompletion(new Snapshot(), completion('one'));
  data = addCompletion(data, completion('two'));
  assert.equal(countToday(data, now), 2);
  const tomorrow = new Date(2026, 9, 4, 12).getTime();
  assert.equal(countToday(data, tomorrow), 0);
  data = addCompletion(data, completion('three', tomorrow));
  assert.equal(countToday(data, tomorrow), 1); assert.equal(data.total, 3);
});
test('duplicate completion id cannot increment twice', () => {
  const record = completion('same'); const data = addCompletion(new Snapshot(), record);
  assert.equal(addCompletion(data, record), data); assert.equal(data.total, 1);
});
test('bounded history retains independent total and daily count', () => {
  let data = new Snapshot();
  for (let i = 0; i < 35; i++) data = addCompletion(data, completion(`id-${i}`));
  assert.equal(data.records.length, 20); assert.equal(data.total, 35); assert.equal(countToday(data, now), 35);
  assert.ok(JSON.stringify(data).length < 8192);
});
test('normal durations use 3, 5 and 10 real minutes', () => {
  for (const minutes of [3, 5, 10]) {
    const s = new ActivitySession(); s.start(now, minutes, false);
    assert.equal(s.remaining(now), minutes * 60); assert.equal(s.tick(now + minutes * 60000 - 1, true), false);
    assert.equal(s.tick(now + minutes * 60000, true), true); assert.equal(s.phase, 'ready');
  }
});
test('demo expires after ten seconds and notification fires once', () => {
  const s = new ActivitySession(); s.start(now, 3, true);
  assert.equal(s.remaining(now), 10); assert.equal(s.tick(now + 10000, true), true);
  assert.equal(s.tick(now + 11000, true), false);
});
test('cancel cannot become ready or notify', () => {
  const s = new ActivitySession(); s.start(now, 3, true); s.cancel();
  assert.equal(s.tick(now + 20000, true), false); assert.equal(s.phase, 'cancelled');
});
test('background expiry resumes without a notification', () => {
  const s = new ActivitySession(); s.start(now, 3, true);
  assert.equal(s.tick(now + 10000, false), false); s.resume(now + 20000);
  assert.equal(s.phase, 'ready'); assert.equal(s.tick(now + 20000, true), false);
});
test('resume before deadline preserves remaining time', () => {
  const s = new ActivitySession(); s.start(now, 3, false); s.resume(now + 60000);
  assert.equal(s.phase, 'running'); assert.equal(s.remaining(now + 60000), 120);
});
test('settings reject unsupported ages, durations and interests', () => {
  const s = new ParentSettings(); assert.equal(validSettings(s), true);
  s.interests = []; assert.equal(validSettings(s), false);
  s.interests = ['Dangerous']; assert.equal(validSettings(s), false);
});
test('AI endpoint permits HTTPS and excludes embedded credentials or keys', () => {
  assert.equal(validEndpoint('https://example.com/recommend'), true);
  for (const url of ['http://example.com', 'https://user:pass@example.com', 'https://example.com?key=secret']) assert.equal(validEndpoint(url), false);
});
console.log(`${passed} host logic checks passed; device behavior is not verified.`);
