/**
 * 设备领域模型
 * 设计要点：用「设备 + 属性(k-v)」的统一结构建模，规则引擎才能对任意设备属性做条件判断，
 * 而不是给每种设备写一套 if-else。
 */

export enum DeviceType {
  SENSOR = 'sensor',
  LIGHT = 'light',
  AC = 'ac',
  CURTAIN = 'curtain',
  HUMIDIFIER = 'humidifier',
  SOCKET = 'socket',
  LOCK = 'lock'
}

export class DeviceProp {
  key: string;
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  unit: string;
  /** 布尔型属性用 1/0 表示，便于统一比较与存储 */
  isBoolean: boolean;

  constructor(key: string, label: string, value: number, min: number, max: number,
    step: number, unit: string, isBoolean: boolean) {
    this.key = key;
    this.label = label;
    this.value = value;
    this.min = min;
    this.max = max;
    this.step = step;
    this.unit = unit;
    this.isBoolean = isBoolean;
  }

  clamp(v: number): number {
    let out: number = v;
    if (this.isBoolean) {
      out = v >= 1 ? 1 : 0;
    }
    if (out < this.min) {
      out = this.min;
    }
    if (out > this.max) {
      out = this.max;
    }
    if (this.step > 0) {
      out = Math.round(out / this.step) * this.step;
      out = Math.round(out * 100) / 100;
    }
    return out;
  }

  copy(): DeviceProp {
    return new DeviceProp(this.key, this.label, this.value, this.min, this.max, this.step, this.unit, this.isBoolean);
  }
}

export class Device {
  id: string;
  name: string;
  type: DeviceType;
  room: string;
  online: boolean;
  /** 是否可被规则/用户控制（传感器只读） */
  controllable: boolean;
  props: DeviceProp[];

  constructor(id: string, name: string, type: DeviceType, room: string, online: boolean,
    controllable: boolean, props: DeviceProp[]) {
    this.id = id;
    this.name = name;
    this.type = type;
    this.room = room;
    this.online = online;
    this.controllable = controllable;
    this.props = props;
  }

  getProp(key: string): DeviceProp | undefined {
    for (let i = 0; i < this.props.length; i++) {
      if (this.props[i].key === key) {
        return this.props[i];
      }
    }
    return undefined;
  }

  getValue(key: string, fallback: number): number {
    const p = this.getProp(key);
    return p === undefined ? fallback : p.value;
  }

  /** 返回 true 表示值确实发生了变化 */
  setValue(key: string, v: number): boolean {
    const p = this.getProp(key);
    if (p === undefined || !this.controllable) {
      return false;
    }
    const next = p.clamp(v);
    if (Math.abs(next - p.value) < 0.0001) {
      return false;
    }
    p.value = next;
    return true;
  }

  copy(): Device {
    const list: DeviceProp[] = [];
    for (let i = 0; i < this.props.length; i++) {
      list.push(this.props[i].copy());
    }
    return new Device(this.id, this.name, this.type, this.room, this.online, this.controllable, list);
  }
}

export class DeviceFactory {
  static readonly ENV_ID: string = 'env';

  static sensor(): Device {
    const props: DeviceProp[] = [
      new DeviceProp('temperature', '室内温度', 26.4, 12, 38, 0.1, '℃', false),
      new DeviceProp('humidity', '相对湿度', 52, 15, 90, 1, '%', false),
      new DeviceProp('illuminance', '光照强度', 420, 0, 1200, 10, 'lx', false),
      new DeviceProp('occupancy', '在寝人数', 2, 0, 4, 1, ' 人', false)
    ];
    return new Device(DeviceFactory.ENV_ID, '环境传感', DeviceType.SENSOR, '全屋', true, false, props);
  }

  static createDefault(): Device[] {
    const list: Device[] = [];
    list.push(DeviceFactory.sensor());
    list.push(new Device('light_main', '主灯', DeviceType.LIGHT, '宿舍', true, true, [
      new DeviceProp('power', '开关', 1, 0, 1, 1, '', true),
      new DeviceProp('level', '亮度', 70, 0, 100, 5, '%', false)
    ]));
    list.push(new Device('light_desk', '书桌灯', DeviceType.LIGHT, '书桌', true, true, [
      new DeviceProp('power', '开关', 0, 0, 1, 1, '', true),
      new DeviceProp('level', '亮度', 40, 0, 100, 5, '%', false)
    ]));
    list.push(new Device('ac_main', '空调', DeviceType.AC, '宿舍', true, true, [
      new DeviceProp('power', '开关', 0, 0, 1, 1, '', true),
      new DeviceProp('targetTemp', '设定温度', 26, 16, 30, 1, '℃', false)
    ]));
    list.push(new Device('curtain_main', '窗帘', DeviceType.CURTAIN, '阳台', true, true, [
      new DeviceProp('position', '开合度', 30, 0, 100, 5, '%', false)
    ]));
    list.push(new Device('humidifier', '加湿器', DeviceType.HUMIDIFIER, '宿舍', true, true, [
      new DeviceProp('power', '开关', 0, 0, 1, 1, '', true),
      new DeviceProp('level', '档位', 1, 1, 3, 1, ' 档', false)
    ]));
    list.push(new Device('socket_desk', '桌面插排', DeviceType.SOCKET, '书桌', true, true, [
      new DeviceProp('power', '开关', 1, 0, 1, 1, '', true)
    ]));
    list.push(new Device('lock_door', '门锁', DeviceType.LOCK, '门口', true, true, [
      new DeviceProp('locked', '反锁', 0, 0, 1, 1, 'lock', true)
    ]));
    return list;
  }
}
