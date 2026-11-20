import { CompareOp, Condition, LogicMode, Rule, RuleAction } from './Rule';

/**
 * 预置规则：覆盖"全部满足(ALL)"与"任一满足(ANY)"两种条件组，
 * 并且三条规则会争用「窗帘开合度」，用于演示优先级冲突消解。
 */
export class RulePresets {
  static createDefault(now: number): Rule[] {
    const list: Rule[] = [];

    list.push(new Rule('r_safety', '极端环境自保', true, 100, LogicMode.ANY, [
      new Condition('env', 'temperature', CompareOp.GT, 32),
      new Condition('env', 'humidity', CompareOp.GT, 75)
    ], [
      new RuleAction('ac_main', 'power', 1),
      new RuleAction('ac_main', 'targetTemp', 25),
      new RuleAction('humidifier', 'power', 0)
    ], 300, 0, 0, now));

    list.push(new Rule('r_cool', '高温自动降温', true, 90, LogicMode.ALL, [
      new Condition('env', 'temperature', CompareOp.GTE, 28)
    ], [
      new RuleAction('ac_main', 'power', 1),
      new RuleAction('ac_main', 'targetTemp', 24)
    ], 120, 0, 0, now));

    list.push(new Rule('r_sleep', '就寝自动熄灯', true, 80, LogicMode.ALL, [
      new Condition('env', 'occupancy', CompareOp.EQ, 0),
      new Condition('env', 'illuminance', CompareOp.LT, 150)
    ], [
      new RuleAction('light_main', 'power', 0),
      new RuleAction('light_desk', 'power', 0),
      new RuleAction('curtain_main', 'position', 0),
      new RuleAction('lock_door', 'locked', 1)
    ], 180, 0, 0, now));

    list.push(new Rule('r_dry', '干燥自动加湿', true, 70, LogicMode.ALL, [
      new Condition('env', 'humidity', CompareOp.LT, 40)
    ], [
      new RuleAction('humidifier', 'power', 1),
      new RuleAction('humidifier', 'level', 2)
    ], 120, 0, 0, now));

    list.push(new Rule('r_empty', '无人断电', true, 60, LogicMode.ALL, [
      new Condition('env', 'occupancy', CompareOp.LTE, 0)
    ], [
      new RuleAction('socket_desk', 'power', 0),
      new RuleAction('light_desk', 'power', 0)
    ], 120, 0, 0, now));

    list.push(new Rule('r_back', '回寝补光', true, 50, LogicMode.ALL, [
      new Condition('env', 'occupancy', CompareOp.GT, 0),
      new Condition('env', 'illuminance', CompareOp.LT, 150)
    ], [
      new RuleAction('light_main', 'power', 1),
      new RuleAction('light_main', 'level', 80)
    ], 90, 0, 0, now));

    list.push(new Rule('r_wake', '天亮自动开帘', true, 40, LogicMode.ALL, [
      new Condition('env', 'illuminance', CompareOp.GT, 600)
    ], [
      new RuleAction('curtain_main', 'position', 100),
      new RuleAction('light_main', 'power', 0)
    ], 300, 0, 0, now));

    return list;
  }

  /** 新建规则时的空白模板 */
  static template(now: number): Rule {
    return new Rule('r_new_' + now.toString(), '新规则', true, 50, LogicMode.ALL,
      [new Condition('env', 'temperature', CompareOp.GT, 28)],
      [new RuleAction('light_main', 'power', 1)], 60, 0, 0, now);
  }
}
