local function IsSetItemCollected(itemLink)
    if not IsItemLinkSetCollectionPiece(itemLink) then
        return true
    end
    local hasSet, _, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)
    if not hasSet then
        return true
    end -- Non-Sets are "collected"
    local slot = GetItemLinkItemSetCollectionSlot(itemLink)
    return IsItemSetCollectionSlotUnlocked(setId, slot)
end

local function IsNotKnown(bagId, slotIndex)
    return not IsSetItemCollected(GetItemLink(bagId, slotIndex))
end

local function HandleTabSwitch(tabData)
    PLAYER_INVENTORY:ChangeFilter(tabData)
end

local function CreateNewTabFilterData(filterType, inventoryType, filterString, normal, pressed, highlight, hiddenColumns, hideTab, isSubFilter)
    local tabData = {
        -- Custom data
        filterType = filterType,
        inventoryType = inventoryType,
        isSubFilter = isSubFilter,
        hiddenColumns = hiddenColumns,
        activeTabText = filterString,
        tooltipText = filterString,
        -- Menu bar data
        hidden = hideTab,
        ignoreVisibleCheck = hideTab == true,
        descriptor = filterType,
        normal = normal,
        pressed = pressed,
        highlight = highlight,
        callback = HandleTabSwitch
    }

    return tabData
end

local IS_SUB_FILTER = true
local hideColumnTable, hideTabFunction
do
    local filterData = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterDisplayInfo(ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS)
    assert(filterData)
    hideColumnTable, hideTabFunction = filterData.hideColumnTable, filterData.hideTabFunction
end

do
    local function addFilter(currentInventoryType, subFilterKey)
        local searchFilterAtId = PLAYER_INVENTORY.inventories[currentInventoryType].subFilters[subFilterKey]
        local filter =
            CreateNewTabFilterData(
            function(slot)
                return IsNotKnown(slot.bagId, slot.slotIndex)
            end,
            currentInventoryType,
            GetString(SI_VOTANS_INVENTORY_FILTER_UNKNOWN_SET),
            "EsoUI/Art/Collections/collections_tabIcon_itemSets_up.dds",
            "EsoUI/Art/Collections/collections_tabIcon_itemSets_down.dds",
            "EsoUI/Art/Collections/collections_tabIcon_itemSets_over.dds",
            hideColumnTable,
            hideTabFunction,
            IS_SUB_FILTER
        )
        table.insert(searchFilterAtId, 1, filter)
    end
    --Causes nil error, because the tab is build already
    --addFilter(INVENTORY_BACKPACK, ITEM_TYPE_DISPLAY_CATEGORY_ALL)

    addFilter(INVENTORY_BACKPACK, ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS)
    addFilter(INVENTORY_BACKPACK, ITEM_TYPE_DISPLAY_CATEGORY_ARMOR)
    addFilter(INVENTORY_BACKPACK, ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY)
    addFilter(INVENTORY_BANK, ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS)
    addFilter(INVENTORY_BANK, ITEM_TYPE_DISPLAY_CATEGORY_ARMOR)
    addFilter(INVENTORY_BANK, ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY)
    addFilter(INVENTORY_HOUSE_BANK, ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS)
    addFilter(INVENTORY_HOUSE_BANK, ITEM_TYPE_DISPLAY_CATEGORY_ARMOR)
    addFilter(INVENTORY_HOUSE_BANK, ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY)
end
do
    local isContainer = {
        [SPECIALIZED_ITEMTYPE_CONTAINER] = true,
        [SPECIALIZED_ITEMTYPE_CONTAINER_CURRENCY] = true,
        [SPECIALIZED_ITEMTYPE_CONTAINER_EVENT] = true,
        [SPECIALIZED_ITEMTYPE_CONTAINER_STYLE_PAGE] = true
    }
    local function addFilter(currentInventoryType, subFilterKey)
        local searchFilterAtId = PLAYER_INVENTORY.inventories[currentInventoryType].subFilters[subFilterKey]
        local filter =
            CreateNewTabFilterData(
            function(slot)
                return isContainer[slot.specializedItemType]
            end,
            currentInventoryType,
            GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_CONTAINER),
            "EsoUI/Art/Inventory/inventory_tabIcon_container_up.dds",
            "EsoUI/Art/Inventory/inventory_tabIcon_container_down.dds",
            "EsoUI/Art/Inventory/inventory_tabIcon_container_over.dds",
            hideColumnTable,
            hideTabFunction,
            IS_SUB_FILTER
        )
        table.insert(searchFilterAtId, 4, filter)
    end
    addFilter(INVENTORY_GUILD_BANK, ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE)
