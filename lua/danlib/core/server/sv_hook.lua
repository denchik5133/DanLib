/***
 *   @addon         DanLib
 *   @component     SV Hook
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
 *   @description   Universal library for GMod Lua, combining all the necessary features to simplify script development. 
 *                  Avoid code duplication and speed up the creation process with this powerful and convenient library.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DHook = DanLib.Hook
local DTable = DanLib.Table
local DNet = DanLib.Net
local DPlayerUtil = DanLib.PlayerUtil

local _type = type
local _pairs = pairs
local _tostring = tostring
local _sub = string.sub
local _Split = string.Split

--- Hook for handling player initial spawn event.
-- This function sends the complete configuration to the player when they first spawn.
-- @param pPlayer: The player who has just spawned.
local function load_player_config(pPlayer)
    DBase:SendCompleteConfig(pPlayer)
end
DHook:Add('PlayerInitialSpawn', 'DanLib.SendPlayerConfig', load_player_config)

--- Creates a popup notification for the specified player.
-- @param pPlayer: The player to whom the notification will be sent.
-- @param title: The title of the notification.
-- @param message: The message content of the notification.
-- @param msgType: The type of notification (e.g., 'WARNING', 'INFO').
-- @param time: Duration for which the notification will be displayed (in seconds).
function DBase:CreatePopupNotifi(pPlayer, title, message, msgType, time)
    DNet:Open('DanLib:ScreenNotification')
        :Str(title or '')
        :Str(message or '')
        :Str(msgType or 'ERROR')
        :Str(_tostring(time or 5))
        :Send(pPlayer)
end

--- Creates a side popup notification for the specified player.
-- @param pPlayer: The player to whom the notification will be sent.
-- @param bool: A boolean indicating whether the message is a table or a string.
-- @param message: The message content (can be a string or table).
-- @param msgType: The type of notification (default is 'ERROR').
-- @param time: Duration for which the notification will be displayed (default is 5 seconds).
function DBase:SidePopupNotifi(pPlayer, message, msgType, time)
    DNet:Open('DanLib:SidePopupNotification')
        :Str(message or '')
        :Str(msgType or 'ERROR')
        :Str(_tostring(time or 5))
        :Send(pPlayer)
end

--- Sends a message with a specific tag to a single player.
-- @param pPlayer: The player to whom the message will be sent.
-- @param tag: The tag to be displayed with the message.
-- @param ...: The message content to be sent to the player.
function DBase:SendGlobalMessage(tag, ...)
    for _, v in _pairs(DPlayerUtil:GetAll()) do
        self:SendMessage(v, DANLIB_TYPE_DEBUG, DBase:GetColor('DarkOrange'), '[', DBase:GetColor('White'), tag, DBase:GetColor('DarkOrange'), '] ', DBase:GetColor('White'), ...)
    end
end

--- Sends a message to a specific player.
-- @param pPlayer: The player to whom the message will be sent.
-- @param ....: The content of the message to be sent to the player.
function DBase:SendMessageTag(pPlayer, tag, ...)
    self:SendMessage(pPlayer, DANLIB_TYPE_DEBUG, DBase:GetColor('DarkOrange'), '[', DBase:GetColor('White'), tag, DBase:GetColor('DarkOrange'), '] ', DBase:GetColor('White'), ...)
end

--- Sends a debug message to a specific player.
-- @param pPlayer: The player to whom the debug message will be sent.
-- @param ...: The debug message content to be sent to the player.
function DBase:SendDebugMessage(pPlayer, ...)
    self:SendMessage(pPlayer, DANLIB_TYPE_DEBUG, DBase:GetColor('Red'), '[Debug] ', DBase:GetColor('White'), ...)
end

--- Sends a global notification to all players.
-- @param text: The text content of the notification to be sent to all players.
function DBase:SendGlobalNotifi(text)
    for _, v in _pairs(DPlayerUtil:GetAll()) do
        self:CreatePopupNotifi(v, 'SERVER', text, 'WARNING', 6)
    end
end

--- Sends a private message to a player with the title.
-- @param pPlayer: The player to whom the private message is sent.
-- @param title: The title of the message.
-- @param ...: Additional arguments for the message.
function DBase:SendPersonalMessage(pPlayer, title, ...)
    self:SendMessage(pPlayer, DANLIB_TYPE_DEBUG, DBase:Theme('decor'), '< ', DBase:GetColor('White'), title, DBase:Theme('decor'), ' >  ', DBase:GetColor('White'), ...)
end

--- Opens the menu for the player based on the assigned key.
-- @param pPlayer: The player for whom the menu will be opened.
local function OpenMenu(pPlayer, menuKey)
    if (DanLib.CONFIG.BASE.OpenMenu == menuKey) then
        DNet:Open('DanLib:BaseMenu'):Send(pPlayer)
    end
end

-- Hook for showing the help menu.
DHook:Add('ShowHelp', 'OpenMenu.ShowHelp', function(pPlayer)
    OpenMenu(pPlayer, 'F1')
end)

-- Hook for showing the team menu.
DHook:Add('ShowTeam', 'OpenMenu.ShowTeam', function(pPlayer)
    OpenMenu(pPlayer, 'F2')
end)

-- Hook for showing spare menu 1.
DHook:Add('ShowSpare1', 'OpenMenu.ShowSpare1', function(pPlayer)
    OpenMenu(pPlayer, 'F3')
end)

-- Hook for showing spare menu 2.
DHook:Add('ShowSpare2', 'OpenMenu.ShowSpare2', function(pPlayer)
    OpenMenu(pPlayer, 'F4')
end)

--- Parses the command input from the player.
-- @param pPlayer: The player who sent the command.
-- @param text: The command text sent by the player.
-- @return: An empty string if a command was successfully executed, otherwise returns nil.
local function HandlePlayerCommand(pPlayer, text)
    -- Define the command prefix
    local prefix = _sub(text, 1, 1)

    -- Check if the text starts with the prefix '/' or '!'
    if (prefix == '/' or prefix == '!') then
        -- Remove the prefix from the command text
        text = _sub(text, 2)

        -- Split the command text into arguments
        local args = _Split(text, ' ')
        local cmd = args[1]      
        local text2 = DTable:Concat(args, ' ', 2)

        -- Create a team
        local cmd2 = DBase.CreateCommand(cmd, true)
        if (cmd2 != nil) then
            -- Get SteamID and convert to SteamID64
            local steamID = pPlayer:SteamID()
            local steamID64 = pPlayer:SteamID64()
            local group = pPlayer:GetUserGroup()
            local rank = pPlayer:get_danlib_rank()

            local hasAccess = false
            if cmd2 and cmd2.access then
                if (_type(cmd2.access) == 'table') then
                    hasAccess = DTable:HasValue(cmd2.access, steamID64) or DTable:HasValue(cmd2.access, steamID) or DTable:HasValue(cmd2.access, group) or DTable:HasValue(cmd2.access, rank)
                elseif (_type(cmd2.access) == 'string') then
                    hasAccess = cmd2.access == steamID64 or cmd2.access == group
                end
            end

            -- If the player does not have access, but access is not defined, allow command execution
            if (not hasAccess and cmd2.access) then
                DBase:SendDebugMessage(pPlayer, DBase:L('#access.ver'))
                return ''
            end

            cmd2:OnRun(pPlayer, text2, args)
            return ''
        end
    end

    -- If no prefix is found, run the generic command hook
    DHook:Run('DanLib:CommandRun.All', 'chat', pPlayer, text)
end 

--- Hook for processing player chat commands.
-- @param pPlayer: The player who sent the message.
-- @param text: The text sent by the player.
-- @return: The result of the command parsing.
DHook:Add('PlayerSay', 'DanLib:CommandsHook', function(pPlayer, text)
    return HandlePlayerCommand(pPlayer, text)  
end)
