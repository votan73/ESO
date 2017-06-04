local addon = SET_MANAGER
local em = GetEventManager()

function addon:InitInventoryScan()
	local function ScanInventory(bagId, list, addTo)
		list = list or { }
		if not addTo then
			ZO_ClearNumericallyIndexedTable(list)
		end

		local IsEquipable, GetItemLink, GetItemLinkSetInfo, ZO_GetNextBagSlotIndex = IsEquipable, GetItemLink, GetItemLinkSetInfo, ZO_GetNextBagSlotIndex

		local slotIndex = ZO_GetNextBagSlotIndex(bagId, nil)
		while slotIndex do
			if IsEquipable(bagId, slotIndex) then
				local itemLink = GetItemLink(bagId, slotIndex)
				local hasSet = GetItemLinkSetInfo(itemLink, false)
				if hasSet then
					list[#list + 1] = itemLink
				end
			end
			slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
		end

		return list
	end
	local function ScanBags()
		addon.account.sets = ScanInventory(BAG_BANK, addon.account.sets)
		addon.account.sets = ScanInventory(BAG_SUBSCRIBER_BANK, addon.account.sets, true)
		addon.player.worn = ScanInventory(BAG_WORN, addon.player.worn)
		addon.player.sets = ScanInventory(BAG_BACKPACK, addon.player.sets)
	end
	local function ScanCrafting(list)
		list = list or { }
		ZO_ClearNumericallyIndexedTable(list)

		return list
	end

	local function PlayerDeactivated()
		ScanBags()
		addon.player.crafting = ScanCrafting(addon.player.crafting)
	end
	SETMANAGER_CHARACTER_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWING then
			ScanBags()
		end
	end )

	em:RegisterForEvent(addon.name, EVENT_PLAYER_DEACTIVATED, PlayerDeactivated)
end
