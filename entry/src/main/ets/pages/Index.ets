import { RouteParam } from '../common/Route';
import { homeStore } from '../store/HomeStore';
import { Fonts, Palette } from '../common/Theme';
import { HomeTab } from './tabs/HomeTab';
import { RulesTab } from './tabs/RulesTab';
import { LogsTab } from './tabs/LogsTab';
import { SettingsTab } from './tabs/SettingsTab';
import { DeviceDetailPage } from './DeviceDetailPage';
import { RuleEditPage } from './RuleEditPage';

/**
 * 应用主页面：
 * - 底部 Tabs 组织四大功能区；
 * - 外层 Navigation + NavPathStack 负责设备详情、规则编辑的页面导航（含参数传递与返回栈）。
 */
@Entry
@Component
struct Index {
  @Provide('navStack') navStack: NavPathStack = new NavPathStack();
  @StorageLink('qijuTab') activeTab: number = 0;

  @Builder
  pageMap(name: string) {
    if (name === 'deviceDetail') {
      DeviceDetailPage()
    } else if (name === 'ruleEdit') {
      RuleEditPage()
    }
  }

  @Builder
  tabBar(index: number, title: string, icon: string) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(18)
        .opacity(this.activeTab === index ? 1 : 0.4)
      Text(title)
        .fontSize(Fonts.micro)
        .fontColor(this.activeTab === index ? Palette.primary : Palette.textMuted)
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)
  }

  private openDevice(id: string): void {
    homeStore.selectedDeviceId = id;
    this.navStack.pushPathByName('deviceDetail', new RouteParam(id));
  }

  private openRule(ruleId: string): void {
    homeStore.editingRuleId = ruleId;
    this.navStack.pushPathByName('ruleEdit', new RouteParam(ruleId));
  }

  private newRule(): void {
    homeStore.editingRuleId = '';
    this.navStack.pushPathByName('ruleEdit', new RouteParam(''));
  }

  build() {
    Navigation(this.navStack) {
      Tabs({ index: this.activeTab, barPosition: BarPosition.End }) {
        TabContent() {
          HomeTab({
            onOpenDevice: (id: string) => {
              this.openDevice(id);
            }
          })
        }
        .tabBar(this.tabBar(0, '首页', '🏠'))

        TabContent() {
          RulesTab({
            onEdit: (ruleId: string) => {
              this.openRule(ruleId);
            },
            onNew: () => {
              this.newRule();
            }
          })
        }
        .tabBar(this.tabBar(1, '规则', '⚙️'))

        TabContent() {
          LogsTab()
        }
        .tabBar(this.tabBar(2, '日志', '🗒️'))

        TabContent() {
          SettingsTab()
        }
        .tabBar(this.tabBar(3, '我的', '👤'))
      }
      .barHeight(56)
      .barMode(BarMode.Fixed)
      .scrollable(false)
      .backgroundColor(Palette.page)
      .onChange((index: number) => {
        this.activeTab = index;
      })
    }
    .navDestination(this.pageMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .backgroundColor(Palette.page)
  }
}
