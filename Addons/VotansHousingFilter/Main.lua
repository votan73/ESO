local addon = {
	name = "VotansHousingFilter"
}

if GetAPIVersion() < 101037 then
	function addon:InitPlaceableFilter()
		local parent = KEYBOARD_HOUSING_FURNITURE_BROWSER.placeablePanel.control

		self.toolBar = CreateControlFromVirtual("$(parent)ToolBar", parent, "ZO_MenuBarTemplate")
		self.toolBar:ClearAnchors()
		self.toolBar:SetAnchor(LEFT, KEYBOARD_HOUSING_FURNITURE_BROWSER.placeablePanel.searchEditBox, RIGHT, 12, 0)

		ZO_MenuBar_OnInitialized(self.toolBar)
		local barData = {
			buttonPadding = -4,
			normalSize = 32,
			downSize = 32,
			animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
			buttonTemplate = "ZO_MenuBarTooltipButton"
		}
		ZO_MenuBar_SetData(self.toolBar, barData)
		ZO_MenuBar_SetClickSound(self.toolBar, "DEFAULT_CLICK")

		local selectedMode
		local additionalFilter
		local function CreateButtonData(name, mode, normal, pressed, highlight, disabled, filter)
			return {
				activeTabText = name,
				categoryName = name,
				descriptor = mode,
				normal = normal,
				pressed = pressed,
				highlight = highlight,
				disabled = disabled,
				callback = function(tabData)
					selectedMode = tabData.descriptor
					additionalFilter = filter
					SHARED_FURNITURE:RequestApplyPlaceableTextFilterToData()
					PlaySound(SOUNDS.DEFAULT_CLICK)
				end
			}
		end

		ZO_MenuBar_AddButton(self.toolBar, CreateButtonData(SI_ITEMFILTERTYPE0, 1, "/esoui/art/inventory/inventory_tabicon_all_up.dds", "/esoui/art/inventory/inventory_tabicon_all_down.dds", "/esoui/art/inventory/inventory_tabicon_all_over.dds", "/esoui/art/inventory/inventory_tabicon_all_disabled.dds"))
		ZO_MenuBar_AddButton(
			self.toolBar,
			CreateButtonData(
				SI_MAIN_MENU_INVENTORY,
				2,
				"/esoui/art/mainmenu/menubar_inventory_up.dds",
				"/esoui/art/mainmenu/menubar_inventory_down.dds",
				"/esoui/art/mainmenu/menubar_inventory_over.dds",
				"/esoui/art/mainmenu/menubar_inventory_disabled.dds",
				function(slot)
					return slot.bagId == BAG_BACKPACK
				end
			)
		)
		local bankSlot = {
			[BAG_BANK] = true,
			[BAG_SUBSCRIBER_BANK] = true
		}
		ZO_MenuBar_AddButton(
			self.toolBar,
			CreateButtonData(
				SI_GAMEPAD_BANK_CATEGORY_HEADER,
				3,
				"VotansHousingFilter/tabicon_bank_up.dds",
				"VotansHousingFilter/tabicon_bank_down.dds",
				"VotansHousingFilter/tabicon_bank_over.dds",
				"VotansHousingFilter/tabicon_bank_disabled.dds",
				function(slot)
					return bankSlot[slot.bagId]
				end
			)
		)
		local chestSlot = {
			[BAG_HOUSE_BANK_ONE] = true,
			[BAG_HOUSE_BANK_TWO] = true,
			[BAG_HOUSE_BANK_THREE] = true,
			[BAG_HOUSE_BANK_FOUR] = true,
			[BAG_HOUSE_BANK_FIVE] = true,
			[BAG_HOUSE_BANK_SIX] = true,
			[BAG_HOUSE_BANK_SEVEN] = true,
			[BAG_HOUSE_BANK_EIGHT] = true,
			[BAG_HOUSE_BANK_NINE] = true,
			[BAG_HOUSE_BANK_TEN] = true
		}
		ZO_MenuBar_AddButton(
			self.toolBar,
			CreateButtonData(
				SI_ITEMTYPE18,
				4,
				"/esoui/art/inventory/inventory_tabicon_container_up.dds",
				"/esoui/art/inventory/inventory_tabicon_container_down.dds",
				"/esoui/art/inventory/inventory_tabicon_container_over.dds",
				"/esoui/art/inventory/inventory_tabicon_container_disabled.dds",
				function(slot)
					return chestSlot[slot.bagId]
				end
			)
		)
		ZO_MenuBar_AddButton(
			self.toolBar,
			CreateButtonData(
				SI_HOUSINGFURNISHINGLIMITTYPE2,
				5,
				"/esoui/art/icons/achievements_indexicon_collections_up.dds",
				"/esoui/art/icons/achievements_indexicon_collections_down.dds",
				"/esoui/art/icons/achievements_indexicon_collections_over.dds",
				"/esoui/art/icons/achievements_indexicon_collections_disabled.dds",
				function(slot)
					return false
				end
			)
		)
		ZO_MenuBar_SelectDescriptor(self.toolBar, 1, true)

		do
			local orgGetPassesTextFilter = ZO_PlaceableFurnitureItem.GetPassesTextFilter
			function ZO_PlaceableFurnitureItem.GetPassesTextFilter(...)
				if not additionalFilter then
					return orgGetPassesTextFilter(...)
				end
				return orgGetPassesTextFilter(...) and additionalFilter(...)
			end
		end
		do
			local orgGetPassesTextFilter = ZO_PlaceableFurnitureCollectible.GetPassesTextFilter
			function ZO_PlaceableFurnitureCollectible.GetPassesTextFilter(...)
				if selectedMode == 1 or selectedMode == 5 then
					return orgGetPassesTextFilter(...)
				end
				return false
			end
		end
	end
	addon:InitPlaceableFilter()
