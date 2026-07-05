/***
 *   @addon         DanLib
 *   @component     Init
 *   @license       MIT License
 *   @version       3.4.0
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
 


DanLib_AddonsName = 'DanLib Basic Library'
DanLib_Version = '3.4.0'
DanLib_Author = '76561198405398290'
DanLib_Key = 'DanLib-8f3A5c2E-9d1B7e4A-6c8F2b5D'
DanLib_ReleaseDate = '10/4/2023'
DanLib_License = 'MIT'

-- Create a Variables/Tables workspace table.
DanLib = DanLib or { }
DanLib = {
    AddonsName = DanLib_AddonsName,
    Author = DanLib_Author,
    Version = DanLib_Version,
    Key = DanLib_Key,
    Config = {
        Style = { },
        Theme = { },
        Description = { },
        Different = { }
    },
    Panels = { },
    Utils = { },
    Modules = { },
    Func = { },
    BaseConfig = { },
    Temp = { },
    Permissions = { },
    Logs = { },
    FileUtil = { },
    NetworkUtil = { },
    DEBUG = { }
}
DanLibUI = DanLibUI or { }

DDI = DDI or { }
DDI = {
    Func = { },
    Config = { },
    Utils = { },
    Temp = { }
}

--- Defines the available data types for the configuration.
-- @table DanLib.Type: A table containing the main data types used in the project.
-- @field Int: Data type for integers.
-- @field String: Data type for strings.
-- @field Bool: Data type for logical values (true/false).
-- @field Table: Data type for tables.
-- @field Key: Data type for keys (strings).
DanLib.Type = {
    Int = 'Int',
    String = 'String',
    Bool = 'Bool',
    Table = 'Table',
    Key = 'Key'
}

local function loadingFunctionType()
    --- Defines functions for working with data types.
    -- @table DanLib.FunctionType: A table containing functions for writing and reading different data types.
    -- @field Int: Functions for working with integers.
    -- @field String: Functions for working with strings.
    -- @field Bool: Functions for working with logical values.
    -- @field Key: Functions for working with keys.
    -- @field Table: Functions for working with tables.
    DanLib.FunctionType = {
        Int = {
            -- Guard: nil would crash WriteInt; default to 0
            NetWrite = function(value)
                net.WriteInt(value or 0, 32)
            end,
            NetRead = function()
                return net.ReadInt(32)
            end
        },
        String = {
            -- Guard: nil would crash WriteString; default to empty string
            NetWrite = function(value)
                net.WriteString(value or '')
            end,
            NetRead = function()
                return net.ReadString()
            end
        },
        Bool = {
            -- Explicit boolean cast: prevents truthy non-booleans (e.g. 1) writing true
            NetWrite = function(value)
                net.WriteBool(value == true)
            end,
            NetRead = function()
                return net.ReadBool()
            end
        },
        Key = {
            -- Guard: nil would crash WriteString; default to empty string
            NetWrite = function(value)
                net.WriteString(value or '')
            end,
            NetRead = function()
                return net.ReadString()
            end,
            CopyFunc = function(value)
                return value
            end
        },
        Table = {
            -- Guard: nil would crash TableToJSON; default to empty table
            NetWrite = function(value)
                net.WriteString(util.TableToJSON(value or { }))
            end,
            -- Guard: JSONToTable can return nil on malformed JSON; fall back to { }
            NetRead = function()
                return util.JSONToTable(net.ReadString()) or { }
            end,
            -- Guard: table.Copy(nil) returns nil; fall back to { }
            CopyFunc = function(value)
                return table.Copy(value) or { }
            end
        }
    }
end

AddCSLuaFile()

if (CLIENT) then
    include('danlib/core/sh_loader.lua')
elseif (SERVER) then
    include('danlib/core/sh_loader.lua')
    AddCSLuaFile('danlib/core/sh_loader.lua')

    -- Resources
    resource.AddFile('resource/fonts/montserrat-medium.ttf')
    resource.AddFile('resource/fonts/montserrat-regular.ttf')
    
    -- UI Sounds
    resource.AddFile('sound/ddi/button-click.wav')
    resource.AddFile('sound/ddi/button-hover.wav')
    resource.AddFile('sound/ddi/error.mp3')
    resource.AddFile('sound/ddi/notifications.wav')
end


-- DanLib Initialization Script
-- Loads all core modules and components in the correct order
local function Start()
    local loader = DanLib.Func.CreateLoader({
        githubName = 'DanLib Basic Library',
        githubAliases = { 'DanLib' },
        version = DanLib_Version,
        Key = DanLib_Key,
        license = DanLib_License
    })

    loader:SetName('DanLib')
    loader:SetLoadDirectory('danlib')
    loader:SetStartsLoading()

    -- Network layer (must be loaded first)
    loader:IncludeDir('core/network')
    loadingFunctionType()
    -- Base UI components
    loader:IncludeDir('core/ui_components')

    -- Configuration system
    loader:IncludeDir('core/config')
    -- Metadata definitions
    loader:IncludeDir('core/meta')

    -- Shared utilities
    loader:IncludeDir('shared')
    loader:IncludeDir('core/shared')
    loader:IncludeDir('core/utils')

    -- Localization
    DanLib.Func.LoadLanguages()
    -- UI themes
    DanLib.Func.LoadThemes()

    -- Client utilities
    loader:IncludeDir('core/client')
    -- Menu pages
    loader:IncludeDir('core/pages')
    -- HUD elements
    loader:IncludeDir('core/hud_elements')
    -- VGUI elements
    loader:IncludeDir('vgui')
    -- Server utilities
    loader:IncludeDir('core/server')
    -- Database layer
    loader:IncludeDir('core/sqlite')

    loader:IncludeDir('entities')

    loader:IncludeDir('weapons')

    -- Gamemode integration
    DanLib.Func.LoadGamemodes()
    -- Chat commands
    DanLib.Func.LoadCommands()
    -- Logging system
    DanLib.Func.LoadLogs()

    -- Register
    loader:Register()
    
    -- Set DanLib as ready
    DanLib.IsReady = true
end
Start()

DanLib.Loading = DanLib.Loading or { }
DanLib.Loading.Start = Start

-- Downloading materials from Steam.
local function AddContent(WorkshopID)
    if SERVER then
        resource.AddWorkshop(WorkshopID)
    end
end

-- Base Content
AddContent('2418668622') -- danlib base content
