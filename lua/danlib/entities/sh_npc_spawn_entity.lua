/***
 *   @addon         DanLib
 *   @component     danlib_npc_spawn
 *   @license       MIT License
 *   @version       2.1.0
 *   @release_date  25/06/2026
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   Decorative NPC entity for DanLib. A stationary animated model that:
 *                    - Tracks the nearest player's head position smoothly (CLIENT)
 *                    - Loads model and animation from DanLib.CONFIG.BASE.NPCs config
 *                    - Persists its animation sequence against the AI base override (SERVER)
 *                    - Shows a tooltip when a player is within 250 units (CLIENT)
 *                    - Handles player interaction via AcceptInput (rate-limited, SERVER)
 *                    - Blocks all incoming damage
 *
 *   @attributes
 *                  Type : ai
 *                  Base : base_ai
 *                  Spawnable : false (admin-placed only via npc_spaw SWEP)
 *                  NetworkVar : String[0] NPCKeyVar — identifies which NPC config to use
 *
 *   @usage
 *                  -- Placed automatically by sv_npc_spawns.lua on map load.
 *                  -- Manually placed via the npc_spaw SWEP (admin only).
 *                  local npc = ents.Create('danlib_npc_spawn')
 *                  npc:SetPos(pos)
 *                  npc:SetAngles(ang)
 *                  npc:Spawn()
 *                  npc:SetNPCKey('my_npc_key')
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         This is the single source-of-truth for the danlib_npc_spawn entity.
 *                  lua/entities/danlib_npc_spawn/ stubs include this file; all logic lives here.
 */



-- CLIENT-side locals — safe to declare in shared context; all usage is inside
-- CLIENT-guarded callbacks so they are never called on the server.
local _IsValid = IsValid
local _CurTime = CurTime
local _FrameTime = FrameTime
local _mathApproach = math.Approach
local _mathNormalizeAngle = math.NormalizeAngle
local _DIST_SQR = 250 * 250  -- Head-tracking activation radius²

local ENT_DEF = DanLib.Func.CreateEntity('danlib_npc_spawn')
ENT_DEF:SetType('ai')
ENT_DEF:SetBase('base_ai')
ENT_DEF:SetPrintName('NPC Spawn Point')
ENT_DEF:SetCategory('[DDI] NPC Spawns')
ENT_DEF:SetAuthor('denchik')
ENT_DEF:SetSpawnable(false)
ENT_DEF:SetAutoFrameAdvance(true)

-- Identifies which DanLib.CONFIG.BASE.NPCs entry this entity represents.
-- Getter: ent:GetNPCKeyVar()
-- Setter: ent:SetNPCKeyVar(key)
ENT_DEF:AddNetworkVar('String', 0, 'NPCKeyVar')

-- Server Initialisation
ENT_DEF:OnServerInitialize(function(self)
    self:SetModel('models/breen.mdl') -- Default until SetNPCKey is called
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_PLAYER)

    self.CachedAnimation = nil -- Animation name string from config
    self.LastAppliedSequence = -1 -- Sequence index for hold-loop in Think
end)

-- Client Initialisation
ENT_DEF:OnClientInitialize(function(self)
    self.Distance = 0 -- (unused, reserved for future proximity effects)
    self.NextThinkTime = 0 -- Throttle: next time to update tracking target

    self.CachedPlayer = nil -- Cached LocalPlayer() reference

    -- Smooth head-tracking state
    self.TargetYaw = 0 -- Desired yaw angle towards player
    self.CurrentYaw = 0 -- Interpolated current yaw (fed to pose parameter)

    -- Animation and config cache
    self.NPCConfig = nil -- DanLib.CONFIG.BASE.NPCs[key] for current key
    self.LastNPCKey = '' -- Last known NPCKeyVar value (change detection)
    self.AnimationSet = false -- Whether the animation sequence has been applied
    self.TooltipSet = false -- Whether SetEntityTooltip has been called
end)

--- Assigns the NPC config key, updates the model, and schedules the animation.
-- Call this after Spawn() to configure which NPC this entity represents.
-- @param key (string): A key from DanLib.CONFIG.BASE.NPCs (e.g. 'merchant').
ENT_DEF:AddMethod('SetNPCKey', function(self, key)
    self:SetNPCKeyVar(key)

    local config = DanLib.CONFIG.BASE.NPCs[key]
    if config then
        if config.Model then
            self:SetModel(config.Model)
        end

        self.CachedAnimation = config.Animation

        -- Slight delay lets the model finish loading before we sequence it
        DanLib.Timer:Simple(0.05, function()
            if _IsValid(self) then
                self:ApplyAnimation()
            end
        end)
    else
        self:SetModel('models/breen.mdl')
        self.CachedAnimation = nil
    end
end)

