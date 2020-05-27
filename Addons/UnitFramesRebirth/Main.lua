local ADDON_NAME = "UnitFramesRebirth"
local ADDON_DISPLAY_NAME = "Unit Frames Rebirth"

local UnitFrames
CALLBACK_MANAGER:RegisterCallback("UnitFramesPreInit", function(unitFrames) UnitFrames = unitFrames end)

-- Hook ZO_StatusBar_SmoothTransition
local PLAYER_HEALTH_BAR_CONTROLS =
{
	["ZO_PlayerAttributeHealthBarLeft"] = true,
	["ZO_PlayerAttributeHealthBarRight"] = true,
}

local function IsTrackedHealthBar(control)
	return PLAYER_HEALTH_BAR_CONTROLS[control:GetName()] == true
end

local function IsSettingEnabled(enableApproachAmountOnPlayerHealthBar)
	return enableApproachAmountOnPlayerHealthBar == true
end

local function HookSmoothTransition(enableApproachAmountOnPlayerHealthBar)
	local origZO_StatusBar_SmoothTransition = ZO_StatusBar_SmoothTransition
	function ZO_StatusBar_SmoothTransition(self, value, max, forceInit, onStopCallback, customApproachAmountMs)
		if IsSettingEnabled(enableApproachAmountOnPlayerHealthBar) and IsTrackedHealthBar(self) and forceInit ~= true then
			customApproachAmountMs = UnitFramesRebirth_GetStatusBarCustomApproachAmountMs() or customApproachAmountMs
			forceInit = customApproachAmountMs == UNIT_FRAMES_REBIRTH_INSTANT_ANIMATION_TIME_MS
		end
		origZO_StatusBar_SmoothTransition(self, value, max, forceInit, onStopCallback, customApproachAmountMs)
	end
end

-- Settings
local function CreateSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings
	local settings = LibHarvensAddonSettings:AddAddon(ADDON_DISPLAY_NAME)

	local UNIT_CHANGED = true
	local function UpdateTargetWindow()
		ZO_UnitFrames_UpdateWindow("reticleover", UNIT_CHANGED)
		ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)
	end

	local DEFAULT_SETTINGS = {
		showClassIcon = true,
		showHealthWarner = true,
		showUnitShield = true,
		switchNames = true,
		hideTitle = true,
		enablePetHealth = true,
		approachAmountMs = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_DEFAULT,
		enableApproachAmountOnPlayerHealthBar = true,
	}
	UnitFrames.account = ZO_SavedVars:NewAccountWide(ADDON_NAME.."_Data", 1, nil, DEFAULT_SETTINGS)

	local enableApproachAmountOnPlayerHealthBar = UnitFrames.account.enableApproachAmountOnPlayerHealthBar
	HookSmoothTransition(enableApproachAmountOnPlayerHealthBar)

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_SECTION_TARGET_FRAME),
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_CLASS_ICON),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_CLASS_ICON_TT),
		default = DEFAULT_SETTINGS.showClassIcon,
		getFunction = function() return UnitFrames.account.showClassIcon end,
		setFunction = function(bool)
			UnitFrames.account.showClassIcon = bool
			UpdateTargetWindow()
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_SWITCH_NAMES),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_SWITCH_NAMES_TT),
		default = DEFAULT_SETTINGS.switchNames,
		getFunction = function() return UnitFrames.account.switchNames end,
		setFunction = function(bool)
			UnitFrames.account.switchNames = bool
			UpdateTargetWindow()
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_HIDE_TITLE),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_HIDE_TITLE_TT),
		default = DEFAULT_SETTINGS.hideTitle,
		getFunction = function() return UnitFrames.account.hideTitle end,
		setFunction = function(bool)
			UnitFrames.account.hideTitle = bool
			UpdateTargetWindow()
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_SECTION_GROUP_PET_FRAME),
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_HEALTH_WARNER),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_HEALTH_WARNER_TT),
		default = DEFAULT_SETTINGS.showHealthWarner,
		getFunction = function() return UnitFrames.account.showHealthWarner end,
		setFunction = function(bool)
			UnitFrames.account.showHealthWarner = bool
			UnitFrames:SetWarner(bool)
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_UNIT_SHIELDS),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_UNIT_SHIELDS_TT),
		default = DEFAULT_SETTINGS.showUnitShield,
		getFunction = function() return UnitFrames.account.showUnitShield end,
		setFunction = function(bool)
			UnitFrames.account.showUnitShield = bool
			UnitFrames:SetShield(bool)
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_PET_HEALTH),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_PET_HEALTH_TT),
		default = DEFAULT_SETTINGS.enablePetHealth,
		getFunction = function() return UnitFrames.account.enablePetHealth end,
		setFunction = function(bool)
			UnitFrames.account.enablePetHealth = bool
			UnitFrames:RefreshPetFrames()
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_SECTION_HEALTH_BARS),
	}

	do
		local Modes = {
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_INSTANT), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_INSTANT },
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_ULTRA_FAST), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_ULTRA_FAST },
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_SUPER_FAST), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_SUPER_FAST },
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_FASTER), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_FASTER },
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_FAST), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_FAST },
			{ name = GetString(SI_UNITFRAMESREBIRTH_APPROACH_DEFAULT), data = UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_DEFAULT },
		}

		local ModeToData = { }
		for i = 1, #Modes do ModeToData[Modes[i].data] = Modes[i] end

		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_APPROACH_HEALTHBAR),
			tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_APPROACH_HEALTHBAR_TT),
			items = Modes,
			default = ModeToData[DEFAULT_SETTINGS.approachAmountMs].name,
			getFunction = function() return (ModeToData[UnitFrames.account.approachAmountMs] or ModeToData[DEFAULT_SETTINGS.approachAmountMs]).name end,
			setFunction = function(combobox, name, item) UnitFrames.account.approachAmountMs = item.data end,
		}
	end

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_PLAYER_HEALTHBAR),
		tooltip = GetString(SI_UNITFRAMESREBIRTH_SETTINGS_PLAYER_HEALTHBAR_TT),
		default = DEFAULT_SETTINGS.enableApproachAmountOnPlayerHealthBar,
		getFunction = function() return UnitFrames.account.enableApproachAmountOnPlayerHealthBar end,
		setFunction = function(bool) UnitFrames.account.enableApproachAmountOnPlayerHealthBar = bool end,
	}
end

local function OnAddOnLoaded(event, name)
	if name ~= ADDON_NAME then return end
	EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

	CreateSettings()

	UnitFrames:SetWarner(UnitFrames.account.showHealthWarner)
	UnitFrames:SetShield(UnitFrames.account.showUnitShield)
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
