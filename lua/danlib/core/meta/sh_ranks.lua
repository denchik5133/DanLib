/***
 *   @addon         DanLib
 *   @component     Rank
 *   @license       MIT License
 *   @version       2.4.0
 *   @release_date  01/12/2024
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Rank management system with caching, permissions, and security
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 */
 


local DBase = DanLib.Func
local DTable = DanLib.Table
local DHook = DanLib.Hook
local METAPLAYER = DanLib.MetaPlayer
local DPlayerUtil = DanLib.PlayerUtil

local _IsValid = IsValid
local _pairs = pairs
local _Color = Color
local _ipairs = ipairs
local _CurTime = CurTime
local _stringFind = string.find
local _stringLower = string.lower
local _stringSplit = string.Split

-- CONSTANTS
local CACHE_DURATION = 5 -- Rank cache time (seconds)
local CACHE_CLEANUP_INTERVAL = 30 -- Cache cleanup interval (seconds)
local DEFAULT_RANK = 'rank_member'
local OWNER_RANK = 'rank_owner'

DanLib.RankCache = DanLib.RankCache or { }
DanLib.NextCacheClean = DanLib.NextCacheClean or 0

--- Retrieves rank data from the configuration
-- @param rankID (string): Rank ID
-- @param field (string|nil): Field to receive (nil = all data)
-- @param default (any): Default value
-- @return any: Rank data or default value
local function GetRankData(rankID, field, default)
    if (not rankID or rankID == '') then
        return default
    end
    
    local ranks = DanLib.ConfigMeta.BASE:GetValue('Ranks') or { }
    local rankData = ranks[rankID]
    
    if (not rankData) then
        return default
    end
    
    if field then
        return rankData[field] ~= nil and rankData[field] or default
    end
    
    return rankData
end

--- Periodic cleaning of outdated cache entries
local function CleanRankCache()
    local currentTime = _CurTime()
    if (DanLib.NextCacheClean > currentTime) then
        return
    end
    
    DanLib.NextCacheClean = currentTime + CACHE_CLEANUP_INTERVAL
    
    local cleaned = 0
    for steamID, data in _pairs(DanLib.RankCache) do
        if (data.time < currentTime - CACHE_DURATION * 2) then
            DanLib.RankCache[steamID] = nil
            cleaned = cleaned + 1
        end
    end
    
    if (cleaned > 0) then
        -- DBase:Print('Cleaned ' .. cleaned .. ' expired rank cache entries')
    end
end

-- Automatic cache clearing
DHook:Add('Think', 'DanLib.CleanRankCache', CleanRankCache)

--- Gets the player's rank ID
-- @return string: Rank ID
function METAPLAYER:get_danlib_rank()
    if (not _IsValid(self)) then
        return DEFAULT_RANK
    end
    return self:GetNWString('DanLib.RankID', DEFAULT_RANK)
end

--- Gets the rank ID with caching
-- @return string: Rank ID
function METAPLAYER:get_danlib_rank_cached()
    if (not _IsValid(self)) then
        return DEFAULT_RANK
    end
    
    local steamID = self:SteamID64()
    local currentTime = _CurTime()
    
    -- Checking the cache
    local cached = DanLib.RankCache[steamID]
    if (cached and cached.time > currentTime - CACHE_DURATION) then
        return cached.rank
    end
    
    -- Updating the cache
    local rank = self:get_danlib_rank()
    DanLib.RankCache[steamID] = {
        rank = rank,
        time = currentTime
    }
    
    return rank
end

--- Gets the name of the player's rank
-- @return string: Rank name
function METAPLAYER:get_danlib_rank_name()
    if (not _IsValid(self)) then
        return 'Member'
    end
    
    local rankID = self:get_danlib_rank_cached()
    return GetRankData(rankID, 'Name', 'Member')
end

--- Gets the color of the player's rank
-- @return Color: Rank color
function METAPLAYER:get_danlib_rank_color()
    if (not _IsValid(self)) then
        return _Color(0, 151, 230)
    end
    
    local rankID = self:get_danlib_rank_cached()
    return GetRankData(rankID, 'Color', _Color(0, 151, 230))
end

--- Gets player rank access rights
-- @return table: Table with access rights
function METAPLAYER:get_danlib_rank_permissions()
    if (not _IsValid(self)) then
        return { }
    end
    
    local rankID = self:get_danlib_rank_cached()
    
    -- The owner has all the rights
    if (rankID == OWNER_RANK) then
        return {
            all_access = true
        }
    end
    
    return GetRankData(rankID, 'Permission', { })
