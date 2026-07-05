/***
 *   @addon         DanLib
 *   @component     UI Button
 *   @license       MIT License
 *   @version       2.1.1
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   The file provides a convenient interface for creating buttons in the project.
 *
 *   @functions
 *                  - Create a button with text, icon, and hover effects.
 *                  - Set background color and hover color for the button.
 *                  - Add icon functionality with customizable size and color.
 *                  - Paint the button with appropriate styles based on its state (hovered, disabled).
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */

 

local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DCustomUtils = DanLib.CustomUtils.Create

local _max = math.max
local _min = math.min
local _Color = Color
local _unpack = unpack
local _IsColor = IsColor
local _ColorToHSV = ColorToHSV
local _ColorAlpha = ColorAlpha
local _strformat = string.format

--- Creates a button in the specified parent panel.
-- @param parent: The parent panel in which the button will be created.
-- @param text: The text to be displayed on the button. Defaults to an empty string if not provided.
-- @param font: The font to be used for the button text. Defaults to 'danlib_font_20' if not provided.
-- @param textColor: The color of the button text. Defaults to the theme's text color if not provided.
function DBase:CreateButton(parent, text, font, textColor)
    local button = DCustomUtils(parent, 'DButton')
    button:SetText(text or '')
    button:SetTextColor(textColor or DBase:Theme('text'))
    button:SetFont(font or 'danlib_font_20')

    -- Initialize default properties for the button
    button.BackgroundColor = DBase:Theme('button')
    button.HoverColor = DBase:Theme('button_hovered')
    button.sIconSize = 24
    button.hover = 0

    --- Sets the background color of the button.
    -- @param color: The color to set as the background.
    -- @return Button: Returns the button instance for method chaining.
    function button:SetBackgroundColor(color)
        self.BackgroundColor = color
        return self
    end

    --- Sets the hover color of the button.
    -- @param color: The color to set when the button is hovered.
    -- @return Button: Returns the button instance for method chaining.
    function button:SetHoverColor(color)
        self.HoverColor = color
        return self
    end

    --- Sets the hover toggle state of the button.
    -- @param tum: Boolean indicating whether hover effects should be applied.
    -- @return Button: Returns the button instance for method chaining.
    function button:SetHoverTum(tum)
        self.HoverTum = tum
        return self
    end

    --- Sets the icon of the button.
    -- @param icon: The icon to be displayed on the button.
    -- @param size: The size of the icon.
    -- @param color: The color of the icon.
    -- @return Button: Returns the button instance for method chaining.
    function button:icon(icon, size, color)
        self.sIcon = icon
        self.sIconSize = size or self.sIconSize
        self.IconColor = color
        return self
    end

    --- Paint function for the button.
    -- This function is responsible for rendering the button's appearance.
    -- @param w: The width of the button.
    -- @param h: The height of the button.
    function button:Paint(w, h)
        local IconSize = DBase:Scale(self.sIconSize)

        -- Hover effect
        if self:IsHovered() then
            self.hover = _min(self.hover + 6, 200)
        else
            self.hover = _max(self.hover - 6, 0)
        end

        local hover = self.hover / 100
        local hoverColor = _ColorAlpha(self.HoverColor, hover * 250)

        -- Background
        DUtils:DrawRect(0, 0, w, h, self.BackgroundColor)

        if (not self:GetDisabled()) then
            if (not self.HoverTum) then
                DUtils:DrawRect(0, 0, w, h, hoverColor)
            end
        end

        if self.sIcon then
            local iconColor = self.IconColor or DBase:Theme('mat', 100 + hover * 250)
            local iconPosX = w * 0.5 - IconSize * 0.5
            local iconPosY = h * 0.5 - IconSize * 0.5
            DUtils:DrawIconOrMaterial(iconPosX, iconPosY, IconSize, self.sIcon, iconColor)
        end

        return self
    end

    return button
end


