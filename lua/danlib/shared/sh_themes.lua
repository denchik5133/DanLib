/***
 *   @addon         DanLib
 *   @component     Module Thmeme
 *   @license       MIT License
 *   @version       1.0.1
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   This file is designed to facilitate theme management tasks, allowing for easy customization
 *                  and organization of visual elements in the game environment.
 *
 *   @functions
 *                  - CreateTheme: Creates a new theme object with a specified ID.
 *                  - Register: Registers the current theme in the global themes table.
 *                  - SetName: Sets the name of the theme.
 *                  - SetAuthor: Sets the author of the theme.
 *                  - SetVersion: Sets the version of the theme.
 *                  - SetDescription: Sets the description of the theme.
 *                  - SetStrings: Merges additional strings into the theme's string table.
 *                  - LoadThemes: Loads all theme files from the specified directory.
 *                  - Theme: Retrieves the color associated with a specific key from the current theme.
 *
 *   @example
 *                  -- To create a new theme:
 *                  local myTheme = DanLib.Func.CreateTheme('my_custom_theme')
 *                  myTheme:SetName('My Custom Theme')
 *                  myTheme:SetAuthor('Your Name')
 *                  myTheme:SetVersion('1.0')
 *                  myTheme:SetDescription('This is a custom theme for my game.')
 *                  myTheme:SetStrings({
 *                       ['primaryColor'] = Color(255, 0, 0)
 *                  })
 *                  myTheme:Register()
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes:        Ensure that theme IDs are unique to avoid conflicts. All theme files should be placed
 *                  in the specified themes directory for proper loading.
 */



local DBase = DanLib.Func

local CurrentThemeID = nil
local CurrentThemeStrings = nil

DanLib.Temp.Themes = DanLib.Temp.Themes or { }
local DTempThemes = DanLib.Temp.Themes

local ThemeMeta = {
    --- Registers the current theme in the global themes table.
    -- This function adds the theme to the DanLib.Temp.Themes table using its ID.
    -- @self: The theme object being registered.
    Register = function(self)
        if (not self.ID or type(self.ID) ~= 'string' or self.ID == '') then
            DBase:PrintType('Error', 'Theme registration failed: Invalid or missing theme ID')
            return false
        end
        
        if DTempThemes[self.ID] then
            DBase:PrintType('Warning', 'Theme "' .. self.ID .. '" already exists, overwriting...')
        end
        
        DTempThemes[self.ID] = self
        
        -- Invalidate cache when new theme is registered
        if (CurrentThemeID == self.ID) then
            CurrentThemeID = nil
            CurrentThemeStrings = nil
        end
      
        return true
    end,

    --- Sets the name of the theme.
    -- @self: The theme object.
    -- @name (string): The name to be assigned to the theme.
    SetName = function(self, name)
        self.Name = name
    end,

    --- Sets the author of the theme.
    -- @self: The theme object.
    -- @author (string): The author to be assigned to the theme.
    SetAuthor = function(self, author)
        self.Author = author
    end,

    --- Sets the version of the theme.
    -- @self: The theme object.
    -- @version (string): The version to be assigned to the theme.
    SetVersion = function(self, version)
        self.Version = version
    end,

    --- Sets the description of the theme.
    -- @self: The theme object.
    -- @description (string): The description to be assigned to the theme.
    SetDescription = function(self, description)
        self.Description = description
    end,

    --- Merges additional strings into the theme's string table.
    -- @self: The theme object.
    -- @strings (table): A table containing strings to be added to the theme.
    SetStrings = function(self, strings)
        if (type(strings) ~= 'table') then
            DBase:PrintType('Error', 'Theme strings must be a table')
            return false
        end
        
        -- Validate color values
        for key, value in pairs(strings) do
            if (not IsColor(value)) then
                DBase:PrintType('Warning', 'Invalid color value for key "' .. tostring(key) .. '"')
                strings[key] = nil
            end
        end
        
        -- Use optimized table merge
        table.Merge(self.Strings, strings)
        
        -- Invalidate cache if this is the current theme
        if (CurrentThemeID == self.ID) then
            CurrentThemeStrings = nil
        end
        
        return true
    end,

    --- Get theme information as a table
    -- @self: The theme object
    -- @return: table with theme information
    GetInfo = function(self)
        return {
            ID = self.ID,
            Name = self.Name,
            Author = self.Author,
            Version = self.Version,
            Description = self.Description,
            StringCount = table.Count(self.Strings)
        }
    end
}

ThemeMeta.__index = ThemeMeta

--- Creates a new theme object with the specified ID.
-- @param id (string): The identifier for the new theme.
-- @return (table): A new theme object with methods for setting properties.
function DanLib.Func.CreateTheme(id)
    local themes = {
        ID = id,
        Strings = { }
    }
    setmetatable(themes, ThemeMeta)
    return themes
end

local path = 'danlib/themes/'

--- Loads all theme files from the specified directory.
-- This function searches for Lua files in the 'danlib/themes/' directory,
-- adds them to the client-side, and includes them for execution.
function DanLib.Func.LoadThemes()
    local themeFiles = file.Find(path .. '*', 'LUA')
    for k, file in ipairs(themeFiles) do
        AddCSLuaFile(path .. file)
        include(path .. file)
    end
end


local CurrentTheme, ThemeStrings, color

--- Retrieves the color associated with a specific key from the current theme.
-- If the current theme is not set, it defaults to the base theme.
-- Reload-safe: if themes have not been populated yet (e.g. during a hot-reload
-- where sh_themes is re-executed before LoadThemes runs again), the function
-- returns a safe fallback color instead of crashing.
-- @param key (string): The key for the desired color in the theme.
-- @param alpha (number|nil): Optional alpha value to modify the color's transparency.
-- @return (Color): The color object associated with the key, or a default color if not found.
function DanLib.Func:Theme(key, alpha)
    if (CurrentTheme != DanLib.CONFIG.BASE.Themes) then
        CurrentTheme = DanLib.CONFIG.BASE.Themes
        local themeData = DTempThemes[CurrentTheme]
        ThemeStrings = themeData and themeData.Strings or nil
    end

    -- Guard: ThemeStrings is nil when themes haven't been loaded yet
    -- (e.g. mid-reload race between sh_themes re-execution and LoadThemes).
    if (not ThemeStrings) then
        return alpha and Color(0, 0, 0, alpha) or Color(0, 0, 0, 200)
    end

    color = ThemeStrings[key] or Color(0, 0, 0, 200)

    if (alpha) then
        color = Color(color.r, color.g, color.b, alpha)
    end
    return color
end
