/***
 *   @addon         DanLib
 *   @component     Owner notification
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
 *   @license       MIT License
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DNet = DanLib.Net
local DMaterial = DanLib.Config.Materials
local DCustomUtils = DanLib.CustomUtils.Create

-- Example of use
local NOTIFY = DBase.CreateHUD('owner_notify')

local ui = DanLib.UI
local notify_panel
local showNotification = false
local squareSize = 64

if ui:valid(DANLIB_MAINHUD) then
    DANLIB_MAINHUD:Remove()
end

if ui:valid(notify_panel) then
    notify_panel:Remove()
end

DNet:On('DanLib.NotifyNoOwner', function()
    local notificationType = DNet:Str()
    if (notificationType == 'no_owner') then
        showNotification = true
    else
        showNotification = false
    end
end)


function NOTIFY:Create(parent)
    local width, height = 400, 110
    local t = 0.2
    local test = true

    -- Calculate coordinates for the centre of the screen
    local pos_x = 10 -- Centre horizontally
    local pos_y = parent:GetTall() - height - 15 -- Set vertically with 15 pixels indentation

    if showNotification then
        if ui:valid(notify_panel) then
            return
        end

        if ui:valid(notify_panel) then
            notify_panel:Remove()
        end

        notify_panel = DCustomUtils(parent)
        notify_panel:SetPos(pos_x, parent:GetTall()) -- Starting position (off screen)
        notify_panel:SetSize(width, height)
        notify_panel:ApplyAttenuation(t)
        notify_panel:MoveTo(pos_x, pos_y, t, 0, -10) -- Move to the desired position
        notify_panel:SetDrawOnTop(true)

        local type_icon = DanLib.TYPE['WARNING']
        local type_color = DanLib.TYPE_COLOR['WARNING']

        notify_panel:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
                DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('primary_notifi'))
                DUtils:DrawTextureGradient(0, 0, w, h, 0, 0, 4, 1, DBase:GetColor('Red', 20), 'vgui/alpha-back')
                DUtils:DrawSquareWithIcon(10, (h - squareSize) / 2, DBase:GetColor('Red', 20), squareSize, DMaterial['Lock'], 6)

                local textWrap = DUtils:TextWrap(DBase:L('#rank.no.owner'), 'danlib_font_18', 310)
                draw.DrawText(textWrap, 'danlib_font_18', squareSize + 20, 10, DBase:Theme('title'), TEXT_ALIGN_LEFT)
            end)
        end)

        DBase.CreateUIButton(notify_panel, {
            dock = { FILL, 2 },
            background = { nil },
            hover = { nil },
            click = function()
                DBase:QueriesPopup(DBase:L('#owner.setup'), DBase:L('#owner.setup.description'), nil, function()
                    if showNotification then
                        DNet:Open('DanLib.SetupOwner'):Up()
                        notify_panel:MoveTo(pos_x, parent:GetTall(), t, nil, nil, function()
                            notify_panel = nil
                            DanLib.Timer:Simple(1, DanLib.PopupWelcome)
                        end)
                    else
                        notify_panel:MoveTo(pos_x, parent:GetTall(), t, nil, nil, function()
                            notify_panel = nil
                        end)
                    end
                end)
            end
        })
    else 
        if (not ui:valid(notify_panel) or not ispanel(notify_panel)) then
            notify_panel = nil
            return
        end

        notify_panel:MoveTo(pos_x, parent:GetTall(), t, nil, nil, function()
            notify_panel = nil
        end)
    end

    return notify_panel
end
