/***
 *   @addon         DanLib
 *   @component     Command Page
 *   @license       MIT License
 *   @version       2.1.0
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Command listing page for DanLib framework.
 *                  Shows all registered chat commands with search and copy support.
 *                  Only displays commands the current player has access to.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DTable = DanLib.Table
local DCustomUtils = DanLib.CustomUtils.Create

-- Cache common functions
local _type = type
local _pairs = pairs
local _Color = Color
local _find = string.find
local _lower = string.lower
local _LocalPlayer = LocalPlayer

local _TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local _TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local _TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM

local COMMAND = DBase.CreatePage('commands')
COMMAND:SetName(DBase:L('#chat.commands'))
COMMAND:SetOrder(3)
COMMAND:SetIcon('5Rr8I1N')
COMMAND:SetID('commands')

--- Checks whether the local player has access to a given command.
-- @param cmd table: Command data with optional access field.
-- @param steamID string: Player's SteamID.
-- @param steamID64 string: Player's SteamID64.
-- @param group string: Player's user group.
-- @param rank string: Player's DanLib rank.
-- @return boolean
local function _HasCommandAccess(cmd, steamID, steamID64, group, rank)
    if (not cmd.access) then
        return true
    end

    if (_type(cmd.access) == 'table') then
        return DTable:HasValue(cmd.access, steamID64) or DTable:HasValue(cmd.access, steamID) or DTable:HasValue(cmd.access, group) or DTable:HasValue(cmd.access, rank)
    elseif (_type(cmd.access) == 'string') then
        return cmd.access == steamID64 or cmd.access == group
    end
    return false
end

function COMMAND:Create(container)
    local PANEL = DCustomUtils(container)
    PANEL:Pin()
    PANEL:ApplyEvent('FillPanel', function(self)
        local margin, wide = 30, 200
        local iconSize = 24
        local iconMargin = 14

        -- Header
        local top = DCustomUtils(self)
        top:PinMargin(TOP, nil, nil, nil, 12)
        top:SetTall(46)
        top:ApplyBackground(DBase:Theme('secondary_dark'), 6)
        top:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawIcon(iconMargin, h * 0.5 - iconSize * 0.5, iconSize, iconSize, '5Rr8I1N', DBase:Theme('mat', 150))
            DUtils:DrawDualText(iconMargin * 3.5, h / 2 - 2, DBase:L('#chat.commands'),       'danlib_font_20', DBase:Theme('decor'), DBase:L('#chat.commands.description'), 'danlib_font_18', DBase:Theme('text'), _TEXT_ALIGN_LEFT, nil, w - wide)
        end)

        -- Search box
        local dockMargin = (top:GetTall() - margin) * 0.5
        self.textEntry = DBase.CreateTextEntry(top, DanLib.Config.Materials['Search'])
        self.textEntry:Pin(RIGHT, dockMargin)
        self.textEntry:SetWide(wide)
        self.textEntry:SetBackText(DBase:L('#search'))
        self.textEntry.OnChange = function()
            self:Refresh()
        end

        -- Scroll list
        self.Scroll = DCustomUtils(self, 'DanLib.UI.Scroll')
        self.Scroll:Pin()

        self:Refresh()
    end)

    PANEL:ApplyEvent('Refresh', function(self)
        self.Scroll:Clear()

        -- Cache player identity once, outside the loop
        local pPlayer = _LocalPlayer()
        local steamID = pPlayer:SteamID()
        local steamID64 = pPlayer:SteamID64()
        local group = pPlayer:GetUserGroup()
        local rank = pPlayer:get_danlib_rank()

        local searchText = _lower(self.textEntry:GetValue())
        local hasSearch = searchText ~= ''

        -- Cache theme colors outside the loop
        local colorBG = DBase:Theme('secondary_dark')
        local colorTitle = DBase:Theme('title')
        local colorText = DBase:Theme('text', 180)
        local colorGreen = _Color(39, 174, 96)

        for cmdName, cmd in _pairs(DanLib.Temp.Command) do
            -- Filter by search
            if hasSearch and not _find(_lower(cmd.description), searchText, 1, true) then
                continue
            end

            -- Filter by access
            if (not _HasCommandAccess(cmd, steamID, steamID64, group, rank)) then
                continue
            end

            -- Command row
            local row = DCustomUtils(self.Scroll)
            row:PinMargin(TOP, 4, nil, 2, 8)
            row:SetTall(50)
            row:ApplyAttenuation(0.2)

            -- Cache per-row text width
            local nameW = DUtils:TextSize(cmdName, 'danlib_font_20').w

            row:ApplyEvent(nil, function(sl, w, h)
                DUtils:DrawRoundedBox(0, 0, w, h, colorBG)
                DUtils:DrawRoundedBox(9, h * 0.5 - 18, nameW + 10, 17, colorGreen)
                draw.SimpleText(cmdName, 'danlib_font_20', 14, h * 0.5 - 22, colorTitle, _TEXT_ALIGN_BOTTOM)
                DUtils:DrawParseText(cmd.description, 'danlib_font_18', 10, h * 0.5, colorText, _TEXT_ALIGN_LEFT, _TEXT_ALIGN_TOP)
            end)

            -- Copy button
            local btnTall   = 46
            local btnMargin = (row:GetTall() - btnTall) * 0.5
            DBase.CreateUIButton(row, {
                background = { nil },
                dock_indent = { RIGHT, nil, btnMargin + 8, 15, btnMargin + 8 },
                wide = DBase:Scale(45),
                icon = { 'C1bpjkc' },
                tooltip = { DBase:L('#copy'), nil, nil, RIGHT },
                click = function()
                    DBase:ClipboardText(cmdName)
                    DBase:TutorialSequence(3, 1)
                end
            })
        end
    end)

    PANEL:FillPanel()
    DBase:TutorialSequence(2, 1)
end