end

local craftables
local function createCraftablesLookup()
	craftables = {}
	for station = 1, 7 do
		for _, list in pairs(PROVISIONER_MANAGER:GetRecipeListData(station)) do
			for _, recipe in pairs(list.recipes) do
				if recipe.specialIngredientType == 3 then
					craftables[recipe.iconFile] = ZO_CachedStrFormat("<<C:1>>", recipe.name)
				end
			end
		end
	end
end
if GetAPIVersion() < 101037 then
	function addon:InitProductFilter()
		local parent = KEYBOARD_HOUSING_FURNITURE_BROWSER.productsPanel.control

		self.toolBar = CreateControlFromVirtual("$(parent)ToolBar", parent, "ZO_MenuBarTemplate")
		self.toolBar:ClearAnchors()
		self.toolBar:SetAnchor(LEFT, KEYBOARD_HOUSING_FURNITURE_BROWSER.productsPanel.searchEditBox, RIGHT, 12, 0)

		ZO_MenuBar_OnInitialized(self.toolBar)
		local barData = {
			buttonPadding = -4,
			normalSize = 32,
			downSize = 32,
			animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
			buttonTemplate = "ZO_MenuBarTooltipButton"
		}
		ZO_MenuBar_SetData(self.toolBar, barData)
		ZO_MenuBar_SetClickSound(self.toolBar, "DEFAULT_CLICK")

		local selectedMode
		local additionalFilter
		local function CreateButtonData(name, mode, normal, pressed, highlight, disabled, filter)
			return {
				activeTabText = name,
				categoryName = name,
				descriptor = mode,
				normal = normal,
				pressed = pressed,
				highlight = highlight,
				disabled = disabled,
				callback = function(tabData)
					selectedMode = tabData.descriptor
					additionalFilter = filter
					PlaySound(SOUNDS.DEFAULT_CLICK)
					return SHARED_FURNITURE:RequestApplyMarketProductTextFilterToData()
				end
			}
		end

		ZO_MenuBar_AddButton(self.toolBar, CreateButtonData(SI_ITEMFILTERTYPE0, 1, "/esoui/art/inventory/inventory_tabicon_all_up.dds", "/esoui/art/inventory/inventory_tabicon_all_down.dds", "/esoui/art/inventory/inventory_tabicon_all_over.dds", "/esoui/art/inventory/inventory_tabicon_all_disabled.dds"))
		local function IsCraftable(slot)
			if not craftables then
				createCraftablesLookup()
			end
			local name = craftables[slot.icon]
			return name and name == slot:GetFormattedName()
		end
		ZO_MenuBar_AddButton(
			self.toolBar,
			CreateButtonData(
				SI_VOTANS_HOUSING_FILTER_NEED_PURCHASE,
				2,
				"/esoui/art/vendor/vendor_tabicon_buy_up.dds",
				"/esoui/art/vendor/vendor_tabicon_buy_down.dds",
				"/esoui/art/vendor/vendor_tabicon_buy_over.dds",
				"/esoui/art/vendor/vendor_tabicon_buy_disabled.dds",
				function(slot)
					return not IsCraftable(slot)
				end
			)
		)
		ZO_MenuBar_AddButton(
			self.toolBar,
			CreateButtonData(
				SI_VOTANS_HOUSING_FILTER_NEED_COULD_CRAFT,
				3,
				"/esoui/art/inventory/inventory_tabicon_crafting_up.dds",
				"/esoui/art/inventory/inventory_tabicon_crafting_down.dds",
				"/esoui/art/inventory/inventory_tabicon_crafting_over.dds",
				"/esoui/art/inventory/inventory_tabicon_crafting_disabled.dds",
				function(slot)
					return IsCraftable(slot)
				end
			)
		)
		ZO_MenuBar_SelectDescriptor(self.toolBar, 1, true)

		do
			local orgGetPassesTextFilter = ZO_HousingMarketProduct.GetPassesTextFilter
			function ZO_HousingMarketProduct.GetPassesTextFilter(...)
				if not additionalFilter then
					return orgGetPassesTextFilter(...)
				end
				return orgGetPassesTextFilter(...) and additionalFilter(...)
			end
		end
	end
