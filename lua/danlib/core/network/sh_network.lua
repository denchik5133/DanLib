/***
 *   @addon         DanLib
 *   @component     Network
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
 *   @description   Fluent network message builder for DanLib.
 *                  Uses a single multiplexed channel (NetStream-style) so that
 *                  DNet:On / DNet:Open work freely from cl_*, sv_*, or sh_* files
 *                  without any util.AddNetworkString calls in userland.
 *
 *   @how it works
 *                  The server registers ONE GMod network string: "DanLib.Net.Channel".
 *                  Every Open() call starts that single channel and writes the message
 *                  name as the first string in the payload.  The router on the receiver
 *                  reads that name and dispatches to the correct handler.
 *                  DNet:On() just stores a function in a plain Lua table — no GMod
 *                  string table involved at all.
 *
 *   @api
 *                  DanLib.Net:Open(name, unreliable) — start a message, returns NetMsg builder.
 *                  DanLib.Net:On(name, fn) — register a receiver.
 *
 *   @write_methods
 *                  :Str(v)          WriteString
 *                  :Int(v, bits)    WriteInt (bits default 32)
 *                  :UInt(v, bits)   WriteUInt (bits default 32)
 *                  :Bool(v)         WriteBool
 *                  :Ent(v)          WriteEntity
 *                  :Tbl(v)          WriteTable
 *                  :Float(v)        WriteFloat
 *                  :Vec(v)          WriteVector
 *                  :Ang(v)          WriteAngle
 *                  :Col(v)          WriteColor
 *                  :Bit(v)          WriteBit
 *                  :Data(v, len)    WriteData (len defaults to #v)
 *
 *   @send_methods
 *                  :Send(target)    net.Send(target) — player, table of players, or nil → Broadcast
 *                  :All()           net.Broadcast()
 *                  :Up()            net.SendToServer() (CLIENT → SERVER)
 *
 *   @read_methods
 *                  :Str()           ReadString
 *                  :Int(bits)       ReadInt
 *                  :UInt(bits)      ReadUInt
 *                  :Bool()          ReadBool
 *                  :Ent()           ReadEntity
 *                  :Tbl()           ReadTable
 *                  :Float()         ReadFloat
 *                  :Vec()           ReadVector
 *                  :Ang()           ReadAngle
 *                  :Col()           ReadColor
 *                  :Bit()           ReadBit
 *                  :Data(len)       ReadData
 *
 *   @example
 *                  -- Sending (SERVER → CLIENT) — works from any file
 *                  DanLib.Net:Open('DDIChat.ForwardMessage')
 *                      :Str(json)
 *                      :Ent(speaker)
 *                      :Bool(isMention)
 *                      :Send(targets)
 *
 *                  -- Receiving (CLIENT) — works from cl_*, sh_* or sv_* file
 *                  DanLib.Net:On('DDIChat.ForwardMessage', function(len, ply)
 *                      local json = DanLib.Net:Str()
 *                      local speaker = DanLib.Net:Ent()
 *                      local mention = DanLib.Net:Bool()
 *                  end)
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes
 *                  - DanLib.Network (old API) is kept for backward compatibility and
 *                    still uses direct util.AddNetworkString per string.
 *                  - Each message pays a small overhead: the name string is written
 *                    at the start of every payload.  For short names this is ~1–40 bytes.
 *                  - Only one GMod network string slot is used for all DanLib.Net traffic.
 */



local _strformat = string.format
local _tostring = tostring
local _assert = assert
local _ipairs = ipairs
local _print = print
local _type = type


-- Single multiplexed channel
-- The server registers this one GMod network string.
-- All DanLib.Net traffic flows through it.
local CHANNEL = 'DanLib.Net.Channel'

if SERVER then
    util.AddNetworkString(CHANNEL)
end

-- Internal routing table: messageName → handlerFn
-- Net:On() writes here; the router below reads from here.
local _handlers = { }

