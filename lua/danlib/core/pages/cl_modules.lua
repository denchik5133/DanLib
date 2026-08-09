/***
 *   @addon         DanLib
 *   @component     Modules Page
 *   @license       MIT License
 *   @version       1.2.2
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Module management panel for DanLib framework with automatic version checking,
 *                  grid display, and interactive module information popups. Provides visual
 *                  interface for viewing installed modules, checking updates, and accessing
 *                  detailed module information with optimized performance through caching.
 *
 *   @functions     
 *                  - Automatic version checking with HTTP caching (5-minute TTL)
 *                  - Dynamic 3-column grid layout with responsive sizing
 *                  - Interactive module cards with hover effects
 *                  - Detailed module information popups at mouse position
 *                  - Debounced update button (2-second cooldown)
 *                  - Sorted module display by priority
 *                  - Performance optimizations (cached colors, pre-calculated sizes)
 *                  - Tutorial integration with sequence tracking
 *                  - Copyable module information headers
 *   
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         An active internet connection is required to verify the version.
 *                  Extracts update data from: https://raw.githubusercontent.com/denchik5133/DDI-Other-Informations/main/DDI/update.json
 */



-- Cache frequently used references
local DBase = DanLib.Func
local DUI = DanLib.UI
local DNet = DanLib.Net
local DUtils = DanLib.Utils
local DTable = DanLib.Table
local DCustomUtils = DanLib.CustomUtils.Create
local DMaterial = DanLib.Config.Materials

-- Cache common functions
local _LocalPlayer = LocalPlayer
local _CurTime = CurTime
local _pairs = pairs
local _ipairs = ipairs
local _ColorAlpha = ColorAlpha
local _DrawText = draw.DrawText
local _SimpleText = draw.SimpleText
local _guiMouseX = gui.MouseX
local _guiMouseY = gui.MouseY

local _TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local _TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local _TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT

local MODULES = DBase.CreatePage('modules')
MODULES:SetName(DBase:L('#modules'))
MODULES:SetOrder(4)
MODULES:SetIcon('oDR9aTn')
MODULES:SetID('modules')
MODULES:SetKeyboardInput(true)

--- Checks if the player has access to the administration pages.
-- @param pPlayer Player|nil The player for whom access is being checked. If nil, LocalPlayer() is used.
-- @return boolean Returns true if the player has access, otherwise false.
function MODULES:AccessСheck(pPlayer)
    return DBase.HasPermission(pPlayer or _LocalPlayer(), 'AdminPages')
end

--- Creates a settings panel.
-- @param parent Panel The parent panel to which the settings panel will be added.
function MODULES:Create(parent)
    DBase:TutorialSequence(3, 2)
    local m = DBase.CreatePanelModules(parent)
    m:Pin()
    m:FillPanel()
end 

local defaultFont = 'danlib_font_20'
local defaultFont2 = 'danlib_font_18'

-- Cache configuration
local versionsCache = nil
local sortedModulesCache = nil
local cacheExpireTime = 0
local CACHE_TTL = 300 -- 5 minutes in seconds
local lastUpdateTime = 0
local UPDATE_COOLDOWN = 2 -- seconds

-- Receive version data sent by sv_modules.lua (server fetches GitHub to avoid client SSL issues)
DNet:On('DanLib.Modules.VersionData', function()
    local json = DNet:Str()
    local ok, data = pcall(util.JSONToTable, json)
    if (ok and data) then
        versionsCache = data
        cacheExpireTime = _CurTime() + CACHE_TTL
    end
end)

--- Creates a panel with common settings for module display.
-- @param parent: The parent panel to which this panel will be attached.
-- @param height: The height of the new panel.
-- @param topOffset: The offset from the top of the parent panel.
-- @return panel: Returns the created panel with specified settings.
local function CreatePanelWithSettings(parent, height, topOffset)
    local panel = DCustomUtils(parent)
    panel:PinMargin(TOP, nil, nil, nil, topOffset)
    panel:SetTall(height)
    panel:ApplyShadow(10, false)
    return panel
end

