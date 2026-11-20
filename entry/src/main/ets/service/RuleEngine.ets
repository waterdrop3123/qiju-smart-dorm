import { Device, DeviceProp } from '../model/Device';
import { Condition, CompareOp, LogicMode, Rule, RuleAction, RuleUtil } from '../model/Rule';

/**
 * 规则引擎：无 UI 依赖的纯逻辑层。
 * 职责：条件求值 → 冷却判断 → 多规则冲突消解 → 生成可执行的动作计划。
 * 因为全部是静态纯函数，所以可以用 hypium 直接做正常/边界/异常测试。
 */

export class Assignment {
  deviceId: string;
  deviceName: string;
  propKey: string;
  propLabel: string;
  value: number;
  ruleId: string;
  ruleName: string;
  priority: number;
  changed: boolean;

  constructor(deviceId: string, deviceName: string, propKey: string, propLabel: string, value: number,
    ruleId: string, ruleName: string, priority: number, changed: boolean) {
    this.deviceId = deviceId;
    this.deviceName = deviceName;
    this.propKey = propKey;
    this.propLabel = propLabel;
    this.value = value;
    this.ruleId = ruleId;
    this.ruleName = ruleName;
    this.priority = priority;
    this.changed = changed;
  }

  describe(): string {
    return this.deviceName + ' ' + this.propLabel + ' → ' + this.value.toString();
  }
}

export class BlockedRule {
  ruleId: string;
  ruleName: string;
  reason: string;

  constructor(ruleId: string, ruleName: string, reason: string) {
    this.ruleId = ruleId;
    this.ruleName = ruleName;
    this.reason = reason;
  }
}

export class ExecutionPlan {
  matched: Rule[];
  assignments: Assignment[];
  blocked: BlockedRule[];
  conflicts: BlockedRule[];

  constructor(matched: Rule[], assignments: Assignment[], blocked: BlockedRule[], conflicts: BlockedRule[]) {
    this.matched = matched;
    this.assignments = assignments;
    this.blocked = blocked;
    this.conflicts = conflicts;
  }

  changedAssignments(): Assignment[] {
    const list: Assignment[] = [];
    for (let i = 0; i < this.assignments.length; i++) {
      if (this.assignments[i].changed) {
        list.push(this.assignments[i]);
      }
    }
    return list;
  }

  isEmpty(): boolean {
    return this.matched.length === 0 && this.blocked.length === 0;
  }
}

export class RuleEngine {
  /** 浮点比较容差：传感器数值保留一位小数，0.05 足够区分 */
  static readonly EPS: number = 0.05;

  static compare(op: CompareOp, left: number, right: number): boolean {
    switch (op) {
      case CompareOp.GT:
        return left > right + RuleEngine.EPS;
      case CompareOp.GTE:
        return left >= right - RuleEngine.EPS;
      case CompareOp.LT:
        return left < right - RuleEngine.EPS;
      case CompareOp.LTE:
        return left <= right + RuleEngine.EPS;
      case CompareOp.EQ:
        return Math.abs(left - right) <= RuleEngine.EPS;
      case CompareOp.NE:
        return Math.abs(left - right) > RuleEngine.EPS;
      default:
        return false;
    }
  }

  /** 单条件求值；设备或属性缺失时按"不满足"处理，避免崩溃 */
  static conditionHolds(cond: Condition, devices: Device[]): boolean {
    const d = RuleUtil.findDevice(devices, cond.deviceId);
    if (d === undefined) {
      return false;
    }
    const p = d.getProp(cond.propKey);
    if (p === undefined) {
      return false;
    }
    return RuleEngine.compare(cond.op, p.value, cond.value);
  }

  /** 规则条件组求值：ALL = 全部满足，ANY = 任一满足；空条件视为不成立 */
  static ruleMatches(rule: Rule, devices: Device[]): boolean {
    if (!rule.enabled || rule.conditions.length === 0) {
      return false;
    }
    let hit = 0;
    for (let i = 0; i < rule.conditions.length; i++) {
      if (RuleEngine.conditionHolds(rule.conditions[i], devices)) {
        hit = hit + 1;
      } else if (rule.logic === LogicMode.ALL) {
        return false;
      }
    }
    if (rule.logic === LogicMode.ALL) {
      return hit === rule.conditions.length;
    }
    return hit > 0;
  }

  static isCoolingDown(rule: Rule, now: number): boolean {
    if (rule.cooldownSec <= 0 || rule.lastFiredAt <= 0) {
      return false;
    }
    return now - rule.lastFiredAt < rule.cooldownSec * 1000;
  }

  static targetKey(deviceId: string, propKey: string): string {
    return deviceId + '#' + propKey;
  }

