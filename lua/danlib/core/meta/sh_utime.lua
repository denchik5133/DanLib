/***
 *   @addon         DanLib
 *   @component     Time
 *   @license       MIT License
 *   @version       1.0.0
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
local DNet = DanLib.Net
local DHook = DanLib.Hook
local DTimer = DanLib.Timer
local DMetaPlayer = DanLib.MetaPlayer
local DPlayerUtil = DanLib.PlayerUtil

local _IsValid = IsValid
local _CurTime = CurTime
local _ostime = os.time
local _ipairs = ipairs
local _Clamp = math.Clamp
local _tostring = tostring
local _tonumber = tonumber
local _mathmax = math.max
local _ErrorNoHalt = ErrorNoHalt

--- Returns the accumulated playtime stored in the NWFloat (seconds).
-- This is the saved base — does NOT include the current session delta.
function DMetaPlayer:get_ddi_time()
    return self:GetNWFloat('ddi_time', 0)
end

--- Stores a new base playtime value into the NWFloat.
-- @param num (number): seconds
function DMetaPlayer:set_ddi_time(num)
    self:SetNWFloat('ddi_time', num)
end

--- Returns the CurTime() timestamp when the current session started.
function DMetaPlayer:get_ddi_time_start()
    return self:GetNWFloat('ddi_time_start', 0)
end

--- Stores the session-start timestamp into the NWFloat.
-- @param num (number): CurTime() value
function DMetaPlayer:set_ddi_time_start(num)
    self:SetNWFloat('ddi_time_start', num)
end

--- Returns the length of the current session in seconds (since last load/save).
function DMetaPlayer:get_ddi_session_time()
    return _CurTime() - self:get_ddi_time_start()
end

--- Returns total playtime INCLUDING the current session.
-- Use this for display purposes — it stays live every frame.
function DMetaPlayer:get_total_ddi_time()
    return self:get_ddi_time() + _CurTime() - self:get_ddi_time_start()
end

if SERVER then
    local TABLE_NAME = 'danlib_time'
    local SAVE_INTERVAL = 300 -- auto-save every 5 minutes

    -- Table init
    local function InitTable()
        DDIDB:CreateTable(TABLE_NAME, [[
            steamid TEXT NOT NULL,
            time REAL NOT NULL DEFAULT 0,
            last_seen INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (steamid)
        ]], function(ok)
            if ok then
                DBase:Print('Time table ready (' .. TABLE_NAME .. ')')
            else
                _ErrorNoHalt('[DanLib] Time: failed to create table ' .. TABLE_NAME .. '\n')
            end
        end)
    end

    -- Internal save
    local function SavePlayerTime(pPlayer, final)
        if (not _IsValid(pPlayer)) then
        	return
        end

        local steamid = pPlayer:SteamID()
        local base = pPlayer:get_ddi_time()
        local start = pPlayer:get_ddi_time_start()
        local total = base + (start > 0 and (_CurTime() - start) or 0)
        local now = _ostime()

        DDIDB:Update(TABLE_NAME, {
        	time = total,
        	last_seen = now
        }, 'steamid = ?', { steamid }, function(data)
	        if (data.affected == 0) then
	            DDIDB:Insert(TABLE_NAME, {
	                steamid = steamid,
	                time = total,
	                last_seen = now,
	            })
	        end

	        -- After a mid-session save reset the baseline so the next
	        -- save does not double-count the current segment.
	        if (not final and _IsValid(pPlayer)) then
	            pPlayer:set_ddi_time(total)
	            pPlayer:set_ddi_time_start(_CurTime())

	            -- Keep the client in sync after the baseline shift.
	            DNet:Open('DanLib.Time.Sync')
	                :Float(total)
	                :Send(pPlayer)
	        end
	    end)
    end

    --  Internal load
    local function LoadPlayerTime(pPlayer)
        if (not _IsValid(pPlayer)) then
        	return
        end

        local steamid = pPlayer:SteamID()
        DDIDB:Select(TABLE_NAME, { 'time' }, 'steamid = ?', { steamid }, nil, 1, function(data)
            if (not _IsValid(pPlayer)) then
            	return
            end

            local saved = 0
            if (data.status and data.results and data.results[1]) then
                saved = _tonumber(data.results[1].time) or 0
            end

            pPlayer:set_ddi_time(saved)
            pPlayer:set_ddi_time_start(_CurTime())

            -- Send loaded time to the owning client.
            DNet:Open('DanLib.Time.Sync')
                :Float(saved)
                :Send(pPlayer)
        end, function(err)
            _ErrorNoHalt('[DanLib] Time: load failed for ' .. steamid .. ': ' .. _tostring(err) .. '\n')
            if _IsValid(pPlayer) then
                pPlayer:set_ddi_time(0)
                pPlayer:set_ddi_time_start(_CurTime())
            end
        end)
    end

    -- Hooks
    DHook:Add('InitPostEntity', 'DanLib.Time.Init', function()
        if DDIDB:IsConnected() then
            InitTable()
        else
            DDIDB:WaitForConnection(function(ok)
                if ok then
                	InitTable()
                else
                	_ErrorNoHalt('[DanLib] Time: DB never became ready\n')
                end
            end, 30)
        end
    end)

    DHook:Add('PlayerInitialSpawn', 'DanLib.Time.Load', function(pPlayer)
        DTimer:Simple(1, function()
            if _IsValid(pPlayer) then
            	LoadPlayerTime(pPlayer)
            end
        end)
    end)

    DHook:Add('PlayerDisconnected', 'DanLib.Time.Disconnect', function(pPlayer)
        SavePlayerTime(pPlayer, true)
    end)

    DTimer:Create('DanLib.Time.AutoSave', SAVE_INTERVAL, 0, function()
        for _, pPlayer in _ipairs(DPlayerUtil:GetAll()) do
            SavePlayerTime(pPlayer, false)
        end
    end)

    --- Overrides a player's time and immediately syncs to the DB and client.
    -- @param seconds (number): New total playtime in seconds.
    function DMetaPlayer:SetDDITime(seconds)
        seconds = _mathmax(0, _tonumber(seconds) or 0)
        self:set_ddi_time(seconds)
        self:set_ddi_time_start(_CurTime())
        SavePlayerTime(self, false)
    end

    --- Manually triggers an immediate save for this player.
    function DMetaPlayer:SaveDDITime()
        SavePlayerTime(self, false)
    end

    --- Server receives a request from a client: send back top N by playtime.
    -- Message: DanLib.Time.RequestTop
    --   UInt(8) → count (capped at 50)
    DNet:On('DanLib.Time.RequestTop', function(len, pPlayer)
        if (not _IsValid(pPlayer)) then
        	return
        end

        local count = _Clamp(DNet:UInt(8), 1, 50)
        DDIDB:Select(TABLE_NAME, { 'steamid', 'time' }, nil, nil, 'time DESC', count, function(data)
            if (not _IsValid(pPlayer)) then
            	return
            end

            local rows = (data.status and data.results) or { }
            DNet:Open('DanLib.Time.TopResult')
                :Tbl(rows)
                :Send(pPlayer)
        end)
    end)
end

if CLIENT then
    --- Server → client: baseline time was reset after a mid-session save.
    -- Updates the local player's NWFloats so get_total_ddi_time() stays correct.
    -- Message: DanLib.Time.Sync
    --   Float → new base time (seconds)
    DNet:On('DanLib.Time.Sync', function()
        local saved = DNet:Float()
        local pPlayer = LocalPlayer()
        if (not _IsValid(pPlayer)) then
        	return
        end

        pPlayer:set_ddi_time(saved)
        pPlayer:set_ddi_time_start(_CurTime())
    end)

    --- Server → client: response to DanLib.Time.RequestTop.
    -- Message: DanLib.Time.TopResult
    --   Tbl → array of { steamid (string), time (string) }
    --
    -- Usage: store the result and draw it in your HUD / panel.
    --   DanLib.Time.TopPlayers = { }
    --   DNet:On is already registered here; just read DanLib.Time.TopPlayers.
    DanLib.Time = DanLib.Time or { }
    DanLib.Time.TopPlayers = DanLib.Time.TopPlayers or { }

    DNet:On('DanLib.Time.TopResult', function()
        DanLib.Time.TopPlayers = DNet:Tbl()
    end)

    --- Sends a request to the server for the top N players by playtime.
    -- @param count (number): How many players to fetch (max 50, default 10).
    --
    -- Example:
    --   time.RequestTop(10) -- then read DanLib.Time.TopPlayers
    function DanLib.Time.RequestTop(count)
        count = _Clamp(_tonumber(count) or 10, 1, 50)
        DNet:Open('DanLib.Time.RequestTop')
            :UInt(count, 8)
            :Up()
    end
end
