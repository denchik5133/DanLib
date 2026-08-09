/***
 *   @addon         DanLib
 *   @component     Logs Page
 *   @license       MIT License
 *   @version       2.0.1
 *   @release_date  30/11/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *   
 *   @description   Client-side UI for Discord logging configuration
 *   
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local ui = DanLib.UI
local DTable = DanLib.Table
local DMaterial = DanLib.Config.Materials
local DCustomUtils = DanLib.CustomUtils.Create
local LOGS = DanLib.UiPanel()
local DUtils = DanLib.Utils

-- LOCALIZED FUNCTIONS (PERFORMANCE)
local _pairs = pairs
local _ipairs = ipairs
local _upper = string.upper
local _lower = string.lower
local _gsub = string.gsub
local _ostime = os.time
local _drawSimpleText = draw.SimpleText

-- CONSTANTS
local defaultFont = 'danlib_font_18'
local secondaryFont = 'danlib_font_16'
local smallFont = 'danlib_font_16'

-- Priority colors
local PRIORITY_COLORS = {
    [1] = Color(255, 50, 50), -- CRITICAL - Red
    [2] = Color(255, 165, 0), -- HIGH - Orange
    [3] = Color(100, 150, 255), -- NORMAL - Blue
    [4] = Color(150, 150, 150) -- LOW - Gray
}

local PRIORITY_NAMES = {
    [1] = 'CRITICAL',
    [2] = 'HIGH',
    [3] = 'NORMAL',
    [4] = 'LOW'
}

--- Validates Discord webhook URL format
-- @param url (string): Webhook URL to validate
-- @return (boolean): True if valid, false otherwise
-- 
-- VALID FORMAT:
--   https://discord.com/api/webhooks/{WEBHOOK_ID}/{WEBHOOK_TOKEN}
--   - WEBHOOK_ID: numeric ID (minimum 17 digits)
--   - WEBHOOK_TOKEN: alphanumeric + hyphen + underscore
--
-- EXAMPLES:
--   https://discord.com/api/webhooks/1234567890123456789/abcXYZ123_-token
--   https://discordapp.com/api/webhooks/1234567890123456789/token (the old format)
--   '' (is an empty string)
--   https://example.com/webhook (no Discord)
--   https://discord.com/api/webhooks/123 (no token)
local function isValidWebhook(url)
    -- Empty line
    if (not url or url == '' or url:Trim() == '') then 
        return false
    end
    
    -- Normalize URL
    url = _lower(url):Trim()
    url = _gsub(url, 'discordapp%.com', 'discord.com')
    
    -- Discord webhook format
    -- Pattern breakdown:
    -- ^https://discord%.com/api/webhooks/  - the beginning of the URL (. escaped as %.)
    -- %d+                                  - ID (one or more digits)
    -- /                                    - delimiter
    -- [%w%-_]+                             - TOKEN (letters, numbers, hyphen, underscore)
    -- $                                    - end of line (nothing after the token)
    local isValid = url:match('^https://discord%.com/api/webhooks/%d+/[%w%-_]+$') ~= nil
    return isValid
end

--- Gets the log values from the configuration.
-- @return (table): Log values
function LOGS:GetLOGSValues()
    return DBase:RetrieveUpdatedVariable('BASE', 'Logs') or DanLib.ConfigMeta.BASE:GetValue('Logs')
end

--- Fills the panel with the required interface components.
function LOGS:FillPanel()
    local width = ui:ClampScaleW(self, 700, 800)
    local height = ui:ClampScaleH(self, 550, 550)

    self:SetHeader('Logs setup')
    self:SetPopupWide(width)
    self:SetExtraHeight(height)
    self:SetSettingsFunc(DBase:L('#help'), nil, function() 
        gui.OpenURL('https://discord.com/channels/849615817355558932/1129356041314914314/1129357663189340172') 
    end)

    self.grid = DBase.CreateGridPanel(self):CustomUtils()
    self.grid:Pin(FILL, 20)
    self.grid:SetColumns(3)
    self.grid:SetHorizontalMargin(12)
    self.grid:SetVerticalMargin(12)

    -- Updating panel
    self:Refresh()
end

--- Adds a new log to the list.
function LOGS:AddNewLog()
    DBase:RequestTextPopup(DBase:L('#webhook.url'), DBase:L('#webhook.url.Description'), '', nil,  function(webhook)
        local values = self:GetLOGSValues()
        DTable:Add(values, { 
            Name = 'New Webhook', 
            Webhook = webhook,
            Time = _ostime(), 
            Modules = {} 
        })

        DBase:TutorialSequence(4, 5)
        DBase:SetConfigVariable('BASE', 'Logs', values)
        self:Refresh()
    end, nil, nil, isValidWebhook)
end

--- Refreshes the panel to show the current logs.
function LOGS:Refresh()
    self.grid:Clear()

    local values = self:GetLOGSValues()
    local sorted = {}

    -- Log sorting
    for k, v in _pairs(values) do
        -- WE DELETE ONLY THE OLD EMPTY WEBHOOKS (if they remain in the config)
        if (not v.Webhook and not v.WebhookConfigured) then
            DBase:PrintType('Logs', Color(255, 165, 0), ' Found invalid webhook entry in config, removing: ', color_white, v.Name or k)
            values[k] = nil
        else
            DTable:Add(sorted, { k, k })
        end
    end
    DTable:SortByMember(sorted, 1, true)

    for _, v in _ipairs(sorted) do
        local key = v[1]
        local Panel = self:CreateLogPanel(key, values)
        self.grid:AddCell(Panel, nil, false)
    end

    -- Add new button
    local addButton = DBase.CreateUIButton(nil, {
        tall = 45,
        text = { 'Add new' },
        click = function(sl)
            self:AddNewLog()
        end
    })
    self.grid:AddCell(addButton, nil, false)
end

--- Creates a panel to display log information.
-- @param key (string): Log key
-- @param values (table): Log data
-- @return (Panel): The panel created
function LOGS:CreateLogPanel(key, values)
    local panel = DCustomUtils()
    panel:PinMargin(TOP, nil, nil, nil, self.Margin10)
    panel:SetTall(45)
    panel:ApplyBackground(DBase:Theme('secondary_dark'), 6)
    panel:ApplyEvent(nil, function(sl, w, h)
        local webhookName = values[key].Name
        local webhookTime = DBase:FormatHammerTime(values[key].Time) or ''
        DUtils:DrawDualText(12, h / 2 - 2, webhookName, secondaryFont, DBase:Theme('title'), webhookTime, smallFont, DBase:Theme('text', 150), TEXT_ALIGN_LEFT, nil, w - 30)
    end)

    self:AddLogButtons(panel, key, values)
    return panel
end

--- Adds buttons to the log panel.
-- @param panel (Panel): Log panel
-- @param key (string): Log key
-- @param values (table): Log data
function LOGS:AddLogButtons(panel, key, values)
    local size = 30
    local topMargin = (panel:GetTall() - size) / 2

    local buttons = {
        {
            Name = DBase:L('#edit.name'),
            Icon = DMaterial['Edit'],
            Func = function()
                self:EditLogName(values, key)
            end
        },
        {
            Name = DBase:L('#modules'),
            Icon = DMaterial['Module'],
            Func = function()
                self:CreateConfigPopup(key, values)
            end
        },
        {
            Name = 'WebHook',
            Icon = DMaterial['Link'],
            Func = function()
                self:EditWebhook(values, key)
            end
        },
        {
            Name = DBase:L('#delete'),
            Icon = DMaterial['Delete'],
            Col = DBase:GetColor('Red'),
            Func = function()
                self:DeleteLog(values, key)
            end
        }
    }

    DBase.CreateUIButton(panel, {
        dock_indent = { RIGHT, nil, topMargin, topMargin, topMargin },
        wide = size,
        icon = { DMaterial['Edit'], 16 },
        tooltip = { DBase:L('#edit'), nil, nil, TOP },
        click = function(sl)
            local context = DBase:UIContextMenu()
            for _, v in _ipairs(buttons) do
                context:Option(v.Name, v.Col or nil, v.Icon, v.Func)
            end

            local mouse_x = gui.MouseX()
            local mouse_y = gui.MouseY()
            context:Open(mouse_x + 30, mouse_y - 24, button)
        end
    })
end

--- Edits the log name.
-- @param values (table): Log data
-- @param key (string): Log key
function LOGS:EditLogName(values, key)
    DBase:RequestTextPopup(DBase:L('#webhook.name'), DBase:L('#webhook.name.description'), values[key].Name, nil, function(name)
        values[key].Name = name
        DBase:TutorialSequence(4, 6)
        DBase:SetConfigVariable('BASE', 'Logs', values)
    end)
end

--- Removes the log from the list.
-- @param values (table): Log data
-- @param key (string): Log key
function LOGS:DeleteLog(values, key)
    DBase:QueriesPopup(DBase:L('#deletion'), DBase:L('#deletion.description'), nil, function()
        local values = self:GetLOGSValues()
        values[key] = nil
        DBase:TutorialSequence(4, 6)
        DBase:SetConfigVariable('BASE', 'Logs', values)
        self:Refresh()
    end)
end

--- Edits the webhook URL.
-- @param values (table): Log data
-- @param key (string): Log key
function LOGS:EditWebhook(values, key)
    -- The current webhook is never sent to clients. An empty field means
    -- "replace the configured webhook" and the server preserves it otherwise.
    DBase:RequestTextPopup(DBase:L('#webhook.url'), DBase:L('#webhook.url.Description'), '', nil, function(webhook)
        values[key].Webhook = webhook
        DBase:TutorialSequence(4, 6)
        DBase:SetConfigVariable('BASE', 'Logs', values)
    end, nil, nil, isValidWebhook)
end

--- Creates a configuration popup for the module.
-- @param key (string): Log key
-- @param values (table): Log data
function LOGS:CreateConfigPopup(key, values)
    if ui:valid(Container) then
        return
    end

    local Changed = false

    Container = DCustomUtils(nil, 'DanLib.UI.PopupBasis')
    Container:SetHeader('Module Configuration')
    local x, y = 650, 400
    Container:SetPopupWide(x)
    Container:SetExtraHeight(y)
    Container.OnClose = function()
        if Changed then
            DBase:SetConfigVariable('BASE', 'Logs', values)
            self:Refresh()
        end
    end

    self:CreatePopupTitle(Container, '#SelectWebhook')

    local fieldsBack = DCustomUtils(Container, 'DanLib.UI.Scroll')
    fieldsBack:Pin(FILL, 5)
    fieldsBack:ToggleScrollBar()

    self:CreateModuleCheckboxes(fieldsBack, key, values)
end

--- Creates a title for the popup window.
-- @param parent (Panel): Parent Panel
-- @param titleKey (string): Title key
function LOGS:CreatePopupTitle(parent, titleKey)
    local title = DUtils:TextWrap(DBase:L(titleKey), defaultFont, 500)
    local title_y = DUtils:TextSize(title, defaultFont).y

    local titlePanel = DCustomUtils(parent)
    titlePanel:Pin(TOP, 2)
    titlePanel:SetTall(title_y)
    titlePanel:ApplyEvent(nil, function(sl, w, h)
        draw.DrawText(title, defaultFont, w / 2, 4, DBase:Theme('text'), TEXT_ALIGN_CENTER)
    end)
end

--- Creates checkboxes for modules in the popup window.
-- @param parent (Panel): Parent panel for the checkboxes
-- @param key (string): Log key
-- @param values (table): Log data
function LOGS:CreateModuleCheckboxes(parent, key, values)
    -- GROUPING BY ADDONS
    local addons = {}
    
    for k, v in _pairs(DanLib.ModulesMetaLogs) do
        local addonName = v.Addon or 'Unknown'
        addons[addonName] = addons[addonName] or {}
        DTable:Add(addons[addonName], { v.Sort, k, v })
    end
    
    -- SORTING ADDONS ALPHABETICALLY
    local sortedAddons = {}
    for addonName, _ in _pairs(addons) do
        DTable:Add(sortedAddons, addonName)
    end
    DTable:Sort(sortedAddons)
    
    -- DISPLAY BY ADDONS
    for _, addonName in _ipairs(sortedAddons) do
        local addonModules = addons[addonName]
        
        -- Sorting modules inside the addon
        DTable:SortByMember(addonModules, 1, true)
        
        -- ADDON HEADER
        local addonHeader = DCustomUtils(parent)
        addonHeader:PinMargin(TOP, 10, 10, 5)
        addonHeader:SetTall(24)
        addonHeader:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawRoundedBox(4, 0, 0, w, h, DBase:Theme('primary'))
            -- Addon icon (optional)
            _drawSimpleText(string.format('%s ( %s modules )', addonName, #addonModules), secondaryFont, 0, h / 2, DBase:Theme('text', 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end)
        
        -- MODULES INSIDE THE ADDON
        for _, v in _ipairs(addonModules) do
            local moduleKey = v[2]
            local moduleLog = v[3]

            local panel = DCustomUtils(parent)
            panel:PinMargin(TOP, 10, 10, 10)
            panel:ApplyShadow(10, false, 8)
            panel:SetTall(45)
            panel:ApplyEvent(nil, function(sl, w, h)
                local decor = moduleLog.Color or DBase:Theme('decor')
                DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('secondary_dark'))
                DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
                    DUtils:DrawRect(0, 0, 4, h, decor)
                end)
                DUtils:DrawDualText(14, h / 2 - 2, moduleKey, defaultFont, decor, moduleLog.Description, secondaryFont, DBase:Theme('text', 100), TEXT_ALIGN_LEFT, nil, w - 60)
            end)

            local CheckBox = DBase.CreateCheckbox(panel)
            CheckBox:PinMargin(RIGHT, nil, 8, 10, 8)
            CheckBox:SetWide(30)
            CheckBox:SetValue(values[key].Modules[moduleKey] or false)
            CheckBox:DisableShadows(10)

            function CheckBox:OnChange(value)
                values[key] = values[key] or {}
                values[key].Modules[moduleKey] = value
                DBase:TutorialSequence(4, 6)
                DBase:SetConfigVariable('BASE', 'Logs', values)
            end
        end
    end
end

LOGS:SetBase('DanLib.UI.PopupBasis')
LOGS:Register('DanLib.UI.Logs')
