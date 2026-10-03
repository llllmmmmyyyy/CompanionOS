// Actual ArkTS protocol/client/receiver logic, with network and timers mocked explicitly.
const fs = require('node:fs'); const path = require('node:path'); const vm = require('node:vm');
const assert = require('node:assert/strict'); const ts = require(path.resolve(process.argv[2]));
let request = async () => { throw Error('unconfigured mock'); }; let interval;
const cache = new Map();
function load(file) {
  file = path.resolve(__dirname, '..', file);
  if (cache.has(file)) return cache.get(file);
  const exports = {}; cache.set(file, exports);
  const box = { exports, Date, Math, Number, JSON, Array, Promise, Error,
    setInterval: callback => { interval = callback; return 1; }, clearInterval: () => {},
    require: name => name === './GameBoard' ? {GameBoard:()=>{}} : name === '@companion/protocol' ? { ...load('shared/Index.ets'), backendRequest: (...args) => request(...args) } :
      file === path.resolve(__dirname, '../shared/Index.ets') && name === './Network' ? { backendRequest: (...args) => request(...args) } :
        load(path.relative(path.resolve(__dirname, '..'), path.resolve(path.dirname(file), name + '.ets'))) };
  vm.runInNewContext(ts.transpileModule(fs.readFileSync(file, 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021 } }).outputText, box);
  return exports;
}
const { TvMessage, parseMessage, validBackendUrl, EMULATOR_RELAY_ENDPOINT, connectionError } = load('shared/Index.ets');
const { EmulatorTvTransport } = load('entry/src/main/ets/services/EmulatorTvTransport.ets');
const { TvFrame } = load('entry/src/main/ets/services/TvSessionTransport.ets');
const { TvReceiver } = load('tventry/src/main/ets/services/TvReceiver.ets');
const { backendActivity, BackendActivityService } = load('entry/src/main/ets/services/BackendActivityService.ets');
const { ActivityPlanRequest } = load('entry/src/main/ets/services/AiActivityService.ets');
const flush = async () => { for (let i = 0; i < 20; i++) await Promise.resolve(); };
let passed = 0; async function test(name, run) { await run(); passed++; console.log('PASS ' + name); }
(async () => {
  await test('gateway endpoint and detailed receiver connection failures/waiting are explicit', async () => {
    assert.equal(EMULATOR_RELAY_ENDPOINT, 'http://10.0.2.2:18080'); assert.ok(validBackendUrl(EMULATOR_RELAY_ENDPOINT));
    assert.equal(validBackendUrl('http://10.0.2.2:8787'), false);
    const failure = new Error('Connection refused'); failure.code = 2300007;
    assert.match(connectionError(failure), /2300007.*Connection refused/);
    const reports = []; const receiver = new TvReceiver(EMULATOR_RELAY_ENDPOINT, 'family-demo', (state, message, detail) => reports.push([state, detail]));
    request = async () => { throw failure; }; receiver.start(); await flush();
    assert.equal(reports[0][0], 'CONNECTING'); assert.match(reports.at(-1)[1], /Connection failed:.*2300007/);
    request = async () => JSON.stringify({ connected: false, revision: 0, message: new TvMessage() }); interval(); await flush();
    assert.equal(reports.at(-1)[0], 'WAITING'); assert.match(reports.at(-1)[1], /Connected to Windows relay/); receiver.stop();
  });
  await test('strict shared protocol rejects malformed, unknown, private and oversized messages', () => {
    const m = new TvMessage(); assert.ok(parseMessage(JSON.stringify(m)));
    for (const change of [{ protocolVersion: 2 }, { type: 'BAD' }, { phase: 'unknown' }, { stepIndex: 99 },
      { videoUrl: 'file:///private' }, { videoSource: 'fake' }, { activityMode: 'UNKNOWN' }, { title: 'x'.repeat(81) }, { remaining: -1 }]) {
      assert.equal(parseMessage(JSON.stringify({ ...m, ...change })), undefined);
    }
    for (const raw of ['null', '{}', '[1]', '{broken', 'x'.repeat(17000)]) assert.equal(parseMessage(raw), undefined);
    assert.ok(validBackendUrl('http://10.0.2.2:18080')); assert.equal(validBackendUrl('http://public.example'), false);
  });
  await test('HTTP transport forwards phone commands, coalesces sync, and survives disconnect/reconnect', async () => {
    const sent = []; const events = []; let online = true;
    request = async (url, method, raw) => { if (method === 'POST' && url.endsWith('/phone')) sent.push(JSON.parse(raw));
      return JSON.stringify({ receiverConnected: online, videoStatus: 'IDLE' }); };
    const transport = new EmulatorTvTransport('http://10.0.2.2:18080', 'family-demo', event => events.push(event));
    await transport.connect(); const frame = new TvFrame(); frame.phase = 'running'; frame.remaining = 180;
    for (const method of ['startActivity', 'pauseActivity', 'resumeActivity', 'nextStep', 'previousStep', 'cancelActivity']) {
      if (method === 'startActivity') transport[method]({}, frame); else transport[method](frame); await flush();
    }
    assert.equal(sent.map(m => m.type).join(','), 'START,PAUSE,RESUME,NEXT_STEP,PREVIOUS_STEP,CANCEL');
    online = false; transport.synchronize(frame); await flush(); assert.ok(events.includes('disconnected'));
    online = true; transport.synchronize(frame); await flush(); assert.equal(events.at(-1), 'connected');
    frame.phase = 'completed'; transport.synchronize(frame); await flush(); assert.equal(sent.at(-1).type, 'COMPLETE');
    transport.disconnect(); const n = sent.length; transport.synchronize(frame); await flush(); assert.equal(sent.length, n);
  });
  await test('connect rejects absent TV and invalid endpoints; network failure preserves caller state', async () => {
    request = async () => JSON.stringify({ receiverConnected: false });
    await assert.rejects(new EmulatorTvTransport('http://10.0.2.2:18080', 'family-demo', () => {}).connect());
    await assert.rejects(new EmulatorTvTransport('file:///bad', 'room', () => {}).connect());
    const events = []; request = async () => JSON.stringify({ receiverConnected: true });
    const transport = new EmulatorTvTransport('http://10.0.2.2:18080', 'family-demo', e => events.push(e)); await transport.connect();
    request = async () => { throw Error('network timeout'); }; transport.synchronize(new TvFrame()); await flush();
    assert.equal(events.at(-1), 'disconnected'); transport.disconnect();
  });
  await test('TV receiver restores state, preserves last safe state on disconnect and rejects malformed frames', async () => {
    const states = []; const message = new TvMessage(); message.sessionId = 'phone'; message.phase = 'paused'; message.remaining = 42;
    request = async () => JSON.stringify({ connected: true, revision: 1, message });
    const receiver = new TvReceiver('http://10.0.2.2:18080', 'family-demo', (status, frame) => states.push([status, frame]));
    receiver.start(); await flush(); assert.equal(states.at(-1)[0], 'CONNECTED'); assert.equal(states.at(-1)[1].remaining, 42);
    request = async () => '{broken'; interval(); await flush(); assert.equal(states.at(-1)[0], 'DISCONNECTED'); assert.equal(states.at(-1)[1].remaining, 42);
    request = async () => JSON.stringify({ connected: true, revision: 2, message: { ...message, phase: 'running' } });
    interval(); await flush(); assert.equal(states.at(-1)[1].phase, 'running'); receiver.stop();
    const n = states.length; interval(); await flush(); assert.equal(states.length, n);
  });
  await test('backend client uses real endpoints and validates plans and approved cached URLs', async () => {
    const r = new ActivityPlanRequest();
    const job = { id: 'a'.repeat(32), state: 'READY', source: 'fallback', message: 'Fallback, not AI',
      plan: { title: 'Adventure', theme: 'Clouds', educationalGoal: 'Count', steps: [1, 2, 3].map(i => ({ id: 'step-' + i, instruction: 'Rest with parent', durationSeconds: 60, learningGoal: 'Count' })) },
      segments: [1, 2, 3].map(() => ({ state: 'FAILED', videoUrl: '' })) };
    const urls = []; request = async url => { urls.push(url); return JSON.stringify(job); };
    const result = await BackendActivityService.create('http://10.0.2.2:18080', r, ['Movement'], () => {}, () => true);
    assert.equal(backendActivity(result, r, 'http://10.0.2.2:18080').generatedByAI, false);
    assert.ok(urls[0].endsWith('/activities/generate')); assert.ok(urls[1].endsWith('/status'));
    job.source = 'ai'; job.segments[0] = { state: 'READY', videoUrl: '/videos/' + 'b'.repeat(64) };
    assert.ok(backendActivity(job, r, 'http://10.0.2.2:18080').activitySteps[0].videoUrl.startsWith('http://10.0.2.2'));
    job.segments[0].videoUrl = 'file:///secret'; assert.throws(() => backendActivity(job, r, 'http://10.0.2.2:18080'));
    request = async () => { throw Error('unavailable'); };
    await assert.rejects(BackendActivityService.create('http://10.0.2.2:18080', r, ['Movement'], () => {}, () => true));
  });
  await test('Tablet real inputs reach the Phone callback exactly once; stale or malformed commands are filtered', async()=>{
    const {GameCommand}=load('shared/Index.ets');const action=new GameCommand();action.id='input-1';action.sessionId='active';action.action='answer';action.value='2';action.phase='input';
    const received=[];request=async()=>JSON.stringify({receiverConnected:true,actions:[action,{...action,id:'invalid',action:'camera'}]});
    const transport=new EmulatorTvTransport(EMULATOR_RELAY_ENDPOINT,'family-demo',(event,frame)=>{if(event==='gameInput')received.push(frame.gameCommand)});await transport.connect();const frame=new TvFrame();transport.synchronize(frame);await flush();transport.synchronize(frame);await flush();assert.equal(received.length,1);assert.equal(received[0].value,'2');transport.disconnect();
    let endpoint='';request=async(url)=>{endpoint=url;return '{}'};const receiver=new TvReceiver(EMULATOR_RELAY_ENDPOINT,'family-demo',()=>{});assert.equal(await receiver.gameInput(action),true);assert.ok(endpoint.endsWith('/game'));receiver.stop();
  });
  console.log(`${passed} emulator protocol/client host checks passed`);
})().catch(error => { console.error(error); process.exitCode = 1; });
