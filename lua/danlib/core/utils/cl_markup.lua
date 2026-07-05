/***
 *   @addon         DanLib
 *   @component     Markup
 *   @license       MIT License
 *   @version       2.0.10
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
 *
 *	 @source 		
 *                  GitHub: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/markup.lua
 */



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DHook = DanLib.Hook
local DTable = DanLib.Table

-- Cache frequently used functions and constants
local markupIndex = {}
markupIndex.__index = markupIndex

-- Cached string functions for performance
local string = string
local len = string.len
local match = string.match
local gmatch = string.gmatch
local _gsub = string.gsub
local find = string.find
local lower = string.lower
local sub = string.sub
local explode = string.Explode

-- Cached surface functions
local surface = surface
local textFont = surface.SetFont
local textColor = surface.SetTextColor
local drawText = surface.DrawText
local textPos = surface.SetTextPos
local textSize = surface.GetTextSize
local drawColor = surface.SetDrawColor
local drawRect = surface.DrawRect -- Added for background rendering
local drawBox = draw.RoundedBox -- Added for background rendering

-- Cached global functions
local _tostring = tostring
local _ipairs = ipairs
local _setmetatable = setmetatable
local _tonumber = tonumber
local _select = select
local _CurTime = CurTime
local _Color = Color

-- Cached math functions
local math = math
local max = math.max
local ceil = math.ceil

-- UTF-8 compatibility layer
local utf8 = utf8
local codes = utf8.codes
local char = utf8.char
local offset = utf8.offset
local force = utf8.force
local charpattern = utf8.charpattern

-- Pre-defined constants for better performance
local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM


-- Temporary information used when building text frames (reused for memory optimization)
local colour_stack = { _Color(255, 255, 255) }
local font_stack = { 'danlib_font_18' }
local bg_color_stack = { nil } -- Background color stack with default transparent background
local bg_color_pooled_stack = { false } -- Track which bg colors are pooled vs named
local blocks = {}

-- Pre-allocated Color object pool for background colors to prevent garbage collection
local bg_color_pool = {}
local bg_color_pool_size = 10 -- Maximum nesting depth for background colors
for i = 1, bg_color_pool_size do
    bg_color_pool[i] = _Color(255, 255, 255, 255)
end
local bg_color_pool_index = 0

-- Pre-allocated color objects to reduce garbage collection
local default_white = _Color(255, 255, 255)
local default_black = _Color(0, 0, 0)
local default_transparent = nil -- For transparent backgrounds

-- Optimized color map with pre-allocated Color objects
local colourmap = {
    -- Black and white
    ['black'] = _Color(0, 0, 0),
    ['white'] = _Color(255, 255, 255),

    -- Greys
    ['dkgrey'] = _Color(64, 64, 64),
    ['grey'] = _Color(128, 128, 128),
    ['ltgrey'] = _Color(192, 192, 192),

    -- Account for spelling mistakes
    ['dkgray'] = _Color(64, 64, 64),
    ['gray'] = _Color(128, 128, 128),
    ['ltgray'] = _Color(192, 192, 192),

    -- Normal colours
    ['red'] = _Color(255, 0, 0),
    ['green'] = _Color(0, 255, 0),
    ['blue'] = _Color(0, 151, 230),
    ['yellow'] = _Color(255, 255, 0),
    ['purple'] = _Color(255, 0, 255),
    ['cyan'] = _Color(0, 255, 255),
    ['turq'] = _Color(0, 255, 255),

    -- Dark variations
    ['dkred'] = _Color(128, 0, 0),
    ['dkgreen'] = _Color(0, 128, 0),
    ['dkblue'] = _Color(0, 0, 128),
    ['dkyellow'] = _Color(128, 128, 0),
    ['dkpurple'] = _Color(128, 0, 128),
    ['dkcyan'] = _Color(0, 128, 128),
    ['dkturq'] = _Color(0, 128, 128),

    -- Light variations
    ['ltred'] = _Color(255, 128, 128),
    ['ltgreen'] = _Color(128, 255, 128),
    ['ltblue'] = _Color(128, 128, 255),
    ['ltyellow'] = _Color(255, 255, 128),
    ['ltpurple'] = _Color(255, 128, 255),
    ['ltcyan'] = _Color(128, 255, 255),
    ['ltturq'] = _Color(128, 255, 255),
}

