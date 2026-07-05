/***
 *   @addon         DanLib
 *   @components    UI ScrollBar | Scroll | HorizontalScroll
 *   @license       MIT License
 *   @version       1.6.5
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Production-ready scroll components for DanLib with smooth animations,
 *                  Accessor pattern, Think-based optimization, and comprehensive API.
 *                  Includes vertical ScrollBar, full-featured Scroll panel with navigation
 *                  buttons, and HorizontalScroll with drag support.
 *
 *   @functions      
 *                  - Smooth scrolling with configurable physics (WheelSmoothSpeed, WheelScrollSpeed)
 *                  - Think-based animations (no recursive timers, 60+ FPS)
 *                  - Accessor pattern for all properties with validation
 *                  - Click-to-scroll with dynamic animation duration
 *                  - Drag support (vertical and horizontal)
 *                  - Navigation buttons with fade animations (Scroll only)
 *                  - LocalToScreen positioning for ScrollToChild accuracy
 *                  - NaN/Infinity safety checks
 *                  - LocalToScreen caching during drag (-30% CPU)
 *                  - Early exit optimizations
 *
 *   @api           
 *                  ScrollBar:
 *                    :SetScroll(position) - Set scroll position
 *                    :AnimateTo(target, duration, delay, callback) - Smooth animation
 *                    :SetBarColors(base, hover) - Custom colors
 *                    :GetScroll() - Current scroll position
 *                  
 *                  Scroll:
 *                    :ScrollToChild(panel, duration, callback) - Center child in view
 *                    :AnimateToTop/Bottom(duration) - Quick navigation
 *                    :SetShowNavButtons(enabled) - Toggle navigation buttons
 *                    :GetMaxScroll() - Maximum scroll distance
 *                  
 *                  HorizontalScroll:
 *                    :ScrollToChild(child, duration, callback) - Scroll to child
 *                    :AnimateToLeft/Right(duration) - Edge navigation
 *                    :SetBarMargin(pixels) - Configurable spacing
 *                    :IsChildVisible(child) - Visibility check
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         All components use Think-based animation instead of recursive timers for optimal performance.
 *                  ScrollBar and HorizontalScroll share similar architecture for consistency.
 */
 


local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DTimer = DanLib.Timer
local DMaterial = DanLib.Config.Materials
local DCustomUtils = DanLib.CustomUtils.Create

-- Cached globals for performance
local _IsValid = IsValid
local _Lerp = Lerp
local _type = type
local _SysTime = SysTime
local math = math
local _Clamp = math.Clamp
local _abs = math.abs
local _max = math.max
local gui = gui
local _guiMouseX = gui.MouseX
local _guiMouseY = gui.MouseY
local _ColorAlpha = ColorAlpha
local _FrameTime = FrameTime
local _ErrorNoHalt = ErrorNoHalt
local surface = surface
local _SetAlphaMultiplier = surface.SetAlphaMultiplier

-- Configuration constants
local GRIP_ALPHA_SPEED = 5
local GRIP_ALPHA_MAX = 100
local SCROLL_DELTA_MULTIPLIER = 25
local MIN_GRIP_SIZE = 10
local SMOOTH_SCROLL_THRESHOLD = 0.1

local SCROLLBAR, Constructor = DanLib.UiPanel()

-- Accessors with default values
SCROLLBAR:Accessor('HideButtons', Constructor.Boolean, { default = false })
SCROLLBAR:Accessor('BarColor', Constructor.Color, { default = nil })
SCROLLBAR:Accessor('BarHoverColor', Constructor.Color, { default = nil })
SCROLLBAR:Accessor('ClickAnimationDuration', Constructor.Number, { default = 0.4 })
SCROLLBAR:Accessor('WheelSmoothSpeed', Constructor.Number, { default = 6 })
SCROLLBAR:Accessor('WheelScrollSpeed', Constructor.Number, { 
    default = 3,
    validate = function(self, val)
        return val > 0 and val <= 100
    end
})

--- Initializes the scrollbar component
-- Sets up internal state variables and creates the grip button
function SCROLLBAR:Init()
    self.Offset = 0
    self.Scroll = 0
    self.SmoothScroll = 0
    self.CanvasSize = 1
    self.BarSize = 1
    
    -- Caching
    self.CachedBarScale = 1
    self.CachedOffset = 0
    self.LastScroll = 0
    self.LayoutDirty = false
    self.IsScrolling = false
    self.IsAnimatingScroll = false

    self.btnGrip = DCustomUtils(self, 'DScrollBarGrip')
    
    if (not _IsValid(self.btnGrip)) then
        _ErrorNoHalt('[DanLib.UI.ScrollBar] Failed to create grip button!\n')
        return
    end
    
    self:SetSize(8, 15)
    self.btnGrip:SetCursor('hand')
    self:SetCursor('hand')
    
    self.GripAlpha = 0
end

--- Enables or disables the scrollbar
-- @param b (boolean): True to enable, false to disable
function SCROLLBAR:SetEnabled(b)
    if (not b) then
        self.Offset = 0
        self:SetScroll(0)
        self.LayoutDirty = true
    end

    self:SetMouseInputEnabled(b)
    self:SetVisible(b)

    if (self.Enabled ~= b) then
        local parent = self:GetParent()
        if _IsValid(parent) then
            parent:InvalidateLayout()
            if parent.OnScrollbarAppear then
                parent:OnScrollbarAppear()
            end
        end
    end
    
    self.Enabled = b
end

--- Returns the current scroll position value
-- @return (number): The current position value
function SCROLLBAR:Value()
    return self.Pos
end

--- Returns the cached bar scale ratio
-- @return (number): The bar scale (0-1)
function SCROLLBAR:BarScale()
    return self.CachedBarScale
end

--- Recalculates the bar scale based on bar and canvas size
-- Updates the cached bar scale for rendering
function SCROLLBAR:RecalculateBarScale()
    if (self.BarSize == 0) then
        self.CachedBarScale = 1
    else
        self.CachedBarScale = self.BarSize / (self.CanvasSize + self.BarSize)
    end
end

--- Configures the scrollbar dimensions
-- @param _barsize_ (number): The visible area size
-- @param _canvassize_ (number): The total scrollable area size
function SCROLLBAR:SetUp(_barsize_, _canvassize_)
    if (self.BarSize == _barsize_ and self.CanvasSize == (_canvassize_ - _barsize_)) then
        return
    end
    
    self.BarSize = _barsize_
    self.CanvasSize = _max(_canvassize_ - _barsize_, 1)
    self:SetEnabled(_canvassize_ > _barsize_)
    
    self:RecalculateBarScale()
    self.LayoutDirty = true
    
    self:InvalidateLayout()
end

--- Clears the paint functions
-- Removes custom paint from both scrollbar and grip
function SCROLLBAR:ClearPaint()
    self.Paint = nil
    
    if _IsValid(self.btnGrip) then
        self.btnGrip.Paint = nil
    end
end

