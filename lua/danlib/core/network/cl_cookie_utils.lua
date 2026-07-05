/***
 *   @addon         DanLib
 *   @component     Cookie utils
 *   @license       MIT License
 *   @version       1.0.2
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   This file defines the CookieUtils library, a collection of utility functions for managing cookies
 *                  in Garry's Mod. These functions simplify the process of setting, getting, and deleting cookies,
 *                  as well as providing additional functionality for cookie management.
 *
 *   @functions
 *                  - Delete: Removes a cookie by its key.
 *                  - GetNumber: Retrieves a cookie value as a number, with an optional default value.
 *                  - GetString: Retrieves a cookie value as a string, with an optional default value.
 *                  - Set: Sets a cookie value by its key.
 *                  - Exists: Checks if a cookie exists by its key.
 *                  - GetAll: Returns a table containing all cookies tracked by this session.
 *                  - ClearAll: Deletes all cookies tracked by this session.
 *                  - SetWithTTL: Sets a cookie with a specified time-to-live (TTL) after which it will be deleted.
 *
 *   @example
 *                  - To set a cookie: DanLib.CookieUtils:Set('username', 'JohnDoe')
 *                  - To get a cookie value: local username = DanLib.CookieUtils:GetString('username', 'Guest')
 *                  - To check if a cookie exists: if DanLib.CookieUtils:Exists('username') then ... end
 *                  - To delete a cookie: DanLib.CookieUtils:Delete('username')
 *                  - To clear all cookies: DanLib.CookieUtils:ClearAll()
 *                  - To set a cookie with TTL: DanLib.CookieUtils:SetWithTTL('session', 'abc123', 300)
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



DanLib.CookieUtils = DanLib.CookieUtils or { }
local DCookieUtils = DanLib.CookieUtils

-- Tracks keys set via this library so GetAll / ClearAll work correctly.
-- Keys are stored as a set (keys[name] = true) to avoid duplicates.
DCookieUtils.keys = DCookieUtils.keys or { }

local _tostring = tostring
local _assert = assert
local _pairs = pairs
local _type = type

local function validateKey(key)
    _assert(_type(key) == 'string', 'DanLib.CookieUtils: key must be a string')
end

local function validateValue(value)
    _assert(_type(value) == 'string' or _type(value) == 'number', 'DanLib.CookieUtils: value must be a string or a number')
end

--- Deletes a cookie by key.
-- @param key (string): The key of the cookie to delete.
function DCookieUtils:Delete(key)
    validateKey(key)
    cookie.Delete(key)
    self.keys[key] = nil
end

--- Retrieves a cookie value as a number.
-- @param name (string): The name of the cookie.
-- @param default (number|nil): Default value if the cookie does not exist.
-- @return (number): The cookie value or the default.
function DCookieUtils:GetNumber(name, default)
    validateKey(name)
    return cookie.GetNumber(name, default)
end

--- Retrieves a cookie value as a string.
-- @param name (string): The name of the cookie.
-- @param default (string|nil): Default value if the cookie does not exist.
-- @return (string): The cookie value or the default.
function DCookieUtils:GetString(name, default)
    validateKey(name)
    return cookie.GetString(name, default)
end

--- Sets a cookie value.
-- Overwrites any existing cookie with the same key.
-- @param key (string): The key of the cookie.
-- @param value (string|number): The value to store.
function DCookieUtils:Set(key, value)
    validateKey(key)
    validateValue(value)
    cookie.Set(key, _tostring(value))
    self.keys[key] = true
end

--- Checks whether a cookie with the given key exists.
-- A cookie is considered to exist when its stored value is not nil.
-- @param key (string): The key of the cookie.
-- @return (boolean): true if the cookie exists, false otherwise.
function DCookieUtils:Exists(key)
    validateKey(key)
    return cookie.GetString(key, nil) ~= nil
end

--- Returns a table of all cookies tracked by this library in the current session.
-- Only cookies set via DanLib.CookieUtils:Set / SetWithTTL are included.
-- @return (table): A key → value string table of all tracked cookies.
function DCookieUtils:GetAll()
    local allCookies = { }
    for key in _pairs(self.keys) do
        if self:Exists(key) then
            allCookies[key] = cookie.GetString(key)
        end
    end
    return allCookies
end

--- Deletes all cookies tracked by this library in the current session.
function DCookieUtils:ClearAll()
    for key in _pairs(self.keys) do
        cookie.Delete(key)
    end
    self.keys = { }
end

--- Sets a cookie that is automatically deleted after a given number of seconds.
-- The key is removed from the tracking table when the TTL expires.
-- @param key (string): The key of the cookie.
-- @param value (string|number): The value to store.
-- @param ttl (number): Lifetime of the cookie in seconds.
function DCookieUtils:SetWithTTL(key, value, ttl)
    validateKey(key)
    validateValue(value)
    _assert(_type(ttl) == 'number' and ttl > 0, 'DanLib.CookieUtils: ttl must be a positive number')

    cookie.Set(key, _tostring(value))
    self.keys[key] = true

    timer.Simple(ttl, function()
        cookie.Delete(key)
        DCookieUtils.keys[key] = nil
    end)
end
