# YiboBeastPaths 路径校准方案

## 目标

为潘达利亚潜行宠物路线图建立一套稳定、可重复的人工校准流程：

1. 每条宠物路径都能在各自地图上准确显示。
2. 调试阶段允许人工微调位置与缩放。
3. 最终将人工校准结果固化为硬编码参数。
4. 普通用户安装插件后，无需调试即可直接获得正确显示效果。

---

## 总体原则

1. 每条路径一组独立参数。
2. 原始路线图统一裁切规则。
3. 每张地图使用统一归一化坐标系。
4. 调试时以按钮微调为主，命令为辅。
5. 最终只保留硬编码配置，调试模块默认不参与正式使用。

---

## 坐标系设计

### 地图统一坐标系

所有校准参数统一基于地图本地归一化坐标系：

1. 地图左上角为 `(0, 0)`
2. 地图右下角为 `(1, 1)`
3. 路径贴图默认先铺满该地图的可绘制区域
4. 所有平移与缩放都在该坐标系中完成

### 地图级底座

每张地图单独定义一个统一的地图绘制区域：

```lua
[mapID] = {
    left = ...,
    top = ...,
    right = ...,
    bottom = ...,
}
```

用途：

1. 同地图多条路径共享同一底座
2. 保证每条路径都在同一参照系下调节
3. 后续维护更简单

---

## 原始路径图处理规则

### 资产分层

每条路径建议保留两层资产：

1. `source`
   原始参考图，保留完整来源内容
2. `overlay`
   只保留路线本身的透明覆盖图

### 裁切规则

统一裁切到“地图主体矩形”，而不是紧贴路线边缘裁切。

原因：

1. 如果紧裁切，每条路径的局部原点都不同，参数会难以统一
2. 统一到地图主体矩形后，同地图多条路径可以共用同一地图底座
3. 后续只需要调节平移和缩放，不需要额外补偿不同裁切方式造成的偏差

### 清理要求

覆盖图中应尽量去掉以下内容：

1. 宠物立绘
2. 标签文字
3. 边框
4. 明显杂点

保留：

1. 路径线
2. 终点/起点圆点（若其本身属于路线视觉表达）
3. 椭圆巡逻区域（如 `Bombyx`）

---

## 每条路径参数设计

每条宠物路径使用独立参数：

```lua
[petID] = {
    offsetX = 0,
    offsetY = 0,
    scale = 1,
    scaleX = 1,
    scaleY = 1,
}
```

### 参数含义

1. `offsetX`
   水平方向平移
2. `offsetY`
   垂直方向平移
3. `scale`
   整体统一缩放
4. `scaleX`
   水平方向额外缩放补偿
5. `scaleY`
   垂直方向额外缩放补偿

### 生效顺序

建议渲染时按以下顺序计算：

1. 路径贴图先铺到地图级底座
2. 先应用 `scale`
3. 再分别乘上 `scaleX` 和 `scaleY`
4. 最后应用 `offsetX` 和 `offsetY`

### 为什么保留三种缩放

不只保留单个 `scale`，也不只保留 `scaleX/scaleY`，而是三者并存。

原因：

1. 大多数情况只需要调 `scale`
2. 个别路径图若存在横纵比例误差，可用 `scaleX/scaleY` 微修
3. 默认仍保持低复杂度，高级情况下才开启额外修正

---

## 调试模块设计

### 模块目标

调试模块不是正式功能，而是“参数生产工具”。

它的职责是：

1. 实时调节当前地图上的路径覆盖图
2. 展示当前参数
3. 导出最终硬编码配置

### 文件建议

建议使用以下结构：

1. `RouteOverlays.lua`
   仅保存每条路径的基础覆盖图信息
2. `MapCanvasBounds.lua`
   仅保存每张地图的绘制区域底座
3. `RouteTransforms.lua`
   仅保存每条路径的最终校准参数
4. `DebugCalibrator.lua`
   调试模块

---

## 调试面板设计

### 目标

提供轻量但高效的人工调参面板，尽量减少频繁输入命令。

### 面板内容

主区域：

1. 当前地图名
2. 当前宠物名
3. 当前 `petID`
4. 当前参数值摘要

常用按钮：

1. `X-`
2. `X+`
3. `Y-`
4. `Y+`
5. `Scale-`
6. `Scale+`
7. `上一个`
8. `下一个`
9. `重置当前`
10. `保存当前`

