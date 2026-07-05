/***
 *   @addon         DanLib
 *   @component     UI Slider
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
 *
 *	 @Source
 *					GitHub: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dslider.lua
 */


local KNOB, Constructor = DanLib.UiPanel()

AccessorFunc(KNOB, 'm_fSlideX', 'SlideX')
AccessorFunc(KNOB, 'm_fSlideY', 'SlideY')
AccessorFunc(KNOB, 'm_iLockX', 'LockX')
AccessorFunc(KNOB, 'm_iLockY', 'LockY')
AccessorFunc(KNOB, 'Dragging', 'Dragging')
AccessorFunc(KNOB, 'm_bTrappedInside', 'TrapInside')

function KNOB:Init()
	self:SetMouseInputEnabled(true)
	self:SetSlideX(0.5)
	self:SetSlideY(0.5)

	self.Knob = DanLib.CustomUtils.Create(self, 'DButton')
	self.Knob:SetText('')
	self.Knob:SetSize(15, 15)
	self.Knob:NoClipping(true)
	self.Knob.Paint = function(panel, w, h)
        local circleColor = panel.Hovered and DanLib.Utils:UiColor(0, 151, 230) or color_white
        DanLib.Utils:DrawMaterial(0, 0, w, h, circleColor, DanLib.Config.Materials['vCircle'])
    end
	self.Knob.OnCursorMoved = function(panel, x, y)
		x, y = panel:LocalToScreen(x, y)
		x, y = self:ScreenToLocal(x, y)
		self:OnCursorMoved(x, y)
	end

	self.Knob.OnMousePressed = function(panel, mcode)
		if (mcode == MOUSE_MIDDLE) then
			self:ResetToDefaultValue()
			return
		end
		DButton.OnMousePressed(panel, mcode)
	end

	-- Why is this set by default?
	self:SetLockY(0.5)
end

-- We we currently editing?
function KNOB:IsEditing()
	return self.Dragging or self.Knob.Depressed
end

function KNOB:ResetToDefaultValue()
	local x, y = self:TranslateValues(0.5, 0.5)
	self:SetSlideX(x)
	self:SetSlideY(y)
end

function KNOB:SetBackground(img)
	if (not self.BGImage) then self.BGImage = DanLib.CustomUtils.Create(self, 'DImage') end
	self.BGImage:SetImage(img)
	self:InvalidateLayout()
end

function KNOB:SetEnabled(b)
	self.Knob:SetEnabled(b)
	FindMetaTable('Panel').SetEnabled(self, b) -- There has to be a better way!
end

function KNOB:OnCursorMoved(x, y)
	if (not self.Dragging && not self.Knob.Depressed) then
		return
	end
	
	local w, h = self:GetSize()
	local iw, ih = self.Knob:GetSize()

	if self.m_bTrappedInside then
		w = w - iw
		h = h - ih
		x = x - iw * 0.5
		y = y - ih * 0.5
	end

	-- Limit x and y to within 0 and 1
	x = math.Clamp(x, 0, w) / w
	y = math.Clamp(y, 0, h) / h

	-- Apply constraints for SlideX and SlideY values
	if self.m_iLockX then x = self.m_iLockX end
	if self.m_iLockY then y = self.m_iLockY end

	x, y = self:TranslateValues(x, y)
	-- Set values subject to constraints
	self:SetSlideX(x) -- Limit the value of SlideX
	self:SetSlideY(y) -- Limit SlideY
	self:InvalidateLayout()
end

function KNOB:OnMousePressed(mcode)
	if (not self:IsEnabled()) then return true end

	-- When starting dragging with not pressing on the knob.
	self.Knob.Hovered = true
	self:SetDragging(true)
	self:MouseCapture(true)

	local x, y = self:CursorPos()
	self:OnCursorMoved(x, y)
end

