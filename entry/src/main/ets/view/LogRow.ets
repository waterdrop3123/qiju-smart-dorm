import { LogEntry, LogKind } from '../model/LogEntry';
import { Fonts, Palette } from '../common/Theme';
import { Fmt } from '../common/Formats';

/** 单条执行日志（日志对象不可变，直接作为属性传入即可） */
@Component
export struct LogRow {
  @Prop entry: LogEntry = new LogEntry('', 0, LogKind.SYSTEM, '', '', '', '', true, '');

  private accent(): string {
    switch (this.entry.kind) {
      case LogKind.AUTOMATION:
        return Palette.primary;
      case LogKind.MANUAL:
        return Palette.info;
      case LogKind.SCENE:
        return Palette.accent;
      case LogKind.BLOCKED:
        return Palette.danger;
      default:
        return Palette.textMuted;
    }
  }

  build() {
    Row({ space: 10 }) {
      Column()
        .width(3)
        .height('100%')
        .borderRadius(2)
        .backgroundColor(this.accent())

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(this.entry.title)
            .fontSize(Fonts.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Palette.text)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.entry.kindLabel())
            .fontSize(Fonts.micro)
            .fontColor(this.accent())
          Text(Fmt.time(this.entry.ts))
            .fontSize(Fonts.micro)
            .fontColor(Palette.textMuted)
        }
        .width('100%')

        Text(this.entry.detail)
          .fontSize(Fonts.caption)
          .fontColor(Palette.textSecondary)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(Palette.card)
    .borderRadius(10)
  }
}
