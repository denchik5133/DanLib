/***
 *   @addon         DanLib
 *   @component     UI HUD
 *   @license       MIT License
 *   @version       1.0.1
 *   @release_date  16/03/2025
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



local DHook = DanLib.Hook

local _pairs = pairs
local _ipairs = ipairs
local _IsValid = IsValid

--- DanLib HUD class for creating, managing, and accessing HUD elements
local hudElement, hudBuilder = DanLib.UiClass.Create()

--- Initializes a new HUD instance
-- @param instance: The new HUD instance being created
-- @param name: The unique name of the HUD element
function hudElement.Init(instance, name)
    -- instance:SetName(name)
end

-- Default function implementations for HUD events
hudElement.AccessСheck = function() end
hudElement.Create = function() end

-- DanLib HUD management
DanLib.HUD = DanLib.HUD or { }
DanLib.HUD_Map = DanLib.HUD_Map or { }

--- Creates a new HUD instance or retrieves an existing one
-- @param name: The unique name of the HUD element
-- @return: The HUD instance
function DanLib.Func.CreateHUD(name)
    local instance = DanLib.HUD_Map[name]
    if (instance == nil) then
        instance = hudElement:new({ }, name)
        instance.id = #DanLib.HUD + 1
        DanLib.HUD_Map[name] = instance
        DanLib.HUD[instance.id] = DanLib.HUD_Map[name]

        -- Initializing the HUD element
        instance:Init(instance, name) -- Calling the Init function to initialize
    end

    return instance
end


local ui = DanLib.UI
if ui:valid(DANLIB_MAINHUD) then
    DANLIB_MAINHUD:Remove()
end

local function create_derma_hud(pPlayer)
	if ui:valid(DANLIB_MAINHUD) then
        DANLIB_MAINHUD:Remove()
    end

	local container = DanLib.CustomUtils.Create()
	DANLIB_MAINHUD = container
    -- container:ParentToHUD()
    container:SetSize(ui:ScrW(), ui:ScrH())
    -- container:ApplyBackground(Color(20, 20, 20, 100))

    container:ApplyEvent('Think', function(sl, w, h)
        local shouldDraw = DHook:Run('HUDShouldDraw', 'CHudGMod')
        if (not shouldDraw) then
            sl:Remove()
        end
    end)

    -- Populate pages
    local hud_elements = { }
    for _, v in _pairs(DanLib.HUD) do
        hud_elements[#hud_elements + 1] = v
    end

    container:ApplyEvent('Refresh', function(sl, w, h)
        for i, hud in _ipairs(hud_elements) do
        	if (hud.AccessСheck and hud:AccessСheck(pPlayer) == false) then
                continue
            end

        	if hud.Create then
                local content = hud:Create(container)
                if (not _IsValid(content)) then
                    continue
                end
            end
        end
    end)
    container:Refresh()

    -- Register the configuration update hook inside create_derma_hud
    DHook:Add('DanLib:HooksConfigUpdated', 'HooksConfigUpdated_' .. tostring(container), function()
        -- if ui:valid(DANLIB_MAINHUD) then DANLIB_MAINHUD:Remove() end
        DANLIB_MAINHUD:Refresh()
    end)
end

DHook:Add('HUDPaint', 'DanLib.MainHUD', function()
    local pPlayer = LocalPlayer()
    if (not ui:valid(DANLIB_MAINHUD)) then
        create_derma_hud(pPlayer)
    end
end)