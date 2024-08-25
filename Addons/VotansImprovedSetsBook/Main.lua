local addon = {
	name = "VotansImprovedSetsBook"
}
local em = GetEventManager()
local wm = WINDOW_MANAGER

local favCategory
local distinct = {}

local getPieceSlotId
do
	-- Each normal item of a set will generate the same "pieceSlotId" as the corresponding set collection piece.
	-- The ids are not continuous, but unique.
	-- The id is non-zero. Items generating a zero are not a set piece.
	local equipSlotToPieceSlot = {
		[0] = 0,
		[3] = 1 * 16,
		[2] = 2 * 16,
		[16] = 3 * 16,
		[6] = 4 * 16,
		[8] = 5 * 16,
		[9] = 6 * 16,
		[1] = 7 * 16,
		[11] = 8 * 16,
		[4] = 9 * 16,
		[5] = 10 * 16
	}
	local weaponTypeToPieceSlot = {
		[0] = 0,
		[11] = 1,
		[1] = 2,
		[2] = 3,
		[3] = 4,
		[5] = 5,
		[6] = 6,
		[4] = 7,
		[8] = 8,
		[9] = 9,
		[12] = 10,
		[13] = 11,
		[15] = 12,
		[14] = 13
	}
	--itemLink = "|H1:item:77377:362:50:0:0:0:0:0:0:0:0:0:0:0:0:12:0:0:0:300:0|h|h"
	--itemLink = "|H1:item:77372:362:50:0:0:0:0:0:0:0:0:0:0:0:0:12:0:0:0:300:0|h|h"
	getPieceSlotId = function(itemLink)
		local equipSlot = GetComparisonEquipSlotsFromItemLink(itemLink)
		return (equipSlotToPieceSlot[equipSlot] or 0) + GetItemLinkArmorType(itemLink) + (weaponTypeToPieceSlot[GetItemLinkWeaponType(itemLink)] or 0)
	end
end

