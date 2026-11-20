/**
 * 全局视觉规范（Design Token）
 * 所有页面、组件统一从这里取色与尺寸，保证界面风格一致。
 */
export class Palette {
  static readonly page: string = '#F2F5F9';
  static readonly card: string = '#FFFFFF';
  static readonly primary: string = '#0F6B60';
  static readonly primaryDeep: string = '#0B4F47';
  static readonly primarySoft: string = '#E3F2EF';
  static readonly accent: string = '#E39A2E';
  static readonly accentSoft: string = '#FCF1DE';
  static readonly text: string = '#1B2430';
  static readonly textSecondary: string = '#5A6673';
  static readonly textMuted: string = '#94A1AF';
  static readonly line: string = '#E6EBF1';
  static readonly danger: string = '#D25A56';
  static readonly dangerSoft: string = '#FBEAE9';
  static readonly success: string = '#2E9B6C';
  static readonly successSoft: string = '#E4F5EC';
  static readonly info: string = '#3C7DD9';
  static readonly infoSoft: string = '#E7F0FC';
  static readonly purple: string = '#7264CE';
  static readonly purpleSoft: string = '#EDEAFA';
  static readonly white: string = '#FFFFFF';
  static readonly shade: string = '#0000001A';
}

export class Metrics {
  static readonly page: number = 16;
  static readonly gap: number = 12;
  static readonly gapSm: number = 8;
  static readonly radius: number = 18;
  static readonly radiusSm: number = 12;
  static readonly radiusXs: number = 8;
  static readonly cardPad: number = 16;
  static readonly barHeight: number = 64;
}

export class Fonts {
  static readonly display: number = 24;
  static readonly title: number = 20;
  static readonly section: number = 16;
  static readonly body: number = 14;
  static readonly caption: number = 12;
  static readonly micro: number = 10;
}
