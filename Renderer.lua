local addonName, ns = ...
local YBP = _G.YiboBeastPaths

local overlayFrames = {}
local routeNodeFrames = {}
local hoveredRoutePetID = nil
local defaultMapBounds = {
    left = 0.0,
    top = 0.0,
    right = 1.0,
    bottom = 1.0,
}
local defaultTransform = {
    offsetX = 0.0,
    offsetY = 0.0,
    scale = 1.0,
    scaleX = 1.0,
    scaleY = 1.0,
    thickness = 1.0,
    opacity = 1.0,
}
local thicknessOffsets = {
    { 0, 0 },
    { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 },
    { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 },
    { -2, 0 }, { 2, 0 }, { 0, -2 }, { 0, 2 },
}
local zoneNameToMapID = {
    ["翡翠林"] = 371,
    ["Jade Forest"] = 371,
    ["The Jade Forest"] = 371,
    ["昆莱山"] = 379,
    ["Kun-Lai Summit"] = 379,
    ["四风谷"] = 376,
    ["Valley of the Four Winds"] = 376,
    ["卡桑琅丛林"] = 418,
    ["Krasarang Wilds"] = 418,
    ["恐惧废土"] = 422,
    ["Dread Wastes"] = 422,
    ["锦绣谷"] = 390,
    ["Vale of Eternal Blossoms"] = 390,
    ["螳螂高原"] = 388,
    ["Townlong Steppes"] = 388,
}
local blockedParentMapNames = {
    ["Pandaria"] = true,
    ["潘达利亚"] = true,
}

for _, pet in pairs(ns.pets or {}) do
    if pet.zone and pet.mapID and not zoneNameToMapID[pet.zone] then
        zoneNameToMapID[pet.zone] = pet.mapID
    end
end

local function TrimText(text)
    if type(text) ~= "string" then
        return nil
    end

    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        return nil
    end

    return text
end

local function GetMapDropdownText()
    local candidates = {
        "WorldMapFrameAreaDropDownText",
        "WorldMapFrameZoneDropDownText",
        "WorldMapZoneDropDownText",
        "WorldMapAreaDropDownText",
    }

    for _, name in ipairs(candidates) do
        local widget = _G[name]
        if widget and widget.GetText then
            local text = TrimText(widget:GetText())
            if text then
                return text
            end
        end
    end
end

function YBP:GetCurrentWorldMapID()
    local text = GetMapDropdownText()
    if text then
        if blockedParentMapNames[text] then
            return nil
        end

        if zoneNameToMapID[text] then
            return zoneNameToMapID[text]
        end
    end

    if WorldMapFrame and WorldMapFrame.GetMapID then
        local mapID = WorldMapFrame:GetMapID()
        if mapID and mapID > 0 then
            return mapID
        end
    end

    if WorldMapFrame and WorldMapFrame.mapID and WorldMapFrame.mapID > 0 then
        return WorldMapFrame.mapID
    end
end

local function GetOverlayParent()
    if _G.WorldMapDetailFrame then
        return _G.WorldMapDetailFrame
    end

    if _G.WorldMapButton then
        return _G.WorldMapButton
    end

    if WorldMapFrame and WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
        return WorldMapFrame.ScrollContainer.Child
    end

    return WorldMapFrame
end

