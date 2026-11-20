import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SnapshotBundle, SnapshotCodec } from './SnapshotCodec';

const DOMAIN: number = 0x0001;
const TAG: string = 'QijuRepo';
const PREF_NAME: string = 'qiju_store';
const KEY_COUNT: string = 'snap_count';
const KEY_PREFIX: string = 'snap_';

/**
 * preferences 单个 value 有 8KB 上限，因此把整份快照切成多个分片存储：
 *   snap_count = 分片数，snap_0..snap_n = 分片内容。
 * 这样即使日志积累到上百条，也不会因为超过单值上限而写入失败。
 */
const CHUNK_MAX: number = 2000;

/**
 * 持久化仓库：使用 ArkData 的 preferences 保存整个业务快照（设备、规则、日志）。
 * 采用 getPreferencesSync / putSync，保证冷启动时能同步取到数据，界面首帧即为恢复后的状态。
 */
export class AppRepository {
  private static prefs: preferences.Preferences | undefined = undefined;
  private static ready: boolean = false;

  static init(context: common.UIAbilityContext): boolean {
    try {
      AppRepository.prefs = preferences.getPreferencesSync(context, { name: PREF_NAME });
      AppRepository.ready = AppRepository.prefs !== undefined;
      hilog.info(DOMAIN, TAG, 'preferences ready=%{public}s', AppRepository.ready.toString());
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'init preferences failed: %{public}s', e.message);
      AppRepository.ready = false;
    }
    return AppRepository.ready;
  }

  static isReady(): boolean {
    return AppRepository.ready;
  }

  static load(): SnapshotBundle | undefined {
    if (!AppRepository.ready || AppRepository.prefs === undefined) {
      return undefined;
    }
    try {
      const count = AppRepository.prefs.getSync(KEY_COUNT, 0) as number;
      if (count <= 0 || count > 500) {
        return undefined;
      }
      let raw = '';
      for (let i = 0; i < count; i++) {
        const part = AppRepository.prefs.getSync(KEY_PREFIX + i.toString(), '') as string;
        raw = raw + part;
      }
      if (raw.length === 0) {
        return undefined;
      }
      hilog.info(DOMAIN, TAG, 'load snapshot chars=%{public}d chunks=%{public}d', raw.length, count);
      return SnapshotCodec.decode(raw);
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'load failed: %{public}s', e.message);
      return undefined;
    }
  }

  static save(bundle: SnapshotBundle): boolean {
    if (!AppRepository.ready || AppRepository.prefs === undefined) {
      return false;
    }
    try {
      const raw = SnapshotCodec.encode(bundle.devices, bundle.rules, bundle.logs);
      const prev = AppRepository.prefs.getSync(KEY_COUNT, 0) as number;
      let chunks = Math.ceil(raw.length / CHUNK_MAX);
      if (chunks < 1) {
        chunks = 1;
      }
      for (let i = 0; i < chunks; i++) {
        const start = i * CHUNK_MAX;
        const end = start + CHUNK_MAX > raw.length ? raw.length : start + CHUNK_MAX;
        AppRepository.prefs.putSync(KEY_PREFIX + i.toString(), raw.substring(start, end));
      }
      // 清掉上一次多出来的分片，避免残留脏数据
      for (let i = chunks; i < prev; i++) {
        AppRepository.prefs.deleteSync(KEY_PREFIX + i.toString());
      }
      AppRepository.prefs.putSync(KEY_COUNT, chunks);
      const chars = raw.length;
      AppRepository.prefs.flush().then(() => {
        hilog.info(DOMAIN, TAG, 'snapshot flushed chars=%{public}d chunks=%{public}d', chars, chunks);
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'flush failed: %{public}s', err.message);
      });
      return true;
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'save failed: %{public}s', e.message);
      return false;
    }
  }

  static clear(): void {
    if (!AppRepository.ready || AppRepository.prefs === undefined) {
      return;
    }
    try {
      const prev = AppRepository.prefs.getSync(KEY_COUNT, 0) as number;
      for (let i = 0; i < prev; i++) {
        AppRepository.prefs.deleteSync(KEY_PREFIX + i.toString());
      }
      AppRepository.prefs.putSync(KEY_COUNT, 0);
      AppRepository.prefs.flush().then(() => {
        hilog.info(DOMAIN, TAG, 'snapshot cleared');
      });
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'clear failed: %{public}s', e.message);
    }
  }
}
