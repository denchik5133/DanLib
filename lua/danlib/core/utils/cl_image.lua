/***
 *   @addon         DanLib
 *   @component     Image System
 *   @license       MIT License
 *   @version       2.6.1
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   A system for uploading and managing HTTP content (images) in the client-side
 *                  portion of the DanLib project, featuring significantly improved image quality.
 *
 *   @functions
 *                  - Handling errors during material loading and showing a placeholder instead of the error texture.
 *                  - Validating downloaded/cached files via PNG magic bytes before writing to disk.
 *                  - Saving downloaded materials to a file and updating the material cache.
 *                  - Downloading materials from the internet and managing download requests using a queue.
 *                  - Retrieving materials based on their identifiers, checking local cache, and queuing downloads if necessary.
 *                  - Drawing icons on the screen with optional rotation, rounding and color settings.
 *                  - Pre-loading icons before they are needed, checking load state, clearing and validating the cache.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DHTTP = DanLib.HTTP
local DBase = DanLib.Func
local DHook = DanLib.Hook
local DUtils = DanLib.Utils
local DTable = DanLib.Table
local DFileUtil = DanLib.FileUtil

-- surface / render locals (avoid global lookups on hot draw paths)
local _Color = Color
local _pairs = pairs
local _ipairs = ipairs
local _unpack = unpack
local _min = math.min
local _max = math.max
local _floor = math.floor
local _Material = Material
local _SetMaterial = surface.SetMaterial
local _SetDrawColor = surface.SetDrawColor
local _DrawTexturedRect = surface.DrawTexturedRect
local _DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local _DrawRect = surface.DrawRect
local _DrawOutlinedRect = surface.DrawOutlinedRect

-- stencil locals — used only by DrawIconRounded
local _ClearStencil = render.ClearStencil
local _SetStencilEnable = render.SetStencilEnable
local _SetStencilWriteMask = render.SetStencilWriteMask
local _SetStencilTestMask = render.SetStencilTestMask
local _SetStencilReferenceValue = render.SetStencilReferenceValue
local _SetStencilCompareFunction = render.SetStencilCompareFunction
local _SetStencilPassOperation = render.SetStencilPassOperation
local _SetStencilFailOperation = render.SetStencilFailOperation
local _RoundedBox = draw.RoundedBox

--- Maximum allowed size of a downloaded icon (5 MB).
local MAX_ICON_BYTES = 5 * 1024 * 1024

--- PNG file signature (magic bytes). Every valid PNG starts with exactly these 8 bytes.
-- Used to reject HTML error pages, empty bodies, and other non-image data
-- before writing anything to disk.
local PNG_MAGIC = '\137\80\78\71\13\10\26\10'

--- Returns true when raw bytes look like a valid PNG file.
-- Checks only the 8-byte magic header — cheap and sufficient to catch
-- imgur 404 HTML pages, empty responses, and obvious corruption.
-- @param raw (string)  Raw HTTP body or file contents.
-- @return boolean
local function _isValidPNG(raw)
    return raw ~= nil and #raw >= 8 and raw:sub(1, 8) == PNG_MAGIC
end

--- Pre-baked white color used as the default draw tint.
-- Declared once to avoid allocating a new Color object on every Paint call.
local COLOR_WHITE = _Color(255, 255, 255, 255)

--- Unified material cache: icon-id → Material object.
-- Holds _Material('error') for permanently-failed icons (see failedIcons).
-- @type table
local httpMaterial = { }

--- Set of icon IDs that permanently failed to load.
-- When true, draw functions show a placeholder instead of attempting to draw.
-- @type table
local failedIcons = { }

--- Tracks icon IDs whose download is currently in-flight.
-- Prevents the same icon from being queued multiple times across Paint frames.
-- @type table
local gMaterials = { }

--- Sequential download queue; each entry is { iconId, matFlags, callback }.
-- @type table
local queue = { }

--- Whether the DuckDuckGo proxy should be used for the next fetch attempt.
-- Resets to false after every completed attempt (success or permanent failure)
-- so each new icon always tries the direct Imgur URL first.
-- @type boolean
local useProxy = false

-- Ensure the icon cache directory exists.
DFileUtil:CreateDir('danlib/icon')

--- Draws a neutral grey placeholder when an icon could not be loaded.
-- @param x (number) Draw X.
-- @param y (number) Draw Y.
-- @param w (number) Width.
-- @param h (number) Height.
local function _drawPlaceholder(x, y, w, h)
    _SetDrawColor(55, 55, 55, 220)
    _DrawRect(x, y, w, h)
    _SetDrawColor(90, 90, 90, 255)
    _DrawOutlinedRect(x, y, w, h)

    local s = _max(2, _floor(_min(w, h) * 0.22))
    local cx = _floor(x + w * 0.5)
    local cy = _floor(y + h * 0.5)

    _SetDrawColor(120, 120, 120, 255)
    _DrawRect(cx - s, cy - 1, s * 2, 2)
    _DrawRect(cx - 1, cy - s, 2, s * 2)
end

--- Marks an icon as permanently failed and fires its callback.
-- Also resets useProxy so the next icon always tries the direct URL first.
-- @param icon (string) Icon ID.
-- @param cback (function) Callback to fire.
local function _handleError(icon, cback)
    failedIcons[icon] = true
    httpMaterial[icon] = _Material('error')
    gMaterials[icon] = nil
    useProxy = false
    cback(httpMaterial[icon])
end

--- Validates, writes and loads a downloaded icon into the cache.
-- Rejects non-PNG data (e.g. imgur 404 HTML pages) via PNG magic-byte check
-- so corrupt content is never written to disk.
-- @param icon (string) Icon ID.
-- @param raw (string) Raw HTTP response body.
-- @param matgs (string|nil) Material flags.
-- @return boolean  true on success, false if data is invalid or missing.
local function _saveMaterial(icon, raw, matgs)
    if (not _isValidPNG(raw)) then
        return false 
    end

    DFileUtil:Write('danlib/icon/' .. icon .. '.png', raw)
    httpMaterial[icon] = _Material('../data/danlib/icon/' .. icon .. '.png', matgs or 'noclamp smooth mips')
    return true
end

--- Processes a completed HTTP download.
-- Rejects non-200 responses, oversized payloads, and non-PNG bodies.
-- @param icon (string) Icon ID.
-- @param code (number) HTTP status code returned by the server.
-- @param len (number) Response length in bytes.
-- @param raw (string) Raw response body.
-- @param matgs (string|nil) Material flags.
-- @param cback (function) Callback.
local function _processDownload(icon, code, len, raw, matgs, cback)
    if code ~= 200 or len > MAX_ICON_BYTES or not _saveMaterial(icon, raw, matgs) then
        _handleError(icon, cback)
    else
        useProxy = false
        gMaterials[icon] = nil
        cback(httpMaterial[icon])
    end
end

--- Pops the first queued icon and starts its HTTP download.
-- Falls back to the DuckDuckGo proxy on first failure; marks the icon as
-- permanently failed if the proxy also fails.
local function _downloadMaterial()
    if (not queue[1]) then
        return
    end

    local icon, matgs, cback = _unpack(queue[1])
    local url = (useProxy and 'https://proxy.duckduckgo.com/iu/?u=https://i.imgur.com/' or  'https://i.imgur.com/') .. icon .. '.png'

    DHTTP:Fetch(url, function(raw, len, _, code)
        _processDownload(icon, code, len, raw, matgs, cback)
    end, function(err)
        if useProxy then
            _handleError(icon, cback)
        else
            useProxy = true
            _downloadMaterial()
        end
    end)
end

--- Shared pre-draw guard used by all draw functions.
-- Returns true when the icon is ready to draw, false when it is still loading
-- (or permanently failed — in that case it draws the placeholder itself).
-- @param x (number) Draw X.
-- @param y (number) Draw Y.
-- @param w (number) Width.
-- @param h (number) Height.
-- @param icon (string) Imgur image ID.
-- @return boolean
local function _ensureReady(x, y, w, h, icon)
    if (not icon) then
        return false
    end

    if failedIcons[icon] then
        _drawPlaceholder(x, y, w, h)
        return false
    end

    if (not httpMaterial[icon]) then
        if (not gMaterials[icon]) then
            gMaterials[icon] = true
            DBase:GetMaterial(icon, function()
                gMaterials[icon] = nil
            end)
        end
        return false
    end
    return true
end

--- Internal flat-draw dispatcher (no stencil overhead).
local function _drawIconInternal(x, y, w, h, icon, color, rotate)
    if (not _ensureReady(x, y, w, h, icon)) then
        return
    end

    color = color or COLOR_WHITE
    _SetMaterial(httpMaterial[icon])
    _SetDrawColor(color.r, color.g, color.b, color.a)
    if rotate then
        _DrawTexturedRectRotated(x, y, w, h, rotate)
    else
        _DrawTexturedRect(x, y, w, h)
    end
end

--- Reads only the first 8 bytes of a cached file using file.Open,
-- avoiding the need to load the entire PNG into memory just to check its header.
-- Returns nil if the file cannot be opened.
-- @param path (string)  DATA-relative path, e.g. 'danlib/icon/abc123.png'.
-- @return string|nil  First 8 bytes, or nil on failure.
local function _readHeader(path)
    local fh = DFileUtil:Open(path, 'rb', 'DATA')
    if (not fh) then
        return nil
    end

    local header = fh:Read(8)
    fh:Close()
    return header
end

--- Retrieves the Material for an imgur icon ID.
-- Resolution order: in-memory cache → validated disk cache → HTTP download queue.
-- @param icon (string) Imgur image ID (no extension).
-- @param cback (function) Called with the Material once it is available.
-- @param _ (any) Unused legacy parameter.
-- @param matgs (string|nil) Material flags override (default: 'noclamp smooth mips').
function DBase:GetMaterial(icon, cback, _, matgs)
    -- 1. In-memory hit — fastest path.
    if httpMaterial[icon] then
        cback(httpMaterial[icon])
        return
    end

    -- 2. Disk hit — validate before loading to catch previously-saved HTML 404 pages.
    if DFileUtil:Exists('danlib/icon/' .. icon .. '.png', 'DATA') then
        local raw = DFileUtil:Read('danlib/icon/' .. icon .. '.png', 'DATA')
        if _isValidPNG(raw) then
            httpMaterial[icon] = _Material('../data/danlib/icon/' .. icon .. '.png', matgs or 'noclamp smooth mips')
            cback(httpMaterial[icon])
            return
        end
        -- Corrupt / non-PNG on disk — delete and fall through to re-download.
        DFileUtil:Delete('danlib/icon/' .. icon .. '.png')
    end

    -- 3. Queue an HTTP download.
    DTable:Add(queue, { icon, matgs, function(mat)
        cback(mat)
        DTable:Remove(queue, 1)
        _downloadMaterial()
    end })

    if (#queue == 1) then
        _downloadMaterial()
    end
end

--- Starts downloading an icon immediately, without waiting for a draw call.
-- Safe to call multiple times — ignored if the icon is already cached or in-flight.
-- @param icon (string) Imgur image ID.
-- @param matgs (string|nil) Optional material flags override.
function DBase:PreloadMaterial(icon, matgs)
    if (not icon) then
        return
    end

    if (httpMaterial[icon] or gMaterials[icon]) then
        return
    end

    if DFileUtil:Exists('danlib/icon/' .. icon .. '.png', 'DATA') then
        local raw = DFileUtil:Read('danlib/icon/' .. icon .. '.png', 'DATA')
        if _isValidPNG(raw) then
            httpMaterial[icon] = _Material('../data/danlib/icon/' .. icon .. '.png', matgs or 'noclamp smooth mips')
            return
        end
        DFileUtil:Delete('danlib/icon/' .. icon .. '.png')
    end

    gMaterials[icon] = true
    DBase:GetMaterial(icon, function()
        gMaterials[icon] = nil
    end, nil, matgs)
end

--- Returns true when the icon is fully loaded and ready to draw.
-- Returns false while downloading, not yet requested, or permanently failed.
-- @param icon (string)  Imgur image ID.
-- @return boolean
function DBase:IsMaterialReady(icon)
    return httpMaterial[icon] ~= nil and not failedIcons[icon]
end

--- Clears the in-memory cache for one icon or for every icon.
-- The next draw or GetMaterial call for a cleared icon will re-load from
-- disk (if a valid PNG is still there) or re-download from Imgur.
-- @param icon (string|nil) Icon ID to clear, or nil to clear everything.
-- @param clearDisk (boolean|nil) Also delete the cached PNG file(s) from disk.
function DBase:ClearMaterialCache(icon, clearDisk)
    if icon then
        httpMaterial[icon] = nil
        failedIcons[icon] = nil
        if clearDisk and DFileUtil:Exists('danlib/icon/' .. icon .. '.png', 'DATA') then
            DFileUtil:Delete('danlib/icon/' .. icon .. '.png')
        end
    else
        for k in _pairs(httpMaterial) do
            httpMaterial[k] = nil
        end

        for k in _pairs(failedIcons) do
            failedIcons[k] = nil
        end

        if clearDisk then
            local found = DFileUtil:Find('danlib/icon/*.png', 'DATA')
            for _, f in _ipairs(found) do
                DFileUtil:Delete('danlib/icon/' .. f)
            end
        end
    end
end

--- Scans every PNG file in the disk cache and removes corrupt ones.
-- "Corrupt" means: missing PNG magic bytes (e.g. an imgur 404 HTML page
-- saved by an older version of this code), empty, or unreadable.
-- In-memory entries for deleted files are also cleared so the next draw
-- or GetMaterial call triggers a fresh download automatically.
--
-- Only reads the first 8 bytes of each file (PNG header) via file.Open —
-- the full file body is never loaded, so performance is constant and fast
-- regardless of how many icons are cached or how large each file is.
--
-- @return number  Count of corrupt files deleted.
function DBase:ValidateMaterialCache()
    local found = DFileUtil:Find('danlib/icon/*.png', 'DATA')
    local removed = 0
    for _, f in _ipairs(found) do
        local header = _readHeader('danlib/icon/' .. f)
        if (not _isValidPNG(header)) then
            DFileUtil:Delete('danlib/icon/' .. f)
            -- Strip extension to recover the icon ID.
            local dotPos = #f - 3 -- length of '.png' is 4; last char of id is at #f-4
            local id = f:sub(1, dotPos - 1)
            if (id ~= '') then
                httpMaterial[id] = nil
                failedIcons[id] = nil
            end
            removed = removed + 1
        end
    end
    return removed
end

-- Runs once after the client fully initialises.
-- Scans the icon disk cache and silently removes any files that are not
-- valid PNGs (e.g. HTML 404 pages saved by an older version of this code).
-- Only the 8-byte magic header of each file is read, so the scan is fast
-- regardless of cache size.
if CLIENT then
    DHook:Add('Initialize', 'DanLib.ValidateIconCache', function()
        local removed = DBase:ValidateMaterialCache()
        if (removed > 0) then
            DBase:Print('Removed ' .. removed .. ' corrupt cached icon(s). They will be re-downloaded on next use.\n')
        end
    end)
end

--- Returns the imgur image ID if the icon string is an imgur URL,
-- otherwise returns nil (meaning the icon is an emoji or plain text).
-- Accepts:
--   https://i.imgur.com/abc1234.png -> 'abc1234'
--   https://i.imgur.com/abc1234 -> 'abc1234'
--   https://imgur.com/abc1234 -> 'abc1234'
function DUtils:ExtractImgurID(icon)
    if (not icon) then
        return nil
    end
    return icon:match('^https?://i?%.?imgur%.com/([A-Za-z0-9]+)')
end

--- Draws an icon at the specified position and size.
-- @param x (number) Draw X.
-- @param y (number) Draw Y.
-- @param w (number) Width.
-- @param h (number) Height.
-- @param icon (string) Imgur image ID.
-- @param color (Color|nil) Tint; defaults to white.
function DUtils:DrawIcon(x, y, w, h, icon, color)
    _drawIconInternal(x, y, w, h, icon, color, false)
end

--- Draws a rotated icon at the specified position and size.
-- @param x (number) Draw X.
-- @param y (number) Draw Y.
-- @param w (number) Width.
-- @param h (number) Height.
-- @param r (number) Rotation angle in degrees.
-- @param icon (string) Imgur image ID.
-- @param color (Color|nil) Tint; defaults to white.
function DUtils:DrawIconRotated(x, y, w, h, r, icon, color)
    _drawIconInternal(x, y, w, h, icon, color, r)
end

--- Draws an icon clipped to a rounded rectangle via the stencil buffer.
-- Perfect for circular avatars (radius = w/2) or softly-cornered thumbnails.
-- Shows the standard placeholder when the icon has not loaded yet.
-- Must be called from a VGUI Paint hook or a valid render context.
--
-- @param x (number) Draw X.
-- @param y (number) Draw Y.
-- @param w (number) Width.
-- @param h (number) Height.
-- @param icon (string) Imgur image ID.
-- @param color (Color|nil) Tint; defaults to white.
-- @param radius (number|nil) Corner radius in pixels; defaults to 4.
function DUtils:DrawIconRounded(x, y, w, h, icon, color, radius)
    if (not _ensureReady(x, y, w, h, icon)) then
        return
    end

    radius = radius or 4
    color = color  or COLOR_WHITE

    -- Phase 1: stamp the rounded shape into the stencil buffer.
    _ClearStencil()
    _SetStencilEnable(true)
    _SetStencilWriteMask(0xFF)
    _SetStencilTestMask(0xFF)
    _SetStencilReferenceValue(1)
    _SetStencilCompareFunction(STENCIL_NEVER)
    _SetStencilFailOperation(STENCIL_REPLACE)
    _SetStencilPassOperation(STENCIL_KEEP)
    _RoundedBox(radius, x, y, w, h, COLOR_WHITE)

    -- Phase 2: draw the texture only where stencil == 1.
    _SetStencilCompareFunction(STENCIL_EQUAL)
    _SetStencilFailOperation(STENCIL_KEEP)
    _SetStencilPassOperation(STENCIL_KEEP)
    _SetMaterial(httpMaterial[icon])
    _SetDrawColor(color.r, color.g, color.b, color.a)
    _DrawTexturedRect(x, y, w, h)

    -- Restore stencil state so subsequent VGUI elements are unaffected.
    _SetStencilEnable(false)
    _ClearStencil()
end
