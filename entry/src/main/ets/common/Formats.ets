import { DeviceProp } from '../model/Device';

/**
 * 统一的展示格式化工具：时间、数值、时长。
 */
export class Fmt {
  static pad(n: number): string {
    return n < 10 ? '0' + n.toString() : n.toString();
  }

  static time(ts: number): string {
    const d = new Date(ts);
    return Fmt.pad(d.getHours()) + ':' + Fmt.pad(d.getMinutes()) + ':' + Fmt.pad(d.getSeconds());
  }

  static timeShort(ts: number): string {
    const d = new Date(ts);
    return Fmt.pad(d.getHours()) + ':' + Fmt.pad(d.getMinutes());
  }

  static date(ts: number): string {
    const d = new Date(ts);
    return (d.getMonth() + 1).toString() + '月' + d.getDate().toString() + '日';
  }

  static weekday(ts: number): string {
    const names: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const d = new Date(ts);
    return names[d.getDay()];
  }

  static greeting(ts: number): string {
    const h = new Date(ts).getHours();
    if (h < 6) {
      return '夜深了';
    }
    if (h < 11) {
      return '早上好';
    }
    if (h < 14) {
      return '午间好';
    }
    if (h < 18) {
      return '下午好';
    }
    return '晚上好';
  }

  static duration(ms: number): string {
    if (ms < 0) {
      return '刚刚';
    }
    const s = Math.floor(ms / 1000);
    if (s < 60) {
      return s.toString() + ' 秒前';
    }
    const m = Math.floor(s / 60);
    if (m < 60) {
      return m.toString() + ' 分钟前';
    }
    const h = Math.floor(m / 60);
    if (h < 24) {
      return h.toString() + ' 小时前';
    }
    return Math.floor(h / 24).toString() + ' 天前';
  }

  /** 属性值的展示文本：布尔属性显示开/关，数值属性带单位 */
  static propValue(p: DeviceProp): string {
    if (p.isBoolean) {
      if (p.unit === 'lock') {
        return p.value >= 1 ? '已上锁' : '未上锁';
      }
      return p.value >= 1 ? '开' : '关';
    }
    const rounded = Math.round(p.value * 10) / 10;
    return rounded.toString() + p.unit;
  }

  static signed(v: number): string {
    const r = Math.round(v * 10) / 10;
    return r > 0 ? '+' + r.toString() : r.toString();
  }
}