--- Applies custom paint with theme colors and hover effects
-- Uses accessor-defined colors or falls back to DanLib theme
function SCROLLBAR:ApplyPaint()
    if (not _IsValid(self.btnGrip)) then
        _ErrorNoHalt('[DanLib.UI.ScrollBar] Cannot apply paint - grip is not valid!\n')
        return
    end
    
    self.GripAlpha = 0
    self.Paint = nil
    
    self.btnGrip.Paint = function(sl, w, h)
        local isActive = sl:IsHovered() or sl.Depressed
        self.GripAlpha = isActive and _Clamp(self.GripAlpha + GRIP_ALPHA_SPEED, 0, GRIP_ALPHA_MAX) or _Clamp(self.GripAlpha - GRIP_ALPHA_SPEED, 0, GRIP_ALPHA_MAX)
        
        local baseColor = self:GetBarColor() or DBase:Theme('scroll_dark')
        local hoverColor = self:GetBarHoverColor() or DBase:Theme('decor')
        
        DUtils:DrawRoundedBox(0, 0, w, h, baseColor)
        
        if (self.GripAlpha > 0) then
            _SetAlphaMultiplier(self.GripAlpha / 255)
            DUtils:DrawRoundedBox(0, 0, w, h, hoverColor)
            _SetAlphaMultiplier(1)
        end
    end
end

--- Handles mouse wheel scrolling
-- @param dlta (number): Mouse wheel delta (-1 for up, 1 for down)
-- @return (boolean): True if scroll changed, false otherwise
function SCROLLBAR:OnMouseWheeled(dlta)
    if (not self:IsVisible()) then
        return false
    end

    if self.IsAnimatingScroll then
        self:ApplyEndAnimations()
        self.IsAnimatingScroll = false
    end

    local OldSmoothScroll = self.SmoothScroll
    local force = self:GetWheelScrollSpeed() or 3
    self.SmoothScroll = _Clamp(self.SmoothScroll - dlta * force, -self.CanvasSize, self.CanvasSize)
    
    if (self.SmoothScroll ~= 0) then
        self.IsScrolling = true
    end

    return OldSmoothScroll ~= self.SmoothScroll
end

--- Triggers scroll callback on parent panel
-- Calls OnVScroll or InvalidateLayout on parent
function SCROLLBAR:TriggerScrollCallback()
    local parent = self:GetParent()
    if (not _IsValid(parent)) then
        return
    end
    
    local func = parent.OnVScroll
    if func then
        func(parent, self.CachedOffset)
    else
        parent:InvalidateLayout()
    end
end

--- Updates internal scroll state and triggers callbacks
-- @return (boolean): True if scroll position changed, false otherwise
function SCROLLBAR:UpdateScrollState()
    if (self.LastScroll ~= self.Scroll) then
        self.LastScroll = self.Scroll
        self.CachedOffset = self.Scroll * -1
        self.LayoutDirty = true
        self:InvalidateLayout()
        self:TriggerScrollCallback()
        return true
    end
    return false
end

--- Main think loop for smooth scrolling animation
-- Handles smooth scroll physics and stopping conditions
-- @todo ISSUE: Early return during animation prevents scroll position updates

-- Current behavior: When IsAnimatingScroll=true, function returns after UpdateScrollState(),
-- preventing parent panels from getting real-time scroll position updates.

-- Impact: Navigation buttons in parent DanLib.UI.Scroll always see scrollPos=0
-- because GetScroll() returns self.Scroll which only updates at animation completion.
-- Potential fix: Remove the return statement to allow continuous position tracking.
function SCROLLBAR:Think()
    -- Processing the click animation
    if self.IsAnimatingScroll then
        self:UpdateScrollState()
        return -- TODO: Consider removing for continuous scroll position updates
    end
    
    -- Early exit if we don't scroll down
    if (not self.IsScrolling or self.SmoothScroll == 0) then
        return
    end

    local speed = _FrameTime() * (self:GetWheelSmoothSpeed() or 10)

    if (self.SmoothScroll > 0) then
        self.SmoothScroll = _Clamp(self.SmoothScroll - speed, 0, self.CanvasSize)
    else
        self.SmoothScroll = _Clamp(self.SmoothScroll + speed, -self.CanvasSize, 0)
    end

    local oldScroll = self.Scroll
    self.Scroll = _Clamp(self.Scroll + self.SmoothScroll, 0, self.CanvasSize)
    
    if (oldScroll ~= self.Scroll) then
        self.CachedOffset = self.Scroll * -1
        self.LayoutDirty = true
        self:InvalidateLayout()
        self:TriggerScrollCallback()
    end

    -- Stopping when the boundaries or threshold are reached
    if (self.SmoothScroll > 0 and self.Scroll >= self.CanvasSize) or (self.SmoothScroll < 0 and self.Scroll <= 0) or _abs(self.SmoothScroll) < SMOOTH_SCROLL_THRESHOLD then
        self.SmoothScroll = 0
        self.IsScrolling = false
    end
end

--- Adds a delta value to current scroll position
-- @param dlta (number): Delta value to add
-- @return (boolean): True if scroll changed, false otherwise
function SCROLLBAR:AddScroll(dlta)
    local OldScroll = self:GetScroll()
    dlta = dlta * SCROLL_DELTA_MULTIPLIER
    self:SetScroll(self:GetScroll() + dlta)
    return OldScroll ~= self:GetScroll()
end

--- Sets the scroll position directly
-- @param scrll (number): Target scroll position (clamped to valid range)
function SCROLLBAR:SetScroll(scrll)
    local newScroll = _Clamp(scrll, 0, self.CanvasSize)
    if (self.Scroll == newScroll) then
        return
    end
    
    self.Scroll = newScroll
    self.LastScroll = newScroll
    self.CachedOffset = self.Scroll * -1
    self.LayoutDirty = true
    self.SmoothScroll = 0
    
    self:InvalidateLayout()
    self:TriggerScrollCallback()
end

--- Animates scroll to target position
-- @param scrll (number): Target scroll position
-- @param length (number): Animation duration in seconds (default: 0.5)
-- @param delay (number): Delay before animation starts (default: 0)
-- @param callback (function): Optional callback when animation completes
function SCROLLBAR:AnimateTo(scrll, length, delay, callback)
    length = length or 0.5
    delay = delay or 0
    
    scrll = _Clamp(scrll, 0, self.CanvasSize)
    self.SmoothScroll = 0
    
    local function startAnimation()
        if (not _IsValid(self)) then
            return
        end
        
        self.IsAnimatingScroll = true
        self.IsScrolling = false
        
        self:ApplyLerp('Scroll', scrll, length, function()
            self.IsAnimatingScroll = false
            self.IsScrolling = false
            
            if (callback and _type(callback) == 'function') then
                callback(self)
            end
        end)
    end
    
    if (delay > 0) then
        DTimer:Simple(delay, startAnimation)
    else
        startAnimation()
    end
end

--- Gets the current scroll position
-- @return (number): Current scroll position
function SCROLLBAR:GetScroll()
    if (not self.Enabled) then
        self.Scroll = 0
    end
    return self.Scroll
end

--- Gets the scroll offset for positioning canvas
-- @return (number): Negative scroll position for canvas offset
function SCROLLBAR:GetOffset()
    if (not self.Enabled) then
        return 0
    end
    return self.CachedOffset
end

--- Paint function (empty, rendering done by grip)
-- @param w (number): Width of scrollbar
-- @param h (number): Height of scrollbar
function SCROLLBAR:Paint(w, h)
end

