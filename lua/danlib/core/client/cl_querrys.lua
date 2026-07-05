/***
 *   @addon         DanLib
 *   @component     UI Popup
 *   @license       MIT License
 *   @version       2.0.1
 *   @release_date  16/04/2023
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
local DUtils = DanLib.Utils
local DCustomUtils = DanLib.CustomUtils.Create

local vgui = vgui
local string = string
local upper = string.upper
local lerp = Lerp
local _IsValid = IsValid
local _Explode = string.Explode
local _stringformat = string.format
local _sub = string.gsub
local _select = select
local _max = math.max
local _ColorAlpha = ColorAlpha

local defaultFont = 'danlib_font_20'
local cancelColor = Color(236, 57, 62)
local confirmColor = Color(106, 178, 242)

if _IsValid(DANLIB_POPUPS) then
    DANLIB_POPUPS:Remove()
end

--- Calculate text dimensions using DanLib's markup parser
-- Uses DUtils.Create (CreateMarkup) internally - same as DrawParseText
-- @param text (string): Text with optional color tags
-- @param font (string): Font to use for measurement
-- @param maxWidth (number): Maximum width for text wrapping
-- @return table: {width, height}
local function CalculateTextDimensions(text, font, maxWidth)
    font = font or defaultFont
    maxWidth = maxWidth or 400

    -- We use DUtils:CreateMarkup (as in DrawParseText)
    local tempMarkup = DUtils:CreateMarkup(text, font, DBase:Theme('text'), maxWidth)
    return {
        width = tempMarkup:GetWidth(),
        height = tempMarkup:GetHeight()
    }
end

--- Displays a message pop-up with optional confirmation and cancellation buttons.
-- Automatically calculates height based on text content with color tag support.
-- @param title (string): The title of the pop-up
-- @param text (string): The description or message to display (supports color tags)
-- @param confirmText (string): The text for the confirmation button (default: "Confirm")
-- @param confirmFunc (function): The function to call when the confirmation button is clicked
-- @param cancelText (string): The text for the cancel button (default: "Cancel")
-- @param cancelFunc (function): The function to call when the cancel button is clicked
-- @param st (boolean): If true, the cancel button will not be displayed (default: false)
--
-- Example Usage:
--    DBase:QueriesPopup(
--        'DELETE CATEGORY',
--        'Are you sure you want to delete "{color:red}Prop Abuse{/color:}"?\n\n' ..
--        '{color:orange}Warning:{/color:} This cannot be undone!',
--        nil,
--        function() print('Confirmed!') end
--    )
function DBase:QueriesPopup(title, text, confirmText, confirmFunc, cancelText, cancelFunc, st)
    -- Set default values
    confirmText = confirmText or DBase:L('confirm')
    cancelText = cancelText or DBase:L('cancel')
    title = title or 'No text'
    text = text or 'No text'
    st = st or false

    -- Create the pop-up container
    local Container = DCustomUtils(nil, 'DanLib.UI.PopupBasis')
    DANLIB_POPUPS = Container
    Container:BackgroundCloseButtonShow(false)
    Container:CloseButtonShow(false)
    Container:SetHeader(upper(title))

    -- Calculating the height using CalculateTextDimensions
    local maxTextWidth = 400
    local textData = CalculateTextDimensions(text, defaultFont, maxTextWidth)

    -- Store for rendering
    Container.OriginalText = text
    Container.MaxTextWidth = maxTextWidth
    Container.buttonW = DBase:Scale(170)

    -- Adding padding for visual comfort
    local popupWidth = _max(450, textData.width + 50)
    local textAreaHeight = textData.height
    local buttonHeight = 30
    local gapBetweenTextAndButtons = 15
    local totalHeight = textAreaHeight + gapBetweenTextAndButtons + buttonHeight + 20

    Container:SetPopupWide(popupWidth)
    Container:SetExtraHeight(totalHeight)

    -- Create text area with proper height
    local textArea = DCustomUtils(Container)
    textArea:PinMargin(TOP, 10, 10)
    textArea:SetTall(textAreaHeight)
    textArea:ApplyEvent(nil, function(_, w, h)
        DUtils:DrawParseText(Container.OriginalText, defaultFont, w / 2, 0, DBase:Theme('text'), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, Container.MaxTextWidth, TEXT_ALIGN_CENTER)
    end)

    -- Create button container
    Container.ButtonContainer = DCustomUtils(Container)
    Container.ButtonContainer:PinMargin(BOTTOM, 10, 0, 10, 10)
    Container.ButtonContainer:SetTall(buttonHeight)

    -- Create cancel button if not suppressed
    if (not st) then
        Container.ButtonContainer.ButtonCancel = DBase.CreateUIButton(Container.ButtonContainer, {
            background = { nil },
            dock_indent = { RIGHT, 6 },
            wide = Container.buttonW,
            hover = { _ColorAlpha(cancelColor, 50), nil, 6 },
            text = { cancelText, defaultFont, nil, nil, cancelColor },
            click = function()
                Container:Close()
                if cancelFunc then
                    cancelFunc()
                end
            end
        })
    end

    -- Create confirm button
    Container.ButtonContainer.ButtonConfirm = DBase.CreateUIButton(Container.ButtonContainer, {
        background = { nil },
        dock_indent = { RIGHT, 6 },
        wide = Container.buttonW,
        hover = { _ColorAlpha(confirmColor, 50), nil, 6 },
        text = { confirmText, defaultFont, nil, nil, confirmColor },
        click = function()
            Container:Close()
            if confirmFunc then
                confirmFunc()
            end
        end
    })

    return Container
end

--- Displays a text input pop-up with optional confirmation and cancellation buttons.
-- Automatically calculates height based on text content with color tag support.
-- @param title (string): The title of the pop-up
-- @param text (string): The description or message to display (supports color tags)
-- @param default (string): The default text for the text entry field (default: '')
-- @param confirmText (string): The text for the confirmation button (default: "Confirm")
-- @param confirmFunc (function): The function to call when the confirmation button is clicked
-- @param cancelText (string): The text for the cancel button (default: "Cancel")
-- @param cancelFunc (function): The function to call when the cancel button is clicked
-- @param verification (function): Optional validation function(text) -> boolean
--
-- Example Usage:
--    DBase:RequestTextPopup(
--        'NEW CATEGORY',
--        'Enter the name for the new report category\n{color:gray}Example: "Prop Abuse", "RDM"{/color:}',
--        '',
--        nil,
--        function(input) print('User input:', input) end
--    )
function DBase:RequestTextPopup(title, text, default, confirmText, confirmFunc, cancelText, cancelFunc, verification)
    -- Setting default values
    default = default or ''
    confirmText = confirmText or DBase:L('confirm')
    cancelText = cancelText or DBase:L('cancel')
    title = title or 'No text'
    text = text or 'No text'

    -- Creating a container for a popup
    local Container = DCustomUtils(nil, 'DanLib.UI.PopupBasis')
    DANLIB_POPUPS = Container
    Container:BackgroundCloseButtonShow(false)
    Container:CloseButtonShow(false)
    Container:SetHeader(upper(title))
    Container.buttonW = DBase:Scale(150)

    -- Calculate text dimensions
    local maxTextWidth = 400
    local textData = CalculateTextDimensions(text, defaultFont, maxTextWidth)

    Container.OriginalText = text
    Container.MaxTextWidth = maxTextWidth

    -- Set dimensions
    local popupWidth = _max(450, textData.width + 50)
    local textAreaHeight = textData.height + 10
    local textEntryHeight = 30
    local buttonHeight = 30
    local gaps = 15
    local totalHeight = textAreaHeight + textEntryHeight + buttonHeight + gaps + 20

    Container:SetPopupWide(popupWidth)
    Container:SetExtraHeight(totalHeight)

    -- Text area
    local textArea = DCustomUtils(Container)
    textArea:PinMargin(TOP, 10, 10, 5)
    textArea:SetTall(textAreaHeight)
    textArea:ApplyEvent(nil, function(sl, w, h)
        DUtils:DrawParseText(Container.OriginalText, defaultFont, w / 2, 0, DBase:Theme('text'), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, Container.MaxTextWidth, TEXT_ALIGN_CENTER)
    end)

    -- Text entry
    Container.TextEntry = DBase.CreateTextEntry(Container)
    Container.TextEntry:PinMargin(TOP, 10, nil, 15)
    Container.TextEntry:SetTall(textEntryHeight)
    Container.TextEntry:SetValue(default)
    Container.TextEntry:SetUpdateOnType(true)
    Container.TextEntry:RequestFocus()

    -- Button container
    Container.ButtonContainer = DCustomUtils(Container)
    Container.ButtonContainer:PinMargin(BOTTOM, 10, nil, 10, 10)
    Container.ButtonContainer:SetTall(buttonHeight)

    -- Cancel button
    Container.ButtonContainer.ButtonCancel = DBase.CreateUIButton(Container.ButtonContainer, {
        background = { nil },
        dock_indent = { RIGHT, 6 },
        wide = Container.buttonW,
        hover = { _ColorAlpha(cancelColor, 50), nil, 6 },
        text = { cancelText, defaultFont, nil, nil, cancelColor },
        click = function()
            Container:Close()
            if cancelFunc then
                cancelFunc()
            end
        end
    })

    -- Confirm button
    Container.ButtonContainer.ButtonConfirm = DBase.CreateUIButton(Container.ButtonContainer, {
        background = { nil },
        dock_indent = { RIGHT, 6 },
        wide = Container.buttonW,
        hover = { _ColorAlpha(confirmColor, 50), nil, 6 },
        text = { confirmText, defaultFont, nil, nil, confirmColor },
        click = function()
            local val = Container.TextEntry:GetValue()
            Container:Close()
            if confirmFunc then
                confirmFunc(val)
            end
        end
    })

    -- Validation
    if verification then
        Container.TextEntry.textEntry:ApplyEvent('OnTextChanged', function(sl)
            local text = Container.TextEntry:GetValue()
            local isValid = verification(text)
            Container.TextEntry:SetVerification(not isValid)
            Container.ButtonContainer.ButtonConfirm:SetEnabled(isValid)
        end)
        local initialValid = verification(default)
        Container.TextEntry:SetVerification(not initialValid)
        Container.ButtonContainer.ButtonConfirm:SetEnabled(initialValid)
    end

    return Container
end

--- Displays a color selection pop-up using a color mixer with confirmation and cancellation options.
-- This pop-up allows the user to select a color and provides options to confirm or cancel the selection.
-- @param title (string): The title of the pop-up (default: 'RGB Colors').
-- @param default (Color): The initial color for the color mixer (default: Color(255, 255, 255, 255)).
-- @param confirmText (string): The text for the confirmation button (default: 'Confirm').
-- @param confirmFunc (function): The function to call when the confirmation button is clicked, receiving the selected color.
-- @param cancelText (string): The text for the cancel button (default: 'Cancel').
-- @param cancelFunc (function): The function to call when the cancel button is clicked.
--
-- Example Usage:
--    local function OnColorConfirmed(selectedColor)
--        print('Selected color:', selectedColor)
--    end
--
--    local function OnColorCanceled()
--        print('Color selection canceled.')
--    end
--
--    DanLib.Func:RequestColorChangesPopup(
--        'Choose a Color',              -- Title
--        Color(100, 150, 200),          -- Default color
--        'Confirm',                     -- Confirmation button text
--        OnColorConfirmed,              -- Confirmation callback
--        'Cancel',                      -- Cancel button text
--        OnColorCanceled                -- Cancellation callback
--    )
function DBase:RequestColorChangesPopup(title, default, confirmText, confirmFunc, cancelText, cancelFunc)
    default = default or Color(255, 255, 255, 255)
    title = title or 'RGB Colors'
    confirmText = confirmText or DBase:L('confirm')
    cancelText = cancelText or DBase:L('cancel')

    local Container = DCustomUtils(nil, 'DanLib.UI.PopupBasis')
    DANLIB_POPUPS = Container
    Container:BackgroundCloseButtonShow(false)
    Container:CloseButtonShow(false)
    Container:SetHeader(upper(title))
    Container.buttonW = DBase:Scale(150)
    Container:SetPopupWide(300)
    Container:SetExtraHeight(350)

    Container.MixerEntry = DCustomUtils(Container, 'DanLib.UI.ColorMixer')
    Container.MixerEntry:Pin(nil, 10)
    Container.MixerEntry:SetAlphaBar(true)
    Container.MixerEntry:SetWangs(true)
    Container.MixerEntry:SetPalette(true)
    Container.MixerEntry:SetColor(default)

    Container.ButtonContainer = DCustomUtils(Container)
    Container.ButtonContainer:PinMargin(BOTTOM, 10, nil, 10, 10)
    Container.ButtonContainer:SetTall(30)

    Container.ButtonContainer.ButtonCancel = DBase.CreateUIButton(Container.ButtonContainer, {
        background = { nil },
        dock_indent = { RIGHT, 6 },
        wide = Container.buttonW,
        hover = { _ColorAlpha(cancelColor, 50), nil, 6 },
        text = { cancelText, defaultFont, nil, nil, cancelColor },
        click = function()
            Container:Close()
            if cancelFunc then
                cancelFunc()
            end
        end
    })

    Container.ButtonContainer.ButtonConfirm = DBase.CreateUIButton(Container.ButtonContainer, {
        background = { nil },
        dock_indent = { RIGHT, 6 },
        wide = Container.buttonW,
        hover = { _ColorAlpha(confirmColor, 50), nil, 6 },
        text = { confirmText, defaultFont, nil, nil, confirmColor },
        click = function()
            local val = Container.MixerEntry:GetColor()
            Container:Close()
            if confirmFunc then
                confirmFunc(val)
            end
        end
    })

    return Container, Container.MixerEntry
end

--- Displays a combo box selection pop-up with optional confirmation and cancellation buttons.
-- Automatically calculates height based on text content with color tag support.
-- @param title (string): The title of the pop-up
-- @param text (string): The description or message to display (supports color tags)
-- @param options (table): Table of options for the combo box
-- @param default (any): The default selected option
-- @param confirmText (string): The text for the confirmation button (default: "Confirm")
-- @param confirmFunc (function): The function to call when the confirmation button is clicked
-- @param cancelText (string): The text for the cancel button (default: "Cancel")
-- @param cancelFunc (function): The function to call when the cancel button is clicked
--
-- Example Usage:
--    DBase:ComboRequestPopup(
--        'SELECT REASON',
--        'Choose the report category:\n{color:gray}This will be visible to all staff members{/color:}',
--        { 'RDM', 'RDA', 'Prop Abuse', 'Harassment' },
--        'RDM',
--        nil,
--        function(selected) print('Selected:', selected) end
--    )
function DBase:ComboRequestPopup(title, text, options, default, confirmText, confirmFunc, cancelText, cancelFunc)
    -- Setting default values
    options = options or {}
    default = default or nil
    confirmText = confirmText or DBase:L('confirm')
    cancelText = cancelText or DBase:L('cancel')
    title = title or 'No text'
    text = text or 'No text'

    -- Creating a container for a popup
    local Container = DCustomUtils(nil, 'DanLib.UI.PopupBasis')
    DANLIB_POPUPS = Container
    Container:BackgroundCloseButtonShow(false)
    Container:CloseButtonShow(false)
    Container:SetHeader(upper(title))
    Container.buttonW = DBase:Scale(150)

    -- Calculate text dimensions
    local maxTextWidth = 400
    local textData = CalculateTextDimensions(text, defaultFont, maxTextWidth)

    Container.OriginalText = text
    Container.MaxTextWidth = maxTextWidth

    -- Set dimensions
    local popupWidth = _max(450, textData.width + 50)
    local textAreaHeight = textData.height + 10
    local comboBoxHeight = 30
    local buttonHeight = 30
    local gaps = 15
    local totalHeight = textAreaHeight + comboBoxHeight + buttonHeight + gaps + 20

    Container:SetPopupWide(popupWidth)
    Container:SetExtraHeight(totalHeight)

    -- Text area
    local textArea = DCustomUtils(Container)
    textArea:PinMargin(TOP, 10, 10, 5)
    textArea:SetTall(textAreaHeight)
    textArea:ApplyEvent(nil, function(sl, w, h)
        DUtils:DrawParseText(Container.OriginalText, defaultFont, w / 2, 0, DBase:Theme('text'), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, Container.MaxTextWidth, TEXT_ALIGN_CENTER)
    end)

    -- Combo box
    Container.ComboBox = DBase.CreateUIComboBox(Container)
    Container.ComboBox:PinMargin(TOP, 10, nil, 15)
    Container.ComboBox:SetTall(comboBoxHeight)

    -- Populate combo box with options
    for k, v in pairs(options) do
        Container.ComboBox:AddChoice(v, k)
    end

    -- Set default value if provided
    if default then
        Container.ComboBox:SetValue(default)
    end

    -- Button container
    Container.ButtonContainer = DCustomUtils(Container)
    Container.ButtonContainer:PinMargin(BOTTOM, 10, nil, 10, 10)
    Container.ButtonContainer:SetTall(buttonHeight)

    -- Cancel button
    Container.ButtonContainer.ButtonCancel = DBase.CreateUIButton(Container.ButtonContainer, {
        background = { nil },
        dock_indent = { RIGHT, 6 },
        wide = Container.buttonW,
        hover = { _ColorAlpha(cancelColor, 50), nil, 6 },
        text = { cancelText, defaultFont, nil, nil, cancelColor },
        click = function()
            Container:Close()
            if cancelFunc then
                cancelFunc()
            end
        end
    })

    -- Confirm button
    Container.ButtonContainer.ButtonConfirm = DBase.CreateUIButton(Container.ButtonContainer, {
        background = { nil },
        dock_indent = { RIGHT, 6 },
        wide = Container.buttonW,
        hover = { _ColorAlpha(confirmColor, 50), nil, 6 },
        text = { confirmText, defaultFont, nil, nil, confirmColor },
        click = function()
            local selectedText, selectedData = Container.ComboBox:GetSelected()
            Container:Close()
            if confirmFunc then
                confirmFunc(selectedText, selectedData)
            end
        end
    })

    return Container
end

--- Displays a Lua code editor pop-up with confirmation and cancellation buttons.
-- Opens an in-game Lua editor (http://metastruct.github.io/lua_editor/) that allows
-- the user to view and modify code, then confirm (passing the edited code) or cancel.
-- @param title (string): The title of the pop-up
-- @param sCode (string): The initial code to pre-load into the editor
-- @param confirmText (string): The text for the confirmation button (default: "Confirm")
-- @param confirmFunc (function): Called on confirm — receives the edited code as first argument
-- @param cancelText (string): The text for the cancel button (default: "Cancel")
-- @param cancelFunc (function): Called on cancel (optional)
-- @param mode (string): Syntax highlighting mode (default: "glua")
--   Supported modes: "glua" (Garry's Mod Lua), "lua" (plain Lua), "text" (no highlighting)
--
-- Example Usage:
--    -- GLua (default)
--    DBase:EditorPopup('EDIT SCRIPT', 'print("Hello")', 'Save', function(code)
--        print('Saved:', code)
--    end)
--
--    -- Plain Lua syntax
--    DBase:EditorPopup('EDIT LUA', myCode, 'Save', function(code)
--        RunString(code)
--    end, nil, nil, 'lua')
--
--    -- Plain text (no highlighting)
--    DBase:EditorPopup('EDIT CONFIG', myJson, 'Save', function(code)
--        util.JSONToTable(code)
--    end, nil, nil, 'text')
function DBase:EditorPopup(title, sCode, confirmText, confirmFunc, cancelText, cancelFunc, mode)
    title = title or 'No text'
    sCode = sCode or ''
    confirmText = confirmText or DBase:L('confirm')
    cancelText = cancelText or DBase:L('cancel')
    mode = mode or 'glua'

    local Container = DCustomUtils(nil, 'DanLib.UI.PopupBasis')
    DANLIB_POPUPS = Container
    Container:BackgroundCloseButtonShow(false)
    Container:CloseButtonShow(false)
    Container:SetHeader(upper(title))
    Container.buttonW = DBase:Scale(150)
    Container:SetPopupWide(650)
    Container:SetExtraHeight(300)

    -- Raw vgui DHTML — no DanLib wrapper (needed for correct Chromium positioning)
    local editor = DCustomUtils(Container, 'DHTML')
    editor:Pin(nil, 6)
    editor:SetTall(240)
    editor.Code = sCode

    function editor:GetCode()
        return self.Code
    end

    function editor:JavascriptSafe(str)
        return str:gsub(".", {
            ["\\"] = "\\\\",
            ["\0"]  = "\\0",
            ["\b"]  = "\\b",
            ["\t"]  = "\\t",
            ["\n"]  = "\\n",
            ["\v"]  = "\\v",
            ["\f"]  = "\\f",
            ["\r"]  = "\\r",
            ["\""]  = "\\\"",
            ["\'"]  = "\\\'"
        })
        :gsub("\226\128\168", "\\\226\128\168")
        :gsub("\226\128\169", "\\\226\128\169")
    end

    function editor:SetCode(code)
        self.Code = code
        self:Call('SetContent(\"' .. self:JavascriptSafe(code) .. '\");')
    end

    -- OnReady: fired by the page JS when Ace Editor has fully initialised.
    -- Set the syntax mode, inject custom scrollbar CSS, then load the initial code.
    editor:AddFunction('gmodinterface', 'OnReady', function()
        if (not _IsValid(editor)) then
            return
        end

        editor:Call('SetMode("' .. mode .. '")')

        -- Build a CSS colour string from the DanLib theme accent colour
        local col = DBase:Theme('decor')
        local cssCol = _stringformat('rgba(%d,%d,%d,0.8)', col.r, col.g, col.b)
        local cssColH = _stringformat('rgba(%d,%d,%d,1.0)', col.r, col.g, col.b)

        -- Inject custom scrollbar: thin thumb only, no track, theme colour
        editor:Call([[
            (function() {
                var s = document.createElement('style');
                s.id = 'danlib-scrollbar';
                s.textContent = [
                    '.ace_scrollbar::-webkit-scrollbar { width: 6px; height: 4px; }',
                    '.ace_scrollbar::-webkit-scrollbar-track { background: transparent; }',
                    '.ace_scrollbar::-webkit-scrollbar-thumb { background: ]] .. cssCol .. [[; border-radius: 2px; }',
                    '.ace_scrollbar::-webkit-scrollbar-thumb:hover { background: ]] .. cssColH .. [[; }',
                    '.ace_scrollbar::-webkit-scrollbar-button { display: none; }'
                ].join('');
                document.head.appendChild(s);
            })();
        ]])

        if sCode ~= '' then
            editor:SetCode(sCode)
        end
    end)

    -- OnCode: fired on every keystroke — keep editor.Code in sync.
    editor:AddFunction('gmodinterface', 'OnCode', function(code)
        editor.Code = code
    end)

    editor:OpenURL('http://metastruct.github.io/lua_editor/')

    Container.ButtonContainer = DCustomUtils(Container)
    Container.ButtonContainer:PinMargin(BOTTOM, 10, nil, 10, 10)
    Container.ButtonContainer:SetTall(30)

    Container.ButtonContainer.ButtonCancel = DBase.CreateUIButton(Container.ButtonContainer, {
        background = { nil },
        dock_indent = { RIGHT, 6 },
        wide = Container.buttonW,
        hover = { _ColorAlpha(cancelColor, 50), nil, 6 },
        text = { cancelText, defaultFont, nil, nil, cancelColor },
        click = function()
            Container:Close()
            if cancelFunc then
                cancelFunc()
            end
        end
    })

    Container.ButtonContainer.ButtonConfirm = DBase.CreateUIButton(Container.ButtonContainer, {
        background = { nil },
        dock_indent = { RIGHT, 6 },
        wide = Container.buttonW,
        hover = { _ColorAlpha(confirmColor, 50), nil, 6 },
        text = { confirmText, defaultFont, nil, nil, confirmColor },
        click = function()
            local code = _IsValid(editor) and editor:GetCode() or sCode
            Container:Close()
            if confirmFunc then
                confirmFunc(code)
            end
        end
    })

    return Container
end