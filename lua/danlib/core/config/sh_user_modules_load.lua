/***
 *   @addon         DanLib
 *   @component     User Config
 *   @license       MIT License
 *   @version       1.8.0
 *   @release_date  16/03/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   Client-side per-player settings system for DanLib modules.
 *                  Manages the DanLib.UserModules registry: module registration, option declaration,
 *                  disk serialisation, and real-time UI sync via the DanLib.ClientConfigChanged hook.
 *
 *   @functions
 *                  ModuleMeta — metatable for every user-module object.
 *                  DanLib.UserModules — registry of all registered user modules.
 *                  DanLib.USERCONFIG — live in-memory config values for the local player.
 *                  DanLib.TypeHandlers — per-type serialize / deserialize / validate helpers.
 *                  DanLib.UserCategoryRegistry — registry of all declared option category groups.
 *
 *   @api
 *                  DanLib.Client.GetValue(module, variable) — read a live config value.
 *                  DanLib.Client.SetValue(module, variable, value, now) — write a value with auto-save debounce.
 *                  DanLib.Client.ResetValue(module, variable) — reset one variable to its default.
 *                  DanLib.Client.ResetAll(module) — reset all variables of a module.
 *                  DanLib.Client.ExtendModule(moduleId, callback) — inject options from an external addon.
 *
 *   @hooks
 *                  DanLib.ClientConfigChanged(moduleID, variable, value) — on every value write.
 *                  DanLib.ClientConfigSaved() — after a disk save.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DHook = DanLib.Hook
local DTable = DanLib.Table
local DTimer = DanLib.Timer
local DFileUtil = DanLib.FileUtil
local DNetworkUtil = DanLib.NetworkUtil

local _ErrorNoHalt = ErrorNoHalt
local _tostring = tostring
local _tonumber = tonumber
local _assert = assert
local _pairs = pairs
local _ipairs = ipairs
local _pcall = pcall
local _error = error
local _type = type

-- Client-side configuration types
DanLib.UserModules = { }
DanLib.Client = DanLib.Client or { }

-- Reuse the shared dedup-warn cache created in sh_module_loader.lua.
-- Both CONFIG and USERCONFIG use one table so warnings stay deduplicated.
DanLib._warnedConfigKeys = DanLib._warnedConfigKeys or { }
local _warnedCfg = DanLib._warnedConfigKeys

-- Helper: emit a one-shot debug warning when Debugg is enabled.
-- Uses rawget to avoid __index recursion on DanLib.CONFIG.
local function _ucfgWarn(msg)
    local base = rawget(DanLib.CONFIG or {}, 'BASE')
    if (base and rawget(base, 'Debugg')) then
        DBase:PrintType('[USERCONFIG] ' .. msg)
    end
end

-- Helper: attach the unknown-key __index guard to a freshly-built module table.
-- Called after every LoadUserConfig / LoadUserModuleConfig population pass.
local function _guardModuleTable(tbl, modID)
    setmetatable(tbl, {
        __index = function(_, key)
            local mod = DanLib.UserModules[modID]
            if (mod and mod.Variables[key]) then
                return mod.Variables[key].Default
            end
            local wk = 'ucfg:' .. modID .. ':' .. tostring(key)
            if (not _warnedCfg[wk]) then
                _warnedCfg[wk] = true
                _ucfgWarn('Access to unknown key "' .. tostring(key) .. '" in user module "' .. modID .. '" — returning nil.')
            end
            return nil
        end
    })
end

-- DanLib.USERCONFIG — live per-player config values.
-- Protected metatable: unknown modules return a nil-proxy (no crash on chained access).
-- NOTE: (DanLib.USERCONFIG.X ~= nil) is always true even for unknown modules.
-- Use DanLib.UserModules[id] to test whether a module is actually registered.
DanLib.USERCONFIG = setmetatable({ }, {
    __index = function(_, moduleID)
        local mod = DanLib.UserModules[moduleID]
        if (not mod) then
            local wk = 'ucfg:mod:' .. tostring(moduleID)
            if (not _warnedCfg[wk]) then
                _warnedCfg[wk] = true
                _ucfgWarn('Access to unregistered user module "' .. tostring(moduleID) .. '" — returning nil-proxy. Use DanLib.UserModules to check existence.')
            end
            return setmetatable({ }, {
                __index = function() return nil end
            })
        end
        -- Known module not yet loaded — return defaults
        return setmetatable({ }, {
            __index = function(_, key)
                local varData = mod.Variables[key]
                return varData and varData.Default or nil
            end
        })
    end
})

-- Permanent registry of all ExtendModule callbacks.
-- Key: moduleId (string), Value: ordered array of callback functions.
-- Never cleared — Register re-applies them on every call so that
-- InitPostEntity re-registrations do not lose extended variables.
DanLib._registeredExtensions = DanLib._registeredExtensions or { }

-- Per-module category registry (analogous to DanLib.CategoryRegistry in sh_module_loader).
-- Key: categoryName (string), Value: { Name, Color, Icon, Order }.
DanLib.UserCategoryRegistry = DanLib.UserCategoryRegistry or { }

-- Function handlers for different types
DanLib.TypeHandlers = {
    Int = {
        Serialize = function(value)
            return _tostring(value)
        end,
        Deserialize = function(value)
            return _tonumber(value)
        end,
        Validate = function(value)
            return _type(value) == 'number'
        end,
        Default = 0
    },
    String = {
        Serialize = function(value)
            return _tostring(value)
        end,
        Deserialize = function(value)
            return _tostring(value)
        end,
        Validate = function(value)
            return _type(value) == 'string'
        end,
        Default = ''
    },
    Bool = {
        Serialize = function(value)
            return value and 'true' or 'false'
        end,
        Deserialize = function(value)
            return value == 'true'
        end,
        Validate = function(value)
            return _type(value) == 'boolean'
        end,
        Default = false
    },
    Table = {
        Serialize = function(value)
            return DNetworkUtil:TableToJSON(value)
        end,
        Deserialize = function(value)
            return DNetworkUtil:JSONToTable(value) or { }
        end,
        Validate = function(value)
            return _type(value) == 'table'
        end,
        Default = { }
    },
    Key = {
        -- Stores the GMod KEY_ numeric code (e.g. KEY_A = 65). 0 = no key bound.
        Serialize = function(value)
            return _tostring(_tonumber(value) or 0)
        end,
        Deserialize = function(value)
            return _tonumber(value) or 0
        end,
        Validate = function(value)
            -- Accept nil or a non-negative integer (GMod KEY_ constant).
            return value == nil or (_type(value) == 'number' and value >= 0)
        end,
        Default = 0 -- 0 = KEY_NONE (no key bound)
    }
}


--- Returns the declared type of a user-config variable.
-- @param module (string): Module ID to look up in DanLib.UserModules.
-- @param variable (string): Variable name inside that module.
-- @return string|nil: The type string (e.g. DanLib.Type.Bool), or nil if not found.
function DanLib.GetUserConfigType(module, variable)
    if (not DanLib.UserModules[module] or not DanLib.UserModules[module].Variables) then
        return
    end
    return DanLib.UserModules[module].Variables[variable].Type
end

--- Returns the value as-is (client values are primitives; no deep-copy needed).
-- Kept for API symmetry with DanLib.Func.CopyTypeValue in sh_module_loader.lua.
-- @param type (string): DanLib type identifier (currently unused on the client side).
-- @param value (any): The value to return.
-- @return any: The original value unchanged.
function DanLib.CopyUserTypeValue(type, value)
    if (not type or not DanLib.TypeHandlers[type]) then
        return value
    end
    return value
end

-- Path to configuration files.
local ConfigPath = 'danlib/config/modules'
-- Create config directory if it doesn't exist
DFileUtil:CreateDir(ConfigPath)

-- Module metatable
local ModuleMeta = {
    --- Registers this module into DanLib.UserModules and re-applies all
    -- DanLib.Client.ExtendModule callbacks from DanLib._registeredExtensions.
    -- Never clears the extension registry — safe to call multiple times
    -- (e.g. on InitPostEntity re-load) without losing injected options.
    -- @return self: Returns the module object for continued method chaining.
    Register = function(self)
        DanLib.UserModules[self.ID] = self

        local extensions = DanLib._registeredExtensions[self.ID]
        if extensions then
            for _, cb in _ipairs(extensions) do
                local ok, err = _pcall(cb, self)
                if (not ok) then
                    _ErrorNoHalt('[DanLib] ExtendModule error ("' .. self.ID .. '"): ' .. _tostring(err) .. '\n')
                end
            end
        end

        return self
    end,

    --- Sets the display title shown in the settings panel header.
    -- @param title (string): Human-readable module title.
    -- @return self: Returns the module object for continued method chaining.
    SetTitle = function(self, title)
        self.Title = title
        return self
    end,

    --- Sets the icon shown next to the module in the settings panel sidebar.
    -- @param icon (string): Icon material path or icon key.
    -- @return self: Returns the module object for continued method chaining.
    SetIcon = function(self, icon)
        self.Icon = icon
        return self
    end,

    --- Sets the description shown in the settings panel detail view.
    -- @param description (string): Full description of what this module controls.
    -- @return self: Returns the module object for continued method chaining.
    SetDescription = function(self, description)
        self.Description = description
        return self
    end,

    --- Sets the accent colour used for this module in the settings panel.
    -- @param color (Color): GMod Color object used for highlights and headers.
    -- @return self: Returns the module object for continued method chaining.
    SetColor = function(self, color)
        self.Color = color
        return self
    end,

    --- Controls whether this module is visible in the settings panel.
    -- Hidden modules are fully functional but not listed in the sidebar.
    -- @param hidden (bool): true to hide the module from the panel.
    -- @return self: Returns the module object for continued method chaining.
    SetHidden = function(self, hidden)
        self.Hidden = hidden and true or false
        return self
    end,

    --- Declares a named visual category group and returns a category object.
    -- Options added via the returned object are automatically tagged with this category
    -- and grouped together (with a separator header) in the settings panel.
    -- Registers the category in DanLib.UserCategoryRegistry if not already present.
    -- Mirrors AddCategory in ConfigModuleMeta (sh_module_loader.lua).
    -- @param categoryName (string): Display name for the category group.
    -- @param categoryColor (Color): Accent colour for the category header (optional, default blue).
    -- @param categoryIcon (string): Icon material or key for the header (optional).
    -- @return table: Category object; call :AddOption() on it to add grouped options.
    AddCategory = function(self, categoryName, categoryColor, categoryIcon)
        if (not DanLib.UserCategoryRegistry[categoryName]) then
            DanLib.UserCategoryRegistry[categoryName] = {
                Name = categoryName,
                Color = categoryColor or Color(67, 156, 242),
                Icon = categoryIcon or nil,
                Order = DTable:Count(DanLib.UserCategoryRegistry) + 1
            }
        end

        local categoryObj = {
            Name = categoryName,
            Module = self
        }
        
        function categoryObj:AddOption(variable, name, description, sType, default, vguiElement, getOptions, action)
            return self.Module:AddOption(variable, name, description, sType, default, vguiElement, getOptions, action, categoryName)
        end
        return categoryObj
    end,

    --- Adds a configurable option to this user module.
    -- Returns a chainable option object so you can call :SetMinMax() / :HelpText() immediately.
    -- @param variable (string): Internal key stored in DanLib.USERCONFIG[moduleID][variable].
    -- @param name (string): Human-readable label shown in the settings panel.
    -- @param description (string): Tooltip / subtitle text for the option row.
    -- @param sType (string): DanLib type constant (e.g. DanLib.Type.Bool, DanLib.Type.Int).
    -- @param default (any): Default value — must pass the type handler's Validate check.
    -- @param vguiElement (string): VGUI element class used to render this option (optional).
    -- @param getOptions (function): Supplier called to populate dynamic dropdown lists (optional).
    -- @param action (function): Called when the user changes the value (optional).
    -- @param category (string): Category name from :AddCategory() for grouping (internal, optional).
    -- @return table: Chainable option object; call :SetMinMax() and/or :HelpText() on it.
    AddOption = function(self, variable, name, description, sType, default, vguiElement, getOptions, action, category)
        self.Variables[variable] = {
            Name = name,
            Description = description,
            Type = sType,
            Default = default,
            VguiElement = vguiElement or (sType == DanLib.Type.Table and 'EditablePanel'),
            GetOptions = getOptions,
            Action = action or nil,
            Order = DTable:Count(self.Variables) + 1,
            Category = category or nil,
            Help = ''
        }

        local handler = DanLib.TypeHandlers[sType]
        if (handler and not handler.Validate(default)) then
            _error('Default value for ' .. variable .. ' is not valid!')
        end

        local option = {
            Parent = self,
            VariableName = variable,
            Type = sType
        }

        function option:SetMinMax(minValue, maxValue)
            if (self.Type ~= DanLib.Type.Int) then
                DBase:PrintType('[ERROR] SetMinMax can only be used with Int type options')
                return self
            end

            if (_type(minValue) ~= 'number' or _type(maxValue) ~= 'number') then
                DBase:PrintType('[ERROR] SetMinMax requires numeric min and max values')
                return self
            end

            if (minValue > maxValue) then
                DBase:PrintType('[ERROR] SetMinMax: minimum value cannot be greater than maximum value')
                return self
            end

            self.Parent.Variables[self.VariableName].Min = minValue
            self.Parent.Variables[self.VariableName].Max = maxValue
            return self
        end

        function option:ValidateKeyBinding(bannedKeys)
            -- Fixed: was self.Variable (nil) — must be self.VariableName
            if (self.Parent.Variables[self.VariableName] and
                self.Parent.Variables[self.VariableName].Type == DanLib.Type.Key) then
                self.Parent.Variables[self.VariableName].bannedKeys = bannedKeys
            end
            return self
        end

        function option:HelpText(helpText)
            if (_type(helpText) ~= 'string') then
                DBase:PrintType('[ERROR] HelpText requires a string parameter')
                return self
            end

            self.Parent.Variables[self.VariableName].HelpText = helpText
            return self
        end

        --- Attaches a custom validator function for this option's value.
        -- Called by DanLib.Client.SetValue before writing a new value,
        -- and on config load (from disk) to reject persisted bad values.
        -- @param fn (function): function(value) -> true  |  false, reason_string
        --   Return true on success; return false + a short reason string on failure.
        --   On failure SetValue returns false and the old value is preserved;
        --   on load the declared default is used instead.
        -- @return self: Returns self so other option methods can be chained after.
        function option:SetValidation(fn)
            if (_type(fn) ~= 'function') then
                DBase:PrintType('[ERROR] SetValidation requires a function parameter')
                return self
            end
            self.Parent.Variables[self.VariableName].Validation = fn
            return self
        end

        return option
    end,

    --- Sets the numeric sort order that determines module position in the settings panel sidebar.
    -- Lower values appear first. Defaults to 0.
    -- @param sortOrder (number): Sort priority for this module.
    -- @return self: Returns the module object for continued method chaining.
    SetSortOrder = function(self, sortOrder)
        self.SortOrder = sortOrder
        return self
    end,

    --- Returns a flat, ordered list of this module's variables ready for the settings panel UI.
    -- Uncategorised options appear first (sorted by Order).
    -- Each category block is preceded by a CategorySeparator sentinel row
    -- { IsSeparator=true, Type="CategorySeparator", Name=..., CategoryInfo=... }.
    -- Mirrors GetSorted in ConfigModuleMeta (sh_module_loader.lua).
    -- @return table: Flat list of variable data rows (and separator sentinels) sorted for display.
    GetSorted = function(self)
        local sortedVariables = { }
        local categorizedVars = { }
        local uncategorizedVars = { }

        for k, v in _pairs(self.Variables) do
            local data = DTable:Copy(v)
            data.Key = k

            if v.Category then
                if (not categorizedVars[v.Category]) then
                    categorizedVars[v.Category] = { }
                end
                DTable:Add(categorizedVars[v.Category], data)
            else
                DTable:Add(uncategorizedVars, data)
            end
        end

        -- Uncategorised options first
        DTable:SortByMember(uncategorizedVars, 'Order', true)
        for _, var in _ipairs(uncategorizedVars) do
            DTable:Add(sortedVariables, var)
        end

        -- Sort categories by registration order
        local sortedCategories = { }
        for categoryName, vars in _pairs(categorizedVars) do
            local info = DanLib.UserCategoryRegistry[categoryName]
            DTable:Add(sortedCategories, {
                Name = categoryName,
                Variables = vars,
                Order = info and info.Order or 999,
                Info = info
            })
        end
        DTable:SortByMember(sortedCategories, 'Order', true)

        -- Inject separator sentinel + sorted vars for each category
        for _, category in _ipairs(sortedCategories) do
            DTable:Add(sortedVariables, {
                Type = 'CategorySeparator',
                Name = category.Name,
                CategoryInfo = category.Info,
                IsSeparator = true
            })

            DTable:SortByMember(category.Variables, 'Order', true)
            for _, var in _ipairs(category.Variables) do
                DTable:Add(sortedVariables, var)
            end
        end

        return sortedVariables
    end,

    --- Returns the live in-memory value from DanLib.USERCONFIG, falling back to the declared default.
    -- @param variable (string): Variable name.
    -- @return any: Current value, or the declared default if not yet set, or nil if variable not found.
    GetValue = function(self, variable)
        local varData = self.Variables[variable]
        if (not varData) then
            local c = debug.getinfo(2, 'Sl')
            local src = c and (c.source .. ':' .. c.currentline) or 'unknown'
            DBase:PrintType('GetValue: variable "' .. _tostring(variable) .. '" is not registered in module "' .. _tostring(self.ID) .. '" | caller: ' .. src)
            return nil
        end

        local handler = DanLib.TypeHandlers[varData.Type]
        if (not handler) then
            return varData.Default
        end

        local value = DanLib.USERCONFIG[self.ID] and DanLib.USERCONFIG[self.ID][variable]
        if (value == nil) then
            return varData.Default
        end

        return value
    end,

    --- Writes a value into DanLib.USERCONFIG and fires DanLib.ClientConfigChanged.
    -- Does NOT persist to disk — use DanLib.Client.SetValue from outside the settings panel
    -- (it adds debounced auto-save and type validation).
    -- @param variable (string): Variable name.
    -- @param value (any): New value to store.
    -- @return bool: true on success, false if the variable is not declared in this module.
    SetValue = function(self, variable, value)
        local varData = self.Variables[variable]
        if (not varData) then
            return false
        end

        if (not DanLib.USERCONFIG[self.ID]) then
            DanLib.USERCONFIG[self.ID] = { }
        end

        DanLib.USERCONFIG[self.ID][variable] = value
        DHook:Run('DanLib.ClientConfigChanged', self.ID, variable, value)
        return true
    end,

    --- Resets a single variable to its declared default, fires the change hook, and saves to disk.
    -- @param variable (string): Variable name to reset.
    -- @return bool: true on success, false if the variable is not declared in this module.
    ResetValue = function(self, variable)
        local varData = self.Variables[variable]
        if (not varData) then
            return false
        end

        if (not DanLib.USERCONFIG[self.ID]) then
            DanLib.USERCONFIG[self.ID] = { }
        end

        DanLib.USERCONFIG[self.ID][variable] = varData.Default
        DHook:Run('DanLib.ClientConfigChanged', self.ID, variable, varData.Default)
        DanLib.SaveUserConfig()
        return true
    end,

    --- Resets every variable of this module to its declared default, fires the change hook
    -- for each one, and persists the result to disk via DanLib.SaveUserConfig().
    -- @return nil
    ResetAll = function(self)
        if (not DanLib.USERCONFIG[self.ID]) then
            DanLib.USERCONFIG[self.ID] = { }
        end

        for variable, varData in _pairs(self.Variables) do
            DanLib.USERCONFIG[self.ID][variable] = varData.Default
            DHook:Run('DanLib.ClientConfigChanged', self.ID, variable, varData.Default)
        end

        DanLib.SaveUserConfig()
    end,
}

ModuleMeta.__index = ModuleMeta

--- Creates a new client user-module with ModuleMeta as its metatable.
-- Chain the returned object with :SetTitle(), :AddOption(), :AddCategory(), etc.,
-- then call :Register() to add it to DanLib.UserModules.
-- @param id (string): Unique module ID — used as the key in DanLib.UserModules and DanLib.USERCONFIG.
-- @return table: New module object with all ModuleMeta methods available.
function DanLib.CreateUserModule(id)
    local module = {
        ID = id,
        Variables = { },
        SortOrder = 0,
        Hidden = false
    }
    setmetatable(module, ModuleMeta)
    return module
end

--- Returns the live value of a user-config variable.
-- Wrapper around ModuleMeta:GetValue() for use outside the settings panel.
-- @param module (string): Module ID (e.g. "CHAT").
-- @param variable (string): Variable name (e.g. "WindowWidth").
-- @return any: Current value, or declared default if not set, or nil if module not found.
--
-- Example:
--   local w = DanLib.Client.GetValue('CHAT', 'WindowWidth')
function DanLib.Client.GetValue(module, variable)
    local mod = DanLib.UserModules[module]
    if (not mod) then
        local c = debug.getinfo(2, 'Sl')
        local src = c and (c.source .. ':' .. c.currentline) or 'unknown'
        DBase:PrintType('Client.GetValue: module "' .. _tostring(module) .. '" is not registered | caller: ' .. src)
        return nil
    end

    return mod:GetValue(variable)
end

--- Writes a user-config value from outside the settings panel.
-- Validates the value against the declared type handler; fires DanLib.ClientConfigChanged
-- for real-time settings panel sync; auto-saves to disk after 1 s of inactivity (debounce).
-- @param module (string): Module ID (e.g. "CHAT").
-- @param variable (string): Variable name (e.g. "WindowWidth").
-- @param value (any): New value; must pass the type handler's Validate check.
-- @param instant (bool): If true, saves to disk immediately instead of debouncing (default: false).
-- @return bool: true on success, false if module or variable not found, or type mismatch.
--
-- Examples:
--   DanLib.Client.SetValue('CHAT', 'WindowWidth', 600)
--   DanLib.Client.SetValue('CHAT', 'WindowPosX', 100, true)  -- immediate save
function DanLib.Client.SetValue(module, variable, value, instant)
    local mod = DanLib.UserModules[module]
    if (not mod) then
        local c = debug.getinfo(2, 'Sl')
        local src = c and (c.source .. ':' .. c.currentline) or 'unknown'
        DBase:PrintType('Client.SetValue: module "' .. _tostring(module) .. '" is not registered | caller: ' .. src)
        return false
    end

    local varData = mod.Variables[variable]
    if (not varData) then
        local c = debug.getinfo(2, 'Sl')
        local src = c and (c.source .. ':' .. c.currentline) or 'unknown'
        DBase:PrintType('Client.SetValue: variable "' .. _tostring(variable) .. '" is not registered in module "' .. _tostring(module) .. '" | caller: ' .. src)
        return false
    end

    local handler = DanLib.TypeHandlers[varData.Type]
    if (handler and not handler.Validate(value)) then
        DBase:PrintType('Client.SetValue: invalid type for "' .. variable .. '" in module "' .. module .. '"')
        return false
    end

    if (varData.Validation) then
        local _ok, _ = varData.Validation(value)
        if (not _ok) then
            return false
        end
    end

    if (not DanLib.USERCONFIG[module]) then
        DanLib.USERCONFIG[module] = { }
    end

    DanLib.USERCONFIG[module][variable] = value
    DHook:Run('DanLib.ClientConfigChanged', module, variable, value)

    if instant then
        DanLib.SaveUserConfig()
    else
        DTimer:Create('DanLib_AutoSave_' .. module .. '_' .. variable, 1, 1, function()
            DanLib.SaveUserConfig()
        end)
    end

    return true
end

--- Resets a single user-config variable to its declared default from outside the settings panel.
-- Fires DanLib.ClientConfigChanged and saves to disk immediately.
-- @param module (string): Module ID (e.g. "CHAT").
-- @param variable (string): Variable name to reset.
-- @return bool: true on success, false if module or variable not found.
--
-- Example:
--   DanLib.Client.ResetValue('CHAT', 'WindowWidth')
function DanLib.Client.ResetValue(module, variable)
    local mod = DanLib.UserModules[module]
    if (not mod) then
        return false
    end
    return mod:ResetValue(variable)
end

--- Resets every user-config variable of a module to its declared default from outside the settings panel.
-- Fires DanLib.ClientConfigChanged for each variable and saves to disk via DanLib.SaveUserConfig().
-- @param module (string): Module ID (e.g. "CHAT").
-- @return bool: true on success, false if module not found.
--
-- Example:
--   DanLib.Client.ResetAll('CHAT')
function DanLib.Client.ResetAll(module)
    local mod = DanLib.UserModules[module]
    if (not mod) then
        return false
    end

    mod:ResetAll()
    return true
end

/***
 *   DanLib.Client.ExtendModule
 *
 *   Injects additional per-player options into an already-registered client user-module
 *   from an external addon, without that addon needing to own or create the module.
 *
 *   Which API to use:
 *     DanLib.Client.ExtendModule — per-player settings panel  (DanLib.UserModules).
 *     DanLib.Func.ExtendModule — admin/server config panel  (DanLib.ConfigMeta).
 *
 *   Load-order safe:
 *     • Already registered — callback fires immediately; LoadUserModuleConfig fills in new variables from disk (or defaults if no saved value).
 *     • Not registered yet — callback is stored in DanLib._registeredExtensions and applied automatically inside ModuleMeta.Register.
 *     • Module never exists — callback is silently discarded; no errors.
 *
 *   Error safety: every callback is wrapped in pcall. A broken callback prints an
 *   ErrorNoHalt message but does not block other callbacks or the base module.
 *
 *   @param moduleId (string): ID of the target user-module (e.g. "CHAT").
 *   @param callback (function): Receives the module object as its sole argument.
 *                               Call :AddOption(), :AddCategory(), :SetSortOrder() etc. inside.
 *
 *   Example (in DDI-Chat's cl_mention_hints.lua):
 *
 *     DanLib.Client.ExtendModule('CHAT', function(mod)
 *         local MENTIONS = mod:AddCategory('Mentions', Color(82, 136, 193))
 *         MENTIONS:AddOption('MentionSound', 'Play sound', 'Plays a sound when you are @mentioned.', DanLib.Type.Bool, true)
 *             :HelpText('Uses the DanLib notification sound by default.')
 *     end)
 */
