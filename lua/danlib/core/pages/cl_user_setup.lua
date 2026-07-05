/***
 *   @addon         DanLib
 *   @component     User Settings Page
 *   @license       MIT License
 *   @version       1.4.1
 *   @release_date  16/03/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Dynamic user configuration panel for DanLib framework with collapsible
 *                  categories, multiple input types (int, string, bool, key, custom), and
 *                  automatic saving. Provides visual interface for managing module settings
 *                  with real-time validation and tooltips.
 *
 *   @functions     
 *                  - Collapsible category system with smooth animations
 *                  - Multiple setting types (Int, String, Bool, Key, Table, Custom)
 *                  - Real-time auto-save on change
 *                  - Reset individual settings or entire module
 *                  - Help tooltips for complex settings
 *                  - Custom action buttons per setting
 *                  - Sorted module display by priority
 *                  - Key binding validation with banned keys
 *                  - ComboBox support for enum values
 *                  - Custom VGUI element integration
 *                  - Real-time UI sync when values are changed externally (e.g. from other addons)
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         Requires DanLib.UserModules to be populated with module configurations.
 *                  Settings are automatically persisted to data/danlib/config/modules/<id>.txt
 */



-- Cache DanLib modules
local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DTable = DanLib.Table
local DTimer = DanLib.Timer
local DCustomUtils = DanLib.CustomUtils.Create
local DMaterials = DanLib.Config.Materials
local DType = DanLib.Type
local DHook = DanLib.Hook
local USERCONFIG = DanLib.USERCONFIG

-- Cache standard Lua functions
local _pairs, _ipairs = pairs, ipairs
local _ColorAlpha = ColorAlpha
local _SimpleText = draw.SimpleText
local color_white = color_white
local _TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local _TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local _Lerp = Lerp
local _FrameTime = FrameTime
local _IsValid = IsValid

-- PAGE CONFIGURATION
local SETUP = DBase.CreatePage('User')
SETUP:SetOrder(2)
SETUP:SetIcon('bQldJcj')
SETUP:SetID('player_settings')
SETUP:SetKeyboardInput(true)

function SETUP:Create(parent)
    -- Do NOT call DanLib.LoadUserConfig() here — it reads from disk and would
    -- overwrite any in-memory changes that haven't been flushed yet
    -- (e.g. a debounced save from DanLib.Client.SetValue that is still pending).
    -- Config is already loaded at startup via InitPostEntity.
    local settings = parent:Add('DanLib.UI.UserSetup')
    settings:Dock(FILL)
end

-- MAIN SETUP PANEL
local ui = DanLib.UI
local SETUP_PANEL = DanLib.UiPanel()

function SETUP_PANEL:Init()
    self.sortedConfigCache = nil
    self.defaultFont = 'danlib_font_18'
    self.themeCache = {}

    -- Table to track active input controls for external sync: [moduleID][varKey] = inputControl
    self.inputControls = {}

    -- Guard flag: prevents onChangeCallback from firing when SyncControl updates a control,
    -- which would cause an infinite hook loop (external change → SyncControl → OnChange → hook → SyncControl → ...)
    self.syncingFromExternal = false

    self:CacheThemeColors()
    self:TopHeader()

    self.scroll = DCustomUtils(self, 'DanLib.UI.Scroll')
    self.scroll:Pin()

    self:Refresh()

    -- Listen for value changes triggered from outside the settings menu
    -- (e.g. a chat addon calling DanLib.Client.SetValue to save window position/size)
    local hookName = 'DanLib.UserSetup.ExternalSync_' .. tostring(self)
    DHook:Add('DanLib.ClientConfigChanged', hookName, function(moduleID, variable, value)
        -- Panel may have been closed without OnRemove firing (parent removal, GC, etc.)
        -- In GMod, accessing methods on an invalid panel returns nil, so we must guard here.
        if (not _IsValid(self)) then
            DHook:Remove('DanLib.ClientConfigChanged', hookName)
            return
        end
        self:SyncControl(moduleID, variable, value)
    end)
