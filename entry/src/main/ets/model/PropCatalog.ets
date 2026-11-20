import { Device } from './Device';

/** 编辑器里的"可配置属性"选项：把 设备+属性 扁平化成一条可选项目 */
export class PropOption {
  deviceId: string;
  propKey: string;
  deviceName: string;
  propLabel: string;
  unit: string;
  min: number;
  max: number;
  step: number;
  isBoolean: boolean;
  isSensor: boolean;

  constructor(deviceId: string, propKey: string, deviceName: string, propLabel: string, unit: string,
    min: number, max: number, step: number, isBoolean: boolean, isSensor: boolean) {
    this.deviceId = deviceId;
    this.propKey = propKey;
    this.deviceName = deviceName;
    this.propLabel = propLabel;
    this.unit = unit;
    this.min = min;
    this.max = max;
    this.step = step;
    this.isBoolean = isBoolean;
    this.isSensor = isSensor;
  }

  label(): string {
    return this.deviceName + ' · ' + this.propLabel;
  }

  key(): string {
    return this.deviceId + '#' + this.propKey;
  }

  format(v: number): string {
    if (this.isBoolean) {
      if (this.unit === 'lock') {
        return v >= 1 ? '已上锁' : '未上锁';
      }
      return v >= 1 ? '开' : '关';
    }
    return (Math.round(v * 10) / 10).toString() + this.unit;
  }
}

export class PropCatalog {
  /** 全部属性（含传感器），可作为条件 */
  static options(devices: Device[]): PropOption[] {
    const list: PropOption[] = [];
    for (let i = 0; i < devices.length; i++) {
      const d = devices[i];
      for (let j = 0; j < d.props.length; j++) {
        const p = d.props[j];
        list.push(new PropOption(d.id, p.key, d.name, p.label, p.unit, p.min, p.max, p.step, p.isBoolean, !d.controllable));
      }
    }
    return list;
  }

  /** 仅可写属性，可作为动作 */
  static actionOptions(devices: Device[]): PropOption[] {
    const list: PropOption[] = [];
    for (let i = 0; i < devices.length; i++) {
      const d = devices[i];
      if (!d.controllable) {
        continue;
      }
      for (let j = 0; j < d.props.length; j++) {
        const p = d.props[j];
        list.push(new PropOption(d.id, p.key, d.name, p.label, p.unit, p.min, p.max, p.step, p.isBoolean, false));
      }
    }
    return list;
  }

  static indexOf(list: PropOption[], deviceId: string, propKey: string): number {
    for (let i = 0; i < list.length; i++) {
      if (list[i].deviceId === deviceId && list[i].propKey === propKey) {
        return i;
      }
    }
    return -1;
  }

  static find(list: PropOption[], deviceId: string, propKey: string): PropOption | undefined {
    const idx = PropCatalog.indexOf(list, deviceId, propKey);
    return idx < 0 ? undefined : list[idx];
  }

  static labels(list: PropOption[]): string[] {
    const out: string[] = [];
    for (let i = 0; i < list.length; i++) {
      out.push(list[i].label());
    }
    return out;
  }
}