-- Cache for parsed colors to avoid repeated parsing
local color_cache = {}
-- Cache for parsed background colors to avoid repeated parsing
local bg_color_cache = {}
-- Performance optimization: track last background color to avoid redundant draw calls
local last_bg_color = nil

--- Match the colour name to the rgb value. (Optimized colour matching with caching)
-- @param color (string): color name
-- @return The corresponding colour
local function colourMatch(c)
    local lower_c = lower(c)
    local cached = color_cache[lower_c]
    if cached then
        return cached
    end
    
    local result = colourmap[lower_c]
    if result then
        color_cache[lower_c] = result
    end
    return result
end

--- Match the background colour name to the rgb value. (Optimized colour matching with caching for backgrounds)
-- @param color (string): color name for background
-- @return The corresponding background colour
local function bgColourMatch(c)
    local lower_c = lower(c)
    local cached = bg_color_cache[lower_c]
    if cached then
        return cached
    end
    
    local result = colourmap[lower_c]
    if result then
        bg_color_cache[lower_c] = result
    end
    return result
end

-- Pre-compiled patterns for better performance
local color_pattern = '(%d+),?'
local tag_pattern = '{([%a/]*:)%s*([^}]*)}'
local escape_pattern = '[&<>]'
local unescape_pattern = '&amp;|&lt;|&gt;'
local entity_pattern = '(&.-;)'
local space_pattern = ' +$'

-- escape_text entities for markup-safe conversion
local escapeEntities = { 
    ['&'] = '&amp;', 
    ['<'] = '&lt;', 
    ['>'] = '&gt;' 
}

-- Function for decoding escaped characters
local unescapeEntities = { 
    ['&amp;'] = '&', 
    ['&lt;'] = '<', 
    ['&gt;'] = '>' 
}

--- This function is used to extract tag information with support for background colors.
-- Performance optimized with Color object pooling for RGB values to prevent garbage collection.
-- @param p1 (string): tag name (supports color:, font:, bg: tags)
-- @param p2 (string): tag value (color name, font name, or background color in format 'name' or 'r,g,b[,a]')
local function extract_params(p1, p2)
    if (sub(p1, 1, 1) == '/') then
        local tag = sub(p1, 2, -1)
        if (tag == 'color:') then
            DTable:Remove(colour_stack)
        elseif (tag == 'font:') then
            DTable:Remove(font_stack)
        elseif (tag == 'bg:') then
            -- Release pooled background color object back to pool only if it was pooled
            DTable:Remove(bg_color_stack)
            local was_pooled = DTable:Remove(bg_color_pooled_stack)
            if (was_pooled and bg_color_pool_index > 0) then
                bg_color_pool_index = bg_color_pool_index - 1
            end
        end
    else
        if (p1 == 'color:') then
            local rgba = colourMatch(p2)
            if (rgba == nil) then
                rgba = _Color(255, 255, 255, 255)
                local x, n = { 'r', 'g', 'b', 'a' }, 1
                for k, v in gmatch(p2, '(%d+),?') do
                    rgba[x[n]] = _tonumber(k)
                    n = n + 1
                end
            end
            DTable:Add(colour_stack, rgba)
        elseif (p1 == 'font:') then
            DTable:Add(font_stack, _tostring(p2))
        elseif (p1 == 'bg:') then
            local bg_rgba = bgColourMatch(p2)
            if (bg_rgba == nil) then
                -- Use pooled Color object for RGB values to prevent garbage collection
                if (bg_color_pool_index < bg_color_pool_size) then
                    bg_color_pool_index = bg_color_pool_index + 1
                    bg_rgba = bg_color_pool[bg_color_pool_index]
                else
                    -- Fallback if pool is exhausted (should not happen with reasonable nesting)
                    bg_rgba = _Color(255, 255, 255, 255)
                end
                -- Parse RGB values into pooled object
                local x, n = { 'r', 'g', 'b', 'a' }, 1
                for k, v in gmatch(p2, '(%d+),?') do
                    bg_rgba[x[n]] = _tonumber(k)
                    n = n + 1
                end
                -- Set default alpha if not specified
                if (n <= 4) then
                    bg_rgba.a = 255
                end
                DTable:Add(bg_color_stack, bg_rgba)
                DTable:Add(bg_color_pooled_stack, true) -- Mark as pooled
            else
                -- Named color from colourmap (shared reference, not pooled)
                DTable:Add(bg_color_stack, bg_rgba)
                DTable:Add(bg_color_pooled_stack, false) -- Mark as named
            end
        end
    end