end

-- Remove the hook when the panel is closed to avoid ghost listeners
function SETUP_PANEL:OnRemove()
    DHook:Remove('DanLib.ClientConfigChanged', 'DanLib.UserSetup.ExternalSync_' .. tostring(self))
end

-- Cache all theme colors once
function SETUP_PANEL:CacheThemeColors()
    self.themeCache = {
        secondary_dark = DBase:Theme('secondary_dark'),
        secondary = DBase:Theme('secondary'),
        secondary_150 = DBase:Theme('secondary', 150),
        secondary_50 = DBase:Theme('secondary', 50),
        mat_150 = DBase:Theme('mat', 150),
        mat_100 = DBase:Theme('mat', 100),
        decor = DBase:Theme('decor'),
        text = DBase:Theme('text'),
        yellow = DBase:GetColor('Yellow'),
        yellow_60 = DBase:GetColor('Yellow', 60)
    }
end

function SETUP_PANEL:TopHeader()
    local cache = self.themeCache
    local settingsText = DBase:L('#settings')
    local settingsDesc = DBase:L('#settings.description')

    self.header = DCustomUtils(self)
    self.header:Pin(TOP)
    self.header:DockMargin(0, 0, 0, 12)
    self.header:SetTall(46)
    self.header:ApplyShadow(10, false)

    local icon = 24
    local iconMargin = 14

    self.header:ApplyEvent(nil, function(sl, w, h)
        DUtils:DrawRoundedBox(0, 0, w, h, cache.secondary_dark)
        DUtils:DrawIcon(iconMargin, h * .5 - icon * 0.5, icon, icon, 'bQldJcj', cache.mat_150)
        DUtils:DrawDualText(iconMargin * 3.5, h * 0.5 - 2, settingsText, 'danlib_font_20', cache.decor, settingsDesc, self.defaultFont, cache.text, _TEXT_ALIGN_LEFT, nil, w - 300)
    end)

    self.resetAllButton = self:CreateButton('Reset All', function()
        self:ResetAll()
    end)
end

function SETUP_PANEL:ResetAll()
    for _, module in _pairs(DanLib.UserModules) do
        module:ResetAll()
    end
    self.sortedConfigCache = nil
    self:Refresh()
end

function SETUP_PANEL:CreateButton(name, onClick)
    local buttonSize = DUtils:TextSize(name, self.defaultFont).w
    return DBase.CreateUIButton(self.header, {
        background = { nil },
        dock_indent = { RIGHT, nil, 7, 6, 7 },
        wide = 14 + buttonSize,
        hover = { self.themeCache.yellow_60, nil, 6 },
        text = { name, nil, nil, nil, self.themeCache.yellow },
        click = onClick
    })
end

function SETUP_PANEL:GetSortedConfig()
    if not self.sortedConfigCache then
        self.sortedConfigCache = {}
        for k, v in _pairs(DanLib.UserModules) do
            DTable:Add(self.sortedConfigCache, { v.SortOrder, k })
        end
        DTable:SortByMember(self.sortedConfigCache, 1, false)
    end
    return self.sortedConfigCache
end

