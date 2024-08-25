local addon = VOTANS_IMPROVED_OUTFIT

local INVALID_DYE_ID = INVALID_DYE_ID

local atOutfit
local swatchesByPosition, positionByDyeId, swatchByDyeId
local stylesByPosition, positionByCollectibleId, styleByCollectibleId = {}, {}, {}
function addon:HookDyeSwatchGrid()
	local orgZO_Dyeing_LayoutSwatches = ZO_Dyeing_LayoutSwatches
	function ZO_Dyeing_LayoutSwatches(...)
		swatchesByPosition, positionByDyeId, swatchByDyeId = orgZO_Dyeing_LayoutSwatches(...)
		return swatchesByPosition, positionByDyeId, swatchByDyeId
	end
end

local function GoNextDyePosition(mvX, mvY)
	local self = ZO_DYEING_KEYBOARD
	local currentSheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
	if not self.selectedDyeId then
		return
	end

	local swatch, dyeId
	local mousedOverDyeableSlotData, mousedOverDyeChannel = currentSheet:GetMousedOverDyeableSlotInfo()
	if mousedOverDyeableSlotData then
		dyeId = select(mousedOverDyeChannel, mousedOverDyeableSlotData:GetPendingDyes())
		dyeId = dyeId or INVALID_DYE_ID
	end
	dyeId = dyeId ~= INVALID_DYE_ID and dyeId or self.selectedDyeId

	if not positionByDyeId[dyeId] then
		return
	end

	repeat
		local y, x = unpack(positionByDyeId[dyeId])
		x, y = x + mvX, y + mvY
		if y <= 0 then
			y = #swatchesByPosition
		else
			if y > #swatchesByPosition then
				y = 1
			end
		end
		if x <= 0 then
			y = y + mvX
			if y <= 0 then
				y = #swatchesByPosition
			end
			x = #swatchesByPosition[y]
		end
		if not swatchesByPosition[y][x] then
			y = y + mvX
			if y > #swatchesByPosition then
				y = 1
			end
			x = 1
		end

		swatch = swatchesByPosition[y][x]
		dyeId = swatch.dataSource.dyeId
	until not mousedOverDyeableSlotData or not swatch.locked

	assert(swatch, "no next dye???")

	self:SetSelectedDyeId(dyeId, false, true)
	ZO_Scroll_ScrollControlIntoCentralView(self.pane, swatch.control)

	-- if swatch and mousedOverDyeableSlotData and not swatch.locked then
	-- 	addon:BeginTransaction(addon.UndoBuffer)
	-- 	local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(mousedOverDyeableSlotData)
	-- 	mousedOverDyeableSlotData:SetPendingDyes(zo_replaceInVarArgs(mousedOverDyeChannel, dyeId, mousedOverDyeableSlotData:GetPendingDyes()))
	-- 	slotManipulator:OnPendingDataChanged()
	-- 	if mousedOverDyeableSlotData:GetRestyleMode() ~= RESTYLE_MODE_OUTFIT then
	-- 		ZO_RESTYLE_STATION_KEYBOARD:OnPendingDyesChanged(mousedOverDyeableSlotData)
	-- 	end
	-- 	addon:EndTransaction()
	-- else
	PlaySound(SOUNDS.DYEING_SWATCH_SELECTED)
	-- end
end

local function GoNextStylePosition(mvX, mvY)
	local self = ZO_OUTFIT_STYLES_PANEL_KEYBOARD
	local currentSheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()

	local collectibleId = self.restyleSlotData
	if collectibleId then
		collectibleId = collectibleId:GetPendingCollectibleData() or collectibleId:GetCurrentCollectibleData()
		if collectibleId then
			collectibleId = collectibleId:GetId()
		end
	end

	local outfitStyle = collectibleId and styleByCollectibleId[collectibleId] or stylesByPosition[1][1]
	if not outfitStyle then
		return
	end
	local collectibleId = outfitStyle:GetDataSource():GetId()

	if not positionByCollectibleId[collectibleId] then
		return
	end

	repeat
		local y, x = unpack(positionByCollectibleId[collectibleId])
		x, y = x + mvX, y + mvY
		if y <= 0 then
			y = #stylesByPosition
		else
			if y > #stylesByPosition then
				y = 1
			end
		end
		if x <= 0 then
			y = y + mvX
			if y <= 0 then
				y = #stylesByPosition
			end
			x = #stylesByPosition[y]
		end
		if not stylesByPosition[y][x] then
			y = y + mvX
			if y > #stylesByPosition then
				y = 1
			end
			x = 1
		end

		outfitStyle = stylesByPosition[y][x]
		collectibleId = outfitStyle:GetDataSource():GetId()
	until not outfitStyle.isEmptyCell

	assert(outfitStyle, "no next outfitStyle???")

	self:ScrollToCollectibleData(outfitStyle)
	addon:BeginTransaction(addon.UndoBuffer)
	self:OnRestyleOutfitStyleEntrySelected(outfitStyle.dataEntry, 1)
	addon:EndTransaction()
	ClearCursor()
