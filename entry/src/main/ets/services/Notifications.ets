import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';

export class Notifications {
  static async enable(context: common.UIAbilityContext): Promise<string> {
    try {
      if (!await notificationManager.isNotificationEnabled()) {
        await notificationManager.requestEnableNotification(context);
      }
      return await notificationManager.isNotificationEnabled() ? 'Notifications enabled.' :
        'Notifications were not enabled. You can still complete activities in the app.';
    } catch {
      return 'Notification permission was denied or unavailable. Activities still work.';
    }
  }

  static async publish(title: string, stillActive: () => boolean): Promise<string> {
    try {
      if (!await notificationManager.isNotificationEnabled()) {
        return 'Time is up. Notifications are disabled; confirm completion in the app.';
      }
      if (!stillActive()) { return ''; }
      await notificationManager.publish({
        id: 1001,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: { title: 'CompanionOS: time is up', text: `${title}: finish together, then ask your parent to confirm.` }
        }
      });
      return 'Time is up. A system notification was submitted. Parent confirmation is still required.';
    } catch {
      return 'Time is up. The notification could not be sent; you can still confirm completion here.';
    }
  }
}
