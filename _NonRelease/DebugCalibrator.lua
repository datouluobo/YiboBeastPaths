local addonName, ns = ...
local YBP = _G.YiboBeastPaths

--- 默认调试数据库结构
local debugDefaults = {
    enabled = false,
    selectedPetIDByMap = {},
    transforms = {},
    nodeTransforms = {},
    ui = {
        stepMove = 0.005,
        stepScale = 0.01,
        advanced = false,
    },
}

--- 步进级别定义
local stepPresets = {
    fine = {
        label = "细",
        move = 0.002,
        scale = 0.005,
    },
    medium = {
        label = "中",
        move = 0.005,
        scale = 0.01,
    },
    coarse = {
        label = "粗",
        move = 0.01,
        scale = 0.02,
    },
}

--- 步进顺序列表（用于循环切换）
local stepOrder = { "fine", "medium", "coarse" }

----------------------------------------------------------------
-- 工具函数
----------------------------------------------------------------

local function DeepCopyTable(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = DeepCopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function CopyDefaults(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                CopyDefaults(target[key], value)
            else
                target[key] = value
            end
        end
    end
end

local function FormatFloat(val)
    -- 格式化为 4 位小数，保留正负号
    return string.format("%.4f", val)
end

local function GetPetDebugVisual(petID)
    local tooltipData = ns.routeNodeTooltips and ns.routeNodeTooltips[petID] or nil
    return {
        iconTexture = (tooltipData and tooltipData.imageTexture) or (tooltipData and tooltipData.iconTexture) or "Interface\\Icons\\Ability_Tracking",
        footTexture = "Interface\\Icons\\Ability_Tracking",
        displayLabel = (tooltipData and tooltipData.displayLabel) or (tooltipData and tooltipData.colorName) or "外观- 未知",
    }
end

----------------------------------------------------------------
-- 调试状态管理
----------------------------------------------------------------

function YBP:InitDebugDB()
    if type(_G.YiboBeastPathsDebugDB) ~= "table" then
        _G.YiboBeastPathsDebugDB = {}
    end
    CopyDefaults(_G.YiboBeastPathsDebugDB, debugDefaults)
end

function YBP:IsDebugEnabled()
    local db = _G.YiboBeastPathsDebugDB
    return db and db.enabled or false
end

function YBP:SetDebugEnabled(enabled)
    local db = _G.YiboBeastPathsDebugDB
    if not db then
        return
    end
    db.enabled = enabled
    if not enabled then
        self:HideDebugPanel()
    else
        self:ShowDebugPanel()
    end
    self:RefreshMapLayer()
    self:RefreshDebugPanel()
end

function YBP:GetDebugPetIDsForCurrentMap()
    local mapID = self:GetCurrentWorldMapID()
    if not mapID then
        return {}
    end
    return self:GetVisiblePetIDsForMap(mapID)
end

function YBP:GetSelectedDebugPetID()
    local db = _G.YiboBeastPathsDebugDB
    if not db then
        return nil
    end
    local mapID = self:GetCurrentWorldMapID()
    if not mapID then
        return nil
    end
    -- 从每地图记录中取
    if db.selectedPetIDByMap[mapID] then
        return db.selectedPetIDByMap[mapID]
    end
    -- 默认取该地图第一条
    local petIDs = self:GetVisiblePetIDsForMap(mapID)
    if #petIDs > 0 then
        return petIDs[1]
    end
    return nil
end

function YBP:SetSelectedDebugPetID(petID)
    local db = _G.YiboBeastPathsDebugDB
    if not db then
        return
    end
    local mapID = self:GetCurrentWorldMapID()
    if not mapID then
        return
    end
    db.selectedPetIDByMap[mapID] = petID
    self:RefreshMapLayer()
    self:RefreshDebugPanel()
end

function YBP:GetDebugTransform(petID)
    local db = _G.YiboBeastPathsDebugDB
    if not db or not db.transforms then
        return nil
    end
    return db.transforms[petID]
end

function YBP:GetDebugRouteNode(petID, nodeID)
    local db = _G.YiboBeastPathsDebugDB
    if not db or not db.nodeTransforms or not db.nodeTransforms[petID] then
        return nil
    end
    return db.nodeTransforms[petID][nodeID]
end

--- 确保当前选中宠物有调试参数（从正式参数复制初始值）
function YBP:EnsureDebugTransform(petID)
    local db = _G.YiboBeastPathsDebugDB
    if not db then
        return
    end
    if not db.transforms[petID] then
        -- 从正式配置复制作为初始值
        local formal = ns.routeTransforms and ns.routeTransforms[petID] or {}
        db.transforms[petID] = {
            offsetX = formal.offsetX or 0,
            offsetY = formal.offsetY or 0,
            scale = formal.scale or 1,
            scaleX = formal.scaleX or 1,
            scaleY = formal.scaleY or 1,
            thickness = formal.thickness or 1,
            opacity = formal.opacity or 1,
        }
    end
end

function YBP:EnsureDebugRouteNode(petID, nodeID)
    local db = _G.YiboBeastPathsDebugDB
    if not db then
        return
    end

    local formalNodes = ns.routeNodes and ns.routeNodes[petID]
    if not formalNodes then
        return
    end

    local formalNode
    for _, node in ipairs(formalNodes) do
        if node.id == nodeID then
            formalNode = node
            break
        end
    end
    if not formalNode then
        return
    end

    db.nodeTransforms[petID] = db.nodeTransforms[petID] or {}
    if not db.nodeTransforms[petID][nodeID] then
        db.nodeTransforms[petID][nodeID] = {
            normalizedX = formalNode.normalizedX or 0.5,
            normalizedY = formalNode.normalizedY or 0.5,
            nodeScale = formalNode.nodeScale or 1.0,
            isPlaceholder = false,
        }
    end
end

function YBP:AdjustDebugValue(petID, field, delta)
    local db = _G.YiboBeastPathsDebugDB
    if not db then
        return
    end
    self:EnsureDebugTransform(petID)
    if db.transforms[petID] and db.transforms[petID][field] ~= nil then
        db.transforms[petID][field] = db.transforms[petID][field] + delta
        if field == "opacity" then
            if db.transforms[petID][field] < 0.10 then
                db.transforms[petID][field] = 0.10
            elseif db.transforms[petID][field] > 1.00 then
                db.transforms[petID][field] = 1.00
            end
        end
    end
    self:RefreshMapLayer()
    self:RefreshDebugPanel()
end

function YBP:AdjustDebugRouteNodeValue(petID, nodeID, field, delta)
    local db = _G.YiboBeastPathsDebugDB
    if not db then
        return
    end

    self:EnsureDebugRouteNode(petID, nodeID)
    local node = db.nodeTransforms[petID] and db.nodeTransforms[petID][nodeID]
    if not node or node[field] == nil then
        return
    end

    node[field] = node[field] + delta
    if field == "nodeScale" then
        if node[field] < 0.50 then
            node[field] = 0.50
        elseif node[field] > 3.00 then
            node[field] = 3.00
        end
        node[field] = math.floor(node[field] * 100 + 0.5) / 100
    else
        if node[field] < 0.0 then
            node[field] = 0.0
        elseif node[field] > 1.2 then
            node[field] = 1.2
        end
    end

    self:RefreshMapLayer()
    self:RefreshDebugPanel()
end

function YBP:GetDebugRouteThickness()
    local petID = self:GetSelectedDebugPetID()
    if not petID then
        return 1.0
    end
    local transform = self:GetResolvedTransform(petID)
    return transform and transform.thickness or 1.0
end

function YBP:AdjustDebugRouteThickness(delta)
    local petID = self:GetSelectedDebugPetID()
    if not petID then
        return
    end
    self:EnsureDebugTransform(petID)
    local db = _G.YiboBeastPathsDebugDB
    if not db or not db.transforms or not db.transforms[petID] then
        return
    end
    local value = (db.transforms[petID].thickness or 1.0) + delta
    if value < 0.4 then
        value = 0.4
    elseif value > 4.0 then
        value = 4.0
    end

    db.transforms[petID].thickness = math.floor(value * 100 + 0.5) / 100
    self:RefreshMapLayer()
    self:RefreshDebugPanel()
end

function YBP:ResetDebugTransform(petID)
    local db = _G.YiboBeastPathsDebugDB
    if not db or not db.transforms then
        return
    end
    db.transforms[petID] = nil
    self:RefreshMapLayer()
    self:RefreshDebugPanel()
end

function YBP:ResetDebugRouteNode(petID, nodeID)
    local db = _G.YiboBeastPathsDebugDB
    if not db or not db.nodeTransforms or not db.nodeTransforms[petID] then
        return
    end

    db.nodeTransforms[petID][nodeID] = nil
    if not next(db.nodeTransforms[petID]) then
        db.nodeTransforms[petID] = nil
    end

    self:RefreshMapLayer()
    self:RefreshDebugPanel()
end

----------------------------------------------------------------
-- 导出功能
----------------------------------------------------------------

local function FormatTransformEntry(petID, transform)
    return string.format(
        "[%d] = { offsetX = %s, offsetY = %s, scale = %s, scaleX = %s, scaleY = %s, thickness = %s, opacity = %s },",
        petID,
        FormatFloat(transform.offsetX),
        FormatFloat(transform.offsetY),
        FormatFloat(transform.scale),
        FormatFloat(transform.scaleX),
        FormatFloat(transform.scaleY),
        FormatFloat(transform.thickness or 1.0),
        FormatFloat(transform.opacity or 1.0)
    )
end

local function FormatRouteNodeEntry(petID, node)
    return string.format(
        "[%d] = { { id = \"%s\", role = \"%s\", normalizedX = %s, normalizedY = %s, nodeScale = %s, isPlaceholder = false }, },",
        petID,
        node.id or "start",
        node.role or "start",
        FormatFloat(node.normalizedX or 0.5),
        FormatFloat(node.normalizedY or 0.5),
        FormatFloat(node.nodeScale or 1.0)
    )
end

function YBP:ExportCurrentDebugTransform()
    local petID = self:GetSelectedDebugPetID()
    if not petID then
        return ""
    end

    -- 优先导出调试参数，若没有则导出正式参数
    local debugT = self:GetDebugTransform(petID)
    local transform = debugT or (ns.routeTransforms and ns.routeTransforms[petID])
    if not transform then
        return ""
    end

    local lines = {
        "-- RouteTransforms.lua",
        FormatTransformEntry(petID, transform),
    }

    local nodes = self.GetResolvedRouteNodes and self:GetResolvedRouteNodes(petID) or nil
    if nodes and nodes[1] then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "-- RouteNodes.lua"
        lines[#lines + 1] = FormatRouteNodeEntry(petID, nodes[1])
    end

    return table.concat(lines, "\n")
end

function YBP:ExportCurrentMapDebugTransforms()
    local mapID = self:GetCurrentWorldMapID()
    if not mapID then
        return ""
    end

    local petIDs = self:GetVisiblePetIDsForMap(mapID)
    if #petIDs == 0 then
        return ""
    end

    local transformLines = {}
    local nodeLines = {}
    table.sort(petIDs)
    for _, petID in ipairs(petIDs) do
        local debugT = self:GetDebugTransform(petID)
        local transform = debugT or (ns.routeTransforms and ns.routeTransforms[petID])
        if transform then
            transformLines[#transformLines + 1] = FormatTransformEntry(petID, transform)
        end

        local nodes = self.GetResolvedRouteNodes and self:GetResolvedRouteNodes(petID) or nil
        if nodes and nodes[1] then
            nodeLines[#nodeLines + 1] = FormatRouteNodeEntry(petID, nodes[1])
        end
    end

    local lines = {}
    if #transformLines > 0 then
        lines[#lines + 1] = "-- RouteTransforms.lua"
        for _, line in ipairs(transformLines) do
            lines[#lines + 1] = line
        end
    end

    if #nodeLines > 0 then
        if #lines > 0 then
            lines[#lines + 1] = ""
        end
        lines[#lines + 1] = "-- RouteNodes.lua"
        for _, line in ipairs(nodeLines) do
            lines[#lines + 1] = line
        end
    end

    return table.concat(lines, "\n")
end

----------------------------------------------------------------
-- 面板构建
----------------------------------------------------------------

local panel = nil
local panelElements = {}

local function GetOrCreatePanel()
    if panel then
        return panel
    end

    -- 根面板
    panel = CreateFrame("Frame", "TTRDebugPanel", UIParent, "BackdropTemplate")
    panel:SetSize(300, 620)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(100)
    panel:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    panel:SetBackdropColor(0.05, 0.05, 0.12, 0.92)
    panel:SetBackdropBorderColor(0.40, 0.55, 0.90, 0.85)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    panel:Hide()

    panelElements.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panelElements.title:SetPoint("TOP", panel, "TOP", 0, -6)
    panelElements.title:SetText("调试校准面板")
    panelElements.title:SetTextColor(0.70, 0.85, 1.0)

    -- 关闭按钮
    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        YBP:SetDebugEnabled(false)
    end)
    panelElements.closeBtn = closeBtn

    local yOff = -30

    -- === 区块 1：当前状态区 ===
    local stateY = yOff

    panelElements.petIconBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    panelElements.petIconBg:SetSize(42, 42)
    panelElements.petIconBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, stateY - 2)
    panelElements.petIconBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    panelElements.petIconBg:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    panelElements.petIconBg:SetBackdropBorderColor(0.75, 0.55, 0.18, 0.78)

    panelElements.petIcon = panelElements.petIconBg:CreateTexture(nil, "ARTWORK")
    panelElements.petIcon:SetPoint("TOPLEFT", panelElements.petIconBg, "TOPLEFT", 4, -4)
    panelElements.petIcon:SetPoint("BOTTOMRIGHT", panelElements.petIconBg, "BOTTOMRIGHT", -4, 4)
    panelElements.petIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    panelElements.petIcon:SetTexture("Interface\\Icons\\Ability_Tracking")

    panelElements.petFootprint = panel:CreateTexture(nil, "OVERLAY")
    panelElements.petFootprint:SetSize(18, 18)
    panelElements.petFootprint:SetPoint("BOTTOMLEFT", panelElements.petIconBg, "BOTTOMLEFT", 26, -4)
    panelElements.petFootprint:SetTexture("Interface\\Icons\\Ability_Tracking")
    panelElements.petFootprint:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    panelElements.petFootprint:SetVertexColor(1.00, 0.82, 0.18, 1.00)

    panelElements.mapText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panelElements.mapText:SetPoint("TOPLEFT", panel, "TOPLEFT", 60, stateY)
    panelElements.mapText:SetText("外观: -")

    panelElements.petText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panelElements.petText:SetPoint("TOPLEFT", panel, "TOPLEFT", 60, stateY - 18)
    panelElements.petText:SetText("宠物: -")

    panelElements.paramText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panelElements.paramText:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, stateY - 52)
    panelElements.paramText:SetText("X: —  Y: —  S: —")

    panelElements.thicknessText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panelElements.thicknessText:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, stateY - 68)
    panelElements.thicknessText:SetText("线宽: —")

    panelElements.opacityText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panelElements.opacityText:SetPoint("TOPLEFT", panel, "TOPLEFT", 110, stateY - 68)
    panelElements.opacityText:SetText("透明: —")

    panelElements.advParamText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panelElements.advParamText:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, stateY - 84)
    panelElements.advParamText:SetText("SX: —  SY: —")
    panelElements.advParamText:Hide()

    panelElements.nodeText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panelElements.nodeText:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, stateY - 100)
    panelElements.nodeText:SetText("NX: —  NY: —  NS: —")

    local divider1 = panel:CreateTexture(nil, "OVERLAY")
    divider1:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    divider1:SetVertexColor(0.4, 0.55, 0.9, 0.3)
    divider1:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, stateY - 116)
    divider1:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, stateY - 116)
    divider1:SetHeight(1)

    -- === 区块 2：路径切换区 ===
    local navY = stateY - 132

    local prevBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    prevBtn:SetSize(60, 22)
    prevBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 50, navY)
    prevBtn:SetText("上一条")
    prevBtn:SetScript("OnClick", function()
        local petIDs = YBP:GetDebugPetIDsForCurrentMap()
        local selected = YBP:GetSelectedDebugPetID()
        if #petIDs == 0 then
            return
        end
        local idx = 1
        for i, id in ipairs(petIDs) do
            if id == selected then
                idx = i
                break
            end
        end
        idx = idx - 1
        if idx < 1 then
            idx = #petIDs
        end
        YBP:SetSelectedDebugPetID(petIDs[idx])
    end)
    panelElements.prevBtn = prevBtn

    local nextBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    nextBtn:SetSize(60, 22)
    nextBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -50, navY)
    nextBtn:SetText("下一条")
    nextBtn:SetScript("OnClick", function()
        local petIDs = YBP:GetDebugPetIDsForCurrentMap()
        local selected = YBP:GetSelectedDebugPetID()
        if #petIDs == 0 then
            return
        end
        local idx = 1
        for i, id in ipairs(petIDs) do
            if id == selected then
                idx = i
                break
            end
        end
        idx = idx + 1
        if idx > #petIDs then
            idx = 1
        end
        YBP:SetSelectedDebugPetID(petIDs[idx])
    end)
    panelElements.nextBtn = nextBtn

    local divider2 = panel:CreateTexture(nil, "OVERLAY")
    divider2:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    divider2:SetVertexColor(0.4, 0.55, 0.9, 0.3)
    divider2:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, navY - 18)
    divider2:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, navY - 18)
    divider2:SetHeight(1)

    -- === 区块 3：参数调节区 ===
    local adjY = navY - 34

    -- 行 1: X-, X+, Y-, Y+, Scale-, Scale+
    local function MakeAdjustButton(parent, text, left, top, width, petID, field, delta)
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(width or 42, 22)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
        btn:SetText(text)
        btn:SetScript("OnClick", function()
            local pid = YBP:GetSelectedDebugPetID()
            if pid then
                local db = _G.YiboBeastPathsDebugDB
                local step = db.ui.stepMove
                if field == "__nodeX" then
                    YBP:AdjustDebugRouteNodeValue(pid, "start", "normalizedX", delta * step)
                elseif field == "__nodeY" then
                    YBP:AdjustDebugRouteNodeValue(pid, "start", "normalizedY", delta * step)
                elseif field == "__nodeScale" then
                    YBP:AdjustDebugRouteNodeValue(pid, "start", "nodeScale", delta * db.ui.stepScale)
                else
                    YBP:EnsureDebugTransform(pid)
                    step = (field:find("scale") or field:find("Scale"))
                        and db.ui.stepScale or db.ui.stepMove
                    YBP:AdjustDebugValue(pid, field, delta * step)
                end
            end
        end)
        return btn
    end

    local function MakeStepButton(parent, text, left, top, width, stepKey)
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(width or 42, 22)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
        btn:SetText(text)
        btn:SetScript("OnClick", function()
            local db = _G.YiboBeastPathsDebugDB
            if not db then
                return
            end
            local preset = stepPresets[stepKey]
            if preset then
                db.ui.stepMove = preset.move
                db.ui.stepScale = preset.scale
            end
            YBP:RefreshDebugPanel()
        end)
        return btn
    end

    -- 常用调节行
    panelElements.btnXMinus = MakeAdjustButton(panel, "X-", 8, adjY, 36, nil, "offsetX", -1)
    panelElements.btnXPlus = MakeAdjustButton(panel, "X+", 48, adjY, 36, nil, "offsetX", 1)
    panelElements.btnYMinus = MakeAdjustButton(panel, "Y-", 96, adjY, 36, nil, "offsetY", -1)
    panelElements.btnYPlus = MakeAdjustButton(panel, "Y+", 136, adjY, 36, nil, "offsetY", 1)
    panelElements.btnSMinus = MakeAdjustButton(panel, "S-", 184, adjY, 36, nil, "scale", -1)
    panelElements.btnSPlus = MakeAdjustButton(panel, "S+", 224, adjY, 36, nil, "scale", 1)

    local thickY = adjY - 28
    panelElements.btnTMinus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panelElements.btnTMinus:SetSize(54, 22)
    panelElements.btnTMinus:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, thickY)
    panelElements.btnTMinus:SetText("T-")
    panelElements.btnTMinus:SetScript("OnClick", function()
        YBP:AdjustDebugRouteThickness(-0.10)
    end)

    panelElements.btnTPlus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panelElements.btnTPlus:SetSize(54, 22)
    panelElements.btnTPlus:SetPoint("TOPLEFT", panel, "TOPLEFT", 66, thickY)
    panelElements.btnTPlus:SetText("T+")
    panelElements.btnTPlus:SetScript("OnClick", function()
        YBP:AdjustDebugRouteThickness(0.10)
    end)

    panelElements.btnOMinus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panelElements.btnOMinus:SetSize(54, 22)
    panelElements.btnOMinus:SetPoint("TOPLEFT", panel, "TOPLEFT", 140, thickY)
    panelElements.btnOMinus:SetText("O-")
    panelElements.btnOMinus:SetScript("OnClick", function()
        local pid = YBP:GetSelectedDebugPetID()
        if pid then
            YBP:AdjustDebugValue(pid, "opacity", -0.05)
        end
    end)

    panelElements.btnOPlus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panelElements.btnOPlus:SetSize(54, 22)
    panelElements.btnOPlus:SetPoint("TOPLEFT", panel, "TOPLEFT", 198, thickY)
    panelElements.btnOPlus:SetText("O+")
    panelElements.btnOPlus:SetScript("OnClick", function()
        local pid = YBP:GetSelectedDebugPetID()
        if pid then
            YBP:AdjustDebugValue(pid, "opacity", 0.05)
        end
    end)

    -- 高级调节行（默认隐藏）
    local advY = thickY - 28
    panelElements.btnSXMinus = MakeAdjustButton(panel, "SX-", 8, advY, 42, nil, "scaleX", -1)
    panelElements.btnSXPlus = MakeAdjustButton(panel, "SX+", 54, advY, 42, nil, "scaleX", 1)
    panelElements.btnSYMinus = MakeAdjustButton(panel, "SY-", 108, advY, 42, nil, "scaleY", -1)
    panelElements.btnSYPlus = MakeAdjustButton(panel, "SY+", 154, advY, 42, nil, "scaleY", 1)

    panelElements.btnSXMinus:Hide()
    panelElements.btnSXPlus:Hide()
    panelElements.btnSYMinus:Hide()
    panelElements.btnSYPlus:Hide()

    local nodeY = advY - 28
    panelElements.btnNXMinus = MakeAdjustButton(panel, "NX-", 8, nodeY, 42, nil, "__nodeX", -1)
    panelElements.btnNXPlus = MakeAdjustButton(panel, "NX+", 54, nodeY, 42, nil, "__nodeX", 1)
    panelElements.btnNYMinus = MakeAdjustButton(panel, "NY-", 108, nodeY, 42, nil, "__nodeY", -1)
    panelElements.btnNYPlus = MakeAdjustButton(panel, "NY+", 154, nodeY, 42, nil, "__nodeY", 1)
    panelElements.btnNSMinus = MakeAdjustButton(panel, "NS-", 208, nodeY, 42, nil, "__nodeScale", -1)
    panelElements.btnNSPlus = MakeAdjustButton(panel, "NS+", 254, nodeY, 42, nil, "__nodeScale", 1)

    -- 步进行
    local stepY = nodeY - 28
    panelElements.stepLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panelElements.stepLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, stepY - 3)
    panelElements.stepLabel:SetText("步进:")

    panelElements.btnStepFine = MakeStepButton(panel, "细", 48, stepY, 36, "fine")
    panelElements.btnStepMed = MakeStepButton(panel, "中", 88, stepY, 36, "medium")
    panelElements.btnStepCoarse = MakeStepButton(panel, "粗", 128, stepY, 42, "coarse")

    -- 辅助按钮行
    local ctrlY = stepY - 28

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(80, 22)
    resetBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, ctrlY)
    resetBtn:SetText("重置当前")
    resetBtn:SetScript("OnClick", function()
        local petID = YBP:GetSelectedDebugPetID()
        if petID then
            YBP:ResetDebugTransform(petID)
            YBP:ResetDebugRouteNode(petID, "start")
        end
    end)
    panelElements.resetBtn = resetBtn

    local saveBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    saveBtn:SetSize(80, 22)
    saveBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 98, ctrlY)
    saveBtn:SetText("保存当前")
    saveBtn:SetScript("OnClick", function()
        local petID = YBP:GetSelectedDebugPetID()
        if petID then
            YBP:EnsureDebugTransform(petID)
            YBP:EnsureDebugRouteNode(petID, "start")
            print(string.format("|cff4fd8ff[YBP调试]|r 已保存宠物 [%d] 的路线与起点调试参数。", petID))
        end
    end)
    panelElements.saveBtn = saveBtn

    local advToggle = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    advToggle:SetSize(80, 22)
    advToggle:SetPoint("TOPLEFT", panel, "TOPLEFT", 186, ctrlY)
    advToggle:SetText("显示高级")
    advToggle:SetScript("OnClick", function()
        local db = _G.YiboBeastPathsDebugDB
        if not db then
            return
        end
        db.ui.advanced = not db.ui.advanced
        YBP:RefreshDebugPanel()
    end)
    panelElements.advToggle = advToggle

    local divider3 = panel:CreateTexture(nil, "OVERLAY")
    divider3:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    divider3:SetVertexColor(0.4, 0.55, 0.9, 0.3)
    divider3:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, ctrlY - 18)
    divider3:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, ctrlY - 18)
    divider3:SetHeight(1)

    -- === 区块 4：参数导出区 ===
    local exportY = ctrlY - 34

    -- 导出文本框
    local exportFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    exportFrame:SetSize(280, 92)
    exportFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, exportY)
    exportFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    exportFrame:SetBackdropColor(0.02, 0.02, 0.08, 0.90)
    exportFrame:SetBackdropBorderColor(0.30, 0.40, 0.70, 0.70)
    panelElements.exportFrame = exportFrame

    local exportScroll = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
    exportScroll:SetPoint("TOPLEFT", exportFrame, "TOPLEFT", 4, -4)
    exportScroll:SetPoint("BOTTOMRIGHT", exportFrame, "BOTTOMRIGHT", -28, 4)
    panelElements.exportScroll = exportScroll

    local editBox = CreateFrame("EditBox", nil, exportScroll)
    editBox:SetWidth(244)
    editBox:SetHeight(400)
    editBox:SetMultiLine(true)
    editBox:EnableMouse(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetTextInsets(4, 4, 2, 2)
    editBox:SetPoint("TOPLEFT", exportScroll, "TOPLEFT", 0, 0)
    editBox:SetScript("OnTextChanged", function(self)
        self:GetParent():UpdateScrollChildRect()
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    exportScroll:SetScrollChild(editBox)
    panelElements.exportBox = editBox

    local exportBtnY = exportY - 100

    local exportCurBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    exportCurBtn:SetSize(80, 22)
    exportCurBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 15, exportBtnY)
    exportCurBtn:SetText("导出当前")
    exportCurBtn:SetScript("OnClick", function()
        local text = YBP:ExportCurrentDebugTransform()
        panelElements.exportBox:SetText(text)
    end)
    panelElements.exportCurBtn = exportCurBtn

    local exportMapBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    exportMapBtn:SetSize(80, 22)
    exportMapBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 102, exportBtnY)
    exportMapBtn:SetText("导出本图")
    exportMapBtn:SetScript("OnClick", function()
        local text = YBP:ExportCurrentMapDebugTransforms()
        panelElements.exportBox:SetText(text)
    end)
    panelElements.exportMapBtn = exportMapBtn

    local selectAllBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    selectAllBtn:SetSize(60, 22)
    selectAllBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 192, exportBtnY)
    selectAllBtn:SetText("全选")
    selectAllBtn:SetScript("OnClick", function()
        panelElements.exportBox:HighlightText()
    end)
    panelElements.selectAllBtn = selectAllBtn

    return panel