end
-- SLASH_COMMANDS["/zgoo"](outfitStyle)

function addon:Navigation(keybind)
	if KEYBOARD_DYEING_FRAGMENT:IsShowing() then
		if keybind == "VOTANS_IMPROVED_OUTFIT_NEXT" then
			GoNextDyePosition(1, 0)
		elseif keybind == "VOTANS_IMPROVED_OUTFIT_PREV" then
			GoNextDyePosition(-1, 0)
		elseif keybind == "VOTANS_IMPROVED_OUTFIT_DOWN" then
			GoNextDyePosition(0, 1)
		elseif keybind == "VOTANS_IMPROVED_OUTFIT_UP" then
			GoNextDyePosition(0, -1)
		end
	end
	-- if KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:IsShowing() then
	-- 	if keybind == "VOTANS_IMPROVED_OUTFIT_NEXT" then
	-- 		GoNextStylePosition(1, 0)
	-- 	elseif keybind == "VOTANS_IMPROVED_OUTFIT_PREV" then
	-- 		GoNextStylePosition(-1, 0)
	-- 	elseif keybind == "VOTANS_IMPROVED_OUTFIT_DOWN" then
	-- 		GoNextStylePosition(0, 1)
	-- 	elseif keybind == "VOTANS_IMPROVED_OUTFIT_UP" then
	-- 		GoNextStylePosition(0, -1)
	-- 	end
	-- end
end

function addon:InitNavigationKeybind()
	local function NavigationKeys(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWN then
			if not ZO_RESTYLE_SCENE:IsShowing() then
				return
			end
			PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_IMPROVED_OUTFIT_NAVIGATION))
		elseif newState == SCENE_HIDING then
			RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_IMPROVED_OUTFIT_NAVIGATION))
		end
	end

	KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:RegisterCallback("StateChange", NavigationKeys)
	KEYBOARD_DYEING_FRAGMENT:RegisterCallback("StateChange", NavigationKeys)
end

function addon:HookGridEntryMouseHandler()
	local orgDoubleClick = ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseDoubleClick
	local orgClick = ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseUp
	function ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseUp(...)
		local control, button, upInside = ...
		if not upInside then
			return
		end
		if button == MOUSE_BUTTON_INDEX_RIGHT then
			return orgClick(...)
		elseif button == MOUSE_BUTTON_INDEX_LEFT then
			local IsMenuVisible = IsMenuVisible or IsMenuVisisble
			if IsMenuVisible() then
				ClearCursor()
				return ClearMenu(...)
			end
			return orgDoubleClick(...)
		end
	end
	function ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseDoubleClick()
	end
end

local function HideRowHighlight(rowControl, hidden)
	if not rowControl then
		return
	end
	if not ZO_ScrollList_GetData(rowControl) then
		return
	end

	local highlight = rowControl:GetNamedChild("Highlight")

	if highlight then
		if not highlight.animation then
			highlight.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
		end

		if highlight.animation:IsPlaying() then
			highlight.animation:Stop()
		end
		if hidden then
			highlight.animation:PlayBackward()
			ClearTooltip(SetItemTooltip, rowControl)
		else
			highlight.animation:PlayForward()
		end
	end
end

