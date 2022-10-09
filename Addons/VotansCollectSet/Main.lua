local addon = {
  name = "VotansCollectSet"
}

local function BindItem(bagId, slotIndex)
  local worn = SHARED_INVENTORY:GetBagCache(BAG_WORN)
  local saveEquipment = {}
  for slotIndex, slot in pairs(worn) do
    saveEquipment[slotIndex] = slot and slot.itemInstanceId
  end

  local function Reequip(bagId, slotIndex)
    if bagId ~= BAG_BACKPACK then
      if bagId == BAG_WORN and not saveEquipment[slotIndex] then
        -- This slot was empty. Done.
        SHARED_INVENTORY:UnregisterCallback("SingleSlotInventoryUpdate", Reequip)
      end
      return
    end

    local backpack = SHARED_INVENTORY:GetBagCache(BAG_BACKPACK)
    for targetSlotIndex, itemInstanceId in pairs(saveEquipment) do
      for _, slot in pairs(backpack) do
        if slot.itemInstanceId == itemInstanceId then
          EquipItem(slot.bagId, slot.slotIndex, targetSlotIndex)
          return -- wait for the next slot update
        end
      end
    end
    -- No previously equipped item in backpack. Done.
    SHARED_INVENTORY:UnregisterCallback("SingleSlotInventoryUpdate", Reequip)
  end

  SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", Reequip)

  -- This starts the update cascade
  EquipItem(bagId, slotIndex)
end

local IsNotKnown = IsItemSetCollectionPieceUnlocked and function(...)
    return not IsItemSetCollectionPieceUnlocked(GetItemId(...))
  end or function(...)
    return not IsItemBound(...)
  end

local function ShowInMenu(inventorySlot)
  local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
  return bagId == BAG_BACKPACK and IsEquipable(bagId, slotIndex) and IsNotKnown(bagId, slotIndex)
end

local function AddItem(inventorySlot, slotActions)
  if ShowInMenu(inventorySlot) then
    slotActions:AddCustomSlotAction(
      SI_VOTANS_COLLECT_SET,
      function()
        local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
        BindItem(bagId, slotIndex)
      end,
      ""
    )
  end
end

local menu = LibCustomMenu
menu:RegisterContextMenu(AddItem, menu.CATEGORY_TERTIARY)
