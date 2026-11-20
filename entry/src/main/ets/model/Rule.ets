import { Device, DeviceProp } from './Device';

/**
 * 规则领域模型：条件(Condition) + 动作(Action) + 元信息
 * 规则是纯数据，判断逻辑全部在 RuleEngine 中，便于单元测试。
 */

export enum CompareOp {
  GT = 'gt',
  GTE = 'gte',
  LT = 'lt',
  LTE = 'lte',
  EQ = 'eq',
  NE = 'ne'
}

export enum LogicMode {
  ALL = 'all',
  ANY = 'any'
}

export class CompareOpUtil {
  static symbol(op: CompareOp): string {
    switch (op) {
      case CompareOp.GT:
        return '>';
      case CompareOp.GTE:
        return '≥';
      case CompareOp.LT:
        return '<';
      case CompareOp.LTE:
        return '≤';
      case CompareOp.EQ:
        return '=';
      case CompareOp.NE:
        return '≠';
      default:
        return '?';
    }
  }

  static label(op: CompareOp): string {
    switch (op) {
      case CompareOp.GT:
        return '大于';
      case CompareOp.GTE:
        return '大于等于';
      case CompareOp.LT:
        return '小于';
      case CompareOp.LTE:
        return '小于等于';
      case CompareOp.EQ:
        return '等于';
      case CompareOp.NE:
        return '不等于';
      default:
        return '未知';
    }
  }

  static all(): CompareOp[] {
    return [CompareOp.GT, CompareOp.GTE, CompareOp.LT, CompareOp.LTE, CompareOp.EQ, CompareOp.NE];
  }

  static parse(s: string): CompareOp {
    if (s === CompareOp.GT) {
      return CompareOp.GT;
    }
    if (s === CompareOp.GTE) {
      return CompareOp.GTE;
    }
    if (s === CompareOp.LT) {
      return CompareOp.LT;
    }
    if (s === CompareOp.LTE) {
      return CompareOp.LTE;
    }
    if (s === CompareOp.EQ) {
      return CompareOp.EQ;
    }
    return CompareOp.NE;
  }
}

export class Condition {
  deviceId: string;
  propKey: string;
  op: CompareOp;
  value: number;

  constructor(deviceId: string, propKey: string, op: CompareOp, value: number) {
    this.deviceId = deviceId;
    this.propKey = propKey;
    this.op = op;
    this.value = value;
  }

  describe(devices: Device[]): string {
    const d = RuleUtil.findDevice(devices, this.deviceId);
    if (d === undefined) {
      return '设备缺失';
    }
    const p = d.getProp(this.propKey);
    const propLabel = p === undefined ? this.propKey : p.label;
    const text = RuleUtil.valueText(p, this.value);
    return d.name + ' · ' + propLabel + ' ' + CompareOpUtil.symbol(this.op) + ' ' + text;
  }

  copy(): Condition {
    return new Condition(this.deviceId, this.propKey, this.op, this.value);
  }
}

export class RuleAction {
  deviceId: string;
  propKey: string;
  value: number;

  constructor(deviceId: string, propKey: string, value: number) {
    this.deviceId = deviceId;
    this.propKey = propKey;
    this.value = value;
  }

  describe(devices: Device[]): string {
    const d = RuleUtil.findDevice(devices, this.deviceId);
    if (d === undefined) {
      return '设备缺失';
    }
    const p = d.getProp(this.propKey);
    const propLabel = p === undefined ? this.propKey : p.label;
    return d.name + ' ' + propLabel + ' → ' + RuleUtil.valueText(p, this.value);
  }

  copy(): RuleAction {
    return new RuleAction(this.deviceId, this.propKey, this.value);
  }
}

export class Rule {
  id: string;
  name: string;
  enabled: boolean;
  priority: number;
  logic: LogicMode;
  conditions: Condition[];
  actions: RuleAction[];
  cooldownSec: number;
  lastFiredAt: number;
  fireCount: number;
  createdAt: number;

  constructor(id: string, name: string, enabled: boolean, priority: number, logic: LogicMode,
    conditions: Condition[], actions: RuleAction[], cooldownSec: number,
    lastFiredAt: number, fireCount: number, createdAt: number) {
    this.id = id;
    this.name = name;
    this.enabled = enabled;
    this.priority = priority;
    this.logic = logic;
    this.conditions = conditions;
    this.actions = actions;
    this.cooldownSec = cooldownSec;
    this.lastFiredAt = lastFiredAt;
    this.fireCount = fireCount;
    this.createdAt = createdAt;
  }

  conditionText(devices: Device[]): string {
    const parts: string[] = [];
    for (let i = 0; i < this.conditions.length; i++) {
      parts.push(this.conditions[i].describe(devices));
    }
    const joiner = this.logic === LogicMode.ALL ? ' 且 ' : ' 或 ';
    if (parts.length === 0) {
      return '未设置条件';
    }
    return parts.join(joiner);
  }

  actionText(devices: Device[]): string {
    const parts: string[] = [];
    for (let i = 0; i < this.actions.length; i++) {
      parts.push(this.actions[i].describe(devices));
    }
    if (parts.length === 0) {
      return '未设置动作';
    }
    return parts.join('，');
  }

  copy(): Rule {
    const conds: Condition[] = [];
    for (let i = 0; i < this.conditions.length; i++) {
      conds.push(this.conditions[i].copy());
    }
    const acts: RuleAction[] = [];
    for (let i = 0; i < this.actions.length; i++) {
      acts.push(this.actions[i].copy());
    }
    return new Rule(this.id, this.name, this.enabled, this.priority, this.logic, conds, acts,
      this.cooldownSec, this.lastFiredAt, this.fireCount, this.createdAt);
  }
}

export class RuleUtil {
  static findDevice(devices: Device[], id: string): Device | undefined {
    for (let i = 0; i < devices.length; i++) {
      if (devices[i].id === id) {
        return devices[i];
      }
    }
    return undefined;
  }

  static valueText(p: DeviceProp | undefined, v: number): string {
    if (p === undefined) {
      return Math.round(v).toString();
    }
    if (p.isBoolean) {
      if (p.unit === 'lock') {
        return v >= 1 ? '已上锁' : '未上锁';
      }
      return v >= 1 ? '开' : '关';
    }
    return (Math.round(v * 10) / 10).toString() + p.unit;
  }

  static ruleId(index: number): string {
    return 'r_' + Date.now().toString() + '_' + index.toString();
  }
}
