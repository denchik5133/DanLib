/***
 *   @addon         DanLib
 *   @component     UI NumberWang
 *   @license       MIT License
 *   @version       1.0.1
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
 


local DBase = DanLib.Func
local DUtils = DanLib.Utils
local DTimer = DanLib.Timer
local DCustomUtils = DanLib.CustomUtils.Create

function DBase.CreateNumberWang(parent)
	local Number = DCustomUtils(parent)

	Number.numberWang = DCustomUtils(Number, 'DNumberWang')
	Number.numberWang:Pin(FILL)
	Number.numberWang:DockMargin(2, 0, 2, 0)
	Number.numberWang:SetFont('danlib_font_18')
	Number.numberWang:SetText('')
	Number.numberWang:SetTextColor(Color(255, 255, 255, 20))
	Number.numberWang:SetCursorColor(Color(255, 255, 255))
	Number.numberWang:SetMinMax(0, 99999999)
	Number.numberWang.backTextColor = DBase:Theme('secondary_dark', 100)
	Number.numberWang:ApplyClearPaint()
	Number.numberWang:ApplyEvent(nil, function(sl, w, h)
		if (sl:GetTextColor().a != 255 or sl:GetTextColor().a != 0) then
			sl:SetTextColor(Color(255, 255, 255, 100 + (Number.alpha or 0)))
		end

		if (sl.GetPlaceholderText && sl.GetPlaceholderColor && sl:GetPlaceholderText() && sl:GetPlaceholderText():Trim() != '' && sl:GetPlaceholderColor() && (not sl:GetText() or sl:GetText() == '')) then
			local oldText = sl:GetText()
			local str = sl:GetPlaceholderText()
			if (str:StartWith('#')) then str = str:sub(2) end
			str = language.GetPhrase(str)
	
			sl:SetText(str)
			sl:DrawTextEntryText(sl:GetPlaceholderColor(), sl:GetHighlightColor(), sl:GetCursorColor())
			sl:SetText(oldText)
			return
		end
	
		sl:DrawTextEntryText(sl:GetTextColor(), sl:GetHighlightColor(), sl:GetCursorColor())
		if (not sl:IsEditing() and sl:GetText() == '') then
			draw.SimpleText(sl.backText or '', sl:GetFont(), 0, h / 2, sl.backTextColor, 0, TEXT_ALIGN_CENTER)
		end
	end)

	function Number.numberWang:OnChange()
        if Number.OnChange then
        	Number:OnChange()
        end
    end

    function Number.numberWang:OnEnter()
        if Number.OnEnter then
        	Number:OnEnter()
        end
    end

    function Number.numberWang:OnValueChanged()
        if Number.OnValueChanged then
        	Number:OnValueChanged()
        end
    end

	-- Enhanced OnLoseFocus with MinMax support
    function Number.numberWang:OnLoseFocus()
        DTimer:Simple(nil, function() 
            if (not IsValid(self)) then
            	return
            end
            
            -- Check if field is empty and MinMax is set
            local currentText = self:GetText()
            if (not currentText or currentText:Trim() == '') then
                -- If MinMax was set via SetMinMax and minimum is greater than 0, use minimum
                -- Otherwise use 0 as default
                local minValue = self:GetMin()
                if (minValue and minValue > 0) then
                    self:SetValue(minValue)
                else
                    self:SetValue(0)
                end
            else
                -- Normal clamp behavior for non-empty values
                self:SetValue(math.Clamp(self:GetValue(), self:GetMin(), self:GetMax()))
            end
        end)

        if (Number.OnLoseFocus) then
        	Number:OnLoseFocus()
        end
    end

	function Number:SetMinMax(min, max) 
        self.numberWang:SetMinMax(min, max)
        -- Store the min/max values for reference
        self._minValue = min
        self._maxValue = max
    end

	function Number:SetValue(val) self.numberWang:SetValue(val) end
	function Number:GetValue() return self.numberWang:GetValue() end
	function Number:SetBackColor(color) self.backColor = color end
	function Number:SetHighlightColor(color) self.highlightColor = color end

	function Number:DisableShadows(distance, noClip, iteration)
	    self:ApplyShadow(distance or 10, noClip or false, iteration or 5)
	end

	function Number:Paint(w, h)
		self:ApplyAlpha(0.2, 155, false, false, self.numberWang:IsEditing(), 155)

		if (self.numberWang:IsEditing()) then
			self.hoverPercent = math.Clamp((self.hoverPercent or 0) + 3, 0, 100)
		else
			self.hoverPercent = math.Clamp((self.hoverPercent or 0) - 3, 0, 100)
		end

		local hoverPercent = self.hoverPercent / 100
		DUtils:DrawRect(0, 0, w, h, DBase:Theme('decor_elements'))
		DUtils:OutlinedRect(0, 0, w, h, DBase:Theme('frame'))
		DUtils:OutlinedRect(0, 0, w, h, DBase:Theme('decor', hoverPercent * 100))
	end

	return Number
end


--- Creates a numeric slider with the given parameters.
-- @param parent (Panel): The parent element to which the slider will be attached.
-- @param text (string): The text to be displayed on the slider. If not specified, an empty value will be used.
-- @param colour (Color): The colour of the slider text. If not specified, the default theme is used.
-- @return Slider (DNumSlider): The slider element created.
function DBase.CreateNumSlider(parent, text, color)
	color = color or DBase:Theme('text')
	local alpha = 0

	local Slider = DCustomUtils(parent, 'DNumSlider')
	Slider:Pin(FILL)
   	Slider:SetDecimals(0)

    Slider.Scratch:SetVisible(false)
	Slider.TextArea:SetVisible(false)

	-- If no text is specified, hide the text label
	if (not text or text == '') then
		Slider.Label:SetVisible(false)
	else
		Slider:SetText(text)
		Slider.Label:SetTextColor(color)
		Slider.Label:SetFont('danlib_font_18')
	end

    Slider.Slider.Paint = function(sl, w, h)
        DUtils:DrawRect(8, h / 2, select(1, Slider.Slider.Knob:GetPos()), 2, Color(0, 136, 209))
        DUtils:DrawRect(select(1, Slider.Slider.Knob:GetPos()), h / 2, w - 13 - select(1, Slider.Slider.Knob:GetPos()), 2, Color(160, 160, 160))
    end

    Slider.Slider.Knob:SetSize(14, 14)
    Slider.Slider.Knob.Paint = function(sl, w, h)
    	sl:ApplyAlpha(0.2, 100, false, false, sl.Depressed, 100)
        draw.RoundedBox(10, w / 2 - (22) / 2, h / 2 - (22) / 2 + (1), 22, 22, Color(0, 136, 209, sl.alpha))
        draw.RoundedBox(10, w / 2 - (14) / 2, h / 2 - (14) / 2 + (1), w, h, Color(0, 136, 209))
        Slider.Label:SetTextColor(color)
    end

    Slider.Slider.Knob.PaintOver = function(sl, w, h)
    	sl:ApplyAlpha(0.2, 180, false, false, sl.Depressed, 100)
        local value = Slider.TextArea:GetValue()
        draw.SimpleText(value, 'danlib_font_18', (sl.x - sl.x) + sl:GetWide() / 2, sl.y - 20, Color(255, 255, 255, sl.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	return Slider
end
