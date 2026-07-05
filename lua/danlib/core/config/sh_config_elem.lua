/***
 *   @addon         DanLib
 *   @component     Config
 *   @license       MIT License
 *   @version       3.0.0
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
 


-- Primary colours
-- This section defines the basic colour schemes used in the interface.
DanLib.Config.Theme = DanLib.Config.Theme or { }
DanLib.Config.Theme = {
    ['White'] = Color(255, 255, 255), -- White
    ['DarkGray'] = Color(47, 54, 64), -- Dark grey
    ['Gray'] = Color(113, 128, 147), -- Grey
    ['Red'] = Color(255, 69, 0), -- Red colour
    ['DarkRed'] = Color(181, 50, 50), -- Dark red colour
    ['LightRed'] = Color(232, 65, 24), -- Light red colour
    ['DarkBlue'] = Color(64, 115, 158), -- Dark blue colour
    ['Blue'] = Color(0, 151, 230), -- Blue colour
    ['DarkGreen1'] = Color(68, 189, 50), -- Dark green colour
    ['Green'] = Color(0, 255, 0), -- Green colour
    ['DarkGreen'] = Color(39, 174, 96), -- Dark green colour
    ['Yellow'] = Color(251, 197, 49), -- Yellow colour
    ['Gold'] = Color(201, 176, 55), -- Golden colour
    ['Silver'] = Color(180, 180, 180), -- Silver colour
    ['Bronze'] = Color(173, 138, 86), -- Bronze colour
    ['DarkOrange'] = Color(255, 140, 0), -- Dark orange colour
    ['DodgerBlue'] = Color(30, 144, 255), -- Dodger colour
}

--- Retrieves a colour from DanLib.Config.Theme by name.
-- Mirrors the DBase:Theme(key, alpha) pattern for the raw palette table.
-- @param name (string) Key in DanLib.Config.Theme, e.g. 'Red', 'Gold'.
-- @param alpha (number|nil) Optional alpha override (0–255). Creates a new Color so the palette entry itself is never mutated.
-- @return Color The requested colour, or Color(0,0,0,255) if not found.
function DanLib.Func:GetColor(name, alpha)
    local c = DanLib.Config.Theme[name]
    if (not c) then
        return Color(0, 0, 0, alpha or 255)
    end

    if alpha then
        return Color(c.r, c.g, c.b, alpha)
    end
    return c
end

-- Basic sounds
-- This section defines the sounds used in the various actions of the interface.
DanLib.Config.Sound = DanLib.Config.Sound or { }
DanLib.Config.Sound = {
    ['ClickButton'] = Sound('danlib/click2.wav'), -- Sound of a button being pressed
    ['Navigation'] = Sound('danlib/synopsis.mp3'), -- Navigation sound
    ['button-click'] = Sound('ddi/button-click.wav'), -- Button click sound
    ['button-hover'] = Sound('ddi/button-hover.wav'), -- Button pointing sound
    ['click-hover'] = Sound('ddi/click-hover.wav'), -- Click sound when pointing
    ['notifications'] = Sound('ddi/notifications.wav'), -- Notification sound
    ['error'] = Sound('ddi/error.mp3'), -- Error sound
}

-- Basic materials (icons)
-- This section contains the materials used for icons in the interface.
DanLib.Config.Materials = DanLib.Config.Materials or { }
DanLib.Config.Materials = {
    ['Module']          = '4on53Ef', -- Module icon
    ['User']            = 'iUXCfUK', -- User icon
    ['Users']           = 'TP4DSDw', -- User icon
    ['Admin']           = 'L4eqghL', -- Administrator icon
    ['Search']          = 'R4qkeG5',
    ['Close']           = 'She8xJ5',
    ['Settings']        = 'l0pYMcX',
    ['Ok']              = 'M7CgANR',
    ['Link']            = 'irIrtWn',
    ['box']             = 'Gv2bPhD',
    ['Information']     = 'Oqh2IcD',
    ['Arrow']           = 'PvPag9O',
    ['Up-Arrow']        = 'UgzEn0C',
    ['LeftArrow']       = '6kIZNbu',
    ['RightDown']       = 'LZ7kvs1',
    ['Warning']         = 'RitchEz',
    ['Loading']         = 'WodBmpe',
    ['Lock']            = 's4ninvB',
    ['AdminSetings']    = 'q19G9ag',
    ['Image']           = 'FrCS4x6',
    ['World']           = 'CfeOKK6',
    -- ['Search']          = 'SJ27tx8',
    ['Reset']           = 'Eqb2vcp',
    ['Edit']            = 'yeMohp9',
    ['Notifi']          = 'GMJq2Ps',
    ['Add']             = '1P9nWXt',
    ['Delete']          = 'Xfkr9Wh',
    ['LMouse']          = '6ALXJGo',
    ['RMouse']          = 'wteAWHK',
    ['ScrollM']         = 'JOMHB8C',
    ['gCircle']         = 'Ob63sVK',
    ['Color']           = 'WM5Z1ZJ',
    ['Error']           = 'guArjM3',
    ['Debug']           = 'oABaJ7r',
    ['Info']            = '2ozta79',
    ['Confirm']         = 'KaL0bD8',
    ['Copy']            = 'C1bpjkc',

    -- Other
    ['Blur']            = Material('pp/blurscreen'), -- blur
    ['vCircle']         = Material('vgui/circle'),

    -- predefined materials
    -- list of internal gmod mat paths
    ['pp_blur']         = Material('pp/blurscreen'),
    ['pp_blur_m']       = Material('pp/motionblur'),
    ['pp_blur_x']       = Material('pp/blurx'),
    ['pp_blur_y']       = Material('pp/blury'),
    ['pp_blur_b']       = Material('pp/bokehblur'),
    ['pp_copy']         = Material('pp/copy'),
    ['pp_add']          = Material('pp/add'),
    ['pp_sub']          = Material('pp/sub'),
    ['pp_clr_mod']      = Material('pp/colour'),
    ['alpha_grid']      = Material('gui/alpha_grid.png', 'nocull'),
    ['clr_white']       = Material('vgui/white'),
    ['circle']          = Material('vgui/circle'),
    ['grad_center']     = Material('gui/center_gradient'),
    ['grad']            = Material('gui/gradient'),
    ['grad_up']         = Material('gui/gradient_up'),
    ['grad_down']       = Material('gui/gradient_down'),
    ['grad_l']          = Material('vgui/gradient-l'),
    ['grad_r']          = Material('vgui/gradient-r'),
    ['grad_u']          = Material('vgui/gradient-u'),
    ['grad_d']          = Material('vgui/gradient-d'),

    -- predefined corners
    ['corner_8']        = Material('gui/corner8'),
    ['corner_16']       = Material('gui/corner16'),
    ['corner_32']       = Material('gui/corner32'),
    ['corner_64']       = Material('gui/corner64'),
    ['corner_512']      = Material('gui/corner512'),
}

-- Configuration of chat types
-- This section defines the message types and their colours for chat.
DanLib.BaseConfig.ChatType = DanLib.BaseConfig.ChatType or { }
DanLib.BaseConfig.ChatType = {
    NONE_COLOR = color_white, -- Colour for an empty message

    SUCCESS_MSG = 'Successfully', -- Success message
    SUCCESS_COLOR = Color(83, 199, 0), -- Colour for success message

    WARNING_MSG = 'Attention', -- Warning message
    WARNING_COLOR = Color(255, 129, 56), -- Colour for warning message

    ERROR_MSG = 'Mistake', -- Error message
    ERROR_COLOR = Color(255, 69, 0), -- Colour of the error message

    MESSAGES_TYPE = { 
        NONE = 0 --[[ No message ]], 
        SUCCESS = 1 --[[ Successful message ]], 
        WARNING = 2 --[[ Warning message ]], 
        ERROR = 3 --[[ Error message ]], 
        RP = 4 --[[ RP message ]],
    }
}

-- Constants for message types
DANLIB_TYPE_DEBUG = 0 -- Debug type
DANLIB_TYPE_INFO = 1 -- Information type
DANLIB_TYPE_WARNING = 2 -- Warning type
DANLIB_TYPE_ERROR = 3 -- Error type
DANLIB_TYPE_ADMIN = 4 -- Administrator type
DANLIB_TYPE_USER = 5 -- User type
DANLIB_TYPE_CONFIRM = 6 -- Confirmation type
DANLIB_TYPE_NOTIFICATION = 7 -- Notification type
DANLIB_TYPE_RP = 8 -- RP type
DANLIB_TYPE_SERVER = 9 -- Server type

FORMAT_PLAYER = 0
FORMAT_WEAPON = 1
FORMAT_ENTITY = 2
FORMAT_PROP = 3
FORMAT_RAGDOLL = 4
FORMAT_CURRENCY = 5
FORMAT_COUNTRY = 6
FORMAT_AMMO = 7
FORMAT_TEAM = 8
FORMAT_USERGROUP = 9
FORMAT_STRING = 10
FORMAT_HIGHLIGHT = 11
FORMAT_ROLE = 12
FORMAT_VEHICLE = 13
FORMAT_DAMAGE = 14

-- Permissions
DanLib.BaseConfig.RanksMax = 15
DanLib.BaseConfig.Permissions = DanLib.BaseConfig.Permissions or { }
-- DanLib.BaseConfig.Permissions['EditSettings'] = 'Permission to edit the configuration.'
-- DanLib.BaseConfig.Permissions['EditRanks'] = 'Permission to edit ranks.'
-- DanLib.BaseConfig.Permissions['AdminPages'] = 'Permission to view pages for administrators.'
-- DanLib.BaseConfig.Permissions['ViewHelp'] = 'Permissions to view the page and other help items.'
-- DanLib.BaseConfig.Permissions['Tutorial'] = 'Permission to view the textbook.'

-- Initialising the key binding menu
DanLib.KEY_BIND_MENU = DanLib.KEY_BIND_MENU or { }
DanLib.KEY_BIND_MENU = {
    ['F1'] = true, -- Switching on F1
    ['F2'] = true, -- Switching on F2
    ['F3'] = true, -- Switching on F3
    ['F4'] = true, -- Switching on F4
    ['OFF'] = true, -- Deactivation of binding
}

-- Initialising the list of bound keys
DanLib.KEY_BINDS = DanLib.KEY_BINDS or { }
DanLib.KEY_BINDS = {
    -- Numbers
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    -- Буквы
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    -- Numpad keys
    'Numpad 0', 'Numpad 1', 'Numpad 2', 'Numpad 3', 'Numpad 4', 'Numpad 5', 'Numpad 6', 'Numpad 7', 'Numpad 8', 'Numpad 9', 
    'Numpad /', 'Numpad *', 'Numpad -', 'Numpad +', 'Numpad Enter', 'Numpad .',
    -- Special characters
    '(', ')', ';', "'", '`', ',', '.', '/', [[\]], '-', '=',
    -- Control keys
    'Enter', 'Space', 'Backspace', 'Tab', 'Capslock', 'Numlock', 'Escape', 'Scrolllock',
    'Insert', 'Delete', 'Home', 'End', 'Pageup', 'Pagedown', 'Break',
    'Left Shift', 'Right Shift', 'Alt', 'Right Alt', 'Left Control','Right Control', 'Left Windows', 'Right Windows',
    -- Arrow keys
    'App', 'Up', 'Left', 'Down', 'Right',
    -- Function keys
    'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12',
    -- Mouse buttons
    'Mouse 1' --[[ Left click ]], 'Mouse 2' --[[ Right click ]], 'Mouse 3' --[[ Middle click (wheel) ]], 'Mouse 4' --[[ Additional button 1 ]], 'Mouse 5' --[[ Additional button 2 ]],
    -- Additional functions
    'Capslock Toggle', 'Numlock Toggle', 'Last', 'Count'
}

-- Initialisation of message types with relevant material
DanLib.TYPE = DanLib.TYPE or { }
DanLib.TYPE = {
    ['DEBUG'] = DanLib.Config.Materials['Debug'], -- Debugging material
    ['INFO'] = DanLib.Config.Materials['Info'], -- Material for information
    ['WARNING'] = DanLib.Config.Materials['Warning'], -- Material for warnings
    ['ERROR'] = DanLib.Config.Materials['Error'], -- Material for errors
    ['ADMIN'] = DanLib.Config.Materials['Admin'], -- Material for administrators
    ['USER'] = DanLib.Config.Materials['User '], -- Material for users
    ['CONFIRM'] = DanLib.Config.Materials['Ok'], -- Material for confirmations
    ['NOTIFICATION'] = DanLib.Config.Materials['Notifi'] -- Material for notifications
}

-- Initialising colours for message types
DanLib.TYPE_COLOR = DanLib.TYPE_COLOR or { }
DanLib.TYPE_COLOR = {
    ['DEBUG'] = DanLib.Config.Theme['LightRed'], -- Colour for debugging
    ['INFO'] = DanLib.Config.Theme['DarkBlue'], -- Colour for information
    ['WARNING'] = DanLib.Config.Theme['Gold'], -- Colour for warnings
    ['ERROR'] = DanLib.Config.Theme['Red'], -- Colour for errors
    ['ADMIN'] = DanLib.Config.Theme['DodgerBlue'], -- Colour for administrators
    ['USER'] = DanLib.Config.Theme['Bronze'], -- Colour for users
    ['CONFIRM'] = DanLib.Config.Theme['Green'], -- Colour for confirmations
    ['NOTIFICATION'] = DanLib.Config.Theme['Yellow'] -- Colour for notifications
}

-- Initialisation of entity types
DanLib.BaseConfig.EntityTypes = DanLib.BaseConfig.EntityTypes or { }
DanLib.BaseConfig.EntityTypes['ddi_npc_spawn'] = {
    -- Function for retrieving entity data
    GetDataFunc = function(entity) 
        return entity:GetNPCKeyVar() or 0 -- Returns the value of the NPC key or 0 if it does not exist
    end,
    -- Function for setting entity data
    SetDataFunc = function(entity, data) 
        return entity:SetNPCKey(data or 0) -- Sets the value of the NPC key, default is 0
    end
}

-- Initialisation of entity type functions
DanLib.BaseConfig.EntityTypesFunc = DanLib.BaseConfig.EntityTypesFunc or { }
DanLib.BaseConfig.EntityTypesFunc['default_menu'] = {
    -- Function for using the menu
    UseFunc = function(pPlayer, ent, key)
        DanLib.Net:Open('DanLib:BaseMenu')
            :UInt(key, 8)
            :Send(pPlayer)
    end
}

-- Initialising the textbook configuration in the base configuration
DanLib.BaseConfig.Tutorials = DanLib.BaseConfig.Tutorials or { }
DanLib.BaseConfig.Tutorials = {
    [1] = {
        -- The title of the first textbook
        Title = 'Fundamentals',
        -- Textbook steps
        Steps = {
            [1] = 'Open the menu. To do this, simply type the command (! /) danlibmenu into the game chat. If you see this, re-enter the menu after resetting the tutorial.',
            [2] = 'Great! You have completed the first step by opening the menu. Do not close the menu until the chapter is completely finished! If you close the menu, you will have to go through the chapter steps all over again!\n\nIf you want to go through the whole course again, click on Help => TUTORIAL, then confirm and the whole process will be reset, then re-enter the menu.',
            [3] = 'Also for convenience, whenever DanLib updates are released, you will be notified that a new version has been released and new chapters will appear to make it easier for you to learn.\n\nNote that this window displays the entire process in the upper right corner and the chapter description in the upper left corner.',
            [4] = 'All right! Now we can get down to business!\n\nPress "Further" to get started.'
        },
        -- Indicates that you can proceed to the next step
        Further = true
    },
    [2] = { 
        Title = 'Dashboard',
        Steps = {
            [1] = "There's nothing here =) But there will be a lot of interesting stuff here soon.\n\nGo to the ‘Chat Commands’ page.",
        },
        Further = false
    },
    [3] = { 
        Title = 'Chat Commands',
        Steps = {
            [1] = 'This page displays all chat commands registered in DanLib, with descriptions.\n\nTo copy a command, click on the icon on the right.',
            [2] = 'This way, you can easily copy to the clipboard and then paste into the in-game chat.\n\nYou can also use the input line to quickly search for a command by keyword.\n\nGo to the ‘Modules’ page to continue.'
        },
        Further = false
    },
    [4] = { 
        Title = 'Modules',
        Steps = {
            [1] = 'Great. On this page you will be able to view all available modules on your server. As well as modules that you can add to your server by clicking on the link provided.\n\nHover over and then click on any available module',
            [2] = "In the window that opens you can see who is the author, the author's name, and his SteamID 64, as well as the description and version of the module.\n\nYou can also copy the data by clicking on one of the above descriptions.",
            [3] = 'To close the window, click on any empty space.\n\nYou can also check if the module has been updated. To do this, click on the ‘Update’ button in the upper right corner.',
            [4] = "Oh, great! That's taken care of. Let's get to the most important part, which is customizing the menus and modules.\n\nGo to the ‘Settings’ page to continue.",
        },
        Further = false
    },
    [5] = { 
        Title = 'Settings',
        Steps = {
            [1] = 'At the top there is a panel with a brief description of the page and two buttons {color: 67, 156, 242}Save{/color:} and {color:209, 53, 62}Cancel{/color:}.\n\nAt the bottom there is a navigation bar. It contains tabs of modules, between which you can switch. In the tabs themselves, if you look at them, you can see the module description and version.\n\nAfter selecting the desired module, the configuration page appears.\n\nOn the left is the name and description, on the right is a field for Input, Checkbox and so on, as well as a button to reset. When the selected field is changed, the {color: 67, 156, 242}Save{/color:} and {color: 209, 53, 62}Cancel{/color:} buttons are unblocked, and a notification appears on the bottom left, where you can click on it and it will show you where the changes have been made.\n\nPerform the first setup and save the configuration. To continue.',
            [2] = "Okay. Let's briefly go through the default settings.\n\n– {color: 255, 165, 0}Tag{/color:} is mainly used for notification in game chat, console. There is no need to use other somvols such as []/‘|<>,’ and so on. It is always written at the beginning of a message.\n\n– {color: 255, 165, 0}Chat Command{/color:} opens the main menu. The default command is `danlibmenu`. You don't need to use the symbology above here either. The defaults are / and !\n\n– {color: 255, 165, 0}Currency symbol{/color:}/{color: 255, 165, 0}Website{/color:}/{color: 255, 165, 0}discor link{/color:} can be omitted.\n\n– {color: 255, 165, 0}Debugging{/color:} notice appears in the middle at the bottom of the screen. Good for when you are testing scripts.\n\n– {color: 255, 165, 0}Languages{/color:}/{color: 255, 165, 0}Themes{/color:}/{color: 255, 165, 0}Open Menu{/color:} is an obvious one in itself.\n\n– {color: 255, 165, 0}NPC{/color:}, when you open the window you will see a button, clicking on it will create a new NPC and you can customise it - animations/name/model and functions it performs. To use it, use the tool.\n\n– {color: 255, 165, 0}Ranks{/color:} is one of the most important systems that allows you to use ranks to limit the use of systems. It is quite easy to set up. By default there are only 3 of them (Owner, Staff, Member). It is also quite easy to configure.\n\n– {color: 255, 165, 0}Logs{/color:} system that allows you to enter a log and send it to discord. It is also quite easy to set up.\n\n{font: danlib_font_16}{color: 0, 151, 230}You can read more information on the website.{/color:}{/font:}\n\nThat's a good place to end it. Go to the `Help` page to continue.",
        },
        Further = false
    },
    [6] = { 
        Title = 'Help',
        Steps = {
            [1] = 'This is where you can get help. In particular, links to read the documentation or join a guild.\n\nIf you want to contribute, you can go to the {color: 0, 151, 230}site{/color:} => {color: 0, 151, 230}login{/color:} => {color: 0, 151, 230}contribute{/color:} => {color: 0, 151, 230}report{/color:} => {color: 0, 151, 230}copy the unique key{/color:} => on the server open menu (chat command {color: 255, 140, 0}!ddi_contribution{/color:} - only available to Owner) and paste it into the input field, then click save. This will create a script report and send it to the developer.\n\nAlso, if you forget something important while going through the tutorial, you can always come back here and reload the tutorial to start it again.'
        },
        Further = true
    },
    [7] = { 
        Title = 'Conclusion',
        Steps = {
            [1] = "That's great! You have completed the short tutorial!\n\nNow you have the opportunity to customise everything to your liking. Don't be afraid to experiment!\n\n{color: 251, 197, 49}Good luck with your project!{/color:}"
        },
        Further = true
    }
}