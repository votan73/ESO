local addon = {
	name = "VotansImprovedQuests"
}

local em = GetEventManager()
local QUEST_TYPE_ID = 1
local LOCATION_TYPE_ID = 2

local headerColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
local selectedColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))

local iconAssisted = "esoui/art/compass/quest_icon_assisted.dds"
local iconCrafting = "esoui/art/treeicons/gamepad/achievement_categoryicon_crafting.dds"
local iconRepeatable = "esoui/art/compass/repeatablequest_assistedareapin.dds"
local iconOtherZone = "esoui/art/compass/quest_icon_door_assisted.dds"
local iconOthers = "esoui/art/tutorial/gamepad/gp_lfg_world.dds"

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
		highlight:SetTexture("esoui/art/miscellaneous/listitem_highlight.dds")
		if hidden then
			highlight.animation:PlayBackward()
		else
			highlight.animation:PlayForward()
		end
	end
end

function addon:ShowLevel(levelLabel, level)
	if level and self.account.showLevels then
		levelLabel:SetText(level)
	else
		levelLabel:SetText("")
	end
end

do
	local function onMouseEnter(rowControl)
		HideRowHighlight(rowControl, false)
		ZO_WorldMapQuestHeader_OnMouseEnter(rowControl)
	end
	local function onMouseExit(rowControl)
		ZO_WorldMapQuestHeader_OnMouseExit(rowControl)
		HideRowHighlight(rowControl, true)
	end
	local function NoOp()
	end
	local function ShowQuestOnMap(rowControl)
		local orgZO_Alert = ZO_Alert
		ZO_Alert = NoOp
		ZO_WorldMap_ShowQuestOnMap(rowControl.data.questIndex)
		WORLD_MAP_QUEST_BREADCRUMBS:RefreshQuest(rowControl.data.questIndex)
		ZO_Alert = orgZO_Alert
	end
	local function onMouseClick(rowControl, button, upInside)
		WORLD_MAP_QUESTS:QuestHeader_OnClicked(rowControl, button)
		if addon.account.alwaysShowOnMap then
			ShowQuestOnMap(rowControl)
		end
		WORLD_MAP_QUESTS:RefreshHeaders()
	end
	local function onMouseDoubleClick(rowControl, button, upInside)
		WORLD_MAP_QUESTS:QuestHeader_OnClicked(rowControl, button)
		ShowQuestOnMap(rowControl)
		WORLD_MAP_QUESTS:RefreshHeaders()
	end

	function addon:SetupQuest(rowControl, rowData)
		local nameLabel = rowControl:GetNamedChild("Name")
		nameLabel:SetText(rowData.name)
		nameLabel:SetColor(selectedColor:UnpackRGB())

		-- Assisted State
		local isAssisted = FOCUSED_QUEST_TRACKER:IsTrackTypeAssisted(TRACK_TYPE_QUEST, rowData.questIndex)
		local icon = rowControl:GetNamedChild("AssistedIcon")
		icon:SetHidden(not isAssisted)

		rowControl.data = rowData

		local levelLabel = rowControl:GetNamedChild("Level")
		self:ShowLevel(levelLabel, rowData.level)

		rowControl:SetHeight(25)
		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExit)
		rowControl:SetHandler("OnMouseUp", onMouseClick)
		rowControl:SetHandler("OnMouseDoubleClick", onMouseDoubleClick)
	end
end

function addon:SetupQuestType(rowControl, rowData)
	local locationLabel = rowControl:GetNamedChild("Location")
	local texture = rowControl:GetNamedChild("Texture")

	texture:ClearAnchors()
	texture:SetDimensions(40, 40)
	texture:SetAnchor(BOTTOMLEFT)
	if rowData.zoneIndex then
		locationLabel:SetText(ZO_CachedStrFormat("<<!AC:1>>", GetZoneNameByIndex(rowData.zoneIndex)))
	elseif rowData.text then
		locationLabel:SetText(ZO_CachedStrFormat(GetString(rowData.text)))
	end
	texture:SetTexture(rowData.icon)
	rowControl:SetHeight(40)
	locationLabel:SetColor(headerColor:UnpackRGB())
end

