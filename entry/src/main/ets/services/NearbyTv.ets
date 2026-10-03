import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';

export class NearbyTv {
  static async search(context: common.UIAbilityContext): Promise<string> {
    try {
      const permission = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context,
        ['ohos.permission.DISTRIBUTED_DATASYNC']);
      if (permission.authResults.some((result: number) => result !== 0)) {
        return 'Nearby-device permission denied. Demo TV Mode is available.';
      }
      const manager = distributedDeviceManager.createDeviceManager('com.example.companionos');
      try {
        const devices = manager.getAvailableDeviceListSync();
        return devices.length ? `${devices.length} authorized device(s) visible. A compatible CompanionOS TV receiver is still required. Use Demo TV Mode.` :
          'No authorized distributed devices found. Demo TV Mode is available.';
      } finally { distributedDeviceManager.releaseDeviceManager(manager); }
    } catch {
      return 'Distributed discovery unavailable or permission denied. Demo TV Mode is available.';
    }
  }
}
