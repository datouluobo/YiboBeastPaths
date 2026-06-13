# YiboBeastPaths

潘达利亚隐藏猎人宠物路线图插件。  
作用是把部分稀有猎人宠物的巡逻/活动路线直接覆盖显示在世界地图上，方便在游戏内快速查看和蹲守。

当前版本：`v1.0.1`

![Logo](Assets/Brand/logo-main.png)

## 当前状态

- 已接入世界地图路线覆盖显示。
- 已提供地图左下角开关按钮，可直接切换路线显示。
- 已提供插件列表图标资源。
- 已为每条路线提供起点标记与悬浮信息。
- 已移除按钮切换时的聊天框刷屏提示。
- 仓库内包含 `_NonRelease/DebugCalibrator.lua` 调试校准工具，供路线微调用。

## 当前收录宠物

目前仓库内已收录 10 条潘达利亚隐藏猎人宠物路线：

- `50811` 重蹄 `Stompy`
- `50812` 帕特兰纳克 `Patrannache`
- `50813` 噩兆 `Portent`
- `50816` 刺脊 `Bristlespine`
- `50817` 血牙 `Bloodtooth`
- `50818` 赫克萨波斯 `Hexapos`
- `50820` 洛克海德 `Rockhide the Immovable`
- `50821` 萨维奇 `Savage`
- `50822` 微光之蛾 `Glimmer`
- `66522` 邦比 `Bombyx`

## 功能说明

- 在世界地图对应区域显示该地图下的宠物路线覆盖图。
- 路线起点会显示额外节点标记。
- 鼠标悬停节点时会显示宠物名称、英文名、外观标签和路线 ID。
- 地图左下角按钮可切换 `宠物路线: 开/关`。
- 支持命令：
  - `/ybp`
  - `/ybp show`
  - `/ybp hide`

## 安装方式

1. 将插件目录放入：
   `World of Warcraft/_classic_/Interface/AddOns/`
2. 保证最终目录结构类似：
   `Interface/AddOns/YiboBeastPaths/`
3. 进入游戏后启用插件。

## 主要文件

- [YiboBeastPaths.toc](E:/Program/YiboBeastPaths/YiboBeastPaths.toc)：插件入口与元数据
- [Core.lua](E:/Program/YiboBeastPaths/Core.lua)：初始化、按钮与命令
- [Renderer.lua](E:/Program/YiboBeastPaths/Renderer.lua)：世界地图路线绘制与节点显示
- [Data.lua](E:/Program/YiboBeastPaths/Data.lua)：宠物基础数据
- [RouteOverlays.lua](E:/Program/YiboBeastPaths/RouteOverlays.lua)：路线覆盖图资源映射
- [RouteNodes.lua](E:/Program/YiboBeastPaths/RouteNodes.lua)：路线节点与提示数据
- [RouteTransforms.lua](E:/Program/YiboBeastPaths/RouteTransforms.lua)：每条路线的定位参数

## v1.0.1 更新

- 新增项目主 Logo 与插件列表小图标。
- 为插件列表接入 `IconTexture`。
- 调整世界地图开关按钮的大小、位置和状态文案。
- 修复按钮只显示外框、不显示文本的问题。
- 修复按钮相关兼容问题导致的路线不显示风险。
- 移除路线开关时的聊天框提示。

## 说明

- 当前路线效果依赖覆盖图资源与定位参数。
- 如果某条路线位置仍需微调，可使用仓库内的调试校准脚本继续修正。
