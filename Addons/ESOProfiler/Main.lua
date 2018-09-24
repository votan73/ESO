if GetAPIVersion() < 100025 then return end

local addon = {
	name = "ESOProfiler",
}
local em = GetEventManager()
local async = LibStub("LibAsync")
local task = async:Create("ESO_PROFILER")

local function UpdateKeybind()
	if addon.keybindButtonGroup and KEYBIND_STRIP:HasKeybindButtonGroup(addon.keybindButtonGroup) then
		KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.keybindButtonGroup)
	end
end

do
	local orgStartScriptProfiler = StartScriptProfiler
	function StartScriptProfiler()
		if addon.profiling then return end
		addon.newRun = GetGameTimeMilliseconds()
		addon.profiling = true
		UpdateKeybind()
		return orgStartScriptProfiler()
	end
	local orgStopScriptProfiler = StopScriptProfiler
	function StopScriptProfiler()
		if not addon.profiling then return end
		addon.profiling = false
		addon.hasProfile = true
		UpdateKeybind()
		return orgStopScriptProfiler()
	end
end

-- TODO: Someday there will be multiple record types, and they will be delineated by a SCRIPT_PROFILER_RECORD_TYPE enum.
local SCRIPT_PROFILER_RECORD_TYPE_CLOSURE = 1

function addon:GenerateReport()
	if self.lastProfile == self.newRun or self.profiling then return end
	self.lastProfile = self.newRun

	local numRecords = 0

	local recordDataByRecordType =
	{
		[SCRIPT_PROFILER_RECORD_TYPE_CLOSURE] = { },
	}
	self.profile = recordDataByRecordType

	local GetScriptProfilerClosureInfo = GetScriptProfilerClosureInfo
	local function GetOrCreateRecordData(recordType, recordDataIndex)
		local recordData = recordDataByRecordType[recordType]
		-- assert(recordData, "Missing record type")
		if not recordData[recordDataIndex] then
			local data =
			{
				count = 0,
				includeTime = 0,
				includeTimeMin = 1e99,
				includeTimeMax = 0,
				excludeTime = 0,
			}

			if recordType == SCRIPT_PROFILER_RECORD_TYPE_CLOSURE then
				data.name, data.filename, data.lineDefined = GetScriptProfilerClosureInfo(recordDataIndex)
				-- else
				-- assert(false, "Missing record type")
			end
			recordData[recordDataIndex] = data
		end

		return recordData[recordDataIndex]
	end

	local GetScriptProfilerRecordInfo, zo_min, zo_max = GetScriptProfilerRecordInfo, zo_min, zo_max
	local function ParseRecord(frameIndex, recordIndex)
		-- TODO
		local recordType = SCRIPT_PROFILER_RECORD_TYPE_CLOSURE
		--

		local recordDataIndex, startTimeNS, endTimeNS, calledByRecordIndex = GetScriptProfilerRecordInfo(frameIndex, recordIndex)
		local timeMS =(endTimeNS - startTimeNS) * 0.0000001

		local source = GetOrCreateRecordData(recordType, recordDataIndex)
		source.count = source.count + 1
		source.includeTime = source.includeTime + timeMS
		source.excludeTime = source.excludeTime + timeMS
		source.includeTimeMin = zo_min(source.includeTimeMin, timeMS)

		local calledByData
		if calledByRecordIndex then
			-- TODO
			local calledByRecordType = SCRIPT_PROFILER_RECORD_TYPE_CLOSURE
			--
			local calledByRecordDataIndex = GetScriptProfilerRecordInfo(frameIndex, calledByRecordIndex)
			calledByData = GetOrCreateRecordData(calledByRecordType, calledByRecordDataIndex)
			calledByData.excludeTime = calledByData.excludeTime - timeMS
		else
			calledByData = nil
		end
		if source.includeTimeMax < timeMS then
			source.calledBy = calledByData
			source.includeTimeMax = timeMS
		end
	end

	local statusBar = self.control:GetNamedChild("LoadingBar")
	local content = self.control:GetNamedChild("Content")
	local function PrintReport()
		self.numRecords = numRecords
		self:PrintReport()
		statusBar:SetHidden(true)
		content:SetHidden(false)
	end

	local numFrames = GetScriptProfilerNumFrames()
	self.numFrames = numFrames

	statusBar:SetMinMax(0, numFrames)
	statusBar:SetValue(0)
	statusBar:SetHidden(false)
	content:SetHidden(true)

	task:Cancel():For(1, numFrames):Do( function(frameIndex)
		statusBar:SetValue(frameIndex)
		task:For(1, GetScriptProfilerFrameNumRecords(frameIndex)):Do( function(recordIndex)
			ParseRecord(frameIndex, recordIndex)
			numRecords = numRecords + 1
		end )
	end ):Then(PrintReport)
