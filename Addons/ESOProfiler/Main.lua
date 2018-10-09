if GetAPIVersion() < 100025 then return end

local addon = {
	name = "ESOProfiler",
}
local em = GetEventManager()
local async = LibStub("LibAsync")
local task = async:Create("ESO_PROFILER")

do
	local function CaptureFrameMetrics()
		local fps = tostring(math.floor(GetFramerate())*100)
		local latency = tostring(GetLatency())
		local memory = tostring(collectgarbage("count")*1024)
		local name = string.format("statsF%sL%sM%s", fps, latency, memory)
		LoadString("", name)()
	end

	local function UpdateKeybind()
		if addon.keybindButtonGroup and KEYBIND_STRIP:HasKeybindButtonGroup(addon.keybindButtonGroup) then
			KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.keybindButtonGroup)
		end
	end

	local orgStartScriptProfiler = StartScriptProfiler
	function StartScriptProfiler()
		if addon.profiling then return end
		addon.newRun = GetGameTimeMilliseconds()
		addon.startTime = GetTimeStamp()
		addon.profiling = true
		EVENT_MANAGER:RegisterForUpdate(addon.name, 0, CaptureFrameMetrics)
		UpdateKeybind()
		d("Start profiler....")
		return orgStartScriptProfiler()
	end
	local orgStopScriptProfiler = StopScriptProfiler
	function StopScriptProfiler()
		EVENT_MANAGER:UnregisterForUpdate(addon.name)
		addon.profiling = false
		UpdateKeybind()
		d("Profiler stopped ....")
		return orgStopScriptProfiler()
	end
end

-- TODO: Someday there will be multiple record types, and they will be delineated by a SCRIPT_PROFILER_RECORD_TYPE enum.
local SCRIPT_PROFILER_RECORD_TYPE_CLOSURE = 1
local CLOSURE_NAME_INDEX = 1
local CLOSURE_FILE_INDEX = 2
local CLOSURE_LINE_INDEX = 3

function addon:GenerateReport()
	if self.lastProfile == self.newRun or self.profiling then return end
	self.lastProfile = self.newRun

	local statusBar = self.control:GetNamedChild("LoadingBar")
	local content = self.control:GetNamedChild("Content")
	local function PrintReport()
		self:PrintReport()
		statusBar:SetHidden(true)
		content:SetHidden(false)
	end

	local _, upTime = GetScriptProfilerRecordInfo(1, 1)
	local profilerData = self.ProfilerData:New(self.startTime, upTime)
	self.profilerData = profilerData

	local numFrames = GetScriptProfilerNumFrames()
	self.numFrames = numFrames

	statusBar:SetMinMax(0, numFrames)
	statusBar:SetValue(0)
	statusBar:SetHidden(false)
	content:SetHidden(true)

	task:Cancel():For(1, numFrames):Do( function(frameIndex)
		statusBar:SetValue(frameIndex)
		task:For(1, GetScriptProfilerFrameNumRecords(frameIndex)):Do( function(recordIndex)
			profilerData:ProcessRecord(frameIndex, recordIndex)
		end )
	end ):Then(PrintReport)
end

function addon:PrintReport()
	local scrollList = self.contentList
	ZO_ScrollList_Clear(scrollList)
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
	local text = self.searchBox:GetText():lower()
	local line = tonumber(text)
	task:For(pairs(self.profilerData:GetClosureInfoList())):Do( function(recordDataIndex, closure)
		if text == "" or line == closure.info[CLOSURE_LINE_INDEX] or zo_plainstrfind(closure.info[CLOSURE_NAME_INDEX]:lower(), text) or zo_plainstrfind(closure.info[CLOSURE_FILE_INDEX]:lower(), text) then
			dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(SCRIPT_PROFILER_RECORD_TYPE_CLOSURE, { closure = closure })
		end
	end )
	task:Then( function()
		local sortHeaders = self.sortHeaders
		self:ChangeSort(sortHeaders.selectedSortHeader.key, sortHeaders.sortDirection)
	end )
end