local baseStyles = {
	"/esoui/art/icons/gear_altmer_",
	"/esoui/art/icons/gear_argonian_",
	"/esoui/art/icons/gear_bosmer_",
	"/esoui/art/icons/gear_breton_",
	"/esoui/art/icons/gear_dunmer_",
	"/esoui/art/icons/gear_khajiit_",
	"/esoui/art/icons/gear_nord_",
	"/esoui/art/icons/gear_orc_",
	"/esoui/art/icons/gear_redguard_"
}
function addon:InitStyleList()
	local filteredCollections = COLLECTIONS_BOOK_SINGLETON
	local baseGetSearchResults = filteredCollections.GetSearchResults
	local function filterSelectedStyle(data, icon)
		if not data then
			return false
		end
		return zo_plainstrfind(data:GetIcon(), icon) or zo_plainstrfind(data:GetIcon():gsub("light_", "_"):gsub("medium_", "_"):gsub("heavy_", "_"), icon)
	end
	local function filterBaseStyle(data)
		if not data then
			return false
		end

		local icon = data:GetIcon()
		local result = false
		for i = 1, #baseStyles do
			if zo_plainstrfind(icon, baseStyles[i]) then
				result = true
				break
			end
		end
		return not result
	end
	local function buildSubCategory(categoryIndex, filter, ...)
		local categoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex)
		local list, collectibles, sublist
		for subCategoryIndex = 1, categoryData:GetNumSubcategories() do
			collectibles = categoryData:GetSubcategoryData(subCategoryIndex)
			for collectibleIndex = 1, collectibles:GetNumCollectibles() do
				if filter(collectibles:GetCollectibleDataByIndex(collectibleIndex), ...) then
					list = list or {}
					sublist = list[subCategoryIndex] or {}
					list[subCategoryIndex] = sublist
					sublist[collectibleIndex] = true
				end
			end
		end
		return list
	end
	function filteredCollections:GetSearchResults()
		if not atOutfit then
			return baseGetSearchResults(self)
		end

		local result = baseGetSearchResults(self)
		if result then
			return result
		end

		if addon.selectedStyle and #addon.selectedStyle > 0 then
			local icon = addon.selectedStyle
			result = {}
			result[addon.categoryIndexArmor] = buildSubCategory(addon.categoryIndexArmor, filterSelectedStyle, icon)
			result[addon.categoryIndexWeapon] = buildSubCategory(addon.categoryIndexWeapon, filterSelectedStyle, icon)
		elseif addon.settings.filterBaseStyles then
			result = {}
			result[addon.categoryIndexArmor] = buildSubCategory(addon.categoryIndexArmor, filterBaseStyle)
			result[addon.categoryIndexWeapon] = buildSubCategory(addon.categoryIndexWeapon, filterBaseStyle)
		end
		return result
	end
	local function refresh()
		if KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:IsShowing() then
			ZO_OUTFIT_STYLES_PANEL_KEYBOARD:RefreshVisible()
		else
			ZO_OUTFIT_STYLES_PANEL_KEYBOARD.isDirty = true
		end
	end
	local function atOutfitStateChange(oldState, newState)
		if newState == SCENE_SHOWING then
			atOutfit = true
		elseif newState == SCENE_HIDING then
			atOutfit = false
		end
	end
	ZO_RESTYLE_SCENE:RegisterCallback("StateChange", atOutfitStateChange)
	ZO_OUTFIT_STYLES_BOOK_SCENE:RegisterCallback("StateChange", atOutfitStateChange)

	local orgOnOutfitStyleEntryRightClick = ZO_OutfitStylesPanel_Keyboard.OnOutfitStyleEntryRightClick
	local function setSelectedStyle(style)
		self.selectedStyle = style
		refresh()
	end
	local function allStyles()
		self.selectedFashion = nil
		setSelectedStyle(nil)
	end
	local function setFilterBaseStyles(hide)
		self.settings.filterBaseStyles = hide
		refresh()
	end
	local function addMenuItems()
		if self.settings.filterBaseStyles then
			AddCustomMenuItem(
				GetString(SI_VOTANS_IMPROVED_OUTFIT_FILTER_SHOW_BASESTYLE),
				function()
					setFilterBaseStyles(false)
				end
			)
		else
			AddCustomMenuItem(
				GetString(SI_VOTANS_IMPROVED_OUTFIT_FILTER_HIDE_BASESTYLE),
				function()
					setFilterBaseStyles(true)
				end
			)
		end
	end
	function ZO_OutfitStylesPanel_Keyboard.OnOutfitStyleEntryRightClick(...)
		local panel, entryData = ...
		local collectibleData = entryData.data
		if collectibleData and not collectibleData.isEmptyCell then
			local orgShowMenu = ShowMenu
			function ShowMenu(...)
				ShowMenu = orgShowMenu
				local style = collectibleData.GetIcon and collectibleData:GetIcon():match("(/icons/[^_]+_[^_]+_)") or ""
				if not self.selectedFashion and self.selectedStyle ~= style and #style > 0 then
					AddCustomMenuItem(
						GetString(SI_VOTANS_IMPROVED_OUTFIT_FILTER_STYLE),
						function()
							ZO_RESTYLE_STATION_KEYBOARD.contentSearchEditBox:SetText("")
							setSelectedStyle(style)
						end
					)
				elseif self.selectedStyle and #self.selectedStyle > 0 then
					AddCustomMenuItem(GetString(SI_OUTFIT_ALL_TYPES_FILTER), allStyles)
				elseif self.selectedFashion then
					AddCustomMenuItem(GetString(SI_OUTFIT_ALL_TYPES_FILTER), allStyles)
				end
				addMenuItems()
				return ShowMenu(...)
			end
		else
			ClearMenu()
			if self.selectedStyle and #self.selectedStyle > 0 then
				AddCustomMenuItem(GetString(SI_OUTFIT_ALL_TYPES_FILTER), allStyles)
			elseif self.selectedFashion then
				AddCustomMenuItem(GetString(SI_OUTFIT_ALL_TYPES_FILTER), allStyles)
			end
			addMenuItems()

			ShowMenu(ZO_OUTFIT_STYLES_PANEL_KEYBOARD.control)
		end
		return orgOnOutfitStyleEntryRightClick(...)
	end
