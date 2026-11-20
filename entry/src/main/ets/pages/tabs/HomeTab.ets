import { Device } from '../../model/Device';
import { Scene } from '../../model/Scene';
import { homeStore } from '../../store/HomeStore';
import { Fmt } from '../../common/Formats';
import { Fonts, Metrics, Palette } from '../../common/Theme';
import { DeviceCard } from '../../view/DeviceCard';
import { ScenePill } from '../../view/ScenePill';
import { Pill, SectionHeader, StatTile } from '../../view/Widgets';

/** 首页：环境快照 + 快捷场景 + 设备网格 + 自动化概览 */
@Component
export struct HomeTab {
  @StorageLink('qijuRev') rev: number = 0;
  @StorageLink('qijuTab') activeTab: number = 0;
  onOpenDevice: (id: string) => void = () => {
  };

  private devices(): Device[] {
    return homeStore.controllableDevices();
  }

  private onlineCount(): number {
    let n = 0;
    const list = this.devices();
    for (let i = 0; i < list.length; i++) {
      if (list[i].online) {
        n = n + 1;
      }
    }
    return n;
  }

  private statusSentence(): string {
    const t = homeStore.envValue('temperature');
    const h = homeStore.envValue('humidity');
    const o = homeStore.envValue('occupancy');
    if (t >= 29) {
      return '室内偏热，规则正在联动降温';
    }
    if (h < 40) {
      return '空气偏干，加湿器已介入';
    }
    if (o <= 0) {
      return '当前无人，宿舍进入节能状态';
    }
    if (t < 22) {
      return '温度偏低，注意保暖';
    }
    return '环境舒适，一切正常';
  }

  private activeRules(): number {
    return homeStore.stats().activeRules;
  }

  private lastTriggerText(): string {
    if (homeStore.lastTriggerAt <= 0) {
      return '等待条件命中';
    }
    return Fmt.duration(Date.now() - homeStore.lastTriggerAt) + '触发 ' + homeStore.lastTriggerTitle;
  }

  build() {
    Scroll() {
      Column({ space: Metrics.gap }) {
        // 顶部问候
        Row() {
          Column({ space: 2 }) {
            Text(Fmt.greeting(Date.now()) + '，熹航')
              .fontSize(Fonts.title)
              .fontWeight(FontWeight.Bold)
              .fontColor(Palette.text)
            Text(Fmt.date(Date.now()) + ' · ' + Fmt.weekday(Date.now()) + ' · 24 栋 305')
              .fontSize(Fonts.caption)
              .fontColor(Palette.textMuted)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Row({ space: 4 }) {
            Circle()
              .width(6)
              .height(6)
              .fill(homeStore.simulate ? Palette.success : Palette.textMuted)
            Text(homeStore.simulate ? '模拟中' : '已暂停')
              .fontSize(Fonts.micro)
              .fontColor(homeStore.simulate ? Palette.success : Palette.textMuted)
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(Palette.card)
          .borderRadius(10)
        }
        .width('100%')
        .margin({ top: 4 })

        // 环境主卡
        Column({ space: 10 }) {
          Row() {
            Column({ space: 2 }) {
              Text('室内温度')
                .fontSize(Fonts.caption)
                .fontColor('#CFEAE6')
              Row() {
                Text(homeStore.envValue('temperature').toFixed(1))
                  .fontSize(44)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Palette.white)
                Text('℃')
                  .fontSize(Fonts.section)
                  .fontColor('#CFEAE6')
                  .margin({ left: 2, bottom: 8 })
              }
              .alignItems(VerticalAlign.Bottom)
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Column({ space: 4 }) {
              Text('当前生效规则')
                .fontSize(Fonts.micro)
                .fontColor('#CFEAE6')
              Text(this.activeRules().toString() + ' 条')
                .fontSize(Fonts.title)
                .fontWeight(FontWeight.Bold)
                .fontColor(Palette.white)
              Text(this.lastTriggerText())
                .fontSize(Fonts.micro)
                .fontColor('#CFEAE6')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(120)
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')

          Text(this.statusSentence())
            .fontSize(Fonts.caption)
            .fontColor('#E4F5F1')
            .width('100%')

          Row({ space: 8 }) {
            StatTile({
              icon: '💧',
              label: '湿度',
              value: Math.round(homeStore.envValue('humidity')).toString(),
              unit: '%',
              highlight: true
            })
            StatTile({
              icon: '☀️',
              label: '光照',
              value: Math.round(homeStore.envValue('illuminance')).toString(),
              unit: 'lx',
              highlight: true
            })
            StatTile({
              icon: '👥',
              label: '在寝',
              value: Math.round(homeStore.envValue('occupancy')).toString(),
              unit: '人',
              highlight: true
            })
          }
          .width('100%')
        }
        .padding(16)
        .borderRadius(Metrics.radius)
        .linearGradient({ angle: 135, colors: [['#0F6B60', 0.0], ['#14887B', 1.0]] })
        .shadow({ radius: 18, color: '#330F6B60', offsetY: 6 })

        // 场景
        SectionHeader({ title: '快捷场景', hint: '一键执行' })
        Scroll() {
          Row({ space: 10 }) {
            ForEach(homeStore.scenes, (scene: Scene) => {
              ScenePill({ sceneId: scene.id })
            }, (scene: Scene) => scene.id)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        // 设备
        SectionHeader({
          title: '设备状态',
          hint: this.onlineCount().toString() + '/' + this.devices().length.toString() + ' 在线'
        })
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.devices(), (device: Device) => {
            DeviceCard({
              deviceId: device.id,
              onOpen: () => {
                this.onOpenDevice(device.id);
              }
            })
              .width('48.4%')
              .margin({ bottom: 10 })
          }, (device: Device) => device.id)
        }
        .width('100%')

        // 自动化概览
        Row({ space: 12 }) {
          Text('⚙️')
            .fontSize(22)
            .width(42)
            .height(42)
            .textAlign(TextAlign.Center)
            .backgroundColor(Palette.primarySoft)
            .borderRadius(12)
          Column({ space: 4 }) {
            Row({ space: 6 }) {
              Text('自动化规则')
                .fontSize(Fonts.body)
                .fontWeight(FontWeight.Medium)
                .fontColor(Palette.text)
              Pill({ text: this.activeRules().toString() + ' 启用', color: Palette.primary, bg: Palette.primarySoft })
            }
            Text('已自动运行 ' + homeStore.tickCount.toString() + ' 轮 · 保存 ' + homeStore.saveCount.toString() + ' 次')
              .fontSize(Fonts.micro + 1)
              .fontColor(Palette.textMuted)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('管理')
            .fontSize(Fonts.caption)
            .fontColor(Palette.white)
            .backgroundColor(Palette.primary)
            .borderRadius(10)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .onClick(() => {
              this.activeTab = 1;
            })
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Palette.card)
        .borderRadius(Metrics.radiusSm + 2)

        Text(homeStore.storageReady ? '数据由 preferences 本地持久化 · 冷启动自动恢复' : '本地存储未就绪，本次修改仅保留在内存')
          .fontSize(Fonts.micro)
          .fontColor(Palette.textMuted)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 4, bottom: 12 })
      }
      .width('100%')
      .padding({ left: Metrics.page, right: Metrics.page, top: 8 })
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
    .backgroundColor(Palette.page)
  }
}
