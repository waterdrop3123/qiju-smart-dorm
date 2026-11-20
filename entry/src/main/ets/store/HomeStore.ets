import { AppRepository } from '../data/AppRepository';
import { SnapshotBundle } from '../data/SnapshotCodec';
import { Device, DeviceFactory, DeviceProp } from '../model/Device';
import { LogEntry, LogFactory, LogKind } from '../model/LogEntry';
import { Rule, RuleUtil } from '../model/Rule';
import { RulePresets } from '../model/RulePresets';
import { Scene, SceneFactory } from '../model/Scene';
import { AutomationService } from '../service/AutomationService';
import { EnvSimulator } from '../service/EnvSimulator';
import { ExecutionPlan, RuleEngine } from '../service/RuleEngine';

/** 全局状态版本号：任何业务数据变化都递增，页面通过 @StorageLink 订阅后重绘 */
export const REV_KEY: string = 'qijuRev';
/** 日志上限，避免 preferences 里字符串无限膨胀 */
export const MAX_LOGS: number = 120;

export class StoreStats {
  devices: number;
  rules: number;
  activeRules: number;
  logs: number;

  constructor(devices: number, rules: number, activeRules: number, logs: number) {
    this.devices = devices;
    this.rules = rules;
    this.activeRules = activeRules;
    this.logs = logs;
  }
}

/**
 * 应用状态中心（唯一数据源）。
 * 页面不直接改设备/规则，一律调用这里的方法，方法内部负责：修改 → 通知 → 持久化。
 */
export class HomeStore {
  devices: Device[] = [];
  rules: Rule[] = [];
  scenes: Scene[] = [];
  logs: LogEntry[] = [];
  simulate: boolean = true;
  tickMs: number = 3000;
  revision: number = 0;
  bootedAt: number = 0;
  lastTickAt: number = 0;
  lastTriggerAt: number = 0;
  lastTriggerTitle: string = '尚未触发';
  saveCount: number = 0;
  persistedAt: number = 0;
  storageReady: boolean = false;
  tickCount: number = 0;
  selectedDeviceId: string = '';
  editingRuleId: string = '';
  private timerId: number = -1;

  /** 启动：优先从 preferences 恢复，失败则用默认数据 */
  init(): void {
    this.bootedAt = Date.now();
    this.scenes = SceneFactory.createDefault();
    this.storageReady = AppRepository.isReady();
    const bundle = AppRepository.load();
    if (bundle !== undefined) {
      this.devices = bundle.devices;
      this.rules = bundle.rules;
      this.logs = bundle.logs;
      this.addLog(LogFactory.create(LogKind.SYSTEM, '数据恢复成功',
        '从本地存储恢复 ' + this.devices.length.toString() + ' 台设备、' +
        this.rules.length.toString() + ' 条规则、' + this.logs.length.toString() + ' 条日志',
        'preferences', '', '', true));
    } else {
      this.devices = DeviceFactory.createDefault();
      this.rules = RulePresets.createDefault(this.bootedAt);
      this.logs = [];
      this.addLog(LogFactory.create(LogKind.SYSTEM, '首次启动',
        '已载入 ' + this.devices.length.toString() + ' 台模拟设备与 ' +
        this.rules.length.toString() + ' 条预置规则', 'preferences', '', '', true));
    }
    this.notify();
    this.persist(true);
  }

  // ---------------- 基础查询 ----------------

  deviceById(id: string): Device | undefined {
    return RuleUtil.findDevice(this.devices, id);
  }

  ruleById(id: string): Rule | undefined {
    for (let i = 0; i < this.rules.length; i++) {
      if (this.rules[i].id === id) {
        return this.rules[i];
      }
    }
    return undefined;
  }

  sceneById(id: string): Scene | undefined {
    for (let i = 0; i < this.scenes.length; i++) {
      if (this.scenes[i].id === id) {
        return this.scenes[i];
      }
    }
    return undefined;
  }

  sensor(): Device | undefined {
    return this.deviceById(DeviceFactory.ENV_ID);
  }

  envValue(key: string): number {
    const s = this.sensor();
    return s === undefined ? 0 : s.getValue(key, 0);
  }

  envProps(): DeviceProp[] {
    const s = this.sensor();
    return s === undefined ? [] : s.props;
  }

  /** 除传感器外、需要在首页展示的可控设备 */
  controllableDevices(): Device[] {
    return RuleEngine.controllableDevices(this.devices);
  }

  stats(): StoreStats {
    let active = 0;
    for (let i = 0; i < this.rules.length; i++) {
      if (this.rules[i].enabled) {
        active = active + 1;
      }
    }
    return new StoreStats(this.devices.length, this.rules.length, active, this.logs.length);
  }

