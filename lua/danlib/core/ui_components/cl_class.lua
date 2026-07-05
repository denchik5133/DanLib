/***
 *   @addon         DanLib
 *   @component     UI Class
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
 *   @description   Universal library for GMod Lua, combining all the necessary features to simplify script development. 
 *                  Avoid code duplication and speed up the creation process with this powerful and convenient library.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



DanLib.UI = DanLib.UI or {}
local UI = DanLib.UI

local math = math
local _isstring = isstring
local _isnumber = isnumber
local _IsValid = IsValid
local _ScreenScale = ScreenScale
local _type = type
local _Clamp = math.Clamp
local _ScrW = ScrW
local _ScrH = ScrH

--- Returns the width of the screen, capped at 3840 pixels.
-- @return number: The width of the screen.
function UI:ScrW()
    local w = _ScrW()
    if (w > 3840) then
        w = 3840
    end
    return w
end

--- Returns the height of the screen, capped at 2160 pixels.
-- @return number: The height of the screen.
function UI:ScrH()
    local h = _ScrH()
    if (h > 2160) then
        h = 2160
    end
    return h
end

--- Scales width and height values based on the screen size.
-- @param w: The width value to be scaled.
-- @param h: The height value to be scaled (optional, defaults to w).
-- @return number, number: The scaled width and height.
function UI:ClampScale(w, h)
    h = _isnumber(h) and h or w
    return _Clamp(1920, 0, _ScrW() / w), _Clamp(1080, 0, _ScrH() / h)
end

--- Clamps a width value between specified minimum and maximum values.
-- @param w: The width value to be clamped.
-- @param min: The minimum width value (optional, defaults to 0).
-- @param max: The maximum width value (optional, defaults to the scaled value of w).
-- @return number: The clamped width.
function UI:ClampScaleW(w, min, max)
    w = _isnumber(w) and w or _ScrW()
    return _Clamp(_ScreenScale(w), min or 0, max or _ScreenScale(w))
end

--- Clamps a height value between specified minimum and maximum values.
-- @param h: The height value to be clamped.
-- @param min: The minimum height value (optional, defaults to 0).
-- @param max: The maximum height value (optional, defaults to the scaled value of h).
-- @return number: The clamped height.
function UI:ClampScaleH(h, min, max)
    h = _isnumber(h) and h or _ScrH()
    return _Clamp(_ScreenScale(h), min or 0, max or _ScreenScale(h))
end

--- Returns a scaled value based on the screen width.
-- @param s: The base scale value.
-- @param m: The medium scale value (optional, defaults to s).
-- @param l: The large scale value (optional, defaults to s).
-- @return number: The scaled value based on screen width.
function UI:bscale(s, m, l)
    if (not m) then
    	m = s
    end

    if (not l) then
        l = s
    end

    if (_ScrW() <= 1280) then
        return _ScreenScale(s)
    elseif (_ScrW() >= 1281 and _ScrW() <= 1600) then
        return _ScreenScale(m)
    elseif (_ScrW() >= 1601) then
        return _ScreenScale(l)
    else
        return s
    end
end

--- Returns a simple scaled value based on the screen width.
-- @param s: The base scale value.
-- @param m: The medium scale value (optional, defaults to s).
-- @param l: The large scale value (optional, defaults to s).
-- @return number: The simple scaled value based on screen width.
function UI:SetScaleSimple(s, m, l)
    if (not m) then
        m = s
    end

    if (not l) then
        l = s
    end

    if (_ScrW() <= 1280) then
        return s
    elseif (_ScrW() >= 1281 and _ScrW() <= 1600) then
        return m
    elseif (_ScrW() >= 1601) then
        return l
    else
        return s
    end
end

--- Sets the scale for width and height based on the current screen resolution.
-- @param w: The desired width (optional, defaults to 300).
-- @param h: The desired height (optional, defaults to w).
-- @return number, number: The scaled width and height.
function UI:SetScale(w, h)
    w = _isnumber(w) and w or 300
    h = _isnumber(h) and h or w

    local sc_w, sc_h = self:SetScaleSimple(0.85, 0.85, 0.90), self:SetScaleSimple(0.85, 0.85, 0.90)
    local parent_w, parent_h = w, h
    local ui_w, ui_h = sc_w * parent_w, sc_h * parent_h

    return ui_w, ui_h
end

--- Checks if the given object is a valid panel.
-- @param parent: The object to check for validity.
-- @return boolean: True if the object is a valid panel, false otherwise.
function UI:valid(parent)
    if (not parent or _type(parent) ~= 'Panel') then
        return false
    end

    if (not _IsValid(parent)) then
        return false
    end
    return true
end


-- Meta Function to Register Classes
local MetaUI = DanLib.MetaPanel

--- Checks if the given object is a valid panel.
-- @return boolean: True if the object is a valid panel, false otherwise.
function MetaUI:Valid()
    if (not self or _type(self) ~= 'Panel') then
        return false
    end

    if (not _IsValid(self)) then
        return false
    end
    return true
end

--- Calculates the position (x, y) for a specified parent panel based on the desired position string or integer.
-- @param parent The parent panel for which the position is calculated.
-- @param pos: The desired position (string or number, e.g., 'TOP', 'CENTER', etc.).
-- @param pad: The padding value (optional, defaults to 0).
-- @return number, number:The calculated x and y coordinates.
function MetaUI:GetPosition(pos, pad)
	-- check > valid parent
    if (not self:Valid()) then
        return 0, 0
    end

	-- validate > vars
    pos = _isnumber(pos) and pos or _isstring(pos) and pos or 5
    pad = _isnumber(pad) and pad or 0

    -- define > vars
    local parent_w, parent_h = self:GetSize()
    local x, y  = 0, 0

    if (pos == 'TOP' or pos == 8) then -- top
        x, y = _ScrW() / 2 - parent_w / 2, pad
    elseif (pos == 'TOP_RIGHT' or pos == 9) then -- top-right
        x, y = _ScrW() - parent_w - 20, pad
    elseif (pos == 'RIGHT' or pos == 6) then -- right
        x, y = _ScrW() - parent_w - pad, ((_ScrH() / 2) - (parent_h / 2))
    elseif (pos == 'BOTTOM_RIGHT' or pos == 3) then -- bottom-right
        x, y = _ScrW() - parent_w - pad, _ScrH() - parent_h - pad
    elseif (pos == 'BOTTOM' or pos == 2) then -- bottom
        x, y = _ScrW() / 2 - parent_w / 2, _ScrH() - parent_h - pad
    elseif(pos == 'BOTTOM_LEFT' or pos == 1) then -- bottom-left
        x, y = pad, _ScrH() - parent_h - pad
    elseif (pos == 'LEFT' or pos == 4) then -- left
        x, y = pad, ((_ScrH() / 2) - (parent_h / 2))
    elseif (pos == 'TOP_LEF' or pos == 7) then -- top-left
        x, y = pad, pad
    elseif (pos == 'CENTER' or pos == 5) then -- center
        x, y  = ((_ScrW() / 2) - (parent_w / 2)), ((_ScrH() / 2) - (parent_h / 2))
    end

    return x, y
end

--- Makes the parent panel appear on the screen with a fading effect.
-- @param pos: The desired position for the panel (string or number, optional, defaults to 'CENTER').
-- @param time: The duration of the fade effect (optional, defaults to 0.3 seconds).
-- @param func: The callback function to be executed after the fade effect completes (optional).
-- @return nil
function MetaUI:ApplyAppear(pos, time, func)
    if (not self:Valid()) then
        return
    end

    local pad = 20
    pos = (_isnumber(pos) and pos or _isstring(pos) and pos) or 5
    time = (_isnumber(time) and time) or 0.3

    -- default size
    local x, y = self:GetPosition(pos, pad)
    self:SetAlpha(0)
    self:SetPos(x, y)
    self:AlphaTo(255, time or 0, 0, function()
        if isfunction(func) then
            func()
        else
            return
        end
    end)
end
