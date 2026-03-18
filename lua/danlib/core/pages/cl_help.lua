/***
 *   @addon         DanLib
 *   @version       3.0.0
 *   @release_date  10/4/2023
 *   @author        denchik
 *   @contact       Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Universal library for GMod Lua, combining all the necessary features to simplify script development. 
 *                  Avoid code duplication and speed up the creation process with this powerful and convenient library.
 *
 *   @usage         !danlibmenu (chat) | danlibmenu (console)
 *   @license       MIT License
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local base = DanLib.Func
local utils = DanLib.Utils


local HELP = base.CreatePage(base:L('#help'))
HELP:SetOrder(100)
HELP:SetIcon(DanLib.Config.Materials['Info'])

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
        local button = base.CreateUIButton(helpPanel, {
            dock_indent = { TOP, nil, nil, nil, 10 },
            background = { nil },
            hover = { nil },
            tall = base:Scale(100),
            paint = function(sl, w, h)
                sl:ApplyAlpha(0.3, 255)
                -- DanLib.DrawShadow:Begin()
                -- local x, y = sl:LocalToScreen(0, 0)      
                utils:DrawRoundedBox(0, 0, w, h, base:Theme('secondary_dark'))
                -- DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
                utils:DrawRoundedBox(0, 0, w, h, base:Theme('secondary', sl.alpha))

                local iconSize = base:Scale(64)
                utils:DrawIconOrMaterial((h / 2) - (iconSize / 2), (h / 2) - (iconSize / 2), iconSize, icon, base:Theme('mat', 150))
                utils:DrawDualTextWrap(h, 35, title, 'danlib_font_20', base:Theme('decor'), text, 'danlib_font_18', base:Theme('text'), TEXT_ALIGN_LEFT, nil, helpPanel:GetWide() - base:Scale(100) - 10)
            end,
            click = buttonFunc
        })

        helpPanel:SetTall(helpPanel:GetTall() + button:GetTall() + (helpPanel:GetTall() > 0 and 10 or 0))
        -- Centre the panel after adding the button
        centerHelpPanel()
    end

    createButton('DOCUMENTETION', 'Explore our documentation to find helpful guides, tips and answers to your questions!', 'HuFRarz', function()
        gui.OpenURL('https://ddi-docs.site/')
    end )

    createButton('DISCORD', 'If you need help or want to share your opinions, join the Discord server!', 'tBLUAUp', function()
        gui.OpenURL('https://discord.gg/CND6B5sH3j')
    end )

    if base.HasPermission(LocalPlayer(), 'Tutorial') then
        createButton('TUTORIAL', 'Forgot how to do something? Click here to go back to the tutorial and start again!', 'XCrjccb', function()
            base:QueriesPopup(base:L('#tutorial.reset'), base:L('#tutorial.reset.description'), nil, function()
                DanLib.BaseMenu:Toggle()
                base:TutorialDelete('DanLib.TutorialCompleted')
            end)
        end)
    end

    base:TutorialSequence(5, 2)
end



--- Prints the details of visible VGUI panels, including their size, position, and parent panel.
-- @param panel Panel: The VGUI panel to inspect.
-- @param indent string: The string used for indentation in the output (default is an empty string).
local function PrintVisiblePanels(panel, indent)
    indent = indent or '' -- Set the default indentation

    -- panel:SetVisible(true) -- Set the visibility of the current panel

    -- Check if the panel is visible
    if panel:IsVisible() then
        -- Get the name of the parent panel, if there is one
        local parentName = panel:GetParent() and panel:GetParent():GetName() or 'None'
        
        print(indent .. panel:GetName() .. ' - Size: ' .. tostring(panel:GetSize()) .. ' - Pos: ' .. tostring(panel:GetPos()) .. ' - Parent: ' .. parentName)

        function panel:Paint(w, h)
            surface.SetDrawColor(10, 10, 10, 50) -- Use the standard method for drawing
            surface.DrawRect(0, 0, w, h)
        end

        -- Go through all child elements
        for _, child in pairs(panel:GetChildren()) do
            PrintVisiblePanels(child, indent .. '  ') -- Increase the indentation for child elements
        end
    end
end

-- Call the function for the root element (usually a screen)
-- PrintVisiblePanels(vgui.GetWorldPanel())

