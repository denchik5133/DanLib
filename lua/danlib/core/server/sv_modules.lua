/***
 *   @addon         DanLib
 *   @component     SV Module Version
 *   @license       MIT License
 *   @version       1.0.0
 *   @release_date  12/07/2026
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   Server-side module version fetching.
 *                  Fetches version data from GitHub (SSL works server-side),
 *                  caches it, and sends it to clients on request via DanLib.Net.
 *   
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         An active internet connection is required to verify the version.
 *                  Extracts update data from: https://raw.githubusercontent.com/denchik5133/DDI-Other-Informations/main/DDI/update.json
 */



local DBase = DanLib.Func
local DNet = DanLib.Net
local DHTTP = DanLib.HTTP
local DTimer = DanLib.Timer
local DNetworkUtil = DanLib.NetworkUtil

local _IsValid = IsValid
local _CurTime = CurTime
local _tostring = tostring
local _pairs = pairs
local _pcall = pcall
local _type = type

local updateLink = 'https://raw.githubusercontent.com/denchik5133/DDI-Other-Informations/main/DDI/update.json'
local CACHE_TTL = 300

local _cachedVersions = nil
local _cacheExpireTime = 0
local _fetchInProgress = false

local function NormalizeVersionData(data)
    local normalized = { }
    for k, v in _pairs(data) do
        if (_type(v) == 'table') then
            normalized[k] = v.version
        elseif (_type(v) == 'string') then
            normalized[k] = v
        end
    end
    return normalized
end

local function FetchVersions(callback)
    if _fetchInProgress then
        return
    end
    _fetchInProgress = true

    DHTTP:Request({
        url = updateLink,
        method = 'GET',
        success = function(code, body)
            _fetchInProgress = false
            if (code ~= 200) then
                DBase:PrintType('Warning', 'Module version fetch: HTTP ' .. _tostring(code))
                if callback then
                    callback(nil)
                end
                return
            end

            local ok, data = _pcall(util.JSONToTable, body)
            if (not ok or not data) then
                DBase:PrintType('Warning', 'Module version fetch: JSON parse failed')
                if callback then
                    callback(nil)
                end
                return
            end

            _cachedVersions  = NormalizeVersionData(data)
            _cacheExpireTime = _CurTime() + CACHE_TTL

            if callback then
                callback(_cachedVersions)
            end
        end,
        failed = function(err)
            _fetchInProgress = false
            DBase:PrintType('Warning', 'Module version fetch failed: ' .. _tostring(err))
            if callback then
                callback(nil)
            end
        end
    })
end

local function _SendVersionsToClient(ply, versions)
    if (not _IsValid(ply)) then
        return
    end

    local json = versions and DNetworkUtil:TableToJSON(versions) or '{}'
    DNet:Open('DanLib.Modules.VersionData')
        :Str(json)
        :Send(ply)
end

DNet:On('DanLib.Modules.RequestVersions', function(len, ply)
    if (not _IsValid(ply)) then
        return
    end

    local now = _CurTime()
    if (_cachedVersions and now < _cacheExpireTime) then
        _SendVersionsToClient(ply, _cachedVersions)
        return
    end

    FetchVersions(function(versions)
        _SendVersionsToClient(ply, versions)
    end)
end)

DTimer:Simple(10, function()
    FetchVersions(nil)
end)
