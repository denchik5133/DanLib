/***
 *   @addon         DanLib
 *   @component     Font
 *   @license       MIT License
 *   @version       2.0.0
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
local DTable = DanLib.Table
local DUtils = DanLib.Utils

local _ScrW = ScrW
local _ScrH = ScrH
local _type = type
local _IsValid = IsValid
local _pairs = pairs
local _ipairs = ipairs
local _min = math.min
local _abs = math.abs
local _len = string.len
local _floor = math.floor
local _gmatch = string.gmatch
local _Explode = string.Explode

local SH = _ScrH() / 1080
local SW = _ScrW() / 1920
local Ratio = _min(SH, SW)

-- Font information storage
local fontCache = { }
local adaptiveFonts = { }

function DBase:GetSize(number)
    return number * Ratio * (DDI.Scale or 1)
end

-- Get font information by name
function DBase:GetFontInfo(fontName)
    if (not fontCache[fontName]) then
        surface.SetFont(fontName)
        local testText = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
        local w, h = surface.GetTextSize(testText)
        local avgCharWidth = w / _len(testText)

        fontCache[fontName] = {
            name = fontName,
            height = h,
            avgCharWidth = avgCharWidth,
            testWidth = w,
            created = true
        }
    end
    return fontCache[fontName]
end

-- Get optimal font size for given constraints
function DBase:GetOptimalFontSize(text, maxWidth, maxHeight, baseFontSize, minSize, maxSize)
    baseFontSize = baseFontSize or 18
    minSize = minSize or 8
    maxSize = maxSize or 100

    local bestSize = baseFontSize
    local testSize = baseFontSize

    -- Binary search for optimal size
    local low, high = minSize, maxSize
    while low <= high do
        testSize = _floor((low + high) / 2)
        local testFont = 'danlib_adaptive_test_' .. testSize

        -- Create temporary font for testing
        local tbl = {
            font = 'Montserrat Regular',
            size = self:GetSize(testSize),
            weight = 500,
            extended = true
        }

        surface.CreateFont(testFont, tbl)
        surface.SetFont(testFont)

        local w, h = surface.GetTextSize(text)
        if (w <= maxWidth and h <= maxHeight) then
            bestSize = testSize
            low = testSize + 1
        else
            high = testSize - 1
        end
    end

    return bestSize
end

-- Create adaptive font that scales with container
function DBase:CreateAdaptiveFont(name, baseSize, containerPanel, text, options)
    options = options or { }
    local font = options.font or 'Montserrat Regular'
    local weight = options.weight or 500
    local minSize = options.minSize or 8
    local maxSize = options.maxSize or 100
    local padding = options.padding or 10

    local adaptiveData = {
        name = name,
        baseSize = baseSize,
        container = containerPanel,
        text = text,
        font = font,
        weight = weight,
        minSize = minSize,
        maxSize = maxSize,
        padding = padding,
        lastWidth = 0,
        lastHeight = 0,
        currentSize = baseSize
    }

    adaptiveFonts[name] = adaptiveData

    -- Initial font creation
    self:UpdateAdaptiveFont(name)

    return name
end

-- Update adaptive font based on container size
function DBase:UpdateAdaptiveFont(name)
    local data = adaptiveFonts[name]
    if (not data or not _IsValid(data.container)) then
        return
    end

    local w, h = data.container:GetSize()
    w = w - data.padding
    h = h - data.padding

    -- Only update if container size changed significantly
    if (_abs(w - data.lastWidth) > 5 or _abs(h - data.lastHeight) > 5) then
        data.lastWidth = w
        data.lastHeight = h

        local optimalSize = self:GetOptimalFontSize(data.text, w, h, data.baseSize, data.minSize, data.maxSize)
        if (optimalSize ~= data.currentSize) then
            data.currentSize = optimalSize

            local tbl = {
                font = data.font,
                size = self:GetSize(optimalSize),
                weight = data.weight,
                extended = true
            }

            surface.CreateFont(data.name, tbl)
            fontCache[data.name] = nil -- Clear cache to force refresh
        end
    end
end

-- Get text dimensions for word wrapping
function DBase:GetTextDimensions(text, fontName)
    surface.SetFont(fontName)
    return surface.GetTextSize(text)
end

-- Calculate line breaks for text wrapping
function DBase:CalculateLineBreaks(text, fontName, maxWidth)
    local lines = { }
    local words = _Explode(' ', text)
    local currentLine = ''

    surface.SetFont(fontName)

    for i, word in _ipairs(words) do
        local testLine = currentLine
        if (currentLine ~= '') then
            testLine = testLine .. ' ' .. word
        else
            testLine = word
        end

        local w, h = surface.GetTextSize(testLine)

        if (w <= maxWidth) then
            currentLine = testLine
        else
            if (currentLine ~= '') then
                DTable:Add(lines, currentLine)
                currentLine = word
            else
                -- Single word is too long, try to break it
                local chars = { }
                for char in _gmatch(word, '.') do
                    DTable:Add(chars, char)
                end

                local partialWord = ''
                for j, char in _ipairs(chars) do
                    local testChar = partialWord .. char
                    local cw, ch = surface.GetTextSize(testChar)

                    if (cw <= maxWidth) then
                        partialWord = testChar
                    else
                        if (partialWord ~= '') then
                            DTable:Add(lines, partialWord)
                            partialWord = char
                        else
                            DTable:Add(lines, char)
                            partialWord = ''
                        end
                    end
                end

                if partialWord ~= '' then
                    currentLine = partialWord
                end
            end
        end
    end

    if (currentLine ~= '') then
        DTable:Add(lines, currentLine)
    end

    return lines
end

function DBase:CreateFont(name, size, font, weight)
    local tbl = {
        font = font or 'Montserrat Regular',
        size = size or self:GetSize(18),
        weight = weight or 500,
        extended = true
    }

    surface.CreateFont(name, tbl)
    fontCache[name] = nil
end

--- Registers a font using a full surface.CreateFont-compatible table.
-- Supports all surface.CreateFont fields: italic, underline, strikeout,
-- shadow, outline, additive, rotary, symbol, antialias, extended, etc.
-- Defaults are applied for any omitted fields.
--
-- @param name (string): The name to register the font under.
-- @param tbl (table): A table of font parameters passed directly to surface.CreateFont.
-- @return (nil)
--
-- @xample
--      DBase:RegisterFont('my_bold_italic', {
--          font = 'Roboto',
--          size = DBase:GetSize(20),
--          weight = 700,
--          italic = true,
--          underline = true,
--      })
function DBase:RegisterFont(name, tbl)
    if (_type(tbl) ~= 'table') then
        error('tbl must be a table', 2)
    end

    local final = {
        font = 'Montserrat Regular',
        size = self:GetSize(18),
        weight = 500,
        extended = true
    }

    DTable:Merge(final, tbl)
    surface.CreateFont(name, final)
    fontCache[name] = nil
end

function DBase:LoadedFonts()
    self:CreateFont('danlib_font_12', self:GetSize(12))
    self:CreateFont('danlib_font_14', self:GetSize(14))
    self:CreateFont('danlib_font_16', self:GetSize(16))
    self:CreateFont('danlib_font_18', self:GetSize(18))
    self:CreateFont('danlib_font_20', self:GetSize(20))
    self:CreateFont('danlib_font_22', self:GetSize(22))
    self:CreateFont('danlib_font_24', self:GetSize(24))
    self:CreateFont('danlib_font_26', self:GetSize(26))
    self:CreateFont('danlib_font_28', self:GetSize(28))
    self:CreateFont('danlib_font_30', self:GetSize(30))
    self:CreateFont('danlib_font_32', self:GetSize(32))
    self:CreateFont('danlib_font_34', self:GetSize(34))
    self:CreateFont('danlib_font_36', self:GetSize(36))
    self:CreateFont('danlib_font_38', self:GetSize(38))
    self:CreateFont('danlib_font_40', self:GetSize(40))
    self:CreateFont('danlib_font_42', self:GetSize(42))
    self:CreateFont('danlib_font_44', self:GetSize(44))
    self:CreateFont('danlib_font_46', self:GetSize(46))
    self:CreateFont('danlib_font_48', self:GetSize(48))
    self:CreateFont('danlib_font_50', self:GetSize(50))
    self:CreateFont('danlib_font_52', self:GetSize(52))
    self:CreateFont('danlib_font_54', self:GetSize(54))
    self:CreateFont('danlib_font_56', self:GetSize(56))
    self:CreateFont('danlib_font_58', self:GetSize(58))
    self:CreateFont('danlib_font_60', self:GetSize(60))
    self:CreateFont('danlib_font_62', self:GetSize(62))
    self:CreateFont('danlib_font_64', self:GetSize(64))
    self:CreateFont('danlib_font_66', self:GetSize(66))
    self:CreateFont('danlib_font_68', self:GetSize(68))
    self:CreateFont('danlib_font_70', self:GetSize(70))
    self:CreateFont('danlib_font_72', self:GetSize(72))
    self:CreateFont('danlib_font_74', self:GetSize(74))
    self:CreateFont('danlib_font_76', self:GetSize(76))
    self:CreateFont('danlib_font_78', self:GetSize(78))
    self:CreateFont('danlib_font_80', self:GetSize(80))
    self:CreateFont('danlib_font_82', self:GetSize(82))
    self:CreateFont('danlib_font_84', self:GetSize(84))
    self:CreateFont('danlib_font_86', self:GetSize(86))
    self:CreateFont('danlib_font_88', self:GetSize(88))
    self:CreateFont('danlib_font_90', self:GetSize(90))
    self:CreateFont('danlib_font_92', self:GetSize(92))
    self:CreateFont('danlib_font_94', self:GetSize(94))
    self:CreateFont('danlib_font_96', self:GetSize(96))
    self:CreateFont('danlib_font_98', self:GetSize(98))
    self:CreateFont('danlib_font_100', self:GetSize(100))
end
DBase:LoadedFonts()

-- Update all adaptive fonts
function DBase:UpdateAllAdaptiveFonts()
    for name, _ in _pairs(adaptiveFonts) do
        self:UpdateAdaptiveFont(name)
    end
end

local needsFontUpdate = true
local function ScreenSizeChanged(oldWidth, oldHeight, newWidth, newHeight)
    SW, SH = _ScrW() / 1920, _ScrH() / 1080

    local newRatio = _min(SH, SW)
    if (newRatio ~= Ratio) then
        Ratio = newRatio
        needsFontUpdate = true
        -- Clear font cache on screen size change
        fontCache = { }
    end
end
DHook:Add('OnScreenSizeChanged', 'DanLib.ScreenSizeChanged', ScreenSizeChanged)

-- Call DBase:LoadedFonts() only if necessary
DHook:Add('PostRender', 'DanLib.UpdateFonts', function()
    if needsFontUpdate then
        DBase:LoadedFonts()
        DBase:UpdateAllAdaptiveFonts()
        needsFontUpdate = false
        DHook:Run('DanLib.PostScreenSizeChanged')
    end
end)