-- Router — receives every packet on the single channel,
-- reads the message name, then dispatches to the stored handler.
net.Receive(CHANNEL, function(len, ply)
    local name = net.ReadString()
    local fn = _handlers[name]
    if fn then
        fn(len, ply)
    end
end)


-- NetMsg — fluent write builder
-- Returned by DanLib.Net:Open(); each write method returns
-- self so calls can be chained freely in any order.
local NetMsg = { }
NetMsg.__index = NetMsg

--- Writes a string value.
-- @param value (string)
-- @return self
function NetMsg:Str(value)
    _assert(_type(value) == 'string', '[DanLib.Net:' .. self._name .. '] Str — expected string, got ' .. _type(value))
    net.WriteString(value)
    return self
end

--- Writes a signed integer.
-- @param value (number)
-- @param bits (number, default 32)
-- @return self
function NetMsg:Int(value, bits)
    _assert(_type(value) == 'number', '[DanLib.Net:' .. self._name .. '] Int — expected number, got ' .. _type(value))
    net.WriteInt(value, bits or 32)
    return self
end

--- Writes an unsigned integer.
-- @param value (number)
-- @param bits (number, default 32)
-- @return self
function NetMsg:UInt(value, bits)
    _assert(_type(value) == 'number', '[DanLib.Net:' .. self._name .. '] UInt — expected number, got ' .. _type(value))
    net.WriteUInt(value, bits or 32)
    return self
end

--- Writes a boolean.
-- @param value (boolean)
-- @return self
function NetMsg:Bool(value)
    _assert(_type(value) == 'boolean', '[DanLib.Net:' .. self._name .. '] Bool — expected boolean, got ' .. _type(value))
    net.WriteBool(value)
    return self
end

--- Writes an entity reference.
-- @param entity (Entity)
-- @return self
function NetMsg:Ent(entity)
    net.WriteEntity(entity)
    return self
end

--- Writes a table.
-- Prefer :Str(util.TableToJSON(tbl)) for large / nested tables.
-- @param tbl (table)
-- @return self
function NetMsg:Tbl(tbl)
    _assert(_type(tbl) == 'table', '[DanLib.Net:' .. self._name .. '] Tbl — expected table, got ' .. _type(tbl))
    net.WriteTable(tbl)
    return self
end

--- Writes a 32-bit float.
-- @param value (number)
-- @return self
function NetMsg:Float(value)
    _assert(_type(value) == 'number', '[DanLib.Net:' .. self._name .. '] Float — expected number, got ' .. _type(value))
    net.WriteFloat(value)
    return self
end

--- Writes a Vector.
-- @param vec (Vector)
-- @return self
function NetMsg:Vec(vec)
    net.WriteVector(vec)
    return self
end

--- Writes an Angle.
-- @param ang (Angle)
-- @return self
function NetMsg:Ang(ang)
    net.WriteAngle(ang)
    return self
end

--- Writes a Color.
-- @param color (Color)
-- @return self
function NetMsg:Col(color)
    net.WriteColor(color)
    return self
end

--- Writes a single bit (0 or 1).
-- @param bit (number)
-- @return self
function NetMsg:Bit(bit)
    net.WriteBit(bit)
    return self
end

