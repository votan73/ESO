local addon = {
	name = "VotansUIFixes"
}
local em = GetEventManager()

function CHAT_MENU_GAMEPAD:AddMessage()
end

function CHAT_MENU_GAMEPAD:OnChatChannelChanged()
end

function MAIN_MENU_GAMEPAD:UpdateEntryEnabledStates()
end

function GAMEPAD_WORLD_MAP_LOCATIONS:UpdateSelectedMap()
end

function CAMPAIGN_EMPEROR_GAMEPAD:CommitScrollList()
end

function ZO_AntiquityJournalGamepad:RefreshData()
end

function ZO_MapAntiquities_Gamepad:RefreshList()
end

function MAIN_MENU_GAMEPAD:RefreshLists()
end

function MAIN_MENU_GAMEPAD:RefreshMainList()
end

function ZONE_STORIES_GAMEPAD:BuildZoneList()
end

function ZONE_STORIES_GAMEPAD:UpdateZoneStory()
end

function ZO_RetraitStation_Retrait_Gamepad:RefreshHeader()
end

function ZO_ACTIVITY_FINDER_ROOT_GAMEPAD.RefreshCategories()
end

function ANTIQUITY_JOURNAL_LIST_GAMEPAD.RefreshAntiquities()
end

function ARMORY_GAMEPAD.RefreshList()
end

function ZO_COMPANION_GAMEPAD.RefreshList()
end

EVENT_MANAGER:UnregisterForUpdate("DirectionalInput")

do
	local function SetInverseKinematics(value)
		SetSetting(SETTING_TYPE_IN_WORLD, IN_WORLD_UI_SETTING_FOOT_INVERSE_KINEMATICS, value and "1" or "0")
	end

	local identifier = "NoInverseKinematicsAtStation"
	local oldState = true
	em:RegisterForEvent(
		identifier,
		EVENT_CRAFTING_STATION_INTERACT,
		function()
			oldState = GetSetting_Bool(SETTING_TYPE_IN_WORLD, IN_WORLD_UI_SETTING_FOOT_INVERSE_KINEMATICS)
			SetInverseKinematics(false)
		end
	)

	em:RegisterForEvent(
		identifier,
		EVENT_END_CRAFTING_STATION_INTERACT,
		function()
			SetInverseKinematics(oldState)
		end
	)
end

