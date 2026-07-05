/***
 *   @addon         DanLib
 *   @component     Settings Page
 *   @license       MIT License
 *   @version       2.0.2
 *   @release_date  10/04/2023
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
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DTable = DanLib.Table
local DTimer = DanLib.Timer
local DHook = DanLib.Hook
local ui = DanLib.UI
local DCustomUtils = DanLib.CustomUtils.Create
local DMaterials = DanLib.Config.Materials

local _pairs = pairs
local _ipairs = ipairs
local _next = next

local SETUP = DBase.CreatePage('settings')
SETUP:SetName(DBase:L('#settings'))
SETUP:SetOrder(5)
SETUP:SetIcon(DMaterials['Settings'])
SETUP:SetID('settings')
SETUP:SetKeyboardInput(true)

--- Checks if the player has access to the administration pages.
-- @param pPlayer Player|nil The player for whom access is being checked. If nil, LocalPlayer() is used.
-- @return boolean Returns true if the player has access, otherwise false.
function SETUP:AccessСheck(pPlayer)
    return DBase.HasPermission(pPlayer or LocalPlayer(), 'AdminPages')
end

--- Creates a settings panel.
-- @param parent Panel The parent panel to which the settings panel will be added.
function SETUP:Create(parent)
    DBase:TutorialSequence(4, 4)
    local settings = parent:Add('DanLib.UI.Setup')
    settings:Dock(FILL)
end 


local SETUP = DanLib.UiPanel()

--- Initializes the setup panel
function SETUP:Init()
    self:TopHeader() -- Creating a top header
    self.pages = { } -- Table for page storage
    self.categoryButtons = { } -- Table for category buttons
    self.modulesToPages = { }
    self.pageIndexCounter = 0 -- Counter for unique page indexes
    self.defaultFont = 'danlib_font_18' -- Default font

    self.tabs = self:Add('DanLib.UI.Tabs')
    self.tabs:DockMargin(0, 8, 0, 0)
    self.tabs.TabID = { }

    self:PopulatePages() -- Filling pages
    self:Refresh() -- Interface update
    self:CheckForUnsavedChanges()
end

--- Creates the top header of the panel
function SETUP:TopHeader()
    self.header = DCustomUtils(self)
    self.header:PinMargin(TOP, nil, nil, nil, 12)
    self.header:SetTall(46)
    self.header:ApplyShadow(10, false)
    self.header.icon = 24
    self.header.iconMargin = 14
    self.header:ApplyEvent(nil, function(sl, w, h)
        DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('secondary_dark'))
        DUtils:DrawIcon(sl.iconMargin, h * .5 - sl.icon * 0.5, sl.icon, sl.icon, DMaterials['Settings'], DBase:Theme('mat', 150))
        DUtils:DrawDualText(sl.iconMargin * 3.5, h / 2 - 2, DBase:L('#settings'), 'danlib_font_20', DBase:Theme('decor'), DBase:L('#settings.description'), self.defaultFont, DBase:Theme('text'), TEXT_ALIGN_LEFT, nil, w - 300)
    end)

    -- Defining the buttons for saving and cancelling
    self.cancelButton = self:CreateButton(DBase:L('cancel'), Color(209, 53, 62), function()
        DanLib.ChangedConfig = nil
        DHook:Run('DanLib.ConfigSaved') -- hide save notification immediately
        self:Refresh()
    end)
    self.saveButton = self:CreateButton(DBase:L('save'), Color(67, 156, 242), function()
        self:HandleSave()
    end)
end

--- Creates a button in the header
-- @param name: string The name of the button
-- @param color: Color The color of the button
-- @param onClick: function The function to call when the button is clicked
-- @return DButton: The created button
function SETUP:CreateButton(name, color, onClick)
    local buttonSize = DUtils:TextSize(name, self.defaultFont).w
    local Button = DBase.CreateUIButton(self.header, {
        background = { nil },
        dock_indent = { RIGHT, nil, 7, 6, 7 },
        wide = 14 + buttonSize,
        hover = { ColorAlpha(color, 60), nil, 6 },
        text = { name, nil, nil, nil, color },
        click = onClick
    })
    Button:SetEnabled(false)
    return Button
end

--- Gets a sorted configuration
-- @return table: A sorted table of configuration items
function SETUP:GetSortedConfig()
    local sortedConfig = { }
    for k, v in _pairs(DanLib.ConfigMeta) do
        DTable:Add(sortedConfig, { v.SortOrder, k })
    end
    DTable:SortByMember(sortedConfig, 1, true) -- Sort by order
    return sortedConfig
end

-- The default reset depends on the type.
function SETUP:GetReset(moduleKey, key)
    -- Retrieve module by key
    local module = DanLib.ConfigMeta[moduleKey]
    
    -- Check if the module exists
    if (not module) then
        DBase:PrintError('Module not found: ' .. moduleKey)
        return
    end

    -- Get values by key
    local defaultValues = module:GetDefaultValue(key)

    -- Check the type of the returned value
    if (type(defaultValues) == 'table') then
        -- If it's a table, copy it
        defaultValues = DTable:Copy(defaultValues)
    elseif (type(defaultValues) == 'string') then
        -- If it's a string, leave it unchanged
        defaultValues = defaultValues
    elseif (type(defaultValues) == 'boolean') then
        -- If it's a boolean, leave it unchanged
        defaultValues = defaultValues
    elseif (type(defaultValues) == 'number') then
        -- If it's a number, leave it unchanged
        defaultValues = defaultValues
    else
        -- If it is not a table, string, or boolean, we print an error message
        DBase:PrintError('A table, string, or boolean was expected but received: ' .. type(defaultValues))
        return
    end

    -- Call the function to change the configuration
    DBase:SetConfigVariable(moduleKey, key, defaultValues)
end

--- Fills the pages with content
function SETUP:PopulatePages()
    local sortedConfig = self:GetSortedConfig()
    for k, config in _pairs(sortedConfig) do
        local moduleKey = config[2]
        local module = DanLib.ConfigMeta[moduleKey]
        local page = DCustomUtils(self.tabs)
        local scrollPanel = DCustomUtils(page, 'DanLib.UI.Scroll')
        scrollPanel:Pin(FILL)
        page.scrollPanel = scrollPanel

        -- Increase the page index count
        self.pageIndexCounter = self.pageIndexCounter + 1
        self.modulesToPages[moduleKey] = self.pageIndexCounter -- Assign a unique index

        -- Refreshing a page
        page:ApplyEvent('Refresh', function(sl)
            scrollPanel:Clear()
            local hasVariables = false
            sl.variablePanels = { }

            for key, val in _ipairs(module:GetSorted()) do
                -- Set flag if variables are found
                hasVariables = true
                
                -- Check if this is a category separator
                if val.IsSeparator then
                    self:CreateCategorySeparator(scrollPanel, val)
                else
                    self:CreateVariablePanel(scrollPanel, val, moduleKey, module, sl)
                end
            end

            -- Check if there are variables
            if (not hasVariables) then
                -- Create a panel with a message
                local emptyMessagePanel = DCustomUtils(page)
                emptyMessagePanel:Pin(FILL)
                emptyMessagePanel:ApplyText("There's nothing here", 'danlib_font_26', nil, nil, DBase:Theme('text'))
            end
        end)
        self:AddPageModule(page, k, module, moduleKey) -- Adding a page to the public list
    end

    DHook:Add('DanLib:HooksConfigUpdated', 'HooksConfigUpdated', function() self:Refresh() end)
end

--- Creates a category separator in the scrollable area
-- @param scrollPanel: The scroll panel to add the separator to
-- @param categoryData: The category data containing name and styling info
function SETUP:CreateCategorySeparator(scrollPanel, categoryData)
    local separatorHeight = 32
    local separator = DCustomUtils(scrollPanel)
    separator:PinMargin(TOP, nil, 4, 4, 4)
    separator:SetTall(separatorHeight)
    separator:ApplyEvent(nil, function(sl, w, h)
        local categoryColor = categoryData.CategoryInfo and categoryData.CategoryInfo.Color or Color(67, 156, 242)
        local categoryIcon = categoryData.CategoryInfo and categoryData.CategoryInfo.Icon
        local categoryName = categoryData.CategoryInfo and categoryData.Name or DBase:L('#no.data')
        
        local textX = 6
        local textY = h / 2
        local iconSize = 16
        local currentX = textX
        if categoryIcon then
            DUtils:DrawIconOrMaterial(currentX, h / 2 - iconSize / 2, iconSize, categoryIcon, categoryColor)
            currentX = currentX + iconSize + 8
        end
        
        -- Draw category name
        draw.SimpleText(categoryName, 'danlib_font_18', currentX, textY, categoryColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)
end

--- Creates a variable panel in the scrollable area
-- @param pages: The scroll panel to add the variable to
-- @param val (table): The variable configuration
-- @param moduleKey (string): The key for the module
-- @param module (table): The module object
-- @param sl (table): Reference to the current setup object
function SETUP:CreateVariablePanel(pages, val, moduleKey, module, sl)
    local headerH = 50
    local customElement = val.Type == DanLib.Type.Table and val.VguiElement

    -- Wrapper: the only panel pinned to the scroll.
    -- Its height grows/shrinks; internal controls never see the resize.
    local wrapper = DCustomUtils(pages)
    wrapper:PinMargin(TOP, nil, nil, 4, 8)
    wrapper:SetTall(headerH)

    -- Row panel: always headerH (50px). All controls live here.
    local variablePanel = DCustomUtils(wrapper)
    variablePanel:Dock(TOP)
    variablePanel:SetTall(headerH)
    variablePanel.hasError = false
    variablePanel:ApplyEvent(nil, function(sl, w, h)
        if sl.hasError then
            DUtils:DrawRoundedTopBox(0, 0, w, h, DBase:Theme('secondary', 150))
        else
            DUtils:DrawRoundedBox(0, 0, w, h, DBase:Theme('secondary', 150))
        end
        sl:ApplyAlpha(false, 0, 0.5, false, sl.undercolor, 255, 0.5)
        DUtils:DrawRoundedBox(0, 0, w, h, Color(46, 62, 82, sl.alpha))

        -- The size of the input element by type
        local inputWidth = 300
        if (val.Type == DanLib.Type.Int or val.Type == DanLib.Type.String) then
            inputWidth = 270
        elseif (val.Type == DanLib.Type.Bool) then
            inputWidth = 105
        end

        -- Size of the action button (if any)
        local actionButtonWidth = 0
        if val.Action then
            actionButtonWidth = 32 + 10 -- 32px button + 10px indentation
        end

        -- The total width of the text is subtracted from the total width of the input field, the button, and the margins.
        local margin = w - inputWidth - actionButtonWidth
        DUtils:DrawDualText(10, headerH / 2 - 2, val.Name or nil, self.defaultFont, DBase:Theme('decor'), val.Description or nil, self.defaultFont, DBase:Theme('text'), TEXT_ALIGN_LEFT, nil, margin)
    end)

    -- Add help text tooltip functionality if HelpText is provided
    if val.HelpText then
        local x = DUtils:TextSize(val.Name, self.defaultFont).w
        local HelpPanel = DCustomUtils(variablePanel)
        HelpPanel:SetPos(x + 14, 6)
        HelpPanel:SetSize(14, 14)
        HelpPanel:ApplyTooltip(val.HelpText, nil, nil, TOP)
        HelpPanel:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawIcon(0, 0, w, h, DMaterials['Help'] or DMaterials['Info'], DBase:Theme('mat', 100))
        end)
    end

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
        draw.SimpleText((sl._errorText or sl._lastError), 'danlib_font_14', 10, h * 0.5, DBase:GetColor('Red'), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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

    -- Adding functionality depending on the type of variable
    self:AddVariableFunctionality(variablePanel, customElement, val, moduleKey, module, sl)
end

--- Adds functionality to a variable panel DBased on its type
-- @param variablePanel (Panel): The variable panel to add functionality to
-- @param customElement (string): The custom element type (if any)
-- @param val (table): The variable configuration
-- @param moduleKey (string): The key for the module
-- @param module (table): The module object
-- @param sl (table): Reference to the current setup object
function SETUP:AddVariableFunctionality(variablePanel, customElement, val, moduleKey, module, sl)
    local wide, margiMoveToRight, margin = 200, 15, (variablePanel:GetTall() - 30) * 0.5 -- indentation
    sl.variablePanels[val.Key] = variablePanel

    -- Per-panel refresher: updates only this control to the effective staged/saved value
    variablePanel.RefreshValue = function(sl)
        local control = sl.inputControl
        if not (control and ui:valid(control)) then
            return
        end

        local newVal = DBase:GetEffectiveConfigValue(moduleKey, val.Key)
        local savedOnChange = control.OnChange
        control.OnChange = nil
        if control.SetValue then
            control:SetValue(newVal)
        end
        control.OnChange = savedOnChange
    end

    -- Frozen options are read-only: hide reset and action controls
    if (not val.Frozen) then
        self:CreateResetButton(variablePanel, moduleKey, val.Key)
    end

    -- Processing different types of variables
    if (customElement or val.GetOptions) then
        if val.GetOptions then
            local options = val.GetOptions()
            local comboSelect = DBase.CreateUIComboBox(variablePanel)
            comboSelect:CustomUtils()
            comboSelect:Dock(RIGHT)
            comboSelect:DockMargin(0, margin, margiMoveToRight, margin)
            comboSelect:SetWide(wide)
            comboSelect:SetValue(module:GetValue(val.Key))
            local currentValue = module:GetValue(val.Key)
            for k, v in _pairs(options) do
                comboSelect:AddChoice(v, k, currentValue == k)
            end
            comboSelect:ApplyEvent('OnSelect', function(_, index, value, data)
                if val.Validation then
                    local _vok, _vreason = val.Validation(data)
                    variablePanel:ShowValidationError((not _vok) and (_vreason or 'Invalid value') or nil)
                end
                DBase:SetConfigVariable(moduleKey, val.Key, data)
            end)
        else
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
        end
    elseif (val.Type == DanLib.Type.Int) then
        local numberWang = DBase.CreateNumberWang(variablePanel)
        numberWang:PinMargin(RIGHT, nil, margin, margiMoveToRight, margin)
        numberWang:SetWide(wide)
        numberWang:SetHighlightColor(DBase:Theme('secondary', 50))
        numberWang:SetValue(DBase:GetEffectiveConfigValue(moduleKey, val.Key))
        numberWang:DisableShadows()
        variablePanel.inputControl = numberWang

        -- Set the minimum and maximum values, if specified
        if (val.MinValue ~= nil and val.MaxValue ~= nil) then
            numberWang:SetMinMax(val.MinValue, val.MaxValue)
        end

        if val.Frozen then
            numberWang:SetEnabled(false)
            numberWang:SetCursor('no')
        else
            numberWang:ApplyEvent('OnChange', function()
                local newVal = numberWang:GetValue()
                if val.Validation then
                    local _vok, _vreason = val.Validation(newVal)
                    variablePanel:ShowValidationError((not _vok) and (_vreason or 'Invalid value') or nil)
                end
                DBase:SetConfigVariable(moduleKey, val.Key, newVal)
            end)
        end
    elseif (val.Type == DanLib.Type.String) then
        local textEntry = DBase.CreateTextEntry(variablePanel)
        textEntry:PinMargin(RIGHT, nil, margin, margiMoveToRight, margin)
        textEntry:SetWide(wide)
        textEntry:SetHighlightColor(DBase:Theme('secondary', 50))
        textEntry:SetValue(DBase:GetEffectiveConfigValue(moduleKey, val.Key) or '')
        textEntry:DisableShadows()
        variablePanel.inputControl = textEntry

        if val.Frozen then
            textEntry:SetEnabled(false)
            textEntry:SetCursor('no')
        else
            textEntry:ApplyEvent('OnChange', function()
                local newVal = textEntry:GetValue()
                if val.Validation then
                    local _vok, _vreason = val.Validation(newVal)
                    variablePanel:ShowValidationError((not _vok) and (_vreason or 'Invalid value') or nil)
                end
                DBase:SetConfigVariable(moduleKey, val.Key, newVal)
            end)
        end
    elseif (val.Type == DanLib.Type.Bool) then
        local CheckBox = DBase.CreateCheckbox(variablePanel)
        CheckBox:PinMargin(RIGHT, nil, margin, margiMoveToRight, margin)
        CheckBox:SetWide(32)
        CheckBox:SetValue(DBase:GetEffectiveConfigValue(moduleKey, val.Key))
        CheckBox:DisableShadows()
        variablePanel.inputControl = CheckBox

        if val.Frozen then
            CheckBox:SetEnabled(false)
            CheckBox:SetCursor('no')
        else
            CheckBox:ApplyEvent('OnChange', function(_, value)
                if val.Validation then
                    local _vok, _vreason = val.Validation(value)
                    variablePanel:ShowValidationError((not _vok) and (_vreason or 'Invalid value') or nil)
                end
                DBase:SetConfigVariable(moduleKey, val.Key, value)
            end)
        end
    end

    -- Checking if there is an action (skipped for frozen options)
    if val.Action and not val.Frozen then
        self:CreateActionButton(variablePanel, val)
    end
end

--- Creates an action button for a variable panel
-- @param variablePanel (Panel): The variable panel to add the action button to
-- @param val (table): The variable configuration
function SETUP:CreateActionButton(variablePanel, val)
    DBase.CreateUIButton(variablePanel, {
        dock_indent = { RIGHT, nil, 10, 15 - 4, 10 },
        wide = 32,
        icon = { DMaterials['Info'] },
        tooltip = { 'Additionally', nil, nil, TOP },
        click = function()
            if (type(val.Action) == 'function') then
                val.Action()  -- If it is a function, call it
            elseif (type(val.Action) == 'string') then
                DCustomUtils(nil, val.Action)  -- Register an item with vgui
            end
        end
    })
end

function SETUP:CreateResetButton(variablePanel, moduleKey, Key)
    DBase.CreateUIButton(variablePanel, {
        dock_indent = { RIGHT, nil, 10, 15 - 4, 10 },
        wide = 32,
        icon = { DMaterials['Reset'] },
        tooltip = { DBase:L('#resetting.changes'), nil, nil, TOP },
        click = function()
            self:GetReset(moduleKey, Key)
            variablePanel:RefreshValue()
        end
    })
end

--- Updates the interface by refreshing all pages
function SETUP:Refresh()
    for _, page in _pairs(self.pages) do
        page:Refresh()
    end
end

--- Adds a page to the setup
-- @param panel Panel: The panel to add as a page
-- @param id (string): The ID of the page
-- @param configMeta (table): The metadata for the configuration
function SETUP:AddPageModule(panel, id, configMeta, moduleKey)
    panel.ID = id

    local key = #self.pages + 1
    self.pages[key] = panel

    local tab = self.tabs
    local text_wrap = DUtils:TextWrap(configMeta.Description, nil, 200)
    local c = tab:AddTab(panel, configMeta.Title, text_wrap, nil, configMeta.Color)
    tab.TabID[id] = c
end

--- Gets the page index and page name by module key.
-- The function looks for the page index in the modulesToPages table by the passed module key and returns the page name and index.
-- If no index is found, returns nil.
-- @param moduleKey (string): The module key of the module for which you want to get the page index.
-- @return string|nil Page name if index is found, otherwise nil.
-- @return number|nil The page index if the index is found, otherwise nil.
function SETUP:GetModuleAndPageIndex(moduleKey)
    -- Get page index by module key
    local pageIndex = self.modulesToPages[moduleKey]
    local pageName = (pageIndex and self.pages[pageIndex]) and self.pages[pageIndex].ID or nil -- Get the page name if the index is found
    return pageName, pageIndex
end

--- Opens a page by its ID
-- @param id (string): The ID of the page to open
-- @return Panel|nil The opened page or nil if not found
function SETUP:ScrollPageByID(id)
    for k, v in _ipairs(self.pages) do
        if ((v.ID or '') == id) then
            self.tabs:SetActive(k)
            return v
        end
    end
end

--- Go to the page with the change
-- @param index (number): Page index for the transition
-- @param key (string): Change key for selection
function SETUP:GotoOnPage(index, key)
    local page = self:ScrollPageByID(index)
    if (not ui:valid(page)) then
        return
    end

    local variablePanel = page.variablePanels[key]
    if (not ui:valid(variablePanel)) then
        return
    end

    DTimer:Simple(nil, function() 
        page.scrollPanel:ScrollToChild(variablePanel) 
    end)

    DTimer:Simple(1.2, function()
        if (not ui:valid(variablePanel)) then
            return
        end
        variablePanel.undercolor = true

        DTimer:Simple(1, function()
            if (not ui:valid(variablePanel)) then
                return
            end
            variablePanel.undercolor = false
        end)
    end)
end

--- Handles saving the configuration changes
function SETUP:HandleSave()
    if (not DanLib.ChangedConfig or DTable:Count(DanLib.ChangedConfig) <= 0) then
        return
    end

    local msg = DanLib.Net:Open('DanLib:RequestSaveConfigChanges')
    msg:UInt(DTable:Count(DanLib.ChangedConfig), 8)

    for k, v in _pairs(DanLib.ChangedConfig) do
        msg:Str(k)
        msg:UInt(DTable:Count(v), 8)

        for key, val in _pairs(v) do
            msg:Str(key)
            local variableType = DBase.GetConfigType(k, key)
            -- Send type on wire so server can safely consume the value
            -- even when it doesn't recognise the variable in its ConfigMeta.
            msg:Str(variableType or '')
            DBase.ProcessTypeValue(variableType, val, true)
        end
    end

    msg:Up()

    -- Apply changes to local CONFIG immediately so UI shows correct values
    -- without waiting for the server's SendConfigUpdate response.
    for moduleKey, moduleData in _pairs(DanLib.ChangedConfig) do
        DanLib.CONFIG[moduleKey] = DanLib.CONFIG[moduleKey] or { }
        for variable, value in _pairs(moduleData) do
            DanLib.CONFIG[moduleKey][variable] = value
        end
    end

    DanLib.ChangedConfig = nil
    DHook:Run('DanLib.ConfigSaved') -- hide save notification immediately
    self:Refresh()
    DBase:TutorialSequence(5, 1)
end

--- Checks for unsaved changes and navigates to the appropriate page.
-- If there are unsaved changes, the function retrieves the first change key and determines which page to jump to.
-- @return nil
function SETUP:CheckForUnsavedChanges()
    -- Checking for unsaved changes
    local hasChanges = DanLib.ChangedConfig and DTable:Count(DanLib.ChangedConfig) > 0
    if hasChanges then
        -- Get the first unsaved setting
        local firstKey, firstChange = _next(DanLib.ChangedConfig)
        local variableKey = _next(firstChange) -- Get the change key
        local pageName, pageIndex = self:GetModuleAndPageIndex(firstKey)

        -- Check if the page index is found
        if pageIndex then
            self:GotoOnPage(pageIndex, variableKey) -- Go to the page with the change
        end
    end
end

--- Think function to check for changes and update button states
function SETUP:Think()
    -- Check for changes and update the state of the buttons
    local hasChanges = DanLib.ChangedConfig and DTable:Count(DanLib.ChangedConfig) > 0
    self.cancelButton:SetEnabled(hasChanges)
    self.saveButton:SetEnabled(hasChanges)

    -- Change the cursor depending on the state of the buttons
    if (not hasChanges) then
        self.cancelButton:SetCursor('no') -- Set the cursor to "deny"
        self.saveButton:SetCursor('no') -- Set the cursor to "deny"
    else
        self.cancelButton:SetCursor('hand') -- Set normal cursor
        self.saveButton:SetCursor('hand') -- Set normal cursor
    end
end

SETUP:Register('DanLib.UI.Setup')
