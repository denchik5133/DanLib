/***
 *   @addon         DanLib
 *   @component     UI ListView
 *   @license       MIT License
 *   @version       1.2.1
 *   @release_date  01/24/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Advanced data table component for DanLib featuring sortable columns,
 *                  custom cell rendering, row selection, alternating backgrounds, and
 *                  smooth animations.
 *
 *   @features      
 *                  - Sortable columns with numeric/string comparison + cached lower()
 *                  - Custom cell rendering (avatars, badges, buttons)
 *                  - Single/multi-row selection with callbacks
 *                  - Alternating row backgrounds (zebra stripes)
 *                  - Smooth hover animations with ApplyAlpha
 *                  - Auto-width column distribution
 *                  - Rounded corners for first/last rows (cached IsLast flag)
 *                  - Dynamic scrollbar spacing (4px)
 *                  - Text alignment (LEFT/CENTER/RIGHT)
 *                  - Truncation with ellipsis support
 *                  - Shared event handlers (reduced closure allocation)
 *
 *   @api           
 *                  list:AddColumn(name, options) - Define table columns
 *                  list:AddLine(...) - Add data rows
 *                  list:SortByColumn(index, desc) - Sort by column
 *                  list.OnRowSelected(line, selected) - Selection callback
 *                  list.OnRowRightClick(line) - Right-click callback
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DTable = DanLib.Table
local DUtils = DanLib.Utils
local DCustomUtils = DanLib.CustomUtils.Create

-- Cache
local math = math
local _min = math.min
local _Clamp = math.Clamp
local _random = math.random
local string = string
local _sub = string.sub
local _len = string.len
local _lower = string.lower
local _format = string.format
local _IsValid = IsValid
local _Color = Color
local _type = type
local _tostring = tostring
local _tonumber = tonumber
local _ipairs = ipairs
local _drawSimpleText = draw.SimpleText


local LISTVIEW = DanLib.UiPanel()

--- Handles dynamic right margin when scrollbar visibility changes.
-- Adds 4px spacing when scrollbar is visible to prevent content overlap.
-- @param sl (Panel): Line panel instance
-- @param w (number): Line width
-- @param h (number): Line height
-- @internal Shared handler attached to line:ApplyEvent('PerformLayout')
local function LinePerformLayout(sl, w, h)
    local listView = sl.ListView
    local vbar = listView.ScrollPanel:GetVBar()
    
    if (vbar and vbar:IsVisible()) then
        sl:DockMargin(0, 0, listView.ScrollBarSpacing, DBase:Scale(1))
    else
        sl:DockMargin(0, 0, 0, DBase:Scale(1))
    end
end

--- Checks if line is in visible viewport.
-- @param line (Panel): Line panel to check
-- @return (boolean): true if line is visible on screen
-- @internal Performance optimization - skip Paint for invisible lines
function LISTVIEW:IsLineVisible(line)
    if (not self.ScrollPanel) then
    	return true
    end
    
    local vbar = self.ScrollPanel:GetVBar()
    if (not vbar:IsVisible()) then
    	return true 
    end
    
    local scrollOffset = vbar:GetScroll()
    local viewHeight = self.ScrollPanel:GetTall()
    local lineY = line:GetY()
    local lineH = line:GetTall()
    
    -- Line is visible if it intersects viewport
    return (lineY + lineH >= scrollOffset) and (lineY <= scrollOffset + viewHeight)
end

--- Renders line background, hover effects, and selection state.
-- Uses cached IsLast flag for rounded corners on bottom row.
-- Implements smooth hover animation via ApplyAlpha (0.15s fade in, 0.2s fade out).
-- @param sl (Panel): Line panel instance
-- @param w (number): Line width
-- @param h (number): Line height
-- @internal Shared handler attached to line:ApplyEvent(nil) for Paint event
local function LinePaint(sl, w, h)
    local listView = sl.ListView

    -- Skip rendering if line is not visible
    if (not LISTVIEW:IsLineVisible(sl)) then
        return
    end
    
    -- Smooth animation
    sl:ApplyAlpha(0.15, 100, 0.2, 0)
    
    -- Cached IsLast instead of calculating every frame
    local isLast = sl.IsLast
    
    -- Alternation
    if listView.AlternatingRows and (sl.VisualIndex % 2 == 0) then
        if isLast then
            DUtils:DrawRoundedBottomBox(0, 0, w, h, DBase:Theme('secondary_dark', 80))
        else
            DUtils:DrawRect(0, 0, w, h, DBase:Theme('secondary_dark', 80))
        end
    end
    
    -- Hover with animation
    if (sl.alpha and sl.alpha > 0 and not sl.Selected) then
        local hoverAlpha = (sl.alpha / 100) * 50
        
        if isLast then
            DUtils:DrawRoundedBottomBox(0, 0, w, h, DBase:Theme('button_hovered', hoverAlpha))
        else
            DUtils:DrawRect(0, 0, w, h, DBase:Theme('button_hovered', hoverAlpha))
        end
    end
    
    listView:RenderLine(sl, w, h)
    
    -- Selection
    if sl.Selected then
        if isLast then
            DUtils:DrawRoundedBottomBox(0, 0, w, h, DBase:Theme('decor2', 30))
        else
            DUtils:DrawRect(0, 0, w, h, DBase:Theme('decor2', 30))
        end
    end
end

--- Handles double-click on a line.
-- Override this function to customize double-click behavior.
-- @param line (Panel): Line panel that was double-clicked
function LISTVIEW:DoDoubleClick(line)
    -- Override in your implementation
end

--- Handles mouse click events on line rows.
-- Left-click triggers selection toggle, right-click fires callback.
-- @param sl (Panel): Line panel instance
-- @param keyCode (number): Mouse button code (MOUSE_LEFT or MOUSE_RIGHT)
-- @internal Shared handler attached to line:ApplyEvent('OnMousePressed')
local function LineMousePressed(sl, keyCode)
    local listView = sl.ListView
    
    if (keyCode == MOUSE_LEFT) then
        -- Double-click detection
        local clickTime = CurTime()
        if sl._lastClickTime and (clickTime - sl._lastClickTime) < 0.3 then
            if listView.DoDoubleClick then
                listView:DoDoubleClick(sl)
            end
            sl._lastClickTime = nil
        else
            sl._lastClickTime = clickTime
        end
        
        listView:OnLineSelected(sl)
    elseif (keyCode == MOUSE_RIGHT) then
        listView:OnLineRightClick(sl)
    end
end

--- Lazy-loads cell panels on first Think() cycle.
-- Creates cell panels only when needed, reducing initial AddLine() overhead.
-- Cells are created once and reused for the lifetime of the line.
-- @param sl (Panel): Line panel instance
-- @internal Shared handler attached to line:ApplyEvent('Think')
local function LineThink(sl)
    if (#sl.Cells == 0) then
        sl.ListView:CreateLineCells(sl)
    end
end

--- Initializes the ListView component with default settings.
-- Creates header, scroll panel, and configures initial state.
-- @internal Called automatically by DanLib.UiPanel()
function LISTVIEW:Init()
    self:CustomUtils()
    
    self.HeaderHeight = DBase:Scale(40)
    self.LineHeight = DBase:Scale(50)
    self.Padding = DBase:Scale(10)
    self.ScrollBarSpacing = DBase:Scale(4)
    
    self.Columns = { }
    self.Lines = { }
    self.SortColumn = nil
    self.SortDescending = false
    self.SelectedLines = { }
    self.MultiSelect = false
    self.AutoWidthColumns = { }
    self.AlternatingRows = true
    
    -- Header
    self.Header = DCustomUtils(self)
    self.Header:Pin(TOP)
    self.Header:SetTall(self.HeaderHeight)
    self.Header.ListView = self
    
    -- Scroll
    self.ScrollPanel = DCustomUtils(self, 'DanLib.UI.Scroll')
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(0, DBase:Scale(1), 0, 0)
    
    local vbar = self.ScrollPanel:GetVBar()
    vbar:SetWide(DBase:Scale(8))
    vbar:ApplyPaint()

    -- Track corner animation state
    self._headerFullyRounded = true
    self._headerCornerAlpha = 1.0
end

--- Enables or disables alternating row backgrounds (zebra stripes).
-- @param enabled (boolean): true to enable alternating rows, false to disable
function LISTVIEW:SetAlternatingRows(enabled)
    self.AlternatingRows = enabled
end

--- Adds a column to the ListView.
-- @param name (string): Column header text
-- @param options (table): Column configuration
--   - width (number): Fixed width in pixels. If nil, column auto-sizes
--   - minWidth (number): Minimum width for auto-sized columns (default: 50px)
--   - maxWidth (number): Maximum width for auto-sized columns (default: 800px)
--   - align (number): Text alignment - TEXT_ALIGN_LEFT/CENTER/RIGHT (default: LEFT)
--   - font (string): Font name for cell text (default: 'danlib_font_16')
--   - color (Color): Text color (default: Theme('text'))
--   - sortable (boolean): Enable column sorting (default: false) ← ИЗМЕНЕНО!
--   - truncate (boolean): Truncate long text with ellipsis (default: true)
--   - render (function): Custom cell renderer function(line, cell, data)
--   - headerRender (function): Custom header renderer function(panel, x, y, w, h, column)
-- @return (table): Column object with configuration
-- @usage 
--   -- Non-sortable column (default)
--   list:AddColumn('Name', { width = 200 })
--   
--   -- Sortable column
--   list:AddColumn('Age', { sortable = true, align = TEXT_ALIGN_CENTER })
function LISTVIEW:AddColumn(name, options)
    options = options or { }
    
    local column = {
        Name = name,
        Width = options.width,
        MinWidth = options.minWidth or DBase:Scale(50),
        MaxWidth = options.maxWidth or DBase:Scale(800),
        Align = options.align or TEXT_ALIGN_LEFT,
        Font = options.font or 'danlib_font_16',
        Color = options.color or DBase:Theme('text'),
        Sortable = options.sortable == true,
        Render = options.render,
        Index = #self.Columns + 1,
        HeaderRender = options.headerRender,
        IsAutoWidth = not options.width,
        Truncate = options.truncate ~= false
    }
    
    if column.IsAutoWidth then
        DTable:Add(self.AutoWidthColumns, column)
    end
    
    DTable:Add(self.Columns, column)
    return column
end

--- Gets column configuration by index.
-- @param index (number): Column index (1-based)
-- @return (table): Column object or nil if not found
function LISTVIEW:GetColumn(index)
    return self.Columns[index]
end

--- Sets the width of a column.
-- @param columnIndex (number): Column index (1-based)
-- @param width (number): New column width in pixels
function LISTVIEW:SetColumnWidth(columnIndex, width)
    local column = self.Columns[columnIndex]
    if (not column) then
    	return
    end
    
    column.Width = width
    column.IsAutoWidth = false  -- Disable auto-width
    
    -- Remove from auto-width tracking
    for i, col in ipairs(self.AutoWidthColumns) do
        if col == column then
            DTable:Remove(self.AutoWidthColumns, i)
            break
        end
    end
    
    self:InvalidateLayout()
end

--- Gets the width of a column.
-- @param columnIndex (number): Column index (1-based)
-- @return (number): Column width in pixels or nil if not found
function LISTVIEW:GetColumnWidth(columnIndex)
    local column = self.Columns[columnIndex]
    return column and column.Width or nil
end

--- Removes all columns from the ListView.
-- This also clears auto-width column tracking.
function LISTVIEW:ClearColumns()
    self.Columns = { }
    self.AutoWidthColumns = { }
end

--- Calculates and distributes width for auto-sized columns.
-- Fixed-width columns retain their size. Remaining space is split
-- equally among auto-width columns within their min/max constraints.
-- @internal Called automatically in PerformLayout()
function LISTVIEW:CalculateColumnWidths()
    local totalWidth = self:GetWide()
    local usedWidth = self.Padding * 2
    
    -- Calculate used width from fixed columns
    for _, col in _ipairs(self.Columns) do
        if (not col.IsAutoWidth) then
            usedWidth = usedWidth + col.Width
        end
    end
    
    -- Distribute remaining width among auto-width columns
    local autoWidthCount = #self.AutoWidthColumns
    if (autoWidthCount > 0) then
        local remainingWidth = totalWidth - usedWidth
        local widthPerColumn = remainingWidth / autoWidthCount
        
        for _, col in _ipairs(self.AutoWidthColumns) do
            col.Width = _Clamp(widthPerColumn, col.MinWidth, col.MaxWidth)
        end
    end
end

--- Updates cached state flags for all lines.
-- Sets IsLast flag for last row rounded corners.
-- @internal Called after AddLine, RemoveLine, SortByColumn, Clear
function LISTVIEW:UpdateLineStates()
    local lineCount = #self.Lines
    
    for i, line in _ipairs(self.Lines) do
        line.IsLast = (i == lineCount)
    end
end

--- Adds a data row to the ListView.
-- @param ... (vararg): Cell data matching column order. Can be any type (string, number, table)
-- @return (Panel): Line panel object with properties:
--   - Data (table): Array of cell values
--   - Cells (table): Array of cell panels
--   - Selected (boolean): Selection state
--   - VisualIndex (number): Current display position
--   - IsLast (boolean): Cached flag for last row
--   - DataLower (table): Cached lowercase strings for sorting
-- @usage list:AddLine('ID123', 'John Doe', {status = 'active'}, 25)
function LISTVIEW:AddLine(...)
    local data = {...}
    
    local line = DCustomUtils(self.ScrollPanel:GetCanvas())
    line:PinMargin(TOP, nil, nil, nil, DBase:Scale(1))
    line:SetTall(self.LineHeight)
    line:SetCursor('hand')
    
    line.Data = data
    line.ListView = self
    line.Cells = { }
    line.Selected = false
    line.ID = #self.Lines + 1
    line.VisualIndex = #self.Lines + 1
    line.IsLast = false
    
    -- Cache lowercase strings for faster sorting
    line.DataLower = { }
    for i, v in _ipairs(data) do
        if (_type(v) == 'string') then
            line.DataLower[i] = _lower(v)
        end
    end
    
    -- Shared event handlers instead of closures
    line:ApplyEvent('PerformLayout', LinePerformLayout)
    line:ApplyEvent(nil, LinePaint)
    line:ApplyEvent('OnMousePressed', LineMousePressed)
    line:ApplyEvent('Think', LineThink)
    
    DTable:Add(self.Lines, line)
    
    -- Update IsLast flags
    self:UpdateLineStates()
    
    return line
end

--- Creates cell panels for a line based on column definitions.
-- Cells with custom render functions enable mouse input for interaction.
-- @param line (Panel): Line panel to create cells for
-- @internal Called automatically on first Think() event
function LISTVIEW:CreateLineCells(line)
    local xOffset = self.Padding
    
    for i = 1, #self.Columns do
        local col = self.Columns[i]
        local cell = DCustomUtils(line)
        
        cell:SetMouseInputEnabled(false)
        
        cell.ColumnIndex = i
        cell.Line = line
        
        cell:SetPos(xOffset, 0)
        cell:SetSize(col.Width, self.LineHeight)
        
        -- Render custom content ONCE
        if col.Render then
            local cellData = line.Data[i]
            col.Render(line, cell, cellData)
            cell:SetMouseInputEnabled(true)
        end
        
        DTable:Add(line.Cells, cell)
        xOffset = xOffset + col.Width
    end
end

--- Renders text-only cells for a line.
-- Skips cells with custom render functions. Handles alignment and truncation.
-- @param line (Panel): Line panel to render
-- @param w (number): Line width
-- @param h (number): Line height
-- @internal Called automatically in Paint event
function LISTVIEW:RenderLine(line, w, h)
    local xOffset = self.Padding
    
    for i, column in _ipairs(self.Columns) do
        local cellData = line.Data[i]
        
        if (not column.Render and cellData ~= nil) then
            local text = _tostring(cellData)
            
            if column.Truncate then
                text = DUtils:TruncatedText(column.Width - DBase:Scale(10), text, column.Font)
            end
            
            local textX = xOffset + DBase:Scale(5)
            
            if (column.Align == TEXT_ALIGN_CENTER) then
                textX = xOffset + column.Width / 2
            elseif (column.Align == TEXT_ALIGN_RIGHT) then
                textX = xOffset + column.Width - DBase:Scale(5)
            end
            
            _drawSimpleText(text, column.Font, textX, h / 2, column.Color, column.Align, TEXT_ALIGN_CENTER)
        end
        
        xOffset = xOffset + column.Width
    end
end

--- Gets a line by index.
-- @param index (number): Line index (1-based)
-- @return (Panel): Line panel or nil if not found
function LISTVIEW:GetLine(index)
    return self.Lines[index]
end

--- Gets all lines in the ListView.
-- @return (table): Array of line panels
function LISTVIEW:GetLines()
    return self.Lines
end

--- Removes a specific line from the ListView.
-- @param line (Panel): Line panel to remove
function LISTVIEW:RemoveLine(line)
    for i, l in _ipairs(self.Lines) do
        if l == line then
            DTable:Remove(self.Lines, i)
            if _IsValid(l) then
                l:Remove()
            end
            
            -- Update IsLast flags after removal
            self:UpdateLineStates()
            break
        end
    end
end

--- Removes all lines from the ListView and clears selection.
function LISTVIEW:Clear()
    for _, line in _ipairs(self.Lines) do
        if _IsValid(line) then
            line:Remove()
        end
    end
    self.Lines = { }
    self.SelectedLines = { }
end

--- Enables or disables multi-row selection.
-- @param enabled (boolean): true for multi-select, false for single-select
function LISTVIEW:SetMultiSelect(enabled)
    self.MultiSelect = enabled
end

--- Selects a specific line programmatically.
-- @param line (Panel): Line panel to select
-- @param forceSelection (boolean): If true, selects even if already selected
function LISTVIEW:SelectItem(line, forceSelection)
    if (not IsValid(line)) then
    	return
    end
    
    if (not self.MultiSelect) then
        self:ClearSelection()
    end
    
    if (forceSelection or not line.Selected) then
        line.Selected = true
        DTable:Add(self.SelectedLines, line)
        
        if self.OnRowSelected then
            self:OnRowSelected(line, true)
        end
    end
end

--- Handles line selection toggle.
-- In single-select mode, deselects other lines. Fires OnRowSelected callback.
-- @param line (Panel): Line panel to toggle selection
-- @internal Called automatically on left-click
function LISTVIEW:OnLineSelected(line)
    if (not self.MultiSelect) then
        for _, l in _ipairs(self.Lines) do
            l.Selected = false
        end
        self.SelectedLines = { }
    end
    
    line.Selected = not line.Selected
    
    if line.Selected then
        DTable:Add(self.SelectedLines, line)
    else
        for i, l in _ipairs(self.SelectedLines) do
            if (l == line) then
                DTable:Remove(self.SelectedLines, i)
                break
            end
        end
    end
    
    if self.OnRowSelected then
        self:OnRowSelected(line, line.Selected)
    end
end

--- Gets the first selected line.
-- @return (Panel): First selected line panel or nil
function LISTVIEW:GetSelectedLine()
    return self.SelectedLines[1]
end

--- Gets all selected lines.
-- @return (table): Array of selected line panels
function LISTVIEW:GetSelectedLines()
    return self.SelectedLines
end

--- Deselects all lines.
function LISTVIEW:ClearSelection()
    for _, line in _ipairs(self.Lines) do
        line.Selected = false
    end
    self.SelectedLines = { }
end

--- Gets the currently sorted column index.
-- @return (number): Column index (1-based) or nil if not sorted
function LISTVIEW:GetSortedColumn()
    return self.SortColumn
end

--- Sorts lines by column data.
-- Supports numeric and string comparison. Uses cached lowercase strings.
-- Updates VisualIndex and IsLast flags after sort.
-- @param columnIndex (number): Column index to sort by (1-based)
-- @param descending (boolean): true for descending sort, false for ascending
function LISTVIEW:SortByColumn(columnIndex, descending)
    if (not self.Columns[columnIndex] or not self.Columns[columnIndex].Sortable) then
        return
    end
    
    self.SortColumn = columnIndex
    self.SortDescending = descending
    
    DTable:Sort(self.Lines, function(a, b)
        local valA = a.Data[columnIndex]
        local valB = b.Data[columnIndex]
        
        -- Handle nil values first
        if (valA == nil and valB == nil) then
            return false
        elseif (valA == nil) then
            return not descending -- nil values go to end
        elseif (valB == nil) then
            return descending
        end
        
        -- Handle tables - maintain original order
        if (_type(valA) == 'table' or _type(valB) == 'table') then
            return false
        end
        
        -- Try numeric comparison first
        local numA = _tonumber(valA)
        local numB = _tonumber(valB)
        
        if (numA and numB) then
            if descending then
                return numA > numB
            else
                return numA < numB
            end
        end
        
        -- String comparison with cached lowercase
        if (_type(valA) == 'string' and _type(valB) == 'string') then
            local lowerA = a.DataLower[columnIndex]
            local lowerB = b.DataLower[columnIndex]
            
            -- Use cached values if available, otherwise fallback to original
            lowerA = lowerA or _lower(valA)
            lowerB = lowerB or _lower(valB)
            
            if descending then
                return lowerA > lowerB
            else
                return lowerA < lowerB
            end
        end
        
        -- Mixed types - convert to string and compare
        local strA = _tostring(valA)
        local strB = _tostring(valB)
        
        if descending then
            return strA > strB
        else
            return strA < strB
        end
    end)
    
    -- Update VisualIndex and IsLast after sorting
    for i, line in _ipairs(self.Lines) do
        line.VisualIndex = i
        line:SetZPos(i)
    end
    
    -- Update IsLast flags after sort
    self:UpdateLineStates()
end

--- Recalculates layout when size changes.
-- Updates column widths and initializes header on first call.
-- @param w (number): New width
-- @param h (number): New height
-- @internal Called automatically by panel system
function LISTVIEW:PerformLayout(w, h)
    self:CalculateColumnWidths()
    
    if (not self.HeaderSetup) then
        self:SetupHeader()
        self.HeaderSetup = true
    end
end

--- Configures header panel with column rendering and click handlers.
-- @internal Called once in PerformLayout()
function LISTVIEW:SetupHeader()
    local header = self.Header
    local listView = self
    local hoverColumnIndex = nil
    
    header:ApplyEvent(nil, function(sl, w, h)
        local xOffset = listView.Padding
        local hasLines = #listView.Lines > 0
        
        -- Smooth corner transition
        local targetAlpha = hasLines and 0 or 1
        listView._headerCornerAlpha = Lerp(FrameTime() * 8, listView._headerCornerAlpha, targetAlpha)
        
        -- Background
        if (listView._headerCornerAlpha > 0.01) then
            DUtils:DrawRoundedBottomBox(0, 0, w, h, DBase:Theme('secondary_dark')) -- Fully rounded (when empty)
        else
            DUtils:DrawRoundedTopBox(0, 0, w, h, DBase:Theme('secondary_dark')) -- Top only (when has lines)
        end
        
        for i, column in _ipairs(listView.Columns) do
            if column.HeaderRender then
                column.HeaderRender(sl, xOffset, 0, column.Width, h, column)
            else
                local headerText = DUtils:TruncatedText(column.Width - DBase:Scale(20), column.Name, 'danlib_font_18')
                local textX = xOffset + DBase:Scale(5)
                local align = column.Align
                
                if (align == TEXT_ALIGN_CENTER) then
                    textX = xOffset + column.Width / 2
                elseif (align == TEXT_ALIGN_RIGHT) then
                    textX = xOffset + column.Width - DBase:Scale(5)
                end
                
                _drawSimpleText(headerText, 'danlib_font_18', textX, h / 2, DBase:Theme('text'), align, TEXT_ALIGN_CENTER)
            end
            
            xOffset = xOffset + column.Width
        end
        
        DUtils:DrawRect(0, h - 1, w, 1, DBase:Theme('line_up'))
    end)
    
    header:ApplyEvent('Think', function(sl)
        if (not sl:IsHovered()) then
            sl:SetCursor('arrow')
            return
        end
        
        local mouseX = sl:CursorPos()
        local xOffset = listView.Padding
        
        for i, column in _ipairs(listView.Columns) do
            if (mouseX >= xOffset and mouseX <= xOffset + column.Width) then
                -- Changing the cursor depending on sortable
                if column.Sortable then
                    sl:SetCursor('hand')
                else
                    sl:SetCursor('arrow')
                end
                
                break
            end
            xOffset = xOffset + column.Width
        end
    end)
    
    header:ApplyEvent('OnMousePressed', function(sl, code)
        if (code ~= MOUSE_LEFT) then
            return
        end
        
        local mouseX = sl:CursorPos()
        local xOffset = listView.Padding
        
        for i, column in _ipairs(listView.Columns) do
            if column.Sortable then
                if (mouseX >= xOffset and mouseX <= xOffset + column.Width) then
                    local descending = false
                    if (listView.SortColumn == i) then
                        descending = not listView.SortDescending
                    end
                    listView:SortByColumn(i, descending)
                    break
                end
            end
            
            xOffset = xOffset + column.Width
        end
    end)
end

--- Handles right-click on a line. Fires OnRowRightClick callback.
-- @param line (Panel): Line panel that was right-clicked
-- @internal Called automatically on right-click
function LISTVIEW:OnLineRightClick(line)
    if self.OnRowRightClick then
        self:OnRowRightClick(line)
    end
end

--- Shows or hides the header panel.
-- @param hide (boolean): true to hide header, false to show
function LISTVIEW:SetHideHeaders(hide)
    self.Header:SetVisible(not hide)
    
    if hide then
        self.Header:SetTall(0)
    else
        self.Header:SetTall(self.HeaderHeight)
    end
end

--- Gets the height of data rows.
-- @return (number): Line height in pixels
function LISTVIEW:GetDataHeight()
    return self.LineHeight
end

--- Sets the height for all lines.
-- @param height (number): Line height in pixels (will be scaled by DBase:Scale)
function LISTVIEW:SetLineHeight(height)
    self.LineHeight = DBase:Scale(height)
    for _, line in _ipairs(self.Lines) do
        line:SetTall(self.LineHeight)
    end
end

--- Sets the header height.
-- @param height (number): Header height in pixels (will be scaled by DBase:Scale)
function LISTVIEW:SetHeaderHeight(height)
    self.HeaderHeight = DBase:Scale(height)
    self.Header:SetTall(self.HeaderHeight)
end

LISTVIEW:Register('DanLib.UI.ListView')






-- A simple example
local function ListView()
    if _IsValid(DanLib.ListView) then
        DanLib.ListView:Remove()
    end

    local frame = DBase.CreateUIFrame()
    frame:SetSize(1000, 600)
    frame:SetTitle('A data view with rows and columns.')
    frame:Center()
    frame:MakePopup()
    DanLib.ListView = frame

    local list = DCustomUtils(frame, 'DanLib.UI.ListView')
    list:Pin(FILL, 10)
    -- list:SetHideHeaders(true)

    -- Fixed-width columns
    list:AddColumn('ID', {
        width = DBase:Scale(130),
        font = 'danlib_font_16'
    })

    list:AddColumn('Reporter', {
        width = DBase:Scale(220),
        sortable = true,
        render = function(line, cell, data)
            if (not data) then
            	return
            end
            
            -- Create an avatar ONCE
            if (not cell.Avatar) then
                cell.Avatar = DCustomUtils(cell)
                cell.Avatar:ApplyAvatar() -- rounded
                cell.Avatar:SetSteamID(data.sid64, 32)
                cell.Avatar:SetSize(32, 32)
                cell:ApplyEvent('PerformLayout', function(sl)
			        cell.Avatar:SetPos(0, (sl:GetTall() - cell.Avatar:GetTall()) / 2)
			    end)
            end
            
            -- Text
            cell:ApplyEvent(nil, function(sl, w, h)
                _drawSimpleText(data.name, 'danlib_font_16', 40, h/2 - 8, DBase:Theme('title'), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                _drawSimpleText(data.steamid, 'danlib_font_14', 40, h/2 + 8, DBase:Theme('text'), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end)
        end
    })

    list:AddColumn('Reported', {
        width = DBase:Scale(200),
        sortable = true,
        render = function(line, cell, data)
            if (not data or cell.Created) then
            	return
            end

            cell.Created = true
            cell:ApplyEvent(nil, function(sl, w, h)
                DUtils:DrawRoundedBox(0, 6, 26, 26, _Color(200, 50, 50))
                _drawSimpleText(_tostring(data.count or '?'), 'danlib_font_14', 14, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                _drawSimpleText(data.name, 'danlib_font_16', 32, h/2 - 8, DBase:Theme('title'), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                _drawSimpleText(data.steamid, 'danlib_font_14', 32, h/2 + 8, DBase:Theme('text'), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end)
        end
    })

    list:AddColumn('Reason', {
        width = DBase:Scale(180),
        sortable = true,
        font = 'danlib_font_16'
    })

    list:AddColumn('Waiting Time', {
        width = DBase:Scale(140),
        sortable = true,
        align = TEXT_ALIGN_CENTER,
    })

    list:AddColumn('Status', {
        align = TEXT_ALIGN_CENTER,
        render = function(line, cell, status)
            if (not status or cell.Created) then
            	return
            end

            cell.Created = true
            cell:ApplyEvent(nil, function(sl, w, h)
                local colors = {
                    ['Active'] = DBase:Theme('decor'),
                    ['Closed'] = _Color(100, 100, 100),
                    ['Punished'] = _Color(200, 50, 50)
                }
                
                local col = colors[status] or _Color(100, 100, 100)
                local badgeW = _min(w - 20, DBase:Scale(90))
                DUtils:DrawRoundedBox((w - badgeW)/2, h/2 - 12, badgeW, 24, col)
                _drawSimpleText(status, 'danlib_font_16', w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end)
        end
    })

    list:AddColumn('Actions', {
        render = function(line, cell, data)
            -- We create the buttons ONCE
            if (not cell.ViewBtn) then
                cell.ViewBtn = DBase.CreateUIButton(cell, {
                    icon = { Material('icon16/eye.png'), color_white, 16 },
                    size = { 28, 28 },
                    pos = { 2, 4 },
                    sound = false,
                    click = function()
                        print('View:', line.Data[1])
                    end
                })
            end
            
            if (not cell.MenuBtn) then
                cell.MenuBtn = DBase.CreateUIButton(cell, {
                    text = {'•••', 'danlib_font_20'},
                    size = { 28, 28 },
                    pos = { 36, 4 },
                    sound = false,
                    click = function()
                        print('Menu:', line.Data[1])
                    end
                })
            end
        end
    })

    -- A simple random option
	local names = { 'CastleKeeper', 'PlayerOne', 'ShadowHunter', 'NightWolf', 'DragonSlayer', 'PhoenixRising', 'IceQueen', 'ThunderBolt', 'StarGazer', 'MoonWalker' }
	local reasons = { 'Exploiting', 'NLR', 'RDM', 'FailRP', 'Mic Spam', 'Aimbot', 'Prop Block', 'AFK Farm', 'Metagaming', 'Trolling' }
	local statuses = { 'Active', 'Closed', 'Punished' }

	for i = 1, 20 do
	    list:AddLine('17639858680' .. _format('%03d', i),
	        {
	            name = names[_random(#names)],
	            steamid = _format('STEAM_0:%d:%d', i % 2, 100000 + i * 1000),
	            sid64 = '765611' .. _format('%011d', 98000000 + i * 10000)
	        },
	        {
	            name = names[_random(#names)],
	            steamid = _format('STEAM_0:%d:%d', (i+1) % 2, 200000 + i * 2000),
	            count = _random(1, 8)
	        },
	        reasons[_random(#reasons)],
	        _format('%dm %02ds', _random(2, 28), _random(10, 59)),
	        statuses[(i % 3) + 1]
	    )
	end

    -- Callbacks
    list:ApplyEvent('OnRowSelected', function(sl, line, selected)
        print('Selected:', line.Data[1], selected)
    end)
    
    list:ApplyEvent('OnRowSelected', function(sl, line)
        print('Right clicked:', line.Data[1])
    end)
end
-- ListView()