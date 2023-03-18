local RFT = RFT

local function IsItemFish(slotData)
	if slotData.bagId ~= BAG_BACKPACK then
		return false
	end
	return SPECIALIZED_ITEMTYPE_COLLECTIBLE_RARE_FISH == slotData.specializedItemType
end

local function ZoneIdOfPlayer()
	return ZO_ExplorationUtils_GetZoneStoryZoneIdByZoneIndex(GetUnitZoneIndex("player"))
end

local database
function RFT:InitCatchTracker()
	if not self.account.allowPerCharacter then
		function RFT:GetAchievementCriterion(achieveId, index)
			local desc, done = GetAchievementCriterion(achieveId, index)
			return desc, done
		end
		return
	end
	function RFT:GetAchievementCriterion(achieveId, index)
		local desc, done = GetAchievementCriterion(achieveId, index)
		-- done is a number, not boolean
		return desc, done and (BitAnd(database[achieveId] or 0, BitLShift(1, index - 1)) ~= 0) and 1 or 0
	end
	local charId = GetCurrentCharacterId()
	database = RareFishTrackerSavedVars[charId]
	if not database then
		database = {}
		RareFishTrackerSavedVars[charId] = database
	end
	SHARED_INVENTORY:RegisterCallback(
		"SlotAdded",
		function(bagId, slotIndex, slotData)
			if bagId ~= BAG_BACKPACK then
				return
			end
			if not IsItemFish(slotData) then
				return
			end
			local zoneId, achievements = RFT.GetAchievementsByZoneId(ZoneIdOfPlayer())
			local itemId = GetItemId(slotData.bagId, slotData.slotIndex)

			for _, achieveId in pairs(achievements) do
				local index = (ZO_IndexOfElementInNumericallyIndexedTable(RFT.achievementToItem[achieveId], itemId) or 0) - 1
				if index >= 0 then
					local bit = BitLShift(1, index)

					local bitfield = database[achieveId] or 0
					local bitfieldNew = BitOr(bitfield, bit)
					database[achieveId] = bitfieldNew
					if bitfieldNew ~= bitfield then
						self.ProcessUpdate(0, achieveId)
					end
				end
			end
		end
	)

	SLASH_COMMANDS["/rftzone"] = function(arg)
		local bitfield, done
		if arg == "clear" then
			bitfield, done = 0, 0
		else
			bitfield, done = 4095, 1
		end

		local zoneId, achievements = RFT.GetAchievementsByZoneId(ZoneIdOfPlayer())
		for _, achieveId in pairs(achievements) do
			database[achieveId] = bitfield
			local list = RFT.progress[achieveId]
			for fish in pairs(list) do
				list[fish] = done
			end
		end
		RFT.RefreshWindow()
	end
end
