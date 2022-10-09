local addon = {
	name = "VotansDolmenTimer",
}
local em = GetEventManager()

local async = LibAsync
local pinManager = ZO_WorldMap_GetPinManager()

local pinKeyCountUp = {
}

local function updatePin(key, info)
	local zoneIndex, poiIndex, time = unpack(info)
	local diff = GetTimeStamp() - time
	if diff > 1800 then pinKeyCountUp[key] = nil end
	local pin = pinManager:FindPin("poi", zoneIndex, poiIndex)
	if pin then
		local control = pin:GetControl()
		local labelControl = control:GetNamedChild("Label")
		if diff <= 1800 then
			labelControl:SetText(string.format("|ce0d0e0%s|r", ZO_FormatTime(diff, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS)))
			labelControl:SetFont("$(BOLD_FONT)|$(KB_16)|thick-outline")
			-- labelControl:SetColor(0.8, 0.75, 0.8)
			labelControl:SetDrawLayer(DL_TEXT)
			labelControl:SetHidden(false)
		else
			labelControl:SetText("")
			labelControl:SetFont("ZoFontGameOutline")
			-- labelControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
			-- 		labelControl:SetHorizontalAlignment(CENTER)
			-- 		labelControl:SetVerticalAlignment(CENTER)
			labelControl:SetDrawLayer(DL_BACKGROUND)
			labelControl:SetHidden(true)
		end
	end
end

local function FindPin()
	local px, py = GetMapPlayerPosition("player")
	local zoneIndex = GetCurrentMapZoneIndex()
	local x, y, poiType, icon
	for poiIndex = 1, GetNumPOIs(zoneIndex) do
		x, y, poiType, icon = GetPOIMapInfo(zoneIndex, poiIndex)
		x, y = x - px, y - py
		x, y = x * x, y * y
		if (x + y) < 0.0001 then
			pinKeyCountUp[string.format("%i_%i", zoneIndex, poiIndex)] = { zoneIndex, poiIndex, GetTimeStamp() }
			break
		end
	end
end

function addon:Initialize()
	local accountDefaults = {
		pinKeyCountUp = { }
	}
	self.account = ZO_SavedVars:NewAccountWide("VotansDolmenTimer_Data", 1, nil, accountDefaults)
	pinKeyCountUp = self.account.pinKeyCountUp

	em:RegisterForEvent(addon.name, EVENT_EXPERIENCE_GAIN, function(_, reason)
		if reason == PROGRESS_REASON_SCRIPTED_EVENT then
			async:Call(FindPin)
		end
	end )

	em:RegisterForUpdate(addon.name .. "_pinupdater", 1000, function()
		if next(pinKeyCountUp) then async:For(pairs(pinKeyCountUp)):Do(updatePin) end
	end )
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:Initialize()
	-- addon:InitSettings()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
