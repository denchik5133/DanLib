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


/***
 *   sh_hooks.lua
 *   This file is responsible for managing hooks in the DanLib project.
 *
 *   It includes the following functions:
 *   - Adding a hook for a specific event (Add).
 *   - Removing a hook for a specific event (Remove).
 *   - Safely executing a hook with error handling (ProtectedRun).
 *   - Retrieving a table of hooks for a specific event (GetTable).
 *
 *   The file provides a comprehensive interface for managing event hooks,
 *   allowing multiple scripts to modify game functions without conflicts.
 */



--- Shared online library for DanLib
DanLib.Hook = DanLib.Hook or {}
local DHook = DanLib.Hook

local _pcall = pcall
local _xpcall = xpcall
local _tostring = tostring
local _ErrorNoHalt = ErrorNoHalt
local _debug_traceback = debug.traceback

--- Adds a hook to be called upon the given event occurring.
-- @param eventName The name of the event to hook into.
-- @param hookIdentifier A unique identifier for this hook.
-- @param func The function to call when the event occurs.
function DHook:Add(eventName, hookIdentifier, func)
    if (type(func) ~= 'function') then
        error('func must be a function', 2)
    end

    -- Remove any existing hook with the same identifier
    self:Remove(eventName, hookIdentifier) 

    local success, err = _pcall(function()
        hook.Add(eventName, hookIdentifier, func)
    end)

    if (not success) then
        _ErrorNoHalt('Error occurred while removing hook "' .. hookIdentifier .. '" from event "' .. eventName .. '": ' .. err)
    end
end

--- Removes the hook with the supplied identifier from the given event.
-- @param eventName The name of the event to unhook from.
-- @param hookIdentifier The unique identifier of the hook to remove.
function DHook:Remove(eventName, hookIdentifier)
    local success, err = _pcall(function()
        hook.Remove(eventName, hookIdentifier)
    end)

    if (not success) then
        _ErrorNoHalt('Error occurred while removing hook "' .. hookIdentifier .. '" from event "' .. eventName .. '": ' .. err)
    end
end

--- Safely executes a hook with error handling.
-- This function attempts to run a specified hook and captures any errors that may occur.
-- If an error occurs, it logs the error without breaking the addon.
-- 
-- @param hookName (string) The name of the hook to run.
-- @param ... (vararg) Additional arguments to pass to the hook.
-- @return (vararg|nil) Returns the results of the hook if successful, or nil if an error occurred.
-- 
-- Example usage:
--      local result = DanLib.Hook:ProtectedRun('MyHookName', arg1, arg2)
--      if result then
--          -- Process result
--      end
function DHook:ProtectedRun(hookName, ...)
    -- Attempt to run the hook and capture any errors
    local success, result1, result2, result3, result4, result5, result6 = _xpcall(hook.Run, function(err)
        -- Log the error with a traceback for debugging
        _ErrorNoHalt(_debug_traceback(err))
    end, hookName, ...)

    -- If the hook execution was unsuccessful, return nil
    if (not success) then
        return nil
    end
    
    -- Return the results of the hook execution
    return result1, result2, result3, result4, result5, result6
end

--- Calls a hook directly and returns its results.
-- This function allows you to call a specific hook by its name and pass arguments to it.
-- 
-- @param hookName (string) The name of the hook to call.
-- @param ... (vararg) Additional arguments to pass to the hook.
-- @return (vararg|nil) Returns the results of the hook if successful, or nil if an error occurred.
function DHook:Call(hookName, ...)
    local success, result1, result2, result3, result4, result5, result6 = _xpcall(hook.Call, function(err)
        -- Log the error with a traceback for debugging
        _ErrorNoHalt(_debug_traceback(err))
    end, hookName, ...)

    -- If the hook execution was unsuccessful, return nil
    if (not success) then
        return nil
    end
    
    -- Return the results of the hook execution
    return result1, result2, result3, result4, result5, result6
end

--- Retrieves a table of hooks for a specific event.
-- This function returns all hooks associated with the given event name.
-- 
-- @param eventName (string) The name of the event to get hooks for.
-- @return (table|nil) A table containing all hooks for the specified event, or nil if an error occurred.
function DHook:GetTable(eventName)
    local success, hooksTable = _pcall(function()
        return hook.GetTable()[eventName] or {}
    end)

    if (not success) then
        _ErrorNoHalt("Error retrieving hooks for event '" .. _tostring(eventName) .. "': " .. hooksTable)
        return nil
    end

    -- Return the hooks table if successful
    return hooksTable
end
