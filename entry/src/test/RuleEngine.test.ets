import { describe, it, expect } from '@ohos/hypium';
import { Device, DeviceFactory, DeviceType } from '../main/ets/model/Device';
import { CompareOp, Condition, LogicMode, Rule, RuleAction } from '../main/ets/model/Rule';
import { ExecutionPlan, RuleEngine } from '../main/ets/service/RuleEngine';
import { EnvSimulator } from '../main/ets/service/EnvSimulator';

function findDevice(devices: Device[], id: string): Device {
  for (let i = 0; i < devices.length; i++) {
    if (devices[i].id === id) {
      return devices[i];
    }
  }
  return devices[0];
}

function sensorOf(devices: Device[]): Device {
  for (let i = 0; i < devices.length; i++) {
    if (devices[i].type === DeviceType.SENSOR) {
      return devices[i];
    }
  }
  return devices[0];
}

function setEnv(devices: Device[], key: string, value: number): void {
  const p = sensorOf(devices).getProp(key);
  if (p !== undefined) {
    p.value = value;
  }
}

/** 构造一条单条件单动作的规则，便于对引擎做最小化验证 */
function makeRule(id: string, priority: number, cond: Condition, act: RuleAction,
  cooldown: number, lastFiredAt: number): Rule {
  return new Rule(id, '规则' + id, true, priority, LogicMode.ALL, [cond], [act], cooldown, lastFiredAt, 0, Date.now());
}

