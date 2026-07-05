/***
 *   @addon         DanLib
 *   @component     CL Debug
 *   @license       MIT License
 *   @version       1.0.1
 *   @release_date  15/12/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *   
 *   @description   Client Debug UI Panel
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local UI = DanLib.UI
local DNet = DanLib.Net
local DUtils = DanLib.Utils
local DTable = DanLib.Table
local DHook = DanLib.Hook
local DCustomUtils = DanLib.CustomUtils.Create
local DEBUG = DanLib.DEBUG

-- Local optimizations
local _IsValid = IsValid
local _next = next
local _Color = Color
local _pairs = pairs
local _ipairs = ipairs
local _osDate = os.date
local _CurTime = CurTime
local _mathMax = math.max
local _mathClamp = math.Clamp
local _stringFormat = string.format
local _drawSimpleText = draw.SimpleText
local _stringGsub = string.gsub
local _stringFind = string.find
local _drawRoundedBox = draw.RoundedBox
local _colorWhite = _Color(255, 255, 255)
local _colorGray = _Color(130, 130, 130)

-- Grouping logs
local groupedLogs = { }
local lastCleanup = 0
local processedLogs = { }
local processedErrors = { }

DEBUG.unreadLogs = DEBUG.unreadLogs or { }

-- Precompiled patterns for highlighting
local HIGHLIGHT_PATTERNS = {
    -- CRITICAL ERRORS (Red)
    { pattern = '(attempt to)', color = '{color:255,100,100}%1{/color:}' },
    { pattern = '(stack overflow)', color = '{color:255,80,80}%1{/color:}' },
    { pattern = '(bad argument)', color = '{color:255,90,90}%1{/color:}' },
    { pattern = '(invalid key)', color = '{color:255,100,100}%1{/color:}' },
    { pattern = '(out of memory)', color = '{color:255,50,50}%1{/color:}' },
    { pattern = '(C stack overflow)', color = '{color:255,70,70}%1{/color:}' },
    
    -- NIL ERRORS (Light red)
    { pattern = '(nil value)', color = '{color:255,120,120}%1{/color:}' },
    { pattern = "(a nil value)", color = '{color:255,120,120}%1{/color:}' },
    { pattern = '(is nil)', color = '{color:255,130,130}%1{/color:}' },
    { pattern = '(null)', color = '{color:255,120,120}%1{/color:}' },
    
    -- SYNTAX ERRORS (Orange)
    { pattern = '(expected)', color = '{color:255,150,100}%1{/color:}' },
    { pattern = '(unexpected symbol)', color = '{color:255,140,90}%1{/color:}' },
    { pattern = '(syntax error)', color = '{color:255,130,80}%1{/color:}' },
    { pattern = '(malformed)', color = '{color:255,140,90}%1{/color:}' },
    { pattern = '(to close)', color = '{color:255,160,100}%1{/color:}' },
    { pattern = "(unfinished)", color = '{color:255,150,90}%1{/color:}' },
    
    -- TYPES (Yellow)
    { pattern = '(number)', color = '{color:255,200,100}%1{/color:}' },
    { pattern = '(string)', color = '{color:255,200,100}%1{/color:}' },
    { pattern = '(table)', color = '{color:255,200,100}%1{/color:}' },
    { pattern = '(function)', color = '{color:255,200,100}%1{/color:}' },
    { pattern = '(boolean)', color = '{color:255,200,100}%1{/color:}' },
    { pattern = '(userdata)', color = '{color:255,200,100}%1{/color:}' },
    
    -- OTHER PROBLEMS (Pink)
    { pattern = '(undefined)', color = '{color:255,120,180}%1{/color:}' },
    { pattern = '(not found)', color = '{color:255,120,180}%1{/color:}' },
    { pattern = '(missing)', color = '{color:255,130,190}%1{/color:}' },
    { pattern = '(invalid)', color = '{color:255,110,170}%1{/color:}' },
    { pattern = '(deprecated)', color = '{color:255,150,100}%1{/color:}' },
    
    -- FILES AND STRINGS (Blue)
    { pattern = '(%.lua:%d+)', color = '{color:150,200,255}%1{/color:}' },
    { pattern = '(addons/[%w_/]+%.lua)', color = '{color:140,190,255}%1{/color:}' },
    { pattern = '(lua/[%w_/]+%.lua)', color = '{color:140,190,255}%1{/color:}' },
    { pattern = '(%[C%])', color = '{color:150,200,255}%1{/color:}' },
    
    -- FUNCTIONS AND VARIABLES (Green)
    { pattern = "('([%w_%.:%+]+)')", color = '{color:200,255,150}%1{/color:}' }, -- 'functionName'
    { pattern = '("([%w_%.:%+]+)")', color = '{color:255,220,150}%1{/color:}' }, -- 'variableName'
    { pattern = '(%(([%w_]+)%))', color = '{color:180,255,180}%1{/color:}' }, -- (parameters)

    -- SYMBOLS AND OPERATORS (Cyanogen/Purple)
    -- Brackets (all kinds)
    { pattern = "(%'%[%')", color = '{color:200,150,255}%1{/color:}' }, -- '['
    { pattern = "(%'%]%')", color = '{color:200,150,255}%1{/color:}' }, -- ']'
    { pattern = "(%'%(%')", color = '{color:200,150,255}%1{/color:}' }, -- '('
    { pattern = "(%'%)%')", color = '{color:200,150,255}%1{/color:}' }, -- ')'
    { pattern = "(%'%{%')", color = '{color:200,150,255}%1{/color:}' }, -- '{'
    { pattern = "(%'%}%')", color = '{color:200,150,255}%1{/color:}' }, -- '}'
    
    -- Special characters
    { pattern = "(%'<%')", color = '{color:200,150,255}%1{/color:}' }, -- '<'
    { pattern = "(%'>%')", color = '{color:200,150,255}%1{/color:}' }, -- '>'
    { pattern = "(%'=%')", color = '{color:200,150,255}%1{/color:}' }, -- '='
    { pattern = "(%'%+%')", color = '{color:200,150,255}%1{/color:}' }, -- '+'
    { pattern = "(%'%-%')", color = '{color:200,150,255}%1{/color:}' }, -- '-'
    { pattern = "(%'%*%')", color = '{color:200,150,255}%1{/color:}' }, -- '*'
    { pattern = "(%'/%')", color = '{color:200,150,255}%1{/color:}' }, -- '/'
    { pattern = "(%'%%%')", color = '{color:200,150,255}%1{/color:}' }, -- '%'
    { pattern = "(%'%.%')", color = '{color:200,150,255}%1{/color:}' }, -- '.'
    { pattern = "(%',%')", color = '{color:200,150,255}%1{/color:}' }, -- ','
    { pattern = "(%';%')", color = '{color:200,150,255}%1{/color:}' }, -- ';'
    { pattern = "(%':%')", color = '{color:200,150,255}%1{/color:}' }, -- ':'
    { pattern = "(%'#%')", color = '{color:200,150,255}%1{/color:}' }, -- '#'
    
    -- OPERATIONS (Purple)
    { pattern = '(index)', color = '{color:200,150,255}%1{/color:}' },
    { pattern = '(call)', color = '{color:200,150,255}%1{/color:}' },
    { pattern = '(concatenate)', color = '{color:200,150,255}%1{/color:}' },
    { pattern = '(perform)', color = '{color:200,150,255}%1{/color:}' },
    { pattern = '(get length)', color = '{color:200,150,255}%1{/color:}' },
    
    -- GMOD SPECIFIC (Cyan)
    { pattern = '(Entity)', color = '{color:100,255,255}%1{/color:}' },
    { pattern = '(Player)', color = '{color:100,255,255}%1{/color:}' },
    { pattern = '(Vector)', color = '{color:100,255,255}%1{/color:}' },
    { pattern = '(Angle)', color = '{color:100,255,255}%1{/color:}' },
    { pattern = '(Color)', color = '{color:100,255,255}%1{/color:}' },
    { pattern = '(NULL Entity)', color = '{color:255,100,100}%1{/color:}' },
    
    -- NUMBERS AND ADDRESSES (Grey)
    { pattern = '(0x[%x]+)', color = '{color:180,180,180}%1{/color:}' }, -- Hex addresses
    { pattern = '(%d+ms)', color = '{color:255,200,100}%1{/color:}' }, -- Time
    { pattern = '(%d+%%%%)', color = '{color:255,200,100}%1{/color:}' }, -- Percentages
}

-- Tag color cache (we don't create a Color every time)
local TAG_COLORS = {
    RUNTIME = _Color(255, 150, 150),
    LUA = _Color(255, 150, 150),
    PARSE = _Color(255, 150, 150),
    SQL = _Color(150, 200, 255),
    NETWORK = _Color(150, 200, 255),
    PERFORMANCE = _Color(255, 200, 100),
    SYSTEM = _Color(150, 255, 150),
    TEST = _Color(200, 150, 255),
    DEFAULT = _Color(150, 150, 150)
}

-- Cache of highlighted text
local highlightCache = { }
local highlightCacheSize = 0
local MAX_CACHE_SIZE = 100

--- Text highlighting function with caching
local function HighlightText(text)
    -- Checking the cache
    local cached = highlightCache[text]
    if cached then
        return cached
    end
    
    local result = text
    
    -- We apply all the patterns
    for i = 1, #HIGHLIGHT_PATTERNS do
        local p = HIGHLIGHT_PATTERNS[i]
        result = _stringGsub(result, p.pattern, p.color)
    end
    
    -- We save it to the cache with a size limit
    if (highlightCacheSize < MAX_CACHE_SIZE) then
        highlightCache[text] = result
        highlightCacheSize = highlightCacheSize + 1
    end
    
    return result
end

-- Getting the tag color (without creating a new Color)
local function GetTagColor(tagText)
    return TAG_COLORS[tagText] or TAG_COLORS.DEFAULT
end

-- Creating a UI panel
function DEBUG:CreatePanel(parent)
    if (not self:IsEnabled()) then
        return
    end

    if (_IsValid(self.panel)) then
        return
    end
    
    local panel = DCustomUtils(parent)
    panel:ApplyAttenuation(0.4)
    panel:SetSize(420, parent:GetTall() - 60)
    
    local x, y = panel:GetPosition('TOP_RIGHT', 12)
    y = 40
    panel:SetPos(x, y)

    local scrollPanel = DCustomUtils(panel, 'DanLib.UI.Scroll')
    scrollPanel:Pin(nil, 6)
    
    self.scrollPanel = scrollPanel
    self.panel = panel
    self:RefreshLogs()
    
    return panel
end

-- Batch creation of panels
function DEBUG:RefreshLogs()
    if (not _IsValid(self.scrollPanel)) then
        return
    end
    
    local currentTime = _CurTime()
    self:UpdateGroupedLogs()
    
    -- Sorting
    local sortedLogs = { }
    for hash, data in _pairs(groupedLogs) do
        sortedLogs[#sortedLogs + 1] = data
    end
    
    DTable:Sort(sortedLogs, function(a, b)
        return (a.lastSeen or 0) > (b.lastSeen or 0)
    end)
    
    -- Removing old panels
    for hash, panel in _pairs(self.logPanels or { }) do
        if _IsValid(panel) then
            panel:Remove()
        end
    end
    self.logPanels = { }
    
    -- Precomputing common values
    local maxTextWidth = self.scrollPanel:GetWide() - 30
    local hasUnreadLogs = _next(self.unreadLogs) ~= nil
    
    -- Creating panels
    for i = 1, #sortedLogs do
        local data = sortedLogs[i]
        local log = data.log
        local hash = _stringFormat('%s|%s|%s', log.level or 'INFO', log.tag or 'UNKNOWN', log.text or '')
        
        local isUnread = self.unreadLogs[hash] ~= nil
        local isJustAdded = (data.lastSeen or 0) > (currentTime - 3)
        
        -- The color of the level
        local levelColor = self:GetLogColor(log.level) or _colorWhite
        
        -- Tag color (using cache)
        local tagText = log.tag or 'UNKNOWN'
        local tagColor = GetTagColor(tagText)
        
        -- Text highlighting (with caching)
        local logText = log.text or 'No message'
        local highlightedText = HighlightText(logText)
        
        -- Creating markup
        local markup = DUtils:CreateMarkup(highlightedText, 'danlib_font_14', _Color(220, 220, 220), maxTextWidth)
        local textHeight = markup and markup:GetHeight() or 20
        local panelHeight = _mathMax(42, 22 + textHeight + 8)
        
        -- Size pre-calculation
        local timeText = log.timestamp or '--:--:--'
        local timeW = DUtils:TextSize(timeText, 'danlib_font_14').w
        
        local levelText = log.level or 'INFO'
        local levelW = DUtils:TextSize(levelText, 'danlib_font_14').w + 10
        local tagW = DUtils:TextSize(tagText, 'danlib_font_14').w
        
        -- Creating a panel
        local logPanel = DCustomUtils(self.scrollPanel)
        logPanel:PinMargin(TOP, 5, 2, 5, 2)
        logPanel:SetTall(panelHeight)
        
        if isJustAdded then
            logPanel:SetAlpha(0)
            logPanel:AlphaTo(255, 0.3)
        end
        
        -- Saving data
        logPanel.logData = {
            log = log,
            levelColor = levelColor,
            count = data.count,
            markup = markup,
            logText = logText,
            isUnread = isUnread,
            isJustAdded = isJustAdded,
            creationTime = currentTime,
            hash = hash,
            timeText = timeText,
            timeW = timeW,
            levelText = levelText,
            levelW = levelW,
            tagText = tagText,
            tagW = tagW,
            tagColor = tagColor
        }
        
        -- Minimizing calls in Paint
        logPanel:ApplyEvent(nil, function(sl, w, h)
            local d = sl.logData
            if (not d or not d.levelColor) then
                return
            end
            
            -- Background
            local bgColor = _Color(15, 20, 28, 60)
            
            if d.isUnread then
                bgColor = _Color(50, 100, 200, 30)
            elseif d.isJustAdded then
                local elapsed = _CurTime() - d.creationTime
                if (elapsed < 3) then
                    local alpha = _mathClamp(40 * (1 - elapsed / 3), 0, 40)
                    bgColor = _Color(d.levelColor.r, d.levelColor.g, d.levelColor.b, alpha)
                else
                    d.isJustAdded = false
                end
            end
            
            DUtils:DrawRoundedBox(0, 0, w, h, bgColor)
            
            -- Dynamic layout (precomputed values)
            local padding = 7
            local x = padding
            
            -- time
            _drawSimpleText(d.timeText, 'danlib_font_14', x, 4, _colorGray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            x = x + d.timeW + padding
            
            -- LEVEL BADGE
            DUtils:DrawRoundedBox(x, 3, d.levelW, 14, _Color(d.levelColor.r, d.levelColor.g, d.levelColor.b, 80))
            _drawSimpleText(d.levelText, 'danlib_font_14', x + d.levelW * 0.5, 10, d.levelColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            x = x + d.levelW + padding
            
            -- TAG TAG
            _drawSimpleText(d.tagText, 'danlib_font_14', x, 10, d.tagColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Counter
            if (d.count > 1) then
                local countText = '×' .. d.count
                local countW = DUtils:TextSize(countText, 'danlib_font_14').w + 10
                local countX = w - countW - padding - (d.isUnread and 45 or 0)
                _drawRoundedBox(10, countX, 4, countW, 14, _Color(255, 107, 107, 220))
                _drawSimpleText(countText, 'danlib_font_14', countX + countW * 0.5, 10, _colorWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- text
            if d.markup then
                d.markup:Draw(padding, 22, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            else
                _drawSimpleText(d.logText, 'danlib_font_14', padding, 22, _Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end)
        
        self.logPanels[hash] = logPanel
    end
    
    -- Empty state
    if (_next(self.logPanels) == nil) then
        if (not _IsValid(self.emptyPanel)) then
            self.emptyPanel = DCustomUtils(self.scrollPanel)
            self.emptyPanel:Pin(FILL)
            self.emptyPanel:ApplyText('No logs yet...', 'danlib_font_16', nil, nil, _colorGray)
        end
    elseif _IsValid(self.emptyPanel) then
        self.emptyPanel:Remove()
        self.emptyPanel = nil
    end
end

-- Updating grouped logs
function DEBUG:UpdateGroupedLogs()
    local currentTime = _CurTime()
    
    -- Cleaning every 60 seconds
    if (currentTime - lastCleanup > 60) then
        groupedLogs = { }
        processedLogs = { }
        processedErrors = { }
        highlightCache = { } -- Clearing the backlight cache
        highlightCacheSize = 0
        lastCleanup = currentTime
    end
    
    self.unreadLogs = self.unreadLogs or { }
    local menuIsOpen = _IsValid(self.panel)
    
    -- Log processing
    for i = #processedLogs + 1, #self.logs do
        local log = self.logs[i]
        local hash = _stringFormat('%s|%s|%s', log.level or 'INFO', log.tag or 'UNKNOWN', log.text or '')
        
        if (not groupedLogs[hash]) then
            groupedLogs[hash] = {
                log = log,
                count = 1,
                lastSeen = log.time or currentTime
            }
        else
            groupedLogs[hash].count = groupedLogs[hash].count + 1
            groupedLogs[hash].lastSeen = log.time or currentTime
        end
        
        if (not menuIsOpen) then
            self.unreadLogs[hash] = currentTime
        end
        
        processedLogs[i] = true
    end
    
    -- Error handling
    for i = #processedErrors + 1, #self.errors do
        local err = self.errors[i]
        
        -- Checking the realm
        local realm = err.realm or 'CLIENT'
        local errorText = err.error or 'Unknown error'
        
        -- Adding [SERVER] only for server errors
        if (realm == 'SERVER' and not _stringFind(errorText, '%[SERVER%]', 1, true)) then
            errorText = '[SERVER] ' .. errorText
        end
        
        local log = {
            level = 'ERROR',
            tag = err.type or 'RUNTIME',
            text = errorText,
            timestamp = err.timestamp,
            time = err.time
        }
        
        local hash = _stringFormat('ERROR|%s|%s', log.tag, errorText)
        
        if (not groupedLogs[hash]) then
            groupedLogs[hash] = {
                log = log,
                count = 1,
                lastSeen = err.time or currentTime
            }
        else
            groupedLogs[hash].count = groupedLogs[hash].count + 1
            groupedLogs[hash].lastSeen = err.time or currentTime
        end
        
        if (not menuIsOpen) then
            self.unreadLogs[hash] = currentTime
        end
        
        processedErrors[i] = true
    end
end

-- Hooks
DHook:Add('DanLib.MainMenu', 'DanLib.Debug.CreatePanel', function(mainMenu)
    if (not DEBUG:IsEnabled()) then
        return
    end

    -- Rights verification
    local pPlayer = LocalPlayer()
    if (not _IsValid(pPlayer) or not DEBUG:CanPlayerDebug(pPlayer)) then
        return
    end
    
    if _IsValid(DEBUG.panel) then
        DEBUG.panel:Remove()
        DEBUG.panel = nil
    end
    
    DEBUG:CreatePanel(mainMenu)
end)

-- Reception of server logs
DNet:On('DanLib.Debug.ServerLog', function()
    local logEntry = DNet:Tbl()
    if DEBUG:IsEnabled() then
        DEBUG:Log('[SERVER] ' .. logEntry.text, logEntry.level, logEntry.tag)
    end
end)

-- Receiving server errors
DNet:On('DanLib.Debug.ServerError', function()
    local errorEntry = DNet:Tbl()
    if (not DEBUG:IsEnabled()) then
        return
    end
    
    -- Adding to local errors with the [SERVER] prefix
    DTable:Add(DEBUG.errors, {
        error = '[SERVER] ' .. (errorEntry.error or 'Unknown error'),
        stack = errorEntry.stack or '',
        time = _CurTime(),
        timestamp = errorEntry.timestamp or _osDate('%H:%M:%S'),
        type = errorEntry.type or 'RUNTIME',
        realm = 'SERVER'
    })
    
    -- Updating the UI
    if DEBUG.RefreshLogs then
        DEBUG:RefreshLogs()
    end
end)

DanLib.Concommand:Add('danlib_debug_clear', function()
    local pPlayer = LocalPlayer()
    if (not _IsValid(pPlayer) or not DEBUG:CanPlayerDebug(pPlayer)) then
        return
    end

    DEBUG:Clear()
    groupedLogs = { }
    processedLogs = { }
    processedErrors = { }
    DEBUG.unreadLogs = { }
    highlightCache = { }
    highlightCacheSize = 0
    
    if DEBUG.RefreshLogs then
        DEBUG:RefreshLogs()
    end
    
    print('[DanLib Debug] All data cleared')
end)
