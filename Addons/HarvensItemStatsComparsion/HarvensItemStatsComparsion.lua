local function Harvens_UpdateStatComparisonValue(control)
	control.UpdateStatComparisonValueOrg(control)
	if not control.control:IsHidden() and not control.control.comparisonValue:IsHidden() and control.currentStatDelta and control.currentStatDelta ~= 0 then
		local text
		if control.currentStatDelta < 0 then
			text = string.format('|cff0000(%i) %i|r', control.currentStatDelta, control:GetValue()+control.currentStatDelta)
		else
			text = string.format('|c00ff00(+%i) %i|r', control.currentStatDelta, control:GetValue()+control.currentStatDelta)
		end
		control.control.comparisonValue:SetText(text)
	end
end

local function OnInitialized(eventId, addonName)
	if addonName ~= "HarvensItemStatsComparsion" then
		return
	end
	
	EVENT_MANAGER:UnregisterForEvent("HarvensItemStatsComparsion", EVENT_ADD_ON_LOADED)
	
	for i=1,ZO_CharacterWindowStatsScrollScrollChild:GetNumChildren() do
		local control = ZO_CharacterWindowStatsScrollScrollChild:GetChild(i)
	
		control.statEntry.UpdateStatComparisonValueOrg = control.statEntry.UpdateStatComparisonValue
		control.statEntry.UpdateStatComparisonValue = Harvens_UpdateStatComparisonValue
	end	
end

EVENT_MANAGER:RegisterForEvent("HarvensItemStatsComparsion", EVENT_ADD_ON_LOADED, OnInitialized)