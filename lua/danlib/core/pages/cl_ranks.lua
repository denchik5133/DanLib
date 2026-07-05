/***
 *   @addon         DanLib
 *   @component     Ranks Page
 *   @license       MIT License
 *   @version       2.0.1
 *   @release_date  01/12/2024
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *   
 *   @description   Client-side UI for rank management system with permissions,
 *                  user list, and advanced filtering capabilities
 *   
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local ui = DanLib.UI
local DNet = DanLib.Net
local DTable = DanLib.Table
local DUtils = DanLib.Utils
local RANK = DanLib.UiPanel()
local DPlayerUtil = DanLib.PlayerUtil
local DNetworkUtil = DanLib.NetworkUtil
local DMaterial = DanLib.Config.Materials
local DCustomUtils = DanLib.CustomUtils.Create

-- Optimizing frequent calls
local _IsValid = IsValid
local _type = type
local _pairs = pairs
local _ipairs = ipairs
local _CurTime = CurTime
local _stringFind = string.find
local _stringLower = string.lower
local _stringTrim = string.Trim
local _stringGsub = string.gsub
local _mathClamp = math.Clamp
local _drawSimpleText = draw.SimpleText
local _tableHasValue = table.HasValue
local _osTime = os.time

-- CONSTANTS
local CONSTANTS = {
    BUTTON_SIZE = 30,
    PANEL_HEIGHT = 60,
    CHECKBOX_SIZE = 26,
    ICON_SIZE = 14,
    ANIMATION_DURATION = 0.3,
    SEARCH_DEBOUNCE = 0.3,
    POPUP_WIDTH = 650,
    POPUP_HEIGHT = 400,
    GRID_COLUMNS = 2,
    GRID_H_MARGIN = 12,
    GRID_V_MARGIN = 12,
}

-- CACHING
local rankDataCache = nil
local rankDataCacheTime = 0
local CACHE_DURATION = 1 -- Cache updates every second

-- GLOBAL RANK UPDATES HANDLER
-- Stores all active rank panels
DanLib.ActiveRankPanels = DanLib.ActiveRankPanels or { }

-- ONE global receiver for ALL panels (registered only once)
if (not DanLib._RankDataReceiverRegistered) then
    DanLib._RankDataReceiverRegistered = true
    
    DNet:On('DanLib.SendRankData', function()
        local allRankData = DNet:Tbl()
        
        -- Updating ALL open rank panels
        for panel, _ in _pairs(DanLib.ActiveRankPanels) do
            if (_IsValid(panel) and _IsValid(panel.userScroll)) then
                panel.lastRankData = allRankData
                panel:UpdateUserList(panel.userScroll, allRankData)
            else
                -- Removing dead panels from the registry
                DanLib.ActiveRankPanels[panel] = nil
            end
        end
    end)
end

--- Debounce function for search optimization
local function CreateDebounce(delay)
    local timer = nil
    return function(callback)
        if timer then
            timer:Stop()
        end
        timer = DanLib.Timer:Simple(delay, callback)
    end
end

--- Validation of the rank name
local function ValidateRankName(name)
    if (not name or name == '') then
        return false, 'Rank name cannot be empty!'
    end
    
    name = _stringTrim(name)
    
    if (not name:match('^[%w%s]+$')) then
        return false, 'Role name can only contain letters, numbers, and spaces!'
    end
    
    return true, name
end

--- Generating a rank ID from a name
local function GenerateRankID(name)
    return 'rank_' .. _stringLower(_stringGsub(name, '%s+', '_'))
end

--- Retrieves cached rank data
function RANK:GetRanksValues()
    local currentTime = _CurTime()
    
    -- We return the cache if it is fresh.
    if rankDataCache and (currentTime - rankDataCacheTime) < CACHE_DURATION then
        return rankDataCache
    end
    
    -- Updating the cache
    rankDataCache = DBase:RetrieveUpdatedVariable('BASE', 'Ranks') or DanLib.ConfigMeta.BASE:GetValue('Ranks')
    rankDataCacheTime = currentTime
    
    return rankDataCache
end

--- Cache invalidation (to be called after changes)
function RANK:InvalidateCache()
    rankDataCache = nil
    rankDataCacheTime = 0
end

--- Checking access with result caching
function RANK:CheckAccess()
    -- Caching the verification result
    if (not self._accessCheckCache) then
        self._accessCheckCache = DBase.HasPermission(LocalPlayer(), 'EditRanks')
    end
    
    if self._accessCheckCache then
        return false
    end
    
    DBase:QueriesPopup('WARNING', "You can't edit ranks as you don't have access to them!", nil, nil, nil, nil, true)
    return true
end

--- Checking the possibility of editing the rank
function RANK:CanEditRank(targetRankKey)
    local values = self:GetRanksValues()
    local actorRankKey = LocalPlayer():get_danlib_rank()
    
    -- Validation of input data
    if (not targetRankKey or not actorRankKey) then
        return true
    end
    
    local actorRank = values[actorRankKey]
    local targetRank = values[targetRankKey]
    
    if (not actorRank) then
        DBase:QueriesPopup('ERROR', "Your rank '" .. actorRankKey .. "' does not exist in the configuration!", nil, nil, nil, nil, true)
        return true
    end
    
    if (not targetRank) then
        DBase:QueriesPopup('ERROR', "Target rank '" .. targetRankKey .. "' does not exist!", nil, nil, nil, nil, true)
        return true
    end
    
    if actorRank.Order > targetRank.Order then
        DBase:QueriesPopup('WARNING', "You can't edit this rank!", nil, nil, nil, nil, true)
        return true
    end
    return false
end

--- Adding a new rank
function RANK:add_new()
    if self:CheckAccess() then
        return
    end

    local values = self:GetRanksValues()
    local maxRanks = DanLib.BaseConfig.RanksMax or 15
    
    if (DTable:Count(values) >= maxRanks) then
        DBase:QueriesPopup('ERROR', DBase:L('#rank.limit', {
            limit = maxRanks
        }), nil, nil, nil, nil, true)
        return
    end

    DBase:RequestTextPopup('ADD NEW', DBase:L('#rank.new'), 'New rank', nil, function(roleName)
        local isValid, result = ValidateRankName(roleName)
        if (not isValid) then
            DBase:QueriesPopup('WARNING', result, nil, nil, nil, nil, true)
            return
        end
        
        roleName = result
        local roleID = GenerateRankID(roleName)
        -- Checking the existence of a rank
        if values[roleID] then
            DBase:QueriesPopup('WARNING', 'A role with this ID already exists!', nil, nil, nil, nil, true)
            return
        end
        -- Auto-assigning permissions
        local defaultPermissions = { }
        local autoAssignedCount = 0
        
        for permKey, permData in _pairs(DanLib.BaseConfig.Permissions) do
            if (_type(permData) == 'table' and permData.AutoAssignAll == true) then
                defaultPermissions[permKey] = true
                autoAssignedCount = autoAssignedCount + 1
            end
        end

        -- Creating a new rank
        values[roleID] = {
            Name = roleName,
            Order = DTable:Count(values) + 1,
            Color = Color(255, 255, 255),
            Time = _osTime(),
            Permission = defaultPermissions
        }
        DBase:SetConfigVariable('BASE', 'Ranks', values)
        self:InvalidateCache()
        self:Refresh()
        
        if (autoAssignedCount > 0) then
            DBase:QueriesPopup('SUCCESS', 'Rank "' .. roleName .. '" created with ' .. autoAssignedCount .. ' default permissions!', nil, nil, nil, nil, true)
        end
    end)
end

--- Filling in the panel
function RANK:FillPanel()
    local width = ui:ClampScaleW(self, 700, 750)
    local height = ui:ClampScaleH(self, 500, 500)

    self:SetHeader('Rank')
    self:SetPopupWide(width)
    self:SetExtraHeight(height)
    self:SetSettingsFunc('Update', nil, function()
        if self:CheckAccess() then
            return
        end
        DNet:Open('DanLib.RequestRankData'):Up()
    end)
    self:ApplyEvent('OnClose', function()
        -- Removing the panel from the global registry
        DanLib.ActiveRankPanels[self] = nil
        
        -- Clearing the local cache of the panel
        self._accessCheckCache = nil
        self._sortedRanksCache = nil
        self._lastRefreshTime = nil
        
        -- Resetting the global cache
        self:InvalidateCache()
    end)

    local mainNavPanel = DCustomUtils(self)
    mainNavPanel:Pin(FILL, 16)

    self.tabs = mainNavPanel:Add('DanLib.UI.Tabs')

    local grid = DBase.CreateGridPanel(self.tabs)
    grid:Pin(FILL, 6)
    grid:SetColumns(CONSTANTS.GRID_COLUMNS)
    grid:SetHorizontalMargin(CONSTANTS.GRID_H_MARGIN)
    grid:SetVerticalMargin(CONSTANTS.GRID_V_MARGIN)

    self.grid = grid
    self.tabs:AddTab(grid, 'Ranks')
    self:UsersList()
    self:Refresh()
end

--- Interface update
function RANK:Refresh()
    self.grid:Clear()
    local values = self:GetRanksValues()

    -- Cached sorting
    if (not self._sortedRanksCache or self._lastRefreshTime ~= rankDataCacheTime) then
        local sorted = { }
        for k, v in _pairs(values) do
            DTable:Add(sorted, { v.Order, k })
        end
        DTable:SortByMember(sorted, 1, false)
        self._sortedRanksCache = sorted
        self._lastRefreshTime = rankDataCacheTime
    end

    local sorted = self._sortedRanksCache
    for k, v in _ipairs(sorted) do
        local Key = v[2]
        local rolePanel = DCustomUtils()
        rolePanel:SetTall(CONSTANTS.PANEL_HEIGHT)
        self.grid:AddCell(rolePanel, nil, false)
        self:CreateRankPanel(rolePanel, values, Key, sorted, k)
    end
    self:CreateAddRankButton()
end

--- Creating a Rank panel
function RANK:CreateRankPanel(rolePanel, values, Key, sorted, k)
    local rankData = values[Key]
    local RankColor = rankData.Color or DBase:Theme('title')
    local name = rankData.Name or 'unknown'
    local panelH = CONSTANTS.PANEL_HEIGHT

    -- Order number
    local orderNum = DCustomUtils(rolePanel)
    orderNum:PinMargin(LEFT, nil, nil, 8)
    orderNum:SetWide(26)
    orderNum:ApplyBackground(Color(35, 46, 62), 6)
    orderNum:ApplyText(rankData.Order, 'danlib_font_18', nil, nil, Color(255, 255, 255, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Move buttons
    local function createMoveButton(icon, direction)
        local moveButton = DBase.CreateUIButton(orderNum, {
            background = { nil },
            hover = { nil },
            tall = panelH / 2 - 8,
            wide = CONSTANTS.ICON_SIZE,
            paint = function(sl, w, h)
                self:DrawMoveButtonEffect(sl, h, icon, direction)
            end,
            click = function(sl)
                self:MoveRank(sl, direction, k, sorted, values, Key)
            end
        })
        return moveButton
    end
    createMoveButton(DMaterial['Up-Arrow'], 'up'):Pin(TOP)
    createMoveButton(DMaterial['Arrow'], 'down'):Dock(BOTTOM)

    -- Main panel
    local Panel = DCustomUtils(rolePanel)
    Panel:Pin()
    Panel:ApplyBackground(DBase:Theme('secondary_dark'), 6)
    Panel:ApplyEvent(nil, function(sl, w, h)
        DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
            DUtils:DrawRect(0, 0, 4, h, RankColor)
        end)

        DUtils:DrawDualText(13, h / 2 - 10, name, 'danlib_font_18', RankColor, 'Added ' .. DBase:FormatHammerTime(rankData.Time), 'danlib_font_16', DBase:Theme('text'), TEXT_ALIGN_LEFT, nil, w - 50)
        _drawSimpleText('ID: ' .. Key, 'danlib_font_16', 13, h / 2 + 16, DBase:Theme('text'), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)

    self:CreateRankActionButton(Panel, Key, values, RankColor, name)
end

--- Rendering the move button effect
function RANK:DrawMoveButtonEffect(sl, h, icon, direction)
    local lastClicked = sl.lastClicked or 0
    local clickPercent = _mathClamp((_CurTime() - lastClicked) / CONSTANTS.ANIMATION_DURATION, 0, 1)

    if (_CurTime() < lastClicked + CONSTANTS.ANIMATION_DURATION) then
        local w = sl:GetWide()
        local boxH = h * clickPercent
        DUtils:DrawRoundedMask(6, 0, 0, w, h, function()
            DUtils:DrawRect(0, direction == 'up' and h - boxH or 0, w, boxH, DBase:GetColor('Red', 100))
        end)
    end

    local iconSize = CONSTANTS.ICON_SIZE * clickPercent
    DUtils:DrawIcon(sl:GetWide() / 2 - iconSize / 2, h / 2 - iconSize / 2, iconSize, iconSize, icon, Color(238, 238, 238, 50))
end

--- Moving the rank
function RANK:MoveRank(sl, direction, k, sorted, values, Key)
    sl.lastClicked = _CurTime()
    if self:CanEditRank(Key) then
        return
    end

    local swapIndex = direction == 'up' and k - 1 or k + 1
    if (swapIndex < 1 or swapIndex > #sorted) then
        return
    end
    
    local swapKey = sorted[swapIndex][2]
    if self:CanEditRank(swapKey) then
        return
    end

    -- Exchange of order
    values[swapKey].Order, values[Key].Order = values[Key].Order, values[swapKey].Order
    
    DBase:SetConfigVariable('BASE', 'Ranks', values)
    self:InvalidateCache()
    self:Refresh()
end

--- Creating action buttons above the rank
function RANK:CreateRankActionButton(Panel, Key, values, RankColor, name)
    local size = CONSTANTS.BUTTON_SIZE
    local topMargin = (CONSTANTS.PANEL_HEIGHT - size) / 2
    local buttons = {
        { Name = 'Edit name', Icon = DMaterial['Edit'], Col = DBase:GetColor('Blue'), Func = function() 
            if self:CanEditRank(Key) then
                return
            end
            self:EditRankName(Key, values, name) 
        end },
        { Name = 'Permission', Icon = 'cPzyO3T', Func = function() 
            if self:CanEditRank(Key) then
                return
            end
            self:editPopup(Key, values) 
        end },
        { Name = 'Color', Icon = 'PHLbyno', Func = function() 
            if self:CanEditRank(Key) then
                return
            end
            self:ChangeRankColor(Key, values) 
        end },
        { Name = DBase:L('#delete'), Icon = DMaterial['Delete'], Col = DBase:GetColor('Red'),
          hide = (Key == 'rank_owner'),
          Func = function() 
            if self:CanEditRank(Key) then
                return
            end
            self:DeleteRank(Key, values) 
        end }
    }

    DBase.CreateUIButton(Panel, {
        dock_indent = { RIGHT, nil, topMargin, topMargin, topMargin },
        wide = size,
        icon = { DMaterial['Edit'] },
        tooltip = { DBase:L('#edit'), nil, nil, TOP },
        click = function(sl)
            if self:CheckAccess() then
                return
            end

            local context = DBase:UIContextMenu(self)
            for _, v in _ipairs(buttons) do
                if not v.hide then
                    context:Option(v.Name, v.Col, v.Icon, v.Func)
                end
            end

            local mouse_x, mouse_y = gui.MouseX(), gui.MouseY()
            context:Open(mouse_x + 30, mouse_y - 24, sl)
        end
    })
end

--- Editing the rank name
function RANK:EditRankName(Key, values, name)
    DBase:RequestTextPopup('RANK NAME', DBase:L('#rank.name'), name, nil, function(newName)
        local isValid, result = ValidateRankName(newName)
        if (not isValid) then
            DBase:QueriesPopup('WARNING', result, nil, nil, nil, nil, true)
            return
        end
        
        newName = result
        local newID = GenerateRankID(newName)
        
        if (values[newID] and newID ~= Key) then
            DBase:QueriesPopup('WARNING', DBase:L('#rank.name.exists'), nil, nil, nil, nil, true)
            return
        end

        -- Saving data
        local rankData = values[Key]
        rankData.Name = newName
        rankData.Time = _osTime()
        
        -- If the ID has changed, we will transfer it.
        if (newID ~= Key) then
            values[newID] = rankData
            values[Key] = nil
        end

        DBase:SetConfigVariable('BASE', 'Ranks', values)
        self:InvalidateCache()
        self:Refresh()
    end)
end

--- Removing a rank
function RANK:DeleteRank(Key, values)
    if (DTable:Count(values) <= 1) then
        DBase:QueriesPopup('WARNING', "You can't delete this rank, at least one rank must remain!", nil, nil, nil, nil, true)
        return
    end
    
    if (Key == 'rank_member') then
        DBase:QueriesPopup('ERROR', "You cannot delete 'rank_member' as it is the default rank!", nil, nil, nil, nil, true)
        return
    end

    DBase:QueriesPopup('DELETION', DBase:L('#deletion.description'), nil, function()
        values[Key] = nil
        DBase:SetConfigVariable('BASE', 'Ranks', values)
        self:InvalidateCache()
        self:Refresh()
    end)
end

--- Changing the color of the rank
function RANK:ChangeRankColor(Key, values)
    local RankColor = values[Key].Color
    DBase:RequestColorChangesPopup('COLOR', RankColor, nil, function(value)
        values[Key].Color = value
        DBase:SetConfigVariable('BASE', 'Ranks', values)
        self:InvalidateCache()
        self:Refresh()
    end)
end

--- Creating a rank addition button
function RANK:CreateAddRankButton()
    local createNew = DBase.CreateUIButton(nil, {
        dock_indent = { RIGHT, nil, 7, 6, 7 },
        tall = 30,
        text = { 'Add a new rank', nil, nil, nil, DBase:Theme('text', 200) },
        click = function() self:add_new() end
    })
    self.grid:AddCell(createNew, nil, false)
end

--- Permissions Editing window
function RANK:editPopup(Key, values)
    if _IsValid(Container) then
        return
    end

    Container = DBase.CreateUIPopupBasis()
    Container:SetHeader('Permission - ' .. Key)
    Container:SetPopupWide(CONSTANTS.POPUP_WIDTH)
    Container:SetExtraHeight(CONSTANTS.POPUP_HEIGHT)
    
    local fieldsBack = DCustomUtils(Container, 'DanLib.UI.Scroll')
    fieldsBack:Pin(nil, 6)
    fieldsBack:ToggleScrollBar()
    local playerPermissions = LocalPlayer():get_danlib_rank_permissions()

    -- Sorting permissions
    local sorted = { }
    for k, v in _pairs(DanLib.BaseConfig.Permissions) do
        DTable:Add(sorted, { k, k })
    end
    DTable:SortByMember(sorted, 1, true)

    for k, v in _pairs(sorted) do
        local mKey = v[2]
        local permData = DanLib.BaseConfig.Permissions[mKey]
        local title = _type(permData) == 'table' and (permData.Description or 'No description') or (permData or 'No description')

        local panel = DCustomUtils(fieldsBack)
        panel:PinMargin(TOP, 8, 8, 6)
        panel:ApplyBackground(DBase:Theme('secondary_dark'), 6)
        panel:SetTall(46)
        panel:ApplyEvent(nil, function(sl, w, h)
            DUtils:DrawDualText(8, h / 2 - 1, mKey, 'danlib_font_20', DBase:Theme('decor'), title, 'danlib_font_18', DBase:Theme('text'), TEXT_ALIGN_LEFT, nil, w - CONSTANTS.CHECKBOX_SIZE - 20)
        end)

        local margin = (panel:GetTall() - CONSTANTS.CHECKBOX_SIZE) * 0.5 - 4
        local CheckBox = DBase.CreateCheckbox(panel)
        CheckBox:PinMargin(RIGHT, nil, margin, 10, margin)
        CheckBox:SetWide(CONSTANTS.CHECKBOX_SIZE + 4)
        CheckBox:SetValue(values[Key].Permission[mKey] or false)

        if (not playerPermissions[mKey] and not playerPermissions.all_access) then
            CheckBox:SetDisabled(true)
        end

        function CheckBox:OnChange(value)
            values[Key] = values[Key] or { }
            values[Key].Permission = values[Key].Permission or { }
            values[Key].Permission[mKey] = value
            DBase:SetConfigVariable('BASE', 'Ranks', values)
        end
    end
end

--- User list (with debounce search)
function RANK:UsersList()
    local userPanel = DCustomUtils(self.tabs)
    self.tabs:AddTab(userPanel, 'Users')

    -- Search Bar
    local searchPanel = DCustomUtils(userPanel)
    searchPanel:PinMargin(TOP, nil, 8, 8, 8)
    searchPanel:SetTall(40)
    searchPanel:ApplyBackground(DBase:Theme('secondary_dark'), 6)

    local searchEntry = DBase.CreateTextEntry(searchPanel)
    searchEntry:PinMargin(nil, 10, 6, 10, 6)
    searchEntry:SetBackText('Search by Name, SteamID, or SteamID64...')
    
    self.searchQuery = ''
    
    -- Saving the link to the callback panel
    local rankPanel = self
    
    -- Debounce for optimization
    local searchDebounce = CreateDebounce(CONSTANTS.SEARCH_DEBOUNCE)
    searchEntry:ApplyEvent('OnValueChange', function(sl, value)
        -- Checking that the panel exists
        if (not _IsValid(rankPanel)) then
            return
        end
        
        rankPanel.searchQuery = _stringLower(value or '')
        searchDebounce(function()
            if (_IsValid(rankPanel) and rankPanel.lastRankData) then
                rankPanel:UpdateUserList(rankPanel.userScroll, rankPanel.lastRankData)
            end
        end)
    end)

    -- Update button
    DBase.CreateUIButton(searchPanel, {
        dock = { RIGHT, 6 },
        wide = 130,
        text = { 'Refresh List', nil, nil, nil, DBase:Theme('text') },
        click = function()
            DNet:Open('DanLib.RequestRankData'):Up()
        end
    })

    -- Scroll for users
    local scroll = DCustomUtils(userPanel, 'DanLib.UI.Scroll')
    scroll:Pin(nil, 6)

    self.userList = { }
    self.userScroll = scroll
    self.lastRankData = { }

    -- Registering the panel in the global registry
    DanLib.ActiveRankPanels[self] = true
    -- Initial request
    DNet:Open('DanLib.RequestRankData'):Up()
end

--- Updating the user list
function RANK:UpdateUserList(scroll, allRankData)
    -- Cleaning old items
    for _, user in _ipairs(self.userList) do
        if _IsValid(user) then
            user:Remove()
        end
    end

    self.userList = { }

    -- Sorting users
    local sortedUsers = { }
    for steamID64, data in _pairs(allRankData) do
        DTable:Add(sortedUsers, {
            steamID64 = steamID64,
            data = data,
            time = data.Time or 0
        })
    end
    
    DTable:Sort(sortedUsers, function(a, b)
        return (a.time or 0) > (b.time or 0)
    end)

    local searchQuery = self.searchQuery or ''
    local ranks = DanLib.ConfigMeta.BASE:GetValue('Ranks') or { }

    -- Displaying users
    for _, userData in _ipairs(sortedUsers) do
        local steamID64 = userData.steamID64
        local data = userData.data
        
        local pPlayer = DPlayerUtil:GetBySteamID64(steamID64)
        local isOnline = _IsValid(pPlayer)
        
        local name = steamworks.GetPlayerName(steamID64) or 'Unknown'
        local steamID = DNetworkUtil:SteamIDFrom64(steamID64) or ''
        
        -- Filtering by search
        if searchQuery ~= '' then
            local nameMatch = _stringFind(_stringLower(name), searchQuery, 1, true)
            local steamIDMatch = _stringFind(_stringLower(steamID), searchQuery, 1, true)
            local steamID64Match = _stringFind(steamID64, searchQuery, 1, true)
            
            if (not nameMatch and not steamIDMatch and not steamID64Match) then
                continue
            end
        end
        
        local rankID = data.Rank or 'rank_member'
        local rankData = ranks[rankID]
        local rankName = rankData and rankData.Name or 'Member'
        local rankColor = rankData and rankData.Color or Color(255, 255, 255)

        -- Set default value for name if it is empty or equal to nil
        -- Or 'Unknown', depending on your preference
        name = (name and name ~= '') and name or 'BOT'
        
        -- Creating a User Panel
        local userPanel = DCustomUtils(scroll)
        userPanel:PinMargin(TOP, nil, nil, 4, 8)
        userPanel:ApplyBackground(DBase:Theme('secondary_dark'), 6)
        userPanel:SetTall(60)
        userPanel:ApplyEvent(nil, function(sl, w, h)
            -- Online Status
            local statusColor = isOnline and Color(76, 175, 80) or Color(158, 158, 158)
            draw.RoundedBox(8, 8, h / 2 - 4, 8, 8, statusColor)
            
            -- Name and information
            DUtils:DrawDualText(24, h / 2 - 10, name, 'danlib_font_18', Color(255, 255, 255), 'Rank: ' .. rankName, 'danlib_font_16', rankColor, TEXT_ALIGN_LEFT, nil, w - 100)
            _drawSimpleText('SteamID: ' .. steamID, 'danlib_font_14', 24, h / 2 + 14, DBase:Theme('text', 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end)
        
        -- Action button (if you have rights)
        if DBase.HasPermission(LocalPlayer(), 'EditRanks') then
            local size = CONSTANTS.BUTTON_SIZE
            local topMargin = (60 - size) / 2
            
            DBase.CreateUIButton(userPanel, {
                dock_indent = { RIGHT, nil, topMargin, topMargin, topMargin },
                wide = size,
                icon = { DMaterial['Edit'] },
                tooltip = { 'Edit User', nil, nil, TOP },
                click = function(sl)
                    if self:CheckAccess() then
                        return
                    end

                    local context = DBase:UIContextMenu(self)
                    context:Option(DBase:L('#rank.copy.name'), nil, nil, function()
                        DBase:ClipboardText(rankName)
                    end)
                    context:Option(DBase:L('#copy_id'), nil, nil, function()
                        DBase:ClipboardText(steamID64)
                    end)
                    context:Option('Copy SteamID', nil, nil, function()
                        DBase:ClipboardText(steamID)
                    end)
                    
                    -- Change the rank (for online and offline)
                    context:Option(DBase:L('#edit.rank'), nil, nil, function()
                        local options = { }
                        for k, v in _pairs(ranks or { }) do
                            options[k] = v.Name
                        end

                        DBase:ComboRequestPopup(DBase:L('#rank.list'), DBase:L('#select.assign.rank'), options, rankName, nil, function(value, selectedRankID)
                            if self:CanEditRank(selectedRankID) then
                                return
                            end
                            
                            if isOnline then
                                DNet:Open('DanLib.NetSetRank')
                                    :Ent(pPlayer)
                                    :Str(selectedRankID)
                                    :Up()
                            else
                                DNet:Open('DanLib.NetSetOfflineRank')
                                    :Str(steamID64)
                                    :Str(selectedRankID)
                                    :Up()
                            end
                        end)
                    end)
                    
                    -- Delete data (offline only)
                    if (not isOnline) then
                        context:Option('Delete Player Data', DBase:GetColor('Red'), DMaterial['Delete'], function()
                            DBase:QueriesPopup('DELETION', 'Are you sure you want to delete data for ' .. name .. '?', nil, function()
                                DNet:Open('DanLib.NetDeleteOfflinePlayer'):Str(steamID64):Up()
                            end)
                        end)
                    end
                    
                    context:Open()
                end
            })
        end
        
        DTable:Add(self.userList, userPanel)
    end
end

RANK:SetBase('DanLib.UI.PopupBasis')
RANK:Register('DanLib.UI.Ranks')
