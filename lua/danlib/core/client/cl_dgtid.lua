/***
 *   @addon         DanLib
 *   @component     UI Gtid
 *   @license       MIT License
 *   @version       1.0.6
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   This function creates a grid panel with customizable margins, columns, and maximum height.
 *                  Enhanced version with scrollbar fixes, sorting, and animation support.
 *
 *   @attributes
 *                  - horizontalMargin: The horizontal margin between cells.
 *                  - verticalMargin: The vertical margin between rows.
 *                  - columns: The number of columns in the grid.
 *                  - maxHeight: The maximum height of the grid panel.
 *                  - animationEnabled: Enable/disable smooth animations.
 *                  - sortFunction: Custom sorting function for grid elements.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DTable = DanLib.Table
local DUtils = DanLib.Utils
local DTimer = DanLib.Timer
local DCustomUtils = DanLib.CustomUtils.Create

local _IsValid = IsValid
local _pairs = pairs
local _ipairs = ipairs
local _max = math.max

-- Animation easing functions
local AnimationEasing = {
    Linear = function(t) return t end,
    EaseIn = function(t) return t * t end,
    EaseOut = function(t) return 1 - (1 - t) * (1 - t) end,
    EaseInOut = function(t) 
        return t < 0.5 and 2 * t * t or 1 - math.pow(-2 * t + 2, 2) / 2
    end
}

function DBase.CreateGridPanel(parent)
    -- Create a scrollable panel as the base for the grid
    local PANEL = DCustomUtils(parent, 'DanLib.UI.Scroll')

    -- Define accessors for grid panel attributes
    AccessorFunc(PANEL, 'horizontalMargin', 'HorizontalMargin', FORCE_NUMBER)
    AccessorFunc(PANEL, 'verticalMargin', 'VerticalMargin', FORCE_NUMBER)
    AccessorFunc(PANEL, 'columns', 'Columns', FORCE_NUMBER)
    AccessorFunc(PANEL, 'maxHeight', 'MaxHeight', FORCE_NUMBER)
    AccessorFunc(PANEL, 'animationDuration', 'AnimationDuration', FORCE_NUMBER)
    AccessorFunc(PANEL, 'animationDelay', 'AnimationDelay', FORCE_NUMBER)
    AccessorFunc(PANEL, 'animationEasing', 'AnimationEasing', FORCE_STRING)

    -- Set default values
    PANEL:SetHorizontalMargin(4)
    PANEL:SetVerticalMargin(4)
    PANEL:SetAnimationDuration(0.4)
    PANEL:SetAnimationDelay(0.08)
    PANEL:SetAnimationEasing('EaseOut')

    -- Initialize data structures
    PANEL.Rows = { }
    PANEL.Cells = { }
    PANEL.SortData = { }
    PANEL.AnimationQueue = { }
    PANEL.ScrollbarWidth = 0
    PANEL.LastContentHeight = 0

    -- Check if scrollbar is actually needed and visible
    function PANEL:GetScrollbarWidth()
        local contentHeight = self:GetContentHeight()
        local panelHeight = self:GetTall()
        
        -- Only reserve space if scrollbar is actually needed
        if (contentHeight > panelHeight) then
            local vbar = self:GetVBar()
            if _IsValid(vbar) then
                return vbar:GetWide()
            end
            return 16 -- Standard scrollbar width fallback
        end
        return 0 -- No scrollbar needed
    end

    -- Scrollbar detection and width calculation
    function PANEL:UpdateScrollbarWidth()
        local oldWidth = self.ScrollbarWidth
        local contentHeight = self:GetContentHeight()
        local panelHeight = self:GetTall()
        
        -- Check if scrollbar is needed
        if (contentHeight > panelHeight) then
            -- Scrollbar is present, measure its width
            local vbar = self:GetVBar()
            if (_IsValid(vbar) and vbar:IsVisible()) then
                self.ScrollbarWidth = vbar:GetWide()
            else
                self.ScrollbarWidth = 16 -- Default fallback
            end
        else
            self.ScrollbarWidth = 0
        end

        -- If scrollbar width changed, recalculate layout
        if (oldWidth ~= self.ScrollbarWidth) then
            self:RecalculateLayout()
        end
    end

    -- Get available width - subtract scrollbar only when it exists
    function PANEL:GetAvailableWidth()
        local scrollbarWidth = self:GetScrollbarWidth()
        local safetyMargin = scrollbarWidth > 0 and 4 or 0 -- Safety margin only when scrollbar present
        return _max(50, self:GetWide() - scrollbarWidth - safetyMargin)
    end

    -- Method to get the content height
    function PANEL:GetContentHeight()
        local totalHeight = 0
        for _, row in _pairs(self.Rows) do
            if _IsValid(row) then
                totalHeight = totalHeight + row:GetTall() + DBase:Scale(self:GetVerticalMargin())
            end
        end
        return _max(0, totalHeight - DBase:Scale(self:GetVerticalMargin()))
    end

    -- Recalculate layout for all cells
    function PANEL:RecalculateLayout()
        local slots = self:GetColumns()
        local margin = self:GetHorizontalMargin()
        local availableWidth = self:GetAvailableWidth() - margin * (slots - 1)
        local cellWidth = availableWidth / slots

        for _, cell in _pairs(self.Cells) do
            if (_IsValid(cell) and not cell.CustomWidth) then
                cell:SetWide(cellWidth)
            end
        end

        self:InvalidateLayout(true)
    end

    -- Animation system
    function PANEL:StartAnimation()
        -- Clear existing animations
        self:StopAnimation()

        local animDuration = self:GetAnimationDuration()
        local animDelay = self:GetAnimationDelay()
        local easingFunc = AnimationEasing[self:GetAnimationEasing()] or AnimationEasing.EaseOut

        -- Animate each cell sequentially
        for i, cell in _ipairs(self.Cells) do
            if _IsValid(cell) then
                local startTime = CurTime() + (i - 1) * animDelay
                local endTime = startTime + animDuration
                
                -- Store original alpha
                cell.OriginalAlpha = cell:GetAlpha()
                cell:SetAlpha(0)

                -- Create animation data
                local animData = {
                    cell = cell,
                    startTime = startTime,
                    endTime = endTime,
                    startAlpha = 0,
                    endAlpha = cell.OriginalAlpha or 255,
                    easingFunc = easingFunc,
                    timerName = 'DanLibGrid_Anim_' .. i
                }

                DTable:Add(self.AnimationQueue, animData)

                -- Start the animation timer
                DTimer:Create(animData.timerName, 0, 0, function()
                    if (not _IsValid(cell)) then
                        DTimer:Remove(animData.timerName)
                        return
                    end

                    local currentTime = CurTime()
                    if (currentTime < animData.startTime) then
                        return
                    end

                    if (currentTime >= animData.endTime) then
                        cell:SetAlpha(animData.endAlpha)
                        DTimer:Remove(animData.timerName)
                        return
                    end

                    local progress = (currentTime - animData.startTime) / animDuration
                    local easedProgress = animData.easingFunc(progress)
                    local currentAlpha = Lerp(easedProgress, animData.startAlpha, animData.endAlpha)
                    
                    cell:SetAlpha(currentAlpha)
                end)
            end
        end
    end

    -- Stop all animations
    function PANEL:StopAnimation()
        for _, animData in _pairs(self.AnimationQueue) do
            if animData.timerName then
                DTimer:Remove(animData.timerName)
            end

            if _IsValid(animData.cell) then
                animData.cell:SetAlpha(animData.cell.OriginalAlpha or 255)
            end
        end
        self.AnimationQueue = { }
    end

    -- Sorting functionality
    function PANEL:SetSortFunction(sortFunc)
        self.SortFunction = sortFunc
    end

    function PANEL:Sort(sortFunc)
        if (not sortFunc and not self.SortFunction) then
            DBase:PrintType('DanLib Grid', 'Nosort function provided')
            return
        end

        local actualSortFunc = sortFunc or self.SortFunction
        
        -- Create sortable data array
        local sortableData = { }
        for i, cell in _ipairs(self.Cells) do
            DTable:Add(sortableData, {
                cell = cell,
                data = cell.SortData or { },
                index = i
            })
        end

        -- Sort the data
        DTable:Sort(sortableData, function(a, b)
            return actualSortFunc(a.data, b.data, a.cell, b.cell)
        end)

        -- Rebuild the grid with sorted order
        local sortedCells = { }
        for _, item in _ipairs(sortableData) do
            DTable:Add(sortedCells, item.cell)
        end

        self:RebuildGrid(sortedCells)
    end

    -- Rebuild grid with new cell order
    function PANEL:RebuildGrid(newCellOrder)
        -- Clear existing rows
        for _, row in _pairs(self.Rows) do
            if _IsValid(row) then
                row:Remove()
            end
        end
        self.Rows = { }

        -- Update cells array
        if newCellOrder then
            self.Cells = newCellOrder
        end

        -- Re-add cells in new order
        local tempCells = DTable:Copy(self.Cells)
        self.Cells = { }

        for _, cell in _ipairs(tempCells) do
            if _IsValid(cell) then
                self:AddCellToGrid(cell, cell.CustomWidth, cell.CustomHeight)
            end
        end

        self:UpdateScrollbarWidth()
        self:StartAnimation()
    end

    -- Internal method to add cell to grid
    function PANEL:AddCellToGrid(panel, customWidth, customHeight)
        local slots = self:GetColumns()
        local index = math.floor(#self.Cells / slots) + 1
        local margin = self:GetHorizontalMargin()

        -- Create a new row if it doesn't exist
        self.Rows[index] = self.Rows[index] or self:CreateRow()

        -- Set the panel's parent and dock it
        panel:CustomUtils()
        panel:SetParent(self.Rows[index])
        panel:PinMargin(LEFT, nil, nil, (#self.Rows[index].Items + 1 < slots) and margin or 0)

        -- Calculate width with scrollbar consideration
        if (not customWidth) then
            local availableWidth = self:GetAvailableWidth()
            local totalMarginWidth = margin * _max(0, slots - 1)
            local cellWidth = _max(10, (availableWidth - totalMarginWidth) / slots)
            panel:SetWide(cellWidth)
            panel.CustomWidth = false
            
            -- Dynamic width updating with proper calculations
            panel.PerformLayout = function()
                if not panel.CustomWidth then
                    local newAvailableWidth = self:GetAvailableWidth()
                    local newTotalMarginWidth = margin * _max(0, slots - 1)
                    local newCellWidth = _max(10, (newAvailableWidth - newTotalMarginWidth) / slots)
                    panel:SetWide(newCellWidth)
                end
            end
        else
            panel.CustomWidth = true
        end

        if customHeight then
            panel.CustomHeight = true
        end

        -- Store the panel in the row and cells
        DTable:Add(self.Rows[index].Items, panel)
        DTable:Add(self.Cells, panel)

        -- Calculate the height of the row
        self:CalculateRowHeight(self.Rows[index])
    end

    -- Enhanced AddCell method
    function PANEL:AddCell(panel, width, height, sortData)
        -- Store sort data
        if sortData then
            panel.SortData = sortData
        end

        self:AddCellToGrid(panel, width, height)
        self:UpdateScrollbarWidth()
    end

    -- Calculate the heights of all rows
    function PANEL:CalculateRows()
        for _, row in _pairs(self.Rows) do
            if _IsValid(row) then
                self:CalculateRowHeight(row)
            end
        end
    end

    -- Auto-size the grid panel
    function PANEL:AutoSize()
        local totalHeight = self:GetContentHeight()

        -- Respect the maximum height if set
        if (self:GetMaxHeight() and self:GetMaxHeight() ~= 0) then
            totalHeight = math.min(totalHeight, DBase:Scale(self:GetMaxHeight()))
        end

        self:SetTall(totalHeight)

        -- Adjust parent height if necessary
        if (_IsValid(self:GetParent()) and self:GetParent():GetName() == 'EditablePanel') then
            self:GetParent():SetTall(totalHeight + (self:GetTopMargin() or 0))
        end

        self:UpdateScrollbarWidth()
        return totalHeight
    end

    -- Create a new row
    function PANEL:CreateRow()
        local row = self:Add('EditablePanel'):CustomUtils()
        row:PinMargin(TOP, nil, nil, nil, DBase:Scale(self:GetVerticalMargin()))
        row.Items = { }
        return row
    end

    -- Calculate the height of a row
    function PANEL:CalculateRowHeight(row)
        if (not _IsValid(row)) then
            return
        end
        
        local height = 0
        for _, cell in _pairs(row.Items) do
            if _IsValid(cell) then
                height = _max(height, cell:GetTall())
            end
        end
        row:SetTall(height)
    end

    -- Skip a cell by adding an empty panel
    function PANEL:Skip()
        local cell = DCustomUtils()
        self:AddCell(cell)
    end

    -- Clear all cells and rows
    function PANEL:Clear()
        self:StopAnimation()
        
        for _, row in _pairs(self.Rows) do
            if _IsValid(row) then
                for _, cell in _pairs(row.Items) do
                    if _IsValid(cell) then
                        cell:Remove()
                    end
                end
                row:Remove()
            end
        end
        
        self.Cells = { }
        self.Rows = { }
        self.SortData = { }
        self.ScrollbarWidth = 0
    end

    -- Enhanced Think method for scrollbar monitoring
    local oldThink = PANEL.Think
    function PANEL:Think()
        if oldThink then
            oldThink(self)
        end
        
        -- Monitor content height changes
        local currentContentHeight = self:GetContentHeight()
        if (self.LastContentHeight ~= currentContentHeight) then
            self.LastContentHeight = currentContentHeight
            self:UpdateScrollbarWidth()
        end
    end

    -- Override PerformLayout to handle scrollbar changes
    local oldPerformLayout = PANEL.PerformLayout
    function PANEL:PerformLayout(...)
        if oldPerformLayout then oldPerformLayout(self, ...) end
        self:UpdateScrollbarWidth()
    end

    -- Cleanup on removal
    function PANEL:OnRemove()
        self:StopAnimation()
        self:Clear()
    end

    return PANEL
end

-- Demo function (updated to show new features)
local function gridDemo()
    local Frame = DBase.CreateUIFrame()
    Frame:SetSize(500, 500)
    Frame:Center()
    Frame:MakePopup()
    Frame:SetTitle('Enhanced Grid Panel Demo')

    local Grid = DBase.CreateGridPanel(Frame)
    Grid:Pin(FILL, 10)
    Grid:SetColumns(3)
    Grid:SetHorizontalMargin(6)
    Grid:SetVerticalMargin(6)

    -- Add test panels with sort data
    for i = 1, 30 do
        local Panel = DCustomUtils()
        Panel:SetTall(60)
        Panel:ApplyBackground(DBase:Theme('secondary_dark'), 6)
        Panel:ApplyEvent(nil, function(sl, w, h)
            draw.SimpleText('Panel #' .. i, 'danlib_font_16', w * 0.5, h * 0.35, DBase:Theme('text'), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText('Value: ' .. (i * 7) % 100, 'danlib_font_14', w * 0.5, h * 0.65, DBase:Theme('title'), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end)
        
        -- Add sort data
        local sortData = {
            index = i,
            value = (i * 7) % 100,
            name = 'Panel #' .. i
        }
        
        Grid:AddCell(Panel, nil, nil, sortData)
    end

    -- Add control buttons
    local ButtonPanel = DCustomUtils(Frame)
    ButtonPanel:Pin(BOTTOM)
    ButtonPanel:SetTall(40)

    local SortByIndex = ButtonPanel:Add('DButton')
    SortByIndex:SetText('Sort by Index')
    SortByIndex:SetWide(120)
    SortByIndex:Dock(LEFT)
    SortByIndex:DockMargin(5, 5, 5, 5)
    SortByIndex.DoClick = function()
        Grid:Sort(function(a, b) return a.index < b.index end)
    end

    local SortByValue = ButtonPanel:Add('DButton')
    SortByValue:SetText('Sort by Value')
    SortByValue:SetWide(120)
    SortByValue:Dock(LEFT)
    SortByValue:DockMargin(0, 5, 5, 5)
    SortByValue.DoClick = function()
        Grid:Sort(function(a, b) return a.value < b.value end)
    end

    local ReverseSort = ButtonPanel:Add('DButton')
    ReverseSort:SetText('Reverse')
    ReverseSort:SetWide(80)
    ReverseSort:Dock(LEFT)
    ReverseSort:DockMargin(0, 5, 5, 5)
    ReverseSort.DoClick = function()
        Grid:Sort(function(a, b) return a.index > b.index end)
    end

    local AnimateBtn = ButtonPanel:Add('DButton')
    AnimateBtn:SetText('Animate')
    AnimateBtn:SetWide(80)
    AnimateBtn:Dock(LEFT)
    AnimateBtn:DockMargin(0, 5, 5, 5)
    AnimateBtn.DoClick = function()
        Grid:StartAnimation()
    end

    Grid:StartAnimation()
end

-- Uncomment to test
-- gridDemo()
