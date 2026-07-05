/***
 *   @addon         DanLib
 *   @component     Module Base
 *   @license       MIT License
 *   @version       1.2.1
 *   @release_date  10/4/2023
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



local BASE = DanLib.Func.CreateModule('BASE')
BASE:SetTitle(DanLib.AddonsName)
BASE:SetIcon('HuFRarz')
BASE:SetAuthor(DanLib.Author)
BASE:SetVersion(DanLib.Version)
BASE:SetDescription('The main library is designed for the use of add-ons based on this base.')
BASE:SetColor(Color(255, 165, 0))
BASE:SetSortOrder(1)

BASE:AddOption('Gamemode', 'Gamemode', 'Select the appropriate gamemode.', DanLib.Type.String, 'Blank', false, function()
    local gamemode = { }
    for k, v in pairs(DanLib.Func:GetAllGamemodes()) do
        gamemode[v.ID] = k
    end
    return gamemode
end)

BASE:AddOption('Tag', 'Tag', 'What should our chat tag be? There is no need to put </, !, [ ]>', DanLib.Type.String, 'DanLib')
BASE:AddOption('ChatCommand', 'Chat Command', 'What should our chat command be?. There is no need to put signs </, !>', DanLib.Type.String, 'danlibmenu')
BASE:AddOption('CurrencySymbol', 'Currency symbol', 'Put the currency symbol you would like to see on the server.', DanLib.Type.String, '$')
BASE:AddOption('WebsiteLink', 'Website link', 'The URL to go to when the Site button is clicked.', DanLib.Type.String, 'https://ddi-docs.site/')
BASE:AddOption('DiscordLink', 'Discord link', 'The URL to navigate to when the community button is clicked.', DanLib.Type.String, 'https://discord.gg/CND6B5sH3j')
BASE:AddOption('Debugg', 'Debugging mode', 'System debug mode. Alert your players.', DanLib.Type.Bool, false, nil, nil)

BASE:AddOption('Languages', 'Languages', 'The language used for the addon.', DanLib.Type.String, 'English', false, function()
    local languages = { }
    -- Always use English as the 100% baseline so the percentage never
    -- changes when the user switches the active language.
    local original = DanLib.Temp.Languages['English']
    if (not original) then
        return languages
    end

    local base = table.Count(original)
    if (base == 0) then
        return languages
    end

    for k, v in pairs(DanLib.Temp.Languages) do
        local count = table.Count(v)
        local percent = math.min(math.Round(count / base * 100, 2), 100)
        languages[k] = k .. ', translated ' .. percent .. '%'
    end
    return languages
end)

BASE:AddOption('Themes', 'Themes', 'The colours used for various UI elements.', DanLib.Type.String, 'default', false, function()
    local themes = { }
    for k, v in pairs(DanLib.Temp.Themes) do
        themes[v.ID] = v.Name
    end
    return themes
end)

BASE:AddOption('OpenMenu', 'Open menu', 'Which key should open the menu.', DanLib.Type.String, 'OFF', false, function()
    local _KEY = { }
    for key in pairs(DanLib.KEY_BIND_MENU) do
        _KEY[key] = key
    end
    return _KEY
end)

BASE:AddOption('NPCs', 'NPC', 'Tools for creating NPCs, allowing you to customise their behaviour and interaction with players.', DanLib.Type.Table, { }, nil)

BASE:AddOption('Ranks', 'Ranks', 'Defining and setting up player roles to create a safe and organised play environment.', DanLib.Type.Table, {
    ['rank_owner'] = {
        Name = 'Owner',
        Order = 1,
        Color = Color(255, 165, 0),
        Time = '1707699060',
        Permission = {
            ['EditSettings'] = true,
            ['EditRanks'] = true,
            ['AdminPages'] = true,
            ['SpawnNPC'] = true,
            ['ViewHelp'] = true,
            ['Tutorial'] = true
        }
    },
    ['rank_staff'] = {
        Name = 'Staff',
        Order = 2,
        Color = Color(127, 255, 0),
        Time = '1707699060',
        Permission = {
            ['EditSettings'] = true,
            ['AdminPages'] = true,
            ['ViewHelp'] = true,
            ['Tutorial'] = true
        }
    },
    ['rank_member'] = {
        Name = 'Member',
        Order = 3,
        Color = Color(0, 151, 230),
        Time = '1707699060',
        Permission = {}
    }
}, 'DanLib.UI.Ranks')

BASE:AddOption('Logs', 'Logs', 'Configuring logging parameters to record and analyse actions in gameplay.', DanLib.Type.Table, { }, 'DanLib.UI.Logs')

BASE:Register()
