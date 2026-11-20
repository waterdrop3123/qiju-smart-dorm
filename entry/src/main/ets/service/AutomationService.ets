import { Assignment, BlockedRule, ExecutionPlan } from './RuleEngine';

/**
 * 执行计划的文本化（纯函数）：把引擎的结果翻译成可读日志，供界面与报告展示。
 */
export class AutomationService {
  static brief(plan: ExecutionPlan): string {
    if (plan.matched.length === 0) {
      return '本轮没有规则命中';
    }
    return plan.matched.length.toString() + ' 条规则命中，共 ' +
      plan.assignments.length.toString() + ' 个写动作';
  }

  static changedText(plan: ExecutionPlan): string {
    const changed: Assignment[] = plan.changedAssignments();
    if (changed.length === 0) {
      return '条件命中，但所有设备已处于目标状态';
    }
    const parts: string[] = [];
    for (let i = 0; i < changed.length; i++) {
      parts.push(changed[i].describe());
    }
    return parts.join('；');
  }

  static ruleNames(plan: ExecutionPlan): string {
    const names: string[] = [];
    for (let i = 0; i < plan.matched.length; i++) {
      names.push('「' + plan.matched[i].name + '」');
    }
    return names.join('、');
  }

  static conflictText(conflicts: BlockedRule[]): string {
    const parts: string[] = [];
    for (let i = 0; i < conflicts.length; i++) {
      parts.push(conflicts[i].reason);
    }
    return parts.join('；');
  }

  static blockedText(blocked: BlockedRule[]): string {
    const parts: string[] = [];
    for (let i = 0; i < blocked.length; i++) {
      parts.push('「' + blocked[i].ruleName + '」' + blocked[i].reason);
    }
    return parts.join('；');
  }
}
