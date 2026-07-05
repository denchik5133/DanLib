/***
 *   @addon         DanLib
 *   @component     Print
 *   @license       MIT License
 *   @version       1.0.8
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   This module is designed to enhance the logging and debugging capabilities of the DanLib framework,
 *                  making it easier for developers to track messages and errors during development and runtime.
 *
 *   @components
 *                  - DanLib.Utils.Print: A function that prints a message to the console with a specific format,
 *                    including a prefix indicating the source of the message.
 *                  - DanLib.Utils.PrintType: A function that prints a message with a specified type label (e.g., 
 *                    'Info', 'Warning'), allowing for better categorization of log messages.
 *                  - DanLib.Utils.Error: A function that prints an error message in red and halts execution 
 *                    without terminating the script, providing a clear indication of issues.
 *
 *   @example
 *                  -- To print a standard message:
 *                  DanLib.Func:Print('This is a standard message.')
 *              
 *                  -- To print a message with a type:
 *                  DanLib.Func:PrintType('Warning', 'This is a warning message.')
 *              
 *                  -- To print an error message:
 *                  DanLib.Func:PrintError('This is an error message.')
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DTable = DanLib.Table
local DFileUtil = DanLib.FileUtil

local _MsgC = MsgC
local _type = type
local _Color = Color
local _ipairs = ipairs
local _tostring = tostring

local colorBlue = _Color(30, 144, 255)
local colorError = _Color(255, 0, 0)
local prefix = 'DanLib'
local logDir = 'danlib/logs/' -- Log directory

-- Get the current date and time in the format "YYYYY-MM-DD HH:MM:SS"
local function getCurrentTime()
    return os.date('%Y-%m-%d %H:%M:%S')
end

-- Check and create a directory for logs if it does not exist
local function ensureLogDirectoryExists()
    if (not DFileUtil:Exists(logDir, 'DATA')) then
        DFileUtil:CreateDir(logDir)
    end
end

-- Logging to a file with dynamic filename
local function logToFile(message, logType)
    ensureLogDirectoryExists() -- Let's make sure the directory exists

    local filename = logDir .. 'log.txt' -- Default main log file

    if (logType == 'Error') then
        filename = logDir .. 'error_log.txt' -- Log file for errors
    end

    DFileUtil:Append(filename, message .. '\n') -- Use file.Append to append to the file
end

--- Prints a message to the console with a specific format.
-- @param ... any: The message content to print. Can accept multiple arguments.
function DBase:Print(message)
    _MsgC(colorBlue, '[', color_white, prefix, colorBlue, '] ', color_white, message .. '\n')
end

--- Prints a message to the console with a specific type label.
-- @param logType string: The type label to include in the message (e.g., 'Info', 'Warning').
-- @param ... any: The message content to print. Accepts strings, numbers, and Color objects.
function DBase:PrintType(logType, ...)
    -- Pass varargs directly to MsgC so Color objects work for coloured output
    _MsgC(colorBlue, _Color(255, 215, 0), '[', color_white, logType, _Color(255, 215, 0), '] ', color_white, ...)
    _MsgC('\n')

    -- Write to file only for 'Logs' / 'SQL' types; skip Color objects
    if (logType == 'Logs' or logType == 'SQL') then
        local parts = {}
        for _, v in _ipairs({ ... }) do
            local t = _type(v)
            if (t == 'string' or t == 'number') then
                parts[#parts + 1] = _tostring(v)
            end
            -- Color objects and other tables are silently skipped in file output
        end
        logToFile(getCurrentTime() .. ' - ' .. logType .. ': ' .. DTable:Concat(parts))
    end
end

--- Prints an error message to the console with a specific format.
-- @param message string: The error message to print.
function DBase:PrintError(message)
    if (_type(message) ~= 'string') then
        message = 'Unknown error'
    end
    _MsgC(colorBlue, '[', color_white, prefix, colorBlue, ']', colorError, '[ ', color_white, 'Error', colorError, ' ] ', color_white, message .. '\n')
    logToFile(getCurrentTime() .. ' - Error: ' .. message, 'Error')
end