end

function addon:PrintReport()
	local scrollList = self.contentList
	ZO_ScrollList_Clear(scrollList)
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
	local text = self.searchBox:GetText()
	if text == "" then
		task:For(pairs(self.profile)):Do( function(recordType, recordDatas)
			task:For(pairs(recordDatas)):Do( function(recordDataIndex, recordData)
				dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(recordType, recordData)
			end )
		end )
	else
		text = text:lower()
		local zo_plainstrfind = zo_plainstrfind
		local line = tonumber(text)
		task:For(pairs(self.profile)):Do( function(recordType, recordDatas)
			task:For(pairs(recordDatas)):Do( function(recordDataIndex, recordData)
				if zo_plainstrfind(recordData.name:lower(), text) or zo_plainstrfind(recordData.filename:lower(), text) or line == recordData.lineDefined then
					dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(recordType, recordData)
				end
			end )
		end )
	end
	task:Then( function()
		local sortHeaders = self.sortHeaders
		self:ChangeSort(sortHeaders.selectedSortHeader.key, sortHeaders.sortDirection)
	end )
end
----------------------------------

do
	local function AddLine(tooltip, text, color, alignment)
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, alignment, alignment ~= TEXT_ALIGN_LEFT)
	end

	local function AddLineCenter(tooltip, text, color)
		if not color then color = ZO_TOOLTIP_DEFAULT_COLOR end
		AddLine(tooltip, text, color, TEXT_ALIGN_CENTER)
	end

	local function AddLineTitle(tooltip, text, color)
		if not color then color = ZO_SELECTED_TEXT end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontHeader3", r, g, b, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
	end

	local function AddLineSubTitle(tooltip, text, color)
		if not color then color = ZO_SELECTED_TEXT end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontWinH5", r, g, b, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
	end

	local text = { }
	function addon:OnSelectionChanged(previouslySelectedData, selectedData, selectingDuringRebuild)
		if not selectedData or selectingDuringRebuild then
			ClearTooltip(ItemTooltip)
			return
		end

		InitializeTooltip(ItemTooltip, self.control, RIGHT, -5, 0, LEFT)
		ZO_ItemTooltip_SetStolen(ItemTooltip, false)
		local count = selectedData.count
		ZO_ClearNumericallyIndexedTable(text)
		text[#text + 1] = string.format("%s in %s:%i", selectedData.name, selectedData.filename, selectedData.lineDefined)
		text[#text + 1] = ""
		text[#text + 1] = string.format("Time: %.5fms", selectedData.includeTime / count)
		text[#text + 1] = string.format("Fastest: %.5fms", selectedData.includeTimeMin)
		text[#text + 1] = string.format("Slowest %.5fms", selectedData.includeTimeMax)
		text[#text + 1] = string.format("Without sub-calls %.5fms", selectedData.excludeTime / count)
		text[#text + 1] = string.format("%i calls => %f per frame", count, count / self.numFrames)
		AddLineCenter(ItemTooltip, table.concat(text, "\n"))

		if selectedData.excludeTime > 0 and(selectedData.excludeTime / selectedData.includeTime) < 0.5 then
			AddLineCenter(ItemTooltip, "Expensive sub-calls.")
		end
		ZO_ClearNumericallyIndexedTable(text)
		local num = 20
		while num > 0 and selectedData.calledBy do
			selectedData = selectedData.calledBy
			num = num - 1
			text[#text + 1] = string.format("=>%s in |cefefef%s:%i|r", selectedData.name, selectedData.filename, selectedData.lineDefined)
		end
		if #text > 0 then
			AddLine(ItemTooltip, table.concat(text, "\n"), ZO_TOOLTIP_DEFAULT_COLOR, TEXT_ALIGN_LEFT)
		end
		ZO_ClearNumericallyIndexedTable(text)
	end
end

function addon:ShowContextMenu(control)
end

function addon:EndSearch(editBox)
	if editBox:GetText() ~= "" then
		editBox:SetText("")
	end
	editBox:LoseFocus()
	self:PrintReport()
end

function addon:OnSearchEnterKeyPressed(editBox)
	editBox:LoseFocus()
	self:PrintReport()
end
------------------------------------------
function addon:AddKeybind()
	self.keybindButtonGroup = {
		alignment = KEYBIND_STRIP_ALIGN_RIGHT,
		{
			name = function() return GetString(self.profiling and SI_JOURNAL_MENU_ESO_PROFILER_STOP or SI_JOURNAL_MENU_ESO_PROFILER_START) end,
			keybind = "ESO_PROFILER_TOGGLE",
			order = 100,
			callback = function()
				if self.profiling then
					StopScriptProfiler()
					self:GenerateReport()
				else
					StartScriptProfiler()
				end
			end,
		},
	}
	ESO_PROFILER_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWN then
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindButtonGroup)
		elseif newState == SCENE_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindButtonGroup)
		end
	end )
end

function addon:InitializeWindow()
	self.control = ESOProfilerTopLevel
	self.content = self.control:GetNamedChild("Content")
	self.contentList = self.content:GetNamedChild("List")
	self.searchBox = self.content:GetNamedChild("SearchBox")

	local function formatValue(value)
		if value >= 100 then
			return string.format("%.3f", value)
		elseif value >= 10 then
			return string.format("%.4f", value)
		else
			return string.format("%.5f", value)
		end
	end
	local function setupDataRow(rowControl, rowData, scrollList)
		local nameCtl = rowControl:GetNamedChild("Name")
		local includeTimeCtl = rowControl:GetNamedChild("IncludeTime")
		local includeTimeMinCtl = rowControl:GetNamedChild("IncludeTimeMin")
		local includeTimeMaxCtl = rowControl:GetNamedChild("IncludeTimeMax")
		local excludeTimeCtl = rowControl:GetNamedChild("ExcludeTime")
		local countCtl = rowControl:GetNamedChild("Count")

		local count = rowData.count

		nameCtl:SetText(string.format("%s (%s:%d)", rowData.name, rowData.filename, rowData.lineDefined))
		includeTimeCtl:SetText(formatValue(rowData.includeTime / count))
		includeTimeMinCtl:SetText(formatValue(rowData.includeTimeMin))
		includeTimeMaxCtl:SetText(formatValue(rowData.includeTimeMax))
		excludeTimeCtl:SetText(formatValue(rowData.excludeTime / count))
		countCtl:SetText(count)
	end
	ZO_ScrollList_AddDataType(self.contentList, SCRIPT_PROFILER_RECORD_TYPE_CLOSURE, "ESOProfilerRow", 24, setupDataRow)
	ZO_ScrollList_SetTypeSelectable(self.contentList, SCRIPT_PROFILER_RECORD_TYPE_CLOSURE, true)
	ZO_ScrollList_SetDeselectOnReselect(self.contentList, false)
	ZO_ScrollList_EnableSelection(self.contentList, "ZO_ThinListHighlight", function(...) self:OnSelectionChanged(...) end)
	ZO_ScrollList_EnableHighlight(self.contentList, "ZO_ThinListHighlight")

	local sortByHeaderControl = self.control:GetNamedChild("ContentSortBy")
	local sortHeaders = ZO_SortHeaderGroup:New(sortByHeaderControl, true)

	local function OnSortHeaderClicked(key, order)
		self:ChangeSort(key, order)
	end

	sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
	sortHeaders:AddHeadersFromContainer()
	sortHeaders:SelectHeaderByKey("includeTimeMax", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)

	self.sortHeaders = sortHeaders
end

do
	local function name(order)
		if order then
			return function(a, b)
				if a.data.filename == b.data.filename then
					return a.data.name < b.data.name
				else
					return a.data.filename < b.data.filename
				end
			end
		else
			return function(a, b)
				if a.data.filename == b.data.filename then
					return a.data.name > b.data.name
				else
					return a.data.filename > b.data.filename
				end
			end
		end
	end
	local function simple(name, order)
		if order then
			return function(a, b) return a.data[name] < b.data[name] end
		else
			return function(a, b) return a.data[name] > b.data[name] end
		end
	end

	function addon:ChangeSort(key, order)
		-- order = true => ASC
		local f
		if key == "name" then
			f = name(order)
		elseif key == "includeTime" then
			f = simple(key, order)
		elseif key == "includeTimeMin" then
			f = simple(key, order)
		elseif key == "includeTimeMax" then
			f = simple(key, order)
		elseif key == "excludeTime" then
			f = simple(key, order)
		elseif key == "count" then
			f = simple(key, order)
		end
		if f then
			local scrollList = self.contentList
			local dataList = ZO_ScrollList_GetDataList(scrollList)
			table.sort(dataList, f)
			ZO_ScrollList_Commit(scrollList)
		end
	end
end

function addon:CreateJournalTab()
	local sceneName = "eso_profiler"
	ESO_PROFILER_FRAGMENT = ZO_HUDFadeSceneFragment:New(self.control)
	ESO_PROFILER_SCENE = ZO_Scene:New(sceneName, SCENE_MANAGER)
	ESO_PROFILER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
	ESO_PROFILER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
	ESO_PROFILER_SCENE:AddFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_FRAGMENT)
	-- ESO_PROFILER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
	ESO_PROFILER_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
	ESO_PROFILER_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
	-- ESO_PROFILER_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
	ESO_PROFILER_SCENE:AddFragment(TITLE_FRAGMENT)
	ESO_PROFILER_SCENE:AddFragment(JOURNAL_TITLE_FRAGMENT)
	ESO_PROFILER_SCENE:AddFragment(CODEX_WINDOW_SOUNDS)
	ESO_PROFILER_SCENE:AddFragment(ESO_PROFILER_FRAGMENT)

	SYSTEMS:RegisterKeyboardRootScene(sceneName, ESO_PROFILER_SCENE)

	local sceneGroupInfo = MAIN_MENU_KEYBOARD.sceneGroupInfo["journalSceneGroup"]
	local iconData = sceneGroupInfo.menuBarIconData
	iconData[#iconData + 1] = {
		categoryName = SI_JOURNAL_MENU_ESO_PROFILER,
		descriptor = sceneName,
		normal = "esoui/art/treeicons/collection_indexicon_service_up.dds",
		pressed = "esoui/art/treeicons/collection_indexicon_service_down.dds",
		highlight = "esoui/art/treeicons/collection_indexicon_service_over.dds",
	}
	local sceneGroupBarFragment = sceneGroupInfo.sceneGroupBarFragment
	ESO_PROFILER_SCENE:AddFragment(sceneGroupBarFragment)

	local scenegroup = SCENE_MANAGER:GetSceneGroup("journalSceneGroup")
	scenegroup:AddScene(sceneName)
	MAIN_MENU_KEYBOARD:AddRawScene(sceneName, MENU_CATEGORY_JOURNAL, MAIN_MENU_KEYBOARD.categoryInfo[MENU_CATEGORY_JOURNAL], "journalSceneGroup")
end

function addon:Initialize()
	self:InitializeWindow()
	self:CreateJournalTab()
	self:AddKeybind()

	ESO_PROFILER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_SHOWING then
			self:GenerateReport()
		elseif newState == SCENE_HIDING then
			ClearTooltip(ItemTooltip)
		end
	end )
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:Initialize()
	-- addon:InitSettings()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

StartScriptProfiler()
em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, function()
	em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	task:Delay(2000, StopScriptProfiler)
end )

ESO_PROFILER = addon