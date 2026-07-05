/***
 *   @addon         DanLib
 *   @component     Version Control & Validation
 *   @license       MIT License
 *   @version       1.2.0
 *   @release_date  17/12/2024
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *   
 *   @description   Semantic versioning system with compatibility checking and automatic update detection.
 *                  Validates addon dependencies, prevents incompatible loads, and notifies about updates.
 *   
 *   @functions
 *                  - Semantic versioning (major.minor.patch) with comparison
 *                  - Automatic compatibility validation before addon load
 *                  - GitHub-based update checking with download URLs
 *                  - Strict/permissive mode for compatibility enforcement
 *                  - Auto-registration via loader hooks
 *                  - Centralized addon/library registry
 *                  - Development version detection (ahead of GitHub)
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/DanLib
 *
 *   @notes         Requires HTTP module for update checking. GitHub JSON URL configurable in Config.GitHub.URL.
 *                  For feature requests or bug reports, please open an issue on GitHub.
 */




local DHook = DanLib.Hook
local DTable = DanLib.Table
local DNetworkUtil = DanLib.NetworkUtil

DanLib.VersionControl = DanLib.VersionControl or { }
local DVersionControl = DanLib.VersionControl

-- Cached functions
local _pairs = pairs
local _ipairs = ipairs
local _stringformat = string.format
local _stringExplode = string.Explode
local _tonumber = tonumber
local _tostring = tostring
local _MsgC = MsgC
local _Color = Color
local _HTTP = HTTP
local _type = type
local _pcall = pcall
local _osTime = os.time

-- Colors
local COLOR_ERROR = _Color(255, 50, 50)
local COLOR_WARNING = _Color(255, 200, 50)
local COLOR_SUCCESS = _Color(100, 255, 100)
local COLOR_INFO = _Color(100, 200, 255)
local COLOR_GRAY = _Color(150, 150, 150)
local COLOR_WHITE = color_white


DVersionControl.Registered = { }

-- Configuration
DVersionControl.Config = {
    GitHub = {
        Enabled = true,
        URL = 'https://raw.githubusercontent.com/denchik5133/DDI-Other-Informations/main/DDI/update.json'
    },
    API = {
        Enabled = false,
        BaseURL = 'https://api.danlib.dev',
        Endpoints = {
            VersionCheck = '/v1/version',
            LicenseValidate = '/v1/license/validate',
            Compatibility = '/v1/compatibility'
        }
    },
    CompatibilityCheck = {
        Enabled = true,
        StrictMode = true
    },
    UpdateCheck = {
        Enabled = true,
        AutoCheck = true
    }
}

--- Parse version string into components
-- @param version (string): Version string (e.g., '3.2.0')
-- @return table|nil Parsed version table with major, minor, patch fields
--- Pre-release keywords that mark a version as unstable.
local PRE_RELEASE_KEYWORDS = { 'beta', 'alpha', 'dev', 'rc', 'nightly', 'snapshot', 'preview' }

--- Checks whether a version string contains any pre-release keyword.
-- @param lower (string): Lower-cased version string.
-- @return boolean
local function _isPreRelease(lower)
    for _, kw in _ipairs(PRE_RELEASE_KEYWORDS) do
        if lower:find(kw, 1, true) then
            return true
        end
    end
    return false
end

