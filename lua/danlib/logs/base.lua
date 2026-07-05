/***
 *   @addon         DanLib
 *   @component     Module Logs Base
 *   @license       MIT License
 *   @version       1.5.1
 *   @release_date  01/12/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *   
 *   @description   Enhanced Discord logging system with queue, batch, and retry mechanisms
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */
 


local DBase = DanLib.Func
local DHook = DanLib.Hook

-- ============================================
-- CONFIGURATION LOG
-- ============================================
local CONFIG = DBase.CreateLogs('Configuration')
CONFIG:SetDescription('Configuration changes. This parameter allows you to track who changes the configuration of the base.')
CONFIG:SetColor(Color(255, 165, 0)) -- Orange
CONFIG:SetAddon('DanLib')
CONFIG:SetSort(1)
CONFIG:SetPriority(2) -- HIGH PRIORITY
CONFIG:SetSetup(function()
    if SERVER then
        DHook:Add('DanLib:HooksConfigUpdated', 'Logs.SaveConfig', function(pPlayer, tbl)
            local configJSON = DanLib.NetworkUtil:TableToJSON(tbl, true)
            CONFIG:Send(DBase:L('save_config', {
                player = pPlayer:Nick(),
                steamid = pPlayer:SteamID(),
                steamid64 = pPlayer:SteamID64(),
                table = configJSON
            }))
        end)
    end
end)
CONFIG:Register()

-- ============================================
-- RANK CHANGE LOG
-- ============================================
local RANK = DBase.CreateLogs('EditRank')
RANK:SetDescription("Changing a player's rank.")
RANK:SetColor(Color(0, 165, 0)) -- Green
RANK:SetAddon('DanLib')
RANK:SetSort(2)
RANK:SetPriority(1) -- CRITICAL PRIORITY
RANK:SetSetup(function()
    if SERVER then
        DHook:Add('DanLib.Rank.Changed', 'Logs.Rank', function(pPlayer, old_rank, new_rank, author)
            local fields = {
                { name = 'To whom', value = pPlayer:Name(), inline = true },
                { name = 'Old Rank', value = old_rank, inline = true },
                { name = 'New Rank', value = new_rank, inline = true },
                { name = 'Author', value = author:Name(), inline = true },
            }
            RANK:Send(DBase:L('#rank.log.changed'), fields)
        end)
    end
end)
RANK:Register()