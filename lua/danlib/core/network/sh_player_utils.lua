/***
 *   @addon         DanLib
 *   @component     Player util
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
 *   @description   Utility wrapper for the GMod player.* library. Covers all 12 standard
 *                  player functions with consistent argument validation.
 *                  Usable on both SERVER and CLIENT.
 *
 *   @functions
 *                  - CreateNextBot: Create a bot player with a given name (server-only).
 *                  - GetAll: Return a table of all currently connected players.
 *                  - GetBots: Return a table of all bot players.
 *                  - GetByAccountID: Find a player by their Steam account ID.
 *                  - GetByID: Find a player by their entity index.
 *                  - GetBySteamID: Find a player by their legacy SteamID (STEAM_0:...).
 *                  - GetBySteamID64: Find a player by their 64-bit SteamID.
 *                  - GetByUniqueID: Find a player by their GMod unique ID. [DEPRECATED]
 *                  - GetCount: Return the number of connected players.
 *                  - GetCountConnecting: Return the number of players currently connecting.
 *                  - GetHumans: Return a table of all human (non-bot) players.
 *                  - Iterator: Return a stateless iterator over all connected players.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



DanLib.PlayerUtil = DanLib.PlayerUtil or { }
local DPlayerUtil = DanLib.PlayerUtil

local _assert = assert
local _type = type

--- Creates a bot player with the given name (server-only).
-- @param name (string): The display name for the bot.
-- @return (Player|nil): The created bot Player entity, or nil on failure.
function DPlayerUtil:CreateNextBot(name)
    _assert(_type(name) == 'string', 'DPlayerUtil:CreateNextBot — name must be a string')
    return player.CreateNextBot(name)
end

--- Returns a sequential table of all currently connected players (humans and bots).
-- @return (table): All connected Player entities.
function DPlayerUtil:GetAll()
    return player.GetAll()
end

--- Returns a sequential table of all bot players.
-- @return (table): All bot Player entities.
function DPlayerUtil:GetBots()
    return player.GetBots()
end

--- Finds a player by their Steam account ID (the numeric part of a SteamID).
-- @param accountID (number): The Steam account ID to search for.
-- @return (Player|nil): The matching Player entity, or nil if not found.
function DPlayerUtil:GetByAccountID(accountID)
    _assert(_type(accountID) == 'number', 'DPlayerUtil:GetByAccountID — accountID must be a number')
    return player.GetByAccountID(accountID)
end

--- Finds a player by their entity index.
-- @param index (number): The entity index of the player.
-- @return (Player|nil): The matching Player entity, or nil if not found.
function DPlayerUtil:GetByID(index)
    _assert(_type(index) == 'number', 'DPlayerUtil:GetByID — index must be a number')
    return player.GetByID(index)
end

--- Finds a player by their legacy SteamID string (e.g. STEAM_0:1:12345).
-- @param steamID (string): The legacy SteamID to search for.
-- @return (Player|nil): The matching Player entity, or nil if not found.
function DPlayerUtil:GetBySteamID(steamID)
    _assert(_type(steamID) == 'string', 'DPlayerUtil:GetBySteamID — steamID must be a string')
    return player.GetBySteamID(steamID)
end

--- Finds a player by their 64-bit SteamID string.
-- @param steamID64 (string): The 64-bit SteamID to search for.
-- @return (Player|nil): The matching Player entity, or nil if not found.
function DPlayerUtil:GetBySteamID64(steamID64)
    _assert(_type(steamID64) == 'string', 'DPlayerUtil:GetBySteamID64 — steamID64 must be a string')
    return player.GetBySteamID64(steamID64)
end

--- Finds a player by their GMod unique ID (a CRC of their SteamID).
-- @deprecated Use GetBySteamID or GetBySteamID64 instead.
-- @param uniqueID (string): The unique ID string to search for.
-- @return (Player|nil): The matching Player entity, or nil if not found.
function DPlayerUtil:GetByUniqueID(uniqueID)
    _assert(_type(uniqueID) == 'string', 'DPlayerUtil:GetByUniqueID — uniqueID must be a string')
    return player.GetByUniqueID(uniqueID)
end

--- Returns the number of players currently connected to the server.
-- @param noFake (boolean): If true, exclude fake players (bots). Defaults to false.
-- @return (number): The connected player count.
function DPlayerUtil:GetCount(noFake)
    return player.GetCount(noFake or false)
end

--- Returns the number of players currently in the process of connecting (not yet fully joined).
-- @return (number): The connecting player count.
function DPlayerUtil:GetCountConnecting()
    return player.GetCountConnecting()
end

--- Returns a sequential table of all human (non-bot) players.
-- @return (table): All human Player entities.
function DPlayerUtil:GetHumans()
    return player.GetHumans()
end

--- Returns a stateless iterator that steps through all connected players.
-- Equivalent to ipairs(player.GetAll()) but uses the engine iterator directly.
-- @return (function): An iterator function suitable for use in a for loop.
function DPlayerUtil:Iterator()
    return player.Iterator()
end
