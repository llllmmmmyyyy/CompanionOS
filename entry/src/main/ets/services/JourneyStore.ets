import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { JourneyState, parseJourney } from '../model/AdventureJourney';
export class JourneyStore {
  private store: preferences.Preferences;
  constructor(context: common.Context) { this.store = preferences.getPreferencesSync(context, { name: 'companion_journey' }); }
  load(): JourneyState {
    const bank = this.store.getSync('active', 'a') as string; const count = this.store.getSync(`${bank}-count`, 0) as number;
    if (!['a', 'b'].includes(bank) || !Number.isInteger(count) || count < 0 || count > 100) { return new JourneyState(); }
    let raw = ''; for (let i = 0; i < count; i++) { raw += this.store.getSync(`${bank}-${i}`, '') as string; } return parseJourney(raw);
  }
  save(data: JourneyState): void {
    const raw = JSON.stringify(data); const size = Math.min(2048, Math.floor(preferences.MAX_VALUE_LENGTH / 4));
    const count = Math.ceil(raw.length / size); if (count > 100) { throw new Error('Journey is too large'); }
    const bank = this.store.getSync('active', 'b') === 'a' ? 'b' : 'a';
    for (let i = 0; i < count; i++) { this.store.putSync(`${bank}-${i}`, raw.slice(i * size, (i + 1) * size)); }
    this.store.putSync(`${bank}-count`, count); this.store.flushSync(); this.store.putSync('active', bank); this.store.flushSync();
  }
}
