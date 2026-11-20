import { RuleAction } from './Rule';

/**
 * 快捷场景：一组预置动作，一键执行（独立于规则引擎，用于对比"手动场景"与"自动规则"）。
 */
export class Scene {
  id: string;
  name: string;
  icon: string;
  hint: string;
  actions: RuleAction[];

  constructor(id: string, name: string, icon: string, hint: string, actions: RuleAction[]) {
    this.id = id;
    this.name = name;
    this.icon = icon;
    this.hint = hint;
    this.actions = actions;
  }

  copy(): Scene {
    const list: RuleAction[] = [];
    for (let i = 0; i < this.actions.length; i++) {
      list.push(this.actions[i].copy());
    }
    return new Scene(this.id, this.name, this.icon, this.hint, list);
  }
}

export class SceneFactory {
  static createDefault(): Scene[] {
    const list: Scene[] = [];
    list.push(new Scene('scene_sleep', '就寝', '🌙', '熄灯 · 合帘 · 锁门', [
      new RuleAction('light_main', 'power', 0),
      new RuleAction('light_desk', 'power', 0),
      new RuleAction('curtain_main', 'position', 0),
      new RuleAction('lock_door', 'locked', 1)
    ]));
    list.push(new Scene('scene_wake', '起床', '☀️', '开帘 · 亮灯 · 关空调', [
      new RuleAction('curtain_main', 'position', 100),
      new RuleAction('light_main', 'power', 1),
      new RuleAction('ac_main', 'power', 0)
    ]));
    list.push(new Scene('scene_leave', '离家', '🚪', '断电 · 关灯 · 关空调', [
      new RuleAction('socket_desk', 'power', 0),
      new RuleAction('light_main', 'power', 0),
      new RuleAction('ac_main', 'power', 0),
      new RuleAction('lock_door', 'locked', 1)
    ]));
    list.push(new Scene('scene_home', '回寝', '🏠', '开灯 · 解锁 · 通风', [
      new RuleAction('lock_door', 'locked', 0),
      new RuleAction('light_main', 'power', 1),
      new RuleAction('curtain_main', 'position', 60)
    ]));
    return list;
  }
}