  recentLogs(limit: number): LogEntry[] {
    return this.logs.slice(0, limit);
  }

  logsMatching(keyword: string, limit: number): LogEntry[] {
    const out: LogEntry[] = [];
    for (let i = 0; i < this.logs.length; i++) {
      if (this.logs[i].detail.indexOf(keyword) >= 0 || this.logs[i].title.indexOf(keyword) >= 0) {
        out.push(this.logs[i]);
        if (out.length >= limit) {
          break;
        }
      }
    }
    return out;
  }

  // ---------------- 业务动作 ----------------

  /** 一个节拍：环境演化 → 规则求值 → 应用动作 → 写日志 */
  tick(): void {
    const now = Date.now();
    this.tickCount = this.tickCount + 1;
    if (this.simulate) {
      this.simulateEnv();
    }
    const plan: ExecutionPlan = RuleEngine.buildPlan(this.rules, this.devices, now);
    let changed = 0;
    for (let i = 0; i < plan.assignments.length; i++) {
      if (!plan.assignments[i].changed) {
        continue;
      }
      const d = this.deviceById(plan.assignments[i].deviceId);
      if (d !== undefined && d.setValue(plan.assignments[i].propKey, plan.assignments[i].value)) {
        changed = changed + 1;
      }
    }
    for (let i = 0; i < plan.matched.length; i++) {
      const r = this.ruleById(plan.matched[i].id);
      if (r !== undefined) {
        r.lastFiredAt = now;
        r.fireCount = r.fireCount + 1;
      }
    }
    if (plan.matched.length > 0 && changed > 0) {
      const names = AutomationService.ruleNames(plan);
      this.lastTriggerAt = now;
      this.lastTriggerTitle = names;
      this.addLog(LogFactory.create(LogKind.AUTOMATION, names + ' 自动执行',
        AutomationService.changedText(plan), '规则引擎',
        plan.matched[0].id, plan.matched[0].name, true));
    }
    if (plan.conflicts.length > 0 && this.shouldLogConflict(now)) {
      this.addLog(LogFactory.create(LogKind.BLOCKED, '动作冲突已消解',
        AutomationService.conflictText(plan.conflicts), '优先级仲裁', '', '', true));
    }
    this.lastTickAt = now;
    this.notify();
    this.persist(false);
  }

  /** 冲突日志限流：30 秒内只记一条，避免刷屏 */
  private shouldLogConflict(now: number): boolean {
    for (let i = 0; i < this.logs.length && i < 6; i++) {
      if (this.logs[i].kind === LogKind.BLOCKED && now - this.logs[i].ts < 30000) {
        return false;
      }
    }
    return true;
  }

  private simulateEnv(): void {
    const s = this.sensor();
    if (s === undefined) {
      return;
    }
    const t = s.getProp('temperature');
    const h = s.getProp('humidity');
    const l = s.getProp('illuminance');
    const o = s.getProp('occupancy');
    if (t !== undefined) {
      t.value = EnvSimulator.nextTemperature(t.value);
    }
    if (h !== undefined) {
      h.value = EnvSimulator.nextHumidity(h.value);
    }
    if (o !== undefined) {
      o.value = EnvSimulator.nextOccupancy(o.value);
    }
    if (l !== undefined) {
      const occ = o === undefined ? 0 : o.value;
      l.value = EnvSimulator.nextIlluminance(l.value, occ);
    }
  }

  /** 手动调节（详情页/卡片操作），会留下 MANUAL 日志 */
  setDeviceValue(deviceId: string, propKey: string, value: number): boolean {
    const d = this.deviceById(deviceId);
    if (d === undefined) {
      return false;
    }
    const p = d.getProp(propKey);
    if (p === undefined) {
      return false;
    }
    const changed = d.setValue(propKey, value);
    if (changed) {
      this.addLog(LogFactory.create(LogKind.MANUAL, '手动调节 · ' + d.name,
        p.label + ' → ' + RuleUtil.valueText(p, p.value), '用户', '', '', true));
      this.notify();
      this.persist(true);
    }
    return changed;
  }

  applyScene(sceneId: string): number {
    const scene = this.sceneById(sceneId);
    if (scene === undefined) {
      return 0;
    }
    let changed = 0;
    const parts: string[] = [];
    for (let i = 0; i < scene.actions.length; i++) {
      const act = scene.actions[i];
      const d = this.deviceById(act.deviceId);
      if (d === undefined) {
        continue;
      }
      if (d.setValue(act.propKey, act.value)) {
        changed = changed + 1;
        parts.push(act.describe(this.devices));
      }
    }
    this.addLog(LogFactory.create(LogKind.SCENE, '场景执行 · ' + scene.name,
      changed > 0 ? parts.join('；') : '设备已处于该场景状态', '用户', '', '', true));
    this.notify();
    this.persist(true);
    return changed;
  }

