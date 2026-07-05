# DanLib

**A foundational library for Garry's Mod addons**, providing a unified infrastructure for networking, UI components, module configuration, themes, localization, and utilities. Developed since 2023 by **denchik** and **CastleKeeper**.

> **Version:** 3.4.0 · **License:** MIT · **Workshop ID:** `2418668622`

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Library Systems](#library-systems)
  - [Network Module](#network-module-danlibnет)
  - [Configuration & Modules](#configuration--modules)
  - [Themes](#themes)
  - [Localization](#localization)
  - [UI Components](#ui-components)
  - [Notifications](#notifications)
  - [Drawing & Shadows](#drawing--shadows)
  - [HTTP](#http)
  - [Ranks & Permissions](#ranks--permissions)
  - [Utilities](#utilities)
- [Built-in Admin Menu](#built-in-admin-menu)
- [Links](#links)

---

## Installation

### Manual

Extract the addon into your addons folder:
```
Steam\steamapps\common\GarrysMod\garrysmod\addons\DanLib\
```

### Server owners — Workshop collection (recommended)

The easiest way to deploy DanLib on a server is to add it to your server's **Steam Workshop collection**. If your server already uses a collection, simply open the [Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=2418668622) and click **"Add to collection"** — the addon will be downloaded automatically for all connecting players.

> If you don't have a collection yet, create one on the Steam Workshop and link it to your server via the `+host_workshop_collection <id>` launch parameter.

### Distributing to clients via Lua

Alternatively, call `resource.AddWorkshop` in a server-side Lua file, for example `garrysmod/lua/autorun/server/danlib_ws.lua`:

```lua
resource.AddWorkshop('2418668622')
```

> `resource.AddWorkshop` is a Lua function — it does not go in `server.cfg`.

### Verify it works

| Method | Command |
|---|---|
| Chat | `!danlibmenu` |
| Console | `danlibmenu` |

---

## Quick Start

DanLib loads automatically via `lua/autorun/init.lua`. No additional `include` or `AddCSLuaFile` calls are needed in your own addon — the library is already in the global namespace:

```lua
-- Main entry points:
DanLib.Func       -- core: themes, localization, scaling, config API
DanLib.Net        -- network module
DanLib.HTTP       -- HTTP requests
DanLib.Language   -- localization
DanLib.Hook       -- wrappers around hook.*
DanLib.Table      -- extensions to table.*
DanLib.Utils      -- general utilities
```

---

## Library Systems

### Network Module `DanLib.Net`

A single multiplexed channel `DanLib.Net.Channel` instead of many `util.AddNetworkString` calls. Fluent-builder API that works from `cl_*`, `sv_*`, and `sh_*` files without any additional registration.

```lua
-- Sending (SERVER → CLIENT)
DanLib.Net:Open('MyAddon.SomeEvent')
    :Str(playerName)
    :Int(score)
    :Bool(isWinner)
    :Send(ply) -- to a specific player
    -- :All() -- broadcast to everyone
    -- :Up() -- CLIENT → SERVER

-- Receiving (CLIENT)
DanLib.Net:On('MyAddon.SomeEvent', function(len, ply)
    local name = DanLib.Net:Str()
    local score = DanLib.Net:Int()
    local isWinner = DanLib.Net:Bool()
end)
```

**Available data types:**  
`:Str` `:Int(bits)` `:UInt(bits)` `:Bool` `:Ent` `:Tbl` `:Float` `:Vec` `:Ang` `:Col` `:Bit` `:Data(len)`

---

### Configuration & Modules

Register configuration modules for your addon — they will automatically appear in the admin menu.

```lua
-- Creating a module
local myModule = DanLib.Func.CreateModule('my_addon')
myModule:SetName('My Addon')
myModule:SetDescription('Addon description')
myModule:AddOption('MaxPlayers', DanLib.Type.Int, 16)
    :SetLabel('Max Players')
    :SetMin(1):SetMax(64)
myModule:Register()

-- Extending another addon's module from an external addon
DanLib.Func.ExtendModule('some_other_module', function(mod)
    mod:AddOption('MyExtraOption', DanLib.Type.Bool, false)
end)

-- Reading a value at runtime
local max = DanLib.CONFIG['my_addon']['MaxPlayers']
```

**Available types:** `DanLib.Type.Int` · `DanLib.Type.String` · `DanLib.Type.Bool` · `DanLib.Type.Table` · `DanLib.Type.Key`

---

### Themes

Three built-in themes: `default`, `dark_green`, `dark_orange`. All UI components read colors from the active theme automatically.

```lua
local myTheme = DanLib.Func.CreateTheme('my_theme')
myTheme:SetName('My Theme')
myTheme:SetAuthor('denchik')
myTheme:SetVersion('1.0')
myTheme:SetStrings({
    ['primary'] = Color(30, 144, 255),
    ['secondary'] = Color(20, 20, 30),
    ['text'] = Color(255, 255, 255),
})
myTheme:Register()

-- Get a color from the currently active theme
local col = DanLib.Func:Theme('primary')
```

---

### Localization

50+ languages supported. Players switch language in their personal settings directly inside the menu.

**Important:** the language key is the full English name (`'English'`, `'Russian'`), not an ISO code. Variable substitution in strings uses `{key}` placeholders, not `string.format`.

```lua
-- Registering strings for your addon
DanLib.Func.RegisterLanguage('English', {
    ['my_addon.hello'] = 'Hello, world!',
    ['my_addon.version'] = 'Version: {ver}',
})
DanLib.Func.RegisterLanguage('Russian', {
    ['my_addon.hello'] = 'Привет, мир!',
    ['my_addon.version'] = 'Версия: {ver}',
})

-- Getting a string in the player's active language
local text = DanLib.Func:L('my_addon.hello')

-- With variable substitution via a params table
local ver = DanLib.Func:L('my_addon.version', { ver = '1.0.0' })
-- → 'Version: 1.0.0'
```

---

### UI Components

A full set of VGUI elements with theme support, resolution scaling, and animations. Created via the standard `vgui.Create` call with the class name.

| VGUI Class | Description |
|---|---|
| `DanLib.UI.Frame` | draggable window with transparency support |
| `DanLib.UI.PopupBasis` | base popup panel without a title bar |
| `DanLib.UI.ColorButton` | button with icon and hover effects |
| `DanLib.UI.Input` | text entry field |
| `DanLib.UI.ComboBox` | dropdown list |
| `DanLib.UI.Checkbox` | checkbox |
| `DanLib.UI.Slider` | slider |
| `DanLib.UI.ColorMixer` | color picker (HSV) |
| `DanLib.UI.ColorPalette` | color palette |
| `DanLib.UI.RGBPicker` | RGB picker |
| `DanLib.UI.AlphaBar` | alpha/transparency bar |
| `DanLib.UI.ColorCube` | color cube |
| `DanLib.UI.Scroll` | vertical scroll panel |
| `DanLib.UI.HorizontalScroll` | horizontal scroll panel |
| `DanLib.UI.ScrollBar` | scroll bar |
| `DanLib.UI.Tabs` | tab strip |
| `DanLib.UI.Sidenav` | side navigation panel |
| `DanLib.UI.ListView` | list with columns |
| `DanLib.UI.ContextMenu` | context menu |

```lua
-- Example: window with a text field
local frame = vgui.Create('DanLib.UI.Frame')
frame:SetTitle('My Addon')
frame:SetSize(400, 300)
frame:Center()
frame:MakePopup()

local input = vgui.Create('DanLib.UI.Input', frame)
input:SetPos(10, 50)
input:SetSize(200, 30)
input:SetPlaceholderText('Type something...')
```

Custom panels are created via `DanLib.UiPanel()` — it returns a metatable that is registered with VGUI by calling `:Register('MyAddon.MyPanel')`.

---

### Notifications

Three display modes with smooth animations, icons, and markup tag support.

```lua
local DBase = DanLib.Func

-- Center notification (one at a time, replaces the previous)
DBase:ScreenNotification('Title', 'Message text', 'SUCCESS', 5)

-- Side notification (stacked, up to 8 simultaneously)
DBase:SidePopupNotification('Task completed!', 'INFO', 3)
DBase:SidePopupNotification('Critical error', 'ERROR', 5, 'BOTTOM_RIGHT')

-- Embedded inside a panel
DBase:CreateUIPopupNotifi(parentPanel, 'Title', 'Message', 'WARNING', 4)
```

**Icon types:** `ERROR` · `SUCCESS` · `WARNING` · `INFO` · `ADMIN`  
**Side positions:** `TOP_LEFT` · `TOP_RIGHT` · `BOTTOM_LEFT` · `BOTTOM_RIGHT`

---

### Drawing & Shadows

Shadow rendering system with per-instance render target caching — blur is only re-computed when size or parameters change.

```lua
-- Without cache
DanLib.DrawShadow:Begin()
    draw.RoundedBox(6, x, y, w, h, color)
DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false)

-- With caching (recommended for static panels)
DanLib.DrawShadow:Begin('my_panel_shadow')
    draw.RoundedBox(6, x, y, w, h, color)
DanLib.DrawShadow:End(1, 1, 1, 255, 0, 0, false, w, h, 'my_panel_shadow')
```

---

### HTTP

A thin wrapper around `http.Fetch` / `http.Post` / `HTTP()` with input validation and consistent error handling.

```lua
-- GET
DanLib.HTTP:Fetch('https://api.example.com/data', function(body, len, headers, code)
    local data = util.JSONToTable(body)
end)

-- POST
DanLib.HTTP:Post('https://api.example.com/submit', { key = 'value' }, function(body)
    print('Response:', body)
end)

-- Arbitrary method (PUT, DELETE, PATCH…)
DanLib.HTTP:Request({
    url = 'https://api.example.com/item/5',
    method = 'DELETE',
    headers = { Authorization = 'Bearer token' },
    success = function(code, body) end,
    failed = function(err) end,
})
```

---

### Ranks & Permissions

Built-in rank system with TTL caching (5 s, cleanup every 30 s), CAMI integration, and player metatable extensions.

```lua
-- Player rank information
local rankID = ply:get_danlib_rank()             -- rank ID (no cache)
local rankID = ply:get_danlib_rank_cached()      -- rank ID (TTL-cached)
local name = ply:get_danlib_rank_name()          -- display name
local color = ply:get_danlib_rank_color()        -- Color(...)
local perms = ply:get_danlib_rank_permissions()  -- permissions table

-- Permission check (static function, not a player method)
if DanLib.Func.HasPermission(ply, 'manage_bans') then
    -- player has the manage_bans permission
end
```

Ranks, colors, and permissions are configured in the admin menu without editing any files. The server owner (`rank_owner`) automatically has all permissions.

---

### Utilities

| Namespace | Purpose |
|---|---|
| `DanLib.Table` | extensions to `table.*`: deep copy, merge, contains, etc. |
| `DanLib.Hook` | `hook.Add` / `hook.Remove` with automatic cleanup |
| `DanLib.Timer` | wrappers around `timer.*` |
| `DanLib.FileUtil` | GMod filesystem helpers |
| `DanLib.PlayerUtil` | player utility functions |
| `DanLib.Func:Scale(n)` | scale a number to the current screen resolution |
| `sh_formatting.lua` | formatting for time, numbers, and file sizes |

---

## Built-in Admin Menu

Opened with `danlibmenu` (console) or `!danlibmenu` (chat).

| Page | Description |
|---|---|
| Dashboard | server overview |
| Modules | manage addon modules |
| Ranks | configure ranks and permissions |
| Logs | server-side logs |
| Setup | DanLib configuration |
| User Setup | personal settings (language, theme) |
| Languages | preview localization strings |
| Help | documentation |

---

## Links

| Name | Link |
|---|---|
| **Documentation** | https://ddi-docs.site/DanLib |
| **GitHub** | https://github.com/denchik5133/danlib |
| **Discord** | https://discord.gg/CND6B5sH3j |
| **Steam (author)** | https://steamcommunity.com/profiles/76561198405398290/ |
| **Workshop** | https://steamcommunity.com/sharedfiles/filedetails/?id=2418668622 |
