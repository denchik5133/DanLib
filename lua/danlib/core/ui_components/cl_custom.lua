/***
 *   @addon         DanLib
 *   @component     Custom Panel Extensions
 *   @license       MIT License
 *   @version       1.0.8
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Custom panel utility extensions for DanLib with advanced visual effects,
 *                  animations, and dynamic property support. Provides reusable methods for hover effects,
 *                  backgrounds, text rendering, blur effects, and interactive animations with real-time
 *                  color updates and transition support.
 *
 *   @functions      
 *                  - Dynamic color support for all visual effects (hover, text, background, etc.)
 *                  - Fade hover effects with customizable speed and radius
 *                  - Fill hover animations with directional support (LEFT, TOP, RIGHT, BOTTOM)
 *                  - Circle ripple effect on click with smooth animations
 *                  - Bar hover indicator with customizable height and color
 *                  - Background rendering with rounded corners and custom rounding per corner
 *                  - Blur effect integration with intensity and depth control
 *                  - Text rendering with alignment and dynamic color updates
 *                  - Avatar support with rounded corners and outline
 *                  - Sound effects for hover and click events
 *                  - Panel docking utilities (Pin, PinMargin)
 *                  - Transition system for smooth property animations
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         All methods support dynamic property updates via Think event.
 *                  Color properties (TextColor, HoverColor, BackgroundColor, etc.) can be
 *                  modified in real-time and will be reflected immediately in rendering.
 */



local DBase = DanLib.Func
local DTable = DanLib.Table

local material = Material
local surface = surface
local draw_material = surface.SetMaterial
local draw_color = surface.SetDrawColor
local draw_poly = surface.DrawPoly
local draw_rect = surface.DrawRect
local draw_textured_rect = surface.DrawTexturedRect
local draw_textured_rect_rotated = surface.DrawTexturedRectRotated
local draw_textured_rect_uv = surface.DrawTexturedRectUV

local draw = draw
local no_texture = draw.NoTexture
local rounded_box = draw.RoundedBox
local rounded_box_ex = draw.RoundedBoxEx
local simple_text = draw.SimpleText
local draw_text = draw.DrawText

local table = table
local insert = table.insert

local render = render
local render_clear_stencil = render.ClearStencil
local render_set_stencil_enable = render.SetStencilEnable
local render_set_stencil_write_mask = render.SetStencilWriteMask
local render_set_stencil_test_mask = render.SetStencilTestMask
local render_set_stencil_fail_operation = render.SetStencilFailOperation
local render_set_stencil_pass_operation = render.SetStencilPassOperation
local render_set_stencil_z_fail_operation = render.SetStencilZFailOperation
local render_set_stencil_compare_function = render.SetStencilCompareFunction
local render_set_stencil_reference_value = render.SetStencilReferenceValue
local render_update_screen_effect_texture = render.UpdateScreenEffectTexture

local vgui_create = vgui.Create
local surface_play_sound = surface.PlaySound

local math = math
local rad = math.rad
local cos = math.cos
local sin = math.sin
local round = math.Round
local max = math.max

local color = Color
local color_alpha = ColorAlpha
local lerp = Lerp
local frame_time = FrameTime

local ScrW = ScrW
local ScrH = ScrH

local IsMouseDown = input.IsMouseDown

--- Constants
local screenBlur = material('pp/blurscreen')
local gradientLeft = material('vgui/gradient-l')
local gradientUp = material('vgui/gradient-u')
local gradientRight = material('vgui/gradient-r')
local gradientDown = material('vgui/gradient-d')

local MOUSE_LEFT = MOUSE_LEFT
local MOUSE_RIGHT = MOUSE_RIGHT

