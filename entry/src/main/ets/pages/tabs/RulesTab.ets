import { promptAction } from '@kit.ArkUI';
import { Rule } from '../../model/Rule';
import { homeStore } from '../../store/HomeStore';
import { Fonts, Metrics, Palette } from '../../common/Theme';
import { RuleCard } from '../../view/RuleCard';
import { EmptyView } from '../../view/Widgets';

/** 规则列表：按优先级排序，支持启停、左滑删除、进入编辑、新建 */
@Component
export struct RulesTab {
  @StorageLink('qijuRev') rev: number = 0;
  onEdit: (ruleId: string) => void = () => {
  };
  onNew: () => void = () => {
  };

  private sorted(): Rule[] {
    const list = homeStore.rules.slice();
    list.sort((a: Rule, b: Rule): number => {
      if (b.priority !== a.priority) {
        return b.priority - a.priority;
      }
      return a.id < b.id ? -1 : 1;
    });
    return list;
  }

  @Builder
  deleteAction(ruleId: string) {
    Column() {
      Text('删除')
        .fontSize(Fonts.body)
        .fontColor(Palette.white)
    }
    .width(72)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Palette.danger)
    .borderRadius(12)
    .onClick(() => {
      homeStore.deleteRule(ruleId);
      promptAction.showToast({ message: '规则已删除', duration: 1500 });
    })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column({ space: 10 }) {
        Row() {
          Column({ space: 2 }) {
            Text('自动化规则')
              .fontSize(Fonts.title)
              .fontWeight(FontWeight.Bold)
              .fontColor(Palette.text)
            Text('条件满足即自动执行，冲突按优先级仲裁')
              .fontSize(Fonts.micro + 1)
              .fontColor(Palette.textMuted)
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Text(homeStore.stats().activeRules.toString() + '/' + homeStore.rules.length.toString())
            .fontSize(Fonts.caption)
            .fontColor(Palette.primary)
            .backgroundColor(Palette.primarySoft)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
        }
        .width('100%')
        .padding({ left: Metrics.page, right: Metrics.page, top: 8, bottom: 4 })

        if (homeStore.rules.length === 0) {
          EmptyView({ icon: '🧩', title: '还没有规则', hint: '点击右下角新建一条自动化规则' })
        } else {
          List({ space: 10 }) {
            ForEach(this.sorted(), (rule: Rule) => {
              ListItem() {
                RuleCard({
                  ruleId: rule.id,
                  onOpen: () => {
                    this.onEdit(rule.id);
                  }
                })
              }
              .swipeAction({ end: this.deleteAction(rule.id) })
            }, (rule: Rule) => rule.id)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: Metrics.page, right: Metrics.page })
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')

      Button('＋ 新建规则')
        .fontSize(Fonts.body)
        .fontColor(Palette.white)
        .backgroundColor(Palette.primary)
        .height(44)
        .borderRadius(22)
        .padding({ left: 20, right: 20 })
        .margin({ right: Metrics.page, bottom: 20 })
        .shadow({ radius: 14, color: '#550F6B60', offsetY: 6 })
        .onClick(() => {
          this.onNew();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Palette.page)
  }
}