local function EnsureOverlayFrame(petID, parent)
    local frame = overlayFrames[petID]
    if frame and frame:GetParent() ~= parent then
        frame:Hide()
        overlayFrames[petID] = nil
        frame = nil
    end

    if frame then
        return frame, frame.texture
    end

    frame = CreateFrame("Frame", nil, parent)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel((parent:GetFrameLevel() or 1) + 10)
    frame:SetAllPoints(parent)
    frame:Hide()

    frame.texture = frame:CreateTexture(nil, "OVERLAY")
    frame.texture:SetAllPoints(frame)
    frame.texture:SetBlendMode("BLEND")

    frame.emphasis = frame:CreateTexture(nil, "OVERLAY")
    frame.emphasis:SetAllPoints(frame)
    frame.emphasis:SetBlendMode("ADD")
    frame.emphasis:Hide()

    frame.echoes = {}
    for i = 2, #thicknessOffsets do
        local echo = frame:CreateTexture(nil, "OVERLAY")
        echo:SetBlendMode("BLEND")
        echo:Hide()
        frame.echoes[#frame.echoes + 1] = echo
    end

    overlayFrames[petID] = frame
    return frame, frame.texture
end

local function HideAllRouteNodes()
    for _, nodeMap in pairs(routeNodeFrames) do
        for _, button in pairs(nodeMap) do
            button:Hide()
        end
    end
end

local function GetNodeRoleLabel(role)
    if role == "start" then
        return "路线起点"
    elseif role == "end" then
        return "路线终点"
    elseif role == "mid" then
        return "路线节点"
    end

    return "路线交互点"
end

local function BuildTooltipData(petID, node)
    local tooltipData = ns.routeNodeTooltips and ns.routeNodeTooltips[petID] or nil
    local pet = ns.pets and ns.pets[petID] or nil
    local title = (tooltipData and tooltipData.title) or (pet and pet.name) or ("宠物 " .. tostring(petID))
    local subtitle = (tooltipData and tooltipData.subtitle) or (pet and pet.nameEN) or nil
    local colorName = tooltipData and tooltipData.colorName or nil
    local displayLabel = tooltipData and tooltipData.displayLabel or colorName or nil
    local iconTexture = tooltipData and tooltipData.iconTexture or "Interface\\Icons\\Ability_Hunter_BeastCall"
    local imageTexture = tooltipData and tooltipData.imageTexture or iconTexture
    local tooltipTexture = tooltipData and tooltipData.tooltipTexture or imageTexture
    local footTexture = "Interface\\Icons\\Ability_Tracking"
    local zoneName = pet and (pet.zone or pet.zoneEN) or nil

    return {
        title = title,
        subtitle = subtitle,
        colorName = colorName,
        displayLabel = displayLabel,
        iconTexture = iconTexture,
        imageTexture = imageTexture,
        tooltipTexture = tooltipTexture,
        footTexture = footTexture,
        zoneName = zoneName,
        roleLabel = GetNodeRoleLabel(node and node.role),
        isPlaceholder = node and node.isPlaceholder or false,
        npcID = tooltipData and tooltipData.npcID or nil,
        routeID = petID,
    }
end

local routeNodeTooltip

local function GetOrCreateRouteNodeTooltip()
    if routeNodeTooltip then
        return routeNodeTooltip
    end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(200)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.07, 0.04, 0.08, 0.95)
    frame:SetBackdropBorderColor(0.45, 0.10, 0.22, 0.90)
    frame:Hide()

    frame.portraitBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.portraitBg:SetSize(56, 56)
    frame.portraitBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame.portraitBg:SetBackdropColor(0.10, 0.10, 0.14, 0.98)
    frame.portraitBg:SetBackdropBorderColor(0.85, 0.66, 0.20, 0.90)

    frame.portrait = frame.portraitBg:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetPoint("TOPLEFT", frame.portraitBg, "TOPLEFT", 3, -3)
    frame.portrait:SetPoint("BOTTOMRIGHT", frame.portraitBg, "BOTTOMRIGHT", -3, 3)
    frame.portrait:SetTexCoord(0.02, 0.98, 0.02, 0.98)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetJustifyH("LEFT")
    frame.title:SetTextColor(0.25, 0.85, 1.00)

    frame.meta = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.meta:SetJustifyH("LEFT")
    frame.meta:SetTextColor(1.00, 0.82, 0.00)

    frame.route = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.route:SetJustifyH("LEFT")
    frame.route:SetTextColor(0.72, 0.72, 0.78)

    routeNodeTooltip = frame
    return routeNodeTooltip
end

