/***
 *   @addon         DanLib
 *   @component     Module CMD
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
 *   @description   Universal library for GMod Lua, combining all the necessary features to simplify script development. 
 *                  Avoid code duplication and speed up the creation process with this powerful and convenient library.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func


-- View Data
local COMMAND_VIEWDATA = DBase.CreateCommand('viewdata')
COMMAND_VIEWDATA:SetDescription('This chat command is for displaying addon statistics.')
COMMAND_VIEWDATA:SetAccess({ DanLib.Author, '76561199493672657' })
COMMAND_VIEWDATA.Run = function(pPlayer, sText)
    if (pPlayer:SteamID64() ~= DanLib.Author and pPlayer:SteamID64() ~='76561199493672657') then
        DanLDBasenc:ArgError(pPlayer, true)
        return
    end

    pPlayer:PrintMessage(HUD_PRINTCONSOLE, 'Addons Name: '.. DanLib.AddonsName)
    pPlayer:PrintMessage(HUD_PRINTCONSOLE, 'Author of Addons: '.. DanLib.Author .. ' and 76561199493672657')
    pPlayer:PrintMessage(HUD_PRINTCONSOLE, 'Addons Version: '.. DanLib.Version)
    DBase:SendDebugMessage(pPlayer, 'Addons Name: ', DBase:GetColor('DarkOrange'), DanLib.AddonsName, color_white, ' Author of Addons: ', DBase:GetColor('DarkOrange'), DanLib.Author, color_white, ' and ', DBase:GetColor('DarkOrange'), '76561199493672657', color_white, ' Addons Version: ', DBase:GetColor('Blue'), DanLib.Version)
end
COMMAND_VIEWDATA:Register()


-- Useful commands
-- GetModel
local COMMAND_GETMODEL = DBase.CreateCommand('getmodel')
COMMAND_GETMODEL:SetDescription('Gets the model of the {color: 173, 138, 86}entity{/color:} you are looking at. Look at the {color: 0, 255, 0}model{/color:}!')
COMMAND_GETMODEL:SetAccess({ 'user', 'superadmin', 'rank_owner', 'rank_member' })
COMMAND_GETMODEL.Run = function(pPlayer)
    local ent = pPlayer:GetEyeTrace().Entity
    if (not IsValid(ent)) then
        DBase:SendMessage(pPlayer, DANLIB_TYPE_WARNING, DBase:L('#view.receive'))
        return
    end

    DBase:SendMessage(pPlayer, 0, DBase:L('model:'), Color(0, 255, 0), ent:GetModel(), color_white, DBase:L('#model.retrieved'))
    pPlayer:SendLua('SetClipboardText(' .. string.format('%q', tostring(ent:GetModel() or '')) .. ')')
end
COMMAND_GETMODEL:Register()


-- Pop-up notification
local COMMAND_NOTIFI = DBase.CreateCommand('sn')
COMMAND_NOTIFI:SetDescription('Sends a pop-up message on behalf of the server. {color: 251, 197, 49}(/sn ...){/color:}')
COMMAND_NOTIFI:SetAccess({ 'superadmin', 'rank_owner' })
COMMAND_NOTIFI.Run = function(pPlayer, sText)
    if (not pPlayer:IsSuperAdmin()) then
        DBase:ArgError(pPlayer, true)
        return
    end

    if (sText == '' or sText == nil) then 
        DBase:ArgError(pPlayer)
        return
    end
    DBase:SendGlobalNotifi(sText)
end
COMMAND_NOTIFI:Register()


-- Server message
local COMMAND_SERVERMSG = DBase.CreateCommand('sm')
COMMAND_SERVERMSG:SetDescription('Sends a message on behalf of the server. {color: 251, 197, 49}(/sm ...){/color:}')
COMMAND_SERVERMSG:SetAccess({ 'superadmin', 'rank_owner' })
COMMAND_SERVERMSG.Run = function(pPlayer, sText)
    if (not pPlayer:IsAdmin()) then
        DBase:ArgError(pPlayer, true)
        return
    end

    if (sText == '' or sText == nil) then 
        DBase:ArgError(pPlayer)
        return
    end
    DBase:SendGlobalMessage('SERVER', sText)
end
COMMAND_SERVERMSG:Register()