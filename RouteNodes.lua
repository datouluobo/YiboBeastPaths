local ns = select(2, ...)

ns.routeNodeStyles = {
    default = {
        color = { 0.31, 0.85, 1.00 },
        size = 18,
    },
}

ns.routeNodeTooltips = {
    [50811] = {
        title = "重蹄",
        subtitle = "Stompy",
        colorName = "白灰色山羊",
        displayLabel = "山羊- 白灰",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\50998_stompy",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\50998_stompy",
        npcID = 50998,
    },
    [50812] = {
        title = "帕特兰纳克",
        subtitle = "Patrannache",
        colorName = "粉色鹤",
        displayLabel = "鹤- 粉色",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\50885_patrannache",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\50885_patrannache",
        npcID = 50885,
    },
    [50813] = {
        title = "噩兆",
        subtitle = "Portent",
        colorName = "四色随机魁麟",
        displayLabel = "魁麟- 四色",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\50843_portent_jade",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\50843_portent_jade",
        npcID = 50843,
    },
    [50816] = {
        title = "刺脊",
        subtitle = "Bristlespine",
        colorName = "紫黑色豪猪",
        displayLabel = "豪猪- 紫黑",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\50944_bristlespine",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\50944_bristlespine",
        npcID = 50944,
    },
    [50817] = {
        title = "血牙",
        subtitle = "Bloodtooth",
        colorName = "红色带刺龙龟",
        displayLabel = "龙龟- 红色",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\50854_bloodtooth",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\50854_bloodtooth",
        npcID = 50854,
    },
    [50818] = {
        title = "赫克萨波斯",
        subtitle = "Hexapos",
        colorName = "绿底白纹水黾",
        displayLabel = "水黾- 绿白",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\50960_hexapos",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\50960_hexapos",
        npcID = 50960,
    },
    [50820] = {
        title = "洛克海德",
        subtitle = "Rockhide the Immovable",
        colorName = "灰紫晶背蜥蜴",
        displayLabel = "蜥蜴- 灰紫",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\51013_rockhide_the_immovable",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\51013_rockhide_the_immovable",
        npcID = 51013,
    },
    [50821] = {
        title = "萨维奇",
        subtitle = "Savage",
        colorName = "亮蓝眼白虎",
        displayLabel = "虎- 白蓝眼",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\50850_savage",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\50850_savage",
        npcID = 50850,
    },
    [50822] = {
        title = "微光之蛾",
        subtitle = "Glimmer",
        colorName = "水蓝透明水黾",
        displayLabel = "水黾- 水蓝",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\50859_glimmer",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\50859_glimmer",
        npcID = 50859,
    },
    [66522] = {
        title = "邦比",
        subtitle = "Bombyx",
        colorName = "亮红色蚕虫",
        displayLabel = "蚕虫- 亮红",
        iconTexture = "Interface\\Icons\\Ability_Tracking",
        imageTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\Textures\\67820_bombyx",
        tooltipTexture = "Interface\\AddOns\\YiboBeastPaths\\Assets\\ReferencePets\\TooltipTextures\\67820_bombyx",
        npcID = 67820,
    },
}

-- 当前先为每条路线提供一个可调试的起点占位。
-- 调试模式中可直接校准 normalizedX/Y，后续固化到这里。
ns.routeNodes = {
    [50811] = {
        { id = "start", role = "start", normalizedX = 0.5680, normalizedY = 0.6950, nodeScale = 1.0000, isPlaceholder = false },
    },
    [50812] = {
        { id = "start", role = "start", normalizedX = 0.9600, normalizedY = 0.4100, nodeScale = 1.0000, isPlaceholder = false },
    },
    [50813] = {
        { id = "start", role = "start", normalizedX = 0.0880, normalizedY = 0.2220, nodeScale = 1.0000, isPlaceholder = false },
    },
    [50816] = {
        { id = "start", role = "start", normalizedX = 0.6560, normalizedY = 0.1640, nodeScale = 1.0000, isPlaceholder = false },
    },
    [50817] = {
        { id = "start", role = "start", normalizedX = 0.9320, normalizedY = 0.2780, nodeScale = 1.0000, isPlaceholder = false },
    },
    [50818] = {
        { id = "start", role = "start", normalizedX = 0.1300, normalizedY = 0.6980, nodeScale = 1.0000, isPlaceholder = false },
    },
    [50820] = {
        { id = "start", role = "start", normalizedX = 0.6000, normalizedY = 0.1060, nodeScale = 0.9400, isPlaceholder = false },
    },
    [50821] = {
        { id = "start", role = "start", normalizedX = 0.1350, normalizedY = 0.9520, nodeScale = 1.0000, isPlaceholder = false },
    },
    [50822] = {
        { id = "start", role = "start", normalizedX = 0.3800, normalizedY = 0.7940, nodeScale = 1.0000, isPlaceholder = false },
    },
    [66522] = {
        { id = "start", role = "start", normalizedX = 0.4700, normalizedY = 0.5100, nodeScale = 1.0000, isPlaceholder = false },
    },
}
