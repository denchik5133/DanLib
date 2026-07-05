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



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local UI = DanLib.UI
local PANEL, _ = DanLib.UiPanel()
local DNetworkUtil = DanLib.NetworkUtil
local DCustomUtils = DanLib.CustomUtils.Create

local _IsValid = IsValid
local _Vector = Vector
local _Angle = Angle
local _pairs = pairs
local _Color = Color
local _RealTime = RealTime
local _Clamp = math.Clamp
local _SimpleText = draw.SimpleText
local _strformat = string.format

-- initialize
function PANEL:Init()
    -- interface settings storage
	self.modelSetup = {
		['fov'] = {
			name = 'Field of View',
			text = 'Field of view',
			value = 110,
			min = 0,
			max = 180
		},
		['campos_x'] = {
			name = 'campos x',
			text = 'Camera pos x',
			value = 100,
			min = -1000,
			max = 1000
		},
		['campos_y'] = {
			name = 'campos y',
			text = 'Camera pos y',
			value = 0,
			min = -1000,
			max = 1000
		},
		['campos_z'] = {
			name = 'campos z',
			text = 'Camera pos z',
			value = 0,
			min = -1000,
			max = 1000
		},
		['lookat_x'] = {
			name = 'lookat x',
			text = 'Lookat pos x',
			value = 0,
			min = -1000,
			max = 1000
		},
		['lookat_y'] = {
			name = 'lookat y',
			text = 'Lookat pos y',
			value = 0,
			min = -1000,
			max = 1000
		},
		['lookat_z'] = {
			name = 'lookat z',
			text = 'Lookat pos z',
			value = 0,
			min = -1000,
			max = 1000
		}
	}

    self.panelWidth, self.panelHeight = 800, 600
    self.defaultFont18 = 'danlib_font_18'
    self.IsToggleAnimation = false

    -- Sets the size of the panel.
    self:SetSize(self.panelWidth, self.panelHeight)
    -- Sets the minimum width the DFrame can be resized to by the user.
    -- Sets the minimum height the DFrame can be resized to by the user.
    self:SetMinWMinH(self.panelWidth, self.panelHeight) -- minHeight
    -- Focuses the panel and enables it to receive input.
    self:MakePopup()
    -- Sets the title of the frame.
    self:SetTitle('Model Viewer')

    self:ApplyAppear(5)

    -- if turned on, however this is extremely unreliable for detecting a valid model due to the
    -- restrictions it has. it is recommended to keep this off unless you need to see if the game sees
    -- a particular model as valid
    self.bIsValidOnly = false

	-- Set default values
    self.defaultModel = 'models/props_interiors/VendingMachineSoda01a.mdl'

    -- Subpanel creation
    self.subPanel = DCustomUtils(self)
    self.subPanel:Pin()

    -- model panel
    self.modelPanel = DCustomUtils(self.subPanel, 'DModelPanel')
    self.modelPanel:Pin()
    self.modelPanel:SetModel(self.defaultModel)
    self.modelPanel:ApplyEvent('LayoutEntity', function(ent, sl)
    	if (not self.IsToggleAnimation) then
	        sl:SetAngles(_Angle(0, 0, 0))
	        return
	    end

	    if self.modelPanel.bAnimated then self.modelPanel:RunAnimation() end
	    sl:SetAngles(_Angle(0, _RealTime() * 10 % 360, 0))
    end)
	self.modelPanel:ApplyEvent('Think', function(sl)
        if (sl:GetModel() == self.defaultModel) then
	        sl:SetFOV(62)
	        sl:SetCamPos(_Vector(187, -107, 93))
	        sl:SetLookAt(_Vector(20, 13, 13))
	        return
	    end
	    sl:SetFOV(self.modelSetup['fov'].value)
	    sl:SetCamPos(_Vector(self.modelSetup['campos_x'].value, self.modelSetup['campos_y'].value, self.modelSetup['campos_z'].value))
	    sl:SetLookAt(_Vector(self.modelSetup['lookat_x'].value, self.modelSetup['lookat_y'].value, self.modelSetup['lookat_z'].value))
    end)
	self.modelPanel:ApplyEvent('PaintOver', function(sl, w, h)
	    local posY = 10
	    local label = _Color(200, 200, 200, 255)
	    local clr_value = _Color(93, 180, 255, 255)

	    local sizeW, sizeH = w, h
        DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
	       draw.TexturedQuad({
            texture = surface.GetTextureID('gui/gradient_up'),
            color = _Color(93, 180, 255, 60),
            x = 0,
            y = sizeH - 100,
            w = sizeW,
            h = 100
        })
        end)

        local camPos = _Vector(self.modelSetup['campos_x'].value, self.modelSetup['campos_y'].value, self.modelSetup['campos_z'].value)
        local lookAt = _Vector(self.modelSetup['lookat_x'].value, self.modelSetup['lookat_y'].value, self.modelSetup['lookat_z'].value)
        local fov = self.modelSetup['fov'].value

        _SimpleText(_strformat('Cam(%.1f, %.1f, %.1f)', camPos.x, camPos.y, camPos.z), self.defaultFont18, 15, 15, label, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        _SimpleText(_strformat('Look(%.1f, %.1f, %.1f)', lookAt.x, lookAt.y, lookAt.z), self.defaultFont18, 15, posY + 23, label, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        _SimpleText(_strformat('FOV: %s', self.modelSetup['fov'].value), self.defaultFont18, 15, posY + 43, label, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	    _SimpleText('Animations', self.defaultFont18, 45, posY + 74, label, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	    _SimpleText('Show valid only', self.defaultFont18, 45, posY + 103, label, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end)

    self.modelPanel:ApplyEvent('OnMouseWheeled', function(_, delta)
        -- Changing the FOV based on mouse wheel movement
        self.modelSetup['fov'].value = _Clamp(self.modelSetup['fov'].value - delta * 5, 10, 180) -- Increase or decrease the multiplier to adjust the zoom speed
    end)

    self.modelPanel:ApplyEvent('OnMouseReleased', function(panel, mcode)
        if (mcode == MOUSE_LEFT) then
            self:CreatePopout()
        end
    end)

    local CheckBox = DBase.CreateCheckbox(self.modelPanel)
    CheckBox:SetPos(15, 80)
    CheckBox:SetSize(24, 24)
    CheckBox:SetValue(self.IsToggleAnimation and true or false)
    CheckBox:DisableShadows()
    CheckBox:ApplyEvent('OnChange', function(_, value)
        self.IsToggleAnimation = value
    end)

    local CheckBox = DBase.CreateCheckbox(self.modelPanel)
    CheckBox:SetPos(15, 110)
    CheckBox:SetSize(24, 24)
    CheckBox:SetValue(self.bIsValidOnly and true or false)
    CheckBox:DisableShadows()
    CheckBox:ApplyEvent('OnChange', function(_, value)
        self.bIsValidOnly = value
    end)
end

function PANEL:CreatePopout()
    local panelW = 250
    local panelX = ScrW() / 2 - panelW
    local panelY = 15
    local panelWide = panelW * 0.7

    if _IsValid(self.subPanel.Popout) then
        self.subPanel.Popout:Remove()
    else
        local popoutClose = DCustomUtils(self)
        popoutClose:Pin()
        popoutClose:ApplyAttenuation(0.2)
        popoutClose:SetCursor('hand')
        popoutClose:ApplyEvent('OnMousePressed', function(sl)
            self.subPanel.Popout:MoveTo(panelX, panelY, 0.2, 0, -1, function()
                if _IsValid(self.subPanel.Popout) then
                    self.subPanel.Popout:Remove()
                end
            end)

            sl:AlphaTo(0, 0.2, 0, function()
                if _IsValid(sl) then
                    sl:Remove()
                end
            end)
        end)

        self.subPanel.Popout = DCustomUtils(popoutClose)
        self.subPanel.Popout:SetSize(panelW, 500)
        self.subPanel.Popout:SetPos(panelX, panelY)
        self.subPanel.Popout:MoveTo((panelX) - (panelWide), panelY, 0.2)
        self.subPanel.Popout:ApplyBackground(DBase:Theme('secondary_dark'), 6)
        self.controlsPanel = self.subPanel.Popout

        self.blockPanel = DCustomUtils(self.controlsPanel)
        self.blockPanel:Pin(TOP, 8)
        self.blockPanel:SetTall(35)

        local TextEntry = DBase.CreateTextEntry(self.blockPanel)
        TextEntry:PinMargin(nil, 5, 5, 4, 5)
        TextEntry:SetValue(self.defaultModel)
        TextEntry:ApplyEvent('OnEnter', function(sl)
            local val = sl:GetValue()
            val = DBase:TrimWhitespace(val)

            if _IsValid(self.modelPanel) then
                if (self.bIsValidOnly and DNetworkUtil:IsValidModel(self.modelPanel:GetModel()) or not self.bIsValidOnly) then
                    self.modelPanel:SetModel(val)
                else
                    self.modelPanel:SetModel(self.defaultModel)
                end
            end
        end)

        -- button clear
        DBase.CreateUIButton(self.blockPanel, {
            dock_indent = { RIGHT, 5, 5, 4, 5 },
            wide = 24,
            icon = { 'EkxU20l', 16 },
            tooltip = { 'Clear', nil, nil, TOP },
            click = function(sl)
                TextEntry:SetValue(self.defaultModel)
                self.modelPanel:SetModel(self.defaultModel)
            end
        })

        -- scroll panel
        self.scrollPanel = DCustomUtils(self.controlsPanel, 'DanLib.UI.Scroll')
        self.scrollPanel:Pin(nil, 8)

        -- loop through modelSetup to create UI elements
        for key, value in _pairs(self.modelSetup) do
            -- left container
            self.container = DCustomUtils(self.scrollPanel)
            self.container:Pin(TOP, 4)

            self.slider = DBase.CreateNumSlider(self.container, value.text)
            self.slider:Pin()
            self.slider:SetMin(value.min)
            self.slider:SetMax(value.max)
            self.slider:SetValue(self.modelSetup[key].value or 0)
            self.slider:ApplyEvent('OnValueChanged', function(sl)
                self.modelSetup[key].value = sl:GetValue()
            end)
        end
    end
end

PANEL:SetBase('DanLib.UI.Frame')
PANEL:Register('DanLib.UI.ModelViewerMenu')





if _IsValid(DanLib.ModelViewerMenu) then
    DanLib.ModelViewerMenu:Remove()
end

local function ModelViewerMenu()
	if _IsValid(DanLib.ModelViewerMenu) then
        DanLib.ModelViewerMenu:Remove()
    end

    local modelPanel = DCustomUtils(nil, 'DanLib.UI.ModelViewerMenu')
    DanLib.ModelViewerMenu = modelPanel
end
-- ModelViewerMenu()
