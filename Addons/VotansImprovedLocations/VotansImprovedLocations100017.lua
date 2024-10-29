local addon = {
	name = "VotansImprovedLocations",
	allianceOrder = {
		[ALLIANCE_DAGGERFALL_COVENANT] = {
			[ALLIANCE_DAGGERFALL_COVENANT] = 1,
			[ALLIANCE_ALDMERI_DOMINION] = 2,
			[ALLIANCE_EBONHEART_PACT] = 3,
			[100] = 100,
			[999] = 999
		},
		[ALLIANCE_ALDMERI_DOMINION] = {
			[ALLIANCE_ALDMERI_DOMINION] = 1,
			[ALLIANCE_EBONHEART_PACT] = 2,
			[ALLIANCE_DAGGERFALL_COVENANT] = 3,
			[100] = 100,
			[999] = 999
		},
		[ALLIANCE_EBONHEART_PACT] = {
			[ALLIANCE_EBONHEART_PACT] = 1,
			[ALLIANCE_DAGGERFALL_COVENANT] = 2,
			[ALLIANCE_ALDMERI_DOMINION] = 3,
			[100] = 100,
			[999] = 999
		}
	},
	-- Thanks to Enodoc
	levels = {
		-- difficulty
		{
			{4, 6},
			{3, 15},
			{16, 23},
			{24, 31},
			{31, 37},
			{37, 43}
		},
		{
			{90, 90},
			{90, 90},
			{120, 120},
			{150, 150},
			{180, 180},
			{200, 200}
		},
		{
			{210, 210},
			{210, 210},
			{210, 210},
			{210, 210},
			{210, 210},
			{210, 210}
		}
	},
	locations = {
		-- [1] =
		{
			-- "Tamriel",
			alliance = 999
		},
		-- [2] =
		{
			-- "Glenumbra",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 2,
			zoneSortOrder = 2
		},
		-- [3] =
		{
			-- "Kluftspitze",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 4,
			zoneSortOrder = 4
		},
		-- [4] =
		{
			-- "Sturmhafen",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 3,
			zoneSortOrder = 3
		},
		-- [5] =
		{
			-- "Alik'r-Wüste",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 5,
			zoneSortOrder = 5
		},
		-- [6] =
		{
			-- "Bangkorai",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 6,
			zoneSortOrder = 6
		},
		-- [7] =
		{
			-- "Grahtwald",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 3,
			zoneSortOrder = 3
		},
		-- [8] =
		{
			-- "Malabal Tor",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 5,
			zoneSortOrder = 5
		},
		-- [9] =
		{
			-- "Schattenfenn",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 4,
			zoneSortOrder = 4
		},
		-- [10] =
		{
			-- "Deshaan",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 3,
			zoneSortOrder = 3
		},
		-- [11] =
		{
			-- "Steinfälle",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 2,
			zoneSortOrder = 2
		},
		-- [12] =
		{
			-- "Rift",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 6,
			zoneSortOrder = 6
		},
		-- [13] =
		{
			-- "Ostmarsch",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 5,
			zoneSortOrder = 5
		},
		-- [14] =
		{
			-- "Cyrodiil",
			alliance = 100
		},
		-- [15] =
		{
			-- "Auridon",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 2
		},
		-- [16] =
		{
			-- "Grünschatten",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 4,
			zoneSortOrder = 4
		},
		-- [17] =
		{
			-- "Schnittermark",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 6,
			zoneSortOrder = 6
		},
		-- [18] =
		{
			-- "Bal Foyen",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 1,
			zoneSortOrder = 1
		},
		-- [19] =
		{
			-- "Stros M'Kai",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 1,
			zoneSortOrder = 1.1
		},
		-- [20] =
		{
			-- "Betnikh",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 1,
			zoneSortOrder = 1
		},
		-- [21] =
		{
			-- "Khenarthis Rast",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 1,
			zoneSortOrder = 1
		},
		-- [22] =
		{
			-- "Ödfels",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 1,
			zoneSortOrder = 1.1
		},
		-- [23] =
		{
			-- "Kalthafen",
			alliance = 100,
			zoneLevel = 7
		},
		-- [24] =
		{
			-- "Aurbis",
			alliance = 999
		},
		-- [25] =
		{
			-- "Kargstein",
			alliance = 100
		},
		-- [26] =
		{
			-- "Kaiserstadt",
			alliance = 100
		},
		-- [27] =
		{
			-- "Wrothgar",
			alliance = ALLIANCE_DAGGERFALL_COVENANT
		},
		-- [28] =
		{
			-- "Abah's Landing",
			alliance = ALLIANCE_DAGGERFALL_COVENANT
		},
		-- [29] =
		{
			-- "Gold Coast",
			alliance = 100
		},
		-- [30] =
		{
			-- "Vvardenfell",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [31] =
		{
			-- "Clockwork City",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [32] =
		{
			-- "Summerset",
			alliance = ALLIANCE_ALDMERI_DOMINION
		},
		-- [33] =
		{
			-- "Artaeum",
			alliance = 100
		},
		-- [34] =
		{
			-- "Murkmire",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [35] =
		{
			-- "Norg-Tzel",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [36] =
		{
			-- "Northern Elswyer",
			alliance = ALLIANCE_ALDMERI_DOMINION
		},
		-- [37] =
		{
			-- "Southern Elswyer",
			alliance = ALLIANCE_ALDMERI_DOMINION
		},
		-- [38] =
		{
			-- "Western Skyrim",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [39] =
		{
			-- "Blackreach",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [40] =
		{
			-- "Blackreach",
			alliance = 999
		},
		-- [41] =
		{
			-- "Blackreach: Arkthzand",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [42] =
		{
			-- "Reik",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [43] =
		{
			-- "Blackwood",
			alliance = 999
		},
		-- [44] =
		{
			-- "Fargrave",
			alliance = 999
		},
		-- [45] =
		{
			-- "Deathlands",
			alliance = 999
		},
		-- [46] =
		{
			-- "High Isle",
			alliance = ALLIANCE_DAGGERFALL_COVENANT
		},
		-- [47] =
		{
			-- "Fargrave City"
			alliance = 999
		},
		-- [48] =
		{
			-- "Galen",
			alliance = ALLIANCE_DAGGERFALL_COVENANT
		},
		-- [49] =
		{
			-- "Telvani",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [50] =
		{
			-- "Apocrypha",
			alliance = 999
		},
		-- [51] =
		{
			-- "Westauen",
			alliance = 999
		},
		-- [52] =
		{
			-- "Augvea",
			alliance = 999
		}
	},
	tresureMap = {},
	survey = {}
}

local em = GetEventManager()
local am = GetAnimationManager()

local LOCATION_TYPE_ID = 2
local ALLIANCE_TYPE_ID = 3
local MAP_TYPE_ID = 4
local RECENT_TYPE_ID = 5
local FAV_TYPE_ID = 6

local headerColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
local selectedColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
local disabledColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))

local SORT_LOCATION_NAME = "Name"
local SORT_LOCATION_LEVEL_ASC = "LevelAsc"
local SORT_LOCATION_LEVEL_DSC = "LevelDsc"

local function HideRowHighlight(rowControl, hidden, unselected)
	if not rowControl then
		return
	end
	if not ZO_ScrollList_GetData(rowControl) then
		return
	end

	local highlight = rowControl:GetNamedChild("Highlight")

	if highlight then
		if not highlight.animation then
			highlight.animation = am:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
		end

		if highlight.animation:IsPlaying() then
			highlight.animation:Stop()
		end
		if unselected ~= false then
			highlight:SetTexture("esoui/art/miscellaneous/listitem_selectedhighlight.dds")
		else
			highlight:SetTexture("esoui/art/miscellaneous/listitem_highlight.dds")
		end
		if hidden and unselected ~= false then
			highlight.animation:PlayBackward()
		else
			highlight.animation:PlayForward()
		end
	end
end

function addon:RefreshList()
	if IsInGamepadPreferredMode() then
		GAMEPAD_WORLD_MAP_LOCATIONS.list:RefreshVisible()
	else
		ZO_ScrollList_RefreshVisible(WORLD_MAP_LOCATIONS.list)
	end
end

do
	local allianceOrder2zoneOrder2icon = {[1] = {}, [2] = {}, [3] = {}}
	local function FormatLevel(allianceOrder, zoneOrder)
		local zoneOrder2icon = allianceOrder2zoneOrder2icon[allianceOrder]
		if zoneOrder2icon then
			local icon = zoneOrder2icon[zoneOrder]
			if not icon then
				if allianceOrder == 1 then
					icon = zo_iconFormatInheritColor("esoui/art/journal/journal_tabicon_cadwell_down.dds", 28, 28) .. zoneOrder
				elseif allianceOrder == 2 then
					icon = zo_iconFormatInheritColor("esoui/art/cadwell/cadwell_indexicon_silver_down.dds", 28, 28) .. zoneOrder
				elseif allianceOrder == 3 then
					icon = zo_iconFormatInheritColor("esoui/art/cadwell/cadwell_indexicon_gold_down.dds", 28, 28) .. zoneOrder
				end
				zoneOrder2icon[zoneOrder] = icon
			end
			return icon
		else
			return zoneOrder > 0 and zoneOrder or ""
		end
	end
	local dlcOrder2icon = {}
	local function FormatDlcOrder(dlcOrder)
		local icon = dlcOrder2icon[dlcOrder]
		if not icon then
			icon = zo_iconFormatInheritColor("esoui/art/collections/collections_tabicon_dlc_down.dds", 28, 28) .. dlcOrder
			dlcOrder2icon[dlcOrder] = icon
		end
		return icon
	end

	function addon:ShowLevel(levelLabel, location)
		if location and self.account.showLevels then
			if location.zoneOrder > 0 then
				levelLabel:SetText(FormatLevel(location.allianceOrder, location.zoneOrder))
			elseif location.zoneLevel then
				levelLabel:SetText(FormatLevel(1, location.zoneLevel))
			elseif location.mapContentType == MAP_CONTENT_AVA then
				levelLabel:SetText("|t23:23:/esoui/art/icons/mapkey/mapkey_keep.dds|t")
			elseif location.dlcOrder and location.dlcOrder > 0 then
				levelLabel:SetText(FormatDlcOrder(location.dlcOrder))
			else
				levelLabel:SetText("")
			end
			levelLabel:SetHidden(false)
		else
			levelLabel:SetText("")
			levelLabel:SetHidden(true)
		end
	end
end

local function onMouseEnter(rowControl)
	HideRowHighlight(rowControl, false)
end

function addon:SetupLocationName(rowData)
	return rowData.locationName
end

do
	local callback = {dataEntry = {data = {index = 1}}}
	-- Fork functions called by original callback handler
	function callback:GetParent()
		return self
	end
	function callback:SetAnchor()
	end
	--
	function callback:PerformClick(index, button, upInside)
		self.dataEntry.data.index = index
		ZO_WorldMapLocationRowLocation_OnMouseUp(self, button, upInside)
	end

	local function onMouseExitLocation(rowControl)
		local data = ZO_ScrollList_GetData(rowControl)
		HideRowHighlight(rowControl, true, not data or addon:GetCurrentMapIndex() ~= data.index)
	end
	local function onMouseClickLocation(rowControl, button, upInside)
		local data = ZO_ScrollList_GetData(rowControl)
		callback:PerformClick(data.index, button, upInside)
	end

	function addon:SetupLocation(rowControl, rowData)
		local listDisabled = WORLD_MAP_LOCATIONS:GetDisabled()
		local locationLabel = rowControl.locationLabel
		locationLabel:SetText(self:SetupLocationName(rowData))
		locationLabel:SetColor((listDisabled and disabledColor or selectedColor):UnpackRGB())

		local levelLabel = rowControl.levelLabel
		self:ShowLevel(levelLabel, self.locations[rowData.index])

		-- HideRowHighlight(rowControl, true, rowData and WORLD_MAP_LOCATIONS.selectedMapIndex ~= rowData.index)
		HideRowHighlight(rowControl, true, rowData and self:GetCurrentMapIndex() ~= rowData.index)

		rowControl:SetMouseEnabled(not listDisabled)
	end
	function addon:CreateLocation(rowControl)
		rowControl:SetHeight(25)
		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExitLocation)
		rowControl:SetHandler("OnMouseUp", onMouseClickLocation)
		rowControl.locationLabel = rowControl:GetNamedChild("Location")
		rowControl.levelLabel = rowControl:GetNamedChild("Level")
	end

	local function onMouseExitRecent(rowControl)
		HideRowHighlight(rowControl, true)
	end
	local function onMouseClickRecent(rowControl, button, upInside)
		local rowData = ZO_ScrollList_GetData(rowControl)
		if not rowData then
			return
		end
		callback:PerformClick(addon.player.recent[rowData.index], button, upInside)
	end
	local function onMouseClickFavorite(rowControl, button, upInside)
		local rowData = ZO_ScrollList_GetData(rowControl)
		if not rowData then
			return
		end
		callback:PerformClick(addon.account.favorites[rowData.index], button, upInside)
	end

	function addon:SetupRecentLocation(rowControl, rowData)
		local listDisabled = WORLD_MAP_LOCATIONS:GetDisabled()
		local locationLabel = rowControl.locationLabel
		local levelLabel = rowControl.levelLabel

		rowData = self.player.recent[rowData.index] or 0
		if rowData > 0 then
			local location = self.locations[rowData]

			locationLabel:SetText(self:SetupLocationName(location))
			rowControl:SetMouseEnabled(not listDisabled)

			self:ShowLevel(levelLabel, location)
		else
			locationLabel:SetText("-")
			levelLabel:SetText("")
			rowControl:SetMouseEnabled(false)
		end

		locationLabel:SetColor((listDisabled and disabledColor or selectedColor):UnpackRGB())
	end
	function addon:CreateRecentLocation(rowControl)
		rowControl:SetHeight(25)
		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExitRecent)
		rowControl:SetHandler("OnMouseUp", onMouseClickRecent)
		rowControl.locationLabel = rowControl:GetNamedChild("Location")
		rowControl.levelLabel = rowControl:GetNamedChild("Level")
	end

	function addon:SetupFavoriteLocation(rowControl, rowData)
		local listDisabled = WORLD_MAP_LOCATIONS:GetDisabled()
		local locationLabel = rowControl.locationLabel
		local levelLabel = rowControl.levelLabel

		rowData = self.account.favorites[rowData.index] or 0
		if rowData > 0 then
			local location = self.locations[rowData]

			locationLabel:SetText(self:SetupLocationName(location))
			rowControl:SetMouseEnabled(not listDisabled)

			local levelLabel = rowControl:GetNamedChild("Level")
			self:ShowLevel(levelLabel, location)
		else
			locationLabel:SetText("-")
			levelLabel:SetText("")
			rowControl:SetMouseEnabled(false)
		end

		locationLabel:SetColor((listDisabled and disabledColor or selectedColor):UnpackRGB())
	end
	function addon:CreateFavoriteLocation(rowControl)
		rowControl:SetHeight(25)
		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExitRecent)
		rowControl:SetHandler("OnMouseUp", onMouseClickFavorite)
		rowControl.locationLabel = rowControl:GetNamedChild("Location")
		rowControl.levelLabel = rowControl:GetNamedChild("Level")
	end
end

function addon:SetupHeader(rowControl, rowData)
	local locationLabel = rowControl:GetNamedChild("Location")
	local texture = rowControl:GetNamedChild("Texture")

	texture:ClearAnchors()

	if rowData.alliance < 100 then
		locationLabel:SetText(zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(rowData.alliance)))
		texture:SetTexture(ZO_GetAllianceIcon(rowData.alliance))
		texture:SetDimensions(32, 64)
		texture:SetAnchor(TOPLEFT)
		rowControl:SetHeight(50)
	elseif rowData.alliance == 100 then
		locationLabel:SetText(zo_strformat(GetString(SI_MAPTRANSITLINEALLIANCE1)))
		texture:SetTexture("esoui/art/compass/ava_flagneutral.dds")
		texture:SetDimensions(64, 64)
		texture:SetAnchor(TOPLEFT, nil, TOPLEFT, -16)
		rowControl:SetHeight(50)
	end

	locationLabel:SetColor(headerColor:UnpackRGB())
end

function addon:SetupMapType(rowControl, rowData)
	local locationLabel = rowControl:GetNamedChild("Location")
	local texture = rowControl:GetNamedChild("Texture")

	if rowData.alliance == 999 then
		locationLabel:SetText(zo_strformat(GetString(SI_MAP_MENU_WORLD_MAP)))
		texture:ClearAnchors()
		texture:SetTexture("esoui/art/tutorial/gamepad/gp_lfg_world.dds")
		texture:SetDimensions(32, 32)
		texture:SetAnchor(BOTTOMLEFT)
	elseif rowData.alliance == 1000 then
		locationLabel:SetText("")
		texture:ClearAnchors()
		texture:SetTexture("esoui/art/icons/mapkey/mapkey_elderscroll.dds")
		texture:SetDimensions(48, 48)
		texture:SetAnchor(TOPLEFT)
	elseif rowData.alliance == 1001 then
		locationLabel:SetText("")
		texture:ClearAnchors()
		texture:SetTexture("esoui/art/icons/mapkey/mapkey_events.dds")
		texture:SetDimensions(40, 40)
		texture:SetAnchor(TOPLEFT, nil, TOPLEFT, -4, 0)
	end
	rowControl:SetHeight(40)
	locationLabel:SetColor(headerColor:UnpackRGB())
end

function addon:GetPlayerMapIndex()
	local zoneId = GetZoneId(GetUnitZoneIndex("player"))
	return GetMapIndexByZoneId(zoneId) or GetMapIndexByZoneId(GetZoneStoryZoneIdForZoneId(zoneId))
end

do
	local function MapIndexFromCurrentMap()
		local zoneId = GetZoneId(GetCurrentMapZoneIndex())
		return GetMapIndexByZoneId(zoneId) or GetMapIndexByZoneId(GetZoneStoryZoneIdForZoneId(zoneId))
	end
	function addon:GetCurrentMapIndex()
		return GetCurrentMapIndex() or MapIndexFromCurrentMap()
	end
end

function addon:UpdateRecent(mapIndex)
	if not self.account.showRecentList then
		return
	end

	local recent = self.player.recent
	local oldCount = #recent
	for i = oldCount, 1, -1 do
		if recent[i] and recent[i] == mapIndex then
			table.remove(recent, i)
		end
	end
	table.insert(recent, 1, mapIndex)

	local count = #recent
	while count > 5 do
		table.remove(recent, count)
		count = count - 1
	end
	return count > oldCount
end

local function SortFavs(favorites)
	local locations = addon.locations
	table.sort(
		favorites,
		function(a, b)
			return locations[a].locationName < locations[b].locationName
		end
	)
end

function addon:UpdateFavorite(mapIndex)
	local favorites = self.account.favorites
	local oldCount = #favorites
	for i = oldCount, 1, -1 do
		if favorites[i] and favorites[i] == mapIndex then
			table.remove(favorites, i)
			return true
		end
	end
	favorites[#favorites + 1] = mapIndex
	SortFavs(favorites)
	return true
end

local GetMapInfoByIndex = GetMapInfoByIndex or function(mapIndex)
		local name, mapType, mapContentType, zoneIndex, description = GetMapInfo(mapIndex)
		return name, mapType, mapContentType, zoneIndex + 1, description
	end

function addon:MarkDirty()
	GAMEPAD_WORLD_MAP_LOCATIONS.votanListIsDirty = true
	WORLD_MAP_LOCATIONS.votanListIsDirty = true
end

function addon:BuildLocationList()
	local playerAlliance = self.playerAlliance
	local allianceOrder = addon.allianceOrder[playerAlliance]
	allianceOrder[100] = self.account.allAllianceOnTop and 0 or 100

	local location
	local mapData = self.mapData
	local getAllianceOrder = self.account.assignToAlliance and function(location)
			return allianceOrder[location.alliance] or allianceOrder[100]
		end or function(location)
			return location.zoneOrder > 0 and allianceOrder[location.alliance] or allianceOrder[100]
		end
	if not mapData then
		mapData = {}
		local GetMapInfoByIndex, LocalizeString = GetMapInfoByIndex, ZO_CachedStrFormat
		local SI_WORLD_MAP_LOCATION_NAME = GetString(SI_QUEST_JOURNAL_ZONE_FORMAT)
		for i = 1, GetNumMaps() do
			local mapName, mapType, mapContentType, zoneIndex, description = GetMapInfoByIndex(i)
			if mapName ~= "" then
				location = self.locations[i]
				if not location then
					location = ZO_DeepTableCopy(self.locations[29])
					self.locations[i] = location
				end
				location.zoneIndex = zoneIndex

				location.dlcOrder = 0
				location.zoneOrder = location.zoneOrder or 0
				location.zoneSortOrder = location.zoneSortOrder or 999
				location.allianceOrder = getAllianceOrder(location)
				location.locationName = LocalizeString(SI_WORLD_MAP_LOCATION_NAME, mapName)
				location.rawName = mapName
				location.mapType = mapType
				location.mapContentType = mapContentType
				location.index = i
				location.description = description

				mapData[#mapData + 1] = location
			end
		end
		local dlcOrder = 0
		for i = 27, GetNumMaps() do
			location = self.locations[i]
			if location then
				local zoneId = GetZoneId(location.zoneIndex)
				local storyZoneId = GetZoneStoryZoneIdForZoneId(zoneId)
				if i ~= 35 and i ~= 40 and storyZoneId == 0 or storyZoneId == zoneId then
					dlcOrder = dlcOrder + 1
					location.dlcOrder = dlcOrder
				end
			end
		end
		for i = 27, GetNumMaps() do
			location = self.locations[i]
			if location then
				local zoneId = GetZoneId(location.zoneIndex)
				local storyZoneId = GetZoneStoryZoneIdForZoneId(zoneId)
				if i == 35 then
					location.dlcOrder = self.locations[34].dlcOrder
				elseif i == 40 then
					location.dlcOrder = self.locations[42].dlcOrder
				elseif storyZoneId > 0 and storyZoneId ~= zoneId then
					location.dlcOrder = self.locations[GetMapIndexByZoneId(storyZoneId)].dlcOrder
				end
			end
		end
		self.mapData = mapData

		local list = {}
		self.zoneNameToMapIndex = list
		local GetZoneNameByIndex = GetZoneNameByIndex
		for mapIndex, entry in pairs(self.locations) do
			list[GetZoneNameByIndex(entry.zoneIndex)] = mapIndex
		end
	else
		for i = 1, GetNumMaps() do
			location = self.locations[i]
			if location then
				location.allianceOrder = getAllianceOrder(location)
			end
		end
	end

	local sortLoc
	if self.account.sortBy == SORT_LOCATION_NAME then
		sortLoc = function(a, b)
			return a.locationName < b.locationName
		end
	elseif self.account.sortBy == SORT_LOCATION_LEVEL_ASC then
		sortLoc = function(a, b)
			if a.zoneSortOrder ~= b.zoneSortOrder then
				return a.zoneSortOrder < b.zoneSortOrder
			elseif a.dlcOrder ~= b.dlcOrder then
				return a.dlcOrder < b.dlcOrder
			else
				return a.locationName < b.locationName
			end
		end
	else
		sortLoc = function(a, b)
			if a.zoneSortOrder ~= b.zoneSortOrder then
				return a.zoneSortOrder > b.zoneSortOrder
			elseif a.dlcOrder ~= b.dlcOrder then
				return a.dlcOrder > b.dlcOrder
			else
				return a.locationName < b.locationName
			end
		end
	end

	table.sort(
		mapData,
		function(a, b)
			if a.allianceOrder == b.allianceOrder then
				if a.allianceOrder > 0 and a.allianceOrder < 100 then
					return sortLoc(a, b)
				else
					if a.mapContentType == b.mapContentType then
						return sortLoc(a, b)
					else
						return a.mapContentType < b.mapContentType
					end
				end
			else
				return a.allianceOrder < b.allianceOrder
			end
		end
	)
	SortFavs(self.account.favorites)

	return self.mapData
end

local function setupFactory(list, typeId, factory)
	list.dataTypes[typeId].pool:SetCustomAcquireBehavior(factory)
end
local function HookLocations()
	ZO_ScrollList_AddDataType(
		WORLD_MAP_LOCATIONS.list,
		LOCATION_TYPE_ID,
		"VotansLocationRow",
		25,
		function(control, rowData)
			addon:SetupLocation(control, rowData)
		end
	)
	setupFactory(
		WORLD_MAP_LOCATIONS.list,
		LOCATION_TYPE_ID,
		function(control)
			addon:CreateLocation(control)
		end
	)

	ZO_ScrollList_AddDataType(
		WORLD_MAP_LOCATIONS.list,
		ALLIANCE_TYPE_ID,
		"VotansLocationHeaderRow",
		50,
		function(control, rowData)
			addon:SetupHeader(control, rowData)
		end
	)
	ZO_ScrollList_AddDataType(
		WORLD_MAP_LOCATIONS.list,
		MAP_TYPE_ID,
		"VotansLocationHeaderRow",
		40,
		function(control, rowData)
			addon:SetupMapType(control, rowData)
		end
	)
	ZO_ScrollList_AddDataType(
		WORLD_MAP_LOCATIONS.list,
		RECENT_TYPE_ID,
		"VotansLocationRow",
		25,
		function(control, rowData)
			addon:SetupRecentLocation(control, rowData)
		end
	)
	setupFactory(
		WORLD_MAP_LOCATIONS.list,
		RECENT_TYPE_ID,
		function(control)
			addon:CreateRecentLocation(control)
		end
	)
	ZO_ScrollList_AddDataType(
		WORLD_MAP_LOCATIONS.list,
		FAV_TYPE_ID,
		"VotansLocationRow",
		25,
		function(control, rowData)
			addon:SetupFavoriteLocation(control, rowData)
		end
	)
	setupFactory(
		WORLD_MAP_LOCATIONS.list,
		FAV_TYPE_ID,
		function(control)
			addon:CreateFavoriteLocation(control)
		end
	)
	function WORLD_MAP_LOCATIONS:BuildLocationList()
		if not addon.playerAlliance then
			addon:MarkDirty()
			return
		end

		ZO_ScrollList_Clear(self.list)

		local mapData = addon:BuildLocationList()

		self.list.mode = 2
		local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
		local scrollData = ZO_ScrollList_GetDataList(self.list)
		if #addon.account.favorites > 0 then
			scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(MAP_TYPE_ID, {alliance = 1001})
			for i = 1, #addon.account.favorites do
				scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(FAV_TYPE_ID, {index = i})
			end
		end

		addon.recentPosition = #scrollData
		if addon.account.showRecentList then
			scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(MAP_TYPE_ID, {alliance = 1000})
			for i = 1, #addon.player.recent do
				scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(RECENT_TYPE_ID, {index = i})
			end
		end
		addon.nextRecentIndex = #scrollData - addon.recentPosition

		local lastAlliance = -1
		for i = 1, #mapData do
			local entry = mapData[i]
			if entry.allianceOrder ~= lastAlliance then
				lastAlliance = entry.allianceOrder
				if entry.alliance < 999 then
					scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ALLIANCE_TYPE_ID, entry)
				else
					scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(MAP_TYPE_ID, entry)
				end
			end

			scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(LOCATION_TYPE_ID, entry)
		end

		ZO_ScrollList_Commit(self.list)
	end

	local orgUpdateSelectedMap = WORLD_MAP_LOCATIONS.UpdateSelectedMap
	function WORLD_MAP_LOCATIONS:UpdateSelectedMap(...)
		local mapIndex = addon:GetPlayerMapIndex()
		local scrollData = ZO_ScrollList_GetDataList(self.list)
		if mapIndex and addon.player.recent[1] ~= mapIndex then
			local needUpdate = addon:UpdateRecent(mapIndex)

			if needUpdate then
				-- can be one new entry, only
				local count = addon.nextRecentIndex or 0
				addon.nextRecentIndex = count + 1
				table.insert(scrollData, addon.nextRecentIndex + (addon.recentPosition or 1), ZO_ScrollList_CreateDataEntry(RECENT_TYPE_ID, {index = count}))
				ZO_ScrollList_Commit(self.list)
			end
		end
		-- if WORLD_MAP_LOCATIONS_FRAGMENT:IsHidden() then
		-- 	mapIndex = GetCurrentMapIndex()
		-- 	for i = 1, #scrollData do
		-- 		if scrollData[i].data.index == mapIndex then
		-- 			ZO_ScrollList_ScrollDataIntoView(self.list, i, nil, true)
		-- 			break
		-- 		end
		-- 	end
		-- end
		return orgUpdateSelectedMap(self, ...)
	end
end

local function HookGamepadLocations()
	GAMEPAD_WORLD_MAP_LOCATIONS.list:AddDataTemplate(
		"VotansGamepadLocationRow",
		function(...)
			local control, entryData = select(1, ...)
			local levelLabel = control:GetNamedChild("SubLabel1")
			addon:ShowLevel(levelLabel, entryData)
			control.label:SetWidth(ZO_GAMEPAD_DEFAULT_LIST_ENTRY_WIDTH_AFTER_INDENT - levelLabel:GetWidth())

			local texture = control.icon
			if entryData.alliance < 100 then
				texture:SetTexture(ZO_GetAllianceIcon(entryData.alliance))
				texture:SetDimensions(32, 64)
			elseif entryData.alliance == 100 then
				texture:SetTexture("esoui/art/compass/ava_flagneutral.dds")
				texture:SetDimensions(64, 64)
			end
			control.icon:SetHidden(false)

			return GAMEPAD_WORLD_MAP_LOCATIONS:SetupLocation(...)
		end,
		ZO_GamepadMenuEntryTemplateParametricListFunction
	)

	GAMEPAD_WORLD_MAP_LOCATIONS.list:AddDataTemplate(
		"VotansGamepadRecentLocationRow",
		function(...)
			local control, entryData = select(1, ...)
			local levelLabel = control:GetNamedChild("SubLabel1")
			addon:ShowLevel(levelLabel, entryData)
			control.label:SetWidth(ZO_GAMEPAD_DEFAULT_LIST_ENTRY_WIDTH_AFTER_INDENT - levelLabel:GetWidth())
			return GAMEPAD_WORLD_MAP_LOCATIONS:SetupLocation(...)
		end,
		ZO_GamepadMenuEntryTemplateParametricListFunction
	)

	local recentEntries = {}
	local locationEntries = {}
	function GAMEPAD_WORLD_MAP_LOCATIONS:BuildLocationList()
		if not addon.playerAlliance then
			addon:MarkDirty()
			return
		end

		self.list:Clear()

		local mapData = addon:BuildLocationList()

		for i = 1, #addon.player.recent do
			local entry = addon.locations[addon.player.recent[i]]
			local entryData = recentEntries[entry.locationName]
			if not entryData then
				entryData = ZO_GamepadEntryData:New(addon:SetupLocationName(entry), "esoui/art/icons/mapkey/mapkey_elderscroll.dds")
				recentEntries[entry.locationName] = entryData
			end
			entryData:SetDataSource(entry)
			self.list:AddEntry("VotansGamepadRecentLocationRow", entryData)
		end

		for i = 1, #mapData do
			local entry = mapData[i]
			local entryData = locationEntries[entry.locationName]
			if not entryData then
				entryData = ZO_GamepadEntryData:New(addon:SetupLocationName(entry))
				locationEntries[entry.locationName] = entryData
			end
			entryData:SetDataSource(entry)
			self.list:AddEntry("VotansGamepadLocationRow", entryData)
		end

		self.list:Commit()
	end

	local orgUpdateSelectedMap = GAMEPAD_WORLD_MAP_LOCATIONS.UpdateSelectedMap
	function GAMEPAD_WORLD_MAP_LOCATIONS:UpdateSelectedMap(...)
		local mapIndex = addon:GetPlayerMapIndex()
		if mapIndex and addon.player.recent[1] ~= mapIndex then
			addon:UpdateRecent(mapIndex)
			self:BuildLocationList()
		end

		return orgUpdateSelectedMap(self, ...)
	end
end

local function RebuildList()
	if GAMEPAD_WORLD_MAP_LOCATIONS.votanListIsDirty and GAMEPAD_WORLD_MAP_LOCATIONS_FRAGMENT:IsShowing() then
		GAMEPAD_WORLD_MAP_LOCATIONS:BuildLocationList()
		GAMEPAD_WORLD_MAP_LOCATIONS.votanListIsDirty = false
	end
	if WORLD_MAP_LOCATIONS.votanListIsDirty and WORLD_MAP_LOCATIONS_FRAGMENT:IsShowing() then
		WORLD_MAP_LOCATIONS:BuildLocationList()
		WORLD_MAP_LOCATIONS.votanListIsDirty = false
	end
end

function addon:InitializeKeybindDescriptors()
	if self.keybindStripDescriptor then
		return
	end

	self.keybindStripDescriptor = {
		alignment = KEYBIND_STRIP_ALIGN_RIGHT,
		{
			name = GetString(SI_BINDING_NAME_VOTANS_TOGGLE_LOCATION_FAVORITE),
			keybind = "VOTANS_TOGGLE_LOCATION_FAVORITE",
			order = 100,
			callback = function()
				local mapIndex = self:GetCurrentMapIndex()
				if mapIndex and mapIndex > 0 and mapIndex < 2147483647 then
					if self:UpdateFavorite(mapIndex) then
						self:MarkDirty()
						RebuildList()
					end
				end
			end,
			visible = function()
				if not self.account.showToggleFavorite then
					return false
				end
				local mapIndex = self:GetCurrentMapIndex()
				return mapIndex and mapIndex > 0 and mapIndex < 2147483647
			end
		}
	}
	CALLBACK_MANAGER:RegisterCallback(
		"OnWorldMapChanged",
		function()
			if KEYBIND_STRIP:HasKeybindButtonGroup(self.keybindStripDescriptor) then
				KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
			end
		end
	)
end

function addon:InitSettings()
	self.player = ZO_SavedVars:NewCharacterIdSettings("VotansImprovedLocations_Data", 1, nil, {recent = {}})

	local defaults = {
		showLevels = false,
		sortBy = SORT_LOCATION_NAME,
		allAllianceOnTop = false,
		favorites = {},
		showToggleFavorite = true,
		showRecentList = true,
		assignToAlliance = false
	}
	self.account = ZO_SavedVars:NewAccountWide("VotansImprovedLocations_Data", 1, nil, defaults)

	local optionsTable = {
		{
			-- Show Levels
			type = "checkbox",
			name = GetString(SI_VOTANSIMPROVEDLOCATIONS_SHOW_LEVELS),
			tooltip = nil,
			getFunc = function()
				return self.account.showLevels
			end,
			setFunc = function(value)
				if self.account.showLevels ~= value then
					self.account.showLevels = value
					self:RefreshList()
				end
			end,
			width = "full",
			default = defaults.showLevels
		},
		{
			-- Sort Order
			type = "dropdown",
			name = GetString(SI_VOTANSIMPROVEDLOCATIONS_SORT),
			tooltip = nil,
			choices = {
				GetString(SI_VOTANSIMPROVEDLOCATIONS_SORT_NAME),
				GetString(SI_VOTANSIMPROVEDLOCATIONS_SORT_ASC),
				GetString(SI_VOTANSIMPROVEDLOCATIONS_SORT_DSC)
			},
			getFunc = function()
				local value = self.account.sortBy
				if value == SORT_LOCATION_NAME then
					value = GetString(SI_VOTANSIMPROVEDLOCATIONS_SORT_NAME)
				elseif value == SORT_LOCATION_LEVEL_ASC then
					value = GetString(SI_VOTANSIMPROVEDLOCATIONS_SORT_ASC)
				else
					value = GetString(SI_VOTANSIMPROVEDLOCATIONS_SORT_DSC)
				end
				return value
			end,
			setFunc = function(value)
				if value == GetString(SI_VOTANSIMPROVEDLOCATIONS_SORT_NAME) then
					value = SORT_LOCATION_NAME
				elseif value == GetString(SI_VOTANSIMPROVEDLOCATIONS_SORT_ASC) then
					value = SORT_LOCATION_LEVEL_ASC
				else
					value = SORT_LOCATION_LEVEL_DSC
				end
				if self.account.sortBy ~= value then
					self.account.sortBy = value
					self:MarkDirty()
					RebuildList()
				end
			end,
			width = "full",
			default = defaults.sortBy
		},
		{
			-- All alliance on top
			type = "checkbox",
			name = GetString(SI_VOTANSIMPROVEDLOCATIONS_SHOW_ALL_ALLIANCE_ON_TOP),
			tooltip = nil,
			getFunc = function()
				return self.account.allAllianceOnTop
			end,
			setFunc = function(value)
				if self.account.allAllianceOnTop ~= value then
					self.account.allAllianceOnTop = value
					self:MarkDirty()
					RebuildList()
				end
			end,
			width = "full",
			default = defaults.allAllianceOnTop
		},
		{
			-- Show toggle favorite
			type = "checkbox",
			name = GetString(SI_VOTANSIMPROVEDLOCATIONS_SHOW_TOGGLE_FAVORITE),
			tooltip = nil,
			getFunc = function()
				return self.account.showToggleFavorite
			end,
			setFunc = function(value)
				if self.account.showToggleFavorite ~= value then
					self.account.showToggleFavorite = value
				end
			end,
			width = "full",
			default = defaults.showToggleFavorite
		},
		{
			-- Show recent list
			type = "checkbox",
			name = GetString(SI_VOTANSIMPROVEDLOCATIONS_SHOW_RECENT_LIST),
			tooltip = nil,
			getFunc = function()
				return self.account.showRecentList
			end,
			setFunc = function(value)
				if self.account.showRecentList ~= value then
					self.account.showRecentList = value
					self:MarkDirty()
					RebuildList()
				end
			end,
			width = "full",
			default = defaults.showRecentList
		},
		{
			-- Assign DLC to alliance
			type = "checkbox",
			name = GetString(SI_VOTANSIMPROVEDLOCATIONS_ASSIGN_TO_ALLIANCE),
			tooltip = nil,
			getFunc = function()
				return self.account.assignToAlliance
			end,
			setFunc = function(value)
				if self.account.assignToAlliance ~= value then
					self.account.assignToAlliance = value
					self:MarkDirty()
					RebuildList()
				end
			end,
			width = "full",
			default = defaults.assignToAlliance
		}
	}

	self:PostInitSettings(optionsTable)
end

function addon:PostInitSettings(optionsTable)
	local LAM2 = LibAddonMenu2 or LibStub("LibAddonMenu-2.0")
	local panelData = {
		type = "panel",
		name = "Improved Locations",
		author = "votan",
		version = "1.23.1",
		registerForRefresh = false,
		registerForDefaults = true,
		website = "http://www.esoui.com/downloads/info1096-VotansImprovedLocations.html"
	}
	LAM2:RegisterAddonPanel(addon.name, panelData)
	LAM2:RegisterOptionControls(addon.name, optionsTable)
end

local function stateChange(oldState, newState)
	if newState == SCENE_SHOWING then
		RebuildList()
	elseif newState == SCENE_SHOWN then
		PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_VOTANS_IMPROVED_LOCATIONS))
		addon:InitializeKeybindDescriptors()
		KEYBIND_STRIP:AddKeybindButtonGroup(addon.keybindStripDescriptor)
	elseif newState == SCENE_HIDING then
		KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.keybindStripDescriptor)
		RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_VOTANS_IMPROVED_LOCATIONS))
	end
end

function addon:PreInitList()
	HookLocations()
	HookGamepadLocations()

	GAMEPAD_WORLD_MAP_LOCATIONS_FRAGMENT:RegisterCallback("StateChange", stateChange)
	WORLD_MAP_LOCATIONS_FRAGMENT:RegisterCallback("StateChange", stateChange)
end

function addon:PostInitList()
end

function addon:Initialize()
	self:InitSettings()
	self:PreInitList()
end

function addon:FirstPlayerActivated()
	self.playerAlliance = GetUnitAlliance("player")
	self:MarkDirty()
	RebuildList()
	self:PostInitList()
end

local function OnAddOnLoaded(event, addonName)
	if addonName == addon.name then
		em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
		addon:Initialize()
	end
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
em:RegisterForEvent(
	addon.name,
	EVENT_PLAYER_ACTIVATED,
	function()
		em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
		addon:FirstPlayerActivated()
	end
)

VOTANS_IMPROVED_LOCATIONS = addon