高级区域：

1. `ScaleX-`
2. `ScaleX+`
3. `ScaleY-`
4. `ScaleY+`
5. 步进切换：`细 / 中 / 粗`

### 步进建议

平移：

1. 细调：`0.002`
2. 中调：`0.005`
3. 粗调：`0.01`

缩放：

1. 细调：`0.005`
2. 中调：`0.01`
3. 粗调：`0.02`

---

## 参数输出文本框

建议在面板底部放置一个多行只读文本框，用于复制导出参数。

### 文本框用途

1. 显示当前选中路径参数
2. 显示当前地图全部路径参数
3. 方便手动复制给开发阶段写回硬编码

### 建议按钮

1. `导出当前`
2. `导出本图`
3. `全选`（如果实现方便）

### 导出格式

建议直接贴近最终硬编码格式：

```lua
[50812] = { offsetX = 0.0120, offsetY = -0.0060, scale = 0.9850, scaleX = 1.0000, scaleY = 1.0000 },
```

若同地图存在两只宠物，则连续输出两行或多行。

---

## 同地图多宠物处理

同地图有多只宠物时：

1. 地图级底座共用
2. 每只宠物的参数独立

即：

1. `MapCanvasBounds[mapID]` 共享
2. `RouteTransforms[petID]` 各自维护

原因：

1. 同地图底图一致
2. 但不同来源路线图的边距和视觉重心不一定一致
3. 因此不能共用同一套变换参数

---

## 推荐校准流程

建议实际操作时使用以下顺序：

1. 打开目标地图
2. 调试面板自动列出该地图所有路径
3. 选择当前需要校准的宠物
4. 先调 `offsetX/offsetY`
5. 再调 `scale`
6. 如果仍有横纵比例误差，再微调 `scaleX/scaleY`
7. 保存当前宠物参数
8. 切换到下一只宠物
9. 校准完成后使用 `导出当前` 或 `导出本图`
10. 将导出参数写入 `RouteTransforms.lua`

---

## 渲染层最终职责

正式渲染逻辑建议简化为：

1. 读取当前世界地图 `mapID`
2. 查找该地图对应的 `MapCanvasBounds`
3. 找出属于该地图的所有 `RouteOverlays`
4. 对每条路径读取其 `RouteTransforms`
5. 将覆盖图铺到底座后，按参数进行缩放和平移
6. 正常显示

正式模式不依赖调试模块提供的数据变更能力。

---

## 最终结论

本方案采用：

1. 地图统一归一化坐标系
2. 路径统一裁切到地图主体矩形
3. 每条路径独立参数
4. 参数使用 `offsetX / offsetY / scale / scaleX / scaleY`
5. 调试时使用按钮微调
6. 输出参数通过文本框复制
7. 最终结果写回硬编码配置供所有用户直接使用

这是当前最稳、最可维护、也最适合人工校准的实现路线。

---

## 实现细化

下面将方案继续细化到“可以直接按模块开发”的粒度。

### 一期目标

一期只做“够用且稳定”的校准工具，不追求复杂交互。

一期完成标准：

1. 世界地图上可显示当前地图对应的全部路径覆盖图
2. 可切换当前选中的宠物路径
3. 可实时微调当前路径的 `offsetX / offsetY / scale`
4. 可在高级模式下微调 `scaleX / scaleY`
5. 可导出当前宠物或当前地图全部宠物的参数
6. 可将导出的参数写回正式配置文件

一期暂不做：

1. 鼠标直接拖拽路径
2. 鼠标滚轮缩放路径
3. 多人共享参数
4. 游戏内写回 Lua 文件

---

## 文件职责拆分

建议最终代码按以下职责划分：

### 1. `RouteOverlays.lua`

职责：

1. 保存每条宠物路径的基础覆盖图资源信息
2. 保存每条宠物所属地图 `mapID`
3. 不保存校准参数

建议结构：

```lua
ns.routeOverlays = {
    [50812] = {
        slug = "patrannache",
        mapID = 376,
        texture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ExtractedRoutes\\Overlays\\50812_patrannache",
    },
}
```

### 2. `MapCanvasBounds.lua`

职责：

1. 保存每张地图的统一绘制底座区域
2. 作为路径覆盖图的统一定位参考