local function ShowRouteNodeTooltip(button)
    if not button or not button.petID or not button.nodeData then
        return
    end

    local data = BuildTooltipData(button.petID, button.nodeData)
    local tooltip = GetOrCreateRouteNodeTooltip()
    tooltip:ClearAllPoints()
    tooltip:SetPoint(button:GetCenter() > UIParent:GetCenter() and "RIGHT" or "LEFT", button,
        button:GetCenter() > UIParent:GetCenter() and "LEFT" or "RIGHT",
        button:GetCenter() > UIParent:GetCenter() and -12 or 12, 0)

    tooltip.portraitBg:ClearAllPoints()
    tooltip.portraitBg:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, -10)
    tooltip.portrait:SetTexture(data.tooltipTexture)

    local combinedTitle = data.title or ""
    if data.subtitle and data.subtitle ~= "" then
        combinedTitle = string.format("%s  |cffd9d9d9%s|r", combinedTitle, data.subtitle)
    end
    tooltip.title:SetText(combinedTitle)
    tooltip.meta:SetText(data.displayLabel or data.colorName or "")
    tooltip.route:SetText(string.format("Route ID: %d", data.routeID))

    local textWidth = math.max(
        tooltip.title:GetStringWidth() or 0,
        tooltip.meta:GetStringWidth() or 0,
        tooltip.route:GetStringWidth() or 0
    )
    textWidth = math.max(120, math.min(240, textWidth + 8))

    tooltip.title:SetWidth(textWidth)
    tooltip.meta:SetWidth(textWidth)
    tooltip.route:SetWidth(textWidth)

    tooltip.title:ClearAllPoints()
    tooltip.title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 74, -12)
    tooltip.meta:ClearAllPoints()
    tooltip.meta:SetPoint("TOPLEFT", tooltip.title, "BOTTOMLEFT", 0, -6)
    tooltip.route:ClearAllPoints()
    tooltip.route:SetPoint("TOPLEFT", tooltip.meta, "BOTTOMLEFT", 0, -6)

    local frameWidth = 74 + textWidth + 12
    local frameHeight = math.max(78, 12
        + (tooltip.title:GetStringHeight() or 0)
        + 6
        + (tooltip.meta:GetStringHeight() or 0)
        + 6
        + (tooltip.route:GetStringHeight() or 0)
        + 12)
    tooltip:SetSize(frameWidth, frameHeight)
    tooltip:Show()
end

function YBP:SetHoveredRoutePetID(petID)
    if hoveredRoutePetID == petID then
        return
    end

    hoveredRoutePetID = petID
    if self.UpdateOverlayHoverState then
        self:UpdateOverlayHoverState()
    end
end

local function EnsureRouteNodeButton(petID, nodeID, parent)
    local petNodes = routeNodeFrames[petID]
    if not petNodes then
        petNodes = {}
        routeNodeFrames[petID] = petNodes
    end

    local button = petNodes[nodeID]
    if button and button:GetParent() ~= parent then
        button:Hide()
        petNodes[nodeID] = nil
        button = nil
    end

    if button then
        return button
    end

    button = CreateFrame("Button", nil, parent)
    button:SetFrameStrata("DIALOG")
    button:SetFrameLevel((parent:GetFrameLevel() or 1) + 30)
    button:RegisterForClicks("LeftButtonUp")
    button:Hide()

    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetAllPoints(button)

    button.emphasis = button:CreateTexture(nil, "BACKGROUND")
    button.emphasis:SetAtlas("worldquest-questmarker-abilityhighlight")
    button.emphasis:SetBlendMode("ADD")
    button.emphasis:SetSize(26, 26)
    button.emphasis:SetPoint("CENTER", button, "CENTER")
    button.emphasis:SetVertexColor(1.0, 1.0, 1.0, 0.40)
    button.emphasis:Hide()

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAtlas("worldquest-questmarker-abilityhighlight")
    button.highlight:SetAllPoints(button.emphasis)
    button.highlight:SetBlendMode("ADD")
    button.highlight:SetVertexColor(1.00, 1.00, 1.00, 0.20)
    button.highlight:Hide()

    button:SetScript("OnEnter", ShowRouteNodeTooltip)
    button:SetScript("OnLeave", function()
        YBP:SetHoveredRoutePetID(nil)
        if routeNodeTooltip then
            routeNodeTooltip:Hide()
        end
    end)
    button:HookScript("OnEnter", function(self)
        YBP:SetHoveredRoutePetID(self.petID)
    end)

    petNodes[nodeID] = button
    return button
end

local function RefreshOverlayFrameLevel(frame, orderIndex, isHovered)
    if not frame then
        return
    end

    local parent = frame:GetParent()
    local parentLevel = parent and parent:GetFrameLevel() or 1
    local baseLevel = parentLevel + 10 + ((orderIndex or 1) * 2)
    frame.baseFrameLevel = baseLevel

    if isHovered then
        frame:SetFrameLevel(baseLevel + 100)
    else
        frame:SetFrameLevel(baseLevel)
    end
