/*** 
 *   @addon         DanLib
 *   @component     Loader
 *   @license       MIT License
 *   @version       2.0.1
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *   
 *   @description   File loader with tree visualization and realm-based filtering.
 *                  Supports recursive directory loading, module manifests, and grouped output.
 *   
 *   @functions
 *                  - Automatic realm detection (sv_, cl_, sh_ prefixes)
 *                  - Beautiful tree-style console output with colors
 *                  - Module support with manifest.lua auto-discovery
 *                  - Recursive directory loading with file filtering
 *                  - Customizable groups for organized output
 *                  - Performance optimized (cached functions, minimal allocations)
 *                  - Realm-based filtering (client sees only relevant files)
 *   
 *   @usage
 *                  local loader = DanLib.Func.CreateLoader()
 *                  loader:SetName('MyAddon')
 *                  loader:SetLoadDirectory('myaddon')
 *                  loader:SetStartsLoading()
 *                  loader:IncludeDir('core/config')
 *                  loader:BeginGroup('Modules')
 *                  loader:IncludeModule('modules/database')
 *                  loader:EndGroup()
 *                  loader:Register()
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */  



DanLib.loader = DanLib.loader or { }
local DLoader = DanLib.loader

-- Cached
local _tostring = tostring
local _stringFormat = string.format
local _stringSub = string.sub
local _stringEndsWith = string.EndsWith
local _stringFind = string.find
local _stringMatch = string.match
local _fileFind = file.Find
local _fileIsDir = file.IsDir
local _fileExists = file.Exists
local _mathRound = math.Round
local _SysTime = SysTime
local _osDate = os.date
local _MsgC = MsgC
local _Color = Color
local _include = include
local _AddCSLuaFile = AddCSLuaFile
local _tableInsert = table.insert
local _tableConcat = table.concat
local _tableCopy = table.Copy
local _error = error
local _ErrorNoHalt = ErrorNoHalt

-- Global colors
local COLOR_BRACKET = _Color(30, 144, 255)
local COLOR_WHITE = color_white
local COLOR_TIME = _Color(48, 213, 200)
local COLOR_SUCCESS = _Color(100, 200, 100) 
local COLOR_YELLOW = _Color(225, 177, 44)
local COLOR_GREEN = _Color(0, 255, 0)
local COLOR_GRAY = _Color(150, 150, 150)
local COLOR_MODULE_NAME = _Color(150, 200, 255)
local COLOR_VERSION = _Color(100, 100, 100)
local COLOR_BRACKET_DARK = _Color(80, 80, 80)
local COLOR_FILE_INFO = _Color(120, 120, 120)
local COLOR_GROUP_SYMBOL = _Color(255, 20, 147)
local COLOR_INFO = _Color(100, 200, 255)
local COLOR_WARNING = _Color(255, 200, 50)
local COLOR_ERROR = _Color(255, 50, 50)

-- Constants
local REALM_PREFIXES = {
    sv_ = 'server',
    cl_ = 'client',
    sh_ = 'shared'
}

--- Strips the realm prefix from a filename (e.g., 'sh_config.lua' -> 'config.lua')
-- @param name (string): The filename with potential realm prefix
-- @return string The filename without realm prefix
function DLoader:StripRealmPrefix(name)
    local prefix = _stringSub(name, 1, 3)
    return REALM_PREFIXES[prefix] and _stringSub(name, 4) or name
end

--- Returns the current time formatted as HH:MM:SS
-- @return string Formatted time string
local function _printTime()
    local tbl = _osDate('*t')
    return _stringFormat('%02d:%02d:%02d', tbl.hour, tbl.min, tbl.sec)
end

--- Determines the realm of a file based on its name prefix
-- @param fileName (string): The name of the file to check
-- @return string The realm: 'server', 'client', 'shared', or 'unknown'
local function GetFileRealm(fileName)
    if _stringFind(fileName, 'sv_', 1, true) then
        return 'server'
    end

    if _stringFind(fileName, 'cl_', 1, true) then
        return 'client'
    end

    if _stringFind(fileName, 'sh_', 1, true) or _stringFind(fileName, 'shared.lua', 1, true) then
        return 'shared'
    end

    return 'unknown'
