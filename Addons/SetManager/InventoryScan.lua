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
		local function ScanCrafting()
			local result = { }

			-- 		local styles = { }
			-- 		result.styles = styles
			-- 		local GetSmithingStyleItemInfo = GetSmithingStyleItemInfo
			-- 		for styleIndex = 1, GetNumSmithingStyleItems() do
			-- 			local name, icon, sellPrice, meetsUsageRequirement, itemStyle, quality = GetSmithingStyleItemInfo(styleIndex)
			-- 			if meetsUsageRequirement then
			-- 				styles[#styles + 1] = itemStyle
			-- 			end
			-- 		end

			-- 		local traits = { }
			-- 		result.traits = traits
			-- 		local GetSmithingTraitItemInfo = GetSmithingTraitItemInfo
			-- 		for traitIndex = 1, GetNumSmithingTraitItems() do
			-- 			local traitType, name, icon, sellPrice, meetsUsageRequirement, itemStyle, quality = GetSmithingTraitItemInfo(traitIndex)
			-- 			if traitType then
			-- 				if meetsUsageRequirement and traitType ~= ITEM_TRAIT_TYPE_NONE then
			-- 					traits[#traits + 1] = traitType
			-- 				end
			-- 			end
			-- 		end

			return result
		end
		addon.account.sets = ScanInventory(BAG_BANK)
		-- addon.player.sets = ScanInventory(BAG_WORN, ScanInventory(BAG_BAGBACK))
		addon.player.sets = ScanInventory(BAG_BAGBACK)
		-- TODO: scan all other player's sets
		addon.player.crafting = ScanCrafting()
		addon:DoCompleteProcess()
	end

	em:RegisterForEvent(addon.name, EVENT_PLAYER_DEACTIVATED, PlayerDeactivated)
end
