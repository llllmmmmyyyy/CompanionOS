// Presentation choreography only. Never owns sessions, rewards or completion.
export const PICO_ACTIONS: string[] = ['idle', 'blink', 'wave', 'hop', 'bounce', 'walk', 'run', 'pull', 'eat', 'reveal', 'point', 'celebrate', 'gentle-error'];
export class PicoTransitionFrame {
  visible: boolean = false;
  action: string = 'idle';
  stage: string = 'rest';
  contentScale: number = 1;
  contentX: number = 0;
  contentOpacity: number = 1;
  mascotX: number = -110;
  duration: number = 0;
}
export class PicoAnimationController {
  private timers: number[] = [];
  private revision: number = 0;
  private pending: (() => void) | undefined = undefined;
  private emit: ((frame: PicoTransitionFrame) => void) | undefined = undefined;
  cancel(commitPending: boolean = false): void {
    this.revision++;
    this.timers.forEach((timer: number) => clearTimeout(timer)); this.timers = [];
    const commit = this.pending; this.pending = undefined;
    if (commitPending && commit) { commit(); }
    this.emit?.(new PicoTransitionFrame()); this.emit = undefined;
  }
  transition(action: string, commit: () => void, emit: (frame: PicoTransitionFrame) => void, reducedMotion: boolean = false): void {
    this.cancel();
    if (reducedMotion) { commit(); emit(new PicoTransitionFrame()); return; }
    const revision = this.revision;
    this.pending = commit; this.emit = emit;
    const enter = new PicoTransitionFrame(); enter.visible = true; enter.action = 'run'; enter.stage = 'enter'; emit(enter);
    this.later(24, revision, () => {
      const out = new PicoTransitionFrame(); out.visible = true; out.action = action; out.stage = 'out'; out.duration = 260;
      out.contentScale = action === 'eat' ? 0.08 : 0.97; out.contentX = action === 'pull' ? -320 : 0;
      out.contentOpacity = 0; out.mascotX = 0; emit(out);
    });
    this.later(290, revision, () => {
      const next = this.pending; this.pending = undefined; next?.();
      const incoming = new PicoTransitionFrame(); incoming.visible = true; incoming.action = 'reveal'; incoming.stage = 'in';
      incoming.contentOpacity = 0; incoming.contentScale = 0.96; incoming.mascotX = 0; emit(incoming);
    });
    this.later(330, revision, () => {
      const reveal = new PicoTransitionFrame(); reveal.visible = true; reveal.action = 'reveal'; reveal.stage = 'reveal'; reveal.duration = 300;
      reveal.mascotX = -10; emit(reveal);
    });
    this.later(790, revision, () => { this.timers = []; emit(new PicoTransitionFrame()); this.emit = undefined; });
  }
  private later(delay: number, revision: number, action: () => void): void {
    this.timers.push(setTimeout(() => { if (revision === this.revision) { action(); } }, delay));
  }
}
