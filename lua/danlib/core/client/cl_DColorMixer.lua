/***
 *   @addon         DanLib
 *   @component     UI ColorMixer
 *   @license       MIT License
 *   @version       1.0.2
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Complete Color Mixer - All issues fixed:
 *                  1. HSV slider properly updates text with alpha changes
 *                  2. Text input accepts only numbers and commas
 *                  3. Auto-fill prevents empty text field
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DTable = DanLib.Table
local DCustomUtils = DanLib.CustomUtils.Create

local math = math
local clamp = math.Clamp
local floor = math.floor
local string = string
local format = string.format
local gmatch = string.gmatch

-- Enhanced color format handlers for parsing input text with comma support
local formatHandlers = {
    RGB = function(input)
        if (not input or input == '') then
        	return nil
        end
        
        -- Remove spaces and split by commas
        local values = {}
        for value in gmatch(input:gsub('%s+', ''), '([^,]+)') do
            local num = tonumber(value)
            if num then
                DTable:Add(values, clamp(num, 0, 255))
            end
        end
        
        -- Ensure we have 3 or 4 values (RGB or RGBA)
        if (#values >= 3) then
            return values[1], values[2], values[3], values[4] or 255
        end
        
        -- Fallback to DanLib parser
        return DUtils:ParseColor(input, 'RGB')
    end,
    HEX = function(input)
        if (not input or input == '') then
        	return nil
        end

        return DUtils:ParseColor(input, 'HEX')
    end,
    CMYK = function(input)
        if (not input or input == '') then
        	return nil
        end
        
        -- Parse comma-separated CMYK values
        local values = {}
        for value in gmatch(input:gsub('%s+', ''), '([^,]+)') do
            local num = tonumber(value)
            if num then
                DTable:Add(values, clamp(num, 0, 100))
            end
        end
        
        if (#values >= 4) then
            local r, g, b = DUtils:CMYKtoRGB(values[1], values[2], values[3], values[4])
            if r then
                return r, g, b, 255
            end
        end
        
        -- Fallback to DanLib parser
        local c, m, y, k = DUtils:ParseColor(input, 'CMYK')
        if (c and m and y and k) then
            return DUtils:CMYKtoRGB(c, m, y, k), 255
        end
        return nil
    end,
    HSV = function(input)
        if (not input or input == '') then
        	return nil
        end
        
        -- Parse comma-separated HSV values
        local values = {}
        for value in gmatch(input:gsub('%s+', ''), "([^,]+)") do
            local num = tonumber(value)
            if num then
                DTable:Add(values, num)
            end
        end
        
        if (#values >= 3) then
            -- HSV: H(0-360), S(0-100), V(0-100), A(0-255)
            local h = clamp(values[1], 0, 360)
            local s = clamp(values[2], 0, 100) / 100 -- Convert to 0-1
            local v = clamp(values[3], 0, 100) / 100 -- Convert to 0-1
            local a = values[4] and clamp(values[4], 0, 255) or 255
            
            local r, g, b = DUtils:HSVtoRGB(h, s, v)
            if r then
                return r, g, b, a
            end
        end
        
        -- Fallback to DanLib parser
        local h, s, v = DUtils:ParseColor(input, 'HSV')
        if (h and s and v) then
            return DUtils:HSVtoRGB(h, s, v), 255
        end
        return nil
    end,
    HSL = function(input)
        if (not input or input == '') then
        	return nil
        end
        
        -- Parse comma-separated HSL values
        local values = {}
        for value in gmatch(input:gsub('%s+', ''), '([^,]+)') do
            local num = tonumber(value)
            if num then
                DTable:Add(values, num)
            end
        end
        
        if (#values >= 3) then
            -- HSL: H(0-360), S(0-100), L(0-100), A(0-255)
            local h = clamp(values[1], 0, 360)
            local s = clamp(values[2], 0, 100)
            local l = clamp(values[3], 0, 100)
            local a = values[4] and clamp(values[4], 0, 255) or 255
            
            local r, g, b = DUtils:HSLtoRGB(h, s, l)
            if r then
                return r, g, b, a
            end
        end
        
        -- Fallback to DanLib parser
        local h, s, l = DUtils:ParseColor(input, 'HSL')
        if (h and s and l) then
            return DUtils:HSLtoRGB(h, s, l), 255
        end
        return nil
    end
}

-- Color format converters for displaying text with proper comma formatting
local formatConverters = {
    RGB = function(color)
        if (not color or not color.r) then
        	return '255, 0, 0, 255'
        end

        return format('%d, %d, %d, %d', clamp(color.r or 255, 0, 255), clamp(color.g or 0, 0, 255), clamp(color.b or 0, 0, 255), clamp(color.a or 255, 0, 255))
    end,
    HEX = function(color)
        if (not color or not color.r) then
        	return '#FF0000'
        end

        return format('#%02X%02X%02X', clamp(color.r or 255, 0, 255), clamp(color.g or 0, 0, 255), clamp(color.b or 0, 0, 255))
    end,
    CMYK = function(color)
        if (not color or not color.r) then
        	return '0, 100, 100, 0'
        end

        local c, m, y, k = DUtils:RGBtoCMYK(color.r, color.g, color.b)
        if (not c) then
        	return '0, 100, 100, 0'
        end

        return format('%d, %d, %d, %d', math.Round(c), math.Round(m), math.Round(y), math.Round(k))
    end,
    HSV = function(color)
        if (not color or not color.r) then
        	return '0, 100, 100, 255'
        end

        local h, s, v = ColorToHSV(Color(color.r, color.g, color.b))
        if (not h) then
        	return '0, 100, 100, 255'
        end

        return format('%d, %d, %d, %d', math.Round(h), math.Round(s * 100), math.Round(v * 100), clamp(color.a or 255, 0, 255))
    end,
    HSL = function(color)
        if (not color or not color.r) then
        	return '0, 100, 50, 255'
        end

        local h, s, l = DUtils:RGBtoHSL(color.r, color.g, color.b)
        if (not h) then
        	return '0, 100, 50, 255'
        end

        return format('%d, %d, %d, %d', math.Round(h), math.Round(s), math.Round(l), clamp(color.a or 255, 0, 255))
    end
}


local MIXER, Constructor = DanLib.UiPanel()

AccessorFunc(MIXER, 'm_bPalette', 'Palette', FORCE_BOOL)
AccessorFunc(MIXER, 'm_bAlpha', 'AlphaBar', FORCE_BOOL)
AccessorFunc(MIXER, 'm_bWangsPanel', 'Wangs', FORCE_BOOL)
AccessorFunc(MIXER, 'm_Color', 'Color')

function MIXER:Init()
    -- Initialize current format and prevent feedback loops
    self.currentFormat = 'RGB'
    self.isUpdating = false
    
    -- Initialize safe default color
    self.m_Color = DUtils:UiColor(255, 0, 0, 255)
    
    local container = DCustomUtils(self):Pin(nil, 6)
    local scroll = DCustomUtils(container, 'DanLib.UI.Scroll')
    scroll:PinMargin(BOTTOM, nil, 8)
    scroll:SetTall(60)
    scroll:ToggleScrollBar()

    -- Format selector and text input panel
    self.WangsPanel = DCustomUtils(container)
    self.WangsPanel:PinMargin(BOTTOM, nil, 10, nil, 4)
    self.WangsPanel:SetTall(26)
    self:SetWangs(true)

    -- Format selector combo box
    self.combo = DBase.CreateUIComboBox(self.WangsPanel)
    self.combo:PinMargin(RIGHT, 4)
    self.combo:SetWide(80)
    self.combo:SetValue('RGB')
    self.combo:SetDirection(true)

    local options = { 'RGB', 'HEX', 'CMYK', 'HSV', 'HSL' }
    for k, v in pairs(options) do
        self.combo:AddChoice(v, k)
    end

    -- Format selection event with guaranteed text field population
    self.combo:ApplyEvent('OnSelect', function(_, index, value, data)
        if self.isUpdating then
        	return
        end
        
        self.currentFormat = value
        
        -- Always ensure text field is populated when format changes
        local currentColor = self:GetRGBColor()
        if not currentColor then
            currentColor = DUtils:UiColor(255, 0, 0, 255)
            self.m_Color = currentColor
        end
        
        self:UpdateTextFromColor(currentColor)
        self:RefreshPalette()
    end)

    -- Color palette
    function self:RefreshPalette()
        if IsValid(self.Palette) then
            self.Palette:Remove()
        end
        
        self.Palette = DCustomUtils(scroll, 'DanLib.UI.ColorPalette')
        self.Palette:Pin()
        self.Palette:SetFormatRGB(self.currentFormat)
        self.Palette:SetButtonSize(24)
        self.Palette:Reset()
        self.Palette:ApplyEvent('DoClick', function(ctrl, color, btn)
            if (color and color.r) then
                self:SetColor(DUtils:UiColor(color.r, color.g, color.b, self:GetAlphaBar() and color.a or 255))
            end
        end)
        self:SetPalette(true)
    end
    self:RefreshPalette()

    -- Text input field with comprehensive validation
    self.input = DBase.CreateTextEntry(self.WangsPanel)
    self.input:Pin()
    self.input:SetValue('255, 0, 0, 255')
    
    -- Text input change event with complete validation and auto-fill
    self.input.textEntry:ApplyEvent('OnTextChanged', function()
        if self.isUpdating then
            return
        end
        
        local inputValue = self.input:GetValue()
        
        -- Auto-fill empty field with current color
        if (not inputValue or inputValue == '') then
            DanLib.Timer:Simple(0.01, function()
                if IsValid(self) and IsValid(self.input) then
                    self:UpdateTextFromColor()
                end
            end)
            return
        end
        
        -- Filter input to only allow valid characters
        local filteredValue = inputValue
        if (self.currentFormat == 'HEX') then
            filteredValue = string.gsub(inputValue, '[^0-9A-Fa-f#]', '')
        else
            filteredValue = string.gsub(inputValue, '[^0-9,%s]', '')
        end
        
        -- Update input if filtering changed the value
        if (filteredValue ~= inputValue) then
            self.isUpdating = true
            self.input:SetValue(filteredValue)
            self.isUpdating = false
            return
        end
        
        local handler = formatHandlers[self.currentFormat]
        if handler then
            local r, g, b, a = handler(filteredValue)
            
            -- Validate parsed values
            if (r and g and b and a) then
                -- Clamp values to valid ranges
                r = clamp(r, 0, 255)
                g = clamp(g, 0, 255)
                b = clamp(b, 0, 255)
                a = clamp(a, 0, 255)
                
                -- Update color and all controls
                local color = DUtils:UiColor(r, g, b, a)
                self:UpdateFromTextInput(color)
            end
        end
    end)

    -- HSV Color Cube with proper alpha preservation
    self.HSV = DCustomUtils(container, 'DanLib.UI.ColorCube')
    self.HSV:Pin()
    self.HSV:ApplyEvent('OnUserChanged', function(ctrl, color)
        if self.isUpdating then
        	return
        end
        
        if color then
            -- Preserve alpha value from current color
            local currentColor = self:GetRGBColor()
            color.a = currentColor and currentColor.a or 255
            self:UpdateFromColorCube(color)
        else
            -- Auto-fill if no color provided
            self:EnsureTextFilled()
        end
    end)

    -- Alpha Bar with proper text synchronization
    self.Alpha = DCustomUtils(self, 'DanLib.UI.AlphaBar')
    self.Alpha:PinMargin(RIGHT, 4, 4)
    self.Alpha:SetWidth(14)
    self.Alpha:ApplyEvent('OnChange', function(ctrl, fAlpha)
        if self.isUpdating then
        	return
        end
        
        local color = self:GetRGBColor()
        if color then
            color.a = floor((fAlpha or 0) * 255)
            self:UpdateFromSlider(color)
        else
            self:EnsureTextFilled()
        end
    end)
    self:SetAlphaBar(true)

    -- RGB Picker with proper text synchronization
    self.RGB = DCustomUtils(self, 'DanLib.UI.RGBPicker')
    self.RGB:PinMargin(LEFT, nil, 4, 4)
    self.RGB:SetWidth(14)
    self.RGB:ApplyEvent('OnChange', function(ctrl, color)
        if self.isUpdating then
        	return
        end
        
        if color then
            self:SetBaseColor(color)
        else
            self:EnsureTextFilled()
        end
    end)

    -- Initialize with default color
    self:SetColor(DUtils:UiColor(255, 0, 0, 255))
    self:SetSize(256, 230)
    self:InvalidateLayout()
end

-- Ensure text field is always filled
function MIXER:EnsureTextFilled()
    if (not self.input or not IsValid(self.input)) then
    	return
    end
    
    local currentValue = self.input:GetValue()
    if (not currentValue or currentValue == '') then
        self:UpdateTextFromColor()
    end
end

-- Update color from text input with full RGB and alpha synchronization
function MIXER:UpdateFromTextInput(color)
    if (not color) then
    	return
    end
    
    self.isUpdating = true
    
    -- Update internal color
    self.m_Color = color
    
    -- Update Alpha bar
    if IsValid(self.Alpha) then
        self.Alpha:SetBarColor(ColorAlpha(color, 255))
        self.Alpha:SetValue((color.a or 255) / 255)
    end
    
    -- Update HSV color cube (RGB only, alpha handled separately)
    if IsValid(self.HSV) then
        local rgbColor = Color(color.r, color.g, color.b)
        self.HSV:SetColor(rgbColor)
    end
    
    -- Update RGB picker
    if IsValid(self.RGB) then
        local hue, s, v = ColorToHSV(color)
        if hue then
            self.RGB.LastY = (1 - hue / 360) * self.RGB:GetTall()
        end
    end
    
    -- Call value changed callback
    self:ValueChanged(color)
    self.isUpdating = false
end

-- Update color from HSV cube with proper alpha preservation
function MIXER:UpdateFromColorCube(color)
    if (not color) then
    	return
    end
    
    self.isUpdating = true
    
    -- Ensure alpha is preserved
    if (not color.a) then
        local currentColor = self:GetRGBColor()
        color.a = currentColor and currentColor.a or 255
    end
    
    -- Update text input immediately
    self:UpdateTextFromColor(color)
    
    -- Update Alpha bar
    if IsValid(self.Alpha) then
        self.Alpha:SetBarColor(ColorAlpha(color, 255))
        self.Alpha:SetValue((color.a or 255) / 255)
    end
    
    -- Update internal color and callback
    self:UpdateColor(color)
    self.isUpdating = false
end

-- Update color from alpha/RGB sliders
function MIXER:UpdateFromSlider(color)
    if (not color) then
    	return
    end
    
    self.isUpdating = true
    
    -- Update text input immediately
    self:UpdateTextFromColor(color)
    
    -- Update HSV cube (RGB only)
    if IsValid(self.HSV) then
        local rgbColor = Color(color.r, color.g, color.b)
        self.HSV:SetColor(rgbColor)
    end
    
    -- Update internal color and callback
    self:UpdateColor(color)
    self.isUpdating = false
end

-- Update text input from current color (always works, even during updates)
function MIXER:UpdateTextFromColor(color)
    local currentColor = color or self:GetRGBColor()
    
    -- Ensure we have a valid color object
    if (not currentColor or type(currentColor) ~= "table" or not currentColor.r) then
        currentColor = { r = 255, g = 0, b = 0, a = 255 }
    end
    
    local converter = formatConverters[self.currentFormat]
    
    if (converter and self.input and IsValid(self.input)) then
        local success, formattedText = pcall(converter, currentColor)
        if (success and formattedText) then
            -- Temporarily allow text setting without triggering events
            local wasUpdating = self.isUpdating
            self.isUpdating = true
            self.input:SetValue(formattedText)
            self.isUpdating = wasUpdating
        end
    end
end

-- Standard color mixer methods
function MIXER:SetPalette(bEnabled)
    self.m_bPalette = bEnabled
    if IsValid(self.Palette) then
        self.Palette:SetVisible(bEnabled)
    end
    self:InvalidateLayout()
end

function MIXER:SetAlphaBar(bEnabled)
    self.m_bAlpha = bEnabled
    if IsValid(self.Alpha) then
        self.Alpha:SetVisible(bEnabled)
    end
    self:InvalidateLayout()
end

function MIXER:SetWangs(bEnabled)
    self.m_bWangsPanel = bEnabled
    if IsValid(self.WangsPanel) then
        self.WangsPanel:SetVisible(bEnabled)
    end
    self:InvalidateLayout()
end

function MIXER:SetColor(color)
    if (not color) then
    	return
    end
    
    local h, s, v = ColorToHSV(color)
    if (IsValid(self.RGB) and h) then
        self.RGB.LastY = (1 - h / 360) * self.RGB:GetTall()
    end
    
    if IsValid(self.HSV) then
        self.HSV:SetColor(color)
    end
    
    self:UpdateColor(color)
    self:UpdateTextFromColor(color)
end

function MIXER:SetVector(vec)
    if (vec and vec.x and vec.y and vec.z) then
        self:SetColor(DUtils:UiColor(vec.x * 255, vec.y * 255, vec.z * 255, 255))
    end
end

-- Enhanced SetBaseColor with proper text synchronization
function MIXER:SetBaseColor(color)
    if (not color or not IsValid(self.HSV)) then
    	return
    end
    
    self.HSV:SetBaseRGB(color)
    self.HSV:TranslateValues()
    
    -- Update text when base color changes
    if (not self.isUpdating) then
        local currentColor = self:GetRGBColor()
        local newColor = DUtils:UiColor(color.r, color.g, color.b, currentColor.a)
        self:UpdateTextFromColor(newColor)
        self:UpdateColor(newColor)
    end
end

function MIXER:UpdateColor(color)
    if (not color) then
    	return
    end
    
    -- Ensure color has all required components
    local safeColor = {
        r = clamp(color.r or 255, 0, 255),
        g = clamp(color.g or 0, 0, 255),
        b = clamp(color.b or 0, 0, 255),
        a = clamp(color.a or 255, 0, 255)
    }
    
    if IsValid(self.Alpha) then
        self.Alpha:SetBarColor(ColorAlpha(DUtils:UiColor(safeColor.r, safeColor.g, safeColor.b), 255))
        self.Alpha:SetValue(safeColor.a / 255)
    end

    -- Update text input (unless we're updating from text input)
    if (not self.isUpdating) then
        self:UpdateTextFromColor(safeColor)
    end

    self:ValueChanged(safeColor)
    self.m_Color = DUtils:UiColor(safeColor.r, safeColor.g, safeColor.b, safeColor.a)
end

function MIXER:ValueChanged(color)
    -- Override in parent class
end

-- Enhanced GetColor method
function MIXER:GetColor(format)
    if (not self.m_Color) then
        self.m_Color = DUtils:UiColor(255, 0, 0, 255)
    end
    
    local color = {
        r = self.m_Color.r or 255,
        g = self.m_Color.g or 0,
        b = self.m_Color.b or 0,
        a = 255
    }
    
    if (self.Alpha and IsValid(self.Alpha) and self.Alpha:IsVisible()) then 
        color.a = floor(self.Alpha:GetValue() * 255) 
    else
        color.a = self.m_Color.a or 255
    end
    
    -- If format is specified, return in that format
    if format then
        local converter = formatConverters[format]
        if converter then
            local success, result = pcall(converter, color)
            if success then
                return result
            end
        end
    end
    
    -- Return in current format if no format specified
    local converter = formatConverters[self.currentFormat]
    if (converter and self.currentFormat ~= 'RGB') then
        local success, result = pcall(converter, color)
        if success then
            return result
        end
    end
    
    return DUtils:UiColor(color.r, color.g, color.b, color.a)
end

-- Get raw RGB color object
function MIXER:GetRGBColor()
    if (not self.m_Color) then
        self.m_Color = DUtils:UiColor(255, 0, 0, 255)
    end
    
    local color = DUtils:UiColor(self.m_Color.r or 255, self.m_Color.g or 0, self.m_Color.b or 0, 255)
    if (self.Alpha and IsValid(self.Alpha) and self.Alpha:IsVisible()) then 
        color.a = floor(self.Alpha:GetValue() * 255) 
    else
        color.a = self.m_Color.a or 255
    end
    
    return color
end

function MIXER:GetVector()
    local col = self:GetRGBColor()
    if col then
        return Vector((col.r or 255) / 255, (col.g or 0) / 255, (col.b or 0) / 255)
    end
    return Vector(1, 0, 0)
end

function MIXER:GetCurrentFormat()
    return self.currentFormat or 'RGB'
end

function MIXER:SetFormat(format)
    if formatConverters[format] then
        self.currentFormat = format
        if IsValid(self.combo) then
            self.combo:SetValue(format)
        end
        self:UpdateTextFromColor()
        self:RefreshPalette()
    end
end

MIXER:Register('DanLib.UI.ColorMixer')

-- Complete test function
if IsValid(FrameS) then FrameS:Remove() end
local function testCompleteColorMixer()
    if IsValid(FrameS) then FrameS:Remove() end

    local Frame = DBase.CreateUIFrame()
    FrameS = Frame
    FrameS:SetTitle('Color Mixer')
    Frame:SetSize(300, 420)
    Frame:Center()
    Frame:MakePopup()

    local Picker = DCustomUtils(Frame, 'DanLib.UI.ColorMixer')
    Picker:Pin(FILL, 10)
    Picker:SetPalette(true)
    Picker:SetAlphaBar(true)
    Picker:SetWangs(true)
    Picker:SetColor(Color(30,100,160))

    -- Test panel
    local ButtonPanel = DCustomUtils(Frame)
    ButtonPanel:PinMargin(BOTTOM, 10, nil, 10, 10)
    ButtonPanel:SetTall(60)

    DBase.CreateUIButton(ButtonPanel, {
        background = { nil },
        dock_indent = { TOP, 10, nil, 10, 5 },
        tall = 25,
        hover = { Color(106, 178, 242, 50), nil, 6 },
        text = { 'Test All Features', 'danlib_font_16', nil, nil, Color(106, 178, 242) },
        click = function()
            DBase:Print('=== COMPLETE COLOR MIXER TEST ===')
            DBase:Print('Current Format:', Picker:GetCurrentFormat())
            DBase:Print('Color in format:', Picker:GetColor())
            DBase:Print('RGB Color:', Picker:GetRGBColor())
            DBase:Print('===================================')
        end
    })

    DBase.CreateUIButton(ButtonPanel, {
        background = { nil },
        dock_indent = { BOTTOM, 10, nil, 10, 5 },
        tall = 25,
        hover = { Color(178, 106, 242, 50), nil, 6},
        text = { 'Switch HSV', 'danlib_font_16', nil, nil, Color(178, 106, 242) },
        click = function()
            Picker:SetFormat('HSV')
        end
    })
end
-- testCompleteColorMixer()