/***
 *   @addon         DanLib
 *   @component     Admin
 *   @license       MIT License
 *   @version       2.4.1
 *   @release_date  07/12/2024
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Enhanced config system with validation,
 *                  transactions, conditional logging, and security
 *
 *   @security      Input Validation:
 *                  - Blocks: RunString, CompileString, SQL injection, file operations
 *                  - Sanitizes: null bytes, control characters, excessive whitespace
 *                  - Validates: string length, number ranges, color values (0-255)
 *                  - Logs: all security violations with player IP and timestamp
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DNet = DanLib.Net
local DHook = DanLib.Hook
local DTable = DanLib.Table
local DFileUtil = DanLib.FileUtil
local DPlayerUtil = DanLib.PlayerUtil
local DNetworkUtil = DanLib.NetworkUtil

local _pairs = pairs
local _ipairs = ipairs
local _mathFloor = math.floor
local _osDate = os.date
local _IsValid = IsValid
local _print = print
local _type = type
local _istable = istable
local _CurTime = CurTime
local _tonumber = tonumber
local _tostring = tostring
local _strFormat = string.format
local _strgsub = string.gsub
local _strmatch = string.match
local _strfind = string.find
local _strlen = string.len

-- Dangerous Lua patterns that could be used for code injection
local DANGEROUS_PATTERNS = {
    -- Code execution
    'RunString', 'CompileString', 'RunStringEx', 'include', 'require',
    'loadstring', 'load', 'dofile',
    -- Debug manipulation
    'debug%.',
    -- Environment manipulation
    'getfenv', 'setfenv', 'rawget', 'rawset', '_G%[',
    -- SQL
    'sql%.Query', 'sql%.QueryValue', 'sql%.Begin', 'sql%.Commit',
    'TMysql', 'mysqloo',
    -- File operations (dangerous)
    'file%.Delete', 'file%.Write', 'file%.Append',
    -- Network
    'http%.Fetch', 'http%.Post', 'HTTP%(',
    -- Command execution
    'concommand%.Add', 'game%.ConsoleCommand',
    -- Hook/Timer manipulation
    'hook%.Add', 'hook%.Remove',
    'timer%.Create', 'timer%.Simple',
    -- Path traversal
    '%.%./.*',
    -- Multiline strings
    '%[%[.*RunString', '%[%[.*CompileString',
    -- Function definitions (We do NOT block the entire pattern, only with dangerous content.)
    'function%s*%(.*RunString', 'function%s*%(.*timer%.Create',
}

-- CONSTANTS
local ABSOLUTE_MAX_STRING_LENGTH = 10000 -- Prevent DoS attacks with huge strings
local MAX_SECURITY_VIOLATIONS = 5 -- Kick player after this many violations
local RATE_LIMIT_COOLDOWN = 1 -- Seconds between config save requests
local NOTIFICATION_DURATION_SHORT = 6 -- Seconds for short notifications
local NOTIFICATION_DURATION_LONG = 10 -- Seconds for detailed error messages

-- TRACKING TABLES
local securityViolations = { } -- Track security violations per player
local rateLimitTracker = { } -- Track last request time per player

-- logs
local function _errorLog(message)
    DBase:Print('[CRITICAL ERROR] ' .. message)
end

-- DEBUG LOGGING SYSTEM
local function _debugLog(level, message)
    if (not DanLib.CONFIG or not DanLib.CONFIG.BASE or not DanLib.CONFIG.BASE.Debugg) then
        return
    end

    local prefix = 'DanLib Config'
    local colorCode = ''

    if (level == 'ERROR') then
        colorCode = '[ERROR]'
    elseif (level == 'WARNING') then
        colorCode = '[WARNING]'
    elseif (level == 'SUCCESS') then
        colorCode = '[SUCCESS]'
    elseif (level == 'INFO') then
        colorCode = '[INFO]'
    end

    DBase:PrintType(prefix, _strFormat('%s %s', colorCode, message))
end

--- Sanitize and validate input value
-- @param value (any): Value to sanitize
-- @param valueType (string): Type of the value
-- @param module (string): Module name
-- @param variable (string): Variable name
-- @return (bool, any, string|nil): isValid, sanitizedValue, errorMessage
local function _sanitizeAndValidate(value, valueType, module, variable)
    -- STRING VALIDATION & SANITIZATION
    if (valueType == 'String' or valueType == 'Text') then
        if (_type(value) ~= 'string') then
            return false, nil, 'Value must be a string'
        end

        -- Check absolute max length BEFORE expensive pattern matching
        if (_strlen(value) > ABSOLUTE_MAX_STRING_LENGTH) then
            return false, nil, _strFormat('String exceeds absolute maximum (%d characters)', ABSOLUTE_MAX_STRING_LENGTH)
        end

        -- Get max length from metadata (if defined)
        local maxLen = nil
        if (DanLib.ConfigMeta and DanLib.ConfigMeta[module] and DanLib.ConfigMeta[module].Variables[variable]) then
            maxLen = DanLib.ConfigMeta[module].Variables[variable].MaxLength
        end

        -- Apply length validation only if MaxLength is set
        if (maxLen and _strlen(value) > maxLen) then
            return false, nil, _strFormat('String too long (max %d characters)', maxLen)
        end

        -- Check for dangerous patterns
        for _, pattern in _ipairs(DANGEROUS_PATTERNS) do
            if _strmatch(value, pattern) then
                _errorLog(_strFormat('SECURITY: Blocked dangerous pattern "%s" in %s.%s', pattern, module, variable))
                return false, nil, 'Input contains forbidden patterns'
            end
        end

        -- Remove null bytes and control characters
        if (valueType == 'Text') then
            value = _strgsub(value, '[%z\1-\8\11-\12\14-\31]', '')
        else
            value = _strgsub(value, '[%z\1-\31]', '')
        end

        -- Trim whitespace
        value = _strgsub(value, '^%s*(.-)%s*$', '%1')

        return true, value
    end

    -- NUMBER VALIDATION (uses existing SetMinMax metadata
    if (valueType == 'Number' or valueType == 'Slider' or valueType == 'Int') then
        local numValue = _tonumber(value)

        if (not numValue) then
            return false, nil, 'Value must be a number'
        end

        -- Check for infinity/NaN
        if (numValue ~= numValue) then
            return false, nil, 'Invalid number: NaN (Not a Number)'
        end

        if (numValue == math.huge) then
            return false, nil, 'Invalid number: Positive Infinity'
        end

        if (numValue == -math.huge) then
            return false, nil, 'Invalid number: Negative Infinity'
        end

        -- Get min/max from metadata (if defined via SetMinMax)
        if (DanLib.ConfigMeta and DanLib.ConfigMeta[module] and DanLib.ConfigMeta[module].Variables[variable]) then
            local varMeta = DanLib.ConfigMeta[module].Variables[variable]

            if (varMeta.MinValue and numValue < varMeta.MinValue) then
                return false, nil, _strFormat('Number too small (min: %d)', varMeta.MinValue)
            end

            if (varMeta.MaxValue and numValue > varMeta.MaxValue) then
                return false, nil, _strFormat('Number too large (max: %d)', varMeta.MaxValue)
            end
        end

        return true, numValue
    end

    -- COLOR VALIDATION
    if (valueType == 'Color') then
        if (_type(value) ~= 'table') then
            return false, nil, 'Color must be a table'
        end

        if (not value.r or not value.g or not value.b) then
            return false, nil, 'Color must have r, g, b values'
        end

        -- Validate RGB ranges
        for _, key in _ipairs({ 'r', 'g', 'b', 'a' }) do
            if value[key] then
                local v = _tonumber(value[key])
                if (not v or v < 0 or v > 255) then
                    return false, nil, _strFormat('Color %s must be 0-255', key)
                end
                value[key] = _mathFloor(v)
            end
        end

        return true, value
    end

    -- Default: allow value as-is
    return true, value
end

--- Validate module and variable names (NO LENGTH LIMITS - they're hardcoded)
-- @param name (string): Name to validate
-- @param nameType (string): 'module' or 'variable'
-- @return (bool, string|nil): isValid, errorMessage
local function _validateName(name, nameType)
    if (_type(name) ~= 'string') then
        return false, _strFormat('%s name must be a string', nameType)
    end

    -- Only allow alphanumeric, underscore, and dash
    if (not _strmatch(name, '^[%w_-]+$')) then
        return false, _strFormat('%s name contains invalid characters (only A-Z, a-z, 0-9, _, - allowed)', nameType)
    end

    -- Block path traversal attempts
    if (_strfind(name, '%.%.') or _strfind(name, '/') or _strfind(name, '\\')) then
        return false, _strFormat('%s name contains forbidden path characters', nameType)
    end

    return true
end

--- Log security violations with automatic kick after threshold
-- @param pPlayer (Player): Player who attempted the violation
-- @param violationType (string): Type of violation
-- @param details (string): Additional details
local function _logSecurityViolation(pPlayer, violationType, details)
    if (not DFileUtil:Exists('danlib/logs', 'DATA')) then
        DFileUtil:CreateDir('danlib/logs')
    end

    local playerName = _IsValid(pPlayer) and pPlayer:Nick() or 'Unknown'
    local playerID = _IsValid(pPlayer) and pPlayer:SteamID() or 'UNKNOWN'
    local playerIP = _IsValid(pPlayer) and pPlayer:IPAddress() or 'UNKNOWN'

    -- Track violations per player
    securityViolations[playerID] = (securityViolations[playerID] or 0) + 1

    local logEntry = _strFormat('[%s] SECURITY VIOLATION #%d - Type: %s | Player: %s (%s) | IP: %s | Details: %s', _osDate('%Y-%m-%d %H:%M:%S'), securityViolations[playerID], violationType, playerName, playerID, playerIP, details)
    DFileUtil:Append('danlib/logs/security_violations.txt', logEntry .. '\n')
    _errorLog(logEntry)

    -- Auto-kick after threshold
    if (securityViolations[playerID] >= MAX_SECURITY_VIOLATIONS and _IsValid(pPlayer)) then
        local kickReason = _strFormat('Kicked for %d security violations. Contact server administrator.', MAX_SECURITY_VIOLATIONS)
        pPlayer:Kick(kickReason)
        _errorLog(_strFormat('KICKED PLAYER: %s (%s) for %d security violations', playerName, playerID, MAX_SECURITY_VIOLATIONS))
        -- Log the kick
        DFileUtil:Append('danlib/logs/security_violations.txt', _strFormat('[%s] PLAYER KICKED: %s (%s) for repeated violations\n', _osDate('%Y-%m-%d %H:%M:%S'), playerName, playerID))
    end
end

local configValidators = { }

--- Register custom validator for a specific config variable
-- @param module (string): Module name
-- @param variable (string): Variable name
-- @param validatorFunc (function): Validator function
function DBase:RegisterConfigValidator(module, variable, validatorFunc)
    configValidators[module] = configValidators[module] or { }
    configValidators[module][variable] = validatorFunc
    _debugLog('INFO', DBase:L('#config.debug.validator.registered', {
        module = module,
        variable = variable
    }))
end

--- Validate configuration value
-- @param module (string): Module name
-- @param variable (string): Variable name
-- @param value (any): Value to validate
-- @return (bool, string|nil, any): isValid, errorMessage, sanitizedValue
local function _validateConfigValue(module, variable, value)
    local variableType = DBase.GetConfigType(module, variable)
    if (not variableType) then
        return false, DBase:L('#config.debug.validator.unknown', {
            module = module,
            variable = variable
        })
    end

    -- SECURITY: Sanitize and validate input
    local isValid, sanitizedValue, errorMsg = _sanitizeAndValidate(value, variableType, module, variable)
    if (not isValid) then
        return false, errorMsg
    end

    -- Update value with sanitized version
    value = sanitizedValue

    -- Run custom validator if registered
    if (configValidators[module] and configValidators[module][variable]) then
        local customValid, customError = configValidators[module][variable](value)
        if (not customValid) then
            _debugLog('WARNING', DBase:L('#config.debug.validator.failed', {
                module = module,
                variable = variable,
                errorMsg = customError or 'Unknown error'
            }))
            return false, customError or 'Validation failed'
        end
    end

    return true, nil, value -- Return sanitized value
end

--- Safely write configuration to file with verification
-- @param moduleKey (string): Module identifier
-- @param data (table): Configuration data
-- @return (bool, string|nil): success, errorMessage
local function _safeWriteConfig(moduleKey, data)
    if (not DFileUtil:Exists('danlib/config', 'DATA')) then
        DFileUtil:CreateDir('danlib/config')
        _debugLog('INFO', DBase:L('#config.debug.dir.created'))
    end

    local fileName = 'danlib/config/' .. moduleKey .. '.txt'

    local jsonData = DNetworkUtil:TableToJSON(data, true)
    if (not jsonData) then
        _errorLog(DBase:L('#config.debug.file.serialize.failed', {
            moduleKey = moduleKey
        }))
        return false, 'Failed to serialize config data'
    end

    DFileUtil:Write(fileName, jsonData)

    if (not DFileUtil:Exists(fileName, 'DATA')) then
        _errorLog(DBase:L('#config.debug.file.write.failed', {
            moduleKey = moduleKey
        }))
        return false, 'File write failed'
    end

    local writtenContent = DFileUtil:Read(fileName, 'DATA')
    if (not writtenContent or writtenContent ~= jsonData) then
        _errorLog(DBase:L('#config.debug.file.verify.failed', {
            moduleKey = moduleKey
        }))
        return false, 'File write verification failed'
    end

    _debugLog('SUCCESS', DBase:L('#config.debug.file.write.success', {
        moduleKey = moduleKey
    }))
    return true
end

--- Write config table into an open network message builder.
-- All writes go through the builder so there are no raw net.Write* calls
-- mixed with the DNet channel protocol.
-- @param msg (NetMsg): The open builder returned by DNet:Open().
-- @param configTable (table): Configuration table to serialise.
local function _writeConfigTable(msg, configTable)
    msg:UInt(DTable:Count(configTable), 8)

    for moduleKey, moduleData in _pairs(configTable) do
        msg:Str(moduleKey)
        local varCount = DTable:Count(moduleData)
        if (varCount > 255) then
            _errorLog(_strFormat('[DanLib] Module "%s" has %d variables — max is 255. Config sync will be broken. Reduce AddOption() calls in this module.', moduleKey, varCount))
        end
        msg:UInt(varCount, 8)

        for variable, value in _pairs(moduleData) do
            msg:Str(variable)
            local variableType = DBase.GetConfigType(moduleKey, variable)
            -- Send type on the wire so the client can always consume the value,
            -- even if the variable is unknown in its local ConfigMeta.
            msg:Str(variableType or '')
            DBase.ProcessTypeValue(variableType, value, true)
        end
    end
end

--- Send updated config to players
-- @param pPlayers (table|Player): Target players
-- @param changedConfig (table): Changed configuration
local function _sendUpdatedConfig(pPlayers, changedConfig)
    local msg = DNet:Open('DanLib:SendConfigUpdate')
    _writeConfigTable(msg, changedConfig)
    msg:Send(pPlayers)

    _debugLog('INFO', DBase:L('#config.debug.network.update.sent', {
        players = _istable(pPlayers) and #pPlayers or 1
    }))
end

--- Send complete config to a player
-- @param pPlayer (Player): Target player
function DBase:SendCompleteConfig(pPlayer)
    if (not _IsValid(pPlayer)) then
        _debugLog('WARNING', DBase:L('#config.debug.network.send.invalid'))
        return
    end

    local msg = DNet:Open('DanLib:SendConfig')
    _writeConfigTable(msg, DanLib.CONFIG)
    msg:Send(pPlayer)

    _debugLog('INFO', DBase:L('#config.debug.network.complete.sent', {
        name = pPlayer:Nick()
    }))
end

--- Main configuration save handler
-- @param length (number): Network message length
-- @param pPlayer (Player): Player requesting save
local function _handleConfigSave(length, pPlayer)
    if (not _IsValid(pPlayer)) then
        _errorLog(DBase:L('#config.debug.save.invalid.player'))
        return
    end

    if (not DBase.HasPermission(pPlayer, 'EditSettings')) then
        DBase:CreatePopupNotifi(pPlayer, DBase:L('#access.denied'), DBase:L('#access.ver'), 'ERROR', NOTIFICATION_DURATION_SHORT)
        _debugLog('WARNING', DBase:L('#config.debug.save.no.permission', {
            name = pPlayer:Nick()
        }))
        return
    end

    -- Rate limiting
    local steamID = pPlayer:SteamID()
    local lastRequest = rateLimitTracker[steamID] or 0

    if (_CurTime() - lastRequest < RATE_LIMIT_COOLDOWN) then
        _debugLog('WARNING', _strFormat('Rate limit hit: %s', pPlayer:Nick()))
        return
    end

    rateLimitTracker[steamID] = _CurTime()

    _debugLog('INFO', DBase:L('#config.debug.save.initiated', {
        name = pPlayer:Nick()
    }))

    local receivedConfig = { }
    local moduleCount = DNet:UInt(8)

    _debugLog('INFO', DBase:L('#config.debug.save.receiving', {
        score = moduleCount,
        name = pPlayer:Nick()
    }))

    for i = 1, moduleCount do
        local moduleKey = DNet:Str()

        -- SECURITY: Validate module name
        local validName, nameError = _validateName(moduleKey, 'module')
        if (not validName) then
            _logSecurityViolation(pPlayer, 'INVALID_MODULE_NAME', _strFormat('Module: %s, Error: %s', moduleKey, nameError))
            DBase:CreatePopupNotifi(pPlayer, DBase:L('#save.failed'), nameError, 'ERROR', NOTIFICATION_DURATION_SHORT)
            return
        end

        if (not DanLib.CONFIG[moduleKey]) then
            DBase:CreatePopupNotifi(pPlayer, DBase:L('#save.failed'), DBase:L('#config.error.module.notfound', {
                key = moduleKey
            }), 'ERROR', NOTIFICATION_DURATION_SHORT)

            _errorLog(DBase:L('#config.debug.save.invalid.module', {
                name = pPlayer:Nick(),
                key = moduleKey
            }))
            return
        end

        receivedConfig[moduleKey] = { }
        local varCount = DNet:UInt(8)

        for j = 1, varCount do
            local variable = DNet:Str()
            -- Read the wire type sent by the client; used to safely consume
            -- the value from the net stream when we need to skip this variable,
            -- preventing stream misalignment for remaining variables in the loop.
            local wireType = DNet:Str()

            -- SECURITY: Validate variable name
            local validVarName, varNameError = _validateName(variable, 'variable')
            if (not validVarName) then
                -- Consume value to keep stream aligned, then skip this variable
                if (wireType ~= '' and DanLib.FunctionType[wireType]) then
                    DBase.ProcessTypeValue(wireType, nil, false)
                end

                _logSecurityViolation(pPlayer, 'INVALID_VARIABLE_NAME', _strFormat('Variable: %s.%s, Error: %s', moduleKey, variable, varNameError))
                DBase:CreatePopupNotifi(pPlayer, DBase:L('#save.failed'), varNameError, 'ERROR', NOTIFICATION_DURATION_SHORT)
            else
                local variableType = DBase.GetConfigType(moduleKey, variable)
                if (not variableType) then
                    -- Consume value to keep stream aligned, then skip this variable
                    if (wireType ~= '' and DanLib.FunctionType[wireType]) then
                        DBase.ProcessTypeValue(wireType, nil, false)
                    end

                    DBase:CreatePopupNotifi(pPlayer, DBase:L('#save.failed'), DBase:L('#config.error.variable.notfound', {
                        key = moduleKey,
                        variable = variable,
                        key2 = moduleKey,
                        variable2 = variable
                    }), 'ERROR', NOTIFICATION_DURATION_LONG)
                    _errorLog(_strFormat('%s tried to save invalid variable: %s.%s', pPlayer:Nick(), moduleKey, variable))
                else
                    local value = DBase.ProcessTypeValue(variableType, nil, false)

                    -- SECURITY: Validate and sanitize value
                    local isValid, validationError, sanitizedValue = _validateConfigValue(moduleKey, variable, value)
                    if (not isValid) then
                        -- Log security violation, skip this variable
                        _logSecurityViolation(pPlayer, 'MALICIOUS_INPUT', _strFormat('%s.%s = %s (Error: %s)', moduleKey, variable, _tostring(value), validationError))

                        DBase:CreatePopupNotifi(pPlayer, DBase:L('#save.failed'), DBase:L('#config.error.value.invalid', {
                            key = moduleKey,
                            variable = variable,
                            validation = validationError or 'Unknown validation error',
                            value = _tostring(value),
                            type = _type(value)
                        }), 'ERROR', NOTIFICATION_DURATION_LONG)

                        _errorLog(DBase:L('#config.debug.validator.failed', {
                            module = moduleKey,
                            variable = variable,
                            errorMsg = validationError
                        }))
                    else
                        -- Use sanitized value
                        if (sanitizedValue ~= nil) then
                            receivedConfig[moduleKey][variable] = sanitizedValue
                        else
                            receivedConfig[moduleKey][variable] = value
                        end
                    end
                end
            end
        end
    end

    local configBackup = DTable:Copy(DanLib.CONFIG)
    _debugLog('INFO', DBase:L('#config.debug.save.backup.created'))

    local changeCount = 0
    for moduleKey, moduleData in _pairs(receivedConfig) do
        for variable, newValue in _pairs(moduleData) do
            local oldValue = DanLib.CONFIG[moduleKey][variable]
            DanLib.CONFIG[moduleKey][variable] = newValue
            changeCount = changeCount + 1
        end
    end

    _debugLog('INFO', DBase:L('#config.debug.save.changes.applied', {
        score = changeCount
    }))

    local success = true
    local failedModule = nil
    local writeError = nil
    local successfulWrites = 0

    for moduleKey in _pairs(receivedConfig) do
        local writeSuccess, errorMsg = _safeWriteConfig(moduleKey, DanLib.CONFIG[moduleKey])
        if (not writeSuccess) then
            success = false
            failedModule = moduleKey
            writeError = errorMsg
            break
        end

        successfulWrites = successfulWrites + 1
        _debugLog('INFO', DBase:L('#config.debug.save.module.written', {
            key = moduleKey,
            records = successfulWrites,
            received = DTable:Count(receivedConfig)
        }))
    end

    if (not success) then
        DanLib.CONFIG = configBackup

        -- Re-apply __index metatables lost by table.Copy during backup.
        -- Without this, variables added via ExtendModule return nil instead of their default.
        for mid, moduleTable in _pairs(DanLib.CONFIG) do
            if (not getmetatable(moduleTable)) then
                local moduleID = mid
                setmetatable(moduleTable, {
                    __index = function(_, key)
                        local meta = DanLib.ConfigMeta[moduleID]
                        if (meta and meta.Variables[key]) then
                            return meta.Variables[key].Default
                        end
                        return nil
                    end
                })
            end
        end

        DBase:CreatePopupNotifi(pPlayer, DBase:L('#save.failed'), DBase:L('#config.save.rollback', {
            module = failedModule,
            record = writeError or DBase:L('#config.error.unknown'),
            writes = successfulWrites,
            received = DTable:Count(receivedConfig),
            score = changeCount
        }), 'ERROR', NOTIFICATION_DURATION_LONG)

        _errorLog(DBase:L('#config.debug.save.rollback', {
            name = pPlayer:Nick(),
            module = failedModule,
            record = writeError,
            score = changeCount
        }))
        return
    end

    _sendUpdatedConfig(DPlayerUtil:GetAll(), receivedConfig)
    DHook:Run('DanLib:HooksConfigUpdated', pPlayer, receivedConfig)

    DBase:CreatePopupNotifi(pPlayer, DBase:L('#config.saved'), DBase:L('#config.all.saved'), 'CONFIRM', NOTIFICATION_DURATION_SHORT)

    _debugLog('SUCCESS', DBase:L('#config.debug.save.success', {
        name = pPlayer:Nick(),
        score = DTable:Count(receivedConfig),
        score2 = changeCount
    }))
end
DNet:On('DanLib:RequestSaveConfigChanges', _handleConfigSave)

--- Clean up per-player tracking tables on disconnect to prevent memory leaks.
DHook:Add('PlayerDisconnected', 'DanLib.Config.CleanupPlayer', function(pPlayer)
    if (not _IsValid(pPlayer)) then
        return
    end

    local steamID = pPlayer:SteamID()
    rateLimitTracker[steamID] = nil
    securityViolations[steamID] = nil
end)