function addon:ApplyFavorites()
	-- The order depends on work load/number of active addon
	if not favCategory or not self.settings then
		return
	end

	local favorites, collections = self.settings.favorites, favCategory.collections
	local manager, book = ITEM_SET_COLLECTIONS_DATA_MANAGER, ITEM_SET_COLLECTIONS_BOOK_KEYBOARD
	for i = 1, #favorites do
		local collectionData = manager:GetItemSetCollectionData(favorites[i])
		if not distinct[collectionData:GetId()] then
			collections[#collections + 1] = collectionData
			distinct[collectionData:GetId()] = collectionData
		end
	end
	for _, itemSetCollectionData in ITEM_SET_COLLECTIONS_DATA_MANAGER:ItemSetCollectionIterator() do
		book.collapsedSetIds[itemSetCollectionData:GetId()] = true
	end
	favCategory:SortCollections()
end

local orgSortTopLevelCategories = ITEM_SET_COLLECTIONS_DATA_MANAGER.SortTopLevelCategories
local function createFavoriteCategory(self)
	local categoryId = -186789 -- unique
	favCategory = self.itemSetCollectionCategories[categoryId]
	if favCategory then
		return
	end
	favCategory = ZO_ItemSetCollectionCategoryData:New(categoryId)
	function favCategory:GetKeyboardIcons()
		return "esoui/art/market/keyboard/giftmessageicon_up.dds", "esoui/art/market/keyboard/giftmessageicon_down.dds", "esoui/art/market/keyboard/giftmessageicon_over.dds"
	end
	function favCategory:GetName()
		return GetString(SI_VOTANS_IMPROVED_SETS_BOOK_FAVORITES)
	end
	function favCategory:GetOrder()
		return -1000
	end
	local function compareTo(a, b)
		return a:GetRawName() < b:GetRawName()
	end
	function favCategory:SortCollections()
		table.sort(self.collections, compareTo)
	end
	self.itemSetCollectionCategories[categoryId] = favCategory
	table.insert(self.topLevelCategories, 1, favCategory)
	addon:ApplyFavorites()
end
function ITEM_SET_COLLECTIONS_DATA_MANAGER.SortTopLevelCategories(...)
	createFavoriteCategory(...)
	return orgSortTopLevelCategories(...)
end
ITEM_SET_COLLECTIONS_DATA_MANAGER.isDataDirty = true

local function updateSettings(collections)
	local favorites = addon.settings.favorites
	ZO_ClearTable(favorites)
	for i = #collections, 1, -1 do
		favorites[#favorites + 1] = collections[i]:GetId()
	end
end

local function createFilterTypes(collectionData)
	local filterTypes, shift = {}, {}
	for equipType = 1, 11 do
		filterTypes[equipType] = 0
		shift[equipType] = 1
	end
	for _, piece in collectionData:PieceIterator() do
		local equipType = piece:GetEquipmentFilterType()
		local bit = shift[equipType]
		if piece:IsUnlocked() then
			filterTypes[equipType] = filterTypes[equipType] + bit
		end
		shift[equipType] = BitLShift(bit, 1)
	end
	return filterTypes
end

function addon:AddToFavorites(itemSetId)
	if distinct[itemSetId] then
		return
	end
	local collectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(itemSetId)
	distinct[itemSetId] = collectionData
	table.insert(favCategory.collections, collectionData)
	favCategory:SortCollections()
	updateSettings(favCategory.collections)
end

function addon:RemoveFromFavorites(itemSetId)
	local collections = favCategory.collections
	for i = #collections, 1, -1 do
		if collections[i]:GetId() == itemSetId then
			table.remove(collections, i)
			break
		end
	end
	distinct[itemSetId] = nil
	updateSettings(collections)
end

local function addMenu(self, control)
	local headerData = control.dataEntry.data.header
	local itemSetId = headerData:GetId()
	local isRemove = distinct[itemSetId]
	AddCustomMenuItem(
		isRemove and GetString(SI_VOTANS_IMPROVED_SETS_BOOK_FAVORITE_REMOVE) or GetString(SI_VOTANS_IMPROVED_SETS_BOOK_FAVORITE_ADD),
		function()
			if isRemove then
				addon:RemoveFromFavorites(itemSetId)
			else
				addon:AddToFavorites(itemSetId)
			end
			self:RefreshCategoryContent()
		end
	)
	AddCustomMenuItem(
		GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
		function()
			addon:InsertLink(itemSetId)
		end
	)
	AddCustomMenuItem(
		GetString(SI_VOTANS_IMPROVED_SETS_BOOK_FAVORITE_POPUP),
		function()
			local collectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(itemSetId)
			local filterTypes = createFilterTypes(collectionData)
			addon:ShowLink(itemSetId, filterTypes, true)
		end
	)
end

local orgOnContentHeaderMouseUp = ZO_ItemSetsBook_Keyboard.OnContentHeaderMouseUp
function ZO_ItemSetsBook_Keyboard.OnContentHeaderMouseUp(...)
	local self, control, button, upInside = ...
	if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
		local orgShowMenu = ShowMenu
		function ShowMenu(...)
			ShowMenu = orgShowMenu
			addMenu(self, control)
			return ShowMenu(...)
		end
	end
	return orgOnContentHeaderMouseUp(...)
end

local orgIsViewingCategory = ZO_ItemSetsBook_Keyboard.IsViewingCategory
function ZO_ItemSetsBook_Keyboard.IsViewingCategory(...)
	local self, itemSetCollectionCategoryData = ...
	if favCategory and self:GetSelectedCategory() and self:GetSelectedCategory():GetId() == favCategory:GetId() then
		local originalCategoryId = itemSetCollectionCategoryData:GetId()
		local collections = favCategory.collections
		for i = 1, #collections do
			if collections[i]:GetCategoryData():GetId() == originalCategoryId then
				return true
			end
		end
		return false
	end
	return orgIsViewingCategory(...)
end

local gridListPanelList = ITEM_SET_COLLECTIONS_BOOK_KEYBOARD.gridListPanelList
do
	local orgSetup = gridListPanelList.list.dataTypes[1].setupCallback
	assert(orgSetup)
	gridListPanelList.list.dataTypes[1].setupCallback = function(...)
		local control, item = ...
		local border = control:GetNamedChild("OverlayBorder")
		border:SetDrawLayer(DL_BACKGROUND)
		border:SetDrawTier(0)
		border:SetDrawLevel(2)

		local pieceData = item.dataSource
		if pieceData and pieceData:IsUnlocked() then
			border:SetCenterColor(0.8, 0.9, 1, 0.125)
		else
			border:SetCenterColor(0, 0, 0, 0)
		end
		return orgSetup(...)
	end
end
do
	local TEXTURE_FAVORITE = "esoui/art/ava/ava_rankicon_general.dds"
	local FAV_COLOR = ZO_ColorDef:New("FFE900")
	local function onMouseClick(statusIcon, button, upInside)
		if not upInside then
			return
		end
		local control = statusIcon:GetParent()
		control.dataEntry.data.header.dataSource:ClearNew()
	end
	local function createFavorite(parent)
		local control = wm:CreateControl("$(parent)Favorite", parent, CT_TEXTURE)
		control:SetTexture(TEXTURE_FAVORITE)
		control:SetAnchor(TOPRIGHT, nil, TOPRIGHT, -2, 2)
		control:SetDimensions(32, 32)
		control:SetHandler("OnMouseUp", onMouseClick)
		control:SetDrawLayer(DL_CONTROLS)
		control:SetDrawLevel(2)
		parent.favoriteMarker = control
		return control
	end
	local orgSetup = gridListPanelList.list.dataTypes[2].setupCallback
	assert(orgSetup)
	local function setupFavorite(control, item)
		local pieceData = item.data.dataSource

		local collectionData = pieceData:GetItemSetCollectionData()

		local itemSetId = collectionData:GetId()
		local hasNew = collectionData:HasAnyNewPieces()
		local isFav = distinct[itemSetId] ~= nil
		local isHidden = not (isFav or hasNew)
		local fav = control.favoriteMarker or (hasNew or isFav) and createFavorite(control)
		if fav then
			fav:SetHidden(isHidden)
			if not isHidden then
				fav:SetMouseEnabled(hasNew)
				local color = isFav and FAV_COLOR or ZO_WHITE
				fav:SetColor(color:UnpackRGB())
				fav:SetTexture(hasNew and ZO_KEYBOARD_NEW_ICON or TEXTURE_FAVORITE)
			end
		end
	end
	gridListPanelList.list.dataTypes[2].setupCallback = function(...)
		setupFavorite(...)
		return orgSetup(...)
	end

	local pool = gridListPanelList.list.dataTypes[2].pool
	ITEM_SET_COLLECTIONS_DATA_MANAGER:RegisterCallback(
		"CategoryNewStatusCleared",
		function()
			for _, control in pairs(pool:GetActiveObjects()) do
				if control.dataEntry then
					setupFavorite(control, control.dataEntry.data)
				end
			end
		end
	)
end

do
	local categoryTree = ITEM_SET_COLLECTIONS_BOOK_KEYBOARD.categoryTree
	assert(categoryTree)
	assert(categoryTree.templateInfo)
	local function hookCustomSetup(template, setup)
		local objectPool = categoryTree.templateInfo[template].objectPool
		if objectPool.customAcquireBehavior then
			local orgSetup = objectPool.customAcquireBehavior
			objectPool:SetCustomAcquireBehavior(
				function(...)
					setup(...)
					return orgSetup(...)
				end
			)
		else
			objectPool:SetCustomAcquireBehavior(setup)
		end
	end
	local function onMouseClick(statusIcon, button, upInside)
		if not upInside then
			return
		end
		local header = statusIcon:GetParent()
		header.node.data.dataSource:ClearNew()
	end
	local function setupStatusIcon(control)
		local statusIcon = control.statusIcon or control:GetNamedChild("StatusIcon")
		statusIcon:SetMouseEnabled(true)
		statusIcon:SetHandler("OnMouseUp", onMouseClick)
	end
	hookCustomSetup("ZO_StatusIconHeader", setupStatusIcon)
	hookCustomSetup("ZO_TreeStatusLabelSubCategory", setupStatusIcon)
end

function addon:AddUndauntedInfo()
	local categories = {
		[5] = true,
		[6] = true,
		[7] = true,
		[8] = true
	}
	SecurePostHook(
		ZO_ItemSetsBook_Keyboard,
		"RefreshCategoryProgress",
		function(self)
			local itemSetCollectionCategoryData = self:GetSelectedCategory()
			if itemSetCollectionCategoryData and not itemSetCollectionCategoryData:IsInstanceOf(ZO_ItemSetCollectionSummaryCategoryData) then
				if self:IsReconstructing() then
					return
				end
				local datasource = itemSetCollectionCategoryData:GetDataSource()
				--SLASH_COMMANDS["/zgoo"]({itemSetCollectionCategoryData, datasource})
				local numUnlockedPieces, numPieces = datasource:GetNumUnlockedAndTotalPieces()
				if numUnlockedPieces ~= numPieces then
					local normal, vet, vendor = 0, 0, 0
					local parent = datasource:GetParentCategoryData()
					if parent and categories[parent:GetId()] then
						for _, collectionData in datasource:CollectionIterator() do
							for _, pieceData in collectionData:PieceIterator() do
								if not pieceData:IsUnlocked() then
									local quality = pieceData:GetDisplayQuality()
									if quality == 4 then
										if collectionData:GetNumPieces() == 6 and GetItemLinkEquipType(pieceData:GetItemLink()) == EQUIP_TYPE_SHOULDERS then
											vendor = vendor + 1
										else
											vet = vet + 1
										end
									else
										if quality == 3 then
											normal = normal + 1
										end
									end
								end
							end
						end
					end
					if normal > 0 or vet > 0 or vendor > 0 then
						local text = {}
						if normal > 0 then
							text[#text + 1] = normal .. "|t23:23:/esoui/art/lfg/gamepad/lfg_menuicon_normaldungeon.dds|t"
						end
						if vet > 0 then
							text[#text + 1] = vet .. "|t31:31:/esoui/art/lfg/gamepad/lfg_menuicon_veteranldungeon.dds|t"
						end
						if vendor > 0 then
							text[#text + 1] = vendor .. "|t23:23:/esoui/art/icons/servicemappins/servicepin_undaunted.dds|t"
						end
						self.categoryProgressLabel:SetText(string.format("%s (%s)", self.categoryProgressLabel:GetText(), table.concat(text, " \226\128\162 ")))
					else
						self.categoryProgressLabel:SetText(string.format("%s (%i)", self.categoryProgressLabel:GetText(), numPieces - numUnlockedPieces))
					end
				end
			end
		end
	)
end
---- Keybind Strip ----

local function initLocations(zoneIdToLocation)
	local categoryData, location

	-- Beginners areas
	categoryData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionCategoryData(26)
	assert(categoryData)
	location = categoryData:GetFormattedName()
	zoneIdToLocation[281] = location
	zoneIdToLocation[534] = location
	zoneIdToLocation[537] = location

	-- Battlegrounds
	categoryData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionCategoryData(85)
	assert(categoryData)
	location = categoryData:GetFormattedName()
	-- ToDo: zone ids

	-- Apocrypha
	categoryData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionCategoryData(107)
	assert(categoryData)
	location = categoryData:GetFormattedName()
	zoneIdToLocation[1413] = location
	zoneIdToLocation[1414] = location
end

function addon:InitializeKeybindStripDescriptors()
	local categoryTree = ITEM_SET_COLLECTIONS_BOOK_KEYBOARD.categoryTree
	local zoneIdToLocation = {}
	local function getLocation(zoneId, format)
		local location = zo_strformat(format, GetZoneNameById(zoneId):gsub("\194\160", " "))
		-- Remove roman numbers at the end
		for i = 2, 1, -1 do
			location = location:gsub(ZO_CachedStrFormat(" <<R:1>>$", i), "")
		end
		return location
	end
	local function selectNode(location)
		for _, categoryData in pairs(ITEM_SET_COLLECTIONS_DATA_MANAGER.itemSetCollectionCategories) do
			if categoryData:GetFormattedName() == location then
				local node = categoryTree:GetTreeNodeByData(categoryData)
				if not node then
					return false
				end
				categoryTree:SelectNode(node)
				return categoryTree:GetSelectedNode() == node
			end
		end
		return false
	end
	local function tryLocation(zoneId, format)
		local location = getLocation(zoneId, format)
		if selectNode(location) then
			zoneIdToLocation[zoneId] = location
			return true
		end
	end
	local function selectCategory(zoneId)
		local location = zoneIdToLocation[zoneId]
		if location then
			return selectNode(location)
		end

		return tryLocation(zoneId, SI_SKILLS_TREE_NAME_FORMAT) or tryLocation(zoneId, SI_WORLD_MAP_LOCATION_NAME)
	end
	self.keybindStripDescriptor = {
		alignment = KEYBIND_STRIP_ALIGN_RIGHT,
		{
			name = GetString(SI_VOTANS_IMPROVED_SETS_BOOK_LOCATION),
			keybind = "VOTANS_SETSBOOK_CURRENT_LOCATION",
			callback = function()
				local zoneId = GetZoneId(GetUnitZoneIndex("player"))
				local found = selectCategory(zoneId)
				if not found then
					found = selectCategory(GetParentZoneId(zoneId))
				end
				PlaySound(found and SOUNDS.DEFAULT_CLICK or SOUNDS.NEGATIVE_CLICK)
			end,
			visible = function(keybindButtonDescriptor)
				return GetHighestPriorityActionBindingInfoFromName(keybindButtonDescriptor.keybind) ~= KEY_INVALID
			end
		}
	}
	local function stateChange(oldState, newState)
		if newState == SCENE_SHOWING then
			if not next(zoneIdToLocation) then
				initLocations(zoneIdToLocation)
			end
		elseif newState == SCENE_SHOWN then
			PushActionLayerByName(GetString(SI_VOTANS_SETSBOOK_LAYER))
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
		elseif newState == SCENE_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
			RemoveActionLayerByName(GetString(SI_VOTANS_SETSBOOK_LAYER))
		end
	end
	ITEM_SET_COLLECTIONS_BOOK_KEYBOARD:GetScene():RegisterCallback("StateChange", stateChange)
end

---- Custom Chat Link ----

SETSBOOK_LINK_TYPE = "setsbook"

local function reformatLink(linkStyle, linkType, data)
	local itemSetId = tonumber(data:match("(.-):"))
	local collectionData = itemSetId and ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(itemSetId)
	return collectionData and string.format("|H1:%s:%s|h[%s]|h", SETSBOOK_LINK_TYPE, data, collectionData:GetFormattedName())
end
LibChatMessage:RegisterCustomChatLink(SETSBOOK_LINK_TYPE, reformatLink)

function addon:OnLinkClicked(link, button, text, color, linkType, itemSetId, ...)
	if linkType ~= SETSBOOK_LINK_TYPE then
		return
	end
	itemSetId = tonumber(itemSetId)
	if button == MOUSE_BUTTON_INDEX_LEFT then
		local filterTypes = {...}
		assert(itemSetId and #filterTypes == 11, "invalid link format")
		self:ShowLink(itemSetId, filterTypes)
	elseif button == MOUSE_BUTTON_INDEX_MIDDLE then
		assert(itemSetId, "invalid link format")
		local collectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(itemSetId)
		local filterTypes = createFilterTypes(collectionData)
		self:ShowLink(itemSetId, filterTypes, true)
	end
	return true
end

local ICON_SIZE = 24
local bagTexture = zo_iconTextFormat("esoui/art/mainmenu/menubar_inventory_up.dds", ICON_SIZE, ICON_SIZE, "")

function addon:ShowLink(itemSetId, filterTypes, own)
	for equipType = 1, 11 do
		filterTypes[equipType] = tonumber(filterTypes[equipType])
	end
	local collectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(itemSetId)
	local hasItemInBag = {}
	local BAG_BACKPACK = BAG_BACKPACK
	local currentSetId = 0
	for _, piece in collectionData:PieceIterator() do
		currentSetId = select(6, GetItemLinkSetInfo(piece:GetItemLink()))
		break
	end
	local backpackSlots = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)
	for _, slotData in pairs(backpackSlots) do
		if own or not IsItemBound(BAG_BACKPACK, slotIndex) then
			local itemLink = GetItemLink(slotData.bagId, slotData.slotIndex)
			local hasSet, _, _, _, _, setId = GetItemLinkSetInfo(itemLink)
			if hasSet and setId == currentSetId then
				-- df("+%s=%i", itemLink, getPieceSlotId(itemLink))
				hasItemInBag[getPieceSlotId(itemLink)] = true
			end
		end
	end

	local list = {}
	local LOCKED_COLOR, ZO_CachedStrFormat, SI_ITEM_SET_NAME_FORMATTER = LOCKED_COLOR, ZO_CachedStrFormat, GetString(SI_ITEM_SET_NAME_FORMATTER)
	for _, piece in collectionData:PieceIterator() do
		local name = zo_iconTextFormat(piece:GetIcon(), ICON_SIZE, ICON_SIZE, ZO_CachedStrFormat(SI_ITEM_SET_NAME_FORMATTER, piece:GetRawName()))

		local itemLink = piece:GetItemLink()
		--df("*%s=%i", itemLink, getPieceSlotId(itemLink))
		if hasItemInBag[getPieceSlotId(itemLink)] then
			name = name .. bagTexture
		end
		local equipType = piece:GetEquipmentFilterType()
		local bit = filterTypes[equipType]
		if BitAnd(bit, 1) == 1 then
			filterTypes[equipType] = BitRShift(bit - 1, 1)
			list[#list + 1] = name
		else
			filterTypes[equipType] = BitRShift(bit, 1)
			list[#list + 1] = LOCKED_COLOR:Colorize(name)
		end
	end
	ClearTooltip(PopupTooltip)
	InitializeTooltip(PopupTooltip)
	ZO_ItemIconTooltip_OnAddGameData(PopupTooltip, TOOLTIP_GAME_DATA_ITEM_ICON, "/esoui/art/collections/collections_tabicon_itemsets_up.dds")
	PopupTooltip:AddLine("")
	PopupTooltip:AddLine(collectionData:GetFormattedName(), "ZoFontHeader")
	if own then
		PopupTooltip:AddLine(GetString(SI_TARGETTYPE2), "ZoFontWindowSubtitle")
	end
	PopupTooltip:AddLine(table.concat(list, "\r\n"))
end

function addon:InsertLink(itemSetId)
	local collectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(itemSetId)
	local filterTypes = createFilterTypes(collectionData)
	ZO_LinkHandler_InsertLink(ZO_LinkHandler_CreateLink(collectionData:GetFormattedName(), nil, SETSBOOK_LINK_TYPE, itemSetId, unpack(filterTypes)))
end

function addon:InitLinkHandler()
	LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, self.OnLinkClicked, self)
	LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.OnLinkClicked, self)
end

---- Init ----

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	VotansImprovedSetsBook_Data = VotansImprovedSetsBook_Data or {}
	addon.settings = VotansImprovedSetsBook_Data
	addon.settings.favorites = addon.settings.favorites or {}
	addon:InitLinkHandler()
	local function initSetsBook()
		addon:ApplyFavorites()
		addon:InitializeKeybindStripDescriptors()
	end
	if ITEM_SET_COLLECTIONS_BOOK_KEYBOARD.categoryTree then
		initSetsBook()
	else
		SecurePostHook(ITEM_SET_COLLECTIONS_BOOK_KEYBOARD, "InitializeCategories", initSetsBook)
	end
	em:RegisterForEvent(
		addon.name,
		EVENT_PLAYER_ACTIVATED,
		function()
			em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
			addon:AddUndauntedInfo()
		end
	)
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_IMPROVED_SETS_BOOK = addon