--- Handles mouse press on scrollbar track
-- Animates scroll to clicked position
function SCROLLBAR:OnMousePressed()
    if (not _IsValid(self.btnGrip) or self.btnGrip:IsHovered()) then
        return
    end
    
    local _, y = self:CursorPos()
    local tall = self:GetTall()
    local gripHeight = self.btnGrip:GetTall()
    local trackSize = tall - gripHeight
    
    if (trackSize <= 0) then
        return
    end
    
    local targetGripY = y - (gripHeight / 2)
    targetGripY = _Clamp(targetGripY, 0, trackSize)
    
    local scrollPercent = targetGripY / trackSize
    local targetScroll = scrollPercent * self.CanvasSize
    local distance = _abs(targetScroll - self:GetScroll())
    local distancePercent = distance / _max(self.CanvasSize, 1)
    local baseDuration = self:GetClickAnimationDuration() or 0.4
    local duration = _Lerp(distancePercent, baseDuration * 0.5, baseDuration * 1.25)
    
    self:AnimateTo(targetScroll, duration, 0)
end

--- Handles mouse release event
-- Stops dragging and releases mouse capture
function SCROLLBAR:OnMouseReleased()
    self.Dragging = false
    self.DraggingCanvas = nil
    self:MouseCapture(false)
    
    if _IsValid(self.btnGrip) then
        self.btnGrip.Depressed = false
    end
end

--- Handles cursor movement during grip drag
-- @param x (number): X position (unused)
-- @param y (number): Y position
function SCROLLBAR:OnCursorMoved(x, y)
    if (not self.Enabled or not self.Dragging) then
        return
    end

    local _, y = self:ScreenToLocal(0, gui.MouseY())
    y = y - self.HoldPos

    local TrackSize = self:GetTall() - self.btnGrip:GetTall()
    y = y / TrackSize
    
    self.SmoothScroll = 0
    
    if self.IsAnimatingScroll then
        self:ApplyEndAnimations()
        self.IsAnimatingScroll = false
    end
    
    self:SetScroll(y * self.CanvasSize)
end

--- Starts grip dragging
-- Called when user clicks on grip button
function SCROLLBAR:Grip()
    if (not self.Enabled or self.BarSize == 0 or not _IsValid(self.btnGrip)) then
        return
    end
    
    self:MouseCapture(true)
    self.Dragging = true
    
    self.SmoothScroll = 0
    
    if self.IsAnimatingScroll then
        self:ApplyEndAnimations()
        self.IsAnimatingScroll = false
    end
    
    self.IsScrolling = false
    
    local _, y = self.btnGrip:ScreenToLocal(0, gui.MouseY())
    self.HoldPos = y
    self.btnGrip.Depressed = true
end

--- Performs layout calculations
-- Positions and sizes the grip based on scroll state
function SCROLLBAR:PerformLayout()
    if (not self.LayoutDirty and not self.IsScrolling and not self.IsAnimatingScroll) then
        return
    end
    
    if (not _IsValid(self.btnGrip)) then
        return
    end
    
    local _wide = self:GetWide()
    local _tall = self:GetTall()
    
    local scrollPercent = self.CanvasSize > 0 and (self.Scroll / self.CanvasSize) or 0
    local barSize = _max(self.CachedBarScale * _tall, MIN_GRIP_SIZE)
    local track = _tall - barSize
    local scrollPos = scrollPercent * track
    
    self.btnGrip:SetPos(0, scrollPos)
    self.btnGrip:SetSize(_wide, barSize)
    
    self.LayoutDirty = false
end

--- Sets both base and hover colors for the scrollbar
-- @param baseColor (Color): Base color of the scrollbar
-- @param hoverColor (Color): Hover color (optional, defaults to baseColor)
-- @return (Panel): Self for method chaining
function SCROLLBAR:SetBarColors(baseColor, hoverColor)
    self:SetBarColor(baseColor)
    self:SetBarHoverColor(hoverColor or baseColor)
    return self
end

--- Resets scrollbar colors to default theme colors
-- @return (Panel): Self for method chaining
function SCROLLBAR:ResetBarColors()
    self:SetBarColor(nil)
    self:SetBarHoverColor(nil)
    return self
end

--- Shared callback for visual property changes
-- @param new (any): New value
-- @param old (any): Old value
local function InvalidateOnVisualChange(self, new, old)
    if (_IsValid(self.btnGrip) and self.btnGrip.Paint) then
        self:InvalidateLayout()
    end
end

-- Assign shared callback to all visual property changes
SCROLLBAR.OnBarColorChange = InvalidateOnVisualChange
SCROLLBAR.OnBarHoverColorChange = InvalidateOnVisualChange
SCROLLBAR.OnBarCornerRadiusChange = InvalidateOnVisualChange

-- Register the scrollbar component
SCROLLBAR:Register('DanLib.UI.ScrollBar')







-- Configuration constants
local DEFAULT_SCROLLBAR_WIDTH = 10
local DEFAULT_PADDING = 0
local SCROLLBAR_WIDTH_SCALE = 0.75
local SCROLL_ANIMATION_DURATION = 2

-- Constants for navigation buttons
local NAV_BUTTON_SIZE = 32
local NAV_BUTTON_MARGIN = 8
local NAV_BUTTON_FADE_SPEED = 10
local NAV_BUTTON_EDGE_THRESHOLD = 100 -- The distance from the edge to show the buttons

local SCROLL, Constructor = DanLib.UiPanel()

-- Accessors with default values
SCROLL:Accessor('Padding', nil, { default = 0 })
SCROLL:Accessor('Canvas', nil, { default = nil })
SCROLL:Accessor('VBar', nil, { default = nil })
SCROLL:Accessor('ScrollBarLeft', nil, { default = false })
SCROLL:Accessor('ShowNavButtons', nil, { default = false })
-- Navigation button positioning
SCROLL:Accessor('NavButtonsPosition', nil, { default = BOTTOM }) -- TOP or BOTTOM
SCROLL:Accessor('NavButtonsAlign', nil, { default = CENTER }) -- LEFT, CENTER, RIGHT
SCROLL:Accessor('NavButtonsLayout', Constructor.Number, { default = 0 }) -- 0 = horizontal, 1 = vertical
SCROLL:Accessor('NavButtonsMargin', Constructor.Number, { default = 4 })

--- Initializes the scroll panel component
-- Sets up canvas and scrollbar with optimal defaults
function SCROLL:Init()
    -- Create canvas panel
    self.pnlCanvas = DCustomUtils(self)
    -- Forward mouse events to parent
    self.pnlCanvas:ApplyEvent('OnMousePressed', function(sl, code)
        sl:GetParent():OnMousePressed(code)
    end)
    self.pnlCanvas:SetMouseInputEnabled(true)
    
    -- Canvas layout callback
    self.pnlCanvas.PerformLayout = function(pnl)
        self:PerformLayout()
        self:InvalidateParent()
    end

    -- Create vertical scrollbar
    self.VBar = DCustomUtils(self, 'DanLib.UI.ScrollBar')
    
    if (not _IsValid(self.VBar)) then
        _ErrorNoHalt('[DanLib.UI.Scroll] Failed to create scrollbar!\n')
        return
    end
    
    self.VBar:SetWide(DEFAULT_SCROLLBAR_WIDTH)
    self.VBar:Dock(RIGHT)
    
    -- Initialize properties
    self:SetPadding(DEFAULT_PADDING)
    self:SetMouseInputEnabled(true)
    
    -- Disable engine drawing for performance
    self:SetPaintBackgroundEnabled(false)
    self:SetPaintBorderEnabled(false)
    self:SetPaintBackground(false)
    
    -- Apply scrollbar paint
    self.VBar:ApplyPaint()
    
    -- Apply default scaling
    self:SetWide(self:GetWide() * SCROLLBAR_WIDTH_SCALE)
    self.VBar:SetWide(self.VBar:GetWide() * SCROLLBAR_WIDTH_SCALE)
    
    -- Creating navigation buttons
    self:CreateNavigationButtons()
