import { Device, DeviceFactory, DeviceProp, DeviceType } from '../model/Device';
import { CompareOpUtil, Condition, LogicMode, Rule, RuleAction } from '../model/Rule';
import { LogEntry, LogKind } from '../model/LogEntry';

/**
 * 持久化 DTO（纯数据结构）与编解码。
 * 之所以不直接把 JSON.parse 的结果当对象用：ArkTS 里解析出来的是普通对象，
 * 缺少类方法，必须显式重建领域对象，否则运行期调用方法会崩。
 */

interface PropDTO {
  key: string;
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  unit: string;
  isBoolean: boolean;
}

interface DeviceDTO {
  id: string;
  name: string;
  type: string;
  room: string;
  online: boolean;
  controllable: boolean;
  props: PropDTO[];
}

interface ConditionDTO {
  deviceId: string;
  propKey: string;
  op: string;
  value: number;
}

interface ActionDTO {
  deviceId: string;
  propKey: string;
  value: number;
}

interface RuleDTO {
  id: string;
  name: string;
  enabled: boolean;
  priority: number;
  logic: string;
  conditions: ConditionDTO[];
  actions: ActionDTO[];
  cooldownSec: number;
  lastFiredAt: number;
  fireCount: number;
  createdAt: number;
}

interface LogDTO {
  id: string;
  ts: number;
  kind: string;
  title: string;
  detail: string;
  ruleId: string;
  ruleName: string;
  ok: boolean;
  from: string;
}

interface BundleDTO {
  version: number;
  devices: DeviceDTO[];
  rules: RuleDTO[];
  logs: LogDTO[];
}

/** 一次持久化的数据包 */
export class SnapshotBundle {
  version: number;
  devices: Device[];
  rules: Rule[];
  logs: LogEntry[];

  constructor(version: number, devices: Device[], rules: Rule[], logs: LogEntry[]) {
    this.version = version;
    this.devices = devices;
    this.rules = rules;
    this.logs = logs;
  }
}

function parseDeviceType(s: string): DeviceType {
  if (s === DeviceType.SENSOR) {
    return DeviceType.SENSOR;
  }
  if (s === DeviceType.LIGHT) {
    return DeviceType.LIGHT;
  }
  if (s === DeviceType.AC) {
    return DeviceType.AC;
  }
  if (s === DeviceType.CURTAIN) {
    return DeviceType.CURTAIN;
  }
  if (s === DeviceType.HUMIDIFIER) {
    return DeviceType.HUMIDIFIER;
  }
  if (s === DeviceType.SOCKET) {
    return DeviceType.SOCKET;
  }
  return DeviceType.LOCK;
}

function parseLogic(s: string): LogicMode {
  return s === LogicMode.ANY ? LogicMode.ANY : LogicMode.ALL;
}

function parseKind(s: string): LogKind {
  if (s === LogKind.AUTOMATION) {
    return LogKind.AUTOMATION;
  }
  if (s === LogKind.MANUAL) {
    return LogKind.MANUAL;
  }
  if (s === LogKind.SCENE) {
    return LogKind.SCENE;
  }
  if (s === LogKind.BLOCKED) {
    return LogKind.BLOCKED;
  }
  return LogKind.SYSTEM;
}

export class SnapshotCodec {
  static readonly VERSION: number = 1;

  static encode(devices: Device[], rules: Rule[], logs: LogEntry[]): string {
    const bundle = new SnapshotBundle(SnapshotCodec.VERSION, devices, rules, logs);
    return JSON.stringify(bundle);
  }

  /** 解析失败时返回 undefined，由调用方决定回退到默认数据 */
  static decode(raw: string): SnapshotBundle | undefined {
    if (raw.length < 2) {
      return undefined;
    }
    try {
      const dto = JSON.parse(raw) as BundleDTO;
      if (dto === null || dto === undefined || dto.devices === undefined) {
        return undefined;
      }
      const devices: Device[] = [];
      for (let i = 0; i < dto.devices.length; i++) {
        const d = dto.devices[i];
        const props: DeviceProp[] = [];
        for (let j = 0; j < d.props.length; j++) {
          const p = d.props[j];
          props.push(new DeviceProp(p.key, p.label, p.value, p.min, p.max, p.step, p.unit, p.isBoolean));
        }
        devices.push(new Device(d.id, d.name, parseDeviceType(d.type), d.room, d.online, d.controllable, props));
      }
      const rules: Rule[] = [];
      for (let i = 0; i < dto.rules.length; i++) {
        const r = dto.rules[i];
        const conds: Condition[] = [];
        for (let j = 0; j < r.conditions.length; j++) {
          const c = r.conditions[j];
          conds.push(new Condition(c.deviceId, c.propKey, CompareOpUtil.parse(c.op), c.value));
        }
        const acts: RuleAction[] = [];
        for (let j = 0; j < r.actions.length; j++) {
          const a = r.actions[j];
          acts.push(new RuleAction(a.deviceId, a.propKey, a.value));
        }
        rules.push(new Rule(r.id, r.name, r.enabled, r.priority, parseLogic(r.logic), conds, acts,
          r.cooldownSec, r.lastFiredAt, r.fireCount, r.createdAt));
      }
      const logs: LogEntry[] = [];
      for (let i = 0; i < dto.logs.length; i++) {
        const l = dto.logs[i];
        logs.push(new LogEntry(l.id, l.ts, parseKind(l.kind), l.title, l.detail, l.ruleId, l.ruleName, l.ok, l.from));
      }
      if (devices.length === 0) {
        return undefined;
      }
      return new SnapshotBundle(dto.version, devices, rules, logs);
    } catch (err) {
      return undefined;
    }
  }

  static defaultBundle(): SnapshotBundle {
    return new SnapshotBundle(SnapshotCodec.VERSION, DeviceFactory.createDefault(), [], []);
  }
}