end

local function RefreshRouteNodeButtonsForPet(petID, overlayFrame)
    local nodes = YBP.GetResolvedRouteNodes and YBP:GetResolvedRouteNodes(petID) or (ns.routeNodes and ns.routeNodes[petID])
    local petNodes = routeNodeFrames[petID]
    if petNodes then
        for _, button in pairs(petNodes) do
            button:Hide()
        end
    end

    if not nodes or not overlayFrame or not overlayFrame:IsShown() then
        return
    end

    local width = overlayFrame:GetWidth() or 0
    local height = overlayFrame:GetHeight() or 0
    if width <= 0 or height <= 0 then
        return
    end

    for index, node in ipairs(nodes) do
        local nodeID = node.id or tostring(index)
        local button = EnsureRouteNodeButton(petID, nodeID, overlayFrame:GetParent())
        local style = ns.routeNodeStyles and ns.routeNodeStyles.default or nil
        local size = (node.size or (style and style.size) or 18) * (node.nodeScale or 1.0)
        local color = node.color or (style and style.color) or { 0.31, 0.85, 1.00 }
        local x = width * (node.normalizedX or 0.5)
        local y = height * (node.normalizedY or 0.5)

        button.petID = petID
        button.nodeData = node
        button:SetSize(size + 2, size + 2)
        button:ClearAllPoints()
        button:SetPoint("CENTER", overlayFrame, "TOPLEFT", x, -y)
        button.texture:SetAtlas(ns.CLASSIC and "VignetteKillElite" or "VignetteKill")
        button.texture:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, 0.95)
        button:Show()
    end
end

local function ApplyRouteNodeHoverState(petID, isHovered, hasHoveredTarget)
    local petNodes = routeNodeFrames[petID]
    if not petNodes then
        return
    end

    for _, button in pairs(petNodes) do
        if button and button:IsShown() then
            if hasHoveredTarget then
                if isHovered then
                    button.emphasis:Show()
                    button.highlight:Show()
                    button.texture:SetAlpha(1.0)
                else
                    button.emphasis:Hide()
                    button.highlight:Hide()
                    button.texture:SetAlpha(0.95)
                end
            else
                button.emphasis:Hide()
                button.highlight:Hide()
                button.texture:SetAlpha(0.95)
            end
        end
    end
end

local function ApplyTextureThickness(frame, texturePath, alpha, thickness)
    if not frame or not frame.texture then
        return
    end

    local strength = thickness or 1.0
    if strength < 0.4 then
        strength = 0.4
    end

    local inset = 0
    local finalAlpha = alpha
    if strength < 1.0 then
        -- 位图本身不能真正无损“变细”，这里用轻微收缩 + 降低 alpha 做视觉减细。
        inset = (1.0 - strength) * 6
        finalAlpha = alpha * (0.65 + 0.35 * strength)
    end

    frame.texture:SetTexture(texturePath)
    frame.texture:ClearAllPoints()
    frame.texture:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
    frame.texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
    frame.texture:SetAlpha(finalAlpha)

    local layers = math.floor((strength - 1.0) * 8 + 0.5)
    if layers < 0 then
        layers = 0
    elseif layers > #frame.echoes then
        layers = #frame.echoes
    end

    for index, echo in ipairs(frame.echoes) do
        if index <= layers then
            local offset = thicknessOffsets[index + 1]
            echo:SetTexture(texturePath)
            echo:ClearAllPoints()
            echo:SetPoint("TOPLEFT", frame, "TOPLEFT", inset + offset[1], -(inset + offset[2]))
            echo:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(inset - offset[1]), inset - offset[2])
            echo:SetAlpha(alpha * 0.75)
            echo:Show()
        else
            echo:Hide()
        end
    end
end