--- Creates a panel for displaying module information.
-- @param parent: The parent panel to which this module panel will be attached.
-- @return MODULE: Returns the created module panel.
function DBase.CreatePanelModules(parent)
    local MODULE = DCustomUtils(parent)

    --- Refreshes the version cache by requesting data from the server.
    -- Server fetches from GitHub (SSL works server-side) and sends back JSON.
    -- @param force: If true, forces a cache refresh regardless of TTL
    function MODULE:RefreshVersionCache(force)
        local currentTime = _CurTime()
        
        if (force or not versionsCache or currentTime > cacheExpireTime) then
            DNet:Open('DanLib.Modules.RequestVersions')
                :Up()
        end
    end

    --- Gets or creates cached sorted modules list
    -- @return table: Returns sorted modules array
    function MODULE:GetSortedModules()
        if (not sortedModulesCache) then
            sortedModulesCache = { }
            for k, v in _pairs(DanLib.ConfigMeta) do
                DTable:Add(sortedModulesCache, { v.SortOrder, k })
            end
            DTable:SortByMember(sortedModulesCache, 1, false)
        end
        return sortedModulesCache
    end

    --- Invalidates all caches (useful when modules change)
    function MODULE:InvalidateCache()
        sortedModulesCache = nil
        versionsCache = nil
        cacheExpireTime = 0
    end

    --- Fills the module panel with content.
    function MODULE:FillPanel()
        -- Cache theme colors for better performance
        local colorSecondaryDark = DBase:Theme('secondary_dark')
        local colorDecor = DBase:Theme('decor')
        local colorText = DBase:Theme('text')
        local colorMat = DBase:Theme('mat', 150)
        local colorYellow = DBase:GetColor('Yellow')

        -- Create the title panel.
        self.header = CreatePanelWithSettings(self, 46, 12)
        self.header.icon = 24
        self.header.iconMargin = 14
        
        -- Cache strings
        local modulesText = DBase:L('#modules')
        local modulesDesc = DBase:L('#modules.description')
        
        self.header:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawRoundedBox(0, 0, w, h, colorSecondaryDark)
            DUtils:DrawIcon(sl.iconMargin, h * .5 - sl.icon * 0.5, sl.icon, sl.icon, DMaterial['box'], colorMat)
            DUtils:DrawDualText(sl.iconMargin * 3.5, h / 2 - 2, modulesText, 'danlib_font_20', colorDecor, modulesDesc, defaultFont, colorText, _TEXT_ALIGN_LEFT, nil, w - 300)
        end)

        -- Create a grid layout for modules.
        self.grid = DBase.CreateGridPanel(self)
        self.grid:PinMargin(nil, 4, nil, 2)
        self.grid:SetColumns(3)
        self.grid:SetHorizontalMargin(12)
        self.grid:SetVerticalMargin(12)
        self.grid:StartAnimation()

        -- Button to refresh module versions with debounce protection
        DBase.CreateUIButton(self.header, {
            background = { nil },
            dock_indent = { RIGHT, nil, 7, 6, 7 },
            hover = { _ColorAlpha(colorYellow, 60), nil, 6 },
            wide = 100,
            text = { 'Update', nil, nil, nil, colorYellow },
            click = function(sl)
                local currentTime = _CurTime()
                
                -- Debounce protection
                if (currentTime - lastUpdateTime < UPDATE_COOLDOWN) then
                    return
                end
                lastUpdateTime = currentTime
                
                -- Force refresh
                self:InvalidateCache()
                self.grid:StartAnimation()
                self:RefreshVersionCache(true)
                
                -- Trigger tutorial sequence
                DBase:TutorialSequence(4, 3)
            end
        })

        -- Initial cache load
        self:RefreshVersionCache(false)
        -- Refresh the panel to display module data
        self:Refresh()
    end

    --- Refreshes the module list and updates the UI.
    function MODULE:Refresh()
        self.grid:Clear()

        -- Get sorted modules from cache
        local sortedModules = self:GetSortedModules()
        -- Cache theme colors
        local colorSecondaryDark = DBase:Theme('secondary_dark')
        local themeSecondary = DBase:Theme('secondary')
        local colorText = DBase:Theme('text', 150)
        local versionBgColor = Color(37, 44, 55)

        -- Loop through sorted modules to create UI elements
        for _, v in _ipairs(sortedModules) do
            -- Get the module key
            local Key = v[2]
            -- Retrieve module data
            local module = DanLib.ConfigMeta[Key]
            -- Set the height for the module slot
            local SlotTall = DUI:ClampScaleH(self, 145, 145)
            -- Create a panel for the module
            local modulesBack = DCustomUtils()
            modulesBack:SetTall(SlotTall)
            modulesBack.size = 70
            
            -- Cache module-specific data
            modulesBack.moduleTitle = module.Title
            modulesBack.moduleVersion = 'v' .. module.Version
            modulesBack.moduleColor = module.Color
            modulesBack.moduleIcon = module.Icon or DMaterial['box']
            -- Pre-calculate version text size (cached)
            modulesBack.versionTextW = DUtils:TextSize(modulesBack.moduleVersion, defaultFont2).w
            -- Cache colors to avoid repeated theme lookups
            modulesBack.cachedBG = colorSecondaryDark
            modulesBack.cachedSecondary = themeSecondary
            modulesBack.cachedText = colorText
            modulesBack.cachedVersionBG = versionBgColor
            modulesBack:ApplyEvent(nil, function(sl, w, h)
                DUtils:DrawRoundedBox(0, 0, w, h, sl.cachedBG)
                DUtils:DrawSquareWithIcon(w * 0.5 - sl.size * 0.5, 10, sl.cachedSecondary, sl.size, sl.moduleIcon, 6)
                _SimpleText(sl.moduleTitle, defaultFont, w * 0.5, h * 0.5 + 25, sl.moduleColor, _TEXT_ALIGN_CENTER, _TEXT_ALIGN_CENTER)
                DUtils:DrawRoundedBox(8, h - 26, 8 + sl.versionTextW, 20, sl.cachedVersionBG)
                _SimpleText(sl.moduleVersion, defaultFont2, 12, h - 16, sl.cachedText, _TEXT_ALIGN_LEFT, _TEXT_ALIGN_CENTER)
            end)

            -- Add the module panel to the grid
            self.grid:AddCell(modulesBack, nil, true)
            -- Cache hover color
            local hoverColor = DBase:Theme('button_hovered')
            local titleColor = DBase:Theme('title')

            -- Button for more information about the module
            DBase.CreateUIButton(modulesBack, {
                background = { nil },
                dock = { FILL },
                hover = { hoverColor, nil, 6 },
                wide = 100,
                paint = function(sl, w, h)
                    sl:ApplyAlpha(0.5, 220)
                    _DrawText('Click for more information', defaultFont, w / 2, h / 2, _ColorAlpha(titleColor, sl.alpha), _TEXT_ALIGN_CENTER)
                end,
                click = function(sl)
                    -- Trigger tutorial sequence
                    DBase:TutorialSequence(4, 1)
                    -- Show module info popup
                    self:ModuleInfoPopup(modulesBack, module)
                end
            })
        end
    end

    --- Adds a header panel with text and title.
    -- @param panel: The panel to which the header will be added.
    -- @param text: The header text.
    -- @param title: The title text.
    -- @param titleColor: The color of the title text.
    -- @param size: The height of the header panel.
    MODULE.AddPanelText = function(panel, text, title, titleColor, size)
        -- Cache theme colors
        local themeTitleColor = DBase:Theme('title')
        local transparentBG = Color(0, 0, 0, 0)
        
        -- Create a button for the header
        local headerPanel = DBase:CreateButton(panel)
        headerPanel:PinMargin(TOP, nil, nil, nil, 5)
        headerPanel:SetTall(size or 24)
        headerPanel:SetHoverTum(true)
        headerPanel:SetBackgroundColor(transparentBG)
        
        headerPanel:ApplyEvent(nil, function(sl, w, h)
            _DrawText(text, defaultFont2, 10, 2, themeTitleColor, _TEXT_ALIGN_LEFT)
            _DrawText(title, defaultFont2, w - 10, 2, titleColor, _TEXT_ALIGN_RIGHT)
        end)
        
        headerPanel:ApplyEvent('DoClick', function(sl)
            -- Trigger tutorial sequence
            DBase:TutorialSequence(4, 2)
            -- Copy title to clipboard
            DBase:ClipboardText(title)
        end)
    end
    --- Displays a popup with detailed information about a module.
    -- @param modulesBack: The background panel of the module.
    -- @param module: The module data to be displayed.
    function MODULE:ModuleInfoPopup(modulesBack, module)
        -- Remove existing popup if valid
        if DUI:valid(self.pnlBack) then 
            self.pnlBack:Remove() 
        end

        -- Get mouse position
        local mouse_x = _guiMouseX()
        local mouse_y = _guiMouseY()

        -- Create a new panel for the popup
        self.pnlBack = DCustomUtils()
        self.pnlBack:SetSize(ScrW(), ScrH())
        self.pnlBack:MakePopup()
        self.pnlBack:ApplyAttenuation(0.3)
        self.pnlBack:ApplyEvent('OnMousePressed', function(sl)
            sl:SetAlpha(255)
            sl:AlphaTo(0, 0.1, 0, function()
                sl:Remove()
            end)
        end)

        local width = DUI:ClampScaleW(self.pnlBack, 300, 300)
        local height = DUI:ClampScaleH(self.pnlBack, 380, 380)

        -- Cache theme colors
        local themePrimaryNotifi = DBase:Theme('primary_notifi')
        local themeFrame = DBase:Theme('frame')

        -- Create a panel for the popup content
        local pnl = DCustomUtils(self.pnlBack)
        pnl:SetPos(mouse_x + 5, mouse_y - 5)
        pnl:SetSize(width, height)
        pnl:ApplyEvent(nil, function(sl, w, h)
            local x, y = sl:LocalToScreen(0, 0)
            DanLib.DrawShadow:Begin()
            DUtils:DrawRoundedBox(x, y, w, h, themePrimaryNotifi)
            DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
            -- DanLib.Outline:Draw(6, x, y, w, h, themeFrame, nil, 1)
            surface.DrawOutlinedRoundedRect(0, 0, w, h, 6, 1, themeFrame)
        end)

        -- Create a base panel for the popup content
        local main = DCustomUtils(pnl)
        main:Pin(TOP)
        main:SetHeight(140)

        -- Create a blur panel for the avatar
        local blurBase = DCustomUtils(main)
        blurBase:Pin(TOP)
        blurBase:SetHeight(100)

        -- Get the module author ID.
        local ID = module.Author or nil
        -- Get the player's name.
        local playerName = steamworks.GetPlayerName(ID) or 'unknown'

        -- Create an avatar image.
        local avatarBaner = DCustomUtils(blurBase, 'AvatarImage')
        avatarBaner:SetPos(0, -75)
        avatarBaner:SetSize(310, 310)
        avatarBaner:SetSteamID(ID, 64)

        -- Create a panel for the blur effect.
        local blur = DCustomUtils(avatarBaner)
        blur:Pin(FILL)
        blur:ApplyEvent(nil, function(sl, w, h)
            -- Apply blur effect.
            DUtils:DrawBlur(sl, 1, 1)
            -- Draw a semi-transparent background.
            -- DUtils:DrawRect(0, 0, w, h, Color(0, 0, 0, 200))
            -- Draw a circle on the blur.
            -- DUtils:DrawCircle(w * 0.5, h * 0.5 + 15, 44, 32, DBase:Theme('primary_notifi'))
        end)

        local avatar = DCustomUtils(main)
        avatar:ApplyAvatar(false, 6)
        avatar:SetSteamID(ID, 124)
        avatar:SetPos(115, 54)
        avatar:SetSize(80, 80)

        -- Create a scrollable panel for module details.
        local scroll = DCustomUtils(pnl, 'DanLib.UI.Scroll')
        scroll:PinMargin(nil, nil, 5, nil, 5)
        scroll:ToggleScrollBar() -- Enable scrolling.

        -- Add module details to the scroll panel.
        self.AddPanelText(scroll, 'Author', 'By ' .. playerName, DBase:Theme('text', 180))
        self.AddPanelText(scroll, 'SteamID64', ID, DBase:Theme('text', 180))
        self.AddPanelText(scroll, 'Name', module.Title, module.Color)

        -- Get cached version data.
        local checkVersions = versionsCache or { }
        -- Check the version for the module.
        local checkVer = checkVersions[module.Title]
        -- Define color constants.
        local red, green, yellow = DBase:GetColor('Red'), DBase:GetColor('Green'), DBase:GetColor('Yellow')
        -- Check if the module is up-to-date.
        local isUpToDate = (module.Version == checkVer)
        -- Default text and color.
        local text, color = DBase:L('#modules.no.inf'), red

        if checkVer then
            -- Set color based on version status.
            color = isUpToDate and green or yellow
            -- Set text based on version status.
            text = isUpToDate and DBase:L('#latest.version') or DBase:L('#update.needed') .. ' ' .. DBase:L('#new.version', {
                version = checkVer
            })
        end

        -- Wrap text for display.
        local wText = DUtils:TextWrap(text or 'none', defaultFont, scroll:GetWide() * 3)
        -- Get text size for layout.
        local text_y = DUtils:TextSize(wText, defaultFont).h
        -- Add version text.
        self.AddPanelText(scroll, DBase:L('version'), wText, color, 10 + text_y)

        -- Wrap module description text.
        local wrappedText = DUtils:TextWrap(module.Description or 'none', defaultFont, scroll:GetWide() * 3)
        -- Get the size of the wrapped text.
        local title_y = DUtils:TextSize(wrappedText, defaultFont).h
        -- Add description text.
        self.AddPanelText(scroll, DBase:L('description'), wrappedText, DBase:Theme('text', 180), title_y)
    end

    -- Return the created module panel.
    return MODULE
end
