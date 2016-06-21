local addon = SET_MANAGER
local em = GetEventManager()

function addon:InitInventoryScan()
	local function PlayerDeactivated()
		local function ScanInventory(bagId, list)
			list = list or { }

			local slotIndex = ZO_GetNextBagSlotIndex(bagId, nil)
			local IsEquipable, GetItemLink, GetItemLinkSetInfo = IsEquipable, GetItemLink, GetItemLinkSetInfo
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
		addon.account.sets = ScanInventory(BAG_BANK)
		addon.player.sets = ScanInventory(BAG_WORN, ScanInventory(BAG_BAGBACK))
	end
	em:RegisterForEvent(addon.name, EVENT_PLAYER_DEACTIVATED, PlayerDeactivated)
end
