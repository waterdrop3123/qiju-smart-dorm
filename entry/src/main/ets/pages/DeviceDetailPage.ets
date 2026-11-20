import { promptAction } from '@kit.ArkUI';
import { Device, DeviceProp, DeviceType } from '../model/Device';
import { LogEntry } from '../model/LogEntry';
import { homeStore } from '../store/HomeStore';
import { Fmt } from '../common/Formats';
import { Fonts, Metrics, Palette } from '../common/Theme';
import { Visuals } from '../common/Visuals';
import { EmptyView, MiniBar, Pill } from '../view/Widgets';
import { LogRow } from '../view/LogRow';

/** 设备详情：单个设备的状态、精细控制与相关日志 */
@Component
export struct DeviceDetailPage {
  @StorageLink('qijuRev') rev: number = 0;
  @Consume('navStack') navStack: NavPathStack;

  private deviceId(): string {
    return homeStore.selectedDeviceId;
  }

  private dev(): Device | undefined {
    return homeStore.deviceById(this.deviceId());
  }

  private devType(): DeviceType {
    const d = this.dev();
    return d === undefined ? DeviceType.SOCKET : d.type;
  }

  private isOnline(): boolean {
    const d = this.dev();
    return d === undefined ? false : d.online;
  }

  private roomText(): string {
    const d = this.dev();
    return d === undefined ? '' : d.room;
  }

  private name(): string {
    const d = this.dev();
    return d === undefined ? '设备详情' : d.name;
  }

  private switchKey(): string {
    const d = this.dev();
    if (d === undefined) {
      return '';
    }
    if (d.getProp('power') !== undefined) {
      return 'power';
    }
    if (d.getProp('locked') !== undefined) {
      return 'locked';
    }
    return '';
  }

  private switchValue(): boolean {
    const d = this.dev();
    if (d === undefined || this.switchKey().length === 0) {
      return false;
    }
    return d.getValue(this.switchKey(), 0) >= 1;
  }

  private props(): DeviceProp[] {
    const d = this.dev();
    return d === undefined ? [] : d.props;
  }

  private logs(): LogEntry[] {
    return homeStore.logsMatching(this.name(), 5);
  }

  @Builder
  control(prop: DeviceProp) {
    Column({ space: 8 }) {
      Row() {
        Text(prop.label)
          .fontSize(Fonts.body)
          .fontColor(Palette.text)
        Blank()
        Text(Fmt.propValue(prop))
          .fontSize(Fonts.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(Palette.primary)
      }
      .width('100%')

      if (prop.isBoolean) {
        Row() {
          Text(prop.value >= 1 ? '已开启' : '已关闭')
            .fontSize(Fonts.caption)
            .fontColor(Palette.textMuted)
          Blank()
          Toggle({ type: ToggleType.Switch, isOn: prop.value >= 1 })
            .selectedColor(Palette.primary)
            .onChange((isOn: boolean) => {
              homeStore.setDeviceValue(this.deviceId(), prop.key, isOn ? 1 : 0);
            })
        }
        .width('100%')
      } else {
        Slider({
          value: prop.value,
          min: prop.min,
          max: prop.max,
          step: prop.step,
          style: SliderStyle.OutSet
        })
          .selectedColor(Palette.primary)
          .trackColor(Palette.line)
          .blockColor(Palette.white)
          .width('100%')
          .onChange((value: number, mode: SliderChangeMode) => {
            if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
              homeStore.setDeviceValue(this.deviceId(), prop.key, value);
            }
          })
        Row() {
          Text((prop.min.toString() + prop.unit))
            .fontSize(Fonts.micro)
            .fontColor(Palette.textMuted)
          Blank()
          Text((prop.max.toString() + prop.unit))
            .fontSize(Fonts.micro)
            .fontColor(Palette.textMuted)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  build() {
    NavDestination() {
      if (this.dev() === undefined) {
        EmptyView({ icon: '🔍', title: '设备不存在', hint: '请返回首页重新选择' })
      } else {
        Scroll() {
          Column({ space: Metrics.gap }) {
            // 头部
            Row({ space: 12 }) {
              Text(Visuals.icon(this.devType()))
                .fontSize(28)
                .width(56)
                .height(56)
                .textAlign(TextAlign.Center)
                .backgroundColor(Visuals.tint(this.devType()))
                .borderRadius(16)
              Column({ space: 4 }) {
                Row({ space: 6 }) {
                  Text(this.name())
                    .fontSize(Fonts.title)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Palette.text)
                  Pill({
                    text: this.isOnline() ? '在线' : '离线',
                    color: this.isOnline() ? Palette.success : Palette.danger,
                    bg: this.isOnline() ? Palette.successSoft : Palette.dangerSoft
                  })
                }
                Text(Visuals.typeName(this.devType()) + ' · ' + this.roomText())
                  .fontSize(Fonts.caption)
                  .fontColor(Palette.textMuted)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (this.switchKey().length > 0) {
                Toggle({ type: ToggleType.Switch, isOn: this.switchValue() })
                  .selectedColor(Palette.primary)
                  .onChange((isOn: boolean) => {
                    homeStore.setDeviceValue(this.deviceId(), this.switchKey(), isOn ? 1 : 0);
                  })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Palette.card)
            .borderRadius(Metrics.radius)

            // 控制
            Column() {
              Text('手动控制')
                .fontSize(Fonts.section)
                .fontWeight(FontWeight.Bold)
                .fontColor(Palette.text)
                .width('100%')
              ForEach(this.props(), (prop: DeviceProp) => {
                this.control(prop)
                Divider().color(Palette.line)
              }, (prop: DeviceProp) => prop.key)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Palette.card)
            .borderRadius(Metrics.radius)

            // 相关日志
            Column({ space: 8 }) {
              Row() {
                Text('相关日志')
                  .fontSize(Fonts.section)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Palette.text)
                Blank()
                Text('最近 ' + this.logs().length.toString() + ' 条')
                  .fontSize(Fonts.micro)
                  .fontColor(Palette.textMuted)
              }
              .width('100%')

              if (this.logs().length === 0) {
                Text('该设备还没有操作记录')
                  .fontSize(Fonts.caption)
                  .fontColor(Palette.textMuted)
                  .width('100%')
                  .padding({ top: 8, bottom: 8 })
              } else {
                ForEach(this.logs(), (entry: LogEntry) => {
                  LogRow({ entry: entry })
                }, (entry: LogEntry) => entry.id)
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Palette.card)
            .borderRadius(Metrics.radius)

            Text('最近更新 ' + Fmt.time(Date.now()))
              .fontSize(Fonts.micro)
              .fontColor(Palette.textMuted)
              .margin({ bottom: 16 })
          }
          .width('100%')
          .padding({ left: Metrics.page, right: Metrics.page, top: 8 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
    .title(this.name())
    .backgroundColor(Palette.page)
    .onBackPressed(() => {
      this.navStack.pop();
      return true;
    })
  }
}
