import { Want } from '@kit.AbilityKit';
import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { preferences } from '@kit.ArkData';
import { LocalStore } from '../services/LocalStore';
import { Widgets, WidgetData } from '../services/Widgets';

export default class TodayFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const id = want.parameters ? want.parameters[formInfo.FormParam.IDENTITY_KEY] as string : '';
    Widgets.register(this.context, id);
    return formBindingData.createFormBindingData(this.readData());
  }

  private readData(): WidgetData {
    try {
      preferences.removePreferencesFromCacheSync(this.context, 'companion_history');
      return Widgets.data(new LocalStore(this.context).load());
    } catch { return new WidgetData(); }
  }

  onUpdateForm(formId: string): void {
    this.refresh(formId);
  }

  private async refresh(formId: string): Promise<void> {
    try { await formProvider.updateForm(formId, formBindingData.createFormBindingData(this.readData())); }
    catch { /* The desktop controls scheduling; no reliable background timing is claimed. */ }
  }

  onRemoveForm(formId: string): void { Widgets.register(this.context, formId, true); }
}