--- Draws a circle on the screen.
-- @param sx: The X-coordinate of the centre of the circle.
-- @param sy: The Y-coordinate of the center of the circle.
-- @param radius: The radius of the circle.
-- @param seg: The number of segments to draw the circle. The default value is 30.
-- @param color: The colour of the circle. The default colour is white.
-- @param angle: The angle of rotation of the circle in radians. The default value is 0.
-- @return: Table with the coordinates of the vertices of the circle.
local function draw_circle(sx, sy, radius, seg, color, angle)
    -- Set the default colour
    color = color or color_white
    -- Set the default number of segments
    seg = seg or 30

    local cir = {}
    -- Angle in radians
    local ang = -rad(angle or 0)
    local c = cos(ang)
    local s = sin(ang)

    -- Circle vertex generation
    for i = 0, 360, 360 / seg do
        local radd = rad(i)
        local x = cos(radd)
        local y = sin(radd)

        local tempx = x * radius * c - y * radius * s + sx
        y = x * radius * s + y * radius * c + sy
        x = tempx

        -- u or v -- Placeholder for texture coordinates
        cir[#cir + 1] = {
            x = x,
            y = y,
            u = 0,
            v = 0
        }
    end

    -- Checking that the circle contains at least one vertex
    if (#cir > 0) then -- (cir and #cir > 0)
        -- Turning off the texture for rendering
        no_texture()
        -- Set the colour for rendering
        draw_color(color)
        -- Drawing a circle
        draw_poly(cir)
    end

    return cir  -- Return the table with the vertices of the circle
end

--- Function for drawing a rectangle with rounded corners
local function draw_rounded_rect(w, h)
    -- Draw a rounded rectangle
    local poly = {}

    local x = w / 2
    local y = h / 2
    local radius = h / 1.5
    local vertices = 90

    insert(poly, {
        x = x,
        y = y
    })

    for i = 0, vertices do
        local a = rad((i / vertices) * -360) + 90
        insert(poly, {
            x = x + sin(a) * radius,
            y = y + cos(a) * radius
        })
    end

    local a = rad(0)
    insert(poly, {
        x = x + sin(a) * radius,
        y = y + cos(a) * radius
    })

    return poly
end


--- Utility Functions
DanLib.CustomUtils = DanLib.CustomUtils or {}
local CustomUtils = {}

--- Draws a filled circle at the specified coordinates.
-- @param cx: The x-coordinate of the center of the circle.
-- @param cy: The y-coordinate of the center of the circle.
-- @param radius: The radius of the circle.
-- @param color: The color of the circle.
CustomUtils.DrawFilledCircle = function(cx, cy, radius, color)
    local points = {}

    for angle = 0, 360 do
        local rad = rad(angle)
        points[#points + 1] = {
            x = cx + cos(rad) * radius,
            y = cy + sin(rad) * radius
        }
    end

    -- draw_color(color)
    no_texture()
    draw_poly(points)
end

--- Draws an arc segment.
-- @param cx: The x-coordinate of the center of the arc.
-- @param cy: The y-coordinate of the center of the arc.
-- @param startAngle: The starting angle of the arc in degrees.
-- @param sweepAngle: The angle to sweep in degrees.
-- @param radius: The radius of the arc.
-- @param color: The color of the arc.
-- @param segments: The number of segments to use for drawing the arc.
CustomUtils.DrawArcSegment = function(cx, cy, startAngle, sweepAngle, radius, color, segments)
    segments = segments or 80
    local points = {}

    insert(points, {
        x = cx,
        y = cy
    })

    for i = 0, segments do
        local angle = rad(startAngle + (i / segments) * sweepAngle)
        insert(points, {
            x = cx + cos(angle) * radius,
            y = cy + sin(angle) * radius
        })
    end

    draw_color(color)
    no_texture()
    draw_poly(points)
end

--- Performs linear interpolation between two colors.
-- @param fraction: The interpolation fraction (0 to 1).
-- @param startColor: The starting color.
-- @param endColor: The ending color.
-- @return The interpolated color.
CustomUtils.ColorLerp = function(fraction, startColor, endColor)
    return color(lerp(fraction, startColor.r, endColor.r), lerp(fraction, startColor.g, endColor.g), lerp(fraction, startColor.b, endColor.b), lerp(fraction, startColor.a, endColor.a))
end

--- Checks if the panel is currently hovered.
-- @param panel: The panel to check.
-- @return True if the panel is hovered, false otherwise.
CustomUtils.IsHovered = function(panel)
    return panel:IsHovered()
end

--- Checks if the panel or any of its children are currently hovered.
-- @param panel: The panel to check.
-- @return True if the panel or its children are hovered, false otherwise.
CustomUtils.IsHoveredOrChild = function(panel)
    return panel:IsHovered() or panel:IsChildHovered()
end


--- Panel Class Functions
local panelClasses = {}

--- Extends the panel with new functionalities for events.
-- @param panel: The panel to extend.
-- @param eventName: The name of the event to hook into.
-- @param callback: The callback function to run when the event is triggered.
function panelClasses:ApplyEvent(eventName, callback)
    -- Set the default value for eventName if it is not specified
    eventName = eventName or 'Paint' -- If eventName is not set, we use 'Paint'
    local originalEvent = self[eventName]

    self[eventName] = function(sl, ...)
        if originalEvent then
            originalEvent(sl, ...)
        end
        callback(sl, ...)
    end
end

--- Sets a transition for a specified property of the panel.
-- @param propertyName: The name of the property to transition.
-- @param speed: The speed of the transition.
-- @param targetFunc: The function that determines the target value.
function panelClasses:SetTransition(propertyName, speed, targetFunc)
    self[propertyName] = 0
    self:ApplyEvent('Think', function(sl)
        sl[propertyName] = lerp(frame_time() * speed, sl[propertyName], (targetFunc or sl.TransitionFunc)(sl) and 1 or 0)
    end)
end

--- Applies a fade effect on hover to the panel with dynamic color support
-- @param color (Color): The color to fade to
-- @param speed (number): The speed of the fade transition
-- @param radius (number): The corner radius for rounded boxes
function panelClasses:ApplyFadeHover(color, speed, radius)
    self.color = color or color(255, 255, 255, 30)
    self.HoverColor = color
    self.HoverRadius = radius
    self:SetTransition('HoverFade', speed or 8, CustomUtils.IsHovered)
    
    self:ApplyEvent(nil, function(sl, w, h)
        local currentHoverColor = sl.HoverColor or self.color
        local currentRadius = sl.HoverRadius or radius
        local fadeColor = color_alpha(currentHoverColor, currentHoverColor.a * sl.HoverFade)
        
        if currentRadius and currentRadius > 0 then
            rounded_box(currentRadius, 0, 0, w, h, fadeColor)
        else
            draw_color(fadeColor)
            draw_rect(0, 0, w, h)
        end
    end)
    
    return self
end

--- Draws a blur effect on a specified panel
-- @param intensity: The intensity of the blur effect
-- @param depth: The number of iterations to apply the blur
function panelClasses:ApplyBlur(intensity, depth)
    intensity = intensity or 1
    depth = depth or 1
    local sw, sh = ScrW(), ScrH()
    self:ApplyEvent(nil, function(sl, w, h)
        local x, y = sl:LocalToScreen(0, 0)
        draw_color(255, 255, 255)
        draw_material(screenBlur)
        for i = 1, depth do
            screenBlur:SetFloat('$blur', (i / depth) * intensity)
            screenBlur:Recompute()
            render_update_screen_effect_texture()
            draw_textured_rect(-x, -y, sw, sh)
        end
    end)
    
    return self
end

--- Applies background color to the panel with dynamic color support
-- @param color (Color): The background color
-- @param radius (number): The corner radius
-- @param rounding (table): Custom rounding for corners {topLeft, topRight, bottomLeft, bottomRight}
function panelClasses:ApplyBackground(color, radius, rounding)
    color = color or color(10, 10, 10, 100)
    self.BackgroundColor = color
    self.BackgroundRadius = radius or 0
    self.BackgroundRounding = rounding
    
    self:ApplyEvent(nil, function(sl, w, h)
        local currentBgColor = sl.BackgroundColor or color
        
        if (currentBgColor.a == 0) then
            return
        end

        local bgRounding = sl.BackgroundRounding
        local bgRadius = sl.BackgroundRadius
        
        if bgRounding then
            rounded_box_ex(bgRadius, 0, 0, w, h, currentBgColor, bgRounding[1], bgRounding[2], bgRounding[3], bgRounding[4])
        elseif (bgRadius > 0) then
            rounded_box(bgRadius, 0, 0, w, h, currentBgColor)
        else
            draw_color(currentBgColor)
            draw_rect(0, 0, w, h)
        end
    end)
    
    return self
end

--- Applies a hover effect to a panel using a horizontal bar with dynamic color support
-- @param color: The color of the bar
-- @param height: The height of the bar (default is 2)
-- @param speed: Transition speed (default 6)
function panelClasses:ApplyBarHover(color, height, speed)
    color = color or color(255, 255, 255, 255)
    self.BarHoverColor = color
    self.BarHoverHeight = height or 2
    self:SetTransition('BarHover', speed or 6, CustomUtils.IsHovered)
    
    self:ApplyEvent('PaintOver', function(sl, w, h)
        local currentColor = sl.BarHoverColor or color
        local currentHeight = sl.BarHoverHeight or height
        local bar = round(w * sl.BarHover)
        
        draw_color(currentColor)
        draw_rect((w - bar) * 0.5, h - currentHeight, bar, currentHeight)
    end)
    
    return self
end

--- Applies a hover effect to the panel using fill with dynamic color support
-- @param color: Fill color
-- @param dir: Direction of the fill (default is BOTTOM)
-- @param speed: Transition speed (default is 8)
-- @param mat: Fill material (optional)
function panelClasses:ApplyFillHover(color, dir, speed, mat)
    color = color or color(255, 255, 255, 30)
    self.FillHoverColor = color
    self.FillHoverDir = dir or BOTTOM
    self.FillHoverMat = mat
    self:SetTransition('FillHover', speed or 8, CustomUtils.IsHovered)
    
    self:ApplyEvent('PaintOver', function(sl, w, h)
        local currentColor = sl.FillHoverColor or color
        local currentDir = sl.FillHoverDir or dir
        local currentMat = sl.FillHoverMat
        local fill = sl.FillHover
        
        draw_color(currentColor)
        
        local x, y, fw, fh
        if (currentDir == LEFT) then
            fw = round(w * fill)
            x, y, fh = 0, 0, h
        elseif (currentDir == TOP) then
            fh = round(h * fill)
            x, y, fw = 0, 0, w
        elseif (currentDir == RIGHT) then
            fw = round(w * fill)
            x, y, fh = w - fw, 0, h
        else -- BOTTOM
            fh = round(h * fill)
            x, y, fw = 0, h - fh, w
        end
        
        if currentMat then
            draw_material(currentMat)
            draw_textured_rect(x, y, fw, fh)
        else
            draw_rect(x, y, fw, fh)
        end
    end)
    
    return self
end

--- Applies a circle ripple effect on click with dynamic color support
-- @param color (Color): The ripple color
-- @param speed (number): Speed of the ripple animation
-- @param maxRadius (number): Maximum radius of the ripple
function panelClasses:ApplyCircleEffect(color, speed, maxRadius)
    color = color or Color(255, 255, 255, 100)
    self.CircleEffectColor = color
    self.CircleEffectSpeed = speed or 5
    self.CircleEffectMaxRadius = maxRadius
    self.CircleRadius = 0
    self.CircleAlpha = 0
    self.CircleX = 0
    self.CircleY = 0
    
    self:ApplyEvent('OnMousePressed', function(sl, keyCode)
        if (keyCode == MOUSE_LEFT or keyCode == MOUSE_RIGHT) then
            sl.CircleX, sl.CircleY = sl:CursorPos()
            sl.CircleRadius = 0
            sl.CircleAlpha = (sl.CircleEffectColor or color).a
        end
    end)
    
    self:ApplyEvent(nil, function(sl, w, h)
        if (sl.CircleAlpha <= 1) then
            return
        end
        
        local currentCircleColor = sl.CircleEffectColor or color
        local currentSpeed = sl.CircleEffectSpeed or speed
        local currentMaxRadius = sl.CircleEffectMaxRadius or max(w, h)
        local ft = frame_time() * currentSpeed
        
        draw_color(color_alpha(currentCircleColor, sl.CircleAlpha))
        no_texture()
        CustomUtils.DrawFilledCircle(sl.CircleX, sl.CircleY, sl.CircleRadius)
        
        sl.CircleRadius = lerp(ft, sl.CircleRadius, currentMaxRadius)
        
        local isHolding = (IsMouseDown(MOUSE_LEFT) or IsMouseDown(MOUSE_RIGHT)) and sl:IsHovered()
        sl.CircleAlpha = isHolding and max(sl.CircleAlpha, currentCircleColor.a * 0.5) or lerp(ft, sl.CircleAlpha, 0)
    end)
    
    return self
end

--- Pin the panel to a specified dock position with optional margin
-- @param dock: The docking position (default is FILL)
-- @param margin: The margin around the panel (default is 0)
-- @param dontInvalidate: If true, the parent will not be invalidated (default is false)
function panelClasses:Pin(dock, margin, dontInvalidate)
    self:Dock(dock or FILL)
    
    if (margin and margin > 0) then
        self:DockMargin(margin, margin, margin, margin)
    end

    if (not dontInvalidate) then
        self:InvalidateParent(true)
    end
    
    return self
end

--- Snaps the panel at the specified position with margins
-- @param dock: Snap position (default is FILL)
-- @param marginLeft: Left margin (default is 0)
-- @param marginTop: Top margin (default is 0)
-- @param marginRight: Right margin (default is 0)
-- @param marginBottom: Bottom margin (default is 0)
function panelClasses:PinMargin(dock, marginLeft, marginTop, marginRight, marginBottom)
    self:Dock(dock or FILL)
    self:DockMargin(marginLeft or 0, marginTop or 0, marginRight or 0, marginBottom or 0)
    return self
end

--- Sets the panel width equal to the parent width or screen width
function panelClasses:ApplyWide()
    local parent = self:GetParent()
    self:SetWide(parent and parent:GetWide() or ScrW())
    return self
end

--- Sets the panel height equal to the parent height or screen height
function panelClasses:ApplyTall()
    local parent = self:GetParent()
    self:SetTall(parent and parent:GetTall() or ScrH())
    return self
end

--- Applies sound effects to the panel
-- @param pathHover: Sound path for hover
-- @param pathClick: Sound path for click
function panelClasses:ApplySound(pathHover, pathClick)
    if pathHover then
        self:ApplyEvent('OnCursorEntered', function()
            surface_play_sound(pathHover)
        end)
    end

    if pathClick then
        local lastClickTime = 0
        self:ApplyEvent('OnMouseReleased', function(sl, keyCode)
            if (keyCode == MOUSE_LEFT or keyCode == MOUSE_RIGHT) then
                local currentTime = CurTime()
                -- Spam protection: minimum 0.1 seconds between clicks
                if (currentTime - lastClickTime > 0.1) then
                    surface_play_sound(pathClick)
                    lastClickTime = currentTime
                end
            end
        end)
    end
    
    return self
end

--- Applies text to the panel with dynamic color support
-- @param text (string): The text to display
-- @param font (string): The font to use
-- @param x (number): X position of the text
-- @param y (number): Y position of the text
-- @param color (Color): Default text color
-- @param xAlign (number): Horizontal text alignment
-- @param yAlign (number): Vertical text alignment
function panelClasses:ApplyText(text, font, x, y, color, xAlign, yAlign)
    self.Text = text
    self.TextFont = font or 'danlib_font_18'
    self.TextX = x
    self.TextY = y
    self.TextColor = color or DBase:Theme('text')
    self.TextXAlign = xAlign or TEXT_ALIGN_CENTER
    self.TextYAlign = yAlign or TEXT_ALIGN_CENTER
    
    self:ApplyEvent(nil, function(sl, w, h)
        if (not sl.Text) then
            return
        end
        
        simple_text(sl.Text, sl.TextFont, sl.TextX or w * 0.5, sl.TextY or h * 0.5, sl.TextColor, sl.TextXAlign, sl.TextYAlign)
    end)
    
    return self
end

--- Creates a panel with an avatar
-- @param rounded: Whether to use circular avatar
-- @param cornerRadius: The rounding radius of the avatar corners
-- @param outlineColor: Color of the outline
function panelClasses:ApplyAvatar(rounded, cornerRadius, outlineColor)
    self.AvatarRounded = rounded or false
    self.AvatarCornerRadius = cornerRadius or 4
    self.AvatarOutlineColor = outlineColor or DanLib.Func:Theme('frame')
    self.Avatar = vgui_create('AvatarImage', self)
    self.Avatar:SetPaintedManually(true)
    self.PerformLayout = function(sl)
        sl.Avatar:SetSize(sl:GetSize())
    end
    self.SetPlayer = function(sl, pPlayer, size)
        sl.Avatar:SetPlayer(pPlayer, size)
    end
    
    self.SetSteamID = function(sl, id, size)
        sl.Avatar:SetSteamID(id, size)
    end
    self.Paint = function(sl, w, h)
        if sl.AvatarRounded then
            render_clear_stencil()
            render_set_stencil_enable(true)
            render_set_stencil_write_mask(1)
            render_set_stencil_test_mask(1)
            render_set_stencil_fail_operation(STENCILOPERATION_REPLACE)
            render_set_stencil_pass_operation(STENCILOPERATION_ZERO)
            render_set_stencil_z_fail_operation(STENCILOPERATION_ZERO)
            render_set_stencil_compare_function(STENCILCOMPARISONFUNCTION_NEVER)
            render_set_stencil_reference_value(1)
            CustomUtils.DrawFilledCircle(w * 0.5, h * 0.5, min(w, h) * 0.5)
            render_set_stencil_fail_operation(STENCILOPERATION_ZERO)
            render_set_stencil_pass_operation(STENCILOPERATION_REPLACE)
            render_set_stencil_z_fail_operation(STENCILOPERATION_ZERO)
            render_set_stencil_compare_function(STENCILCOMPARISONFUNCTION_EQUAL)
            render_set_stencil_reference_value(1)
            sl.Avatar:PaintManual()
            render_set_stencil_enable(false)
            render_clear_stencil()
        else
            local radius = sl.AvatarCornerRadius
            DanLib.Utils:DrawRoundedMask(radius, 0, 0, w, h, function()
                rounded_box(radius, 0, 0, w, h, color(0, 0, 0, 150))
                sl.Avatar:PaintManual()
            end)
        end
    end
    
    return self
end

--- Applies the circle pattern to the panel
-- @param color: Color of the circle
function panelClasses:ApplyCircle(clr)
    self.CircleColor = clr or Color(255, 255, 255, 255)
    self:ApplyEvent(nil, function(sl, w, h)
        draw_color(sl.CircleColor)
        CustomUtils.DrawFilledCircle(w * 0.5, h * 0.5, min(w, h) * 0.5)
    end)
    
    return self
end

--- Applies a delete event to the panel.
-- Deletes the specified target if it is valid.
-- @param target: The target to delete. The default is the panel itself.
function panelClasses:ApplyRemove(target)
    target = target or self
    self:ApplyEvent('DoClick', function()
        if IsValid(target) then
            target:Remove()
        end
    end)

    return self
end

-- @param duration (nember): The time in seconds it should take to reach the alpha.
-- @param alpha (nember): The alpha value (0-255) to approach.
function panelClasses:ApplyAttenuation(duration, alpha)
    duration = duration or 0.2
    alpha = alpha or 255

    self:SetAlpha(0)
    self:AlphaTo(alpha, duration, 0)

    return self
end

--- Hides the vertical scrollbar.
-- Sets the width of the vertical scrollbar to 0 and hides it.
function panelClasses:ApplyHideBar()
    local vbar = self:GetVBar()
    vbar:SetWide(0)
    vbar:Hide()

    return self
end

--- Clears the panel drawing function.
-- Sets the panel drawing function to nil, resulting in no drawing.
function panelClasses:ApplyClearPaint()
    self.Paint = nil
    return self
end

--- Sets the transition function for the panel.
-- @param func: Function to be used for transitions.
function panelClasses:SetTransitionFunc(func)
    self.TransitionFunc = func
end

--- Clears the transition function for the panel.
-- Sets the transition function to nil, which disables transitions.
function panelClasses:ClearTransitionFunc()
    self.TransitionFunc = nil
end

--- Sets the function to add or overwrite.
-- @param func: The function to be used to add or overwrite.
function panelClasses:SetAppendOverwrite(func)
    self.AppendOverwrite = func
end

--- Clears the add or overwrite function.
-- Sets the add or overwrite function to nil.
function panelClasses:ClearAppendOverwrite()
    self.AppendOverwrite = nil
end

--- Configures the text field to be ready for editing.
-- Disables background fill and sets the add or overwrite function.
function panelClasses:ApplyReadyTextbox()
    self:SetPaintBackground(false)
    self:SetAppendOverwrite('PaintOver')
    self:SetTransitionFunc(function(sl)
        return sl:IsEditing()
    end)
    return self
end

-- Meta Function to Register Classes
local DMetaPanel = DanLib.MetaPanel
function DMetaPanel:CustomUtils()
    self.Class = function(panel, className, ...)
        local classFunc = panelClasses[className]
        assert(classFunc, '[Custom Utils]: Class ' .. className .. ' does not exist.')
        classFunc(panel, ...)
        return panel
    end

    for name, func in pairs(panelClasses) do
        self[name] = function(self, ...)
            return self:Class(name, ...)
        end
    end
    return self
end

--- Creates a new panel with specified class.
-- @param parent: The parent panel to attach the new panel to.
-- @param classname: The name of the class to create (defaults to 'EditablePanel').
-- @return The created panel item.
function DanLib.CustomUtils.Create(parent, classname)
    -- If parent is nil, return nil and do nothing
    parent = parent or nil

    -- If classname is not specified, we use 'EditablePanel' by default
    classname = classname or 'EditablePanel'

    -- Creating a new panel element based on the specified class
    local panel = vgui.Create(classname, parent)

    -- Applying the CustomUtils method to the created panel
    panel:CustomUtils()

    -- Return the created panel item
    return panel
end