end

-- Converts a string to its markup-safe equivalent
-- @param str (string): string to be escaped
-- @return (string): escaped string
function escape_text(str)
    return _gsub(_tostring(str), escape_pattern, escapeEntities)
end

-- Function to decode escaped characters
-- @param str (string): string to decode
-- @return (string): decoded string
function unescape_text(str)
    return _gsub(_tostring(str), unescape_pattern, unescapeEntities)
end

-- This function puts data into the "blocks" table depending on whether content is a tag or text.
-- @param content (string): text or tag to process
local function process_content(content)
    if (not content or content == '') then
        return
    end

    if (sub(content, 1, 1) == '{') then
        -- Process tags with error handling
        local success, err = pcall(_gsub, content, tag_pattern, extract_params)
        if (not success) then
            print('Error during tag processing: ' .. _tostring(err))
        end
    else
        -- Create text block efficiently with background color support
        -- Store immutable background color values to prevent pooling mutation bugs
        local bg_color = bg_color_stack[#bg_color_stack]
        local block_count = #blocks + 1
        blocks[block_count] = {
            text = content, -- Decode text before adding unescape_text(content)
            colour = colour_stack[#colour_stack],
            font = font_stack[#font_stack],
            -- Store background color as immutable values, not object reference
            bg_r = bg_color and bg_color.r or nil,
            bg_g = bg_color and bg_color.g or nil,
            bg_b = bg_color and bg_color.b or nil,
            bg_a = bg_color and bg_color.a or nil
        }
    end
end

-- process_content for 3 parameters. Called by _gsub
-- @param p1 (string): text or tag
-- @param p2 (string): text or tag
-- @param p3 (string): text or tag
local function ProcessMatches(p1, p2, p3)
    if p1 then process_content(p1) end
    if p2 then process_content(p2) end
    if p3 then process_content(p3) end
end

-- Returns the width of the markup block
-- @return block width
function markupIndex:GetWidth()
    return self.totalWidth
end

-- Returns the maximum width of the markup block
-- @return (number): maximum block width
function markupIndex:GetMaxWidth()
    return self.maxWidth or self.totalWidth
end

-- Returns the height of the markup block
-- @return (number): block height
function markupIndex:GetHeight()
    return self.totalHeight
end

-- Returns the dimensions of the markup block
-- @return (number, number): width and height of the block
function markupIndex:Size()
    return self.totalWidth, self.totalHeight
end

--- Draws the markup text on the screen with optimized background color support
-- Performance optimized: eliminates redundant SetDrawColor calls and coalesces adjacent backgrounds
-- @param xOffset (number): X-axis offset for drawing position
-- @param yOffset (number): Y-axis offset for drawing position  
-- @param halign (number): horizontal alignment (TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT)
-- @param valign (number): vertical alignment (TEXT_ALIGN_TOP, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
-- @param alphaoverride (number): override text and background alpha value
-- @param textAlign (number): align text inside borders for individual lines
function markupIndex:Draw(xOffset, yOffset, halign, valign, alphaoverride, textAlign)
    local blocks = self.blocks
    local totalWidth = self.totalWidth
    local totalHeight = self.totalHeight
    local lineWidths = self.lineWidths
    
    -- Pre-calculate alignment offsets
    local xAlignOffset = 0
    local yAlignOffset = 0
    
    if (halign == TEXT_ALIGN_CENTER) then
        xAlignOffset = -totalWidth * 0.5
    elseif halign == TEXT_ALIGN_RIGHT then
        xAlignOffset = -totalWidth
    end
    
    if (valign == TEXT_ALIGN_CENTER) then
        yAlignOffset = -totalHeight * 0.5
    elseif (valign == TEXT_ALIGN_BOTTOM) then
        yAlignOffset = -totalHeight
    end
    
    -- Reset background color tracking for optimization
    last_bg_color = nil
    
    -- First pass: draw all backgrounds with coalescing optimization
    local i = 1
    while i <= #blocks do
        local blk = blocks[i]
        if blk.bg_r then -- Check for background using immutable values
            local y = yOffset + (blk.height - blk.thisY) + blk.offset.y + yAlignOffset
            local x = xOffset + blk.offset.x + xAlignOffset
            
            -- Handle text alignment within lines for background positioning
            if (textAlign and textAlign ~= TEXT_ALIGN_LEFT) then
                local lineWidth = lineWidths[blk.offset.y]
                if lineWidth then
                    if textAlign == TEXT_ALIGN_CENTER then
                        x = x + (totalWidth - lineWidth) * 0.5
                    elseif textAlign == TEXT_ALIGN_RIGHT then
                        x = x + (totalWidth - lineWidth)
                    end
                end
            end
            
            local bg_alpha = alphaoverride or blk.bg_a
            local width = blk.thisX
            local height = blk.thisY or blk.height or 16
            
            -- Coalesce adjacent blocks with same background color on same line
            local next_i = i + 1
            while next_i <= #blocks do
                local next_blk = blocks[next_i]
                if (next_blk.bg_r and next_blk.bg_r == blk.bg_r and next_blk.bg_g == blk.bg_g and next_blk.bg_b == blk.bg_b and next_blk.bg_a == blk.bg_a and next_blk.offset.y == blk.offset.y and next_blk.offset.x == blk.offset.x + width) then
                    width = width + next_blk.thisX
                    next_i = next_i + 1
                else
                    break
                end
            end
            
            -- Optimize: only call SetDrawColor if background color changed
            if (not last_bg_color or last_bg_color.r ~= blk.bg_r or last_bg_color.g ~= blk.bg_g or last_bg_color.b ~= blk.bg_b or last_bg_color.a ~= bg_alpha) then
                drawColor(blk.bg_r, blk.bg_g, blk.bg_b, bg_alpha)
                last_bg_color = {
                    r = blk.bg_r,
                    g = blk.bg_g, 
                    b = blk.bg_b, 
                    a = bg_alpha
                }
            end
            
            -- drawRect(x, y, width, blk.height)
            drawBox(6, x - 1, y + 1, width + 2, height - 2, _Color(blk.bg_r, blk.bg_g, blk.bg_b, bg_alpha))
            i = next_i - 1 -- Skip coalesced blocks
        end
        i = i + 1
    end
    
    -- Second pass: draw all text
    for i = 1, #blocks do
        local blk = blocks[i]
        local y = yOffset + (blk.height - blk.thisY) + blk.offset.y + yAlignOffset
        local x = xOffset + blk.offset.x + xAlignOffset
        local alpha = alphaoverride or blk.colour.a
        
        -- Handle text alignment within lines
        if (textAlign and textAlign ~= TEXT_ALIGN_LEFT) then
            local lineWidth = lineWidths[blk.offset.y]
            if lineWidth then
                if (textAlign == TEXT_ALIGN_CENTER) then
                    x = x + (totalWidth - lineWidth) * 0.5
                elseif textAlign == TEXT_ALIGN_RIGHT then
                    x = x + (totalWidth - lineWidth)
                end
            end
        end
        
        textFont(blk.font)
        textColor(blk.colour.r, blk.colour.g, blk.colour.b, alpha)
        textPos(x, y)
        drawText(blk.text)
    end
end

--- Parses the pseudo-html markup language and creates markup that can be used to display text on the screen.
-- Supports color, font, and background color tags with high-performance optimizations.
-- 
-- Supported tag formats:
--   {color:name} or {color:r,g,b[,a]} - Sets text color using named colors or RGB values
--   {font:name} - Sets font for text rendering  
--   {bg:name} or {bg:r,g,b[,a]} - Sets background color using named colors or RGB values
--   {/color:}, {/font:}, {/bg:} - Closes respective tags (supports nesting)
--
-- Performance features:
--   - Pre-allocated Color object pool for background RGB values (zero garbage collection)
--   - Background color caching for named colors (shared with text color cache)
--   - Drawing optimization with state change elimination and rectangle coalescing
--   - Stack-based color/font/background management for proper nesting
--
-- @param text (string): text to parse with markup tags
-- @param dFont (string): default font name to use if no font tag specified  
-- @param dColor (Color): default text color to use if no color tag specified
-- @param maxwidth (number): maximum width of the text for automatic line wrapping
-- @return (Markup): markup object with parsed text blocks and optimized rendering information
function markupIndex:ParseMarkup(text, dFont, dColor, maxwidth)
    text = force(escape_text(text))
    colour_stack = { dColor or _Color(255, 255, 255, 255) }
    font_stack = { dFont or 'danlib_font_18' }
    bg_color_stack = { nil } -- Reset background color stack
    bg_color_pooled_stack = { false } -- Reset background color pooled tracking
    bg_color_pool_index = 0 -- Reset background color pool for reuse
    blocks = {}

    if (not find(text, '{')) then 
        text = text .. '{nop}'
    end
    _gsub(text, '([^{}]*)([{][^}]*[}])([^{}]*)', ProcessMatches)

    local xOffset = 0
    local yOffset = 0
    local xSize = 0
    local xMax = 0
    local thisMaxY = 0
    local new_block_list = {}
    local ymaxes = {}
    local lineWidths = {}

    local lineHeight = 0
    for i, blk in _ipairs(blocks) do
        textFont(blk.font)
        blk.text = _gsub(blk.text, '(&.-;)', unescapeEntities)

        local thisY = 0
        local curString = ''
        for j, c in codes(blk.text) do
            local ch = char(c)
            if (ch == '\n') then
                if (thisY == 0) then
                    thisY = lineHeight
                    thisMaxY = lineHeight
                else
                    lineHeight = thisY
                end

                if (len(curString) > 0) then
                    local x1 = textSize(curString)
                    local new_block = {
                        text = curString,
                        font = blk.font,
                        colour = blk.colour,
                        -- Preserve background color as immutable values
                        bg_r = blk.bg_r,
                        bg_g = blk.bg_g,
                        bg_b = blk.bg_b,
                        bg_a = blk.bg_a,
                        thisY = thisY,
                        thisX = x1,
                        offset = {
                            x = xOffset,
                            y = yOffset
                        }
                    }
                    DTable:Add(new_block_list, new_block)
                    if (xOffset + x1 > xMax) then 
                        xMax = xOffset + x1
                    end
                end

                xOffset = 0
                xSize = 0
                yOffset = yOffset + thisMaxY
                thisY = 0
                curString = ''
                thisMaxY = 0
            elseif (ch == '\t') then
                if (len(curString) > 0) then
                    local x1 = textSize(curString)
                    local new_block = {
                        text = curString,
                        font = blk.font,
                        colour = blk.colour,
                        -- Preserve background color as immutable values
                        bg_r = blk.bg_r,
                        bg_g = blk.bg_g,
                        bg_b = blk.bg_b,
                        bg_a = blk.bg_a,
                        thisY = thisY,
                        thisX = x1,
                        offset = {
                            x = xOffset,
                            y = yOffset
                        }
                    }
                    DTable:Add(new_block_list, new_block)
                    if (xOffset + x1 > xMax) then
                        xMax = xOffset + x1
                    end
                end

                curString = ''
                local xOldSize = xSize
                xSize = 0
                local xOldOffset = xOffset
                xOffset = ceil((xOffset + xOldSize) / 50) * 50

                if (xOffset == xOldOffset) then
                    xOffset = xOffset + 50
                    if (maxwidth and xOffset > maxwidth) then
                        -- Needs a new line
                        if (thisY == 0) then
                            thisY = lineHeight
                            thisMaxY = lineHeight
                        else
                            lineHeight = thisY
                        end

                        xOffset = 0
                        yOffset = yOffset + thisMaxY
                        thisY = 0
                        thisMaxY = 0
                    end
                end
            else
                local x, y = textSize(ch)
                if (x == nil) then
                    return
                end

                if (maxwidth and maxwidth > x) then
                    if (xOffset + xSize + x >= maxwidth) then
                        -- need to: find the previous space in the curString
                        --      if we can't find one, take off the last character and DTable:Add as a new block, incrementing the y etc
                        local lastSpacePos = len(curString)
                        for k = 1, len(curString) do
                            local chspace = sub(curString, k, k)
                            if (chspace == ' ') then
                                lastSpacePos = k
                            end
                        end

                        local previous_block = new_block_list[#new_block_list]
                        local wrap = lastSpacePos == len(curString) and lastSpacePos > 0

                        if (previous_block and previous_block.text:match(' $') and wrap and textSize(blk.text) < maxwidth) then
                            -- If the block was preceded by a space, wrap the block onto the next line first, as we can probably fit it there
                            local trimmed, trimCharNum = previous_block.text:gsub(' +$', '')
                            if (trimCharNum > 0) then
                                previous_block.text = trimmed
                                previous_block.thisX = textSize(previous_block.text)
                            end
                        else
                            if wrap then
                                -- If the block takes up multiple lines (and has no spaces), split it up
                                local sequenceStartPos = offset(curString, 0, lastSpacePos)
                                ch = match(curString, utf8.charpattern, sequenceStartPos) .. ch
                                j = offset(curString, 1, sequenceStartPos)
                                curString = sub(curString, 1, sequenceStartPos - 1)
                            else
                                -- Otherwise, strip the trailing space and start a new line
                                ch = sub(curString, lastSpacePos + 1) .. ch
                                j = lastSpacePos + 1
                                curString = sub(curString, 1, max(lastSpacePos - 1, 0))
                            end

                            local m = 1
                            while (sub(ch, m, m) == ' ') do
                                m = m + 1
                            end
                            ch = sub(ch, m)

                            local x1, y1 = textSize(curString)
                            if (y1 > thisMaxY) then
                                thisMaxY = y1
                                ymaxes[yOffset] = thisMaxY
                                lineHeight = y1
                            end

                            local new_block = {
                                text = curString,
                                font = blk.font,
                                colour = blk.colour,
                                        -- Preserve background color as immutable values
                                bg_r = blk.bg_r,
                                bg_g = blk.bg_g,
                                bg_b = blk.bg_b,
                                bg_a = blk.bg_a,
                                thisY = thisY,
                                thisX = x1,
                                offset = {
                                    x = xOffset, 
                                    y = yOffset 
                                }
                            }
                            DTable:Add(new_block_list, new_block)

                            if (xOffset + x1 > xMax) then 
                                xMax = xOffset + x1 
                            end
                            curString = ''
                        end

                        xOffset = 0
                        xSize = 0
                        x, y = textSize(ch)
                        yOffset = yOffset + thisMaxY
                        thisY = 0
                        thisMaxY = 0
                    end
                end

                curString = curString .. ch
                thisY = y
                xSize = xSize + x

                if (y > thisMaxY) then
                    thisMaxY = y
                    ymaxes[yOffset] = thisMaxY
                    lineHeight = y
                end
            end
        end

        if (len(curString) > 0) then
            local x1 = textSize(curString)
            local new_block = {
                text = curString,
                font = blk.font,
                colour = blk.colour,
                -- Preserve background color as immutable values
                bg_r = blk.bg_r,
                bg_g = blk.bg_g,
                bg_b = blk.bg_b,
                bg_a = blk.bg_a,
                thisY = thisY,
                thisX = x1,
                offset = {
                    x = xOffset, 
                    y = yOffset
                }
            }
            DTable:Add(new_block_list, new_block)
            lineHeight = thisY

            if (xOffset + x1 > xMax) then
                xMax = xOffset + x1
            end

            xOffset = xOffset + x1
        end
        xSize = 0
    end

    local totalHeight = 0
    for i, blk in _ipairs(new_block_list) do
        blk.height = ymaxes[blk.offset.y]

        if (blk.offset.y + blk.height > totalHeight) then
            totalHeight = blk.offset.y + blk.height
        end

        lineWidths[blk.offset.y] = max(lineWidths[blk.offset.y] or 0, blk.offset.x + blk.thisX)
    end

    return _setmetatable({
        blocks = new_block_list,
        totalWidth = xMax,
        totalHeight = totalHeight,
        lineWidths = lineWidths
    }, markupIndex)
end

-- Ultra-fast markup creation function
function DUtils:CreateMarkup(text, font, color, maxwidth)
    local markup = _setmetatable({}, markupIndex)
    return markup:ParseMarkup(text, font, color, maxwidth)
end

--- Draws markup text on the screen at the specified position with the given formatting options.
-- @param text (string): The markup text to be displayed, which may include formatting tags.
-- @param font (string): The font to be used for rendering the text.
-- @param x (number): The X coordinate for the text's starting position on the screen.
-- @param y (number): The Y coordinate for the text's starting position on the screen.
-- @param color (Color): The color of the text to be displayed.
-- @param xAlign (number): The horizontal alignment of the text (e.g., left, center, right).
-- @param yAlign (number): The vertical alignment of the text (e.g., top, center, bottom).
-- @param maxwidth (number): The maximum width allowed for the text before it wraps.
-- @param textAlign (number): The alignment of the text within its allocated space.
function DUtils:DrawParseText(text, font, x, y, color, xAlign, yAlign, maxwidth, textAlign)
	x = x or 0
	y = y or 0
	xAlign = xAlign or TEXT_ALIGN_CENTER
	yAlign = yAlign or TEXT_ALIGN_CENTER
	textAlign = textAlign or TEXT_ALIGN_CENTER

    local markupObject = self:CreateMarkup(text, font, color, maxwidth)
    if markupObject then
        markupObject:Draw(x, y, xAlign, yAlign, nil, textAlign)
    end
end

-- Cache for cleared text (performance optimization)
local cleanTextCache = {}

--- Universal function for clearing text from all types of markup tags
-- @param text (string): text with possible markup tags
-- @return (string): cleared text without tags
function DUtils:CleanMarkupText(text)
    if (not text or text == '') then
        return ''
    end
    
    -- Checking the cache for optimization
    local cached = cleanTextCache[text]
    if cached then
        return cached
    end
    
    local cleanText = _tostring(text)
    
    -- Remove all types of markup tags:
    -- Color tags: {color:255,0,0}, {color: 255, 0, 0}, {/color:}
    cleanText = _gsub(cleanText, '{color:%s*%d+,%s*%d+,%s*%d+}', '')
    cleanText = _gsub(cleanText, '{/color:}', '')
    -- Font tags: {font:Arial}, {font: fontname}, {/font:}
    cleanText = _gsub(cleanText, '{font:%s*[%w_%-]+}', '')
    cleanText = _gsub(cleanText, '{/font:}', '')
    -- cleanText = _gsub(cleanText, '{[^}]*}', '') -- Universal cleanup of all other {any_characters} tags
    -- cleanText = _gsub(cleanText, '<[^>]*>', '') -- HTML-like <tag></tag> tags (if used)
    -- cleanText = _gsub(cleanText, '%s+', ' ') -- Cleanup of extra spaces
    -- cleanText = string.match(cleanText, '^%s*(.-)%s*$') or cleanText -- Trim whitespace from edges
    
    -- Save the result to the cache
    cleanTextCache[text] = cleanText
    
    return cleanText
end

--- Function to get text size without markup tags
-- @param text (string): text with possible markup tags
-- @param font (string): font for size calculation
-- @return (number, number): width and height of text
function DUtils:GetSafeTextSize(text, font)
    if (not text or text == '') then
        return 0, 0
    end
    
    local cleanText = self:CleanMarkupText(text)
    local isMultiline = find(text, '\n') ~= nil
    
    textFont(font or 'danlib_font_18')
    
    if isMultiline then
        local cleanLines = explode('\n', cleanText)
        local maxLineWidth = 0
        local lineHeight = 16
        
        if textSize then
            lineHeight = _select(2, textSize('Test'))
            
            for i, cleanLine in _ipairs(cleanLines) do
                local cleanWidth = textSize(cleanLine)
                local safeWidth = cleanWidth * 1.001 -- Minimum margin of 8% for multi-line
                
                if (safeWidth > maxLineWidth) then
                    maxLineWidth = safeWidth
                end
            end
        else
            for _, cleanLine in _ipairs(cleanLines) do
                local cleanWidth = len(cleanLine) * 8 * 1.1
                if (cleanWidth > maxLineWidth) then
                    maxLineWidth = cleanWidth
                end
            end
        end
        
        return maxLineWidth, lineHeight * #cleanLines
    else
        -- Single line text - adding significant margin
        local cleanWidth, textHeight = 0, 16
        
        if textSize then
            cleanWidth, textHeight = textSize(cleanText)
        else
            cleanWidth = len(cleanText) * 8
        end
        
        -- Minimum margin of 12% for single line
        local safeWidth = cleanWidth * 1.01
        return safeWidth, textHeight
    end
end

DHook:Add('Initialize', 'CleanTextCache_Clear', function()
    cleanTextCache = {}
end)

-- Periodic cache clearing to save memory
local lastCacheClean = 0
local function CleanTextCache_Periodic()
    local curTime = _CurTime()
    if (curTime - lastCacheClean > 300) then -- every 5 minutes
        cleanTextCache = {}
        lastCacheClean = curTime
    end
end
DHook:Add('Think', 'CleanTextCache_Periodic', CleanTextCache_Periodic)

-- An example of using text markup in a HUD.
local function testTextHUD()
	-- Example of markup text
	-- local text = 'This is a long line of text that should wrap if it exceeds the maximum width.'
	local text = 'This is a long {font: danlib_font_14}{color: 0, 255, 0}{bg:purple}line{/bg:} of text that should{/color:}{/font:} wrap if it exceeds the {bg:blue}maximum{/bg:} {color: 255, 0, 0}width{/color:}.'

	-- Call the function to display the text with the maximum width value
	DUtils:DrawParseText(text, nil, ScrW() - 10, 100, nil, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 0)
end
-- DHook:Add('HUDPaint', 'DrawParseText', testTextHUD)