end

--- Creates navigation buttons for quick scroll to top/bottom
-- Buttons fade in/out based on scroll position
function SCROLL:CreateNavigationButtons()
    -- Container for buttons
    self.navContainer = DCustomUtils(self)
    self.navContainer:SetMouseInputEnabled(false)
    
    -- Alpha for each button separately
    self.topButtonAlpha = 0
    self.bottomButtonAlpha = 0
    
    -- The "Up" button
    self.btnScrollTop = DBase.CreateUIButton(self.navContainer, {
        size = { NAV_BUTTON_SIZE, NAV_BUTTON_SIZE },
        icon = { DMaterial['Up-Arrow'] },
        hover = { _ColorAlpha(DBase:Theme('decor'), 60), nil, 6 },
        background = { DBase:Theme('secondary_dark') },
        click = function()
            self:AnimateToTop()
        end
    })
    
    -- The "Down" button
    self.btnScrollBottom = DBase.CreateUIButton(self.navContainer, {
        size = { NAV_BUTTON_SIZE, NAV_BUTTON_SIZE },
        icon = { DanLib.Config.Materials['Arrow'] or DanLib.Config.Materials['Down'] },
        hover = { _ColorAlpha(DBase:Theme('decor'), 60), nil, 6 },
        background = { DBase:Theme('secondary_dark') },
        click = function()
            self:AnimateToBottom()
        end
    })
    
    -- Think to update position and visibility
    self.navContainer:ApplyEvent('Think', function(sl)
        -- Checking for button display
        if (not _IsValid(self) or not self:GetShowNavButtons()) then
            sl:SetVisible(false)
            return
        end
        
        -- Checking which buttons need to be shown
        local canScrollUp, canScrollDown = self:GetNavButtonsVisibility()
        -- If both buttons are not needed, we hide the container completely.
        if (not canScrollUp and not canScrollDown) then
            sl:SetVisible(false)
            self.topButtonAlpha = 0
            self.bottomButtonAlpha = 0
            
            if _IsValid(self.btnScrollTop) then
                self.btnScrollTop:SetVisible(false)
                self.btnScrollTop:SetAlpha(0)
            end
            
            if _IsValid(self.btnScrollBottom) then
                self.btnScrollBottom:SetVisible(false)
                self.btnScrollBottom:SetAlpha(0)
            end
            return
        end
        
        -- Get positioning preferences
        local align = self:GetNavButtonsAlign() or CENTER -- LEFT, CENTER, RIGHT
        local position = self:GetNavButtonsPosition() or BOTTOM -- TOP or BOTTOM
        local layout = self:GetNavButtonsLayout() or 0 -- 0 = horizontal, 1 = vertical
        local margin = self:GetNavButtonsMargin() or 4
        local containerX, containerY
        
        -- HORIZONTAL LAYOUT (buttons side by side) - DEFAULT
        if (layout == 0) then
            sl:SetSize(NAV_BUTTON_SIZE * 2 + NAV_BUTTON_MARGIN, NAV_BUTTON_SIZE)
            
            -- Buttons side by side
            self.btnScrollTop:SetPos(0, 0)
            self.btnScrollBottom:SetPos(NAV_BUTTON_SIZE + NAV_BUTTON_MARGIN, 0)
            
            -- Calculate X position based on alignment
            if (align == LEFT) then
                containerX = margin
            elseif (align == RIGHT) then
                containerX = self:GetWide() - sl:GetWide() - margin
            else -- CENTER
                containerX = (self:GetWide() - sl:GetWide()) / 2
            end
            
            -- Calculate Y position
            containerY = (position == BOTTOM) and (self:GetTall() - NAV_BUTTON_SIZE - margin) or margin
        else
            -- VERTICAL LAYOUT (buttons stacked)
            sl:SetSize(NAV_BUTTON_SIZE, NAV_BUTTON_SIZE * 2 + NAV_BUTTON_MARGIN)
            
            -- Buttons stacked vertically
            self.btnScrollTop:SetPos(0, 0)
            self.btnScrollBottom:SetPos(0, NAV_BUTTON_SIZE + NAV_BUTTON_MARGIN)
            
            -- Calculate X position based on alignment
            if (align == LEFT) then
                containerX = margin
            elseif (align == RIGHT) then
                containerX = self:GetWide() - NAV_BUTTON_SIZE - margin
            else -- CENTER
                containerX = (self:GetWide() - NAV_BUTTON_SIZE) / 2
            end
            
            -- Calculate Y position
            containerY = (position == BOTTOM) and (self:GetTall() - sl:GetTall() - margin) or margin
        end
        
        sl:SetPos(containerX, containerY)
        
        -- Smooth alpha change for each button
        if canScrollUp then
            self.topButtonAlpha = _Clamp(self.topButtonAlpha + NAV_BUTTON_FADE_SPEED, 0, 255)
        else
            self.topButtonAlpha = _Clamp(self.topButtonAlpha - NAV_BUTTON_FADE_SPEED * 2, 0, 255)
        end
        
        if canScrollDown then
            self.bottomButtonAlpha = _Clamp(self.bottomButtonAlpha + NAV_BUTTON_FADE_SPEED, 0, 255)
        else
            self.bottomButtonAlpha = _Clamp(self.bottomButtonAlpha - NAV_BUTTON_FADE_SPEED * 2, 0, 255)
        end
        
        -- We show the container if at least one button is visible.
        local shouldShowContainer = self.topButtonAlpha > 0 or self.bottomButtonAlpha > 0
        sl:SetVisible(shouldShowContainer)
        sl:SetMouseInputEnabled(shouldShowContainer)
        
        -- Applying alpha to the buttons
        if _IsValid(self.btnScrollTop) then
            self.btnScrollTop:SetAlpha(self.topButtonAlpha)
            self.btnScrollTop:SetVisible(self.topButtonAlpha > 0)
            self.btnScrollTop:SetMouseInputEnabled(self.topButtonAlpha > 200)
        end
        
        if _IsValid(self.btnScrollBottom) then
            self.btnScrollBottom:SetAlpha(self.bottomButtonAlpha)
            self.btnScrollBottom:SetVisible(self.bottomButtonAlpha > 0)
            self.btnScrollBottom:SetMouseInputEnabled(self.bottomButtonAlpha > 200)
        end
    end)
end

--- Gets the visibility state for navigation buttons
-- @return { boolean } canScrollUp - Whether the scroll-up button should be visible
-- @return { boolean } canScrollDown - Whether the scroll-down button should be visible
-- @note KNOWN ISSUE: Currently not working - buttons never appear

-- GetScrollPosition() consistently returns 0 even when content is scrolled,
-- causing buttons to never meet the threshold requirements for visibility.

-- Root cause: VBar.Scroll and VBar:GetOffset() remain at 0 during scrolling.
-- Possible reasons:
--     OnMouseWheeled may not be propagating correctly
--     SCROLLBAR:Think() returns early during animations, preventing position updates
--     Canvas position updates may not sync with VBar scroll values
-- 
-- TODO: Fix scroll position tracking to enable threshold-based button visibility
-- For temporary workaround, change return statement to: return true, true
function SCROLL:GetNavButtonsVisibility()
    if (not _IsValid(self.VBar) or not self.VBar.Enabled) then
        return false, false
    end
    
    local scrollPos = self:GetScrollPosition()
    local maxScroll = self:GetMaxScroll()
    
    -- If there is no place to scroll, hide both buttons.
    if (maxScroll <= 0) then
        return false, false
    end
    
    -- Button visibility based on distance from edges
    -- NOTE: Currently always returns false, false because scrollPos is always 0
    local canScrollUp = scrollPos > NAV_BUTTON_EDGE_THRESHOLD
    local canScrollDown = (maxScroll - scrollPos) > NAV_BUTTON_EDGE_THRESHOLD
    return canScrollUp, canScrollDown
