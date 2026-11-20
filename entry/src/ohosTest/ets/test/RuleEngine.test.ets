import { describe, it, expect } from '@ohos/hypium';
import { Device, DeviceFactory, DeviceType } from '../../../main/ets/model/Device';
import { CompareOp, Condition, LogicMode, Rule, RuleAction } from '../../../main/ets/model/Rule';
import { ExecutionPlan, RuleEngine } from '../../../main/ets/service/RuleEngine';

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

/**
 * 设备侧（Instrument Test）核心规则回归：验证真机/模拟器环境下引擎与设备模型的行为
 * 与本地单元测试保持一致。
 */
export default function ruleEngineDeviceSuite() {
  describe('RuleEngineOnDevice', () => {
    it('device_高温规则命中并生成执行计划', 0, () => {
      const devices = DeviceFactory.createDefault();
      setEnv(devices, 'temperature', 30.5);
      const rule = new Rule('r_cool', '高温降温', true, 90, LogicMode.ALL,
        [new Condition('env', 'temperature', CompareOp.GTE, 28)],
        [new RuleAction('ac_main', 'power', 1), new RuleAction('ac_main', 'targetTemp', 24)],
        0, 0, 0, Date.now());
      const plan: ExecutionPlan = RuleEngine.buildPlan([rule], devices, Date.now());
      expect(plan.matched.length).assertEqual(1);
      expect(plan.assignments.length).assertEqual(2);
    });

    it('device_优先级冲突时高优先级生效', 0, () => {
      const devices = DeviceFactory.createDefault();
      setEnv(devices, 'temperature', 34);
      const high = new Rule('r_high', '自保', true, 100, LogicMode.ALL,
        [new Condition('env', 'temperature', CompareOp.GT, 32)],
        [new RuleAction('ac_main', 'power', 1)], 0, 0, 0, Date.now());
      const low = new Rule('r_low', '降温', true, 10, LogicMode.ALL,
        [new Condition('env', 'temperature', CompareOp.GT, 20)],
        [new RuleAction('ac_main', 'power', 0)], 0, 0, 0, Date.now());
      const plan = RuleEngine.buildPlan([low, high], devices, Date.now());
      expect(plan.assignments[0].ruleId).assertEqual('r_high');
      expect(plan.conflicts.length).assertEqual(1);
    });

    it('device_只读传感器写入被拦截', 0, () => {
      const devices = DeviceFactory.createDefault();
      setEnv(devices, 'temperature', 30);
      const rule = new Rule('r_bad', '非法写入', true, 90, LogicMode.ALL,
        [new Condition('env', 'temperature', CompareOp.GT, 28)],
        [new RuleAction('env', 'humidity', 80)], 0, 0, 0, Date.now());
      const plan = RuleEngine.buildPlan([rule], devices, Date.now());
      expect(plan.assignments.length).assertEqual(0);
      expect(plan.blocked.length).assertEqual(1);
    });
  });
}