function addon:Export()
	if (self.profilerData) then
		local content = self.control:GetNamedChild("Content")
		content:SetHidden(true)
		-- we reload ui anyway
		local loading = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Loading", self.control, "ZO_Loading")
		loading:SetAnchor(CENTER)
		ZO_Loading_Initialize(loading, "Exporting ...")
		loading:Show()

		task:Call( function(task)
			ESOProfiler_Export = self.profilerData:Export(task)
		end ):Then( function() return ReloadUI() end)
	end
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

	local text = { }
	function addon:OnSelectionChanged(previouslySelectedData, selectedData, selectingDuringRebuild)
		if not selectedData or selectingDuringRebuild then
			ClearTooltip(ItemTooltip)
			return
		end

		InitializeTooltip(ItemTooltip, self.control, RIGHT, -5, 0, LEFT)
		ZO_ItemTooltip_SetStolen(ItemTooltip, false)
		local closure = selectedData.closure
		local count = closure.callCount
		ZO_ClearNumericallyIndexedTable(text)
		text[#text + 1] = string.format("%s in %s:%i", closure.info[CLOSURE_NAME_INDEX], closure.info[CLOSURE_FILE_INDEX], closure.info[CLOSURE_LINE_INDEX])
		text[#text + 1] = ""
		text[#text + 1] = string.format("wall-time: %.3fµs / avg: %.3fµs", closure.wallTime, closure.wallTime / count)
		text[#text + 1] = string.format("self-time: %.3fus / avg: %.3fµs", closure.selfTime, closure.selfTime / count)
		text[#text + 1] = string.format("slowest %.3fµs / fastest: %.3fµs", closure.maxTime, closure.minTime)
		text[#text + 1] = string.format("%i calls => %f per frame", count, count / self.numFrames)
		AddLineCenter(ItemTooltip, table.concat(text, "\n"))

		if closure.selfTime > 0 and (closure.selfTime / closure.wallTime) < 0.5 then
			AddLineCenter(ItemTooltip, "Expensive sub-calls.")
		end
		ZO_ClearNumericallyIndexedTable(text)

		text[#text + 1] = "Slowest run callstack:"
		local num = 20
		local stackId = closure.slowestRun
		local profilerData = self.profilerData
		local parent
		while num > 0 and stackId and stackId > 0 do
			parent, stackId = profilerData:GetClosureByStackId(stackId)
			num = num - 1
			text[#text + 1] = string.format("%s (|cefefef%s:%i|r)", parent.info[CLOSURE_NAME_INDEX], parent.info[CLOSURE_FILE_INDEX], parent.info[CLOSURE_LINE_INDEX])
		end

		AddLine(ItemTooltip, table.concat(text, "\n"), ZO_TOOLTIP_DEFAULT_COLOR, TEXT_ALIGN_LEFT)
	end
	ZO_ClearNumericallyIndexedTable(text)
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
		return string.format("%d", value)
	end
	local function setupDataRow(rowControl, rowData, scrollList)
		local nameCtl = rowControl:GetNamedChild("Name")
		local includeTimeCtl = rowControl:GetNamedChild("IncludeTime")
		local includeTimeMinCtl = rowControl:GetNamedChild("IncludeTimeMin")
		local includeTimeMaxCtl = rowControl:GetNamedChild("IncludeTimeMax")
		local excludeTimeCtl = rowControl:GetNamedChild("ExcludeTime")
		local countCtl = rowControl:GetNamedChild("Count")

		local closure = rowData.closure
		nameCtl:SetText(string.format("%s (%s:%d)", closure.info[CLOSURE_NAME_INDEX], closure.info[CLOSURE_FILE_INDEX], closure.info[CLOSURE_LINE_INDEX]))
		includeTimeCtl:SetText(formatValue(closure.wallTime))
		includeTimeMinCtl:SetText(formatValue(closure.minTime))
		includeTimeMaxCtl:SetText(formatValue(closure.maxTime))
		excludeTimeCtl:SetText(formatValue(closure.selfTime))
		countCtl:SetText(closure.callCount)
	end
	ZO_ScrollList_AddDataType(self.contentList, SCRIPT_PROFILER_RECORD_TYPE_CLOSURE, "ESOProfilerRow", 24, setupDataRow)
	ZO_ScrollList_SetTypeSelectable(self.contentList, SCRIPT_PROFILER_RECORD_TYPE_CLOSURE, true)
	ZO_ScrollList_SetDeselectOnReselect(self.contentList, true)
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
				local infoA = a.data.closure.info
				local infoB = b.data.closure.info
				if infoA[CLOSURE_FILE_INDEX] == infoB[CLOSURE_FILE_INDEX] then
					return infoA[CLOSURE_NAME_INDEX] < infoB[CLOSURE_NAME_INDEX]
				else
					return infoA[CLOSURE_FILE_INDEX] < infoB[CLOSURE_FILE_INDEX]
				end
			end
		else
			return function(a, b)
				local infoA = a.data.closure.info
				local infoB = b.data.closure.info
				if infoA[CLOSURE_FILE_INDEX] == infoB[CLOSURE_FILE_INDEX] then
					return infoA[CLOSURE_NAME_INDEX] > infoB[CLOSURE_NAME_INDEX]
				else
					return infoA[CLOSURE_FILE_INDEX] > infoB[CLOSURE_FILE_INDEX]
				end
			end
		end
	end
	local function simple(name, order)
		if order then
			return function(a, b) return a.data.closure[name] < b.data.closure[name] end
		else
			return function(a, b) return a.data.closure[name] > b.data.closure[name] end
		end
	end

	function addon:ChangeSort(key, order)
		-- order = true => ASC
		local f
		if key == "name" then
			f = name(order)
		elseif key == "includeTime" then
			f = simple("wallTime", order)
		elseif key == "includeTimeMin" then
			f = simple("minTime", order)
		elseif key == "includeTimeMax" then
			f = simple("maxTime", order)
		elseif key == "excludeTime" then
			f = simple("selfTime", order)
		elseif key == "count" then
			f = simple("callCount", order)
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
	-- clear last export on load to prevent longer loading times due to the huge amount of data
	ESOProfiler_Export = ESO_PROFILER.GetEmptySaveData(0, 0)
	-- addon:InitSettings()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

StartScriptProfiler()
em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, function()
	em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	task:Delay(2000, StopScriptProfiler)
end )

ESO_PROFILER = addon