end

--- Gets the maximum scroll position
-- @return (number): Maximum scroll value
function SCROLL:GetMaxScroll()
    if (not _IsValid(self.VBar) or not _IsValid(self.pnlCanvas)) then
        return 0
    end
    
    return _max(0, self.pnlCanvas:GetTall() - self:GetTall())
end

--- Toggles scrollbar visibility
-- Hides scrollbar by setting width to 0
function SCROLL:ToggleScrollBar()
    if (not _IsValid(self.VBar)) then
        return
    end
    
    self.VBar:SetWide(0)
end

--- Shows the scrollbar with specified width
-- @param width (number): Width of scrollbar (optional, defaults to DEFAULT_SCROLLBAR_WIDTH)
function SCROLL:ShowScrollBar(width)
    if (not _IsValid(self.VBar)) then
        return
    end
    
    self.VBar:SetWide(width or DEFAULT_SCROLLBAR_WIDTH)
    self:InvalidateLayout()
end

--- Adds a panel to the scroll canvas
-- @param pnl (Panel): Panel to add to canvas
function SCROLL:AddItem(pnl)
    if (not _IsValid(self.pnlCanvas) or not _IsValid(pnl)) then
        return
    end
    
    pnl:SetParent(self.pnlCanvas)
end

--- Callback when child is added
-- @param child (Panel): Child panel that was added
function SCROLL:OnChildAdded(child)
    self:AddItem(child)
end

--- Sizes the scroll panel to fit its contents
function SCROLL:SizeToContents()
    if (not _IsValid(self.pnlCanvas)) then
        return
    end
    
    self:SetSize(self.pnlCanvas:GetSize())
end

--- Gets the vertical scrollbar
-- @return (Panel): Vertical scrollbar panel
function SCROLL:GetVBar()
    return self.VBar
end

--- Gets the canvas panel
-- @return (Panel): Canvas panel containing scroll content
function SCROLL:GetCanvas()
    return self.pnlCanvas
end

--- Gets the inner width of the canvas
-- @return (number): Canvas width in pixels
function SCROLL:InnerWidth()
    if (not _IsValid(self.pnlCanvas)) then
        return 0
    end
    
    return self.pnlCanvas:GetWide()
end

--- Rebuilds canvas size based on children
-- Automatically sizes canvas to fit all child panels
function SCROLL:Rebuild()
    if (not _IsValid(self.pnlCanvas)) then
        return
    end
    
    self.pnlCanvas:SizeToChildren(false, true)
    
    -- Center vertically if content is smaller than container
    if (self.m_bNoSizing and self.pnlCanvas:GetTall() < self:GetTall()) then
        self.pnlCanvas:SetPos(0, (self:GetTall() - self.pnlCanvas:GetTall()) * 0.5)
    end
end

--- Handles mouse wheel scrolling
-- @param dlta (number): Mouse wheel delta
-- @return (boolean): True if scroll was handled
function SCROLL:OnMouseWheeled(dlta)
    if (not _IsValid(self.VBar)) then
        return false
    end
    
    return self.VBar:OnMouseWheeled(dlta)
end

--- Callback when vertical scroll position changes
-- @param iOffset (number): New scroll offset
function SCROLL:OnVScroll(iOffset)
    if (not _IsValid(self.pnlCanvas) or not _IsValid(self.VBar)) then
        return
    end
    
    local xPos = (self:GetScrollBarLeft() or false) and self.VBar:GetWide() or 0
    self.pnlCanvas:SetPos(xPos, iOffset)
end

--- Scrolls to make a specific child panel visible with smooth animation
-- @param panel (Panel): Child panel to scroll to
-- @param duration (number): Animation duration in seconds (optional, default: 0.5)
-- @param callback (function): Optional callback when animation completes
function SCROLL:ScrollToChild(panel, duration, callback)
    if (not _IsValid(panel) or not _IsValid(self.pnlCanvas) or not _IsValid(self.VBar)) then
        return
    end
    
    -- Force layout update before calculating position
    self:PerformLayout()
    
    local x, y = self.pnlCanvas:GetChildPosition(panel)
    if (not y) then
        _ErrorNoHalt('[DanLib.UI.Scroll] Could not get child position!\n')
        return
    end
    
    local w, h = panel:GetSize()
    
    -- Calculate target scroll position to center panel in viewport
    local targetY = y + h * 0.5 - self:GetTall() * 0.5
    self.VBar:AnimateTo(targetY, duration or SCROLL_ANIMATION_DURATION, 0, callback)
end

--- Scrolls to top of a specific child panel (aligns to top edge)
-- @param panel (Panel): Child panel to scroll to
-- @param duration (number): Animation duration in seconds (optional)
function SCROLL:ScrollToChildTop(panel, duration)
    if (not _IsValid(panel) or not _IsValid(self.pnlCanvas) or not _IsValid(self.VBar)) then
        return
    end
    
    self:PerformLayout()
    
    local x, y = self.pnlCanvas:GetChildPosition(panel)
    if (not y) then
        return
    end
    
    -- Scroll so panel is at the top
    self.VBar:AnimateTo(y, duration or SCROLL_ANIMATION_DURATION, 0, nil)
end

--- Performs layout calculations
-- Updates canvas size and scrollbar position
function SCROLL:PerformLayout()
    if (not _IsValid(self.pnlCanvas) or not _IsValid(self.VBar)) then
        return
    end
    
    local previousTall = self.pnlCanvas:GetTall()
    local canvasWide = self:GetWide()
    
    -- Rebuild canvas to fit children
    self:Rebuild()
    
    -- Setup scrollbar
    self.VBar:SetUp(self:GetTall(), self.pnlCanvas:GetTall())
    local yOffset = self.VBar:GetOffset()
    
    -- Adjust canvas width if scrollbar is visible
    if self.VBar.Enabled then
        canvasWide = canvasWide - self.VBar:GetWide()
    end
    
    -- Position canvas based on scrollbar side
    local xPos = (self:GetScrollBarLeft() or false) and self.VBar:GetWide() or 0
    self.pnlCanvas:SetPos(xPos, yOffset)
    self.pnlCanvas:SetWide(canvasWide)
    
    -- Rebuild again after width change
    self:Rebuild()
    
    -- Clamp scroll if canvas height changed
    if (previousTall ~= self.pnlCanvas:GetTall()) then
        self.VBar:SetScroll(self.VBar:GetScroll())
    end
end

--- Clears all children from the canvas
function SCROLL:Clear()
    if (not _IsValid(self.pnlCanvas)) then
        return
    end
    
    return self.pnlCanvas:Clear()
end

--- Sets scrollbar position (left or right)
-- @param left (boolean): True for left side, false for right side
function SCROLL:SetScrollBarLeft(left)
    if (not _IsValid(self.VBar)) then
        return
    end
    
    self.ScrollBarLeft = left
    self.VBar:Dock(left and LEFT or RIGHT)
    self:InvalidateLayout()
end

