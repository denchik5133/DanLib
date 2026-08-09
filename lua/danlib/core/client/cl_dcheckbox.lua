/***
 *   @addon         DanLib
 *   @component     UI Checkbox
 *   @version       2.0.5
 *   @release_date  01/23/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Advanced checkbox component for DanLib with dynamic state-based text,
 *                  disabled state support, and optimized rendering. Features include
 *                  LEFT/RIGHT text positioning, state-specific colors, hover animations,
 *                  and full backward compatibility with DanLib 3.0.0.
 *
 *   @functions     
 *                  - Dynamic text system (ON/OFF, Active/Inactive, custom states)
 *                  - Disabled state with 40% alpha dimming and cursor feedback
 *                  - LEFT/RIGHT text positioning with fixed checkbox alignment
 *                  - Independent text colors for enabled/disabled states
 *                  - Smooth hover animations and color transitions
 *                  - Shadow, sound, and tooltip support
 *                  - Cached rendering with PerformLayout() auto-update
 *                  - Dual API: CreateCheckbox() (legacy) + CreateUICheckbox() (modern)
 *
 *   @api           DBase.CreateCheckbox(parent) - Legacy API with manual configuration
 *                  DBase.CreateUICheckbox(parent, options) - Modern declarative API
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DMaterial = DanLib.Config.Materials
local DCustomUtils = DanLib.CustomUtils.Create

local math = math
local _clamp = math.Clamp
local _max = math.max
local _type = type
local _IsColor = IsColor
local _ColorAlpha = ColorAlpha
local _TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local _TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local _drawSimpleText = draw.SimpleText

--- Normalizes the option to the table
-- @param opt (any): Option for normalization
-- @return (table): The table with the option
local function _normalizeOption(opt)
    return _type(opt) == 'table' and opt or { opt }
end

-- ============================================
-- CHECKBOX COMPONENT (UNIVERSAL)
-- ============================================

local CHECKBOX = DanLib.UiPanel()

--- Initializing a checkbox with default parameters
-- Sets initial values for size, colors, text, and position
function CHECKBOX:Init()
    self:SetText('')
    self:SetCursor('hand')
    
    self.checkboxSize = DBase:Scale(36)
    self.labelText = ''
    self.labelFont = 'danlib_font_16'
    self.labelPosition = RIGHT
    self.labelGap = DBase:Scale(8)
    
    self.labelTextEnabled = nil
    self.labelTextDisabled = nil
    
    self.labelColorEnabled = DBase:Theme('text')
    self.labelColorDisabled = DBase:Theme('text', 150)
    
    self.value = false
    
    -- Caching of the material
    self.checkMaterial = DMaterial['Ok']
    
    -- Cached positions
    self.cachedCheckboxX = 0
    self.cachedCheckboxY = 0
    self.cachedTextX = 0
    self.cachedTextAlign = _TEXT_ALIGN_LEFT
    
    self:RecalculateSize()
end

--- Updates cached item positions
-- Called when the size or position is changed
function CHECKBOX:UpdatePositions()
    local w, h = self:GetSize()
    self.cachedCheckboxY = (h - self.checkboxSize) / 2
    
    if (self.labelPosition == LEFT) then
        self.cachedCheckboxX = w - self.checkboxSize
        self.cachedTextX = self.cachedCheckboxX - self.labelGap
        self.cachedTextAlign = _TEXT_ALIGN_RIGHT
    else
        self.cachedCheckboxX = 0
        self.cachedTextX = self.checkboxSize + self.labelGap
        self.cachedTextAlign = _TEXT_ALIGN_LEFT
    end
end

--- Automatic update when resizing
function CHECKBOX:PerformLayout(w, h)
    self:UpdatePositions()
end

--- Recalculates the size of the checkbox based on the text
-- Uses the longest text (static or dynamic) to determine the width
function CHECKBOX:RecalculateSize()
    if (self.labelText == '' and not self.labelTextEnabled and not self.labelTextDisabled) then
        self:SetWide(self.checkboxSize)
        self:SetTall(self.checkboxSize)
    else
        local maxText = self.labelText
        
        if (self.labelTextEnabled and #self.labelTextEnabled > #maxText) then
            maxText = self.labelTextEnabled
        end
        
        if (self.labelTextDisabled and #self.labelTextDisabled > #maxText) then
            maxText = self.labelTextDisabled
        end
        
        local textW, textH = DUtils:GetTextSize(maxText, self.labelFont)
        local totalWidth = self.checkboxSize + self.labelGap + textW
        local totalHeight = _max(self.checkboxSize, textH)
        
        self:SetWide(totalWidth)
        self:SetTall(totalHeight)
    end
    
    self:UpdatePositions()
end

--- Sets the static label text
-- @param text (string): Text to display next to the checkbox
-- @return (Panel): self for the call chain
function CHECKBOX:SetLabel(text)
    self.labelText = text or ''
    self:RecalculateSize()
    return self
end

--- Sets dynamic text for different checkbox states
-- @param enabledText (string): Text when the checkbox is enabled (value = true)
-- @param disabledText (string): Text when the checkbox is disabled (value = false)
-- @return (Panel): self for the call chain
-- @example checkbox:SetStateTexts('ON', 'OFF')
function CHECKBOX:SetStateTexts(enabledText, disabledText)
    self.labelTextEnabled = enabledText
    self.labelTextDisabled = disabledText
    self:RecalculateSize()
    return self
end

--- Gets the current text based on the dynamic state
-- @return (string): The current text to display (dynamic or static)
function CHECKBOX:GetLabel()
    -- If there is a dynamic text, we use it.
    if (self.value and self.labelTextEnabled) then
        return self.labelTextEnabled
    elseif (not self.value and self.labelTextDisabled) then
        return self.labelTextDisabled
    end
    -- Otherwise static
    return self.labelText
end

--- Sets the position of the text relative to the checkbox
-- @param position (number): LEFT or RIGHT
-- @return (Panel): self for the call chain
function CHECKBOX:SetLabelPosition(position)
    self.labelPosition = position == LEFT and LEFT or RIGHT
    self:RecalculateSize()
    return self
end

--- Sets the font of the text
-- @param font (string): Font name (for example, 'danlib_font_16')
-- @return (Panel): self for the call chain
function CHECKBOX:SetLabelFont(font)
    self.labelFont = font or 'danlib_font_16'
    self:RecalculateSize()
    return self
end

--- Sets the text colors for the on and off state
-- @param enabledColor (Color): The color of the text when the checkbox is enabled
-- @param disabledColor (Color): The color of the text when the checkbox is off
-- @return (Panel): self for the call chain
function CHECKBOX:SetLabelColors(enabledColor, disabledColor)
    self.labelColorEnabled = enabledColor or DBase:Theme('text')
    self.labelColorDisabled = disabledColor or DBase:Theme('text', 150)
    return self
end

--- Sets the size of the checkbox square
-- @param size (number): The size in pixels
-- @return (Panel): self for the call chain
function CHECKBOX:SetCheckboxSize(size)
    self.checkboxSize = size
    self:RecalculateSize()
    return self
end

--- Sets the indentation between the checkbox and the text
-- @param gap (number): Pixel offset
-- @return (Panel): self for the call chain
function CHECKBOX:SetLabelGap(gap)
    self.labelGap = gap
    self:RecalculateSize()
    return self
end

--- Sets the value of the checkbox and calls onChange
-- @param val (boolean): true = enabled, false = disabled
-- @return (Panel): self for the call chain
function CHECKBOX:SetValue(val)
    self.value = val
    
    if self.OnChange then
        self:OnChange(val)
    end
    
    return self
end

--- Gets the current value of the checkbox
-- @return (boolean): true if enabled, false if disabled
function CHECKBOX:GetValue()
    return self.value
end

--- Gets the status of the checkbox (alias for getValue)
-- @return (boolean): true if enabled, false if disabled
function CHECKBOX:GetChecked()
    return self.value
end

--- Switches the status of the checkbox to the opposite
-- @return (Panel): self for the call chain
function CHECKBOX:Toggle()
    self:SetValue(not self.value)
    return self
end

--- The checkbox click handler
-- Ignores the click if the checkbox is disabled
function CHECKBOX:DoClick()
    -- Не кликается если disabled (новая фича)
    if (not self:GetDisabled()) then
        self:Toggle()
    end
end

--- Enables or disables the checkbox by changing the cursor
-- @param enabled (boolean): true = active, false = blocked
-- @return (Panel): self for the call chain
function CHECKBOX:SetEnabled(enabled)
    self:SetDisabled(not enabled)
    self:SetCursor(enabled and 'hand' or 'no')
    return self
end

--- Applies shadow to the checkbox (old API for compatibility)
-- @param distance (number): Shadow distance (default: 10)
-- @param noClip (boolean): Disable clipping (default: false)
-- @param iteration (number): Number of shadow iterations (default: 5)
-- @return (Panel): self for the call chain
function CHECKBOX:DisableShadows(distance, noClip, iteration)
    self:ApplyShadow(distance or 10, noClip or false, iteration or 3)
    return self
end

--- Rendering the checkbox (optimized version)
-- Draws the background, borders, icon, and text based on the state and disabled
-- @param w (number): Width of the panel
-- @param h (number): Panel height
function CHECKBOX:Paint(w, h)
    self:ApplyAlpha(0.2, 150)

    -- Hover animation
    local hoverChange = self.value and 3 or -3
    self.hoverPercent = _clamp((self.hoverPercent or 0) + hoverChange, 0, 100)
    local hoverPercent = self.hoverPercent / 100

    -- Dimming if disabled
    local disabledAlpha = (self.GetDisabled and self:GetDisabled()) and 0.4 or 1.0
    local disabledAlpha255 = disabledAlpha * 255

    -- We use cached positions
    local checkboxX = self.cachedCheckboxX
    local checkboxY = self.cachedCheckboxY
    local textX = self.cachedTextX
    local textAlign = self.cachedTextAlign
    
    -- Flower preparation
    local baseAlpha = self.alpha * disabledAlpha
    local bgColor = DBase:Theme('secondary', baseAlpha)
    local btnColor = DBase:Theme('button')
    local borderColor = _ColorAlpha(Color(37, 56, 79), disabledAlpha255)
    
    -- We draw the background and basic frames
    DUtils:DrawRoundedBox(checkboxX, checkboxY, self.checkboxSize, self.checkboxSize, bgColor)
    DUtils:DrawRoundedBox(checkboxX, checkboxY, self.checkboxSize, self.checkboxSize, btnColor)
    surface.DrawOutlinedRoundedRect(checkboxX, checkboxY, self.checkboxSize, self.checkboxSize, 6, 1, borderColor)
    
    -- Color frame and icon when turned on
    if self.value then
        local decorAlpha = hoverPercent * 100 * disabledAlpha
        local decorColor = DBase:Theme('decor', decorAlpha)
        surface.DrawOutlinedRoundedRect(checkboxX, checkboxY, self.checkboxSize, self.checkboxSize, 6, 1, decorColor)
        
        local IconSize = DBase:Scale(24)
        local iconX = checkboxX + (self.checkboxSize - IconSize) / 2
        local iconY = checkboxY + (self.checkboxSize - IconSize) / 2
        local iconColor = DBase:Theme('mat', 200 * disabledAlpha)
        DUtils:DrawIcon(iconX, iconY, IconSize, IconSize, self.checkMaterial, iconColor)
    end
    
    -- Validating an empty string correctly
    local currentText = self:GetLabel()
    if (currentText ~= '') then
        local labelColor = self.value and self.labelColorEnabled or self.labelColorDisabled
        labelColor = _ColorAlpha(labelColor, disabledAlpha255)
        _drawSimpleText(currentText, self.labelFont, textX, h / 2, labelColor, textAlign, TEXT_ALIGN_CENTER)
    end
end

CHECKBOX:SetBase('DButton')
CHECKBOX:Register('DanLib.UI.Checkbox')

-- ============================================
-- OLD API (TO BE DELETED IN THE FUTURE)
-- ============================================

--- Creates a simple checkbox without options (old API)
-- Fully compatible with the old code. Use the methods to configure it.
-- @param parent (Panel): Parent Panel
-- @return (Panel): A copy of the checkbox
-- @example
--   local cb = DBase.CreateCheckbox(panel)
--   cb:SetPos(10, 10)
--   cb:SetLabel('Old Style')
--   cb:SetValue(true)
function DBase.CreateCheckbox(parent)
    return DCustomUtils(parent or nil, 'DanLib.UI.Checkbox')
end


-- ============================================
-- NEW API (EXTENDED)
-- ============================================
--- Creates a checkbox with advanced options (new API)
-- @param parent (Panel): Parent Panel
-- @param options (table): A table with configuration options
--
-- @param options.text (table): Text Settings { text, font, color, position, stateColors }
--   [1] text (string|table): Label text OR {enabledText, disabledText} for dynamic text
--   [2] font (string): Font (default: 'danlib_font_16')
--   [3] color (Color|nil): Universal text color (default: Theme('text'))
--   [4] position (number): LEFT or RIGHT (default: RIGHT)
--   [5] stateColors (Color|table): Status:
--       • Color - colors The color for
--       • {Color, Color} - { on, off }
--
-- @param options.value (boolean): The initial value of the checkbox (default: false)
-- @param options.disabled (boolean): Block the checkbox (default: false)
-- @param options.checkboxSize (number): The size of the checkbox square in pixels
-- @param options.gap (number): The indentation between the checkbox and the text
--
-- @param options.dock (table): Docking { position, margin }
-- @param options.dock_indent (table): Indented docking { position, top, left, bottom, right }
-- @param options.pos (table): Position { x, y }
-- @param options.size (table): Size { width, height }
-- @param options.wide (number): Width
-- @param options.tall (number): Height
--
-- @param options.click (function): Function when clicked function(self) end
-- @param options.change (function): Function when the value changes function(self, value) end
--
-- @param options.tooltip (table): Popup hint { text, color, icon, position }
-- @param options.sound (table): Sounds { hoverSound, clickSound }
-- @param options.shadow (table): Shadow Settings { distance, noClip, iteration }
--
-- @return (Panel): A copy of the checkbox
--
-- @example A simple checkbox:
--   DBase.CreateUICheckbox(panel, {
--       text = { 'Enable feature' },
--       pos = { 10, 10 },
--       value = true
--   })
--
-- @example Dynamic text with colors:
--   DBase.CreateUICheckbox(panel, {
--       text = { {'ON', 'OFF'}, 'danlib_font_16', nil, RIGHT, { Color(0, 255, 0), Color(255, 0, 0) } },
--       pos = { 10, 50 },
--       wide = 150,
--       change = function(self, val) print('Changed:', val) end
--   })
--
-- @example With shadow and tooltip:
--   DBase.CreateUICheckbox(panel, {
--       text = { 'Important Option' },
--       dock_indent = { TOP, 5, 10, 0, 10 },
--       shadow = { 12, false, 6 },
--       tooltip = { 'This is important!', nil, nil, TOP }
--   })
function DBase.CreateUICheckbox(parent, options)
    options = options or {}
    
    local checkbox = DCustomUtils(parent or nil, 'DanLib.UI.Checkbox')
    
    local function hasKey(key)
        return options[key] ~= nil
    end
    
    -- TEXT - WITH DYNAMIC TEXT SUPPORT
    if hasKey('text') then
        local text = _normalizeOption(options.text)
        
        -- [1] = , text OR {enabledText, disabledText}
        if text[1] then
            if (_type(text[1]) == 'table') then
                checkbox:SetStateTexts(text[1][1], text[1][2])
            else
                checkbox:SetLabel(text[1])
            end
        end
        
        -- [2] = font
        if text[2] then
            checkbox:SetLabelFont(text[2])
        end
        
        local universalColor = _IsColor(text[3]) and text[3] or nil
        local position = text[4] or RIGHT
        local stateColors = text[5]
        
        checkbox:SetLabelPosition(position)
        
        -- logical colors
        if stateColors then
            if (_type(stateColors) == 'table' and not _IsColor(stateColors)) then
                local enabledColor = _IsColor(stateColors[1]) and stateColors[1] or DBase:Theme('text')
                local disabledColor = _IsColor(stateColors[2]) and stateColors[2] or DBase:Theme('text', 150)
                checkbox:SetLabelColors(enabledColor, disabledColor)
            elseif _IsColor(stateColors) then
                checkbox:SetLabelColors(stateColors, DBase:Theme('text', 150))
            end
        elseif universalColor then
            checkbox:SetLabelColors(universalColor, universalColor)
        else
            checkbox:SetLabelColors(DBase:Theme('text'), DBase:Theme('text', 150))
        end
    end
    
    -- VALUE
    if hasKey('value') then
        checkbox:SetValue(options.value)
    end
    
    -- DISABLED
    if hasKey('disabled') then
        checkbox:SetEnabled(not options.disabled)
    end
    
    -- CHECKBOX SIZE
    if hasKey('checkboxSize') then
        checkbox:SetCheckboxSize(options.checkboxSize)
    end
    
    -- GAP
    if hasKey('gap') then
        checkbox:SetLabelGap(options.gap)
    end
    
    -- DOCKING
    if hasKey('dock') then
        local dock = _normalizeOption(options.dock)
        if dock[1] then
            checkbox:Pin(dock[1], dock[2] or 0)
        end
    end
    
    if hasKey('dock_indent') then
        local dockIndent = _normalizeOption(options.dock_indent)
        checkbox:Dock(dockIndent[1])
        checkbox:DockMargin(dockIndent[2] or 0, dockIndent[3] or 0, dockIndent[4] or 0, dockIndent[5] or 0)
    end
    
    -- POSITION & SIZE
    if hasKey('pos') then checkbox:SetPos(unpack(options.pos)) end
    if hasKey('size') then checkbox:SetSize(unpack(options.size)) end
    if hasKey('wide') then checkbox:SetWide(options.wide) end
    if hasKey('tall') then checkbox:SetTall(options.tall) end
    
    -- EVENTS
    if hasKey('click') then checkbox:ApplyEvent('DoClick', options.click) end
    if hasKey('change') then checkbox.OnChange = options.change end
    
    -- TOOLTIP
    if hasKey('tooltip') then
        local tooltip = _normalizeOption(options.tooltip)
        local tooltipColor = tooltip[2] and _IsColor(tooltip[2]) and tooltip[2] or nil
        checkbox:ApplyTooltip(tooltip[1], tooltipColor, tooltip[3], tooltip[4])
    end
    
    -- SOUND
    if hasKey('sound') then
        local sound = _normalizeOption(options.sound)
        if (sound[1] or sound[2]) then
            checkbox:ApplySound(sound[1], sound[2])
        end
    end
    
    -- SHADOW
    if hasKey('shadow') then
        local shadow = _normalizeOption(options.shadow)
        local distance = shadow[1] or 10
        local noClip = shadow[2] or false
        local iteration = shadow[3] or 5
        checkbox:DisableShadows(distance, noClip, iteration)
    end
    
    return checkbox
end

local function checkboxExample()
    if IsValid(DanLib.CheckboxExample) then
        DanLib.CheckboxExample:Remove()
    end

    local frame = DBase.CreateUIFrame()
    frame:SetSize(300, 300)
    frame:SetTitle('Checkbox Example')
    frame:Center()
    frame:MakePopup()
    DanLib.CheckboxExample = frame

    local checkbox = DBase.CreateUICheckbox(frame, {
        pos = { 130, 40 },
        value = false,
    })

    local checkbox1 = DBase.CreateUICheckbox(frame, {
        pos = { 10, 40 },
        text = { 'Debug Mode', 'danlib_font_16', color_white, LEFT },
        value = true,
    })

    local checkbox2 = DBase.CreateUICheckbox(frame, {
        pos = { 10, 80 },
        text = { 'Exact Match', 'danlib_font_16', Color(100, 255, 100), RIGHT, Color(150, 150, 150) },
        value = false,
        tooltip = { 'This is an important setting', nil, nil, TOP },
    })

    local checkbox3 = DBase.CreateUICheckbox(frame, {
        text = { 'Large Checkbox' },
        pos = { 10, 120 },
        checkboxSize = DBase:Scale(50),
        gap = DBase:Scale(12),
        value = false
    })

    local checkbox4 = DBase.CreateUICheckbox(frame, {
        text = { 'Important Option', 'danlib_font_18', Color(255, 200, 0) },
        pos = { 10, 170 },
        value = true,
        tooltip = { 'This is an important setting', nil, nil, TOP },
        sound = { 'buttons/button15.wav', 'buttons/button14.wav' }
    })

    local checkbox5 = DBase.CreateUICheckbox(frame, {
        text = { 'Auto-Refresh', 'danlib_font_16', nil, RIGHT, { Color(255, 200, 0), Color(100, 100, 100) } },
        dock_indent = { TOP, 10, 180, 0, 10 },
        value = false,
        tooltip = { 'Toggle auto-refresh', nil, nil, TOP },
        change = function(self, val)
            DBase:Print('Auto-refresh:', val)
        end
    })

    local checkbox6 = DBase.CreateUICheckbox(frame, {
        text = { 'ON/OFF Indicator', 'danlib_font_18', nil, RIGHT, { Color(0, 255, 0), Color(255, 0, 0) } },
        pos = { 10, 250 },
        value = false,
        change = function(self, val)
            DBase:Print('State:', val and 'ON' or 'OFF')
        end
    })

    local checkbox7 = DBase.CreateUICheckbox(frame, {
        text = { { 'Online', 'Offline' }, 'danlib_font_20', nil, RIGHT, { Color(100, 255, 100), Color(255, 100, 100) } },
        pos = { 170, 40 },
        value = true,
        tooltip = { 'Server status indicator', nil, nil, TOP },
        change = function(self, val)
            DBase:Print('Server is', val and 'ONLINE' or 'OFFLINE')
        end
    })

    -- The controller
    local controller = DBase.CreateUICheckbox(frame, {
        text = { 'Enable Checkbox Below', nil, nil, LEFT },
        pos = { 120, 100 },
        value = false
    })

    local controlled = DBase.CreateUICheckbox(frame, {
        text = { { 'Active', 'Inactive' }, 'danlib_font_14', nil, LEFT },
        pos = { 220, 140 },
        value = false,
        disabled = true
    })
    controller.OnChange = function(self, val)
        controlled:SetEnabled(val)
    end
end

-- checkboxExample()