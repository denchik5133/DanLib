/***
 *   @addon         DanLib
 *   @component     UI ColorPalette
 *   @license       MIT License
 *   @version       1.0.1
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Universal library for GMod Lua, combining all the necessary features to simplify script development. 
 *                  Avoid code duplication and speed up the creation process with this powerful and convenient library.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DTable = DanLib.Table
local DUtils = DanLib.Utils
local DCustomUtils = DanLib.CustomUtils.Create

local _IsValid = IsValid
local _ipairs = ipairs
local _pairs = pairs
local _tonumber = tonumber
local _ColorToHSV = ColorToHSV
local _HSVToColor = HSVToColor
local fromColor = string.FromColor

local math = math
local round = math.Round
local min = math.min
local floor = math.floor
local clamp = math.Clamp

local input = input
local mouseDown = input.IsMouseDown

local color_Error = Color(255, 0, 255)
local circleMaterial = DanLib.Config.Materials['vCircle']
local matGradient = Material('vgui/gradient-u')
local matGrid = Material('gui/alpha_grid.png', 'nocull')


--- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/drgbpicker.lua
local PICKER, Constructor = DanLib.UiPanel()

AccessorFunc(PICKER, 'm_RGB', 'RGB')

function PICKER:Init()
	self:SetRGB(color_white)
	self.Material = Material('gui/colors.png') -- TODO: Light/Dark
	self.LastY = -100
	self.IsPressed = false
	self:SetCursor('hand')
end

function PICKER:GetPosColor(x, y)
    local con_x = (x / self:GetWide()) * self.Material:Width()
    local con_y = (y / self:GetTall()) * self.Material:Height()

    con_x = clamp(con_x, 0, self.Material:Width() - 1)
    con_y = clamp(con_y, 0, self.Material:Height() - 1)

    return self.Material:GetColor(con_x, con_y), con_x, con_y
end

function PICKER:OnCursorMoved(x, y)
	if (not mouseDown(MOUSE_LEFT)) then
		return
	end

	local col = self:GetPosColor(x, y)
	if col then
		self.m_RGB = col
		self.m_RGB.a = 255
		self:OnChange(self.m_RGB)
	end

	self.LastY = y
end

function PICKER:OnChange(col)
	-- Override me
end

function PICKER:OnMousePressed(mcode)
	self:MouseCapture(true)
	self.IsPressed = true
	self:OnCursorMoved(self:CursorPos())
end

function PICKER:OnMouseReleased(mcode)
	self:MouseCapture(false)
	self.IsPressed = false
	self:OnCursorMoved(self:CursorPos())
end

function PICKER:Paint(w, h)
    DUtils:DrawRoundedMask(10, 0, 0, w, h, function()
        DUtils:DrawMaterial(2.5, 0, w - 4, h, color_white, self.Material)
    end)

    local circleSize = 14
    local centerX = clamp((w - circleSize) / 2, 0, w - circleSize) -- Centred at X and bounded
    local centerY = clamp(self.LastY - (circleSize / 2), 0, h - circleSize) -- Y centred and constrained
    -- Change the colour of the circle when it is pressed
    local circleColor = self.IsPressed and DUtils:UiColor(0, 151, 230) or color_white -- Blue if pressed, otherwise white
    DUtils:DrawMaterial(centerX, centerY, circleSize, circleSize, circleColor, circleMaterial)
end

PICKER:Register('DanLib.UI.RGBPicker')



--- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dalphabar.lua
local BAR, Constructor = DanLib.UiPanel()

AccessorFunc(BAR, 'm_Value', 'Value')
AccessorFunc(BAR, 'm_BarColor', 'BarColor')

function BAR:Init()
	self:SetBarColor(color_white)
	self:SetSize(26, 26)
	self:SetValue(1)
	self.IsPressed = false
	self:SetCursor('hand')
end

function BAR:OnCursorMoved(x, y)
    if (not mouseDown(MOUSE_LEFT)) then
    	return
    end
    
    local fHeight = y / self:GetTall()
    fHeight = 1 - clamp(fHeight, 0, 1)
    
    self:SetValue(fHeight)
    self:OnChange(fHeight)
end

function BAR:OnMousePressed(mcode)
	self:MouseCapture(true)
	self.IsPressed = true
	self:OnCursorMoved(self:CursorPos())
end

function BAR:OnMouseReleased(mcode)
	self:MouseCapture(false)
	self.IsPressed = false
	self:OnCursorMoved(self:CursorPos())
end

function BAR:OnChange(fAlpha) end

function BAR:Paint(w, h)
	local size = 128
	DUtils:DrawRoundedMask(10, 0, 0, w, h, function()
        for i = 0, math.ceil(h / size) do
            DUtils:DrawMaterial(2, i * size, w - 4, size, color_white, matGrid)
        end
        DUtils:DrawMaterial(2.5, 0, w - 4, h, DUtils:UiColor(self.m_BarColor.r, self.m_BarColor.g, self.m_BarColor.b, self.m_BarColor.a), matGradient)
    end)

    local lineY = (1 - self.m_Value) * h - 1
    local circleSize = 14
    local centerX = clamp((w - circleSize) / 2, 0, w - circleSize) -- Centred at X and bounded
    local centerY = clamp(lineY - (circleSize / 2), 0, h - circleSize) -- Y centred and constrained
    -- Change the colour of the circle when it is pressed
    local circleColor = self.IsPressed and DUtils:UiColor(0, 151, 230) or color_white -- Blue if pressed, otherwise white
    DUtils:DrawMaterial(centerX, centerY, circleSize, circleSize, circleColor, circleMaterial)
end

BAR:Register('DanLib.UI.AlphaBar')



--- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dcolorcube.lua
local CUBE, Constructor = DanLib.UiPanel()

AccessorFunc(CUBE, 'm_Hue', 'Hue')
AccessorFunc(CUBE, 'm_BaseRGB', 'BaseRGB')
AccessorFunc(CUBE, 'm_OutRGB', 'RGB')
AccessorFunc(CUBE, 'm_DefaultColor', 'DefaultColor')

function CUBE:Init()
	-- self:SetImage('vgui/minixhair')
	self.Knob:NoClipping(false)
	self:SetBaseRGB(Color(255, 0, 0))
	self:SetRGB(Color(255, 0, 0))
	self:SetColor(Color(255, 0, 0))
	self:SetLockX(nil)
	self:SetLockY(nil)
	self:SetDefaultColor(color_white)
end

function CUBE:PerformLayout(w, h)
	DSlider.PerformLayout(self, w, h)
end

function CUBE:ResetToDefaultValue()
	self:SetColor(self:GetDefaultColor())
	self:OnUserChanged(self.m_OutRGB)
end

function CUBE:Paint(w, h)
	-- Drawing the mask
    DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
        DUtils:DrawRect(0, 0, w, h, DUtils:UiColor(self.m_BaseRGB.r, self.m_BaseRGB.g, self.m_BaseRGB.b, 255))

        -- Draw gradients
	    -- DUtils:DrawGradient(0, 0, w, h, RIGHT, Color(255, 0, 0, 255))
	    DUtils:DrawGradient(0, 0, w, h, RIGHT, color_white)
	    DUtils:DrawGradient(0, 0, w, h, nil, Color(0, 0, 0, 255))
    end)
end

function CUBE:TranslateValues(x, y)
	self:UpdateColor(x, y)
	self:OnUserChanged(self.m_OutRGB)
	return x, y
end

function CUBE:UpdateColor(x, y)
    x = x or self:GetSlideX()
    y = y or self:GetSlideY()

    local value = 1 - y
    local saturation = 1 - x
    local h = _ColorToHSV(self.m_BaseRGB)
    local color = _HSVToColor(h, saturation, value)
    self:SetRGB(color)
end

function CUBE:OnUserChanged(color)
	-- Override me
end

function CUBE:SetColor(color)
	local h, s, v = _ColorToHSV(color)
	self:SetBaseRGB(_HSVToColor(h, 1, 1))
	self:SetSlideY(1 - v)
	self:SetSlideX(1 - s)
	self:UpdateColor()
end

function CUBE:SetBaseRGB(color)
	self.m_BaseRGB = color
	self:UpdateColor()
end

CUBE:SetBase('DanLib.UI.Slider')
CUBE:Register('DanLib.UI.ColorCube')



-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dcolorpalette.lua
--- Enhanced Color Palette with format-specific display
local function CreateColorTable(num_rows)
    local rows = num_rows or 8
    local index = 0
    local ColorTable = { }

    -- HSV bright colors
    for i = 0, rows * 2 - 1 do
        local col = round(min(i * (360 / (rows * 2)), 359))
        index = index + 1
        ColorTable[index] = _HSVToColor(360 - col, 1, 1)
    end

    -- HSV dark colors
    for i = 0, rows - 1 do
        local col = round(min(i * (360 / rows), 359))
        index = index + 1
        ColorTable[index] = _HSVToColor(360 - col, 1, 0.5)
    end

    -- HSV medium saturation
    for i = 0, rows - 1 do
        local col = round(min(i * (360 / rows), 359))
        index = index + 1
        ColorTable[index] = _HSVToColor(360 - col, 0.5, 0.5)
    end

    -- HSV high brightness
    for i = 0, rows - 1 do
        local col = min(i * (360 / rows), 359)
        index = index + 1
        ColorTable[index] = _HSVToColor(360 - col, 0.5, 1)
    end

    -- Grayscale gradient
    for i = 0, rows - 1 do
        local white = 255 - round(min(i * (256 / (rows - 1)), 255))
        index = index + 1
        ColorTable[index] = Color(white, white, white)
    end

    return ColorTable
end


local PALETTE, Constructor = DanLib.UiPanel()

AccessorFunc(PALETTE, 'm_buttonsize', 'ButtonSize', FORCE_NUMBER)
AccessorFunc(PALETTE, 'm_NumRows', 'NumRows', FORCE_NUMBER)
AccessorFunc(PALETTE, 'm_formatRGB', 'FormatRGB')

-- This stuff could be better
g_ColorPalettePanels = g_ColorPalettePanels or { }

function PALETTE:Init()
	-- self:SetTall(80, 120)
	self:SetNumRows(12)
	self:Reset()
	self:SetButtonSize(16)
	self:SetSpaceX(5)
	self:SetSpaceY(5)
	self:SetFormatRGB('RGB')
	DTable:Add(g_ColorPalettePanels, self)
end

-- This stuff could be better
function PALETTE:NetworkColorChange()
    for id, pnl in _pairs(g_ColorPalettePanels) do
        if (not _IsValid(pnl)) then 
            DTable:Remove(g_ColorPalettePanels, id) 
        end
    end

    for id, pnl in _pairs(g_ColorPalettePanels) do
        if (not _IsValid(pnl) or pnl == self) then
        	continue
        end
        
        local tab = { }
        for pid, p in _ipairs(self:GetChildren()) do
            tab[p:GetID()] = p:GetColor()
        end
        pnl:SetColorButtons(tab)
    end
end

function PALETTE:DoClick(color, button)
	-- Override
end

function PALETTE:Reset()
	self:SetColorButtons(CreateColorTable(self:GetNumRows()))
end

function PALETTE:PaintOver(w, h)
	local childW = 0
	for id, child in _ipairs(self:GetChildren()) do
		if (childW + child:GetWide() > w) then
			break
		end

		childW = childW + child:GetWide()
	end
end

-- Enhanced color button setup with format awareness
function PALETTE:SetColorButtons(tab)
    self:Clear()
    local formatRGB = self:GetFormatRGB()

    for i, color in _pairs(tab or { }) do
        local id = _tonumber(i)
        if (not id) then
        	break
        end
        
        local size = self:GetButtonSize()
        local button = DCustomUtils(self, 'DanLib.UI.ColorButton')
        
        button:SetSize(size or 10, size or 10)
        button:SetID(i)
        button:SetFormatRGB(formatRGB or 'RGB')
        button:SetColor(color or color_Error)
        button:ApplyEvent('DoClick', function(sl)
            local col = sl:GetColor() or color_Error
            self:OnValueChanged(col)
            self:DoClick(col, button)
        end)
    end
    
    self:InvalidateLayout()
end

function PALETTE:SetButtonSize(val)
	self.m_buttonsize = floor(val)
	for k, v in _ipairs(self:GetChildren()) do
		v:SetSize(self:GetButtonSize(), self:GetButtonSize())
	end
	self:InvalidateLayout()
end

function PALETTE:SaveColor(btn, color)
	color = DTable:Copy(color or color_Error)
	btn:SetColor(color)
	self:NetworkColorChange()
end

function PALETTE:SetColor(newcol)
    -- Mark selected color in palette
    for _, child in _ipairs(self:GetChildren()) do
        if (_IsValid(child) and child.GetColor) then
            local childCol = child:GetColor()
            if (childCol and childCol.r == newcol.r and childCol.g == newcol.g and childCol.b == newcol.b) then
                child:SetSelected(true)
            else
                child:SetSelected(false)
            end
        end
    end
end

function PALETTE:OnValueChanged(newcol)
    -- Override in parent
end

function PALETTE:OnRightClickButton(btn)
    -- Override in parent - can be used for color saving/management
end

PALETTE:SetBase('DIconLayout')
PALETTE:Register('DanLib.UI.ColorPalette')
