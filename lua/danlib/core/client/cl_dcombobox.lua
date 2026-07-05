/***
 *   @addon         DanLib
 *   @component     UI ComboBox
 *   @license       MIT License
 *   @version       1.4.1
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Customizable ComboBox (dropdown) component for DanLib UI framework.
 *                  Provides a dropdown selection menu with support for icons, custom fonts,
 *                  sorting, and smooth animations. Only one menu can be open at a time.
 *
 *   @features      
 *                  - Single active menu enforcement (closes other ComboBoxes)
 *                  - Customizable text direction and alignment
 *                  - Icon support for options
 *                  - Smooth rotation animation for dropdown indicator
 *                  - Sortable options
 *                  - Custom font support
 *
 *   @usage         
 *                  local combo = DBase.CreateUIComboBox(parent)
 *                  combo:AddChoice('Option 1', 1, true)
 *                  combo:SetDirection(true)
 *                  combo:SetFont('danlib_font_18')
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DTable = DanLib.Table
local DUtils = DanLib.Utils
local DCustomUtils = DanLib.CustomUtils.Create

-- Cached global functions for performance
local _IsValid = IsValid
local _pairs = pairs
local _max = math.max
local _min = math.min
local _Lerp = Lerp
local _stringlen = string.len
local _tostring = tostring
local _isnumber = isnumber
local _tonumber = tonumber
local _FrameTime = FrameTime
local _SimpleText = draw.SimpleText

-- Global tracker for currently open ComboBox (ensures only one menu is open at a time)
local ActiveComboBox = nil

local COMBOBOX = DanLib.UiPanel()

-- Defining an accessor for sorting items
COMBOBOX:Accessor('SortItems', COMBOBOX.Boolean, {
    default = true
})

--- Initializes the ComboBox with default settings.
function COMBOBOX:Init()
    self:SetTall(22)
    self:Clear()
    self:SetText('')
    self:SetContentAlignment(4)
    self:SetTextInset(8, 0)
    self:SetIsMenu(true)
    self.iconAngle = 0
end

--- Clears all choices and resets the ComboBox to default state.
function COMBOBOX:Clear()
    self:SetText('')
    self.Choices = { }
    self.Data = { }
    self.ChoiceIcons = { }
    self.Spacers = { }
    self.selected = nil
    self:CloseMenu()
end

--- Gets the display text for an option by index.
-- @param index (number): The index of the option.
-- @return (string): The display text of the option.
function COMBOBOX:GetOptionText(index)
    return self.Choices[index]
end

--- Gets the associated data for an option by index.
-- @param index (number): The index of the option.
-- @return (any): The data associated with the option.
function COMBOBOX:GetOptionData(index)
    return self.Data[index]
end

--- Handles layout updates.
-- @param w (number): Width of the panel.
-- @param h (number): Height of the panel.
function COMBOBOX:PerformLayout(w, h)
    DButton.PerformLayout(self, w, h)
end

--- Selects an option by value and index.
-- @param value (string): The display text of the option.
-- @param index (number): The index of the option.
function COMBOBOX:ChooseOption(value, index)
    self:CloseMenu()
    self.text = value
    self.selected = index
    self:OnSelect(index, value, self.Data[index])
end

--- Selects an option by its index.
-- @param index (number): The index of the option to select.
function COMBOBOX:ChooseOptionID(index)
    local value = self:GetOptionText(index)
    self:ChooseOption(value, index)
end

--- Gets the index of the currently selected option.
-- @return (number): The index of the selected option, or nil if none selected.
function COMBOBOX:GetSelectedID()
    return self.selected
end

--- Gets the text and data of the currently selected option.
-- @return (string, any): The display text and associated data, or nil if none selected.
function COMBOBOX:GetSelected()
    if (not self.selected) then
        return
    end
    return self:GetOptionText(self.selected), self:GetOptionData(self.selected)
end

--- Called when an option is selected. Override this for custom behavior.
-- @param index (number): The index of the selected option.
-- @param value (string): The display text of the selected option.
-- @param data (any): The data associated with the selected option.
function COMBOBOX:OnSelect(index, value, data)
    -- For override
end

--- Called when the dropdown menu is opened. Override this for custom behavior.
-- @param menu (Panel): The menu panel that was opened.
function COMBOBOX:OnMenuOpened(menu)
    -- For override
end

--- Adds a visual spacer after the last added choice.
function COMBOBOX:AddSpacer()
    self.Spacers[#self.Choices] = true
end

--- Adds a choice to the ComboBox.
-- @param value (string): The display text for the choice.
-- @param data (any): Optional data to associate with the choice.
-- @param select (boolean): Whether to select this choice immediately.
-- @param icon (string): Optional icon material name for the choice.
-- @return (number): The index of the added choice.
function COMBOBOX:AddChoice(value, data, select, icon)
    local index = DTable:Add(self.Choices, value)

    if data then
        self.Data[index] = data
    end

    if icon then
        self.ChoiceIcons[index] = icon
    end

    if select then
        self:ChooseOption(value, index)
    end
    return index
end

--- Removes a choice from the ComboBox by index.
-- @param index (number): The index of the choice to remove.
-- @return (string, any): The removed choice's text and data.
function COMBOBOX:RemoveChoice(index)
    if (not _isnumber(index)) then
        return
    end

    local text = DTable:Remove(self.Choices, index)
    local data = DTable:Remove(self.Data, index)
    return text, data
end

--- Checks if the dropdown menu is currently open.
-- @return (boolean): True if the menu is open and visible.
function COMBOBOX:IsMenuOpen()
    return _IsValid(self.Menu) and self.Menu:IsVisible()
end

function COMBOBOX:AddPlayerChoice(pPlayer, select)
    if (not IsValid(pPlayer)) then
        return
    end
    
    local index = #self.Choices + 1
    
    -- Сохраняем данные игрока
    self.Choices[index] = pPlayer:Nick()
    self.Data[index] = pPlayer
    self.ChoiceIcons[index] = 'avatar://' .. pPlayer:SteamID64() -- Специальный формат
    
    -- Флаг для кастомного рендера
    self.CustomRender = self.CustomRender or { }
    self.CustomRender[index] = 'player'
    
    if select then
        self:ChooseOption(pPlayer:Nick(), index)
    end
    
    return index
end

--- Opens the dropdown menu with all available choices.
-- @param pControlOpener (Panel): The control that triggered the opening (internal use).
function COMBOBOX:OpenMenu(pControlOpener)
    if (pControlOpener and pControlOpener == self.TextEntry) then
        return
    end

    if (#self.Choices == 0) then
        return
    end

    -- Close any other open ComboBox
    if (_IsValid(ActiveComboBox) and ActiveComboBox ~= self) then
        ActiveComboBox:CloseMenu()
    end

    self:CloseMenu()
    ActiveComboBox = self

    -- Find modal parent if exists
    local parent = self
    while _IsValid(parent) and not parent:IsModal() do
        parent = parent:GetParent()
    end

    if (not _IsValid(parent)) then
        parent = self
    end

    self.Menu = DBase:UIContextMenu(parent)
    self.iconAngle = 180
    
    -- Reset icon angle when menu is removed
    self.Menu.OnRemove = function()
        self.iconAngle = 0
        if (ActiveComboBox == self) then
            ActiveComboBox = nil
        end
    end

    if self:GetSortItems() then
        local sorted = { }
        for k, v in _pairs(self.Choices) do
            local val = _tostring(v)
            if (_stringlen(val) > 1 and not _tonumber(val) and val:StartsWith('#')) then
                val = language.GetPhrase(val:sub(2))
            end

            DTable:Add(sorted, {
                id = k,
                data = v,
                label = val
            })
        end

        for k, v in SortedPairsByMemberValue(sorted, 'label') do
            self.Menu:Option(v.data, nil, self.ChoiceIcons[v.id], function()
                self:ChooseOption(v.data, v.id)
            end)

            if self.Spacers[v.id] then
                -- Reserved for future spacer implementation
            end
        end
    else
        for k, v in _pairs(self.Choices) do
            self.Menu:Option(v, nil, self.ChoiceIcons[k], function()
                self:ChooseOption(v, k)
            end)

            if self.Spacers[k] then
                -- Reserved for future spacer implementation
            end
        end
    end

    local x, y = self:LocalToScreen(0, self:GetTall())
    self.Menu:SetMinimumWidth(self:GetWide())
    self.Menu:Open(x, y + 2, false, self)
    self:OnMenuOpened(self.Menu)
end

--- Closes the dropdown menu if it's open.
function COMBOBOX:CloseMenu()
    if _IsValid(self.Menu) then
        self.Menu:Remove()
    end
    self.Menu = nil
    self.iconAngle = 0
end

--- Sets the text alignment direction.
-- @param d (boolean): True for left-aligned text with right icon, false for centered text.
-- @return (Panel): Returns self for method chaining.
function COMBOBOX:SetDirection(d)
    self.Direction = d
    return self
end

--- Sets the font for the ComboBox text.
-- @param font (string): The font name to use.
-- @return (Panel): Returns self for method chaining.
function COMBOBOX:SetFont(font)
    self.setFont = font
    return self
end

--- Sets the displayed value/text of the ComboBox.
-- @param strValue (string): The text to display.
function COMBOBOX:SetValue(strValue)
    self.text = strValue
end

--- Handles click events on the ComboBox.
function COMBOBOX:DoClick()
    if self:IsMenuOpen() then
        return self:CloseMenu()
    end
    self:OpenMenu()
end

--- Applies shadow effect to the ComboBox.
-- @param distance (number): Shadow distance (default: 10).
-- @param noClip (boolean): Whether to disable clipping (default: false).
-- @param iteration (number): Number of shadow iterations (default: 5).
-- @return (Panel): Returns self for method chaining.
function COMBOBOX:DisableShadows(distance, noClip, iteration)
    self:ApplyShadow(distance or 10, noClip or false, iteration or 5)
    return self
end

--- Renders the ComboBox with all visual elements.
-- @param w (number): Width of the panel.
-- @param h (number): Height of the panel.
function COMBOBOX:Paint(w, h)
    self:ApplyAlpha(0.1, 155, false, false, self:IsMenuOpen(), 155)

    -- Smooth hover animation
    self.hover = self:IsMenuOpen() and _min((self.hover or 0) + 5, 100) or _max((self.hover or 0) - 5, 0)
    local hover = self.hover / 100

    -- Draw background and borders
    DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('decor_elements'))
    DUtils:OutlinedRect(0, 0, w, h, DBase:Theme('frame'))
    DUtils:OutlinedRect(0, 0, w, h, DBase:Theme('decor', hover * 100))

    -- Draw icon if set
    local x = 10
    if self.setIcon then
        local iconSize = DBase:Scale(30)
        DUtils:DrawIconOrMaterial(h * 0.5 - iconSize * 0.5, h * 0.5 - iconSize * 0.5, iconSize, self.setIcon, DBase:Theme('mat', 75 + self.alpha))
        x = x + 20
    end

    -- Draw dropdown arrow with smooth rotation
    if self.Direction then
        local sz = 16
        self.deg = _Lerp(_FrameTime() * 15, self.deg or 0, self.iconAngle)
        DUtils:DrawIconRotated(w - sz - 5, h / 2, sz, sz, self.deg, DanLib.Config.Materials['Arrow'], DBase:Theme('decor', 100 + self.alpha))
    end

    -- Draw text
    local text = self.text or DBase:L('#no.data')
    local font = self.setFont or 'danlib_font_18'
    _SimpleText(text, font, self.Direction and x or w * 0.5, h * 0.5, DBase:Theme('text', 100 + self.alpha), self.Direction and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

COMBOBOX:SetBase('DButton')
COMBOBOX:Register('DanLib.UI.ComboBox')

--- Creates a new ComboBox instance.
-- @param parent (Panel): The parent panel to attach the ComboBox to.
-- @return (Panel): The created ComboBox panel.
function DBase.CreateUIComboBox(parent)
    parent = parent or nil
    local ComboBox = DCustomUtils(parent, 'DanLib.UI.ComboBox')
    return ComboBox
end
