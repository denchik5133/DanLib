/***
 *   @addon         DanLib
 *   @component     Main Manu
 *   @license       MIT License
 *   @version       2.0.1
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
local DHook = DanLib.Hook
local DCookieUtils = DanLib.CookieUtils
local DCustomUtils = DanLib.CustomUtils.Create
local DTable = DanLib.Table
local DTimer = DanLib.Timer
local ui = DanLib.UI
local DUtils = DanLib.Utils

local _IsValid = IsValid
local _pairs = pairs
local _ipairs = ipairs
local _mathMin = math.min
local _mathMax = math.max
local _mathClamp = math.Clamp
local _CurTime = CurTime
local _osDate = os.date
local _osTime = os.time
local _type = type
local _ErrorNoHalt = ErrorNoHalt
local _drawSimpleText = draw.SimpleText

-- Constants
local CONSTANTS = {
    WIDTH = DBase:GetSize(1000),
    HEIGHT = DBase:GetSize(620),
    NEWS_SIZE = DBase:GetSize(300),
    SAVE_POPUP_WIDTH = 300,
    SAVE_POPUP_HEIGHT = 80,
    ANIM_DURATION = 0.3,
}

-- Page caching
local PageCache = {
    sorted = nil,
    version = 0
}

-- Getting a sorted list of pages
function PageCache:Get()
    if self.sorted then
        return self.sorted
    end
    
    self.sorted = { }
    for _, page in _pairs(DanLib.Pages) do
        DTable:Add(self.sorted, page)
    end
    
    DTable:Sort(self.sorted, function(a, b)
        local orderA = a:GetOrder()
        local orderB = b:GetOrder()
        if (orderA == orderB) then
            return a:GetName() < b:GetName()
        end
        return orderA < orderB
    end)
    
    return self.sorted
end

-- Disabling the cache when adding a new page
function PageCache:Invalidate()
    self.sorted = nil
    self.version = self.version + 1
end

-- A hook to register a new page
local originalRegisterPage = DanLib.RegisterPage
if originalRegisterPage then
    function DanLib:RegisterPage(page)
        originalRegisterPage(self, page)
        PageCache:Invalidate()
    end
end


local MenuBuilder = { }

-- Creating the main frame
function MenuBuilder:CreateMainFrame()
    local MainMenu = DCustomUtils()
    MainMenu:SetPos(0, 0)
    MainMenu:SetSize(DanLib.ScrW, DanLib.ScrH)
    MainMenu:MakePopup()
    MainMenu:ApplyAttenuation()
    MainMenu:ApplyBlur(2, 2)
    MainMenu:ApplyBackground(Color(14, 22, 33, 180))
    
    return MainMenu
end

-- Creating a menu header
function MenuBuilder:CreateHeader(parent)
    local header = DCustomUtils(parent)
    header:SetTall(30)
    header:Dock(TOP)
    local versionText = DBase:L('#version', { version = DanLib.Version })
    header:ApplyEvent(nil, function(sl, w, h)
        _drawSimpleText(DanLib.AddonsName, 'danlib_font_20', 10, h * 0.5, DBase:Theme('text'), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        _drawSimpleText(versionText, 'danlib_font_20', w - 10, h * 0.5, DBase:Theme('text'), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end)
    
    return header
end

--- Creating seasonal effects
function MenuBuilder:CreateSeasonalEffects(parent)
    if (not DanLib.USERCONFIG.BASE.ShowParticles) then
        return
    end
    
    local month = _osDate('!*t', _osTime()).month
    if (month == 12 or month == 1 or month == 2) then
        DBase.CreateSnowPanel(parent)
    else
        DBase.CreateLinePanel(parent)
    end
end

-- Creating the main container
function MenuBuilder:CreateContainer(parent)
    local Container = DCustomUtils(parent)
    Container:SetSize(CONSTANTS.WIDTH, CONSTANTS.HEIGHT)
    Container:Center()
    Container:ApplyEvent(nil, function(sl, w, h)
        DanLib.DrawShadow:Begin()
        local x, y = sl:LocalToScreen(0, 0)
        DUtils:DrawRect(x, y, w, h, DBase:Theme('background'))
        DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
    end)
    
    return Container
end

-- Creating a navigation bar
function MenuBuilder:CreateNavigation(container, mainMenu)
    local Navigation = DCustomUtils(container, 'DanLib.UI.Sidenav')
    Navigation:Pin(LEFT)
    Navigation:SetWide(50)
    Navigation.MainMenu = mainMenu
    Navigation.Container = container
    
    return Navigation
end

-- Creating a content area
function MenuBuilder:CreateContentArea(container)
    local ContentArea = DCustomUtils(container)
    ContentArea:Pin(nil, 8)
    return ContentArea
end

-- Setting up pages and tabs
function MenuBuilder:SetupPages(mainMenu, navigation, contentArea)
    local pPlayer = LocalPlayer()
    local pages = PageCache:Get()
    
    mainMenu.pages = pages
    local firstValidPage = nil
    
    for i, page in _ipairs(pages) do
        -- Creating a tab (creating it for all pages)
        page.pnl = navigation:AddTab(page:GetIcon() or 'error', page:GetName() or '???', function()
            -- Calling a custom click handler
            if (page.OnClick and page:OnClick(mainMenu)) then
                return
            end
            
            -- Preventing the active tab from opening again
            if (mainMenu.activeTab == i) then
                return
            end
            
            self:ActivatePage(mainMenu, navigation, contentArea, page, i)
        end)
        
        -- Checking access for tab visibility
        local hasAccess = not page.AccessСheck or page:AccessСheck(pPlayer) ~= false
        page.pnl:SetVisible(hasAccess)
        
        -- Memorizing the first available tab
        if hasAccess then
            firstValidPage = firstValidPage or page.pnl
        end
    end
    
    -- Opening the last active page
    local lastPageIndex = _mathClamp(DCookieUtils:GetNumber('DanLib.ActivePage', 1), 1, #pages)
    
    -- Checking the availability of the saved page
    if (pages[lastPageIndex] and pages[lastPageIndex].pnl and pages[lastPageIndex].pnl:IsVisible()) then
        DanLib.BaseMenu:SetActive(lastPageIndex)
    elseif firstValidPage then
        if (_IsValid(firstValidPage) and firstValidPage.DoClick) then
            firstValidPage:DoClick()
        end
    end
end

-- Page activation
function MenuBuilder:ActivatePage(mainMenu, navigation, contentArea, page, index)
    mainMenu.activeTab = index
    
    -- Saving the selected page
    DCookieUtils:Set('DanLib.ActivePage', index)
    
    -- Cleaning up old content
    for _, child in _ipairs(contentArea:GetChildren()) do
        child:Remove()
    end
    
    -- Input Settings
    mainMenu:SetKeyboardInputEnabled(page:GetKeyboardInput())
    
    -- Creating Page Content
    if page.Create then
        page:Create(contentArea)
    end
    
    -- Updating the active tab
    navigation.activeTab = page.pnl
    navigation:UpdateActiveTab()
    
    -- Return of focus
    mainMenu:MakePopup()
end

-- Unsaved change notification system
function MenuBuilder:SetupSaveNotification(mainMenu)
    local savePopup = nil
    local isClosing = false
    local lastConfigHash = nil
    
    --- Notification display
    local function ShowSavePopup()
        if (_IsValid(savePopup) or isClosing) then
            return
        end
        
        savePopup = DCustomUtils(mainMenu)
        
        local pos_x, pos_y = savePopup:GetPosition('BOTTOM_LEFT', 80)
        pos_x = pos_x - 50
        
        savePopup:SetPos(pos_x, mainMenu:GetTall())
        savePopup:SetSize(CONSTANTS.SAVE_POPUP_WIDTH, CONSTANTS.SAVE_POPUP_HEIGHT)
        savePopup:ApplyAttenuation(CONSTANTS.ANIM_DURATION, 255)
        savePopup:MoveTo(pos_x, pos_y, CONSTANTS.ANIM_DURATION, 0, -10)
        savePopup:SetDrawOnTop(true)
        savePopup:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('primary_notifi'))
            -- DUtils:DrawOutlinedRoundedRect(6, 0, 0, w, h, 4, DBase:Theme('frame'))
            local squareSize = 64
            DUtils:DrawSquareWithIcon(8, (h - squareSize) * 0.5, DBase:Theme('secondary_dark'), squareSize, DanLib.TYPE['WARNING'], 6)
            DUtils:DrawDualTextWrap(squareSize + 24, h * 0.5, 'WARNING', 'danlib_font_18', DanLib.TYPE_COLOR['WARNING'], DBase:L('PlsRememberSaveChanges'), 'danlib_font_18', DBase:Theme('title'), TEXT_ALIGN_LEFT, nil, 200)
        end)
        
        local button = DBase.CreateUIButton(savePopup, {
            background = false,
            dock = { FILL },
            hover = { DBase:Theme('button_hovered', 40), nil, 6 },
            hoverClick = false,
            click = function()
                DanLib.BaseMenu:SetActive(5)
            end
        })
    end
    
    -- Hiding the notification
    local function HideSavePopup()
        if (not _IsValid(savePopup) or isClosing) then
            return
        end
        
        isClosing = true
        
        local pos_x = savePopup:GetPosition('BOTTOM_LEFT', 80) - 50
        
        savePopup:SetAlpha(255)
        savePopup:AlphaTo(0, CONSTANTS.ANIM_DURATION, 0)
        savePopup:MoveTo(pos_x, mainMenu:GetTall(), CONSTANTS.ANIM_DURATION, nil, nil, function()
            if _IsValid(savePopup) then
                savePopup:Remove()
                savePopup = nil
            end
            isClosing = false
        end)
    end
    
    -- Checking configuration changes
    local function _checkConfigChanges()
        if (not _IsValid(mainMenu)) then
            return false
        end
        
        -- Checking for changes
        local hasChanges = DanLib.ChangedConfig and DTable:Count(DanLib.ChangedConfig) > 0
        if hasChanges then
            if (not _IsValid(savePopup)) then
                ShowSavePopup()
            end
            return true
        else
            if (_IsValid(savePopup) and not isClosing) then
                HideSavePopup()
            end
            return false
        end
    end
    
    -- Event subscription (priority)
    DHook:Add('DanLib.ConfigChanged', 'DanLib.Menu.SaveNotification', function()
        if (not _IsValid(mainMenu)) then
            DHook:Remove('DanLib.ConfigChanged', 'DanLib.Menu.SaveNotification')
            return
        end
        ShowSavePopup()
    end)
    
    DHook:Add('DanLib.ConfigSaved', 'DanLib.Menu.HideSaveNotification', function()
        if (not _IsValid(mainMenu)) then
            DHook:Remove('DanLib.ConfigSaved', 'DanLib.Menu.HideSaveNotification')
            return
        end
        HideSavePopup()
    end)
    
    -- Fallback via optimized Think (only if events don't work)
    local nextCheck = 0
    local checkInterval = 0.5 -- We check every 0.5 seconds instead of every frame
    
    mainMenu:ApplyEvent('Think', function(sl)
        local curTime = _CurTime()
        if (curTime < nextCheck) then
            return
        end
        nextCheck = curTime + checkInterval
        
        _checkConfigChanges()
    end)
    
    -- Clearing hooks when deleting menus
    local originalOnRemove = mainMenu.OnRemove
    mainMenu.OnRemove = function(sl)
        DHook:Remove('DanLib.ConfigChanged', 'DanLib.Menu.SaveNotification')
        DHook:Remove('DanLib.ConfigSaved', 'DanLib.Menu.HideSaveNotification')
        
        if _IsValid(savePopup) then
            savePopup:Remove()
        end
        
        if originalOnRemove then
            originalOnRemove(sl)
        end
    end
    
    -- Initial verification
    _checkConfigChanges()
end

local function _createBaseMenu()
    if _IsValid(DanLib.MainMenu) then
        DanLib.MainMenu:Remove()
        DanLib.MainMenu = nil
    end
    
    -- Creating the main components
    local MainMenu = MenuBuilder:CreateMainFrame()
    DanLib.MainMenu = MainMenu
    
    MenuBuilder:CreateHeader(MainMenu)
    MenuBuilder:CreateSeasonalEffects(MainMenu)
    
    local Container = MenuBuilder:CreateContainer(MainMenu)
    local Navigation = MenuBuilder:CreateNavigation(Container, MainMenu)
    local ContentArea = MenuBuilder:CreateContentArea(Container)

    -- Linking components
    MainMenu.Navigation = Navigation
    MainMenu.Container = ContentArea
    
    -- Configuring Functionality
    MenuBuilder:SetupPages(MainMenu, Navigation, ContentArea)
    MenuBuilder:SetupSaveNotification(MainMenu)

    -- A SINGLE hook for all modules
    DTimer:Simple(0.1, function()
        if (not _IsValid(MainMenu)) then
            return
        end
        
        -- Calling the hook with the menu data
        DHook:Run('DanLib.MainMenu', MainMenu, Navigation, ContentArea)
    end)
    
    return MainMenu
end


DanLib.BaseMenu = DanLib.BaseMenu or { }

--- Opens the menu (if closed) and activates the specified page.
-- Accepts either a number (sorted index) or a string (unique page ID set via :SetID()).
-- External addons should always prefer the string ID - it never changes regardless
-- of how many pages other addons register.
--
-- Usage:
--   DanLib.BaseMenu:SetActive(2) -- open by sorted index
--   DanLib.BaseMenu:SetActive('my_page') -- open by unique string ID
--
-- @param target (number|string): Sorted page index OR unique string ID
function DanLib.BaseMenu:SetActive(target)
    -- If the menu is not open yet - defer EVERYTHING to the next frame.
    -- _createBaseMenu() must never be called synchronously from HTML/JS callbacks
    -- or other restricted VGUI contexts, as MakePopup() will freeze the game.
    if (not _IsValid(DanLib.MainMenu)) then
        DTimer:Simple(0, function()
            if (not _IsValid(DanLib.MainMenu)) then
                _createBaseMenu()
            end
            DanLib.BaseMenu:SetActive(target)
        end)
        return
    end

    local menu  = DanLib.MainMenu
    local pages = menu.pages
    if (not pages) then
        return
    end

    local page, pageIndex

    if (_type(target) == 'number') then
        -- Search by sorted position
        if (target < 1 or target > #pages) then
            return
        end

        page = pages[target]
        pageIndex = target
    elseif (_type(target) == 'string') then
        -- Search by unique string ID
        local targetPage = DanLib.Pages_ID[target]
        if (not targetPage) then
            _ErrorNoHalt('[DanLib] SetActive: page with ID "' .. target .. '" not found. ' .. 'Make sure the page is registered with :SetID() before calling SetActive.\n')
            return
        end
        for i, p in _ipairs(pages) do
            if (p == targetPage) then
                page = p
                pageIndex = i
                break
            end
        end
    end

    if (not page or not _IsValid(page.pnl)) then
        return
    end

    MenuBuilder:ActivatePage(menu, menu.Navigation, menu.Container, page, pageIndex)
end

-- Switches the visibility of the menu
function DanLib.BaseMenu:Toggle()
    if (not _IsValid(DanLib.MainMenu)) then
        _createBaseMenu()
    else
        DanLib.MainMenu:Remove()
        DanLib.MainMenu = nil
    end
end

--- Sets the transparency of the menu
-- @param show (boolean): Show (true) or hide (false)
function DanLib.BaseMenu:ToggleMenuVisibility(show)
    local menu = DanLib.MainMenu
    if (not _IsValid(menu)) then
        return
    end
    
    local targetAlpha = show and 255 or 80
    menu:SetVisible(true)
    menu:AlphaTo(targetAlpha, CONSTANTS.ANIM_DURATION, 0)
end

DanLib.Net:On('DanLib:BaseMenu', function()
    DanLib.BaseMenu:Toggle()
    DBase:TutorialSequence(1, 1)
end)

-- Updating constants when the resolution changes
DHook:Add('DDI.PostScreenSizeChanged', 'DanLib.Menu.UpdateConstants', function()
    CONSTANTS.WIDTH = DBase:GetSize(1000)
    CONSTANTS.HEIGHT = DBase:GetSize(620)
    CONSTANTS.NEWS_SIZE = DBase:GetSize(300)
    
    -- Recreating the menu when the resolution changes
    if _IsValid(DanLib.MainMenu) then
        local wasOpen = true
        local activeTab = DanLib.MainMenu.activeTab
        
        DanLib.MainMenu:Remove()
        _createBaseMenu()
        
        if activeTab then
            DanLib.BaseMenu:SetActive(activeTab)
        end
    end
end)