--- Creates a button in the specified parent panel with customizable options.
-- @param parent Panel: The parent panel in which the button will be created.
-- @param options table: A table containing various customizable options for the button.
-- @param options.text string: The text displayed on the button (default: '').
-- @param options.textColor Color: The color of the button text (default: Theme text color).
-- @param options.font string: The font used for the button text (default: 'danlib_font_18').
-- @param options.background table: A table containing background color and rounding options.
-- @param options.hover table: A table for hover color and animation properties.
-- @param options.dock table: A table for docking options (position and indent).
-- @param options.dock_indent table: A table for docking with specific margins.
-- @param options.pos table: A table containing x and y position for the button.
-- @param options.size table: A table containing width and height for the button.
-- @param options.wide number: The width of the button.
-- @param options.tall number: The height of the button.
-- @param options.click function: The function to call when the button is clicked.
-- @param options.rclick function: The function to call when the button is right-clicked.
-- @param options.tooltip table: A table containing tooltip text, color, icon, and position.
-- @param options.icon table: A table containing icon, color, and size.
-- @param options.paint function: A custom paint function for the button.
-- @param options.hoverClick table: A table for hover click effects (ripple effect).
-- @param options.think function: Custom Think function called every frame.
-- @param options.sound table: A table containing sound paths {hoverSound, clickSound}.
-- @return DButton: Returns the button instance for method chaining.
--
-- @note: The `think` function can be used to implement custom behavior that needs to be updated 
-- every frame (e.g., animations, state changes). To use it, provide a function in the options 
-- table under the `think` key. The function will receive the button instance as its first argument.
--
-- @example:
-- DBase.CreateUIButton(parent, {
--     text = { 'Click Me', 'danlib_font_18', nil, nil, Color(255, 255, 255) },
--     background = { Color(50, 50, 50), 6 },
--     hover = { Color(255, 255, 255, 30), 8, 6 },
--     sound = { 'buttons/button15.wav', 'buttons/button14.wav' },
--     click = function() print('Clicked!') end
-- })
function DBase.CreateUIButton(parent, options)
    options = options or { }
    local button = DCustomUtils(parent, 'DButton')
    button:SetText('')
    button:ApplyClearPaint()

    -- Helper to check if key exists in options table
    local function hasKey(key)
        return options[key] ~= nil
    end

    -- Helper function to normalize options (supports both nil and {nil} formats)
    local function normalizeOption(opt)
        return type(opt) == 'table' and opt or { opt }
    end

    -- Helper to wrap event with disabled check
    local function wrapDisabledCheck(eventName)
        local original = button[eventName]
        button[eventName] = function(sl, ...)
            if (not sl:GetDisabled() and original) then
                return original(sl, ...)
            end
        end
    end

    -- Auto cursor management based on enabled state
    local originalSetEnabled = button.SetEnabled
    button.SetEnabled = function(sl, enabled)
        originalSetEnabled(sl, enabled)
        sl:SetCursor(enabled and 'hand' or 'no')
        return sl
    end
    button:SetCursor('hand')

    -- ApplyBackground stores color in sl.BackgroundColor and reads it every
    -- frame, so updating that field at runtime is all that is needed.
    if hasKey('background') then
        local bg = normalizeOption(options.background)
        local bgColor = bg[1] and (_IsColor(bg[1]) and bg[1] or DBase:Theme('button')) or _Color(0, 0, 0, 0)
        button:ApplyBackground(bgColor, bg[2] or 6, bg[3])
    else
        button:ApplyBackground(DBase:Theme('button'), 6, nil)
    end

    -- Setter: update background color at runtime without re-registering paint.
    button.SetBackgroundColor = function(sl, color, radius)
        sl.BackgroundColor = color
        if radius then
            sl.BackgroundRadius = radius
        end
        return sl
    end

    -- ApplyFadeHover stores color in sl.HoverColor and reads it every frame.
    local function setupHoverThink()
        local originalThink = button.Think
        button.Think = function(sl)
            if originalThink then
                originalThink(sl)
            end

            if sl:GetDisabled() then
                sl.HoverFade = 0
            end
        end
    end

    if hasKey('hover') then
        local hover = normalizeOption(options.hover)
        local hoverColor = hover[1] and (_IsColor(hover[1]) and hover[1] or DBase:Theme('button_hovered')) or _Color(0, 0, 0, 0)
        if (hoverColor.a > 0) then
            button:ApplyFadeHover(hoverColor, hover[2], hover[3] or 6)
            setupHoverThink()
        end
    else
        button:ApplyFadeHover(DBase:Theme('button_hovered'), nil, 6)
        setupHoverThink()
    end

    -- Setter: update hover color at runtime.
    button.SetHoverColor = function(sl, color)
        sl.HoverColor = color
        return sl
    end

    -- All text properties are stored in panel fields (_label, _labelFont, …)
    -- and drawn every frame from those fields — so SetText / SetTextColor /
    -- SetFont all take effect immediately without stacking new paint handlers.
    if hasKey('text') then
        local text = normalizeOption(options.text)
        button._label = text[1] or ''
        button._labelFont = text[2] or 'danlib_font_18'
        button._labelXOff = text[3] or 0
        button._labelYOff = text[4] or 0
        button._labelColor = _IsColor(text[5]) and text[5] or DBase:Theme('text')
        button._labelXA = text[6] or TEXT_ALIGN_CENTER
        button._labelYA = text[7] or TEXT_ALIGN_CENTER
    end

    button.SetText = function(sl, val)
        sl._label = val or ''
        return sl
    end

    button.SetTextColor = function(sl, color)
        sl._labelColor = color
        return sl
    end

    button.SetFont = function(sl, font)
        sl._labelFont = font
        return sl
    end

    -- Icon properties stored in panel fields so SetIcon() updates them at runtime.
    if hasKey('icon') then
        local icon = normalizeOption(options.icon)
        button._iconMat = icon[1] or ''
        button._iconColor = _IsColor(icon[2]) and icon[2] or nil
        button._iconSize = icon[3] or 18
    end

    button.SetIcon = function(sl, mat, color, size)
        sl._iconMat = mat
        sl._iconColor = color
        sl._iconSize = size or 18
        return sl
    end

    --  Docking / position / size
    if hasKey('dock') then
        local dock = normalizeOption(options.dock)
        if dock[1] then
            button:Pin(dock[1], dock[2] or 0)
        end
    end

    if hasKey('dock_indent') then
        local di = normalizeOption(options.dock_indent)
        button:Dock(di[1] or FILL)
        button:DockMargin(di[2] or 0, di[3] or 0, di[4] or 0, di[5] or 0)
    end

    if hasKey('pos') then
        button:SetPos(_unpack(options.pos))
    end

    if hasKey('size') then
        button:SetSize(_unpack(options.size))
    end

    if hasKey('wide') then
        button:SetWide(options.wide)
    end

    if hasKey('tall') then
        button:SetTall(options.tall)
    end

    -- Sound
    if hasKey('sound') then
        local sound = normalizeOption(options.sound)
        if (sound[1] or sound[2]) then
            button:ApplySound(sound[1], sound[2])
            if sound[1] then
                wrapDisabledCheck('OnCursorEntered')
            end

            if sound[2] then
                wrapDisabledCheck('OnMouseReleased')
            end
        end
    end

    -- Click handlers
    if hasKey('click') then
        button:ApplyEvent('DoClick', options.click or function() end)
    end

    if hasKey('rclick') then
        button:ApplyEvent('DoRightClick', options.rclick or function() end)
    end

    -- Tooltip
    if hasKey('tooltip') then
        local tooltip = normalizeOption(options.tooltip)
        local tooltipColor = tooltip[2] and _IsColor(tooltip[2]) and tooltip[2] or nil
        button:ApplyTooltip(tooltip[1], tooltipColor, tooltip[3], tooltip[4])
    end

    button.SetTooltipText = function(sl, text, color, icon, pos)
        sl:ApplyTooltip(text, color, icon, pos)
        return sl
    end

    -- Think
    if hasKey('think') then
        button:ApplyEvent('Think', options.think)
    end

    -- Paint (custom override)
    if hasKey('paint') then
        button:ApplyEvent(nil, function(sl, w, h)
            options.paint(sl, w, h)
        end)
    end

    -- Paint: icon + label (both read from panel fields every frame)
    button:ApplyEvent(nil, function(sl, w, h)
        if (sl._iconMat and sl._iconMat ~= '') then
            local iconSize = DBase:Scale(sl._iconSize  or 18)
            local iconColor = sl._iconColor or DBase:Theme('mat', 150)
            DUtils:DrawIconOrMaterial((w - iconSize) * 0.5, (h - iconSize) * 0.5, iconSize, sl._iconMat, iconColor)
        end

        if (sl._label and sl._label ~= '') then
            draw.SimpleText(sl._label, sl._labelFont or 'danlib_font_18', w * 0.5 + (sl._labelXOff or 0), h * 0.5 + (sl._labelYOff or 0), sl._labelColor or DBase:Theme('text'), sl._labelXA or TEXT_ALIGN_CENTER, sl._labelYA or TEXT_ALIGN_CENTER)
        end
    end)

    -- Hover click effects
    if hasKey('hoverClick') then
        local hoverClick = normalizeOption(options.hoverClick)
        local hoverClickColor = hoverClick[1] and (_IsColor(hoverClick[1]) and hoverClick[1] or nil) or _Color(0, 0, 0, 0)
        if (hoverClickColor and hoverClickColor.a > 0) then
            button:ApplyCircleEffect(hoverClickColor, hoverClick[2], hoverClick[3])
            wrapDisabledCheck('OnMousePressed')
        end
    end

    return button