  /**
   * 生成执行计划：
   * 1) 规则按优先级降序、id 升序排序，保证结果确定；
   * 2) 同一设备同一属性被多条规则命中时，高优先级生效，低优先级记入 conflicts；
   * 3) 冷却中的规则记入 blocked，不执行。
   */
  static buildPlan(rules: Rule[], devices: Device[], now: number): ExecutionPlan {
    const sorted: Rule[] = rules.slice();
    sorted.sort((a: Rule, b: Rule): number => {
      if (b.priority !== a.priority) {
        return b.priority - a.priority;
      }
      return a.id < b.id ? -1 : 1;
    });

    const matched: Rule[] = [];
    const assignments: Assignment[] = [];
    const blocked: BlockedRule[] = [];
    const conflicts: BlockedRule[] = [];
    const taken: Map<string, Assignment> = new Map<string, Assignment>();

    for (let i = 0; i < sorted.length; i++) {
      const rule = sorted[i];
      if (!rule.enabled) {
        continue;
      }
      if (!RuleEngine.ruleMatches(rule, devices)) {
        continue;
      }
      if (RuleEngine.isCoolingDown(rule, now)) {
        blocked.push(new BlockedRule(rule.id, rule.name, '冷却中（' + rule.cooldownSec.toString() + ' 秒内不重复执行）'));
        continue;
      }
      matched.push(rule);
      for (let j = 0; j < rule.actions.length; j++) {
        const act = rule.actions[j];
        const device = RuleUtil.findDevice(devices, act.deviceId);
        if (device === undefined) {
          blocked.push(new BlockedRule(rule.id, rule.name, '动作指向的设备不存在：' + act.deviceId));
          continue;
        }
        if (!device.controllable) {
          blocked.push(new BlockedRule(rule.id, rule.name, device.name + ' 为只读传感器，不能写入'));
          continue;
        }
        const prop = device.getProp(act.propKey);
        if (prop === undefined) {
          blocked.push(new BlockedRule(rule.id, rule.name, device.name + ' 不存在属性 ' + act.propKey));
          continue;
        }
        const key = RuleEngine.targetKey(act.deviceId, act.propKey);
        const exist = taken.get(key);
        if (exist !== undefined) {
          conflicts.push(new BlockedRule(rule.id, rule.name,
            '与「' + exist.ruleName + '」争用 ' + device.name + '·' + prop.label + '，按优先级让位'));
          continue;
        }
        const target = prop.clamp(act.value);
        const changed = !(Math.abs(target - prop.value) < 0.0001);
        const item = new Assignment(device.id, device.name, act.propKey, prop.label, target,
          rule.id, rule.name, rule.priority, changed);
        taken.set(key, item);
        assignments.push(item);
      }
    }
    return new ExecutionPlan(matched, assignments, blocked, conflicts);
  }

  /** 规则静态校验：编辑器保存前调用，返回错误信息列表（空数组表示合法） */
  static validateRule(rule: Rule, devices: Device[]): string[] {
    const errors: string[] = [];
    if (rule.name.trim().length === 0) {
      errors.push('规则名称不能为空');
    }
    if (rule.name.length > 24) {
      errors.push('规则名称不能超过 24 个字符');
    }
    if (rule.conditions.length === 0) {
      errors.push('至少需要一条触发条件');
    }
    if (rule.actions.length === 0) {
      errors.push('至少需要一条执行动作');
    }
    if (rule.priority < 1 || rule.priority > 99) {
      errors.push('优先级需在 1—99 之间');
    }
    if (rule.cooldownSec < 0 || rule.cooldownSec > 3600) {
      errors.push('冷却时间需在 0—3600 秒之间');
    }
    for (let i = 0; i < rule.conditions.length; i++) {
      const c = rule.conditions[i];
      const d = RuleUtil.findDevice(devices, c.deviceId);
      if (d === undefined) {
        errors.push('条件 ' + (i + 1).toString() + ' 指向的设备不存在');
        continue;
      }
      const p = d.getProp(c.propKey);
      if (p === undefined) {
        errors.push('条件 ' + (i + 1).toString() + ' 指向的属性不存在');
        continue;
      }
      if (c.value < p.min || c.value > p.max) {
        errors.push('条件 ' + (i + 1).toString() + ' 的阈值超出 ' + p.min.toString() + '—' + p.max.toString() + p.unit);
      }
    }
    for (let i = 0; i < rule.actions.length; i++) {
      const a = rule.actions[i];
      const d = RuleUtil.findDevice(devices, a.deviceId);
      if (d === undefined) {
        errors.push('动作 ' + (i + 1).toString() + ' 指向的设备不存在');
        continue;
      }
      if (!d.controllable) {
        errors.push('动作 ' + (i + 1).toString() + ' 指向的 ' + d.name + ' 是只读传感器');
        continue;
      }
      const p = d.getProp(a.propKey);
      if (p === undefined) {
        errors.push('动作 ' + (i + 1).toString() + ' 指向的属性不存在');
        continue;
      }
      if (a.value < p.min || a.value > p.max) {
        errors.push('动作 ' + (i + 1).toString() + ' 的目标值超出 ' + p.min.toString() + '—' + p.max.toString() + p.unit);
      }
    }
    return errors;
  }

  /** 供编辑器使用：某设备可参与条件的属性列表 */
  static propsOf(device: Device): DeviceProp[] {
    return device.props;
  }

  /** 供编辑器使用：可被动作控制的设备列表 */
  static controllableDevices(devices: Device[]): Device[] {
    const list: Device[] = [];
    for (let i = 0; i < devices.length; i++) {
      if (devices[i].controllable) {
        list.push(devices[i]);
      }
    }
    return list;
  }
}