function SETUP_PANEL:Refresh()
    self.scroll:Clear()
    -- Clear tracked controls since we are rebuilding all rows
    self.inputControls = {}

    local sortedConfig = self:GetSortedConfig()
    local cache = self.themeCache

    local iconSize = 18
    local borderH = 35

    for _, config in _pairs(sortedConfig) do
        local moduleKey = config[2]
        local module = DanLib.UserModules[moduleKey]
        if (module.Hidden) then
            continue
        end

        local colorExpanded = module.Color or color_white
        local colorExpanded100 = _ColorAlpha(colorExpanded, 100)

        local category = DCustomUtils(self.scroll, 'DCollapsibleCategory')
        category:SetLabel('')
        category:PinMargin(TOP, nil, nil, 4, 8)
        category:ApplyClearPaint()
        category:SetHeaderHeight(borderH)
        category:SetExpanded(true)
        category.Header:CustomUtils()
        local moduleTitle = module.Title or 'Untitled'
        category.Header:ApplyEvent(nil, function(sl, w, h)
            local expanded = category:GetExpanded()
            local tomColor = expanded and colorExpanded or colorExpanded100

            sl.deg = _Lerp(_FrameTime() * 15, sl.deg or 0, expanded and 0 or 180)

            DUtils:DrawRoundedBox(0, 0, w, h, cache.secondary)
            DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
                DUtils:DrawRoundedBox(0, 0, 3, h, tomColor)
            end)
            DUtils:DrawIconRotated(w - 20, h * 0.5, iconSize, iconSize, sl.deg, DMaterials['Arrow'], tomColor)
            _SimpleText(moduleTitle, 'danlib_font_18', 14, h * 0.5, tomColor, _TEXT_ALIGN_LEFT, _TEXT_ALIGN_CENTER)
        end)

        local categoryContent = DCustomUtils()
        category:SetContents(categoryContent)

        for _, val in _ipairs(module:GetSorted()) do
            if val.IsSeparator then
                self:CreateCategorySeparator(categoryContent, val)
            else
                self:CreateSettingRow(categoryContent, module, val)
            end
        end
    end
end

--- Renders a category header separator row between option groups.
-- @param parent (Panel): Container to add the separator into.
-- @param val (table): Sentinel row produced by GetSorted (IsSeparator = true).
function SETUP_PANEL:CreateCategorySeparator(parent, val)
    local separatorH = 32
    local cache = self.themeCache

    local separator = DCustomUtils(parent)
    separator:PinMargin(TOP, nil, 8, nil, -6)
    separator:SetTall(separatorH)
    separator:ApplyEvent(nil, function(sl, w, h)
        local info = val.CategoryInfo
        local color = (info and info.Color) or color_white
        local icon = info and info.Icon
        local name = (info and info.Name) or val.Name or 'Category'

        local iconSize = 16
        local curX = 8
        if icon then
            DUtils:DrawIcon(curX, h * 0.5 - iconSize * 0.5, iconSize, iconSize, icon, color)
            curX = curX + iconSize + 6
        end

        _SimpleText(name, self.defaultFont, curX, h * 0.5, color, _TEXT_ALIGN_LEFT, _TEXT_ALIGN_CENTER)
    end)
end

