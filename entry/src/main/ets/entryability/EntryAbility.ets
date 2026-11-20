import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppRepository } from '../data/AppRepository';
import { homeStore } from '../store/HomeStore';

const DOMAIN: number = 0x0000;
const TAG: string = 'QijuAbility';

/**
 * 应用入口 Ability：
 * 1) 启动时初始化 preferences 并从本地快照恢复业务数据（冷启动恢复）；
 * 2) 前台启动节拍器（环境演化 + 规则执行）；
 * 3) 切后台/销毁前强制落盘（数据不丢）。
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    const ready = AppRepository.init(this.context);
    homeStore.init();
    hilog.info(DOMAIN, TAG, 'onCreate ready=%{public}s devices=%{public}d rules=%{public}d',
      ready.toString(), homeStore.devices.length, homeStore.rules.length);
  }

  onDestroy(): void {
    homeStore.stopTicker();
    homeStore.flushNow();
    hilog.info(DOMAIN, TAG, '%{public}s', 'onDestroy, snapshot flushed');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, '%{public}s', 'loadContent succeeded');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'onWindowStageDestroy');
  }

  onForeground(): void {
    homeStore.startTicker();
    hilog.info(DOMAIN, TAG, '%{public}s', 'onForeground, ticker started');
  }

  onBackground(): void {
    homeStore.stopTicker();
    homeStore.flushNow();
    hilog.info(DOMAIN, TAG, '%{public}s', 'onBackground, ticker stopped and snapshot saved');
  }
}