建议结构：

```lua
ns.mapCanvasBounds = {
    [376] = {
        left = 0.0,
        top = 0.0,
        right = 1.0,
        bottom = 1.0,
    },
}
```

一期可以先全部默认 `(0, 0, 1, 1)`，后续若发现某些地图画布并非完整区域，再逐图修正。

### 3. `RouteTransforms.lua`

职责：

1. 保存每条宠物的正式硬编码校准参数
2. 正式渲染逻辑只读这里，不读调试临时状态

建议结构：

```lua
ns.routeTransforms = {
    [50812] = {
        offsetX = 0,
        offsetY = 0,
        scale = 1,
        scaleX = 1,
        scaleY = 1,
    },
}
```

### 4. `DebugCalibrator.lua`

职责：

1. 提供调试面板
2. 提供临时调参能力
3. 提供导出文本
4. 不直接负责正式渲染

### 5. `Renderer.lua`

职责：

1. 获取当前地图
2. 找出该地图对应的所有路径
3. 读取地图底座和每条路径的正式参数
4. 实际进行显示
5. 调试模式开启时，叠加调试态参数

---

## 数据流设计

### 正式模式数据流

```text
当前地图
-> RouteOverlays.lua 找到该地图上的所有路径
-> MapCanvasBounds.lua 取得该地图底座
-> RouteTransforms.lua 取得每条路径的正式参数
-> Renderer.lua 计算最终显示区域并绘制
```

### 调试模式数据流

```text
当前地图
-> RouteOverlays.lua 找路径
-> MapCanvasBounds.lua 找底座
-> RouteTransforms.lua 取正式参数作为初始值
-> DebugCalibrator.lua 叠加临时调试参数
-> Renderer.lua 显示结果
-> 用户点击按钮调整
-> DebugCalibrator.lua 更新临时参数
-> 文本框导出结果
```

### 参数优先级

调试模式下建议优先级如下：

1. 临时调试参数
2. 正式硬编码参数
3. 默认值

即如果某个字段没有调过，则继续读取正式参数或默认值。

---

## 渲染计算规则

建议将渲染过程固定为以下步骤：

1. 取到该地图的底座矩形：
   `left, top, right, bottom`
2. 将路径贴图先铺满这个底座
3. 以底座中心点为原点进行缩放
4. 先应用 `scale`
5. 再分别应用 `scaleX` 和 `scaleY`
6. 最后应用 `offsetX / offsetY`

### 推荐公式

设：

1. `baseWidth = right - left`
2. `baseHeight = bottom - top`
3. `finalScaleX = scale * scaleX`
4. `finalScaleY = scale * scaleY`

则：

1. `finalWidth = baseWidth * finalScaleX`
2. `finalHeight = baseHeight * finalScaleY`
3. 以底座中心为锚点计算位置
4. 最终再叠加 `offsetX` 和 `offsetY`

这样调节时视觉最稳定，不会因为缩放引发难以预测的漂移。

---

## 调试模块交互细节

### 面板建议布局

从上到下建议分 4 块：

1. 当前状态区
2. 路径切换区
3. 参数调节区
4. 参数导出区

### 1. 当前状态区

显示内容：

1. 当前地图名
2. 当前地图 `mapID`
3. 当前宠物名
4. 当前宠物 `petID`
5. 当前是否处于高级调节模式

### 2. 路径切换区

按钮：

1. `上一条`
2. `下一条`

逻辑：

1. 只在当前地图拥有的宠物列表里切换
2. 同地图两只宠物时非常好用

### 3. 参数调节区

常用按钮：

1. `X-`
2. `X+`
3. `Y-`
4. `Y+`
5. `Scale-`
6. `Scale+`

高级按钮：

1. `ScaleX-`
2. `ScaleX+`
3. `ScaleY-`
4. `ScaleY+`

辅助按钮：

1. `重置当前`
2. `保存当前`
3. `显示高级`

### 4. 参数导出区

控件：

1. 多行只读文本框
2. `导出当前`
3. `导出本图`
4. `全选`

---

## 调试状态存储建议

一期建议把调试状态存在内存里即可，同时允许保存到 SavedVariables。

建议结构：

```lua
YiboBeastPathsDebugDB = {
    transforms = {
        [50812] = {
            offsetX = ...,
            offsetY = ...,
            scale = ...,
            scaleX = ...,
            scaleY = ...,
        },
    },
}
```

