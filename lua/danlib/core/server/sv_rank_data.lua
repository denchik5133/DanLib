/***
 *   @addon         DanLib
 *   @component     Rank data
 *   @license       MIT License
 *   @version       2.0.1
 *   @release_date  01/12/2024
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Server-side rank data management with owner protection and caching
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local tag = 'DanLib'
local DBase = DanLib.Func
local DNet = DanLib.Net
local DHook = DanLib.Hook
local DTimer = DanLib.Timer
local DFileUtil = DanLib.FileUtil
local DConcommand = DanLib.Concommand
local DPlayerUtil = DanLib.PlayerUtil
local DNetworkUtil = DanLib.NetworkUtil

-- LOCALIZATION
local _IsValid = IsValid
local _pairs = pairs
local _ipairs = ipairs
local _CurTime = CurTime
local _osdate = os.date
local _stringTrim = string.Trim
local _stringMatch = string.match

-- CONSTANTS
local RANK_DIR = 'danlib/rank/'
local OWNER_FILE = 'danlib/owner.txt'
local DEFAULT_RANK = 'rank_member'
local OWNER_RANK = 'rank_owner'
local BROADCAST_DELAY = 0.3
local SPAWN_INIT_DELAY = 5
local OWNER_CHECK_INTERVAL = 5

-- COLORS (centralized)
local COLOR_ORANGE = Color(255, 165, 0)
local COLOR_BLUE = Color(0, 151, 230)
local COLOR_YELLOW = Color(255, 215, 0)
local COLOR_WHITE = Color(255, 255, 255)
local COLOR_RED = Color(255, 69, 0)

-- OWNER CACHE
local ownerIDCache = nil
local ownerCacheTime = 0
local OWNER_CACHE_DURATION = 60 -- Cache for 60 seconds

-- RANK CACHE: in-memory mirror of danlib/rank/ directory.
-- Populated lazily on first broadcast/request, then kept in sync.
-- Key: SteamID64 string. Value: parsed rank data table.
local RankCache = nil

--- Initializes player rank data from a file
-- @return table: The player's rank data
function DanLib.MetaPlayer:InitPlayerRank()
    local path = RANK_DIR .. self:SteamID64() .. '.txt'
    if (not DFileUtil:Exists(path, 'DATA')) then 
        DFileUtil:Write(path, '[]') 
    end

    local data = DNetworkUtil:JSONToTable(DFileUtil:Read(path, 'DATA') or '[]')
    return data
end

--- Initializes the rank data directory if it doesn't exist
-- @return boolean: true if successful
function DBase.RankData()
    if (not DFileUtil:Exists(RANK_DIR, 'DATA')) then 
        DFileUtil:CreateDir(RANK_DIR) 
    end
    return true
end
DBase.RankData()

--- Gets the server owner ID with caching
-- @return string: Owner SteamID or empty string
function DBase.InitOwnerServer()
    local currentTime = _CurTime()
    
    -- Return cached value if fresh
    if (ownerIDCache and (currentTime - ownerCacheTime) < OWNER_CACHE_DURATION) then
        return ownerIDCache
    end
    
    -- Read from file
    local fileContent = DFileUtil:Read(OWNER_FILE, 'DATA')
    if (not fileContent) then
        DBase:PrintType('Logs', 'Owner file not found or cannot be read.')
        ownerIDCache = ''
        ownerCacheTime = currentTime
        return ''
    end

    local ownerID = _stringTrim(fileContent)
    ownerIDCache = ownerID
    ownerCacheTime = currentTime
    
    return ownerID
end

--- Invalidates owner cache (call after owner changes)
local function _InvalidateOwnerCache()
    ownerIDCache = nil
    ownerCacheTime = 0
end

--- Builds (or rebuilds) the full rank cache from disk.
-- Called lazily; avoid calling in hot paths.
local function _buildRankCache()
    local files = DFileUtil:Find(RANK_DIR .. '*', 'DATA')
    RankCache = {}
    for _, fileName in _ipairs(files) do
        local steamID64 = _stringMatch(fileName, '^(%d+)%..*')
        if steamID64 then
            local raw = DFileUtil:Read(RANK_DIR .. fileName, 'DATA')
            RankCache[steamID64] = DNetworkUtil:JSONToTable(raw)
        end
    end
end

--- Updates a single entry in the rank cache after a write.
-- @param steamID64 string
-- @param data table
local function _updateRankCache(steamID64, data)
    if RankCache then
        RankCache[steamID64] = data
    end
end

--- Removes a single entry from the rank cache after deletion.
-- @param steamID64 string
local function _evictRankCache(steamID64)
    if RankCache then
        RankCache[steamID64] = nil
    end
end

--- Checks if the player has owner access
-- @param pPlayer Player: The player to check
-- @return boolean: true if player is owner
local function _checkOwnerAccess(pPlayer)
    if (not _IsValid(pPlayer)) then 
        return false 
    end

    local owner = DBase.InitOwnerServer()
    if (not owner or owner == '') then 
        return false 
    end

    return _stringTrim(owner) == _stringTrim(pPlayer:SteamID())
end

--- Saves player rank data to a file
-- @param pPlayer Player: The player whose data is being saved
-- @param tData table: The data to save
local function _savePlayer(pPlayer, tData)
    local path = RANK_DIR .. pPlayer:SteamID64() .. '.txt'
    local data = DNetworkUtil:TableToJSON(tData, true)
    DFileUtil:Write(path, data)
    _updateRankCache(pPlayer:SteamID64(), tData)
end

--- Saves the server owner ID to a file
-- @param steamID string: Owner SteamID
local function _save_owner_file(steamID)
    if (not DFileUtil:Write(OWNER_FILE, steamID)) then
        DBase:PrintError('Failed to write owner data to file.')
        return false
    end
    _InvalidateOwnerCache()
    return true
end

--- Broadcasts rank data update to all admins
-- @param delay number: Delay before broadcast (default 0.3)
local function BroadcastRankUpdate(delay)
    delay = delay or BROADCAST_DELAY

    DTimer:Simple(delay, function()
        -- Use the in-memory cache; build it from disk only on the first call.
        if (not RankCache) then
            _buildRankCache()
        end

        for _, ply in _ipairs(DPlayerUtil:GetAll()) do
            if (_IsValid(ply) and DBase.HasPermission(ply, 'EditRanks')) then
                DNet:Open('DanLib.SendRankData')
                    :Tbl(RankCache)
                    :Send(ply)
            end
        end
    end)
end

--- Checks if the player is an owner, and assigns the rank 'rank_owner' if so
-- @param pPlayer Player: The player to be checked
-- @return boolean: true if owner rank assigned
function DBase.AssignOwnerRank(pPlayer)
    if (not _IsValid(pPlayer)) then
        return false
    end

    local ownerID = DBase.InitOwnerServer()
    if (not ownerID or ownerID == '') then
        return false
    end

    if _stringTrim(ownerID) == _stringTrim(pPlayer:SteamID()) then
        local data = pPlayer:InitPlayerRank()
        data.Rank = OWNER_RANK
        pPlayer:SetNWString('DanLib.RankID', OWNER_RANK)
        _savePlayer(pPlayer, data)
        DBase:Print(pPlayer:Name() .. ' has been assigned the rank of owner.')
        return true
    end

    return false
end

--- Gets a list of all rank files and their contents
DNet:On('DanLib.RequestRankData', function(len, pPlayer)
    if (not _IsValid(pPlayer)) then
        return
    end

    -- Use the in-memory cache; build it from disk only on the first call.
    if (not RankCache) then
        _buildRankCache()
    end

    DNet:Open('DanLib.SendRankData')
        :Tbl(RankCache)
        :Send(pPlayer)
end)

--- Handles rank change requests from players
DNet:On('DanLib.NetRequestChangeRank', function(_, sender)
    local target = DNet:Ent()
    local rank = DNet:Str()

    if (not _IsValid(sender) or not _IsValid(target)) then
        return
    end

    if (not DBase.HasPermission(sender, 'EditRanks')) then
        DBase:CreatePopupNotifi(sender, DBase:L('#access.denied'), DBase:L('#access.ver'), 'ERROR', 6)
        return
    end

    DNet:Open('DanLib.NetSetRank')
        :Ent(target)
        :Str(rank)
        :Send(sender)
end)

--- Initializes player rank on spawn
DHook:Add('PlayerInitialSpawn', 'InitSpawn', function(pPlayer)
    DTimer:Simple(SPAWN_INIT_DELAY, function()
        if (not _IsValid(pPlayer)) then
            return
        end
        
        if DBase.AssignOwnerRank(pPlayer) then
            return
        end

        local data = pPlayer:InitPlayerRank()
        if (data and data.Rank) then
            pPlayer:SetNWString('DanLib.RankID', data.Rank)
        else
            pPlayer:SetNWString('DanLib.RankID', DEFAULT_RANK)
        end
    end)
end)

--- Sets a player's rank
DNet:On('DanLib.NetSetRank', function(_, actor)
    local pPlayer = DNet:Ent()
    local rank = DNet:Str()

    if (not _IsValid(actor) or not _IsValid(pPlayer)) then
        return
    end
    
    if (not DBase.RankData()) then
        DBase.RankData()
    end

    -- Owner protection
    if _checkOwnerAccess(pPlayer) then
        DBase:SendMessageTag(actor, tag, 'You cannot change the rank of player ', COLOR_ORANGE, pPlayer:Name(), COLOR_WHITE, ' as he is determined by the server ', COLOR_BLUE, 'Owner', COLOR_WHITE, '!')
        return
    end

    -- Prevent manual owner rank assignment
    if (rank == OWNER_RANK) then
        DBase:SendMessageTag(actor, tag, COLOR_RED, 'Error: ', COLOR_WHITE, 'Cannot manually assign owner rank! Use ', COLOR_YELLOW, 'danlib_force_owner', COLOR_WHITE, ' console command.')
        return
    end

    local data = pPlayer:InitPlayerRank()
    local old_rank = pPlayer:get_danlib_rank()

    if data then
        if (old_rank == rank) then
            DBase:SendMessageTag(actor, tag, COLOR_WHITE, 'The rank of player ', COLOR_YELLOW, pPlayer:Name(), COLOR_WHITE, ' is already ', COLOR_BLUE, rank, COLOR_WHITE, '. No changes made.')
            return
        end

        data.Rank = rank
        pPlayer:SetNWString('DanLib.RankID', rank)
        _savePlayer(pPlayer, data)

        DBase:PrintType('Logs', 'You have changed the rank for ', COLOR_BLUE, pPlayer:Name(), COLOR_WHITE, '. His new rank is ', COLOR_BLUE, rank, COLOR_WHITE, '.')
        DBase:SendMessageTag(actor, tag, COLOR_ORANGE, 'You ', COLOR_WHITE, 'changed a player ', COLOR_YELLOW, pPlayer:Name(), COLOR_WHITE, ' rank ', COLOR_BLUE, old_rank, COLOR_WHITE, ' ➞ ', COLOR_BLUE, rank, COLOR_WHITE, '.')
        DBase:SendMessageTag(pPlayer, tag, DBase:L('#rank.changed'), COLOR_BLUE, old_rank, COLOR_WHITE, ' ➞ ', COLOR_BLUE, rank, COLOR_WHITE, '! Gave out: ', COLOR_ORANGE, actor:Name(), COLOR_WHITE, '.')
        DHook:Run('DanLib.Rank.Changed', pPlayer, old_rank, rank, actor)
        
        BroadcastRankUpdate()
    end
end)

--- Sets offline player rank
DNet:On('DanLib.NetSetOfflineRank', function(_, actor)
    local steamID64 = DNet:Str()
    local newRank = DNet:Str()
    
    if (not _IsValid(actor) or not DBase.HasPermission(actor, 'EditRanks')) then
        DBase:CreatePopupNotifi(actor, DBase:L('#access.denied'), DBase:L('#access.ver'), 'ERROR', 6)
        return
    end
    
    local path = RANK_DIR .. steamID64 .. '.txt'
    if (not DFileUtil:Exists(path, 'DATA')) then
        DBase:SendMessageTag(actor, tag, COLOR_RED, 'Error: ', COLOR_WHITE, 'Player file not found!')
        return
    end
    
    local data = DNetworkUtil:JSONToTable(DFileUtil:Read(path, 'DATA') or '[]')
    local oldRank = data.Rank or DEFAULT_RANK
    
    if (oldRank == OWNER_RANK or newRank == OWNER_RANK) then
        DBase:SendMessageTag(actor, tag, COLOR_RED, 'Error: ', COLOR_WHITE, 'Cannot change owner rank for offline players!')
        return
    end
    
    data.Rank = newRank
    local jsonData = DNetworkUtil:TableToJSON(data, true)
    DFileUtil:Write(path, jsonData)
    _updateRankCache(steamID64, data)

    DBase:SendMessageTag(actor, tag, COLOR_ORANGE, 'Success: ', COLOR_WHITE, 'Offline player rank changed: ', COLOR_BLUE, oldRank, COLOR_WHITE, ' ➞ ', COLOR_BLUE, newRank)
    BroadcastRankUpdate()
end)

--- Deletes offline player data
DNet:On('DanLib.NetDeleteOfflinePlayer', function(_, actor)
    local steamID64 = DNet:Str()
    
    if (not _IsValid(actor) or not DBase.HasPermission(actor, 'EditRanks')) then
        DBase:CreatePopupNotifi(actor, DBase:L('#access.denied'), DBase:L('#access.ver'), 'ERROR', 6)
        return
    end
    
    local path = RANK_DIR .. steamID64 .. '.txt'
    if (not DFileUtil:Exists(path, 'DATA')) then
        DBase:SendMessageTag(actor, tag, COLOR_RED, 'Error: ', COLOR_WHITE, 'Player file not found!')
        return
    end
    
    local data = DNetworkUtil:JSONToTable(DFileUtil:Read(path, 'DATA') or '[]')
    if (data.Rank == OWNER_RANK) then
        DBase:SendMessageTag(actor, tag, COLOR_RED, 'Error: ', COLOR_WHITE, 'Cannot delete owner data!')
        return
    end
    
    DFileUtil:Delete(path)
    _evictRankCache(steamID64)

    DBase:SendMessageTag(actor, tag, COLOR_ORANGE, 'Success: ', COLOR_WHITE, 'Player data deleted for SteamID64: ', COLOR_BLUE, steamID64)
    BroadcastRankUpdate()
end)

--- Removes the owner file (console only) - REQUIRES CONFIRMATION
DConcommand:Add('danlib_remove_owner', function(pPlayer, cmd, args)
    -- Checking that the command was called from the server console
    if _IsValid(pPlayer) then
        DBase:SendMessageTag(pPlayer, tag, 'This command can be executed only by server ', COLOR_BLUE, 'console', COLOR_WHITE, '!')
        return
    end

    local confirmFlag = args[1]
    
    -- Checking the existence of the file owner
    if (not DFileUtil:Exists(OWNER_FILE, 'DATA')) then
        DBase:Print('No owner file exists. Nothing to remove.')
        return
    end
    
    -- Reading the current owner BEFORE deleting
    local currentOwner = DBase.InitOwnerServer()
    if (not currentOwner or currentOwner == '') then
        DBase:Print('Owner file exists but is empty. Removing...')
        DFileUtil:Delete(OWNER_FILE)
        _InvalidateOwnerCache()
        DBase:Print('Empty owner file removed.')
        return
    end
    
    -- Owner exists - we require confirmation
    if (confirmFlag ~= 'confirm') then
        _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        DBase:Print(' WARNING: This will remove the server owner!')
        DBase:Print('')
        DBase:Print(' Current owner: ' .. currentOwner)
        
        -- We show the name if online
        for _, ply in _ipairs(DPlayerUtil:GetAll()) do
            if (ply:SteamID() == currentOwner) then
                DBase:Print('Player name: ' .. ply:Name() .. ' (ONLINE)')
                break
            end
        end
        
        DBase:Print('')
        DBase:Print(' This action will:')
        DBase:Print('   1. Remove owner file')
        DBase:Print('   2. Demote owner to default rank')
        DBase:Print('   3. Allow anyone to become owner via setup')
        DBase:Print('')
        DBase:Print(' To confirm, run:')
        DBase:Print(' danlib_remove_owner confirm')
        _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        return
    end
    
    -- Confirmation received - delete the owner
    DBase:Print('SECURITY: Removing owner ' .. currentOwner)
    
    -- We find the owner online and remove the rank
    local ownerFound = false
    for _, ply in _ipairs(DPlayerUtil:GetAll()) do
        if (ply:SteamID() == currentOwner) then
            local data = ply:InitPlayerRank()
            local oldRank = data.Rank or DEFAULT_RANK
            
            data.Rank = DEFAULT_RANK
            ply:SetNWString('DanLib.RankID', DEFAULT_RANK)
            _savePlayer(ply, data)
            
            -- Notifying the player
            DBase:SendMessageTag(ply, tag, COLOR_RED, 'WARNING: ', COLOR_WHITE, 'Your ', COLOR_BLUE, 'Owner', COLOR_WHITE, ' rank has been removed by server console!')
            DBase:SendMessageTag(ply, tag, 'Rank changed: ', COLOR_BLUE, oldRank, COLOR_WHITE, ' ➞ ', COLOR_BLUE, DEFAULT_RANK)
            
            DBase:Print('Demoted owner: ' .. ply:Name() .. ' (' .. oldRank .. ' → ' .. DEFAULT_RANK .. ')')
            ownerFound = true
            break
        end
    end
    
    if (not ownerFound) then
        DBase:Print('Owner is offline. Rank will be reset on next join.')
    end
    
    -- Deleting the owner file
    DFileUtil:Delete(OWNER_FILE)
    _InvalidateOwnerCache()
    
    -- Logging
    DBase:Print('Owner file removed successfully.')
    DBase:Print('SECURITY LOG: Owner removed at ' .. _osdate('%Y-%m-%d %H:%M:%S'))
    DBase:Print('Server is now without an owner. First player to use setup will become owner.')
    
    -- We are notifying all administrators
    for _, ply in _ipairs(DPlayerUtil:GetAll()) do
        if (_IsValid(ply) and DBase.HasPermission(ply, 'EditRanks')) then
            DBase:SendMessageTag(ply, tag, COLOR_ORANGE, 'NOTICE: ', COLOR_WHITE, 'Server owner has been removed by console. Server is now without an owner.')
        end
    end
    
    BroadcastRankUpdate()
end)

--- Forces owner assignment (console only) - REQUIRES CONFIRMATION
DConcommand:Add('danlib_force_owner', function(pPlayer, cmd, args)
    -- Checking that the command was called from the server console
    if _IsValid(pPlayer) then
        DBase:SendMessageTag(pPlayer, tag, 'This command can be executed only by server ', COLOR_BLUE, 'console', COLOR_WHITE, '!')
        return
    end
    
    -- Checking arguments
    if (#args < 1) then
        DBase:Print(' Usage: danlib_force_owner <SteamID> [confirm]')
        DBase:Print('')
        DBase:Print(' Supported formats:')
        DBase:Print('   STEAM_0:1:12345678  (SteamID)')
        DBase:Print('   76561198012345678   (SteamID64)')
        DBase:Print('')
        DBase:Print(' Example: danlib_force_owner STEAM_0:1:12345678')
        DBase:Print(' Example: danlib_force_owner 76561198012345678')
        return
    end
    
    local steamID = args[1]
    local confirmFlag = args[2]
    
    -- SteamID Normalization
    local normalizedSteamID = steamID
    
    -- Format verification and conversion
    if _stringMatch(steamID, '^STEAM_%d:%d:%d+$') then
        -- SteamID format (STEAM_0:1:12345678) - we use it as it is
        normalizedSteamID = steamID
        DBase:Print('Detected SteamID format: ' .. steamID)
    elseif _stringMatch(steamID, '^7656119%d%d%d%d%d%d%d%d%d%d$') then
        -- steamID64 format (76561198...) - convert to SteamID
        local steamID64 = steamID
        normalizedSteamID = DNetworkUtil:SteamIDFrom64(steamID64)
        if (not normalizedSteamID or normalizedSteamID == '') then
            DBase:PrintError('ERROR: Failed to convert SteamID64 to SteamID!')
            return
        end
        
        DBase:Print('Detected SteamID64 format: ' .. steamID64)
        DBase:Print('Converted to SteamID: ' .. normalizedSteamID)
    else
        DBase:PrintError('ERROR: Invalid SteamID format!')
        DBase:PrintError('')
        DBase:PrintError(' Supported formats:')
        DBase:PrintError('   STEAM_0:1:12345678  (SteamID)')
        DBase:PrintError('   76561198012345678   (SteamID64)')
        DBase:PrintError('')
        DBase:PrintError(' You entered: ' .. steamID)
        return
    end
    
    -- Checking the existing owner
    local currentOwner = DBase.InitOwnerServer()
    if (currentOwner and currentOwner ~= '') then
        -- The owner already exists - confirmation is required
        if (confirmFlag ~= 'confirm') then
            _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
            DBase:Print(' WARNING: Owner already exists!')
            DBase:Print(' Current owner: ' .. currentOwner)
            DBase:Print(' New owner: ' .. normalizedSteamID)
            DBase:Print('')
            DBase:Print(' This will REPLACE the current owner!')
            DBase:Print(' To confirm, run:')
            DBase:Print(' danlib_force_owner ' .. steamID .. ' confirm')
            _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
            return
        end
        
        -- Confirmation received - owner replacement
        DBase:Print('SECURITY: Replacing owner ' .. currentOwner .. ' with ' .. normalizedSteamID)
        
        -- We find the old owner and remove the rank
        for _, ply in _ipairs(DPlayerUtil:GetAll()) do
            if (ply:SteamID() == currentOwner) then
                local data = ply:InitPlayerRank()
                data.Rank = DEFAULT_RANK
                ply:SetNWString('DanLib.RankID', DEFAULT_RANK)
                _savePlayer(ply, data)
                DBase:SendMessageTag(ply, tag, COLOR_RED, 'WARNING: ', COLOR_WHITE, 'Your owner rank has been removed by server console!')
                DBase:Print('Demoted old owner: ' .. ply:Name())
                break
            end
        end
    end
    
    -- Saving the new owner (using the normalized SteamID)
    if _save_owner_file(normalizedSteamID) then
        DBase:Print('Owner SteamID saved: ' .. normalizedSteamID)
        
        -- We are looking for a player online and assign a rank
        local found = false
        for _, ply in _ipairs(DPlayerUtil:GetAll()) do
            if (ply:SteamID() == normalizedSteamID) then
                DBase.AssignOwnerRank(ply)
                DBase:SendMessageTag(ply, tag, COLOR_ORANGE, 'SUCCESS: ', COLOR_WHITE, 'You have been assigned the ', COLOR_BLUE, 'Owner', COLOR_WHITE, ' rank by server console!')
                DBase:Print('Owner assigned to online player: ' .. ply:Name())
                found = true
                break
            end
        end
        
        if (not found) then
            DBase:Print('Owner player is offline. Rank will be assigned on next join.')
        end
        
        -- Logging for security
        DBase:Print('SECURITY LOG: Owner changed at ' .. _osdate('%Y-%m-%d %H:%M:%S'))
        BroadcastRankUpdate()
    else
        DBase:PrintError('ERROR: Failed to save owner file!')
    end
end)

--- Shows current owner information (console only)
DConcommand:Add('danlib_show_owner', function(pPlayer)
    if _IsValid(pPlayer) then
        DBase:SendMessageTag(pPlayer, tag, 'This command can be executed only by server ', COLOR_BLUE, 'console', COLOR_WHITE, '!')
        return
    end
    
    local currentOwner = DBase.InitOwnerServer()
    
    _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    if (currentOwner and currentOwner ~= '') then
        DBase:Print('Current Owner SteamID: ' .. currentOwner)
        
        -- Convert to steamID64 for convenience
        local steamID64 = DNetworkUtil:SteamIDTo64(currentOwner)
        if steamID64 then
            DBase:Print('SteamID64: ' .. steamID64)
        end
        
        -- Checking if the owner is online
        local isOnline = false
        for _, ply in _ipairs(DPlayerUtil:GetAll()) do
            if (ply:SteamID() == currentOwner) then
                DBase:Print('Status: ONLINE (' .. ply:Name() .. ')')
                DBase:Print('Current Rank: ' .. ply:get_danlib_rank())
                isOnline = true
                break
            end
        end
        
        if (not isOnline) then
            DBase:Print('Status: OFFLINE')
        end
        
        -- Showing the path to the file
        DBase:Print('File: data/' .. OWNER_FILE)
    else
        DBase:Print(' No owner set!')
        DBase:Print('')
        DBase:Print(' To set owner, use:')
        DBase:Print('   danlib_force_owner STEAM_0:1:12345678')
        DBase:Print('   danlib_force_owner 76561198012345678')
    end
    _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
end)

--- Sets up the server owner (first-time setup)
DNet:On('DanLib.SetupOwner', function(_, pPlayer)
    if (not _IsValid(pPlayer)) then
        return
    end
    
    if (not DBase.RankData()) then
        DBase.RankData()
    end
    
    local currentOwner = DBase.InitOwnerServer()
    -- Only allow setup if no owner exists
    if (currentOwner and currentOwner ~= '') then
        DBase:SendMessageTag(pPlayer, tag, COLOR_RED, 'Error: ', COLOR_WHITE, 'Owner already set! Use ', COLOR_YELLOW, 'danlib_force_owner', COLOR_WHITE, ' to change.')
        return
    end

    local newOwnerID = pPlayer:SteamID()
    if _save_owner_file(newOwnerID) then
        local data = pPlayer:InitPlayerRank()
        data.Rank = OWNER_RANK
        pPlayer:SetNWString('DanLib.RankID', OWNER_RANK)
        _savePlayer(pPlayer, data)

        DBase:PrintType('Logs', 'User ', pPlayer:Name(), ' has been determined to be the Owner of the server.')
        DBase:SendMessageTag(pPlayer, tag, 'User ', COLOR_ORANGE, pPlayer:Name(), COLOR_WHITE, ' has been determined to be the ', COLOR_BLUE, 'Owner', COLOR_WHITE, ' of the server.')
    end
end)

--- Checks owner availability and notifies client
local function check_owner_and_notify(pPlayer)
    if (not _IsValid(pPlayer)) then
        return
    end
    
    local owner = DBase.InitOwnerServer()
    local notificationType = (owner == '' and 'no_owner' or 'owner_set')

    DNet:Open('DanLib.NotifyNoOwner')
        :Str(notificationType)
        :Send(pPlayer)
end

--- Periodic owner check timer
local function periodic_owner_check(pPlayer)
    if (not _IsValid(pPlayer)) then
        return
    end
    
    local timerName = 'CheckOwnerTimer_' .. pPlayer:EntIndex()
    DTimer:Create(timerName, OWNER_CHECK_INTERVAL, 0, function()
        if _IsValid(pPlayer) then
            check_owner_and_notify(pPlayer)
        else
            DTimer:Remove(timerName)
        end
    end)
end

--- Initial owner check on spawn
DHook:Add('PlayerInitialSpawn', 'CheckOwnerOnSpawn', function(pPlayer)
    check_owner_and_notify(pPlayer)
    periodic_owner_check(pPlayer)
end)
