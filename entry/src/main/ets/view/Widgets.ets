import { Fonts, Metrics, Palette } from '../common/Theme';

/** 区块标题：左标题 + 右操作/说明 */
@Component
export struct SectionHeader {
  @Prop title: string = '';
  @Prop hint: string = '';
  @Prop action: string = '';
  onAction: () => void = () => {
  };

  build() {
    Row() {
      Text(this.title)
        .fontSize(Fonts.section)
        .fontWeight(FontWeight.Bold)
        .fontColor(Palette.text)
      if (this.hint.length > 0) {
        Text(this.hint)
          .fontSize(Fonts.caption)
          .fontColor(Palette.textMuted)
          .margin({ left: 8 })
      }
      Blank()
      if (this.action.length > 0) {
        Text(this.action)
          .fontSize(Fonts.caption)
          .fontColor(Palette.primary)
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 12, bottom: 8 })
  }
}

/** 小标签：用于优先级、状态等 */
@Component
export struct Pill {
  @Prop text: string = '';
  @Prop color: string = Palette.primary;
  @Prop bg: string = Palette.primarySoft;

  build() {
    Text(this.text)
      .fontSize(Fonts.micro + 1)
      .fontColor(this.color)
      .backgroundColor(this.bg)
      .borderRadius(6)
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
  }
}

/** 空状态 */
@Component
export struct EmptyView {
  @Prop icon: string = '🌿';
  @Prop title: string = '暂无数据';
  @Prop hint: string = '';

  build() {
    Column({ space: 8 }) {
      Text(this.icon)
        .fontSize(40)
      Text(this.title)
        .fontSize(Fonts.body)
        .fontColor(Palette.textSecondary)
      if (this.hint.length > 0) {
        Text(this.hint)
          .fontSize(Fonts.caption)
          .fontColor(Palette.textMuted)
      }
    }
    .width('100%')
    .padding({ top: 48, bottom: 48 })
    .justifyContent(FlexAlign.Center)
  }
}

/** 环境指标块 */
@Component
export struct StatTile {
  @Prop icon: string = '📊';
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop unit: string = '';
  @Prop tint: string = Palette.primarySoft;
  @Prop highlight: boolean = false;

  build() {
    Column({ space: 6 }) {
      Row() {
        Text(this.icon).fontSize(14)
        Text(this.label)
          .fontSize(Fonts.micro + 1)
          .fontColor(this.highlight ? '#D9F2EE' : Palette.textMuted)
          .margin({ left: 4 })
      }
      .width('100%')

      Row() {
        Text(this.value)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highlight ? Palette.white : Palette.text)
        Text(this.unit)
          .fontSize(Fonts.caption)
          .fontColor(this.highlight ? '#CFEAE6' : Palette.textMuted)
          .margin({ left: 2, bottom: 2 })
      }
      .alignItems(VerticalAlign.Bottom)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(this.highlight ? 12 : 10)
    .borderRadius(Metrics.radiusSm)
    .backgroundColor(this.highlight ? '#FFFFFF1A' : Palette.page)
    .layoutWeight(1)
  }
}

/** 细进度条 */
@Component
export struct MiniBar {
  @Prop value: number = 0;
  @Prop color: string = Palette.primary;

  build() {
    Stack({ alignContent: Alignment.Start }) {
      Row()
        .width('100%')
        .height(5)
        .borderRadius(3)
        .backgroundColor(Palette.line)
      Row()
        .width((this.value < 0 ? 0 : (this.value > 100 ? 100 : this.value)).toString() + '%')
        .height(5)
        .borderRadius(3)
        .backgroundColor(this.color)
        .animation({ duration: 280, curve: Curve.EaseOut })
    }
    .width('100%')
    .height(5)
  }
}
