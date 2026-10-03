import { BalanceRules, validRules } from '../model/SessionBalanceEngine';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { WorldResult, validWorldResult } from '@companion/protocol';
export class ParentWorldData { customRules: BalanceRules = new BalanceRules(); version: number = 1; results: WorldResult[] = []; minutes: number = 30; memorySignals: number = 2; preset: string = 'Balanced'; }
export class ParentWorldStore {
  private store: preferences.Preferences;
  constructor(context: common.Context) { this.store = preferences.getPreferencesSync(context, { name: 'companion_parent_world' }); }
  load(): ParentWorldData { try { const bank = this.store.getSync('active', '') as string; const count = this.store.getSync(`${bank}-count`, 0) as number;
    if (!['a', 'b'].includes(bank) || !Number.isInteger(count) || count < 1 || count > 1000) { return new ParentWorldData(); }
    let raw = ''; for (let i = 0; i < count; i++) { raw += this.store.getSync(`${bank}-${i}`, '') as string; } const data = JSON.parse(raw) as ParentWorldData;
    if (!validRules(data.customRules)) { data.customRules = new BalanceRules(); }
    if (data.memorySignals === undefined) { data.memorySignals = 2; }
    if (![2, 3, 4, 5].includes(data.memorySignals) || data.version !== 1 || !Array.isArray(data.results) || data.results.length > 300 || !data.results.every((r: WorldResult) => validWorldResult(r)) || ![15, 30, 45, 60].includes(data.minutes) || !['Balanced', 'More Learning', 'More Movement', 'Low Energy', 'Custom'].includes(data.preset)) { return new ParentWorldData(); }
    return data;
  } catch { return new ParentWorldData(); } }
  save(data: ParentWorldData): void { const raw = JSON.stringify(data); const bank = this.store.getSync('active', 'b') === 'a' ? 'b' : 'a'; const count = Math.ceil(raw.length / 2048);
    if (count > 1000) { throw new Error('Parent journal limit'); } for (let i = 0; i < count; i++) { this.store.putSync(`${bank}-${i}`, raw.slice(i * 2048, (i + 1) * 2048)); }
    this.store.putSync(`${bank}-count`, count); this.store.flushSync(); this.store.putSync('active', bank); this.store.flushSync(); }
}
