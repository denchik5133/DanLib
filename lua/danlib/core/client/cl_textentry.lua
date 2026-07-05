/***
 *   @addon         DanLib
 *   @component     UI TextEntry
 *   @license       MIT License
 *   @version       1.8.2
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



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local INPUT = DanLib.UiPanel()
local DCustomUtils = DanLib.CustomUtils.Create

local _IsValid = IsValid
local _Clamp = math.Clamp
local _utf8len = utf8.len
local _ColorAlpha = ColorAlpha
local _SimpleText = draw.SimpleText

-- Initialises the text field with default settings.
function INPUT:Init()
    -- Inner DTextEntry
    self.textEntry = DCustomUtils(self, 'DTextEntry')
    self.textEntry:PinMargin(nil, 8, nil, 8)
    self.textEntry:SetFont('danlib_font_18')
    self.textEntry:SetText('')
    self.textEntry:SetTextColor(Color(255, 255, 255, 20))
    self.textEntry:SetCursorColor(Color(255, 255, 255))
    self.textEntry.backTextColor = DBase:Theme('text', 100)

    -- Custom paint for inner DTextEntry
    self.textEntry:ApplyClearPaint()
    self.textEntry:ApplyEvent(nil, function(sl, w, h)
        local textColor = sl:GetTextColor()
        if (textColor.a != 255 or textColor.a != 0) then
            sl:SetTextColor(DBase:Theme('text', 100 + (self.alpha or 0)))
        end

        sl:DrawTextEntryText(textColor, sl:GetHighlightColor(), sl:GetCursorColor())
        if (not sl:IsEditing() and sl:GetText() == '') then
            _SimpleText(sl.backText or '', sl:GetFont(), 0, h / 2, sl.backTextColor, 0, TEXT_ALIGN_CENTER)
        end
    end)

    -- Forward inner events to the outer INPUT panel so callers can do:
    --   entry.OnChange = function(sl) ... end
    self.textEntry.OnChange  = function()
        if self.OnChange then
            self:OnChange()
        end
    end

    self.textEntry.OnEnter = function()
        if self.OnEnter then
            self:OnEnter()
        end
    end

    self.textEntry.OnGetFocus = function()
        if self.OnGetFocus then
            self:OnGetFocus()
        end
    end

    self.textEntry.OnLoseFocus = function()
        if self.OnLoseFocus then
            self:OnLoseFocus()
        end
    end
end

--- Sets an optional icon to display on the left side of the field.
-- @param strIcon (string): Icon material key.
-- @param iSize (number): Icon size in pixels (default 16).
-- @return self
function INPUT:SetIcon(strIcon, iSize)
    if _IsValid(self.icon) then
        self.icon:Remove()
    end

    self.icon = DCustomUtils(self)
    self.icon:SetMouseInputEnabled(false)
    self.icon.size = iSize or 16

    self.icon:ApplyEvent(nil, function(sl, w, h)
        DUtils:DrawIconOrMaterial(w * 0.5 - sl.size * 0.5, h * 0.5 - sl.size * 0.5, sl.size, strIcon, DBase:Theme('mat', 150))
    end)

    self.textEntry:PinMargin(nil, 30, nil, 8)
    self:InvalidateLayout()
    return self
end

-- Positions the icon (if present).
function INPUT:PerformLayout(w, h)
    if _IsValid(self.icon) then
        self.icon:SetPos(5, 5)
        self.icon:SetSize(h - 10, h - 10)
    end
end

-- Paints the text field background, border, and optional character counter.
function INPUT:Paint(w, h)
    local is_editing = self.textEntry:IsEditing()
    self:ApplyAlpha(0.1, 155, false, false, is_editing, 155)
    self.hoverPercent = is_editing and _Clamp((self.hoverPercent or 0) + 5, 0, 100) or  _Clamp((self.hoverPercent or 0) - 5, 0, 100)
    local hp = self.hoverPercent / 100

    DUtils:DrawRect(0, 0, w, h, DBase:Theme('decor_elements'))
    DUtils:OutlinedRect(0, 0, w, h, DBase:Theme('frame'))
    DUtils:OutlinedRect(0, 0, w, h, self.verification and DBase:GetColor('Red', hp * 100) or  DBase:Theme('decor', hp * 100))

    if self.max then
        local remaining = self.max - (_utf8len(self:GetValue()) or 0)
        local countColor = (remaining <= 0) and DBase:GetColor('Red', 150) or DBase:Theme('text', 150)
        _SimpleText(remaining, 'danlib_font_16', w - 4, 10, countColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

function INPUT:RequestFocus()
    if _IsValid(self.textEntry) then
        return self.textEntry:RequestFocus()
    end
    return false
end

function INPUT:IsEditing()
    return self.textEntry:IsEditing()
end

function INPUT:SetValue(val)
    self.textEntry:SetValue(val)
end

function INPUT:GetValue()
    return self.textEntry:GetValue()
end

-- Sets the placeholder text shown when the field is empty.
function INPUT:SetBackText(backText)
    self.textEntry.backText = backText
    return self
end

function INPUT:SetPlaceholderText(backText)
    self.textEntry.backText = backText
    return self
end

function INPUT:SetBackColor(color)
    self.backColor = color
    return self
end

function INPUT:SetHighlightColor(color)
    self.highlightColor = color
    self.textEntry:SetHighlightColor(color)
    return self
end

function INPUT:SetFont(font)
    self.textEntry:SetFont(font)
    return self
end

function INPUT:SetEnabled(enabled)
    self.textEntry:SetEnabled(enabled)
    return self
end

function INPUT:SetMultiline(enabled)
    self.textEntry:SetMultiline(enabled)
end

function INPUT:SetUpdateOnType(enabled)
    self.textEntry:SetUpdateOnType(enabled)
    return self
end

-- Highlights the border red when true.
function INPUT:SetVerification(verification)
    self.verification = verification
    return self
end

function INPUT:DisableShadows(distance, noClip, iteration)
    self:ApplyShadow(distance or 10, noClip or false, iteration or 5)
    return self
end

-- Limits input length and shows a live counter in the top-right corner.
function INPUT:SetMaxChar(max)
    self.max = max
    self.textEntry.AllowInput = function(sl, char)
        local currentLen = _utf8len(sl:GetValue()) or 0
        if (currentLen >= max and char ~= nil and char ~= '') then
            return true
        end
        return false
    end
end

function INPUT:OnChange() end
function INPUT:OnEnter() end
function INPUT:OnGetFocus() end
function INPUT:OnLoseFocus() end

INPUT:Register('DanLib.UI.Input')

--- Creates a new DanLib.UI.Input instance.
-- @param parent (Panel):  Parent panel.
-- @param strIcon (string): Optional icon shown on the left.
-- @param iSize (number): Icon size in pixels (default 16).
-- @return DanLib.UI.Input
function DBase.CreateTextEntry(parent, strIcon, iSize)
    local entry = DCustomUtils(parent, 'DanLib.UI.Input')
    if strIcon then
        entry:SetIcon(strIcon, iSize)
    end
    return entry
end
