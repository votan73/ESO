local g_savedVars

local name = "VotanSearchBox"
local glass = " |t40:40:/esoui/art/tutorial/gamepad/gp_inventory_trait_not_researched_icon.dds|t"

local SEARCH_TYPE_INVENTORY = 1
local CACHE_DATA = true
local wm = GetWindowManager()
local LTF = LibTextFilter
local templateName = "ZO_InventorySearchTemplate"

local function VotanSearchBoxSetHidden(self, state)
	-- Keep hidden, no matter what FilterIt says
	self:VSBSetHidden(g_savedVars.hideSearchBox)
end

local function HideLabel(hidden)
	ZO_PlayerInventoryMenuBarLabel:SetHidden(hidden)
	ZO_SmithingTopLevelModeMenuBarLabel:SetHidden(hidden)
end

local function GetLowercase(name)
	return ZO_CachedStrFormat("<<z:1>>", name, 1)
end

local lowercase = {}

local lastSearchTerm
local lastIsMulti
local lastSplit

local GetItemLinkSetInfo, GetItemLink = GetItemLinkSetInfo, GetItemLink
local GenerateMasterWritBaseText, GetItemType, ITEMTYPE_MASTER_WRIT = GenerateMasterWritBaseText, GetItemType, ITEMTYPE_MASTER_WRIT

local function ProcessInventoryItem(_, data, searchTerm)
	if #searchTerm == 0 then
		return true
	end

	data = SHARED_INVENTORY:GetBagCache(data.bagId)[data.slotIndex]
	if not data then
		return false
	end
	local equipType = data.equipType
	if equipType and equipType > 0 then
		if g_savedVars.searchSetName then
			local hasSet, setName = GetItemLinkSetInfo(GetItemLink(data.bagId, data.slotIndex))
			if hasSet then
				local name = lowercase[setName]
				if not name then
					name = GetLowercase(setName)
					lowercase[setName] = name
				end
				if LTF:Filter(name, searchTerm) then
					return true
				end
			end
		end
	elseif g_savedVars.searchMasterWrit then
		local itemType = GetItemType(data.bagId, data.slotIndex)
		if itemType == ITEMTYPE_MASTER_WRIT then
			local itemLink = GetItemLink(data.bagId, data.slotIndex)
			local description = lowercase[itemLink]
			if not description then
				description = GenerateMasterWritBaseText(itemLink)
				description = description:lower()
				lowercase[itemLink] = description
			end
			if LTF:Filter(description, searchTerm) then
				return true
			end
		end
	end
	return LTF:Filter(GetLowercase(data.rawName), searchTerm)
end

local function EnhanceTextSearch()
	local function IsItemInSearchTextResultsBag(searchTerm, bagId, slotIndex)
		local slot = {["bagId"] = bagId, ["slotIndex"] = slotIndex}
		return ProcessInventoryItem(nil, slot, searchTerm)
	end
	local function IsItemInSearchTextResultsCollectible(searchTerm, collectibleId)
		local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
		return LTF:Filter(GetLowercase(collectibleData:GetName()), searchTerm)
	end
	local function search(currentContext, filter, ...)
		local searchTerm = TEXT_SEARCH_MANAGER:GetSearchText(currentContext)
		if #searchTerm < 2 then
			return false
		end
		return filter(searchTerm, ...)
	end
	local function IsItemInSearchTextResults(self, currentContext, target, ...)
		if target == BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT then
			return search(currentContext, IsItemInSearchTextResultsBag, ...)
		elseif target == BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID then
			return search(currentContext, IsItemInSearchTextResultsCollectible, ...)
		end
	end
	local orgProcessor = TEXT_SEARCH_MANAGER.IsItemInSearchTextResults
	TEXT_SEARCH_MANAGER.IsItemInSearchTextResults = function(...)
		return orgProcessor(...) or IsItemInSearchTextResults(...)
	end
end

local function VotanSearchBoxMouseDown(bagSearch, button)
	if not bagSearch:HasFocus() and button == MOUSE_BUTTON_INDEX_RIGHT then
		bagSearch:SetText("")
	end
end

local searchBoxes = {}
local searchContexts = {
	"fenceTextSearch",
	"guildBankTextSearch",
	"guildTraderTextSearch",
	"houseBankTextSearch",
	"playerBankTextSearch",
	"playerInventoryTextSearch",
	"quickslotTextSearch",
	"storeTextSearch",
	"tradeTextSearch"
}

local function setDefaultText(control, text)
	control:SetDefaultText(text)
end