--- Callback when scrollbar position changes
-- @param new (boolean): New scrollbar left state
-- @param old (boolean): Previous scrollbar left state
function SCROLL:OnScrollBarLeftChange(new, old)
    if _IsValid(self.VBar) then
        self.VBar:Dock(new and LEFT or RIGHT)
        self:InvalidateLayout()
    end
end

--- Sets the width of the scrollbar
-- @param width (number): Width in pixels
function SCROLL:SetScrollBarWidth(width)
    if (not _IsValid(self.VBar)) then
        return
    end
    
    self.VBar:SetWide(width)
    self:InvalidateLayout()
end

--- Gets the current scroll position
-- @return (number): Current scroll offset
function SCROLL:GetScrollPosition()
    if (not _IsValid(self.VBar)) then
        return 0
    end
    
    return self.VBar:GetScroll()
end

--- Sets the scroll position
-- @param pos (number): Target scroll position
function SCROLL:SetScrollPosition(pos)
    if (not _IsValid(self.VBar)) then
        return
    end
    
    self.VBar:SetScroll(pos)
end

--- Scrolls to the top of the content
function SCROLL:ScrollToTop()
    self:SetScrollPosition(0)
end

--- Scrolls to the bottom of the content
function SCROLL:ScrollToBottom()
    if (not _IsValid(self.VBar) or not _IsValid(self.pnlCanvas)) then
        return
    end
    
    local maxScroll = self.pnlCanvas:GetTall() - self:GetTall()
    self:SetScrollPosition(maxScroll)
end

--- Animates scroll to top
-- @param duration (number): Animation duration in seconds (optional)
function SCROLL:AnimateToTop(duration)
    if (not _IsValid(self.VBar)) then
        return
    end
    
    self.VBar:AnimateTo(0, duration or SCROLL_ANIMATION_DURATION, 0, nil)
end

--- Animates scroll to bottom
-- @param duration (number): Animation duration in seconds (optional)
function SCROLL:AnimateToBottom(duration)
    if (not _IsValid(self.VBar) or not _IsValid(self.pnlCanvas)) then
        return
    end
    
    local maxScroll = self.pnlCanvas:GetTall() - self:GetTall()
    self.VBar:AnimateTo(maxScroll, duration or SCROLL_ANIMATION_DURATION, 0, nil)
end

SCROLL:SetBase('DPanel')
SCROLL:Register('DanLib.UI.Scroll')






--- Horizontal scroll bar with smooth animations and Accessor pattern
local HORIZONTALSCROLL, Constructor = DanLib.UiPanel()

-- Accessors with default values
HORIZONTALSCROLL:Accessor('BarColor', Constructor.Color, { default = nil })
HORIZONTALSCROLL:Accessor('BarHoverColor', Constructor.Color, { default = nil })
HORIZONTALSCROLL:Accessor('BarMargin', Constructor.Number, { default = 0 })
HORIZONTALSCROLL:Accessor('ClickAnimationDuration', Constructor.Number, { default = 0.4 })
HORIZONTALSCROLL:Accessor('WheelScrollSpeed', Constructor.Number, { 
    default = 50,
    validate = function(self, val)
        return val > 0 and val <= 200
    end
})
HORIZONTALSCROLL:Accessor('WheelSmoothSpeed', Constructor.Number, { default = 6 })

--- Initializes the horizontal scroll panel component
-- Sets up canvas, scrollbar, and grip with event handlers for dragging and clicking
function HORIZONTALSCROLL:Init()
    -- Smooth scrolling state
    self.SmoothScroll = 0
    self.IsScrolling = false
    self.IsAnimatingScroll = false
    
    local alpha = 0
    
    -- Create scrollbar (no background, just container)
    self.scrollBar = DCustomUtils(self)
    self.scrollBar:SetTall(8)
    self.scrollBar:SetCursor('hand')

    -- Create grip
    self.scrollBar.grip = DCustomUtils(self.scrollBar, 'DButton')
    self.scrollBar.grip:SetText('')
    self.scrollBar.grip:SetPos(0, 0)
    self.scrollBar.grip:SetSize(0, self.scrollBar:GetTall())
    self.scrollBar.grip:ApplyClearPaint()
    self.scrollBar.grip:ApplyEvent(nil, function(sl, w, h)
        alpha = (sl:IsHovered() or sl.Depressed) and _Clamp(alpha + 5, 0, 100) or _Clamp(alpha - 5, 0, 100)
        
        local baseColor = self:GetBarColor() or DBase:Theme('scroll_dark')
        local hoverColor = self:GetBarHoverColor() or DBase:Theme('decor')
        
        DUtils:DrawRoundedBox(0, 0, w, h, baseColor)
        
        if alpha > 0 then
            _SetAlphaMultiplier(alpha / 255)
            DUtils:DrawRoundedBox(0, 0, w, h, hoverColor)
            _SetAlphaMultiplier(1)
        end
    end)
    
    -- Custom SetScrollX event for grip positioning
    self.scrollBar.grip:ApplyEvent('SetScrollX', function(sl, x)
        sl:SetX(_Clamp(x, 0, self:GetWide() - sl:GetWide()))
    end)
    
    -- Grip drag handlers
    self.scrollBar.grip:ApplyEvent('OnMousePressed', function(sl)
        sl.mouseStartX = _guiMouseX()
        sl.startX = sl:GetX()
        sl.isDragging = true
        sl.Depressed = true
        
        -- Reset animation
        self.IsAnimatingScroll = false
        self.SmoothScroll = 0
        self.IsScrolling = false
    end)
    
    self.scrollBar.grip:ApplyEvent('OnMouseReleased', function(sl)
        sl.isDragging = false
        sl.mouseStartX = nil
        sl.Depressed = false
    end)
    
    self.scrollBar.grip:ApplyEvent('Think', function(sl)
        if (not sl.isDragging) then
            return
        end

        if (not input.IsMouseDown(MOUSE_LEFT)) then
            sl.isDragging = false
            sl.mouseStartX = nil
            sl.Depressed = false
            return
        end
        
        self:SetScroll((sl.startX + _guiMouseX() - sl.mouseStartX) / (self:GetWide() - sl:GetWide()))
    end)
    
    -- Click on scrollBar for animation
    self.scrollBar:ApplyEvent('OnMousePressed', function(sl)
        if (_IsValid(self.scrollBar.grip) and self.scrollBar.grip:IsHovered()) then
            return
        end
        
        local x, _ = sl:CursorPos()
        local wide = sl:GetWide()
        local gripWidth = self.scrollBar.grip:GetWide()
        local trackSize = wide - gripWidth
        
        if (trackSize <= 0) then
            return
        end
        
        local targetGripX = x - (gripWidth / 2)
        targetGripX = _Clamp(targetGripX, 0, trackSize)
        
        local scrollPercent = targetGripX / trackSize
        local canvasWide = self.canvas:GetWide()
        local viewWide = self:GetWide()
        local maxScroll = canvasWide - viewWide
        
        if (maxScroll <= 0) then
            return
        end
        
        local targetScroll = scrollPercent * maxScroll
        local currentScroll = _abs(self:GetScrollX())
        local distance = _abs(targetScroll - currentScroll)
        local distancePercent = distance / maxScroll
        local baseDuration = self:GetClickAnimationDuration() or 0.4
        local duration = _Lerp(distancePercent, baseDuration * 0.5, baseDuration * 1.25)
        
        self:AnimateToPosition(targetScroll, duration)
    end)

    -- Create canvas
    self.canvas = DCustomUtils(self)
    self.canvas:SetPos(0, 0)
    self.canvas:SetSize(0, self:GetTall())
    self.canvas:SetZPos(-100)
    
    -- Forward mouse events to parent
    self.canvas:ApplyEvent('OnMousePressed', function(sl, code)
        sl:GetParent():OnMousePressed(code)
    end)
    self.canvas:SetMouseInputEnabled(true)
    
    -- Canvas layout callback
    self.canvas.PerformLayout = function(pnl)
        self:PerformLayout()
        self:InvalidateParent()
    end