### 为什么建议加临时 SavedVariables

1. 你调到一半掉线或重载不会白调
2. 可以分多次慢慢校
3. 最终仍以导出结果写回正式 Lua 为准

---

## 导出文本规则

### 导出当前宠物

格式：

```lua
[50812] = { offsetX = 0.0120, offsetY = -0.0060, scale = 0.9850, scaleX = 1.0000, scaleY = 1.0000 },
```

### 导出当前地图全部宠物

格式：

```lua
[50817] = { offsetX = 0.0000, offsetY = 0.0000, scale = 1.0000, scaleX = 1.0000, scaleY = 1.0000 },
[66522] = { offsetX = -0.0040, offsetY = 0.0020, scale = 0.9920, scaleX = 1.0000, scaleY = 1.0000 },
```

### 导出排序建议

1. 按当前地图中的宠物显示顺序输出
2. 或按 `petID` 升序输出

推荐按 `petID` 升序，更稳定。

---

## 调试命令补充设计

虽然主要依赖按钮，但仍建议保留少量命令，用于：

1. 开关调试模式
2. 快速显示面板
3. 紧急重置

建议命令：

1. `/ybpdebug on`
2. `/ybpdebug off`
3. `/ybpdebug show`
4. `/ybpdebug hide`
5. `/ybpdebug reset 50812`

不建议保留复杂命令式调参作为主要工作流。

---

## 一期开发顺序建议

建议按以下顺序实现：

### 步骤 1

整理正式数据文件：

1. `RouteOverlays.lua`
2. `MapCanvasBounds.lua`
3. `RouteTransforms.lua`

### 步骤 2

重构 `Renderer.lua`：

1. 只负责地图识别和正式绘制
2. 允许读取调试临时参数叠加

### 步骤 3

实现 `DebugCalibrator.lua` 最小版：

1. 面板显示
2. 当前地图路径切换
3. `offsetX / offsetY / scale` 调节
4. 文本导出

### 步骤 4

加入高级调节：

1. `scaleX`
2. `scaleY`

### 步骤 5

加入调试 SavedVariables

### 步骤 6

你开始逐图校准，产出参数

### 步骤 7

把结果写回 `RouteTransforms.lua`

---

## 验收标准

调试模块完成后，应满足以下验收条件：

1. 打开某张地图时，只显示该地图对应的路径
2. 同地图多宠物时，可切换当前选中目标
3. 点按钮后路径实时移动或缩放
4. `/reload` 后可保留调试状态（若启用调试保存）
5. 可稳定导出 Lua 参数片段
6. 写回正式配置后，关闭调试模块仍能正确显示

---

## 风险与注意事项

### 1. 地图识别风险

不同客户端版本的世界地图接口不完全一致。

解决思路：

1. 正式渲染使用最稳的当前地图识别逻辑
2. 调试模块中可加一行当前地图识别结果提示

### 2. 路径原图质量不一致

不同参考图可能存在：

1. 边距不同
2. 路线宽度不同
3. 标注元素干扰不同

解决思路：

1. 路线图资产统一保留 `source`
2. 覆盖图单独维护
3. 必要时手工清理个别覆盖图

### 3. 同地图多路径遮挡

同地图两只宠物可能有重叠区域。

解决思路：

1. 默认全部显示
2. 当前选中宠物可高亮或提高透明度
3. 非当前选中宠物可稍降透明度

这可以作为二期增强项。

---

## 二期可选增强

一期完成后，可考虑后续增强：

1. 鼠标拖拽平移
2. 鼠标滚轮整体缩放
3. 当前选中路径高亮
4. 同地图路径显隐勾选
5. 自动复制导出文本
6. 直接在游戏内生成更完整的参数块

---

## 模块 API 细化

下面定义建议的模块级接口，目的是在真正实现前先统一边界。

### `RouteOverlays.lua`

建议只暴露数据表：

```lua
ns.routeOverlays = {
    [petID] = {
        slug = "...",
        mapID = 0,
        texture = "...",
    },
}
```

不建议在这个文件里放函数。

### `MapCanvasBounds.lua`

建议只暴露数据表：

```lua
ns.mapCanvasBounds = {
    [mapID] = {
        left = 0,
        top = 0,
        right = 1,
        bottom = 1,
    },
}
```