function SETUP_PANEL:CreateSettingRow(parent, module, val)
    local headerH = 50
    local cache = self.themeCache
    local settingName = val.Name or 'Unnamed'
    local settingDesc = val.Description or ''

    -- Wrapper: the only panel pinned to the scroll.
    -- Its height grows/shrinks; internal controls never see the resize.
    local wrapper = DCustomUtils(parent)
    wrapper:Pin(TOP)
    wrapper:SetTall(headerH)
    wrapper:PinMargin(TOP, 2, 6, 4)

    -- Row panel: always headerH (50px). All controls live here.
    local variablePanel = DCustomUtils(wrapper)
    variablePanel:Dock(TOP)
    variablePanel:SetTall(headerH)
    variablePanel.hasError = false

    local inputWidth = 300
    if (val.Type == DType.Int or val.Type == DType.String) then
        inputWidth = 270
    elseif (val.Type == DType.Bool) then
        inputWidth = 105
    end

    local actionButtonWidth = val.Action and 42 or 0

    variablePanel:ApplyEvent(nil, function(sl, w, h)
        if sl.hasError then
            DUtils:DrawRoundedTopBox(0, 0, w, h, cache.secondary_150)
        else
            DUtils:DrawRoundedBox(0, 0, w, h, cache.secondary_150)
        end
        local margin = w - inputWidth - actionButtonWidth
        DUtils:DrawDualText(10, 25, settingName, self.defaultFont, cache.decor, settingDesc, self.defaultFont, cache.text, _TEXT_ALIGN_LEFT, nil, margin)
    end)

    if val.HelpText then
        local x = DUtils:TextSize(settingName, self.defaultFont).w
        local helpPanel = DCustomUtils(variablePanel)
        helpPanel:SetPos(x + 14, 6)
        helpPanel:SetSize(14, 14)
        helpPanel:ApplyTooltip(val.HelpText, nil, nil, TOP)
        helpPanel:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawIcon(0, 0, w, h, DMaterials['Help'] or DMaterials['Info'], cache.mat_100)
        end)
    end

    local inputControl = nil
    local moduleID = module.ID
    local valKey = val.Key

    -- Error strip: child of wrapper, below the row.
    -- Height changes instantly (no gap/jitter); alpha fades via DanLib ApplyLerpFade.
    local errorPanel = DCustomUtils(wrapper)
    errorPanel:Dock(TOP)
    errorPanel:SetTall(0)
    errorPanel:SetAlpha(0)
    errorPanel._errorText = nil
    errorPanel._lastError = ''
    errorPanel:ApplyEvent(nil, function(sl, w, h)
        if (h < 1) then
            return
        end
        DUtils:DrawRoundedBottomBox(0, 0, w, h, DBase:GetColor('Red', 20))
        _SimpleText((sl._errorText or sl._lastError), 'danlib_font_14', 10, h * 0.5, DBase:GetColor('Red'), _TEXT_ALIGN_LEFT, _TEXT_ALIGN_CENTER)
    end)

    variablePanel._ep = errorPanel
    variablePanel._wrapper = wrapper
    function variablePanel:ShowValidationError(msg)
        local ep, wr = self._ep, self._wrapper
        ep:ApplyEndAnimations()
        if msg then
            ep._lastError = msg
            ep._errorText = msg
            self.hasError = true
            -- Expand instantly, then fade in text
            ep:SetTall(22)
            wr:SetTall(headerH + 22)
            ep:ApplyLerpFade(0.2, ep:GetAlpha(), 255)
        else
            ep._errorText = nil
            self.hasError = false
            ep:SetTall(0)
            wr:SetTall(headerH)
        end
    end

    -- Reset button: resets this single variable to default
    self:CreateResetButton(variablePanel, function()
        USERCONFIG[moduleID][valKey] = val.Default
        DHook:Run('DanLib.ClientConfigChanged', moduleID, valKey, val.Default)
        DanLib.SaveUserConfig()

        if _IsValid(inputControl) then
            self:_ApplyValueToControl(inputControl, val, val.Default)
        end
    end)

    local wide = 200
    local margiMoveToRight = 15
    local margin = 10

    -- onChange: called when the user edits a control directly inside the panel.
    -- The guard prevents this from re-firing when SyncControl updates the control from outside.
    local function onChangeCallback(newValue)
        if self.syncingFromExternal then
            return
        end

        USERCONFIG[moduleID][valKey] = newValue
        DHook:Run('DanLib.ClientConfigChanged', moduleID, valKey, newValue)

        DTimer:Create('DanLib_AutoSave_' .. moduleID .. '_' .. valKey, 1, 1, function()
            DanLib.SaveUserConfig()
        end)
    end

    if val.GetOptions then
        local options = val.GetOptions()
        local comboSelect = DBase.CreateUIComboBox(variablePanel)
        comboSelect:PinMargin(RIGHT, nil, margin, margiMoveToRight, margin)
        comboSelect:SetWide(wide)
        comboSelect:SetValue(module:GetValue(valKey))
        comboSelect:DisableShadows()

        inputControl = comboSelect

        local currentValue = module:GetValue(valKey)
        for k, v in _pairs(options) do
            comboSelect:AddChoice(v, k, currentValue == k)
        end

        comboSelect:ApplyEvent('OnSelect', function(_, index, value, data)
            if val.Validation then
                local _vok, _vreason = val.Validation(data)
                variablePanel:ShowValidationError((not _vok) and (_vreason or 'Invalid value') or nil)
            end
            onChangeCallback(data)
        end)
    elseif (val.Type == DType.Table and val.VguiElement) then
        DBase.CreateUIButton(variablePanel, {
            dock_indent = { RIGHT, nil, margin, margiMoveToRight, margin },
            wide = 32,
            icon = { DMaterials['Edit'] },
            tooltip = { DBase:L('#edit'), nil, nil, TOP },
            click = function(sl)
                if ui:valid(sl.con) then
                    sl.con:Remove()
                    return
                end
                local Container = DCustomUtils(nil, val.VguiElement)
                sl.con = Container
                Container:FillPanel()
            end
        })
    elseif (val.Type == DType.Int) then
        local numberWang = DBase.CreateNumberWang(variablePanel)
        numberWang:PinMargin(RIGHT, nil, margin, margiMoveToRight, margin)
        numberWang:SetWide(wide)
        numberWang:SetHighlightColor(cache.secondary_50)
        numberWang:SetValue(module:GetValue(valKey))
        numberWang:DisableShadows()

        inputControl = numberWang

        if (val.Min and val.Max) then
            numberWang:SetMinMax(val.Min, val.Max)
        end

        local function commitIntValue()
            local newVal = tonumber(numberWang:GetValue()) or 0
            if val.Validation then
                local _vok, _vreason = val.Validation(newVal)
                variablePanel:ShowValidationError((not _vok) and (_vreason or 'Invalid value') or nil)
            end
            onChangeCallback(newVal)
        end

        numberWang:ApplyEvent('OnValueChanged', function(sl)
            commitIntValue()
        end)
        numberWang:ApplyEvent('OnEnter', function()
            commitIntValue()
        end)
        numberWang:ApplyEvent('OnLoseFocus', function()
            commitIntValue()
        end)
    elseif (val.Type == DType.String) then
        local textEntry = DBase.CreateTextEntry(variablePanel)
        textEntry:PinMargin(RIGHT, nil, margin, margiMoveToRight, margin)
        textEntry:SetWide(wide)
        textEntry:SetHighlightColor(cache.secondary_50)
        textEntry:SetValue(module:GetValue(valKey) or '')
        textEntry:DisableShadows()

        inputControl = textEntry

        textEntry:ApplyEvent('OnChange', function(sl)
            local newVal = sl:GetValue()
            if val.Validation then
                local _vok, _vreason = val.Validation(newVal)
                variablePanel:ShowValidationError((not _vok) and (_vreason or 'Invalid value') or nil)
            end
            onChangeCallback(newVal)
        end)
    elseif (val.Type == DType.Bool) then
        local checkBox = DBase.CreateCheckbox(variablePanel)
        checkBox:PinMargin(RIGHT, nil, margin, margiMoveToRight, margin)
        checkBox:SetWide(32)
        checkBox:SetValue(module:GetValue(valKey))
        checkBox:DisableShadows()

        inputControl = checkBox

        checkBox:ApplyEvent('OnChange', function(_, value)
            if val.Validation then
                local _vok, _vreason = val.Validation(value)
                variablePanel:ShowValidationError((not _vok) and (_vreason or 'Invalid value') or nil)
            end
            onChangeCallback(value)
        end)
    elseif (val.Type == DType.Key) then
        local binder = DBase.CreateUIBinder(variablePanel)
        binder:PinMargin(RIGHT, nil, margin, margiMoveToRight, margin)
        binder:Help()
        binder:SetWide(wide)
        binder:DisableShadows()

        inputControl = binder

        local bannedBind = val.bannedKeys or {}
        -- GetValue now returns a numeric GMod KEY_ code (0 = no key).
        local gvalBind = tonumber(module:GetValue(valKey)) or 0
        binder:SetValue(gvalBind)

        function binder:OnChange(value)
            if self.syncingFromExternal then
                return
            end

            -- value is already a numeric GMod KEY_ code from input.CheckKeyTrapping().
            local keyName = input.GetKeyName(value) or ''
            if (#bannedBind > 0 and DanLib.Table:HasValue(bannedBind, keyName)) then
                DBase:ScreenNotification(DBase:L('#key.bind.forbidden'), DBase:L('#key.bind.binding'), 'ERROR')
                binder:SetValue(gvalBind)
            else
                gvalBind = value
                if val.Validation then
                    local _vok, _vreason = val.Validation(value)
                    variablePanel:ShowValidationError((not _vok) and (_vreason or 'Invalid value') or nil)
                end
                onChangeCallback(value)
            end
        end
    end

    if val.Action then
        self:CreateActionButton(variablePanel, val)
    end

    -- Track the input control so SyncControl can update it when the value changes externally
    if inputControl then
        if (not self.inputControls[moduleID]) then
            self.inputControls[moduleID] = {}
        end
        self.inputControls[moduleID][valKey] = inputControl
    end

    return variablePanel
end

--- Updates a single input control when its value is changed from outside the settings menu.
-- Called automatically via the DanLib.ClientConfigChanged hook.
-- Uses self.syncingFromExternal to prevent the control's own OnChange from re-firing the hook.
-- @param moduleID (string): Module ID
-- @param variable (string): Variable name
-- @param value (any): New value
function SETUP_PANEL:SyncControl(moduleID, variable, value)
    if (not self.inputControls[moduleID]) then
        return
    end

    local inputControl = self.inputControls[moduleID][variable]
    if (not _IsValid(inputControl)) then
        return
    end

    local mod = DanLib.UserModules[moduleID]
    if (not mod) then
        return
    end

    local varData = mod.Variables[variable]
    if (not varData) then
        return
    end

    -- Set the guard so the control's OnChange/OnValueChanged doesn't trigger onChangeCallback again
    self.syncingFromExternal = true
    self:_ApplyValueToControl(inputControl, varData, value)
    self.syncingFromExternal = false
end

--- Internal helper: applies a value to an input control based on its type.
-- Shared by SyncControl and the reset button callback.
-- @param (inputControl): VGUI panel
-- @param (varData): Variable definition table (must have .Type, .bannedKeys, .GetOptions)
-- @param (value): Value to apply
function SETUP_PANEL:_ApplyValueToControl(inputControl, varData, value)
    if (not _IsValid(inputControl)) then
        return
    end

    if varData.GetOptions then
        -- Find the matching choice by its data and update display text directly.
        -- Using SetValue(raw_key) would show the key instead of the label, so we
        -- bypass ChooseOption (which fires OnSelect) and write text/selected directly.
        for i = 1, #inputControl.Choices do
            if inputControl.Data[i] == value then
                inputControl.text = inputControl.Choices[i]
                inputControl.selected = i
                return
            end
        end
        -- Fallback: no matching choice found, show raw value
        inputControl:SetValue(tostring(value or ''))
    elseif varData.Type == DType.Int then
        inputControl:SetValue(value or 0)
    elseif varData.Type == DType.String then
        inputControl:SetValue(value or '')
    elseif varData.Type == DType.Bool then
        inputControl:SetValue(value or false)
    elseif varData.Type == DType.Key then
        -- Pass the numeric GMod KEY_ code directly; SetValue expects a number.
        inputControl:SetValue(tonumber(value) or 0)
    end
end

function SETUP_PANEL:CreateResetButton(variablePanel, onReset)
    return DBase.CreateUIButton(variablePanel, {
        dock_indent = { RIGHT, nil, 10, 15 - 4, 10 },
        wide = 32,
        icon = { DMaterials['Reset'] },
        tooltip = { DBase:L('#resetting.changes'), nil, nil, TOP },
        click = onReset
    })
end

function SETUP_PANEL:CreateActionButton(variablePanel, val)
    DBase.CreateUIButton(variablePanel, {
        dock_indent = { RIGHT, nil, 10, 15 - 4, 10 },
        wide = 32,
        icon = { DMaterials['Action'] or DMaterials['Settings'] },
        tooltip = { val.ActionTooltip or 'Action', nil, nil, TOP },
        click = function()
            if val.Action then
                val.Action()
            end
        end
    })
end

SETUP_PANEL:Register('DanLib.UI.UserSetup')
