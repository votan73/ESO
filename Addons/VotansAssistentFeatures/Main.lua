local addon = {
	name = "VotansAssistentFeatures"
}
local em = GetEventManager()

do
	-- Show Sell All Junk
	local orgSelectFragment = STORE_WINDOW.modeBar.SelectFragment
	function STORE_WINDOW.modeBar.SelectFragment(...)
		local self = STORE_WINDOW
		local mode = select(2, ...)
		if IsStoreEmpty() and mode == SI_STORE_MODE_SELL and not KEYBIND_STRIP:HasKeybindButtonGroup(self.keybindStripDescriptor) then
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
		end
		return orgSelectFragment(...)
	end
end

do
	local currentAssistent
	local keybindStripDescriptor = {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
		{
			name = "",
			keybind = "UI_SHORTCUT_QUATERNARY",
			callback = function()
				UseCollectible(currentAssistent:GetId())
			end,
			enabled = function()
				return currentAssistent ~= nil
			end
		}
	}
	local function handleScene(oldState, newState)
		if newState == SCENE_SHOWN then
			if IsInteractingWithMyAssistant() then
				currentAssistent = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT, GAMEPLAY_ACTOR_CATEGORY_PLAYER))
				local farewell = zo_strformat(SI_INTERACT_OPTION_DISMISS_ASSISTANT, currentAssistent:GetName())
				keybindStripDescriptor[1].name = farewell
				KEYBIND_STRIP:AddKeybindButtonGroup(keybindStripDescriptor)
			else
				currentAssistent = nil
			end
		elseif newState == SCENE_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(keybindStripDescriptor)
		end
	end
	SCENE_MANAGER:GetScene("bank"):RegisterCallback("StateChange", handleScene)
	SCENE_MANAGER:GetScene("store"):RegisterCallback("StateChange", handleScene)
	SCENE_MANAGER:GetScene("universalDeconstructionSceneKeyboard"):RegisterCallback("StateChange", handleScene)
end
