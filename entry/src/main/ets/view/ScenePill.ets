import { promptAction } from '@kit.ArkUI';
import { homeStore } from '../store/HomeStore';
import { Fonts, Palette } from '../common/Theme';

/** 快捷场景按钮：一键执行一组动作 */
@Component
export struct ScenePill {
  @Prop sceneId: string = '';

  private name(): string {
    const s = homeStore.sceneById(this.sceneId);
    return s === undefined ? '' : s.name;
  }

  private icon(): string {
    const s = homeStore.sceneById(this.sceneId);
    return s === undefined ? '✨' : s.icon;
  }

  private hint(): string {
    const s = homeStore.sceneById(this.sceneId);
    return s === undefined ? '' : s.hint;
  }

  build() {
    Column({ space: 4 }) {
      Text(this.icon())
        .fontSize(20)
      Text(this.name())
        .fontSize(Fonts.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(Palette.text)
      Text(this.hint())
        .fontSize(Fonts.micro)
        .fontColor(Palette.textMuted)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .width(112)
    .padding(12)
    .borderRadius(14)
    .backgroundColor(Palette.card)
    .border({ width: 1, color: Palette.line })
    .onClick(() => {
      const changed = homeStore.applyScene(this.sceneId);
      promptAction.showToast({
        message: changed > 0 ? '「' + this.name() + '」已执行，' + changed.toString() + ' 个设备状态更新' : '设备已处于该场景状态',
        duration: 1800
      });
    })
  }
}
