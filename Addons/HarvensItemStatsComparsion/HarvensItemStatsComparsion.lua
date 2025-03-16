if IsConsoleUI() then
	return
end

local function Harvens_UpdateStatComparisonValue(control)
	if not control.control:IsHidden() and not control.control.comparisonValue:IsHidden() and control.currentStatDelta and control.currentStatDelta ~= 0 then
		local text
		if control.currentStatDelta < 0 then
			text = string.format("|cff0000(%i) %i|r", control.currentStatDelta, control:GetValue() + control.currentStatDelta)
		else
			text = string.format("|c00ff00(+%i) %i|r", control.currentStatDelta, control:GetValue() + control.currentStatDelta)
		end
		control.control.comparisonValue:SetText(text)
	end
end

SecurePostHook(ZO_StatEntry_Keyboard, "UpdateStatComparisonValue", Harvens_UpdateStatComparisonValue)