local function SetupSearchBox(bagSearchBg, ...)
	local bagSearch = bagSearchBg:GetNamedChild("Box")
	local bagSearchTx = bagSearch:GetNamedChild("Text")
	local closeButton = wm:CreateControlFromVirtual(nil, bagSearchBg, "ZO_CloseButton")
	closeButton:SetExcludeFromResizeToFitExtents(true)
	bagSearch.background = bagSearchBg

	local textWidth = 170
	local otherControls = {...}
	local othersVisibility = {}
	local function KeepHidden(control, hidden)
		hidden = hidden or bagSearch:GetText() ~= ""
		return control.vsbSetHidden(control, hidden)
	end
	local function VotanSearchBoxFocusGained(bagSearch)
		setDefaultText(bagSearch, "")
		bagSearchBg:SetAlpha(0.25)
		bagSearchBg:SetWidth(textWidth)
		closeButton:SetHidden(false)
		HideLabel(true)

		for _, controlName in ipairs(otherControls) do
			local control = _G[controlName]
			if control then
				othersVisibility[control] = control:IsHidden()
			end
		end
		for control in pairs(othersVisibility) do
			if not control.vsbSetHidden then
				control.vsbSetHidden = control.SetHidden
				control.SetHidden = KeepHidden
			end
			control:SetHidden(true)
		end
		return false
	end
	local function updateBackground(control, text)
		if text and text ~= "" then
			bagSearchBg:SetAlpha(0.25)
			bagSearchBg:SetWidth(textWidth)
			closeButton:SetHidden(false)
			HideLabel(true)
			setDefaultText(bagSearch, "")
		else
			bagSearchBg:SetAlpha(0)
			bagSearchBg:SetWidth(64)
			closeButton:SetHidden(true)
			HideLabel(false)
			for control, hidden in pairs(othersVisibility) do
				control:SetHidden(hidden)
			end
			setDefaultText(bagSearch, glass)
		end

		if g_savedVars.allSameText then
			for i = 1, #searchContexts do
				if not TEXT_SEARCH_MANAGER:IsActiveTextSearch(searchContexts[i]) then
					TEXT_SEARCH_MANAGER:SetSearchText(searchContexts[i], text)
				end
			end
		end
		return false
	end
	local function VotanSearchBoxFocusLost(bagSearch, ...)
		local text = bagSearch:GetText()
		updateBackground(bagSearch, text)
	end

	local orgSetText = bagSearch.SetText
	local cursorPosition
	function bagSearch.SetText(...)
		if wm:GetFocusControl() ~= bagSearch then
			updateBackground(...)
			return orgSetText(...)
		end
	end

	local function VotanSearchBoxCloseClick(control, ...)
		bagSearch:SetText("")
		PlaySound(SOUNDS.DEFAULT_CLICK)
	end

	closeButton:ClearAnchors()
	closeButton:SetAnchor(TOPLEFT, bagSearch, TOPRIGHT, 0, 4)
	closeButton:SetHidden(true)
	closeButton:SetHandler("OnMouseDown", VotanSearchBoxCloseClick)
	closeButton:SetDimensions(16, 16)
	closeButton:SetInheritAlpha(false)

	bagSearchBg.VSBSetHidden = bagSearchBg.SetHidden
	bagSearchBg:SetHidden(g_savedVars.hideSearchBox)
	bagSearchBg.SetHidden = VotanSearchBoxSetHidden
	bagSearchBg:SetEdgeTexture("EsoUI/Art/Tooltips/UI-SliderBackdrop.dds", 32, 4)
	bagSearchBg:SetInsets(1, 1, 1, 1)
	bagSearch:ClearAnchors()
	bagSearch:SetAnchor(TOPLEFT, nil, TOPLEFT, 4, 4)
	bagSearch:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -20, -4)
	bagSearch:SetInheritAlpha(false)
	bagSearch:SetEditEnabled(true)
	setDefaultText(bagSearch, glass)
	if bagSearchTx then
		bagSearchTx:ClearAnchors()
		bagSearchTx:SetAnchorFill()
	end
	VotanSearchBoxFocusLost(bagSearch)

	ZO_PreHookHandler(bagSearch, "OnMouseDown", VotanSearchBoxMouseDown)
	ZO_PreHookHandler(bagSearch, "OnFocusGained", VotanSearchBoxFocusGained)
	ZO_PreHookHandler(bagSearch, "OnFocusLost", VotanSearchBoxFocusLost)

	bagSearch:SetHandler("OnEffectivelyShown", VotanSearchBoxFocusLost, name)

	searchBoxes[#searchBoxes + 1] = bagSearch
end

local function AnchorSearchBox(bagSearchBg)
	bagSearchBg:ClearAnchors()
	bagSearchBg:SetAnchor(BOTTOMLEFT, nil, TOPLEFT, -12, -5)
end

local function SetupInventoryControl(inventoryType, ...)
	local inventory = PLAYER_INVENTORY.inventories[inventoryType]
	local bagSearch = inventory.searchBox:GetParent()
	SetupSearchBox(bagSearch, ...)
	local subTabs = inventory.subFilterBar
	local parent = subTabs:GetParent()
	if bagSearch:GetParent() == parent then
		local w1, h1, w2, h2 = parent:GetDimensionConstraints()
		h1 = math.max(32, h1)
		parent:SetDimensionConstraints(w1, h1, w2, h2)
		parent:SetResizeToFitDescendents(true)

		bagSearch:SetParent(parent:GetParent())
		AnchorSearchBox(bagSearch)
		subTabs:ClearAnchors()
		subTabs:SetAnchor(RIGHT, nil, RIGHT, -12, 0)
	end
end

---- Crafting Filter ----

local function SetupCraftingControl(parent, inventory, ...)
	local bagSearch = wm:CreateControlFromVirtual("$(parent)VotanSearch", parent, templateName)
	local cachedSearchTerm = ""
	local function OnTextChanged(self)
		ZO_EditDefaultText_OnTextChanged(self)
		cachedSearchTerm = self:GetText():lower()
		inventory.dirty = true
		if not parent:IsControlHidden() then
			inventory:HandleVisibleDirtyEvent()
		end
	end
	bagSearch:GetNamedChild("Box"):SetHandler("OnTextChanged", OnTextChanged)

	SetupSearchBox(bagSearch, ...)
	AnchorSearchBox(bagSearch)

	assert(inventory.AddItemData, "Addon out-dated.")
	local stringSearch = ZO_StringSearch:New(true)
	stringSearch:AddProcessor(SEARCH_TYPE_INVENTORY, ProcessInventoryItem)
	local function filterFunction(self, bagId, slotIndex, totalStack, scrollDataType, data, customDataGetFunction, slotData)
		local oldType = slotData.type
		slotData.type = SEARCH_TYPE_INVENTORY
		local result = not stringSearch:IsMatch(cachedSearchTerm, slotData)
		slotData.type = oldType
		return result
	end

	ZO_PreHook(inventory, "AddItemData", filterFunction)
end

---- Store and QuickSlot Window ----

local function HookShouldAddItemToListSearchBox(bagSearch, parent, inventory, ...)
	SetupSearchBox(bagSearch, ...)
	AnchorSearchBox(bagSearch)
end

local function HookShouldAddItemToList(parent, inventory, ...)
	local bagSearch = wm:CreateControlFromVirtual("$(parent)VotanSearch", parent, templateName)
	local cachedSearchTerm = ""
	local function OnTextChanged(self)
		ZO_EditDefaultText_OnTextChanged(self)
		cachedSearchTerm = self:GetText():lower()
		if not parent:IsControlHidden() then
			return inventory:UpdateList()
		end
	end
	bagSearch:GetNamedChild("Box"):SetHandler("OnTextChanged", OnTextChanged)

	SetupSearchBox(bagSearch, ...)
	AnchorSearchBox(bagSearch)

	local function filterFunction(self, slotData)
		return #cachedSearchTerm == 0 or LTF:Filter(GetLowercase(slotData.name), cachedSearchTerm)
	end
	local orgShouldAddItemToList = inventory.ShouldAddItemToList
	inventory.ShouldAddItemToList = function(...)
		if filterFunction(...) then
			return orgShouldAddItemToList(...)
		end
	end
end

local function AddQuickSlotFilter(searchBox)
	local cachedSearchTerm = ""
	local function filterQuestItem(questItemData)
		return #cachedSearchTerm == 0 or LTF:Filter(GetLowercase(questItemData.name), cachedSearchTerm)
	end
	local baseClass = GetAPIVersion() < 101034 and ZO_QuickslotManager or ZO_Quickslot_Keyboard
	local orgShouldAddQuestItemToList = baseClass.ShouldAddQuestItemToList
	function baseClass:ShouldAddQuestItemToList(questItemData)
		return orgShouldAddQuestItemToList(self, questItemData) and filterQuestItem(questItemData)
	end
	local orgAppendQuestItemData = baseClass.AppendQuestItemData
	function baseClass.AppendQuestItemData(...)
		cachedSearchTerm = searchBox:GetText():lower()
		return orgAppendQuestItemData(...)
	end
end

local function HookPostedItems()
	local parent = ZO_TradingHousePostedItemsList
	local bagSearch = wm:CreateControlFromVirtual("$(parent)VotanSearch", parent, templateName)
	local cachedSearchTerm = ""
	local function OnTextChanged(self)
		ZO_EditDefaultText_OnTextChanged(self)
		cachedSearchTerm = self:GetText():lower()
		local trading = TRADING_HOUSE
		if trading:GetCurrentMode() == ZO_TRADING_HOUSE_MODE_LISTINGS then
			trading:RefreshListings()
		end
	end
	bagSearch:GetNamedChild("Box"):SetHandler("OnTextChanged", OnTextChanged)

	SetupSearchBox(bagSearch)
	bagSearch:ClearAnchors()
	bagSearch:SetAnchor(TOPLEFT, PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].searchBox:GetParent())

	local org = ZO_TradingHouse_CreateListingItemData
	function ZO_TradingHouse_CreateListingItemData(...)
		local data = org(...)
		if data and cachedSearchTerm ~= "" and not LTF:Filter(GetLowercase(data.name), cachedSearchTerm) then
			return
		end
		return data
	end