--- Forces the entity to play its configured idle animation.
-- Safe to call multiple times; re-caches the animation name from config when needed.
-- Called automatically by SetNPCKey and by sv_npc_spawns.lua after map cleanup.
ENT_DEF:AddMethod('ApplyAnimation', function(self)
    -- Re-cache animation name if lost (e.g. after a reload)
    if (not self.CachedAnimation) then
        local npcKey = self:GetNPCKeyVar()
        if (npcKey and npcKey ~= '') then
            local config = DanLib.CONFIG.BASE.NPCs[npcKey]
            if config then
                self.CachedAnimation = config.Animation
            end
        end
    end

    if self.CachedAnimation then
        local anim = self:LookupSequence(self.CachedAnimation)
        if (anim and anim > 0) then
            self:ResetSequence(anim)
            self.LastAppliedSequence = anim
        end
    end
end)

-- Holds the animation sequence — base_ai would otherwise reset it every tick.
-- Re-checks every 0.5 s to keep CPU usage low.
ENT_DEF:OnServerThink(function(self)
    if (self.LastAppliedSequence and self.LastAppliedSequence > 0) then
        if (self:GetSequence() ~= self.LastAppliedSequence) then
            self:ResetSequence(self.LastAppliedSequence)
        end
    end

    self:NextThink(_CurTime() + 0.5)
    return true
end)

-- Two responsibilities:
--   1. Apply animation + tooltip when NPCKeyVar changes or is first received
--   2. Smooth head-tracking towards the local player at 10 Hz, interpolated every frame
ENT_DEF:OnClientThink(function(self)
    local npcKey = self:GetNPCKeyVar() or ''
    -- Re-apply whenever the key changes or the animation was lost
    if (npcKey ~= '' and (npcKey ~= self.LastNPCKey or not self.AnimationSet)) then
        self.NPCConfig = DanLib.CONFIG.BASE.NPCs[npcKey]
        self.LastNPCKey = npcKey
        self.AnimationSet = false

        if (self.NPCConfig and self.NPCConfig.Animation) then
            local anim = self:LookupSequence(self.NPCConfig.Animation)
            if (anim and anim > 0) then
                self:ResetSequence(anim)
                self.AnimationSet = true
            end
        end

        if (self.NPCConfig and not self.TooltipSet) then
            self:SetEntityTooltip({
                title = self.NPCConfig.Name or 'Unknown NPC',
                icon = 'BGCpqAF',
                distance = 250,
            })
            self.TooltipSet = true
        end
    end

    -- Update head-tracking target at 10 Hz (throttled)
    local curTime = _CurTime()
    if (curTime >= self.NextThinkTime) then
        self.NextThinkTime = curTime + 0.1

        if (not _IsValid(self.CachedPlayer)) then
            self.CachedPlayer = LocalPlayer()
        end

        local pPlayer = self.CachedPlayer
        -- Skip tracking if player is outside activation radius
        if (pPlayer:GetPos():DistToSqr(self:GetPos()) > _DIST_SQR) then
            self.TargetYaw = 0
            if (self.Distance ~= 0) then
                self.Distance = 0
            end
            return
        end

        local pPos = pPlayer:EyePos()
        local yaw = _mathNormalizeAngle((pPos - self:EyePos()):Angle().y - self:GetAngles().y)
        self.TargetYaw = yaw
        self:SetEyeTarget(pPos)
    end

    -- Interpolate head pose every frame for smooth 60-FPS rotation
    self.CurrentYaw = _mathApproach(self.CurrentYaw, self.TargetYaw, _FrameTime() * 120)
    self:SetPoseParameter('head_yaw', self.CurrentYaw)
end)

-- Client Draw
ENT_DEF:OnClientDraw(function(self)
    self:DrawModel()
end)

-- Reset all cached state when the server sends a new NPC key.
-- Triggers re-application of animation and tooltip on the next Think frame.
ENT_DEF:OnNetVarChanged('NPCKeyVar', function(self, varname, oldval, newval)
    self.AnimationSet = false
    self.LastNPCKey = ''
    self.NPCConfig = nil
    self.TooltipSet = false
end)

-- Rate-limited to 1 activation per second per actor to prevent spam.
-- Delegates to the FuncType handler registered in DanLib.BaseConfig.EntityTypesFunc.
ENT_DEF:OnAcceptInput(function(self, inputName, activator, caller, data)
    local actor = _IsValid(activator) and activator or caller
    if (not _IsValid(actor)) then
        return
    end

    if (actor.timer or 0) > _CurTime() then
        return
    end
    actor.timer = _CurTime() + 1

    local npcKey = self:GetNPCKeyVar()
    if (not npcKey or not DanLib.CONFIG.BASE.NPCs[npcKey]) then
        return
    end

    local config = DanLib.CONFIG.BASE.NPCs[npcKey]
    local typeTable = DanLib.BaseConfig.EntityTypesFunc[config.FuncType or '']

    if (typeTable and typeTable.UseFunc) then
        typeTable.UseFunc(actor, self, npcKey)
    end
end)

-- Completely block all damage — the NPC is a decorative prop, not a combatant.
ENT_DEF:OnTakeDamage(function(self, dmgInfo)
    return 0
end)

--  Register
ENT_DEF:Register()