local function HookQuests()
	WORLD_MAP_QUESTS_FRAGMENT:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				WORLD_MAP_QUESTS:LayoutList()
			end
		end
	)
	GAMEPAD_WORLD_MAP_QUESTS_FRAGMENT:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				GAMEPAD_WORLD_MAP_QUESTS:LayoutList()
			end
		end
	)
	CALLBACK_MANAGER:RegisterCallback(
		"OnWorldMapChanged",
		function()
			local gamepadMode = IsInGamepadPreferredMode()
			if (gamepadMode and GAMEPAD_WORLD_MAP_QUESTS_FRAGMENT or WORLD_MAP_QUESTS_FRAGMENT):IsShowing() then
				local questList = gamepadMode and GAMEPAD_WORLD_MAP_QUESTS or WORLD_MAP_QUESTS
				questList:LayoutList()
			end
		end
	)

	local function CreateQuestsList(AddQuests)
		local currentZoneIndex = GetCurrentMapZoneIndex()
		AddQuests(
			{zoneIndex = currentZoneIndex, icon = iconAssisted},
			function(rowData)
				local questIndex = rowData.questIndex
				local zoneIndex = GetJournalQuestStartingZone(questIndex)
				return zoneIndex > 1 and zoneIndex <= 2147483647 and
					(IsJournalQuestInCurrentMapZone(questIndex) or zoneIndex == currentZoneIndex)
			end
		)
		AddQuests(
			{text = SI_CRAFTING_PERFORM_FREE_CRAFT, icon = iconCrafting},
			function(rowData)
				return QUEST_TYPE_CRAFTING == rowData.questType
			end
		)
		AddQuests(
			{text = SI_MAIN_MENU_GUILDS, icon = iconRepeatable},
			function(rowData)
				return QUEST_TYPE_GUILD == rowData.questType and INSTANCE_DISPLAY_TYPE_NONE == rowData.displayType
			end
		)
		if not addon.account.consolidateOtherZones then
			local nameToIndex, names = {}, {}
			local GetJournalQuestStartingZone, GetZoneNameByIndex = GetJournalQuestStartingZone, GetZoneNameByIndex
			for questIndex = 1, MAX_JOURNAL_QUESTS do
				local currentIndex = GetJournalQuestStartingZone(questIndex)
				if currentIndex > 1 then
					local name = GetZoneNameByIndex(currentIndex)
					if not nameToIndex[name] then
						nameToIndex[name] = currentIndex
						names[#names + 1] = name
					end
				end
			end
			table.sort(names)
			for i = 1, #names do
				local currentIndex = nameToIndex[names[i]]
				AddQuests(
					{zoneIndex = currentIndex, icon = iconOtherZone},
					function(rowData)
						local questIndex = rowData.questIndex
						local zoneIndex = GetJournalQuestStartingZone(questIndex)
						return zoneIndex > 1 and zoneIndex <= 2147483647 and zoneIndex == currentIndex
					end
				)
			end
		end
		AddQuests(
			{text = SI_VOTANSIMPROVEDQUESTS_OTHER_ZONES, icon = iconOtherZone},
			function(rowData)
				local questIndex = rowData.questIndex
				local zoneIndex = GetJournalQuestStartingZone(questIndex)
				return zoneIndex > 1 and zoneIndex <= 2147483647 and zoneIndex ~= currentZoneIndex
			end
		)
		AddQuests(
			{text = 0, icon = iconOthers},
			function(rowData)
				return true
			end
		)
	end

	local function GetQuests(self)
		local quests = self.data.masterList
		ZO_ClearNumericallyIndexedTable(quests)

		local GetJournalQuestInfo, IsValidQuestIndex = GetJournalQuestInfo, IsValidQuestIndex
		for questIndex = 1, MAX_JOURNAL_QUESTS do
			if IsValidQuestIndex(questIndex) then
				local name, _, _, _, _, _, _, level, _, questType, displayType = GetJournalQuestInfo(questIndex)

				quests[#quests + 1] = {
					questIndex = questIndex,
					name = name,
					level = level,
					questType = questType,
					displayType = displayType
				}
			end
		end
		table.sort(quests, self.data.CompareQuests)
		return {unpack(quests)}
	end

	local function DoLayout()
		local scrollList = addon.QuestsScrollList
		local dataList = ZO_ScrollList_GetDataList(scrollList)

		ZO_ScrollList_Clear(scrollList)
		local IsJournalQuestInCurrentMapZone, GetJournalQuestStartingZone, IsValidQuestIndex, ZO_ScrollList_CreateDataEntry =
			IsJournalQuestInCurrentMapZone,
			GetJournalQuestStartingZone,
			IsValidQuestIndex,
			ZO_ScrollList_CreateDataEntry

		local quests = GetQuests(WORLD_MAP_QUESTS)
		local num = #quests

		local function AddQuests(captionData, filter)
			local caption = false
			for i = 1, num do
				if quests[i] and filter(quests[i]) then
					if not caption then
						caption = true
						dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(LOCATION_TYPE_ID, captionData, 1)
					end
					dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(QUEST_TYPE_ID, quests[i], 1)
					quests[i] = nil
				end
			end
		end
		CreateQuestsList(AddQuests)

		ZO_ScrollList_Commit(scrollList)
	end
	function WORLD_MAP_QUESTS:LayoutList()
		if WORLD_MAP_QUESTS_FRAGMENT:IsShowing() then
			addon.QuestsScrollList:SetHidden(not ZO_WorldMapQuestsData_Singleton.ShouldMapShowQuestsInList())
			self:RefreshNoQuestsLabel()
			DoLayout()
		end
	end
	function WORLD_MAP_QUESTS:RefreshHeaders()
		if WORLD_MAP_QUESTS_FRAGMENT:IsShowing() then
			ZO_ScrollList_RefreshVisible(addon.QuestsScrollList)
		end
	end
	do
		local identifier = "ZO_WorldMapQuests_RefreshNoQuestsLabel"
		function ZO_WorldMapQuests_Shared:RefreshNoQuestsLabel()
			em:UnregisterForUpdate(identifier)
			if ZO_WorldMapQuestsData_Singleton.ShouldMapShowQuestsInList() then
				self.noQuestsLabel:SetHidden(true)
				local function Check()
					em:UnregisterForUpdate(identifier)
					if #self.data.masterList == 0 then
						self.noQuestsLabel:SetHidden(false)
						self.noQuestsLabel:SetText(GetString(SI_WORLD_MAP_NO_QUESTS))
					end
				end
				em:RegisterForUpdate(identifier, 150, Check)
			else
				self.noQuestsLabel:SetHidden(false)
				self.noQuestsLabel:SetText(GetString(SI_WORLD_MAP_DOESNT_SHOW_QUESTS_DISTANCE))
			end
		end
	end

	---------------------------------------------
	do
		local function equalityFunction(data1, data2)
			return data1.questInfo.questIndex == data2.questInfo.questIndex
		end

		local function SetupQuestRow(...)
			local control, entryData = select(1, ...)
			local levelLabel = control:GetNamedChild("SubLabel1")
			addon:ShowLevel(levelLabel, entryData.questLevel)
			control.label:SetWidth(ZO_GAMEPAD_DEFAULT_LIST_ENTRY_WIDTH_AFTER_INDENT - levelLabel:GetWidth())
			ZO_SharedGamepadEntry_OnSetup(...)
			levelLabel:SetHidden(false)
		end
		GAMEPAD_WORLD_MAP_QUESTS.questList:AddDataTemplate(
			"VotansGamepadQuestRow",
			SetupQuestRow,
			ZO_GamepadMenuEntryTemplateParametricListFunction,
			equalityFunction
		)
	end

	function GAMEPAD_WORLD_MAP_QUESTS:RefreshHeaders()
		if GAMEPAD_WORLD_MAP_QUESTS_FRAGMENT:IsShowing() then
			self:LayoutList()
		end
	end

	local unselectedColor = selectedColor:Lerp(ZO_ColorDef:New(0, 0, 0), 0.25)
	local function GoAssisted(rowData)
		return rowData.isAssisted
	end
	function GAMEPAD_WORLD_MAP_QUESTS:LayoutList()
		if GAMEPAD_WORLD_MAP_QUESTS_FRAGMENT:IsShowing() then
			self.questList:Clear()
			ZO_ClearTable(self.entriesByIndex)
			self.assistedEntryData = nil

			local questJournalObject = SYSTEMS:GetObject("questJournal")
			local quests = GetQuests(self)
			local num = #quests

			local template =
				addon.account.showLevels and "VotansGamepadQuestRow" or "ZO_GamepadSubMenuEntryTemplateWithStatusLowercase42"

			local function AddQuests(captionData, filter)
				local FOCUSED_QUEST_TRACKER, GetJournalQuestLevel, ZO_GamepadEntryData =
					FOCUSED_QUEST_TRACKER,
					GetJournalQuestLevel,
					ZO_GamepadEntryData
				for i = 1, num do
					local srcData = quests[i]
					if srcData and filter(srcData) then
						local questIndex = srcData.questIndex
						-- local questIcon = questJournalObject:GetIconTexture(srcData.questType, srcData.displayType)

						local entryData = ZO_GamepadEntryData:New(srcData.name, captionData.icon)
						self.entriesByIndex[questIndex] = entryData

						entryData.questInfo = srcData

						local isAssisted = FOCUSED_QUEST_TRACKER:IsTrackTypeAssisted(TRACK_TYPE_QUEST, questIndex)
						entryData.isAssisted = isAssisted
						if isAssisted then
							self.assistedEntryData = entryData
						end

						local questLevel = GetJournalQuestLevel(questIndex)
						entryData.questLevel = questLevel

						entryData:SetNameColors(selectedColor, unselectedColor)
						entryData:SetFontScaleOnSelection(false)

						self.questList:AddEntry(template, entryData)
						quests[i] = nil
					end
				end
			end
			if ZO_WorldMapQuestsData_Singleton.ShouldMapShowQuestsInList() then
				CreateQuestsList(AddQuests)
			end

			self.questList:Commit()

			if self.assistedEntryData then
				self.questList:EnableAnimation(false)
				self.questList:SetSelectedDataByEval(GoAssisted)
				self.questList:EnableAnimation(true)
			end

			self:RefreshNoQuestsLabel()
		end
	end
end

local function HookAlwaysShowQuest()
	local function AlwaysShowQuest(questIndex)
		return true
	end
	local orgShouldMapShowQuestsInList = ZO_WorldMapQuestsData_Singleton.ShouldMapShowQuestsInList
	local function newShouldMapShowQuestsInList(...)
		if addon.account.alwaysShowQuests then
			return AlwaysShowQuest(...)
		end
		return orgShouldMapShowQuestsInList(...)
	end
	ZO_WorldMapQuestsData_Singleton.ShouldMapShowQuestsInList = newShouldMapShowQuestsInList
end

do
	local function AddLine(tooltip, text, color, alignment)
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, alignment, alignment ~= TEXT_ALIGN_LEFT)
	end

	local function AddLineCenter(tooltip, text, color)
		if not color then
			color = ZO_TOOLTIP_DEFAULT_COLOR
		end
		AddLine(tooltip, text, color, TEXT_ALIGN_CENTER)
	end

	local function AddLineTitle(tooltip, text, color)
		if not color then
			color = ZO_SELECTED_TEXT
		end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontHeader3", r, g, b, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
	end

	local function AddLineSubTitle(tooltip, text, color)
		if not color then
			color = ZO_SELECTED_TEXT
		end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontWinH5", r, g, b, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
	end

	local orgSetQuest = ZO_MapQuestDetailsTooltip.SetQuest
	function ZO_MapQuestDetailsTooltip.SetQuest(...)
		local self, questIndex = ...

		local name, _, _, _, _, _, _, _, _, questType, displayType = GetJournalQuestInfo(questIndex)
		local zoneName, objectiveName, zoneIndex = GetJournalQuestLocationInfo(questIndex)
		if zoneIndex > 1 and zoneIndex <= 2147483647 then
			zoneName = GetZoneNameByIndex(zoneIndex)
		else
			zoneIndex = GetJournalQuestStartingZone(questIndex)
			if zoneIndex > 1 and zoneIndex <= 2147483647 then
				zoneName = GetZoneNameByIndex(zoneIndex)
			end
		end
		AddLineTitle(self, name)
		self:AddVerticalPadding(-9)
		if objectiveName and #objectiveName > 0 then
			AddLineSubTitle(
				self,
				zo_strformat(SI_VOTANSIMPROVEDQUESTS_LOCATION_ON_MAP, objectiveName, zoneName),
				ZO_TOOLTIP_DEFAULT_COLOR
			)
		else
			AddLineSubTitle(self, zo_strformat(SI_ZONE_NAME, zoneName), ZO_TOOLTIP_DEFAULT_COLOR)
		end
		self:AddVerticalPadding(-9)
		ZO_ItemIconTooltip_OnAddGameData(self, TOOLTIP_GAME_DATA_DIVIDER)

		orgSetQuest(...)
	end
