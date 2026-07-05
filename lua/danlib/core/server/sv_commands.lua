/***
 *   @addon         DanLib
 *   @component     SV Commands
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



DanLib.Concommand:Add('danlibmenu', function(pPlayer)
    DanLib.Net:Open('DanLib:BaseMenu'):Send(pPlayer)
end)

DanLib.Hook:Add('PlayerSay', 'DanLib.hooksOpenConfig', function(pPlayer, text)
    if (text:lower():sub(1, 1) ~= '!' or text:lower():sub(2, #DanLib.CONFIG.BASE.ChatCommand + 1) ~= DanLib.CONFIG.BASE.ChatCommand) then
        return
    end
    
    DanLib.Net:Open('DanLib:BaseMenu'):Send(pPlayer)
    return ''
end)

DanLib.Concommand:Add('ddi_player_coordinates', function(pPlayer)
    local pos, ang = pPlayer:GetPos(), pPlayer:GetAngles()
    pPlayer:PrintMessage(HUD_PRINTCONSOLE, string.format('{pos = Vector(%g, %g, %g), ang = Angle(%g, %g, %g)},', pos.x, pos.y, pos.z, ang.x, ang.y, ang.z))
end)