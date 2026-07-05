/***
 *   @addon         DanLib
 *   @component     EntityTooltip
 *   @license       MIT License
 *   @version       2.0.1
 *   @release_date  28/11/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *   
 *   @description   High-performance hint system for Entity with support for:
 *                  - Smooth appearance/disappearance over distance
 *                  - Highlighting an Entity on hover
 *                  - Callback events (OnHoverStart, OnHoverEnd, onUpdate)
 *                  - Caching markup and optimizing rendering
 *                  - Object pooling to minimize GC
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DHook = DanLib.Hook
local DUtils = DanLib.Utils
local DTable = DanLib.Table

DanLib.UI = DanLib.UI or { }
DanLib.UI.Tooltips = DanLib.UI.Tooltips or { }
local DTooltips = DanLib.UI.Tooltips

-- Function cache
local _IsValid = IsValid
local _pairs = pairs
local _ipairs = ipairs
local _CurTime = CurTime
local _Vector = Vector
local _ScrW, _ScrH = ScrW, ScrH
local _Lerp = Lerp
local _Color = Color
local _ColorAlpha = ColorAlpha
local _FrameTime = FrameTime
local _min = math.min
local _Clamp = math.Clamp
local _floor = math.floor
local _format = string.format
local _tableEmpty = table.Empty
local _tableinsert = table.insert
local _tablesort = table.sort
local _ErrorNoHalt = ErrorNoHalt

-- Pool for Color objects (avoid creating new objects every frame)
local colorPool = { }
local colorPoolIndex = 0
local MAX_COLOR_POOL = 20

--- Get a Color object from the pool to minimize GC
-- @param r (number): Red channel 0-255
-- @param g (number): Green channel 0-255
-- @param b (number): Blue channel 0-255
-- @param a (number): Alpha channel 0-255
-- @return (Color): A reused Color object from the pool
local function _getPooledColor(r, g, b, a)
    colorPoolIndex = colorPoolIndex + 1
    if (colorPoolIndex > MAX_COLOR_POOL) then
        colorPoolIndex = 1
    end
    
    if (not colorPool[colorPoolIndex]) then
        colorPool[colorPoolIndex] = _Color(r, g, b, a)
    else
        local col = colorPool[colorPoolIndex]
        col.r, col.g, col.b, col.a = r, g, b, a
    end
    
    return colorPool[colorPoolIndex]
end

-- CONFIGURATION
local CONFIG = {
    defaultDistance = 150, -- Default tooltip visibility distance
    defaultFadeTime = 0.25, -- Tooltip appearance time in seconds
    maxTooltips = 5, -- Maximum number of simultaneous tooltips
    updateRate = 0.02, -- Refresh rate (50 FPS)
    fadeStartPercent = 0.7, -- At what% of the distance does fade start (0.7 = 70%)
    defaultHighlight = false, -- The Entity backlight is off by default.
    highlightColor = _Color(100, 150, 255, 180), -- Default backlight color
}

-- RENDERING CONSTANTS
local RENDER_CONSTANTS = {
    -- Icon
    ICON_SIZE = 22,
    ICON_PADDING = 32,
    
    -- Padding
    PADDING_X = 10,
    PADDING_Y = 8,
    
    -- The backlight
    HIGHLIGHT_ALPHA_MULTIPLIER = 0.5, -- The backlight is 2 times weaker than the tooltip
    HIGHLIGHT_GLOW_MIN = 2,
    HIGHLIGHT_GLOW_MAX = 5,
    HIGHLIGHT_GLOW_RANGE = 3,
    HIGHLIGHT_PASSES = 2,
    
    -- Text
    TEXT_DESCRIPTION_COLOR = Color(200, 200, 200),
    
    -- Screen borders
    SCREEN_MARGIN = 10,
    
    -- Minimum visible alpha
    MIN_VISIBLE_ALPHA = 1,
    MIN_HIGHLIGHT_ALPHA = 2,
}

-- GLOBAL VARIABLES
local tooltipRegistry = { } -- The registry of all registered tooltips

-- LOCAL VARIABLES
local activeTooltips = { } -- Active tooltips in the current frame
local lastUpdate = 0 -- Last update time
local lastLookingEntity = nil -- The entity that the player is looking at

-- Cache of screen sizes
local scrW, scrH = _ScrW(), _ScrH()
local lastScreenSizeCheck = 0

--- Screen size update (performed once per second)
local function _updateScreenSize()
    if (_CurTime() - lastScreenSizeCheck > 1) then
        scrW, scrH = _ScrW(), _ScrH()
        lastScreenSizeCheck = _CurTime()
    end
end

-- THE ENTITY META-TABLE
local DMetaEntity = DanLib.MetaEntity

--- Install tooltip for Entity
-- @param data (table): Table with tooltip parameters
--   - title (string): Tooltip header
--   - text (string|nil): Tooltip description (optional)
--   - icon (string|nil): The path to the Material icon (optional)
--   - color (Color|nil): Title color (default from theme)
--   - distance (number|nil): Visibility distance in units (default 150)
--   - fadeTime (number|nil): Time of appearance in seconds (default is 0.25)
--   - offset (Vector|nil): Offset of the tooltip position from the center of the Entity
--   - condition (function|nil): Visibility check function (ent, ply) -> bool
--   - OnRender (function|nil): Callback during rendering (ent, data, alpha) -> data
--   - highlight (boolean|nil): Turn on the Entity backlight (false by default)
--   - highlightColor (Color|nil): Backlight color (default is blue)
--   - OnHoverStart (function|nil): Callback at the beginning of pointing (ent, ply)
--   - OnHoverEnd (function|nil): Callback at the end of the hover (ent, ply)
--   - OnUpdate (function|nil): Callback every frame on hover (ent, ply, dist, alpha)
--   - maxWidth (number|nil): Maximum width of the text to wrap
--   - hideDistance (number|nil): Full concealment distance (if different from distance)
-- @usage entity:SetEntityTooltip({ title = 'Door', text = 'Press E to open' })
-- @usage entity:SetEntityTooltip({ 
--     title = 'Important', 
--     highlight = true,
--     highlightColor = Color(255, 0, 0, 150),
--     OnHoverStart = function(ent, ply) print('Looking!') end
-- })
function DMetaEntity:SetEntityTooltip(data)
    if (not _IsValid(self)) then
        return
    end
    
    if (not data) then
        _ErrorNoHalt('[DanLib.Tooltips] SetEntityTooltip: data is nil\n')
        return
    end
    
    if (not data.title) then
        _ErrorNoHalt('[DanLib.Tooltips] SetEntityTooltip: title is required\n')
        return
    end
    
    -- Validation of numerical parameters
    local fadeTime = data.fadeTime or CONFIG.defaultFadeTime
    local distance = data.distance or CONFIG.defaultDistance
    
    if (fadeTime <= 0) then
        _ErrorNoHalt('[DanLib.Tooltips] SetEntityTooltip: fadeTime must be > 0, using default\n')
        fadeTime = CONFIG.defaultFadeTime
    end
    
    if (distance <= 0) then
        _ErrorNoHalt('[DanLib.Tooltips] SetEntityTooltip: distance must be > 0, using default\n')
        distance = CONFIG.defaultDistance
    end
    
    local fadeStart = distance * CONFIG.fadeStartPercent
    
    tooltipRegistry[self] = {
        title = data.title,
        text = data.text,
        icon = data.icon,
        color = data.color or DBase:Theme('title'),
        distance = distance,
        fadeTime = fadeTime,
        offset = data.offset or _Vector(0, 0, 0),
        condition = data.condition,
        OnRender = data.OnRender,
        highlight = data.highlight or false,
        highlightColor = data.highlightColor or CONFIG.highlightColor,
        OnHoverStart = data.OnHoverStart,
        OnHoverEnd = data.OnHoverEnd,
        OnUpdate = data.OnUpdate,
        maxWidth = data.maxWidth,
        hideDistance = data.hideDistance,
        
        -- Pre-calculated values
        _fadeInSpeed = 1 / fadeTime,
        _fadeOutSpeed = 1 / (fadeTime * 0.4),
        _fadeStart = fadeStart,
        _fadeEnd = distance,
        _fadeRange = distance - fadeStart,
        
        _alpha = 0,
        _targetAlpha = 0,
        _isLookingAt = false,
        _wasLookingAt = false,
        _lastMarkup = nil,
        _lastMarkupText = nil,
    }
end

--- Remove tooltip from Entity
-- @usage entity:RemoveEntityTooltip()
function DMetaEntity:RemoveEntityTooltip()
    tooltipRegistry[self] = nil
end

--- Get tooltip Entity data
-- @return (table|nil): A table with tooltip or nil data if not installed
-- @usage local data = entity:GetEntityTooltipData()
function DMetaEntity:GetEntityTooltipData()
    return tooltipRegistry[self]
end

--- Update tooltip data without completely recreating it
-- @param data (table): The table with the parameters for updating (see SetEntityTooltip)
-- @usage entity:UpdateEntityTooltip({ title = 'New Title' })
-- @usage entity:UpdateEntityTooltip({ distance = 200, highlight = true })
function DMetaEntity:UpdateEntityTooltip(data)
    if (not _IsValid(self)) then
        return
    end
    
    local existing = tooltipRegistry[self]
    if (not existing) then
        _ErrorNoHalt('[DanLib.Tooltips] UpdateEntityTooltip: Tooltip not found for this entity\n')
        return
    end
    
    if (not data) then
        _ErrorNoHalt('[DanLib.Tooltips] UpdateEntityTooltip: data is nil\n')
        return
    end
    
    -- Updating only public fields
    for k, v in _pairs(data) do
        if (k:sub(1, 1) ~= '_') then
            existing[k] = v
        end
    end
    
    -- Recalculating the pre-calculated values if the key parameters have changed
    if data.fadeTime or data.distance then
        local fadeTime = existing.fadeTime
        local distance = existing.distance
        
        -- Validation
        if (fadeTime <= 0) then
            fadeTime = CONFIG.defaultFadeTime
        end

        if (distance <= 0) then
            distance = CONFIG.defaultDistance
        end
        
        local fadeStart = distance * CONFIG.fadeStartPercent
        existing._fadeInSpeed = 1 / fadeTime
        existing._fadeOutSpeed = 1 / (fadeTime * 0.4)
        existing._fadeStart = fadeStart
        existing._fadeEnd = distance
        existing._fadeRange = distance - fadeStart
    end
    
    -- Disabling the markup cache if the text has changed
    if (data.title or data.text) then
        existing._lastMarkup = nil
        existing._lastMarkupText = nil
    end
end

--- Check if the tooltip is installed on the Entity
-- @return (boolean): true if tooltip is installed
-- @usage if entity:HasEntityTooltip() then ... end
function DMetaEntity:HasEntityTooltip()
    return tooltipRegistry[self] ~= nil
end

--- [OUTDATED] Install tooltip (old API, to be removed in the future)
-- @param title (string): Header
-- @param bool (boolean): Whether to show the description
-- @param text (string): Description text
-- @param icon (string): The path to the icon
-- @param color (Color): Header color
-- @deprecated Use SetEntityTooltip instead
function DMetaEntity:SetCreateEntityToolTip(title, bool, text, icon, color)
    if (not _IsValid(self)) then
        return
    end

    self:SetEntityTooltip({
        title = title or 'No title',
        text = bool and text or nil,
        icon = icon,
        color = color or DBase:Theme('title'),
    })
end

--- Trigger OnHoverEnd callback and reset state
-- @param ent (Entity): The entity
-- @param data (table): Tooltip data
-- @param pPlayer (Player): The player
local function _triggerOnHoverEnd(ent, data, pPlayer)
    if (data._wasLookingAt and data.OnHoverEnd) then
        data.OnHoverEnd(ent, pPlayer)
    end
    data._wasLookingAt = false
end

-- Pool for reuse of candidates tables
local candidatesPool = { }
local pooledCandidates = 0

--- Updating the active tooltip (internal function)
-- Checks all registered Entities and determines which tooltips to show
-- Runs with the frequency CONFIG.updateRate
local function _updateActiveTooltips()
    local now = _CurTime()
    if (now - lastUpdate < CONFIG.updateRate) then
        return
    end
    lastUpdate = now
    
    local pPlayer = LocalPlayer()
    if (not _IsValid(pPlayer)) then
        return
    end
    
    local trace = pPlayer:GetEyeTrace()
    local eyePos = pPlayer:EyePos()
    
    _tableEmpty(activeTooltips)
    pooledCandidates = 0
    
    local currentLookingEntity = nil
    local tracedEntity = trace.Entity
    
    for ent, data in _pairs(tooltipRegistry) do
        if _IsValid(ent) then
            local isLookingAt = (tracedEntity == ent)
            -- Early exit if we don't look and it's already invisible
            local shouldSkip = not isLookingAt and data._targetAlpha == 0 and data._alpha < RENDER_CONSTANTS.MIN_VISIBLE_ALPHA
            if (not shouldSkip) then
                local entCenter = ent:LocalToWorld(ent:OBBCenter())
                local entPos = entCenter + data.offset
                local dist = eyePos:Distance(entPos)
                local maxDist = data.hideDistance or data.distance
                
                if (dist <= maxDist) then
                    if (not data.condition or data.condition(ent, pPlayer)) then
                        -- Optimized fade calculation
                        local distanceFade = 1.0
                        if (dist > data._fadeStart) then
                            distanceFade = 1 - _Clamp((dist - data._fadeStart) / data._fadeRange, 0, 1)
                        end
                        
                        if isLookingAt then
                            data._targetAlpha = 255 * distanceFade
                            data._isLookingAt = true
                            currentLookingEntity = ent
                            
                            if data.OnUpdate then
                                data.OnUpdate(ent, pPlayer, dist, data._alpha)
                            end
                            
                            if (not data._wasLookingAt and data.OnHoverStart) then
                                data.OnHoverStart(ent, pPlayer)
                            end
                            
                            data._wasLookingAt = true
                        else
                            data._targetAlpha = 0
                            data._isLookingAt = false
                            _triggerOnHoverEnd(ent, data, pPlayer)
                        end
                        
                        -- Reusing existing tables
                        pooledCandidates = pooledCandidates + 1
                        if (not candidatesPool[pooledCandidates]) then
                            candidatesPool[pooledCandidates] = { }
                        end
                        
                        local candidate = candidatesPool[pooledCandidates]
                        candidate.ent = ent
                        candidate.data = data
                        candidate.dist = dist
                        candidate.pos = entPos
                    end
                else
                    data._targetAlpha = 0
                    data._isLookingAt = false
                    _triggerOnHoverEnd(ent, data, pPlayer)
                end
            end
        else
            tooltipRegistry[ent] = nil
        end
    end
    
    -- We only sort the elements used by distance.
    if (pooledCandidates > 0) then
        _tablesort(candidatesPool, function(a, b)
            if (not a.dist) then
                return false
            end

            if (not b.dist) then
                return true
            end
            return a.dist < b.dist
        end)
        
        for i = 1, _min(pooledCandidates, CONFIG.maxTooltips) do
            _tableinsert(activeTooltips, candidatesPool[i])
        end
    end
    
    lastLookingEntity = currentLookingEntity
end

--- Rendering a single tooltip (internal function)
-- @param candidate (table): Candidate data table {ent, data, dist, pos}
local function _renderTooltip(candidate)
    local ent = candidate.ent
    local data = candidate.data
    local pos = candidate.pos
    
    -- Smooth alpha interpolation
    local ft = _FrameTime()
    if (data._alpha < data._targetAlpha) then
        data._alpha = _Lerp(ft * data._fadeInSpeed, data._alpha, data._targetAlpha)
    else
        data._alpha = _Lerp(ft * data._fadeOutSpeed, data._alpha, data._targetAlpha)
    end
    
    local alpha = _floor(data._alpha)
    if (alpha <= RENDER_CONSTANTS.MIN_VISIBLE_ALPHA) then
        return
    end
    
    local renderData = data
    if data.OnRender then
        renderData = data.OnRender(ent, DTable:Copy(data), alpha) or data
    end
    
    local scrPos = pos:ToScreen()
    if (not scrPos.visible) then
        return
    end
    
    -- Creating a text with markup tags
    local titleColor = _format('%d,%d,%d,%d', renderData.color.r, renderData.color.g, renderData.color.b, alpha)
    local descColor = RENDER_CONSTANTS.TEXT_DESCRIPTION_COLOR
    local textColor = _format('%d,%d,%d,%d', descColor.r, descColor.g, descColor.b, alpha)
    local fullText = _format('{color:%s}%s{/color:}', titleColor, renderData.title)
    
    if (renderData.text and renderData.text ~= '') then
        fullText = fullText .. _format('\n{color:%s}%s{/color:}', textColor, renderData.text)
    end
    
    -- Caching markup
    local markup
    if (data._lastMarkupText == fullText and data._lastMarkup) then
        markup = data._lastMarkup
    else
        markup = DUtils:CreateMarkup(fullText, 'danlib_font_18', color_white, renderData.maxWidth)
        data._lastMarkup = markup
        data._lastMarkupText = fullText
    end
    
    local textW, textH = markup:Size()
    
    -- We use constants
    local iconSize = renderData.icon and RENDER_CONSTANTS.ICON_SIZE or 0
    local iconPadding = iconSize > 0 and RENDER_CONSTANTS.ICON_PADDING or 0
    
    local panelW = textW + iconPadding + RENDER_CONSTANTS.PADDING_X * 2
    local panelH = textH + RENDER_CONSTANTS.PADDING_Y * 2
    
    -- Position using the constant SCREEN_MARGIN
    local margin = RENDER_CONSTANTS.SCREEN_MARGIN
    local x = _Clamp(scrPos.x - panelW * 0.5, margin, scrW - panelW - margin)
    local y = _Clamp(scrPos.y - panelH * 0.5, margin, scrH - panelH - margin)
    
    -- Tooltip background
    DUtils:DrawRoundedBox(x, y, panelW, panelH, DBase:Theme('primary_notifi', alpha))
    
    -- Icon
    local textStartX = x + RENDER_CONSTANTS.PADDING_X
    if (iconSize > 0) then
        local iconY = y + (panelH * 0.5) - (iconSize * 0.5)
        DUtils:DrawIconOrMaterial(x + RENDER_CONSTANTS.PADDING_X, iconY, iconSize, renderData.icon, _ColorAlpha(renderData.color, alpha))
        textStartX = x + iconPadding + RENDER_CONSTANTS.PADDING_X
    end
    
    -- Text
    local textY = y + (panelH * 0.5) - (textH * 0.5)
    markup:Draw(textStartX, textY, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, alpha)
end

--- Rendering the Entity backlight (internal function)
-- Uses halo.Add to create a glow around the Entity
local function _renderEntityHighlight()
    for _, candidate in _ipairs(activeTooltips) do
        local ent = candidate.ent
        local data = candidate.data
        
        if data.highlight then
            local alpha = _floor(data._alpha * RENDER_CONSTANTS.HIGHLIGHT_ALPHA_MULTIPLIER)
            if (alpha > RENDER_CONSTANTS.MIN_HIGHLIGHT_ALPHA) then
                local hCol = data.highlightColor
                -- Dynamic size using constants
                local glowSize = _Clamp(RENDER_CONSTANTS.HIGHLIGHT_GLOW_MIN + (alpha / 255) * RENDER_CONSTANTS.HIGHLIGHT_GLOW_RANGE, RENDER_CONSTANTS.HIGHLIGHT_GLOW_MIN, RENDER_CONSTANTS.HIGHLIGHT_GLOW_MAX)
                halo.Add({ ent }, _getPooledColor(hCol.r, hCol.g, hCol.b, alpha), glowSize, glowSize, RENDER_CONSTANTS.HIGHLIGHT_PASSES, true, true)
            end
        end
    end
end

--- The main HUDPaint hook (internal function)
local function _HUDPaintTooltips()
    _updateScreenSize()
    _updateActiveTooltips()
    _renderEntityHighlight()
    
    for _, candidate in _ipairs(activeTooltips) do
        _renderTooltip(candidate)
    end
end
DHook:Add('HUDPaint', 'DanLib.EntityTooltips', _HUDPaintTooltips)

--- Cleaning up when deleting an Entity
-- @param ent (Entity): Deleted Entity
local function OnEntityRemoved(ent)
    tooltipRegistry[ent] = nil
end
DHook:Add('EntityRemoved', 'DanLib.TooltipCleanup', OnEntityRemoved)

-- PUBLIC API

--- Register a tooltip for an Entity
-- @param ent (Entity): The entity for which the tooltip is installed
-- @param data (table): Tooltip parameters (see DMetaEntity:SetEntityTooltip)
-- @usage DanLib.UI.Tooltips:Register(entity, { title = 'Door' })
function DTooltips:Register(ent, data)
    if _IsValid(ent) then
        ent:SetEntityTooltip(data)
    end
end

--- Remove tooltip from Entity
-- @param ent (Entity): The entity that the tooltip is being deleted from
-- @usage DanLib.UI.Tooltips:Remove(entity)
function DTooltips:Remove(ent)
    if _IsValid(ent) then
        ent:RemoveEntityTooltip()
    end
end

--- Get a list of active tooltips in the current frame
-- @return (table): Array of active tooltips
-- @usage local active = DanLib.UI.Tooltips:GetActive()
function DTooltips:GetActive()
    return activeTooltips
end

--- Get the entire registry of registered tooltips
-- @return (table): Table { Entity = data }
-- @usage local all = DanLib.UI.Tooltips:GetAll()
function DTooltips:GetAll() return
    tooltipRegistry
end

--- Clear all registered tooltips
-- @usage DanLib.UI.Tooltips:ClearAll()
function DTooltips:ClearAll()
    tooltipRegistry = { }
end

--- Get the Entity that the player is looking at
-- @return (Entity|nil): The entity with the tooltip that the player is looking at or nil
-- @usage local ent = DanLib.UI.Tooltips:GetLookingEntity()
function DTooltips:GetLookingEntity()
    return lastLookingEntity
end

--- Install tooltip en masse for all Entities of the specified class
-- @param className (string): Name of the Entity class
-- @param data (table): Tooltip parameters (see DMetaEntity:SetEntityTooltip)
-- @usage DanLib.UI.Tooltips:RegisterClass('prop_physics', { title = 'Prop' })
function DTooltips:RegisterClass(className, data)
    for _, ent in _ipairs(ents.FindByClass(className)) do
        if _IsValid(ent) then
            ent:SetEntityTooltip(data)
        end
    end
end

--- Change the global configuration parameter
-- @param key (string): The parameter key (see CONFIG)
-- @param value (any): New parameter value
-- @usage DanLib.UI.Tooltips:SetConfig('defaultDistance', 200)
-- @usage DanLib.UI.Tooltips:SetConfig('maxTooltips', 10)
function DTooltips:SetConfig(key, value)
    if (CONFIG[key] ~= nil) then
        CONFIG[key] = value
    end
end
