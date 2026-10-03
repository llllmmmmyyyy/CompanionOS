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
const { SessionBalanceEngine, BalanceRules, presetRules, validRules } = load('SessionBalanceEngine');
const { BehaviorData, ChildInteractionEvent, BehaviorInsightEngine, appendEvent, parseBehavior, sampleLabel } = load('BehaviorInsightEngine');
const { WorkState, planWork, settleEntry, endWork, parseWork, categoryMinutes, remainingWork, workActivity } = load('WorkSession');
let passed = 0;
function test(name, run) { run(); passed++; console.log('PASS ' + name); }
test('balanced default thirty-minute plan and invalid duration recovery', () => {
  const settings = new ParentSettings();
  const state = planWork(30, settings);
  assert.ok(['MOVE','LEARN','CREATE','CALM'].every(type => state.entries.some(entry => entry.category === type)));
  assert.ok(state.entries.filter(entry => entry.category === 'MOVE').reduce((n,e)=>n+e.minutes,0)>=6);
  assert.ok(state.entries.filter(entry => entry.category === 'LEARN').reduce((n,e)=>n+e.minutes,0)>=9);
  assert.equal(remainingWork(state), 30);
  assert.equal(planWork(NaN, settings).minutes, 30);
  settings.preferredActivityTypes = ['CALM'];
  assert.ok(planWork(30, settings).entries.some(entry => entry.category === 'MOVE')); // balance goals survive preferences
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
    const state = planWork(minutes, settings); assert.equal(state.entries.reduce((n,e)=>n+e.minutes,0), minutes);
    assert.equal(remainingWork(state), minutes); assert.ok(['MOVE','LEARN','CREATE','CALM'].every(type => state.entries.some(entry => entry.category === type)));
    assert.equal(parseWork(JSON.stringify(state)).phase, 'active');
  }
});
test('sequencing, skip, full summary and completion id protect duplicate submissions', () => {
  let state = planWork(15, new ParentSettings()); state = settleEntry(state, 'completed', false);
  state = settleEntry(state, 'skipped', false); state = settleEntry(state, 'completed', true); state = settleEntry(state, 'skipped', false);
  assert.equal(state.phase, 'completed'); assert.equal(state.index, 4); assert.equal(categoryMinutes(state, 'LEARN'), 5);
  assert.equal(categoryMinutes(state, 'CREATE'), 0); assert.equal(settleEntry(state, 'completed', false), state);
  const completion = new Completion(); completion.id = state.id + '-0'; completion.completedAt = Date.now();
  const data = addCompletion(new Snapshot(), completion); assert.equal(addCompletion(data, completion).total, 1);
});
test('end session preserves completed entries and marks only unfinished entries skipped', () => {
  const state = endWork(settleEntry(planWork(30, new ParentSettings()), 'completed', false));
  assert.equal(state.phase, 'ended'); assert.equal(state.entries[0].outcome, 'completed');
  assert.equal(state.entries.filter(entry => entry.outcome === 'skipped').length, state.entries.length-1);
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
test('all presets and durations protect category goals with bounded video alongside interactive learning', () => {
 for(const preset of ['Balanced','More Movement','More Learning','Low Energy','Custom']) for(const minutes of [15,30,45,60]) {
  const rules=presetRules(preset), slots=SessionBalanceEngine.plan(minutes,rules);
  assert.equal(slots.reduce((n,e)=>n+e.minutes,0),minutes);
  assert.ok(slots.some(e=>e.mode==='INTERACTIVE')); assert.ok(slots.filter(e=>e.mode==='VIDEO').reduce((n,e)=>n+e.minutes,0)<=minutes*rules.passive/100);
  assert.ok(slots.filter(e=>e.category==='MOVE').reduce((n,e)=>n+e.minutes,0)>=Math.ceil(minutes*rules.movement/100));
  assert.ok(slots.filter(e=>e.category==='LEARN').reduce((n,e)=>n+e.minutes,0)>=Math.ceil(minutes*rules.learning/100));
  assert.ok(['MOVE','LEARN','CREATE','CALM'].every(t=>slots.some(e=>e.category===t)));
 }
});
test('custom rules reject impossible and nonfinite inputs, recover safe plan', () => {
 for(const value of [-1,NaN,Infinity,100]) { const r=new BalanceRules();r.movement=value;assert.equal(validRules(r),false);assert.equal(SessionBalanceEngine.plan(15,r).reduce((n,e)=>n+e.minutes,0),15); }
 const r=new BalanceRules();r.movement=50;r.learning=50;assert.equal(validRules(r),false);
});
test('video budget rejects over-allocation without blocking offscreen fallback',()=>{
 const slots=SessionBalanceEngine.plan(30,new BalanceRules()); assert.equal(SessionBalanceEngine.videoAllowed(slots,3,30),true); assert.equal(SessionBalanceEngine.videoAllowed(slots,0,30),false);
 slots[2].mode='VIDEO'; slots[3].mode='VIDEO';assert.equal(SessionBalanceEngine.videoAllowed(slots,6,30),false);
});
function event(type,id,category='LEARN',mode='INTERACTIVE',game='CHOICE',time=Date.now()) {
 const e=new ChildInteractionEvent();e.eventId=id+':'+type;e.sessionId=id;e.activityId='activity';e.activityCategory=category;e.activityMode=mode;e.gameType=game;e.timestamp=time;e.eventType=type;return e;
}
test('event model deduplicates, persists choice/memory/movement and rejects corruption',()=>{
 let data=new BehaviorData();for(const type of ['ACTIVITY_STARTED','ANSWER_SELECTED','ANSWER_INCORRECT','RETRY','ANSWER_CORRECT','NEED_MORE_TIME','ACTIVITY_REPEATED','ACTIVITY_SKIPPED','FEEDBACK_SUBMITTED','PAUSE','RESUME']) data=appendEvent(data,event(type,'one'));
 assert.equal(appendEvent(data,event('RETRY','one')).events.length,data.events.length);
 data=appendEvent(data,event('ACTIVITY_STARTED','memory','LEARN','INTERACTIVE','MEMORY_SEQUENCE'));
 data=appendEvent(data,event('ACTIVITY_STARTED','move','MOVE','GUIDED_OFFSCREEN','MOVEMENT_CHALLENGE'));
 assert.equal(parseBehavior(JSON.stringify(data)).events.length,13);assert.equal(parseBehavior('{bad').events.length,0);
});
test('metrics, sample thresholds, feedback scoring and Demo exclusion are factual',()=>{
 let data=new BehaviorData();for(let i=0;i<6;i++){data=appendEvent(data,event('ACTIVITY_STARTED','a'+i));data=appendEvent(data,event(i<4?'ACTIVITY_COMPLETED':'ACTIVITY_SKIPPED','a'+i));}
 data=appendEvent(data,event('RETRY','a0'));data=appendEvent(data,event('ANSWER_SELECTED','a0'));data=appendEvent(data,event('ANSWER_CORRECT','a0'));
 const f=event('FEEDBACK_SUBMITTED','a0');f.feedback='Liked';f.difficultyFeedback='Just right';data=appendEvent(data,f);
 const demo=event('ACTIVITY_STARTED','demo');demo.demo=true;data=appendEvent(data,demo);
 const window=BehaviorInsightEngine.window(data,7,Date.now()),m=BehaviorInsightEngine.metrics(window);
 assert.equal(m.started,6);assert.equal(m.completed,4);assert.equal(m.skipped,2);assert.equal(m.retries,1);assert.equal(m.correct,1);
 assert.equal(BehaviorInsightEngine.score(window,'LEARN','CHOICE'),3);assert.match(sampleLabel(2),/Not enough/);assert.match(sampleLabel(4),/Early/);assert.match(sampleLabel(6),/Recent/);
 assert.ok(BehaviorInsightEngine.observations(window).some(t=>t.includes('Why')));
});
test('today/seven/thirty day windows and insufficient comparisons are safe',()=>{
 const now=Date.now(),data=new BehaviorData();data.events=[event('ACTIVITY_STARTED','now','LEARN','INTERACTIVE','CHOICE',now),event('ACTIVITY_STARTED','old','LEARN','INTERACTIVE','CHOICE',now-8*86400000)];
 assert.equal(BehaviorInsightEngine.window(data,7,now).length,1);assert.equal(BehaviorInsightEngine.window(data,30,now).length,2);
 assert.equal(BehaviorInsightEngine.window(data,1,now).length,1);assert.match(BehaviorInsightEngine.observations([])[0],/Not enough/);
});
test('unknown old completion fields survive; corrupt optional detail does not erase history',()=>{
 const r=new Completion();r.id='old';r.completedAt=Date.now();r.title='Old activity';let data=addCompletion(new Snapshot(),r);delete data.settings.balanceRules;
 const restored=restoreSnapshot(JSON.stringify(data));assert.equal(restored.total,1);assert.equal(restored.records[0].questionsAttempted,undefined);
 r.questionsAttempted=-1;r.actualDuration='wrong';r.activityMode='bad';const sanitized=restoreSnapshot(JSON.stringify(addCompletion(new Snapshot(),r)));
 assert.equal(sanitized.total,1);assert.equal(sanitized.records[0].questionsAttempted,undefined);assert.equal(sanitized.records[0].activityMode,undefined);
});
test('empty, one-start, all-skipped, video-only and interactive-only metrics avoid fabricated rates',()=>{
 assert.equal(BehaviorInsightEngine.rate(0,0),'Not enough data yet');
 for(const mode of ['VIDEO','INTERACTIVE']){const events=[];for(let i=0;i<3;i++){events.push(event('ACTIVITY_STARTED',mode+i,'LEARN',mode));events.push(event('ACTIVITY_SKIPPED',mode+i,'LEARN',mode))}const m=BehaviorInsightEngine.metrics(events);assert.equal(m.completed,0);assert.equal(m.skipped,3);assert.equal(BehaviorInsightEngine.guidedMinutes(events,''),0);assert.ok(BehaviorInsightEngine.formats(events).every(line=>!line.includes('NaN')));assert.ok(BehaviorInsightEngine.observations(events).some(line=>line.includes('Not enough data to compare')));}
 const one=[event('ACTIVITY_STARTED','one')];assert.match(BehaviorInsightEngine.metrics(one).sample,/Not enough/);assert.equal(BehaviorInsightEngine.metrics([event('ACTIVITY_COMPLETED','orphan')]).completed,0);
});
test('preference ranking and explicit difficulty feedback adapt games without changing protected categories',()=>{
 const events=[];for(let i=0;i<3;i++){events.push(event('ACTIVITY_STARTED','m'+i,'LEARN','INTERACTIVE','MEMORY_SEQUENCE'));const f=event('FEEDBACK_SUBMITTED','m'+i,'LEARN','INTERACTIVE','MEMORY_SEQUENCE');f.feedback='Liked';f.difficultyFeedback='Too hard';events.push(f);}
 assert.equal(BehaviorInsightEngine.recommendGame(events,'CHOICE'),'MEMORY_SEQUENCE');assert.equal(BehaviorInsightEngine.recommendDifficulty(events,'Standard'),'Gentle');assert.equal(BehaviorInsightEngine.recommendDifficulty(events.slice(0,4),'Standard'),'Standard');
 assert.ok(SessionBalanceEngine.plan(30,new BalanceRules()).some(slot=>slot.category==='MOVE'));
});
test('guided planned minutes and weekly trends require matching completion and exclude Demo',()=>{
 const data=new BehaviorData(),now=Date.now();const start=event('ACTIVITY_STARTED','move','MOVE','GUIDED_OFFSCREEN','MOVEMENT_CHALLENGE',now);start.plannedMinutes=3;data.events=[start,event('MOVEMENT_CONFIRMED','move','MOVE','GUIDED_OFFSCREEN','MOVEMENT_CHALLENGE',now),event('ACTIVITY_COMPLETED','move','MOVE','GUIDED_OFFSCREEN','MOVEMENT_CHALLENGE',now)];
 assert.equal(BehaviorInsightEngine.guidedMinutes(data.events,'MOVE'),3);assert.equal(BehaviorInsightEngine.weekly(data,now).length,7);assert.match(BehaviorInsightEngine.weekly(data,now).at(-1),/MOVE 3 min/);start.demo=true;data.events.forEach(e=>e.demo=true);assert.equal(BehaviorInsightEngine.guidedMinutes(BehaviorInsightEngine.window(data,7,now),'MOVE'),0);
});
console.log(`${passed} parent work-session host checks passed`);