### `RouteTransforms.lua`

建议只暴露数据表：

```lua
ns.routeTransforms = {
    [petID] = {
        offsetX = 0,
        offsetY = 0,
        scale = 1,
        scaleX = 1,
        scaleY = 1,
    },
}
```

### `Renderer.lua`

建议由它提供以下方法：

```lua
function YBP:GetCurrentWorldMapID()
end

function YBP:GetVisiblePetIDsForMap(mapID)
end

function YBP:GetResolvedTransform(petID)
end

function YBP:ApplyOverlayTransform(frame, mapBounds, transform)
end

function YBP:RefreshMapLayer()
end
```

职责解释：

1. `GetCurrentWorldMapID`
   统一当前世界地图识别逻辑
2. `GetVisiblePetIDsForMap`
   返回该地图有哪些宠物路径应显示
3. `GetResolvedTransform`
   合并正式参数与调试临时参数
4. `ApplyOverlayTransform`
   负责底座、缩放、平移换算
5. `RefreshMapLayer`
   统一重绘入口

### `DebugCalibrator.lua`

建议由它提供以下方法：

```lua
function YBP:IsDebugEnabled()
end

function YBP:SetDebugEnabled(enabled)
end

function YBP:GetDebugPetIDsForCurrentMap()
end

function YBP:GetSelectedDebugPetID()
end

function YBP:SetSelectedDebugPetID(petID)
end

function YBP:AdjustDebugValue(field, delta)
end

function YBP:ResetDebugTransform(petID)
end

function YBP:ExportCurrentDebugTransform()
end

function YBP:ExportCurrentMapDebugTransforms()
end

function YBP:RefreshDebugPanel()
end
```

---

## 数据结构字段细化

### 正式参数字段

```lua
{
    offsetX = 0,
    offsetY = 0,
    scale = 1,
    scaleX = 1,
    scaleY = 1,
}
```

### 调试临时参数字段

建议与正式参数结构完全一致，减少转换：

```lua
YiboBeastPathsDebugDB = {
    enabled = false,
    selectedPetIDByMap = {
        [376] = 50812,
    },
    transforms = {
        [50812] = {
            offsetX = 0.0100,
            offsetY = -0.0040,
            scale = 0.9900,
            scaleX = 1.0000,
            scaleY = 1.0000,
        },
    },
    ui = {
        stepMove = 0.005,
        stepScale = 0.01,
        advanced = false,
    },
}
```

### 为什么记录 `selectedPetIDByMap`

这样你切不同地图时：

1. 每张地图都记住上次选中的宠物
2. 同地图两只宠物来回调节更顺手
3. 不需要全局只维护一个 `selectedPetID`

---

## 渲染计算函数细化

建议把变换计算集中到一个纯逻辑函数，方便复查：

```lua
function YBP:ComputeOverlayRect(mapBounds, transform)
    -- return left, top, right, bottom
end
```

### 输入

`mapBounds`

```lua
{
    left = 0,
    top = 0,
    right = 1,
    bottom = 1,
}
```

`transform`

```lua
{
    offsetX = 0,
    offsetY = 0,
    scale = 1,
    scaleX = 1,
    scaleY = 1,
}
```

### 输出

返回已经应用缩放和平移后的归一化矩形：

```lua
left, top, right, bottom
```

### 推荐计算方式

设：

1. `cx = (left + right) / 2`
2. `cy = (top + bottom) / 2`
3. `baseWidth = right - left`
4. `baseHeight = bottom - top`
5. `resolvedScaleX = scale * scaleX`
6. `resolvedScaleY = scale * scaleY`

则：

1. `newWidth = baseWidth * resolvedScaleX`
2. `newHeight = baseHeight * resolvedScaleY`
3. `newLeft = cx - newWidth / 2 + offsetX`
4. `newRight = cx + newWidth / 2 + offsetX`
5. `newTop = cy - newHeight / 2 + offsetY`
6. `newBottom = cy + newHeight / 2 + offsetY`

---

## 调试面板控件清单

建议每个控件都先列出来，避免实现时边做边想。

### 基础控件

1. 面板根框体
2. 标题文本
3. 当前地图文本
4. 当前宠物文本
5. 当前参数摘要文本

### 路径切换控件

1. `上一条` 按钮
2. `下一条` 按钮