end

--- Handles mouse wheel scrolling with smooth animation
-- @param delta (number): Mouse wheel delta value (-1 for left, 1 for right)
function HORIZONTALSCROLL:OnMouseWheeled(delta)
    -- Reset animation without delay
    self.IsAnimatingScroll = false
    
    local force = self:GetWheelScrollSpeed() or 50
    self.SmoothScroll = self.SmoothScroll + (delta * force)
    self.IsScrolling = true
end

--- Main think loop - handles smooth scrolling, animations, and canvas dragging
-- Processes click animations, wheel scrolling physics, and drag interactions
function HORIZONTALSCROLL:Think()
    -- Animation processing
    if self.IsAnimatingScroll then
        if (not _IsValid(self.canvas)) then
            self.IsAnimatingScroll = false
            return
        end
        
        local elapsed = _SysTime() - self.AnimStartTime
        local progress = _Clamp(elapsed / self.AnimDuration, 0, 1)
        
        -- Smooth easing
        local eased = progress < 0.5 and 2 * progress * progress or 1 - math.pow(-2 * progress + 2, 2) / 2
        local currentX = _Lerp(eased, self.AnimStartX, self.AnimTargetX)
        
        self:SetScrollX(currentX)
        
        if (progress >= 1) then
            self.IsAnimatingScroll = false
            self.AnimStartX = nil
            self.AnimTargetX = nil
            self.AnimStartTime = nil
            self.AnimDuration = nil
        end
        return
    end
    
    -- Smooth wheel scrolling physics
    if (self.IsScrolling and self.SmoothScroll ~= 0) then
        -- Checking for NaN/Infinity
        if (self.SmoothScroll ~= self.SmoothScroll or _abs(self.SmoothScroll) == math.huge) then
            self.SmoothScroll = 0
            self.IsScrolling = false
            return
        end
        
        local speed = _FrameTime() * (self:GetWheelSmoothSpeed() or 10)
        
        if (not _IsValid(self.canvas)) then
            self.IsScrolling = false
            return
        end
        
        local currentX = self:GetScrollX()
        
        -- Check for stopping conditions
        local maxX = self:GetWide() - self.canvas:GetWide()
        local atLeftEdge = (currentX >= 0 and self.SmoothScroll > 0)
        local atRightEdge = (currentX <= maxX and self.SmoothScroll < 0)
        
        if (_abs(self.SmoothScroll) < 0.1 or atLeftEdge or atRightEdge) then
            self.SmoothScroll = 0
            self.IsScrolling = false
        else
            if (self.SmoothScroll > 0) then
                self.SmoothScroll = _Clamp(self.SmoothScroll - speed, 0, 10000)
            else
                self.SmoothScroll = _Clamp(self.SmoothScroll + speed, -10000, 0)
            end
            
            self:SetScrollX(currentX + self.SmoothScroll)
        end
        return
    end
    
    -- Canvas drag logic
    if (not input.IsMouseDown(MOUSE_LEFT)) then
        if (not self.isDragging) then
            return
        end

        self.isDragging = false
        -- Clearing the cache at the end of the drag
        self.cachedScreenX = nil
        self.cachedScreenY = nil
        return
    end

    -- We use cached coordinates
    local startX, startY
    if (self.isDragging and self.cachedScreenX) then
        startX, startY = self.cachedScreenX, self.cachedScreenY
    else
        startX, startY = self:LocalToScreen(0, 0)
    end
    
    local endX, endY = startX + self:GetWide(), startY + self:GetTall()
    local mouseX, mouseY = _guiMouseX(), _guiMouseY()
    local withinBounds = (mouseX >= startX) and (mouseX <= endX) and (mouseY >= startY) and (mouseY <= endY)
    if (not withinBounds) then
        self.isDragging = false
        self.cachedScreenX = nil
        self.cachedScreenY = nil
        return
    end

    if (not self.isDragging) then
        self.isDragging = true
        self.dragMouseStartX = mouseX
        self.dragPosStartX = self:GetScrollX()
        -- We cache it at the beginning of the drag
        self.cachedScreenX, self.cachedScreenY = startX, startY
    end
    
    if (self.dragPosStartX and self.dragMouseStartX) then
        self:SetScrollX(self.dragPosStartX + mouseX - self.dragMouseStartX)
    end
end

--- Sets scroll position in pixels with safety checks
-- @param x (number): Target scroll position in pixels (negative value moves canvas left)
function HORIZONTALSCROLL:SetScrollX(x)
    if (not _IsValid(self.canvas)) then
        return
    end
    
    -- Checking for NaN/Infinity
    if (x ~= x or _abs(x) == math.huge) then
        return
    end
    
    local maxX = self:GetWide() - self.canvas:GetWide()
    local newX = _Clamp(x, maxX, 0)
    
    -- Early exit if the position has not changed
    local currentX = self.canvas:GetX()
    if (_abs(currentX - newX) < 0.01) then
        return
    end
    
    self.canvas:SetX(newX)
    
    -- Update grip position
    if (_IsValid(self.scrollBar.grip) and _abs(maxX) > 0) then
        self.scrollBar.grip:SetScrollX((self:GetWide() - self.scrollBar.grip:GetWide()) * (_abs(newX) / _abs(maxX)))
    end
end

--- Gets current scroll position in pixels
-- @return (number): Current scroll X position (negative value)
function HORIZONTALSCROLL:GetScrollX()
    if (not _IsValid(self.canvas)) then
        return 0
    end
    
    return self.canvas:GetX()
end

--- Sets scroll by percentage
-- @param percent (number): Scroll percentage from 0 to 1 (0 = left edge, 1 = right edge)
function HORIZONTALSCROLL:SetScroll(percent)
    if (not _IsValid(self.canvas)) then
        return
    end
    
    self.scrollPercent = _Clamp(percent, 0, 1)
    local maxX = self:GetWide() - self.canvas:GetWide()
    local newX = _Clamp(maxX * self.scrollPercent, maxX, 0)
    self.canvas:SetX(newX)
    
    if _IsValid(self.scrollBar.grip) then
        self.scrollBar.grip:SetScrollX(percent * (self:GetWide() - self.scrollBar.grip:GetWide()))
    end
end

--- Gets current scroll percentage
-- @return (number): Scroll percentage from 0 to 1
function HORIZONTALSCROLL:GetScroll()
    return self.scrollPercent or 0
end

--- Toggles scrollbar visibility
-- Hides the scrollbar and grip by setting their size to 0
function HORIZONTALSCROLL:ToggleScrollBar()
    if (not _IsValid(self.scrollBar)) then
        return
    end
    
    self.scrollBar:SetTall(0)
    
    if _IsValid(self.scrollBar.grip) then
        self.scrollBar.grip:SetSize(0, 0)
    end
end

