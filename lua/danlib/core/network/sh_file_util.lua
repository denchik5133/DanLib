/***
 *   @addon         DanLib
 *   @component     File util
 *   @license       MIT License
 *   @version       2.0.0
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Universal file system utility for DanLib. Wraps GMod's file.*
 *                  functions with consistent argument validation, error handling,
 *                  and an optional pathID argument (defaults to 'DATA') so callers
 *                  can target any GMod search path.
 *
 *   @functions
 *                  - Exists: Check whether a path exists (file or directory).
 *                  - IsDir: Check whether a path is specifically a directory.
 *                  - CreateDir: Create a directory tree if it does not yet exist.
 *                  - Delete: Delete a file from the DATA path.
 *                  - Find: Search for files matching a pattern in a path.
 *                  - Read: Read the entire contents of a file as a string.
 *                  - Write: Write (overwrite) a string to a file.
 *                  - Append: Append a string to an existing file.
 *                  - Size: Return the size of a file in bytes.
 *                  - Time: Return the last-modified timestamp of a file.
 *                  - Open: Open a file handle for low-level read/write.
 *                  - ReadJSON: Read a JSON file and deserialize it into a Lua table.
 *                  - WriteJSON: Serialize a Lua table to JSON and write it to a file.
 *                  - ReadJSONOrDefault: Read a JSON file, returning a default table if absent or invalid.
 *                  - UpdateJSON: Read, mutate via a callback, and write a JSON file atomically.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



DanLib.FileUtil = DanLib.FileUtil or { }
local DFileUtil = DanLib.FileUtil

local _assert = assert
local _type = type

--- Checks whether a file or directory exists at the given path.
-- @param path (string): The path to check.
-- @param pathID (string): GMod search path, e.g. 'DATA', 'GAME', 'LUA'. Defaults to 'DATA'.
-- @return (boolean): true if the path exists, false otherwise.
function DFileUtil:Exists(path, pathID)
    _assert(_type(path) == 'string', 'DFileUtil.Exists: path must be a string')
    return file.Exists(path, pathID or 'DATA')
end

--- Checks whether the given path is a directory (not a file).
-- @param path (string): The path to check.
-- @param pathID (string): GMod search path. Defaults to 'DATA'.
-- @return (boolean): true if the path is an existing directory, false otherwise.
function DFileUtil:IsDir(path, pathID)
    _assert(_type(path) == 'string', 'DFileUtil.IsDir: path must be a string')
    return file.IsDir(path, pathID or 'DATA')
end

--- Creates a directory (and any missing parent directories) in the DATA path.
-- Does nothing if the directory already exists.
-- @param dir (string): The directory path to create.
-- @return (boolean): true if the directory was created, false if it already existed.
function DFileUtil:CreateDir(dir)
    _assert(_type(dir) == 'string', 'DFileUtil.CreateDir: dir must be a string')

    if (self:IsDir(dir, 'DATA')) then
        return false
    end

    local current = ''
    for segment in dir:gmatch('[^/]+') do
        current = current == '' and segment or (current .. '/' .. segment)
        if (not self:IsDir(current, 'DATA')) then
            file.CreateDir(current)
        end
    end

    return true
end

--- Deletes a file from the DATA path.
-- Directories cannot be deleted with this function.
-- @param path (string): The path to the file to delete.
-- @return (boolean): true if the file was deleted, false if it did not exist.
function DFileUtil:Delete(path)
    _assert(_type(path) == 'string', 'DFileUtil.Delete: path must be a string')

    if (not self:Exists(path, 'DATA')) then
        return false
    end

    file.Delete(path)
    return true
end

--- Searches for files and directories matching a pattern.
-- Returns two tables: files first, then directories.
-- @param pattern (string): The search pattern, e.g. 'danlib/*.json'.
-- @param pathID (string): GMod search path. Defaults to 'DATA'.
-- @return (table): A list of matching file names.
-- @return (table): A list of matching directory names.
function DFileUtil:Find(pattern, pathID)
    _assert(_type(pattern) == 'string', 'DFileUtil.Find: pattern must be a string')
    return file.Find(pattern, pathID or 'DATA')
end

--- Reads the entire contents of a file as a string.
-- @param filename (string): Path to the file.
-- @param pathID (string): GMod search path. Defaults to 'DATA'.
-- @return (string|nil): The file contents, or nil if the file was not found.
-- @return (string|nil): An error message if the file could not be read.
function DFileUtil:Read(filename, pathID)
    _assert(_type(filename) == 'string', 'DFileUtil.Read: filename must be a string')

    local content, err = file.Read(filename, pathID or 'DATA')
    if (not content) then
        return nil, err or 'file not found'
    end

    return content
end

--- Writes (overwrites) a string to a file in the DATA path.
-- The file is created if it does not exist.
-- @param filename (string): Path to the file.
-- @param data (string): The data to write.
-- @return (boolean): true if the write succeeded.
-- @return (boolean, string): false and an error message if the write failed.
function DFileUtil:Write(filename, data)
    _assert(_type(filename) == 'string', 'DFileUtil.Write: filename must be a string')
    _assert(_type(data) == 'string', 'DFileUtil.Write: data must be a string')

    file.Write(filename, data)

    if (not self:Exists(filename, 'DATA')) then
        return false, 'write failed: file does not exist after write'
    end

    return true
end

--- Appends a string to an existing file in the DATA path.
-- Creates the file if it does not yet exist.
-- @param filename (string): Path to the file.
-- @param data (string): The data to append.
-- @return (boolean): true if the append succeeded.
-- @return (boolean, string): false and an error message if the append failed.
function DFileUtil:Append(filename, data)
    _assert(_type(filename) == 'string', 'DFileUtil.Append: filename must be a string')
    _assert(_type(data) == 'string', 'DFileUtil.Append: data must be a string')

    file.Append(filename, data)

    if (not self:Exists(filename, 'DATA')) then
        return false, 'append failed: file does not exist after append'
    end

    return true
end

--- Returns the size of a file in bytes.
-- @param filename (string): Path to the file.
-- @param pathID (string): GMod search path. Defaults to 'DATA'.
-- @return (number|nil): The file size in bytes, or nil if the file does not exist.
function DFileUtil:Size(filename, pathID)
    _assert(_type(filename) == 'string', 'DFileUtil.Size: filename must be a string')

    if (not self:Exists(filename, pathID or 'DATA')) then
        return nil
    end

    return file.Size(filename, pathID or 'DATA')
end

--- Returns the last-modified timestamp of a file as a Unix timestamp.
-- @param filename (string): Path to the file.
-- @param pathID (string): GMod search path. Defaults to 'DATA'.
-- @return (number|nil): Unix timestamp of last modification, or nil if the file does not exist.
function DFileUtil:Time(filename, pathID)
    _assert(_type(filename) == 'string', 'DFileUtil.Time: filename must be a string')

    if (not self:Exists(filename, pathID or 'DATA')) then
        return nil
    end

    return file.Time(filename, pathID or 'DATA')
end

--- Opens a file handle for low-level reading or writing.
-- Remember to call :Close() on the returned handle when done.
-- @param filename (string): Path to the file.
-- @param mode (string): Open mode: 'r' (read), 'w' (write), 'a' (append), 'rb', 'wb'.
-- @param pathID (string): GMod search path. Defaults to 'DATA'.
-- @return (file_handle|nil): A GMod file handle, or nil if the file could not be opened.
function DFileUtil:Open(filename, mode, pathID)
    _assert(_type(filename) == 'string', 'DFileUtil.Open: filename must be a string')
    _assert(_type(mode) == 'string', 'DFileUtil.Open: mode must be a string')

    return file.Open(filename, mode, pathID or 'DATA')
end

--- Reads a JSON file and deserializes its contents into a Lua table.
-- Calls self:Read to load the raw string, then util.JSONToTable to parse it.
-- Returns nil (plus an error message) if the file does not exist, cannot be read,
-- or contains invalid JSON.
-- @param filename (string): Path to the JSON file.
-- @param pathID (string): GMod search path. Defaults to 'DATA'.
-- @return (table|nil): The deserialized Lua table, or nil on failure.
-- @return (string|nil): An error message if the operation failed.
function DFileUtil:ReadJSON(filename, pathID)
    _assert(_type(filename) == 'string', 'DFileUtil.ReadJSON: filename must be a string')

    local content, err = self:Read(filename, pathID)
    if (not content) then
        return nil, err
    end

    local tbl = util.JSONToTable(content)
    if (not tbl) then
        return nil, 'DFileUtil.ReadJSON: failed to parse JSON in ' .. filename
    end

    return tbl
end

--- Serializes a Lua table to JSON and writes it to a file in the DATA path.
-- Automatically creates any missing parent directories before writing.
-- Calls util.TableToJSON to serialize the table, then self:Write to persist it.
-- The file is created if it does not exist.
-- @param filename (string): Path to the JSON file.
-- @param data (table): The Lua table to serialize.
-- @param prettyPrint (boolean): Whether to indent and format the JSON output. Defaults to false.
-- @return (boolean): true if the write succeeded.
-- @return (boolean, string): false and an error message if serialization or write failed.
function DFileUtil:WriteJSON(filename, data, prettyPrint)
    _assert(_type(filename) == 'string', 'DFileUtil.WriteJSON: filename must be a string')
    _assert(_type(data) == 'table', 'DFileUtil.WriteJSON: data must be a table')

    local json = util.TableToJSON(data, prettyPrint or false)
    if (not json) then
        return false, 'DFileUtil.WriteJSON: failed to serialize table to JSON'
    end

    local dir = filename:match('^(.+)/[^/]+$')
    if (dir and not self:IsDir(dir)) then
        self:CreateDir(dir)
    end

    return self:Write(filename, json)
end

--- Reads a JSON file and returns the parsed table, or a default value if the file
-- does not exist, cannot be read, or contains invalid JSON.
-- Useful for loading configs on first run without extra existence checks.
-- @param filename (string): Path to the JSON file.
-- @param default (table): The value to return when the file is absent or unreadable. Defaults to { }.
-- @param pathID (string): GMod search path. Defaults to 'DATA'.
-- @return (table): The deserialized table, or the default value.
function DFileUtil:ReadJSONOrDefault(filename, default, pathID)
    _assert(_type(filename) == 'string', 'DFileUtil.ReadJSONOrDefault: filename must be a string')

    local defaultValue = default
    if (defaultValue == nil) then
        defaultValue = { }
    end

    local tbl = self:ReadJSON(filename, pathID)
    if (not tbl) then
        return defaultValue
    end

    return tbl
end

--- Reads a JSON file, passes the table to an updater callback, then writes the result back.
-- If the file does not exist or is invalid, the updater receives the default value instead.
-- The file (and any missing parent directories) are created on the first call.
-- The write is skipped when the updater returns nil, allowing the caller to abort.
-- @param filename (string): Path to the JSON file.
-- @param updater (function): Called as updater(tbl) — mutate and return the table to save,
--                            or return nil to abort without writing.
-- @param default (table): Fallback table passed to updater when the file is absent. Defaults to { }.
-- @param pathID (string): GMod search path. Defaults to 'DATA'.
-- @return (boolean): true if the file was written, false if the updater aborted.
-- @return (boolean, string): false and an error message if the write itself failed.
function DFileUtil:UpdateJSON(filename, updater, default, pathID)
    _assert(_type(filename) == 'string', 'DFileUtil.UpdateJSON: filename must be a string')
    _assert(_type(updater) == 'function', 'DFileUtil.UpdateJSON: updater must be a function')

    local tbl = self:ReadJSONOrDefault(filename, default, pathID)
    local result = updater(tbl)

    if (result == nil) then
        return false
    end

    return self:WriteJSON(filename, result)
end
