import { common } from '@kit.AbilityKit';
import { WorldStatus, WorldEnvelope, WorldCommand, WorldResult, WorldSlot, validWorldResult, worldSlots, recommendedWorld, backendRequest, connectionError, EMULATOR_RELAY_ENDPOINT } from '@companion/protocol';
import { BalanceRules, BALANCE_PRESETS, presetRules, validRules, SessionBalanceEngine } from '../model/SessionBalanceEngine';
import { ParentSettings } from '../model/Companion';
import { ParentWorldStore, ParentWorldData } from '../services/ParentWorldStore';
@Component
export struct ParentDashboard {
  @Prop settings: ParentSettings = new ParentSettings();
  @State status: WorldStatus = new WorldStatus();
  @State connected: boolean = false;
  @State detail: string = 'Checking Tablet connection...';
  @State data: ParentWorldData = new ParentWorldData();
  @State view: string = 'dashboard';
  @State evidence: string = '';
  @State sending: boolean = false;
  @State rules: BalanceRules = new BalanceRules();
  private store: ParentWorldStore | undefined = undefined;
  private timer: number = -1;
  private polling: boolean = false;
  private active: boolean = false;
  private dirty: boolean = false;
  private sequence: number = 0;
  aboutToAppear(): void { try { this.store = new ParentWorldStore(this.getUIContext().getHostContext() as common.Context); this.data = this.store.load(); this.rules = this.data.preset === 'Custom' ? this.data.customRules : presetRules(this.data.preset); } catch { this.detail = 'Local parent journal could not open.'; }
    this.active = true; this.timer = setInterval(() => this.poll(), 1500); this.poll(); }
  aboutToDisappear(): void { this.active = false; clearInterval(this.timer); }
  private save(): void { try { if (!this.store) { throw new Error('Local journal unavailable'); } this.store.save(this.data); this.dirty = false; } catch { this.dirty = true; this.detail = 'Local saving failed. Tablet retains its journal; retry connection.'; } }
  private async poll(): Promise<void> {
    if (!this.active || this.polling) { return; } this.polling = true;
    try { const envelope = JSON.parse(await backendRequest(`${EMULATOR_RELAY_ENDPOINT}/world/rooms/family-demo/phone`, 'GET', '', 262144)) as WorldEnvelope;
      if (!this.active) { return; } this.connected = envelope.connected === true; this.detail = this.connected ? 'Connected | family-demo' : 'Tablet offline. Current safe activity can continue locally.';
      if (envelope.status && typeof envelope.status.active === 'boolean') { this.status = envelope.status; }
      if (Array.isArray(envelope.results)) { const merged = this.data.results.slice(); let changed = false; envelope.results.forEach((r: WorldResult) => { if (!validWorldResult(r)) { return; } const index = merged.findIndex((old: WorldResult) => old.id === r.id); if (index < 0) { merged.push(r); changed = true; } else if (merged[index].completed === r.completed && merged[index].skipped === r.skipped && (merged[index].feedback !== r.feedback || merged[index].difficultyFeedback !== r.difficultyFeedback)) { merged[index] = r; changed = true; } });
        if (changed) { this.data.results = merged.slice(-300); this.save(); }
      }
      if (this.dirty) { this.save(); }
    } catch (error) { this.connected = false; this.detail = `Connection failed: ${connectionError(error as Error)}. Retrying automatically.`; }
    finally { this.polling = false; }
  }
  private async send(type: string): Promise<void> {
    if (this.sending || (type === 'START_SESSION' && !validRules(this.rules))) { return; } this.sending = true; const command = new WorldCommand(); command.id = `parent-${Date.now()}-${this.sequence++}`; command.type = type; command.minutes = this.data.minutes;
    command.slots = worldSlots(SessionBalanceEngine.plan(this.data.minutes, this.rules).map((slot) => { const item = new WorldSlot(); item.category = slot.category; item.minutes = slot.minutes; item.mode = slot.mode; item.gameType = slot.gameType; return item; }), recommendedWorld(this.data.results, Date.now()));
    const memory = this.data.results.filter((r: WorldResult) => r.style === 'MEMORY' && r.difficultyFeedback !== '' && r.timestamp >= Date.now() - 7 * 86400000); command.difficulty = memory.length >= 3 && memory.filter((r: WorldResult) => r.difficultyFeedback === 'too hard').length > memory.length / 2 ? 2 : this.data.memorySignals;
    try { console.info(`[CompanionParent] endpoint=${EMULATOR_RELAY_ENDPOINT} room=family-demo command=${type}`); await backendRequest(`${EMULATOR_RELAY_ENDPOINT}/world/rooms/family-demo/command`, 'POST', JSON.stringify(command)); this.detail = 'Command sent. Waiting for Tablet acknowledgement...'; this.save(); await this.poll(); }
    catch { this.detail = 'Command failed. The Tablet did not acknowledge this request.'; } finally { this.sending = false; }
  }
  private recent(): WorldResult[] { return this.data.results.filter((r: WorldResult) => r.timestamp <= Date.now() && r.timestamp >= Date.now() - 7 * 86400000); }
  private styleEvidence(style: string): string { const rows = this.recent().filter((r: WorldResult) => r.style === style); return rows.map((r: WorldResult) => `${r.title}: ${r.completed ? 'completed' : 'skipped'}, ${r.attempts} attempts, ${r.retries} retries, ${r.duration}s, ${r.feedback || 'no feedback'}`).join('\n'); }
  @Builder
  controls() {
    Row({ space: 8 }) { Button('Start Child Mode').layoutWeight(1).enabled(this.connected && !this.sending).onClick(() => this.send('ENTER_CHILD_MODE')); Button('Exit Child Mode').layoutWeight(1).enabled(this.connected && !this.sending).onClick(() => this.send('EXIT_CHILD_MODE')) }
    Row({ space: 8 }) { Button('Pause').layoutWeight(1).enabled(this.status.active && !this.sending).onClick(() => this.send('PAUSE_SESSION')); Button('Resume').layoutWeight(1).enabled(this.status.active && !this.sending).onClick(() => this.send('RESUME_SESSION')); Button('Next').layoutWeight(1).enabled(this.status.total > 0 && !this.status.ended && !this.sending).onClick(() => this.send('NEXT_ACTIVITY')) }
    Button('End session').width('100%').backgroundColor('#E8EDE8').fontColor('#335248').enabled(this.status.active && !this.sending).onClick(() => this.send('END_SESSION'))
  }
  @Builder
  insights() {
    Text('What We Noticed').fontSize(23).fontWeight(FontWeight.Bold).width('100%')
    Text('Last 7 days | Observable activities, never personality or clinical labels').fontSize(14).fontColor('#536D61')
    if (this.recent().length < 3) { Text('Not enough data yet. Explore a few activities before drawing patterns.').fontSize(16) }
    ForEach(['BUILDING', 'MEMORY', 'SORTING', 'COUNTING', 'CREATING', 'MOVEMENT', 'WATCHING', 'EXPLORING'], (style: string) => {
      if (this.recent().some((r: WorldResult) => r.style === style)) {
        Column({ space: 5 }) {
          Text(`${style}: ${this.recent().filter((r: WorldResult) => r.style === style && r.completed).length} / ${this.recent().filter((r: WorldResult) => r.style === style).length} completed`).fontSize(17).fontWeight(FontWeight.Medium).width('100%')
          Text(`${this.recent().filter((r: WorldResult) => r.style === style).reduce((sum: number, r: WorldResult) => sum + r.retries, 0)} retries | ${this.recent().filter((r: WorldResult) => r.style === style && r.feedback === 'liked').length} Loved it responses`).fontSize(14).width('100%')
          Text(this.recent().filter((r: WorldResult) => r.style === style).length < 3 ? 'Too few activities for a preference pattern.' : 'An early descriptive pattern. It can change as more activities are tried.').fontSize(13).fontColor('#536D61')
          Button('Why am I seeing this?').height(40).onClick(() => { this.evidence = this.styleEvidence(style); this.view = 'evidence'; })
        }.width('100%').padding(12).backgroundColor('#EFF2EB').borderRadius(12)
      }
    })
    Text(`Play: ${this.recent().filter((r: WorldResult) => !['WATCHING', 'MOVEMENT'].includes(r.style)).length} | Watch: ${this.recent().filter((r: WorldResult) => r.style === 'WATCHING').length} | Move: ${this.recent().filter((r: WorldResult) => r.style === 'MOVEMENT').length}`).fontSize(16)
    Text('These are activity counts, not a ratio of choices offered. No attention or ability score is inferred. Movement is child-confirmed.').fontSize(13).fontColor('#536D61')
    if (this.evidence) { Text(this.evidence).fontSize(15).width('100%').padding(12).backgroundColor('#FFF9E8') }
  }
  build() {
    Column({ space: 12 }) {
      Text('CompanionOS Parent').fontSize(26).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      Text('Understand your child through everyday discoveries.').fontSize(15).fontColor('#536D61').width('100%')
      Row({ space: 7 }) { ForEach(['dashboard', 'history', 'insights'], (view: string) => { Button(view === 'dashboard' ? 'Live status' : view === 'history' ? 'Tablet history' : 'Parent Insights').fontSize(12).layoutWeight(1).height(42).onClick(() => { this.view = view; this.evidence = ''; }) }) }
      if (this.view === 'dashboard') {
        Column({ space: 5 }) {
          Text(`Tablet: ${this.connected ? 'Connected' : 'Disconnected'}`).fontSize(20).fontWeight(FontWeight.Bold).width('100%')
          Text(`Child Mode: ${this.status.active ? 'ACTIVE' : 'INACTIVE'}`).fontSize(17).width('100%')
          Text(`${this.status.world} | ${this.status.mission}`).fontSize(17).width('100%')
          Text(`${this.status.style} | ${this.status.ended ? 'Session ended' : this.status.paused ? 'Adventure paused' : this.status.phase}`).fontSize(15).width('100%')
          Text(this.status.total > 0 ? `${Math.floor(this.status.remaining / 60)}:${(this.status.remaining % 60).toString().padStart(2, '0')} remaining | ${this.status.completed} / ${this.status.total} completed` : `${this.status.completed} discoveries | Free exploration`).fontSize(17).width('100%')
          Text(this.detail).fontSize(13).fontColor('#536D61').width('100%')
        }.width('100%').padding(14).backgroundColor('#E8F0E7').borderRadius(16)
        this.controls()
        Text('Parent session configuration').fontSize(20).fontWeight(FontWeight.Bold).width('100%')
        Row({ space: 6 }) { ForEach([15, 30, 45, 60], (minutes: number) => { Button(`${minutes} min`).fontSize(13).layoutWeight(1).height(44).backgroundColor(this.data.minutes === minutes ? '#335E49' : '#E8EDE8').fontColor(this.data.minutes === minutes ? '#FFFFFF' : '#335E49').onClick(() => { this.data.minutes = minutes; this.save(); }) }) }
        Text('Memory sequence length').fontSize(16).width('100%')
        Row({ space: 6 }) { ForEach([2, 3, 4, 5], (signals: number) => { Button(`${signals} lights`).height(40).fontSize(13).layoutWeight(1).backgroundColor(this.data.memorySignals === signals ? '#335E49' : '#E8EDE8').fontColor(this.data.memorySignals === signals ? '#FFFFFF' : '#335E49').onClick(() => { this.data.memorySignals = signals; this.save(); }) }) }
        ForEach(BALANCE_PRESETS, (preset: string) => { Button(`${this.data.preset === preset ? 'Selected: ' : ''}${preset}`).width('100%').height(40).backgroundColor(this.data.preset === preset ? '#335E49' : '#E8EDE8').fontColor(this.data.preset === preset ? '#FFFFFF' : '#335E49').onClick(() => { this.data.preset = preset; this.rules = preset === 'Custom' ? this.data.customRules : presetRules(preset); this.save(); }) })
        if (this.data.preset === 'Custom') {
          Text(`MOVE minimum ${this.rules.movement}%`).fontSize(15).width('100%')
          Slider({ value: this.rules.movement, min: 10, max: 50, step: 5 }).width('100%').onChange((value: number) => { this.rules.movement = Math.round(value); this.rules.preset = 'Custom'; this.data.customRules = this.rules; this.save(); })
          Text(`LEARN minimum ${this.rules.learning}%`).fontSize(15).width('100%')
          Slider({ value: this.rules.learning, min: 20, max: 50, step: 5 }).width('100%').onChange((value: number) => { this.rules.learning = Math.round(value); this.rules.preset = 'Custom'; this.data.customRules = this.rules; this.save(); })
          Text(`Passive video maximum ${this.rules.passive}%`).fontSize(15).width('100%')
          Slider({ value: this.rules.passive, min: 0, max: 30, step: 5 }).width('100%').onChange((value: number) => { this.rules.passive = Math.round(value); this.rules.preset = 'Custom'; this.data.customRules = this.rules; this.save(); })
          if (!validRules(this.rules)) { Text('Combined MOVE and LEARN must be at most 80%.').fontSize(14).fontColor('#8A452C') }
        }
        Text('Longer learning slots contain two short story missions. Custom balance controls are saved locally. Adult nearby, indoor, no climbing or jumping.').fontSize(13).fontColor('#536D61')
        Text(SessionBalanceEngine.plan(this.data.minutes, this.rules).map((slot) => `${slot.category} ${slot.minutes}m ${slot.mode === 'VIDEO' ? 'Watch' : 'Play / guided'}`).join(' | ')).fontSize(14).width('100%')
        Button('Start Tablet session').width('100%').height(50).enabled(this.connected && !this.sending && validRules(this.rules)).onClick(() => this.send('START_SESSION'))
        Text('In-app Child Mode. This does not lock the operating system. Windows development relay; no production distributed-device claim.').fontSize(12).fontColor('#536D61')
      } else if (this.view === 'insights') { this.insights() }
      else if (this.view === 'evidence') { Text('Why am I seeing this?').fontSize(23).fontWeight(FontWeight.Bold).width('100%'); Text(this.evidence).fontSize(16).width('100%').padding(12).backgroundColor('#FFF9E8'); Text('Only recorded outcomes and explicit feedback are used. Duration is foreground interaction time, not a clinical attention score.').fontSize(14).fontColor('#536D61'); Button('Back to Parent Insights').width('100%').onClick(() => { this.view = 'insights'; this.evidence = ''; }) }
      else {
        Text(`${this.data.results.filter((r: WorldResult) => r.completed).length} child-completed activities saved locally`).fontSize(20).fontWeight(FontWeight.Bold)
        Text('Tablet results are child interaction summaries. Parent-confirmed Phone fallback records remain in Progress.').fontSize(13).fontColor('#536D61')
        ForEach(this.data.results.slice(-30).reverse(), (r: WorldResult) => { Column({ space: 4 }) { Text(`${r.title} | ${r.completed ? 'Completed' : 'Skipped'}`).fontSize(17).fontWeight(FontWeight.Medium).width('100%'); Text(`${new Date(r.timestamp).toLocaleString()} | ${r.style} | ${r.duration}s`).fontSize(13).width('100%'); Text(`${r.attempts} attempts | ${r.retries} retries | ${r.feedback || 'Feedback optional'}`).fontSize(13).width('100%') }.width('100%').padding(10).backgroundColor('#EFF2EB').borderRadius(10) }, (r: WorldResult) => r.id)
      }
    }.width('100%')
  }
}