  toggleRule(ruleId: string): void {
    const r = this.ruleById(ruleId);
    if (r === undefined) {
      return;
    }
    r.enabled = !r.enabled;
    this.addLog(LogFactory.create(LogKind.SYSTEM, '规则' + (r.enabled ? '启用' : '停用') + ' · ' + r.name,
      '优先级 ' + r.priority.toString() + '，冷却 ' + r.cooldownSec.toString() + ' 秒', '用户', r.id, r.name, true));
    this.notify();
    this.persist(true);
  }

  /** 保存规则（新增或更新），返回校验错误；空数组表示保存成功 */
  saveRule(rule: Rule): string[] {
    const errors = RuleEngine.validateRule(rule, this.devices);
    if (errors.length > 0) {
      return errors;
    }
    let replaced = false;
    const next: Rule[] = [];
    for (let i = 0; i < this.rules.length; i++) {
      if (this.rules[i].id === rule.id) {
        next.push(rule);
        replaced = true;
      } else {
        next.push(this.rules[i]);
      }
    }
    if (!replaced) {
      next.push(rule);
    }
    this.rules = next;
    this.addLog(LogFactory.create(LogKind.SYSTEM, (replaced ? '更新规则 · ' : '新建规则 · ') + rule.name,
      rule.conditionText(this.devices) + ' → ' + rule.actionText(this.devices), '用户', rule.id, rule.name, true));
    this.notify();
    this.persist(true);
    return [];
  }

  deleteRule(ruleId: string): void {
    const r = this.ruleById(ruleId);
    const next: Rule[] = [];
    for (let i = 0; i < this.rules.length; i++) {
      if (this.rules[i].id !== ruleId) {
        next.push(this.rules[i]);
      }
    }
    this.rules = next;
    this.addLog(LogFactory.create(LogKind.SYSTEM, '删除规则 · ' + (r === undefined ? ruleId : r.name),
      '规则已从本地存储移除', '用户', ruleId, r === undefined ? '' : r.name, true));
    this.notify();
    this.persist(true);
  }

  clearLogs(): void {
    this.logs = [];
    this.addLog(LogFactory.create(LogKind.SYSTEM, '日志已清空', '执行记录已重置', '用户', '', '', true));
    this.notify();
    this.persist(true);
  }

  resetAll(): void {
    this.devices = DeviceFactory.createDefault();
    this.rules = RulePresets.createDefault(Date.now());
    this.logs = [];
    AppRepository.clear();
    this.addLog(LogFactory.create(LogKind.SYSTEM, '已恢复出厂数据', '设备与规则回到初始状态', '用户', '', '', true));
    this.notify();
    this.persist(true);
  }

  setSimulate(on: boolean): void {
    this.simulate = on;
    this.addLog(LogFactory.create(LogKind.SYSTEM, on ? '环境模拟已开启' : '环境模拟已暂停',
      on ? '传感器数值每 ' + (this.tickMs / 1000).toString() + ' 秒演化一次' : '数值保持当前值，规则仍在比对',
      '用户', '', '', true));
    this.notify();
    this.persist(true);
  }

  // ---------------- 生命周期：定时节拍 ----------------

  /** 前台启动节拍器：环境演化 + 规则求值，是"无人操作也会自动执行"的来源 */
  startTicker(): void {
    if (this.timerId >= 0) {
      return;
    }
    this.timerId = setInterval(() => {
      this.tick();
    }, this.tickMs);
  }

  stopTicker(): void {
    if (this.timerId < 0) {
      return;
    }
    clearInterval(this.timerId);
    this.timerId = -1;
  }

  /** 立即落盘（切后台/退出前调用，保证下次冷启动能恢复） */
  flushNow(): void {
    this.persist(true);
  }

  // ---------------- 内部：日志 / 通知 / 持久化 ----------------

  addLog(entry: LogEntry): void {
    const next: LogEntry[] = [entry];
    for (let i = 0; i < this.logs.length && next.length < MAX_LOGS; i++) {
      next.push(this.logs[i]);
    }
    this.logs = next;
  }

  private notify(): void {
    this.revision = this.revision + 1;
    AppStorage.setOrCreate<number>(REV_KEY, this.revision);
  }

  private persist(force: boolean): void {
    const now = Date.now();
    if (!force && now - this.persistedAt < 4000) {
      return;
    }
    const ok = AppRepository.save(new SnapshotBundle(1, this.devices, this.rules, this.logs));
    if (ok) {
      this.persistedAt = now;
      this.saveCount = this.saveCount + 1;
    }
  }
}

/** 全局单例：整个应用共享同一份状态 */
export const homeStore: HomeStore = new HomeStore();
