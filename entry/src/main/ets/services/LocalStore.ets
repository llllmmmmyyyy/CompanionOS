import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Completion, Snapshot, dayKey, parseSnapshot } from '../model/Companion';

class LegacyRecord {
  id: string = '';
  title: string = '';
  animal: string = '';
  completedAt: number = 0;
}

export class LocalStore {
  private store: preferences.Preferences;
  recovered: boolean = false;

  constructor(context: common.Context) {
    this.store = preferences.getPreferencesSync(context, { name: 'companion_history' });
  }

  load(): Snapshot {
    let raw: string = '';
    try { raw = this.store.getSync('mvp', '') as string; }
    catch { throw new Error('Local storage could not be read'); }
    if (raw === '' && ['a', 'b'].includes(this.store.getSync('active', '') as string)) {
      const bank = this.store.getSync('active', '') as string;
      const count = this.store.getSync(`${bank}-count`, 0) as number;
      if (!Number.isInteger(count) || count < 1 || count > 100) { this.recovered = true; return new Snapshot(); }
      for (let index = 0; index < count; index++) { raw += this.store.getSync(`${bank}-${index}`, '') as string; }
    }
    if (raw !== '') {
      const data = parseSnapshot(raw);
      this.recovered = data === undefined;
      return data ? data : new Snapshot();
    }
    // Preserve valid completions made by the original offline homepage.
    const data = new Snapshot();
    try {
      const legacy = JSON.parse(this.store.getSync('records', '[]') as string) as LegacyRecord[];
      if (!Array.isArray(legacy)) { this.recovered = true; return data; }
      const valid = legacy.filter((item: LegacyRecord) => item !== null && typeof item.id === 'string' && item.id.length <= 100 &&
        typeof item.title === 'string' && item.title.length <= 80 && Number.isFinite(item.completedAt) && item.completedAt > 0);
      data.records = valid.slice(0, 20).map((item: LegacyRecord) => {
        const record = new Completion();
        record.id = item.id;
        record.title = item.title;
        record.completedAt = item.completedAt;
        return record;
      });
      data.countDay = dayKey(Date.now());
      const oldDay = this.store.getSync('countDay', '') as string;
      const oldCount = this.store.getSync('todayCount', 0) as number;
      const recentCount = valid.filter((item: LegacyRecord) => dayKey(item.completedAt) === data.countDay).length;
      data.todayCount = oldDay === data.countDay && Number.isSafeInteger(oldCount) && oldCount >= 0 ?
        Math.max(oldCount, recentCount) : recentCount;
      data.total = Math.max(valid.length, data.todayCount);
      this.recovered = legacy.length !== valid.length;
    } catch {
      this.recovered = true;
    }
    return data;
  }

  async save(data: Snapshot): Promise<void> {
    const raw = JSON.stringify(data);
    const size = Math.min(2048, Math.floor(preferences.MAX_VALUE_LENGTH / 4));
    const count = Math.ceil(raw.length / size);
    if (count > 100) { throw new Error('Local data is too large'); }
    const bank = this.store.getSync('active', 'b') === 'a' ? 'b' : 'a';
    try {
      for (let index = 0; index < count; index++) { this.store.putSync(`${bank}-${index}`, raw.slice(index * size, (index + 1) * size)); }
      this.store.putSync(`${bank}-count`, count);
      await this.store.flush();
      this.store.putSync('active', bank); this.store.putSync('mvp', '');
      await this.store.flush();
    } catch { throw new Error('Local storage could not be saved'); }
  }
}
