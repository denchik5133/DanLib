/***
 *   @addon         DanLib
 *   @component     Utils
 *   @license       MIT License
 *   @version       3.0.2
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
local DTable = DanLib.Table
local DUtils = DanLib.Utils
local DMaterial = DanLib.Config.Materials

local math = math
local _round = math.Round
local _max = math.max
local _rad = math.rad
local _min = math.min
local _sin = math.sin
local _cos = math.cos
local _pow = function(a, b)
    return a ^ b
end
local _ceil = math.ceil
local _floor = math.floor
local _Clamp = math.Clamp
local _EaseInOut = math.EaseInOut

local surface = surface
local set_material = surface.SetMaterial
local draw_color = surface.SetDrawColor
local draw_poly = surface.DrawPoly
local draw_line = surface.DrawLine
local draw_texture = surface.SetTexture
local draw_text = surface.DrawText
local draw_textured_rect = surface.DrawTexturedRect
local draw_textured_rect_rotated = surface.DrawTexturedRectRotated
local draw_textured_rect_uv = surface.DrawTexturedRectUV
local draw_rect = surface.DrawRect
local set_font = surface.SetFont
local get_text_size = surface.GetTextSize
local set_text_color = surface.SetTextColor
local draw_outlined_rect = surface.DrawOutlinedRect
local set_text_pos = surface.SetTextPos
local draw_texture_id = surface.GetTextureID

local draw = draw
local draw_text = draw.DrawText
local _RoundedBox = draw.RoundedBox
local _RoundedBoxEx = draw.RoundedBoxEx
local _SimpleText = draw.SimpleText
local _NoTexture = draw.NoTexture

local render = render
local push_filter_mag = render.PushFilterMag
local push_filter_min = render.PushFilterMin
local pop_filter_mag = render.PopFilterMag
local pop_filter_min = render.PopFilterMin
local depth_range = render.DepthRange
local rmaterial = render.SetMaterial
local update_screen_effect_texture = render.UpdateScreenEffectTexture
local set_stencil_write_mask = render.SetStencilWriteMask
local set_stencil_test_mask = render.SetStencilTestMask
local set_stencil_reference_value= render.SetStencilReferenceValue
local set_stencil_pass_operation = render.SetStencilPassOperation
local set_stencilZ_fail_operation = render.SetStencilZFailOperation
local clear_stencil = render.ClearStencil
local rclear = render.Clear
local set_stencil_compare_function = render.SetStencilCompareFunction
local set_stencil_fail_operation = render.SetStencilFailOperation
local set_stencil_enable = render.SetStencilEnable
local pushRenderTarget = render.PushRenderTarget
local overrideAlphaWriteEnable = render.OverrideAlphaWriteEnable
local overrideBlendFunc = render.OverrideBlendFunc
local popRenderTarget = render.PopRenderTarget
local drawScreenQuad = render.DrawScreenQuad
local getRenderTargetEx = GetRenderTargetEx

local string = string
local _format = string.format
local _match = string.match
local _gmatch = string.gmatch
local _rep = string.rep

local bit = bit
local _bitBor = bit.bor
local _bitBand = bit.band
local _bitLshift = bit.lshift

local _Lerp = Lerp
local _type = type
local _ScrW = ScrW
local _ScrH = ScrH
local _Color = Color
local _unpack = unpack
local _SysTime = SysTime
local _pairs = pairs
local _ipairs = ipairs
local _error = error
local _CurTime = CurTime
local _material = Material
local _tonumber = tonumber
local _isstring = isstring
local _ColorToHSV = ColorToHSV
local _HSVToColor = HSVToColor

do
    --- Scales a value based on the current screen width.
    -- @param value (number): The value to scale.
    -- @return (number): The scaled value.
    function DBase:Scale(value)
        return _round(value * (_ScrW() / 2560))
    end

    --- Scales a value based on the current screen height, ensuring a minimum value of 1.
    -- @param value (number): The value to scale.
    -- @return (number): The scaled value, or 1 if the result is less than 1.
    function DBase:ScaleH(value)
       return _max(value * (_ScrH() / 1080), 1)
    end

    --- Scales the original width and height based on the current screen resolution.
    -- @param originalWidth (number): The original width of the element.
    -- @param originalHeight (number): The original height of the element.
    -- @return (number, number): The new scaled width and height.
    function DUtils:ScaleSize(originalWidth, originalHeight)
        -- Get the current screen resolution
        local screenWidth, screenHeight = _ScrW(), _ScrH()
        -- Determine the scaling factors
        local widthScale = screenWidth / 1920 -- 1920 - standard width
        local heightScale = screenHeight / 1080 -- 1080 - standard height
        -- We use the minimum scaling factor to preserve proportions
        local scale = _min(widthScale, heightScale)
        -- Returning the new sizes
        return originalWidth * scale, originalHeight * scale
    end

    function DUtils:ScaleWide(w, ref)
        ref = ref or 1600
        return _round(w / ref * _ScrW())
    end

    function DUtils:ScaleTall(h, ref)
        ref = ref or 900
        return _round(h / ref * _ScrH())
    end

    --- Calculates the X position based on a relative percentage of the screen width.
    -- @param t (number): The relative position factor.
    -- @return (number): The calculated X position.
    function DUtils:PosX(t)
        return (_ScrW() / 2) * t
    end

    --- Calculates the Y position based on a relative percentage of the screen height.
    -- @param t (number): The relative position factor.
    -- @return (number): The calculated Y position.
    function DUtils:PosY(t)
        return (_ScrH() / 2) * t
    end

    --- Scales a width value based on the standard width of 1920.
    -- @param x (number): The reference width value.
    -- @return (number): The scaled width based on the current screen width.
    function DUtils:Width(x)
        return 1920 / x * _ScrW()
    end

    --- Scales a height value based on the standard height of 1080.
    -- @param y (number): The reference height value.
    -- @return (number): The scaled height based on the current screen width.
    function DUtils:Height(y)
        return 1080 / y * _ScrW()
    end

    --- Returns the current screen width in pixels.
    -- @return (number): Current screen width.
    function DUtils:ScreenW()
        return _ScrW()
    end

    --- Returns the current screen height in pixels.
    -- @return (number): Current screen height.
    function DUtils:ScreenH()
        return _ScrH()
    end

    --- Converts a fraction (0.0-1.0) to an X pixel position on the current screen.
    -- 0.0 = left edge, 1.0 = right edge.
    -- Use with SetMinMax(0, DBase:ScreenW()) for resolution-aware config options.
    -- @param fraction (number): Relative horizontal position (e.g. 0.5 = center).
    -- @return (number): Pixel X coordinate clamped to [0, ScrW()].
    function DUtils:ScreenX(fraction)
        local w = _ScrW()
        return _Clamp(_round(w * fraction), 0, w)
    end

    --- Converts a fraction (0.0-1.0) to a Y pixel position on the current screen.
    -- 0.0 = top edge, 1.0 = bottom edge.
    -- Use with SetMinMax(0, DBase:ScreenH()) for resolution-aware config options.
    -- @param fraction (number): Relative vertical position (e.g. 0.5 = center).
    -- @return (number): Pixel Y coordinate clamped to [0, ScrH()].
    function DUtils:ScreenY(fraction)
        local h = _ScrH()
        return _Clamp(_round(h * fraction), 0, h)
    end
end

-- Draws a blur effect on a specified panel.
-- @param panel: The panel on which to draw the blur effect.
-- @param intensity: The intensity of the blur effect.
-- @param depth: The number of iterations to apply the blur, affecting the smoothness.
-- @return: None (the function directly modifies the rendering output).
local blurMaterial = DMaterial['Blur']
function DUtils:DrawBlur(panel, intensity, depth)
    -- Get the screen position of the panel
    local x, y = panel:LocalToScreen(0, 0)

    -- Set the draw color to white
    draw_color(255, 255, 255)

    -- Set the blur material
    set_material(blurMaterial)

    -- Update the screen effect texture once before the loop
    if render then 
        update_screen_effect_texture() 
    end

    -- Loop to create the blur effect
    for i = 1, depth do
        -- Calculate the blur amount for the current iteration
        local blurAmount = (i / depth) * intensity
        blurMaterial:SetFloat('$blur', blurAmount)
        blurMaterial:Recompute()

        -- Draw the textured rectangle with the current blur
        draw_textured_rect(-x, -y, _ScrW(), _ScrH())
    end
end

-- This function can be useful in various situations, such as when you want to display the number
-- of objects on the screen or when working with coordinates where integer values are needed:
function DUtils:Round(x)
    return x >= 0 and _floor(x + 0.5) or _ceil(x - 0.5)
end

-- This feature is useful when creating animations to make
-- them more natural and pleasing to look at:
function DUtils:Easing(x)
    return x < 0.5 and 4 * x * x * x or 1 - _pow(-2 * x + 2, 3) / 2
end

-- The DUtils:Repeat function is designed to create a repeating list of values.
-- It accepts two parameters: val (the value to be repeated) and amount (the number of repetitions).
-- Suppose you want to create several objects in the game that have the same properties.
-- Instead of manually specifying the same value, you can use DUtils:Repeat:
--      local positions = { DUtils:Repeat(Vector(0, 0, 0), 5) }
--      This will create a table containing the same value 5 times Vector(0, 0, 0)
function DUtils:Repeat(val, amount)
    local args = { }
    for i = 1, amount do
        DTable:Add(args, val)
    end
    return _unpack(args)
end

do
    --- Function for wrapping text by character
    -- @param text: Text string for wrapping
    -- @param remainingWidth: Remaining width for wrapping
    -- @param maxWidth: Maximum width of the string
    -- @return Wrapped text and total width
    local function charWrap(text, remainingWidth, maxWidth)
        local totalWidth = 0

        return text:gsub('.', function(char)
            local charWidth = get_text_size(char)
            totalWidth = totalWidth + charWidth

            -- Wrap when the maximum width has been reached
            if (totalWidth >= remainingWidth) then
                totalWidth = charWidth -- Resetting the width for a new row
                remainingWidth = maxWidth
                return '\n' .. char
            end

            return char
        end), totalWidth
    end

    --- Function for wrapping text by words
    -- @param text: String of text to be wrapped
    -- @param font: Font to be used
    -- @param maxWidth: Maximum width of the string
    -- @return Wrapped text and number of lines
    function DUtils:TextWrap(text, font, maxWidth, ignoreTags)
        local totalWidth = 0

        font = font or 'danlib_font_18'
        set_font(font)

        local spaceWidth = get_text_size(' ')

        -- Deletes tags if ignoreTags is set to true
        -- Note that using the DUtils:TextSize or DUtils:GetTextSize functions
        -- may cause tags to be counted as characters. In some cases this may be
        -- undesirable and interfere with both the proper display of text and the calculation of element size.
        -- It is therefore important to consider the possibility of ignoring tags when calculating text widths and sizes.
        if ignoreTags then
            text = text:gsub('{color:%s*%d+,%s*%d+,%s*%d+}', '') -- Remove colour tags
            text = text:gsub('{/color:}', '') -- Remove closing colour tag
            text = text:gsub('{font:%s*[%w_]+}', '') -- Remove font tags
            text = text:gsub('{/font:}', '') -- Remove closing font tag
        end

        return text:gsub('(%s?[%S]+)', function(word)
            local char = word:sub(1, 1)
            if (char == '\n' or char == '\t') then
                totalWidth = 0
            end

            local wordWidth = get_text_size(word)
            totalWidth = totalWidth + wordWidth

            -- A wrapper if the word is too long
            if (wordWidth >= maxWidth) then
                local splitWord, splitPoint = charWrap(word, maxWidth - (totalWidth - wordWidth), maxWidth)
                totalWidth = splitPoint
                return splitWord
            elseif (totalWidth < maxWidth) then
                return word
            end

            -- The wrapper in front of the word
            if (char == ' ') then
                totalWidth = wordWidth - spaceWidth
                return '\n' .. word:sub(2)
            end

            totalWidth = wordWidth
            return '\n' .. word
        end), select(2, text:gsub('\n', '')) + 1 -- Number of lines
    end
end

do
    --- Draws two texts on the screen
    -- @param x: X-coordinate for the text
    -- @param y: Y-coordinate for the text
    -- @param topText: The text to be displayed on top.
    -- @param topFont: Font for the top text
    -- @param topColor: Colour for the top text
    -- @param bottomText: Text to be displayed at the bottom
    -- @param bottomFont: Font for bottom text
    -- @param bottomColor: Colour for the bottom text
    -- @param alignment: Text alignment (left by default)
    -- @param centerSpacing: Adjust the distance between two texts
    -- @param maxWidth: Maximum width for the text (optional)
    function DUtils:DrawDualText(x, y, topText, topFont, topColor, bottomText, bottomFont, bottomColor, alignment, centerSpacing, maxWidth)
        topFont = topFont or 'danlib_font_20'
        topColor = topColor or _Color(0, 127, 255, 255)
        bottomFont = bottomFont or 'danlib_font_18'
        bottomColor = bottomColor or color_white
        alignment = alignment or TEXT_ALIGN_LEFT
        centerSpacing = centerSpacing or 0

        -- Function for trimming text with addition '...'
        local function truncateText(text, font, maxWidth)
            -- If maxWidth is not set, return the text unchanged
            if (maxWidth == nil) then return text end

            local textWidth = self:TextSize(text, font).w
            if (textWidth <= maxWidth) then
                return text
            else
                local ellipsis = '...'
                local ellipsisWidth = self:TextSize(ellipsis, font).w
                local truncatedText = text

                -- Delete characters until the text is smaller than maxWidth
                while self:TextSize(truncatedText, font).w + ellipsisWidth > maxWidth do
                    truncatedText = truncatedText:sub(1, -2) -- Delete the last character
                end

                return truncatedText .. ellipsis
            end
        end

        -- Text cropping if maxWidth is set
        topText = truncateText(topText, topFont, maxWidth)
        bottomText = truncateText(bottomText, bottomFont, maxWidth)

        -- Returns the height
        local topHeight = self:TextSize(topText, topFont).h
        local bottomHeight = self:TextSize(bottomText, bottomFont).h

        -- Centre text vertically
        local totalHeight = topHeight + bottomHeight + centerSpacing
        local topY = y - (totalHeight / 2) -- Top text
        local bottomY = topY + topHeight + centerSpacing -- Lower text

        draw_text(topText, topFont, x, topY, topColor, alignment)
        draw_text(bottomText, bottomFont, x, bottomY, bottomColor, alignment)
    end

    --- Draws two texts on the screen without truncation
    -- @param x: X-coordinate for the text
    -- @param y: Y-coordinate for the text
    -- @param topText: The text to be displayed on top.
    -- @param topFont: Font for the top text
    -- @param topColor: Colour for the top text
    -- @param bottomText: Text to be displayed at the bottom
    -- @param bottomFont: Font for bottom text
    -- @param bottomColor: Colour for the bottom text
    -- @param alignment: Text alignment (left by default)
    -- @param centerSpacing: Adjust the distance between two texts
    -- @param maxWidth: Maximum width for the text (optional)
    function DUtils:DrawDualTextWrap(x, y, topText, topFont, topColor, bottomText, bottomFont, bottomColor, alignment, centerSpacing, maxWidth)
        x = x or 0
        y = y or 0
        topFont = topFont or 'danlib_font_20'
        topColor = topColor or _Color(0, 127, 255, 255)
        bottomFont = bottomFont or 'danlib_font_18'
        bottomColor = bottomColor or color_white
        alignment = alignment or TEXT_ALIGN_LEFT
        centerSpacing = centerSpacing or 0

        -- Text processing without cropping
        bottomText = self:TextWrap(bottomText, bottomFont, maxWidth)

        -- Height revert
        local topHeight = self:TextSize(topText, topFont).h
        local bottomHeight = self:TextSize(bottomText, bottomFont).h

        -- Centre text vertically
        local totalHeight = topHeight + bottomHeight + centerSpacing
        local topY = y - (totalHeight / 2) -- Top text
        local bottomY = topY + topHeight + centerSpacing -- Lower text

        draw_text(topText, topFont, x, topY, topColor, alignment)
        draw_text(bottomText, bottomFont, x, bottomY, bottomColor, alignment)
    end

    --- Draws text with an accompanying icon for added visual appeal.
    -- @param text (string): The text to display.
    -- @param font (string): The font to use (optional).
    -- @param ColorText (Color): The color of the text (optional).
    -- @param icon (string or Material): The icon to display (optional).
    -- @param size (number): The size of the icon (optional).
    -- @param ColorIcon (Color): The color of the icon (optional).
    -- @param x (number): The x-coordinate for positioning.
    -- @param y (number): The y-coordinate for positioning.
    -- @param AlignX (number): The horizontal alignment (optional).
    -- @param AlignY (number): The vertical alignment (optional).
    function DUtils:DrawIconText(text, font, ColorText, icon, size, ColorIcon, x, y, AlignX, AlignY)
        font = font or 'danlib_font_20'
        size = size or 18

        local ColorDefault = color_white
        ColorText = ColorText or ColorDefault
        ColorIcon = ColorIcon or ColorDefault

        local w, h = self:GetTextSize(text, font)

        if icon then
            if (AlignX == TEXT_ALIGN_LEFT) then
                _SimpleText(text, font, size + x, y, ColorText, AlignX, AlignY)
                self:DrawIconOrMaterial(x, y * 0.5, size, icon, ColorIcon)
            elseif (AlignX == TEXT_ALIGN_RIGHT) then
                _SimpleText(text, font, x - size + 16, y, ColorText, AlignX, AlignY)
                self:DrawIconOrMaterial(x, y * 0.5, size, icon, ColorIcon)
            else
                _SimpleText(text, font, x + (size / 2) + 20, y, ColorText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                self:DrawIconOrMaterial(x - w + (x / w), y - 20, size, icon, ColorIcon)
            end
        else
            _SimpleText(text, font, x, y, ColorText, AlignX, AlignY)
        end
    end

    --- Draws two pieces of text with customizable fonts, colors, and alignment.
    -- @param tText1: The first text string to be drawn.
    -- @param fFont1: The font used for the first text. Defaults to 'danlib_font_18'.
    -- @param cColor1: The color of the first text. Defaults to white (255, 255, 255, 255).
    -- @param tText2: The second text string to be drawn.
    -- @param fFont2: The font used for the second text. Defaults to 'danlib_font_18'.
    -- @param cColor2: The color of the second text. Defaults to white (255, 255, 255, 255).
    -- @param x: The x-coordinate for positioning the text.
    -- @param y: The y-coordinate for positioning the text.
    -- @param alignx: Horizontal alignment of the text (e.g., TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER).
    -- @param aligny: Vertical alignment of the text (not utilized in this function but can be included for future use).
    function DUtils:DrawSomeText(tText1, fFont1, cColor1, tText2, fFont2, cColor2, x, y, alignx, aligny)
        -- Set default font and color
        local FontDefault = 'danlib_font_18'
        fFont1 = fFont1 or FontDefault
        fFont2 = fFont2 or FontDefault

        local ColorDefault = color_white
        cColor1 = cColor1 or ColorDefault
        cColor2 = cColor2 or ColorDefault

        -- Get the width of both texts
        local w1 = self:TextSize(tText1, fFont1).w
        local w2 = self:TextSize(tText2, fFont2).w

        -- Draw the first text based on the alignment
        draw_text(tText1, fFont1, x, y, cColor1, alignx, aligny)

        -- Calculate the position for the second text based on alignment
        local offsetX = 4  -- Space between the texts
        if (alignx == TEXT_ALIGN_LEFT) then
            x = x + w1 + offsetX
        elseif (alignx == TEXT_ALIGN_RIGHT) then
            x = x - w2 - offsetX
        else  -- Center alignment
            x = x + (w1 + w2) * 0.5 + offsetX
        end

        -- Draw the second text
        draw_text(tText2, fFont2, x, y, cColor2, alignx, aligny)
    end
end

--- Calculates the inverse linear interpolation of a value within a range.
-- @param number pos The position to interpolate.
-- @param number p1 The start of the range.
-- @param number p2 The end of the range.
-- @return number The normalized value between 0 and 1, or 1 if range is zero.
function DUtils:InverseLerp(pos, p1, p2)
    local range = 0
    range = p2 - p1

    if (range == 0) then
        return 1
    end
    return ((pos - p1) / range)
end

--- Draws a loading animation with circles.
-- @param number w The width of the area to draw in.
-- @param number h The height of the area to draw in.
-- @param Color color The color of the circles (optional).
function DUtils:DrawLoad(w, h, color)
    color = color or DBase:GetColor('Blue')
    local mat = _material('vgui/circle')

    for i = 0, 3 do
        -- Set the drawing color and material
        draw_color(color)
        set_material(mat)

        -- Calculate the position and draw the textured rectangle
        local x = w * 0.5 - i * 16 + 12
        local y = h * 0.5 + 4 - 8 - _Clamp(_sin((_CurTime() - 0.2 * i) * 4), 0, 1) * 25
        draw_textured_rect(x, y, 16, 16)
    end
end

do
    --- Safely formats text for drawing.
    -- @param text (string): The text to format.
    -- @return (string): The formatted text, or the original text if not matching.
    -- @source: https://github.com/FPtje/DarkRP/blob/master/gamemode/modules/base/cl_drawfunctions.lua
    local function safeText(text)
        return _match(text, '^#([a-zA-Z_]+)$') and text .. ' ' or text
    end

    --- Draws non-parsed text on the screen.
    -- @param text (string): The text to draw.
    -- @param font (string): The font to use.
    -- @param x (number): The x-coordinate.
    -- @param y (number): The y-coordinate.
    -- @param color (Color): The color of the text.
    -- @param xAlign (number): The horizontal alignment.
    function DUtils:DrawNonParsedText(text, font, x, y, color, xAlign)
        return draw_text(safeText(text), font, x, y, color, xAlign)
    end
end

--- Draws an outline around a rectangle.
-- @param x (number): The x-coordinate of the rectangle.
-- @param y (number): The y-coordinate of the rectangle.
-- @param w (number): The width of the rectangle.
-- @param h (number): The height of the rectangle.
-- @param color (Color): The color of the outline (optional).
function DUtils:DrawOutline(x, y, w, h, color) end

--- Draws a rectangle with an outline.
-- @param x (number): The x-coordinate of the rectangle.
-- @param y (number): The y-coordinate of the rectangle.
-- @param w (number): The width of the rectangle.
-- @param h (number): The height of the rectangle.
-- @param color (Color) The color of the rectangle (optional).
-- @param number width The width of the outline (optional).
function DUtils:OutlinedRect(x, y, w, h, color, width)
    draw_color(color or color_white)
    draw_outlined_rect(x or 0, y or 0, w or 0, h or 0, width or 1)
end

--- Gets the size of the specified text in the given font.
-- @param text (string): The text to measure.
-- @param font (string): The font to use (optional).
-- @return table: A table containing the width and height of the text.
function DUtils:GetTextSize(text, font)
    text = text or 'No data'
    font = font or 'danlib_font_22'
    set_font(font)
    return get_text_size(text)
end

--- Returns the width and height of the specified text in the given font.
-- @param text (string): The text to measure.
-- @param font (string): The font to use (optional).
-- @return table A table with width (w) and height (h) of the text.
function DUtils:TextSize(text, font)
    font = font or 'danlib_font_20'
    set_font(font)
    local width, height = get_text_size(text)
    return {
        w = width,
        h = height
    }
end

--- Draws a filled rectangle.
-- @param x (number): The x-coordinate of the rectangle.
-- @param y (number): The y-coordinate of the rectangle.
-- @param w (number): The width of the rectangle.
-- @param h (number): The height of the rectangle.
-- @param color (Color): The color of the rectangle (optional).
function DUtils:DrawRect(x, y, w, h, color)
    color = color or color_white
    draw_color(color)
    draw_rect(x, y, w, h)
end

--- Draws a line between two points.
-- @param x (number): The starting x-coordinate.
-- @param y (number): The starting y-coordinate.
-- @param eX (number): The ending x-coordinate.
-- @param eY (number): The ending y-coordinate.
-- @param color (Color): The color of the line (optional).
function DUtils:DrawLine(x, y, eX, eY, color)
    color = color or color_white

    draw_color(color)
    draw_line(x, y, eX, eY)
end

do
    -- Set the standard rounding value
    local defaultRoundness = 6

    --- Function to draw a rounded box with the ability to adjust the rounding of the corners
    -- @param x: X-coordinate of the top left corner
    -- @param y: Y-coordinate of the upper left corner
    -- @param w: Width of box
    -- @param h: Height of box
    -- @param colour: Box colour
    -- @param roundTopLeft: Indicates whether the top left corner should be rounded or not
    -- @param roundTopRight: Indicates whether the top right corner should be rounded or not.
    -- @param roundBottomLeft: Indicates if the bottom left corner should be rounded.
    -- @param roundBottomRight: Indicates whether to round the bottom right corner
    local function draw_rounded_box_ex(x, y, w, h, color, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
        -- Limit the rounding value so that it does not exceed half of the height
        local roundness = _Clamp(defaultRoundness, 0, h * 0.5)

        -- Checking for zero value of width or height
        if (w <= 0 or h <= 0) then
            return
        end

        -- If rounding is not required, draw a rectangle
        if (roundness == 0) then
            draw_color(color)
            draw_rect(x, y, w, h)
        else
            -- Drawing a rounded rectangle
            _RoundedBoxEx(roundness, x, y, w, h, color, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
        end
    end

    --- Simplified function for drawing a fully rounded box
    -- @param x: X-coordinate of the top left corner
    -- @param y: Y-coordinate of the top left corner
    -- @param w: Width of the box
    -- @param h: Height of box
    -- @param colour: Box colour
    function DUtils:DrawRoundedBox(x, y, w, h, color)
        -- Draw a rounded box with fully rounded corners
        draw_rounded_box_ex(x, y, w, h, color, true, true, true, true)
    end

    --- Function to draw a box with only the top corners rounded
    -- @param x: X-coordinate of the top left corner
    -- @param y: Y-coordinate of the top left corner
    -- @param w: Width of the box
    -- @param h: Height of the box
    -- @param colour: Box colour
    function DUtils:DrawRoundedTopBox(x, y, w, h, color)
        -- Draw a box with only the top corners rounded
        draw_rounded_box_ex(x, y, w, h, color, true, true, false, false)
    end

    --- Function to draw a box with only the bottom corners rounded
    -- @param x: X-coordinate of the top left corner
    -- @param y: Y-coordinate of the top left corner
    -- @param w: Width of the box
    -- @param h: Height of the box
    -- @param colour: Box colour
    function DUtils:DrawRoundedBottomBox(x, y, w, h, color)
        -- Draw a box with only the bottom corners rounded
        draw_rounded_box_ex(x, y, w, h, color, false, false, true, true)
    end

    --- Function to draw a box with only the left corners rounded
    -- @param x: X-coordinate of the top left corner
    -- @param y: Y-coordinate of the top left corner
    -- @param w: Width of the box
    -- @param h: Height of the box
    -- @param colour: Box colour
    function DUtils:DrawRoundedLeftBox(x, y, w, h, color)
        -- Draw a box with only the left corners rounded
        draw_rounded_box_ex(x, y, w, h, color, true, false, true, false)
    end

    --- Function to draw a box with only the right corners rounded
    -- @param x: X-coordinate of the top left corner
    -- @param y: Y-coordinate of the top left corner
    -- @param w: Width of the box
    -- @param h: Height of the box
    -- @param colour: Box colour
    function DUtils:DrawRoundedRightBox(x, y, w, h, color)
        -- Draw a box with only the right corners rounded
        draw_rounded_box_ex(x, y, w, h, color, false, true, false, true)
    end
end

--- Draws a polygon on the screen.
-- @param vertices: A table of vertices defining a polygon. Each vertex must be represented as a table with coordinates {x, y}.
-- @param color: The colour of the polygon. The default colour is white (255, 255, 255, 255, 255).
function DUtils:DrawPoly(vertices, color)
    -- Set the default colour if not passed in
    color = color or color_white

    -- Check that the vertex table is not empty and contains at least one vertex
    if (vertices and #vertices > 0) then
        -- Turning off the texture for rendering
        _NoTexture()
        -- Set the colour for rendering
        draw_color(color)
        -- Draw a polygon using an array of vertices
        draw_poly(vertices)
    end
end

do
    --- Draws a material at a specified position with optional rotation.
    -- @param x (number): The x-coordinate of the material.
    -- @param y (number): The y-coordinate of the material.
    -- @param w (number): The width of the material.
    -- @param h (number): The height of the material.
    -- @param color (Color): The color of the material (optional).
    -- @param mat (Material): The material to draw (optional).
    -- @param ang (number): The angle for rotation (optional).
    function DUtils:DrawMaterial(x, y, w, h, color, mat, ang)
        color = color or color_white
        mat = mat or _material('error')

        draw_color(color)
        set_material(mat)
        
        if ang then
            draw_textured_rect_rotated(x, y, w, h, ang)
        else
            draw_textured_rect(x, y, w, h)
        end
    end

    --- Draws an icon or material based on the provided parameters.
    -- @param x (number): The x-coordinate for drawing.
    -- @param y (number): The y-coordinate for drawing.
    -- @param size (number): The size of the icon/material.
    -- @param strIcon (string|Material): The icon or material to draw.
    -- @param strIconCol (Color): The color of the icon/material (optional).
    function DUtils:DrawIconOrMaterial(x, y, size, strIcon, strIconCol)
        if _isstring(strIcon) then
            self:DrawIcon(x, y, size, size, strIcon, strIconCol or DBase:Theme('mat', 200))
        else
            self:DrawMaterial(x, y, size, size, strIconCol or DBase:Theme('mat', 200), strIcon)
        end
    end
end

do
    -- Configuration constants
    local ADAPTIVE_SCALING_CONFIG = {
        MIN_SIZE = 32, -- Minimum icon size (32x32)
        MAX_SIZE = 124, -- Maximum icon size (124x124)
        WIDTH_RATIO = 0.25, -- Parent width ratio for size calculation
        HEIGHT_RATIO = 0.6, -- Parent height ratio for size calculation
        PIXEL_PERFECT = true -- Ensure even pixel dimensions
    }

    --- Calculate adaptive icon size based on parent container dimensions
    -- @param parentWidth (number): Width of the parent container
    -- @param parentHeight (number): Height of the parent container  
    -- @param minSize (number, optional): Minimum size constraint (default: 32)
    -- @param maxSize (number, optional): Maximum size constraint (default: 124)
    -- @param options (table, optional): Additional scaling options
    -- @return (number): Calculated icon size
    function DUtils:CalculateAdaptiveIconSize(parentWidth, parentHeight, minSize, maxSize, options)
        -- Set default values
        minSize = minSize or ADAPTIVE_SCALING_CONFIG.MIN_SIZE
        maxSize = maxSize or ADAPTIVE_SCALING_CONFIG.MAX_SIZE
        options = options or { }
        
        -- Get scaling ratios (allow override via options)
        local widthRatio = options.widthRatio or ADAPTIVE_SCALING_CONFIG.WIDTH_RATIO
        local heightRatio = options.heightRatio or ADAPTIVE_SCALING_CONFIG.HEIGHT_RATIO
        
        -- Calculate base size from parent dimensions
        local widthBasedSize = parentWidth * widthRatio
        local heightBasedSize = parentHeight * heightRatio
        local baseSize = _min(widthBasedSize, heightBasedSize)
        
        -- Apply size constraints
        local adaptiveSize = _max(minSize, _min(maxSize, baseSize))
        
        -- Ensure pixel-perfect rendering (even numbers)
        if ADAPTIVE_SCALING_CONFIG.PIXEL_PERFECT then
            adaptiveSize = _floor(adaptiveSize / 2) * 2
        end

        return adaptiveSize
    end
    
    --- Enhanced DrawIcon function with adaptive scaling support
    -- @param x (number): X position
    -- @param y (number): Y position  
    -- @param parentW (number): Parent container width
    -- @param parentH (number): Parent container height
    -- @param icon (string): Icon identifier
    -- @param color (Color): Icon color
    -- @param customSize (number, optional): Override calculated size
    -- @param options (table, optional): Additional options
    -- @return (number): Final icon size used
    function DUtils:DrawAdaptiveIcon(x, y, parentW, parentH, icon, color, customSize, options)
        options = options or { }
        
        -- Calculate or use provided size
        local iconSize = customSize or self:CalculateAdaptiveIconSize(parentW, parentH, 
            options.minSize, options.maxSize, options)
        
        -- Calculate centered position if requested
        local finalX, finalY = x, y
        if options.centerX then
            finalX = x + (parentW - iconSize) * 0.5
        end

        if options.centerY then
            finalY = y + (parentH - iconSize) * 0.5
        end
        
        -- Use existing DrawIcon function with calculated parameters
        self:DrawIcon(finalX, finalY, iconSize, iconSize, icon, color)
        return iconSize
    end

    --- Batch calculate adaptive sizes for multiple containers
    --- Useful for optimizing multiple icon calculations
    -- @param containers (table): Array of {width, height} pairs
    -- @param options (table, optional): Scaling options
    -- @return (table): Array of calculated icon sizes
    function DUtils:BatchCalculateAdaptiveSizes(containers, options)
        local results = { }
        for i, container in _ipairs(containers) do
            results[i] = self:CalculateAdaptiveIconSize(container[1], container[2], options and options.minSize, options and options.maxSize, options)
        end
        return results
    end
    
    --- Get scaling information for debugging/monitoring
    -- @param parentW (number): Parent width
    -- @param parentH (number): Parent height
    -- @return (table): Scaling information
    function DUtils:GetAdaptiveScalingInfo(parentW, parentH)
        local size = self:CalculateAdaptiveIconSize(parentW, parentH)
        return {
            parentWidth = parentW,
            parentHeight = parentH,
            calculatedSize = size,
            scaleFactor = size / ADAPTIVE_SCALING_CONFIG.MIN_SIZE,
            isMinSize = (size == ADAPTIVE_SCALING_CONFIG.MIN_SIZE),
            isMaxSize = (size == ADAPTIVE_SCALING_CONFIG.MAX_SIZE),
            config = ADAPTIVE_SCALING_CONFIG
        }
    end
end

do
    --- Sets the parameters for the operation of the cStepsil.
    -- @param stencilValue: Value for stencil, defaults to 1.
    local function SetupStencil(stencilValue)
        set_stencil_write_mask(1)
        set_stencil_test_mask(1)
        set_stencil_fail_operation(STENCILOPERATION_REPLACE)
        set_stencil_pass_operation(STENCILOPERATION_ZERO)
        set_stencilZ_fail_operation(STENCILOPERATION_ZERO)
        set_stencil_compare_function(STENCILCOMPARISONFUNCTION_NEVER)
        set_stencil_reference_value(stencilValue)
    end

    --- Performs operations on the mask and draw function.
    -- @param mask: Function for drawing a mask.
    -- @param func: Function for rendering in the mask area.
    -- @param stencil: Value for stencil, defaults to 1.
    function DUtils:DrawMask(mask, func, stencil)
        -- Use the default value if not passed.
        stencil = stencil or 1

        clear_stencil()
        set_stencil_enable(true)

        -- Customising the stencil for the mask.
        SetupStencil(stencil)

            -- Drawing the mask.
            draw_color(color_white)
            _NoTexture()
            mask()

        -- Set parameters for drawing inside the mask.
        set_stencil_fail_operation(STENCILOPERATION_ZERO)
        set_stencil_pass_operation(STENCILOPERATION_REPLACE)
        set_stencilZ_fail_operation(STENCILOPERATION_ZERO)
        set_stencil_compare_function(STENCILCOMPARISONFUNCTION_EQUAL)
        set_stencil_reference_value(stencil)

            -- We perform drawing in the mask area.
            func()

        set_stencil_enable(false)
        -- Clearing the stencil.
        clear_stencil()
    end

    --- Performs operations with the inverse mask and draw function.
    -- @param maskFn: Function for drawing the mask.
    -- @param drawFn: Function for rendering in the inverse region of the mask.
    function DUtils:DrawMaskInverse(maskFn, drawFn)
        clear_stencil()
        set_stencil_enable(true)
        depth_range(0, 1)

            -- Customising the stencil for the mask.
            SetupStencil(1)
            -- Drawing the mask.
            maskFn()

        -- Set parameters for drawing outside the mask.
        set_stencil_fail_operation(STENCILOPERATION_REPLACE)
        set_stencil_pass_operation(STENCILOPERATION_REPLACE)
        set_stencilZ_fail_operation(STENCILOPERATION_ZERO)
        set_stencil_compare_function(STENCILCOMPARISONFUNCTION_EQUAL)
        set_stencil_reference_value(0)

            -- We perform drawing in the inverse region of the mask.
            drawFn()

        depth_range(0, 1)
        set_stencil_enable(false)
        -- Clearing the stencil.
        clear_stencil()
    end
end

do
    -- Cache for calculating cross-section sizes (to avoid repeated calculations)
    local gradientMatR = _material('gui/gradient')
    local gradientMatU = _material('gui/gradient_up') 
    local gradientMatD = _material('gui/gradient_down')

    -- Cache for calculating section sizes (avoiding repeated calculations)
    local sectionSizeCache = { }

    --- Draws a multi-color gradient with rounded corners
    -- @param x (number): X coordinate of the upper-left corner
    -- @param y (number): Y is the coordinate of the upper-left corner  
    -- @param w (number): Gradient width (must be > 0)
    -- @param h (number): Gradient height (must be > 0)
    -- @param direction (number): The direction of the gradient:
    --         0 = horizontal (from left to right)
    --         1 = vertical (top to bottom)
    -- @param radius (number): The radius of the rounded corners (by default 8)
    -- @param ... (Color): Gradient colors (minimum 2 colors) Odd indexes are the base colors Even indexes are the colors of the transitions
    -- @example
    --     -- Horizontal gradient with rounded corners
    --     DUtils:DrawGradientBox(0, 0, 200, 100, 0, 8, _unpack{ Color(30, 144, 255), Color(255, 140, 0) })
    --    
    --     -- Vertical gradient with strongly rounded corners
    --     DUtils:DrawGradientBox(0, 0, 200, 100, 1, 16, _unpack{ Color(255, 0, 0), Color(0, 255, 0), Color(0, 0, 255) })
    -- 
    -- @note For optimal performance, use an even number of colors.
    -- @since 2.1
    function DUtils:DrawGradientBox(direction, x, y, w, h, radius, ...)
        local colors = {...}
        local colorCount = #colors
        
        -- If there are less than 2 colors, we use the default colors (blue-orange)
        if (colorCount < 2) then
            colors = { _Color(30, 144, 255, 255), _Color(255, 140, 0, 255) }
            colorCount = 2
        end
        
        -- Default radius value
        radius = radius or 8
        
        -- Determining the orientation of the gradient
        local horizontal = direction ~= 1
        local dimension = horizontal and w or h
        
        -- Cached calculation of the section size
        local cacheKey = colorCount .. '_' .. dimension
        local secSize = sectionSizeCache[cacheKey]
        if (not secSize) then
            secSize = _ceil(dimension / _ceil(colorCount * 0.5))
            sectionSizeCache[cacheKey] = secSize
        end
        
        -- Processing only odd indexes (base colors)
        local currentPos = (horizontal and x or y) - secSize
        local colorIndex = 1
        
        while colorIndex <= colorCount do
            currentPos = currentPos + secSize
            local color = colors[colorIndex]
            
            -- Draw a rounded rectangle instead of the usual one
            if horizontal then
                _RoundedBox(radius, currentPos, y, secSize, h, color)
            else
                _RoundedBox(radius, x, currentPos, w, secSize, color)
            end
            
            colorIndex = colorIndex + 2 -- Moving on to the next odd index
        end
        
        -- We process only even indexes (transition colors)
        currentPos = (horizontal and x or y) - secSize
        colorIndex = 2
        
        while colorIndex <= colorCount do
            currentPos = currentPos + secSize
            local color = colors[colorIndex]
            
            draw_color(color.r, color.g, color.b, color.a)
            
            -- The first gradient transition
            set_material(horizontal and gradientMatR or gradientMatU)
            
            if horizontal then
                draw_textured_rect_uv(currentPos, y, secSize, h, 1, 0, 0, 1)
            else
                draw_textured_rect(x, currentPos, w, secSize)
            end
            
            -- The second gradient transition (if there is a next color)
            if colors[colorIndex + 1] then
                set_material(horizontal and gradientMatR or gradientMatD)
                
                if horizontal then
                    draw_textured_rect(currentPos + secSize, y, secSize, h)
                else
                    draw_textured_rect(x, currentPos + secSize, w, secSize)
                end
            end
            
            colorIndex = colorIndex + 2 -- Goes to the next even index.
        end
    end

    -- @param x (nember): The X integer coordinate.
    -- @param y (nember): The Y integer coordinate.
    -- @param width (nember): The integer width of the rectangle.
    -- @param height (nember): The integer height of the rectangle.
    -- @param startU (nember): The U texture mapping of the rectangle origin.
    -- @param startV (nember): The V texture mapping of the rectangle origin.
    -- @param endU (nember): The U texture mapping of the rectangle end.
    -- @param endV (nember): The V texture mapping of the rectangle end.
    function DUtils:DrawTextureGradient(x, y, width, height, startU, startV, endU, endV, color, texture)
        color = color or DBase:Theme('secondary_dark')
        texture = texture or 'vgui/alpha-back'

        draw_texture(draw_texture_id(texture))
        draw_color(color)
        draw_textured_rect_uv(x, y, width, height, startU, startV, endU, endV)
    end

    --- Draws a gradient rectangle on the screen.
    -- @param x (number) X-axis position.
    -- @param y (number) Y-axis position.
    -- @param w (number) Width of the rectangle.
    -- @param h (number) Height of the rectangle.
    -- @param dir (string) Gradient direction ('BOTTOM', 'LEFT', 'RIGHT', 'TOP').
    -- @param colour (Color) The colour of the gradient (white by default).
    function DUtils:DrawGradient(x, y, w, h, dir, color)
        color = color or color_white -- Set default colour if not specified

        -- Define a table for comparing gradient directions and materials
        local gradientMaterials = {
            [BOTTOM] = DMaterial['grad_u'],
            [LEFT] = DMaterial['grad_l'],
            [RIGHT] = DMaterial['grad_r'],
        }

        -- Get a gradient material depending on the direction, or use the default value
        local gradient = gradientMaterials[dir] or DMaterial['grad_d']
        -- Drawing the gradient material
        self:DrawMaterial(x, y, w, h, color, gradient)
    end
end

do
    --- Draws a circle on the screen.
    -- @param sx: The X-coordinate of the centre of the circle.
    -- @param sy: The Y-coordinate of the center of the circle.
    -- @param radius: The radius of the circle.
    -- @param seg: The number of segments to draw the circle. The default value is 30.
    -- @param color: The colour of the circle. The default colour is white.
    -- @param angle: The angle of rotation of the circle in radians. The default value is 0.
    -- @return: Table with the coordinates of the vertices of the circle.
    function DUtils:DrawCircle(sx, sy, radius, seg, color, angle)
        -- Set the default colour
        color = color or color_white
        -- Set the default number of segments
        seg = seg or 30

        local cir = { }
        -- Angle in radians
        local ang = -_rad(angle or 0)
        local c = _cos(ang)
        local s = _sin(ang)

        -- Circle vertex generation
        for i = 0, 360, 360 / seg do
            local radd = _rad(i)
            local x = _cos(radd)
            local y = _sin(radd)

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
            _NoTexture()
            -- Set the colour for rendering
            draw_color(color)
            -- Drawing a circle
            draw_poly(cir)
        end

        return cir  -- Return the table with the vertices of the circle
    end

    --- Calculates the coordinates of the vertices of the circle.
    -- @param sx: The X-coordinate of the centre of the circle.
    -- @param sy: The Y-coordinate of the center of the circle.
    -- @param radius: The radius of the circle.
    -- @param seg: The number of segments to calculate the circle. The default value is 30.
    -- @param angle: The angle of rotation of the circle in radians. The default value is 0.
    -- @return: Table with the coordinates of the vertices of the circle.
    function DUtils:CalculateCircle(sx, sy, radius, seg, angle)
        -- Set the default number of segments
        seg = seg or 30
        local cir = { }
        -- Angle in radians
        local ang = -_rad(angle or 0)
        local c = _cos(ang)
        local s = _sin(ang)

        -- Circle vertex generation
        for i = 0, 360, 360 / seg do
            local radd = _rad(i)
            local x = _cos(radd)
            local y = _sin(radd)

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

        -- Return the table with the vertices of the circle
        return cir
    end

    --- Draws an arc on the screen.
    -- @param x: The X-coordinate of the arc centre.
    -- @param y: The Y-coordinate of the arc center.
    -- @param ang: Angle of arc origin in degrees.
    -- @param p: Arc length in degrees.
    -- @param rad: Radius of arc.
    -- @param color: Arc colour. The default colour is white.
    -- @param seg: The number of segments to draw the arc. The default value is 80.
    -- @source: TDLib https://github.com/Threebow/tdlib/blob/master/tdlib.lua#L39
    function DUtils:DrawArcT(x, y, ang, p, rad, color, seg)
        -- Set the default number of segments
        seg = seg or 80
        -- Set the default colour
        color = color or color_white
        -- Correcting the angle
        ang = (-ang) + 180
        local circle = { }

        -- Add the starting point of the arc
        DTable:Add(circle, {
            x = x,
            y = y
        })

        -- Arc point generation
        for i = 0, seg do
            local a = _rad((i / seg) * -p + ang)
            DTable:Add(circle, {
                x = x + _sin(a) * rad,
                y = y + _cos(a) * rad
            })
        end

        -- Set the colour and disable the texture for rendering
        _NoTexture()
        -- Set the colour for rendering
        draw_color(color)
        -- Drawing the arc
        draw_poly(circle)
    end

    --- Draws a wedge of a circle, used for the forward FOV indicator.
    -- @param x (number): The x-coordinate of the center of the wedge.
    -- @param y (number): The y-coordinate of the center of the wedge.
    -- @param radius (number): The radius of the wedge.
    -- @param angle (number): The angle of the wedge in degrees.
    -- @param direction (number): The direction of the wedge in radians.
    -- @param res (number): The resolution or number of segments to create the wedge.
    -- @return (table): A table containing the points that define the wedge.
    function DUtils:DrawWedge(x, y, radius, angle, direction, res)
        local points = { }
        DTable:Add(points, { x = x, y = y }) -- Add the center point

        local processedRes = _ceil(angle * res)  -- Calculate the number of segments

        for i = 0, processedRes do
            -- Calculate the current angle in radians
            local currentAngle = _rad(i * (angle / processedRes) + direction)
            -- Calculate the current point's coordinates
            local curX = x + _cos(currentAngle) * radius
            local curY = y + _sin(currentAngle) * radius
            DTable:Add(points, {
                x = curX,
                y = curY
            })  -- Add the calculated point to the table
        end

        return points -- Return the table of points
    end

    --- Draws a masked border shape at a specified position.
    -- @param xpos (number): The x-coordinate for the border.
    -- @param ypos (number): The y-coordinate for the border.
    -- @param color (Color): The color of the border (optional).
    function DUtils:MaskBorder(xpos, ypos, color)
        color = color or color_white

        local mask = {
            { x = xpos,  y = ypos },
            { x = xpos + 5, y = ypos + 10 },
            { x = xpos - 10, y = ypos + 45 },
            { x = xpos - 20, y = ypos + 50 },
        }
        draw_color(color)
        _NoTexture()
        draw_poly(mask)
    end
end

do
    local Icon, size2, ang
    -- Load the material for the icon
    DBase:GetMaterial('CiiJ0Kg', function(mat)
        Icon = mat
    end)

    --- Draws a loading icon at the specified position with rotation.
    -- @param x (number): The x-coordinate for the loading icon.
    -- @param y (number): The y-coordinate for the loading icon.
    -- @param size (number): The size of the loading icon.
    -- @param speed (number): The speed of the rotation (optional).
    -- @param col (Color): The color of the loading icon (optional).
    -- @param center (boolean): If true, centers the icon (optional).
    -- @param earse (boolean): If true, applies easing to the rotation (optional).
    function DUtils:Loading(x, y, size, speed, col, center, earse)
        -- if (loading:GetMaterial() == nil) then return end -- Ensure material is loaded
        col = col or color_white -- Default color
        speed = speed or 100 -- Default speed
        size2 = center and 0 or size * 0.5 -- Calculate offset based on centering

        -- Calculate the angle for rotation
        if earse then
            ang = _EaseInOut(((-_CurTime() * speed) % 360) / 360, 0.5, 0.5) * 360
        else
            ang = -_CurTime() % 360 * speed
        end

        -- Draw the loading icon
        draw_color(col.r, col.g, col.b, col.a)
        set_material(Icon)
        draw_textured_rect_rotated(x + size2, y + size2, size, size, ang)
    end

    --- Checks if a string is a valid URL.
    -- @param str (string): The string to check.
    -- @return (boolean): Returns true if the string is a valid URL, false otherwise.
    function DBase:IsURL(str)
        return str:find('https?://[%w-_%.%?%.:/%+=&]+') and true or false
    end
end

do
    --- Manipulates the given color by adjusting its hue, saturation, and value.
    -- @param color (Color): The original color to manipulate.
    -- @param deltaH (number): The change in hue (degrees, 0-360).
    -- @param deltaS (number): The change in saturation (0 to 1).
    -- @param deltaV (number): The change in value (0 to 1).
    -- @return (Color): The new color after manipulation.
    function DUtils:ManipulateColor(color, deltaH, deltaS, deltaV)
        -- Convert the original color to HSV
        local h, s, v = _ColorToHSV(color)
        -- Adjust the hue, saturation, and value while clamping the results to valid ranges
        local newH = _Clamp(h + deltaH, 0, 360) -- Clamp hue to [0, 360]
        local newS = _Clamp(s + deltaS, 0, 1) -- Clamp saturation to [0, 1]
        local newV = _Clamp(v + deltaV, 0, 1) -- Clamp value to [0, 1]
        -- Convert back to color from the manipulated HSV values and return
        return _HSVToColor(newH, newS, newV)
    end

    -- function DUtils:ManipulateColor(color, deltaH, deltaS, deltaV)
    --     local h, s, v = _ColorToHSV(color)
    --     return _HSVToColor(clamp(h + deltaH, 0, 360), clamp(s + deltaS, 0, 1), clamp(v + deltaV, 0, 1))
    -- end

    --- Adjusts the color values to improve visibility and returns a Color object.
    -- This function modifies the RGB values if they are below a certain threshold 
    -- to ensure they are rendered correctly in the GMod environment.
    -- @param r (number): The red component of the color (0-255).
    -- @param g (number): The green component of the color (0-255).
    -- @param b (number): The blue component of the color (0-255).
    -- @param a (number): The alpha (transparency) component of the color (0-255).
    -- @return (Color): A Color object with the adjusted values.
    function DUtils:UiColor(r, g, b, a)
        r = r < 90 and (0.916 * r + 7.8252) or r
        g = g < 90 and (0.916 * g + 7.8252) or g
        b = b < 90 and (0.916 * b + 7.8252) or b
        return _Color(r, g, b, a)
    end

    --- Linear interpolation between two colours.
    -- @param frac (number) A value from 0 to 1 specifying the degree of interpolation.
    -- @param from (Color) Starting colour.
    -- @param to (Color) The final colour.
    -- @return (Color) The resulting colour after interpolation.
    function DUtils:LerpColor(frac, from, to)
        -- Check that the frac is between 0 and 1
        frac = clamp(frac, 0, 1)

        -- Perform linear interpolation for each colour component
        local r = _Lerp(frac, from.r, to.r)
        local g = _Lerp(frac, from.g, to.g)
        local b = _Lerp(frac, from.b, to.b)
        local a = _Lerp(frac, from.a, to.a)
        return self:UiColor(r, g, b, a)
    end

    -- @source   Link: https://pastebin.pl/view/1f4f3e55
    local colorCorrection = {
        [0] = 0, 5, 8, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
        22, -- lost 15
        23, 24, 25, 26, 27, 28,
        28, -- lost 22
        29, 30, 31, 32, 33, 34, 35,
        35, -- lost 30
        36, 37, 38, 39, 40, 41, 42,
        42, -- lost 38
        43, 44, 45, 46, 47, 48, 49, 50, 51,
        51, -- lost 48
        52, 53, 54, 55, 56, 57, 58, 59, 60,
        60, -- lost 58
        61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
        73, -- lost 72
        74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88,
        88, -- lost 88
        89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109,
        109, -- lost 110
        111,
        111, -- lost 112
        113,
        113, -- lost 114
        114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132,
        133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151,
        152, 153, 154, 155, 156, 157,
        157, -- lost 159
        158, 159, 160, 162, 163, 164, 165,
        165, -- lost 167
        167, 168,
        168, -- lost 170
        170,
        170, -- lost 172
        172,
        172, -- lost 174
        174,
        174, -- lost 176
        176, 177,
        177, -- lost 179
        178, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197,
        198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216,
        217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 236, 237,
        237, -- lost 238
        238, 239, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255
    }
     
    --- Corrects RGB values using a predefined color correction table.
    -- This function ensures that the color values are within a valid range and 
    -- applies a correction based on the colorCorrection table to enhance rendering.
    -- @param r (number): The red component of the color (0-255).
    -- @param g (number): The green component of the color (0-255).
    -- @param b (number): The blue component of the color (0-255).
    -- @param a (number): The alpha (transparency) component of the color (0-255).
    -- @return (Color): A Color object with the corrected values.
    function DUtils:ColorCorrected(r, g, b, a)
        r = r or 0
        g = g or 0
        b = b or 0
        a = a or 255
        return self:UiColor(colorCorrection[_Clamp(_floor(_tonumber(r)), 0, 255)], colorCorrection[_Clamp(_floor(_tonumber(g)), 0, 255)], colorCorrection[_Clamp(_floor(_tonumber(b)), 0, 255)], _Clamp(_floor(_tonumber(a)), 0, 255))
    end

    --- Converts a hexadecimal colour string to a Color object.
    -- Returns `fallback` (or white) when the hex value is absent or too short
    -- to prevent nil-arithmetic crashes inside UiColor.
    -- @param hex (string): Hex colour, with or without leading '#' (e.g. '#754fd6', 'e07e22')
    -- @param alpha (number|nil): Alpha channel (optional, default 255)
    -- @param fallback (Color|nil): Returned when hex is nil or malformed (optional, default white)
    -- @return Color
    function DUtils:HexColor(hex, alpha, fallback)
        hex = (hex or ''):gsub('#', '')
        if (#hex < 6) then
            return fallback or _Color(255, 255, 255, alpha or 255)
        end
        return self:UiColor(_tonumber('0x' .. hex:sub(1, 2)) or 0, _tonumber('0x' .. hex:sub(3, 4)) or 0, _tonumber('0x' .. hex:sub(5, 6)) or 0, alpha or 255)
    end

    --- Converts a Color object to a lowercase hex string (#rrggbb).
    -- @param c (Color): The colour to convert.
    -- @param fallback (string|nil): Returned when c is nil (optional, default '#ffffff')
    -- @return string: e.g. '#e07e22'
    function DUtils:ColorToHex(c, fallback)
        if (not c) then
            return fallback or '#ffffff' 
        end
        return _format('#%02x%02x%02x', c.r or 0, c.g or 0, c.b or 0)
    end

    --- Converts RGB values to decimal representation
    -- @param r (number): Red component (0-255)
    -- @param g (number): Green component (0-255)
    -- @param b (number): Blue component (0-255)
    -- @return number: Decimal representation of colour
    -- Example:
    --      local colorDecimal = base.ColorDecimal(21, 21, 21)  -- Get the decimal value of the colour
    --      local material = CreateMaterial('my_material', 'UnlitGeneric', {
    --          ['$basetexture'] = 'white',
    --          ['$color'] = colorDecimal -- Use the decimal value of the colour
    --      })
    function DUtils:ColorDeciminal(r, g, b)
        r = _bitBand(_bitLshift(r, 16), 0xFF0000)
        g = _bitBand(_bitLshift(g, 8), 0x00FF00)
        b = _bitBand(b, 0x0000FF)
        return _bitBor(_bitBor(r, g), b)
    end

    --- Converts HSL to RGB
    -- @param h (number): Colour tone (0-360)
    -- @param s (number): Saturation (0-100)
    -- @param l (number): Brightness (0-100)
    -- @return number, number, number: RGB values (0-255)
    function DUtils:HSLtoRGB(h, s, l)
        local r, g, b

        if (s == 0) then
            r, g, b = l, l, l -- achromatic
        else
            local function hue2rgb(p, q, t)
                if (t < 0) then
                    t = t + 1
                end

                if (t > 1) then
                    t = 
                    t - 1
                end
                if (t < 1 / 6) then
                    return p + (q - p) * 6 * t
                elseif (t < 1 / 2) then
                    return q
                elseif (t < 2 / 3) then
                    return p + (q - p) * (2/3 - t) * 6
                else 
                    return p
                end
            end

            local q = l < 0.5 and l * (1 + s) or l + s - l * s
            local p = 2 * l - q
            r = hue2rgb(p, q, h / 360 + 1/3)
            g = hue2rgb(p, q, h / 360)
            b = hue2rgb(p, q, h / 360 - 1/3)
        end
        return _floor(r * 255), _floor(g * 255), _floor(b * 255)
    end

    --- Converts RGB to HSL
    -- @param r (number): Red component (0-255)
    -- @param g (number): Green component (0-255)
    -- @param b (number): Blue component (0-255)
    -- @return number, number, number: HSL values (h: 0-360, s: 0-100, l: 0-100)
    function DUtils:RGBtoHSL(r, g, b)
        r = r / 255
        g = g / 255
        b = b / 255

        local max = _max(r, g, b)
        local min = _min(r, g, b)
        local h, s, l = 0, 0, (max + min) / 2

        if (max == min) then
            h = 0 -- achromatic
        else
            local d = max - min
            s = l > 0.5 and d / (2 - max - min) or d / (max + min)
            if (max == r) then
                h = (g - b) / d + (g < b and 6 or 0)
            elseif (max == g) then
                h = (b - r) / d + 2
            elseif (max == b) then
                h = (r - g) / d + 4
            end
            h = h / 6
        end
        return _floor(h * 360), _floor(s * 100), _floor(l * 100)
    end

    --- Converts HSV to RGB
    -- @param h (number): Colour tone (0-360)
    -- @param s (number): Saturation (0-1)
    -- @param v (number): Value (brightness) (0-1)
    -- @return number, number, number: RGB values (0-255)
    function DUtils:HSVtoRGB(h, s, v)
        local r, g, b
        local i = _floor(h / 60) % 6
        local f = h / 60 - _floor(h / 60)
        local p = v * (1 - s)
        local q = v * (1 - f * s)
        local t = v * (1 - (1 - f) * s)

        if (i == 0) then
            r, g, b = v, t, p
        elseif (i == 1) then
            r, g, b = q, v, p
        elseif (i == 2) then
            r, g, b = p, v, t
        elseif (i == 3) then
            r, g, b = p, q, v
        elseif (i == 4) then
            r, g, b = t, p, v
        elseif (i == 5) then
            r, g, b = v, p, q
        end
        return _floor(r * 255), _floor(g * 255), _floor(b * 255)
    end

    --- Converts CMYK to RGB
    -- @param c (number): Percentage of cyan (0-1)
    -- @param m (number): Percentage of magenta (0-1)
    -- @param y (number): Percent yellow (0-1)
    -- @param k (number): Percentage of black (0-1)
    -- @return number, number, number: RGB values (0-255)
    function DUtils:CMYKtoRGB(c, m, y, k)
        local r = 255 * (1 - c) * (1 - k)
        local g = 255 * (1 - m) * (1 - k)
        local b = 255 * (1 - y) * (1 - k)
        return r, g, b
    end

    --- Converts RGB to CMYK
    -- @param r (number): Red component (0-255)
    -- @param g (number): Green component (0-255)
    -- @param b (number): Blue component (0-255)
    -- @return number, number, number, number, number: CMYK values (c: 0-100, m: 0-100, y: 0-100, k: 0-100)
    function DUtils:RGBtoCMYK(r, g, b)
        local c = 1 - (r / 255)
        local m = 1 - (g / 255)
        local y = 1 - (b / 255)
        local k = _min(c, _min(m, y))
        
        if (k < 1) then
            c = (c - k) / (1 - k)
            m = (m - k) / (1 - k)
            y = (y - k) / (1 - k)
        else
            c, m, y = 0, 0, 0
        end

        return _floor(c * 100), _floor(m * 100), _floor(y * 100), _floor(k * 100)
    end

    --- Parses colour values from a string depending on the specified format.
    -- @param input (string): A string containing comma-separated colour values.
    -- @param type (string): The type of format to use for parsing. Possible values are 'CMYK', 'HSV', 'HSL', 'HEX', 'RGB'.
    -- @return number, number, number, number, number, number:
    --         Returns the appropriate colour components.
    --         For HEX, returns (r, g, b, a), where a is 255 (full opacity).
    --         For RGB, returns (r, g, b, a) with a = 255 by default.
    --         If the format is not recognised, returns (nil, nil, nil, nil, nil).
    function DUtils:ParseColor(input, type)
        if (type == 'CMYK') then
            local c, m, y, k = input:match('(%d+),%s*(%d+),%s*(%d+),%s*(%d+)')
            return _tonumber(c), _tonumber(m), _tonumber(y), _tonumber(k)
        elseif (type == 'HSV') then
            local h, s, v = input:match('(%d+),%s*(%d+),%s*(%d+)')
            return _tonumber(h), _tonumber(s), _tonumber(v)
        elseif (type == 'HSL') then
            local h, s, l = input:match('(%d+),%s*(%d+),%s*(%d+)')
            return _tonumber(h), _tonumber(s), _tonumber(l)
        elseif (type == 'HEX') then
            if input:match('^#?([0-9A-Fa-f]{6})$') then
                local hex = input:gsub('#', '')
                local r = _tonumber(hex:sub(1, 2), 16)
                local g = _tonumber(hex:sub(3, 4), 16)
                local b = _tonumber(hex:sub(5, 6), 16)
                return r, g, b, 255 -- Full opacity by default
            end
            return nil, nil, nil, nil
        elseif (type == 'RGB') then
            -- Removing extra spaces and separating values
            input = input:gsub('^%s*(.-)%s*, ', '%1') -- Removing spaces at the beginning and end
            input = input:gsub('%s*,%s*', ',') -- Removing spaces around a comma
            input = input:gsub('%s+', '') -- Removing extra spaces

            -- Checking for numbers and commas only
            if (not input:match('^[%d,]*$')) then
                return nil, nil, nil, nil
            end

            -- Separation of values
            local values = { }
            for value in _gmatch(input, '([^,]+)') do
                DTable:Add(values, value)
            end

            -- Limiting the number of values to 4 (r, g, b, a)
            if (#values > 4) then
                return nil, nil, nil, nil
            end

            -- Convert values to numbers and replace empty values with 0
            local r, g, b, a = 0, 0, 0, 255 -- Default values (a = 255 for full opacity)
            for i = 1, #values do
                if (values[i] and values[i] ~= '') then
                    local num = _tonumber(values[i])
                    if num then
                        if (num < 0 or num > 255) then
                            return nil, nil, nil, nil
                        end

                        if i == 1 then 
                            r = num
                        elseif (i == 2) then
                            g = num
                        elseif (i == 3) then
                            b = num
                        elseif (i == 4) then
                            a = num
                        end
                    else
                        return nil, nil, nil, nil
                    end
                end
            end
            -- Return parsed RGB values
            return r, g, b, a
        end
        return nil, nil, nil, nil -- Return nil if the type is not recognised
    end
end

do
    --- Draws the arc.
    -- @param cx: X coordinate of the arc centre.
    -- @param cy: Y coordinate of the arc centre.
    -- @param radius: The radius of the arc.
    -- @param thickness: Arc thickness.
    -- @param startang: Start angle in degrees.
    -- @param endang: End angle in degrees.
    -- @param roughness: The level of detail of the arc.
    -- @param colour: Arc colour.
    function DUtils:DrawArc(cx, cy, radius, thickness, startang, endang, roughness, color)
        draw_color(color or color_white)
        self:SurfaceDrawArc(self:PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness))
    end

    --- Draws a pre-prepared arc.
    -- @param arc: A table of points representing the arc.
    function DUtils:SurfaceDrawArc(arc)
        _NoTexture()
        for k, v in _ipairs(arc) do
            draw_poly(v)
        end
    end

    --- Prepares the points for the arc.
    -- @param cx: X coordinate of the arc centre.
    -- @param cy: Y coordinate of the arc centre.
    -- @param radius: Arc radius.
    -- @param thickness: Arc thickness.
    -- @param startang: Start angle in degrees.
    -- @param endang: End angle in degrees.
    -- @param roughness: The level of detail of the arc.
    -- @return: A table containing the triangles to draw the arc.
    function DUtils:PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness)
        local triarc = { }
        -- Setting the minimum detail
        local step = _max(roughness or 1, 1)
        startang = startang or 0
        endang = endang or 0

        -- Determining the direction of corner traversal
        if (startang > endang) then step = -step end

        -- Points of the inner arc
        local inner = { }
        local r = radius - thickness

        -- Creating the points of the inner arc
        for deg = startang, endang, step do
            local rad = _rad(deg)
            local ox, oy = cx + (_cos(rad) * r), cy + (-_sin(rad) * r)
            DTable:Add(inner, { x = ox, y = oy, u = (ox - cx) / radius + 0.5, v = (oy - cy) / radius + 0.5 })
        end

        -- Points of the outer arc
        local outer = { }

        -- Creating external arc points
        for deg = startang, endang, step do
            local rad = _rad(deg)
            local ox, oy = cx + (_cos(rad) * radius), cy + (-_sin(rad) * radius)
            DTable:Add(outer, { x = ox, y = oy, u = (ox - cx) / radius + 0.5, v = (oy - cy) / radius + 0.5 })
        end

        -- Point Triangulation
        for tri = 1, #inner * 2 do
            local p1 = outer[_floor(tri / 2) + 1]
            local p3 = inner[_floor((tri + 1) / 2) + 1]
            local p2

            if (tri % 2 == 0) then
                p2 = outer[_floor((tri + 1) / 2)]
            else
                p2 = inner[_floor((tri + 1) / 2)]
            end

            DTable:Add(triarc, { p1, p2, p3 })
        end

        return triarc
    end
end

do
    -- Crop text if it exceeds the specified width
    -- @param maxWidth: The maximum width for the text
    -- @param text: Source text to be cropped
    -- @param font: The font used to calculate the text size
    -- @return: Trimmed text if it exceeds the specified width
    function DUtils:TruncatedText(maxWidth, text, font)
        -- Set default values
        text = text or 'a'
        font = font or 'danlib_font_18'

        -- Get the size of the dots
        local dots = '...'
        local dotsSize = self:TextSize(dots, font).w

        -- If the text fits within the maxWidth, return it as is
        if (self:TextSize(text, font).w <= maxWidth) then
            return text
        end

        -- Initialize variables for trimming
        local trimmedText = ''
        local currentWidth = 0

        -- Iterate through each character in the text
        for i = 1, #text do
            local char = text:sub(i, i)
            local charWidth = self:TextSize(char, font).w

            -- Check if adding this character would exceed the maxWidth
            if (currentWidth + charWidth + dotsSize > maxWidth) then
                break
            end

            -- Add the character to the trimmed text
            trimmedText = trimmedText .. char
            currentWidth = currentWidth + charWidth
        end

        -- Add dots to indicate trimming
        return trimmedText .. dots
    end

    DanLib.ScrollingText = { }

    --- Draws scrolling text on the screen.
    -- @param scr: The unique identifier for the scrolling text. If nil, a new scrolling text entry is created.
    -- @param text: The text to be scrolled across the screen.
    -- @param font: The font used to render the text.
    -- @param x: The x-coordinate for the text position.
    -- @param y: The y-coordinate for the text position.
    -- @param color: The color of the text.
    -- @param ax: The horizontal alignment of the text (default is 0).
    -- @param ay: The vertical alignment of the text (default is 0).
    -- @return: The unique identifier for the scrolling text, or -1 if the scrolling text has completed.
    --
    -- Example of using the DrawScrollingText function:
    --  local scrID = DUtils:DrawScrollingText(nil, 'Hello, World!', 'danlib_font_20', 100, 200, Color(255, 255, 255), 0, 0)
    -- 
    --  local function DrawScrollingTextExample()
    --      if scrID then
    --          scrID = DUtils:DrawScrollingText(scrID, 'Hello, World!', 'danlib_font_20', 100, 200, Color(255, 255, 255), 0, 0)
    --      end
    --  end

    -- DanLib.Hook:Add('HUDPaint', 'DrawScrollingTextExample', DrawScrollingTextExample)
    function DUtils:DrawScrollingText(scr, text, font, x, y, color, ax, ay)
        ax = ax or 0
        ay = ay or 0

        -- Create a new scrolling text entry if none exists
        if (not scr) then
            scr = #DanLib.ScrollingText + 1
            DanLib.ScrollingText[scr] = {
                ['text'] = '',
                ['count'] = 0,
                ['next'] = _SysTime()
            }
            return scr
        end

        -- Validate the scrolling text entry
        if (not DanLib.ScrollingText[scr]) then
            return
        end

        local nowText = DanLib.ScrollingText[scr]['text']
        local w, h = self:GetTextSize(nowText, font)

        -- Draw the current text
        _SimpleText(nowText, font, x, y, color, ax, ay)

        -- Update the text if the time has come to scroll the next character
        if (DanLib.ScrollingText[scr].next <= _SysTime() and DanLib.ScrollingText[scr]['count'] < #text) then
            DanLib.ScrollingText[scr].next = _SysTime() + 0.05
            DanLib.ScrollingText[scr]['text'] = DanLib.ScrollingText[scr]['text'] .. text:sub(DanLib.ScrollingText[scr]['count'] + 1, DanLib.ScrollingText[scr]['count'] + 1)
            DanLib.ScrollingText[scr]['count'] = DanLib.ScrollingText[scr]['count'] + 1
        end

        -- Cleanup if the text has finished scrolling
        if (DanLib.ScrollingText[scr]['count'] >= #text) then
            DanLib.ScrollingText[scr] = nil
            return -1
        end

        return scr
    end
end

do
    /***
     * Credits: 
     *      https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/draw.lua
     *      https://gist.github.com/MysteryPancake/e8d367988ef05e59843f669566a9a59f
     */

    -- @type Material
    local MaskMaterial = CreateMaterial('!bluemask', 'UnlitGeneric', {
        ['$translucent'] = 1,
        ['$vertexalpha'] = 1,
        ['$alpha'] = 1,
    })

    -- @type Color
    local whiteColor = color_white
    local renderTarget

    --- Draws a rounded mask.
    -- @param cornerRadius: The radius of the rounded corners.
    -- @param x: X coordinate of the top left corner.
    -- @param y: Y coordinate of the top left corner.
    -- @param w: Width of the mask.
    -- @param h: Height of the mask.
    -- @param draw_func: Function to draw the contents of the mask.
    -- @param roundTopLeft: Rounding of the top left corner.
    -- @param roundTopRight: Round the top right corner.
    -- @param roundBottomLeft: Rounding of the bottom left corner.
    -- @param roundBottomRight: Rounding of the bottom right corner.
    local function drawRoundedMask(cornerRadius, x, y, w, h, draw_func, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
        if (not renderTarget) then
            renderTarget = getRenderTargetEx('DDI_ROUNDEDBOX', ScrW(), ScrH(), RT_SIZE_FULL_FRAME_BUFFER, MATERIAL_RT_DEPTH_NONE, 2, CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_RGBA8888)
        end

        pushRenderTarget(renderTarget)
        overrideAlphaWriteEnable(true, true)
        rclear(0, 0, 0, 0)

        draw_func()

        overrideBlendFunc(true, BLEND_ZERO, BLEND_SRC_ALPHA, BLEND_DST_ALPHA, BLEND_ZERO)
        _RoundedBoxEx(cornerRadius, x, y, w, h, whiteColor, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
        overrideBlendFunc(false)
        overrideAlphaWriteEnable(false)
        popRenderTarget()

        MaskMaterial:SetTexture('$basetexture', renderTarget)

        _NoTexture()
        draw_color(255, 255, 255, 255)
        set_material(MaskMaterial)
        rmaterial(MaskMaterial)
        drawScreenQuad()
    end

    --- Draws a rounded mask with equal corners.
    -- @param cornerRadius: The radius of the rounded corners.
    -- @param x: X coordinate of the top left corner.
    -- @param y: Y coordinate of the top left corner.
    -- @param w: Width of the mask.
    -- @param h: Height of the mask.
    -- @param dFunc: Function to draw the contents of the mask.
    function DUtils:DrawRoundedMask(cornerRadius, x, y, w, h, dFunc)
        drawRoundedMask(cornerRadius, x, y, w, h, dFunc, true, true, true, true)
    end

    --- Draws a rounded mask with custom corners.
    -- @param cornerRadius: The radius of the rounded corners.
    -- @param x: X coordinate of the top left corner.
    -- @param y: Y coordinate of the top left corner.
    -- @param w: Width of the mask.
    -- @param h: Height of the mask.
    -- @param dFunc: Function to draw the contents of the mask.
    -- @param roundTopLeft: Rounding of the top left corner.
    -- @param roundTopRight: Round the top right corner.
    -- @param roundBottomLeft: Rounding of the bottom left corner.
    -- @param roundBottomRight: Rounding of the bottom right corner.
    function DUtils:DrawRoundedExMask(cornerRadius, x, y, w, h, dFunc, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
        drawRoundedMask(cornerRadius, x, y, w, h, dFunc, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
    end
end

do
    -- Draws an outlined rounded rectangle.
    function DUtils:DrawOutlinedRoundedRect(r, x, y, w, h, thickness, color)
        
    end
end

-- Function for drawing a square with an icon
function DUtils:DrawSquareWithIcon(x, y, color, size, iconMaterial, roundness)
    x = x or 0
    y = y or 0
    color = color or self:UiColor(0, 0, 0, 100)
    size = size or 24
    iconMaterial = iconMaterial or _material('error')

    if (roundness && roundness > 0) then
        _RoundedBox(roundness, x, y, size, size, color)
        -- self:DrawOutlinedRoundedRect(roundness, x, y, size, size, 4, base:Theme('frame'))
    else
        -- If no radius is specified, just draw a rectangle
        self:DrawRect(x, y, size, size, color)
    end

    -- Calculating the size of the icon
    local iconSize = size * 0.5 -- The size of the icon will be half the size of the square
    local iconX = x + (size - iconSize) / 2 -- Centre the icon at X
    local iconY = y + (size - iconSize) / 2 -- Centre the icon in Y

    if _isstring(iconMaterial) then
        self:DrawIcon(iconX, iconY, iconSize, iconSize, iconMaterial, DBase:Theme('mat'))
    else
        self:DrawMaterial(iconX, iconY, iconSize, iconSize, DBase:Theme('mat'), iconMaterial)
    end
end

--- Plays a sound from the DanLib sound configuration.
-- @param soundName string: The name of the sound to play.
-- @return boolean: Returns true if the sound was played successfully, false otherwise.
-- @throws error: If the specified sound does not exist in the configuration.
function DBase:PlaySound(soundName)
    -- Validate input
    if (_type(soundName) ~= 'string' or soundName == '') then
        _error('Invalid sound name provided. It must be a non-empty string.')
    end

    -- Check if the sound exists in the configuration
    local soundPath = DanLib.Config.Sound[soundName]
    if (not soundPath) then
        _error('Sound "' .. soundName .. '" does not exist in the sounds table.')
    end

    -- Play the sound
    surface.PlaySound(soundPath)

    return true -- Indicate successful playback
end
