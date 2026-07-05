/***
 *   @addon         DanLib
 *   @component     UI Tutorial
 *   @license       MIT License
 *   @version       1.0.3
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
local defaultFont = 'danlib_font_18'
local DUtils = DanLib.Utils
local DHook = DanLib.Hook
local DCookieUtils = DanLib.CookieUtils
local DCustomUtils = DanLib.CustomUtils.Create

local _IsValid = IsValid
local _Clamp = math.Clamp
local _min = math.min

--- Creates a panel to display the tutorial.
-- @param parent (Panel): The parent panel to which the tutorial panel will be attached.
-- @return (Panel): The created panel of the tutorial.
function DBase:CreateUITutorial(parent)
    local PANEL = DCustomUtils(parent)

    PANEL:SetDrawOnTop(true)
    PANEL:ApplyAttenuation(0.2)
    PANEL.headerHeight = 20
    PANEL.defaultH = 24
    PANEL:SetSize(ScrW() * 0.16, PANEL.defaultH)

    --- Sets the current tutorial and initialises the panel.
    -- @param tutorialKey (string): The key of the tutorial to be loaded.
    function PANEL:SetTutorial(tutorialKey)
        self:Clear()
        self.tutorialKey, self.stepKey = tutorialKey, 1
        self.progressWidth = 0 -- Initial width of the progress bar
        self.targetWidth = 0 -- Target width of the progress bar

        local tutorialConfig = DanLib.BaseConfig.Tutorials[tutorialKey]

        -- Creating a progress bar
        self.progressPanel = DCustomUtils(self)
        self.progressPanel:Pin(TOP)
        self.progressPanel:SetTall(34)
        self.progressPanel:ApplyBackground(DBase:Theme('line_up'), 6, { true, true, false, false })
        self.progressPanel:ApplyEvent(nil, function(sl, w, h)
            -- Progress bar drawing with interpolation
            self.progressWidth = Lerp(0.1, self.progressWidth, w * _Clamp((self.stepKey - 1) / #tutorialConfig.Steps, 0, 1))
            DUtils:DrawRoundedBox(0, h - 2, self.progressWidth, 2, DBase:Theme('decor2'))
            draw.SimpleText('Chapter: ' .. tutorialConfig.Title, defaultFont, 8, h / 2 - 2, DBase:Theme('text'), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText('Step ' .. self.stepKey .. '/' .. #tutorialConfig.Steps, defaultFont, w - 8, h / 2 - 2, DBase:Theme('text'), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end)

        self.scrollPanel = DCustomUtils(self, 'DanLib.UI.Scroll')
        self.scrollPanel:Pin(FILL, 6)
        -- self.scrollPanel:ToggleScrollBar()

        -- Creating a step information panel
        self.stepInfo = DCustomUtils(self.scrollPanel)
        self.stepInfo:Pin(TOP)
        self.stepInfo:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawParseText(sl.stepText or '', defaultFont, 8, 4, DBase:Theme('text'), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, self.scrollPanel:GetWide() - 22, TEXT_ALIGN_LEFT)
        end)
        
        -- Set the maximum height
        local MAX_HEIGHT = 520

        -- Setting the function to update the step text
        self.stepInfo.SetStepKey = function(sl, stepKey)
            self.stepKey = stepKey

            sl.stepText = tutorialConfig.Steps[stepKey]
            local text = DUtils:TextWrap(sl.stepText, defaultFont, self.scrollPanel:GetWide() - 22, true)
            local text_h = DUtils:TextSize(text, defaultFont).h

            local additionalHeight = (tutorialConfig.Further == false) and 2 or 24
            local additionalButton = (tutorialConfig.Further == false) and 0 or 8
            local newHeight = self.defaultH + 24 + additionalHeight + additionalButton + sl:GetTall()

            -- Set the height taking into account the maximum limitation
            sl:SetTall(6 + text_h)
            -- Update the total height of the panel
            self:SetTall(_min(self.defaultH + 24 + additionalHeight + additionalButton + sl:GetTall(), MAX_HEIGHT))
        end

        local closeTutorial = tutorialKey >= #DanLib.BaseConfig.Tutorials

        -- Creating a "Further" button, if necessary
        if tutorialConfig.Further then
            self.ButtonFurther = DBase.CreateUIButton(self, {
                dock_indent = { BOTTOM, 8, 6, 8, 6 },
                text = { closeTutorial and 'Close' or 'Further' },
                click = function(sl)
                    DBase:TutorialSequence(tutorialKey, self.stepKey)
                end
            })
        end

        self:SetStepKey(self.stepKey)
    end

    --- Sets the current step key.
    -- @param stepKey (number): The number of the step to set.
    function PANEL:SetStepKey(stepKey)
        self.stepInfo:SetStepKey(stepKey)
    end

    --- Draws the panel.
    PANEL:ApplyEvent(nil, function(sl, w, h)
        DanLib.DrawShadow:Begin()
        local x, y = sl:LocalToScreen(0, 0)
        DUtils:DrawRoundedBox(x, y, w, h, DBase:Theme('background'))
        DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)
    end)

    return PANEL
end

-- Setting up a tutorial
local function _setupTutorial(mainMenu)
    local pPlayer = LocalPlayer()
    
    if (not DBase.HasPermission(pPlayer, 'Tutorial')) then
        return
    end
    
    local tutorialStep = DCookieUtils:GetNumber('DanLib.TutorialCompleted', 0)
    local totalTutorials = #DanLib.BaseConfig.Tutorials
    
    if (tutorialStep < totalTutorials and not _IsValid(DANLIB_TUTORIAL)) then
        DANLIB_TUTORIAL = DBase:CreateUITutorial(mainMenu)
        DANLIB_TUTORIAL:SetPos(50, 100)
        DANLIB_TUTORIAL:SetTutorial(tutorialStep + 1)
    end
end

-- Registering a hook for Tutorial
DHook:Add('DanLib.MainMenu', 'DanLib.Menu.SetupTutorial', function(mainMenu)
    _setupTutorial(mainMenu)
end)

--- Controls the sequence of tutorial steps.
-- @param tutorialKey (string): The key of the current tutorial.
-- @param stepKey (number): The number of the current step.
function DBase:TutorialSequence(tutorialKey, stepKey)
    if (not _IsValid(DANLIB_TUTORIAL)) then
        return
    end

    local activeTutorialKey = DANLIB_TUTORIAL.tutorialKey
    if (activeTutorialKey != tutorialKey) then
        return
    end

    local activeStepKey = DANLIB_TUTORIAL.stepKey
    if (activeStepKey != stepKey) then
        return
    end

    local tutorialConfig = DanLib.BaseConfig.Tutorials[tutorialKey]
    if (not tutorialConfig.Steps[stepKey + 1]) then
        DCookieUtils:Set('DanLib.TutorialCompleted', tutorialKey)

        if DanLib.BaseConfig.Tutorials[tutorialKey + 1] then
            DANLIB_TUTORIAL:SetTutorial(tutorialKey + 1)
        else
            DANLIB_TUTORIAL:Remove()
        end
        return
    end

    DANLIB_TUTORIAL:SetStepKey(stepKey + 1)
end


--- Deletes the specified cookie.
-- @param cookieName (string): The name of the cookie to delete.
function DBase:TutorialDelete(cookieName)
    if (not cookieName) then
        error('cookieName is missing!')
        return
    end
    DCookieUtils:Delete(cookieName)
end
-- DBase:TutorialDelete('DanLib.TutorialCompleted')
