/** Navigation 路由参数：页面间传递业务 id，避免用全局变量硬串 */
export class RouteParam {
  id: string;

  constructor(id: string) {
    this.id = id;
  }
}
