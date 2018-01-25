local function ShowPopupMenu(inventorySlot, slotActions)
	local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
	local itemType = GetItemType(bagId, slotIndex)
	return itemType == ITEMTYPE_MASTER_WRIT
end

local function AddItem(inventorySlot, slotActions)
	if ShowPopupMenu(inventorySlot, slotActions) then
		slotActions:AddCustomSlotAction(SI_BINDING_NAME_SET_MANAGER_WRIT_POPUP, function()
			local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
			local itemLink = GetItemLink(bagId, slotIndex)
			ZO_PopupTooltip_SetLink(itemLink)
		end , "")
	end
end

local menu = LibStub("LibCustomMenu")
menu:RegisterContextMenu(AddItem, menu.CATEGORY_SECONDARY)
