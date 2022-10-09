local function OnCallback(dialog, button)
	local data = dialog.data
	ZO_VeteranDifficultyButton_OnClicked(button)
	return data.callback(unpack(data.params))
end

ESO_Dialogs["VOTANS_GROUP_DUNGEON_DIFFICULTY"] = {
	mustChoose = true,
	title = {
		text = function(dialog)
			local data = dialog.data
			local pin = data.params[1]
			local nodeIndex = pin:GetFastTravelNodeIndex()
			local _, recallLocationName = GetFastTravelNodeInfo(nodeIndex)
			return zo_strformat(SI_WORLD_MAP_LOCATION_NAME, recallLocationName)
		end
	},
	mainText = {
		text = SI_DUNGEON_DIFFICULTY_HEADER
	},
	buttons = {
		[1] = {
			text = GetString("SI_DUNGEONDIFFICULTY", DUNGEON_DIFFICULTY_VETERAN),
			callback = function(dialog)
				return OnCallback(dialog, ZO_GroupListVeteranDifficultySettingsVeteranDifficulty)
			end
		},
		[2] = {
			text = GetString("SI_DUNGEONDIFFICULTY", DUNGEON_DIFFICULTY_NORMAL),
			callback = function(dialog)
				return OnCallback(dialog, ZO_GroupListVeteranDifficultySettingsNormalDifficulty)
			end
		}
	}
}

local function hookPinHandler(recall)
	local ocallback = recall.callback
	recall.callback = function(...)
		local pin = ...
		local nodeIndex = pin:GetFastTravelNodeIndex()
		local poiType = select(7, GetFastTravelNodeInfo(nodeIndex))
		if poiType == POI_TYPE_GROUP_DUNGEON and (IsUnitGroupLeader("player") or not IsUnitGrouped("player")) then
			ZO_Dialogs_ShowPlatformDialog("VOTANS_GROUP_DUNGEON_DIFFICULTY", {callback = ocallback, params = {...}})
		else
			return ocallback(...)
		end
	end
end

local WAYSHRINE_LMB = ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_LEFT][MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE]
hookPinHandler(WAYSHRINE_LMB[1])
hookPinHandler(WAYSHRINE_LMB[2])
