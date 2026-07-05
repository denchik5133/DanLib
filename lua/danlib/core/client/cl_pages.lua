/***
 *   @addon         DanLib
 *   @component     UI Page
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
 


--- DanLib Pages class for creating, managing, and accessing UI pages
local page, page_builder = DanLib.UiClass.Create()

--- Initializes a new page instance
-- @param instance: The new page instance being created
-- @param name: The unique name of the page
function page.Init(instance, name)
	instance:SetName(name)
end

-- Accessors for page properties
page:Accessor('Order', page_builder.Number)
page:Accessor('Icon', page_builder.Icon)
page:Accessor('Name', page_builder.String)
page:Accessor('ID', page_builder.String)
page:Accessor('KeyboardInput', page_builder.Boolean, {
	default = false
})

-- Default function implementations for page events
page.OnClick = function() end
page.AccessСheck = function() end
page.Create = function() end

-- DanLib Pages management
DanLib.Pages = DanLib.Pages or { }
DanLib.Pages_Map = DanLib.Pages_Map or { }
DanLib.Pages_ID = DanLib.Pages_ID or { } -- lookup by string ID

--- Creates a new page instance or retrieves an existing one
-- @param name: The unique name of the page
-- @return: The page instance
function DanLib.Func.CreatePage(name)
	local instance = DanLib.Pages_Map[name]

	if (instance == nil) then
		instance = page:new({ }, name), page_builder
		instance.id = #DanLib.Pages + 1
		DanLib.Pages_Map[name] = instance
		DanLib.Pages[instance.id] = DanLib.Pages_Map[name]

		-- Wrap SetID to also register in the ID lookup table
		local _rawSetID = instance.SetID
		instance.SetID = function(self, id)
			-- Warn if another page already owns this ID
			local existing = DanLib.Pages_ID[id]
			if (existing and existing ~= self) then
				ErrorNoHalt('[DanLib] Page ID conflict: "' .. tostring(id) .. '" is already used by page "' .. tostring(existing:GetName()) .. '". The new page "' .. tostring(self:GetName()) .. '" will overwrite it. Use a unique ID (e.g. prefix with your addon name).\n')
			end
			_rawSetID(self, id)
			DanLib.Pages_ID[id] = self
			return self
		end
	else
		-- Instance already exists; re-sync Pages_ID so SetID calls
		-- on this instance never trigger a false conflict.
		local existingId = instance:GetID()
		if (existingId and DanLib.Pages_ID[existingId] ~= instance) then
			DanLib.Pages_ID[existingId] = instance
		end
	end

	return instance
end
