
local UnitFrames

local addonName = "UnitFramesRebirth"

CALLBACK_MANAGER:RegisterCallback("UnitFramesPreInit", function(unitFrames)
	UnitFrames = unitFrames
end )

local function CreateSettings()
	local LibHarvensAddonSettings = LibStub("LibHarvensAddonSettings-1.0")

	local settings = LibHarvensAddonSettings:AddAddon("Unit Frames Rebirth")

	local DEFAULT_SETTINGS = {
		showClassIcon = true,
		showHealthWarner = true,
		switchNames = true,
		hideTitle = true,
		approachAmountMs = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_DEFAULT,
	}
	UnitFrames.account = ZO_SavedVars:NewAccountWide("UnitFramesRebirth_Data", 1, nil, DEFAULT_SETTINGS)

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_CLASS_ICON),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_CLASS_ICON_TT),
		default = DEFAULT_SETTINGS.showClassIcon,
		setFunction = function(bool) UnitFrames.account.showClassIcon = bool end,
		getFunction = function() return UnitFrames.account.showClassIcon end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_SWITCH_NAMES),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_SWITCH_NAMES_TT),
		default = DEFAULT_SETTINGS.switchNames,
		setFunction = function(bool) UnitFrames.account.switchNames = bool end,
		getFunction = function() return UnitFrames.account.switchNames end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_HIDE_TITLE),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_HIDE_TITLE_TT),
		default = DEFAULT_SETTINGS.hideTitle,
		setFunction = function(bool) UnitFrames.account.hideTitle = bool end,
		getFunction = function() return UnitFrames.account.hideTitle end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_HEALTH_WARNER),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_HEALTH_WARNER_TT),
		default = DEFAULT_SETTINGS.showHealthWarner,
		setFunction = function(bool)
			UnitFrames.account.showHealthWarner = bool
			UnitFrames:SetWarner(bool)
		end,
		getFunction = function() return UnitFrames.account.showHealthWarner end,
	}

	do
		local Modes = {
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_ULTRA_FAST), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_ULTRA_FAST },
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_SUPER_FAST), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_SUPER_FAST },
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_FASTER), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_FASTER },
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_FAST), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_FAST },
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_DEFAULT), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_DEFAULT },
		}
		
		local ModeToData = { }
		for i = 1, #Modes do
			ModeToData[Modes[i].data] = Modes[i]
		end
		
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_APPROACH_HEALTHBAR),
			items = Modes,
			default = ModeToData[DEFAULT_SETTINGS.approachAmountMs].name,
			getFunction = function()
				return (ModeToData[UnitFrames.account.approachAmountMs] or ModeToData[DEFAULT_SETTINGS.approachAmountMs]).name
			end,
			setFunction = function(combobox, name, item) UnitFrames.account.approachAmountMs = item.data end,
		}
	end
end

local function OnAddOnLoaded(event, name)
	if name ~= addonName then return end
	EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_ADD_ON_LOADED)

	CreateSettings()

	UnitFrames:SetWarner(UnitFrames.account.showHealthWarner)
end

EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