local function _parseVersion(version)
    if (not version) then
        return nil
    end

    local str   = _tostring(version)
    local lower = str:lower()
    local preRelease = _isPreRelease(lower)

    -- Strip pre-release suffix so '1.0.0-beta' parses as '1.0.0'
    local numericStr = str:match('^([%d%.]+)') or str
    local parts = _stringExplode('.', numericStr)

    if (#parts < 2) then
        -- Pure non-semver label: 'BETA', 'DEV', etc.
        return {
            major = 0, minor = 0, patch = 0,
            string = str,
            isPreRelease = true,
            preReleaseLabel = str:upper()
        }
    end

    return {
        major = _tonumber(parts[1]) or 0,
        minor = _tonumber(parts[2]) or 0,
        patch = _tonumber(parts[3]) or 0,
        string = str,
        isPreRelease = preRelease
    }
end

--- Compare two version strings
-- @param v1 (string|table): First version
-- @param v2 (string|table): Second version
-- @return number 1 if v1 > v2, -1 if v1 < v2, 0 if equal
function DVersionControl:CompareVersions(v1, v2)
    local ver1 = _type(v1) == 'table' and v1 or _parseVersion(v1)
    local ver2 = _type(v2) == 'table' and v2 or _parseVersion(v2)
    
    if (not ver1 or not ver2) then
        return 0
    end
    
    if (ver1.major > ver2.major) then
        return 1
    end

    if (ver1.major < ver2.major) then
        return -1
    end

    if (ver1.minor > ver2.minor) then
        return 1
    end

    if (ver1.minor < ver2.minor) then
        return -1
    end

    if (ver1.patch > ver2.patch) then
        return 1
    end

    if (ver1.patch < ver2.patch) then
        return -1
    end
    
    return 0
end

--- Check if an item is compatible with required version
-- @param name (string): Name of the item to check
-- @param required (string): Required version (e.g., "3.0.0")
-- @return boolean Compatible
-- @return string|nil Error message if incompatible
function DVersionControl:IsCompatible(name, required)
    local item = DVersionControl.Registered[name]
    if (not item) then
        return false, 'Item "' .. name .. '" not registered'
    end
    
    local reqVer = _parseVersion(required)
    local curVer = item.parsedVersion
    
    if (not reqVer) then
        return false, 'Invalid version format'
    end
    
    if (reqVer.major ~= curVer.major) then
        return false, _stringformat('Major version mismatch (required: %d.x.x, current: %d.x.x)', reqVer.major, curVer.major)
    end
    
    if (curVer.minor < reqVer.minor) then
        return false, _stringformat('%s too old (required: %s+, current: %s)', name, required, item.version)
    end
    
    return true
end

--- Register a library or addon in the version control system
-- @param info (table): Registration information
--   - name (string): Item name
--   - version (string): Version string
--   - githubName (string|nil): Name used in GitHub JSON
--   - license (string|nil): License type
--   - dependsOn (string|nil): Dependency name (for addons)
--   - requiredVersion (string|nil): Required dependency version (for addons)
-- @return boolean Success
-- @return string|nil Error message if failed
function DVersionControl:Register(info)
    if (not info or not info.name) then
        return false, 'Missing name'
    end
    
    if (not info.version) then
        return false, 'Missing version'
    end

    -- Warn immediately when a pre-release version is registered
    local _parsedVer = _parseVersion(info.version)
    if (_parsedVer and _parsedVer.isPreRelease) then
        local label = _parsedVer.preReleaseLabel or _parsedVer.string
        _MsgC(COLOR_GRAY,    '\n/***\n')
        _MsgC(COLOR_GRAY,    ' *   ')
        _MsgC(COLOR_WARNING, 'PRE-RELEASE VERSION\n')
        _MsgC(COLOR_GRAY,    ' *\n')
        _MsgC(COLOR_GRAY,    ' *   @addon         ')
        _MsgC(COLOR_INFO,    info.name, '\n')
        _MsgC(COLOR_GRAY,    ' *   @version       ')
        _MsgC(COLOR_WARNING, info.version, '\n')
        _MsgC(COLOR_GRAY,    ' *\n')
        _MsgC(COLOR_GRAY,    ' *   @warning       ')
        _MsgC(COLOR_WARNING, 'This is a pre-release build (' .. label .. ').\n')
        _MsgC(COLOR_GRAY,    ' *                  ')
        _MsgC(COLOR_GRAY,    'Bugs and breaking changes are expected.\n')
        _MsgC(COLOR_GRAY,    ' *                  ')
        _MsgC(COLOR_GRAY,    'Not recommended for production servers.\n')
        _MsgC(COLOR_GRAY,    ' */\n\n')
    end

    local isAddon = info.dependsOn ~= nil or info.requiredVersion ~= nil or info.requiredDanLibVersion ~= nil
    if isAddon then
        local dependsOn = info.dependsOn or 'DanLib'
        local requiredVersion = info.requiredVersion or info.requiredDanLibVersion
        
        if (not requiredVersion) then
            return false, 'Missing requiredVersion'
        end
        
        local compatible, reason = self:IsCompatible(dependsOn, requiredVersion)
        if (not compatible) then
            local dependency = self.Registered[dependsOn]
            local dependencyVersion = dependency and dependency.version or 'Unknown'
            
            _MsgC(COLOR_ERROR, '\n[VersionControl] ', COLOR_WHITE, 'Addon "', COLOR_WARNING, info.name, COLOR_WHITE, '" is INCOMPATIBLE!\n')
            _MsgC(COLOR_ERROR, '  ', reason, '\n')
            _MsgC(COLOR_INFO, '  → Required ', dependsOn, ': ', COLOR_WHITE, requiredVersion, '+\n')
            _MsgC(COLOR_INFO, '  → Current ', dependsOn, ': ', COLOR_WHITE, dependencyVersion, '\n')
            
            local strictMode = info.strictMode
            if (strictMode == nil) then
                strictMode = self.Config.CompatibilityCheck.StrictMode
            end
            
            if strictMode then
                _MsgC(COLOR_ERROR, '  BLOCKING ADDON LOAD\n\n')
                return false, reason
            else
                _MsgC(COLOR_WARNING, '  Loading anyway (Strict Mode disabled)\n\n')
            end
        end
        
        self.Registered[info.name] = {
            type = 'addon',
            name = info.name,
            version = info.version,
            parsedVersion = _parseVersion(info.version),
            githubName = info.githubName or info.name,
            githubAliases = info.githubAliases or { },
            license = info.license,
            dependsOn = dependsOn,
            requiredVersion = requiredVersion,
            compatible = compatible,
            incompatibilityReason = reason,
            registeredAt = _osTime()
        }
        
        return true
    else
        self.Registered[info.name] = {
            type = 'library',
            name = info.name,
            version = info.version,
            parsedVersion = _parseVersion(info.version),
            githubName = info.githubName or info.name,
            githubAliases = info.githubAliases or { },
            license = info.license or 'Unknown',
            registeredAt = _osTime()
        }
        
        if (info.name == 'DanLib') then
            DanLib_AddonsName = info.name
            DanLib_Version = info.version
        end
        
        return true
    end
end

--- Get registered item by name
-- @param name (string): Item name
-- @return table|nil Item data or nil if not found
function DVersionControl:Get(name)
    return self.Registered[name]
end

--- Check if an item is registered
-- @param name (string): Item name
-- @return boolean True if registered
function DVersionControl:IsRegistered(name)
    return self.Registered[name] ~= nil
end

--- Get all registered items, optionally filtered by type
-- @param itemType (string|nil): Filter by type ('library' or 'addon'), nil for all
-- @return table Registered items
function DVersionControl:GetAll(itemType)
    if (not itemType) then
        return self.Registered
    end
    
    local result = { }
    for name, item in _pairs(self.Registered) do
        if (item.type == itemType) then
            result[name] = item
        end
    end
    return result
end

--- Check for updates from GitHub
-- @param name (string|nil): Item name to check (defaults to 'DanLib')
-- @param callback (function|nil): Callback function(hasUpdate, latestVersion, downloadURL, error)
function DVersionControl:CheckForUpdates(name, callback)
    name = name or 'DanLib'
    
    if (not self.Config.GitHub.Enabled) then
        if callback then
            callback(false, nil, nil, 'GitHub disabled')
        end
        return
    end
    
    local item = self.Registered[name]
    if (not item) then
        if callback then
            callback(false, nil, nil, 'Not registered')
        end
        return
    end
    
    local url = self.Config.GitHub.URL
    
    _HTTP({
        url = url,
        method = 'GET',
        success = function(code, body)
            if (code ~= 200) then
                if callback then
                    callback(false, nil, nil, 'HTTP ' .. code)
                end
                return
            end
            
            local success, data = _pcall(util.JSONToTable, body)
            if (not success or not data) then
                if callback then
                    callback(false, nil, nil, 'JSON parse failed')
                end
                return
            end
            
            -- Try primary githubName, then aliases
            local itemData = data[item.githubName]
            local resolvedKey = item.githubName
            if (itemData == nil and item.githubAliases) then
                for _, alias in _ipairs(item.githubAliases) do
                    if (data[alias] ~= nil) then
                        itemData = data[alias]
                        resolvedKey = alias
                        break
                    end
                end
            end
            
            local latestVersion, downloadURL
            
            if (_type(itemData) == 'table') then
                latestVersion = itemData.version
                downloadURL = itemData.url
            elseif (_type(itemData) == 'string') then
                latestVersion = itemData
                downloadURL = data[resolvedKey .. '.url']
            end
            
            if (not latestVersion) then
                _MsgC(COLOR_ERROR, '[VersionControl] No version info for "', name, '" (key: "', item.githubName, '")\n')
                if callback then
                    callback(false, item.version, nil, 'No version info')
                end
                return
            end
            
            -- Compare: github with current
            -- Result: 1 = github newer, -1 = current newer, 0 = equal
            local comparison = self:CompareVersions(latestVersion, item.version)
            if (comparison > 0) then
                _MsgC(COLOR_GRAY, '\n/***\n')
                _MsgC(COLOR_GRAY, ' *   ')
                _MsgC(COLOR_WARNING, 'UPDATE AVAILABLE\n')
                _MsgC(COLOR_GRAY, ' *\n')
                
                _MsgC(COLOR_GRAY, ' *   @name          ')
                _MsgC(COLOR_INFO, name, '\n')
                
                _MsgC(COLOR_GRAY, ' *   @current       ')
                _MsgC(COLOR_WARNING, item.version, '\n')
                
                _MsgC(COLOR_GRAY, ' *   @latest        ')
                _MsgC(COLOR_SUCCESS, latestVersion, '\n')
                
                if downloadURL then
                    _MsgC(COLOR_GRAY, ' *\n')
                    _MsgC(COLOR_GRAY, ' *   @download      ')
                    _MsgC(COLOR_WHITE, downloadURL, '\n')
                end
                
                _MsgC(COLOR_GRAY, ' */\n\n')
                
                if callback then
                    callback(true, latestVersion, downloadURL, nil)
                end
                
            elseif (comparison < 0) then
                _MsgC(COLOR_GRAY, '\n/***\n')
                _MsgC(COLOR_GRAY, ' *   ')
                _MsgC(COLOR_INFO, 'VERSION AHEAD OF GITHUB\n')
                _MsgC(COLOR_GRAY, ' *\n')
                
                _MsgC(COLOR_GRAY, ' *   @name          ')
                _MsgC(COLOR_INFO, name, '\n')
                
                _MsgC(COLOR_GRAY, ' *   @current       ')
                _MsgC(COLOR_SUCCESS, item.version, '\n')
                
                _MsgC(COLOR_GRAY, ' *   @github        ')
                _MsgC(COLOR_WHITE, latestVersion, '\n')
                
                _MsgC(COLOR_GRAY, ' *\n')
                _MsgC(COLOR_GRAY, ' *   @note          ')
                _MsgC(COLOR_GRAY, 'Development version or GitHub not updated\n')
                
                _MsgC(COLOR_GRAY, ' */\n\n')
                
                if callback then
                    callback(false, item.version, nil, 'Ahead of GitHub')
                end
            else
                if callback then
                    callback(false, item.version, nil, nil)
                end
            end
        end,
        failed = function(error)
            _MsgC(COLOR_ERROR, '[VersionControl] Failed to check updates for ', name, ': ', _tostring(error), '\n')
            if callback then
                callback(false, nil, nil, _tostring(error))
            end
        end
    })
end

-- Auto registration hook
DHook:Add('DanLib.Loader.OnRegister', 'DanLib.VersionControl.AutoRegister', function(loader)
    if (not loader) then
        return
    end
    
    local success = DVersionControl:Register({
        name = loader:GetName(),
        version = loader:GetVersion(),
        githubName = loader:GetGitHubName(),
        license = loader:GetLicense(),
        dependsOn = loader:GetDependsOn(),
        requiredVersion = loader:GetRequiredVersion()
    })
    
    if (success and DVersionControl.Config.UpdateCheck.AutoCheck and SERVER) then
        DanLib.Timer:Simple(5, function()
            DVersionControl:CheckForUpdates(loader:GetName())
        end)
    end
end)

-- Print all registered items to console
function DVersionControl:PrintInfo()
    _MsgC(COLOR_INFO, '\n========================================\n')
    _MsgC(COLOR_INFO, '  Version Control System\n')
    _MsgC(COLOR_INFO, '========================================\n\n')
    
    local libraries = { }
    local addons = { }
    
    for name, item in _pairs(DVersionControl.Registered) do
        if (item.type == 'library') then
            DTable:Add(libraries, item)
        else
            DTable:Add(addons, item)
        end
    end
    
    if (#libraries > 0) then
        _MsgC(COLOR_WHITE, '  Libraries (', COLOR_SUCCESS, _tostring(#libraries), COLOR_WHITE, '):\n\n')
        for i = 1, #libraries do
            local lib = libraries[i]
            _MsgC(COLOR_WHITE, '  • ', COLOR_INFO, lib.name, COLOR_WHITE, ' v', lib.version)
            if (lib.githubName ~= lib.name) then
                _MsgC(COLOR_GRAY, ' (GitHub: ', lib.githubName, ')')
            end
            _MsgC(COLOR_WHITE, '\n')
        end
    end
    
    if (#addons > 0) then
        _MsgC(COLOR_WHITE, '\n  Addons (', COLOR_SUCCESS, _tostring(#addons), COLOR_WHITE, '):\n\n')
        for i = 1, #addons do
            local addon = addons[i]
            local color = addon.compatible and COLOR_SUCCESS or COLOR_ERROR
            local icon = addon.compatible and '✓' or '✗'
            _MsgC(COLOR_WHITE, '  ', color, icon, ' ', COLOR_INFO, addon.name, COLOR_WHITE, ' v', addon.version, '\n')
            _MsgC(COLOR_WHITE, '    Depends on: ', COLOR_INFO, addon.dependsOn, ' ', addon.requiredVersion, '+\n')
        end
    end
    
    if (#libraries == 0 and #addons == 0) then
        _MsgC(COLOR_WARNING, '  No items registered\n')
    end
    
    _MsgC(COLOR_INFO, '\n========================================\n\n')
end

DanLib.Concommand:Add('danlib_version', function()
    DVersionControl:PrintInfo()
end)