function KNOB:OnMouseReleased(mcode)
	-- This is a hack. Panel.Hovered is not updated when dragging a panel (Source's dragging, not Lua Drag'n'drop)
	self.Knob.Hovered = vgui.GetHoveredPanel() == self.Knob
	self:SetDragging(false)
	self:MouseCapture(false)
end

function KNOB:PerformLayout()
	local w, h = self:GetSize()
	local iw, ih = self.Knob:GetSize()
	if self.m_bTrappedInside then
		w = w - iw
		h = h - ih
		self.Knob:SetPos((self.m_fSlideX or 0) * w, (self.m_fSlideY or 0) * h)
	else
		self.Knob:SetPos((self.m_fSlideX or 0) * w - iw * 0.5, (self.m_fSlideY or 0) * h - ih * 0.5)
	end

	if self.BGImage then
		self.BGImage:StretchToParent(0, 0, 0, 0)
		self.BGImage:SetZPos(-10)
	end

	-- In case m_fSlideX/m_fSlideY changed multiple times a frame, we do this here
	self:ConVarChanged(self.m_fSlideX, self.m_strConVarX)
	self:ConVarChanged(self.m_fSlideY, self.m_strConVarY)
end

function KNOB:Think()
	self:ConVarXNumberThink()
	self:ConVarYNumberThink()
end

function KNOB:SetSlideX(i)
	self.m_fSlideX = i
	self:OnValuesChangedInternal()
end

function KNOB:SetSlideY(i)
	self.m_fSlideY = i
	self:OnValuesChangedInternal()
end

function KNOB:GetDragging()
	return self.Dragging or self.Knob.Depressed
end

function KNOB:OnValueChanged(x, y)
	-- For override
end

function KNOB:OnValuesChangedInternal()
	self:OnValueChanged(self.m_fSlideX, self.m_fSlideY)
	self:InvalidateLayout()
end

function KNOB:TranslateValues(x, y)
	-- Give children the chance to manipulate the values..
	return x, y
end

-- ConVars
function KNOB:SetConVarX(strConVar)
	self.m_strConVarX = strConVar
end

function KNOB:SetConVarY(strConVar)
	self.m_strConVarY = strConVar
end

function KNOB:ConVarChanged(newValue, cvar)
	if (not cvar or cvar:len() < 2) then return end
	GetConVar(cvar):SetFloat(newValue)
	-- Prevent extra convar loops
	if (cvar == self.m_strConVarX) then self.m_strConVarXValue = GetConVarNumber(self.m_strConVarX) end
	if (cvar == self.m_strConVarY) then self.m_strConVarYValue = GetConVarNumber(self.m_strConVarY) end
end

function KNOB:ConVarXNumberThink()
	if (not self.m_strConVarX or #self.m_strConVarX < 2) then return end
	local numValue = GetConVarNumber( self.m_strConVarX)
	-- In case the convar is a 'nan'
	if (numValue != numValue) then return end
	if (self.m_strConVarXValue == numValue) then return end
	self.m_strConVarXValue = numValue
	self:SetSlideX(self.m_strConVarXValue)
end

function KNOB:ConVarYNumberThink()
	if (not self.m_strConVarY or #self.m_strConVarY < 2) then return end
	local numValue = GetConVarNumber(self.m_strConVarY)
	-- In case the convar is a 'nan'
	if (numValue != numValue) then return end
	if (self.m_strConVarYValue == numValue) then return end
	self.m_strConVarYValue = numValue
	self:SetSlideY(self.m_strConVarYValue)
end

-- Deprecated
AccessorFunc(KNOB, 'NumSlider', 'NumSlider')
AccessorFunc(KNOB, 'm_iNotches', 'Notches')

function KNOB:SetImage(strImage)
	-- RETIRED
end

function KNOB:SetImageColor(color)
	-- RETIRED
end

function KNOB:SetNotchColor(color)
	self.m_cNotchClr = color
end

function KNOB:GetNotchColor()
	return self.m_cNotchClr or self:GetSkin().colNumSliderNotch
end

KNOB:Register('DanLib.UI.Slider')
