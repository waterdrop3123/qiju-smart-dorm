import { promptAction } from '@kit.ArkUI';
import { Condition, CompareOp, CompareOpUtil, LogicMode, Rule, RuleAction } from '../model/Rule';
import { PropCatalog, PropOption } from '../model/PropCatalog';
import { RulePresets } from '../model/RulePresets';
import { homeStore } from '../store/HomeStore';
import { Fonts, Metrics, Palette } from '../common/Theme';
import { Pill } from '../view/Widgets';

/**
 * 规则编辑页：条件组（属性 + 运算符 + 阈值）与动作组（属性 + 目标值）可视化配置。
 * 保存前调用 RuleEngine.validateRule 做校验，非法配置不会落库。
 */
@Component
export struct RuleEditPage {
  @StorageLink('qijuRev') rev: number = 0;
  @Consume('navStack') navStack: NavPathStack;
  @State draft: Rule = RulePresets.template(Date.now());

  aboutToAppear(): void {
    const exist = homeStore.ruleById(homeStore.editingRuleId);
    this.draft = exist === undefined ? RulePresets.template(Date.now()) : exist.copy();
  }

  private isNew(): boolean {
    return homeStore.ruleById(this.draft.id) === undefined;
  }

  private condOptions(): PropOption[] {
    return PropCatalog.options(homeStore.devices);
  }

  private actOptions(): PropOption[] {
    return PropCatalog.actionOptions(homeStore.devices);
  }

  private optLabel(c: Condition): string {
    const opt = PropCatalog.find(this.condOptions(), c.deviceId, c.propKey);
    return opt === undefined ? '选择属性' : opt.label();
  }

  private actLabel(a: RuleAction): string {
    const opt = PropCatalog.find(this.actOptions(), a.deviceId, a.propKey);
    return opt === undefined ? '选择属性' : opt.label();
  }

  private optMin(c: Condition): number {
    const opt = PropCatalog.find(this.condOptions(), c.deviceId, c.propKey);
    return opt === undefined ? 0 : opt.min;
  }

  private optMax(c: Condition): number {
    const opt = PropCatalog.find(this.condOptions(), c.deviceId, c.propKey);
    return opt === undefined ? 100 : opt.max;
  }

  private optStep(c: Condition): number {
    const opt = PropCatalog.find(this.condOptions(), c.deviceId, c.propKey);
    return opt === undefined ? 1 : opt.step;
  }

  private optValueText(c: Condition): string {
    const opt = PropCatalog.find(this.condOptions(), c.deviceId, c.propKey);
    return opt === undefined ? c.value.toString() : opt.format(c.value);
  }

  private optIsBool(c: Condition): boolean {
    const opt = PropCatalog.find(this.condOptions(), c.deviceId, c.propKey);
    return opt === undefined ? false : opt.isBoolean;
  }

  private actValueText(a: RuleAction): string {
    const opt = PropCatalog.find(this.actOptions(), a.deviceId, a.propKey);
    return opt === undefined ? a.value.toString() : opt.format(a.value);
  }

  private touch(): void {
    this.draft = this.draft.copy();
  }

  // ---------- 条件操作 ----------

  private condMenu(index: number): MenuElement[] {
    const list = this.condOptions();
    const items: MenuElement[] = [];
    for (let i = 0; i < list.length; i++) {
      items.push({
        value: list[i].label(),
        action: () => {
          const c = this.draft.conditions[index];
          c.deviceId = list[i].deviceId;
          c.propKey = list[i].propKey;
          c.value = list[i].min;
          this.touch();
        }
      });
    }
    return items;
  }

  private opMenu(index: number): MenuElement[] {
    const ops = CompareOpUtil.all();
    const items: MenuElement[] = [];
    for (let i = 0; i < ops.length; i++) {
      items.push({
        value: CompareOpUtil.label(ops[i]),
        action: () => {
          this.draft.conditions[index].op = ops[i];
          this.touch();
        }
      });
    }
    return items;
  }

