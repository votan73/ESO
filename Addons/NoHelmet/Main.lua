local function CheckHelmet()
	SetSetting(SETTING_TYPE_IN_WORLD, IN_WORLD_UI_SETTING_HIDE_HELM, GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_HAT) == 0 and 1 or 0)
end

EVENT_MANAGER:RegisterForEvent("NO_HELMET", EVENT_COLLECTIBLE_UPDATED, function() zo_callLater(CheckHelmet, 0) end)
CheckHelmet()