end

local function SetupQuickSlot()
	local quickSlot = GetAPIVersion() < 101034 and QUICKSLOT_WINDOW or QUICKSLOT_KEYBOARD
	local baseClass = GetAPIVersion() < 101034 and ZO_QuickSlot or ZO_QuickSlot_Keyboard
	if not quickSlot then
		return
	end
	local searchBox = quickSlot.searchBox
	local bagSearch = searchBox:GetParent()
	local parent = bagSearch:GetParent()
	parent:SetResizeToFitDescendents(false)
	bagSearch:SetParent(parent:GetParent())
	HookShouldAddItemToListSearchBox(bagSearch, baseClass, quickSlot)
	AddQuickSlotFilter(searchBox)
end

---- Keep search text sticky ----
local function HookEndSearch()
	local orgZO_PlayerInventory_EndSearch = ZO_PlayerInventory_EndSearch
	local function NoOp()
	end
	function ZO_PlayerInventory_EndSearch(...)
		if not g_savedVars.keepSticky then
			return orgZO_PlayerInventory_EndSearch(...)
		end
		local editBox = ...
		local orgSetText = editBox.SetText
		editBox.SetText = NoOp
		orgZO_PlayerInventory_EndSearch(editBox)
		editBox.SetText = orgSetText
	end
