/***
 *   @addon         DanLib
 *   @component     NPCSpawnTool (SWEP)
 *   @license       MIT License
 *   @version       2.0.0
 *   @release_date  25/06/2026
 *   @author        denchik
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   Admin SWEP for placing and removing danlib_npc_spawn entities.
 *                  Defined using DanLib.Func.CreateWeapon factory.
 *
 *   @functions
 *                    - Smooth 60 FPS animated model preview (LerpVector interpolation)
 *                    - Distance-based spawn restriction (MAX_SPAWN_DISTANCE = 500 units)
 *                    - Surface validation (floor only, normal.z > 0.7)
 *                    - Color-coded preview: green = valid, orange = too far, red = invalid
 *                    - Right-click NPC removal with persistent spawn-data cleanup
 *                    - [R] key opens NPC type selector via DanLib.Func.ComboRequestPopup
 *                    - In-world instruction panel on viewmodel bone via cam.Start3D2D
 *
 *   @attributes
 *                  Spawnable : true (admin only)
 *                  AdminOnly : true
 *                  ViewModel : models/weapons/v_pistol.mdl
 *                  WorldModel: models/weapons/w_pistol.mdl
 *                  Slot : 1  | SlotPos: 1
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DNet = DanLib.Net
local DNetworkUtil = DanLib.NetworkUtil

local _IsValid = IsValid
local _CurTime = CurTime
local _FrameTime = FrameTime
local _Vector = Vector
local _Angle = Angle
local _Lerp = Lerp
local _Color = Color
local _tonumber = tonumber
local _LerpVector = LerpVector
local _mathMax = math.max
local _mathMin = math.min
local _type = type

local MAX_SPAWN_DISTANCE = 500
local NPC_CLASS = 'danlib_npc_spawn'
local NET_SELECT = 'DDI.SelectingNPCspawning'

--- Returns true when the position is NOT obstructed by worldspawn geometry.
-- Two traces: a downward floor check and a hull-overlap test.
local function IsPositionValid(pos)
    local trFloor = DNetworkUtil:TraceLine({
        start = pos + _Vector(0, 0, 10),
        endpos = pos,
        filter = function(ent)
            return ent:GetClass() == 'worldspawn'
        end
    })

    local trHull = DNetworkUtil:TraceHull({
        start = pos,
        endpos = pos,
        mins = _Vector(-16, -16, -16),
        maxs = _Vector(16, 16, 16),
        filter = function(ent)
            return ent:GetClass() == 'worldspawn'
        end
    })
    return not trFloor.Hit and not trHull.Hit
end


local WEP = DBase.CreateWeapon('npc_spaw')
WEP:SetBase('weapon_base')
WEP:SetPrintName('NPC Spawn Tool')
WEP:SetCategory('[DDI] Tool')
WEP:SetAuthor('denchik')
WEP:SetContact('https://discord.gg/CND6B5sH3j')
WEP:SetPurpose('The tool is designed for Administrators.')
WEP:SetInstructions('LMB — spawn NPC. RMB — remove NPC. [R] — choose NPC type.')
WEP:SetSpawnable(false)
WEP:SetAdminOnly(false)
WEP:SetViewModel('models/weapons/v_pistol.mdl')
WEP:SetModel('models/weapons/w_pistol.mdl')
WEP:SetSlot(1)
WEP:SetSlotPos(1)
WEP:SetDrawAmmo(false)
WEP:SetDrawCrosshair(true)
WEP:SetPrimary({
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = ''
})
WEP:SetSecondary({
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = ''
})

-- Primary Attack — Spawn NPC
WEP:OnPrimaryAttack(function(self)
    if (not IsFirstTimePredicted()) then
        return
    end
    self:SetNextPrimaryFire(_CurTime() + 1)

    local pPlayer = self.Owner
    local trace = DNetworkUtil:TraceLine({
        start = pPlayer:GetShootPos(),
        endpos = pPlayer:GetShootPos() + pPlayer:GetAimVector() * MAX_SPAWN_DISTANCE,
        filter = pPlayer,
    })

    if (not trace.HitPos) then
        return
    end

    if (_IsValid(trace.Entity) and trace.Entity:IsPlayer()) then
        return
    end

    if CLIENT then
        return
    end

    if (not DBase.HasPermission(pPlayer, 'SpawnNPC')) then
        DBase:SidePopupNotifi(pPlayer, 'You do not have permission to use this tool.', 'ERROR', 5)
        return
    end

    local dist = pPlayer:GetPos():Distance(trace.HitPos)
    if (dist > MAX_SPAWN_DISTANCE) then
        DBase:SidePopupNotifi(pPlayer, 'Too far! Maximum: ' .. MAX_SPAWN_DISTANCE .. ' units.', 'ERROR', 5)
        return
    end

    if (trace.HitNormal.z <= 0.7) then
        DBase:SidePopupNotifi(pPlayer, 'Cannot spawn NPC on walls or ceiling.', 'ERROR', 5)
        return
    end

    local hitPos = trace.HitPos + _Vector(0, 0, 5)
    if IsPositionValid(hitPos) then
        DBase:SidePopupNotifi(pPlayer, 'Cannot spawn NPC here. Choose a valid location.', 'WARNING', 5)
        return
    end

    local npcKey = pPlayer:GetNW2String('tool_npc_type', '')
    local _npcCfg = DanLib.CONFIG.BASE.NPCs
    if not (_npcCfg[npcKey] or (_tonumber(npcKey) and _npcCfg[_tonumber(npcKey)])) then
        DBase:SidePopupNotifi(pPlayer, 'No NPC type selected. Press [R] to open the selector.', 'WARNING', 5)
        return
    end

    local npc = ents.Create(NPC_CLASS)
    local ea = npc:GetAngles()
    npc:SetPos(hitPos)
    npc:SetAngles(_Angle(ea.p, pPlayer:GetAngles().y + 180, ea.r))
    npc:Spawn()
    npc:SetNPCKey(npcKey)

    DBase:AddNPCSpawn(npc)
    DBase:SidePopupNotifi(pPlayer, 'NPC spawned successfully!', 'CONFIRM', 5)
end)

-- Secondary Attack — Remove NPC
WEP:OnSecondaryAttack(function(self)
    if (not IsFirstTimePredicted()) then
        return
    end
    self:SetNextSecondaryFire(_CurTime() + 1)

    local pPlayer = self.Owner
    local trace = DNetworkUtil:TraceLine({
        start = pPlayer:GetShootPos(),
        endpos = pPlayer:GetShootPos() + pPlayer:GetAimVector() * MAX_SPAWN_DISTANCE,
        filter = pPlayer,
    })

    if (not trace.HitPos) then
        return
    end

    if CLIENT then
        return true
    end

    if (not DBase.HasPermission(pPlayer, 'SpawnNPC')) then
        DBase:SidePopupNotifi(pPlayer, 'You do not have permission to use this tool.', 'ERROR', 5)
        return
    end

    if (_IsValid(trace.Entity) and trace.Entity:GetClass() == NPC_CLASS) then
        local ent = trace.Entity
        if ent.SpawnID then
            DBase:RemoveNPCSpawn(ent.SpawnID)
        end

        ent:Remove()
        DBase:SidePopupNotifi(pPlayer, 'NPC removed and deleted from npc_spawns.json', 'CONFIRM', 5)
    else
        DBase:SidePopupNotifi(pPlayer, 'Aim at a DanLib NPC to remove it.', 'WARNING', 5)
    end
end)

-- Reload — Open NPC Selector
local _reloadCooldown = 0

WEP:OnReload(function(self)
    if (not IsFirstTimePredicted()) then
        return
    end

    if (_reloadCooldown > _CurTime()) then
        return
    end
    _reloadCooldown = _CurTime() + 1

    if (not CLIENT) then
        return
    end

    local pPlayer = self:GetOwner()
    if (not DBase.HasPermission(pPlayer, 'SpawnNPC')) then
        return
    end

    local options = { }
    for k, v in pairs(DanLib.CONFIG.BASE.NPCs or { }) do
        options[k] = v.Name
    end

    DBase:ComboRequestPopup('NPC List', 'Select one NPC from the list.', options, 'Type', nil, function(value, data)
        -- data is the actual NPC key (e.g. 'npc_1234_5678'), value is the display name
        if (data ~= nil) then
            DNet:Open(NET_SELECT):Str(tostring(data)):Up()
        end
    end)
end)

-- Creates or recreates the animated ghost preview model.
WEP:AddMethod('CreateModel', function(self)
    self:RemoveModel()

    local pPlayer = self:GetOwner()
    if (not _IsValid(pPlayer)) then
        return
    end

    local npcKey = pPlayer:GetNW2String('tool_npc_type', '')
    local npcData = DanLib.CONFIG.BASE.NPCs[npcKey]
    local mdl = (npcData and npcData.Model) or 'models/player/barney.mdl'

    self.model = ClientsideModel(mdl)
    self.model:SetMaterial('models/wireframe')
    self.model:SetRenderMode(RENDERMODE_TRANSALPHA)
    self.model.is_down = true
    self.currentNPCKey = npcKey
    self.intNextSequence = 0

    -- Interpolation state
    self.targetPos = _Vector(0, 0, 0)
    self.currentPos = _Vector(0, 0, 0)
    self.targetAngles = _Angle(0, 0, 0)
    self.currentAngles = _Angle(0, 0, 0)
    self.targetColor = _Color(0, 255, 0, 255)
    self.currentColor = _Color(0, 255, 0, 255)

    if (npcData and npcData.Animation) then
        local idx = self.model:LookupSequence(npcData.Animation)
        if (idx and idx > 0) then
            self.model:ResetSequence(idx)
        end
    end
end)

-- Safely removes the ghost preview model.
WEP:AddMethod('RemoveModel', function(self)
    if _IsValid(self.model) then
        self.model:Remove()
    end
    self.model = nil
end)

-- Deploy / Holster
WEP:OnDeploy(function(self)
    if CLIENT then
        self:CreateModel()
    end
    return true
end)

WEP:OnHolster(function(self)
    if CLIENT then
        self:RemoveModel()
    end
    return true
end)

-- Client Think — Preview Update
WEP:OnClientThink(function(self)
    local pPlayer = self:GetOwner()
    if (not _IsValid(pPlayer)) then
        return
    end

    -- Recreate preview model when the selected NPC type changes
    if (pPlayer:GetNW2String('tool_npc_type', '') ~= self.currentNPCKey) then
        self:CreateModel()
    end

    if (not _IsValid(self.model)) then
        self:CreateModel()
        return
    end

    local tr = pPlayer:GetEyeTrace()
    local lookAtNPC = _IsValid(tr.Entity) and tr.Entity:GetClass() == NPC_CLASS

    -- Hide the ghost when aiming at an existing NPC
    self.model:SetNoDraw(lookAtNPC)
    if lookAtNPC then
        return
    end

    local hitPos = tr.HitPos
    local normal = tr.HitNormal
    local tooFar = pPlayer:GetPos():Distance(hitPos) > MAX_SPAWN_DISTANCE

    -- Position and colour based on surface type
    if (normal.z > 0.7) then
        self.targetPos = hitPos + _Vector(0, 0, 5)
        self.targetColor = tooFar and _Color(255, 128, 0, 255) or _Color(0, 255, 0, 255)
    elseif (normal.z < -0.7) then
        self.targetPos = hitPos - _Vector(0, 0, 5)
        self.targetColor = _Color(255, 0, 0, 255)
    else
        self.targetPos = hitPos + normal * 5
        self.targetColor = _Color(255, 0, 0, 255)
    end
    self.targetAngles = _Angle(0, pPlayer:GetAngles().y + 180, 0)

    -- Smooth interpolation every frame
    local ft = _FrameTime()
    self.currentPos = _LerpVector(ft * 15, self.currentPos, self.targetPos)
    self.currentAngles.y = _Lerp(ft * 10, self.currentAngles.y, self.targetAngles.y)
    self.currentColor.r = _Lerp(ft * 10, self.currentColor.r, self.targetColor.r)
    self.currentColor.g = _Lerp(ft * 10, self.currentColor.g, self.targetColor.g)
    self.currentColor.b = _Lerp(ft * 10, self.currentColor.b, self.targetColor.b)

    self.model:SetPos(self.currentPos)
    self.model:SetAngles(self.currentAngles)
    self.model:SetColor(self.currentColor)

    -- Idle animation toggle every 5 seconds
    local ct = _CurTime()
    if (ct > self.intNextSequence) then
        self.model:ResetSequence(self.model.is_down and 0 or 2)
        self.model.is_down = not self.model.is_down
        self.intNextSequence = ct + 5
    end
end)

-- PostDrawViewModel — In-world Instruction Panel (CLIENT)
local _fadeIn = 0.5
local _fadeOut = 0.5
local _alpha = 0
local _visible = false
local _lastUpdate = 0

-- Draws a labelled hint box anchored to the viewmodel's right-hand bone.
local function DrawHint(text, title, y, alpha)
    local x = 34
    local w1 = DUtils:GetTextSize(title, 'danlib_font_30')
    local w2, h2 = DUtils:GetTextSize(text, 'danlib_font_30')
    w2 = w2 + 34 + w1
    h2 = h2 + 16

    surface.SetAlphaMultiplier((alpha or 255) / 255)
    DUtils:DrawRoundedBox(x, y, w2, h2, DBase:Theme('secondary_dark'))
    DUtils:DrawRoundedBox(x, y, 2, h2, DBase:Theme('decor'))
    DUtils:DrawSomeText(text, 'danlib_font_30', DBase:Theme('decor'), title, 'danlib_font_30', DBase:Theme('title'), x + 14, y + h2 / 2 - 16, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetAlphaMultiplier(1)
end

WEP:OnPostDrawViewModel(function(self, viewModel, wWeapon)
    if (wWeapon:GetClass() ~= 'npc_spaw') then
        return
    end

    local pPlayer = LocalPlayer()
    local trEnt = pPlayer:GetEyeTrace().Entity
    local onNPC = _IsValid(trEnt) and trEnt:GetClass() == NPC_CLASS
    local ct = _CurTime()
    local ft = _FrameTime()

    if onNPC then
        _visible = true
        _lastUpdate = ct
    elseif (ct - _lastUpdate >= _fadeIn) then
        _visible = false
    end

    _alpha = _visible and _mathMin(255, _alpha + 255 / _fadeIn * ft) or _mathMax(0, _alpha - 255 / _fadeOut * ft)

    local boneIdx = viewModel:LookupBone('ValveBiped.Bip01_R_Hand')
    if (not boneIdx) then
        return
    end

    local bPos, bAng = viewModel:GetBonePosition(boneIdx)
    local panelPos = bPos + bAng:Forward() * 4.9 + bAng:Right() * 2 + bAng:Up() * -9.5

    local panelAng = Angle(bAng.p, bAng.y, bAng.r)
    panelAng:RotateAroundAxis(panelAng:Right(), 190)
    panelAng:RotateAroundAxis(panelAng:Up(), 90)
    panelAng:RotateAroundAxis(panelAng:Forward(), 90)

    local npcKey = pPlayer:GetNW2String('tool_npc_type', '')
    local selData = DanLib.CONFIG.BASE.NPCs[npcKey]
    local selName = selData and (selData.Name or 'error') or 'Nothing selected'
    local baseY = onNPC and 140 or 195

    cam.Start3D2D(panelPos, panelAng, 0.0122)
        DrawHint('LeftClick', ' - Spawn where you look.',  baseY)
        DrawHint('RightClick', ' - Remove where you look.', baseY)
        DrawHint('R', ' - Select NPC type.', baseY + 55)
        if onNPC then
            DrawHint('RightClick', ' - Remove this NPC.', baseY + 110, _alpha)
        end
        DrawHint('Selected', ' — ' .. selName, baseY + 165)
    cam.End3D2D()
end)

-- Register
WEP:Register()

-- Server Networking — DanLib.Net
if SERVER then
    DNet:On(NET_SELECT, function(len, pPlayer)
        local npcKey = DNet:Str()
        if (not _IsValid(pPlayer) or not pPlayer:IsPlayer()) then
            return
        end

        local npcConfig = DanLib.CONFIG.BASE.NPCs or { }
        local isKnownKey = (_type(npcKey) == 'string' and npcKey ~= '' and (npcConfig[npcKey] or (_tonumber(npcKey) and npcConfig[_tonumber(npcKey)])))
        if (not isKnownKey or not DBase.HasPermission(pPlayer, 'SpawnNPC')) then
            return
        end

        pPlayer:SetNW2String('tool_npc_type', npcKey)
    end)
end
