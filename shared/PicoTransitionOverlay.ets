import { PicoMascot } from './PicoMascot';
import { PicoTransitionFrame } from './PicoAnimationController';
@Component
export struct PicoTransitionOverlay {
  @Prop frame: PicoTransitionFrame = new PicoTransitionFrame();
  @Prop reducedMotion: boolean = false;
  build() {
    if (this.frame.visible && !this.reducedMotion) {
      Row({ space: 8 }) {
        PicoMascot({ action: this.frame.action, mascotSize: 82, active: true })
        Text(this.frame.stage === 'out' ? 'This way...' : 'Here we are.').fontSize(14).fontColor('#335E49')
      }.padding(10).backgroundColor('#F2F8EA').borderRadius(24)
        .translate({ x: this.frame.mascotX }).animation({ duration: this.frame.duration, curve: Curve.EaseInOut })
        .hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
    }
  }
}