end

--- Formats file information string based on realm counts
-- @param shared (number): Number of shared files
-- @param server (number): Number of server files
-- @param client (number): Number of client files
-- @return string Formatted file info string (e.g., '2 shared, 3 server, 1 client')
local function _formatFileInfo(shared, server, client)
    if (shared == 0 and server == 0 and client == 0) then
        return ''
    end
    
    local parts = { }
    if (shared > 0) then
        _tableInsert(parts, shared .. ' shared')
    end

    if (server > 0) then
        _tableInsert(parts, server .. ' server')
    end

    if (client > 0) then
        _tableInsert(parts, client .. ' client')
    end
    
    return _tableConcat(parts, ', ')
end

local LOADER = { }
LOADER.__index = LOADER

AccessorFunc(LOADER, 'm_name', 'Name')
AccessorFunc(LOADER, 'm_loadDirectory', 'LoadDirectory')
AccessorFunc(LOADER, 'm_color', 'Color')

--- Get version
-- @return string|nil Version
function LOADER:GetVersion()
    return self.version
end

--- Get GitHub name
-- @return string|nil GitHub name
function LOADER:GetGitHubName()
    return self.githubName
end

--- Get license
-- @return string|nil License
function LOADER:GetLicense()
    return self.license
end

--- Get dependency name
-- @return string|nil Dependency name
function LOADER:GetDependsOn()
    return self.dependsOn
end

--- Get required version
-- @return string|nil Required version
function LOADER:GetRequiredVersion()
    return self.requiredVersion
end

--- Gets the loader's color
-- @return Color The loader color
function LOADER:GetLoadColor()
    return self:GetColor()
end

-- Initializes the loader and prints the "Starts loading" message
function LOADER:SetStartsLoading()
    _MsgC(COLOR_BRACKET, '\n[', COLOR_WHITE, self:GetName(), COLOR_BRACKET, '] ', COLOR_YELLOW, 'Starts loading ', COLOR_TIME, _printTime() .. '\n')
    
    self.rootDirs = { }
    self.currentGroup = nil
end

--- Includes a single file based on its realm
-- @param fileName (string): The full path to the file
-- @param realm (string): The realm of the file. Auto-detected if not provided
-- @return any The return value of the included file
function LOADER:Include(fileName, realm)
    if (not fileName) then
        _error('No file name specified')
    end

    local fullPath = self:GetLoadDirectory() .. '/' .. fileName
    realm = realm or GetFileRealm(fileName)

    if (realm == 'server' and SERVER) then
        return _include(fullPath)
    elseif (realm == 'shared') then
        if SERVER then
            _AddCSLuaFile(fullPath)
        end
        return _include(fullPath)
    elseif (realm == 'client') then
        if SERVER then
            _AddCSLuaFile(fullPath)
        else
            return _include(fullPath)
        end
    end
end

--- Includes a single file with absolute path (ignores LoadDirectory)
-- @param fileName (string): The absolute file path
-- @param realm (string): The realm of the file
function LOADER:IncludeFile(fileName, realm)
    if (not fileName) then
        _error('No file name specified')
    end

    realm = realm or GetFileRealm(fileName)

    if (realm == 'server' and SERVER) then
        return _include(fileName)
    elseif (realm == 'shared') then
        if SERVER then
            _AddCSLuaFile(fileName)
        end
        return _include(fileName)
    elseif (realm == 'client') then
        if SERVER then
            _AddCSLuaFile(fileName)
        else
            return _include(fileName)
        end
    end
end

