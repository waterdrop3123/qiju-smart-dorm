/**
 * 环境模拟器：用随机游走模拟宿舍温度、湿度、光照与人数变化。
 * 纯函数实现（输入旧值 + 随机数 → 输出新值），既能在界面里驱动数据，也能被测试。
 */
export class EnvSimulator {
  static clamp(v: number, min: number, max: number): number {
    if (v < min) {
      return min;
    }
    if (v > max) {
      return max;
    }
    return v;
  }

  static round1(v: number): number {
    return Math.round(v * 10) / 10;
  }

  /** 向目标值缓慢回归，并叠加随机扰动 */
  static drift(current: number, target: number, pull: number, noise: number,
    min: number, max: number, digits: number): number {
    const base = current + (target - current) * pull + (Math.random() - 0.5) * 2 * noise;
    const clamped = EnvSimulator.clamp(base, min, max);
    const factor = Math.pow(10, digits);
    return Math.round(clamped * factor) / factor;
  }

  static nextTemperature(current: number): number {
    return EnvSimulator.drift(current, 26.5, 0.06, 0.35, 12, 38, 1);
  }

  static nextHumidity(current: number): number {
    return EnvSimulator.drift(current, 45, 0.06, 2.5, 15, 90, 0);
  }

  static nextIlluminance(current: number, occupancy: number): number {
    const target = occupancy > 0 ? 380 : 90;
    let next = EnvSimulator.drift(current, target, 0.08, 70, 0, 1200, 0);
    if (Math.random() < 0.05) {
      next = EnvSimulator.clamp(next + (Math.random() - 0.3) * 300, 0, 1200);
    }
    return Math.round(next);
  }

  /** 人数在 0—4 之间跳变，模拟有人进出宿舍 */
  static nextOccupancy(current: number): number {
    const roll = Math.random();
    if (roll < 0.12) {
      let next = current + (Math.random() < 0.5 ? -1 : 1);
      next = EnvSimulator.clamp(next, 0, 4);
      return Math.round(next);
    }
    return current;
  }
}
