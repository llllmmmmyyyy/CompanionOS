import { common } from '@kit.AbilityKit';
import { WorldStatus, WorldEnvelope, WorldCommand, WorldResult, WorldSlot, validWorldResult, worldSlots, recommendedWorld, backendRequest, connectionError, EMULATOR_RELAY_ENDPOINT } from '@companion/protocol';
import { BalanceRules, BALANCE_PRESETS, presetRules, validRules, SessionBalanceEngine } from '../model/SessionBalanceEngine';
import { ParentSettings } from '../model/Companion';
import { ParentWorldStore, ParentWorldData } from '../services/ParentWorldStore';
@Component
export struct ParentDashboard {
  @Prop tab: string = 'home';
  openPage: (page: string) => void = () => {};
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
  private uiState(): string {
    if (!this.connected) { return 'DISCONNECTED'; }
    if (!this.status.active) { return 'CONNECTED_IDLE'; }
    if (this.status.ended) { return 'SESSION_COMPLETE'; }
    if (this.status.paused) { return 'SESSION_PAUSED'; }
    if (this.status.total > 0) { return 'SESSION_RUNNING'; }
    return 'CHILD_MODE_READY';
  }
  private today(): WorldResult[] { return this.data.results.filter((r: WorldResult) => new Date(r.timestamp).toDateString() === new Date().toDateString() && r.timestamp <= Date.now()); }
  private quickInsight(): string {
    const rows = this.recent().filter((r: WorldResult) => r.style === 'BUILDING');
    return rows.length >= 3 ? `Building activities: ${rows.filter((r: WorldResult) => r.completed).length} of ${rows.length} completed this week.` : 'Complete a few adventures to start seeing activity patterns.';
  }
  @Builder
  controls() {
    if (this.uiState() === 'DISCONNECTED') { Button('Reconnect').width('100%').backgroundColor('#335E49').onClick(() => this.poll()) }
    else if (this.uiState() === 'CONNECTED_IDLE') { Button('Start Child Mode').width('100%').backgroundColor('#335E49').enabled(!this.sending).onClick(() => this.send('ENTER_CHILD_MODE')) }
    else if (this.uiState() === 'CHILD_MODE_READY') { Button('Start Session').width('100%').backgroundColor('#335E49').enabled(!this.sending && validRules(this.rules)).onClick(() => this.send('START_SESSION')) }
    else if (this.uiState() === 'SESSION_RUNNING') {
      Row({ space: 10 }) {
        Button('Pause').layoutWeight(1).backgroundColor('#E8EDE8').fontColor('#335248').enabled(!this.sending).onClick(() => this.send('PAUSE_SESSION'))
        Button('Next').layoutWeight(1).backgroundColor('#E8EDE8').fontColor('#335248').enabled(!this.sending).onClick(() => this.send('NEXT_ACTIVITY'))
      }
      Button('End Session').fontColor('#914B3A').backgroundColor('#F5EDE8').enabled(!this.sending).onClick(() => this.send('END_SESSION'))
    } else if (this.uiState() === 'SESSION_PAUSED') {
      Button('Resume').width('100%').backgroundColor('#335E49').enabled(!this.sending).onClick(() => this.send('RESUME_SESSION'))
      Button('End Session').fontColor('#914B3A').backgroundColor('#F5EDE8').enabled(!this.sending).onClick(() => this.send('END_SESSION'))
    } else {
      Button('View Summary').width('100%').backgroundColor('#335E49').onClick(() => { this.openPage('parent-insights'); })
      Button('Start New Session').backgroundColor('#E8EDE8').fontColor('#335248').enabled(!this.sending && validRules(this.rules)).onClick(() => this.send('START_SESSION'))
    }
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
          Button('Why am I seeing this?').backgroundColor('#E1EAE3').fontColor('#335248').height(40).onClick(() => { this.evidence = this.styleEvidence(style); this.view = 'evidence'; })
        }.width('100%').padding(12).backgroundColor('#EFF2EB').borderRadius(12)
      }
    })
    Text(`Play: ${this.recent().filter((r: WorldResult) => !['WATCHING', 'MOVEMENT'].includes(r.style)).length} | Watch: ${this.recent().filter((r: WorldResult) => r.style === 'WATCHING').length} | Move: ${this.recent().filter((r: WorldResult) => r.style === 'MOVEMENT').length}`).fontSize(16)
    Text('These are activity counts, not a ratio of choices offered. No attention or ability score is inferred. Movement is child-confirmed.').fontSize(13).fontColor('#536D61')
    if (this.evidence) { Text(this.evidence).fontSize(15).width('100%').padding(12).backgroundColor('#FFF9E8') }
  }
  @Builder
  sessionOptions() {
    Text('Start a Parent Work Session').fontSize(19).fontWeight(FontWeight.Bold).width('100%')
    Text('30 min suggested').fontSize(12).fontColor('#536D61').width('100%')
    Row({ space: 5 }) { ForEach([15, 30, 45, 60], (minutes: number) => { Button(`${minutes} min`).fontSize(12).layoutWeight(1).height(36).backgroundColor(this.data.minutes === minutes ? '#335E49' : '#E8EDE8').fontColor(this.data.minutes === minutes ? '#FFFFFF' : '#335E49').onClick(() => { this.data.minutes = minutes; this.save(); }) }) }
    ForEach([['Balanced', 'More Learning'], ['More Movement', 'Low Energy']], (pair: string[]) => {
      Row({ space: 6 }) { ForEach(pair, (preset: string) => { Button(preset).fontSize(12).layoutWeight(1).height(34).backgroundColor(this.data.preset === preset ? '#D6EBDC' : '#F0F2ED').fontColor('#335248').onClick(() => { this.data.preset = preset; this.rules = presetRules(preset); this.save(); }) }) }
    })
    Text(`${this.data.preset}: Learning + movement + creative + calm`).fontSize(13).fontColor('#536D61').width('100%')
  }
  @Builder
  history() {
    Text('Recent activity').fontSize(20).fontWeight(FontWeight.Bold).width('100%')
    Text(`${this.data.results.filter((r: WorldResult) => r.completed).length} child-completed activities`).fontSize(14).width('100%')
        ForEach(this.data.results.slice(-30).reverse(), (r: WorldResult) => { Column({ space: 4 }) { Text(`${r.title} | ${r.completed ? 'Completed' : 'Skipped'}`).fontSize(17).fontWeight(FontWeight.Medium).width('100%'); Text(`${new Date(r.timestamp).toLocaleString()} | ${r.style} | ${r.duration}s`).fontSize(13).width('100%'); Text(`${r.attempts} attempts | ${r.retries} retries | ${r.feedback || 'Feedback optional'}`).fontSize(13).width('100%') }.width('100%').padding(10).backgroundColor('#EFF2EB').borderRadius(10) }, (r: WorldResult) => r.id)

  }
  build() {
    Column({ space: 10 }) {
      Text(this.tab === 'home' ? 'CompanionOS Parent' : this.tab === 'parent-activities' ? 'Activities' : this.tab === 'parent-insights' ? 'Activity Insights' : 'Parent').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      if (this.tab === 'home') {
        Text('Understand your child through everyday discoveries.').fontSize(14).fontColor('#536D61').width('100%')
        Column({ space: 6 }) {
          Text('TABLET STATUS').fontSize(11).fontWeight(FontWeight.Bold).fontColor('#536D61').width('100%')
          Text(`Tablet: ${this.connected ? 'Connected' : 'Disconnected'}`).fontSize(20).fontWeight(FontWeight.Bold).width('100%')
          Text(`Child Mode: ${!this.connected ? 'Unavailable' : this.status.active ? 'Active' : 'Ready'}`).fontSize(14).width('100%')
          if (this.uiState() === 'SESSION_RUNNING' || this.uiState() === 'SESSION_PAUSED') {
            Text(this.status.paused ? 'Adventure paused' : `${this.status.world} | ${this.status.mission}`).fontSize(16).width('100%')
            Text(`${Math.ceil(this.status.remaining / 60)} min remaining | ${this.status.completed} / ${this.status.total} complete`).fontSize(14).width('100%')
          } else if (this.uiState() === 'SESSION_COMPLETE') { Text(`${this.status.completed === this.status.total && this.status.total > 0 ? 'Session complete' : 'Session ended'} | ${this.status.completed} / ${this.status.total} activities completed`).fontSize(15).width('100%') }
          else if (this.uiState() === 'CHILD_MODE_READY') { Text("Ready for today's adventure").fontSize(15).width('100%') }
          else if (!this.connected) { Text('Open CompanionOS on your Tablet.').fontSize(14).width('100%') }
          Text(`${this.data.minutes} min \u00B7 ${this.data.preset}`).fontSize(14).fontColor('#536D61').width('100%')
          Text('Change session settings >').fontSize(13).fontColor('#335E49').width('100%').padding({ top: 2, bottom: 4 }).onClick(() => this.openPage('parent-controls'))
          this.controls()
          if (this.sending) { Text('Sending request...').fontSize(12) }
          if (this.detail.includes('failed') || this.detail.includes('unavailable') || this.detail.includes('could not')) { Text(this.detail.includes('saving') || this.detail.includes('journal') ? 'Local saving needs attention. See Parent for details.' : 'Connection or request failed. See Parent for details.').fontSize(12).fontColor('#914B3A').width('100%') }
        }.width('100%').padding(12).backgroundColor('#E8F0E7').borderRadius(16)
        Column({ space: 6 }) {
          Text('What We Noticed').fontSize(19).fontWeight(FontWeight.Bold).width('100%')
          Text(this.quickInsight()).fontSize(15).width('100%')
          Text('View Activity Insights >').fontSize(14).fontColor('#335E49').width('100%').onClick(() => this.openPage('parent-insights'))
        }.width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(16)
        Column({ space: 6 }) {
          Text("Today's Activity").fontSize(18).fontWeight(FontWeight.Bold).width('100%')
          ForEach(['LEARN', 'MOVE', 'CREATE', 'CALM'], (category: string) => { Text(`${category}   ${Math.floor(this.today().filter((r: WorldResult) => r.category === category).reduce((sum: number, r: WorldResult) => sum + r.duration, 0) / 60)} min`).fontSize(14).width('100%') })
          Text(`${this.today().filter((r: WorldResult) => r.completed).length} activities completed`).fontSize(14).width('100%')
          Text('View history >').fontSize(14).fontColor('#335E49').width('100%').onClick(() => this.openPage('parent-insights'))
        }.width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(16)
      } else if (this.tab === 'parent-activities') {
        ForEach(['Play', 'Watch', 'Move', 'Create', 'Calm'], (category: string) => {
          Column({ space: 6 }) {
            Text(category).fontSize(20).fontWeight(FontWeight.Bold).width('100%')
            Text(category === 'Play' ? 'Dino Bridge Builder | Robot Memory | Animal Rescue | Star Collector | Rocket' : category === 'Watch' ? 'Built-in Video | AI content | My Video' : category === 'Move' ? 'Copy Pico | Number Move' : category === 'Create' ? 'Creative Garden' : 'Calm Sky | Storybook').fontSize(15).width('100%')
            if (category === 'Watch') { Button('Open Video Library').backgroundColor('#E8EDE8').fontColor('#335248').onClick(() => this.openPage('games')) }
          }.width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(14)
        })
        Text('Interactive world activities run on the Tablet.').fontSize(13).fontColor('#536D61')
        Button('Optional Phone activities').backgroundColor('#E8EDE8').fontColor('#335248').onClick(() => this.openPage('phone-fallback'))
      } else if (this.tab === 'parent-insights') {
        if (this.view === 'evidence') {
          Text('Why am I seeing this?').fontSize(20).fontWeight(FontWeight.Bold)
          Text(this.evidence).fontSize(15).width('100%').padding(12).backgroundColor('#FFF9E8')
          Button('Back to insights').backgroundColor('#E8EDE8').fontColor('#335248').onClick(() => { this.view = 'insights'; this.evidence = ''; })
        } else { this.insights(); this.history() }
        Button('Phone fallback Activity Insights').backgroundColor('#E8EDE8').fontColor('#335248').onClick(() => this.openPage('insights'))
        Button('Parent-confirmed records').backgroundColor('#E8EDE8').fontColor('#335248').onClick(() => this.openPage('progress'))
      } else {
        Button('Child & Safety Settings').backgroundColor('#E8EDE8').fontColor('#335248').onClick(() => this.openPage('settings'))
        Text('Age, interests, safety and content preferences').fontSize(14).fontColor('#536D61')
        this.sessionOptions()
        Text('Memory sequence length').fontSize(16).width('100%')
        Row({ space: 6 }) { ForEach([2, 3, 4, 5], (signals: number) => { Button(`${signals} lights`).height(36).fontSize(12).layoutWeight(1).backgroundColor(this.data.memorySignals === signals ? '#335E49' : '#E8EDE8').fontColor(this.data.memorySignals === signals ? '#FFFFFF' : '#335E49').onClick(() => { this.data.memorySignals = signals; this.save(); }) }) }
        Button('Custom balance').backgroundColor('#E8EDE8').fontColor('#335248').onClick(() => { this.data.preset = 'Custom'; this.rules = this.data.customRules; this.save(); })
        if (this.data.preset === 'Custom') {
          Text(`MOVE minimum ${this.rules.movement}%`).fontSize(15).width('100%')
          Slider({ value: this.rules.movement, min: 10, max: 50, step: 5 }).width('100%').onChange((value: number) => { this.rules.movement = Math.round(value); this.rules.preset = 'Custom'; this.data.customRules = this.rules; this.save(); })
          Text(`LEARN minimum ${this.rules.learning}%`).fontSize(15).width('100%')
          Slider({ value: this.rules.learning, min: 20, max: 50, step: 5 }).width('100%').onChange((value: number) => { this.rules.learning = Math.round(value); this.rules.preset = 'Custom'; this.data.customRules = this.rules; this.save(); })
          Text(`Passive video maximum ${this.rules.passive}%`).fontSize(15).width('100%')
          Slider({ value: this.rules.passive, min: 0, max: 30, step: 5 }).width('100%').onChange((value: number) => { this.rules.passive = Math.round(value); this.rules.preset = 'Custom'; this.data.customRules = this.rules; this.save(); })
          if (!validRules(this.rules)) { Text('Combined MOVE and LEARN must be at most 80%.').fontSize(14).fontColor('#8A452C') }
        }

        Text('Adult nearby, indoor, no climbing or jumping.').fontSize(13).fontColor('#536D61')
        Button('Exit Child Mode').backgroundColor('#F5EDE8').fontColor('#914B3A').enabled(this.connected && this.status.active && !this.sending).onClick(() => this.send('EXIT_CHILD_MODE'))
        Text('About / Technical Information').fontSize(18).fontWeight(FontWeight.Bold).width('100%')
        Text(`Endpoint: ${EMULATOR_RELAY_ENDPOINT} | Room: family-demo`).fontSize(12).width('100%')
        Text(this.detail).fontSize(12).width('100%')
        Text('In-app Child Mode does not lock the operating system. The Windows development/demo relay is not production HarmonyOS distributed-device functionality.').fontSize(12).fontColor('#536D61')
      }
    }.width('100%')
  }
}