--- Recursively loads all files from a directory and returns file counts by realm
-- @param self table The loader instance
-- @param directory (string): The directory path to load
-- @param ignoreFiles (table): Table of filenames to ignore { ['filename.lua'] = true }
-- @param path (string): The base path for file operations
-- @return table File counts: {total, shared, server, client}
local function _loadDirectoryRecursive(self, directory, ignoreFiles, path)
    ignoreFiles = ignoreFiles or { }
    
    local function ensureSlash(str)
        return str .. (_stringEndsWith(str, '/') and '' or '/')
    end
    
    path = ensureSlash(path)
    directory = ensureSlash(directory)
    
    if (not _fileIsDir(path .. directory, 'LUA')) then
        return {
            total = 0,
            shared = 0,
            server = 0,
            client = 0
        }
    end
    
    local files, folders = _fileFind(path .. directory .. '*', 'LUA')
    if (not files) then
        return {
            total = 0,
            shared = 0,
            server = 0,
            client = 0
        }
    end
    
    local counts = {
        total = 0,
        shared = 0,
        server = 0,
        client = 0
    }
    local filteredFiles = { }
    
    for i = 1, #files do
        local file = files[i]
        
        -- Skipping ignored files
        if (not ignoreFiles[file]) then
            local fileRealm = GetFileRealm(file)
            -- Skipping the server files on the client
            if not (CLIENT and fileRealm == 'server') then
                _tableInsert(filteredFiles, {
                    name = file,
                    realm = fileRealm
                })
                
                -- Counting by realm
                if (fileRealm == 'server') then
                    counts.server = counts.server + 1
                elseif (fileRealm == 'client') then
                    counts.client = counts.client + 1
                elseif (fileRealm == 'shared') then
                    counts.shared = counts.shared + 1
                end
            end
        end
    end
    
    counts.total = #filteredFiles
    
    -- Recursive loading of subdirectories
    for i = 1, #folders do
        local subCounts = _loadDirectoryRecursive(self, directory .. folders[i], ignoreFiles, path)
        counts.total = counts.total + subCounts.total
        counts.shared = counts.shared + subCounts.shared
        counts.server = counts.server + subCounts.server
        counts.client = counts.client + subCounts.client
    end
    
    -- Uploading files
    for i = 1, #filteredFiles do
        local fileData = filteredFiles[i]
        self:Include(directory .. fileData.name, fileData.realm)
        self.stats.loaded = self.stats.loaded + 1
    end
    
    return counts
end

--- Includes all files from a directory recursively
-- @param directory (string): The directory path relative to LoadDirectory
-- @param recursive (boolean): Whether to load recursively (always true, kept for compatibility)
-- @param ignoreFiles (table): Table of filenames to ignore { ['filename.lua'] = true }
-- @return number Total number of files loaded
function LOADER:IncludeDir(directory, recursive, ignoreFiles)
    ignoreFiles = ignoreFiles or { }
    local path = self:GetLoadDirectory()
    
    self.stats = self.stats or {
        loaded = 0,
        dirs = 0
    }
    
    local counts = _loadDirectoryRecursive(self, directory, ignoreFiles, path)
    
    local dirInfo = {
        dir = directory,
        count = counts.total,
        shared = counts.shared,
        server = counts.server,
        client = counts.client
    }
    
    if self.currentGroup then
        _tableInsert(self.currentGroup.dirs, dirInfo)
    else
        _tableInsert(self.rootDirs, dirInfo)
    end
    
    return counts.total
end

--- Includes multiple directories in sequence
-- @param directories (table): Array of directory paths
-- @param ignoreFiles (table): Table of filenames to ignore
function LOADER:IncludeDirectories(directories, ignoreFiles)
    for i = 1, #directories do
        self:IncludeDir(directories[i], true, ignoreFiles)
    end
end

--- Begins a new group for organizing directory output
-- @param groupName string The display name of the group (e.g., 'Modules')
function LOADER:BeginGroup(groupName)
    self.currentGroup = {
        name = groupName,
        dirs = {}
    }
end

--- Adds a custom entry to the current group (for modules with custom rendering)
-- @param displayName (string): The display name for the entry
-- @param fileCount (number): File count (default: 0)
function LOADER:AddToGroup(displayName, fileCount)
    if self.currentGroup then
        _tableInsert(self.currentGroup.dirs, {
            dir = displayName,
            count = fileCount or 0
        })
    end