  private addCondition(): void {
    const list = this.condOptions();
    const first = list.length > 0 ? list[0] : undefined;
    if (first === undefined) {
      return;
    }
    this.draft.conditions.push(new Condition(first.deviceId, first.propKey, CompareOp.GT, first.min));
    this.touch();
  }

  private removeCondition(index: number): void {
    if (this.draft.conditions.length <= 1) {
      promptAction.showToast({ message: '至少保留一条条件', duration: 1500 });
      return;
    }
    this.draft.conditions.splice(index, 1);
    this.touch();
  }

  // ---------- 动作操作 ----------

  private actMenu(index: number): MenuElement[] {
    const list = this.actOptions();
    const items: MenuElement[] = [];
    for (let i = 0; i < list.length; i++) {
      items.push({
        value: list[i].label(),
        action: () => {
          const a = this.draft.actions[index];
          a.deviceId = list[i].deviceId;
          a.propKey = list[i].propKey;
          a.value = list[i].min;
          this.touch();
        }
      });
    }
    return items;
  }

  private addAction(): void {
    const list = this.actOptions();
    const first = list.length > 0 ? list[0] : undefined;
    if (first === undefined) {
      return;
    }
    this.draft.actions.push(new RuleAction(first.deviceId, first.propKey, first.min));
    this.touch();
  }

  private removeAction(index: number): void {
    if (this.draft.actions.length <= 1) {
      promptAction.showToast({ message: '至少保留一个动作', duration: 1500 });
      return;
    }
    this.draft.actions.splice(index, 1);
    this.touch();
  }

  private save(): void {
    const errors = homeStore.saveRule(this.draft);
    if (errors.length > 0) {
      promptAction.showToast({ message: errors[0], duration: 2200 });
      return;
    }
    promptAction.showToast({ message: '规则已保存并立即生效', duration: 1600 });
    this.navStack.pop();
  }

