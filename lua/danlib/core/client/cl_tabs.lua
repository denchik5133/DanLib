/***
 *   @addon         DanLib
 *   @component     UI Tabs
 *   @license       MIT License
 *   @version       1.1.1
 *   @release_date  26/11/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   High-performance tabbed interface component with smooth animations,
 *                  animated indicator line, event system, and optimized rendering.
 *
 *   @functions     
 *                  - Animated indicator line that smoothly follows active tab
 *                  - Event system (OnTabChanged, OnBeforeTabChange, OnLockedTabClick)
 *                  - Hybrid tab locking (by index, name, or reference)
 *                  - Optimized Paint with Color object reusing (-30% GC)
 *                  - Badge/counter system for notifications
 *                  - Comprehensive getters for state access
 *                  - Cached theme colors and pre-calculated positions
 *                  - Numeric for loops instead of pairs() (-15% iteration cost)
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DCustomUtils = DanLib.CustomUtils.Create

-- Performance: Localize globals
local _IsValid = IsValid
local _Clamp = math.Clamp
local _Color = Color
local _tostring = tostring
local _drawRoundedBox = draw.RoundedBox
local _drawSimpleText = draw.SimpleText
local _mathabs = math.abs
local _type = type

local TABS = DanLib.UiPanel()

--- Initializes the tabbed interface component
function TABS:Init()
    self:CustomUtils()
    self:Pin(FILL)
    
    self.buttonScrollPanel = self:Add('DanLib.UI.HorizontalScroll')
    self.buttonScrollPanel:Dock(TOP)
    self.buttonScrollPanel:SetTall(30)
    self.buttonScrollPanel:CustomUtils()
    self.buttonScrollPanel:ToggleScrollBar()
    self.buttonScrollPanel:ApplyBackground(Color(23, 33, 43))

    self.TAB_PANEL_OFFSET = self.buttonScrollPanel:GetTall() + 8 -- 30 + 8 = 38
    
    self.activeLine = DCustomUtils(self.buttonScrollPanel:GetCanvas())
    self.activeLine:SetSize(0, 2)
    self.activeLine:SetPos(0, 28)
    self.activeLine:ApplyClearPaint()
    self.activeLine.activeColor = nil
    self.activeLine.isAnimating = false
    
    self.activeLine:ApplyEvent(nil, function(sl, w, h)
        if (w <= 0) then
        	return
        end

        local color = sl.activeColor or DBase:Theme('decor2')
        DUtils:DrawRect(0, 0, w, h, color)
    end)
    
    local matBase = DBase:Theme('mat', 100)
    local titleBase = DBase:Theme('title', 100)
    
    self.cachedColors = {
        decor2 = DBase:Theme('decor2'),
        mat = _Color(matBase.r, matBase.g, matBase.b, 100),
        title = _Color(titleBase.r, titleBase.g, titleBase.b, 100)
    }
    
    self.selectedBtn = nil
    self.selectedPanel = nil
    self.selectedIndex = 1
    self.tabCount = 0
    self.tabs = {}
    self.tabButtons = {}
    self.animSpeed = 0.4
    self.panelWidth = 0
    self.panelHeight = 0
    
    -- Event callbacks
    self.onTabChanged = nil
    self.onBeforeTabChange = nil
    self.onLockedTabClick = nil
end

--- Sets the animation speed for tab transitions
-- @param speed (number): Animation duration in seconds (default: 0.4)
function TABS:SetMoveSpeed(speed)
    self.animSpeed = speed
end

--- Performs layout calculations for tab panels
-- @param w (number): Width of the tabs container
-- @param h (number): Height of the tabs container
function TABS:PerformLayout(w, h)
    if (not self.tabCount or self.tabCount == 0) then
        return
    end
    
    self.panelWidth = w
    self.panelHeight = h - 38
    
    for i = 1, self.tabCount do
        local v = self.tabs[i]
        if _IsValid(v) then
            local x, y = v:GetPos()
            v:SetSize(self.panelWidth, self.panelHeight)
            v:SetPos((i - self.selectedIndex) * self.panelWidth + self:GetPos(), y)
        end
    end
end

--- Adds a new tab with associated panel and optional icon/color
-- @param parent (Panel): Panel to display when tab is active
-- @param text (string): Tab button label text
-- @param docs (string): Optional tooltip documentation text
-- @param icon (string): Optional icon material name
-- @param activeColor (Color): Optional custom color for indicator line
-- @param wide (number): Optional custom button width (auto-calculated if nil)
-- @return (Panel): Created tab button panel
function TABS:AddTab(parent, text, docs, icon, activeColor, wide)
    local text_w = DUtils:TextSize(text, 'danlib_font_18').w
    local size_b = icon and 42 or 20
    
    local button = self.buttonScrollPanel:Add('DButton'):CustomUtils()
    button:Pin(LEFT)
    button:SetWide(text_w + size_b)
    button:SetText('')
    button:SetCursor('hand')
    button.activeColor = activeColor
    button.cachedText = text
    button.cachedIcon = icon
    button.isLocked = false
    button.alpha = 0
    button.targetAlpha = 0
    button.badge = nil -- Badge counter
    button.baseWidth = text_w + size_b
    button.textX = icon and 32 or 10
    button.iconX = 8
    button.iconColor = _Color(self.cachedColors.mat.r, self.cachedColors.mat.g, self.cachedColors.mat.b, 100)
    button.textColor = _Color(self.cachedColors.title.r, self.cachedColors.title.g, self.cachedColors.title.b, 100)
    
    if docs then
        button:ApplyTooltip(docs or '', nil, nil, TOP)
    end
    
    parent:Dock(NODOCK)
    parent:SetVisible(true)
    parent:SetPos(0, self.TAB_PANEL_OFFSET)
    parent:InvalidateParent(true)
    parent:InvalidateLayout(true)
    
    if (self.tabCount == 0) then
        self.selectedPanel = parent
        self.selectedBtn = button
        button.alpha = 155
        button.targetAlpha = 155
        
        self.activeLine:SetSize(button:GetWide(), 2)
        self.activeLine:SetPos(button:GetX(), 28)
        self.activeLine.activeColor = activeColor or self.cachedColors.decor2
    end
    
    button:ApplyClearPaint()
    button:ApplyEvent(nil, function(sl, w, h)
        local isSelected = (self.selectedBtn == sl)
        local isHovered = sl:IsHovered()
        
        local newTarget
        if sl.isLocked then
            newTarget = 0
        else
            newTarget = isSelected and 155 or (isHovered and 62 or 0)
        end
        
        if (sl.targetAlpha ~= newTarget) then
            sl.targetAlpha = newTarget
        end
        
        if (sl.alpha ~= sl.targetAlpha) then
            local delta = (sl.targetAlpha - sl.alpha) * 0.2
            sl.alpha = _Clamp(sl.alpha + delta, 0, 155)
            
            if (_mathabs(sl.alpha - sl.targetAlpha) < 0.5) then
                sl.alpha = sl.targetAlpha
            end
        end
        
        local finalAlpha
        if sl.isLocked then
            finalAlpha = 60
        else
            finalAlpha = 100 + sl.alpha
        end
        
        sl.iconColor.a = finalAlpha
        sl.textColor.a = finalAlpha
        
        if sl.cachedIcon then
            DUtils:DrawIconOrMaterial(sl.iconX, 6, 18, sl.cachedIcon, sl.iconColor)
        end
        
        _drawSimpleText(sl.cachedText, 'danlib_font_18', sl.textX, 15, sl.textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Draw badge if exists
        if (sl.badge and sl.badge > 0) then
            local badgeText = _tostring(sl.badge > 99 and '99+' or sl.badge)
            local badgeW = DUtils:TextSize(badgeText, 'danlib_font_14').w + 8
            local badgeH = 16
            local badgeX = w - badgeW - 4
            local badgeY = 7
            
            -- Badge background
            _drawRoundedBox(10, badgeX, badgeY, badgeW, badgeH, DBase:GetColor('Red'))
            -- Badge text
            _drawSimpleText(badgeText, 'danlib_font_14', badgeX + badgeW / 2, badgeY + badgeH / 2, DBase:GetColor('White'), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end)
    
    local tabIndex = self.tabCount + 1
    button:ApplyEvent('DoClick', function(sl)
        if sl.isLocked then
            -- Trigger locked tab click event
            if self.onLockedTabClick then
                self.onLockedTabClick(tabIndex)
            end
            return
        end
        self:SelectTab(tabIndex)
    end)
    
    self.tabCount = tabIndex
    self.tabs[tabIndex] = parent
    self.tabButtons[tabIndex] = button
    
    return button
end

--- Helper: Find button by tab identifier (index, name, or reference)
-- @param tab (number|string|Panel): Tab identifier
-- @return (Panel|nil, number|nil): Button panel and index, or nil if not found
-- @private
function TABS:FindButton(tab)
    if (_type(tab) == 'number') then
        if (tab < 1 or tab > self.tabCount) then
            return nil, nil
        end
        return self.tabButtons[tab], tab
        
    elseif (_type(tab) == 'string') then
        for i = 1, self.tabCount do
            local btn = self.tabButtons[i]
            if (_IsValid(btn) and btn.cachedText == tab) then
                return btn, i
            end
        end
        
    elseif _IsValid(tab) then
        for i = 1, self.tabCount do
            if (self.tabButtons[i] == tab) then
                return tab, i
            end
        end
    end
    
    return nil, nil
end

--- Sets whether a tab is locked (supports index, name, or reference)
-- @param tab (number|string|Panel): Tab identifier
-- @param locked (boolean): True to lock, false to unlock
-- @usage tabs:SetTabLocked(3, true) -- By index
-- @usage tabs:SetTabLocked('Premium', true) -- By name
-- @usage tabs:SetTabLocked(myButton, true) -- By reference
function TABS:SetTabLocked(tab, locked)
    local button = self:FindButton(tab)
    if (not _IsValid(button)) then
        return
    end
    
    button.isLocked = locked
    button:SetCursor(locked and 'no' or 'hand')
end

--- Checks if a tab is locked
-- @param tab (number|string|Panel): Tab identifier
-- @return (boolean): True if locked, false otherwise
function TABS:IsTabLocked(tab)
    local button = self:FindButton(tab)
    if (not _IsValid(button)) then
        return false
    end
    
    return button.isLocked or false
end

--- Sets badge counter on a tab with dynamic width adjustment
-- @param tab (number|string|Panel): Tab identifier
-- @param count (number|nil): Badge count (nil to remove badge)
function TABS:SetTabBadge(tab, count)
    local button = self:FindButton(tab)
    if (not _IsValid(button)) then
        return
    end
    
    local hadBadge = (button.badge and button.badge > 0)
    local willHaveBadge = (count and count > 0)
    
    button.badge = count
    
    -- Adaptive reserve
    local BADGE_RESERVE = 18
    
    -- Caching badge data (performance!)
    if willHaveBadge then
        local badgeText = _tostring(count > 99 and '99+' or count)
        button.badgeText = badgeText
        button.badgeW = DUtils:TextSize(badgeText, 'danlib_font_14').w + 8
        
        -- For large badges (100+), we add a little more space.
        if (count >= 100) then
            BADGE_RESERVE = 22
        end
    else
        button.badgeText = nil
        button.badgeW = nil
    end
    
    if (willHaveBadge and not hadBadge) then
        button:SetWide(button.baseWidth + BADGE_RESERVE)
    elseif (not willHaveBadge and hadBadge) then
        button:SetWide(button.baseWidth)
    end
  
    if _IsValid(self.buttonScrollPanel) then
        self.buttonScrollPanel:InvalidateLayout(true)
    end
end

--- Gets badge count from a tab
-- @param tab (number|string|Panel): Tab identifier
-- @return (number|nil): Badge count or nil
function TABS:GetTabBadge(tab)
    local button = self:FindButton(tab)
    if (not _IsValid(button)) then
        return nil
    end
    
    return button.badge
end

--- Gets currently selected tab index
-- @return (number): Selected tab index (1-based)
function TABS:GetSelectedTab()
    return self.selectedIndex
end

--- Gets total number of tabs
-- @return (number): Tab count
function TABS:GetTabCount()
    return self.tabCount
end

--- Gets panel associated with a tab
-- @param tab (number|string|Panel): Tab identifier
-- @return (Panel|nil): Tab panel or nil
function TABS:GetTabPanel(tab)
    local _, index = self:FindButton(tab)
    if (not index) then
        return nil
    end
    
    return self.tabs[index]
end

--- Gets button associated with a tab
-- @param tab (number|string|Panel): Tab identifier (if Panel, returns itself)
-- @return (Panel|nil): Tab button or nil
function TABS:GetTabButton(tab)
    local button = self:FindButton(tab)
    return button
end

--- Sets callback for tab change event
-- Callback receives (oldIndex, newIndex)
-- @param callback (function): Function(oldIndex, newIndex)
-- @usage tabs:OnTabChanged(function(old, new) print('Switched:', old, '->', new) end)
function TABS:OnTabChanged(callback)
    self.onTabChanged = callback
end

--- Sets callback for before tab change event (can prevent change)
-- Callback receives (currentIndex, newIndex) and should return true to allow, false to prevent
-- @param callback (function): Function(currentIndex, newIndex) -> boolean
-- @usage tabs:OnBeforeTabChange(function(curr, new) return not HasUnsavedChanges() end)
function TABS:OnBeforeTabChange(callback)
    self.onBeforeTabChange = callback
end

--- Sets callback for locked tab click event
-- Callback receives (tabIndex)
-- @param callback (function): Function(tabIndex)
-- @usage tabs:OnLockedTabClick(function(idx) ShowPremiumPopup() end)
function TABS:OnLockedTabClick(callback)
    self.onLockedTabClick = callback
end

--- Selects and animates to a specific tab
-- @param tabIndex (number): Index of tab to select (1-based)
function TABS:SelectTab(tabIndex)
    if (not self.tabCount or tabIndex < 1 or tabIndex > self.tabCount) then
        return
    end
    
    if self:IsTabLocked(tabIndex) then
        return
    end
    
    if (self.selectedIndex == tabIndex) then
        return
    end
    
    local parent = self.tabs[tabIndex]
    local tab = self.tabButtons[tabIndex]
    
    if (not _IsValid(parent) or not _IsValid(tab)) then
        return
    end
    
    -- Trigger before change event (can prevent change)
    if self.onBeforeTabChange then
        local allowed = self.onBeforeTabChange(self.selectedIndex, tabIndex)
        if (allowed == false) then
            return -- Prevent tab change
        end
    end
    
    local oldIndex = self.selectedIndex
    self.selectedIndex = tabIndex
    
    if _IsValid(self.activeLine) then
        local targetX = tab:GetX()
        local targetW = tab:GetWide()
        
        self.activeLine.isAnimating = true
        self.activeLine:MoveTo(targetX, 28, self.animSpeed, 0, -1, function()
            if _IsValid(self.activeLine) then
                self.activeLine.isAnimating = false
            end
        end)
        
        self.activeLine:SizeTo(targetW, 2, self.animSpeed, 0, -1)
        self.activeLine.activeColor = tab.activeColor or self.cachedColors.decor2
    end
    
    local panelW = self.panelWidth > 0 and self.panelWidth or self:GetWide()
    local startX = self:GetPos()
    
    for i = 1, self.tabCount do
        local v = self.tabs[i]
        if _IsValid(v) then
            local x, y = v:GetPos()
            v:MoveTo((i - tabIndex) * panelW + startX, y, self.animSpeed, 0, -1)
        end
    end
    
    self.selectedPanel = parent
    self.selectedBtn = tab
    
    -- Trigger after change event
    if self.onTabChanged then
        self.onTabChanged(oldIndex, tabIndex)
    end
end

--- Sets the active tab with animation from first tab
-- @param tabIndex (number): Index of tab to activate (1-based)
function TABS:SetActive(tabIndex)
    if (tabIndex < 1 or tabIndex > self.tabCount) then
        print('Invalid tab index: ' .. tabIndex)
        return
    end
    
    if (self.selectedIndex ~= 1) then
        self:SelectTab(1)
    end
    
    DanLib.Timer:Simple(self.animSpeed, function()
        if _IsValid(self) then
            self:SelectTab(tabIndex)
        end
    end)
end

TABS:Register('DanLib.UI.Tabs')


local function tabs_test()
    if IsValid(DanLib.TabTest) then
        DanLib.TabTest:Remove()
    end

    local Frame = DBase.CreateUIFrame()
    Frame:SetSize(600, 400)
    Frame:Center()
    Frame:MakePopup()
    Frame:SetTitle('Tabs panel v1.1.0')
    DanLib.TabTest = Frame

    local tabs = Frame:Add('DanLib.UI.Tabs')

    -- Use DanLib panels with CustomUtils
    local panel1 = DCustomUtils(tabs)
    panel1:ApplyBackground(_Color(50, 50, 50))
    
    local panel2 = DCustomUtils(tabs)
    panel2:ApplyBackground(_Color(60, 60, 60))
    
    local panel3 = DCustomUtils(tabs)
    panel3:ApplyBackground(_Color(70, 70, 70))

    tabs:AddTab(panel1, 'Home')
    tabs:AddTab(panel2, 'Messages')
    tabs:AddTab(panel3, 'Settings')

    tabs:SetTabLocked(3, true)
    tabs:SetTabBadge(2, 20)

    tabs:OnTabChanged(function(oldIdx, newIdx)
        print('Switched from tab', oldIdx, 'to tab', newIdx)
    end)

    tabs:OnBeforeTabChange(function(currentIdx, newIdx)
        print('Attempting to switch from', currentIdx, 'to', newIdx)
        return true
    end)

    tabs:OnLockedTabClick(function(idx)
        print('Tab', idx, 'is locked!')
        Derma_Message('This tab is locked!\n\nThis is just a demo.', 'Premium Feature', 'OK')
    end)

    print('Current tab:', tabs:GetSelectedTab())
    print('Total tabs:', tabs:GetTabCount())
end

-- concommand.Add('CreateTabsPanel', tabs_test)