end

function YBP:ShowDebugPanel()
    local p = GetOrCreatePanel()
    if p then
        p:Show()
        self:RefreshDebugPanel()
    end
end

function YBP:HideDebugPanel()
    if panel then
        panel:Hide()
    end
end

function YBP:RefreshDebugPanel()
    if not panel or not panel:IsShown() then
        return
    end

    local db = _G.YiboBeastPathsDebugDB
    if not db then
        return
    end

    local petIDs = self:GetDebugPetIDsForCurrentMap()
    local selectedPetID = self:GetSelectedDebugPetID()

    -- 更新宠物信息
    if selectedPetID then
        local petInfo = ns.pets and ns.pets[selectedPetID]
        local visual = GetPetDebugVisual(selectedPetID)
        local petName = petInfo and (petInfo.name or petInfo.nameEN) or "未知"
        panelElements.petIcon:SetTexture(visual.iconTexture)
        panelElements.petFootprint:SetTexture(visual.footTexture)
        panelElements.mapText:SetText(visual.displayLabel)
        panelElements.petText:SetText(string.format("宠物: %s [%d] (%d/%d)",
            petName, selectedPetID,
            self:GetPetIndexInCurrentMap(selectedPetID),
            #petIDs))

        -- 参数摘要
        local transform = self:GetResolvedTransform(selectedPetID)
        if transform then
            -- 步进标签更新
            local stepLabel = "?"
            for _, key in ipairs(stepOrder) do
                local preset = stepPresets[key]
                if preset and preset.move == db.ui.stepMove then
                    stepLabel = preset.label
                    break
                end
            end
            panelElements.paramText:SetText(string.format(
                "X: %s  Y: %s  S: %s  [%s]",
                FormatFloat(transform.offsetX),
                FormatFloat(transform.offsetY),
                FormatFloat(transform.scale),
                stepLabel
            ))

            panelElements.thicknessText:SetText(string.format(
                "线宽: %.2f",
                self:GetDebugRouteThickness()
            ))
            panelElements.opacityText:SetText(string.format(
                "透明: %.2f",
                transform.opacity or 1.0
            ))

            -- 高级参数
            panelElements.advParamText:SetText(string.format(
                "SX: %s  SY: %s",
                FormatFloat(transform.scaleX),
                FormatFloat(transform.scaleY)
            ))

            local nodeX, nodeY, nodeScale = "—", "—", "—"
            local nodes = self.GetResolvedRouteNodes and self:GetResolvedRouteNodes(selectedPetID) or nil
            if nodes and nodes[1] then
                nodeX = FormatFloat(nodes[1].normalizedX or 0.5)
                nodeY = FormatFloat(nodes[1].normalizedY or 0.5)
                nodeScale = FormatFloat(nodes[1].nodeScale or 1.0)
            end
            panelElements.nodeText:SetText(string.format(
                "NX: %s  NY: %s  NS: %s",
                nodeX,
                nodeY,
                nodeScale
            ))

            -- 高级模式开关
            local isAdvanced = db.ui.advanced or false
            if isAdvanced then
                panelElements.advParamText:Show()
                panelElements.btnSXMinus:Show()
                panelElements.btnSXPlus:Show()
                panelElements.btnSYMinus:Show()
                panelElements.btnSYPlus:Show()
                panelElements.advToggle:SetText("隐藏高级")
            else
                panelElements.advParamText:Hide()
                panelElements.btnSXMinus:Hide()
                panelElements.btnSXPlus:Hide()
                panelElements.btnSYMinus:Hide()
                panelElements.btnSYPlus:Hide()
                panelElements.advToggle:SetText("显示高级")
            end
        end
    else
        panelElements.petIcon:SetTexture("Interface\\Icons\\Ability_Tracking")
        panelElements.petFootprint:SetTexture("Interface\\Icons\\Ability_Tracking")
        panelElements.mapText:SetText("外观: -")
        panelElements.petText:SetText("宠物: (无)")
        panelElements.paramText:SetText("X: —  Y: —  S: —")
        panelElements.thicknessText:SetText("线宽: —")
        panelElements.opacityText:SetText("透明: —")
        panelElements.advParamText:SetText("SX: —  SY: —")
        panelElements.nodeText:SetText("NX: —  NY: —  NS: —")
    end

    -- 更新导出文本框的内容为当前选中宠物的参数
    local exportText = self:ExportCurrentDebugTransform()
    if exportText ~= "" then
        panelElements.exportBox:SetText(exportText)
    end
end

--- 辅助：获取当前地图中某宠物的序号
function YBP:GetPetIndexInCurrentMap(petID)
    local petIDs = self:GetDebugPetIDsForCurrentMap()
    for i, id in ipairs(petIDs) do
        if id == petID then
            return i
        end
    end
    return 0
end

----------------------------------------------------------------
-- 命令处理
----------------------------------------------------------------

SLASH_YBPDEBUG1 = "/ybpdebug"
SlashCmdList.YBPDEBUG = function(msg)
    YBP:SetDebugEnabled(true)
    print("|cff4fd8ff[YBP调试]|r 调试面板已显示。")
end

----------------------------------------------------------------
-- 集成：ADDON_LOADED 事件初始化调试模块
----------------------------------------------------------------

-- 在 Core.lua 的 ADDON_LOADED 之后初始化调试 DB
-- 使用 ADDON_LOADED 事件确保在正式配置之后加载
local debugInitFrame = CreateFrame("Frame")
debugInitFrame:RegisterEvent("ADDON_LOADED")
debugInitFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        YBP:InitDebugDB()
    end
end)

-- 世界地图事件：地图切换时刷新面板
-- 延迟到 Blizzard_WorldMap 加载后 Hook
local mapHookFrame = CreateFrame("Frame")
mapHookFrame:RegisterEvent("ADDON_LOADED")
mapHookFrame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == "Blizzard_WorldMap" and WorldMapFrame then
        WorldMapFrame:HookScript("OnShow", function()
            YBP:RefreshDebugPanel()
        end)
        WorldMapFrame:HookScript("OnUpdate", function()
            YBP:RefreshDebugPanel()
        end)
    end
end)
