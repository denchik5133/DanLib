/***
 *   @addon         DanLib
 *   @component     UI ContextMenu
 *   @license       MIT License
 *   @version       2.2.0
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
 


local DUtils = DanLib.Utils
local DBase = DanLib.Func
local DCustomUtils = DanLib.CustomUtils.Create

-- Cache frequently used functions for better performance
local isstring = isstring
local math = math
local max = math.max
local min = math.min
local Clamp = math.Clamp

-- Cache common values
local BUTTON_HEIGHT = 32
local ICON_SIZE = 18
local TEXT_INSET_WITH_ICON = 42
local TEXT_INSET_DEFAULT = 16
local ICON_MARGIN = 8
local ICON_PADDING = 6
local BUTTON_WIDTH_PADDING = 10

local CONTEXT = DanLib.UiPanel()

-- Setting access methods for different properties
AccessorFunc(CONTEXT, 'sOpenSubMenu', 'OpenSubMenu')
AccessorFunc(CONTEXT, 'sDeleteSelf', 'DeleteSelf')
AccessorFunc(CONTEXT, 'sMinimumWidth', 'MinimumWidth')
AccessorFunc(CONTEXT, 'sMaxHeight', 'MaxHeight')

function CONTEXT:Init()
    self:SetIsMenu(true)
    self:SetDrawOnTop(true)
    self:SetDeleteSelf(true)
    self:SetVisible(false)
    self:SetMinimumWidth(DUtils:ScaleWide(120))
    self:SetMaxHeight(DUtils:ScaleTall(300))
    self:CustomUtils()
    self:ApplyAttenuation(0.2)
    -- Create internal DScrollPanel with 4px margins
    self.ScrollPanel = DCustomUtils(self, 'DanLib.UI.Scroll')
    self.ScrollPanel:PinMargin(FILL, nil, 4, nil, 4)
    -- Setting the width of the vertical bar
    self.ScrollPanel:ToggleScrollBar()

    RegisterDermaMenuForClose(self)
end

-- Add compatibility methods to delegate scroll panel functionality
function CONTEXT:GetVBar()
    return self.ScrollPanel:GetVBar()
end

function CONTEXT:GetCanvas()
    return self.ScrollPanel:GetCanvas()
end

function CONTEXT:AddItem(item)
    return self.ScrollPanel:AddItem(item)
end

-- Mouse wheel handling for margins
function CONTEXT:OnMouseWheeled(delta)
    return self.ScrollPanel:OnMouseWheeled(delta)
end

-- Additional compatibility methods
function CONTEXT:ScrollToChild(child)
    return self.ScrollPanel:ScrollToChild(child)
end

function CONTEXT:ScrollToTop()
    return self.ScrollPanel:ScrollToTop()
end

-- Helper function for common layout operations
-- @param element The element to layout
-- @param strIcon Whether element has an icon
local function PerformCommonLayout(element, strIcon)
    element:SizeToContents()
    element:SetWide(element:GetWide() + BUTTON_WIDTH_PADDING)

    if strIcon then
        local h = element:GetTall()
        element.icon:SetPos(ICON_MARGIN, ICON_PADDING)
        element.icon:SetSize(h - BUTTON_WIDTH_PADDING, h - BUTTON_WIDTH_PADDING)
    end

    local parentWidth = element:GetParent():GetWide()
    element:SetSize(max(parentWidth, element:GetWide()), BUTTON_HEIGHT)
end

-- Adds a panel to the menu
-- @param pnl (Panel) The panel to be added
function CONTEXT:AddPanel(pnl)
    self.ScrollPanel:AddItem(pnl)
    pnl.ParentMenu = self
end

-- Add a divider to the menu
function CONTEXT:AddDivider()
    local divider = DCustomUtils(self.ScrollPanel)
    divider:SetTall(1)
    divider:ApplyBackground(DBase:Theme('line_up'))
    self:AddPanel(divider)
    return divider
end

-- Creates a sub-option button in the menu
-- @param strText (string) The text to display on the button
-- @param strColor (string) The color of the button text
-- @param strIcon (string) The icon to display on the button
-- @return button (Button) The created button
function CONTEXT:CreateOption(strText, strColor, strIcon)
    local con = self
    strText = strText or DBase:L('#no.data')
    strColor = strColor or DBase:Theme('title')

    local button = DBase:CreateButton(self.ScrollPanel, strText, 'danlib_font_18', strColor)
    button:SetContentAlignment(4)
    button:SetTextInset(strIcon and TEXT_INSET_WITH_ICON or TEXT_INSET_DEFAULT, 0)
    button:PinMargin(TOP)

    -- Create icon for the button if provided
    if strIcon then
        button.icon = DCustomUtils(button)
        button.icon:SetMouseInputEnabled(false)
        button.icon.Size = 18
        button.icon:ApplyEvent(nil, function(_, w, h)
            local iconSize = button.icon.Size
            DUtils:DrawIconOrMaterial(w * 0.5 - iconSize * 0.5, h * 0.5 - iconSize * 0.5, iconSize, strIcon, strColor)
        end)
    end

    -- Set submenu for the button
    function button:SetSubMenu(menu)
        self.SubMenu = menu
    end

    -- Create a sub-option
    function button:SubOption()
        local menu = DCustomUtils(nil, 'DanLib.UI.ContextMenu')
        menu:SetVisible(false)
        menu:SetParent(self)
        self:SetSubMenu(menu)
        return menu
    end

    -- Handle cursor hover
    function button:OnCursorEntered()
        local parentMenu = IsValid(self.ParentMenu) and self.ParentMenu or self:GetParent()
        parentMenu:OpenSubMenu(self, self.SubMenu)
    end

    -- Draw the button
    function button:Paint(w, h)
        self:ApplyAlpha(0.3, 255)
        DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('dmenu_hover', self.alpha))
        self:SetTextColor(strColor)
    end

    -- Handle mouse click
    function button:OnMousePressed(mousecode)
        self.m_MenuClicking = true
        DButton.OnMousePressed(self, mousecode)
    end

    function button:OnMouseReleased(mousecode)
        DButton.OnMouseReleased(self, mousecode)
        if (self.m_MenuClicking and mousecode == MOUSE_LEFT) then
            self.m_MenuClicking = false
            CloseDermaMenus()
        end
    end

    -- Button layout
    function button:PerformLayout(w, h)
        self:SizeToContents()
        self:SetWide(self:GetWide() + 10)

        if strIcon then
            self.icon:SetPos(8, 6)
            self.icon:SetSize(h - 10, h - 10)
        end

        local parentWidth = self:GetParent():GetWide()
        self:SetSize(max(parentWidth, self:GetWide()), 32)
        DButton.PerformLayout(self, w, h)
    end

    return button
end

-- Creates a checkbox element in the menu (as button with checkbox as left icon)
-- @param strText (string) The text to display next to the checkbox
-- @param strColor (string) The color of the text
-- @param bChecked (boolean) Initial checked state
-- @return button (Button) The created button with checkbox functionality
function CONTEXT:CreateCheckBox(strText, strColor, bChecked)
    strText = strText or DBase:L('#no.data')
    strColor = strColor or DBase:Theme('title')
    bChecked = bChecked or false

    -- Create button like Option, but with checkbox as icon
    local button = DBase:CreateButton(self.ScrollPanel, strText, 'danlib_font_18', strColor)
    button:SetContentAlignment(4)
    button:SetTextInset(TEXT_INSET_WITH_ICON - 6, 0)
    button:PinMargin(TOP)
    
    -- Store checkbox state
    button.checked = bChecked
    
    -- Create actual checkbox as "icon" using DanLib.Func.CreateCheckbox
    button.checkbox = DBase.CreateCheckbox(button)
    button.checkbox:SetMouseInputEnabled(false)
    button.checkbox:SetValue(bChecked)
    button.checkbox:SetText('')  -- No text on checkbox itself

    -- Toggle checkbox function
    function button:ToggleCheckBox()
        self.checked = not self.checked
        self.checkbox:SetValue(self.checked)
        if self.OnChange then
            self:OnChange(self.checked and 1 or 0)
        end
    end
    
    -- Get checkbox state
    function button:GetChecked()
        return self.checked
    end
    
    -- Set checkbox state
    function button:SetChecked(checked)
        self.checked = checked
        self.checkbox:SetValue(checked)
    end

    -- Handle cursor hover
    function button:OnCursorEntered()
        local parentMenu = IsValid(self.ParentMenu) and self.ParentMenu or self:GetParent()
        if parentMenu.OpenSubMenu then
            parentMenu:OpenSubMenu(self, nil) -- Close any open submenus
        end
    end

    -- Draw the button
    function button:Paint(w, h)
        self:ApplyAlpha(0.3, 255)
        DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('dmenu_hover', self.alpha))
        self:SetTextColor(strColor)
    end

    -- Handle mouse click
    function button:OnMousePressed(mousecode)
        self.m_MenuClicking = true
        DButton.OnMousePressed(self, mousecode)
    end

    function button:OnMouseReleased(mousecode)
        DButton.OnMouseReleased(self, mousecode)
        if (self.m_MenuClicking and mousecode == MOUSE_LEFT) then
            self.m_MenuClicking = false
            self:ToggleCheckBox()
            -- Don't close menu for checkboxes to allow multiple selections
        end
    end

    -- Button layout
    function button:PerformLayout(w, h)
        self:SizeToContents()
        self:SetWide(self:GetWide() + BUTTON_WIDTH_PADDING)

        -- Position checkbox as "icon" using DanLib checkbox size
        local checkboxSize = DBase:Scale(28) or 30
        self.checkbox:SetPos(ICON_MARGIN, (h - checkboxSize) * 0.5)
        self.checkbox:SetSize(checkboxSize, checkboxSize)

        local parentWidth = self:GetParent():GetWide()
        self:SetSize(max(parentWidth, self:GetWide()), BUTTON_HEIGHT)
        DButton.PerformLayout(self, w, h)
    end

    return button
end

-- Adds an option to the menu
-- @param strText (string) The text to display on the button
-- @param strColor (string) The color of the button text
-- @param strIcon (string) The icon to display on the button
-- @param onClick (function) The function to call when the button is clicked
-- @return self (CONTEXT) The panel
-- @return pnl (Button) The created button
function CONTEXT:Option(strText, strColor, strIcon, onClick)
    local pnl = self:CreateOption(strText, strColor, strIcon)
    if onClick then
        pnl:ApplyEvent('DoClick', onClick)
    end
    self:AddPanel(pnl)
    return self, pnl
end

-- Adds a sub-option to the menu
-- @param strText (string) The text to display on the button
-- @param strColor (string) The color of the button text
-- @param strIcon (string) The icon to display on the button
-- @param onClick (function) The function to call when the button is clicked
-- @return SubMenu (CONTEXT) The created submenu
-- @return pnl (Button) The created button
function CONTEXT:SubOption(strText, strColor, strIcon, onClick)
    local pnl = self:CreateOption(strText, strColor, strIcon)
    local SubMenu = pnl:SubOption(strText, funcFunction)
    if onClick then
        pnl:ApplyEvent('DoClick', onClick)
    end
    self:AddPanel(pnl)
    return SubMenu
end

-- Adds a checkbox to the menu
-- @param strText (string) The text to display next to the checkbox
-- @param strColor (string) The color of the text
-- @param bChecked (boolean) Initial checked state
-- @param onChanged (function) The function to call when checkbox state changes (receives button, checked state)
-- @return self (CONTEXT) The panel
-- @return button (Button) The created button with checkbox functionality
function CONTEXT:CheckBox(strText, strColor, bChecked, onChanged)
    local button = self:CreateCheckBox(strText, strColor, bChecked)
    if onChanged then
        function button:OnChange(val)
            onChanged(self, val == 1)
        end
    end
    self:AddPanel(button)
    return self, button
end

-- Hides the menu
function CONTEXT:Hide()
    local openmenu = self:GetOpenSubMenu()
    if openmenu then
        openmenu:Hide()
    end
    self:SetVisible(false)
    self:SetOpenSubMenu(nil)
end

-- Opens a submenu
-- @param item (Panel) The item that triggered the submenu
-- @param menu (CONTEXT) The submenu to open
function CONTEXT:OpenSubMenu(item, menu)
    -- Close the currently open submenu if it exists and does not match the new one
    local openmenu = self:GetOpenSubMenu()
    if IsValid(openmenu) then
        if (openmenu == menu) then
            return
        end
        self:CloseSubMenu(openmenu)
    end

    -- Check if the menu is valid
    if (not IsValid(menu)) then
        return
    end

    -- Open a new submenu
    local x, y = item:LocalToScreen(self:GetWide() + 4, 0)
    menu:Open(x, y, item)
    self:SetOpenSubMenu(menu)
end

-- Closes a submenu
-- @param menu (CONTEXT) The submenu to close
function CONTEXT:CloseSubMenu(menu)
    if IsValid(menu) then
        menu:Hide()
        self:SetOpenSubMenu(nil)
    end
end

-- Draws the panel
-- @param w (number) The width of the panel
-- @param h (number) The height of the panel
function CONTEXT:Paint(w, h)
    DanLib.DrawShadow:Begin()
    local x, y = self:LocalToScreen()
    DUtils:DrawRoundedBox(x, y, w, h, DBase:Theme('dmenu'))
    DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
end

-- Arranges elements in the panel
-- @param w (number) The width of the panel
-- @param h (number) The height of the panel
function CONTEXT:PerformLayout(w, h)
    local minWidth = self:GetMinimumWidth()
    local maxHeight = self:GetMaxHeight()
    local totalHeight = 0

    for _, v in ipairs(self.ScrollPanel:GetCanvas():GetChildren()) do
        v:InvalidateLayout(true)
        minWidth = max(minWidth, v:GetWide())
    end

    self:SetWide(minWidth)

    for _, v in ipairs(self.ScrollPanel:GetCanvas():GetChildren()) do
        v:SetWide(minWidth)
        v:SetPos(0, totalHeight)
        v:InvalidateLayout(true)
        totalHeight = totalHeight + v:GetTall()
    end

    totalHeight = min(totalHeight + 8, maxHeight)
    self:SetTall(totalHeight)
    -- Ensure scroll panel layout is updated after parent sizing
    self.ScrollPanel:InvalidateLayout(true)
end

-- Opens the menu
-- @param x (number) The x-coordinate to open the menu at
-- @param y (number) The y-coordinate to open the menu at
function CONTEXT:Open(x, y)
    RegisterDermaMenuForClose(self)

    local manual = x and y
    x = x or gui.MouseX()
    y = y or gui.MouseY()

    self:InvalidateLayout(true)

    local w, h = self:GetWide(), self:GetTall()
    self:SetSize(w, h)

    -- Adjust coordinates to fit within screen boundaries
    y = (y + h > ScrH()) and (manual and ScrH() or y - h) or y
    x = (x + w > ScrW()) and (manual and ScrW() or x - w) or x
    y = max(y, 1)
    x = max(x, 1)

    -- Adjust position for modal parent
    local p = self:GetParent()
    if IsValid(p) and p:IsModal() then
        x, y = p:ScreenToLocal(x, y)
        y = min(y, p:GetTall() - h)
        x = min(x, p:GetWide() - w)
        y = max(y, 1)
        x = max(x, 1)
    end

    self:SetPos(x, y)
    self:MakePopup()
    self:SetVisible(true)
    self:SetKeyboardInputEnabled(true)
end

CONTEXT:SetBase('DPanel')
CONTEXT:Register('DanLib.UI.ContextMenu')

-- Creates a UI context menu
-- @param parent (Panel) The parent panel for the context menu
-- @return context (PANEL) The created context menu
function DBase:UIContextMenu(parent)
    parent = parent or nil
    local context = DCustomUtils(parent, 'DanLib.UI.ContextMenu')
    context:SetParent(parent)
    return context
end






if IsValid(contextFrame) then
    contextFrame:Remove()
end

local function contextTest()
    if IsValid(contextFrame) then
        contextFrame:Remove()
    end

    local frame = DBase.CreateUIFrame()
    contextFrame = frame
    frame:SetTitle('Demo DanLib.UI.ContextMenu')
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()

    local button = DBase.CreateUIButton(frame, {
        dock = { FILL },
        background = { nil },
        hover = { nil },
        -- hoverClick = { nil },
        click = function(sl)
            local menu = DBase:UIContextMenu()

            menu:Option('Text test', Color(23, 70, 200), nil, function() 
                print('Text test')
            end)

            menu:AddDivider()

            local snap = menu:SubOption('Elements', nil, nil, function()
                print('Text test 2')
            end)
            local snap2 = snap:SubOption('Scroll', Color(255, 0, 0), nil, function()
                print('Scroll')
            end)

            for i = 1, 20 do
                snap2:Option('Nember #' .. i, nil, 'fqgaszu', function()
                    print('Text test 3')
                end)
            end

            local snap2 = snap:SubOption('CheckBox', Color(255, 0, 0), nil, function()
                print('Scroll')
            end)

            for i = 1, 8 do
                -- Checkboxes
                snap2:CheckBox('Enable Feature ' .. i, Color(0, 150, 0), false, function(checkbox, checked)
                    print('Feature '  .. i .. 'toggled:', checked)
                end)
            end

            menu:AddDivider()

            menu:Option('Text test 3', Color(0, 255, 0), nil, function()
                print('Text test 3')
            end)

            local snap2 = menu:SubOption('Text test 4', nil, nil, function()
                print('Text test 4')
            end)
            local subsnap = snap2:SubOption('Text sub test 4', Color(255, 110, 0), nil, function()
                print('Text sub test 4')
            end)
            subsnap:Option('Text sub test 2', Color(255, 0, 0), nil, function()
                print('Text sub test 3')
            end)
            
            menu:Open()
        end
    })
end
-- contextTest()