else
	function addon:InitProductFilter()
		local parent = KEYBOARD_HOUSING_FURNITURE_BROWSER.productsPanel.control:GetNamedChild("Contents")

		local dropdown = CreateControlFromVirtual("$(parent)VotanFiltersDropdown", parent, "ZO_MultiselectComboBox")
		dropdown:SetWidth(200)
		dropdown:ClearAnchors()
		dropdown:SetAnchor(TOPRIGHT, parent:GetNamedChild("ThemeDropdown"), TOPLEFT, -9, 0)
		self.productFilters = dropdown

		local comboBox = ZO_ComboBox_ObjectFromContainer(dropdown)
		-- Subcategory options are disabled but we do not want them to have the disabled visuals.
		comboBox:SetDisabledColor(ZO_DEFAULT_ENABLED_COLOR)
		comboBox:SetFont("ZoFontWinT1")
		comboBox:SetSortsItems(false)
		comboBox:SetSpacing(4)
		comboBox:SetNoSelectionText(zo_strformat(SI_HOUSING_FURNITURE_FILTER_DROPDOWN_TEXT, 0))
		comboBox:SetMultiSelectionTextFormatter(SI_HOUSING_FURNITURE_FILTER_DROPDOWN_TEXT)

		local additionalFilter

		local function DisableHighlightOnMouseEnter(control)
			-- Suppress the highlight for subcategory entries.
			ZO_Menu_UnselectItem(control)
		end

		local DISABLED = false
		local NO_CALLBACK = nil

		local categories = {}
		local byCategory = function(slot)
			for _, category in pairs(categories) do
				local found = false
				for i = 1, #category do
					if category[i](slot) then
						found = true
						break
					end
				end
				if not found then
					return false
				end
			end
			return true
		end
		local function OnFiltersChanged(comboBox, entryText, entry)
			local selectedItems = comboBox:GetSelectedItemData()
			if #selectedItems == 0 then
				additionalFilter = nil
			elseif #selectedItems == 1 then
				additionalFilter = selectedItems[1].filterValue
			else
				ZO_ClearTable(categories)
				for _, item in ipairs(selectedItems) do
					local orFilter = categories[item.votanCategory] or {}
					orFilter[#orFilter + 1] = item.filterValue
					categories[item.votanCategory] = orFilter
				end

				additionalFilter = byCategory
			end
			PlaySound(SOUNDS.DEFAULT_CLICK)
			return SHARED_FURNITURE:RequestApplyMarketProductTextFilterToData()
		end

		do
			local entry = comboBox:CreateItemEntry(GetString(SI_MAIN_MENU_CHARACTER), NO_CALLBACK, DISABLED)
			entry.highlightColor = ZO_DEFAULT_ENABLED_COLOR
			entry.onEnter = DisableHighlightOnMouseEnter
			comboBox:AddItem(entry)
		end

		local function IsCraftable(slot)
			if not craftables then
				createCraftablesLookup()
			end
			local name = craftables[slot.icon]
			return name and name == slot:GetFormattedName()
		end

		do
			local filterName = zo_strformat(SI_HOUSING_FURNITURE_FILTER_LIST_ITEM_FORMATTER, GetString(SI_VOTANS_HOUSING_FILTER_NEED_COULD_CRAFT))
			local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
			entry.filterValue = function(slot)
				return IsCraftable(slot)
			end
			entry.votanCategory = SI_MAIN_MENU_CHARACTER
			comboBox:AddItem(entry)
		end

		do
			local filterName = zo_strformat(SI_HOUSING_FURNITURE_FILTER_LIST_ITEM_FORMATTER, GetString(SI_VOTANS_HOUSING_FILTER_NEED_PURCHASE))
			local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
			entry.filterValue = function(slot)
				return not IsCraftable(slot)
			end
			entry.votanCategory = SI_MAIN_MENU_CHARACTER
			comboBox:AddItem(entry)
		end

		do
			local entry = comboBox:CreateItemEntry(GetString(SI_MASTER_WRIT_DESCRIPTION_QUALITY), NO_CALLBACK, DISABLED)
			entry.highlightColor = ZO_DEFAULT_ENABLED_COLOR
			entry.onEnter = DisableHighlightOnMouseEnter
			comboBox:AddItem(entry)
		end

		for quality = ITEM_DISPLAY_QUALITY_NORMAL, ITEM_DISPLAY_QUALITY_LEGENDARY do
			local filterName = zo_strformat(SI_HOUSING_FURNITURE_FILTER_LIST_ITEM_FORMATTER, GetString("SI_ITEMQUALITY", quality))
			local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
			entry.filterValue = function(slot)
				return slot:GetDisplayQuality() == quality
			end
			entry.votanCategory = "quality"
			comboBox:AddItem(entry)
		end

		do
			local orgGetPassesTextFilter = ZO_HousingMarketProduct.GetPassesTextFilter
			function ZO_HousingMarketProduct.GetPassesTextFilter(...)
				if not additionalFilter then
					return orgGetPassesTextFilter(...)
				end
				return orgGetPassesTextFilter(...) and additionalFilter(...)
			end
		end
	end
end
addon:InitProductFilter()