function DanLib.Client.ExtendModule(moduleId, callback)
    _assert(_type(moduleId) == 'string' and #moduleId > 0, '[DanLib] ExtendModule: moduleId must be a non-empty string')
    _assert(_type(callback) == 'function', '[DanLib] ExtendModule: callback must be a function')

    -- Store permanently so Register can re-apply on every call (including InitPostEntity re-loads).
    if (not DanLib._registeredExtensions[moduleId]) then
        DanLib._registeredExtensions[moduleId] = { }
    end
    DTable:Add(DanLib._registeredExtensions[moduleId], callback)

    -- If the module is already registered, apply immediately and reload its config.
    local mod = DanLib.UserModules[moduleId]
    if mod then
        local ok, err = _pcall(callback, mod)
        if (not ok) then
            _ErrorNoHalt('[DanLib] ExtendModule error ("' .. moduleId .. '"): ' .. _tostring(err) .. '\n')
        else
            DanLib.LoadUserModuleConfig(moduleId)
        end
    end
    -- If the module is not registered yet, it will be applied automatically
    -- the next time ModuleMeta.Register is called for this moduleId.
end

--- Serialises every registered user-module's in-memory config values to their respective
-- DATA files under danlib/config/modules/<moduleID>.txt.
-- Fires the DanLib.ClientConfigSaved hook when all files have been written.
-- Called by DanLib.Client.SetValue (debounced), ResetValue, ResetAll, and ShutDown hook.
function DanLib.SaveUserConfig()
    for moduleID, module in _pairs(DanLib.UserModules) do
        if (not DanLib.USERCONFIG[moduleID]) then
            continue
        end

        local data = { }
        for varName, varData in _pairs(module.Variables) do
            local value = DanLib.USERCONFIG[moduleID][varName]
            if (value ~= nil) then
                local handler = DanLib.TypeHandlers[varData.Type]
                if handler then
                    data[varName] = handler.Serialize(value)
                end
            end
        end

        local json = DNetworkUtil:TableToJSON(data, true)
        DFileUtil:Write(ConfigPath .. '/' .. moduleID .. '.txt', json)
    end
    DHook:Run('DanLib.ClientConfigSaved')
end

--- Reads every registered user-module's config file from disk into DanLib.USERCONFIG.
-- Missing or unreadable files fall back to declared default values.
-- Called once at startup and again on InitPostEntity (map change / rejoin).
function DanLib.LoadUserConfig()
    for moduleID, module in _pairs(DanLib.UserModules) do
        DanLib.USERCONFIG[moduleID] = { }

        local path = ConfigPath .. '/' .. moduleID .. '.txt'
        local json = DFileUtil:Read(path, 'DATA')

        if json then
            local data = DNetworkUtil:JSONToTable(json) or { }
            for varName, varData in _pairs(module.Variables) do
                local handler = DanLib.TypeHandlers[varData.Type]
                if handler then
                    local savedValue = data[varName]
                    if (savedValue ~= nil) then
                        local deserialized = handler.Deserialize(savedValue)
                        if (varData.Validation) then
                            local _ok, _ = varData.Validation(deserialized)
                            if (not _ok) then
                                deserialized = varData.Default
                            end
                        end
                        DanLib.USERCONFIG[moduleID][varName] = deserialized
                    else
                        DanLib.USERCONFIG[moduleID][varName] = varData.Default
                    end
                end
            end
        else
            for varName, varData in _pairs(module.Variables) do
                DanLib.USERCONFIG[moduleID][varName] = varData.Default
            end
        end
        -- Attach unknown-key guard so DanLib.USERCONFIG[id].badKey returns nil + warns
        _guardModuleTable(DanLib.USERCONFIG[moduleID], moduleID)
    end
end

--- Partially reloads a single user-module's config from disk, filling only variables
-- absent in DanLib.USERCONFIG (i.e. newly added by an ExtendModule callback).
-- Already-loaded values are never overwritten, preserving any unsaved in-session changes.
-- Called automatically by DanLib.Client.ExtendModule after applying its callback.
-- @param moduleID (string): ID of the module to partially reload (e.g. "CHAT").
function DanLib.LoadUserModuleConfig(moduleID)
    local module = DanLib.UserModules[moduleID]
    if (not module) then
        return
    end

    if (not DanLib.USERCONFIG[moduleID]) then
        local tbl = { }
        _guardModuleTable(tbl, moduleID)
        DanLib.USERCONFIG[moduleID] = tbl
    end

    local path = ConfigPath .. '/' .. moduleID .. '.txt'
    local json = DFileUtil:Read(path, 'DATA')
    local data = json and (DNetworkUtil:JSONToTable(json) or { }) or { }

    for varName, varData in _pairs(module.Variables) do
        if (DanLib.USERCONFIG[moduleID][varName] == nil) then
            local handler = DanLib.TypeHandlers[varData.Type]
            if handler then
                local savedValue = data[varName]
                if (savedValue ~= nil) then
                    local deserialized = handler.Deserialize(savedValue)
                    if (varData.Validation) then
                        local _ok, _ = varData.Validation(deserialized)
                        if (not _ok) then
                            deserialized = varData.Default
                        end
                    end
                    DanLib.USERCONFIG[moduleID][varName] = deserialized
                else
                    DanLib.USERCONFIG[moduleID][varName] = varData.Default
                end
            end
        end
    end
end

--  Module file loading
local configPath = 'danlib/user_modules'

--- Includes every *.lua file found in danlib/user_modules and registers each for client download.
-- Called at startup and again on InitPostEntity to pick up any new module files.
local function LoadModules()
    for _, f in _ipairs(DFileUtil:Find(configPath .. '/*.lua', 'LUA')) do
        AddCSLuaFile(configPath .. '/' .. f)
        include(configPath .. '/' .. f)
    end
end

LoadModules()
DanLib.LoadUserConfig()

DHook:Add('InitPostEntity', 'UserConfig', function()
    LoadModules()
    DanLib.LoadUserConfig()
end)

DHook:Add('ShutDown', 'SaveUserConfig', function()
    DanLib.SaveUserConfig()
end)