local function ApplyOverlayEmphasis(frame, texturePath, active, thickness)
    if not frame or not frame.emphasis then
        return
    end
    if not active then
        frame.emphasis:Hide()
        return
    end

    frame.emphasis:SetTexture(texturePath)
    frame.emphasis:ClearAllPoints()
    frame.emphasis:SetAllPoints(frame)
    frame.emphasis:SetVertexColor(1.0, 1.0, 1.0, 0.40)
    frame.emphasis:SetAlpha(0.40)
    frame.emphasis:Show()
end

function YBP:UpdateOverlayHoverState()
    local selectedDebugPetID
    if self.IsDebugEnabled and self:IsDebugEnabled() and self.GetSelectedDebugPetID then
        selectedDebugPetID = self:GetSelectedDebugPetID()
    end

    for petID, frame in pairs(overlayFrames) do
        if frame and frame:IsShown() and frame.texturePath then
            local resolvedTransform = self:GetResolvedTransform(petID)
            local alpha = resolvedTransform.opacity or 1.0
            local thickness = frame.currentThickness or resolvedTransform.thickness or 1.0
            if not hoveredRoutePetID and selectedDebugPetID then
                if petID == selectedDebugPetID then
                    alpha = (resolvedTransform.opacity or 1.0)
                else
                    alpha = (resolvedTransform.opacity or 1.0) * 0.35
                end
            end
            if hoveredRoutePetID then
                if petID == hoveredRoutePetID then
                    alpha = math.max(resolvedTransform.opacity or 1.0, 0.98)
                    thickness = math.max(thickness + 0.30, thickness * 1.18)
                end
            end

            RefreshOverlayFrameLevel(frame, frame.orderIndex, petID == hoveredRoutePetID)
            ApplyTextureThickness(frame, frame.texturePath, alpha, thickness)
            ApplyOverlayEmphasis(frame, frame.texturePath, petID == hoveredRoutePetID, thickness)
            ApplyRouteNodeHoverState(petID, petID == hoveredRoutePetID, hoveredRoutePetID ~= nil)
        end
    end
end

local function HideAllOverlays()
    for _, frame in pairs(overlayFrames) do
        frame:Hide()
    end
    HideAllRouteNodes()
end

