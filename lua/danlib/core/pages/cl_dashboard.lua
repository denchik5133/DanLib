/***
 *   @addon         DanLib
 *   @component     Dashboard Page
 *   @license       MIT License
 *   @version       1.0.0
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
 


local DASHBOARD = DanLib.Func.CreatePage('dashboard')
DASHBOARD:SetName('Dashboard')
DASHBOARD:SetOrder(1)
DASHBOARD:SetIcon('fQgAszu')
DASHBOARD:SetID('dashboard')

function DASHBOARD:Create(container)
	local Dashboard = container:Add('DanLib.UI.Dashboard')
	Dashboard:Dock(FILL)
end


local PANEL = DanLib.UiPanel()

function PANEL:Init()
	self.ModelPanel = DanLib.CustomUtils.Create(self)
	self.ModelPanel:Pin(nil, 10)
	-- self.ModelPanel:ApplyBackground(Color(80, 80, 80), 6)

	local DModelPanel = DanLib.CustomUtils.Create(self.ModelPanel, 'DModelPanel'):Pin(nil, 20):ApplyAttenuation(0.5)
	DModelPanel:SetModel('models/weapons/w_physics.mdl')
	DModelPanel:SetAutoDelete(true)
	DModelPanel:SetMouseInputEnabled(false)
	DModelPanel:SetColor(Color(255, 255, 255, 5))
	DModelPanel:ApplyEvent('LayoutEntity', function(sl, w, h)
		sl.Entity:SetMaterial('models/wireframe')
		sl.Entity:SetAngles(Angle(0, 45 * CurTime(), 0))
		sl:SetFOV(30)
		sl:SetCamPos(Vector(50, 0, 0))
		sl:SetLookAt(Vector(0, 0, 0))
	end)
	DModelPanel:ApplyEvent('PaintOver', function(sl)
		DanLib.Utils:DrawBlur(sl, 1, 2)
	end)
end

PANEL:Register('DanLib.UI.Dashboard')
