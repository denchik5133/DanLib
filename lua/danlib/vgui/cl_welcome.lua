/***
 *   @addon         DanLib
 *   @component     File util
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
 *   @description   Interactive welcome tutorial
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



-- LOCALIZATION
local DBase = DanLib.Func
local DHook = DanLib.Hook
local DUtils = DanLib.Utils
local DTable = DanLib.Table
local DTimer = DanLib.Timer
local DOutline = DanLib.Outline
local DFileUtil = DanLib.FileUtil
local DNetworkUtil = DanLib.NetworkUtil
local DCustomUtils = DanLib.CustomUtils.Create

local _Lerp = Lerp
local _select = select
local _pairs = pairs
local _ipairs = ipairs
local _osTime = os.time
local _osDate = os.date
local _IsValid = IsValid
local _mathAbs = math.abs
local _mathCeil = math.ceil
local _mathRound = math.Round
local _FrameTime = FrameTime
local _CurTime = CurTime
local _Color = Color
local _ColorAlpha = ColorAlpha
local _LocalPlayer = LocalPlayer
local _GetHostName = GetHostName
local _drawDrawText = draw.DrawText
local _drawSimpleText = draw.SimpleText
local _strformat = string.format

-- CONSTANTS
local POPUP_WIDTH = 550
local POPUP_HEIGHT = 500
local ANIM_SPEED = 3

-- colors
local COLOR_BG = _Color(14, 22, 33, 180)
local COLOR_TEXT = _Color(220, 221, 225)
local COLOR_SEPARATOR = _Color(255, 255, 255, 20)

-- A SYSTEM FOR ADDING PARTICIPANTS
local TEAM_MEMBERS = {
    {
        steamID = DanLib.Author,
        role = 'Lead Developer',
        roleColor = _Color(0, 151, 230),
        gradientStart = _Color(255, 140, 0),
        gradientEnd = _Color(0, 151, 230),
        buttons = {
            { color = _Color(88, 101, 242), text = 'Discord', link = 'https://discord.gg/CND6B5sH3j' },
            { color = _Color(36, 41, 46), text = 'GitHub', link = 'https://github.com/denchik5133' },
            { color = _Color(23, 121, 186), text = 'Steam', link = 'https://steamcommunity.com/profiles/76561198405398290/' },
            { color = _Color(255, 69, 0), text = 'Youtube', lick = 'https://www.youtube.com/@denchik3506' }
        },
    },
    {
        steamID = '76561199493672657',
        role = 'Lead Developer',
        roleColor = _Color(0, 151, 230),
        gradientStart = _Color(27, 188, 242),
        gradientEnd = _Color(251, 52, 114),
        buttons = {
            { color = _Color(23, 121, 186), text = 'Steam', link = 'https://steamcommunity.com/profiles/76561199493672657/' }
        },
    },
    {
        steamID = '76561198000000000',
        role = 'Tester',
        roleColor = _Color(76, 175, 80),
        gradientStart = _Color(76, 175, 80),
        gradientEnd = _Color(67, 156, 242),
        buttons = {
            { color = _Color(23, 121, 186), text = 'Steam', link = 'https://steamcommunity.com/profiles/76561198000000000/' }
        }
    }
}

local VERSION_CHECK_CACHE = {
    latestVersion = nil,
    lastCheckTime = 0,
    isChecking = false,
    CACHE_TTL = 300 -- 5 minutes
}

--- Checks the relevance of the cached version of DanLib
-- @param callback (function): The callback function with the result (latestVersion, isUpToDate, isChecking)
local function _checkVersion(callback)
    local currentTime = _CurTime()
    local updateLink = 'https://raw.githubusercontent.com/denchik5133/DDI-Other-Informations/main/DDI/update.json'
    
    -- If the cache is valid, we return the cached data.
    if VERSION_CHECK_CACHE.latestVersion and (currentTime - VERSION_CHECK_CACHE.lastCheckTime < VERSION_CHECK_CACHE.CACHE_TTL) then
        local currentVer = DanLib.Version or '3.0.0'
        local isUpToDate = (currentVer == VERSION_CHECK_CACHE.latestVersion)
        callback(VERSION_CHECK_CACHE.latestVersion, isUpToDate, false)
        return
    end
    
    -- If the check is already underway, we are waiting
    if VERSION_CHECK_CACHE.isChecking then
        callback(nil, nil, true)
        return
    end
    
    -- Starting the verification process
    VERSION_CHECK_CACHE.isChecking = true
    callback(nil, nil, true) -- We immediately return "verified"
    
    DanLib.HTTP:Fetch(updateLink, function(data)
        local versions = DanLib.NetworkUtil:JSONToTable(data)
        if (versions and versions[DanLib.AddonsName]) then
            VERSION_CHECK_CACHE.latestVersion = versions[DanLib.AddonsName]
            VERSION_CHECK_CACHE.lastCheckTime = currentTime
            VERSION_CHECK_CACHE.isChecking = false
            
            local currentVer = DanLib.Version or '3.0.0'
            local isUpToDate = (currentVer == VERSION_CHECK_CACHE.latestVersion)
            callback(VERSION_CHECK_CACHE.latestVersion, isUpToDate, false)
        else
            VERSION_CHECK_CACHE.isChecking = false
            callback(nil, nil, false)
        end
    end, function(err)
        DBase:Print('Failed to fetch version:', err or 'Unknown error')
        VERSION_CHECK_CACHE.isChecking = false
        callback(nil, nil, false)
    end)
end

-- GLOBAL VARIABLES
local currentWidth = DBase:GetSize(POPUP_WIDTH)
local currentHeight = DBase:GetSize(POPUP_HEIGHT)

local function UpdateScreenSize()
    currentWidth = DBase:GetSize(POPUP_WIDTH)
    currentHeight = DBase:GetSize(POPUP_HEIGHT)
end
DHook:Add('OnScreenSizeChanged', 'DanLib.WelcomeResize', UpdateScreenSize)

--- THE FILE SYSTEM
local function GetSafeHostname()
    local hostname = _GetHostName()
    local safeName = hostname:gsub('[^%w%s%-_]', ''):gsub('%s+', '_'):lower()

    if (#safeName > 64) then
        safeName = safeName:sub(1, 64)
    end

    if (safeName == '') then
        safeName = 'server_' .. DNetworkUtil:CRC(hostname)
    end

    return safeName
end

local function _getWelcomeFileName()
    return 'danlib/welcome_' .. GetSafeHostname() .. '.txt'
end

local function _wasTutorialShown()
    local welcomeFile = _getWelcomeFileName()
    if (not DFileUtil:Exists(welcomeFile)) then
        return false
    end

    local content = DFileUtil:Read(welcomeFile) or ''
    if (not content:find(_GetHostName(), 1, true)) then
        return false
    end

    return true
end

local function _saveWelcomeFlag(completed)
    local welcomeFile = _getWelcomeFileName()
    local currentLang = DanLib.CONFIG.BASE.Languages or 'English'
    local content = _strformat('Server: %s\nTimestamp: %s\nCompleted: %s\nVersion: %s\nLanguage: %s', _GetHostName(), _osDate('%Y-%m-%d %H:%M:%S'), completed and 'Yes' or 'Skipped', DanLib.Version or '3.1.0', currentLang)
    DFileUtil:Write(welcomeFile, content)
    DBase:Print('Tutorial ' .. (completed and 'completed' or 'skipped'))
end

--- TUTORIAL STEPS
local TUTORIAL_STEPS = {
    { -- STEP 1: Welcome
        title = 'Welcome {color:255,165,0}{player_name}{/color}!',
        lines = {
            { text = 'You are now the Owner of this DanLib installation.' },
            { text = '' },
            { text = 'This interactive guide will help you:' },
            { text = '' },
            { text = '{color:67,156,242}Configure Settings{/color:}' },
            { text = '  • Choose your preferred language' },
            { text = '  • Select a theme and gamemode' },
            { text = '' },
            { text = '{color:67,156,242}Learn Essential Features{/color:}' },
            { text = '  • Understand your Owner privileges' },
            { text = '  • Navigate the control panel' },
            { text = '' },
            { text = '{color:113, 128, 147}Time required: ~3 minutes{/color:}' }
        },
        buttons = {
            back = 'Skip Tutorial',
            next = 'Let\'s Start'
        }
    },
    { -- STEP 2: About Authors
        title = 'Meet the {color:76,175,80}Development Team{/color}',
        lines = {
            { text = 'DanLib is developed and maintained by DDI Scripts:' },
            { text = '' },
            { text = '{color:113, 128, 147}Connect with us for support, updates, and community!{/color:}' }
        },
        animation = false,
        interactive = function(parent, settings)
            -- VERSION VERIFICATION PANEL
            local versionPanel = DCustomUtils(parent)
            versionPanel:PinMargin(TOP, nil, nil, nil, 8)
            versionPanel:SetTall(80)
            versionPanel.alpha = 0
            versionPanel.latestVersion = nil
            versionPanel.isUpToDate = nil
            versionPanel.isChecking = true

            -- CALLING THE CACHING FUNCTION
            _checkVersion(function(latestVersion, isUpToDate, isChecking)
                if (not _IsValid(versionPanel)) then 
                    return
                end

                versionPanel.latestVersion = latestVersion
                versionPanel.isUpToDate = isUpToDate
                versionPanel.isChecking = isChecking
            end)
            
            versionPanel:ApplyEvent(nil, function(sl, w, h)
                sl.alpha = _Lerp(_FrameTime() * ANIM_SPEED, sl.alpha, 255)
                DUtils:DrawRoundedBox(0, 0, w, h, _Color(32, 42, 58, sl.alpha))
                
                local leftX = 15
                local rightX = w - 15
                
                -- Name and version
                local line1Y = 8
                _drawSimpleText(DanLib.AddonsName or 'DanLib Basic Library', 'danlib_font_18', leftX, line1Y, DBase:Theme('title', sl.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                local currentVersion = 'v' .. (DanLib.Version or '3.0.0')
                _drawSimpleText(currentVersion, 'danlib_font_18', rightX, line1Y, DBase:GetColor('Blue', sl.alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

                -- Author and release date
                local line2Y = 32
                _drawSimpleText('Released', 'danlib_font_18', leftX, line2Y, _Color(113, 128, 147, sl.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                _drawSimpleText(DanLib.ReleaseDate or '10/4/2023', 'danlib_font_18', rightX, line2Y, _Color(113, 128, 147, sl.alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                
                -- Version status
                local line3Y = 56
                _drawSimpleText('by DDI Scripts', 'danlib_font_18', leftX, line3Y, _Color(113, 128, 147, sl.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                if sl.isChecking then
                    _drawSimpleText('Checking for updates...', 'danlib_font_18', rightX, line3Y, _Color(255, 165, 0, sl.alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                elseif sl.latestVersion then
                    if sl.isUpToDate then
                        _drawSimpleText('✓ Up to date', 'danlib_font_18', rightX, line3Y, DBase:GetColor('Green', sl.alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                    else
                        _drawSimpleText('Update available: v' .. sl.latestVersion, 'danlib_font_18', rightX, line3Y, DBase:GetColor('DarkOrange', sl.alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                    end
                else
                    _drawSimpleText('Unable to check for updates', 'danlib_font_18', rightX, line3Y, _Color(180, 180, 180, sl.alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                end
            end)

            local matCircle = Material('vgui/circle')
            -- A FUNCTION FOR CREATING A PARTICIPANT CARD
            local function CreateMemberCard(memberData)
                local avatarSize = 80
                local ID = memberData.steamID
                local playerName = steamworks.GetPlayerName(ID) or 'Unknown'
                
                local devCard = DCustomUtils(parent)
                devCard:PinMargin(TOP, nil, nil, nil, 12)
                devCard:SetTall(150)
                devCard.alpha = 0
                devCard.hoverAlpha = 0
                
                devCard:ApplyEvent(nil, function(sl, w, h)
                    -- Animation of appearance
                    sl.alpha = _Lerp(_FrameTime() * ANIM_SPEED, sl.alpha, 255)
                    
                    -- Hover effect
                    if sl:IsHovered() then
                        sl.hoverAlpha = _Lerp(_FrameTime() * 8, sl.hoverAlpha, 10)
                    else
                        sl.hoverAlpha = _Lerp(_FrameTime() * 8, sl.hoverAlpha, 0)
                    end
                    
                    DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
                        DUtils:DrawRoundedBox(0, 0, w, h, _Color(32, 42, 58, sl.alpha))
                        
                        -- Hover illumination
                        if (sl.hoverAlpha > 0) then
                            DUtils:DrawRoundedBox(0, 0, w, h, _ColorAlpha(memberData.roleColor, sl.hoverAlpha))
                        end
                        
                        -- The upper gradient
                        DUtils:DrawGradientBox(0, 0, 0, w, 50, 0, _ColorAlpha(memberData.gradientStart, sl.alpha), _ColorAlpha(memberData.gradientEnd, sl.alpha))
                        -- Avatar (background)
                        DUtils:DrawMaterial(20, 16, avatarSize, avatarSize, _Color(32, 42, 58, sl.alpha), matCircle)
                        
                        -- Name
                        local nameY = 20 + avatarSize + 8
                        _drawSimpleText(playerName, 'danlib_font_20', 25, nameY,  DBase:Theme('text', sl.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        
                        local badgeY = nameY + 16
                        local text_w = DUtils:TextSize(memberData.role, 'danlib_font_18').w
                        local badgeW = text_w + 10
                        local badgeH = 18
                        -- The shadow under the badge
                        DUtils:DrawRoundedBox(22, badgeY + 1, badgeW, badgeH,  _Color(0, 0, 0, sl.alpha * 0.3))
                        -- Badge
                        DUtils:DrawRoundedBox(20, badgeY, badgeW, badgeH, _ColorAlpha(memberData.roleColor, sl.alpha * 0.8))
                        _drawSimpleText(memberData.role, 'danlib_font_18', 25, badgeY + badgeH / 2, DBase:Theme('title', sl.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end)
                end)
                
                -- Avatar
                local avatar = DCustomUtils(devCard)
                avatar:ApplyAvatar(false, 40)
                avatar:SetSteamID(ID, 124)
                avatar:SetPos(25, 22)
                avatar:SetSize(avatarSize - 10, avatarSize - 10)
                
                local buttonSpacing = 6
                local buttonStartX = 25 + avatarSize + 15
                local buttonStartY = 60
                local buttonHeight = 28
                local rowSpacing = 4
                
                -- Getting the actual width of the parent
                DTimer:Simple(nil, function()
                    if (not _IsValid(devCard)) then
                        return
                    end
                    
                    local parentWidth = parent:GetWide()
                    local cardPadding = 20
                    
                    -- Maximum width = width of the parent - margins - starting position - right margin
                    local maxWidth = parentWidth - buttonStartX - 15
                    local currentX = 0
                    local currentY = buttonStartY
                    
                    for i, btnData in _ipairs(memberData.buttons or { }) do
                        local buttonTextWidth = DUtils:TextSize(btnData.text, 'danlib_font_18').w
                        local buttonWidth = 10 + buttonTextWidth
                        
                        -- Checking whether the button will fit in the current row.
                        if (currentX > 0 and (currentX + buttonWidth) > maxWidth) then
                            -- Switching to a new line
                            currentX = 0
                            currentY = currentY + buttonHeight + rowSpacing
                        end
                        
                        -- Creating a button
                        DBase.CreateUIButton(devCard, {
                            pos = { buttonStartX + currentX, currentY },
                            size = { buttonWidth, buttonHeight },
                            text = { btnData.text, 'danlib_font_18' },
                            sound = false,
                            background = { DBase:Theme('secondary_dark') },
                            hover = { btnData.color, 6 },
                            paint = function(sl, w, h)
                                local x, y = sl:LocalToScreen(0, 0)
                                DOutline:Draw(6, x, y, w, h, DBase:Theme('frame'), nil, 1)
                            end,
                            click = function()
                                local context = DBase:UIContextMenu()
                                context:Option('Copy', nil, nil, function()
                                    DBase:ClipboardText(btnData.link)
                                end)
                                context:Option('Open', nil, nil, function()
                                    gui.OpenURL(btnData.link)
                                end)
                                context:Open()
                            end
                        })
                        
                        -- Updating the position for the next button
                        currentX = currentX + buttonWidth + buttonSpacing
                    end
                    
                    local requiredHeight = currentY + buttonHeight + 15
                    if (requiredHeight > devCard:GetTall()) then
                        devCard:SetTall(requiredHeight)
                    end
                end)
                
                return devCard
            end
            
            -- WE CREATE CARDS FOR ALL PARTICIPANTS
            for _, memberData in _ipairs(TEAM_MEMBERS) do
                CreateMemberCard(memberData)
            end

            -- AUTOMATIC HEIGHT CALCULATION AFTER ALL ELEMENTS ARE CREATED
            DTimer:Simple(nil, function()
                if (not _IsValid(parent)) then
                    return
                end
                
                local totalHeight = 0
                for _, child in _ipairs(parent:GetChildren()) do
                    if _IsValid(child) then
                        totalHeight = totalHeight + child:GetTall() + 12
                    end
                end
                
                parent:SetTall(totalHeight)
            end)
        end,
        buttons = {
            back = 'Back',
            next = 'Next'
        }
    },
    { -- STEP 3: Language Selection
    title = 'Choose Your {color:67,156,242}Language{/color:}',
    lines = {
        { text = 'Select the interface language:' },
        { text = '' },
        { text = '{color:113, 128, 147}Translation quality shown for each language.{/color:}' },
        { text = '{color:113, 128, 147}You can change this later in Settings > DanLib Basic Library.{/color:}' }
    },
        animation = false,
        interactive = function(parent, settings)
            local langCombo = DBase.CreateUIComboBox(parent)
            langCombo:Pin(TOP)
            langCombo:SetTall(30)
            
            local currentLang = DanLib.CONFIG.BASE.Languages or 'English'
            -- The basic language for comparison
            local baseLang = DanLib.Temp.Languages[currentLang] or DanLib.Temp.Languages['English']
            local baseCount = DTable:Count(baseLang)
            
            -- Sorting by transfer percentage
            local sortedLangs = { }
            for langID, langData in _pairs(DanLib.Temp.Languages or { }) do
                local delta = baseCount - DTable:Count(langData)
                local inverted = baseCount - delta
                local percentage = _mathRound(inverted / baseCount * 100, 2)
                
                DTable:Add(sortedLangs, {
                    id = langID,
                    data = langData,
                    percentage = percentage
                })
            end
            
            -- We sort the percentage in descending order
            DTable:Sort(sortedLangs, function(a, b)
                return a.percentage > b.percentage
            end)
            
            for _, lang in _ipairs(sortedLangs) do
                local isSelected = (currentLang == lang.id)
                local percentage = lang.percentage
                local displayName = _strformat('%s, translated %s%%', lang.id, percentage)
                langCombo:AddChoice(displayName, lang.id, isSelected)
            end
            
            langCombo:ApplyEvent('OnSelect', function(_, index, value, data)
                settings.language = data
            end)
        end,
        buttons = {
            back = 'Back',
            next = 'Next'
        }
    },
    { -- STEP 4: Theme Selection
        title = 'Select a {color:67,156,242}Theme{/color:}',
        lines = {
            { text = 'Choose a color scheme for the interface:' },
            { text = '' },
            { text = '{color:67,156,242}Themes customize:{/color:}' },
            { text = '  • Background colors' },
            { text = '  • Accent colors and highlights' },
            { text = '  • Button and panel styles' },
            { text = '' },
            { text = '{color:113, 128, 147}Change anytime in Settings > DanLib Basic Library > Themes.{/color:}' }
        },
        interactive = function(parent, settings)
            local themeCombo = DBase.CreateUIComboBox(parent)
            themeCombo:Pin(TOP)
            themeCombo:SetTall(30)
            
            local currentTheme = DanLib.CONFIG.BASE.Themes or 'DarkTheme'
            for themeID, themeData in _pairs(DanLib.Temp.Themes or {}) do
                local isSelected = (currentTheme == themeID)
                local displayName = themeData.Name or themeID
                themeCombo:AddChoice(displayName, themeID, isSelected)
            end
            
            themeCombo:ApplyEvent('OnSelect', function(_, index, value, data)
                settings.theme = data
            end)
        end,
        buttons = {
            back = 'Back',
            next = 'Next'
        }
    },
    { -- STEP 5: Gamemode Configuration
        title = 'Configure {color:255,165,0}Gamemode{/color:}',
        lines = {
            { text = 'Select your server\'s gamemode integration:' },
            { text = '' },
            { text = '{color:67,156,242}This affects:{/color:}' },
            { text = '  • Economy system integration' },
            { text = '  • Player money handling' },
            { text = '  • Gamemode-specific features' },
            { text = '' },
            { text = '{color:113, 128, 147}DanLib will adapt to your server\'s gamemode automatically.{/color:}' },
            { text = '{color:113, 128, 147}Change in Settings > DanLib Basic Library > Gamemode.{/color:}' }
        },
        interactive = function(parent, settings)
            local modeCombo = DBase.CreateUIComboBox(parent)
            modeCombo:Pin(TOP)
            modeCombo:SetTall(30)
            
            local currentMode = DanLib.CONFIG.BASE.Gamemode or 'blank'
            for modeID, modeData in pairs(DanLib.Temp.Gamemodes or { }) do
                local isSelected = (currentMode == modeID)
                modeCombo:AddChoice(modeData.Name or modeID, modeID, isSelected)
            end
            
            -- Panel with description
            local descPanel = DCustomUtils(parent)
            descPanel:PinMargin(TOP, nil, 10, nil, 10)
            descPanel:SetTall(60)
            descPanel:ApplyAttenuation(0.5, 255)
            descPanel.currentHeight = 60
            
            descPanel:ApplyEvent(nil, function(sl, w, h)
                DUtils:DrawRoundedBox(0, 0, w, h, _Color(30, 40, 55, 150))
                
                -- We get the selected mode
                local selectedMode = settings.gamemode or currentMode
                local modeData = DanLib.Temp.Gamemodes[selectedMode]
                
                -- We take the description
                local desc = 'No description available'
                if (modeData and modeData.Description) then
                    desc = modeData.Description
                end
                
                -- Calculating the required height for the text
                local padding = 20
                local wrappedText = DUtils:TextWrap(desc, 'danlib_font_18', w - 20, true)
                local lineCount = _select(2, wrappedText:gsub('\n', '\n')) + 1
                local lineHeight = DUtils:TextSize('A', 'danlib_font_18').h
                local requiredHeight = (lineCount * lineHeight) + padding
                
                -- Smooth height change
                sl.currentHeight = _Lerp(_FrameTime() * 5, sl.currentHeight, requiredHeight)
                
                -- Updating the actual height of the panel
                if (_mathAbs(sl.currentHeight - sl:GetTall()) > 1) then
                    sl:SetTall(_mathCeil(sl.currentHeight))
                    -- Updating the height of the parent
                    if _IsValid(parent) then
                        parent:InvalidateLayout(true)
                    end
                end
                
                -- Drawing the text
                _drawDrawText(wrappedText, 'danlib_font_18', 10, 10, _Color(180, 190, 200), TEXT_ALIGN_LEFT)
            end)
            
            -- We update the description when the descPanel mode
            modeCombo:ApplyEvent('OnSelect', function(_, index, value, data)
                settings.gamemode = data
            end)
            
            -- AUTOMATIC CALCULATION OF CONTAINER HEIGHT
            DTimer:Simple(0.1, function()
                if (not _IsValid(parent)) then
                    return
                end
                
                local totalHeight = 0
                for _, child in _ipairs(parent:GetChildren()) do
                    if _IsValid(child) then
                        totalHeight = totalHeight + child:GetTall() + 10
                    end
                end
                
                parent:SetTall(totalHeight + 20)
            end)
        end,
        buttons = {
            back = 'Back',
            next = 'Next'
        }
    },
    { -- STEP 6: Owner Privileges
        title = 'Your {color:76,175,80}Owner Privileges{/color:}',
        lines = {
            { text = 'As the Owner, you have unrestricted access to:' },
            { text = '' },
            { text = '{color:67,156,242}Full Module Control{/color:}' },
            { text = '  • Enable or disable any feature in Modules' },
            { text = '  • Configure all settings without restrictions' },
            { text = '' },
            { text = '{color:67,156,242}Rank Management{/color:}' },
            { text = '  • Create custom ranks with specific permissions' },
            { text = '  • Assign ranks to players' },
            { text = '' },
            { text = '{color:67,156,242}System Configuration{/color:}' },
            { text = '  • Modify all library settings' },
            { text = '  • Customize UI themes and interface elements' },
            { text = '' },
            { text = '{color:113, 128, 147}Your Owner rank is protected and cannot be removed by others.{/color:}' }
        },
        buttons = {
            back = 'Back',
            next = 'Next'
        }
    },
    { -- STEP 7: Control Panel Navigation
        title = 'The {color:67,156,242}Control Panel{/color:}',
        lines = {
            { text = 'The DanLib menu has 6 main sections:' },
            { text = '' },
            { text = '{color:67,156,242}Dashboard{/color:} - Server overview and statistics' },
            { text = '  (Currently showing {color:251,197,49}TOOLGAN{/color:} hologram)' },
            { text = '' },
            { text = '{color:67,156,242}User{/color:} - Personal settings for individual players' },
            { text = '  Each player can customize their own preferences' },
            { text = '' },
            { text = '{color:67,156,242}Commands{/color:} - All registered chat commands' },
            { text = '  View and search available commands' },
            { text = '' },
            { text = '{color:67,156,242}Modules{/color:} - Enable/disable registered modules' },
            { text = '  Control which features are active' },
            { text = '' },
            { text = '{color:67,156,242}Settings{/color:} - Configure modules and DanLib' },
            { text = '  Customize all library and module options' },
            { text = '' },
            { text = '{color:67,156,242}Help{/color:} - Documentation, Discord, and Tutorial' },
            { text = '  Get support and restart this guide anytime' },
        },
        buttons = {
            back = 'Back',
            next = 'Next'
        }
    },
    { -- STEP 8: More Menu Sections
        title = 'Control Panel {color:255,165,0}Continued{/color:}',
        lines = {
            { text = 'Additional menu sections:' },
            { text = '' },
            { text = '{color:67,156,242}Settings{/color:} - Configure modules and DanLib' },
            { text = '  • Adjust language, theme, gamemode' },
            { text = '  • Configure chat commands and currency' },
            { text = '  • Set up module-specific options' },
            { text = '  • Manage NPC, Ranks, Logs, and SQL settings' },
            { text = '' },
            { text = '{color:67,156,242}Help{/color:} - Get support and resources' },
            { text = '  • {color:255,140,0}Documentation{/color:} - Opens DDI Documentation website' },
            { text = '  • {color:255,140,0}Discord{/color:} - Join DDI Scripts Discord server' },
            { text = '  • {color:255,140,0}Tutorial{/color:} - Restart this tutorial anytime' },
            { text = '' },
            { text = '{color:113, 128, 147}Access the menu anytime with {color:0,255,0}!danlibmenu{/color:} in chat{/color:}' },
            { text = '{color:113, 128, 147}or {color:0,255,0}danlibmenu{/color:} in console.{/color:}' }
        },
        buttons = {
            back = 'Back',
            next = 'Next'
        }
    },
    { -- STEP 9: Confirm Settings
        title = '{color:76,175,80}Confirm{/color:} Your Settings',
        lines = {
            { text = 'Review your configuration below:' },
            { text = '' },
            { text = '{color:67,156,242}What Happens Next:{/color:}' },
            { text = '  • Your settings will be saved to the server' },
            { text = '  • Interface will update with your chosen theme' },
            { text = '  • Language will change immediately' },
            { text = '  • You can modify these anytime in Settings' },
            { text = '' },
            { text = '{color:113, 128, 147}Click "Apply & Finish" to save and complete setup.{/color:}' },
            { text = '{color:113, 128, 147}Click "Back" to change any settings.{/color:}' }
        },
        review = function(parent, settings)
            local reviewPanel = DCustomUtils(parent)
            reviewPanel:PinMargin(TOP, nil, 20)
            reviewPanel:SetTall(120)
            reviewPanel.alpha = 0
            reviewPanel:ApplyEvent(nil, function(sl, w, h)
                sl.alpha = _Lerp(_FrameTime() * ANIM_SPEED, sl.alpha, 255)
                _drawSimpleText('Selected Configuration:', 'danlib_font_20', 10, 5, _ColorAlpha(DBase:Theme('title'), sl.alpha), TEXT_ALIGN_LEFT)
                
                local y = 35
                local spacing = 28
                local labelX = 20
                local valueX = 180
                
                -- Language
                local langText = settings.language or DanLib.CONFIG.BASE.Languages or 'English'
                _drawSimpleText('Language:', 'danlib_font_18', labelX, y, DBase:GetColor('Blue', sl.alpha), TEXT_ALIGN_LEFT)
                _drawSimpleText(langText, 'danlib_font_18', valueX, y, DBase:GetColor('Green', sl.alpha), TEXT_ALIGN_LEFT)
                y = y + spacing
                
                -- Theme
                local themeText = settings.theme or DanLib.CONFIG.BASE.Themes or 'Default'
                _drawSimpleText('Theme:', 'danlib_font_18', labelX, y, DBase:GetColor('Blue', sl.alpha), TEXT_ALIGN_LEFT)
                _drawSimpleText(themeText, 'danlib_font_18', valueX, y, DBase:GetColor('Green', sl.alpha), TEXT_ALIGN_LEFT)
                y = y + spacing
                
                -- Gamemode
                local modeText = settings.gamemode or DanLib.CONFIG.BASE.Gamemode or 'Blank'
                _drawSimpleText('Gamemode:', 'danlib_font_18', labelX, y, DBase:GetColor('Blue', sl.alpha), TEXT_ALIGN_LEFT)
                _drawSimpleText(modeText, 'danlib_font_18', valueX, y, DBase:GetColor('Green', sl.alpha), TEXT_ALIGN_LEFT)
            end)
        end,
        buttons = {
            back = 'Back',
            next = 'Apply & Finish'
        }
    }
}

-- UI COMPONENTS
local function CreateButton(parent, text, color, onClick)
    local btn = DBase.CreateUIButton(parent, {
        background = { _ColorAlpha(color, 10), 6 },
        dock_indent = { RIGHT, nil, 5, 5, 5 },
        wide = 150,
        hover = { _ColorAlpha(color, 60), nil, 6 },
        text = { text, 'danlib_font_20', nil, nil },
        click = onClick
    })
    return btn
end

-- MAIN FUNCTION
local function RenderTutorialStep(container, stepIndex, onNext, onBack, settings)
    local step = TUTORIAL_STEPS[stepIndex]
    local pPlayer = _LocalPlayer()
    local title = step.title:gsub('{player_name}', pPlayer:Nick())
    
    container:Clear()
    
    -- Heading
    local header = DCustomUtils(container)
    header:SetTall(50)
    header:PinMargin(TOP, nil, nil, nil, 10)
    header.alpha = 0
    header:ApplyEvent(nil, function(sl, w, h)
        sl.alpha = _Lerp(_FrameTime() * ANIM_SPEED, sl.alpha, 255)
        DUtils:DrawParseText(title, 'danlib_font_26', 0, h / 2, _ColorAlpha(COLOR_TEXT, sl.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 500, TEXT_ALIGN_LEFT)
    end)
    
    -- Separator
    local sep1 = DCustomUtils(container)
    sep1:SetTall(1)
    sep1:PinMargin(TOP, nil, nil, nil, 12)
    sep1:ApplyEvent(nil, function(sl, w, h)
        DUtils:DrawGradient(0, 0, w, h, LEFT, COLOR_SEPARATOR)
    end)
    
    -- SCROLL PANEL
    local scrollPanel = DCustomUtils(container, 'DanLib.UI.Scroll')
    scrollPanel:PinMargin(nil, nil, nil, nil, 12)
    scrollPanel:ToggleScrollBar()
    
    -- Text strings
    if step.lines then
        for i, lineData in _ipairs(step.lines) do
            if (lineData.text == '') then
                local spacer = DCustomUtils(scrollPanel)
                spacer:Pin(TOP)
                spacer:SetTall(8)
            else
                local linePanel = DCustomUtils(scrollPanel)
                linePanel:Pin(TOP)
                linePanel:SetTall(22)
                linePanel.alpha = 0
                linePanel.delay = i * 0.03
                linePanel:ApplyEvent(nil, function(sl, w, h)
                    if (sl.delay > 0) then
                        sl.delay = sl.delay - _FrameTime()
                    else
                        sl.alpha = _Lerp(_FrameTime() * ANIM_SPEED, sl.alpha, 255)
                    end
                    DUtils:DrawParseText(lineData.text, 'danlib_font_18', 5, h / 2, DBase:Theme('text', sl.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 500, TEXT_ALIGN_LEFT)
                end)
            end
        end
    end
    
    -- Interactive elements
    if step.interactive then
        local animation = step.animation
        
        local interactiveContainer = DCustomUtils(scrollPanel)
        interactiveContainer:PinMargin(TOP, nil, 10, nil, 15)
        
        -- If there is a fixed height, we use it.
        if step.interactiveHeight then
            interactiveContainer:SetTall(step.interactiveHeight)
        elseif step.getInteractiveHeight then
            interactiveContainer:SetTall(step.getInteractiveHeight())
        else
            -- Otherwise, we start with the minimum height, which will automatically change.
            interactiveContainer:SetTall(100)
        end
        
        if (animation ~= false) then
            interactiveContainer:ApplyAttenuation(1.1, 255)
        end
        
        step.interactive(interactiveContainer, settings)
    end
    
    -- Review element
    if step.review then
        step.review(scrollPanel, settings)
    end
    
    -- Buttons
    local buttonPanel = DCustomUtils(container)
    buttonPanel:Pin(BOTTOM)
    buttonPanel:SetTall(40)
    
    CreateButton(buttonPanel, step.buttons.next, DBase:GetColor('Blue'), onNext)
    CreateButton(buttonPanel, step.buttons.back, DBase:GetColor('Red'), onBack)
end


local function ApplySeasonalEffect(frame)
    local month = _osDate('!*t', _osTime()).month
    if (month == 12 or month == 1 or month == 2) then
        DBase.CreateSnowPanel(frame)
    else
        DBase.CreateLinePanel(frame)
    end
end

-- A function for saving all settings to the server
local function SaveAllSettings(settings)
    local toSave = { }
    
    if settings.language then
        toSave.BASE = toSave.BASE or { }
        toSave.BASE.Languages = settings.language
    end
    
    if settings.theme then
        toSave.BASE = toSave.BASE or { }
        toSave.BASE.Themes = settings.theme
    end
    
    if settings.gamemode then
        toSave.BASE = toSave.BASE or { }
        toSave.BASE.Gamemode = settings.gamemode
    end
    
    DBase:SaveSettings(toSave, true) -- skipHookUpdate = true
end

-- THE MAIN FUNCTION OF OPENING THE TUTORIAL
function DanLib.PopupWelcome()
    if _wasTutorialShown() then
        DBase:Print('Tutorial already shown on: ' .. _GetHostName())
        return
    end
    
    if _IsValid(DanLib.WelcomeFrame) then
        DanLib.WelcomeFrame:Remove()
    end
    
    local currentStep = 1
    -- INITIALIZE THE SETTINGS WITH DEFAULT VALUES
    local userSettings = {
        -- We get the current values from the config as default values
        language = DanLib.CONFIG.BASE.Languages or 'English',
        theme = DanLib.CONFIG.BASE.Themes or 'Default',
        gamemode = DanLib.CONFIG.BASE.Gamemode or 'DarkRP'
    }
    
    -- The main frame
    local MainFrame = DCustomUtils()
    MainFrame:SetSize(ScrW(), ScrH())
    MainFrame:MakePopup()
    MainFrame:ApplyBlur()
    MainFrame:ApplyAttenuation()
    MainFrame:ApplyBackground(COLOR_BG)
    DanLib.WelcomeFrame = MainFrame

    ApplySeasonalEffect(MainFrame)
    
    -- The basic panel
    local basePanel = DCustomUtils(MainFrame)
    basePanel:SetSize(currentWidth, currentHeight)
    basePanel:Center()
    basePanel:ApplyEvent(nil, function(sl, w, h)
        local x, y = sl:LocalToScreen(0, 0)
        DanLib.DrawShadow:Begin()
        DUtils:DrawRoundedBox(x, y, w, h, DBase:Theme('background'))
        DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
    end)
    
    -- Content container
    local contentContainer = DCustomUtils(basePanel)
    contentContainer:PinMargin(nil, 30, 25, 30, 20)

    local function ShowCurrentStep()
        RenderTutorialStep(contentContainer, currentStep, function() --[[ Next ]]
            if (currentStep == #TUTORIAL_STEPS) then
                SaveAllSettings(userSettings)
                MainFrame:Remove()
                _saveWelcomeFlag(true)
            else
                currentStep = currentStep + 1
                ShowCurrentStep()
            end
        end, function() --[[ Back/Skip ]]
            if (currentStep == 1) then
                MainFrame:Remove()
                _saveWelcomeFlag(false)
            else
                currentStep = currentStep - 1
                ShowCurrentStep()
            end
        end, userSettings)
    end
    
    ShowCurrentStep()
end

DanLib.PopupWelcome()