  @Builder
  chip(text: string, active: boolean, onTap: () => void) {
    Text(text)
      .fontSize(Fonts.caption)
      .fontColor(active ? Palette.white : Palette.textSecondary)
      .backgroundColor(active ? Palette.primary : Palette.page)
      .borderRadius(14)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .onClick(() => {
        onTap();
      })
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column({ space: Metrics.gap }) {
            // 基本信息
            Column({ space: 10 }) {
              Text('规则名称')
                .fontSize(Fonts.caption)
                .fontColor(Palette.textMuted)
                .width('100%')
              TextInput({ text: this.draft.name, placeholder: '例如：高温自动降温' })
                .height(44)
                .borderRadius(10)
                .backgroundColor(Palette.page)
                .fontSize(Fonts.body)
                .onChange((value: string) => {
                  this.draft.name = value;
                })

              Row() {
                Text('条件组合方式')
                  .fontSize(Fonts.caption)
                  .fontColor(Palette.textMuted)
                Blank()
                this.chip('全部满足', this.draft.logic === LogicMode.ALL, () => {
                  this.draft.logic = LogicMode.ALL;
                  this.touch();
                })
                Row().width(6)
                this.chip('任一满足', this.draft.logic === LogicMode.ANY, () => {
                  this.draft.logic = LogicMode.ANY;
                  this.touch();
                })
              }
              .width('100%')

              Row() {
                Text('优先级')
                  .fontSize(Fonts.caption)
                  .fontColor(Palette.textMuted)
                Slider({ value: this.draft.priority, min: 1, max: 99, step: 1 })
                  .selectedColor(Palette.accent)
                  .layoutWeight(1)
                  .margin({ left: 10, right: 10 })
                  .onChange((value: number, mode: SliderChangeMode) => {
                    if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                      this.draft.priority = Math.round(value);
                      this.touch();
                    }
                  })
                Text('P' + this.draft.priority.toString())
                  .fontSize(Fonts.caption)
                  .fontColor(Palette.accent)
                  .width(32)
              }
              .width('100%')

              Row() {
                Text('冷却时间')
                  .fontSize(Fonts.caption)
                  .fontColor(Palette.textMuted)
                Slider({ value: this.draft.cooldownSec, min: 0, max: 600, step: 30 })
                  .selectedColor(Palette.info)
                  .layoutWeight(1)
                  .margin({ left: 10, right: 10 })
                  .onChange((value: number, mode: SliderChangeMode) => {
                    if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                      this.draft.cooldownSec = Math.round(value);
                      this.touch();
                    }
                  })
                Text(this.draft.cooldownSec.toString() + 's')
                  .fontSize(Fonts.caption)
                  .fontColor(Palette.info)
                  .width(40)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Palette.card)
            .borderRadius(Metrics.radius)

            // 条件
            Column({ space: 10 }) {
              Row() {
                Text('触发条件')
                  .fontSize(Fonts.section)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Palette.text)
                Blank()
                Text('＋ 添加条件')
                  .fontSize(Fonts.caption)
                  .fontColor(Palette.primary)
                  .onClick(() => {
                    this.addCondition();
                  })
              }
              .width('100%')

              ForEach(this.draft.conditions, (item: Condition, index: number) => {
                Column({ space: 8 }) {
                  Row({ space: 8 }) {
                    Text(this.optLabel(item))
                      .fontSize(Fonts.body)
                      .fontColor(Palette.text)
                      .layoutWeight(1)
                      .bindMenu(this.condMenu(index))
                    Text('✕')
                      .fontSize(Fonts.caption)
                      .fontColor(Palette.textMuted)
                      .padding(4)
                      .onClick(() => {
                        this.removeCondition(index);
                      })
                  }
                  .width('100%')

                  Row({ space: 8 }) {
                    Text(CompareOpUtil.label(item.op))
                      .fontSize(Fonts.caption)
                      .fontColor(Palette.primary)
                      .backgroundColor(Palette.primarySoft)
                      .borderRadius(8)
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                      .bindMenu(this.opMenu(index))

                    if (this.optIsBool(item)) {
                      Toggle({ type: ToggleType.Switch, isOn: item.value >= 1 })
                        .selectedColor(Palette.primary)
                        .onChange((isOn: boolean) => {
                          this.draft.conditions[index].value = isOn ? 1 : 0;
                          this.touch();
                        })
                      Blank()
                    } else {
                      Slider({
                        value: item.value,
                        min: this.optMin(item),
                        max: this.optMax(item),
                        step: this.optStep(item)
                      })
                        .selectedColor(Palette.primary)
                        .layoutWeight(1)
                        .onChange((value: number, mode: SliderChangeMode) => {
                          if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                            this.draft.conditions[index].value = Math.round(value * 10) / 10;
                            this.touch();
                          }
                        })
                    }

                    Text(this.optValueText(item))
                      .fontSize(Fonts.caption)
                      .fontColor(Palette.text)
                      .width(64)
                      .textAlign(TextAlign.End)
                  }
                  .width('100%')
                }
                .width('100%')
                .padding(12)
                .backgroundColor(Palette.page)
                .borderRadius(10)
              }, (item: Condition, index: number) => item.deviceId + item.propKey + index.toString())
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Palette.card)
            .borderRadius(Metrics.radius)

            // 动作
            Column({ space: 10 }) {
              Row() {
                Text('执行动作')
                  .fontSize(Fonts.section)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Palette.text)
                Blank()
                Text('＋ 添加动作')
                  .fontSize(Fonts.caption)
                  .fontColor(Palette.primary)
                  .onClick(() => {
                    this.addAction();
                  })
              }
              .width('100%')

              ForEach(this.draft.actions, (item: RuleAction, index: number) => {
                Column({ space: 8 }) {
                  Row({ space: 8 }) {
                    Text(this.actLabel(item))
                      .fontSize(Fonts.body)
                      .fontColor(Palette.text)
                      .layoutWeight(1)
                      .bindMenu(this.actMenu(index))
                    Text('✕')
                      .fontSize(Fonts.caption)
                      .fontColor(Palette.textMuted)
                      .padding(4)
                      .onClick(() => {
                        this.removeAction(index);
                      })
                  }
                  .width('100%')

                  Row({ space: 8 }) {
                    Text('设为')
                      .fontSize(Fonts.caption)
                      .fontColor(Palette.accent)
                      .backgroundColor(Palette.accentSoft)
                      .borderRadius(8)
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    if (this.optIsBool(this.actionAsCondition(item))) {
                      Toggle({ type: ToggleType.Switch, isOn: item.value >= 1 })
                        .selectedColor(Palette.accent)
                        .onChange((isOn: boolean) => {
                          this.draft.actions[index].value = isOn ? 1 : 0;
                          this.touch();
                        })
                      Blank()
                    } else {
                      Slider({
                        value: item.value,
                        min: this.actMin(item),
                        max: this.actMax(item),
                        step: this.actStep(item)
                      })
                        .selectedColor(Palette.accent)
                        .layoutWeight(1)
                        .onChange((value: number, mode: SliderChangeMode) => {
                          if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                            this.draft.actions[index].value = Math.round(value * 10) / 10;
                            this.touch();
                          }
                        })
                    }
                    Text(this.actValueText(item))
                      .fontSize(Fonts.caption)
                      .fontColor(Palette.text)
                      .width(64)
                      .textAlign(TextAlign.End)
                  }
                  .width('100%')
                }
                .width('100%')
                .padding(12)
                .backgroundColor(Palette.page)
                .borderRadius(10)
              }, (item: RuleAction, index: number) => item.deviceId + item.propKey + index.toString())
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Palette.card)
            .borderRadius(Metrics.radius)

            // 预览
            Column({ space: 6 }) {
              Text('规则预览')
                .fontSize(Fonts.caption)
                .fontColor(Palette.textMuted)
                .width('100%')
              Text('当 ' + this.draft.conditionText(homeStore.devices))
                .fontSize(Fonts.caption)
                .fontColor(Palette.textSecondary)
                .width('100%')
              Text('则 ' + this.draft.actionText(homeStore.devices))
                .fontSize(Fonts.caption)
                .fontColor(Palette.textSecondary)
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Palette.primarySoft)
            .borderRadius(Metrics.radius)
            .margin({ bottom: 12 })
          }
          .width('100%')
          .padding({ left: Metrics.page, right: Metrics.page, top: 8 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // 底部操作栏
        Row({ space: 12 }) {
          if (!this.isNew()) {
            Button('删除')
              .fontColor(Palette.danger)
              .backgroundColor(Palette.dangerSoft)
              .height(44)
              .borderRadius(22)
              .layoutWeight(1)
              .onClick(() => {
                AlertDialog.show({
                  title: '删除规则',
                  message: '删除后无法恢复，确定继续？',
                  autoCancel: true,
                  primaryButton: {
                    value: '取消',
                    action: () => {
                    }
                  },
                  secondaryButton: {
                    value: '删除',
                    fontColor: Palette.danger,
                    action: () => {
                      homeStore.deleteRule(this.draft.id);
                      this.navStack.pop();
                    }
                  }
                });
              })
          }
          Button('保存规则')
            .fontColor(Palette.white)
            .backgroundColor(Palette.primary)
            .height(44)
            .borderRadius(22)
            .layoutWeight(2)
            .onClick(() => {
              this.save();
            })
        }
        .width('100%')
        .padding({ left: Metrics.page, right: Metrics.page, top: 8, bottom: 12 })
        .backgroundColor(Palette.card)
      }
      .width('100%')
      .height('100%')
    }
    .title(this.isNew() ? '新建规则' : '编辑规则')
    .backgroundColor(Palette.page)
    .onBackPressed(() => {
      this.navStack.pop();
      return true;
    })
  }

  private actionAsCondition(a: RuleAction): Condition {
    return new Condition(a.deviceId, a.propKey, CompareOp.EQ, a.value);
  }

  private actMin(a: RuleAction): number {
    const opt = PropCatalog.find(this.actOptions(), a.deviceId, a.propKey);
    return opt === undefined ? 0 : opt.min;
  }

  private actMax(a: RuleAction): number {
    const opt = PropCatalog.find(this.actOptions(), a.deviceId, a.propKey);
    return opt === undefined ? 100 : opt.max;
  }

  private actStep(a: RuleAction): number {
    const opt = PropCatalog.find(this.actOptions(), a.deviceId, a.propKey);
    return opt === undefined ? 1 : opt.step;
  }
}
