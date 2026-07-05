/***
 *   @addon         DanLib
 *   @component     Weapon Factory
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
 *   @description   Weapon (SWEP) factory for DanLib. Provides a fluent meta-based API
 *                  for defining and registering scripted weapons.
 *                  Follows the same factory pattern as DanLib.Func.CreateLogs and
 *                  DanLib.Func.CreateModule.
 *
 *                  Supports two registration modes (auto-detected):
 *                    • lua/weapons/ context — GMod pre-creates global SWEP; Register()
 *                      merges the definition into it so GMod registers automatically.
 *                    • Standalone context (DanLib core files) — Register() calls
 *                      weapons.Register() directly.
 *
 *                  Supports:
 *                    - Full SWEP identity (PrintName, Base, Category, Author, etc.)
 *                    - Client HUD flags (Slot, SlotPos, DrawAmmo, DrawCrosshair)
 *                    - Primary / Secondary fire configs
 *                    - All standard SWEP callbacks
 *                    - Custom methods via AddMethod
 *                    - Server networking helpers (AddNetworkString, OnNetReceive)
 *                    - PostDrawViewModel HUD rendering
 *
 *   @usage
 *                  local WEP = DanLib.Func.CreateWeapon('my_tool')
 *                  WEP:SetPrintName('My Tool')
 *                  WEP:SetModel('models/weapons/w_pistol.mdl')
 *                  WEP:SetAdminOnly(true)
 *                  WEP:OnPrimaryAttack(function(self) ... end)
 *                  WEP:Register()
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase  = DanLib.Func
local _assert = assert
local _type = type
local _pairs = pairs

-- WeaponMeta — fluent definition object returned by CreateWeapon().
-- Methods set properties and callbacks; Register() commits to GMod.
local WeaponMeta = { }
WeaponMeta.__index = WeaponMeta

--- Sets the base SWEP class to inherit from.
-- @param base (string): e.g. 'weapon_base'. Defaults to 'weapon_base'.
function WeaponMeta:SetBase(base)
    _assert(_type(base) == 'string', 'DanLib Weapon:SetBase — base must be a string')
    self._base = base
    return self
end

--- Sets the display name shown in HUD and inventory.
-- @param name (string)
function WeaponMeta:SetPrintName(name)
    _assert(_type(name) == 'string', 'DanLib Weapon:SetPrintName — name must be a string')
    self._printName = name
    return self
end

--- Sets the spawn menu category.
-- @param category (string): Defaults to 'DanLib'.
function WeaponMeta:SetCategory(category)
    _assert(_type(category) == 'string', 'DanLib Weapon:SetCategory — category must be a string')
    self._category = category
    return self
end

--- Sets the world model path.
-- @param model (string): e.g. 'models/weapons/w_pistol.mdl'.
function WeaponMeta:SetModel(model)
    _assert(_type(model) == 'string', 'DanLib Weapon:SetModel — model must be a string')
    self._model = model
    return self
end

--- Sets the view (first-person) model path.
-- @param model (string): e.g. 'models/weapons/v_pistol.mdl'.
function WeaponMeta:SetViewModel(model)
    _assert(_type(model) == 'string', 'DanLib Weapon:SetViewModel — model must be a string')
    self._viewModel = model
    return self
end

--- Sets the author name shown in the spawn menu.
-- @param author (string)
function WeaponMeta:SetAuthor(author)
    _assert(_type(author) == 'string', 'DanLib Weapon:SetAuthor — author must be a string')
    self._author = author
    return self
end

--- Sets the contact string shown in the spawn menu.
-- @param contact (string)
function WeaponMeta:SetContact(contact)
    _assert(_type(contact) == 'string', 'DanLib Weapon:SetContact — contact must be a string')
    self._contact = contact
    return self
end

--- Sets the purpose description shown in the spawn menu.
-- @param purpose (string)
function WeaponMeta:SetPurpose(purpose)
    _assert(_type(purpose) == 'string', 'DanLib Weapon:SetPurpose — purpose must be a string')
    self._purpose = purpose
    return self
end

--- Sets the instructions string shown in the spawn menu.
-- @param instructions (string)
function WeaponMeta:SetInstructions(instructions)
    _assert(_type(instructions) == 'string', 'DanLib Weapon:SetInstructions — instructions must be a string')
    self._instructions = instructions
    return self
end

--- Controls whether the weapon appears in the spawn menu.
-- @param spawnable (boolean): Defaults to true.
function WeaponMeta:SetSpawnable(spawnable)
    _assert(_type(spawnable) == 'boolean', 'DanLib Weapon:SetSpawnable — spawnable must be a boolean')
    self._spawnable = spawnable
    return self
end

--- Restricts the weapon to admins only in the spawn menu.
-- @param adminOnly (boolean): Defaults to false.
function WeaponMeta:SetAdminOnly(adminOnly)
    _assert(_type(adminOnly) == 'boolean', 'DanLib Weapon:SetAdminOnly — adminOnly must be a boolean')
    self._adminOnly = adminOnly
    return self
end

--- Sets the weapon slot in the HUD selection bar (CLIENT).
-- @param slot (number): 0-based slot index (e.g. 1 for secondary slot).
function WeaponMeta:SetSlot(slot)
    _assert(_type(slot) == 'number', 'DanLib Weapon:SetSlot — slot must be a number')
    self._slot = slot
    return self
end

--- Sets the weapon position within its HUD slot (CLIENT).
-- @param pos (number): Position index within the slot.
function WeaponMeta:SetSlotPos(pos)
    _assert(_type(pos) == 'number', 'DanLib Weapon:SetSlotPos — pos must be a number')
    self._slotPos = pos
    return self
end

--- Whether to show the ammo counter in the HUD (CLIENT).
-- @param draw (boolean): Defaults to true.
function WeaponMeta:SetDrawAmmo(draw)
    _assert(_type(draw) == 'boolean', 'DanLib Weapon:SetDrawAmmo — draw must be a boolean')
    self._drawAmmo = draw
    return self
end

--- Whether to draw the default crosshair while this weapon is active (CLIENT).
-- @param draw (boolean): Defaults to true.
function WeaponMeta:SetDrawCrosshair(draw)
    _assert(_type(draw) == 'boolean', 'DanLib Weapon:SetDrawCrosshair — draw must be a boolean')
    self._drawCrosshair = draw
    return self
end

--- Configures the primary fire attack mode.
-- @param config (table): { ClipSize, DefaultClip, Automatic, Ammo }
--   ClipSize (number): Magazine capacity. -1 = no clip.
--   DefaultClip (number):  Starting ammo count.
--   Automatic (boolean): true = hold to fire.
--   Ammo (string):  Ammo type name (e.g. 'Pistol', 'SMG1', '357').
function WeaponMeta:SetPrimary(config)
    _assert(_type(config) == 'table', 'DanLib Weapon:SetPrimary — config must be a table')
    self._primary = config
    return self
end

--- Configures the secondary fire attack mode.
-- @param config (table): Same shape as SetPrimary.
function WeaponMeta:SetSecondary(config)
    _assert(_type(config) == 'table', 'DanLib Weapon:SetSecondary — config must be a table')
    self._secondary = config
    return self
end

--- Adds a custom method to the SWEP table, accessible as self:<name>() at runtime.
-- Use for weapon-specific helpers that don't map to a built-in GMod SWEP callback.
-- @param name (string): Method name (e.g. 'CreateModel', 'FireBullet').
-- @param fn (function): Receives (self, ...) — the SWEP entity plus any args.
-- @example
--      WEP:AddMethod('CreateModel', function(self)
--          self.model = ClientsideModel('models/...')
--      end)
function WeaponMeta:AddMethod(name, fn)
    _assert(_type(name) == 'string', 'DanLib Weapon:AddMethod — name must be a string')
    _assert(_type(fn) == 'function', 'DanLib Weapon:AddMethod — fn must be a function')
    self._customMethods = self._customMethods or { }
    self._customMethods[name] = fn
    return self
end

--- Called on SERVER when the weapon is first equipped by a player.
-- Use for server-side state setup (e.g. setting NW2 vars, registering think hooks).
-- @param fn (function): Receives (self) — the SWEP entity.
function WeaponMeta:OnServerInitialize(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnServerInitialize — fn must be a function')
    self._onServerInitialize = fn
    return self
end

--- Called on CLIENT when the weapon is first equipped by the local player.
-- Use for client-side setup (e.g. creating clientside models, registering HUD hooks).
-- @param fn (function): Receives (self) — the SWEP entity.
function WeaponMeta:OnClientInitialize(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnClientInitialize — fn must be a function')
    self._onClientInitialize = fn
    return self
end

--- Called every SERVER tick while the weapon is held.
-- @param fn (function): Receives (self).
function WeaponMeta:OnServerThink(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnServerThink — fn must be a function')
    self._onServerThink = fn
    return self
end

--- Called every CLIENT frame while the weapon is held.
-- @param fn (function): Receives (self).
function WeaponMeta:OnClientThink(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnClientThink — fn must be a function')
    self._onClientThink = fn
    return self
end

--- Called every tick while the weapon is held (SHARED — both server and client).
-- Prefer OnServerThink / OnClientThink for side-specific logic.
-- @param fn (function): Receives (self).
function WeaponMeta:OnThink(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnThink — fn must be a function')
    self._onThink = fn
    return self
end

--- Called when the player presses the primary fire button.
-- @param fn (function): Receives (self). self is the SWEP entity.
function WeaponMeta:OnPrimaryAttack(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnPrimaryAttack — fn must be a function')
    self._onPrimaryAttack = fn
    return self
end

--- Called when the player presses the secondary fire button.
-- @param fn (function): Receives (self).
function WeaponMeta:OnSecondaryAttack(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnSecondaryAttack — fn must be a function')
    self._onSecondaryAttack = fn
    return self
end

--- Called when the player presses the reload button.
-- @param fn (function): Receives (self).
function WeaponMeta:OnReload(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnReload — fn must be a function')
    self._onReload = fn
    return self
end

--- Called when the weapon is deployed (switched to).
-- Return true to suppress the default deploy animation.
-- @param fn (function): Receives (self).
function WeaponMeta:OnDeploy(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnDeploy — fn must be a function')
    self._onDeploy = fn
    return self
end

--- Called when the weapon is holstered (switched away from).
-- Return true to allow holstering.
-- @param fn (function): Receives (self).
function WeaponMeta:OnHolster(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnHolster — fn must be a function')
    self._onHolster = fn
    return self
end

--- Called every tick while the weapon is held (shared — runs on both sides).
-- @param fn (function): Receives (self).
function WeaponMeta:OnThink(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnThink — fn must be a function')
    self._onThink = fn
    return self
end

--- Called when the weapon entity is removed.
-- @param fn (function): Receives (self).
function WeaponMeta:OnRemove(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnRemove — fn must be a function')
    self._onRemove = fn
    return self
end

--- Called every frame to draw custom HUD elements while this weapon is active (CLIENT).
-- @param fn (function): Receives (self).
function WeaponMeta:OnDrawHUD(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnDrawHUD — fn must be a function')
    self._onDrawHUD = fn
    return self
end

--- Called every frame to draw the world model (CLIENT).
-- @param fn (function): Receives (self).
function WeaponMeta:OnDraw(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnDraw — fn must be a function')
    self._onDraw = fn
    return self
end

--- Called after the view model is drawn while this weapon is active (CLIENT).
-- Use for cam.Start3D2D panels, bone-attached effects, etc.
-- @param fn (function): Receives (self, viewModel, weapon).
function WeaponMeta:OnPostDrawViewModel(fn)
    _assert(_type(fn) == 'function', 'DanLib Weapon:OnPostDrawViewModel — fn must be a function')
    self._onPostDrawViewModel = fn
    return self
end

--- Builds the SWEP table and commits it to GMod's weapon system.
--
-- Two registration modes (detected automatically):
--   • lua/weapons/ context — GMod pre-creates global SWEP before including the file.
--     Register() detects this and MERGES the definition into the global so GMod
--     registers it automatically at the end of file loading.
--   • Standalone context (DanLib core files) — no global SWEP exists; Register()
--     calls weapons.Register() directly.
-- @return (nil)
function WeaponMeta:Register()
    local class = self.ID
    _assert(_type(class) == 'string' and #class > 0, 'DanLib Weapon:Register — weapon ID must be a non-empty string')

    local swepDef = { }
    local SWEP = swepDef -- alias used by closures

    --  Identity
    SWEP.Base = self._base or 'weapon_base'
    SWEP.PrintName = self._printName or class
    SWEP.Category = self._category or 'DanLib'
    SWEP.Author = self._author or ''
    SWEP.Contact = self._contact or ''
    SWEP.Purpose = self._purpose or ''
    SWEP.Instructions = self._instructions or ''
    SWEP.Spawnable = self._spawnable == nil and true or self._spawnable
    SWEP.AdminOnly = self._adminOnly or false

    if self._model then
        SWEP.WorldModel = self._model
    end

    if self._viewModel then
        SWEP.ViewModel = self._viewModel
    end

    -- Client HUD flags
    if (self._slot ~= nil) then
        SWEP.Slot = self._slot
    end

    if (self._slotPos ~= nil) then
        SWEP.SlotPos = self._slotPos
    end

    if (self._drawAmmo ~= nil) then
        SWEP.DrawAmmo = self._drawAmmo
    end

    if (self._drawCrosshair ~= nil) then
        SWEP.DrawCrosshair = self._drawCrosshair
    end

    -- Fire configs
    SWEP.Primary = self._primary or {
        ClipSize = -1,
        DefaultClip = -1,
        Automatic = false,
        Ammo = '',
    }

    SWEP.Secondary = self._secondary or {
        ClipSize = -1,
        DefaultClip = -1,
        Automatic = false,
        Ammo = '',
    }

    -- Initialize (Deploy is GMod's "weapon equipped" hook)
    local serverInitFn = self._onServerInitialize
    local clientInitFn = self._onClientInitialize

    if serverInitFn or clientInitFn then
        function SWEP:Initialize()
            if (SERVER and serverInitFn) then
                serverInitFn(self)
            elseif (CLIENT and clientInitFn) then
                clientInitFn(self)
            end
        end
    end

    -- Think — shared, server-only, or client-only
    local sharedThinkFn = self._onThink
    local serverThinkFn = self._onServerThink
    local clientThinkFn = self._onClientThink

    if (sharedThinkFn or serverThinkFn or clientThinkFn) then
        function SWEP:Think()
            if sharedThinkFn then
                sharedThinkFn(self)
            elseif (SERVER and serverThinkFn) then
                serverThinkFn(self)
            elseif (CLIENT and clientThinkFn) then
                clientThinkFn(self)
            end
        end
    end

    -- Standard callbacks
    if self._onPrimaryAttack then
        SWEP.PrimaryAttack = self._onPrimaryAttack
    end

    if self._onSecondaryAttack then
        SWEP.SecondaryAttack = self._onSecondaryAttack
    end

    if self._onReload then
        SWEP.Reload = self._onReload
    end

    if self._onDeploy then
        SWEP.Deploy = self._onDeploy
    end

    if self._onHolster then
        SWEP.Holster = self._onHolster
    end

    if self._onRemove then
        SWEP.OnRemove = self._onRemove
    end

    if self._onDrawHUD then
        SWEP.DrawHUD = self._onDrawHUD
    end

    if self._onDraw then
        SWEP.Draw = self._onDraw
    end

    if self._onPostDrawViewModel then
        SWEP.PostDrawViewModel = self._onPostDrawViewModel
    end

    -- Custom methods
    if self._customMethods then
        for name, fn in _pairs(self._customMethods) do
            SWEP[name] = fn
        end
    end

    -- Detect whether we are inside GMod's lua/weapons/ loading context.
    -- GMod pre-creates the global SWEP table before including weapon files,
    -- then calls weapons.Register(SWEP, class) automatically afterwards.
    -- In that context we MERGE into the global so GMod registers our definition.
    -- Outside that context we register directly.
    if (_G.SWEP ~= nil) then
        for k, v in _pairs(swepDef) do
            _G.SWEP[k] = v
        end
    else
        weapons.Register(swepDef, class)
    end

    DanLib.ModulesMetaWeapon = DanLib.ModulesMetaWeapon or { }
    DanLib.ModulesMetaWeapon[class] = self
end

--- Creates a new weapon definition object.
-- @param id (string): Unique SWEP class name (e.g. 'danlib_pistol').
-- @return WeaponMeta
function DBase.CreateWeapon(id)
    _assert(_type(id) == 'string' and #id > 0, 'DanLib.Func.CreateWeapon — id must be a non-empty string')
    local def = {
        ID = id
    }
    setmetatable(def, WeaponMeta)
    return def
end

--- Returns the registered weapon definition object for a given class name.
-- Returns nil if the weapon was not registered via DanLib.Func.CreateWeapon.
-- @param id (string): SWEP class name (e.g. 'danlib_pistol').
-- @return WeaponMeta|nil
function DBase.GetWeapon(id)
    _assert(_type(id) == 'string' and #id > 0, 'DanLib.Func.GetWeapon — id must be a non-empty string')
    return (DanLib.ModulesMetaWeapon or { })[id]
end

--- Returns the full table of all weapon definitions registered via this factory.
-- @return table<string, WeaponMeta>
function DBase.GetAllWeapons()
    return DanLib.ModulesMetaWeapon or { }
end
