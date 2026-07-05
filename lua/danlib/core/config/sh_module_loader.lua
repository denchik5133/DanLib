/***
 *   @addon         DanLib
 *   @component     Config
 *   @license       MIT License
 *   @version       3.0.6
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   Responsible for loading and managing the server/shared admin configuration of
 *                  DanLib modules. Consumed by the in-game config panel and by external addons
 *                  that extend base modules via DanLib.Func.ExtendModule.
 *
 *   @functions
 *                  ConfigModuleMeta — metatable for every config module object.
 *                  OptionConfigMeta — chainable helper returned by :AddOption().
 *                  DanLib.ConfigMeta — registry of all registered config modules.
 *                  DanLib.CategoryRegistry — registry of all declared option categories.
 *                  DanLib.CONFIG — live config values loaded from disk at startup.
 *
 *   @api
 *                  DanLib.Func.CreateModule(id) — creates a new config module.
 *                  DanLib.Func.ExtendModule(id, cb) — extends an existing module from an external addon.
 *                  DanLib.Func.LoadModuleConfig(id) — partial config reload for a single module.
 *                  DanLib.Func.GetConfigType(mod, var) — returns the type of a config variable.
 *                  DanLib.Func.CopyTypeValue(type, val) — type-safe value copy.
 *                  DanLib.Func.ProcessTypeValue(t, v, rw) — net read/write dispatch.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DTable = DanLib.Table
local DFileUtil = DanLib.FileUtil
local DNetworkUtil = DanLib.NetworkUtil

local _tostring = tostring
local _ipairs = ipairs
local _type = type
local _pairs = pairs
local _pcall = pcall
local _rawget = rawget
local _assert = assert
local _ErrorNoHalt = ErrorNoHalt

--- Returns the declared type of a config variable.
-- @param module (string): Module ID to look up in DanLib.ConfigMeta.
-- @param variable (string): Variable name inside that module.
-- @return string|nil: The type string (e.g. DanLib.Type.Int), or nil if not found.
function DBase.GetConfigType(module, variable)
    if (not DanLib.ConfigMeta[module] or not DanLib.ConfigMeta[module].Variables) then
        return
    end

    local varData = DanLib.ConfigMeta[module].Variables[variable]
    if (not varData) then
        return
    end
    return varData.Type
end

--- Returns a type-safe copy of a value using the registered CopyFunc for that type.
-- Falls back to the original value if the type has no CopyFunc registered.
-- @param type (string): DanLib type identifier (e.g. DanLib.Type.Int).
-- @param value (any): The value to copy.
-- @return any: Deep-copied value, or the original value if no copy function is registered.
function DBase.CopyTypeValue(type, value)
    if (not type or not DanLib.FunctionType[type] or not DanLib.FunctionType[type].CopyFunc) then
        return value
    end
    return DanLib.FunctionType[type].CopyFunc(value)
end

--- Dispatches a net read or write operation for a typed config value.
-- @param type (string): DanLib type identifier (e.g. DanLib.Type.Bool).
-- @param value (any): Value to write (ignored when isWrite is false).
-- @param isWrite (bool): true to call NetWrite, false to call NetRead.
-- @return any|nil: The received value when isWrite is false, nil when writing.
function DBase.ProcessTypeValue(type, value, isWrite)
    if (not type or not DanLib.FunctionType[type]) then
        return
    end

    if isWrite then
        DanLib.FunctionType[type].NetWrite(value)
    else
        return DanLib.FunctionType[type].NetRead()
    end
end


-- MODULE META
DanLib.ConfigMeta = DanLib.ConfigMeta or { }
DanLib.CategoryRegistry = DanLib.CategoryRegistry or { }

-- Permanent registry of all ExtendModule callbacks for server-side modules.
-- Never cleared — Register re-applies them on every call so that
-- module re-registrations never lose extended variables.
DanLib._registeredModuleExtensions = DanLib._registeredModuleExtensions or { }

-- Option configuration object metatable
local OptionConfigMeta = {
    --- Constrains an Int option to a [min, max] range.
    -- Can be called before or after :SetHelp() / :SetFrozen() — order does not matter.
    -- Silently no-ops (prints a warning and keeps the chain) for non-Int types.
    -- @param min (number): Minimum allowed value.
    -- @param max (number): Maximum allowed value (must be >= min).
    -- @return self: Always returns self so the chain continues regardless of outcome.
    SetMinMax = function(self, min, max)
        if (self.Type ~= DanLib.Type.Int) then
            DBase:Print('[ERROR] SetMinMax can only be used with Int type options')
            return self
        end

        if (_type(min) ~= 'number' or _type(max) ~= 'number') then
            DBase:Print('[ERROR] SetMinMax requires numeric min and max values')
            return self
        end

        if (min > max) then
            DBase:Print('[ERROR] SetMinMax: minimum value cannot be greater than maximum value')
            return self
        end

        -- Store the values directly in the parent module's Variables table
        self.Parent.Variables[self.VariableName].MinValue = min
        self.Parent.Variables[self.VariableName].MaxValue = max
        return self
    end,

    --- Attaches a tooltip string shown on hover in the config panel.
    -- Can be called before or after :SetMinMax() / :SetFrozen() — order does not matter.
    -- @param helpText (string): Help text to display as a tooltip.
    -- @return self: Returns self so any other option method can be chained after.
    SetHelp = function(self, helpText)
        if (_type(helpText) ~= 'string') then
            DBase:Print('[ERROR] SetHelp requires a string parameter')
            return self
        end

        self.Parent.Variables[self.VariableName].HelpText = helpText
        return self
    end,

    --- Attaches a custom validator function for this option's value.
    -- The validator is called on config load (from disk) and whenever the admin panel applies a new value.
    -- @param fn (function): function(value) -> true  |  false, reason_string
    --   Return true on success; return false + a short reason string on failure.
    --   On failure the system logs the reason and falls back to the declared default.
    -- @return self: Returns self so any other option method can be chained after.
    -- @xample:
    --   GIF:AddOption('GifLocale', ..., 'en_US')
    --       :SetValidation(function(v)
    --           if not string.match(v, '^%l%l_%u%u$') then
    --               return false, 'Expected xx_XX format (e.g. en_US, ru_RU)'
    --           end
    --           return true
    --       end)
    SetValidation = function(self, fn)
        if (_type(fn) ~= 'function') then
            DBase:Print('[ERROR] SetValidation requires a function parameter')
            return self
        end
        self.Parent.Variables[self.VariableName].Validation = fn
        return self
    end,

    --- Marks this option as frozen (read-only) in the config panel.
    -- The row remains visible but all input controls are disabled.
    -- Frozen options are never staged or saved by the client — display only.
    -- Can be called before or after :SetHelp() / :SetMinMax() — order does not matter.
    -- Terminal call — returns the parent module for the next :AddOption().
    -- @return parent: Returns the parent module object for continued chaining with :AddOption().
    SetFrozen = function(self)
        self.Parent.Variables[self.VariableName].Frozen = true
        return self.Parent
    end
}
OptionConfigMeta.__index = OptionConfigMeta

local ConfigModuleMeta = {
    --- Registers this module into DanLib.ConfigMeta and re-applies all
    -- ExtendModule callbacks stored in DanLib._registeredModuleExtensions.
    -- Safe to call multiple times — callbacks are never lost between re-registrations.
    -- @return self: Returns the module object for continued method chaining.
    Register = function(self)
        DanLib.ConfigMeta[self.ID] = self

        local extensions = DanLib._registeredModuleExtensions[self.ID]
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

    --- Sets the display title shown in the config panel header.
    -- @param title (string): Human-readable module title.
    -- @return self: Returns the module object for continued method chaining.
    SetTitle = function(self, title)
        self.Title = title
        return self
    end,

    --- Sets the icon shown next to the module in the config panel sidebar.
    -- @param icon (string): Icon material path or icon key.
    -- @return self: Returns the module object for continued method chaining.
    SetIcon = function(self, icon)
        self.Icon = icon
        return self
    end,

    --- Records the author name for display in the config panel.
    -- @param author (string): Author name or Steam alias.
    -- @return self: Returns the module object for continued method chaining.
    SetAuthor = function(self, author)
        self.Author = author
        return self
    end,

    --- Records the module version string for display in the config panel.
    -- @param version (string): Semantic version string (e.g. "1.2.0").
    -- @return self: Returns the module object for continued method chaining.
    SetVersion = function(self, version)
        self.Version = version
        return self
    end,

    --- Sets the accent colour used for this module in the config panel.
    -- @param color (Color): GMod Color object used for highlights and headers.
    -- @return self: Returns the module object for continued method chaining.
    SetColor = function(self, color)
        self.Color = color
        return self
    end,

    --- Sets the long-form description shown in the config panel detail view.
    -- @param description (string): Full description of what this module controls.
    -- @return self: Returns the module object for continued method chaining.
    SetDescription = function(self, description)
        self.Description = description
        return self
    end,

    --- Declares a directory whose *.lua files should be included by the module loader.
    -- @param path (string): Relative path to the include directory (e.g. "danlib/modules/chat").
    -- @return self: Returns the module object for continued method chaining.
    SetIncludeDir = function(self, path)
        self.IncludeDir = path
        --DanLib.loader.IncludeDir(path, true)
        return self
    end,

    --- Declares a single Lua file to be included by the module loader.
    -- @param path (string): Relative path to the Lua file.
    -- @return self: Returns the module object for continued method chaining.
    SetInclude = function(self, path)
        self.Include = path
        --DanLib.loader.Include(path) // (self.ID .. '/' .. path)
        return self
    end,

    --- Sets the numeric sort order that determines module position in the config panel sidebar.
    -- Lower values appear first. Defaults to 0.
    -- @param sortOrder (number): Sort priority for this module.
    -- @return self: Returns the module object for continued method chaining.
    SetSortOrder = function(self, sortOrder)
        self.SortOrder = sortOrder
        return self
    end,

    --- Declares a named visual category group and returns a category object.
    -- Options added via the returned object are automatically tagged with this category
    -- and grouped together (with a separator header) in the config panel.
    -- Registers the category in DanLib.CategoryRegistry if not already present.
    -- @param categoryName (string): Display name for the category group.
    -- @param categoryColor (Color): Accent colour for the category header (optional, default blue).
    -- @param categoryIcon (string): Icon material or key for the header (optional).
    -- @return table: Category object; call :AddOption() on it to add grouped options.
    AddCategory = function(self, categoryName, categoryColor, categoryIcon)
        if (not DanLib.CategoryRegistry[categoryName]) then
            DanLib.CategoryRegistry[categoryName] = {
                Name = categoryName,
                Color = categoryColor or Color(67, 156, 242), -- Default blue color
                Icon = categoryIcon or nil,
                Order = DTable:Count(DanLib.CategoryRegistry) + 1
            }
        end

        -- Create category object
        local categoryObj = {
            Name = categoryName,
            Module = self,
            AddOption = function(catSelf, variable, name, description, type, default, vguiElement, getOptions, action)
                -- Delegate to main AddOption with category parameter
                return self:AddOption(variable, name, description, type, default, vguiElement, getOptions, action, categoryName)
            end
        }

        return categoryObj
    end,

    --- Adds a configurable option to this module.
    -- Returns a chainable OptionConfigMeta object so you can call :SetMinMax() / :SetHelp() immediately.
    -- @param variable (string): Internal key used in DanLib.CONFIG[moduleID][variable].
    -- @param name (string): Human-readable label shown in the config panel.
    -- @param description (string): Tooltip / subtitle text for the option row.
    -- @param type (string): DanLib type constant (e.g. DanLib.Type.Bool, DanLib.Type.Int).
    -- @param default (any): Default value — must match the declared type.
    -- @param vguiElement (string): VGUI element class used to render this option (optional).
    -- @param getOptions (function): Supplier called to populate dynamic dropdown lists (optional).
    -- @param action (function|string): Called or registered when the value changes (optional).
    -- @param category (string): Category name from :AddCategory() for grouping (internal, optional).
    -- @return OptionConfigMeta: Chainable object; call :SetMinMax() and/or :SetHelp() on it.
    AddOption = function(self, variable, name, description, type, default, vguiElement, getOptions, action, category)
        self.Variables[variable] = {
            Name = name,
            Description = description,
            Type = type,
            VguiElement = vguiElement or (type == DanLib.Type.Table && 'EditablePanel'),
            GetOptions = getOptions,
            Default = default,
            Action = action or nil,
            Order = DTable:Count(self.Variables) + 1,
            Category = category or nil
        }

        -- Create chainable option configuration object
        local optionConfig = {
            Parent = self,
            VariableName = variable,
            Type = type
        }

        setmetatable(optionConfig, OptionConfigMeta)

        return optionConfig
    end,

    --- Returns a flat, ordered list of this module's variables ready for the config panel UI.
    -- Uncategorised options appear first (sorted by Order).
    -- Each category block is preceded by a CategorySeparator sentinel row
    -- { IsSeparator=true, Type="CategorySeparator", Name=..., CategoryInfo=... }.
    -- @return table: Flat list of variable data rows (and separator sentinels) sorted for display.
    GetSorted = function(self)
        local sortedVariables = { }
        local categorizedVars = { }
        local uncategorizedVars = { }

        -- Separate variables into categorized and uncategorized
        for k, v in _pairs(self.Variables) do
            local data = { }
            for key, value in _pairs(v) do
                data[key] = value
            end
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

        -- Sort uncategorized variables first (maintain existing behavior)
        DTable:SortByMember(uncategorizedVars, 'Order', false)
        for _, var in _ipairs(uncategorizedVars) do
            DTable:Add(sortedVariables, var)
        end

        -- Sort categories by their registration order
        local sortedCategories = { }
        for categoryName, vars in _pairs(categorizedVars) do
            local categoryInfo = DanLib.CategoryRegistry and DanLib.CategoryRegistry[categoryName]
            DTable:Add(sortedCategories, {
                Name = categoryName,
                Variables = vars,
                Order = categoryInfo and categoryInfo.Order or 999,
                Info = categoryInfo
            })
        end
        DTable:SortByMember(sortedCategories, 'Order', false)

        -- Add categorized variables with separators
        for _, category in _ipairs(sortedCategories) do
            -- Add category separator
            DTable:Add(sortedVariables, {
                Type = 'CategorySeparator',
                Name = category.Name,
                CategoryInfo = category.Info,
                IsSeparator = true
            })

            -- Sort variables within category
            DTable:SortByMember(category.Variables, 'Order', false)
            for _, var in _ipairs(category.Variables) do
                DTable:Add(sortedVariables, var)
            end
        end

        return sortedVariables
    end,

    --- Returns the declared default value for a variable without reading DanLib.CONFIG.
    -- Returns nil (with a console warning) if the variable was never registered via AddOption.
    -- @param variable (string): Variable name.
    -- @return any: The default value declared in :AddOption(), or nil if not found.
    GetDefaultValue = function(self, variable)
        local varData = self.Variables[variable]
        if (not varData) then
            local c = debug.getinfo(2, 'Sl')
            local src = c and (c.source .. ':' .. c.currentline) or 'unknown'
            DBase:Print('GetDefaultValue: variable "' .. _tostring(variable) .. '" is not registered in module "' .. _tostring(self.ID) .. '" | caller: ' .. src)
            return nil
        end
        return varData.Default
    end,

    --- Returns the live config value from DanLib.CONFIG, falling back to the declared default.
    -- The value is deep-copied via DanLib.Func.CopyTypeValue to prevent accidental mutation.
    -- Returns nil (with a console warning) if the variable was never registered via AddOption.
    -- @param variable (string): Variable name.
    -- @return any: Current value from DanLib.CONFIG, or the declared default if not set, or nil if unknown.
    GetValue = function(self, variable)
        local varData = self.Variables[variable]
        if (not varData) then
            local c = debug.getinfo(2, 'Sl')
            local src = c and (c.source .. ':' .. c.currentline) or 'unknown'
            DBase:Print('GetValue: variable "' .. _tostring(variable) .. '" is not registered in module "' .. _tostring(self.ID) .. '" | caller: ' .. src)
            return nil
        end

        local savedVal = DanLib.CONFIG[self.ID][variable]
        local resolvedVal = (savedVal ~= nil) and savedVal or varData.Default
        return DBase.CopyTypeValue(varData.Type, resolvedVal)
    end
}
ConfigModuleMeta['__index'] = ConfigModuleMeta


--- Creates a new server/shared config module with ConfigModuleMeta as its metatable.
-- Chain the returned object with :SetTitle(), :AddOption(), :AddCategory(), etc.,
-- then call :Register() to add it to DanLib.ConfigMeta.
-- @param id (string): Unique module ID — used as the key in DanLib.ConfigMeta and DanLib.CONFIG.
-- @return table: New module object with all ConfigModuleMeta methods available.
function DBase.CreateModule(id)
    local module = {
        ID = id,
        Variables = { },
        SortOrder = 0
    }
    setmetatable(module, ConfigModuleMeta)
    return module
end

--- Partially reloads a single module's config from disk, filling only variables
-- absent in DanLib.CONFIG (i.e. newly added by an ExtendModule callback).
-- Already-loaded values are never overwritten, preserving runtime admin changes.
-- On the CLIENT this is a no-op for disk reads — values arrive via server network sync.
-- Called automatically by DanLib.Func.ExtendModule after applying its callback.
-- @param moduleID (string): ID of the module to partially reload (e.g. "CHAT").
function DBase.LoadModuleConfig(moduleID)
    local module = DanLib.ConfigMeta[moduleID]
    if (not module) then
        return
    end

    if (not DanLib.CONFIG[moduleID]) then
        DanLib.CONFIG[moduleID] = { }
    end

    local configFile = 'danlib/config'
    local savedModule = DNetworkUtil:JSONToTable(DFileUtil:Read(configFile .. '/' .. moduleID .. '.txt', 'DATA') or '') or { }

    for key, val in _pairs(module.Variables) do
        -- rawget bypasses the __index proxy set by configMeta() so that variables
        -- added later via ExtendModule (e.g. DDI-Chat's Announcements) are
        -- correctly detected as absent and populated from disk.
        -- Without rawget the proxy returns the declared Default (a non-nil value)
        -- for any variable that is now in ConfigMeta.Variables, so the real saved
        -- data would be silently skipped every time.
        if (_rawget(DanLib.CONFIG[moduleID], key) == nil) then
            local diskVal = savedModule[key]
            if (diskVal ~= nil and val.Validation) then
                local _ok, _ = val.Validation(diskVal)
                if (not _ok) then
                    diskVal = nil
                end
            end
            DanLib.CONFIG[moduleID][key] = (diskVal ~= nil) and diskVal or val.Default
        end
    end
end
  
-- Injects additional options into an already-registered server/shared config module
-- from an external addon, without that addon needing to own or create the module.
-- Safe to call from shared (client + server) files.
--    
-- Which API to use:
--   DanLib.Func.ExtendModule — admin/server config panel (DanLib.ConfigMeta).
--   DanLib.Client.ExtendModule — per-player settings panel (DanLib.UserModules).
--    
-- Load-order safe:
--   • Already registered — callback fires immediately; LoadModuleConfig fills in new variables from disk (SERVER) or defaults (CLIENT).
--   • Not registered yet — callback is stored in DanLib._registeredModuleExtensions and applied automatically inside ConfigModuleMeta.Register.
--   • Module never exists — callback is silently discarded; no errors.
--    
-- Error safety: every callback is wrapped in pcall. A broken callback prints an
-- ErrorNoHalt message but does not block other callbacks or the base module.
--    
-- @param moduleId (string): ID of the target module (e.g. "CHAT").
-- @param callback (function): Receives the module object as its sole argument.
--                             Call :AddOption(), :AddCategory(), :SetSortOrder() etc. inside.
--        
-- @example
--   DanLib.Func.ExtendModule('CHAT', function(mod)
--       local CAT = mod:AddCategory('AntiSpam', Color(245, 158, 11))
--       CAT:AddOption('rate_limit', 'Rate limit', 'Max messages / second.', DanLib.Type.Int, 5)
--           :SetMinMax(1, 20)
--           :SetHelp('Requires chat reload (ddi_chat_reload) to take effect.')
--   end)
function DBase.ExtendModule(moduleId, callback)
    _assert(_type(moduleId) == 'string' and #moduleId > 0, '[DanLib] Func.ExtendModule: moduleId must be a non-empty string')
    _assert(_type(callback) == 'function', '[DanLib] Func.ExtendModule: callback must be a function')

    -- Store permanently so Register re-applies on every call.
    if (not DanLib._registeredModuleExtensions[moduleId]) then
        DanLib._registeredModuleExtensions[moduleId] = { }
    end
    DTable:Add(DanLib._registeredModuleExtensions[moduleId], callback)

    -- If the module is already registered, apply immediately and reload config.
    local mod = DanLib.ConfigMeta[moduleId]
    if mod then
        local ok, err = _pcall(callback, mod)
        if (not ok) then
            _ErrorNoHalt('[DanLib] Func.ExtendModule error ("' .. moduleId .. '"): ' .. _tostring(err) .. '\n')
        else
            DBase.LoadModuleConfig(moduleId)
        end
        return
    end
    -- Not registered yet — Register will apply the callback when the module is created.
end


local ConfigFile = 'danlib/config'
local ModuleFile = 'danlib/modules'
local SharedFile = 'danlib/shared'

--- Includes every *.lua file found in the given directory and registers each for client download.
-- @param directory (string): LUA-relative path to the directory (e.g. "danlib/modules").
local function LoadFiles(directory)
    for _, file in _ipairs(DFileUtil:Find(directory .. '/*.lua', 'LUA')) do
        AddCSLuaFile(directory .. '/' .. file)
        include(directory .. '/' .. file)
    end
end

LoadFiles(ModuleFile)
LoadFiles(SharedFile)
DFileUtil:CreateDir(ConfigFile)

-- Dedup cache: stores already-warned (module / module+key) combos so the
-- console does not spam when the same missing path is hit every frame.
-- Shared with cl_admin.lua via DanLib namespace so both sides use one table.
DanLib._warnedConfigKeys = DanLib._warnedConfigKeys or { }
local _warnedCfg = DanLib._warnedConfigKeys

-- Helper: emit a one-shot debug warning when Debugg is enabled.
-- Uses rawget to read BASE.Debugg without triggering __index recursion.
local function _cfgWarn(msg)
    local base = _rawget(DanLib.CONFIG, 'BASE')
    if (base and _rawget(base, 'Debugg')) then
        DBase:Print('[CONFIG] ' .. msg)
    end
end

DanLib.CONFIG = setmetatable({ }, {
    -- If the module is not registered or not synchronized yet —
    -- we return the proxy table with defaults instead of nil.
    -- Returning a proxy (not nil) keeps chained access like
    -- DanLib.CONFIG.X.Y safe — no attempt-to-index-nil crash.
    -- NOTE: (DanLib.CONFIG.X ~= nil) is always true even for unknown
    -- modules. Use DanLib.ConfigMeta[id] to check module existence.
    __index = function(_, moduleID)
        local meta = DanLib.ConfigMeta[moduleID]
        if (not meta) then
            -- Unknown module — warn once in debug mode, then return nil-proxy
            local wk = 'mod:' .. _tostring(moduleID)
            if (not _warnedCfg[wk]) then
                _warnedCfg[wk] = true
                _cfgWarn('Access to unregistered module "' .. _tostring(moduleID) .. '" — returning nil-proxy. Use DanLib.ConfigMeta to check existence.')
            end
            return setmetatable({ }, {
                __index = function()
                    return nil
                end
            })
        end

        -- A well-known module, but not yet synchronized: return defaults
        return setmetatable({ }, {
            __index = function(_, key)
                local varMeta = meta.Variables[key]
                return varMeta and varMeta.Default or nil
            end
        })
    end
})

--- Reads every registered module's config file from DATA and populates DanLib.CONFIG.
-- Missing keys fall back to their declared default values.
-- Called once at startup after all module files have been included.
local function configMeta()
    for k, v in _pairs(DanLib.ConfigMeta) do
        local savedModule = DNetworkUtil:JSONToTable(DFileUtil:Read(ConfigFile .. '/' .. k .. '.txt', 'DATA') or '') or { }

        local module = { }
        for key, val in _pairs(v.Variables) do
            local diskVal = savedModule[key]
            if (diskVal ~= nil and val.Validation) then
                local _ok, _ = val.Validation(diskVal)
                if (not _ok) then
                    diskVal = nil
                end
            end
            module[key] = (diskVal ~= nil) and diskVal or val.Default
        end

        -- Guard: warn early if a module exceeds the 8-bit network counter limit (255 variables).
        local _varCount = DTable:Count(v.Variables)
        if (_varCount > 255) then
            DBase:Print('[ERROR] Module "' .. k .. '" has ' .. _tostring(_varCount) .. ' variables — max is 255. Config sync will be broken. Reduce AddOption() calls in this module.')
        end

        -- Protection against adding new variables via ExtendModule after loading:
        -- if the key was not on the disk and did not get into the table, we give the default
        local moduleID = k
        setmetatable(module, {
            __index = function(_, key)
                local meta = DanLib.ConfigMeta[moduleID]
                if (meta and meta.Variables[key]) then
                    return meta.Variables[key].Default
                end
                -- Unknown key — warn once in debug mode
                local wk = moduleID .. ':' .. _tostring(key)
                if (not _warnedCfg[wk]) then
                    _warnedCfg[wk] = true
                    _cfgWarn('Access to unknown key "' .. _tostring(key) .. '" in module "' .. moduleID .. '" — returning nil.')
                end
                return nil
            end
        })
        DanLib.CONFIG[k] = module
    end
end
configMeta()
