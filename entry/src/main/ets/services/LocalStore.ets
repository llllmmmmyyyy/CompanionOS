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
    if (raw.length > preferences.MAX_VALUE_LENGTH) { throw new Error('Local data is too large'); }
    try {
      this.store.putSync('mvp', raw);
      await this.store.flush();
    } catch { throw new Error('Local storage could not be saved'); }
  }
}