### 常用调节控件

1. `X-` 按钮
2. `X+` 按钮
3. `Y-` 按钮
4. `Y+` 按钮
5. `Scale-` 按钮
6. `Scale+` 按钮

### 高级调节控件

1. `ScaleX-` 按钮
2. `ScaleX+` 按钮
3. `ScaleY-` 按钮
4. `ScaleY+` 按钮
5. `高级` 开关按钮

### 步进控件

1. `细` 按钮
2. `中` 按钮
3. `粗` 按钮

### 导出控件

1. 多行只读编辑框
2. `导出当前` 按钮
3. `导出本图` 按钮
4. `全选` 按钮

### 状态控制控件

1. `重置当前` 按钮
2. `保存当前` 按钮
3. `关闭调试` 按钮

---

## 面板交互规则细化

### 选择逻辑

1. 打开某张地图时，自动找到该地图可见宠物列表
2. 若 `selectedPetIDByMap[mapID]` 存在，则自动选中它
3. 若不存在，则默认选中该地图可见列表中的第一条

### 参数调整逻辑

1. 点击按钮后只修改当前选中宠物的调试临时参数
2. 每次修改后立即刷新：
   1. 地图显示
   2. 面板参数文本
   3. 导出文本框

### 保存逻辑

`保存当前` 的职责建议定义为：

1. 将当前选中宠物的临时参数写入 `YiboBeastPathsDebugDB.transforms`
2. 不写回正式 Lua 文件

### 重置逻辑

`重置当前` 建议：

1. 删除该宠物当前的调试临时参数
2. 回退到正式参数显示

---

## 参数显示格式建议

面板中的当前参数摘要建议简短，便于快速扫读：

```text
X: 0.012
Y: -0.006
S: 0.985
SX: 1.000
SY: 1.000
```

导出框则使用完整格式：

```lua
[50812] = { offsetX = 0.0120, offsetY = -0.0060, scale = 0.9850, scaleX = 1.0000, scaleY = 1.0000 },
```

建议所有导出浮点保留 4 位小数，保持一致。

---

## 刷新时机细化

为了避免“地图切了但参数面板没更新”，建议在以下时机刷新：

1. 世界地图打开时
2. 世界地图切换区域时
3. 调试面板按钮点击后
4. 调试开关改变时
5. 玩家 `/reload` 后首次打开世界地图时

### 推荐刷新入口

统一调用：

```lua
YBP:RefreshMapLayer()
YBP:RefreshDebugPanel()
```

不建议在多个地方写各自的零散更新逻辑。

---

## 开发任务清单

下面是一份可执行的开发清单。

### 任务 1：建立正式配置文件

1. 新建 `MapCanvasBounds.lua`
2. 新建 `RouteTransforms.lua`
3. 确保 `.toc` 正确加载顺序

完成标准：

1. 插件能正常加载
2. 正式渲染读取新配置不报错

### 任务 2：整理渲染器

1. 让 `Renderer.lua` 只读正式配置
2. 抽出 `ComputeOverlayRect`
3. 抽出 `GetVisiblePetIDsForMap`

完成标准：

1. 不开调试也能正常显示
2. 渲染逻辑不再混杂实验代码

### 任务 3：建立调试 SavedVariables

1. 在 `.toc` 增加调试 SavedVariables
2. 初始化默认结构

完成标准：

1. `/reload` 不丢临时调参状态

### 任务 4：实现最小调试面板

1. 显示地图与宠物信息
2. 上一条 / 下一条
3. `X / Y / Scale` 调整
4. 导出当前

完成标准：

1. 可在游戏内完成单条路径基础校准

### 任务 5：实现高级调试面板

1. `ScaleX / ScaleY`
2. 步进切换
3. 导出本图

完成标准：

1. 同地图两只宠物可高效校准

### 任务 6：回填正式参数

1. 将导出结果写入 `RouteTransforms.lua`
2. 关闭调试模块验证正式效果

完成标准：

1. 不开调试也正确显示

---

## 推荐开发顺序总结

如果严格按最省返工的顺序，建议是：

1. 先收拾正式配置结构
2. 再收拾正式渲染器
3. 再做调试 SavedVariables
4. 再做最小调试面板
5. 再做高级调节
6. 最后开始逐图校准

这样能避免在临时实验代码上继续叠功能。
