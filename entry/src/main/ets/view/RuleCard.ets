import { homeStore } from '../store/HomeStore';
import { Rule } from '../model/Rule';
import { Fonts, Metrics, Palette } from '../common/Theme';
import { Fmt } from '../common/Formats';
import { Pill } from './Widgets';

/** 规则卡片：条件 → 动作，含启用开关与优先级 */
@Component
export struct RuleCard {
  @Prop ruleId: string = '';
  @StorageLink('qijuRev') rev: number = 0;
  onOpen: () => void = () => {
  };

  private rule(): Rule | undefined {
    return homeStore.ruleById(this.ruleId);
  }

  private name(): string {
    const r = this.rule();
    return r === undefined ? '规则' : r.name;
  }

  private isEnabled(): boolean {
    const r = this.rule();
    return r === undefined ? false : r.enabled;
  }

  private priority(): number {
    const r = this.rule();
    return r === undefined ? 0 : r.priority;
  }

  private conditionText(): string {
    const r = this.rule();
    return r === undefined ? '' : r.conditionText(homeStore.devices);
  }

  private actionText(): string {
    const r = this.rule();
    return r === undefined ? '' : r.actionText(homeStore.devices);
  }

  private lastText(): string {
    const r = this.rule();
    if (r === undefined || r.lastFiredAt <= 0) {
      return '尚未触发';
    }
    return Fmt.duration(Date.now() - r.lastFiredAt) + ' · 累计 ' + r.fireCount.toString() + ' 次';
  }

  private logicText(): string {
    const r = this.rule();
    if (r === undefined) {
      return '';
    }
    return r.logic === 'any' ? '任一满足' : '全部满足';
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(this.name())
          .fontSize(Fonts.body + 1)
          .fontWeight(FontWeight.Bold)
          .fontColor(Palette.text)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Toggle({ type: ToggleType.Switch, isOn: this.isEnabled() })
          .selectedColor(Palette.primary)
          .switchPointColor(Palette.white)
          .width(40)
          .height(24)
          .onChange(() => {
            homeStore.toggleRule(this.ruleId);
          })
      }
      .width('100%')

      Row({ space: 6 }) {
        Pill({ text: 'P' + this.priority().toString(), color: Palette.accent, bg: Palette.accentSoft })
        Pill({ text: this.logicText(), color: Palette.info, bg: Palette.infoSoft })
        Pill({ text: this.lastText(), color: Palette.textSecondary, bg: Palette.page })
      }
      .width('100%')

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text('当')
            .fontSize(Fonts.micro + 1)
            .fontColor(Palette.white)
            .backgroundColor(Palette.primary)
            .borderRadius(4)
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          Text(this.conditionText())
            .fontSize(Fonts.caption)
            .fontColor(Palette.textSecondary)
            .layoutWeight(1)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(VerticalAlign.Top)

        Row({ space: 6 }) {
          Text('则')
            .fontSize(Fonts.micro + 1)
            .fontColor(Palette.white)
            .backgroundColor(Palette.accent)
            .borderRadius(4)
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          Text(this.actionText())
            .fontSize(Fonts.caption)
            .fontColor(Palette.textSecondary)
            .layoutWeight(1)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(VerticalAlign.Top)
      }
      .width('100%')
      .padding(10)
      .borderRadius(Metrics.radiusXs)
      .backgroundColor(Palette.page)
      .opacity(this.isEnabled() ? 1 : 0.55)
    }
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .borderRadius(Metrics.radiusSm + 2)
    .backgroundColor(Palette.card)
    .shadow({ radius: 10, color: '#0D0B1F2A', offsetY: 3 })
    .onClick(() => {
      this.onOpen();
    })
  }
}
