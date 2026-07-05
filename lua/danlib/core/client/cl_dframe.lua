/***
 *   @addon         DanLib
 *   @component     UI Frame & PopupBasis
 *   @license       MIT License
 *   @version       2.0.12
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
local FRAME = DanLib.UiPanel()
local DUtils = DanLib.Utils
local DUI = DanLib.UI
local DHook = DanLib.Hook
local DTable = DanLib.Table
local DTimer = DanLib.Timer
local DCustomUtils = DanLib.CustomUtils.Create

-- Localized functions for performance
local _mathClamp = math.Clamp
local _guiMouseX = gui.MouseX
local _guiMouseY = gui.MouseY
local _guiMousePos = gui.MousePos
local _IsValid = IsValid
local _drawSimpleText = draw.SimpleText
local _ScrW = ScrW
local _ScrH = ScrH
local _pairs = pairs
local _SysTime = SysTime
local _tostring = tostring
local _vguiCursorVisible = vgui.CursorVisible
local _guiEnableScreenClicker = gui.EnableScreenClicker
local _inputIsKeyDown = input.IsKeyDown
local _inputIsMouseDown = input.IsMouseDown
local _stringFormat = string.format
local _TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local _TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local _TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local _TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local _TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM

--- Sets a callback function to be called when the frame is closed.
-- @param func (function): Callback function to execute on close.
function FRAME:SetOnCloseFunc(func)
    self.onCloseFunc = func
end

--- Closes the frame with optional callback and fade-out animation.
-- If removeOnClose is true, the frame is removed after animation.
-- Otherwise, the frame is hidden.
function FRAME:CloseFrame()
    if self.onCloseFunc then
        self.onCloseFunc()
    end

    if self.removeOnClose then
        self:SetAlpha(255)
        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
        end)
    else
        self:SetVisible(false)
    end
end

--- Initializes the frame with default settings and creates the top panel.
-- Sets up dragging functionality, creates title label and close button.
function FRAME:Init()
    self:CustomUtils()
    self:ApplyAttenuation(0.2)

    -- Internal flags
    self.IsTransparent = false
    self.IsResizing = false
    
    -- Configure default settings
    self.btnMaxim:Hide()
    self.btnMinim:Hide()
    self:SetMinHeight(100)
    self:SetMinWidth(100)
    self.lblTitle:SetText('')
    self.removeOnClose = true
    self:SetPaintShadow(true)
    self:DockPadding(0, 0, 0, 0)
    self:SetScreenLock(true)
    self.btnClose:SetVisible(false)

    -- Creating the top panel
    self.top = DCustomUtils(self)
    self.top:Pin(TOP)
    self.top:SetTall(30)
    self.top:DockPadding(0, 0, 0, 2)
    self.top:SetCursor('arrow')
    self.top:ApplyBackground(DBase:Theme('secondary'), 6, { true, true, false, false })

    -- Localized variable for closure
    local top = self.top
    
    --- Starts dragging the window when top panel is clicked.
    -- Validates cursor is within screen bounds before starting.
    local function startDragging()
        local mousex = _guiMouseX()
        local mousey = _guiMouseY()
        local scrW = _ScrW()
        local scrH = _ScrH()
        
        if (mousex < 0 or mousex > scrW or mousey < 0 or mousey > scrH) then
            return
        end
        
        self.DraggingWindow = {
            mousex - self.x,
            mousey - self.y
        }
        top:SetCursor('sizeall')
    end
    
    top.OnMousePressed = startDragging
    top.OnMouseReleased = function()
        self.DraggingWindow = nil
        top:SetCursor('arrow')
    end

    -- Creating a header
    self.title = DBase:CreateLabel(top, '', 'danlib_font_18')
    self.title:PinMargin(LEFT, 10)
    self.title:SetTextColor(DBase:Theme('text'))

    -- Creating a close button
    self.closeBtn = DBase.CreateUIButton(top, {
        background = false,
        hover = false,
        hoverClick = false,
        wide = 30,
        dock = { RIGHT },
        tooltip = { DBase:L('#close'), nil, nil, TOP },
        icon = { 'jWj7VqX', 24 },
        click = function()
            self:CloseFrame()
        end
    })

    -- Think hook for processing window dragging
    local baseThink = self.Think
    self:ApplyEvent('Think', function(sl)
        if baseThink then baseThink(sl) end
        
        local dragging = sl.DraggingWindow
        if (dragging and type(dragging) == 'table') then
            local mousex = _guiMouseX()
            local mousey = _guiMouseY()
            
            -- Stop dragging if cursor leaves screen
            local scrW = _ScrW()
            local scrH = _ScrH()
            if (mousex < 0 or mousex > scrW or mousey < 0 or mousey > scrH) then
                sl.DraggingWindow = nil
                top:SetCursor('arrow')
                return
            end
            
            -- Clamp cursor to screen bounds
            mousex = _mathClamp(mousex, 1, scrW - 1)
            mousey = _mathClamp(mousey, 1, scrH - 1)
            
            local x = mousex - dragging[1]
            local y = mousey - dragging[2]
            
            -- Clamp window position if screen lock is enabled
            if sl:GetScreenLock() then
                x = _mathClamp(x, 0, scrW - sl:GetWide())
                y = _mathClamp(y, 0, scrH - sl:GetTall())
            end
            
            sl:SetPos(x, y)
        end
    end)
end

--- Adds a settings button to the frame's top panel.
-- @param func (function): Function to execute when settings button is clicked.
-- @return (Panel): Returns self for method chaining.
function FRAME:SetSettingsFunc(func)
    DBase.CreateUIButton(self.top, {
        background = false,
        hover = false,
        hoverClick = false,
        wide = 30,
        dock = { RIGHT },
        tooltip = { DBase:L('#settings'), nil, nil, TOP },
        icon = { 'lgHTnoN', 24 },
        click = func or function() end
    })
    return self
end

--- Adds transparency toggle functionality to the frame.
-- Creates a button that toggles between transparent (80% alpha) and opaque (100% alpha) states.
-- In transparent mode, the cursor is hidden and can be shown with F3.
-- Hotkey: ALT+H to toggle transparency from anywhere.
-- @return (Panel): Returns self for method chaining.
function FRAME:Transparency()
    local initialTransparency = 80
    DBase.CreateUIButton(self.top, {
        background = false,
        hover = false,
        hoverClick = false,
        wide = 30,
        dock = { RIGHT },
        tooltip = { 'Toggle transparency (ALT+H)', nil, nil, TOP },
        icon = { 'K3QJsue', 24 },
        click = function()
            self:ToggleTransparency()
        end
    })
    
    -- Internal state tracking
    local topInputEnabled = true
    local top = self.top
    local hookName = 'DanLib.TransparencyFrame.' .. _tostring(self)
    local hookShouldRun = false
    
    --- Sets mouse and keyboard input for top panel children.
    -- @param enabled (boolean): Whether to enable or disable input.
    local function SetTopChildrenInput(enabled)
        for _, child in _pairs(top:GetChildren()) do
            child:SetMouseInputEnabled(enabled)
            child:SetKeyboardInputEnabled(enabled)
        end
    end
    
    --- Toggles transparency mode on/off.
    -- Handles input state, popup status, and cursor visibility automatically.
    function self:ToggleTransparency()
        self.IsTransparent = not self.IsTransparent
        
        if self.IsTransparent then
            -- === TRANSPARENT MODE ===
            self:SetAlpha(255)
            self:AlphaTo(initialTransparency, 0.2)
            
            -- Disable input for frame and children
            self:SetKeyboardInputEnabled(false)
            self:SetMouseInputEnabled(false)
            
            for _, child in _pairs(self:GetChildren()) do
                child:SetKeyboardInputEnabled(false)
                child:SetMouseInputEnabled(false)
            end
            
            topInputEnabled = false
            self._wasPopup = self.IsPopup
            self.IsPopup = false
            
            -- Force hide cursor
            DTimer:Simple(0.05, function()
                if (_IsValid(self) and self.IsTransparent) then
                    _guiEnableScreenClicker(false)
                end
            end)
            
            hookShouldRun = true
            -- Think hook for smart cursor management
            DHook:Add('Think', hookName, function()
                if (not _IsValid(self) or not self.IsTransparent or not hookShouldRun) then
                    DHook:Remove('Think', hookName)
                    return
                end
                
                if _vguiCursorVisible() then
                    -- Cursor visible - enable top panel and buttons
                    if (not topInputEnabled) then
                        top:SetMouseInputEnabled(true)
                        top:SetKeyboardInputEnabled(true)
                        SetTopChildrenInput(true)
                        topInputEnabled = true
                    end
                else
                    -- Cursor hidden - disable top panel
                    if topInputEnabled then
                        top:SetMouseInputEnabled(false)
                        top:SetKeyboardInputEnabled(false)
                        SetTopChildrenInput(false)
                        topInputEnabled = false
                    end
                    _guiEnableScreenClicker(false)
                end
            end)
                        
        else
            -- === OPAQUE MODE ===
            self:AlphaTo(255, 0.2)
            
            hookShouldRun = false
            DHook:Remove('Think', hookName)
            
            top:SetMouseInputEnabled(true)
            top:SetKeyboardInputEnabled(true)
            SetTopChildrenInput(true)
            
            -- Re-enable all input
            self:SetKeyboardInputEnabled(true)
            self:SetMouseInputEnabled(true)
            
            for _, child in _pairs(self:GetChildren()) do
                child:SetKeyboardInputEnabled(true)
                child:SetMouseInputEnabled(true)
            end
            
            topInputEnabled = true
            
            -- Restore popup status
            if (self._wasPopup ~= false) then
                self.IsPopup = true
                self:MakePopup()
            end
        end
    end
    
    -- ALT+H hotkey handler
    local lastHotkeyState = false
    local originalThink = self.Think
    local KEY_LALT_CACHE = KEY_LALT
    local KEY_RALT_CACHE = KEY_RALT
    local KEY_H_CACHE = KEY_H
    
    self.Think = function(sl)
        if originalThink then
            originalThink(sl)
        end
        
        if (sl.IsTransparent ~= nil) then
            local altPressed = _inputIsKeyDown(KEY_LALT_CACHE) or _inputIsKeyDown(KEY_RALT_CACHE)
            local hPressed = _inputIsKeyDown(KEY_H_CACHE)
            local hotkeyPressed = altPressed and hPressed
            
            if (hotkeyPressed and not lastHotkeyState) then
                sl:ToggleTransparency()
            end
            lastHotkeyState = hotkeyPressed
        end
    end
    
    -- Cleanup hook on frame removal
    local originalOnRemove = self.OnRemove
    self.OnRemove = function(pnl)
        hookShouldRun = false
        DHook:Remove('Think', hookName)
        if originalOnRemove then
            originalOnRemove(pnl)
        end
    end
    
    self.IsTransparent = false
    return self
end

--- Enables user-controlled resizing via a handle in the bottom-right corner.
-- Displays current dimensions while resizing.
-- Respects minimum width/height constraints.
-- @return (Panel): Returns self for method chaining.
function FRAME:EnableUserResize()
    self.UserResize = DCustomUtils(self)
    self.UserResize:SetMouseInputEnabled(true)
    self.UserResize:SetCursor('sizenwse')
    self.UserResize:SetSize(18, 18)
    self.UserResize:MoveToFront()
    
    -- Localized variables for closure
    local userResize = self.UserResize
    local frame = self
    
    -- Draw resize icon
    userResize:ApplyEvent(nil, function(sl, w, h)
        local size = 16
        local offset = (w - size) / 2
        DUtils:DrawIcon(offset, offset, size, size, 'QAAyhNn', DBase:Theme('mat', 150))
    end)
    
    userResize:ApplyEvent('OnMousePressed', function()
        frame.DraggingWindow = true 
        frame.IsResizing = true
    end)
    
    userResize:ApplyEvent('Think', function()
        if frame.DraggingWindow == true then
            if _inputIsMouseDown(MOUSE_LEFT) then
                local x, y = _guiMousePos()
                
                if (not frame.StartingCoords) then
                    frame.StartingCoords = { x, y }
                end

                if (not frame.StartingSize) then
                    frame.StartingSize = { frame:GetSize() }
                end

                local screenW, screenH = _ScrW(), _ScrH()
                local minW = frame:GetMinWidth() or 200
                local minH = frame:GetMinHeight() or 200
                
                -- Calculate new dimensions with constraints
                local newWidth = _mathClamp(frame.StartingSize[1] + (x - frame.StartingCoords[1]), minW, screenW)
                local newHeight = _mathClamp(frame.StartingSize[2] + (y - frame.StartingCoords[2]), minH, screenH)
                
                if (x >= 0 and x <= screenW and y >= 0 and y <= screenH) then
                    frame:SetSize(newWidth, newHeight)
                end
                frame:InvalidateChildren(true)
            else
                frame.StartingCoords = nil
                frame.StartingSize = nil
                frame.DraggingWindow = false
                frame.IsResizing = false

                -- Recursively rerender markup children
                local function rerenderChildren(children)
                    for i = 1, #children do
                        local child = children[i]
                        if child.RerenderMarkups then
                            child:RerenderMarkups()
                        end
                        rerenderChildren(child:GetChildren())
                    end
                end
                rerenderChildren(frame:GetChildren())
            end
        end
    end)
    
    return self
end

--- Draws overlay showing current dimensions while resizing.
-- @param w (number): Frame width in pixels.
-- @param h (number): Frame height in pixels.
local font = 'danlib_font_18'
local color = DBase:Theme('decor')

function FRAME:PaintOver(w, h)
    if self.IsResizing then
        DUtils:DrawRoundedBox(0, 0, w, h, Color(10, 10, 10, 240))
        local sizeText = _stringFormat('(%dpx x %dpx)', w, h)
        _drawSimpleText('Editing the size ', font, w / 2, h / 2, color, _TEXT_ALIGN_CENTER, _TEXT_ALIGN_BOTTOM)
        _drawSimpleText(sizeText, font, w / 2, h / 2, color, _TEXT_ALIGN_CENTER, _TEXT_ALIGN_TOP)
        _drawSimpleText(w .. 'px', font, w / 2, h - 15, color, _TEXT_ALIGN_CENTER, _TEXT_ALIGN_BOTTOM)
        _drawSimpleText(h .. 'px', font, w - 15, h / 2, color, _TEXT_ALIGN_RIGHT, _TEXT_ALIGN_CENTER)
        _drawSimpleText(w .. 'px', font, w / 2, 15, color, _TEXT_ALIGN_CENTER, _TEXT_ALIGN_TOP)
        _drawSimpleText(h .. 'px', font, 15, h / 2, color, _TEXT_ALIGN_LEFT, _TEXT_ALIGN_CENTER)
    end
end

--- Sets the frame icon (currently unused).
-- @param str (string): Path to icon file.
function FRAME:SetIcon(str)
    self.imgIcon = str
end

--- Sets minimum dimensions for frame resizing.
-- @param width (number): Minimum width in pixels.
-- @param height (number): Minimum height in pixels.
function FRAME:SetMinWMinH(width, height)
    self:SetMinWidth(width)
    self:SetMinHeight(height)
end

--- Performs layout of frame elements.
-- Called automatically when frame size changes.
-- @param w (number): Frame width in pixels.
-- @param h (number): Frame height in pixels.
function FRAME:PerformLayout(w, h)
    for _, child in _pairs(self:GetChildren()) do
        child:InvalidateLayout(true)
    end

    if _IsValid(self.UserResize) then
        self.UserResize:AlignRight(0)
        self.UserResize:AlignBottom(0)
    end

    if self.PostPerformLayout then
        self:PostPerformLayout()
    end
end

--- Sets the frame title text.
-- @param str (string): Title text to display.
function FRAME:SetTitle(str)
    self.title:SetText(str or '')
    self.title:SizeToContents()
end

--- Draws the frame background with optional shadow.
-- @param w (number): Frame width in pixels.
-- @param h (number): Frame height in pixels.
function FRAME:Paint(w, h)
    if (not self.disableShadows) then
        DanLib.DrawShadow:Begin()
        local x, y = self:LocalToScreen(0, 0)
        DUtils:DrawRoundedBox(x, y, w, h, self.Background or DBase:Theme('background'))
        DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
    else
        DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('background'))
    end
end

--- Shows or hides the close button.
-- @param show (boolean): True to show, false to hide.
function FRAME:ShowCloseButton(show)
    self.closeBtn:SetVisible(show)
end

--- Sets custom background color for the frame.
-- @param background (Color): Background color.
function FRAME:SetBackground(background)
    self.Background = background
end

--- Enables or disables shadow drawing for the frame.
-- @param disable (boolean): True to disable shadows, false to enable.
function FRAME:DisableShadows(disable)
    self.disableShadows = disable
end

FRAME:SetBase('DFrame')
FRAME:Register('DanLib.UI.Frame')


--- Creates a new DanLib UI frame.
-- @param parent (Panel|nil): Parent panel, or nil for no parent.
-- @return (Panel): New DanLib.UI.Frame instance.
-- @usage
--   local frame = DBase.CreateUIFrame()
--   frame:SetSize(400, 300)
--   frame:SetTitle('My Frame')
--   frame:Center()
--   frame:MakePopup()
--   frame:Transparency() -- Enable transparency toggle
--   frame:EnableUserResize() -- Enable resizing
function DBase.CreateUIFrame(parent)
    return DCustomUtils(parent or nil, 'DanLib.UI.Frame')
end




local BASIS = DanLib.UiPanel()
--- Initializes the popup basis with default settings.
-- Creates fullscreen background with blur, centered main panel, header, and close button.
-- Automatically animates panel appearance with fade and size animations.
function BASIS:Init()
    -- Fullscreen background setup
    self:SetSize(_ScrW(), _ScrH())
    self:MakePopup()
    self:SetTitle('')
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetAlpha(0)
    self:AlphaTo(255, 0.1)
    self:SetDrawHeader(true)

    -- Localization for closure
    local scrW = _ScrW()
    local scrH = _ScrH()
    
    -- Invisible background button for closing on click
    self.backButton = DBase.CreateUIButton(self, {
        background = false,
        hover = false,
        hoverClick = false,
        wide = 30,
        dock = { FILL },
        click = function()
            self:Close()
        end
    })
    self.backButton:SetCursor('arrow')

    -- Main centered panel
    self.mainPanel = DCustomUtils(self)
    self.mainPanel:SetSize(scrW * 0.15, 0)
    self.mainPanel:Center()
    local mainPanel = self.mainPanel
    mainPanel:ApplyEvent(nil, function(sl, w, h)
        if (not sl.disableShadows) then
            local x, y = sl:LocalToScreen(0, 0)
            DanLib.DrawShadow:Begin()
            DUtils:DrawRoundedBox(x, y, w, h, DBase:Theme('background'))
            DanLib.DrawShadow:End(1, 1, 1)
        else
            DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('background'))
        end
    end)
    
    mainPanel:ApplyEvent('OnSizeChanged', function(sl)
        sl:Center()
    end)

    -- Header panel
    self.top = DCustomUtils(mainPanel)
    self.top:Pin(TOP)
    self.top:SetTall(30)
    self.top:DockPadding(0, 0, 0, 2)
    self.top.size = 16
    
    local top = self.top
    top:ApplyEvent(nil, function(sl, w, h)
        if (not self.headerShouldDraw) then
            return
        end
        
        DUtils:DrawRoundedTopBox(0, 0, w, h, DBase:Theme('line_up'))
        
        local textX = self.strIcon and 34 or 10
        _drawSimpleText(self.headerText or '', 'danlib_font_18', textX, h / 2 - 1, DBase:Theme('text'), _TEXT_ALIGN_LEFT, _TEXT_ALIGN_CENTER)

        if self.strIcon then
            DUtils:DrawIconOrMaterial(10, h / 2 - sl.size / 2, sl.size, self.strIcon, self.strIconCol)
        end
    end)

    -- Close button
    self.closeBtn = DBase.CreateUIButton(top, {
        background = false,
        hover = false,
        hoverClick = false,
        wide = 30,
        dock = { RIGHT },
        tooltip = { DBase:L('#close'), nil, nil, TOP },
        icon = { 'jWj7VqX', 24 },
        click = function()
            self:Close()
        end
    })

    -- Internal state
    self.initFinished = true
    mainPanel.targetH = top:GetTall()
    mainPanel:SetTall(mainPanel.targetH)
    self.startTime = _SysTime()
    self.blurStartTime = self.startTime

    -- Track open popups so only the topmost one draws the blur overlay.
    -- When the top popup closes, the new top gets a fresh blurStartTime
    -- so Derma_DrawBackgroundBlur fades in smoothly.
    DanLib._popupStack = DanLib._popupStack or { }
    DTable:Add(DanLib._popupStack, self)
    local _origOnRemove = self.OnRemove
    self.OnRemove = function(pnl)
        if _origOnRemove then
            _origOnRemove(pnl)
        end
        
        local stack = DanLib._popupStack
        for i = #stack, 1, -1 do
            if (stack[i] == pnl) then
                DTable:Remove(stack, i)
                break
            end
        end
        -- Give the newly exposed popup a fresh blur start so it fades in
        local newTop = stack[#stack]
        if newTop and _IsValid(newTop) then
            newTop.blurStartTime = _SysTime()
        end
    end
end

--- Closes the popup with fade and size animations.
-- Calls OnClose callback if defined, then removes the panel.
function BASIS:Close()
    self.FullyOpened = false
    if self.OnClose then
        self:OnClose()
    end

    self:AlphaTo(0, 0.2)
    self.mainPanel:SizeTo(self.mainPanel:GetWide(), 0, 0.2, 0, -1, function()
        self:Remove()
    end)
end

--- Enables or disables shadow rendering for the main panel.
-- @param disable (boolean): True to disable shadows, false to enable.
-- @return (Panel): Returns self for method chaining.
function BASIS:DisableShadows(disable)
    self.disableShadows = disable
    return self
end

--- Sets the header text displayed in the top panel.
-- @param header (string): Header text to display.
-- @return (Panel): Returns self for method chaining.
function BASIS:SetHeader(header)
    self.headerText = header
    return self
end

--- Controls whether the header is drawn.
-- @param shouldDraw (boolean): True to show header, false to hide.
-- @return (Panel): Returns self for method chaining.
function BASIS:SetDrawHeader(shouldDraw)
    self.headerShouldDraw = shouldDraw
    return self
end

--- Sets the width of the main panel.
-- @param width (number): Panel width in pixels.
-- @return (Panel): Returns self for method chaining.
function BASIS:SetPopupWide(width)
    self.mainPanel:SetWide(width)
    return self
end

--- Gets the current width of the main panel.
-- @return (number): Panel width in pixels.
function BASIS:GetPopupWide()
    return self.mainPanel:GetWide()
end

--- Sets the icon displayed in the header.
-- @param iconID (string): Icon identifier or material path.
-- @param color (Color|nil): Icon color (optional).
-- @return (Panel): Returns self for method chaining.
function BASIS:SetIcon(iconID, color)
    self.strIcon = iconID
    self.strIconCol = color
    return self
end

--- Gets the target height of the main panel (including header).
-- @return (number): Panel height in pixels.
function BASIS:GetPopupTall()
    return self.mainPanel.targetH
end

--- Shows or hides the close button in the header.
-- @param show (boolean): True to show, false to hide.
-- @return (Panel): Returns self for method chaining.
function BASIS:CloseButtonShow(show)
    self.closeBtn:SetVisible(show)
    return self
end

--- Adds a settings button to the popup's top panel.
-- @param text (string|nil): Tooltip text (default: localized '#settings').
-- @param icon (string|nil): Icon identifier (default: 'lgHTnoN').
-- @param func (function): Callback function when clicked.
-- @return (Panel): Returns self for method chaining.
function BASIS:SetSettingsFunc(text, icon, func)
    DBase.CreateUIButton(self.top, {
        background = false,
        hover = false,
        hoverClick = false,
        wide = 30,
        dock = { RIGHT },
        tooltip = { text or DBase:L('#settings'), nil, nil, TOP },
        icon = { icon or 'lgHTnoN', 24 },
        click = func or function() end
    })
    return self
end

--- Shows or hides the background close button (clicking outside to close).
-- @param show (boolean): True to enable background closing, false to disable.
-- @return (Panel): Returns self for method chaining.
function BASIS:BackgroundCloseButtonShow(show)
    self.backButton:SetVisible(show)
    return self
end

--- Sets the content height and animates the panel to target size.
-- Calls OnOpen callback when animation completes.
-- @param extraH (number): Content height in pixels (excluding header).
-- @return (Panel): Returns self for method chaining.
function BASIS:SetExtraHeight(extraH)
    local mainPanel = self.mainPanel
    mainPanel.targetH = self.top:GetTall() + extraH
    
    mainPanel:SizeTo(mainPanel:GetWide(), mainPanel.targetH, 0.3, 0, -1, function()
        self.FullyOpened = true
        if self.OnOpen then
            self:OnOpen()
        end
    end)
    
    return self
end

--- Automatically parents newly added panels to mainPanel instead of background.
-- @param panel (Panel): Child panel being added.
function BASIS:OnChildAdded(panel)
    if (not self.initFinished) then
        return
    end
    panel:SetParent(self.mainPanel)
end

--- Draws the background blur effect.
-- Only the topmost popup draws the blur; others stay transparent.
-- @param w (number): Panel width in pixels.
-- @param h (number): Panel height in pixels.
function BASIS:Paint(w, h)
    local stack = DanLib._popupStack
    if stack and stack[#stack] == self then
        Derma_DrawBackgroundBlur(self, self.blurStartTime or self.startTime)
    end
end

BASIS:SetBase('DFrame')
BASIS:Register('DanLib.UI.PopupBasis')

--- Creates a new DanLib popup basis panel.
-- Centered popup with blur background, header, and smooth animations.
-- @param parent (Panel|nil): Parent panel, or nil for no parent.
-- @return (Panel): New DanLib.UI.PopupBasis instance.
-- @usage
--   local popup = DBase.CreateUIPopupBasis()
--   popup:SetPopupWide(500)
--   popup:SetHeader('Settings')
--   popup:SetIcon('lgHTnoN', Color(255, 255, 255))
--   popup:SetExtraHeight(400)
--   popup:CloseButtonShow(true)
--   popup:BackgroundCloseButtonShow(true)
--   popup:SetSettingsFunc('Options', 'lgHTnoN', function()
--       print('Settings clicked')
--   end)
--   
--   -- Add content
--   local label = DBase:CreateLabel(popup, 'Content', 'DermaDefault')
--   label:Dock(TOP)
function DBase.CreateUIPopupBasis(parent)
    return DCustomUtils(parent or nil, 'DanLib.UI.PopupBasis')
end
