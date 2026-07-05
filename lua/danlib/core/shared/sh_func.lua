/***
 *   @addon         DanLib
 *   @component     Message Formatting & Utilities
 *   @license       MIT License
 *   @version       1.8.1
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Advanced message formatting with optimized color tag parsing and player
 *                  utility functions. Supports multiple color formats, theme integration,
 *                  and efficient network transmission with minimal overhead.
 *
 *   @functions     
 *                  - Color tags: RGB, RGBA, theme names ({color:Blue}, {color:255,0,0})
 *                  - Flexible spacing in tags ({color: 255, 0, 0} supported)
 *                  - Color object caching (~3x faster, auto-cleanup at 50 items)
 *                  - Distance-based broadcasting
 *
 *   @usage         
 *                  DBase:SendMessage(ply, TYPE_INFO, '{color:Gold}Reward:{/color:} +500$')
 *                  DBase:SendMessageDistance(ply, TYPE_WARNING, 500, '{color:Red}Alert!')
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/DanLib
 */



local DBase = DanLib.Func
local DNet = DanLib.Net
local DTable = DanLib.Table
local DPlayerUtil = DanLib.PlayerUtil

local _type = type
local _unpack = unpack
local _IsValid = IsValid
local _ipairs = ipairs
local _sub = string.sub
local _find = string.find
local _Trim = string.Trim
local _match = string.match
local _gmatch = string.gmatch
local _tonumber = tonumber
local _format = string.format

-- Color cache for performance optimization
local colorCache = { }
local cacheSize = 0
local maxCacheSize = 50

--- Cached color creation to avoid creating duplicate Color objects
-- @param r (number): Red component (0-255)
-- @param g (number): Green component (0-255)
-- @param b (number): Blue component (0-255)
-- @param a (number): Alpha component (0-255), optional
-- @return Color: Cached or newly created Color object
local function getCachedColor(r, g, b, a)
    local key = _format('%d,%d,%d,%d', r, g, b, a or 255)
    
    if (not colorCache[key]) then
        -- Limit cache size to prevent memory bloat
        if (cacheSize >= maxCacheSize) then
            colorCache = { }
            cacheSize = 0
        end
        
        colorCache[key] = Color(r, g, b, a or 255)
        cacheSize = cacheSize + 1
    end
    
    return colorCache[key]
end

--- Formats message arguments with support for colour tags.
-- Supports formats:
-- {color:255,165,0,255} - RGBA without spaces
-- {color: 255, 165, 0, 255} - RGBA with spaces
-- {color:255,165,0} - RGB (alpha = 255)
-- {color: 255, 165, 0} - RGB with spaces
-- {color:Blue} - Color name from DanLib.Config.Theme
-- {/color:} - Reset to default color
--
-- @param ...: Arbitrary number of message arguments (strings, Color objects, tables)
-- @return table: Formatted arguments with text and color objects
local function gormatMessageArgs(...)
    local formattedArgs = { }
    local defaultColor = getCachedColor(255, 255, 255, 255)
    local currentColor = defaultColor
    local themeCache = DanLib.Config.Theme
    
    for _, message in _ipairs({ ... }) do
        if (_type(message) == 'string') then
            local pos = 1
            local len = #message
            
            while pos <= len do
                local tagStart = _find(message, '{', pos, true)
                
                if (not tagStart) then
                    -- No more tags, add rest of string
                    DTable:Add(formattedArgs, _sub(message, pos))
                    break
                end
                
                -- Add text before tag
                if (tagStart > pos) then
                    DTable:Add(formattedArgs, _sub(message, pos, tagStart - 1))
                end
                
                local tagEnd = _find(message, '}', tagStart, true)
                if (not tagEnd) then
                    -- Malformed tag, add rest as text
                    DTable:Add(formattedArgs, _sub(message, tagStart))
                    break
                end
                
                local tag = _sub(message, tagStart + 1, tagEnd - 1)
                
                -- Check tag type
                if (tag == '/color:') then
                    -- Closing tag: reset to default color
                    currentColor = defaultColor
                    DTable:Add(formattedArgs, currentColor)
                elseif (_sub(tag, 1, 6) == 'color:') then
                    -- Opening tag: parse color
                    local content = _Trim(_sub(tag, 7))
                    
                    -- Check if it's a color name (letters and underscores only)
                    if _match(content, '^%a[%a_]*$') then
                        local themeColor = themeCache[content]
                        if themeColor then
                            currentColor = themeColor
                            DTable:Add(formattedArgs, currentColor)
                        end
                    else
                        -- Parse RGB/RGBA numbers
                        local nums = { }
                        for num in _gmatch(content, '%d+') do
                            nums[#nums + 1] = _tonumber(num)
                        end
                        
                        if (#nums >= 3) then
                            currentColor = getCachedColor(nums[1], nums[2], nums[3], nums[4])
                            DTable:Add(formattedArgs, currentColor)
                        end
                    end
                end
                
                pos = tagEnd + 1
            end
        elseif (_type(message) == 'userdata' and message:IsColor()) then
            -- Color object passed directly
            currentColor = message
            DTable:Add(formattedArgs, currentColor)
        elseif (_type(message) == 'table') then
            -- Table passed directly
            DTable:Add(formattedArgs, message)
        else
            DBase:PrintError('A string, colour or table is expected, received: ' .. type(message))
        end
    end

    return formattedArgs
end

--- Sends a message to a player or group of players.
-- @param pPlayer (Player|table): The player to whom the message is sent (or nil for all players)
-- @param msgType (number): Message type (DANLIB_TYPE_*)
-- @param ...: Additional arguments for the message (strings, colors, etc.)
function DBase:SendMessage(pPlayer, msgType, ...)
    local args = gormatMessageArgs(...) -- Format arguments with color tags

    -- Send message over network
    if SERVER then
        DNet:Open('DanLib:Message')
            :Int(msgType, 8)
            :Tbl(args)
            :Send(pPlayer)
    elseif CLIENT then
        DNet:Open('DanLib:Message')
            :Ent(pPlayer)
            :Int(msgType, 8)
            :Tbl(args)
            :Up()
    end
end

--- Sends a message to players within the specified distance.
-- @param pPlayer (Player): The player from whom the message originates
-- @param type (number): Message type
-- @param distance (number): Maximum distance to send the message (0 = all players)
-- @param ...: Additional arguments for the message
function DBase:SendMessageDistance(pPlayer, type, distance, ...) 
    if (not _IsValid(pPlayer)) then
        return
    end

    local args = { ... }

    if (distance == 0) then
        self:SendMessage(nil, type, _unpack(args))
    else
        -- Send to players within distance
        local playerPos = pPlayer:GetPos()
        for _, v in _ipairs(DPlayerUtil:GetAll()) do
            if (_IsValid(v) and v:GetPos():Distance(playerPos) <= distance) then
                self:SendMessage(v, type, _unpack(args))
            end
        end
    end
end

--- Checks if the player has administrator access.
-- @param pPlayer (Player): The player for whom you want to check access
-- @return boolean: true if the player is a super administrator, otherwise false
function DBase:HasAdminAccess(pPlayer)
    return _IsValid(pPlayer) and pPlayer:IsSuperAdmin() or false
end
