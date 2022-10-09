local addon = {
	name = "VotansHousingFilter"
}

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

	ZO_MenuBar_AddButton(
		self.toolBar,
		CreateButtonData(
			SI_ITEMFILTERTYPE0,
			1,
			"/esoui/art/inventory/inventory_tabicon_all_up.dds",
			"/esoui/art/inventory/inventory_tabicon_all_down.dds",
			"/esoui/art/inventory/inventory_tabicon_all_over.dds",
			"/esoui/art/inventory/inventory_tabicon_all_disabled.dds"
		)
	)
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
			if selectedMode == 1 then
				return orgGetPassesTextFilter(...)
			end
			return false
		end
	end
end
addon:InitPlaceableFilter()

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

	ZO_MenuBar_AddButton(
		self.toolBar,
		CreateButtonData(
			SI_ITEMFILTERTYPE0,
			1,
			"/esoui/art/inventory/inventory_tabicon_all_up.dds",
			"/esoui/art/inventory/inventory_tabicon_all_down.dds",
			"/esoui/art/inventory/inventory_tabicon_all_over.dds",
			"/esoui/art/inventory/inventory_tabicon_all_disabled.dds"
		)
	)
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
addon:InitProductFilter()