end

---- Init ----

local function SetupControls()
	EVENT_MANAGER:UnregisterForEvent(name, EVENT_PLAYER_ACTIVATED)
	SetupInventoryControl(INVENTORY_BACKPACK, "CraftBagExtendedBankMenu", "CraftBagExtendedGuildBankMenu", "CraftBagExtendedVendorMenu", "ZO_StoreWindowMenuBar_Auto Recharge_VENDOR_REPAIRKITS", "ZO_StoreWindowMenuBar_Auto Recharge_VENDOR_REPAIRKITS_LABEL")
	SetupInventoryControl(INVENTORY_BANK)
	SetupInventoryControl(INVENTORY_GUILD_BANK)
	SetupInventoryControl(INVENTORY_CRAFT_BAG, "CraftBagExtendedBankMenu", "CraftBagExtendedGuildBankMenu", "CraftBagExtendedVendorMenu", "ZO_StoreWindowMenuBar_Auto Recharge_VENDOR_REPAIRKITS", "ZO_StoreWindowMenuBar_Auto Recharge_VENDOR_REPAIRKITS_LABEL")
	SetupInventoryControl(INVENTORY_HOUSE_BANK)

	SetupCraftingControl(ZO_SmithingTopLevelDeconstructionPanelInventory, SMITHING.deconstructionPanel.inventory)
	SetupCraftingControl(ZO_SmithingTopLevelImprovementPanelInventory, SMITHING.improvementPanel.inventory)
	SetupCraftingControl(ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventory, ZO_RETRAIT_KEYBOARD.inventory)
	SetupCraftingControl(UNIVERSAL_DECONSTRUCTION.deconstructionPanelControl, UNIVERSAL_DECONSTRUCTION.deconstructionPanel.inventory)

	HookShouldAddItemToList(ZO_StoreWindow, STORE_WINDOW)
	SetupQuickSlot()
	EnhanceTextSearch()
	HookPostedItems()
	HookEndSearch()

	local function setConstraintWidth(control, width)
		if not control then
			return
		end
		local constraints = {control:GetDimensionConstraints()}
		if constraints[3] > width or constraints[3] <= 0 then
			constraints[3] = width
			control:SetDimensionConstraints(unpack(constraints))
		end
	end
	if AwesomeGuildStore then
		if AwesomeGuildStore.class and AwesomeGuildStore.class.TradingHouseWrapper and AwesomeGuildStore.class.TradingHouseWrapper.InitializeGuildSelector then
			local orgInitialize = AwesomeGuildStore.class.TradingHouseWrapper.InitializeGuildSelector
			function AwesomeGuildStore.class.TradingHouseWrapper.InitializeGuildSelector(...)
				orgInitialize(...)
				setConstraintWidth(ZO_TradingHouseTitleLabel, 324)
				setConstraintWidth(AwesomeGuildStoreGuildSelectorComboBoxSelectedItemText, 324)
			end
		else
			d("Invalid AwesomeGuildStore definition. Maybe out of date?")
		end
	else
		setConstraintWidth(ZO_TradingHouseTitleLabel, 324)
	end
