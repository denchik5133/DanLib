/***
 *   @addon         DanLib
 *   @component     Util Network
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
 *   @description   Utility wrapper for DanLib. Covers network strings, JSON, hashing,
 *                  compression, tracing, precaching and misc util.* helpers.
 *                  Usable both inside DanLib and from any external addon.
 *
 *   @functions
 *                  - AddString - Register a network string (server-only).
 *                  - JSONToTable - Parse a JSON string into a Lua table.
 *                  - TableToJSON - Serialize a Lua table to a JSON string.
 *                  - Compress / Decompress - LZMA compression for strings/net data.
 *                  - CRC / MD5 / SHA256 - Hash a string.
 *                  - tobool - Convert a value to boolean.
 *                  - NiceFloat - Format a float, removing trailing zeroes.
 *                  - IsValidModel - Check if a model path is valid.
 *                  - PrecacheModel - Precache a model for use.
 *                  - PrecacheSound - Precache a sound for use.
 *                  - TraceLine - Cast a ray and return trace result.
 *                  - TraceHull - Cast a hull trace and return result.
 *                  - IntersectRayWithPlane - Ray/plane intersection.
 *                  - IntersectRayWithOBB - Ray/OBB intersection.
 *                  - IntersectRayWithSphere - Ray/sphere intersection.
 *                  - SteamIDTo64 / SteamIDFrom64 - Convert Steam IDs.
 *                  - Base64Encode / Base64Decode - Base64 encoding/decoding.
 *                  - KeyValuesToTable / TableToKeyValues - KeyValues format parsing.
 *                  - KeyValuesToTablePreserveOrder - KeyValues parse, preserving key order.
 *                  - StringToType / TypeToString - Convert strings to/from Lua types.
 *                  - SharedRandom - Seeded random number shared between server and client.
 *                  - IsInWorld - Check if a point is inside the world bounds.
 *                  - PointContents - Return physics content flags at a world point.
 *                  - RelativePathToFull - Resolve a relative path to a full OS path.
 *                  - Effect - Create a client-side particle/visual effect.
 *                  - Decal / DecalEx - Place a decal on the world or an entity.
 *                  - BlastDamage / BlastDamageInfo - Apply explosion damage (server).
 *                  - SpriteTrail - Attach a sprite trail to an entity (client).
 *                  - ParticleTracer / ParticleTracerEx - Draw a tracer particle (client).
 *                  - PixelVisible - Check point visibility from the camera (client).
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



DanLib.NetworkUtil = DanLib.NetworkUtil or { }
local DNetworkUtil = DanLib.NetworkUtil

local _assert = assert
local _type = type
local _isvector = isvector

--- Table for tracking registered network strings.
DanLib.NetworkStrings = DanLib.NetworkStrings or { }

--- Registers a network string for net communication (server-only).
-- Does nothing if the string is already registered.
--
-- @param networkName (string): The network string name to register.
-- @return (nil)
function DNetworkUtil:AddString(networkName)
    _assert(_type(networkName) == 'string', 'DNetworkUtil:AddString — networkName must be a string')

    if (not DanLib.NetworkStrings[networkName]) then
        util.AddNetworkString(networkName)
        DanLib.NetworkStrings[networkName] = true
    end
end

--- Parses a JSON string into a Lua table.
-- @param jsonString (string): The JSON string to parse.
-- @param ignoreLimits (boolean): Ignore depth/breadth limits. Use with caution.
-- @param ignoreConversions (boolean): Ignore string-to-number key conversions.
-- @return (table|nil): The parsed Lua table, or nil on failure.
function DNetworkUtil:JSONToTable(jsonString, ignoreLimits, ignoreConversions)
    _assert(_type(jsonString) == 'string', 'DNetworkUtil:JSONToTable — jsonString must be a string')
    return util.JSONToTable(jsonString, ignoreLimits, ignoreConversions)
end

--- Serializes a Lua table to a JSON string.
-- @param luaTable (table): The table to serialize.
-- @param prettyPrint (boolean): Whether to indent and format the output.
-- @return (string): The JSON string.
function DNetworkUtil:TableToJSON(luaTable, prettyPrint)
    _assert(_type(luaTable) == 'table', 'DNetworkUtil:TableToJSON — luaTable must be a table')
    return util.TableToJSON(luaTable, prettyPrint)
end

--- Compresses a string using LZMA compression.
-- Useful for reducing the size of large net messages or file data.
-- @param str (string): The string to compress.
-- @return (string): The compressed binary string.
function DNetworkUtil:Compress(str)
    _assert(_type(str) == 'string', 'DNetworkUtil:Compress — str must be a string')
    return util.Compress(str)
end

--- Decompresses a string previously compressed with Compress.
-- @param str (string): The compressed binary string.
-- @return (string|nil): The decompressed string, or nil on failure.
function DNetworkUtil:Decompress(str)
    _assert(_type(str) == 'string', 'DNetworkUtil:Decompress — str must be a string')
    return util.Decompress(str)
end

--- Returns the CRC checksum of a string as a decimal string.
-- @param str (string): The input string.
-- @return (string): The CRC checksum.
function DNetworkUtil:CRC(str)
    _assert(_type(str) == 'string', 'DNetworkUtil:CRC — str must be a string')
    return util.CRC(str)
end

--- Returns the MD5 hash of a string as a hex string.
-- @param str (string): The input string.
-- @return (string): The MD5 hash (32 hex characters).
function DNetworkUtil:MD5(str)
    _assert(_type(str) == 'string', 'DNetworkUtil:MD5 — str must be a string')
    return util.MD5(str)
end

--- Returns the SHA-256 hash of a string as a hex string.
-- @param str (string): The input string.
-- @return (string): The SHA-256 hash (64 hex characters).
function DNetworkUtil:SHA256(str)
    _assert(_type(str) == 'string', 'DNetworkUtil:SHA256 — str must be a string')
    return util.SHA256(str)
end

--- Converts a value to a boolean.
-- Accepts strings ('true'/'1'/'on'), numbers (non-zero), or booleans.
-- @param val (any): The value to convert.
-- @return (boolean): The boolean result.
function DNetworkUtil:tobool(val)
    return util.tobool(val)
end

--- Formats a float, removing unnecessary trailing zeroes.
-- For example: 3.50000 → '3.5', 1.0 → '1'.
-- @param float (number): The number to format.
-- @return (string): The formatted string.
function DNetworkUtil:NiceFloat(float)
    _assert(_type(float) == 'number', 'DNetworkUtil:NiceFloat — float must be a number')
    return util.NiceFloat(float)
end

--- Checks whether a model path is valid and loadable.
-- @param model (string): The model path to check (e.g. 'models/player/combine_soldier.mdl').
-- @return (boolean): true if the model is valid.
function DNetworkUtil:IsValidModel(model)
    _assert(_type(model) == 'string', 'DNetworkUtil:IsValidModel — model must be a string')
    return util.IsValidModel(model)
end

--- Precaches a model so it is available without delay during gameplay.
-- @param model (string): The model path to precache.
-- @return (nil)
function DNetworkUtil:PrecacheModel(model)
    _assert(_type(model) == 'string', 'DNetworkUtil:PrecacheModel — model must be a string')
    util.PrecacheModel(model)
end

--- Precaches a sound so it is available without delay during gameplay.
-- @param sound (string): The sound path to precache.
-- @return (nil)
function DNetworkUtil:PrecacheSound(sound)
    _assert(_type(sound) == 'string', 'DNetworkUtil:PrecacheSound — sound must be a string')
    util.PrecacheSound(sound)
end

--- Casts a ray and returns a trace result table.
-- @param traceData (table): A trace data table (see util.TraceLine wiki for fields).
-- @return (table): The trace result.
function DNetworkUtil:TraceLine(traceData)
    _assert(_type(traceData) == 'table', 'DNetworkUtil:TraceLine — traceData must be a table')
    return util.TraceLine(traceData)
end

--- Casts a hull trace and returns a trace result table.
-- @param traceData (table): A trace data table with mins/maxs fields.
-- @return (table): The trace result.
function DNetworkUtil:TraceHull(traceData)
    _assert(_type(traceData) == 'table', 'DNetworkUtil:TraceHull — traceData must be a table')
    return util.TraceHull(traceData)
end

--- Finds the intersection point of a ray with a plane.
-- @param rayOrigin (Vector): The start point of the ray.
-- @param rayDirection (Vector): The direction of the ray.
-- @param planePosition (Vector): Any point on the plane.
-- @param planeNormal (Vector): The normal of the plane.
-- @return (Vector|nil): The intersection point, or nil if the ray is parallel to the plane.
function DNetworkUtil:IntersectRayWithPlane(rayOrigin, rayDirection, planePosition, planeNormal)
    _assert(_isvector(rayOrigin), 'DNetworkUtil:IntersectRayWithPlane — rayOrigin must be a Vector')
    _assert(_isvector(rayDirection), 'DNetworkUtil:IntersectRayWithPlane — rayDirection must be a Vector')
    _assert(_isvector(planePosition), 'DNetworkUtil:IntersectRayWithPlane — planePosition must be a Vector')
    _assert(_isvector(planeNormal), 'DNetworkUtil:IntersectRayWithPlane — planeNormal must be a Vector')
    return util.IntersectRayWithPlane(rayOrigin, rayDirection, planePosition, planeNormal)
end

--- Finds the intersection of a ray with an oriented bounding box (OBB).
-- @param rayOrigin (Vector): The start point of the ray.
-- @param rayDirection (Vector): The direction of the ray.
-- @param boxOrigin (Vector): The origin of the OBB.
-- @param boxAngles (Angle): The angles of the OBB.
-- @param boxMins (Vector): The minimum corner of the OBB (local space).
-- @param boxMaxs (Vector): The maximum corner of the OBB (local space).
-- @return (number|nil): The distance along the ray to the hit, or nil if no hit.
function DNetworkUtil:IntersectRayWithOBB(rayOrigin, rayDirection, boxOrigin, boxAngles, boxMins, boxMaxs)
    _assert(_isvector(rayOrigin), 'DNetworkUtil:IntersectRayWithOBB — rayOrigin must be a Vector')
    _assert(_isvector(rayDirection), 'DNetworkUtil:IntersectRayWithOBB — rayDirection must be a Vector')
    _assert(_isvector(boxOrigin), 'DNetworkUtil:IntersectRayWithOBB — boxOrigin must be a Vector')
    _assert(_isvector(boxMins), 'DNetworkUtil:IntersectRayWithOBB — boxMins must be a Vector')
    _assert(_isvector(boxMaxs), 'DNetworkUtil:IntersectRayWithOBB — boxMaxs must be a Vector')
    return util.IntersectRayWithOBB(rayOrigin, rayDirection, boxOrigin, boxAngles, boxMins, boxMaxs)
end

--- Finds the intersection of a ray with a sphere.
-- @param rayOrigin (Vector): The start point of the ray.
-- @param rayDirection (Vector): The direction of the ray.
-- @param sphereOrigin (Vector): The center of the sphere.
-- @param sphereRadius (number): The radius of the sphere.
-- @return (number|nil): The distance along the ray to the hit, or nil if no hit.
function DNetworkUtil:IntersectRayWithSphere(rayOrigin, rayDirection, sphereOrigin, sphereRadius)
    _assert(_isvector(rayOrigin), 'DNetworkUtil:IntersectRayWithSphere — rayOrigin must be a Vector')
    _assert(_isvector(rayDirection), 'DNetworkUtil:IntersectRayWithSphere — rayDirection must be a Vector')
    _assert(_isvector(sphereOrigin), 'DNetworkUtil:IntersectRayWithSphere — sphereOrigin must be a Vector')
    _assert(_type(sphereRadius) == 'number' and sphereRadius > 0, 'DNetworkUtil:IntersectRayWithSphere — sphereRadius must be a positive number')
    return util.IntersectRayWithSphere(rayOrigin, rayDirection, sphereOrigin, sphereRadius)
end

--- Converts a Player:SteamID() style ID (STEAM_0:1:...) to a 64-bit Steam ID string.
-- @param steamID (string): The legacy Steam ID string.
-- @return (string): The 64-bit Steam ID as a string.
function DNetworkUtil:SteamIDTo64(steamID)
    _assert(_type(steamID) == 'string', 'DNetworkUtil:SteamIDTo64 — steamID must be a string')
    return util.SteamIDTo64(steamID)
end

--- Converts a 64-bit Steam ID string to a Player:SteamID() style ID (STEAM_0:1:...).
-- @param id64 (string): The 64-bit Steam ID string.
-- @return (string): The legacy Steam ID string.
function DNetworkUtil:SteamIDFrom64(id64)
    _assert(_type(id64) == 'string', 'DNetworkUtil:SteamIDFrom64 — id64 must be a string')
    return util.SteamIDFrom64(id64)
end

--- Encodes a binary string to a Base64 string.
-- @param str (string): The string to encode.
-- @return (string): The Base64-encoded string.
function DNetworkUtil:Base64Encode(str)
    _assert(_type(str) == 'string', 'DNetworkUtil:Base64Encode — str must be a string')
    return util.Base64Encode(str)
end

--- Decodes a Base64 string back to a binary string.
-- @param str (string): The Base64-encoded string.
-- @return (string): The decoded binary string.
function DNetworkUtil:Base64Decode(str)
    _assert(_type(str) == 'string', 'DNetworkUtil:Base64Decode — str must be a string')
    return util.Base64Decode(str)
end

--- Parses a KeyValues string into a Lua table.
-- @param str (string): The KeyValues string to parse.
-- @param separator (string): Key separator character. Defaults to '\n'.
-- @return (table|nil): The parsed table, or nil on failure.
function DNetworkUtil:KeyValuesToTable(str, separator)
    _assert(_type(str) == 'string', 'DNetworkUtil:KeyValuesToTable — str must be a string')
    return util.KeyValuesToTable(str, separator)
end

--- Serializes a Lua table to a KeyValues string.
-- @param tbl (table): The table to serialize.
-- @param parentKey (string): The top-level key name. Defaults to 'base'.
-- @return (string): The KeyValues string.
function DNetworkUtil:TableToKeyValues(tbl, parentKey)
    _assert(_type(tbl) == 'table', 'DNetworkUtil:TableToKeyValues — tbl must be a table')
    return util.TableToKeyValues(tbl, parentKey)
end

--- Parses a KeyValues string into a Lua table, preserving the original key order.
-- @param str (string): The KeyValues string to parse.
-- @return (table|nil): The parsed table with ordered keys, or nil on failure.
function DNetworkUtil:KeyValuesToTablePreserveOrder(str)
    _assert(_type(str) == 'string', 'DNetworkUtil:KeyValuesToTablePreserveOrder — str must be a string')
    return util.KeyValuesToTablePreserveOrder(str)
end

--- Converts a string representation of a Lua value to its actual type.
-- For example, "true" → true, "42" → 42, "hello" → "hello".
-- @param str (string): The string to convert.
-- @return (any): The converted value.
function DNetworkUtil:StringToType(str)
    _assert(_type(str) == 'string', 'DNetworkUtil:StringToType — str must be a string')
    return util.StringToType(str)
end

--- Converts a Lua value to its string representation.
-- Inverse of StringToType.
-- @param val (any): The value to convert.
-- @return (string): The string representation.
function DNetworkUtil:TypeToString(val)
    return util.TypeToString(val)
end

--- Returns a random float that is guaranteed to be the same on both server and client
-- when called with the same seed and sharedKey during the same tick.
-- @param uniqueName (string): A unique key string to differentiate calls.
-- @param min (number): The minimum value.
-- @param max (number): The maximum value.
-- @param additionalSeed (number): An extra seed value.
-- @return (number): The shared random float.
function DNetworkUtil:SharedRandom(uniqueName, min, max, additionalSeed)
    _assert(_type(uniqueName) == 'string', 'DNetworkUtil:SharedRandom — uniqueName must be a string')
    _assert(_type(min) == 'number', 'DNetworkUtil:SharedRandom — min must be a number')
    _assert(_type(max) == 'number', 'DNetworkUtil:SharedRandom — max must be a number')
    return util.SharedRandom(uniqueName, min, max, additionalSeed or 0)
end

--- Checks whether a point is inside the world geometry bounds.
-- @param point (Vector): The world position to check.
-- @return (boolean): true if the point is inside the world.
function DNetworkUtil:IsInWorld(point)
    _assert(_isvector(point), 'DNetworkUtil:IsInWorld — point must be a Vector')
    return util.IsInWorld(point)
end

--- Returns the physics content flags at a given world position.
-- Useful for detecting water, slime, sky, or solid areas.
-- @param point (Vector): The world position to sample.
-- @return (number): A bitmask of CONTENTS_* flags.
function DNetworkUtil:PointContents(point)
    _assert(_isvector(point), 'DNetworkUtil:PointContents — point must be a Vector')
    return util.PointContents(point)
end

--- Resolves a relative path to the full OS path on disk.
-- @param path (string): The relative path to resolve.
-- @param pathID (string): GMod search path, e.g. 'GAME', 'DATA'. Defaults to 'GAME'.
-- @return (string): The full filesystem path.
function DNetworkUtil:RelativePathToFull(path, pathID)
    _assert(_type(path) == 'string', 'DNetworkUtil:RelativePathToFull — path must be a string')
    return util.RelativePathToFull(path, pathID or 'GAME')
end

--- Creates a client-side particle or visual effect at a position.
-- @param effectName (string): The effect name (e.g. "explosion").
-- @param effectData (CEffectData): A CEffectData object describing the effect.
-- @param allowOverride (boolean): Allow Lua-defined effects to override engine ones.
-- @param ignorePrediction (boolean): Ignore prediction for this effect.
function DNetworkUtil:Effect(effectName, effectData, allowOverride, ignorePrediction)
    _assert(_type(effectName) == 'string', 'DNetworkUtil:Effect — effectName must be a string')
    util.Effect(effectName, effectData, allowOverride, ignorePrediction)
end

--- Places a decal on world geometry.
-- @param decalName (string): The decal material name.
-- @param traceStart (Vector): Ray start for finding the surface.
-- @param traceEnd (Vector): Ray end for finding the surface.
-- @param ent (Entity): Optional entity to project onto. Defaults to world.
function DNetworkUtil:Decal(decalName, traceStart, traceEnd, ent)
    _assert(_type(decalName) == 'string', 'DNetworkUtil:Decal — decalName must be a string')
    _assert(_isvector(traceStart), 'DNetworkUtil:Decal — traceStart must be a Vector')
    _assert(_isvector(traceEnd), 'DNetworkUtil:Decal — traceEnd must be a Vector')
    util.Decal(decalName, traceStart, traceEnd, ent)
end

--- Places a decal on an entity with extended options.
-- @param decalName (string): The decal material name.
-- @param ent (Entity): The entity to project onto.
-- @param hitBody (number): The physics body index.
-- @param traceStart (Vector): Ray start for finding the surface.
-- @param traceEnd (Vector): Ray end for finding the surface.
-- @param color (Color): Tint color for the decal.
function DNetworkUtil:DecalEx(decalName, ent, hitBody, traceStart, traceEnd, color)
    _assert(_type(decalName) == 'string', 'DNetworkUtil:DecalEx — decalName must be a string')
    _assert(_isvector(traceStart), 'DNetworkUtil:DecalEx — traceStart must be a Vector')
    _assert(_isvector(traceEnd), 'DNetworkUtil:DecalEx — traceEnd must be a Vector')
    util.DecalEx(decalName, ent, hitBody, traceStart, traceEnd, color)
end

--- Applies explosion damage to all entities within a radius (server-only).
-- @param origin (Vector): The center of the explosion.
-- @param inflictor (Entity): The entity causing the damage.
-- @param attacker (Entity): The entity responsible for the damage.
-- @param damage (number): Maximum damage at the epicenter.
-- @param radius (number): The explosion radius.
function DNetworkUtil:BlastDamage(origin, inflictor, attacker, damage, radius)
    _assert(_isvector(origin), 'DNetworkUtil:BlastDamage — origin must be a Vector')
    _assert(_type(damage) == 'number', 'DNetworkUtil:BlastDamage — damage must be a number')
    _assert(_type(radius) == 'number', 'DNetworkUtil:BlastDamage — radius must be a number')
    util.BlastDamage(origin, inflictor, attacker, damage, radius)
end

--- Applies explosion damage using a CTakeDamageInfo object (server-only).
-- @param origin (Vector): The center of the explosion.
-- @param radius (number): The explosion radius.
-- @param dmgInfo (CTakeDamageInfo): The damage info object.
function DNetworkUtil:BlastDamageInfo(origin, radius, dmgInfo)
    _assert(_isvector(origin), 'DNetworkUtil:BlastDamageInfo — origin must be a Vector')
    _assert(_type(radius) == 'number', 'DNetworkUtil:BlastDamageInfo — radius must be a number')
    util.BlastDamageInfo(origin, radius, dmgInfo)
end

--- Attaches a sprite trail to an entity (client-only).
-- @param ent (Entity): The entity to attach the trail to.
-- @param attachmentID (number): Attachment point index.
-- @param color (Color): Trail color.
-- @param additive (boolean): Whether the trail uses additive blending.
-- @param startWidth (number): Width at the start of the trail.
-- @param endWidth (number): Width at the end of the trail.
-- @param lifetime (number): How long (seconds) each segment persists.
-- @param textureRes (number): Texture resolution divisor.
-- @param texture (string): Material path for the trail.
function DNetworkUtil:SpriteTrail(ent, attachmentID, color, additive, startWidth, endWidth, lifetime, textureRes, texture)
    util.SpriteTrail(ent, attachmentID, color, additive, startWidth, endWidth, lifetime, textureRes, texture)
end

--- Draws a tracer particle from start to end (client-only).
-- @param startPos (Vector): The start of the tracer.
-- @param endPos (Vector): The end of the tracer.
-- @param doWhiz (boolean): Whether to play a whiz sound.
function DNetworkUtil:ParticleTracer(startPos, endPos, doWhiz)
    _assert(_isvector(startPos), 'DNetworkUtil:ParticleTracer — startPos must be a Vector')
    _assert(_isvector(endPos), 'DNetworkUtil:ParticleTracer — endPos must be a Vector')
    util.ParticleTracer(startPos, endPos, doWhiz)
end

--- Draws a tracer particle with extended options (client-only).
-- @param startPos (Vector): The start of the tracer.
-- @param endPos (Vector): The end of the tracer.
-- @param doWhiz (boolean): Whether to play a whiz sound.
-- @param ent (Entity): Entity to attach the tracer origin to.
-- @param attachmentID (number): Attachment point index on the entity.
function DNetworkUtil:ParticleTracerEx(startPos, endPos, doWhiz, ent, attachmentID)
    _assert(_isvector(startPos), 'DNetworkUtil:ParticleTracerEx — startPos must be a Vector')
    _assert(_isvector(endPos), 'DNetworkUtil:ParticleTracerEx — endPos must be a Vector')
    util.ParticleTracerEx(startPos, endPos, doWhiz, ent, attachmentID)
end

--- Checks whether a world-space point is visible from the camera without occlusion (client-only).
-- Must be called after a util.PixelVisible call has been set up.
-- @param pos (Vector): The world position to test.
-- @param radius (number): The test radius in world units.
-- @param ent (Entity): Optional entity to associate with the visibility check.
-- @return (number): A visibility fraction between 0 (hidden) and 1 (fully visible).
function DNetworkUtil:PixelVisible(pos, radius, ent)
    _assert(_isvector(pos), 'DNetworkUtil:PixelVisible — pos must be a Vector')
    _assert(_type(radius) == 'number', 'DNetworkUtil:PixelVisible — radius must be a number')
    return util.PixelVisible(pos, radius, ent)
end
