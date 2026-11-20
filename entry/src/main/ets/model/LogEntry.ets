/**
 * 执行日志模型：规则触发、手动操作、场景执行、系统事件统一记录，
 * 既是界面内容，也是"核心逻辑真实执行"的可核查证据。
 */
export enum LogKind {
  AUTOMATION = 'automation',
  MANUAL = 'manual',
  SCENE = 'scene',
  SYSTEM = 'system',
  BLOCKED = 'blocked'
}

export class LogEntry {
  id: string;
  ts: number;
  kind: LogKind;
  title: string;
  detail: string;
  ruleId: string;
  ruleName: string;
  ok: boolean;
  from: string;

  constructor(id: string, ts: number, kind: LogKind, title: string, detail: string,
    ruleId: string, ruleName: string, ok: boolean, from: string) {
    this.id = id;
    this.ts = ts;
    this.kind = kind;
    this.title = title;
    this.detail = detail;
    this.ruleId = ruleId;
    this.ruleName = ruleName;
    this.ok = ok;
    this.from = from;
  }

  kindLabel(): string {
    switch (this.kind) {
      case LogKind.AUTOMATION:
        return '自动';
      case LogKind.MANUAL:
        return '手动';
      case LogKind.SCENE:
        return '场景';
      case LogKind.SYSTEM:
        return '系统';
      case LogKind.BLOCKED:
        return '拦截';
      default:
        return '事件';
    }
  }

  copy(): LogEntry {
    return new LogEntry(this.id, this.ts, this.kind, this.title, this.detail, this.ruleId,
      this.ruleName, this.ok, this.from);
  }
}

export class LogFactory {
  private static seq: number = 0;

  static create(kind: LogKind, title: string, detail: string, from: string,
    ruleId: string, ruleName: string, ok: boolean): LogEntry {
    LogFactory.seq = LogFactory.seq + 1;
    const id = 'log_' + Date.now().toString() + '_' + LogFactory.seq.toString();
    return new LogEntry(id, Date.now(), kind, title, detail, ruleId, ruleName, ok, from);
  }
}