end

----- Settings -----
local function UpdateHidden()
	for _, searchBox in pairs(searchBoxes) do
		searchBox:SetHidden(g_savedVars.hideSearchBox)
	end
end

local function ResetSearchboxes()
	for _, searchBox in pairs(searchBoxes) do
		if searchBox:GetText() ~= "" then
			searchBox:SetText("")
		end
	end
end

local function InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings
	if not LibHarvensAddonSettings then
		return
	end

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Search Box")
	if not settings then
		return
	end
	settings.version = "1.9.0"
	settings.website = "http://www.esoui.com/downloads/info914-VotansSearchBox.html"

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTAN_SEARCHBOX_SHOW),
		tooltip = GetString(SI_VOTAN_SEARCHBOX_SHOW_TOOLTIP),
		getFunction = function()
			return not g_savedVars.hideSearchBox
		end,
		setFunction = function(value)
			g_savedVars.hideSearchBox = not value
			UpdateHidden()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTAN_SEARCHBOX_STICKY),
		tooltip = GetString(SI_VOTAN_SEARCHBOX_STICKY_TOOLTIP),
		getFunction = function()
			return g_savedVars.keepSticky
		end,
		setFunction = function(value)
			g_savedVars.keepSticky = value
			if not g_savedVars.keepSticky then
				ResetSearchboxes()
			end
			settings:UpdateControls()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = " |u12:0::|u" .. GetString(SI_VOTAN_SEARCHBOX_ALL_SAME_TEXT),
		tooltip = GetString(SI_VOTAN_SEARCHBOX_ALL_SAME_TEXT_TOOLTIP),
		getFunction = function()
			return g_savedVars.allSameText
		end,
		setFunction = function(value)
			g_savedVars.allSameText = value
			if value then
				ResetSearchboxes()
			end
		end,
		disable = function()
			return not g_savedVars.keepSticky
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTAN_SEARCHBOX_SEARCH_SETNAME),
		tooltip = GetString(SI_VOTAN_SEARCHBOX_SEARCH_SETNAME_TOOLTIP),
		getFunction = function()
			return g_savedVars.searchSetName
		end,
		setFunction = function(value)
			g_savedVars.searchSetName = value
			ResetSearchboxes()
			settings:UpdateControls()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTAN_SEARCHBOX_SEARCH_MASTERWRIT),
		tooltip = GetString(SI_VOTAN_SEARCHBOX_SEARCH_MASTERWRIT_TOOLTIP),
		getFunction = function()
			return g_savedVars.searchMasterWrit
		end,
		setFunction = function(value)
			g_savedVars.searchMasterWrit = value
			ResetSearchboxes()
			settings:UpdateControls()
		end
	}
end

local function FixSearchProcess()
	local orgZO_StringSearch = ZO_StringSearch.Process

	local logger = LibDebugLogger and LibDebugLogger(name)
	ZO_StringSearch.Process = function(self, data, ...)
		if not data.type or not self.processors[data.type] then
			if logger then
				if not data.type then
					logger:Warn("Unexpected data. type: nil")
				else
					logger:Warn("Unexpected data. processors: nil")
				end
			end
			return true
		end

		return orgZO_StringSearch(self, data, ...)
	end
end

local function Initialize(eventType, addonName)
	if addonName ~= name then
		return
	end

	local defaults = {hideSearchBox = false, keepSticky = false, allSameText = false, searchSetName = true, searchMasterWrit = true}
	g_savedVars = ZO_SavedVars:NewAccountWide("VotanSearchBox_SavedVariables", 1, nil, defaults)

	InitSettings()
	FixSearchProcess()
	SetupControls()
end

EVENT_MANAGER:RegisterForEvent(name, EVENT_ADD_ON_LOADED, Initialize)
