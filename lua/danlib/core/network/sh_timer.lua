/***
 *   @addon         DanLib
 *   @component     Timer
 *   @license       MIT License
 *   @version       1.0.0
 *   @release_date  21/06/2026
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Timer utility for DanLib. Wraps all GMod timer.* functions with
 *                  consistent argument validation and error handling.
 *                  Usable both inside DanLib and from any external addon.
 *
 *   @functions
 *                  - Create: Create a named repeating or one-shot timer.
 *                  - Simple: Create an anonymous one-shot timer.
 *                  - Remove: Remove a named timer.
 *                  - Exists: Check whether a named timer exists.
 *                  - Adjust: Adjust delay, repetitions or callback of a timer.
 *                  - Pause: Pause a named timer.
 *                  - UnPause: Resume a paused timer.
 *                  - Toggle: Toggle pause/resume state of a timer.
 *                  - Start: Start or restart a named timer.
 *                  - Stop: Stop a timer (resets it without removing).
 *                  - RepsLeft: Get the number of repetitions remaining.
 *                  - TimeLeft: Get the time remaining until the next fire.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



DanLib.Timer = DanLib.Timer or { }
local DTimer = DanLib.Timer

local _assert = assert
local _type = type
local _ErrorNoHalt = ErrorNoHalt

--- Creates a named timer that fires repeatedly or a set number of times.
-- If a timer with the same name already exists it is replaced.
-- @param name (string): Unique identifier for this timer.
-- @param delay (number): Interval in seconds between each fire.
-- @param reps (number): Number of times to fire. 0 = repeat indefinitely.
-- @param func (function): The function to call on each fire.
-- @return (nil)
function DTimer:Create(name, delay, reps, func)
    _assert(_type(name) == 'string', 'DTimer:Create — name must be a string')
    _assert(_type(delay) == 'number' and delay >= 0, 'DTimer:Create — delay must be a non-negative number')
    _assert(_type(reps) == 'number' and reps >= 0, 'DTimer:Create — reps must be a non-negative number')
    _assert(_type(func) == 'function', 'DTimer:Create — func must be a function')
    timer.Create(name, delay, reps, func)
end

--- Creates an anonymous one-shot timer that fires once after the given delay.
-- The timer cannot be paused, removed, or referenced by name.
-- Passing nil or 0 as delay executes the function on the next game tick.
-- @param delay (number|nil): Delay in seconds, 0, or nil for next-tick execution.
-- @param func (function): The function to call after the delay.
-- @return (nil)
function DTimer:Simple(delay, func)
    _assert(delay == nil or (_type(delay) == 'number' and delay >= 0), 'DTimer:Simple — delay must be a non-negative number or nil')
    _assert(_type(func) == 'function', 'DTimer:Simple — func must be a function')
    timer.Simple(delay or 0, func)
end

--- Removes a named timer, stopping it permanently.
-- @param name (string): The name of the timer to remove.
-- @return (nil)
function DTimer:Remove(name)
    _assert(_type(name) == 'string', 'DTimer:Remove — name must be a string')
    timer.Remove(name)
end

--- Checks whether a named timer currently exists.
-- @param name (string): The name of the timer to check.
-- @return (boolean): true if the timer exists, false otherwise.
function DTimer:Exists(name)
    _assert(_type(name) == 'string', 'DTimer:Exists — name must be a string')
    return timer.Exists(name)
end

--- Adjusts the delay, repetitions, and/or callback of an existing timer.
-- Only the fields provided (non-nil) are changed; omit a field to keep its current value.
-- @param name (string): The name of the timer to adjust.
-- @param delay (number|nil): New interval in seconds. Pass nil to keep the current value.
-- @param reps (number|nil): New repetition count. Pass nil to keep the current value.
-- @param func (function|nil): New callback. Pass nil to keep the current callback.
-- @return (boolean): true if the timer was found and adjusted, false if it does not exist.
function DTimer:Adjust(name, delay, reps, func)
    _assert(_type(name) == 'string', 'DTimer:Adjust — name must be a string')

    if (not timer.Exists(name)) then
        _ErrorNoHalt('DTimer:Adjust — timer "' .. name .. '" does not exist\n')
        return false
    end

    timer.Adjust(name, delay, reps, func)
    return true
end

--- Pauses a named timer, freezing its countdown.
-- Use UnPause or Toggle to resume it.
-- @param name (string): The name of the timer to pause.
-- @return (boolean): true if the timer was paused, false if it does not exist.
function DTimer:Pause(name)
    _assert(_type(name) == 'string', 'DTimer:Pause — name must be a string')

    if (not timer.Exists(name)) then
        _ErrorNoHalt('DTimer:Pause — timer "' .. name .. '" does not exist\n')
        return false
    end

    timer.Pause(name)
    return true
end

--- Resumes a paused timer, continuing from where it was frozen.
-- @param name (string): The name of the timer to resume.
-- @return (boolean): true if the timer was resumed, false if it does not exist.
function DTimer:UnPause(name)
    _assert(_type(name) == 'string', 'DTimer:UnPause — name must be a string')

    if (not timer.Exists(name)) then
        _ErrorNoHalt('DTimer:UnPause — timer "' .. name .. '" does not exist\n')
        return false
    end

    timer.UnPause(name)
    return true
end

--- Toggles the pause/resume state of a named timer.
-- @param name (string): The name of the timer to toggle.
-- @return (boolean): true if the timer was toggled, false if it does not exist.
function DTimer:Toggle(name)
    _assert(_type(name) == 'string', 'DTimer:Toggle — name must be a string')

    if (not timer.Exists(name)) then
        _ErrorNoHalt('DTimer:Toggle — timer "' .. name .. '" does not exist\n')
        return false
    end

    timer.Toggle(name)
    return true
end

--- Starts or restarts a named timer from the beginning of its interval.
-- @param name (string): The name of the timer to start.
-- @return (boolean): true if the timer was started, false if it does not exist.
function DTimer:Start(name)
    _assert(_type(name) == 'string', 'DTimer:Start — name must be a string')

    if (not timer.Exists(name)) then
        _ErrorNoHalt('DTimer:Start — timer "' .. name .. '" does not exist\n')
        return false
    end

    timer.Start(name)
    return true
end

--- Stops a named timer, resetting its countdown without removing it.
-- The timer can be restarted with Start.
-- @param name (string): The name of the timer to stop.
-- @return (boolean): true if the timer was stopped, false if it does not exist.
function DTimer:Stop(name)
    _assert(_type(name) == 'string', 'DTimer:Stop — name must be a string')

    if (not timer.Exists(name)) then
        _ErrorNoHalt('DTimer:Stop — timer "' .. name .. '" does not exist\n')
        return false
    end

    timer.Stop(name)
    return true
end

--- Returns the number of repetitions remaining for a named timer.
-- @param name (string): The name of the timer to query.
-- @return (number|nil): Repetitions left, or nil if the timer does not exist.
function DTimer:RepsLeft(name)
    _assert(_type(name) == 'string', 'DTimer:RepsLeft — name must be a string')

    if (not timer.Exists(name)) then
        return nil
    end

    return timer.RepsLeft(name)
end

--- Returns the time in seconds until the next fire of a named timer.
-- @param name (string): The name of the timer to query.
-- @return (number|nil): Seconds until next fire, or nil if the timer does not exist.
function DTimer:TimeLeft(name)
    _assert(_type(name) == 'string', 'DTimer:TimeLeft — name must be a string')

    if (not timer.Exists(name)) then
        return nil
    end

    return timer.TimeLeft(name)
end
