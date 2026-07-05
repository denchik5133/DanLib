/***
 *   @addon         DanLib
 *   @component     Hooks
 *   @license       MIT License
 *   @version       2.0.4
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   The file provides a comprehensive interface for managing event hooks,
 *                  allowing multiple scripts to modify game functions without conflicts.
 *
 *   @functions
 *                  - Adding a hook for a specific event (Add).
 *                  - Removing a hook for a specific event (Remove).
 *                  - Adding a one-shot hook that removes itself after first fire (Once).
 *                  - Safely executing a hook with error handling (Run).
 *                  - Calling a hook via hook.Call with error handling (Call).
 *                  - Retrieving a table of hooks for a specific event (GetTable).
 *                  - ProtectedRun is kept as a backward-compatible alias for Run.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



--- Shared hook library for DanLib.
DanLib.Hook = DanLib.Hook or { }
local DHook = DanLib.Hook

local _pcall = pcall
local _xpcall = xpcall
local _tostring = tostring
local _ErrorNoHalt = ErrorNoHalt
local _debug_traceback = debug.traceback

--- Adds a hook to be called upon the given event occurring.
-- This function registers a callback function for the specified event.
-- If a hook with the same identifier already exists it is replaced.
--
-- @param eventName (string): The name of the event to hook into.
-- @param hookIdentifier (string): A unique identifier for this hook.
-- @param func (function): The function to call when the event occurs.
-- @return (nil)
function DHook:Add(eventName, hookIdentifier, func)
    if (type(func) ~= 'function') then
        error('func must be a function', 2)
    end

    -- Remove any existing hook with the same identifier before adding.
    self:Remove(eventName, hookIdentifier)

    local success, err = _pcall(function()
        hook.Add(eventName, hookIdentifier, func)
    end)

    if (not success) then
        _ErrorNoHalt('Error occurred while adding hook "' .. hookIdentifier .. '" to event "' .. eventName .. '": ' .. err)
    end
end

--- Removes the hook with the supplied identifier from the given event.
-- This function unregisters a previously added callback for the specified event.
--
-- @param eventName (string): The name of the event to unhook from.
-- @param hookIdentifier (string): The unique identifier of the hook to remove.
-- @return (nil)
function DHook:Remove(eventName, hookIdentifier)
    local success, err = _pcall(function()
        hook.Remove(eventName, hookIdentifier)
    end)

    if (not success) then
        _ErrorNoHalt('Error occurred while removing hook "' .. hookIdentifier .. '" from event "' .. eventName .. '": ' .. err)
    end
end

--- Adds a one-shot hook that automatically removes itself after the first call.
-- Useful for "wait for this event exactly once" patterns such as first spawn,
-- post-entity init, or a single config reload.
--
-- @param eventName (string): The name of the event to hook into.
-- @param hookIdentifier (string): A unique identifier for this hook.
-- @param func (function): The function to call when the event fires.
-- @return (nil)
--
-- @example:
--      DanLib.Hook:Once('InitPostEntity', 'DanLib.FirstLoad', function()
--          print('Runs exactly once after the first InitPostEntity')
--      end)
function DHook:Once(eventName, hookIdentifier, func)
    if (type(func) ~= 'function') then
        error('func must be a function', 2)
    end

    self:Add(eventName, hookIdentifier, function(...)
        -- Unregister before calling so the callback itself can re-register
        -- the same hook without immediately being overwritten.
        self:Remove(eventName, hookIdentifier)
        return func(...)
    end)
end

--- Safely executes a hook with full error handling.
-- This function runs the specified hook via xpcall; if an error occurs it is
-- logged with a full traceback and nil is returned instead of propagating.
--
-- @param hookName (string): The name of the hook to run.
-- @param ... (vararg): Additional arguments to pass to the hook.
-- @return (vararg|nil): Returns the results of the hook if successful, or nil if an error occurred.
function DHook:Run(hookName, ...)
    local success, result1, result2, result3, result4, result5, result6, result7, result8 = _xpcall(hook.Run, function(err)
        _ErrorNoHalt(_debug_traceback(err))
    end, hookName, ...)

    if (not success) then
        return nil
    end

    return result1, result2, result3, result4, result5, result6, result7, result8
end

--- Backward-compatible alias for DHook:Run.
-- @deprecated Use DHook:Run instead.
DHook.ProtectedRun = DHook.Run

--- Calls a hook and returns the first non-nil result from any listener.
-- This function runs hook.Call which stops at the first handler that returns a value.
-- If an error occurs it is logged with a traceback and nil is returned.
--
-- @param hookName (string): The name of the hook to call.
-- @param ... (vararg): Additional arguments to pass to the hook.
-- @return (vararg|nil): Returns the results of the hook if successful, or nil if an error occurred.
function DHook:Call(hookName, ...)
    local success, result1, result2, result3, result4, result5, result6, result7, result8 = _xpcall(hook.Call, function(err)
        _ErrorNoHalt(_debug_traceback(err))
    end, hookName, ...)

    if (not success) then
        return nil
    end

    return result1, result2, result3, result4, result5, result6, result7, result8
end

--- Retrieves a table of hooks for a specific event.
-- This function returns all hooks associated with the given event name.
--
-- @param eventName (string): The name of the event to get hooks for.
-- @return (table|nil): A table containing all hooks for the specified event, or nil if an error occurred.
function DHook:GetTable(eventName)
    local success, hooksTable = _pcall(function()
        return hook.GetTable()[eventName] or { }
    end)

    if (not success) then
        _ErrorNoHalt("Error retrieving hooks for event '" .. _tostring(eventName) .. "': " .. hooksTable)
        return nil
    end

    return hooksTable
end
