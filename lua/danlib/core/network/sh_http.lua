/***
 *   @addon         DanLib
 *   @component     HTTP
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
 *   @description   HTTP utility for DanLib. Wraps GMod's http.Fetch, http.Post and
 *                  HTTP() with consistent validation and error handling.
 *                  Use Request() for full control: custom method, headers, and body.
 *
 *   @functions
 *                  - Fetch: Send a GET request and receive the response body.
 *                  - Post: Send a POST request with form-encoded key/value data.
 *                  - Request: Full HTTP request (GET, POST, PUT, DELETE, PATCH, etc.) with custom headers and raw body support.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



DanLib.HTTP = DanLib.HTTP or { }
local DHTTP = DanLib.HTTP

local _assert = assert
local _type = type
local _tostring = tostring
local _ErrorNoHalt = ErrorNoHalt


--- Sends a GET request to the given URL.
-- On success, calls successCallback(body, len, headers, code).
-- On failure, calls failureCallback(err) if provided, otherwise logs via ErrorNoHalt.
-- @param url (string): The URL to fetch.
-- @param successCallback (function): Called with (body, len, headers, code) on success.
-- @param failureCallback (function): Optional. Called with (err) on failure.
-- @return (nil)
function DHTTP:Fetch(url, successCallback, failureCallback)
    _assert(_type(url) == 'string', 'DanLib.HTTP:Fetch — url must be a string')
    _assert(_type(successCallback) == 'function', 'DanLib.HTTP:Fetch — successCallback must be a function')

    http.Fetch(url, successCallback, function(err)
        if failureCallback then
            failureCallback(err)
        else
            _ErrorNoHalt('DanLib.HTTP:Fetch failed (' .. url .. '): ' .. _tostring(err) .. '\n')
        end
    end)
end

--- Sends a POST request with form-encoded key/value data to the given URL.
-- On success, calls successCallback(body, len, headers, code).
-- On failure, calls failureCallback(err) if provided, otherwise logs via ErrorNoHalt.
-- @param url (string): The URL to post to.
-- @param data (table): Key/value pairs to send as the POST body.
-- @param successCallback (function): Called with (body, len, headers, code) on success.
-- @param failureCallback (function): Optional. Called with (err) on failure.
-- @return (nil)
function DHTTP:Post(url, data, successCallback, failureCallback)
    _assert(_type(url) == 'string', 'DanLib.HTTP:Post — url must be a string')
    _assert(_type(data) == 'table', 'DanLib.HTTP:Post — data must be a table')
    _assert(_type(successCallback) == 'function', 'DanLib.HTTP:Post — successCallback must be a function')

    http.Post(url, data, successCallback, function(err)
        if failureCallback then
            failureCallback(err)
        else
            _ErrorNoHalt('DanLib.HTTP:Post failed (' .. url .. '): ' .. _tostring(err) .. '\n')
        end
    end)
end

--- Sends a full HTTP request with custom method, headers, and raw body.
-- Wraps GMod's HTTP() function. Use this for PUT, DELETE, PATCH, or any request
-- that needs custom headers (e.g. Authorization, Content-Type) or a raw JSON body.
-- @param options (table): Request options:
--   • url (string): Required. The target URL.
--   • method (string): HTTP method: 'GET', 'POST', 'PUT', 'DELETE', 'PATCH'. Defaults to 'GET'.
--   • headers (table): Optional. Key/value pairs sent as request headers.
--   • body (string): Optional. Raw request body (e.g. a JSON string).
--   • type (string): Optional. Content-Type header shorthand (e.g. 'application/json').
--   • success (function): Optional. Called with (code, body, headers) on success.
--   • failed (function): Optional. Called with (err) on failure.
-- @return (nil)
--
-- @xample
--      DanLib.HTTP:Request({
--          url = 'https://api.example.com/items/5',
--          method = 'DELETE',
--          headers = { ['Authorization'] = 'Bearer mytoken' },
--          success = function(code, body, headers)
--              print('Deleted, status:', code)
--          end,
--          failed = function(err)
--              print('Request failed:', err)
--          end,
--      })
function DHTTP:Request(options)
    _assert(_type(options) == 'table', 'DanLib.HTTP:Request — options must be a table')
    _assert(_type(options.url) == 'string', 'DanLib.HTTP:Request — options.url must be a string')

    local url = options.url

    HTTP({
        url = url,
        method = options.method or 'GET',
        headers = options.headers or { },
        body = options.body,
        type = options.type,
        success = options.success or function() end,
        failed = options.failed or function(err)
            _ErrorNoHalt('DanLib.HTTP:Request failed (' .. url .. '): ' .. _tostring(err) .. '\n')
        end,
    })
end
