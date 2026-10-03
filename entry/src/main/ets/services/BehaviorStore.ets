import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BehaviorData, parseBehavior } from '../model/BehaviorInsightEngine';
export class BehaviorStore {
  private store: preferences.Preferences;
  constructor(context: common.Context) { this.store = preferences.getPreferencesSync(context, { name: 'companion_behavior' }); }
  load(): BehaviorData {
    const bank = this.store.getSync('active', '') as string;
    if (!['a', 'b'].includes(bank)) { return parseBehavior(this.store.getSync('events', '') as string); }
    const count = this.store.getSync(`${bank}-count`, 0) as number;
    if (!Number.isInteger(count) || count < 1 || count > 3000) { return new BehaviorData(); }
    let raw = '';
    for (let index = 0; index < count; index++) { raw += this.store.getSync(`${bank}-${index}`, '') as string; }
    return parseBehavior(raw);
  }
  save(data: BehaviorData): void {
    const raw = JSON.stringify(data);
    // Keep each value below the installed SDK's limit, including multi-byte characters.
    const size = Math.max(256, Math.min(2048, Math.floor(preferences.MAX_VALUE_LENGTH / 4)));
    const bank = this.store.getSync('active', 'b') === 'a' ? 'b' : 'a';
    const count = Math.ceil(raw.length / size);
    if (count > 3000) { throw new Error('Interaction history is too large'); }
    for (let index = 0; index < count; index++) { this.store.putSync(`${bank}-${index}`, raw.slice(index * size, (index + 1) * size)); }
    this.store.putSync(`${bank}-count`, count); this.store.flushSync();
    // Publish the complete bank only after all its chunks have been flushed.
    this.store.putSync('active', bank); this.store.flushSync();
  }
}
