import { DeviceType } from '../model/Device';
import { Palette } from './Theme';

/**
 * 设备类型的图标、主色与中文名映射（无图片资源，纯文本图标，减少包体）。
 */
export class Visuals {
  static icon(t: DeviceType): string {
    switch (t) {
      case DeviceType.LIGHT:
        return '💡';
      case DeviceType.AC:
        return '❄️';
      case DeviceType.CURTAIN:
        return '🪟';
      case DeviceType.HUMIDIFIER:
        return '💧';
      case DeviceType.SOCKET:
        return '🔌';
      case DeviceType.LOCK:
        return '🔒';
      case DeviceType.SENSOR:
        return '📡';
      default:
        return '📦';
    }
  }

  static tint(t: DeviceType): string {
    switch (t) {
      case DeviceType.LIGHT:
        return Palette.accentSoft;
      case DeviceType.AC:
        return Palette.infoSoft;
      case DeviceType.CURTAIN:
        return Palette.purpleSoft;
      case DeviceType.HUMIDIFIER:
        return Palette.primarySoft;
      case DeviceType.SOCKET:
        return Palette.successSoft;
      case DeviceType.LOCK:
        return Palette.dangerSoft;
      case DeviceType.SENSOR:
        return Palette.infoSoft;
      default:
        return Palette.primarySoft;
    }
  }

  static typeName(t: DeviceType): string {
    switch (t) {
      case DeviceType.LIGHT:
        return '照明';
      case DeviceType.AC:
        return '空调';
      case DeviceType.CURTAIN:
        return '窗帘';
      case DeviceType.HUMIDIFIER:
        return '加湿器';
      case DeviceType.SOCKET:
        return '智能插座';
      case DeviceType.LOCK:
        return '门锁';
      case DeviceType.SENSOR:
        return '环境传感';
      default:
        return '设备';
    }
  }

  static sensorIcon(key: string): string {
    switch (key) {
      case 'temperature':
        return '🌡';
      case 'humidity':
        return '💧';
      case 'illuminance':
        return '☀️';
      case 'occupancy':
        return '👥';
      default:
        return '📊';
    }
  }

  static sensorLabel(key: string): string {
    switch (key) {
      case 'temperature':
        return '室内温度';
      case 'humidity':
        return '相对湿度';
      case 'illuminance':
        return '光照强度';
      case 'occupancy':
        return '在寝人数';
      default:
        return key;
    }
  }
}
