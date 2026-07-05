/***
 *   @addon         DanLib
 *   @component     Notification System
 *   @license       MIT License
 *   @version       2.0.2
 *   @release_date  30/11/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *   
 *   @description   
 *                  Comprehensive notification system with multiple display modes:
 *                  - Center-screen toast notifications (ScreenNotification)
 *                  - Side-stacked popup notifications (SidePopupNotification)
 *                  - UI-embedded notifications (CreateUIPopupNotifi)
 *                  - Multi-position support (TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT)
 *                  - Smooth fade animations with separate alpha channels
 *                  - Markup tag support for colored text
 *                  - Automatic text wrapping and size calculation
 *                  - Shadow caching for performance optimization
 *   
 *   @functions     
 *                  - Only one center notification at a time (auto-replaces)
 *                  - Unlimited side notifications with auto-stacking
 *                  - Position-based notification grouping
 *                  - Smooth repositioning on notification close
 *                  - Custom easing functions for professional animations
 *                  - Icon type system (ERROR, SUCCESS, WARNING, INFO, ADMIN)
 *                  - Adaptive icon sizing based on notification dimensions
 *                  - Markup tag support with proper size calculation
 *   
 *   @example     
 *                  -- Center notification:
 *                  DBase:ScreenNotification('Title', 'Message', 'SUCCESS', 5)
 *   
 *                  -- Side notification (default top-left):
 *                  DBase:SidePopupNotification('Message', 'INFO', 3)
 *   
 *                  -- Side notification with position:
 *                  DBase:SidePopupNotification('Achievement!', 'ADMIN', 4, 'BOTTOM_RIGHT')
 *   
 *                  -- UI-embedded notification:
 *                  DBase:CreateUIPopupNotifi(parent, 'Title', 'Message', 'ERROR', 5)
 *   
 *   @commands      
 *                  danlib_close_side_notifications - Force close all side notifications
 *                  danlib_close_notification - Force close center notification
 *                  danlib_test_side_notifications - Test side notification system
 *                  danlib_popup_debugtest - Test center notification
 *                  danlib_debug_adaptive - Toggle debug mode
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *   
 *   @notes         
 *                  - DUtils:CleanMarkupText() is currently bugged, using temporary workaround
 *                  - Side notifications support up to 8 simultaneous notifications
 *                  - Center notification auto-closes previous notification
 *                  - Markup tags: {color:red}, {font:name}, {bg:color}
 *                  - Position presets include custom X/Y offsets per anchor
 */
 
 

local DBase = DanLib.Func
local ui = DanLib.UI
local DUtils = DanLib.Utils
local DTable = DanLib.Table
local DTimer = DanLib.Timer
local DConcommand = DanLib.Concommand
local DCustomUtils = DanLib.CustomUtils.Create

local _IsValid = IsValid
local _ipairs = ipairs
local _Color = Color
local _mathMax = math.max
local _mathMin = math.min
local _upper = string.upper
local _strformat = string.format
local _drawText = draw.DrawText
local _drawSimpleText = draw.SimpleText
local _ColorAlpha = ColorAlpha
local _SetAlphaMultiplier = surface.SetAlphaMultiplier

-- CONSTANTS
local NOTIFICATION_WIDTH = 420
local NOTIFICATION_MIN_HEIGHT = 6
local ICON_ALPHA_OFFSET = 230
local TEXT_WRAP_WIDTH = 370
local ANIMATION_DURATION = 0.5
local TEXT_ANIMATION_DELAY = 0.1
local TEXT_ANIMATION_DURATION = 0.3
local TEXT_FADE_DURATION = 0.16
local CLOSE_ANIMATION_DURATION = 0.4

-- Smooth easing function
local function _smoothEase(t, b, c, d)
    t = t / d
    if (t < 0.5) then
        return b + c * (4 * t * t * t)
    else
        local f = ((2 * t) - 2)
        return b + c * (1 + f * f * f / 2)
    end
end

if _IsValid(ON_SCREEN_POPUP_NOTIFI) then
    ON_SCREEN_POPUP_NOTIFI:OldRemove()
end

