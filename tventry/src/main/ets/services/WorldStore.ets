import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { WorldState, parseWorld } from '@companion/protocol';
export class WorldStore {
  private store: preferences.Preferences;
  constructor(context: common.Context) { this.store = preferences.getPreferencesSync(context, { name: 'companion_child_world' }); }
  load(): WorldState { const bank = this.store.getSync('active', '') as string; const count = this.store.getSync(`${bank}-count`, 0) as number;
    if (!['a', 'b'].includes(bank) || !Number.isInteger(count) || count < 1 || count > 1000) { return new WorldState(); }
    let raw = ''; for (let i = 0; i < count; i++) { raw += this.store.getSync(`${bank}-${i}`, '') as string; } return parseWorld(raw);
  }
  save(state: WorldState): void { const raw = JSON.stringify(state); const bank = this.store.getSync('active', 'b') === 'a' ? 'b' : 'a';
    const count = Math.ceil(raw.length / 2048); if (count > 1000) { throw new Error('World journal exceeds local limit'); }
    for (let i = 0; i < count; i++) { this.store.putSync(`${bank}-${i}`, raw.slice(i * 2048, (i + 1) * 2048)); }
    this.store.putSync(`${bank}-count`, count); this.store.flushSync(); this.store.putSync('active', bank); this.store.flushSync();
  }
}
