/***
 *   @addon         DanLib
 *   @component     UI Elements Panel
 *   @license       MIT License
 *   @version       1.0.1
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Universal library for GMod Lua, combining all the necessary features to simplify script development. 
 *                  Avoid code duplication and speed up the creation process with this powerful and convenient library.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DCustomUtils = DanLib.CustomUtils.Create

local PlaySound = surface.PlaySound
local isValid = IsValid

local math = math
local abs = math.abs
local max = math.max

function DBase:CreateLabel(parent, text, font, TextColor)
    font = font or 'danlib_font_18'

    local PANEL = DCustomUtils(parent, 'DLabel')
    PANEL:SetTextColor(TextColor or DBase:Theme('title'))
    PANEL:SetFont(font)
    PANEL:SetText(text or '')

    function PANEL:CenterText()
        self:SetContentAlignment(5)
    end

    function PANEL:Color(r, g, b, a)
        if isnumber(r) then
            self:SetTextColor(Color(r, g, b, a))
        else
            self:SetTextColor(r)
        end
    end

    function PANEL:ShadowS(distance, color)
        distance = distance or 1
        color = color and (isnumber(color) and Color(0, 0, 0, color) or color) or Color(0, 0, 0, 100)
        self:SetExpensiveShadow(distance, color)
    end

    function PANEL:AlignText(a)
        self:SetContentAlignment(a)
    end

    function PANEL:GetContentWidth()
        return select(1, DanLib.Utils:TextSize(self:GetText(), font).w)
    end

    return PANEL
end

function DBase:CreateHTML(parent, url)
    local html = DCustomUtils(parent, 'DHTML')
    if url then
        html:SetScrollbars(false)
        html:SetHTML(url)
    end
    return html
end

--- Creates a model panel to display the 3D model in the user interface.
-- @param parent Panel: The parent panel for the model.
-- @return DModelPanel: The created model panel.
function DBase:CreateModelPanel(parent)
    local Panel = DCustomUtils(parent)

    --- Draws the background and frame around the model.
    Panel:ApplyEvent(nil, function(_, w, h)
        DanLib.Utils:DrawRoundedBox(0, 0, w, h, DBase:Theme('background'))
        DanLib.Utils:DrawOutlinedRoundedRect(6, 0, 0, w, h, 4, DBase:Theme('frame'))
    end)

    -- Panel:ApplyEvent('PaintOver', function(sl, w, h)
    --     DanLib.Utils:DrawGradient(0, h - 50, w, 100, TOP, Color(93, 180, 255, 30))
    -- end)

    Panel.ModelPanel = DCustomUtils(Panel, 'DModelPanel')
    Panel.ModelPanel:Pin()

    --- Configuring the behaviour of the model during rendering.
    function Panel.ModelPanel:LayoutEntity()
        -- Here you can add logic for animation or other actions with the model.
    end

    --- Sets the model to be displayed.
    -- @param sModel string: Path to the model.
    function Panel.ModelPanel:SetModel(sModel)
        if IsValid(self.Entity) then
            self.Entity:Remove()
            self.Entity = nil
        end

        if (not ClientsideModel) then return end
        self.Entity = ClientsideModel(sModel, RENDERGROUP_OTHER)

        if (not IsValid(self.Entity)) then return end
        self.Entity:SetNoDraw(true)
        self.Entity:SetIK(false)

        -- Set the animation for the model.
        local iSeq = self.Entity:LookupSequence('walk_all')
        if (iSeq <= 0) then iSeq = self.Entity:LookupSequence('WalkUnarmed_all') end
        if (iSeq <= 0) then iSeq = self.Entity:LookupSequence('walk_all_moderate') end
        if (iSeq > 0) then self.Entity:ResetSequence(iSeq) end
    end

    --- Adjusting the model to fit the dimensions of the model.
    -- @param model string: Path to the model.
    function Panel.ModelPanel:CoagulationModel(model)
        self:SetModel(model)

        if (not IsValid(self.Entity)) then return end
        local SN, SX = self.Entity:GetRenderBounds()
        local Size = 0

        Size = math.max(Size, math.abs(SN.x) + math.abs(SX.x))
        Size = math.max(Size, math.abs(SN.y) + math.abs(SX.y))
        Size = math.max(Size, math.abs(SN.z) + math.abs(SX.z))

        self:SetFOV(45)
        self:SetCamPos(Vector(Size, Size, Size))
        self:SetLookAt((SN + SX) * 0.5)
        self:ArrowCursor()
    end

    --- Sets the NPC model and adjusts the camera.
    -- @param model string: Path to the NPC model.
    function Panel.ModelPanel:SetModelNPC(model)
        self:SetModel(model or 'models/breen.mdl')
        self:SetCamPos(self:GetCamPos() + Vector(40, 0, 0))
        self:SetColor(Color(255, 255, 255))

        if IsValid(self.Entity) then
            local pos = self.Entity:GetBonePosition(self.Entity:LookupBone('ValveBiped.Bip01_Head1') or 1) or Vector(0, 0, 0)
            pos:Add(Vector(0, 0, 2)) -- Sliding up a little bit
            self:SetLookAt(pos)
            self:SetCamPos(pos - Vector(-20, 0, 0)) -- Slide the camera in front of your eyes
            self.Entity:SetEyeTarget(pos - Vector(-12, 0, 0))
        end
        self:ArrowCursor()
    end

    return Panel
end

-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dadjustablemodelpanel.lua
function DBase:CreateAdjustableModelPanel(parent)
    local ModelPanel = DCustomUtils(parent, 'DModelPanel')

    AccessorFunc(ModelPanel, 'm_bFirstPerson', 'FirstPerson')

    ModelPanel.mx = 0
    ModelPanel.my = 0
    ModelPanel.aLookAngle = angle_zero
    ModelPanel.vCamPos = Vector(0, 0, 0) -- Initializing the camera position
    ModelPanel.OrbitPoint = Vector(0, 0, 0) -- Initializing the orbit point
    ModelPanel.OrbitDistance = 100 -- Initial distance to the model

    function ModelPanel:OnMousePressed(mousecode)
        self:SetCursor('none')
        self:MouseCapture(true)
        self.Capturing = true
        self.MouseKey = mousecode

        self:SetFirstPerson(true)
        self:CaptureMouse()

        -- Helpers for the orbit movement
        local mins, maxs = self.Entity:GetModelBounds()
        local center = (mins + maxs) / 2

        local hit1 = DanLib.NetworkUtil:IntersectRayWithPlane(self.vCamPos, self.aLookAngle:Forward(), vector_origin, Vector(0, 0, 1))
        self.OrbitPoint = hit1

        local hit2 = DanLib.NetworkUtil:IntersectRayWithPlane(self.vCamPos, self.aLookAngle:Forward(), vector_origin, Vector(0, 1, 0))
        if ((not hit1 and hit2) or hit2 and hit2:Distance(self.Entity:GetPos()) < hit1:Distance(self.Entity:GetPos())) then self.OrbitPoint = hit2 end

        local hit3 = DanLib.NetworkUtil:IntersectRayWithPlane(self.vCamPos, self.aLookAngle:Forward(), vector_origin, Vector(1, 0, 0))
        if (((not hit1 or !hit2) and hit3) or hit3 and hit3:Distance(self.Entity:GetPos()) < hit2:Distance(self.Entity:GetPos())) then self.OrbitPoint = hit3 end

        self.OrbitPoint = self.OrbitPoint or center
        self.OrbitDistance = (self.OrbitPoint - self.vCamPos):Length()
    end

    function ModelPanel:Think()
        if (not self.Capturing) then return end
        if self.m_bFirstPerson then return self:FirstPersonControls() end
    end

    function ModelPanel:CaptureMouse()
        local x, y = input.GetCursorPos()
        local dx = x - self.mx
        local dy = y - self.my

        local centerx, centery = self:LocalToScreen(self:GetWide() * 0.5, self:GetTall() * 0.5)
        input.SetCursorPos(centerx, centery)
        self.mx = centerx
        self.my = centery
        return dx, dy
    end

    local function IsKey(cmd)
        -- Yes, this is how engine does it for input.LookupBinding
        for keyCode = 1, BUTTON_CODE_LAST do
            if (input.LookupKeyBinding(keyCode) == cmd and input.IsKeyDown(keyCode)) then return true end
        end
        return false
    end

    function ModelPanel:FirstPersonControls()
        local x, y = self:CaptureMouse()
        local scale = self:GetFOV() / 180
        x = x * -0.5 * scale
        y = y * 0.5 * scale

        if (self.MouseKey == MOUSE_LEFT) then
            if (input.IsShiftDown()) then y = 0 end
            self.aLookAngle = self.aLookAngle + Angle(y * 4, x * 4, 0)
            self.vCamPos = self.OrbitPoint - self.aLookAngle:Forward() * self.OrbitDistance
            return
        end

        -- Look around
        self.aLookAngle = self.aLookAngle + Angle(y, x, 0)
        self.aLookAngle.p = math.Clamp(self.aLookAngle.p, -90, 90)

        X, Y, Z = self.aLookAngle.x, self.aLookAngle.y, self.aLookAngle.z

        local Movement = vector_origin
        if (IsKey('+forward') or input.IsKeyDown(KEY_UP)) then Movement = Movement + self.aLookAngle:Forward() end
        if (IsKey('+back') or input.IsKeyDown(KEY_DOWN)) then Movement = Movement - self.aLookAngle:Forward() end
        if (IsKey('+moveleft') or input.IsKeyDown(KEY_LEFT)) then Movement = Movement - self.aLookAngle:Right() end
        if (IsKey('+moveright') or input.IsKeyDown(KEY_RIGHT)) then Movement = Movement + self.aLookAngle:Right() end
        if (IsKey('+jump') or input.IsKeyDown(KEY_SPACE)) then Movement = Movement + vector_up end
        if (IsKey('+duck') or input.IsKeyDown(KEY_LCONTROL)) then Movement = Movement - vector_up end

        local speed = 0.5
        if input.IsShiftDown() then  speed = 4.0 end
        self.vCamPos = self.vCamPos + Movement * speed
    end

    function ModelPanel:OnMouseWheeled(dlta)
        local scale = self:GetFOV() / 180
        self.fFOV = math.Clamp(self.fFOV + dlta * -10.0 * scale, 0.001, 179)
    end

    -- self:ArrowCursor()

    function ModelPanel:OnMouseReleased(mousecode)
        self:MouseCapture(false)
        self.Capturing = false
    end

    return ModelPanel
end

--- Copies text to the clipboard and displays a notification on the screen.
-- @param CopyText (string): Text to be copied to the clipboard. If not specified, an empty string is used.
function DBase:ClipboardText(CopyText)
    CopyText = CopyText or ''
    local text = self:L('#copied.clipboard')
    local pos_x, pos_y = gui.MouseX(), gui.MouseY()
    local text_x, text_y = DanLib.Utils:GetTextSize(text, 'danlib_font_20')

    SetClipboardText(CopyText)

    local CLIP_BOARD_TEXT = DCustomUtils()
    CLIP_BOARD_TEXT:SetDrawOnTop(true)
    CLIP_BOARD_TEXT:ApplyAttenuation(0.2)
    CLIP_BOARD_TEXT:SetSize(text_x + 1, text_y + 1)
    CLIP_BOARD_TEXT:SetPos(pos_x - CLIP_BOARD_TEXT:GetWide() / 2, pos_y)
    CLIP_BOARD_TEXT:MoveTo(pos_x - CLIP_BOARD_TEXT:GetWide() / 2, -ScrH(), 4)

    CLIP_BOARD_TEXT:ApplyEvent(nil, function(sl, w, h)
        draw.SimpleText(text, 'danlib_font_20', (w / 2) + 1, (h / 2) + 1, Color(34, 40, 49), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(text, 'danlib_font_20', w / 2, h / 2, self:Theme('text'), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    -- PlaySound('ddi/error.mp3')
    self:PlaySound('error')

    -- Deleting the panel in 0.4 seconds
    DanLib.Timer:Simple(0.4, function()
       if isValid(CLIP_BOARD_TEXT) then
            CLIP_BOARD_TEXT:AlphaTo(0, 0.4, 0, function()
                CLIP_BOARD_TEXT:Remove()
            end)
        end 
    end)
end
