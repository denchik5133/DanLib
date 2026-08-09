/***
 *   @addon         DanLib
 *   @component     Debugging
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
local DUtils = DanLib.Utils
local DMaterial = DanLib.Config.Materials
local DCustomUtils = DanLib.CustomUtils.Create

-- Example of use
local DEBUG = DBase.CreateHUD('Debugging')

function DEBUG:AccessСheck(player)
    -- Logic to check if the player can see the item
    return true -- Return true if the item should be visible to the player
end

local ui = DanLib.UI
if ui:valid(DANLIB_MAINHUD) then
    DANLIB_MAINHUD:Remove()
end

local debug_panel
if ui:valid(debug_panel) then
    debug_panel:Remove()
end

function DEBUG:Create(parent)
    local width, height = 350, 80
    local t = 0.2

    -- Calculate coordinates for the centre of the screen
    local pos_x = (parent:GetWide() - width) / 2 -- Centre horizontally
    local pos_y = parent:GetTall() - height - 15 -- Set vertically with 15 pixels indentation

    if DanLib.CONFIG.BASE.Debugg then
        if ui:valid(debug_panel) then
            return
        end

        if ui:valid(debug_panel) then
            debug_panel:Remove()
        end

        debug_panel = DCustomUtils(parent)
        -- parent.debug = debug_panel

        debug_panel:SetPos(pos_x, parent:GetTall()) -- Starting position (off screen)
        debug_panel:SetSize(width, height)
        debug_panel:ApplyAttenuation(t)
        debug_panel:MoveTo(pos_x, pos_y, t, 0, -10) -- Move to the desired position
        debug_panel:ApplyBackground(DBase:Theme('primary_notifi'), 8)

        local type_icon = DanLib.TYPE['WARNING']
        local type_color = DanLib.TYPE_COLOR['WARNING']

        debug_panel:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawRoundedMask(8, 0, 0, w, h, function()
                DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('primary_notifi'))
                -- DUtils:DrawOutlinedRoundedRect(8, 0, 0, w, h, 4, DBase:Theme('frame'))
                DUtils:DrawTextureGradient(0, 0, w, h, 0, 0, 4, 1, nil, 'vgui/alpha-back')

                local squareSize = 64
                DUtils:DrawSquareWithIcon(8, (h - squareSize) / 2, DBase:Theme('secondary_dark'), squareSize, DMaterial['Warning'], 6)

                local text_x, text_y = squareSize + 24, h / 2
                local Text = DUtils:TextWrap(DBase:L('SysDebugMode'), 'danlib_font_18', 250)
                DUtils:DrawDualText(text_x, text_y, 'WARNING', 'danlib_font_18', type_color, Text, 'danlib_font_18', DBase:Theme('title'), TEXT_ALIGN_LEFT)
            end)
        end)
    else 
        if (not ui:valid(debug_panel) or not ispanel(debug_panel)) then
            debug_panel = nil
            return
        end

        debug_panel:MoveTo(pos_x, parent:GetTall(), t, nil, nil, function()
            debug_panel = nil
        end)
    end

    return debug_panel
end
