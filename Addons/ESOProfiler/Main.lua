local legacy = GetAPIVersion() < 100027

-- ToDo: Remove
if legacy then
	SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE = 1
end

local addon = {
	name = "ESOProfiler",
}
local em = GetEventManager()
local async = LibStub("LibAsync")
local task = async:Create("ESO_PROFILER")
local extrasFragmentGroup

do
	local function CaptureFrameMetrics()
		local fps = tostring(math.floor(GetFramerate()) * 100)
		local latency = tostring(GetLatency())
		local memory = tostring(collectgarbage("count") * 1024)
		local name = string.format("statsF%sL%sM%s", fps, latency, memory)
		if legacy then
			LoadString("", name)()
		else
			RecordScriptProfilerUserEvent(name)
		end
	end

	local function UpdateKeybind()
		if addon.keybindButtonGroupRight and KEYBIND_STRIP:HasKeybindButtonGroup(addon.keybindButtonGroupRight) then
			KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.keybindButtonGroupRight)
		end
	end

	local orgStartScriptProfiler = StartScriptProfiler
	function StartScriptProfiler()
		if addon.profiling then return end
		addon.newRun = GetGameTimeMilliseconds()
		addon.startTime = GetTimeStamp()
		addon.profiling = true
		EVENT_MANAGER:RegisterForUpdate(addon.name, 500, CaptureFrameMetrics)
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

local CLOSURE_NAME_INDEX = 1
local CLOSURE_FILE_INDEX = 2
local CLOSURE_LINE_INDEX = 3

