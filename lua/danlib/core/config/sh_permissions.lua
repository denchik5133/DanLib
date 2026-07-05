/***
 *   @addon         DanLib
 *   @component     Table
 *   @license       MIT License
 *   @version       2.4.0
 *   @release_date  01/12/2024
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Permission management system with automatic rank assignment
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



--- Module for managing access rights in DanLib.
DanLib.Permissions = DanLib.Permissions or { }
local DPermissions = DanLib.Permissions
DPermissions.list = DPermissions.list or { }
DanLib.BaseConfig.Permissions = DanLib.BaseConfig.Permissions or { }

--- Registers a new permission with optional auto-assignment to specific ranks
-- @param name (string): The unique permission key (e.g., 'EditSettings')
-- @param description (string): Description of the permission
-- @param autoAssignRanks (string|table|boolean|nil): 
--   - string: Single rank ID to auto-assign (e.g., 'rank_owner')
--   - table: Multiple rank IDs to auto-assign (e.g., {'rank_owner', 'rank_staff'})
--   - boolean: true = auto-assign to all new ranks, false = no auto-assign
--   - nil: no auto-assign (default behavior)
-- @param minAccess (string): Minimum access level (DEPRECATED, kept for compatibility)
-- @usage 
--   DanLib.Permissions:Register('EditSettings', 'Permission to edit config', 'rank_owner')
--   DanLib.Permissions:Register('ViewHelp', 'View help pages', {'rank_owner', 'rank_staff', 'rank_member'})
--   DanLib.Permissions:Register('AdminPages', 'View admin pages', true)
function DanLib.Permissions:Register(name, description, autoAssignRanks, minAccess)
    if (not name) then
        error('No name specified for permission')
    end
    local assignRanks = nil
    local assignToAll = false
    
    if (type(autoAssignRanks) == 'string') then
        assignRanks = { autoAssignRanks }
    elseif (type(autoAssignRanks) == 'table') then
        assignRanks = autoAssignRanks
    elseif (autoAssignRanks == true) then
        assignToAll = true
    end
    
    local permissionData = {
        Name = name,
        Description = description or 'This permission has no description',
        AutoAssignRanks = assignRanks,
        AutoAssignAll = assignToAll,
        MinAccess = minAccess or 'admin'
    }
    DPermissions.list[name] = permissionData
    DanLib.BaseConfig.Permissions[name] = permissionData
    
    if (minAccess and SERVER) then
        DanLib.Func:Print('WARNING: MinAccess parameter is DEPRECATED in DanLib.Permissions:Register("' .. name .. '").')
    end
end

--- Checks if the player has permission.
-- @param pPlayer (Player): The player for whom the permission is being checked.
-- @param name (string): The name of the permission.
-- @return boolean: true if the player has permission, otherwise false.
function DPermissions:Check(pPlayer, name)
    if (not pPlayer:IsPlayer()) then
        return false
    end
    return DanLib.Func.HasPermission(pPlayer, name)
end

--- Gets the permission by name.
-- @param name (string): Permission name.
-- @return table: Table with permission data or nil if no permission is found.
function DPermissions:Get(name)
    return self.list[name]
end

--- Gets all the permissions.
-- @return table: Table with all permissions.
function DPermissions:GetAll()
    return self.list
end

--- Gets permission description (supports old and new format)
-- @param name (string): Permission name
-- @return string: Description of the permission
function DPermissions:GetDescription(name)
    local perm = DanLib.BaseConfig.Permissions[name]
    if (not perm) then
        return 'Unknown permission'
    end
    
    -- Новый format (table)
    if (type(perm) == 'table') then
        return perm.Description or 'No description'
    end
    
    -- Old format (string)
    return perm
end

-- Registers
DPermissions:Register('EditSettings', 'Permission to edit the configuration.', 'rank_owner')
DPermissions:Register('EditRanks', 'Permission to edit ranks.', 'rank_owner')
DPermissions:Register('AdminPages', 'Permission to view pages for administrators.', { 'rank_owner', 'rank_staff' })
DPermissions:Register('ViewHelp', 'Permissions to view the page and other help items.', true) -- All ranks
DPermissions:Register('Tutorial', 'Permission to view the textbook.', { 'rank_owner', 'rank_staff' })