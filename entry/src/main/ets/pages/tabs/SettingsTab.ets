import { promptAction } from '@kit.ArkUI';
import { homeStore } from '../../store/HomeStore';
import { Fmt } from '../../common/Formats';
import { Fonts, Metrics, Palette } from '../../common/Theme';
import { Pill } from '../../view/Widgets';

/** 设置页：环境模拟开关、持久化操作、关于信息 */
@Component
export struct SettingsTab {
  @StorageLink('qijuRev') rev: number = 0;

  @Builder
  row(title: string, value: string, danger: boolean, action: () => void) {
    Row() {
      Text(title)
        .fontSize(Fonts.body)
        .fontColor(danger ? Palette.danger : Palette.text)
      Blank()
      Text(value)
        .fontSize(Fonts.caption)
        .fontColor(Palette.textMuted)
      Text('›')
        .fontSize(Fonts.section)
        .fontColor(Palette.textMuted)
        .margin({ left: 6 })
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .onClick(() => {
      action();
    })
  }

  build() {
    Scroll() {
      Column({ space: Metrics.gap }) {
        Column({ space: 2 }) {
          Text('设置')
            .fontSize(Fonts.title)
            .fontWeight(FontWeight.Bold)
            .fontColor(Palette.text)
          Text('数据、模拟与关于')
            .fontSize(Fonts.micro + 1)
            .fontColor(Palette.textMuted)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .margin({ top: 8 })

        // 环境模拟
        Column({ space: 8 }) {
          Row() {
            Column({ space: 2 }) {
              Text('环境模拟')
                .fontSize(Fonts.body)
                .fontWeight(FontWeight.Medium)
                .fontColor(Palette.text)
              Text('每 ' + (homeStore.tickMs / 1000).toString() + ' 秒演化温度/湿度/光照/人数')
                .fontSize(Fonts.micro + 1)
                .fontColor(Palette.textMuted)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: homeStore.simulate })
              .selectedColor(Palette.primary)
              .width(44)
              .height(26)
              .onChange((isOn: boolean) => {
                homeStore.setSimulate(isOn);
              })
          }
          .width('100%')

          Divider().color(Palette.line)

          this.row('立即执行一轮规则评估', homeStore.tickCount.toString() + ' 轮已执行', false, () => {
            homeStore.tick();
            promptAction.showToast({ message: '已触发一次评估，可在日志页查看结果', duration: 1800 });
          })
          Divider().color(Palette.line)
          this.row('最近一次自动触发', homeStore.lastTriggerAt <= 0 ? '尚未触发' :
            Fmt.duration(Date.now() - homeStore.lastTriggerAt) + ' · ' + homeStore.lastTriggerTitle, false, () => {
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Palette.card)
        .borderRadius(Metrics.radiusSm + 2)

        // 数据
        Column({ space: 8 }) {
          Row() {
            Text('数据与存储')
              .fontSize(Fonts.body)
              .fontWeight(FontWeight.Medium)
              .fontColor(Palette.text)
            Blank()
            Pill({
              text: homeStore.storageReady ? 'preferences 已就绪' : '存储未就绪',
              color: homeStore.storageReady ? Palette.success : Palette.danger,
              bg: homeStore.storageReady ? Palette.successSoft : Palette.dangerSoft
            })
          }
          .width('100%')

          Divider().color(Palette.line)

          this.row('立即保存快照', '已写入 ' + homeStore.saveCount.toString() + ' 次', false, () => {
            homeStore.flushNow();
            promptAction.showToast({ message: '已写入本地存储', duration: 1500 });
          })
          Divider().color(Palette.line)
          this.row('清空执行日志', homeStore.logs.length.toString() + ' 条', false, () => {
            homeStore.clearLogs();
            promptAction.showToast({ message: '日志已清空', duration: 1500 });
          })
          Divider().color(Palette.line)
          this.row('恢复默认设备与规则', '会清空本地快照', true, () => {
            AlertDialog.show({
              title: '恢复默认数据',
              message: '将删除本地快照并回到初始设备与规则，确定继续？',
              autoCancel: true,
              primaryButton: {
                value: '取消',
                action: () => {
                }
              },
              secondaryButton: {
                value: '恢复',
                fontColor: Palette.danger,
                action: () => {
                  homeStore.resetAll();
                  promptAction.showToast({ message: '已恢复默认数据', duration: 1500 });
                }
              }
            });
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Palette.card)
        .borderRadius(Metrics.radiusSm + 2)

        // 关于
        Column({ space: 8 }) {
          Text('关于')
            .fontSize(Fonts.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Palette.text)
            .width('100%')
          Text('栖居 · 智慧宿舍场景编排  v1.0.0')
            .fontSize(Fonts.caption)
            .fontColor(Palette.textSecondary)
            .width('100%')
          Text('刘熹航 · 20240313123 · 物联网工程（华为班）')
            .fontSize(Fonts.caption)
            .fontColor(Palette.textSecondary)
            .width('100%')
          Text('DevEco Studio 5.0.13 · HarmonyOS 5.0.5(17)')
            .fontSize(Fonts.caption)
            .fontColor(Palette.textSecondary)
            .width('100%')
          Row({ space: 6 }) {
            Pill({ text: 'ArkTS', color: Palette.primary, bg: Palette.primarySoft })
            Pill({ text: 'ArkUI', color: Palette.info, bg: Palette.infoSoft })
            Pill({ text: 'Navigation', color: Palette.purple, bg: Palette.purpleSoft })
            Pill({ text: 'preferences', color: Palette.accent, bg: Palette.accentSoft })
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Palette.card)
        .borderRadius(Metrics.radiusSm + 2)
        .margin({ bottom: 16 })
      }
      .width('100%')
      .padding({ left: Metrics.page, right: Metrics.page })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Palette.page)
    .scrollBar(BarState.Off)
  }
}
