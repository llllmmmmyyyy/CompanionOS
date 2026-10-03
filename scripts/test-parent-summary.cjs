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
const { ParentInsightSummaryEngine:E }=load('ParentInsightSummaryEngine');
const {WorldResult}=require('./load-protocol.cjs')(ts);
const {SessionBalanceEngine,presetRules}=load('SessionBalanceEngine');
let passed=0;const now=Date.now();let id=0;
function test(name,run){run();passed++;console.log('PASS '+name)}
function rows(style,n,done=n,retries=0,feedback=''){return Array.from({length:n},(_,i)=>{const r=new WorldResult();r.id='summary-'+id++;r.activityId=({BUILDING:'bridge',MEMORY:'memory',SORTING:'rescue',COUNTING:'stars',MOVEMENT:'copy',CREATING:'garden',EXPLORING:'calm',WATCHING:'watch'})[style];r.title=style+' mission';r.sessionId='test-session';r.style=style;r.timestamp=now-1000;r.completed=i<done;r.skipped=!r.completed;r.retries=retries;r.attempts=1+retries;r.feedback=feedback;return r})}
const sum=r=>E.summarize(r,7,now);
const text=s=>[s.primaryObservation,s.secondaryObservation,s.challengeObservation,s.nextSessionSuggestion].join(' ');
test('Building completion dominant without unsupported comparison',()=>{const s=sum([...rows('BUILDING',6,5),...rows('MEMORY',4,1)]);assert.match(s.primaryObservation,/Building activities were usually completed/);assert.doesNotMatch(text(s),/most|chosen|ability/)});
test('Memory retries dominate and suggestion retains all categories',()=>{const s=sum(rows('MEMORY',4,2,2));assert.match(text(s),/Memory missions often needed another try/);assert.match(s.nextSessionSuggestion,/shorter memory sequence/);for(const category of ['learning','movement','creating','calm'])assert.ok(s.nextSessionSuggestion.includes(category))});
test('More play records cannot establish selection preference; supported format completion comparison',()=>{const s=sum([...rows('BUILDING',6,6),...rows('WATCHING',3,1)]);assert.match(text(s),/play activities were completed more consistently/);assert.doesNotMatch(text(s),/chose|chosen|selected|prefer/);assert.ok(s.evidenceItems.some(e=>e.basis.includes('not choices offered')))});
test('Insufficient data yields no suggestion or evidence',()=>{const s=sum(rows('BUILDING',2));assert.equal(s.confidenceLabel,'NOT ENOUGH DATA');assert.match(s.primaryObservation,/Complete a few more/);assert.equal(s.evidenceItems.length,0);assert.equal(s.nextSessionSuggestion,'')});
test('Conflicting signals stay descriptive and do not invent liking',()=>{const s=sum([...rows('BUILDING',3,1,0,'disliked'),...rows('MEMORY',3,1)]);assert.match(s.primaryObservation,/completion varied/);assert.doesNotMatch(text(s),/Loved it|usually|preference/)});
test('Sparse groups with all completed outcomes never invent variation',()=>{const s=sum([...rows('BUILDING',2),...rows('MEMORY',2)]);assert.match(s.primaryObservation,/too few outcomes/);assert.doesNotMatch(text(s),/completion varied|usually/)});
test('No completed activities accurately describes skipped outcomes',()=>{const s=sum(rows('BUILDING',4,0));assert.match(s.primaryObservation,/No activities were recorded as completed/);assert.equal(E.metrics(s.evidenceItems[0].rows).completed,0)});
test('One category supports observation without cross-category claims',()=>{const s=sum(rows('BUILDING',3));assert.equal(s.confidenceLabel,'EARLY PATTERN');assert.match(s.primaryObservation,/Building/);assert.doesNotMatch(text(s),/more than|most/)});
test('Movement completion pattern does not invent short-duration or sensor evidence',()=>{const s=sum(rows('MOVEMENT',6,5));assert.match(s.primaryObservation,/Movement activities were usually completed/);assert.doesNotMatch(text(s),/Short|longer|measured exercise/)});
test('Positive feedback requires three explicit responses and evidence shows exact feedback denominator',()=>{const s=sum(rows('BUILDING',4,4,0,'liked'));assert.match(text(s),/often received Loved it/);assert.match(E.evidenceText(s.evidenceItems[1]),/4 \/ 4 explicit responses were Loved it/);assert.doesNotMatch(text(sum(rows('BUILDING',2,2,0,'liked'))),/Loved it/)});
test('Every observation and suggestion maps to original outcomes and metrics',()=>{const r=[...rows('BUILDING',6,5),...rows('MEMORY',4,2,2,'liked')];const before=JSON.stringify(r);const s=sum(r);assert.equal(s.sampleSize,r.length);assert.ok(s.evidenceItems.length<=4);for(const e of s.evidenceItems){assert.ok(e.rows.length>=3);assert.ok(e.rows.every(row=>r.includes(row)));const m=E.metrics(e.rows);assert.equal(m.completed,e.rows.filter(row=>row.completed).length);assert.equal(m.retries,e.rows.reduce((n,row)=>n+row.retries,0));assert.match(E.evidenceText(e),new RegExp(`${m.completed} / ${m.started} completed`))}assert.equal(JSON.stringify(r),before)});
test('Generated text contains no prohibited psychological language',()=>{const banned=/good memory|bad memory|poor attention|short attention span|smart|gifted|creative child|visual learner|ADHD|anxiety|delayed|intelligence|personality type|learning disorder|cognitive strength|emotional problem/i;for(const style of ['BUILDING','MEMORY','SORTING','COUNTING','MOVEMENT','CREATING','EXPLORING','WATCHING'])for(const done of [0,2,4])assert.doesNotMatch(text(sum(rows(style,4,done,2,'liked'))),banned)});
test('Suggestion is read-only and cannot change SessionBalanceEngine allocations',()=>{for(const preset of ['Balanced','More Learning','More Movement','Low Energy']){const rules=presetRules(preset);const before=JSON.stringify(SessionBalanceEngine.plan(30,rules));sum(rows('MEMORY',6,3,2));assert.equal(JSON.stringify(SessionBalanceEngine.plan(30,rules)),before);for(const c of ['MOVE','LEARN','CREATE','CALM'])assert.ok(SessionBalanceEngine.plan(30,rules).some(slot=>slot.category===c))}});
test('Windows exclude future/old records, distinguish Today/7/30 and deduplicate without mutation',()=>{const r=rows('BUILDING',4);r[0].timestamp=now-20*86400000;r[1].timestamp=now+10000;r[2].timestamp=now-3*86400000;assert.equal(E.summarize([...r,r[3]],7,now).sampleSize,2);assert.equal(E.summarize(r,1,now).sampleSize,1);assert.equal(E.summarize(r,30,now).sampleSize,3)});
if(process.argv[3]){const source=JSON.parse(fs.readFileSync(process.argv[3],'utf8').trimStart());const s=sum(source.results);console.log('ACTUAL JOURNAL SUMMARY '+JSON.stringify(s,null,2));}
console.log(`${passed} parent summary checks passed.`);
