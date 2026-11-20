import { promptAction } from '@kit.ArkUI';
import { LogEntry, LogKind } from '../../model/LogEntry';
import { homeStore } from '../../store/HomeStore';
import { Fmt } from '../../common/Formats';
import { Fonts, Metrics, Palette } from '../../common/Theme';
import { LogRow } from '../../view/LogRow';
import { EmptyView } from '../../view/Widgets';

/** 日志页：按类型筛选，展示规则自动执行与手动操作的完整轨迹 */
@Component
export struct LogsTab {
  @StorageLink('qijuRev') @Watch('syncCounts') rev: number = 0;
  @State filter: number = 0;
  @State totalCount: number = 0;
  @State autoCount: number = 0;
  @State manualCount: number = 0;

  aboutToAppear(): void {
    this.syncCounts();
  }

  // 用 @State 承接统计值：只读 homeStore.logs 时，切到本页后新增的日志不会刷新表头
  syncCounts(): void {
    this.totalCount = homeStore.logs.length;
    this.autoCount = this.countOf(LogKind.AUTOMATION);
    this.manualCount = this.countOf(LogKind.MANUAL);
  }

  private labels(): string[] {
    return ['全部', '自动', '手动', '场景', '冲突'];
  }

  private filtered(): LogEntry[] {
    if (this.filter === 0) {
      return homeStore.logs;
    }
    let kind: LogKind = LogKind.AUTOMATION;
    if (this.filter === 2) {
      kind = LogKind.MANUAL;
    } else if (this.filter === 3) {
      kind = LogKind.SCENE;
    } else if (this.filter === 4) {
      kind = LogKind.BLOCKED;
    }
    const out: LogEntry[] = [];
    for (let i = 0; i < homeStore.logs.length; i++) {
      if (homeStore.logs[i].kind === kind) {
        out.push(homeStore.logs[i]);
      }
    }
    return out;
  }

  private countOf(kind: LogKind): number {
    let n = 0;
    for (let i = 0; i < homeStore.logs.length; i++) {
      if (homeStore.logs[i].kind === kind) {
        n = n + 1;
      }
    }
    return n;
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        Column({ space: 2 }) {
          Text('执行日志')
            .fontSize(Fonts.title)
            .fontWeight(FontWeight.Bold)
            .fontColor(Palette.text)
          Text('共 ' + this.totalCount.toString() + ' 条 · 自动 ' +
            this.autoCount.toString() + ' · 手动 ' +
            this.manualCount.toString())
            .fontSize(Fonts.micro + 1)
            .fontColor(Palette.textMuted)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Text('清空')
          .fontSize(Fonts.caption)
          .fontColor(Palette.danger)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(Palette.dangerSoft)
          .borderRadius(8)
          .onClick(() => {
            AlertDialog.show({
              title: '清空日志',
              message: '将删除全部执行记录（不影响设备与规则），确定继续？',
              autoCancel: true,
              primaryButton: {
                value: '取消',
                action: () => {
                }
              },
              secondaryButton: {
                value: '清空',
                fontColor: Palette.danger,
                action: () => {
                  homeStore.clearLogs();
                  promptAction.showToast({ message: '日志已清空', duration: 1500 });
                }
              }
            });
          })
      }
      .width('100%')
      .padding({ left: Metrics.page, right: Metrics.page, top: 8 })

      Row({ space: 8 }) {
        ForEach(this.labels(), (label: string, index: number) => {
          Text(label)
            .fontSize(Fonts.caption)
            .fontColor(this.filter === index ? Palette.white : Palette.textSecondary)
            .backgroundColor(this.filter === index ? Palette.primary : Palette.card)
            .borderRadius(14)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .onClick(() => {
              this.filter = index;
            })
        }, (label: string) => label)
      }
      .width('100%')
      .padding({ left: Metrics.page, right: Metrics.page })

      if (this.filtered().length === 0) {
        EmptyView({ icon: '🗒️', title: '暂无日志', hint: '规则命中或手动操作后会在这里留痕' })
      } else {
        List({ space: 8 }) {
          ForEach(this.filtered(), (entry: LogEntry) => {
            ListItem() {
              LogRow({ entry: entry })
            }
          }, (entry: LogEntry) => entry.id)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: Metrics.page, right: Metrics.page })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Palette.page)
  }
}
