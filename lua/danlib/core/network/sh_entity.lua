/***
 *   @addon         DanLib
 *   @component     Entity Factory
 *   @license       MIT License
 *   @version       1.1.0
 *   @release_date  25/05/2026
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   Entity factory for DanLib. Provides a fluent meta-based API for
 *                  defining and registering scripted entities (props, NPCs, points).
 *                  Follows the same factory pattern as DanLib.Func.CreateLogs and
 *                  DanLib.Func.CreateModule. Registers entities via scripted_ents.Register.
 *
 *                  Supports:
 *                    - NetworkVar declarations via AddNetworkVar / SetupDataTables
 *                    - Side-specific callbacks (OnServerInitialize / OnClientInitialize,
 *                      OnServerThink / OnClientThink, OnClientDraw, OnClientDrawTranslucent)
 *                    - Custom methods via AddMethod
 *                    - NetworkVar change listeners via OnNetVarChanged
 *                    - AcceptInput and OnTakeDamage handlers
 *                    - AutomaticFrameAdvance flag
 *
 *   @usage
 *                  local ENT_DEF = DanLib.Func.CreateEntity('my_prop')
 *                  ENT_DEF:SetType('anim')
 *                  ENT_DEF:SetModel('models/props_c17/oildrum001.mdl')
 *                  ENT_DEF:SetPrintName('My Prop')
 *                  ENT_DEF:SetSpawnable(true)
 *                  ENT_DEF:AddNetworkVar('String', 0, 'MyKey')
 *                  ENT_DEF:OnServerInitialize(function(self)
 *                      self:PhysicsInit(SOLID_VPHYSICS)
 *                      self:SetMoveType(MOVETYPE_VPHYSICS)
 *                  end)
 *                  ENT_DEF:OnClientDraw(function(self)
 *                      self:DrawModel()
 *                  end)
 *                  ENT_DEF:Register()
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local _assert = assert
local _type = type
local _pairs = pairs

-- EntityMeta — fluent definition object returned by CreateEntity().
-- Methods set properties and callbacks; Register() commits to GMod.
local EntityMeta = { }
EntityMeta.__index = EntityMeta

--- Sets the scripted entity type.
-- @param entType (string): 'anim', 'ai', 'point', 'brush'. Defaults to 'anim'.
function EntityMeta:SetType(entType)
    _assert(_type(entType) == 'string', 'DanLib Entity:SetType — entType must be a string')
    self._type = entType
    return self
end

--- Sets the base entity class to inherit from.
-- @param base (string): e.g. 'base_entity', 'base_anim', 'base_ai'. Defaults to 'base_entity'.
function EntityMeta:SetBase(base)
    _assert(_type(base) == 'string', 'DanLib Entity:SetBase — base must be a string')
    self._base = base
    return self
end

--- Sets the default model path.
-- @param model (string): Model path, e.g. 'models/props_c17/oildrum001.mdl'.
function EntityMeta:SetModel(model)
    _assert(_type(model) == 'string', 'DanLib Entity:SetModel — model must be a string')
    self._model = model
    return self
end

--- Sets the display name shown in the spawn menu.
-- @param name (string)
function EntityMeta:SetPrintName(name)
    _assert(_type(name) == 'string', 'DanLib Entity:SetPrintName — name must be a string')
    self._printName = name
    return self
end

--- Sets the spawn menu category.
-- @param category (string): Defaults to 'DanLib'.
function EntityMeta:SetCategory(category)
    _assert(_type(category) == 'string', 'DanLib Entity:SetCategory — category must be a string')
    self._category = category
    return self
end

--- Sets the author string shown in the spawn menu.
-- @param author (string)
function EntityMeta:SetAuthor(author)
    _assert(_type(author) == 'string', 'DanLib Entity:SetAuthor — author must be a string')
    self._author = author
    return self
end

--- Sets the contact string shown in the spawn menu.
-- @param contact (string): e.g. 'https://discord.gg/...'.
function EntityMeta:SetContact(contact)
    _assert(_type(contact) == 'string', 'DanLib Entity:SetContact — contact must be a string')
    self._contact = contact
    return self
end

--- Whether the entity appears in the spawn menu.
-- @param spawnable (boolean): Defaults to false.
function EntityMeta:SetSpawnable(spawnable)
    _assert(_type(spawnable) == 'boolean', 'DanLib Entity:SetSpawnable — spawnable must be a boolean')
    self._spawnable = spawnable
    return self
end

--- Whether only admins can spawn the entity from the spawn menu.
-- @param adminOnly (boolean): Defaults to false.
function EntityMeta:SetAdminOnly(adminOnly)
    _assert(_type(adminOnly) == 'boolean', 'DanLib Entity:SetAdminOnly — adminOnly must be a boolean')
    self._adminOnly = adminOnly
    return self
end

--- Enables/disables automatic frame advance for animated entities.
-- Required for 'ai' type entities with animations.
-- @param enabled (boolean): Defaults to false.
function EntityMeta:SetAutoFrameAdvance(enabled)
    _assert(_type(enabled) == 'boolean', 'DanLib Entity:SetAutoFrameAdvance — enabled must be a boolean')
    self._autoFrameAdvance = enabled
    return self
end

--- Declares a NetworkVar to be registered in SetupDataTables.
-- Equivalent to calling self:NetworkVar(varType, index, name) inside SetupDataTables.
-- @param varType (string): 'String', 'Int', 'Float', 'Bool', 'Entity', 'Vector', 'Angle'.
-- @param index (number): Slot index (0–31 depending on type).
-- @param name (string): Variable name — getter/setter become Get<Name>/Set<Name>.
-- @example
--      ENT_DEF:AddNetworkVar('String', 0, 'NPCKey')
--      -- Generates: ent:GetNPCKey() / ent:SetNPCKey(val)
function EntityMeta:AddNetworkVar(varType, index, name)
    _assert(_type(varType) == 'string', 'DanLib Entity:AddNetworkVar — varType must be a string')
    _assert(_type(index) == 'number', 'DanLib Entity:AddNetworkVar — index must be a number')
    _assert(_type(name) == 'string', 'DanLib Entity:AddNetworkVar — name must be a string')
    self._networkVars = self._networkVars or { }
    self._networkVars[#self._networkVars + 1] = {
        varType = varType,
        index = index,
        name = name
    }
    return self
end

--- Provides a fully custom SetupDataTables function, replacing the auto-generated one.
-- Use this when you need finer control (e.g. KeyDataTable, custom subtable splits).
-- If both AddNetworkVar and SetupDataTables are called, the custom fn takes precedence.
-- @param fn (function): Receives (self) — the entity instance.
function EntityMeta:SetupDataTables(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:SetupDataTables — fn must be a function')
    self._setupDataTables = fn
    return self
end

--- Registers a callback for when a specific NetworkVar changes (client-side).
-- GMod calls ENT:On<VarName>Changed(varname, oldval, newval) automatically.
-- @param varName (string): The variable name (e.g. 'NPCKey' → 'OnNPCKeyChanged').
-- @param fn (function): Receives (self, varname, oldval, newval).
-- @example
--      ENT_DEF:OnNetVarChanged('NPCKey', function(self, varname, old, new)
--          self.AnimationSet = false
--      end)
function EntityMeta:OnNetVarChanged(varName, fn)
    _assert(_type(varName) == 'string', 'DanLib Entity:OnNetVarChanged — varName must be a string')
    _assert(_type(fn) == 'function', 'DanLib Entity:OnNetVarChanged — fn must be a function')
    self._netVarListeners = self._netVarListeners or { }
    self._netVarListeners[varName] = fn
    return self
end

--- Adds a custom method to the ENT table, accessible as self:<name>() at runtime.
-- Use for entity-specific helpers that don't map to a built-in GMod callback.
-- @param name (string): Method name (e.g. 'SetNPCKey', 'ApplyAnimation').
-- @param fn (function): Receives (self, ...) — the entity instance plus any args.
-- @example
--      ENT_DEF:AddMethod('SetNPCKey', function(self, key)
--          self:SetNPCKeyVar(key)
--      end)
function EntityMeta:AddMethod(name, fn)
    _assert(_type(name) == 'string', 'DanLib Entity:AddMethod — name must be a string')
    _assert(_type(fn) == 'function', 'DanLib Entity:AddMethod — fn must be a function')
    self._customMethods = self._customMethods or { }
    self._customMethods[name] = fn
    return self
end

--- Called on the SERVER when the entity is first created.
-- @param fn (function): Receives (self).
function EntityMeta:OnServerInitialize(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:OnServerInitialize — fn must be a function')
    self._onServerInitialize = fn
    return self
end

--- Called every server tick while the entity is alive.
-- Return true at the end to re-queue Think.
-- @param fn (function): Receives (self).
function EntityMeta:OnServerThink(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:OnServerThink — fn must be a function')
    self._onServerThink = fn
    return self
end

--- Called when the entity takes damage (server).
-- @param fn (function): Receives (self, dmgInfo). Return 0 to block damage.
function EntityMeta:OnTakeDamage(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:OnTakeDamage — fn must be a function')
    self._onTakeDamage = fn
    return self
end

--- Called when a player activates the entity via USE or map I/O (server).
-- Signature matches GMod ENT:AcceptInput(inputName, activator, caller, data).
-- @param fn (function): Receives (self, inputName, activator, caller, data).
function EntityMeta:OnAcceptInput(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:OnAcceptInput — fn must be a function')
    self._onAcceptInput = fn
    return self
end

--- Called when the entity is removed (shared — fires on both server and client).
-- @param fn (function): Receives (self).
function EntityMeta:OnRemove(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:OnRemove — fn must be a function')
    self._onRemove = fn
    return self
end

--- Called on the CLIENT when the entity is first created.
-- @param fn (function): Receives (self).
function EntityMeta:OnClientInitialize(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:OnClientInitialize — fn must be a function')
    self._onClientInitialize = fn
    return self
end

--- Called on the CLIENT every frame for the entity's Think loop.
-- @param fn (function): Receives (self).
function EntityMeta:OnClientThink(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:OnClientThink — fn must be a function')
    self._onClientThink = fn
    return self
end

--- Called every frame to draw the entity (client).
-- @param fn (function): Receives (self).
function EntityMeta:OnClientDraw(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:OnClientDraw — fn must be a function')
    self._onClientDraw = fn
    return self
end

--- Called every frame to draw translucent parts of the entity (client).
-- @param fn (function): Receives (self).
function EntityMeta:OnClientDrawTranslucent(fn)
    _assert(_type(fn) == 'function', 'DanLib Entity:OnClientDrawTranslucent — fn must be a function')
    self._onClientDrawTranslucent = fn
    return self
end

--- Builds the ENT table and commits it to GMod's scripted entity system.
--
-- Two registration modes (detected automatically):
--   • Entity-folder context — GMod pre-creates a global `ENT` table before including
--     shared.lua/init.lua/cl_init.lua. When Register() is called from inside one of
--     those files the factory detects the global and MERGES into it. GMod then calls
--     scripted_ents.Register(ENT, class) automatically at the end of folder loading.
--   • Standalone context — called from any autoloaded DanLib file (e.g. core/shared/).
--     No global ENT exists, so the factory calls scripted_ents.Register directly.
--
-- This dual-mode approach means the factory works both from the conventional
-- lua/entities/ folder layout AND from DanLib's own autoload path without conflicts.
-- @return (nil)
function EntityMeta:Register()
    local class = self.ID
    _assert(_type(class) == 'string' and #class > 0, 'DanLib Entity:Register — entity ID must be a non-empty string')

    -- Use a non-shadowing name so we can inspect the global ENT below.
    local entDef = { }
    local ENT = entDef  -- alias used by the closures below

    -- Static properties
    ENT.Type = self._type or 'anim'
    ENT.Base = self._base or 'base_entity'
    ENT.PrintName = self._printName or class
    ENT.Category = self._category or 'DDI'
    ENT.Author = self._author or ''
    ENT.Contact = self._contact or ''
    ENT.Spawnable = self._spawnable or false
    ENT.AdminOnly = self._adminOnly or false
    ENT.AutomaticFrameAdvance = self._autoFrameAdvance or false

    -- SetupDataTables
    if self._setupDataTables then
        -- Fully custom implementation takes precedence.
        ENT.SetupDataTables = self._setupDataTables
    elseif (self._networkVars and #self._networkVars > 0) then
        local vars = self._networkVars
        function ENT:SetupDataTables()
            for _, v in _pairs(vars) do
                self:NetworkVar(v.varType, v.index, v.name)
            end
        end
    end

    -- Initialize
    local defModel = self._model
    local serverInitFn = self._onServerInitialize
    local clientInitFn = self._onClientInitialize

    if (defModel or serverInitFn or clientInitFn) then
        function ENT:Initialize()
            if SERVER then
                if defModel then
                    self:SetModel(defModel)
                end

                if serverInitFn then
                    serverInitFn(self)
                end
            elseif CLIENT then
                if clientInitFn then
                    clientInitFn(self)
                end
            end
        end
    end

    -- Think
    local serverThinkFn = self._onServerThink
    local clientThinkFn = self._onClientThink

    if serverThinkFn or clientThinkFn then
        function ENT:Think()
            if (SERVER and serverThinkFn) then
                return serverThinkFn(self)
            elseif (CLIENT and clientThinkFn) then
                return clientThinkFn(self)
            end
        end
    end

    -- Server-only callbacks
    if self._onAcceptInput then
        local fn = self._onAcceptInput
        function ENT:AcceptInput(inputName, activator, caller, data)
            return fn(self, inputName, activator, caller, data)
        end
    end

    if self._onTakeDamage then
        ENT.OnTakeDamage = self._onTakeDamage
    end

    -- Shared callbacks
    if self._onRemove then
        ENT.OnRemove = self._onRemove
    end

    -- Client-only callbacks
    if self._onClientDraw then
        ENT.Draw = self._onClientDraw
    end

    if self._onClientDrawTranslucent then
        ENT.DrawTranslucent = self._onClientDrawTranslucent
    end

    -- NetworkVar change listeners
    if self._netVarListeners then
        for varName, fn in _pairs(self._netVarListeners) do
            ENT['On' .. varName .. 'Changed'] = fn
        end
    end

    -- Custom methods
    if self._customMethods then
        for name, fn in _pairs(self._customMethods) do
            ENT[name] = fn
        end
    end

    -- Commit
    -- Detect whether we are inside GMod's entity-folder loading context.
    -- GMod sets the global `ENT` table before including shared/init/cl_init files,
    -- then calls scripted_ents.Register(ENT, class) automatically afterwards.
    -- In that context we MERGE into the global table so GMod registers our definition.
    -- Outside that context (e.g. called from autorun / DanLib core/) we register directly.
    if (_G.ENT ~= nil) then
        for k, v in _pairs(entDef) do
            _G.ENT[k] = v
        end
    else
        scripted_ents.Register(entDef, class)
    end

    DanLib.ModulesMetaEntity = DanLib.ModulesMetaEntity or { }
    DanLib.ModulesMetaEntity[class] = self
end

--- Creates a new entity definition object.
-- @param id (string): Unique entity class name (e.g. 'danlib_my_prop').
-- @return EntityMeta
function DBase.CreateEntity(id)
    _assert(_type(id) == 'string' and #id > 0, 'DanLib.Func.CreateEntity — id must be a non-empty string')
    local def = {
        ID = id
    }
    setmetatable(def, EntityMeta)
    return def
end

--- Returns the registered entity definition object for a given class name.
-- Returns nil if the entity was not registered via DanLib.Func.CreateEntity.
-- @param id (string): Entity class name (e.g. 'danlib_my_prop').
-- @return EntityMeta|nil
function DBase.GetEntity(id)
    _assert(_type(id) == 'string' and #id > 0, 'DanLib.Func.GetEntity — id must be a non-empty string')
    return (DanLib.ModulesMetaEntity or { })[id]
end

--- Returns the full table of all entity definitions registered via this factory.
-- @return table<string, EntityMeta>
function DBase.GetAllEntities()
    return DanLib.ModulesMetaEntity or { }
end
