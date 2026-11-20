import abilityTest from './Ability.test';
import ruleEngineDeviceSuite from './RuleEngine.test';

export default function testsuite() {
  abilityTest();
  ruleEngineDeviceSuite();
}