end

local buttonSize = 35
local inventories = PLAYER_INVENTORY.inventories
for inventoryType, inventory in pairs(inventories) do
    local subTabs = inventory.subFilterBar
    if subTabs then
        local buttonData = subTabs.m_object
        buttonData.m_normalSize = buttonSize
        buttonData.m_downSize = buttonSize
        buttonData.m_buttonPadding = -15
    end
end

do
    local menuBar, subMenuBar, layoutData
    local orgApplyBackpackLayout = PLAYER_INVENTORY.ApplyBackpackLayout
    function PLAYER_INVENTORY.ApplyBackpackLayout(...)
        local self
        self, layoutData = ...

        -- backup for OnShown
        local inventory = self.inventories[INVENTORY_BACKPACK]
        menuBar, subMenuBar = inventory.filterBar, inventory.subFilterBar

        if self.appliedLayout and self.appliedLayout ~= layoutData then
            layoutData.selectedTab = self.appliedLayout.selectedTab or ITEM_TYPE_DISPLAY_CATEGORY_ALL
            layoutData.selectedSubTab = self.appliedLayout.selectedSubTab or ITEM_TYPE_DISPLAY_CATEGORY_ALL
        end
        return orgApplyBackpackLayout(...)
    end

    local function selectDefaultTabIfRequired(menuBar)
        if menuBar and not ZO_MenuBar_GetSelectedDescriptor(menuBar) then
            ZO_MenuBar_SelectDescriptor(menuBar, ITEM_TYPE_DISPLAY_CATEGORY_ALL)
        end
    end
    local function restoreTabs()
        if layoutData.selectedSubTab and layoutData.selectedSubTab ~= ITEM_TYPE_DISPLAY_CATEGORY_ALL then
            ZO_MenuBar_SelectDescriptor(subMenuBar, layoutData.selectedSubTab)
        end
        selectDefaultTabIfRequired(menuBar)
        selectDefaultTabIfRequired(subMenuBar)
    end
    local orgShow = ZO_BackpackLayoutFragment.Show
    function ZO_BackpackLayoutFragment.Show(...)
        local fragment = ...
        local orgOnShown = fragment.OnShown
        function fragment.OnShown(...)
            fragment.OnShown = orgOnShown
            restoreTabs()
            return orgOnShown(...)
        end
        return orgShow(...)
    end

    local function saveSelectedTabs(self, layoutData)
        local inventory = self.inventories[INVENTORY_BACKPACK]
        menuBar, subMenuBar = inventory.filterBar, inventory.subFilterBar

        layoutData.selectedTab = menuBar and ZO_MenuBar_GetSelectedDescriptor(menuBar) or ITEM_TYPE_DISPLAY_CATEGORY_ALL
        layoutData.selectedSubTab = subMenuBar and ZO_MenuBar_GetSelectedDescriptor(subMenuBar) or ITEM_TYPE_DISPLAY_CATEGORY_ALL
        if self.appliedLayout then
            self.appliedLayout.selectedTab = layoutData.selectedTab
            self.appliedLayout.selectedSubTab = layoutData.selectedSubTab
        end
    end
    local orgHide = ZO_BackpackLayoutFragment.Hide
    function ZO_BackpackLayoutFragment.Hide(...)
        saveSelectedTabs(PLAYER_INVENTORY, PLAYER_INVENTORY.appliedLayout)
        return orgHide(...)
    end
end

if QUICKSLOT_WINDOW then
    for i = 1, #QUICKSLOT_WINDOW.quickslotFilters do
        if QUICKSLOT_WINDOW.quickslotFilters[i].descriptor == ITEMFILTERTYPE_ALL then
            table.remove(QUICKSLOT_WINDOW.quickslotFilters, i)
            break
        end
    end
    local button = ZO_MenuBar_GetButtonControl(QUICKSLOT_WINDOW.tabs, ITEMFILTERTYPE_ALL)
    if button then
        button:SetHidden(true)
    end
end
