
local LAM2 = LibAddonMenu2

local colorYellow = "|cFFFF00" 	-- yellow 
local colorRed = "|cFF0000" 	-- Red



-------------------------------------------------------------------------------------------------
--  Settings Menu --
-------------------------------------------------------------------------------------------------
function SetSwap_CreateSettingsMenu(self)
	local panelData = {
		type = "panel",
		name = "SetSwap",
		displayName = "|cFF0000 Circonians |c00FFFF SetSwap",
		author = "Circonian",
		version = self.codeVersion,
		slashCommand = "/setswap",
		registerForRefresh = true,
		registerForDefaults = true,
	}
	local cntrlOptionsPanel = LAM2:RegisterAddonPanel("Circonians_SetSwap_Options", panelData)

	local sv = self.sv

	local function DoesNotHaveRapidManeuver()
		local skillType, skillLineIndex, skillLineAbilityIndex = GetSpecificSkillAbilityKeysByAbilityId(40211)

		local _, _, _, _, _, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, skillLineAbilityIndex)

		return not purchased
	end

	local optionsData = {
		[1] =
		{
			type = "dropdown",
			name = "Toggle Rapid Maneuver Slot",
			tooltip = "Toggles between current ability & rapid maneuver in the selected slot. If rapid maneuver is already on the action bar in a different slot the toggle keybind will do nothing.\n\n" .. colorRed .. "Will be disabled if you do not have rapid maneuver.",
			choices = { "Off", 1, 2, 3, 4, 5 },
			default = "Off",
			disabled = function() return DoesNotHaveRapidManeuver() end,
			getFunc = function() return sv.rapidManeuverSlot end,
			setFunc = function(slotNum) sv.rapidManeuverSlot = slotNum end,
			reference = "SETSWAP_RAPID_MANEUVER",
		},
	}
	LAM2:RegisterOptionControls("Circonians_SetSwap_Options", optionsData)
end