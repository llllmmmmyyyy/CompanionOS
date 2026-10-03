import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { WorkState, parseWork } from '../model/WorkSession';

export class WorkStore {
  private store: preferences.Preferences;
  constructor(context: common.Context) { this.store = preferences.getPreferencesSync(context, { name: 'companion_work' }); }
  load(): WorkState { return parseWork(this.store.getSync('state', '') as string); }
  save(state: WorkState): void {
    this.store.putSync('state', JSON.stringify(state)); this.store.flushSync();
  }
}