end

--- Checks if the player has a license.
-- @param pPlayer (Player): Player
-- @param permission (string): Title of the right
-- @return boolean: true if there is a right
function DBase.HasPermission(pPlayer, permission)
    -- Validation of input data
    if (not _IsValid(pPlayer) or not pPlayer:IsPlayer()) then
        return false
    end
    
    if (not permission or permission == '') then
        return false
    end
    
    -- Getting the rank ID
    local rankID = pPlayer:get_danlib_rank_cached()
    
    -- The owner has all the rights
    if (rankID == OWNER_RANK) then
        return true
    end
    
    -- Checking the existence of a right in the configuration
    if (not DanLib.BaseConfig.Permissions[permission]) then
        if SERVER then
            DBase:Print('Warning: Permission "' .. permission .. '" not registered!')
        end
        return false
    end
    
    -- Getting rank rights
    local permissions = GetRankData(rankID, 'Permission', { })
    return permissions[permission] == true
end

--- Gets rank statistics on the server
-- @return table: A table with the number of players in each rank
function DBase:GetRankStatistics()
    local rankStats = { }
    local players = _playerGetAll()
    local ranks = DanLib.ConfigMeta.BASE:GetValue('Ranks') or { }
    
    for _, ply in _ipairs(players) do
        local rankID = ply:get_danlib_rank_cached()
        
        -- Initialization if the rank occurs for the first time
        if (not rankStats[rankID]) then
            local rankData = ranks[rankID]
            rankStats[rankID] = { 
                Count = 0, 
                RankName = rankData and rankData.Name or 'Member',
                RankColor = rankData and rankData.Color or _Color(255, 255, 255)
            }
        end
        
        rankStats[rankID].Count = rankStats[rankID].Count + 1
    end
    
    return rankStats
end

if CLIENT then
    --- The command to set the player's rank
    local function setrank(pPlayer, cmd, args, str)
        -- Validation of arguments
        if (#args < 2) then
            DBase:Print('Usage: danlib_setrank <player_name> <rank_id>')
            return
        end
        
        -- Rights verification (preliminary, basic on the server)
        if (not DBase.HasPermission(LocalPlayer(), 'EditRanks')) then
            DBase:ScreenNotification(DBase:L('#access.denied'), DBase:L('#access.ver'), 'ERROR', 6)
            return
        end
        
        -- Player Search
        local target = DBase:FindPlayer(args[1])
        if (not target) then
            DBase:Print('Error: Player "' .. args[1] .. '" not found!')
            DBase:Print('Usage: danlib_setrank <player_name> <rank_id>')
            return
        end
        
        -- Checking the existence of a rank
        local ranks = DanLib.ConfigMeta.BASE:GetValue('Ranks') or { }
        if (not ranks[args[2]]) then
            DBase:Print('Error: Rank ID "' .. args[2] .. '" does not exist!')
            return
        end
        
        -- Sending a request to the server
        DanLib.Net:Open('DanLib.NetSetRank')
            :Ent(target)
            :Str(args[2])
            :Up()
        
        DBase:Print('Rank change request sent for ' .. target:Name())
    end
    
    --- Auto-completion for the team
    local function autocomplete(command, str)
        str = str:sub(2, -1) -- Removing the '/' at the beginning
        local suggestions = { }
        local args = _stringSplit(str, ' ')
        
        if (#args == 1) then
            -- Adding player names
            for _, ply in _ipairs(DPlayerUtil:GetAll()) do
                if ply:IsBot() then
                    continue
                end
                DTable:Add(suggestions, 'danlib_setrank ' .. ply:Name())
            end
        elseif (#args == 2) then
            -- Adding Rank IDs
            local rankInput = _stringLower(args[2])
            local ranks = DanLib.ConfigMeta.BASE:GetValue('Ranks') or { }
            
            for rankID, rankData in _pairs(ranks) do
                if _stringFind(_stringLower(rankID), rankInput, 1, true) then
                    DTable:Add(suggestions, 'danlib_setrank ' .. args[1] .. ' ' .. rankID)
                end
            end
        end
        
        return suggestions
    end
    
    DanLib.Concommand:Add('danlib_setrank', setrank, autocomplete)
end