end

function addon:HookOutfitStylesGrid()
	local panel = ZO_OUTFIT_STYLES_PANEL_KEYBOARD
	local x, y
	local orgClearGridList = panel.gridListPanelList.ClearGridList
	function panel.gridListPanelList.ClearGridList(...)
		local ZO_ClearTable = ZO_ClearTable
		ZO_ClearNumericallyIndexedTable(stylesByPosition)
		ZO_ClearTable(positionByCollectibleId)
		ZO_ClearTable(styleByCollectibleId)
		x, y = 0, 0
		return orgClearGridList(...)
	end
	local orgAddEntry = panel.gridListPanelList.AddEntry
	function panel.gridListPanelList.AddEntry(...)
		local grid, data = ...
		local restyleSlotData = data:GetDataSource()
		if not restyleSlotData then
			return orgAddEntry(...)
		end

		if grid.currentHeaderName ~= data.gridHeaderName then
			x = 0
		end
		local stride = grid.numCellsPerRow
		local collectibleId = restyleSlotData:GetId()
		styleByCollectibleId[collectibleId] = data
		if (x % stride) == 0 then
			y = #stylesByPosition + 1
			stylesByPosition[y] = {}
		end
		local currentRowTable = stylesByPosition[y]
		currentRowTable[#currentRowTable + 1] = data
		x = #currentRowTable
		positionByCollectibleId[collectibleId] = {y, x}

		return orgAddEntry(...)
	end
end

function addon:InitSearchBoxFilter()
	local searchTextFor = {}
	local function AddStateChangeHandler(name, fragment)
		local function SearchBoxChange(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				ZO_RESTYLE_STATION_KEYBOARD.contentSearchEditBox:SetText(searchTextFor[name])
			elseif newState == SCENE_HIDING then
				searchTextFor[name] = ZO_RESTYLE_STATION_KEYBOARD.contentSearchEditBox:GetText()
			end
		end
		searchTextFor[name] = ""
		fragment:RegisterCallback("StateChange", SearchBoxChange)
	end
	AddStateChangeHandler("Styles", KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT)
	AddStateChangeHandler("Dyeing", KEYBOARD_DYEING_FRAGMENT)
	AddStateChangeHandler("Fashion", self.fragment)
end

function addon:HookDyeSampleTool()
	local orgSwitchToDyeingWithDyeId = ZO_DYEING_KEYBOARD.SwitchToDyeingWithDyeId
	function ZO_DYEING_KEYBOARD.SwitchToDyeingWithDyeId(...)
		orgSwitchToDyeingWithDyeId(...)
		local self, dyeId = ...
		if not self.dyeIdToSwatch[dyeId] then
			ZO_RESTYLE_STATION_KEYBOARD.contentSearchEditBox:SetText("")
			return orgSwitchToDyeingWithDyeId(...)
		end
	end
end

function addon:InitializeNavigation()
	self:HookDyeSwatchGrid()
	self:InitNavigationKeybind()
	self:HookGridEntryMouseHandler()
	self:HookOutfitStylesGrid()
	SecurePostHook(
		ZO_RESTYLE_STATION_KEYBOARD,
		"OnDeferredInitialize",
		function()
			self:InitSearchBoxFilter()
		end
	)
	self:HookDyeSampleTool()
	self:InitStyleList()
end
