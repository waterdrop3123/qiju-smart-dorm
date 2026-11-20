import { DeviceType } from '../model/Device';
import { homeStore } from '../store/HomeStore';
import { Fonts, Metrics, Palette } from '../common/Theme';
import { Visuals } from '../common/Visuals';
import { MiniBar } from './Widgets';

/** 首页设备卡：自己订阅 qijuRev，数据一变就重绘，父组件无需层层传值 */
@Component
export struct DeviceCard {
  @Prop deviceId: string = '';
  @StorageLink('qijuRev') rev: number = 0;
  onOpen: () => void = () => {
  };

  private name(): string {
    const d = homeStore.deviceById(this.deviceId);
    return d === undefined ? '设备' : d.name;
  }

  private room(): string {
    const d = homeStore.deviceById(this.deviceId);
    return d === undefined ? '' : d.room;
  }

  private type(): DeviceType {
    const d = homeStore.deviceById(this.deviceId);
    return d === undefined ? DeviceType.SOCKET : d.type;
  }

  private online(): boolean {
    const d = homeStore.deviceById(this.deviceId);
    return d === undefined ? false : d.online;
  }

  private switchKey(): string {
    const d = homeStore.deviceById(this.deviceId);
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
    const d = homeStore.deviceById(this.deviceId);
    if (d === undefined) {
      return false;
    }
    const key = this.switchKey();
    if (key.length === 0) {
      return false;
    }
    return d.getValue(key, 0) >= 1;
  }

  private levelValue(): number {
    const d = homeStore.deviceById(this.deviceId);
    if (d === undefined) {
      return 0;
    }
    const lv = d.getProp('level');
    if (lv !== undefined) {
      return lv.value;
    }
    const pos = d.getProp('position');
    return pos === undefined ? 0 : pos.value;
  }

  private hasBar(): boolean {
    const d = homeStore.deviceById(this.deviceId);
    if (d === undefined) {
      return false;
    }
    return d.getProp('level') !== undefined || d.getProp('position') !== undefined;
  }

  private stateText(): string {
    const d = homeStore.deviceById(this.deviceId);
    if (d === undefined) {
      return '未知';
    }
    if (!d.online) {
      return '离线';
    }
    const lk = d.getProp('locked');
    if (lk !== undefined) {
      return lk.value >= 1 ? '已反锁' : '未反锁';
    }
    const power = d.getProp('power');
    if (power !== undefined && power.value < 1) {
      return '已关闭';
    }
    const lv = d.getProp('level');
    if (lv !== undefined) {
      return '亮度 ' + Math.round(lv.value).toString() + '%';
    }
    const pos = d.getProp('position');
    if (pos !== undefined) {
      return '开合 ' + Math.round(pos.value).toString() + '%';
    }
    const tt = d.getProp('targetTemp');
    if (tt !== undefined) {
      return '设定 ' + Math.round(tt.value).toString() + '℃';
    }
    return power === undefined ? '待机' : '运行中';
  }

  build() {
    Column({ space: 10 }) {
      Row() {
        Text(Visuals.icon(this.type()))
          .fontSize(20)
          .width(38)
          .height(38)
          .textAlign(TextAlign.Center)
          .backgroundColor(Visuals.tint(this.type()))
          .borderRadius(11)
        Blank()
        if (this.switchKey().length > 0) {
          Toggle({ type: ToggleType.Switch, isOn: this.switchValue() })
            .selectedColor(Palette.primary)
            .switchPointColor(Palette.white)
            .width(40)
            .height(24)
            .onChange((isOn: boolean) => {
              homeStore.setDeviceValue(this.deviceId, this.switchKey(), isOn ? 1 : 0);
            })
        }
      }
      .width('100%')

      Column({ space: 2 }) {
        Text(this.name())
          .fontSize(Fonts.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(Palette.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.room() + ' · ' + this.stateText())
          .fontSize(Fonts.micro + 1)
          .fontColor(this.online() ? Palette.textMuted : Palette.danger)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      if (this.hasBar()) {
        MiniBar({
          value: this.levelValue(),
          color: this.switchValue() || this.switchKey().length === 0 ? Palette.primary : Palette.line
        })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .borderRadius(Metrics.radiusSm + 2)
    .backgroundColor(Palette.card)
    .shadow({ radius: 12, color: '#0F0B1F2A', offsetY: 4 })
    .onClick(() => {
      this.onOpen();
    })
  }
}
