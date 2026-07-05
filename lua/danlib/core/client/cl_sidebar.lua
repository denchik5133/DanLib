/***
 *   @addon         DanLib
 *   @component     UI Sidebar | Sidenav
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
local DCustomUtils = DanLib.CustomUtils.Create

function DBase.CreateUISidebar(parent)
	local PANEL = DCustomUtils(parent)

	PANEL:Pin(LEFT)
	PANEL:SetWide(50)

	PANEL.selectedBtn = nil
	PANEL.selectedPanel = nil

	PANEL.tabCount = 0
	PANEL.fadeSpeed = 0.1

	PANEL.loadedPanels = { }
	PANEL.pags = { }

	PANEL.accentColor = nil

	PANEL.SetAccentColor = function(self, color)
		self.accentColor = color
	end

	PANEL.SetFadeSpeed = function(self, speed)
		self.fadeSpeed = speed
	end

	PANEL.SetBackground = function(self, color)
		self.background = color
	end 

	PANEL.SwitchTab = function(self, tab, panel)
		if (not self.loadedPanels[panel]) then
			local pStr = panel

			panel = self:GetParent():Add(panel)
			panel:CustomUtils()
			panel:Pin(FILL, 8)

			if panel.FillPanel then
				panel:FillPanel()
			end

			self.loadedPanels[pStr] = panel
		else
			panel = self.loadedPanels[panel]
		end

		self.selectedBtn = tab

		if (self.selectedPanel == panel) then 
			return 
		end

		if (self.tabCount == 0) then
			panel:SetVisible(true)
		else
			local prevPanel = self.selectedPanel

			if (IsValid(prevPanel)) then
				prevPanel:ApplyFadeOutPanel(self.fadeSpeed, function()
					panel:ApplyFadeInPanel(self.fadeSpeed)
				end)
			end
		end

		self.selectedPanel = panel
	end

	PANEL.AddPage = function(self, text, icon, panel, sAlign)
		local Button = DBase:CreateButton(self)
		Button:Pin(sAlign and BOTTOM or TOP, 4)
		Button:SetTall(44)

		if (self.tabCount == 0) then
			self:SwitchTab(Button, panel)
		end

		local Margin = 2
		Button.Enabled = true
		Button:ApplyTooltip(text, nil, nil, LEFT)
		Button.s = 24
		Button:ApplyEvent(nil, function(sl, w, h)
			if (sl:GetParent().selectedBtn == sl) then
				DUtils:DrawRect(0, 0, w, h, sl:GetParent().accentColor or DBase:Theme('button_hovered', 150))
				-- DUtils:DrawRect(0, 0, Margin, h, sl:GetParent().accentColor or DBase:Theme('decor2'))
			end

			local icons = icon
			if icons then
				if isstring(icons) then
					DUtils:DrawIcon(w / 2 + Margin / 2 - sl.s / 2, h / 2 - sl.s / 2, sl.s, sl.s, icons, DBase:Theme('mat', 150))
				else
					DUtils:DrawMaterial(w / 2 + Margin / 2 - sl.s / 2, h / 2 - sl.s / 2, sl.s, sl.s, DBase:Theme('mat', 150), icons)
				end
			end
		end)

		Button.SetActive = function(sl, bool)
			sl:SetEnabled(bool)
			sl:SetCursor(bool and 'none' or 'no')

			sl.Enabled = false
		end

		Button.DoClick = function()
			self:SwitchTab(Button, panel)
		end

		self.tabCount = self.tabCount + 1
		self.pags[Button] = panel

		return Button
	end

	PANEL.AddCloseButton = function(self, text, icon, func)
		text = text or DBase:L('#close')
		icon = icon or DanLib.Config.Materials['Close']

		local Button = DBase:CreateButton(self)
		Button:Pin(BOTTOM, 4)
		Button:SetTall(40)
		Button:ApplyTooltip(text, nil, nil, LEFT)
		Button.s = 24
		Button:ApplyEvent(nil, function(sl, w, h)
			local icons = icon
			if icons then
				DUtils:DrawIconOrMaterial(w / 2 - sl.s / 2, h / 2 - sl.s / 2, sl.s, icons, DBase:Theme('mat', 150))
			end
		end)

		if func then
			Button.DoClick = func
		end

		return Button
	end

	PANEL.Paint = function(self, w, h)
		DUtils:DrawRect(0, 0, w, h, self.background or DBase:Theme('secondary_dark'))
	end
	PANEL:ApplyShadow(10, false)

	return PANEL
end


local NAVIGATION, Constructor = DanLib.UiPanel()
-- Accessors for icon colors
NAVIGATION:Accessor('IconColor', Constructor.Color)
NAVIGATION:Accessor('IconHover', Constructor.Color)

--- Initializes the navigation panel
function NAVIGATION:Init()
	-- Set default colors
	self:SetIconHover(255, 255, 255)

	-- Layout configuration
	self:Dock(LEFT)
	self:DockPadding(8, 8, 8, 8)
	self:SetWide(50)

	-- Container for the icons
	self.container = self:Add('EditablePanel')
	self.container:Dock(FILL)

	-- Layout for the pages
	self.pages = self.container:Add('DIconLayout')
	self.pages:Dock(FILL)
	self.pages:SetSpaceY(10)

	self.activeTab = nil

	-- Close button with functionality
	local close = self:AddIcon(DanLib.Config.Materials['Close'], DanLib.Func:L('#close'), function()
		self.Container:SetAlpha(180)
		self.Container:AlphaTo(0, 0.3)
        self.MainMenu:SetAlpha(255)
        self.MainMenu:AlphaTo(0, 0.2, 0, function()
            self.MainMenu:Remove()
            DanLib.Func:TutorialSequence(4, 7)
        end)

        if IsValid(DANLIB_TUTORIAL) then
            DANLIB_TUTORIAL:SetAlpha(255)
            DANLIB_TUTORIAL:AlphaTo(0, 0.2)
        end
	end)
	close:Dock(BOTTOM)
end

--- Adds a new tab to the navigation
-- @param ico: The icon for the tab
-- @param name: The display name of the tab
-- @param cback: The callback function when the tab is clicked
function NAVIGATION:AddTab(ico, name, cback)
	return self:AddIcon(ico, name, cback, self.pages)
end

--- Adds an icon to the navigation
-- @param ico: The icon to display
-- @param name: The tooltip text
-- @param cback: The callback function on click
-- @param parent: The parent panel for the icon
-- @return The created icon panel
function NAVIGATION:AddIcon(ico, name, cback, parent)
	local icon = (parent or self.container):Add('EditablePanel'):CustomUtils()
	icon:SetSize(36, 36)
	-- icon:SetColor(self:GetIconColor())
	icon:SetCursor('hand')
	icon.hovered = false
	icon.size = 24
	icon.ActivColor = DanLib.Func:Theme('mat', 150)

	-- Draw the icon
	icon:ApplyEvent(nil, function(sl, w, h)
	    DUtils:DrawIconOrMaterial(w / 2 - sl.size / 2, h / 2 - sl.size / 2, sl.size, ico, sl.ActivColor)
	end)

	-- Handle hover effects
	icon:ApplyEvent('Think', function(sl)
		if (sl.hovered ~= sl:IsHovered()) then
			sl.hovered = sl:IsHovered()
			sl:Stop()
			sl:ColorTo(sl.hovered and self:GetIconHover() or self:GetIconColor(), 0.3)
		end
	end)

	-- Handle click events
	icon:ApplyEvent('OnMouseReleased', function(sl, mcode)
		if (mcode == MOUSE_LEFT and sl.Click) then
			sl:Click()
			self.activeTab = icon
            self:UpdateActiveTab()
		end
	end)

	icon:ApplyTooltip(name, nil, nil, LEFT)
	icon.Click = cback

	return icon
end

--- Updates the visual state of the active tab
function NAVIGATION:UpdateActiveTab()
    for _, child in ipairs(self.pages:GetChildren()) do
        if (child == self.activeTab) then
            child.ActivColor = DanLib.Func:Theme('mat', 150) -- Colour for the active tab
        else
            child.ActivColor = Color(100, 100, 100) -- Colour for inactive tabs
        end
    end
end

--- Layout function for custom layout logic
function NAVIGATION:PerformLayout(w, h)
	-- Custom layout logic can be added here if needed
end

--- Paint function for custom drawing
function NAVIGATION:Paint(w, h)
	DUtils:DrawRect(0, 0, w, h, DanLib.Func:Theme('secondary_dark'))
end

NAVIGATION:Register('DanLib.UI.Sidenav')