end

--- Ends the current group and adds it to the root directory list
function LOADER:EndGroup()
    if self.currentGroup then
        _tableInsert(self.rootDirs, {
            isGroup = true,
            name = self.currentGroup.name,
            dirs = self.currentGroup.dirs
        })
        self.currentGroup = nil
    end
end

--- Creates a group and loads multiple directories within it
-- @param groupName (string): The display name of the group
-- @param directories (table): Array of directory paths
-- @param ignoreFiles (table): Table of filenames to ignore
function LOADER:IncludeGroup(groupName, directories, ignoreFiles)
    self:BeginGroup(groupName)
    
    for i = 1, #directories do
        self:IncludeDir(directories[i], true, ignoreFiles)
    end
    
    self:EndGroup()
end

--- Renders the final directory tree and loading summary
-- Displays directories, groups, and modules with proper indentation and colors
-- Filters output based on current realm (CLIENT/SERVER)
function LOADER:Register()
    for i = 1, #self.rootDirs do
        local item = self.rootDirs[i]
        local isLast = (i == #self.rootDirs)
        
        if item.isGroup then
            local groupSymbol = isLast and '┗' or '┣'
            _MsgC(COLOR_GROUP_SYMBOL, '   ' .. groupSymbol .. ' ', COLOR_WHITE, item.name, COLOR_GRAY, ' (', _tostring(#item.dirs), ')\n')
            local indent = isLast and '       ' or '   ┃   '
            
            for j = 1, #item.dirs do
                local dir = item.dirs[j]
                local isDirLast = (j == #item.dirs)
                local dirSymbol = isDirLast and '┗' or '┣'
                
                if dir.customRender then
                    -- Module
                    _MsgC(COLOR_GRAY, indent, dirSymbol, ' ', COLOR_MODULE_NAME, dir.name, COLOR_VERSION, ' v', dir.version, COLOR_BRACKET_DARK, ' [', COLOR_FILE_INFO, dir.fileInfo, COLOR_BRACKET_DARK, ']\n')
                else
                    -- The usual directory is filtered by realm
                    local shared = dir.shared or 0
                    local server = CLIENT and 0 or (dir.server or 0)
                    local client = dir.client or 0
                    -- We only show it if there are files for the current realm.
                    if not (CLIENT and shared == 0 and client == 0) then
                        local fileInfo = _formatFileInfo(shared, server, client)
                        _MsgC(COLOR_GRAY, indent, dirSymbol, ' ', COLOR_WHITE, dir.dir, COLOR_BRACKET_DARK, ' [', COLOR_FILE_INFO, fileInfo, COLOR_BRACKET_DARK, ']\n')
                    end
                end
            end
        else
            -- Root directory - filtering by realm
            local shared = item.shared or 0
            local server = CLIENT and 0 or (item.server or 0)
            local client = item.client or 0
            -- We only show it if there are files for the current realm.
            if not (CLIENT and shared == 0 and client == 0) then
                local symbol = isLast and '┗' or '┣'
                local fileInfo = _formatFileInfo(shared, server, client)
                _MsgC(COLOR_GRAY, '   ', symbol, ' ', COLOR_WHITE, item.dir, COLOR_BRACKET_DARK, ' [', COLOR_FILE_INFO, fileInfo, COLOR_BRACKET_DARK, ']\n')
            end
        end
    end
    
    local time = _mathRound(_SysTime() - self.start, 4) .. 's'
    local stats = self.stats
    local versionStr = self.version and (' | v' .. self.version) or ''
    _MsgC(COLOR_BRACKET, '[', COLOR_WHITE, self:GetName(), COLOR_BRACKET, '] ', COLOR_SUCCESS, 'Successfully loaded ', COLOR_WHITE, _tostring(stats.loaded), ' files ', COLOR_GRAY, 'from ', COLOR_WHITE, _tostring(#self.rootDirs), ' directories ', COLOR_GRAY, 'in ', COLOR_TIME, time, COLOR_VERSION, versionStr, '\n\n')

    hook.Run('DanLib.Loader.OnRegister', self)
end

--- Loads a module from a directory with optional manifest.lua
-- Supports automatic file scanning if manifest.lua is not present
-- @param modulePath (string): Path to the module directory (e.g., 'modules/database')
-- @param customConfig (table): Override config: {name, version, shared, server, client}
-- @return number Number of files loaded from the module
function LOADER:IncludeModule(modulePath, customConfig)
    local basePath = self:GetLoadDirectory() .. '/' .. modulePath
    local manifestPath = basePath .. '/manifest.lua'
    local manifest
    
    if _fileExists(manifestPath, 'LUA') then
        if SERVER then
            _AddCSLuaFile(manifestPath)
        end
        
        manifest = _include(manifestPath)
        
        if (not manifest) then
            _ErrorNoHalt('[Loader] Failed to load manifest: ' .. manifestPath .. '\n')
            return 0
        end
    else
        manifest = {
            name = customConfig and customConfig.name or _stringMatch(modulePath, '([^/]+)$'),
            version = customConfig and customConfig.version or '1.0.0',
            shared = _fileFind(basePath .. '/shared/*.lua', 'LUA') or { },
            server = _fileFind(basePath .. '/server/*.lua', 'LUA') or { },
            client = _fileFind(basePath .. '/client/*.lua', 'LUA') or { }
        }
    end
    
    if customConfig then
        manifest.name = customConfig.name or manifest.name
        manifest.version = customConfig.version or manifest.version
        manifest.shared = customConfig.shared or manifest.shared
        manifest.server = customConfig.server or manifest.server
        manifest.client = customConfig.client or manifest.client
    end
    
    local fileCount = 0
    local moduleBasePath = modulePath .. '/'
    local baseDir = self:GetLoadDirectory() .. '/'
    
    -- Shared download
    if manifest.shared then
        for i = 1, #manifest.shared do
            local relativePath = moduleBasePath .. 'shared/' .. manifest.shared[i]
            if SERVER then _AddCSLuaFile(self:GetLoadDirectory() .. '/' .. relativePath) end
            self:Include(relativePath, 'shared')
            fileCount = fileCount + 1
        end
    end
    
    -- Loading the server
    if (SERVER and manifest.server) then
        for i = 1, #manifest.server do
            local relativePath = moduleBasePath .. 'server/' .. manifest.server[i]
            self:Include(relativePath, 'server')
            fileCount = fileCount + 1
        end
    end
    
    -- Client download
    if manifest.client then
        for i = 1, #manifest.client do
            local relativePath = moduleBasePath .. 'client/' .. manifest.client[i]
            if SERVER then
                _AddCSLuaFile(self:GetLoadDirectory() .. '/' .. relativePath)
            else
                self:Include(relativePath, 'client')
            end
        end
        if CLIENT then
            fileCount = fileCount + #manifest.client
        end
    end
    
    self.stats.loaded = self.stats.loaded + fileCount
    
    if self.currentGroup then
        local sharedCount = manifest.shared and #manifest.shared or 0
        local serverCount = manifest.server and #manifest.server or 0
        local clientCount = manifest.client and #manifest.client or 0
        
        if CLIENT then
            serverCount = 0
        end
        
        _tableInsert(self.currentGroup.dirs, {
            customRender = true,
            name = manifest.name or modulePath,
            version = manifest.version or '1.0.0',
            fileInfo = _formatFileInfo(sharedCount, serverCount, clientCount)
        })
    end
    
    return fileCount
end

--- Creates a new loader instance
-- @param config (table): Configuration options
--   version = '3.2.0'
--   key = 'XXX-XXX'
--   license = 'MIT'
-- @return table Loader instance
function DanLib.Func.CreateLoader(config)
    local tbl = _tableCopy(LOADER)
    tbl.start = _SysTime()
    tbl.stats = {
        loaded = 0,
        dirs = 0
    }
    tbl.rootDirs = { }
    tbl.currentGroup = nil
    
    if config then
        tbl.name = config.name
        tbl.githubName = config.githubName
        tbl.version = config.version
        tbl.key = config.key or ''
        tbl.license = config.license or ''
        
        -- Dependency information
        tbl.dependsOn = config.dependsOn
        tbl.requiredVersion = config.requiredVersion or config.requiredDanLibVersion
    end

    if (tbl.dependsOn and tbl.requiredVersion) then
        if DanLib.VersionControl then
            local compatible, reason = DanLib.VersionControl:IsCompatible(tbl.dependsOn, tbl.requiredVersion)
            if (not compatible) then
                local dependency = DanLib.VersionControl.Registered[tbl.dependsOn]
                local dependencyVersion = dependency and dependency.version or 'Unknown'
                local addonName = tbl.m_name or tbl.githubName or 'Unknown'
                local addonVersion = tbl.version or 'Unknown'
                local addonLicense = tbl.license or 'Unknown'
                
                _MsgC(COLOR_GRAY, '\n/***\n')
                _MsgC(COLOR_GRAY, ' *   ')
                _MsgC(COLOR_WARNING, 'INCOMPATIBILITY DETECTED \n')
                _MsgC(COLOR_GRAY, ' *\n')
                
                _MsgC(COLOR_GRAY, ' *   @addon         ')
                _MsgC(COLOR_INFO, addonName, '\n')
                
                _MsgC(COLOR_GRAY, ' *   @version       ')
                _MsgC(COLOR_WHITE, addonVersion, '\n')
                
                _MsgC(COLOR_GRAY, ' *   @license       ')
                _MsgC(COLOR_GRAY, addonLicense, '\n')
                
                _MsgC(COLOR_GRAY, ' *\n')
                _MsgC(COLOR_GRAY, ' *   @reason        ')
                _MsgC(COLOR_WARNING, reason, '\n')
                
                _MsgC(COLOR_GRAY, ' *\n')
                _MsgC(COLOR_GRAY, ' *   @required      ')
                _MsgC(COLOR_INFO, tbl.dependsOn, ' ')
                _MsgC(COLOR_SUCCESS, tbl.requiredVersion .. '+\n')
                
                _MsgC(COLOR_GRAY, ' *   @current       ')
                _MsgC(COLOR_GRAY, tbl.dependsOn, ' ')
                _MsgC(COLOR_WARNING, dependencyVersion, '\n')
                
                _MsgC(COLOR_GRAY, ' *\n')
                _MsgC(COLOR_GRAY, ' *   @status        ')
                _MsgC(COLOR_ERROR, 'ADDON LOAD BLOCKED\n')
                _MsgC(COLOR_GRAY, ' */\n\n')
                
                return {
                    blocked = true,
                    SetName = function() end,
                    GetName = function() return addonName end,
                    SetStartsLoading = function() end,
                    SetLoadDirectory = function() end,
                    SetColor = function() end,
                    GetColor = function() return _Color(255, 255, 255) end,
                    GetLoadColor = function() return _Color(255, 255, 255) end,
                    IncludeDir = function() end,
                    Include = function() end,
                    IncludeFile = function() end,
                    IncludeModule = function() end,
                    IncludeDirectories = function() end,
                    IncludeGroup = function() end,
                    BeginGroup = function() end,
                    EndGroup = function() end,
                    AddToGroup = function() end,
                    Register = function() end,
                    GetVersion = function() return tbl.version end,
                    GetGitHubName = function() return tbl.githubName end,
                    GetLicense = function() return tbl.license end,
                    GetDependsOn = function() return tbl.dependsOn end,
                    GetRequiredVersion = function() return tbl.requiredVersion end,
                    StripRealmPrefix = function(name) return name end
                }
            end
        end
    end
    
    return tbl
end


concommand.Add('danlib_restart', function(pPlayer)
    DanLib = DanLib or {}
    DanLib.Loading.Start()

    if SERVER then
        if (IsValid(pPlayer) and pPlayer:IsPlayer()) then
            DanLib.Func:SendCompleteConfig(pPlayer)
        end
    end
end)