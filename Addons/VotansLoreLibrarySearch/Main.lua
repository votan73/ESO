local addon = {
	name = "VotansLoreLibrarySearch"
}

local em = GetEventManager()
local ROW_TYPE_BOOK = 1
local ROW_TYPE_NOTIFY = 2
local selectedColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
local disabledColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))

do
	local orgLORE_READER_Show = LORE_READER.Show
	function LORE_READER:Show(title, body, ...)
		local function Highlight(text)
			if addon.words == nil or not addon.settings.highlight then
				return text
			end
			local positions = {}
			local inText = addon.isCase and text or zo_strlower(text)
			local words = addon.words
			local index
			for i = 1, #words do
				index = 1
				local word = words[i]
				while true do
					local s, e = inText:find(word, index)
					if s == nil then
						break
					end
					index = e + 1
					positions[#positions + 1] = {s, e}
				end
			end
			table.sort(
				positions,
				function(a, b)
					return a[1] < b[1]
				end
			)

			local parts = {}
			index = 0
			local p, s
			local color = addon.settings.highlightColor
			for i = 1, #positions do
				p = positions[i]
				s = p[1]
				if s > index then
					parts[#parts + 1] = text:sub(index, s - 1)
					index = s
					s = p[2]
					parts[#parts + 1] = "|c"
					parts[#parts + 1] = color
					parts[#parts + 1] = text:sub(index, s)
					parts[#parts + 1] = "|r"
					index = s + 1
				end
			end
			parts[#parts + 1] = text:sub(index)
			return table.concat(parts)
		end
		return orgLORE_READER_Show(self, Highlight(title), Highlight(body), ...)
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
		else
			highlight.animation:PlayForward()
		end
	end
end

function addon:InitScrollList()
	local function onMouseEnter(rowControl)
		HideRowHighlight(rowControl, false)
	end
	local function onMouseExit(rowControl)
		HideRowHighlight(rowControl, true)
	end
	local function onMouseDoubleClick(rowControl)
		local rowData = ZO_ScrollList_GetData(rowControl)
		ZO_LoreLibrary_ReadBook(rowData.categoryIndex, rowData.collectionIndex, rowData.bookIndex)
	end

	local function setupDataRow(rowControl, rowData, scrollList)
		local icon = rowControl:GetNamedChild("Texture")
		local nameLabel = rowControl:GetNamedChild("Name")
		local originLabel = rowControl:GetNamedChild("Origin")

		local title, texture, known = GetLoreBookInfo(rowData.categoryIndex, rowData.collectionIndex, rowData.bookIndex)

		icon:SetTexture(texture)
		nameLabel:SetText(zo_strformat(title))
		nameLabel:SetColor((known and selectedColor or disabledColor):UnpackRGB())

		local name = GetLoreCollectionInfo(rowData.categoryIndex, rowData.collectionIndex)
		originLabel:SetText(zo_strformat(name))

		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExit)
		rowControl:SetHandler("OnMouseDoubleClick", onMouseDoubleClick)
	end
	local function setupNotifyRow(rowControl, rowData, scrollList)
		local nameLabel = rowControl:GetNamedChild("Text")

		nameLabel:SetText(zo_strformat(rowData.text))
		nameLabel:SetColor(selectedColor:UnpackRGB())
	end
	ZO_ScrollList_AddDataType(self.ResultList, ROW_TYPE_BOOK, "VotansLibraryBookRow", 60, setupDataRow)
	ZO_ScrollList_AddDataType(self.ResultList, ROW_TYPE_NOTIFY, "VotansLibraryNotifyRow", 60, setupNotifyRow)
end

function addon:OnStartSearch()
	self.NavigationContainer:SetHidden(true)
	self.List:SetHidden(true)
	self.SearchContainer:SetHidden(false)
	self.loading:Show()
	VotansLibrarySearchBox:LoseFocus()
	VotansLibrarySearchBox:SetEditEnabled(false)
	self.abortButton:SetHidden(false)
end

function addon:OnEndSearch()
	self.loading:Hide()
	local inSearch = VotansLibrarySearchBox:GetText() ~= ""
	self.NavigationContainer:SetHidden(inSearch)
	self.List:SetHidden(inSearch)
	self.SearchContainer:SetHidden(not inSearch)
	VotansLibrarySearchBox:SetEditEnabled(true)
	self.abortButton:SetHidden(true)
end

local identifier = "VotansBackgroundLoreSearch"

function addon:UpdateScrollList()
	local scrollList = self.ResultList
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	ZO_ScrollList_Clear(scrollList)
	ZO_ScrollList_Commit(scrollList)

	local function endSearch()
		em:UnregisterForUpdate(identifier)
		if #dataList == 0 then
			dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_NOTIFY, {text = GetString(SI_VOTANS_LIBRARY_NO_RESULT)})
		end
		ZO_ScrollList_Commit(scrollList)
		self:OnEndSearch()
	end

	local words = VotansLibrarySearchBox:GetText()
	if words == "" then
		self:OnEndSearch()
		return
	end
	if #words < 2 then
		PlaySound(SOUNDS.NEGATIVE_CLICK)
		return
	end

	self:OnStartSearch()

	local isCase = zo_strlower(words)
	if isCase ~= words then
		isCase = true
	else
		words = isCase
		isCase = false
	end
	words = {zo_strsplit(" ", zo_strtrim(words))}

	for i = #words, 1, -1 do
		if #words[i] < 1 then
			table.remove(words, i)
		end
	end

	self.words = words
	self.isCase = isCase

	local GetLoreBookInfo, ReadLoreBook, zo_plainstrfind = GetLoreBookInfo, ReadLoreBook, zo_plainstrfind
	local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
	local zo_strlower = isCase and function(text)
			return text
		end or zo_strlower

	local function AllWords(text, words)
		for i = 1, #words do
			if not zo_plainstrfind(text, words[i]) then
				return false
			end
		end
		return true
	end
	local categoryIndex, collectionIndex, bookIndex = 0, 0, 0
	local numCollections, totalBooks = 0, 0
	local function step()
		if bookIndex >= totalBooks then
			if collectionIndex >= numCollections then
				if categoryIndex >= GetNumLoreCategories() then
					endSearch()
					return false
				else
					categoryIndex = categoryIndex + 1
					numCollections = select(2, GetLoreCategoryInfo(categoryIndex))
					numCollections = numCollections or 0
					collectionIndex = 0
				end
			end
			collectionIndex = collectionIndex + 1
			totalBooks = select(4, GetLoreCollectionInfo(categoryIndex, collectionIndex))
			totalBooks = totalBooks or 0
			bookIndex = 0
		end
		bookIndex = bookIndex + 1

		local title, _, known = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
		if not known then
			return true
		end
		title = zo_strlower(title)
		local found = AllWords(title, words)
		if not found then
			local body = ReadLoreBook(categoryIndex, collectionIndex, bookIndex)
			body = zo_strlower(body)
			found = AllWords(body, words)
		end
		if found then
			local rowData = {categoryIndex = categoryIndex, collectionIndex = collectionIndex, bookIndex = bookIndex}
			dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_BOOK, rowData, 1)
		end
		return true
	end
	local function steps()
		-- do as much as possible in 5ms
		local gettime = GetGameTimeMilliseconds
		local start = gettime()
		while true do
			if ((gettime() - start) >= 5) or not step() then
				break
			end
		end
	end
	em:RegisterForUpdate(identifier, 0, steps)
end

local function StartSearch(control)
	em:UnregisterForUpdate(identifier)
	control.addon:UpdateScrollList()
end

local function AbortSearch(control, ...)
	em:UnregisterForUpdate(identifier)
	local scrollList = addon.ResultList
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	ZO_ScrollList_Clear(scrollList)
	dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_NOTIFY, {text = GetString(SI_VOTANS_LIBRARY_CANCELLED)})
	ZO_ScrollList_Commit(scrollList)
	addon:OnEndSearch()
end

do
	local searchBoxWidth = 523
	local noSearchBoxWidth = 64
	local glass = " |t40:40:/esoui/art/tutorial/gamepad/gp_inventory_trait_not_researched_icon.dds|t"

	local function VotanSearchBoxMouseDown(bagSearch, button)
		if not bagSearch:HasFocus() and button == MOUSE_BUTTON_INDEX_RIGHT then
			bagSearch:SetText("")
		end
	end

	local function setDefaultText(control, text)
		control:SetDefaultText(text)
	end

	local function SetupControl(bagSearchBg)
		local bagSearch = bagSearchBg:GetNamedChild("Box")
		local bagSearchTx = bagSearch:GetNamedChild("Text")

		local closeButton = WINDOW_MANAGER:CreateControlFromVirtual(nil, bagSearch, "ZO_CloseButton")
		local function VotanSearchBoxFocusGained(control, ...)
			setDefaultText(bagSearch, "")
			bagSearchBg:SetAlpha(0.25)
			bagSearch:SetWidth(searchBoxWidth)
			closeButton:SetDimensions(16, 16)
			closeButton:SetHidden(false)
			return false
		end
		local function updateBackground(control, text)
			if text and text ~= "" then
				bagSearchBg:SetAlpha(0.25)
				bagSearch:SetWidth(searchBoxWidth)
				setDefaultText(bagSearch, "")
			else
				bagSearchBg:SetAlpha(0)
				bagSearch:SetWidth(noSearchBoxWidth)
				setDefaultText(bagSearch, glass)
				closeButton:SetHidden(true)
				StartSearch(control)
			end
		end
		local orgSetText = bagSearch.SetText
		local cursorPosition
		function bagSearch.SetText(...)
			if WINDOW_MANAGER:GetFocusControl() ~= bagSearch then
				updateBackground(...)
				return orgSetText(...)
			end
		end

		local function VotanSearchBoxFocusLost(control, ...)
			local text = control:GetText()
			updateBackground(control, text)
			return false
		end
		local function VotanSearchBoxTextChanged(control, ...)
			if WINDOW_MANAGER:GetFocusControl() ~= bagSearch then
				return VotanSearchBoxFocusLost(control, ...)
			end
			return false
		end
		local function VotanSearchBoxCloseClick(control, ...)
			bagSearch:SetText("")
		end

		closeButton:ClearAnchors()
		closeButton:SetAnchor(TOPLEFT, bagSearch, TOPRIGHT, 0, 3)
		closeButton:SetHidden(true)
		closeButton:SetHandler("OnMouseDown", VotanSearchBoxCloseClick)

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
		bagSearchBg:SetAlpha(0)
		bagSearch:SetWidth(noSearchBoxWidth)
		setDefaultText(bagSearch, glass)

		ZO_PreHookHandler(bagSearch, "OnMouseDown", VotanSearchBoxMouseDown)
		ZO_PreHookHandler(bagSearch, "OnFocusGained", VotanSearchBoxFocusGained)
		ZO_PreHookHandler(bagSearch, "OnFocusLost", VotanSearchBoxFocusLost)
		ZO_PreHookHandler(bagSearch, "OnTextChanged", VotanSearchBoxTextChanged)
	end

	function addon:SetupControls()
		self.SearchContainer = WINDOW_MANAGER:CreateControl("VotansLibrarySearchContainer", ZO_LoreLibrary, CT_CONTROL)

		local control
		control = ZO_LoreLibrary:GetNamedChild("NavigationContainer")
		self.NavigationContainer = control
		control = ZO_LoreLibrary:GetNamedChild("List")
		self.List = control

		control = self.SearchContainer
		control:SetAnchor(TOPRIGHT, nil, TOPRIGHT, 0, 60)
		control:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -33, -55)
		control:SetWidth(485)
		control:SetHidden(true)

		control = VotansLibrarySearchBox
		control.addon = self
		control:SetHandler("OnEnter", StartSearch, self.name)

		control = VotansLibrarySearch
		control:SetParent(ZO_LoreLibrary)
		control:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -43, 0)
		control:SetWidth(searchBoxWidth)
		SetupControl(control)

		local abortButton = WINDOW_MANAGER:CreateControlFromVirtual(nil, control, "ZO_CloseButton")
		abortButton:ClearAnchors()
		abortButton:SetAnchor(TOPRIGHT, control, TOPLEFT, -8, 2)
		abortButton:SetHidden(true)
		abortButton:SetHandler("OnMouseDown", AbortSearch)
		self.abortButton = abortButton

		control = WINDOW_MANAGER:CreateControlFromVirtual("VotansLibraryResultList", self.SearchContainer, "ZO_ScrollList")
		control:SetWidth(600)
		control:SetAnchor(TOPRIGHT, ZO_LoreLibrary, TOPRIGHT, -33, 60)
		control:SetAnchor(BOTTOMRIGHT, ZO_LoreLibrary, BOTTOMRIGHT, -33, -55)
		control:SetHidden(false)
		self.ResultList = control

		control = WINDOW_MANAGER:CreateControlFromVirtual("VotansLibraryLoading", self.SearchContainer, "ZO_Loading")
		control:SetAnchor(CENTER)
		ZO_Loading_Initialize(control, GetString(SI_VOTANS_LIBRARY_LOADING))
		self.loading = control

		self:InitScrollList()
	end
end

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")
	if not LibHarvensAddonSettings then
		return
	end

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Lore Library Search")
	if not settings then
		return
	end
	settings.version = "1.1.10"
	settings.website = "http://www.esoui.com/downloads/info1248-VotansLoreLibrarySearch.html"
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANS_LIBRARY_HIGHLIGHT),
		tooltip = GetString(SI_VOTANS_LIBRARY_HIGHLIGHT_TOOLTIP),
		getFunction = function()
			return self.settings.highlight
		end,
		setFunction = function(value)
			self.settings.highlight = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_LIBRARY_HIGHLIGHT_COLOR),
		getFunction = function()
			return ZO_ColorDef:New(addon.settings.highlightColor):UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.settings.highlightColor = ZO_ColorDef:New(newR, newG, newB, 1):ToHex()
		end,
		default = addon.varGlobalDefaults.highlightColor
	}
end

function addon:Initialize()
	self:SetupControls()

	addon.varGlobalDefaults = {highlight = true, highlightColor = "a06018"}
	local settings = ZO_SavedVars:NewAccountWide("VotansLoreLibrarySearch_Data", 1, nil, addon.varGlobalDefaults)
	self.settings = settings

	self:InitSettings()
end

local function OnAddOnLoaded(event, addonName)
	if addonName == addon.name then
		em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
		addon:Initialize()
	end
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