function addon:GenerateReport()
	if self.lastProfile == self.newRun or self.profiling then return end
	self.lastProfile = self.newRun

	local statusBar = self.statusBar
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

	-- at 100fps this are 300s = 5min. at 60fps 500s ~ 8min
	task:Cancel():For(math.max(1, numFrames - 30000), numFrames):Do( function(frameIndex)
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
	local function doStep(recordDataIndex, recordDataType, closure)
		if text == "" or line == closure.info[CLOSURE_LINE_INDEX] or zo_plainstrfind(closure.info[CLOSURE_NAME_INDEX]:lower(), text) or zo_plainstrfind(closure.info[CLOSURE_FILE_INDEX]:lower(), text) then
			dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(recordDataType, { closure = closure })
		end
	end
	local function perType(recordDataType, recordTable)
		task:For(pairs(recordTable)):Do( function(recordDataIndex, closure) doStep(recordDataIndex, recordDataType, closure) end)
	end
	task:For(pairs(self.profilerData:GetClosureInfoList())):Do(perType)
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
		self.selectedData = selectedData
		if not selectedData or selectingDuringRebuild then
			ClearTooltip(ItemTooltip)
			return
		end

		InitializeTooltip(ItemTooltip, self.control, RIGHT, -5, 0, LEFT)
		ZO_ItemTooltip_SetStolen(ItemTooltip, false)
		local closure = selectedData.closure
		local count = closure.callCount
		ZO_ClearNumericallyIndexedTable(text)
		if closure.recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE then
			text[#text + 1] = string.format("%s in %s:%i", closure.info[CLOSURE_NAME_INDEX], closure.info[CLOSURE_FILE_INDEX], closure.info[CLOSURE_LINE_INDEX])
		else
			text[#text + 1] = string.format("%s (%s)", closure.info[CLOSURE_NAME_INDEX], closure.info[CLOSURE_FILE_INDEX])
		end
		text[#text + 1] = ""
		text[#text + 1] = string.format("wall-time: %.3fµs / avg: %.3fµs", closure.wallTime, closure.wallTime / count)
		text[#text + 1] = string.format("self-time: %.3fµs / avg: %.3fµs", closure.selfTime, closure.selfTime / count)
		text[#text + 1] = string.format("slowest %.3fµs / fastest: %.3fµs", closure.maxTime, closure.minTime)
		text[#text + 1] = string.format("%i calls => %f per frame", count, count / self.numFrames)
		AddLineCenter(ItemTooltip, table.concat(text, "\n"))

		if closure.selfTime > 0 and(closure.selfTime / closure.wallTime) < 0.5 then
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
			if parent.recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE then
				text[#text + 1] = string.format("%s (|cefefef%s:%i|r)", parent.info[CLOSURE_NAME_INDEX], parent.info[CLOSURE_FILE_INDEX], parent.info[CLOSURE_LINE_INDEX])
			else
				text[#text + 1] = string.format("%s (|cefefef%s|r)", parent.info[CLOSURE_NAME_INDEX], parent.info[CLOSURE_FILE_INDEX])
			end
		end

		AddLine(ItemTooltip, table.concat(text, "\n"), ZO_TOOLTIP_DEFAULT_COLOR, TEXT_ALIGN_LEFT)
	end
	ZO_ClearNumericallyIndexedTable(text)
end

----------------------------------

do
	local task = async:Create("ESO_PROFILER_SUBCALLS")
	addon.showSubCalls = false
	local function FindSubCalls(self)
		local selectedData = self.selectedData
		if not selectedData then return end

		local closure = selectedData.closure
		local stackId = closure.slowestRun
		if not stackId then return end

		local profilerData = self.profilerData
		local stackFrames = profilerData.stackFrames
		if #stackFrames == 0 then return end

		task:Cancel()

		local statusBar = self.control:GetNamedChild("LoadingBar")
		local content = self.control:GetNamedChild("Content")

		local value, max = 0, #stackFrames

		statusBar:SetHidden(false)
		content:SetHidden(true)

		self.showSubCalls = true
		local scrollList = self.contentList
		ZO_ScrollList_Clear(scrollList)
		local dataList = ZO_ScrollList_GetDataList(scrollList)

		local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
		local processed = { }

		local function addStackFrame(stackId)
			processed[stackId] = true
			statusBar:SetMinMax(0, max)
			statusBar:SetValue(value)
			local closure = profilerData:GetClosureByStackId(stackId)
			dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(closure.recordDataType, { closure = closure })
			local stackId = closure.slowestRun
			local function loop(index)
				value = value + 1
				local subclosure, parentId = profilerData:GetClosureByStackId(index)
				-- find current stackId as parentId
				if parentId and subclosure.slowestRun == index and parentId == stackId and not processed[index] then
					max = max + #stackFrames
					addStackFrame(index)
				end
			end
			task:For(1, #stackFrames):Do(loop)
		end
		addStackFrame(stackId)

		task:Then( function()
			local sortHeaders = self.sortHeaders
			self:ChangeSort(sortHeaders.selectedSortHeader.key, sortHeaders.sortDirection)
			statusBar:SetHidden(true)
			content:SetHidden(false)
		end )

	end

	function addon:ShowContextMenuInsertBefore(control)
		local data = ZO_ScrollList_GetData(control)
		if self.selectedData ~= data then
			self:OnSelectionChanged(self.selectedData, data, false)
		end
		if self.selectedData then
			AddCustomMenuItem("Find Sub Calls", function() FindSubCalls(self) end)
		end
		if self.showSubCalls then
			AddCustomMenuItem("Show All", function()
				task:Cancel()
				self.showSubCalls = false
				self:PrintReport()
			end )
		end
	end
end

function addon:ShowContextMenuAppendAfter(control)
end

function addon:ShowContextMenu(control)
	ClearMenu()
	self:ShowContextMenuInsertBefore(control)
	self:ShowContextMenuAppendAfter(control)
	ShowMenu()
end

----------------------------------

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
	local function AutoStartEnabled()
		return GetCVar("StartLuaProfilingOnUILoad") ~= "0"
	end
	local function SetAutoStartEnabled(on)
		SetCVar("StartLuaProfilingOnUILoad", on and "1" or "0")
	end

	self.keybindButtonGroupRight = {
		alignment = KEYBIND_STRIP_ALIGN_RIGHT,
		{
			name = function() return GetString(self.profiling and SI_JOURNAL_MENU_ESO_PROFILER_STOP or SI_JOURNAL_MENU_ESO_PROFILER_START) end,
			keybind = "ESO_PROFILER_TOGGLE",
			order = 100,
			callback = function()
				PlaySound(SOUNDS.DEFAULT_CLICK)
				if self.profiling then
					StopScriptProfiler()
					self:GenerateReport()
				else
					StartScriptProfiler()
				end
			end,
		},
	}
	-- ToDo: Remove
	if legacy then
		self.keybindButtonGroupAutoStart = {
			alignment = KEYBIND_STRIP_ALIGN_CENTER,
		}
	else
		self.keybindButtonGroupAutoStart = {
			alignment = KEYBIND_STRIP_ALIGN_CENTER,
			{
				name = function() return GetString(AutoStartEnabled() and SI_JOURNAL_MENU_ESO_PROFILER_AUTOSTART_ON or SI_JOURNAL_MENU_ESO_PROFILER_AUTOSTART_OFF) end,
				keybind = "ESO_PROFILER_AUTOSTART_TOGGLE",
				order = 0,
				callback = function()
					PlaySound(SOUNDS.DEFAULT_CLICK)
					SetAutoStartEnabled(not AutoStartEnabled())
					KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindButtonGroupAutoStart)
				end,
			},
		}
	end

	self.keybindButtonGroupExtras = {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
		{
			name = "Profile Script",
			keybind = "UI_SHORTCUT_TERTIARY",
			order = 0,
			callback = function()
				PlaySound(SOUNDS.DEFAULT_CLICK)
				if ESO_PROFILER_SCENE:HasFragment(LEFT_PANEL_BG_FRAGMENT) then
					ESO_PROFILER_SCENE:RemoveFragmentGroup(extrasFragmentGroup)
				else
					ESO_PROFILER_SCENE:AddFragmentGroup(extrasFragmentGroup)
				end
			end,
		},
	}

	ESO_PROFILER_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWN then
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindButtonGroupExtras)
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindButtonGroupRight)
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindButtonGroupAutoStart)
		elseif newState == SCENE_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindButtonGroupRight)
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindButtonGroupAutoStart)
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindButtonGroupExtras)
		end
	end )
end

function addon:InitializeWindow()
	self.control = ESOProfilerTopLevel
	self.content = self.control:GetNamedChild("Content")
	self.contentList = self.content:GetNamedChild("List")
	self.searchBox = self.content:GetNamedChild("SearchBox")
	self.statusBar = self.control:GetNamedChild("LoadingBar")

	self.statusBar:SetHidden(true)
	self.content:SetHidden(true)

	local function formatValue(value)
		return string.format("%d", value)
	end
	local function setupDataRowBase(rowControl, closure, text)
		local nameCtl = rowControl:GetNamedChild("Name")
		local includeTimeCtl = rowControl:GetNamedChild("IncludeTime")
		local includeTimeMinCtl = rowControl:GetNamedChild("IncludeTimeMin")
		local includeTimeMaxCtl = rowControl:GetNamedChild("IncludeTimeMax")
		local excludeTimeCtl = rowControl:GetNamedChild("ExcludeTime")
		local countCtl = rowControl:GetNamedChild("Count")

		nameCtl:SetText(text)
		includeTimeCtl:SetText(formatValue(closure.wallTime))
		includeTimeMinCtl:SetText(formatValue(closure.minTime))
		includeTimeMaxCtl:SetText(formatValue(closure.maxTime))
		excludeTimeCtl:SetText(formatValue(closure.selfTime))
		countCtl:SetText(closure.callCount)
	end

	local function setupDataRowClosure(rowControl, rowData, scrollList)
		local closure = rowData.closure
		setupDataRowBase(rowControl, closure, string.format("%s (%s:%d)", closure.info[CLOSURE_NAME_INDEX], closure.info[CLOSURE_FILE_INDEX], closure.info[CLOSURE_LINE_INDEX]))
	end
	local function setupDataRowOther(rowControl, rowData, scrollList)
		local closure = rowData.closure
		setupDataRowBase(rowControl, closure, string.format("%s (%s)", closure.info[CLOSURE_NAME_INDEX], closure.info[CLOSURE_FILE_INDEX]))
	end

	ZO_ScrollList_AddDataType(self.contentList, SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE, "ESOProfilerRow", 24, setupDataRowClosure)
	ZO_ScrollList_SetTypeSelectable(self.contentList, SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE, true)

	if not legacy then
		ZO_ScrollList_AddDataType(self.contentList, SCRIPT_PROFILER_RECORD_DATA_TYPE_CFUNCTION, "ESOProfilerRow", 24, setupDataRowOther)
		ZO_ScrollList_SetTypeSelectable(self.contentList, SCRIPT_PROFILER_RECORD_DATA_TYPE_CFUNCTION, true)

		ZO_ScrollList_AddDataType(self.contentList, SCRIPT_PROFILER_RECORD_DATA_TYPE_GARBAGE_COLLECTION, "ESOProfilerRow", 24, setupDataRowOther)
		ZO_ScrollList_SetTypeSelectable(self.contentList, SCRIPT_PROFILER_RECORD_DATA_TYPE_GARBAGE_COLLECTION, true)

		ZO_ScrollList_AddDataType(self.contentList, SCRIPT_PROFILER_RECORD_DATA_TYPE_USER_EVENT, "ESOProfilerRow", 24, setupDataRowOther)
		ZO_ScrollList_SetTypeSelectable(self.contentList, SCRIPT_PROFILER_RECORD_DATA_TYPE_USER_EVENT, true)
	end

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

	self.script = ESOProfilerScriptTopLevel
	self.loopCount = self.script:GetNamedChild("LoopCount")
	self.loopCount:SetText("1")
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
	ESO_PROFILER_SCRIPT_FRAGMENT = ZO_HUDFadeSceneFragment:New(ESOProfilerScriptTopLevel)
	ESO_PROFILER_SCENE = ZO_Scene:New(sceneName, SCENE_MANAGER)
	ESO_PROFILER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
	ESO_PROFILER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
	ESO_PROFILER_SCENE:AddFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_FRAGMENT)
	ESO_PROFILER_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
	ESO_PROFILER_SCENE:AddFragment(FRAME_PLAYER_FRAGMENT)
	-- ESO_PROFILER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_CENTERED_NO_BLUR)
	ESO_PROFILER_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
	ESO_PROFILER_SCENE:AddFragment(TITLE_FRAGMENT)
	ESO_PROFILER_SCENE:AddFragment(JOURNAL_TITLE_FRAGMENT)
	ESO_PROFILER_SCENE:AddFragment(CODEX_WINDOW_SOUNDS)
	ESO_PROFILER_SCENE:AddFragment(ESO_PROFILER_FRAGMENT)

	extrasFragmentGroup = { MINIMIZE_CHAT_FRAGMENT, LEFT_PANEL_BG_FRAGMENT, ESO_PROFILER_SCRIPT_FRAGMENT }

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

do
	local runner = async:Create("ESO_PROFILER_RUNSCRIPT")
	local function finallyStop()
		ESOProfilerScriptTopLevelRunCode:SetEnabled(true)
		addon:GenerateReport()
	end
	runner:Finally(finallyStop)
	local function stop(runner)
		-- The frame, StopScriptProfiler is called in, seems to be excluded
		runner:Delay(20, StopScriptProfiler)
	end
	function addon:RunCode(control, button, upInside)
		if not upInside then return end

		local code = ESOProfilerScriptTopLevelScriptEditBox:GetText()
		-- code = string.format("function script() %s\nend\nscript()", code)
		code = assert(zo_loadstring(code, "test"))
		if code then
			local statusBar = self.statusBar
			local content = self.control:GetNamedChild("Content")

			-- search for the pseudo "file path"
			self.searchBox:SetText("@test")

			local count = self.loopCount:GetText()
			count = count and #count > 0 and tonumber(count) or 1

			statusBar:SetHidden(true)
			content:SetHidden(true)
			ESOProfilerScriptTopLevelRunCode:SetEnabled(false)

			StartScriptProfiler()
			local function script(runner)
				if count > 1 then
					runner:For(1, count):Do(code):Then(stop)
				else
					code()
					stop(runner)
				end
			end
			-- We need a new frame for the profiler to record
			runner:Delay(20, script)
		end
	end
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

if GetCVar("StartLuaProfilingOnUILoad") ~= "0" then
	StartScriptProfiler()
	em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, function()
		em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
		task:Delay(2000, StopScriptProfiler)
	end )
end

ESO_PROFILER = addon
