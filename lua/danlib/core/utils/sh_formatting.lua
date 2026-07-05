/***
 *   @addon         DanLib
 *   @component     Formatting
 *   @license       MIT License
 *   @version       1.6.0
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
local DHTTP = DanLib.HTTP
local DTable = DanLib.Table
local DTimer = DanLib.Timer
local DPlayerUtil = DanLib.PlayerUtil
local DNetworkUtil = DanLib.NetworkUtil

local _type = type
local _error = error
local _pcall = pcall
local _pairs = pairs
local _ipairs = ipairs
local _ostime = os.time
local _osdate = os.date
local _floor = math.floor
local _abs = math.abs
local _max = math.max
local _bitband = bit.band
local _bitrshift = bit.rshift
local _find = string.find
local _byte = string.byte
local _format = string.format
local _tostring = tostring
local _tonumber = tonumber
local _GetPlayerName = steamworks.GetPlayerName

do
    --- Formats the unit of time into a string including singular and plural.
    -- @param value: The numeric value of the time.
    -- @param singular: Format for singular.
    -- @param plural: Format for plural.
    -- @param short: A logical value indicating whether to use the short format.
    -- @return: Formatted string.
    local function _formatUnit(value, singular, plural, short)
        return value .. (short and (value > 1 and 's' or '') or (value > 1 and plural or singular))
    end

    --- Returns the current time in UTC format as the number of seconds since the beginning of the epoch (Unix time).
    -- @return: Current time in seconds (Unix time).
    function DBase:UTCTime() 
        return _ostime(_osdate('!*t'))
    end

    -- Returns the current date and time in the format "day.month.year hours:minutes:seconds".
    -- @return: A formatted string with the current date and time.
    function DBase:DateStamp()
        local t = _osdate('*t')
        return _format('%s.%s.%s  %02i:%02i:%02i', t.day, t.month, t.year, t.hour, t.min, t.sec)
    end

    --- Formats the time in seconds into a more readable form.
    -- @param time: Time in seconds.
    -- @param short: (optional bool) When true, only the largest unit is shown
    --               (e.g. "2m" instead of "2m 15s"). Useful for compact UI labels.
    -- @return: Formatted string with time components.
    function DBase:FormatTime(time, short)
        if (not time) then
            return
        end

        local seconds = time % 60
        time = _floor(time / 60)

        local minutes = time % 60
        time = _floor(time / 60)

        local hours = time % 24
        time = _floor(time / 24)

        local days = time % 7
        local weeks = _floor(time / 7)

        if short then
            if (weeks > 0) then
                return _format('%iw', weeks)
            end

            if (days > 0) then
                return _format('%id', days)
            end

            if (hours > 0) then
                return _format('%ih', hours)
            end

            if (minutes > 0) then
                return _format('%im', minutes)
            end
            
            return _format('%is', seconds)
        end

        if (weeks > 0) then
            return _format('%iw %id %ih %im %is', weeks, days, hours, minutes, seconds)
        elseif (days > 0) then
            return _format('%id %ih %im %is', days, hours, minutes, seconds)
        elseif (hours > 0) then
            return _format('%ih %im %is', hours, minutes, seconds)
        elseif (minutes > 0) then
            return _format('%im %is', minutes, seconds)
        end

        return _format('%is', seconds)
    end

    --- Converts seconds to a more convenient unit of time.
    -- @param d: The number of seconds.
    -- @param short: A logical value indicating whether to use the short format.
    -- @return: A formatted string with units of time.
    function DBase:SecondsTo(d, short)
        short = short or false
        d = _max(0, _floor(d))

        local tbl = { }
        local periods = {
            { 31556926, 'year', 'years' },
            { 2678400, 'month', 'months' },
            { 86400, 'day', 'days' },
            { 3600, 'hour', 'hours' },
            { 60, 'minute', 'minutes' },
            { 1, 'second', 'seconds' }
        }

        for _, period in _ipairs(periods) do
            local value = _floor(d / period[1])
            if (value > 0) then
                DTable:Add(tbl, _formatUnit(value, period[2], period[3], short))
                d = d % period[1]
            end
        end

        return DTable:Concat(tbl, ', ')
    end

    --- Determines how much time has elapsed since the specified timestamp.
    -- @param timestamp: Timestamp in seconds.
    -- @return: A formatted string indicating how much time has elapsed since the specified timestamp.
    function DBase:FormatHammerTime(timestamp)
        local diff = _ostime() - _tonumber(timestamp)
        local periods = {
            { 60, 'second', 'seconds' },
            { 60, 'minute', 'minutes' },
            { 24, 'hour', 'hours' },
            { 30, 'day', 'days' },
            { 12, 'month', 'months' },
            { math.huge, 'year', 'years' }
        }

        for i, period in _ipairs(periods) do
            if (diff < period[1]) then
                local count = _floor(diff)
                return _format('%d %s ago', count, count == 1 and period[2] or period[3])
            end
            diff = diff / period[1]
        end

        return 'a few years ago'
    end
end

--- Encodes a string for use in the URL.
-- @param str: String to encode.
-- @return: Encoded string.
function DBase:UrlEncode(str)
    if str then
        return str:gsub('([^%w])', function(c)
            return _format('%%%02X', _byte(c))
        end)
    else
        return str
    end
end

-- Helper function to create a deep copy of a table
function DBase:FullCopy(tab)
    if (not tab) then
        return nil
    end

    local res = { }
    for k, v in _pairs(tab) do
        if (_type(v) == 'table') then
            res[k] = table.FullCopy(v)
        elseif (_type(v) == 'Vector') then
            res[k] = Vector(v.x, v.y, v.z)
        elseif (_type(v) == 'Angle') then
            res[k] = Angle(v.p, v.y, v.r)
        else
            res[k] = v
        end
    end
    return res
end

--- Removes spaces at the beginning and end of the string.
-- @param str string: Input string from which to remove spaces.
-- @return string: String with no spaces at the beginning and end.
function DBase:TrimWhitespace(str)
    return str:match('^%s*(.-)%s*$')
end

--- Gets the translated string via the Google Translate API.
-- @param lang: The language code for the target translation (default is 'en').
-- @param inputString: String to translate (defaults to an empty string).
-- @param callback: Function to be called with the translation result.
--                  It will receive either a translated string or an error message.
function DBase:GetTranslatedString(lang, inputString, callback)
    -- Set default values for the parameters
    lang = lang or 'en'
    inputString = inputString or ''

    -- Immediately return the original string if the language is English or the input string is empty
    if (lang == 'en' or inputString == '') then
        callback(inputString)
        return
    end

    -- Prepare URL for API request
    -- Use URL encoding for the input string
    local urlFetch = _format('https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=%s&dt=t&q=%s', lang, self:UrlEncode(inputString))

    -- Getting a transfer from the API
    DHTTP:Fetch(urlFetch, function(responseBody, responseLen, headers, successCode)
        -- Парсим JSON-ответParsing JSON response
        local jsonTable = DanLib.NetworkUtil:JSONToTable(responseBody)
        -- Check if the answer contains valid translation data
        if (jsonTable and jsonTable[1] and jsonTable[1][1] and jsonTable[1][1][1]) then
            callback(jsonTable[1][1][1]) -- Callback with translated string
        else
            callback(false, 'INVALID TABLE') -- Return an error if the answer is invalid
        end
    end, function(errorMsg)
        callback(false, errorMsg) -- Return an error message if the request failed
    end)
end

--- Creates a simple timer that calls the given function after the specified time.
-- @param time number: The time in seconds after which the function will be called. The default is 0.
-- @param func function: The function that will be called after the time has elapsed. Must be a function.
-- @return void
-- @throws error If time is not a valid number or func is not a function.
function DBase:TimerSimple(time, func)
    DTimer:Simple(time, func)
end

do
    --- Checks if the provided SteamID64 is valid.
    -- @param id64 The SteamID64 to check.
    -- @return true if valid, false otherwise.
    function DBase:IsValidSteamID64(id64)
        -- Check if id64 is a number and has 17 digits
        return _type(id64) == 'number' and id64 >= 76561197960265728 and id64 <= 76561197960265728 + 9999999999999999
    end

    --- Finds a player by their name.
    -- @param name The name of the player to search for.
    -- @return The player object if found, otherwise false.
    function DBase:FindPlayer(name)
        if (not name) then
            return fals
        end

        for k, player in _pairs(DPlayerUtil:GetAll()) do
            if _find(player:Name(), name, 1, true) then
                return player
            end
        end

        return false
    end


    local pPlayerAvatar = { }

    --- Fetches the Steam avatar for a given player ID.
    -- @param id The Steam ID of the player.
    -- @param sCback The callback function to handle the avatar URL.
    function DBase:SteamAvatar(id, sCback)
        if pPlayerAvatar[id] then
            return sCback(pPlayerAvatar[id])
        end

        DHTTP:Fetch('https://steamcommunity.com/profiles/' .. id .. '/?xml=1', function(xml)
            pPlayerAvatar[id] = xml:match('<avatarFull><%!%[CDATA%[(.-)%]%]></avatarFull>')
            sCback(pPlayerAvatar[id])
        end)
    end

    --- Retrieves the Steam name for a given Steam ID.
    -- @param id The Steam ID to look up.
    -- @return The player's name or 'unknown' if not found.
    function DBase:SteamName(id)
        if (not id) then
            return 'unknown'
        end

        local id64 = DNetworkUtil:SteamIDTo64(id)
        if (not id64) then
            return 'unknown'
        end

        local name = _GetPlayerName(id64)
        return name or 'unknown'
    end

    --- Checks if a given Steam ID is valid.
    -- @param id The Steam ID to validate.
    -- @return True if the Steam ID is valid, otherwise false.
    function DBase:IsValidSteamID(id)
        id = id:Trim():upper()
        if id:find('STEAM_') then
            return DNetworkUtil:SteamIDFrom64(DNetworkUtil:SteamIDTo64(id)) == id
        else
            return DNetworkUtil:SteamIDTo64(DNetworkUtil:SteamIDFrom64(id)) == id
        end
    end

    --- Gets the Steam ID64 of a player.
    -- @param pPlayer The player object.
    -- @return The player's Steam ID64 or their name if they are a bot. 
    function DBase:SteamID64(pPlayer)
        if pPlayer:IsBot() then 
            return pPlayer:GetName()
        else
            return pPlayer:SteamID64()
        end
    end
end

--- Gets the server address in "IP:port" format.
-- @return: A string representing the server address in "IP:port" format.
function DBase:GetAddress()
    -- Get the IP and port string from the settings
    local hostIP = GetConVarString('hostip')
    local hostPort = GetConVarString('hostport')
    
    -- Convert the IP string to a number
    local address = _tonumber(hostIP)

    -- If no address is specified, return the default local address
    if (not address) then
        return '127.0.0.1:' .. hostPort
    end

    -- Break the address into octets
    local ip = {
        _bitrshift(_bitband(address, 0xFF000000), 24),
        _bitrshift(_bitband(address, 0x00FF0000), 16),
        _bitrshift(_bitband(address, 0x0000FF00), 8),
        _bitband(address, 0x000000FF)
    }

    -- Combine the octets into a string and add the port
    return DTable:Concat(ip, '.') .. ':' .. hostPort
end

--- Handles argument errors and sends a message to the player.
-- @param pPlayer (Player): The player to whom the message will be sent.
-- @param t (any): Argument to check.
function DBase:ArgError(pPlayer, t)
    local message = not t and self:L('#wrong.arg') or self:L('#access.ver')
    self:SendMessage(pPlayer, DANLIB_TYPE_ERROR, message)
end

do
    --- Escapes a string for use in JSON.
    -- @param str (string): String to be escaped.
    -- @return (string): The escaped string.
    function DBase:JSON(str)
        return (str:gsub('\\', '\\\\'):gsub('"', '\\"'))
    end

    -- function to retrieve JSON content from a URL
    -- @param url (string): URL to retrieve the data
    -- @param callback (function): Callback function to be called with the result
    function DBase:FetchApiContent(url, callback)
        local result = { } -- Table for storing the result

        -- Use pcall for error handling
        local success, err = _pcall(function()
            -- Use Fetch with callback
            DanLib.HTTP:Fetch(url, function(response, length, headers, code)
                if (code ~= 200) then
                    return
                end

                if response then
                    result = DanLib.NetworkUtil:JSONToTable(response)
                    if callback then
                        callback(result)
                    end -- Calling a callback with a result
                else
                    self:PrintError('Data not received.')
                    if callback then
                        callback({ })
                    end -- Calling a callback with an empty table
                end
            end)
        end)

        if (not success) then
            self:PrintError('On receipt of data:', _tostring(err))
            if callback then
                callback({ })
            end -- Calling a callback with an empty table
        end
    end
end


--- Finds a player by his Steam ID.
-- @param ID (string): Steam ID of the player.
-- @return (Player|nil): Player with the specified Steam ID or nil if not found.
function DBase:AllPlayer(ID)
    for _, player in _pairs(DPlayerUtil:GetAll()) do
        if (player:SteamID() == ID) then
            return player
        end
    end
    return nil -- Explicitly return nil if no player is found
end


if SERVER then
    -- Stores timers for players
    function DBase:GetTimer(pPlayer, sWep)
        -- Initialising the timer table if it does not already exist
        self.Timers = self.Timers or { }
        local timers = self.Timers
        
        -- Initialise the timer for a player if it does not already exist
        local playerID = pPlayer:SteamID()
        timers[playerID] = timers[playerID] or { }

        -- Returns the value of the timer or 0 if no timer is set
        return timers[playerID][sWep] or 0
    end

    --- Sets the timer for the player and weapon
    -- @param pPlayer: The player for whom the timer is set
    -- @param sWep: Name of the weapon for which the timer is set
    -- @param nTime: Time in seconds for which the timer is set
    function DBase:SetTimer(pPlayer, sWep, nTime)
        self.Timers = self.Timers or { }
        local timers = self.Timers
        
        -- Initialise the timer for a player if it does not already exist
        local playerID = pPlayer:SteamID()
        timers[playerID] = timers[playerID] or { }

        -- Sets the timer
        timers[playerID][sWep] = _ostime() + nTime
    end
end

--- Converts a number into a human-readable format with 'k' for thousands.
-- @param num (number): The number to convert.
-- @return (string): The formatted string representing the number in 'k' format.
function DBase:SimpleSum(num)
    local k = 0

    -- Reduce the number by a factor of 1000 until it's less than 1
    while num * 0.001 >= 1 do
        k = k + 1
        num = num * 0.001
    end

    -- Return the formatted number with 'k' suffix
    return sub(num, 1, 3) .. rep('k', k)
end

--- Formats a number into a human-readable string with appropriate suffixes.
-- @param num (number): The number to format.
-- @return (string): The formatted string with 'k' for thousands and 'm' for millions.
function DBase:FormatNumber(num)
    if (num >= 1000000) then
        return _format('%.1fм', num / 1000000) -- Format for millions
    elseif (num >= 1000) then
        return _format('%.1fк', num / 1000) -- Format for thousands
    else
        return _tostring(num) -- Return as string if less than 1000
    end
end

--- Function for processing bindings input
-- @param input (string|number): The key input, either as a string (key name) or a number (index).
-- @param bannedKeys (table): A table containing keys that are banned from being used.
-- @return (string|number): Returns the key name if valid, the index as a string, or 'NONE' if invalid or banned.
function DBase:ProcessBind(input, bannedKeys)
    -- Guard: nil means no key bound; return 0 (KEY_NONE) immediately.
    if (input == nil) then
        return 0
    end

    -- Validate input types
    if (_type(input) ~= 'string' and _type(input) ~= 'number') then
        _error('Invalid input type: expected string or number')
    end

    if (bannedKeys and _type(bannedKeys) ~= 'table') then
        _error('Invalid bannedKeys type: expected table')
    end

    -- Check if input is a number
    local index = _tonumber(input)
    if index then
        -- If input is a number, check that the index is correct
        if (index >= 0 and index < #DanLib.KEY_BINDS) then
            local keyName = DanLib.KEY_BINDS[index] -- Get the key name (indexes start from 0)
            if (bannedKeys and DTable:HasValue(bannedKeys, keyName)) then
                return 'NONE' -- Return 'NONE' if the key is banned
            end
            return keyName
        else
            return 'NONE' -- Return 'NONE' if the index is out of bounds
        end
    else
        -- If input is a string (key name), look for an exact match
        for i, key in _ipairs(DanLib.KEY_BINDS) do
            if (key == input) then
                if (bannedKeys and DTable:HasValue(bannedKeys, key)) then
                    return 'NONE' -- Return 'NONE' if the key is banned
                end
                return _tostring(i) -- Return key number (indexes start from 0)
            end
        end
        return 'NONE' -- Return 'NONE' if no match found
    end
end