end




-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dcolorpalette.lua

local BUTTON, Constructor = DanLib.UiPanel()
local matGrid = DanLib.Config.Materials['alpha_grid']

AccessorFunc(BUTTON, 'm_bBorder', 'DrawBorder', FORCE_BOOL)
AccessorFunc(BUTTON, 'm_bSelected', 'Selected', FORCE_BOOL)
AccessorFunc(BUTTON, 'm_Color', 'Color')
AccessorFunc(BUTTON, 'm_PanelID', 'ID')
AccessorFunc(BUTTON, 'm_formatRGB', 'FormatRGB')

function BUTTON:Init()
    self:SetSize(10, 10)
    self:SetMouseInputEnabled(true)
    self:SetText('')
    self:SetCursor('hand')
    self:SetZPos(0)
    self:SetColor(Color(255, 0, 255))
    self:SetFormatRGB('RGB')
end

function BUTTON:IsDown()
    return self.Depressed
end

function BUTTON:SetColor(color, hideTooltip)
    if (not hideTooltip) then
        local formatType = self:GetFormatRGB() -- Get the current colour format
        local colorStr

        -- Format the string for the tooltip depending on the type
        if (formatType == 'RGB') then
            colorStr = _strformat('R: %d\nG: %d\nB: %d\nA: %d', color.r, color.g, color.b, color.a)
        elseif (formatType == 'HEX') then
            colorStr = _strformat('HEX: #%02X%02X%02X', color.r, color.g, color.b)
        elseif (formatType == 'CMYK') then
            local c, m, y, k = DUtils:RGBtoCMYK(color.r, color.g, color.b)
            colorStr = _strformat('C: %d\nM: %d\nY: %d\nK: %d', c, m, y, k)
        elseif (formatType == 'HSV') then
            local h, s, v = _ColorToHSV(color)
            colorStr = _strformat('H: %d\nS: %d\nV: %d\nA: %d', h, s, v, color.a)
        elseif (formatType == 'HSL') then
            local h, s, l = DUtils:RGBtoHSL(color.r, color.g, color.b)
            colorStr = _strformat('H: %d\nS: %d\nL: %d\nA: %d', h, s, l, color.a)
        end

        -- Output a tooltip with a formatted string
        if colorStr then
            self:ApplyTooltip(colorStr, nil, nil, TOP)
        end
    end
    self.m_Color = color
end

function BUTTON:Paint(w, h)
    if (self:GetColor().a < 255) then -- Grid for Alpha
        local size = _max(128, _max(w, h))
        local x, y = w / 2 - size / 2, h / 2 - size / 2
        DUtils:DrawMaterial(x, y, size, size, color_white, matGrid)
    end
    
    local panelColor = self:GetColor()
    DUtils:DrawRoundedBox(0, 0, w, h, _Color(panelColor.r, panelColor.g, panelColor.b, panelColor.a))
    return false
end

BUTTON:SetBase('DLabel')
BUTTON:Register('DanLib.UI.ColorButton')