--- Writes raw binary data.
-- @param data (string)  Binary string.
-- @param len  (number)  Bytes to write (default: full length).
-- @return self
function NetMsg:Data(data, len)
    _assert(_type(data) == 'string', '[DanLib.Net:' .. self._name .. '] Data — expected string, got ' .. _type(data))
    net.WriteData(data, len or #data)
    return self
end


-- Terminal send methods

--- Sends to one player, a table of players, or broadcasts when target is nil.
-- @param target (Player|table|nil)
-- @return self
function NetMsg:Send(target)
    if target == nil then
        net.Broadcast()
    else
        net.Send(target)
    end
    return self
end

--- Broadcasts to all connected clients.
-- @return self
function NetMsg:All()
    net.Broadcast()
    return self
end

--- Sends from CLIENT to SERVER.
-- @return self
function NetMsg:Up()
    net.SendToServer()
    return self
end


-- DanLib.Net — primary API
DanLib.Net = DanLib.Net or { }
local DNet = DanLib.Net

--- Opens a new network message and returns a chainable write builder.
--
-- Works from any file (cl_*, sv_*, sh_*) without util.AddNetworkString.
-- The message name is written as the first string in the payload and is
-- used by the router on the receiving side to dispatch the correct handler.
--
-- @param name (string): Unique message name.
-- @param unreliable (bool): May be dropped; uses less bandwidth. Default false.
-- @return NetMsg
--
-- Example:
--   DanLib.Net:Open('MyAddon.SomeEvent')
--       :Str(payload)
--       :Bool(flag)
--       :Send(ply)
function DNet:Open(name, unreliable)
    _assert(_type(name) == 'string' and #name > 0, '[DanLib.Net] Open — name must be a non-empty string')
    net.Start(CHANNEL, unreliable == true)
    net.WriteString(name) -- route key — router reads this first on the receiver

    return setmetatable({
        _name = name
    }, NetMsg)
end

--- Registers a handler for an incoming network message.
--
-- Works from any file (cl_*, sv_*, sh_*) — no util.AddNetworkString required.
-- Multiple calls for the same name replace the previous handler (last wins),
-- matching vanilla GMod net.Receive behaviour.
--
-- @param name (string): Message name — must match the name used in DNet:Open().
-- @param fn (function): Handler — receives (len, ply). ply is nil on CLIENT (message came from server).
--
-- Example (works in a pure cl_* file):
--   DanLib.Net:On('MyAddon.SomeEvent', function(len, ply)
--       local payload = DanLib.Net:Str()
--       local flag = DanLib.Net:Bool()
--   end)
function DNet:On(name, fn)
    _assert(_type(name) == 'string' and #name > 0, '[DanLib.Net] On — name must be a non-empty string')
    _assert(_type(fn) == 'function', '[DanLib.Net] On — handler must be a function')
    _handlers[name] = fn
end

--- Removes a previously registered handler.
-- @param name (string): Message name.
function DNet:Off(name)
    _assert(_type(name) == 'string' and #name > 0, '[DanLib.Net] Off — name must be a non-empty string')
    _handlers[name] = nil
end


-- Read methods — used inside On handlers
-- Each call reads one value from the current incoming message
-- in the order it was written.

--- Reads a string.
-- @return string
function DNet:Str()
    return net.ReadString()
end

--- Reads a signed integer.
-- @param bits (number, default 32)
-- @return number
function DNet:Int(bits)
    return net.ReadInt(bits or 32)
end

--- Reads an unsigned integer.
-- @param bits (number, default 32)
-- @return number
function DNet:UInt(bits)
    return net.ReadUInt(bits or 32)
end

--- Reads a boolean.
-- @return bool
function DNet:Bool()
    return net.ReadBool()
end

--- Reads an entity reference.
-- @return Entity
function DNet:Ent()
    return net.ReadEntity()
end

--- Reads a table.
-- @return table
function DNet:Tbl()
    return net.ReadTable()
end

--- Reads a 32-bit float.
-- @return number
function DNet:Float()
    return net.ReadFloat()
end

--- Reads a Vector.
-- @return Vector
function DNet:Vec()
    return net.ReadVector()
end

--- Reads an Angle.
-- @return Angle
function DNet:Ang()
    return net.ReadAngle()
end

--- Reads a Color.
-- @return Color
function DNet:Col()
    return net.ReadColor()
end

--- Reads a single bit.
-- @return number (0 or 1)
function DNet:Bit()
    return net.ReadBit()
end

--- Reads raw binary data.
-- @param len (number): Bytes to read.
-- @return string
function DNet:Data(len)
    return net.ReadData(len)
end


-- Diagnostics

--- Prints all message names that have a registered handler.
-- Useful for auditing what the addon owns.
function DNet:DumpAll()
    local names = { }
    for k in _pairs(_handlers) do
        names[#names + 1] = k
    end

    table.sort(names)
    _print(_strformat('[DanLib.Net] DumpAll — %d handler(s) registered:', #names))
    for _, name in _ipairs(names) do
        _print('  ' .. name)
    end
end

--- Prints whether a handler is registered for the given name.
-- @param name (string)
function DNet:Dump(name)
    local registered = _handlers[name] ~= nil
    _print(_strformat('[DanLib.Net] Dump(%q) | handler=%s', name, _tostring(registered)))
end

--- Returns true if a handler is registered for this name.
-- @param name (string)
-- @return bool
function DNet:HasHandler(name)
    return _handlers[name] ~= nil
end



-- ==== DEPRECATED DEPRECATED DEPRECATED ==== --
-- We do not recommend using this. 
-- This function is not recommended.
-- It will be removed in the future.
-- Instead, use `DanLib.Net`.
-- ==== DEPRECATED DEPRECATED DEPRECATED ==== --

-- DanLib.Network — legacy API (backward compatibility)
-- Kept as-is; uses direct util.AddNetworkString per string.
-- New code should use DanLib.Net instead.
DanLib.Network = DanLib.Network or { }
local Network = DanLib.Network

-- Legacy registry to avoid double-registering on server
local _legacy_registry = { }

local function _legacy_register(name)
    if (SERVER and not _legacy_registry[name]) then
        util.AddNetworkString(name)
        _legacy_registry[name] = true
    end
end

function Network:Start(name)
    _assert(_type(name) == 'string', 'Name for Start is not provided or is not a string.')
    _legacy_register(name)
    net.Start(name)
end

function Network:WriteUInt(value, bits)
    _assert(value ~= nil, 'Value for WriteUInt is not provided.')
    _assert(_type(bits) == 'number', 'Bits for WriteUInt is not provided or is not a number.')
    net.WriteUInt(value, bits)
end

function Network:ReadUInt(bits)
    _assert(_type(bits) == 'number', 'Bits for ReadUInt is not provided or is not a number.')
    return net.ReadUInt(bits)
end

function Network:WriteInt(value, bits)
    _assert(value ~= nil, 'Value for WriteInt is not provided.')
    _assert(_type(bits) == 'number', 'Bits for WriteInt is not provided or is not a number.')
    net.WriteInt(value, bits)
end

function Network:ReadInt(bits)
    _assert(_type(bits) == 'number', 'Bits for ReadInt is not provided or is not a number.')
    return net.ReadInt(bits)
end

function Network:WriteString(value)
    _assert(value ~= nil, 'Value for WriteString is not provided.')
    net.WriteString(value)
end

function Network:ReadString()
    return net.ReadString()
end

function Network:WriteEntity(entity)
    _assert(entity ~= nil, 'Value for WriteEntity is not provided.')
    net.WriteEntity(entity)
end

function Network:ReadEntity()
    return net.ReadEntity()
end

function Network:WriteTable(tbl)
    _assert(tbl ~= nil, 'Value for WriteTable is not provided.')
    net.WriteTable(tbl)
end

function Network:ReadTable()
    return net.ReadTable()
end

function Network:WriteBool(value)
    _assert(value ~= nil, 'Value for WriteBool is not provided.')
    _assert(_type(value) == 'boolean', 'Value for WriteBool is not a boolean.')
    net.WriteBool(value)
end

function Network:ReadBool()
    return net.ReadBool()
end

function Network:Broadcast()
    net.Broadcast()
end

function Network:SendToPlayer(pPlayer)
    _assert(pPlayer ~= nil, 'Player for SendToPlayer is not provided.')
    net.Send(pPlayer)
end

function Network:SendToServer()
    net.SendToServer()
end

function Network:Receive(name, func)
    _assert(_type(name) == 'string', 'Name for Receive is not provided or is not a string.')
    _assert(func ~= nil, 'Function for Receive is not provided.')
    _legacy_register(name)
    net.Receive(name, func)
end
