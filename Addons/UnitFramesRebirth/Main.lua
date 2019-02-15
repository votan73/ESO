
local UnitFrames

local addonName = "UnitFramesRebirth"

CALLBACK_MANAGER:RegisterCallback("UnitFramesPreInit", function(unitFrames)
	UnitFrames = unitFrames
end )

local function CreateSettings()
	local LibHarvensAddonSettings = LibStub("LibHarvensAddonSettings-1.0")

	local settings = LibHarvensAddonSettings:AddAddon("Unit Frames Rebirth")
	assert(settings, "settings not loaded")

	local DEFAULT_SETTINGS = {
		showClassIcon = true,
		showHealthWarner = true,
	}
	UnitFrames.account = ZO_SavedVars:NewAccountWide("UnitFramesRebirth_Data", 1, nil, DEFAULT_SETTINGS)

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_CLASS_ICON),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_CLASS_ICON_TT),
		default = DEFAULT_SETTINGS.showClassIcon,
		setFunction = function(bool)
			UnitFrames.account.showClassIcon = bool
		end,
		getFunction = function()
			return UnitFrames.account.showClassIcon
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_CLASS_HEALTH_WARNER),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_CLASS_HEALTH_WARNER_TT),
		default = DEFAULT_SETTINGS.showHealthWarner,
		setFunction = function(bool)
			UnitFrames.account.showHealthWarner = bool
			UnitFrames:SetWarner(bool)
		end,
		getFunction = function()
			return UnitFrames.account.showHealthWarner
		end,
	}
end

local function OnAddOnLoaded(event, name)
	if name ~= addonName then return end
	EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_ADD_ON_LOADED)

	CreateSettings()

	UnitFrames:SetWarner(UnitFrames.account.showHealthWarner)
end

EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
