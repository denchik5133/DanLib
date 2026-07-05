/***
 *   @addon         DanLib
 *   @component     UI Binder
 *   @license       MIT License
 *   @version       1.0.0
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



local base = DanLib.Func
local utils = DanLib.Utils
local Table = DanLib.Table
local network = DanLib.Net
local customUtils = DanLib.CustomUtils
local PANEL = {}

AccessorFunc(PANEL, 'm_iSelectedNumber', 'SelectedNumber')
Derma_Install_Convar_Functions(PANEL)

function PANEL:Init()
	self:SetSelectedNumber(0)
	self:SetSize(60, 30)
	self:SetText('')
	self.isSelected = false
end

function PANEL:UpdateText()
	local str = input.GetKeyName(self:GetSelectedNumber())
	if (not str) then
		str = 'NONE'
	end

	str = language.GetPhrase(str)
	self.strText = str
end

function PANEL:DoClick()
	self.strText = base:L('#key.bind')
	input.StartKeyTrapping()
	self.Trapping = true
	self.isSelected = true
end

function PANEL:DoRightClick()
	self.strText = 'NONE'
	self:SetValue(0)
	self.isSelected = false
end

function PANEL:SetSelectedNumber(iNum)
	self.m_iSelectedNumber = iNum
	self:ConVarChanged(iNum)
	self:UpdateText()
	self:OnChange(iNum)
end

function PANEL:Think()
	if (input.IsKeyTrapping() && self.Trapping) then
		local code = input.CheckKeyTrapping()
		if code then
			if (code == KEY_ESCAPE) then
				self:SetValue(self:GetSelectedNumber())
			else
				self:SetValue(code)
			end

			self.Trapping = false
			self.isSelected = false
		end
	end
	self:ConVarNumberThink()
end

function PANEL:SetValue(iNumValue)
	self:SetSelectedNumber(iNumValue)
end

function PANEL:GetValue()
	return self:GetSelectedNumber()
end

function PANEL:OnChange(iNum)

end

function PANEL:Help()
	self:ApplyTooltip(base:L('#key.bind.help'), nil, nil, TOP)
end

-- Turning off shadows
function PANEL:DisableShadows(distance, noClip, iteration)
    self:ApplyShadow(distance or 10, noClip or false, iteration or 5)
    return self
end

function PANEL:Paint(w, h)
	self:ApplyAlpha(0.1, 255, false, false, self.isSelected, 155)

	local outColor = self.isSelected and base:Theme('decor', self.alpha) or base:Theme('frame')
    local textColor = self.isSelected and base:Theme('title', self.alpha) or base:Theme('text')

	utils:DrawRect(0, 0, w, h, base:Theme('decor_elements'))
	utils:OutlinedRect(0, 0, w, h, outColor)
	draw.SimpleText(string.upper(self.strText), 'danlib_font_18', w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

derma.DefineControl('DanLib.UI.Binder', '', PANEL, 'DButton')


function base.CreateUIBinder(parent)
	parent = parent or nil

	local binder = customUtils.Create(parent, 'DanLib.UI.Binder')
	return binder
end