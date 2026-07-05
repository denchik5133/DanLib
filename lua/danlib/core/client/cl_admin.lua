/***
 *   @addon         DanLib
 *   @component     Admin
 *   @license       MIT License
 *   @version       2.4.1
 *   @release_date  07/12/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Enhanced client config system with staged changes, batch operations
 *
 *   @functions
 *                  - Staged changes (edit multiple settings before saving)
 *                  - Single-setting saves (immediate apply)
 *                  - Batch saves (save all at once)
 *                  - Effective value lookup (staged + current)
 *                  - Change tracking and discard
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DTable = DanLib.Table
local DHook = DanLib.Hook
local DNet = DanLib.Net

local _pairs = pairs
local _print = print
local _rawget = rawget
local _LocalPlayer = LocalPlayer
local _strFormat = string.format

-- DEBUG LOGGING SYSTEM
local function _debugLog(level, message)
    if (not DanLib.CONFIG or not DanLib.CONFIG.BASE or not DanLib.CONFIG.BASE.Debugg) then
        return
    end
    
    local prefix = '[DanLib Config]'
    local colorCode = ''
    
    if (level == 'ERROR') then
        colorCode = '[ERROR] '
    elseif (level == 'WARNING') then
        colorCode = '[WARNING] '
    elseif (level == 'SUCCESS') then
        colorCode = '[SUCCESS] '
    elseif (level == 'INFO') then
        colorCode = '[INFO] '
    end
    
    DBase:Print(_strFormat('%s %s%s', prefix, colorCode, message))
end

--- Read configuration table from network
-- @return (number, number): moduleCount, variableCount
local function ReadConfigTable()
    local variableCount = 0
    local moduleCount = DNet:UInt(8)

    for i = 1, moduleCount do
        local moduleKey = DNet:Str()
        DanLib.CONFIG[moduleKey] = DanLib.CONFIG[moduleKey] or { }

        -- We set up the metatable once, when the module is first loaded.
        -- Variables that the server did not send (no permissions / not registered
        -- locally) will return the default value instead of nil.
        if (not getmetatable(DanLib.CONFIG[moduleKey])) then
            local mid = moduleKey
            setmetatable(DanLib.CONFIG[moduleKey], {
                __index = function(_, key)
                    local meta = DanLib.ConfigMeta[mid]
                    if (meta and meta.Variables[key]) then
                        return meta.Variables[key].Default
                    end
                    return nil
                end
            })
        end

        local varCount = DNet:UInt(8)
        for j = 1, varCount do
            local variable = DNet:Str()
            -- Read the type sent by the server (always present since _writeConfigTable fix).
            -- Fall back to local ConfigMeta lookup so old servers without this patch still work.
            local wireType = DNet:Str()
            local variableType = DBase.GetConfigType(moduleKey, variable) or (wireType ~= '' and wireType or nil)
            if variableType then
                -- Type is known: read the value and store it
                local readValue = DBase.ProcessTypeValue(variableType, nil, false)
                -- Only write to CONFIG if this variable is declared locally
                if DBase.GetConfigType(moduleKey, variable) then
                    DanLib.CONFIG[moduleKey][variable] = readValue
                    variableCount = variableCount + 1
                end
            else
                -- Type unknown on both sides: cannot safely consume the value.
                -- Stream will be misaligned for this module's remaining variables.
                _debugLog('WARNING', _strFormat('Unknown variable %s.%s with no wire type - stream may be misaligned', moduleKey, variable))
            end
        end
    end
    
    return moduleCount, variableCount
end

-- Handle initial config sync from server
DNet:On('DanLib:SendConfig', function()
    -- Reuse the shared dedup-warn cache from sh_module_loader (shared context).
    local _warnedCfg = DanLib._warnedConfigKeys or { }
    local function _cfgWarn(msg)
        local base = _rawget(DanLib.CONFIG, 'BASE')
        if (base and _rawget(base, 'Debugg')) then
            DBase:Print('[CONFIG] ' .. msg)
        end
    end

    -- Recreate with a protective metatable (mirrors server sh_module_loader).
    -- Returning a proxy (not nil) keeps DanLib.CONFIG.X.Y chains crash-free.
    -- NOTE: (DanLib.CONFIG.X ~= nil) is always true even for unknown modules.
    -- Use DanLib.ConfigMeta[id] to test whether a module is actually registered.
    DanLib.CONFIG = setmetatable({ }, {
        __index = function(_, moduleID)
            local meta = DanLib.ConfigMeta[moduleID]
            if (not meta) then
                local wk = 'mod:' .. tostring(moduleID)
                if (not _warnedCfg[wk]) then
                    _warnedCfg[wk] = true
                    _cfgWarn('Access to unregistered module "' .. tostring(moduleID) .. '" — returning nil-proxy.')
                end
                return setmetatable({ }, {
                    __index = function()
                        return nil
                    end
                })
            end

            return setmetatable({ }, {
                __index = function(_, key)
                    local varMeta = meta.Variables[key]
                    return varMeta and varMeta.Default or nil
                end
            })
        end
    })
    local moduleCount, variableCount = ReadConfigTable()
    
    _debugLog('INFO', _strFormat('Received initial config: %d modules, %d variables', moduleCount, variableCount))
    DHook:Run('DanLib:HooksConfigUpdated')
end)

--- Handle config updates from server
DNet:On('DanLib:SendConfigUpdate', function()
    if (not DBase.HasPermission(_LocalPlayer(), 'EditSettings')) then
        return
    end

    local moduleCount, variableCount = ReadConfigTable()
    
    -- Check if we should skip the hook (for welcome tutorial)
    if DanLib._SkipNextConfigHook then
        DanLib._SkipNextConfigHook = nil
        _debugLog('INFO', 'Skipped config update hook')
        return
    end
    
    _debugLog('INFO', _strFormat('Config updated: %d modules, %d variables', moduleCount, variableCount))
    DHook:Run('DanLib:HooksConfigUpdated')
end)

--- Stage a configuration change (doesn't save immediately)
-- @param module (string): Module name
-- @param variable (string): Variable name
-- @param value (any): New value
-- @return (bool): Success status
function DBase:SetConfigVariable(module, variable, value)
    if (not DBase.HasPermission(_LocalPlayer(), 'EditSettings')) then
        return false
    end

    -- Check if the new value matches the already-saved value.
    -- If so, remove it from staged changes so the user doesn't need to
    -- click Save/Cancel when they simply revert a setting back.
    local originalVal = DanLib.CONFIG[module] and DanLib.CONFIG[module][variable]
    local variableType = DBase.GetConfigType(module, variable)
    local isReverted

    if (variableType == DanLib.Type.Table) then
        -- Tables need deep comparison via JSON serialisation
        local jsonNew = DanLib.NetworkUtil:TableToJSON(value or { })
        local jsonOrig = DanLib.NetworkUtil:TableToJSON(originalVal or { })
        isReverted = (jsonNew == jsonOrig)
    else
        isReverted = (value == originalVal)
    end

    if isReverted then
        -- Remove this variable from staged changes if it was there
        if (DanLib.ChangedConfig and DanLib.ChangedConfig[module]) then
            DanLib.ChangedConfig[module][variable] = nil

            if (DTable:Count(DanLib.ChangedConfig[module]) == 0) then
                DanLib.ChangedConfig[module] = nil
            end

            if (DTable:Count(DanLib.ChangedConfig) == 0) then
                DanLib.ChangedConfig = nil
                -- All changes reverted: hide the save notification immediately
                DHook:Run('DanLib.ConfigSaved')
            end
        end
        return true
    end

    DanLib.ChangedConfig = DanLib.ChangedConfig or { }
    DanLib.ChangedConfig[module] = DanLib.ChangedConfig[module] or { }
    DanLib.ChangedConfig[module][variable] = value

    -- Notify UI that there are unsaved changes
    DHook:Run('DanLib.ConfigChanged')
    return true
end

--- Get a staged configuration value
-- @param module (string): Module name
-- @param variable (string): Variable name
-- @return (any): Staged value or nil
function DBase:RetrieveUpdatedVariable(module, variable)
    if (not DanLib.ChangedConfig or not DanLib.ChangedConfig[module]) then
        return nil
    end
    return DanLib.ChangedConfig[module][variable]
end

--- Get effective config value (staged or current)
-- @param module (string): Module name
-- @param variable (string): Variable name
-- @return (any): Effective value
function DBase:GetEffectiveConfigValue(module, variable)
    -- Check staged changes first
    local stagedValue = DBase:RetrieveUpdatedVariable(module, variable)
    if (stagedValue ~= nil) then
        return stagedValue
    end
    
    -- Fall back to current config
    if DanLib.CONFIG[module] then
        return DanLib.CONFIG[module][variable]
    end
    
    return nil
end

--- Discard all staged configuration changes
-- @return (bool): Whether any changes were discarded
function DBase:DiscardConfigChanges()
    if DanLib.ChangedConfig then
        local count = DTable:Count(DanLib.ChangedConfig)
        DanLib.ChangedConfig = nil
        DBase:PrintType('Info', 'Discarded ' .. count .. ' staged change(s)')
        return true
    end
    return false
end

--- Get count of staged changes
-- @return (number): Number of staged changes
function DBase:GetStagedChangesCount()
    if (not DanLib.ChangedConfig) then
        return 0
    end
    
    local count = 0
    for module, vars in _pairs(DanLib.ChangedConfig) do
        for variable, value in _pairs(vars) do
            count = count + 1
        end
    end
    
    return count
end

--- Save a single configuration setting immediately
-- @param module (string): Module name
-- @param variable (string): Variable name
-- @param value (any): New value
-- @return (bool): Success status
function DBase:SaveSingleSetting(module, variable, value)
    if (not DBase.HasPermission(_LocalPlayer(), 'EditSettings')) then 
        return false
    end
    
    -- Validate module and variable exist
    local variableType = DBase.GetConfigType(module, variable)
    if (not variableType) then
        DBase:PrintType('Error', 'Invalid module or variable: ' .. module .. '.' .. variable)
        return false
    end
    
    -- Send to server
    local msg = DNet:Open('DanLib:RequestSaveConfigChanges')
    msg:UInt(1, 8) -- 1 module
    msg:Str(module)
    msg:UInt(1, 8) -- 1 variable
    msg:Str(variable)
    msg:Str(variableType) -- wire type (always valid here)
    DBase.ProcessTypeValue(variableType, value, true)
    msg:Up()
    
    -- Apply the new value to local CONFIG immediately so the UI reflects it
    -- without waiting for the server's SendConfigUpdate response.
    if DanLib.CONFIG[module] then
        DanLib.CONFIG[module][variable] = value
    end

    -- Clear from staged changes
    if (DanLib.ChangedConfig and DanLib.ChangedConfig[module]) then
        DanLib.ChangedConfig[module][variable] = nil
        
        if (DTable:Count(DanLib.ChangedConfig[module]) == 0) then
            DanLib.ChangedConfig[module] = nil
        end
        
        if (DTable:Count(DanLib.ChangedConfig) == 0) then
            DanLib.ChangedConfig = nil
            DHook:Run('DanLib.ConfigSaved') -- all staged changes are now saved
        end
    end
    
    DBase:PrintType('Info', 'Saving ' .. module .. '.' .. variable)
    return true
end

--- Save multiple configuration settings
-- @param settingsTable (table): { MODULE = { variable = value } }
-- @param skipHookUpdate (bool): If true, skip config update hook (for welcome tutorial)
-- @return (bool): Success status
function DBase:SaveSettings(settingsTable, skipHookUpdate)
    if (not DBase.HasPermission(_LocalPlayer(), 'EditSettings')) then 
        return false
    end
    
    if (not settingsTable or DTable:Count(settingsTable) == 0) then
        DBase:PrintType('Warning', 'No settings to save')
        return false
    end
    
    -- Set skip hook flag if requested
    if skipHookUpdate then
        DanLib._SkipNextConfigHook = true
    end
    
    -- Send to server
    local msg = DNet:Open('DanLib:RequestSaveConfigChanges')
    msg:UInt(DTable:Count(settingsTable), 8)
    
    for moduleKey, moduleData in _pairs(settingsTable) do
        msg:Str(moduleKey)

        -- Pre-collect variables with known types so the count we write is accurate.
        -- Unknown variables are skipped with a warning rather than corrupting the count.
        local knownVars = { }
        for variable, value in _pairs(moduleData) do
            local variableType = DBase.GetConfigType(moduleKey, variable)
            if variableType then
                knownVars[variable] = {
                    value = value,
                    vtype = variableType
                }
            else
                _debugLog('WARNING', _strFormat('Skipping unknown variable %s.%s', moduleKey, variable))
            end
        end

        msg:UInt(DTable:Count(knownVars), 8)

        for variable, data in _pairs(knownVars) do
            msg:Str(variable)
            msg:Str(data.vtype) -- wire type
            DBase.ProcessTypeValue(data.vtype, data.value, true)
        end
    end
    msg:Up()
    
    -- Clear staged changes
    DanLib.ChangedConfig = nil
    DHook:Run('DanLib.ConfigSaved') -- hide save notification immediately
    
    -- If skipping hook, apply changes locally immediately
    if skipHookUpdate then
        for moduleKey, moduleData in _pairs(settingsTable) do
            DanLib.CONFIG[moduleKey] = DanLib.CONFIG[moduleKey] or { }
            for variable, value in _pairs(moduleData) do
                DanLib.CONFIG[moduleKey][variable] = value
            end
        end
    end
    
    DBase:PrintType('Info', 'Saving ' .. DTable:Count(settingsTable) .. ' module(s)')
    return true
end

-- NOTIFICATION HANDLERS
DNet:On('DanLib:ScreenNotification', function()
    DBase:ScreenNotification(DNet:Str(), DNet:Str(), DNet:Str(), DNet:Str(), DNet:Str(), DNet:Str())
end)

DNet:On('DanLib:SidePopupNotification', function()
    DBase:SidePopupNotification(DNet:Str(), DNet:Str(), tonumber(DNet:Str()) or 5)
end)

-- CHAT MESSAGE HANDLER
local MESSAGE = DanLib.BaseConfig.ChatType or { }
DNet:On('DanLib:Message', function()
    local msgType = DNet:Int(8) or -1
    local args = DNet:Tbl()

    local toPrint = { }
    local messageColor, messageText

    if (msgType == MESSAGE.MESSAGES_TYPE.SUCCESS) then
        messageColor = MESSAGE.SUCCESS_COLOR
        messageText = MESSAGE.SUCCESS_MSG
    elseif (msgType == MESSAGE.MESSAGES_TYPE.WARNING) then
        messageColor = MESSAGE.WARNING_COLOR
        messageText = MESSAGE.WARNING_MSG
    elseif (msgType == MESSAGE.MESSAGES_TYPE.ERROR) then
        messageColor = MESSAGE.ERROR_COLOR
        messageText = MESSAGE.ERROR_MSG
    end

    if (messageColor and messageText) then
        DTable:Add(toPrint, messageColor)
        DTable:Add(toPrint, DBase:L(messageText))
        DTable:Add(toPrint, Color(255, 255, 255))
        DTable:Add(toPrint, ' ')
    end

    table.Add(toPrint, args)
    chat.AddText(unpack(toPrint))
end)