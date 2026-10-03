import { common } from '@kit.AbilityKit';
import { WorldEngine, WorldState, WorldCommand, WorldEnvelope, WorldResult, WORLD_GAMES, worldTitle, worldName, backendRequest, connectionError, EMULATOR_RELAY_ENDPOINT, TvMessage } from '@companion/protocol';
import { WorldStore } from '../services/WorldStore';

@Component
export struct ChildWorld {
  onActive: (active: boolean) => void = () => {};
  @Prop frame: TvMessage = new TvMessage();
  @Prop endpoint: string = EMULATOR_RELAY_ENDPOINT;
  @Prop room: string = 'family-demo';
  @State state: WorldState = new WorldState();
  @State connected: boolean = false;
  @State storageError: string = '';
  onSound: (cue: string) => void = () => {};
  @State breath: boolean = false;
  private breathTick: number = 0;
  @State pulse: boolean = false;
  @State worldWidth: number = 900;
  @State worldHeight: number = 460;
  @State dragIndex: number = -1;
  @State dragX: number = 0;
  @State dragY: number = 0;
  @State videoPlaying: boolean = false;
  @StorageLink('tvForeground') @Watch('foregroundChanged') foreground: boolean = true;
  private store: WorldStore | undefined = undefined;
  private timer: number = -1;
  private polling: boolean = false;
  private active: boolean = false;
  private controller: VideoController = new VideoController();
  private saveAt: number = 0;
  aboutToAppear(): void {
    try { this.store = new WorldStore(this.getUIContext().getHostContext() as common.Context); this.state = this.store.load();
      if (this.state.ended) { this.state.paused = false; }
      if (this.state.active && this.state.sessionId && !this.state.ended) { this.state.paused = true; this.state.message = 'Welcome back. Your adventure is safely paused.'; }
    } catch { this.storageError = 'Local saving is unavailable. Ask your parent for help.'; }
    this.onActive(this.state.active); this.active = true; this.timer = setInterval(() => { this.clock(); }, 1000); this.sync();
  }
  aboutToDisappear(): void { this.active = false; clearInterval(this.timer); this.save(); this.stopVideo(); }
  private foregroundChanged(): void { if (!this.foreground) { if (this.state.active && !this.state.ended) { this.state.paused = true; } this.save(); this.stopVideo(); } else { this.state.lastTick = Date.now(); this.sync(); } }
  private stopVideo(): void { this.videoPlaying = false; try { this.controller.pause(); } catch { } }
  private save(): void { try { this.state.savedAt = Date.now(); if (!this.store) { throw new Error('Local saving unavailable'); } this.store.save(this.state); this.storageError = ''; } catch { this.storageError = 'Saving needs help. Keep this screen open and ask your parent.'; } }
  private clock(): void {
    if (!this.foreground) { return; } if (!this.state.paused) { this.pulse = !this.pulse; this.breathTick++; if (this.breathTick % 4 === 0) { this.breath = !this.breath; } }
    this.state = WorldEngine.tick(this.state, Date.now());
    if (Date.now() - this.saveAt > 4000) { this.save(); this.saveAt = Date.now(); }
    this.sync();
  }
  private async sync(): Promise<void> {
    if (!this.active || this.polling || !this.foreground) { return; } this.polling = true;
    try {
      const envelope = JSON.parse(await backendRequest(`${this.endpoint}/world/rooms/${this.room}/tablet`, 'POST', JSON.stringify({ status: WorldEngine.status(this.state), results: this.state.results }), 262144)) as WorldEnvelope;
      if (!this.active || !this.foreground) { return; } this.connected = envelope.connected === true;
      if (Array.isArray(envelope.commands)) { envelope.commands.forEach((command: WorldCommand) => {
        if (!this.state.handled.includes(command.id)) { console.info(`[CompanionWorld] command=${command.type} room=${this.room}`); this.state = WorldEngine.command(this.state, command, Date.now()); this.onActive(this.state.active); this.save(); if (this.state.paused || !this.state.active || this.state.ended) { this.stopVideo(); } else if (command.type === 'RESUME_SESSION' && this.state.game === 'watch' && this.state.phase === 'watch') { try { this.controller.start(); } catch { } } }
      }); }
    } catch (error) { this.connected = false; console.warn(`[CompanionWorld] compact sync paused endpoint=${this.endpoint} room=${this.room}: ${connectionError(error as Error)}`); }
    finally { this.polling = false; }
  }
  private act(action: string, value: number = 0): void { const before = this.state.phase; this.state = WorldEngine.act(this.state, action, value, Date.now()); this.onSound(this.state.phase === 'success' && before !== 'success' ? 'celebration' : ['place', 'habitat', 'collect', 'flower'].includes(action) ? 'object-placement' : 'tap'); this.save(); this.sync(); }
  private open(game: string): void { if (this.state.ended || (this.state.sessionId && this.state.slots.length)) { return; } this.state = WorldEngine.open(this.state, game, Date.now()); this.save(); }
  private backToWorld(): void { this.stopVideo(); this.state = WorldEngine.backToWorld(this.state); this.save(); this.sync(); }
  private choosePath(game: string): void {
    const slot = this.state.slots[this.state.slotIndex];
    if (!slot || slot.category !== 'LEARN' || slot.mode !== 'INTERACTIVE' || this.state.paused || this.state.ended || this.state.attempts > 0 || this.state.progress > 0) { return; }
    WorldEngine.log(this.state, 'OBJECT_SELECTED', `path:${game}`, Date.now()); this.state = WorldEngine.open(this.state, game, Date.now()); this.save();
  }
  private next(): void { this.state = WorldEngine.next(this.state, Date.now()); this.save(); this.sync(); }
  private feedback(value: string, difficulty: boolean): void { if (difficulty) { this.state.difficultyFeedback = value; } else { this.state.feedback = value; } WorldEngine.log(this.state, 'FEEDBACK_SUBMITTED', value, Date.now()); this.save(); }
  private drop(index: number): void {
    const rocket = this.state.game === 'rocket';
    const dx = rocket ? this.worldWidth * 0.4 : this.worldWidth * (0.27 - index * 0.07);
    const dy = rocket ? this.worldHeight * (-index * 0.04) : -this.worldHeight * 0.28;
    const okay = Math.abs(this.dragX - dx) < 65 && Math.abs(this.dragY - dy) < (rocket ? Math.min(35, this.worldHeight * 0.065) : 60);
    this.dragIndex = -1; this.dragX = 0; this.dragY = 0; this.act('place', okay ? index : -1);
  }
  private sceneColor(): string { return this.state.game === 'memory' ? '#D8E8F5' : ['number', 'rocket', 'stars'].includes(this.state.game) ? '#DDE5F7' : this.state.game === 'rescue' ? '#CDEDE7' : '#DFF0D4'; }
  @Builder
  pico() {
    Column({ space: 1 }) {
      Image($rawfile('pico.svg')).width(120).height(140).objectFit(ImageFit.Contain)
        .rotate({ angle: this.state.pico === 'MOVING' ? (this.pulse ? 10 : -10) : this.state.pico === 'THINKING' ? -8 : this.state.pico === 'LOOKING' ? 9 : 0 })
        .scale({ x: this.state.pico === 'CELEBRATING' ? (this.pulse ? 1.12 : 1) : 1, y: this.pulse ? 1.02 : 1 })
        .translate({ y: ['MOVING', 'CELEBRATING'].includes(this.state.pico) && this.pulse ? -12 : 0 })
        .animation({ duration: 700, curve: Curve.EaseInOut })
      Text('Pico').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#245C59')
    }.position({ x: this.state.game === 'bridge' && ['success', 'feedback'].includes(this.state.phase) ? '72%' : '5%', y: '48%' })
      .animation({ duration: 1400, curve: Curve.EaseInOut }).accessibilityGroup(true).accessibilityText(`Pico ${this.state.pico}`).onClick(() => this.act('pico'))
  }
  @Builder
  shape(index: number, filled: boolean) {
    if (index === 0) { Circle().width(64).height(64).fill(filled ? '#70BAD5' : '#EFF6FA').stroke('#456C86').strokeWidth(4) }
    else if (index === 1) { Text('\u25B2').fontSize(70).fontColor(filled ? '#EDAC6A' : '#95AABC').width(72).height(80).textAlign(TextAlign.Center) }
    else { Rect().width(76).height(60).fill(filled ? '#85C8A7' : '#EFF6FA').stroke('#456C86').strokeWidth(4).radius(10) }
  }
  @Builder
  stones() {
    if (this.state.game === 'bridge') {
      Rect().width('60%').height('26%').fill('#83C6D9').radius(40).position({ x: '26%', y: '44%' })
      ForEach([0, 1, 2, 3, 4], (index: number) => {
        Rect().width('7%').height(48).fill(index < 5 || this.state.placed.includes(index - 5) ? '#BA9E73' : '#D7E6EB')
          .stroke('#6A7369').strokeWidth(2).radius(13).position({ x: `${20 + index * 7}%`, y: '50%' })
      })
      Image($rawfile('game-dino.svg')).width(100).height(108).objectFit(ImageFit.Contain)
        .position({ x: ['success', 'feedback'].includes(this.state.phase) ? '78%' : '16%', y: '30%' }).animation({ duration: 1700, curve: Curve.EaseInOut })
    } else { Image($rawfile('game-rocket.svg')).width(210).height(260).objectFit(ImageFit.Contain).position({ x: '56%', y: this.state.phase === 'success' ? '-45%' : '16%' }).animation({ duration: 1800, curve: Curve.EaseInOut }) }
    ForEach([0, 1, 2], (index: number) => {
      if (!this.state.placed.includes(index)) {
        Stack() { if (this.state.game === 'bridge') { Rect().width(76).height(48).fill('#C4AA83').stroke(['#418BD1', '#D6A752', '#75A674'][index]).strokeWidth(3).radius(16) } else { this.shape(index, true) } }
          .width(80).height(80).position({ x: this.state.game === 'bridge' ? `${28 + index * 16}%` : '25%', y: this.state.game === 'bridge' ? '78%' : `${25 + index * 20}%` })
          .translate({ x: this.dragIndex === index ? this.dragX : 0, y: this.dragIndex === index ? this.dragY : 0 })
          .zIndex(5).id(this.state.game === 'bridge' ? `Loose stone ${index + 1}` : `Rocket piece ${index + 1}`).accessibilityGroup(true).accessibilityText(this.state.game === 'bridge' ? `Loose stone ${index + 1}` : `Rocket piece ${index + 1}`)
          .gesture(PanGesture().onActionStart(() => { if (this.state.phase !== 'input' || this.state.paused) { return; } this.dragIndex = index; this.state.pico = 'LOOKING'; WorldEngine.log(this.state, 'OBJECT_DRAG_STARTED', `${index}`, Date.now()); })
            .onActionUpdate((event: GestureEvent) => { if (this.dragIndex === index) { this.dragX = event.offsetX; this.dragY = event.offsetY; } })
            .onActionEnd(() => { if (this.dragIndex === index) { this.drop(index); } }))
      }
      Stack() { if (this.state.game === 'bridge') { Rect().width(78).height(52).fill(this.state.placed.includes(index) ? '#BA9E73' : '#F0EEE0').stroke(['#418BD1', '#D6A752', '#75A674'][index]).strokeWidth(3).radius(16) } else { this.shape(index, this.state.placed.includes(index)) } }
        .width(80).height(80).position({ x: this.state.game === 'bridge' ? `${55 + index * 9}%` : '65%', y: this.state.game === 'bridge' ? '50%' : `${25 + index * 16}%` })
        .id(`Drop target ${index + 1}`).accessibilityGroup(true).accessibilityText(`Drop target ${index + 1}`)
    })
  }
  @Builder
  memory() {
    Image($rawfile('game-robot.svg')).width(210).height(210).objectFit(ImageFit.Contain).position({ x: '62%', y: '20%' })
      .scale({ x: this.state.phase === 'success' && this.pulse ? 1.08 : 1, y: 1 }).animation({ duration: 800 })
    ForEach([0, 1, 2, 3], (index: number) => {
      Column() { Circle().width(100).height(100).fill(['#4D9BDE', '#EA8B89', '#E4C454', '#83C5A7'][index]).stroke(this.state.flash === index || this.state.phase === 'success' ? '#FFFFFF' : '#4D6775').strokeWidth(this.state.flash === index || this.state.phase === 'success' ? 12 : 4)
        Text(['Blue panel', 'Red panel', 'Yellow panel', 'Green panel'][index]).fontSize(17).fontColor('#294658')
      }.position({ x: `${28 + index % 2 * 19}%`, y: `${22 + Math.floor(index / 2) * 36}%` })
        .opacity(this.state.phase === 'preview' && this.state.flash !== index ? 0.55 : 1).scale({ x: this.state.flash === index ? 1.1 : 1, y: this.state.flash === index ? 1.1 : 1 }).animation({ duration: 180 })
        .enabled(this.state.phase === 'input' && !this.state.paused).accessibilityGroup(true).accessibilityText(['Blue panel', 'Red panel', 'Yellow panel', 'Green panel'][index]).onClick(() => this.act('panel', index))
    })
    Text(this.state.phase === 'preview' ? 'Watch the lights' : this.state.phase === 'success' ? 'Robot powered up!' : `${this.state.progress} / ${this.state.sequence.length} lights restored`)
      .fontSize(23).fontColor('#294658').position({ x: '28%', y: '8%' })
  }
  @Builder
  rescue() {
    Column() { Text('Land meadow').fontSize(24).fontColor('#34553D') }.width('35%').height('42%').backgroundColor('#9BCB7B').borderRadius(50).position({ x: '24%', y: '48%' })
      .id('Land habitat').accessibilityGroup(true).accessibilityText('Land habitat').onClick(() => this.act('habitat', 0))
    Column() { Text('Water cove').fontSize(24).fontColor('#315E79') }.width('35%').height('42%').backgroundColor('#83CBDD').borderRadius(50).position({ x: '62%', y: '48%' })
      .id('Water habitat').accessibilityGroup(true).accessibilityText('Water habitat').onClick(() => this.act('habitat', 1))
    ForEach([0, 1, 2], (index: number) => {
      Image(index === 1 ? $rawfile('game-lion.svg') : $rawfile('game-dolphin.svg')).width(112).height(112).objectFit(ImageFit.Contain)
        .position({ x: this.state.placed.includes(index) ? (index === 1 ? '37%' : `${72 + index * 5}%`) : `${28 + index * 23}%`, y: this.state.placed.includes(index) ? '64%' : '14%' })
        .scale({ x: this.state.selected === index ? 1.18 : 1, y: this.state.selected === index ? 1.18 : 1 }).animation({ duration: 850, curve: Curve.EaseInOut })
        .hitTestBehavior(this.state.placed.includes(index) ? HitTestMode.None : HitTestMode.Default).id(index === 1 ? 'Select lion' : index === 0 ? 'Select dolphin' : 'Select whale').accessibilityText(index === 1 ? 'Select lion' : index === 0 ? 'Select dolphin' : 'Select whale').onClick(() => this.act('select', index))
    })
  }
  @Builder
  collect() {
    ForEach([0, 1, 2, 3, 4, 5], (index: number) => {
      if (!this.state.placed.includes(index)) {
        Image($rawfile(`world-${index < (this.state.game === 'number' ? 4 : 5) ? 'blue' : 'amber'}-${this.state.game === 'number' ? 'crystal' : 'star'}.svg`)).objectFit(ImageFit.Contain)
          .width(90).height(95).position({ x: `${27 + index % 3 * 23}%`, y: `${18 + Math.floor(index / 3) * 36}%` })
          .scale({ x: this.pulse ? 1.06 : 1, y: this.pulse ? 1.06 : 1 }).animation({ duration: 1000 })
          .id(`${index < (this.state.game === 'number' ? 4 : 5) ? 'Blue' : 'Amber'} ${this.state.game === 'number' ? 'crystal' : 'star'} ${index + 1}`).accessibilityText(`${index < (this.state.game === 'number' ? 4 : 5) ? 'Blue' : 'Amber'} ${this.state.game === 'number' ? 'crystal' : 'star'} ${index + 1}`).onClick(() => this.act('collect', index))
      }
    })
    Rect().width(90).height(140).fill(this.state.game === 'stars' && this.state.phase === 'success' ? '#F4DA85' : '#8AA082').radius(24).position({ x: '85%', y: '60%' })
      .rotate({ angle: this.state.game === 'stars' && this.state.phase === 'success' ? 65 : 0 }).animation({ duration: 1000 })
    Text(`${this.state.progress} collected`).fontSize(24).fontColor('#345C71').position({ x: '40%', y: '80%' })
  }
  @Builder
  garden() {
    ForEach([0, 1, 2, 3, 4, 8, 9, 10, 11], (index: number) => {
      Text(this.state.flowers.includes(index) ? '\u273F' : '+').fontSize(this.state.flowers.includes(index) ? 60 : 28).fontColor(this.state.flowers.includes(index) ? this.state.color : '#7A9B71')
        .width(65).height(70).textAlign(TextAlign.Center).position({ x: `${26 + index % 4 * 17}%`, y: `${15 + Math.floor(index / 4) * 24}%` })
        .id(`Garden spot ${index + 1}`).accessibilityText(`Garden spot ${index + 1}`).onClick(() => this.act('flower', index))
    })
    Row({ space: 12 }) { ForEach(['#F4B860', '#D596C3', '#6BAECC'], (color: string) => { Circle().width(48).height(48).fill(color).stroke('#FFFFFF').strokeWidth(3).onClick(() => { this.state.color = color; }) }) }.position({ x: '35%', y: '86%' })
  }
  @Builder
  hub() {
    ForEach(WORLD_GAMES, (game: string, index: number) => {
      Column({ space: 2 }) {
        Image(index === 4 ? $rawfile('pico.svg') : index === 5 ? $rawfile('world-energy.svg') : index === 7 ? $rawfile('world-flower.svg') : index === 8 ? $rawfile('world-cloud.svg') : index === 9 ? $rawfile('world-book.svg') : index === 1 ? $rawfile('game-robot.svg') : index === 2 ? $rawfile('game-dolphin.svg') : index === 6 ? $rawfile('game-rocket.svg') : index === 0 ? $rawfile('game-dino.svg') : $rawfile('game-star.svg')).width(64).height(64).objectFit(ImageFit.Contain)
        Text(worldTitle(game)).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#284D4B').maxLines(2).textAlign(TextAlign.Center)
      }.width('17%').position({ x: `${23 + index % 5 * 15}%`, y: `${17 + Math.floor(index / 5) * 48}%` }).onClick(() => this.open(game))
        .accessibilityGroup(true).accessibilityText(worldTitle(game))
    })
  }
  @Builder
  scene() {
    Stack({ alignContent: Alignment.TopStart }) {
      Rect().width('100%').height('100%').fill(this.sceneColor())
      Rect().width('100%').height('27%').fill('#ACC88E').radius(90).position({ x: 0, y: '75%' })
      Image($rawfile('world-cloud.svg')).width(120).height(95).objectFit(ImageFit.Contain).position({ x: this.pulse ? '12%' : '10%', y: '1%' }).animation({ duration: 1800, curve: Curve.EaseInOut })
      Image($rawfile('world-cloud.svg')).width(95).height(80).objectFit(ImageFit.Contain).position({ x: this.pulse ? '79%' : '81%', y: '4%' }).animation({ duration: 1800, curve: Curve.EaseInOut })
      if (this.state.phase === 'hub') { Image($rawfile('world-map.svg')).width('100%').height('100%').objectFit(ImageFit.Fill); this.hub() }
      else if (['bridge', 'rocket'].includes(this.state.game)) { this.stones() }
      else if (this.state.game === 'memory') { this.memory() }
      else if (this.state.game === 'rescue') { this.rescue() }
      else if (['stars', 'number'].includes(this.state.game) && !['movement', 'confirm', 'success', 'feedback'].includes(this.state.phase)) { this.collect() }
      else if (this.state.game === 'garden') { this.garden() }
      else if (this.state.game === 'calm') {
        Image($rawfile('world-cloud.svg')).width(260).height(230).objectFit(ImageFit.Contain).position({ x: '40%', y: '20%' }).scale({ x: this.breath ? 1.12 : 0.9, y: this.breath ? 1.12 : 0.9 }).animation({ duration: 4000, curve: Curve.EaseInOut })
          .id('Breathing cloud').accessibilityText('Breathing cloud').onClick(() => this.act('cloud'))
        Text('Easy, comfortable breaths. No holding.').fontSize(24).fontColor('#47615A').position({ x: '28%', y: '73%' })
      } else if (['copy', 'number'].includes(this.state.game)) {
        Image($rawfile('pico.svg')).width(215).height(245).objectFit(ImageFit.Contain).position({ x: '47%', y: '18%' })
          .rotate({ angle: this.state.phase === 'movement' ? (this.pulse ? 12 : -12) : 0 }).translate({ y: this.pulse && this.state.phase === 'movement' ? -15 : 0 }).animation({ duration: 650 })
        Text(this.state.phase === 'movement' ? `${this.state.remaining} seconds | Tiny steps or seated arm moves` : 'Thank you for moving with Pico. Rest whenever you need.').fontSize(24).fontColor('#345C59').position({ x: '28%', y: '77%' })
      } else if (this.state.game === 'watch' && this.state.phase === 'watch') {
        Video({ src: this.frame.content.uri !== '' ? this.frame.content.uri : this.state.slots[this.state.slotIndex]?.category === 'CALM' ? $rawfile('fallback.mp4') : $rawfile('counting.mp4'), controller: this.controller }).width('72%').height('90%').position({ x: '25%', y: '4%' })
          .controls(true).autoPlay(true).loop(false).muted(true).objectFit(ImageFit.Contain)
          .onStart(() => { if (!this.videoPlaying) { WorldEngine.log(this.state, 'VIDEO_STARTED', '', Date.now()); this.videoPlaying = true; console.info('[CompanionWorld] native storybook playback started'); } })
          .onFinish(() => { WorldEngine.log(this.state, 'VIDEO_COMPLETED', '', Date.now()); this.videoPlaying = false; this.act('done'); })
          .onError(() => { this.state.message = 'This story cannot play. You can return to the world or try Built-in on Phone.'; })
      }
      if (this.state.game === 'watch' && this.state.phase !== 'watch') { Image($rawfile('world-book.svg')).width(180).height(200).position({ x: '48%', y: '30%' }) }
      this.pico()
      Image($rawfile('world-backpack.svg')).width(48).height(50).objectFit(ImageFit.Contain).position({ x: '6%', y: '14%' }).accessibilityText('Pico backpack').onClick(() => this.act('ambient', 2))
      Image($rawfile('world-plant.svg')).width(52).height(58).objectFit(ImageFit.Contain).position({ x: '12%', y: '85%' }).accessibilityText('Pico plant').onClick(() => this.act('ambient', 1))
      Circle().width(35).height(35).fill(this.pulse ? '#FFE7A8' : '#F8D58B').position({ x: '4%', y: '34%' }).accessibilityText('Pico lamp').onClick(() => this.act('ambient', 0))
      ForEach([0, 1, 2, 3, 4].slice(0, Math.min(this.state.decorations, 5)), (index: number) => { Image($rawfile('world-flower.svg')).width(50).height(60).position({ x: `${20 + index * 14}%`, y: '84%' }) })
      if (this.state.decorations > 0) { Text(`${this.state.decorations} garden gifts`).fontSize(20).fontColor('#386946').position({ x: '5%', y: '2%' }) }
      if (this.state.paused) { Text('Adventure paused').fontSize(38).fontColor('#FFFFFF').padding(28).backgroundColor('#C0345160').borderRadius(20).position({ x: '30%', y: '40%' }) }
      if (this.state.phase === 'ending') { Column({ space: 16 }) { Text(this.state.message).fontSize(30).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
        Text('Your world will be here next time. Missed days never remove progress.').fontSize(20).textAlign(TextAlign.Center)
        Button('Back to World').fontSize(22).fontWeight(FontWeight.Bold).height(56).padding({ left: 32, right: 32 }).backgroundColor('#386946').fontColor('#FFFFFF').onClick(() => this.backToWorld())
      }.width('65%').padding(24).backgroundColor('#F8F5D9').borderRadius(30).position({ x: '27%', y: '23%' }) }
    }.width('100%').layoutWeight(1).clip(true).borderRadius(28)
      .onAreaChange((oldArea: Area, area: Area) => { this.worldWidth = Number(area.width); this.worldHeight = Number(area.height); })
  }
  build() {
    if (this.state.active) {
      Column({ space: 10 }) {
        Row() { Text(worldName(this.state.game)).fontSize(26).fontWeight(FontWeight.Bold).fontColor('#284D4B').layoutWeight(1)
          Text(this.connected ? 'Parent connected' : 'Parent connection paused').fontSize(15).fontColor('#45695C')
          Text(`${this.state.results.filter((r: WorldResult) => r.completed).length} discoveries`).fontSize(16).fontColor('#45695C').margin({ left: 18 })
        }.width('100%')
        Text(this.state.phase === 'ending' ? 'A happy ending' : this.state.message).fontSize(21).fontColor('#36584A').maxLines(2).height(52).width('100%')
        if (this.state.daily && !this.state.ended) { Text('Today: Help Dino Get Home').fontSize(16).fontColor('#536F59') }
        if (this.state.slots[this.state.slotIndex]?.category === 'LEARN' && this.state.slots[this.state.slotIndex]?.mode === 'INTERACTIVE' && this.state.attempts === 0 && this.state.progress === 0 && !this.state.ended) {
          Row({ space: 15 }) { Text('Choose a path').fontSize(16).fontColor('#47615A'); ForEach(['bridge', 'memory', 'rocket', 'rescue'], (game: string) => { Button(worldName(game)).height(42).fontSize(15).backgroundColor('#DDE7CD').fontColor('#36584A').onClick(() => this.choosePath(game)) }) }
        }
        this.scene()
        if (['success', 'feedback'].includes(this.state.phase)) {
          Row({ space: 10 }) {
            ForEach(['liked', 'okay', 'disliked'], (value: string, index: number) => { Button(['Loved it', 'Okay', 'Not for me'][index]).height(46).fontSize(17).backgroundColor(this.state.feedback === value ? '#386F5C' : '#ECF1DC').fontColor(this.state.feedback === value ? '#FFFFFF' : '#36584A').onClick(() => this.feedback(value, false)) })
            ForEach(['too easy', 'just right', 'too hard'], (value: string, index: number) => { Button(['Easy', 'Just right', 'Tricky'][index]).height(46).fontSize(17).backgroundColor(this.state.difficultyFeedback === value ? '#386F5C' : '#ECF1DC').fontColor(this.state.difficultyFeedback === value ? '#FFFFFF' : '#36584A').onClick(() => this.feedback(value, true)) })
            Button('Continue adventure').height(50).onClick(() => this.next())
          }
        } else if (this.state.phase !== 'ending' && this.state.phase !== 'hub') {
          Row({ space: 15 }) {
            if (this.state.phase === 'retry') { Button('Try again').height(52).onClick(() => this.act('retry')) }
            if (['movement', 'confirm'].includes(this.state.phase)) { Button('More time').height(52).onClick(() => this.act('more')); Button('Done').height(52).enabled(this.state.phase === 'confirm').onClick(() => this.act('done')) }
            if (['garden', 'calm', 'watch'].includes(this.state.game)) { Button(this.state.game === 'watch' ? 'Return to world' : 'Done exploring').height(52).enabled(this.state.game !== 'garden' || this.state.flowers.length > 0).onClick(() => { this.stopVideo(); this.act(this.state.game === 'watch' ? 'skip' : 'done'); }) }
            Button('Skip').height(52).backgroundColor('#E6EBCF').fontColor('#36584A').onClick(() => this.act('skip'))
          }
        }
        if (this.state.paused) { Button('Resume saved adventure').height(46).onClick(() => { if (!this.connected) { this.state.paused = false; this.state.lastTick = Date.now(); this.save(); } }).enabled(!this.connected) }
        if (this.storageError) { Text(this.storageError).fontSize(15).fontColor('#8A452C') }
        Text('Adult nearby. Gentle, comfortable movement only. Take a break anytime.').fontSize(14).fontColor('#45695C')
      }.width('100%').height('100%').padding(18).backgroundColor('#F5F3DF')
    } else {
      Button('Open Pico world locally').position({ x: 28, y: 65 }).onClick(() => { this.state.active = true; this.state.paused = false; this.state.ended = false; this.state.sessionId = ''; this.state.slots = []; this.state.phase = 'hub'; this.state.game = ''; this.onActive(true); this.save(); })
    }
  }
}
