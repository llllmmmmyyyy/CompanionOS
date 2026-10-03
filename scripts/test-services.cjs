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
const model = load('model/Companion.ets', { '@companion/protocol': require('./load-protocol.cjs')(ts), './SessionBalanceEngine': load('model/SessionBalanceEngine.ets') });
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
    values.set('mvp', ''); values.delete('active');
    values.set('records', JSON.stringify([{ id: 'legacy-1', title: 'Penguin Walk', animal: 'Penguin', completedAt: Date.now() }]));
    values.set('countDay', model.dayKey(Date.now())); values.set('todayCount', 5);
    const data = new LocalStore({}).load();
    assert.equal(data.records[0].id, 'legacy-1'); assert.equal(data.todayCount, 5); assert.equal(data.total, 5);
  });
  await test('failed Preferences flush is reported to caller for retry', async () => {
    failFlush = true; await assert.rejects(new LocalStore({}).save(new model.Snapshot()));
  });
  await test('expanded twenty-record journal exceeds one Preferences value and still round-trips', async () => {
    failFlush = false; values.clear(); let data = new model.Snapshot();
    for(let i=0;i<20;i++){const r=new model.Completion();r.id='full-'+i;r.title='Penguin Walk';r.completedAt=Date.now();r.activityMode='GUIDED_OFFSCREEN';r.category='MOVE';r.actualDuration=100;r.plannedDuration=5;r.gameType='MOVEMENT_CHALLENGE';r.startedAt=Date.now();r.childFeedback='Liked';r.movementConfirmed=true;r.completed=true;r.skipped=false;r.sessionId=r.id;data=model.addCompletion(data,r);}
    await new LocalStore({}).save(data); assert.equal(new LocalStore({}).load().records.length,20);
    for(const value of values.values()) if(typeof value==='string') assert.ok(value.length<=8192);
  });
  const behavior = load('model/BehaviorInsightEngine.ets', {'./Companion': model});
  const {BehaviorStore} = load('services/BehaviorStore.ets', {'@kit.ArkData': {preferences: {...prefs, getPreferencesSync: () => ({getSync: (key,fallback)=>values.has(key)?values.get(key):fallback, putSync:(key,value)=>{if(typeof value==='string'&&value.length>8192)throw Error('value too long');values.set(key,value)},flushSync:()=>{if(failFlush)throw Error('disk')}})}}, '../model/BehaviorInsightEngine': behavior});
  await test('large local event history uses bounded chunks and fresh-store recovery', async()=>{
    values.clear(); const data=new behavior.BehaviorData();for(let i=0;i<100;i++){const e=new behavior.ChildInteractionEvent();e.eventId='event-'+i;e.sessionId='session-'+i;e.activityId='learn';e.activityCategory='LEARN';e.timestamp=Date.now();e.eventType='ACTIVITY_STARTED';data.events.push(e)}
    new BehaviorStore({}).save(data);assert.equal(new BehaviorStore({}).load().events.length,100);new BehaviorStore({}).save(new behavior.BehaviorData());assert.equal(new BehaviorStore({}).load().events.length,0);
    failFlush=true;assert.throws(()=>new BehaviorStore({}).save(data));failFlush=false;
  });
  const journeyModel=load('model/AdventureJourney.ets',{'./Companion':model});
  const {JourneyStore}=load('services/JourneyStore.ets',{'@kit.ArkData':{preferences:{...prefs,getPreferencesSync:()=>({getSync:(key,fallback)=>values.has(key)?values.get(key):fallback,putSync:(key,value)=>values.set(key,value),flushSync:()=>{}})}},'../model/AdventureJourney':journeyModel});
  await test('Adventure Journey persists through fresh Preferences store without losing earned progress',async()=>{
    values.clear();let journey=new journeyModel.JourneyState();journey=journeyModel.completeAdventure(journey,'2026-10-4',false,new Date(2026,9,4).getTime());new JourneyStore({}).save(journey);assert.equal(new JourneyStore({}).load().worlds[0],1);assert.equal(new JourneyStore({}).load().completedDays[0],'2026-10-4');
  });
  const worldProtocol = require('./load-protocol.cjs')(ts);
  const worldPrefs={'@kit.ArkData':{preferences:{getPreferencesSync:()=>({getSync:(key,fallback)=>values.has(key)?values.get(key):fallback,putSync:(key,value)=>{if(typeof value==='string'&&value.length>8192)throw Error('oversized');values.set(key,value)},flushSync:()=>{if(failFlush)throw Error('disk')}})}},'@companion/protocol':worldProtocol,'../model/SessionBalanceEngine':load('model/SessionBalanceEngine.ets')};
  const {WorldStore}=load('../../../../tventry/src/main/ets/services/WorldStore.ets',worldPrefs);
  await test('Tablet world raw journal and earned decorations survive chunked store/restart; corrupt data recovers',async()=>{
    values.clear();let state=new worldProtocol.WorldState();state.active=true;state.decorations=2;state.days=['2026-10-4'];for(let i=0;i<200;i++)worldProtocol.WorldEngine.log(state,'OBJECT_PLACED',String(i),Date.now());new WorldStore({}).save(state);let restored=new WorldStore({}).load();assert.equal(restored.events.length,200);assert.equal(restored.decorations,2);failFlush=true;assert.throws(()=>new WorldStore({}).save(new worldProtocol.WorldState()));failFlush=false;assert.equal(new WorldStore({}).load().events.length,200);values.set(values.get('active')+'-count',-1);assert.equal(new WorldStore({}).load().active,false);
  });
  const {ParentWorldData,ParentWorldStore}=load('services/ParentWorldStore.ets',worldPrefs);
  await test('Phone compact result journal/preset survive chunks and corrupt nested results are rejected',async()=>{
    values.clear();const data=new ParentWorldData();data.minutes=45;data.preset='Low Energy';for(let i=0;i<100;i++){let state=new worldProtocol.WorldState();state.active=true;state=worldProtocol.WorldEngine.open(state,'bridge',Date.now()+i);for(let j=0;j<3;j++)state=worldProtocol.WorldEngine.act(state,'place',j,Date.now());state=worldProtocol.WorldEngine.next(state,Date.now());data.results.push(state.results[0]);}new ParentWorldStore({}).save(data);assert.equal(new ParentWorldStore({}).load().results.length,100);assert.equal(new ParentWorldStore({}).load().minutes,45);data.customRules.movement=999;new ParentWorldStore({}).save(data);assert.equal(new ParentWorldStore({}).load().results.length,100);assert.equal(new ParentWorldStore({}).load().customRules.movement,20);data.results[0].style='IQ';new ParentWorldStore({}).save(data);assert.equal(new ParentWorldStore({}).load().results.length,0);
  });
  console.log(`${passed} mocked-service checks passed; actual platform behavior remains unverified.`);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
