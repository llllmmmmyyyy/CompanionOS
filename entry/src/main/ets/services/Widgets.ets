import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { formBindingData, formProvider } from '@kit.FormKit';
import { ACTIVITIES, Snapshot, countToday, dayKey } from '../model/Companion';

export class WidgetData {
  activityTitle: string = 'Penguin Walk';
  todayCount: string = '0';
  updatedDate: string = '';
}

export class Widgets {
  static data(snapshot: Snapshot): WidgetData {
    const data = new WidgetData();
    const activity = ACTIVITIES.find((item) => snapshot.settings.interests.includes(item.interest));
    data.activityTitle = activity ? activity.title : ACTIVITIES[0].title;
    data.todayCount = countToday(snapshot, Date.now()).toString();
    data.updatedDate = dayKey(Date.now());
    return data;
  }

  static ids(context: common.Context): string[] {
    try {
      preferences.removePreferencesFromCacheSync(context, 'companion_widgets');
      const store = preferences.getPreferencesSync(context, { name: 'companion_widgets' });
      const ids = JSON.parse(store.getSync('ids', '[]') as string) as string[];
      return Array.isArray(ids) ? ids.filter((id: string) => typeof id === 'string' && /^[0-9]+$/.test(id)).slice(0, 20) : [];
    } catch { return []; }
  }

  static async register(context: common.Context, id: string, remove: boolean = false): Promise<void> {
    try {
      const ids = Widgets.ids(context).filter((item: string) => item !== id);
      if (!remove && /^[0-9]+$/.test(id)) { ids.push(id); }
      const store = preferences.getPreferencesSync(context, { name: 'companion_widgets' });
      store.putSync('ids', JSON.stringify(ids.slice(-20)));
      await store.flush();
    } catch { /* A widget registration failure must not block the app. */ }
  }

  static async update(context: common.Context, data: Snapshot): Promise<void> {
    const ids = Widgets.ids(context);
    for (const id of ids) {
      try { await formProvider.updateForm(id, formBindingData.createFormBindingData(Widgets.data(data))); }
      catch { /* Unsupported or removed desktop widgets do not block activity saving. */ }
    }
  }
}
