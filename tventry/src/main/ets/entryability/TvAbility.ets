import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class TvAbility extends UIAbility {
  onWindowStageCreate(stage: window.WindowStage): void {
    stage.getMainWindow().then((main: window.Window) => {
      main.setPreferredOrientation(window.Orientation.LANDSCAPE).catch(() => {});
    }).catch(() => {});
    stage.loadContent('pages/TvHome');
  }
  onForeground(): void { AppStorage.setOrCreate('tvForeground', true); }
  onBackground(): void { AppStorage.setOrCreate('tvForeground', false); }
}
