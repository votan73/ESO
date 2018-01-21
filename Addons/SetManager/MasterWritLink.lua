local function ShowPopupMenu(inventorySlot, slotActions)
	if not slotActions.m_contextMenuMode then return false end

	local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
	local itemType = GetItemType(bagId, slotIndex)
	return itemType == ITEMTYPE_MASTER_WRIT
end

local function AddMenuItem(inventorySlot, slotActions)
	slotActions:AddCustomSlotAction(SI_BINDING_NAME_SET_MANAGER_WRIT_POPUP, function(...)
		local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
		local itemLink = GetItemLink(bagId, slotIndex)
		ZO_PopupTooltip_SetLink(itemLink)
	end , "")
end

local function AddItem(...)
	if ShowPopupMenu(...) then
		-- Temporary replace function
		assert(ZO_InventorySlotActions.Show, "ZO_InventorySlotActions.Show nil")
		local orgShow = ZO_InventorySlotActions.Show
		local inventorySlot, slotActions = ...
		function ZO_InventorySlotActions.Show(...)
			AddMenuItem(inventorySlot, slotActions)
			ZO_InventorySlotActions.Show = orgShow
			return ZO_InventorySlotActions.Show(...)
		end
	end
end

ZO_PreHook("ZO_InventorySlot_DiscoverSlotActionsFromActionList", AddItem)
