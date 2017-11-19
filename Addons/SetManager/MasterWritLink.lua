do
	local orgShow
	local function RemoveMouseOverKeybinds()
		if orgShow then
			ZO_InventorySlotActions.Show = orgShow
			orgShow = nil
		end
	end

	local function ShowPopupMenu(inventorySlot, slotActions)
		RemoveMouseOverKeybinds()

		local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
		local itemLink = GetItemLink(bagId, slotIndex)
		if itemLink ~= "" then
			local itemType = GetItemLinkItemType(itemLink)
			return itemType == ITEMTYPE_MASTER_WRIT
		end
		return false
	end

	local function AddMenuItem(inventorySlot, slotActions)
		slotActions:AddCustomSlotAction(SI_BINDING_NAME_SET_MANAGER_WRIT_POPUP, function(...)
			local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
			local itemLink = GetItemLink(bagId, slotIndex)
			ZO_PopupTooltip_SetLink(itemLink)
		end , "")
	end

	ZO_PreHook("ZO_InventorySlot_RemoveMouseOverKeybinds", RemoveMouseOverKeybinds)
	ZO_PreHook("ZO_InventorySlot_OnMouseExit", RemoveMouseOverKeybinds)
	do
		local orgZO_InventorySlot_ShowContextMenu = ZO_InventorySlot_ShowContextMenu
		function ZO_InventorySlot_ShowContextMenu(...)
			local orgZO_InventorySlot_DiscoverSlotActionsFromActionList = ZO_InventorySlot_DiscoverSlotActionsFromActionList
			function ZO_InventorySlot_DiscoverSlotActionsFromActionList(...)
				ZO_InventorySlot_DiscoverSlotActionsFromActionList = orgZO_InventorySlot_DiscoverSlotActionsFromActionList
				if ShowPopupMenu(...) then
					-- Temporary replace function
					local orgShow = ZO_InventorySlotActions.Show
					local inventorySlot, slotActions = ...
					function ZO_InventorySlotActions.Show(...)
						AddMenuItem(inventorySlot, slotActions)
						ZO_InventorySlotActions.Show = orgShow
						orgShow = nil
						return ZO_InventorySlotActions.Show(...)
					end
				end
				return orgZO_InventorySlot_DiscoverSlotActionsFromActionList(...)
			end
			return orgZO_InventorySlot_ShowContextMenu(...)
		end
	end
end