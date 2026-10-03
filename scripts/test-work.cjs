// Runs actual ArkTS models on the host; UI/device evidence is recorded separately.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const ts = require(path.resolve(process.argv[2]));
const cache = new Map();
function load(name) {
  if (cache.has(name)) return cache.get(name);
  const box = { exports: {}, Date, Math, Number, JSON, Array,
    require: reference => reference === '@companion/protocol' ? require('./load-protocol.cjs')(ts) : load(reference.split('/').at(-1)) };
  const raw = fs.readFileSync(path.join(__dirname, '../entry/src/main/ets/model', name + '.ets'), 'utf8');
  vm.runInNewContext(ts.transpileModule(raw, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021 } }).outputText, box);
  cache.set(name, box.exports); return box.exports;
}
const { ParentSettings, Snapshot, restoreSnapshot, validSettings, addCompletion, Completion } = load('Companion');
const { WorkState, planWork, settleEntry, endWork, parseWork, categoryMinutes, remainingWork, workActivity } = load('WorkSession');
let passed = 0;
function test(name, run) { run(); passed++; console.log('PASS ' + name); }
test('balanced default thirty-minute plan and invalid duration recovery', () => {
  const settings = new ParentSettings();
  const state = planWork(30, settings);
  assert.equal(state.entries.map(entry => entry.category).join(','), 'MOVE,LEARN,LEARN,CREATE,CREATE,CALM');
  assert.equal(remainingWork(state), 30);
  assert.equal(planWork(NaN, settings).minutes, 30);
  settings.preferredActivityTypes = ['CALM'];
  assert.ok(planWork(30, settings).entries.every(entry => entry.category === 'CALM'));
});
test('legacy profile migrates without dropping history; expanded profile survives restart', () => {
  const old = new Snapshot(); for (const field of ['preferredActivityTypes', 'sessionDuration', 'activityDifficulty', 'indoorOnly', 'noJumping', 'lowIntensity']) delete old.settings[field];
  const restored = restoreSnapshot(JSON.stringify(old)); assert.equal(restored.settings.sessionDuration, 30); assert.equal(restored.settings.noJumping, true);
  restored.settings.sessionDuration = 45; restored.settings.preferredActivityTypes = ['CALM', 'CREATE']; restored.settings.activityDifficulty = 'Standard';
  restored.settings.lowIntensity = false;
  const again = restoreSnapshot(JSON.stringify(restored)); assert.equal(again.settings.sessionDuration, 45); assert.equal(again.settings.lowIntensity, false);
  assert.equal(again.settings.preferredActivityTypes.join(','), 'CALM,CREATE');
  again.settings.preferredActivityTypes = []; assert.equal(validSettings(again.settings), false);
});
test('15/30/45/60 minute schedules respect preferred types and bounded short activities', () => {
  const settings = new ParentSettings(); settings.preferredActivityTypes = ['LEARN', 'CALM'];
  for (const minutes of [15, 30, 45, 60]) {
    const state = planWork(minutes, settings); assert.equal(state.entries.length, minutes / 5);
    assert.equal(remainingWork(state), minutes); assert.ok(state.entries.every(entry => ['LEARN', 'CALM'].includes(entry.category)));
    assert.equal(parseWork(JSON.stringify(state)).phase, 'active');
  }
});
test('sequencing, skip, full summary and completion id protect duplicate submissions', () => {
  let state = planWork(15, new ParentSettings()); state = settleEntry(state, 'completed', false);
  state = settleEntry(state, 'skipped', false); state = settleEntry(state, 'completed', true);
  assert.equal(state.phase, 'completed'); assert.equal(state.index, 3); assert.equal(categoryMinutes(state, 'MOVE'), 5);
  assert.equal(categoryMinutes(state, 'CREATE'), 0); assert.equal(settleEntry(state, 'completed', false), state);
  const completion = new Completion(); completion.id = state.id + '-0'; completion.completedAt = Date.now();
  const data = addCompletion(new Snapshot(), completion); assert.equal(addCompletion(data, completion).total, 1);
});
test('end session preserves completed entries and marks only unfinished entries skipped', () => {
  const state = endWork(settleEntry(planWork(30, new ParentSettings()), 'completed', false));
  assert.equal(state.phase, 'ended'); assert.equal(state.entries[0].outcome, 'completed');
  assert.equal(state.entries.filter(entry => entry.outcome === 'skipped').length, 5);
});
test('pause/restart checkpoint keeps remaining seconds and rejects corrupt data', () => {
  const state = planWork(15, new ParentSettings()); state.remaining = 120; state.activityPhase = 'paused'; state.step = 1; state.activityDemo = true;
  const restored = parseWork(JSON.stringify(state)); assert.equal(restored.remaining, 120); assert.equal(restored.step, 1); assert.equal(restored.activityDemo, true);
  assert.equal(remainingWork(restored), 12);
  for (const raw of ['null', '{bad', JSON.stringify({ ...state, remaining: -1 }), JSON.stringify({ ...state, index: 99 }), JSON.stringify({ ...state, entries: [{ category: 'OUTDOOR' }] })]) assert.equal(parseWork(raw).phase, 'idle');
});
test('all four safe templates include structured steps and age/difficulty changes', () => {
  const settings = new ParentSettings();
  for (const type of ['MOVE', 'LEARN', 'CREATE', 'CALM']) {
    const activity = workActivity(type, settings); assert.equal(activity.category, type); assert.equal(activity.activitySteps.length, 3);
    assert.equal(activity.contentSource, 'BUILT_IN');
  }
  settings.age = '6–8'; assert.match(workActivity('LEARN', settings).steps[1], /pairs/);
  settings.activityDifficulty = 'Standard'; assert.match(workActivity('CREATE', settings).steps[2], /second creature/);
});
console.log(`${passed} parent work-session host checks passed`);