function YBP:GetVisiblePetIDsForMap(mapID)
    local petIDs = {}
    if not mapID or not ns.routeOverlays then
        return petIDs
    end

    for petID, overlay in pairs(ns.routeOverlays) do
        if overlay.mapID == mapID then
            petIDs[#petIDs + 1] = petID
        end
    end

    table.sort(petIDs)
    return petIDs
end

function YBP:GetResolvedTransform(petID)
    -- 调试模式：优先返回调试临时参数
    if self.IsDebugEnabled and self:IsDebugEnabled() then
        local debugDB = _G.YiboBeastPathsDebugDB
        if debugDB and debugDB.transforms and debugDB.transforms[petID] then
            local dt = debugDB.transforms[petID]
            return {
                offsetX = dt.offsetX ~= nil and dt.offsetX or defaultTransform.offsetX,
                offsetY = dt.offsetY ~= nil and dt.offsetY or defaultTransform.offsetY,
                scale = dt.scale ~= nil and dt.scale or defaultTransform.scale,
                scaleX = dt.scaleX ~= nil and dt.scaleX or defaultTransform.scaleX,
                scaleY = dt.scaleY ~= nil and dt.scaleY or defaultTransform.scaleY,
                thickness = dt.thickness ~= nil and dt.thickness or defaultTransform.thickness,
                opacity = dt.opacity ~= nil and dt.opacity or defaultTransform.opacity,
            }
        end
    end

    local stored = ns.routeTransforms and ns.routeTransforms[petID] or nil

    return {
        offsetX = stored and stored.offsetX or defaultTransform.offsetX,
        offsetY = stored and stored.offsetY or defaultTransform.offsetY,
        scale = stored and stored.scale or defaultTransform.scale,
        scaleX = stored and stored.scaleX or defaultTransform.scaleX,
        scaleY = stored and stored.scaleY or defaultTransform.scaleY,
        thickness = stored and stored.thickness or defaultTransform.thickness,
        opacity = stored and stored.opacity or defaultTransform.opacity,
    }
end

function YBP:GetResolvedRouteNodes(petID)
    local formalNodes = ns.routeNodes and ns.routeNodes[petID] or nil
    if not formalNodes then
        return nil
    end

    local debugDB = _G.YiboBeastPathsDebugDB
    local debugNodes = debugDB and debugDB.nodeTransforms and debugDB.nodeTransforms[petID] or nil
    local resolved = {}

    for index, node in ipairs(formalNodes) do
        local debugNode = debugNodes and node.id and debugNodes[node.id] or nil
        resolved[index] = {
            id = node.id,
            role = node.role,
            normalizedX = debugNode and debugNode.normalizedX or node.normalizedX,
            normalizedY = debugNode and debugNode.normalizedY or node.normalizedY,
            nodeScale = debugNode and debugNode.nodeScale or node.nodeScale or 1.0,
            size = debugNode and debugNode.size or node.size,
            color = debugNode and debugNode.color or node.color,
            isPlaceholder = node.isPlaceholder,
        }
        if debugNode and debugNode.isPlaceholder ~= nil then
            resolved[index].isPlaceholder = debugNode.isPlaceholder
        end
    end

    return resolved
end

function YBP:ApplyOverlayTransform(frame, mapBounds, transform)
    local parent = frame and frame:GetParent()
    if not parent then
        return
    end

    local parentWidth = parent:GetWidth() or 0
    local parentHeight = parent:GetHeight() or 0
    if parentWidth <= 0 or parentHeight <= 0 then
        frame:SetAllPoints(parent)
        return
    end

    local bounds = mapBounds or defaultMapBounds
    local finalTransform = transform or defaultTransform
    local baseWidth = parentWidth * (bounds.right - bounds.left)
    local baseHeight = parentHeight * (bounds.bottom - bounds.top)
    local finalScaleX = finalTransform.scale * finalTransform.scaleX
    local finalScaleY = finalTransform.scale * finalTransform.scaleY
    local finalWidth = baseWidth * finalScaleX
    local finalHeight = baseHeight * finalScaleY
    local centerX = parentWidth * bounds.left + (baseWidth * 0.5) + (parentWidth * finalTransform.offsetX)
    local centerY = parentHeight * bounds.top + (baseHeight * 0.5) + (parentHeight * finalTransform.offsetY)

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", parent, "TOPLEFT", centerX, -centerY)
    frame:SetWidth(finalWidth)
    frame:SetHeight(finalHeight)
end

function YBP:RefreshMapLayer()
    HideAllOverlays()

    if not self.db or not self.db.visible then
        return
    end

    local currentMapID = self:GetCurrentWorldMapID()
    if not currentMapID or not ns.routeOverlays then
        return
    end

    local petIDs = self:GetVisiblePetIDsForMap(currentMapID)
    if #petIDs == 0 then
        return
    end

    local parent = GetOverlayParent()
    if not parent then
        return
    end

    local mapBounds = ns.mapCanvasBounds and ns.mapCanvasBounds[currentMapID] or defaultMapBounds

    -- 调试模式：确定选中宠物 ID
    local selectedDebugPetID
    if self.IsDebugEnabled and self:IsDebugEnabled() and self.GetSelectedDebugPetID then
        selectedDebugPetID = self:GetSelectedDebugPetID()
    end

    for index, petID in ipairs(petIDs) do
        local overlay = ns.routeOverlays[petID]
        local frame = EnsureOverlayFrame(petID, parent)

        -- 调试模式：选中宠物全不透明，非选中降透明度
        local resolvedTransform = self:GetResolvedTransform(petID)
        local alpha = resolvedTransform.opacity or 1.0
        if selectedDebugPetID then
            if petID == selectedDebugPetID then
                alpha = (resolvedTransform.opacity or 1.0)
            else
                alpha = (resolvedTransform.opacity or 1.0) * 0.35
            end
        end

        local thickness = resolvedTransform.thickness or 1.0
        ApplyTextureThickness(frame, overlay.texture, alpha, thickness)
        frame.texturePath = overlay.texture
        frame.currentThickness = thickness
        frame.orderIndex = index

        self:ApplyOverlayTransform(frame, mapBounds, resolvedTransform)
        RefreshOverlayFrameLevel(frame, index, petID == hoveredRoutePetID)
        frame:Show()
        RefreshRouteNodeButtonsForPet(petID, frame)
    end

    self:UpdateOverlayHoverState()
end