export default function ruleEngineSuite() {
  describe('RuleEngine', () => {
    // ---------------- 正常场景 ----------------

    it('正常_比较运算符在阈值处按语义分流', 0, () => {
      expect(RuleEngine.compare(CompareOp.GT, 28, 28)).assertFalse();
      expect(RuleEngine.compare(CompareOp.GT, 28.3, 28)).assertTrue();
      expect(RuleEngine.compare(CompareOp.GTE, 28, 28)).assertTrue();
      expect(RuleEngine.compare(CompareOp.LTE, 28, 28)).assertTrue();
      expect(RuleEngine.compare(CompareOp.LT, 27.9, 28)).assertTrue();
    });

    it('正常_全部满足(ALL)需要每条条件都成立', 0, () => {
      const devices = DeviceFactory.createDefault();
      setEnv(devices, 'temperature', 29.5);
      setEnv(devices, 'humidity', 38);
      const rule = new Rule('r_all', 'ALL规则', true, 50, LogicMode.ALL, [
        new Condition('env', 'temperature', CompareOp.GT, 28),
        new Condition('env', 'humidity', CompareOp.LT, 40)
      ], [new RuleAction('humidifier', 'power', 1)], 0, 0, 0, Date.now());
      expect(RuleEngine.ruleMatches(rule, devices)).assertTrue();
      setEnv(devices, 'humidity', 55);
      expect(RuleEngine.ruleMatches(rule, devices)).assertFalse();
    });

    it('正常_任一满足(ANY)有一条成立即可触发', 0, () => {
      const devices = DeviceFactory.createDefault();
      setEnv(devices, 'temperature', 25);
      setEnv(devices, 'humidity', 80);
      const rule = new Rule('r_any', 'ANY规则', true, 50, LogicMode.ANY, [
        new Condition('env', 'temperature', CompareOp.GT, 32),
        new Condition('env', 'humidity', CompareOp.GT, 75)
      ], [new RuleAction('ac_main', 'power', 1)], 0, 0, 0, Date.now());
      expect(RuleEngine.ruleMatches(rule, devices)).assertTrue();
    });

    it('正常_高温规则命中后生成空调开机动作', 0, () => {
      const devices = DeviceFactory.createDefault();
      setEnv(devices, 'temperature', 30.2);
      const rule = makeRule('r_cool', 90, new Condition('env', 'temperature', CompareOp.GTE, 28),
        new RuleAction('ac_main', 'power', 1), 0, 0);
      const plan: ExecutionPlan = RuleEngine.buildPlan([rule], devices, Date.now());
      expect(plan.matched.length).assertEqual(1);
      expect(plan.assignments.length).assertEqual(1);
      expect(plan.assignments[0].deviceId).assertEqual('ac_main');
      expect(plan.assignments[0].value).assertEqual(1);
      expect(plan.assignments[0].changed).assertTrue();
    });

    it('正常_动作写回设备后状态真实改变', 0, () => {
      const devices = DeviceFactory.createDefault();
      const ac = findDevice(devices, 'ac_main');
      expect(ac.getValue('power', 0)).assertEqual(0);
      expect(ac.setValue('power', 1)).assertTrue();
      expect(ac.getValue('power', 0)).assertEqual(1);
    });

    // ---------------- 边界场景 ----------------

    it('边界_浮点比较使用容差避免精度误判', 0, () => {
      expect(RuleEngine.compare(CompareOp.EQ, 28.04, 28)).assertTrue();
      expect(RuleEngine.compare(CompareOp.EQ, 28.06, 28)).assertFalse();
      expect(RuleEngine.compare(CompareOp.NE, 28.06, 28)).assertTrue();
    });

    it('边界_空条件规则永不触发', 0, () => {
      const devices = DeviceFactory.createDefault();
      const rule = new Rule('r_empty', '空条件', true, 50, LogicMode.ALL, [],
        [new RuleAction('light_main', 'power', 1)], 0, 0, 0, Date.now());
      expect(RuleEngine.ruleMatches(rule, devices)).assertFalse();
      expect(RuleEngine.buildPlan([rule], devices, Date.now()).matched.length).assertEqual(0);
    });

    it('边界_冷却时间临界点刚好可以再次执行', 0, () => {
      const now = Date.now();
      const devices = DeviceFactory.createDefault();
      setEnv(devices, 'temperature', 30);
      const rule = makeRule('r_cd', 90, new Condition('env', 'temperature', CompareOp.GT, 28),
        new RuleAction('ac_main', 'power', 1), 60, now - 60000);
      expect(RuleEngine.isCoolingDown(rule, now)).assertFalse();
      const plan = RuleEngine.buildPlan([rule], devices, now);
      expect(plan.matched.length).assertEqual(1);
    });

    it('边界_数值越界会被夹紧到属性范围内', 0, () => {
      const devices = DeviceFactory.createDefault();
      const light = findDevice(devices, 'light_main');
      light.setValue('level', 130);
      expect(light.getValue('level', 0)).assertEqual(100);
      light.setValue('level', -20);
      expect(light.getValue('level', 0)).assertEqual(0);
    });

    it('边界_环境模拟数值始终落在物理区间内', 0, () => {
      let t = 26;
      for (let i = 0; i < 300; i++) {
        t = EnvSimulator.nextTemperature(t);
        expect(t >= 12 && t <= 38).assertTrue();
      }
      expect(EnvSimulator.clamp(120, 0, 100)).assertEqual(100);
      expect(EnvSimulator.clamp(-5, 0, 100)).assertEqual(0);
    });

    // ---------------- 异常场景 ----------------

    it('异常_条件引用不存在的设备时按不满足处理且不崩溃', 0, () => {
      const devices = DeviceFactory.createDefault();
      const cond = new Condition('ghost_device', 'temperature', CompareOp.GT, 10);
      expect(RuleEngine.conditionHolds(cond, devices)).assertFalse();
    });

    it('异常_向只读传感器写动作会被拦截并记录原因', 0, () => {
      const devices = DeviceFactory.createDefault();
      setEnv(devices, 'temperature', 30);
      const rule = makeRule('r_bad', 90, new Condition('env', 'temperature', CompareOp.GT, 28),
        new RuleAction('env', 'humidity', 80), 0, 0);
      const plan = RuleEngine.buildPlan([rule], devices, Date.now());
      expect(plan.assignments.length).assertEqual(0);
      expect(plan.blocked.length).assertEqual(1);
      expect(plan.blocked[0].reason.indexOf('只读') >= 0).assertTrue();
      expect(sensorOf(devices).getValue('humidity', 0)).assertEqual(52);
    });

    it('异常_非法规则被校验拦截', 0, () => {
      const devices = DeviceFactory.createDefault();
      const bad = new Rule('r_invalid', '', false, 500, LogicMode.ALL, [],
        [new RuleAction('env', 'temperature', 99)], 9999, 0, 0, Date.now());
      const errors = RuleEngine.validateRule(bad, devices);
      expect(errors.length >= 4).assertTrue();
    });

    it('异常_空规则集合不会产生任何动作', 0, () => {
      const devices = DeviceFactory.createDefault();
      const plan = RuleEngine.buildPlan([], devices, Date.now());
      expect(plan.isEmpty()).assertTrue();
      expect(plan.assignments.length).assertEqual(0);
    });

    it('异常_高优先级规则抢占同一属性时低优先级被消解', 0, () => {
      const devices = DeviceFactory.createDefault();
      setEnv(devices, 'temperature', 33);
      const high = makeRule('r_high', 100, new Condition('env', 'temperature', CompareOp.GT, 32),
        new RuleAction('ac_main', 'power', 1), 0, 0);
      const low = makeRule('r_low', 10, new Condition('env', 'temperature', CompareOp.GT, 20),
        new RuleAction('ac_main', 'power', 0), 0, 0);
      const plan = RuleEngine.buildPlan([low, high], devices, Date.now());
      expect(plan.assignments.length).assertEqual(1);
      expect(plan.assignments[0].ruleId).assertEqual('r_high');
      expect(plan.conflicts.length).assertEqual(1);
    });
  });
}