--- Performs layout calculations for canvas and scrollbar positioning
-- @param w (number): Width of the panel (optional, defaults to current width)
-- @param h (number): Height of the panel (optional, defaults to current height)
function HORIZONTALSCROLL:PerformLayout(w, h)
    if (not _IsValid(self.canvas)) then
        return
    end
    
    w = w or self:GetWide()
    h = h or self:GetTall()
    
    self.canvas:SizeToChildren(true, false)
    
    local scrollBarHeight = 8
    local scrollBarMargin = self:GetBarMargin()
    
    -- Apply bottom padding only if BarMargin is set and > 0
    if (scrollBarMargin and scrollBarMargin > 0) then
        self.canvas:DockPadding(0, 0, 0, scrollBarMargin)
    else
        self.canvas:DockPadding(0, 0, 0, 0)
    end
    
    self.canvas:SetSize(self.canvas:GetWide(), h)
    if (not _IsValid(self.scrollBar)) then
        return
    end
    
    self.scrollBar:SetWide(w)
    self.scrollBar:SetPos(0, h - scrollBarHeight)
    self:CheckShouldEnable()
end

--- Animates scroll to a specific position using Think-based animation
-- @param targetPos (number): Target scroll position in pixels (positive value)
-- @param duration (number): Animation duration in seconds (default: 0.5)
function HORIZONTALSCROLL:AnimateToPosition(targetPos, duration)
    duration = duration or 0.5
    
    if (not _IsValid(self.canvas)) then
        return
    end
    
    local maxX = self:GetWide() - self.canvas:GetWide()
    local targetX = _Clamp(-targetPos, maxX, 0)
    
    -- Stop previous animations
    self.SmoothScroll = 0
    self.IsScrolling = false
    self.IsAnimatingScroll = true
    
    -- Save animation parameters
    self.AnimStartX = self:GetScrollX()
    self.AnimTargetX = targetX
    self.AnimStartTime = _SysTime()
    self.AnimDuration = duration
end

--- Animates scroll to target position with optional delay and callback
-- @param targetX (number): Target scroll position in pixels
-- @param duration (number): Animation duration in seconds (default: 0.5)
-- @param delay (number): Delay before animation starts in seconds (default: 0)
-- @param callback (function): Optional callback function when animation completes
function HORIZONTALSCROLL:AnimateTo(targetX, duration, delay, callback)
    duration = duration or 0.5
    delay = delay or 0
    
    local function startAnimation()
        if (not _IsValid(self)) then
            return
        end
        
        self:AnimateToPosition(targetX, duration)
        
        if (callback and _type(callback) == 'function') then
            DTimer:Simple(duration, function()
                if _IsValid(self) then
                    callback(self)
                end
            end)
        end
    end
    
    if (delay > 0) then
        DTimer:Simple(delay, startAnimation)
    else
        startAnimation()
    end
end

--- Scrolls to make a specific child panel visible with smooth animation
-- Centers the child in the viewport using LocalToScreen for accurate positioning
-- @param child (Panel): Child panel to scroll to
-- @param duration (number): Animation duration in seconds (optional, default: 0.5)
-- @param callback (function): Optional callback when scroll completes
function HORIZONTALSCROLL:ScrollToChild(child, duration, callback)
    if (not _IsValid(child) or not _IsValid(self.canvas)) then
        return
    end
    
    self:PerformLayout()
    
    local childScreenX, _ = child:LocalToScreen(0, 0)
    local canvasScreenX, _ = self.canvas:LocalToScreen(0, 0)
    
    local childX = childScreenX - canvasScreenX
    local childWidth = child:GetWide()
    
    -- Center child in viewport
    local targetPos = childX + childWidth * 0.5 - self:GetWide() * 0.5
    self:AnimateToPosition(targetPos, duration or 0.5)
    
    if (callback and _type(callback) == 'function') then
        DTimer:Simple(duration or 0.5, function()
            if _IsValid(self) then
                callback(self)
            end
        end)
    end
end

--- Scrolls to the left edge of a specific child panel
-- @param child (Panel): Child panel to scroll to
-- @param duration (number): Animation duration in seconds (optional, default: 0.5)
function HORIZONTALSCROLL:ScrollToChildLeft(child, duration)
    if (not _IsValid(child) or not _IsValid(self.canvas)) then
        return
    end
    
    local childScreenX, _ = child:LocalToScreen(0, 0)
    local canvasScreenX, _ = self.canvas:LocalToScreen(0, 0)
    local childX = childScreenX - canvasScreenX
    
    self:AnimateToPosition(childX, duration or 0.5)
end

--- Checks if a child panel is currently visible in the viewport
-- @param child (Panel): Child panel to check
-- @return (boolean): True if child is visible, false otherwise
function HORIZONTALSCROLL:IsChildVisible(child)
    if (not _IsValid(child)) then
        return false
    end

    local childX = child:GetX()
    local childWidth = child:GetWide()
    local scrollX = self:GetScrollX()
    local visibleStart = _abs(scrollX)
    local visibleEnd = visibleStart + self:GetWide()

    return (childX >= visibleStart and childX + childWidth <= visibleEnd)
end

--- Animates scroll to the leftmost position
-- @param duration (number): Animation duration in seconds (optional, default: 0.5)
function HORIZONTALSCROLL:AnimateToLeft(duration)
    self:AnimateToPosition(0, duration or 0.5)
end

--- Animates scroll to the rightmost position
-- @param duration (number): Animation duration in seconds (optional, default: 0.5)
function HORIZONTALSCROLL:AnimateToRight(duration)
    if (not _IsValid(self.canvas)) then
        return
    end
    
    local maxX = self.canvas:GetWide() - self:GetWide()
    self:AnimateToPosition(maxX, duration or 0.5)
end

--- Callback when a child panel is added
-- Automatically parents child to canvas and updates layout
-- @param child (Panel): Child panel that was added
function HORIZONTALSCROLL:OnChildAdded(child)
    if (not _IsValid(self.canvas)) then
        return
    end

    child:SetParent(self.canvas)
    self.canvas:SizeToChildren(true, false)
    self:CheckShouldEnable()
end

--- Checks if scrollbar should be enabled based on canvas size
-- Adjusts grip width based on content size
function HORIZONTALSCROLL:CheckShouldEnable()
    if (not _IsValid(self.scrollBar.grip) or not _IsValid(self.canvas)) then
        return
    end

    local w = self:GetWide()
    if (self.canvas:GetWide() > w) then
        self.scrollBar.grip:SetWide(w / 3)
    else
        self.scrollBar.grip:SetWide(0)
    end
end

--- Gets the canvas panel that contains all children
-- @return (Panel): Canvas panel
function HORIZONTALSCROLL:GetCanvas()
    return self.canvas
end

--- Clears all children from the canvas
function HORIZONTALSCROLL:Clear()
    if (not _IsValid(self.canvas)) then
        return
    end
    
    self.canvas:Clear()
end

--- Sets both base and hover colors for the scrollbar grip
-- @param baseColor (Color): Base color of the grip
-- @param hoverColor (Color): Hover color (optional, defaults to baseColor)
-- @return (Panel): Self for method chaining
function HORIZONTALSCROLL:SetBarColors(baseColor, hoverColor)
    self:SetBarColor(baseColor)
    self:SetBarHoverColor(hoverColor or baseColor)
    return self
end

--- Resets scrollbar colors to default theme colors
-- @return (Panel): Self for method chaining
function HORIZONTALSCROLL:ResetBarColors()
    self:SetBarColor(nil)
    self:SetBarHoverColor(nil)
    return self
end

-- Register the HorizontalScroll component
HORIZONTALSCROLL:Register('DanLib.UI.HorizontalScroll')