--- Function for creating notifications on the screen
-- Displays a smooth animated notification toast at the top center of the screen.
-- Only one notification can be shown at a time - new notifications replace the previous one.
--
-- @param title (string): Notification title text (shown in bold)
-- @param text (string): Notification message body (supports multi-line text)
-- @param icon (string): Notification icon type - one of:
--   • 'ERROR'   - Red notification for errors and failures
--   • 'SUCCESS' - Green notification for successful operations
--   • 'WARNING' - Yellow/Orange notification for warnings
--   • 'INFO'    - Blue notification for informational messages
--   • 'ADMIN'   - Purple notification for admin actions
-- @param time (number): Display duration in seconds (default: 5)
--   • Minimum recommended: 3 seconds
--   • Maximum recommended: 15 seconds
-- @param color (Color): Custom notification color (optional)
--   • If not specified, uses the default color for the icon type
--   • Overrides the icon type color scheme
-- @return toast (EditablePanel): The notification panel object
--   • Can be used to manually close the notification early
--   • Example: local notif = DBase:ScreenNotification(...); notif:Remove()
--
-- @usage
--      - Manually close notification early
--      local notif = DBase:ScreenNotification('Processing', 'Please wait...', 'INFO', 999)
--      DTimer:Simple(2, function()
--          if IsValid(notif) then
--              notif:Remove() -- Close after 2 seconds instead of 999
--          end
--      end)
--
-- @usage
--      - Custom color notification (overrides icon color)
--      DBase:ScreenNotification('Custom', 'This is purple!', 'INFO', 5, Color(150, 0, 255))
--
-- @usage
--      - Notification in a hook
--      hook.Add('PlayerDeath', 'NotifyDeath', function(victim, inflictor, attacker)
--          if attacker:IsPlayer() and attacker ~= victim then
--              DBase:ScreenNotification('Kill', attacker:Nick() .. ' eliminated ' .. victim:Nick(), 'INFO', 4)
--          end
--      end)
--
-- @usage
--      Notification with validation
--      local function SaveConfig()
--          local success, err = pcall(function()
--              -- Save logic here
--          end)
--     
--          if success then
--              DBase:ScreenNotification('Saved', 'Configuration saved!', 'SUCCESS', 3)
--          else
--              DBase:ScreenNotification('Error', 'Failed to save: ' .. tostring(err), 'ERROR', 8)
--          end
--      end
--
-- @note Only one notification is displayed at a time. Creating a new notification
--       will automatically close the previous one with a smooth fade-out animation.
--
-- @note Available icon types and their default colors:
--       ERROR   → Red (#E74C3C)
--       SUCCESS → Green (#2ECC71)
--       WARNING → Orange (#F39C12)
--       INFO    → Blue (#3498DB)
--       ADMIN   → Purple (#9B59B6)
function DBase:ScreenNotification(title, text, icon, time, color)
    -- Deleting a previous notification if it exists
    if _IsValid(ON_SCREEN_POPUP_NOTIFI) then
        ON_SCREEN_POPUP_NOTIFI:OldRemove()
    end

    -- Creating a new notification toast
    local toast = DCustomUtils()
    ON_SCREEN_POPUP_NOTIFI = toast
    local defaultFont18 = 'danlib_font_18'
    
    -- Setting the title, text and icon
    toast.title = title or DBase:L('#no.data')
    toast.text = DUtils:TextWrap(text, defaultFont18, TEXT_WRAP_WIDTH, true)
    toast.icon = (DanLib.TYPE[icon] or DanLib.TYPE['ERROR'])
    toast.color = (DanLib.TYPE_COLOR[icon] or DanLib.TYPE_COLOR['ERROR'])
    toast.time = time or 5
    toast.text_h = DUtils:TextSize(toast.text, defaultFont18).h

    -- Initial position and size
    local startX = DanLib.ScrW / 2 - NOTIFICATION_WIDTH / 2
    local finalHeight = 44 + toast.text_h
    
    toast:SetSize(NOTIFICATION_WIDTH, NOTIFICATION_MIN_HEIGHT) -- The initial size is small
    toast:SetPos(startX, 100) -- Starting position at the bottom
    toast:SetDrawOnTop(true)
    toast.alpha = 0
    toast.textAlpha = 0
    toast.drawtext = false
    toast.ProgressSize = 0
    toast.isRemoving = false

    -- Enhanced Paint function
    toast:ApplyEvent(nil, function(sl, w, h)
        local x, y = sl:LocalToScreen(0, 0)
        -- Draw notification background with shadow
        DanLib.DrawShadow:Begin()
        DUtils:DrawRoundedBox(x, y, w, h, DBase:Theme('primary_notifi'))
        DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
        
        -- Draw colored borders
        DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
            DUtils:DrawRoundedBox(0, 0, 4, h, sl.color)
            DUtils:DrawRoundedBox(w - 4, 0, 4, h, sl.color)
        end)
        
        -- Calculate adaptive icon size and position
        local iconSize = DUtils:CalculateAdaptiveIconSize(w, h, 32, 124)
    
        -- Center icon in the right area of notification
        local iconX = w - iconSize - 15
        local iconY = h * 0.5 - iconSize * 0.5
        
        -- The icon is dim (textAlpha - 230)
        local iconAlpha = _mathMax(0, sl.textAlpha - ICON_ALPHA_OFFSET)
        DUtils:DrawIcon(iconX, iconY, iconSize, iconSize, sl.icon, _ColorAlpha(sl.color, iconAlpha))
        
        -- Draw text content
        _drawText(_upper(sl.title), 'danlib_font_20', 30, 8, _ColorAlpha(sl.color, sl.textAlpha))
        DUtils:DrawParseText(sl.text, defaultFont18, 30, 32, DBase:Theme('text', sl.textAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, TEXT_WRAP_WIDTH, TEXT_ALIGN_LEFT)
        
        -- Debug info
        if DanLib.DEBUG_MODE then
            _drawSimpleText(_strformat('BG: %d | Text: %d | Icon: %d', sl.alpha, sl.textAlpha, iconAlpha), 'danlib_font_16', 5, h - 15, _Color(255, 255, 255, 100))
        end
    end)

    -- ANIMATION OF THE OPENING
    toast:ApplyEvent('Create', function(sl)
        sl.drawtext = false
        sl.ProgressSize = 0
        sl.alpha = 0
        sl.textAlpha = 0
        -- Height animation (5 → finalHeight)
        sl:ApplyLerpHeight(finalHeight, 0.5, function()
            if (not _IsValid(sl)) then
                return
            end
            sl.drawtext = true
        end, _smoothEase)
        sl:ApplyLerpMoveY(40, 0.5) -- Y position animation (120 → 40)
        sl:ApplyLerp('alpha', 255, 0.5) -- Background animation (0 → 255)
        
        -- Text animation with a delay (so that the window grows first)
        DTimer:Simple(0.1, function()
            if _IsValid(sl) then
                sl:ApplyLerp('textAlpha', 255, 0.3)
            end
        end)
        
        -- Progress bar (starts after opening)
        DTimer:Simple(0.5, function()
            if (_IsValid(sl) and not sl.isRemoving) then
                sl:ApplyLerp('ProgressSize', NOTIFICATION_WIDTH, sl.time, function()
                    sl:Remove()
                end)
            end
        end)
    end)

    -- CLOSING ANIMATION
    toast.OldRemove = toast.Remove
    function toast:Remove()
        if self.isRemoving then
            return
        end
        self.isRemoving = true
        self.ProgressSize = 0
        self.drawtext = false
        
        self:ApplyLerp('textAlpha', 0, 0.16) -- The text disappears FIRST (2.5 times faster)
        self:ApplyLerpHeight(NOTIFICATION_MIN_HEIGHT, CLOSE_ANIMATION_DURATION, nil, _smoothEase) -- The height decreases (finalHeight → 5)
        self:ApplyLerpMoveY(100, 0.4) -- The Y position moves down (40 → 100)
        self:ApplyLerp('alpha', 0, 0.4, function() -- The background disappears (255 → 0)
            if _IsValid(self) then
                self:OldRemove()
                -- Clearing the global variable
                if (ON_SCREEN_POPUP_NOTIFI == self) then
                    ON_SCREEN_POPUP_NOTIFI = nil
                end
            end
        end)
    end
    toast:Create()
    return toast
end

DConcommand:Add('danlib_popup_debugtest', function(pPlayer)
    if (pPlayer:SteamID64() ~= '76561198405398290' and pPlayer:SteamID64() ~= '76561199493672657') then
        return false, print 'This command is intended for the developer only. It is only used for testing purposes.'
    end

    DBase:ScreenNotification('CONFIG FILED', "The ability to save data about how a user wants to use an application is an important part of programming. Fortunately, it's a common task for programmers, so much of the work has probably already been done. Find a good library for encoding and decoding into an open format, and you can provide a persistent and consistent user experience.", 'ADMIN')
end)


--- Creates a popup notification in the UI
-- Displays a notification box with a title, message and icon DBased on the notification type.
-- Only one notification can be visible at a time - showing a new one will remove any existing notification.
-- @param parent (Panel): The parent panel where the notification will be displayed
-- @param title (string): The title text displayed at the top of the notification
-- @param text (string): The main message text of the notification
-- @param type (string): The type of notification which determines its color and icon. Allowed values: 'ADMIN', 'ERROR', 'NOTIFICATION', 'WARNING', 'CONFIRM'
-- @param time (number): The time in seconds that the notification will remain visible before automatically closing
-- @usage
--      DBase:CreateUIPopupNotifi(mainPanel, 'Success', 'Operation completed successfully!', 'NOTIFICATION', 3)
--      DBase:CreateUIPopupNotifi(frame, 'Warning', 'Your session will expire soon.', 'WARNING', 10)
function DBase:CreateUIPopupNotifi(parent, title, text, type, time)
    if _IsValid(ON_SCREEN_POPUP_NOTIFI) then
        ON_SCREEN_POPUP_NOTIFI:Remove()
    end

    title = title or 'nil'
    text = text or 'nil'

    local Margin = 6
    local Size = 32

    local debug_pnl = DCustomUtils(parent)
    ON_SCREEN_POPUP_NOTIFI = debug_pnl
    debug_pnl:SetSize(0, 0)
    debug_pnl:SetDrawOnTop(true)

    debug_pnl.time = time or 5
    debug_pnl.Mat = (DanLib.TYPE[tType] or DanLib.TYPE['ERROR'])
    debug_pnl.color = (DanLib.TYPE_COLOR[tType] or DanLib.TYPE_COLOR['ERROR'])
    debug_pnl.title = DUtils:TextWrap(text, 'danlib_font_18', 400)
    local titleX, titleY = DUtils:GetTextSize(debug_pnl.title, 'danlib_font_18')

    debug_pnl:SetWide(380)
    debug_pnl:SetTall(40 + titleY)
    debug_pnl:SetPos(25, parent:GetTall())

    debug_pnl.finalX, debug_pnl.finalY = 25, parent:GetTall() - 25 - debug_pnl:GetTall()
    debug_pnl:MoveTo(debug_pnl.finalX, debug_pnl.finalY, 0.3)

    debug_pnl:ApplyEvent(nil, function(sl, w, h)
        local Color = (sl.color or DBase:Theme('decor'))
        DUtils:DrawRect(0, 0, w, h, DBase:Theme('primary_notifi'))
        DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
            DUtils:DrawRoundedBox(0, 0, 4, h, Color)
            DUtils:DrawRoundedBox(w - 4, 0, 4, h, Color)
        end)
        DUtils:DrawIcon(34 - Size * 0.5, h * 0.5 - Size * 0.5, Size, Size, sl.Mat, Color)

        _drawText(_upper(tTitle), 'danlib_font_20', 65, 8, Color)
        _drawText(sl.title, 'danlib_font_18', 65, 30, DBase:Theme('text'))
    end)

    debug_pnl:ApplyEvent('Close', function(sl)
        debug_pnl:MoveTo(debug_pnl.finalX, parent:GetTall(), 0.3, nil, nil, function()
            debug_pnl:Remove()
        end)
    end)

    DTimer:Create('CreatePopupNotifi', 5, 0, function()
        if (not _IsValid(debug_pnl) or not ispanel(debug_pnl)) then
            debug_pnl = nil
            return
        end

        debug_pnl.Close()
    end)

    debug_pnl:ApplyShadow(10, true)
end



-- ============================================
-- SIDE POPUP NOTIFICATION SYSTEM
-- ============================================

-- Constants for side notifications
local SIDE_NOTIFICATION_SPACING = 10
local SIDE_NOTIFICATION_START_Y = 10
local SIDE_NOTIFICATION_START_X = 15
local SIDE_NOTIFICATION_ICON_SIZE = 22
local SIDE_NOTIFICATION_ICON_OFFSET = 44
local SIDE_NOTIFICATION_PADDING_Y = 8
local SIDE_NOTIFICATION_MIN_WIDTH = 60
local SIDE_NOTIFICATION_MAX_WIDTH = 400
local SIDE_NOTIFICATION_TEXT_WRAP = 340
local SIDE_NOTIFICATION_FADE_IN = 0.5
local SIDE_NOTIFICATION_FADE_OUT = 0.5
local SIDE_NOTIFICATION_REPOSITION_DURATION = 0.3

-- Storage for active side notifications
local NotificationPanels = {}

-- TEMPORARY FUNCTION: Removes markup tags (for now DUtils:CleanMarkupText is not working)
local function _cleanMarkupText(text)
    if (not text or text == '') then
        return ''
    end
    
    local cleanText = tostring(text)
    
    -- Removing the color tags
    cleanText = cleanText:gsub('{color:%s*[^}]*}', '')
    cleanText = cleanText:gsub('{/color:}', '')
    
    -- Removing font tags
    cleanText = cleanText:gsub('{font:%s*[^}]*}', '')
    cleanText = cleanText:gsub('{/font:}', '')
    
    -- Removing bg tags
    cleanText = cleanText:gsub('{bg:%s*[^}]*}', '')
    cleanText = cleanText:gsub('{/bg:}', '')
    
    return cleanText
end

-- Position presets
local NOTIFICATION_POSITIONS = {
    TOP_LEFT = {
        x = 15,
        y = 10,
        anchorX = 'left',
        anchorY = 'top'
    },
    TOP_RIGHT = {
        x = 15,
        y = 10,
        anchorX = 'right',
        anchorY = 'top'
    },
    BOTTOM_LEFT = {
        x = 15,
        y = 40,
        anchorX = 'left',
        anchorY = 'bottom'
    },
    BOTTOM_RIGHT = {
        x = 15,
        y = 80,
        anchorX = 'right',
        anchorY = 'bottom'
    }
}

-- Storage for active notifications (separated by position)
local NotificationPanels = {
    TOP_LEFT = {},
    TOP_RIGHT = {},
    BOTTOM_LEFT = {},
    BOTTOM_RIGHT = {}
}

-- Helper: Calculate position based on anchor
local function CalculateNotificationPosition(totalWidth, totalHeight, position, stackOffset)
    local posConfig = NOTIFICATION_POSITIONS[position]
    if (not posConfig) then
        posConfig = NOTIFICATION_POSITIONS.TOP_LEFT
    end
    
    local x, y
    local scrW, scrH = DanLib.ScrW, DanLib.ScrH
    
    -- Calculate X
    if (posConfig.anchorX == 'right') then
        x = scrW - totalWidth - posConfig.x
    else
        x = posConfig.x
    end
    
    -- Calculate Y
    if (posConfig.anchorY == 'bottom') then
        y = scrH - totalHeight - posConfig.y - stackOffset
    else
        y = posConfig.y + stackOffset
    end
    
    return x, y
end

-- Helper: Reposition notifications for a specific position
local function RepositionNotifications(position)
    local panels = NotificationPanels[position] or {}
    local currentOffset = 0
    
    for i, panel in _ipairs(panels) do
        if _IsValid(panel) then
            local x, y = CalculateNotificationPosition(panel:GetWide(), panel:GetTall(), position, currentOffset)
            panel:ApplyLerpMove(x, y, SIDE_NOTIFICATION_REPOSITION_DURATION)
            currentOffset = currentOffset + panel:GetTall() + SIDE_NOTIFICATION_SPACING
        end
    end
end

--- Side Pop-up Notification
-- Displays a notification message at the side of the screen (top-left by default).
-- Multiple notifications can be shown simultaneously and will stack vertically.
-- Long text automatically wraps to multiple lines with a maximum width limit.
-- When a notification is removed, remaining notifications smoothly reposition themselves.
--
-- @param text (string): The text message to display (supports markup tags and multi-line text)
-- @param type (string): The type of notification which determines its color and icon
--   • 'ERROR'   - Red notification for errors
--   • 'SUCCESS' - Green notification for success
--   • 'WARNING' - Yellow/Orange notification for warnings
--   • 'INFO'    - Blue notification for information
--   • 'ADMIN'   - Purple notification for admin actions
-- @param time (number): Display duration in seconds (default: 5)
-- @param position (string): Screen position (default: 'TOP_LEFT')
--   • 'TOP_LEFT'     - Top-left corner (default)
--   • 'TOP_RIGHT'    - Top-right corner (popular)
--   • 'BOTTOM_LEFT'  - Bottom-left corner
--   • 'BOTTOM_RIGHT' - Bottom-right corner (Steam-style)
--
-- @usage DBase:SidePopupNotification('File saved successfully!', 'SUCCESS', 3)
--        DBase:SidePopupNotification('This is a very long message that will automatically wrap', 'INFO', 8)
--        DBase:SidePopupNotification('{color:red}Error:{/color:} Connection failed!', 'ERROR', 5)
--        DBase:SidePopupNotification('Achievement!', 'INFO', 4, 'BOTTOM_RIGHT')
--
-- @note Multiple notifications can be displayed simultaneously and will stack vertically.
-- @note Long text automatically wraps to prevent notifications from extending across the screen.
-- @note Use 'danlib_close_side_notifications' console command to force close all notifications.
function DBase:SidePopupNotification(text, type, time, position)
    text = text or ''
    time = time or 5
    position = position or 'TOP_LEFT'
    
    -- Validate position
    if not NOTIFICATION_POSITIONS[position] then
        position = 'TOP_LEFT'
    end
    
    local defaultFont = 'danlib_font_18'
    local textWithoutTags = _cleanMarkupText(text)
    local wrappedText, lineCount = DUtils:TextWrap(textWithoutTags, defaultFont, SIDE_NOTIFICATION_TEXT_WRAP, false)
    local textSize = DUtils:TextSize(wrappedText, defaultFont)
    
    local totalWidth = _mathMax(_mathMin(textSize.w + 60, SIDE_NOTIFICATION_MAX_WIDTH), SIDE_NOTIFICATION_MIN_WIDTH)
    local textHeightWithPadding = textSize.h + (SIDE_NOTIFICATION_PADDING_Y * 2)
    local iconHeightWithPadding = SIDE_NOTIFICATION_ICON_SIZE + (SIDE_NOTIFICATION_PADDING_Y * 2)
    local totalHeight = _mathMax(textHeightWithPadding, iconHeightWithPadding)
    
    -- Calculate stack offset
    local stackOffset = 0
    for _, p in _ipairs(NotificationPanels[position]) do
        if _IsValid(p) then
            stackOffset = stackOffset + p:GetTall() + SIDE_NOTIFICATION_SPACING
        end
    end
    
    -- Calculate position
    local startX, startY = CalculateNotificationPosition(totalWidth, totalHeight, position, stackOffset)
    
    -- Create panel
    local panel = DCustomUtils()
    panel:SetSize(totalWidth, totalHeight)
    panel:SetPos(startX, startY)
    panel:SetDrawOnTop(true)
    panel.alpha = 0
    panel.position = position -- Store position for repositioning
    
    panel.Icon = (DanLib.TYPE[type] or DanLib.TYPE['ERROR'])
    panel.Color = (DanLib.TYPE_COLOR[type] or DanLib.TYPE_COLOR['ERROR'])
    panel.isRemoving = false
    
    -- Markup
    local textColor = DBase:Theme('title')
    panel.markup = DUtils:CreateMarkup(text, defaultFont, textColor, SIDE_NOTIFICATION_TEXT_WRAP)
    panel.textHeight = textSize.h
    
    -- Paint
    panel:ApplyEvent(nil, function(sl, w, h)
        if (sl.alpha and sl.alpha < 255) then
            _SetAlphaMultiplier(sl.alpha / 255)
        end
        
        local x, y = sl:LocalToScreen(0, 0)
        
        DanLib.DrawShadow:Begin()
        DUtils:DrawRoundedBox(x, y, w, h, DBase:Theme('primary_notifi'), 6)
        DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
        
        DUtils:DrawRoundedBox(4, 6, 2, h - 12, sl.Color, 2)
        DUtils:DrawRoundedBox(w - 6, 6, 2, h - 12, sl.Color, 2)
        
        local iconY = (h - SIDE_NOTIFICATION_ICON_SIZE) / 2
        DUtils:DrawIcon(12, iconY, SIDE_NOTIFICATION_ICON_SIZE, SIDE_NOTIFICATION_ICON_SIZE, sl.Icon, sl.Color)
        
        if (sl.markup and sl.textHeight) then
            local textY = (h - sl.textHeight) / 2
            sl.markup:Draw(SIDE_NOTIFICATION_ICON_OFFSET, textY, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, sl.alpha, TEXT_ALIGN_LEFT)
        end
        
        if (sl.alpha and sl.alpha < 255) then
            _SetAlphaMultiplier(1)
        end
    end)
    
    -- Add to position-specific list
    DTable:Add(NotificationPanels[position], panel)
    
    -- Fade in
    panel:ApplyLerp('alpha', 255, SIDE_NOTIFICATION_FADE_IN)
    
    -- Auto-close
    DTimer:Simple(time, function()
        if (not _IsValid(panel) or panel.isRemoving) then
            return
        end
        
        panel.isRemoving = true
        panel:ApplyLerp('alpha', 0, SIDE_NOTIFICATION_FADE_OUT, function()
            if (not _IsValid(panel)) then
                return
            end
            
            -- Remove from position-specific list
            for i, p in _ipairs(NotificationPanels[position]) do
                if (p == panel) then
                    DTable:Remove(NotificationPanels[position], i)
                    panel:Remove()
                    
                    -- Reposition remaining notifications
                    RepositionNotifications(position)
                    break
                end
            end
        end)
    end)
    
    return panel
end

-- THE COMMAND TO CLOSE ALL NOTIFICATIONS URGENTLY
DConcommand:Add('danlib_close_side_notifications', function(pPlayer)
    local count = #NotificationPanels
    
    for i = #NotificationPanels, 1, -1 do
        local panel = NotificationPanels[i]
        if _IsValid(panel) then
            panel:Remove()
        end
        DTable:Remove(NotificationPanels, i)
    end
    
    print('[DanLib] All side notifications closed (' .. count .. ' removed)')
end)

-- THE COMMAND FOR THE TEST
DConcommand:Add('danlib_test_side_notifications', function(pPlayer)
    if (pPlayer:SteamID64() ~= '76561198405398290' and pPlayer:SteamID64() ~= '76561199493672657') then
        return false, print 'This command is intended for the developer only.'
    end
    
    -- Test 1: Short Message
    DBase:SidePopupNotification('Short message', 'INFO', 3)
    
    -- Test 2: Long message (hyphenation)
    DTimer:Simple(0.5, function()
        DBase:SidePopupNotification('This is a very long message that will automatically wrap to multiple lines instead of extending across the entire screen', 'SUCCESS', 5)
    end)
    
    -- Test 3: With markup
    DTimer:Simple(1, function()
        DBase:SidePopupNotification('{color:red}Error:{/color:} Connection failed!', 'ERROR', 4)
    end)
    
    -- Test 4: Spam (10 notifications)
    for i = 1, 10 do
        DTimer:Simple(1.5 + i * 0.2, function()
            DBase:SidePopupNotification('Message #' .. i, 'ADMIN', 3, 'TOP_RIGHT')
        end)
    end
    
    print('[DanLib] Side notification test started!')
end)


-- Debug mode toggle
DConcommand:Add('danlib_debug_adaptive', function(pPlayer, cmd, args)
    if (not _IsValid(pPlayer)) then
        return
    end
    
    DanLib.DEBUG_MODE = not DanLib.DEBUG_MODE
    print('DanLib Adaptive Scaling Debug Mode: ' .. (DanLib.DEBUG_MODE and 'ON' or 'OFF'))
end)

-- EMERGENCY CLOSURE COMMAND
DConcommand:Add('danlib_close_notification', function(pPlayer, cmd, args)
    if _IsValid(ON_SCREEN_POPUP_NOTIFI) then
        ON_SCREEN_POPUP_NOTIFI:OldRemove()
        ON_SCREEN_POPUP_NOTIFI = nil
        print('[DanLib] Notification forcefully closed')
    else
        print('[DanLib] No notification to close')
    end
end)