# Non-Release Files

这个目录存放默认不建议随正式发布包携带的文件，方便手动管理。

## 分类

- `DebugCalibrator.lua`
  - 调试面板代码，正式 `.toc` 已关闭默认加载。
- `Docs/`
  - 方案文档、参考资料，不参与运行。
- `Tools/`
  - 生成脚本，不参与运行。
- `Assets/ExtractedRoutes/Sources/`
  - 路线原始参考图。
- `Assets/ExtractedRoutes/Masters/`
  - 路线处理过程中的主素材。
- `Assets/ExtractedRoutes/Overlays/*.png`
  - 中间调试产物，正式运行使用的是同目录下 `.tga` 覆盖图。
- `Assets/ReferencePets/PandariaHiddenHunterPets/`
  - 宠物原始参考照片。
- `Assets/ReferencePets/pandaria_hidden_hunter_pets.json`
  - 参考数据源，不参与运行。
- `Assets/ReferencePets/Textures/67820_bombyx_preview.png`
  - 预览图，不参与运行。

## 正式发布通常仍需保留

- 根目录 `.toc` 与核心 `.lua`
- `Libs/`
- `Assets/ExtractedRoutes/Overlays/*.tga`
- `Assets/ReferencePets/Textures/*.tga`
- `Assets/ReferencePets/TooltipTextures/*.tga`
