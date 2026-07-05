/***
 *   @addon         DanLib
 *   @component     ConCommand
 *   @license       MIT License
 *   @version       1.0.0
 *   @release_date  16/05/2026
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   ConCommand utility for DanLib. Wraps GMod's concommand.* functions
 *                  with consistent argument validation and error handling.
 *                  Usable both inside DanLib and from any external addon.
 *
 *   @functions
 *                  - Add: Register a named console command with callback and optional autocomplete.
 *                  - Remove: Remove a previously registered console command.
 *                  - Exists: Check whether a console command is registered.
 *                  - Run: Execute a console command as a given player.
 *                  - GetTable: Return the full table of all registered console commands.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



DanLib.Concommand = DanLib.Concommand or { }
local DConcommand = DanLib.Concommand

local _assert = assert
local _type = type
local _ErrorNoHalt = ErrorNoHalt

--- Registers a console command.
-- If a command with the same name is already registered it is replaced.
-- @param name (string): The command name. Must be a non-empty string.
-- @param callback (function): Called when the command is executed.
--   Signature: function(pPlayer, cmd, args, argStr)
--     pPlayer (Player) — the player who ran the command; NULL entity on SERVER console.
--     cmd (string) — the command name as typed.
--     args (table) — sequential table of whitespace-separated arguments.
--     argStr (string) — the raw argument string exactly as typed.
-- @param autocomplete (function|nil): Called when the player presses Tab on the command.
--   Signature: function(cmd, argStr) → table of completion strings.
--   Pass nil to disable autocomplete.
-- @param helpText (string|nil): Short description shown in `help` and `find` output.
-- @param flags (number|nil): Bitfield of FCVAR_* flags. Defaults to FCVAR_NONE (0).
-- @return (nil)
function DConcommand:Add(name, callback, autocomplete, helpText, flags)
    _assert(_type(name) == 'string' and #name > 0, 'DConcommand:Add — name must be a non-empty string')
    _assert(_type(callback) == 'function', 'DConcommand:Add — callback must be a function')
    _assert(autocomplete == nil or _type(autocomplete) == 'function', 'DConcommand:Add — autocomplete must be a function or nil')
    _assert(helpText == nil or _type(helpText) == 'string', 'DConcommand:Add — helpText must be a string or nil')
    _assert(flags == nil or _type(flags) == 'number', 'DConcommand:Add — flags must be a number or nil')
    concommand.Add(name, callback, autocomplete, helpText or '', flags or 0)
end

--- Removes a previously registered console command.
-- Does nothing if the command is not registered.
-- @param name (string): The command name to remove.
-- @return (nil)
function DConcommand:Remove(name)
    _assert(_type(name) == 'string' and #name > 0, 'DConcommand:Remove — name must be a non-empty string')
    concommand.Remove(name)
end

--- Returns whether a console command with the given name is currently registered.
-- @param name (string): The command name to check.
-- @return (boolean): true if registered, false otherwise.
function DConcommand:Exists(name)
    _assert(_type(name) == 'string' and #name > 0, 'DConcommand:Exists — name must be a non-empty string')
    return concommand.GetTable()[name] ~= nil
end

--- Executes a registered console command as the given player.
-- @param pPlayer (Player): The player to run the command as. Pass NULL for the server console.
-- @param name (string): The command name to execute.
-- @param args (table|nil): Sequential table of argument strings. Defaults to { }.
-- @param argStr (string|nil): Raw argument string. Defaults to ''.
-- @return (nil)
function DConcommand:Run(pPlayer, name, args, argStr)
    _assert(_type(name) == 'string' and #name > 0, 'DConcommand:Run — name must be a non-empty string')
    _assert(args == nil or _type(args) == 'table', 'DConcommand:Run — args must be a table or nil')
    _assert(argStr == nil or _type(argStr) == 'string', 'DConcommand:Run — argStr must be a string or nil')

    if (not self:Exists(name)) then
        _ErrorNoHalt('DConcommand:Run — command "' .. name .. '" is not registered\n')
        return
    end

    concommand.Run(pPlayer, name, args or { }, argStr or '')
end

--- Returns the full table of all currently registered console commands.
-- Keys are command name strings; values are the command descriptor tables.
-- @return (table)
function DConcommand:GetTable()
    return concommand.GetTable()
end
