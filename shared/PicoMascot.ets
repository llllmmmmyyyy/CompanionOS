// Layered from the existing Pico SVG: independently articulated limbs and face.
@Component
export struct PicoMascot {
  @Prop @Watch('configure') action: string = 'idle';
  @Prop @Watch('configure') cue: number = 0;
  @Prop @Watch('configure') reducedMotion: boolean = false;
  @Prop @Watch('configure') active: boolean = true;
  @Prop mascotSize: number = 72;
  @State beat: boolean = false;
  @State blink: boolean = false;
  @State performing: boolean = false;
  private timer: number = -1;
  private ticks: number = 0;
  private started: number = 0;
  aboutToAppear(): void { this.configure(); }
  aboutToDisappear(): void { clearInterval(this.timer); this.timer = -1; }
  private configure(): void {
    clearInterval(this.timer); this.timer = -1; this.started = Date.now(); this.ticks = 0;
    this.beat = false; this.blink = false; this.performing = this.action !== 'idle';
    if (this.reducedMotion || !this.active) { this.performing = false; return; }
    console.info(`[PicoMotion] action=${this.action} cue=${this.cue}`);
    this.timer = setInterval(() => {
      this.ticks++;
      this.performing = this.action !== 'idle' && Date.now() - this.started < 900;
      this.beat = this.performing ? !this.beat : Math.floor(this.ticks / 4) % 2 === 1;
      this.blink = this.ticks % 17 === 0 || (this.action === 'blink' && this.performing && this.beat);
    }, 300);
  }
  private moving(): boolean { return this.performing && ['walk', 'run', 'pull'].includes(this.action); }
  private arm(left: boolean): number {
    if (!this.performing) { return this.beat && this.active && !this.reducedMotion ? 2 : 0; }
    if (this.action === 'wave' && !left) { return this.beat ? -70 : -110; }
    if (this.action === 'point' && !left) { return -65; }
    if (this.action === 'celebrate') { return left ? (this.beat ? 65 : 85) : (this.beat ? -65 : -85); }
    if (this.action === 'pull') { return left ? -65 : 65; }
    if (this.action === 'reveal') { return left ? 30 : (this.beat ? -45 : -70); }
    return this.moving() ? (left === this.beat ? 22 : -22) : 0;
  }
  private hop(): number { return this.performing && ['hop', 'bounce', 'celebrate', 'run'].includes(this.action) && this.beat ? -14 : this.beat && this.active && !this.reducedMotion ? -2 : 0; }
  build() {
    Stack() {
      Stack() {
        Image($rawfile('pico-body.svg')).width(180).height(210).objectFit(ImageFit.Contain)
          .scale({ x: this.active && !this.reducedMotion && this.beat ? 1.015 : 1, y: this.active && !this.reducedMotion && this.beat ? 1.025 : 1 })
          .animation({ duration: this.reducedMotion || !this.active ? 0 : 280, curve: Curve.EaseInOut })
        Image($rawfile('pico-left-arm.svg')).width(180).height(210).rotate({ angle: this.arm(true), centerX: '18%', centerY: '59%' })
          .animation({ duration: this.reducedMotion || !this.active ? 0 : 280, curve: Curve.EaseInOut })
        Image($rawfile('pico-right-arm.svg')).width(180).height(210).rotate({ angle: this.arm(false), centerX: '82%', centerY: '59%' })
          .animation({ duration: this.reducedMotion || !this.active ? 0 : 280, curve: Curve.EaseInOut })
        Image($rawfile('pico-left-foot.svg')).width(180).height(210).translate({ y: this.moving() && this.beat ? -7 : 0 })
          .animation({ duration: this.reducedMotion || !this.active ? 0 : 280 })
        Image($rawfile('pico-right-foot.svg')).width(180).height(210).translate({ y: this.moving() && !this.beat ? -7 : 0 })
          .animation({ duration: this.reducedMotion || !this.active ? 0 : 280 })
        Image($rawfile('pico-eyes.svg')).width(180).height(210).scale({ y: this.blink ? 0.08 : 1, centerY: '42%' })
          .translate({ x: this.performing && this.action === 'point' ? 3 : 0 })
          .animation({ duration: this.reducedMotion || !this.active ? 0 : 100 })
        if (this.performing && this.action === 'eat') {
          Ellipse().width(this.beat ? 32 : 17).height(this.beat ? 24 : 10).fill('#245C59').position({ x: 75, y: 101 })
        } else { Image($rawfile('pico-smile.svg')).width(180).height(210) }
        if (this.performing && this.action === 'celebrate') {
          ForEach([0, 1, 2], (index: number) => {
            Text('✦').fontSize(22).fontColor('#E7AE55').position({ x: 18 + index * 64, y: this.beat ? 12 : 25 })
              .opacity(this.beat ? 1 : 0.35)
          })
        }
      }.width(180).height(210).translate({ x: this.moving() ? (this.beat ? 7 : -7) : 0, y: this.hop() })
        .rotate({ angle: this.performing && this.action === 'gentle-error' ? (this.beat ? -6 : 6) : this.performing && this.action === 'pull' ? -12 : 0 })
        .animation({ duration: this.reducedMotion || !this.active ? 0 : 280, curve: Curve.EaseInOut })
        .scale({ x: this.mascotSize / 180, y: this.mascotSize / 180 })
    }.width(this.mascotSize).height(this.mascotSize * 210 / 180)
      .accessibilityGroup(true).accessibilityText(`Pico ${this.active ? this.action : 'resting'}`)
  }
}