end

function addon:SetupControls()
	ZO_WorldMapQuestsPane:SetHidden(true)
	local list = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)VotansQuestsList", ZO_WorldMapQuests, "ZO_ScrollList")
	self.QuestsScrollList = list
	list:SetAnchorFill()
	list.mode = 2

	ZO_ScrollList_AddDataType(
		list,
		QUEST_TYPE_ID,
		"VotansQuestRow",
		25,
		function(...)
			addon:SetupQuest(...)
		end
	)
	ZO_ScrollList_AddDataType(
		list,
		LOCATION_TYPE_ID,
		"VotansQuestHeaderRow",
		40,
		function(...)
			addon:SetupQuestType(...)
		end
	)
end

function addon:InitSettings()
	local defaults = {
		showLevels = false,
		sortBy = SORT_LOCATION_NAME,
		alwaysShowQuests = false,
		alwaysShowOnMap = false,
		consolidateOtherZones = true
	}
	self.account = ZO_SavedVars:NewAccountWide("VotansImprovedQuests_Data", 1, nil, defaults)

	local LAM2 = LibAddonMenu2
	local panelData = {
		type = "panel",
		name = "Improved Quests",
		author = "votan",
		version = "1.3.2",
		registerForRefresh = false,
		registerForDefaults = true,
		website = "http://www.esoui.com/downloads/info1523-VotansImprovedQuests.html"
	}
	LAM2:RegisterAddonPanel(addon.name, panelData)

	local optionsTable = {
		{
			-- Show Levels
			type = "checkbox",
			name = GetString(SI_VOTANSIMPROVEDQUESTS_SHOW_LEVELS),
			tooltip = nil,
			getFunc = function()
				return self.account.showLevels
			end,
			setFunc = function(value)
				if self.account.showLevels ~= value then
					self.account.showLevels = value
					ZO_ScrollList_RefreshVisible(self.QuestsScrollList)
				end
			end,
			width = "full",
			default = defaults.showLevels
		},
		{
			-- Show Levels
			type = "checkbox",
			name = GetString(SI_VOTANSIMPROVEDQUESTS_ALWAYS_SHOW_QUESTS),
			tooltip = nil,
			getFunc = function()
				return self.account.alwaysShowQuests
			end,
			setFunc = function(value)
				if self.account.alwaysShowQuests ~= value then
					self.account.alwaysShowQuests = value
					GAMEPAD_WORLD_MAP_QUESTS:LayoutList()
					WORLD_MAP_QUESTS:LayoutList()
				end
			end,
			width = "full",
			default = defaults.alwaysShowQuests
		},
		{
			-- Show Levels
			type = "checkbox",
			name = GetString(SI_VOTANSIMPROVEDQUESTS_ALWAYS_SHOW_ON_MAP),
			tooltip = nil,
			getFunc = function()
				return self.account.alwaysShowOnMap
			end,
			setFunc = function(value)
				self.account.alwaysShowOnMap = value
			end,
			width = "full",
			default = defaults.alwaysShowOnMap
		},
		{
			-- Consolidate Other Zones
			type = "checkbox",
			name = GetString(SI_VOTANSIMPROVEDQUESTS_CONSOLIDATE_OTHER_ZONES),
			tooltip = nil,
			getFunc = function()
				return self.account.consolidateOtherZones
			end,
			setFunc = function(value)
				self.account.consolidateOtherZones = value
			end,
			width = "full",
			default = defaults.consolidateOtherZones
		}
	}

	LAM2:RegisterOptionControls(addon.name, optionsTable)
end

function addon:Initialize()
	self:SetupControls()
	self:InitSettings()
	HookAlwaysShowQuest()
	HookQuests()
end

local function OnAddOnLoaded(event, addonName)
	if addonName == addon.name then
		em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
		addon:Initialize()
	end
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
