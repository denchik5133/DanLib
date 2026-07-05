/***
 *   @addon         DanLib
 *   @component     Help Page
 *   @license       MIT License
 *   @version       1.0.4
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


local HELP = DBase.CreatePage('help')
HELP:SetName(DBase:L('#help'))
HELP:SetOrder(100)
HELP:SetIcon(DanLib.Config.Materials['Info'])
HELP:SetID('help')

function HELP:Create(container)
	local helpPanel = DanLib.CustomUtils.Create(container)
    helpPanel:SetSize(container:GetWide() - 150, 0)

    -- Set the position to centre
    local function centerHelpPanel()
        local containerWidth = container:GetWide()
        local containerHeight = container:GetTall()
        local helpPanelWidth = helpPanel:GetWide()
        local helpPanelHeight = helpPanel:GetTall()
        helpPanel:SetPos((containerWidth - helpPanelWidth) / 2, (containerHeight - helpPanelHeight) / 2)
    end

    -- Call the function for centring
    centerHelpPanel()

    local function createButton(title, text, icon, buttonFunc)
        local button = DBase.CreateUIButton(helpPanel, {
            dock_indent = { TOP, nil, nil, nil, 10 },
            background = { nil },
            hover = { nil },
            tall = DBase:Scale(100),
            paint = function(sl, w, h)
                sl:ApplyAlpha(0.3, 255)
                -- DanLib.DrawShadow:Begin()
                -- local x, y = sl:LocalToScreen(0, 0)      
                DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('secondary_dark'))
                -- DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
                DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('secondary', sl.alpha))

                local iconSize = DBase:Scale(64)
                DUtils:DrawIconOrMaterial((h / 2) - (iconSize / 2), (h / 2) - (iconSize / 2), iconSize, icon, DBase:Theme('mat', 150))
                DUtils:DrawDualTextWrap(h, 35, title, 'danlib_font_20', DBase:Theme('decor'), text, 'danlib_font_18', DBase:Theme('text'), TEXT_ALIGN_LEFT, nil, helpPanel:GetWide() - DBase:Scale(100) - 10)
            end,
            click = buttonFunc
        })

        helpPanel:SetTall(helpPanel:GetTall() + button:GetTall() + (helpPanel:GetTall() > 0 and 10 or 0))
        -- Centre the panel after adding the button
        centerHelpPanel()
    end

    createButton('DOCUMENTETION', 'Explore our documentation to find helpful guides, tips and answers to your questions!', 'HuFRarz', function()
        gui.OpenURL('https://ddi-docs.site/')
    end)

    createButton('DISCORD', 'If you need help or want to share your opinions, join the Discord server!', 'tBLUAUp', function()
        gui.OpenURL('https://discord.gg/CND6B5sH3j')
    end)

    if DBase.HasPermission(LocalPlayer(), 'Tutorial') then
        createButton('TUTORIAL', 'Forgot how to do something? Click here to go back to the tutorial and start again!', 'XCrjccb', function()
            DBase:QueriesPopup(DBase:L('#tutorial.reset'), DBase:L('#tutorial.reset.description'), nil, function()
                DanLib.BaseMenu:Toggle()
                DBase:TutorialDelete('DanLib.TutorialCompleted')
            end)
        end)
    end

    DBase:TutorialSequence(5, 2)
end
