local ROW_TYPE_ID = 1

local INDEX_BUTTON = 1
local INDEX_POOL_KEY = 2
local INDEX_DESCRIPTOR = 3

local em = GetEventManager()
local gps = LibGPS3

local TOOLTIP_MODE = {
	INFORMATION = 1,
	KEEP = 2,
	MAP_LOCATION = 3,
	IMPERIAL_CITY = 4
}
local INFORMATION_TOOLTIP = InformationTooltip
local KEEP_TOOLTIP = ZO_KeepTooltip
local MAP_LOCATION_TOOLTIP = ZO_MapLocationTooltip
local IMPERIAL_CITY_TOOLTIP = ZO_ImperialCityTooltip

-- Creates the actual waypoint window
function WaypointIt:CreateWaypointsWindow()
    -----------------------------------------------------
    -- Initialize handler for default to waypoint window option
    -----------------------------------------------------
    WORLD_MAP_INFO_FRAGMENT:RegisterCallback(
        "StateChange",
        function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:SetupMenuBar()
                if self.sv["DEFAULTTO_WAYPOINT_WIN"] and WORLD_MAP_MANAGER:GetMode() == MAP_MODE_LARGE_CUSTOM then
                    WORLD_MAP_INFO:SelectTab(SI_BINDING_NAME_WAYPOINTIT)
                end
            end
        end
    )

	-----------------------------------------------------
	-- Create String Bindings
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT", "WaypointIt")
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_TOGGLE_DEBUGWIN", self.color.darkOrange .. "Toggle Debug Window|r " .. self.color.magenta .. "- Set a hotkey to toggle the debug window.")
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_AUTOMARK_NEAREST_QUEST", self.color.darkOrange .. "Mark Closest Quest|r " .. self.color.magenta .. "- Set a hotkey to set a waypoint for the closest quest.")
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_AUTOMARK_FOLLOW_NEXT", self.color.darkOrange .. "Follow Next Custom Pin|r " .. self.color.magenta .. "- Set a hotkey to set a waypoint for the next custom pin in the follow list.")
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_TOGGLE_SETTING_NEXT_QUEST", self.color.darkOrange .. "Toggle next quest setting|r " .. self.color.magenta .. "- Set a hotkey to toggle the setting 'Automark Next Quest Waypoint'.")
	-----------------------------------------------------

    -- This one does not need to be added to the WORLD_MAP_INFO UI scene.
    -- It gets automatically shown/hidden when you press buttons on the menu bar
    self.FRAGMENT_WINDOW = ZO_FadeSceneFragment:New(self.waypointWin, false, 0)

    local function hasEntries()
        local scrollList = self.scrollList
        local dataList = ZO_ScrollList_GetDataList(scrollList)
        return #dataList > 0
    end
    self.keybindButtonGroupMap = {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        {
            name = GetString(SI_BINDING_NAME_WAYPOINTIT_TOGGLE_SORT),
            keybind = "WAYPOINTIT_TOGGLE_SORT",
            enabled = hasEntries,
            order = 100,
            callback = function()
                self:ToggleCurrentSort()
                PlaySound(SOUNDS.DEFAULT_CLICK)
            end
        },
        {
            name = GetString(SI_BINDING_NAME_WAYPOINTIT_ADD_FOLLOW),
            keybind = "WAYPOINTIT_ADD_FOLLOW",
            enabled = hasEntries,
            order = 100,
            visible = function()
                return ZO_MenuBar_GetSelectedDescriptor(self.c_MainMenuBar) == 5
            end,
            callback = function()
                self:FollowCurrentCustomPins()
                PlaySound(SOUNDS.DEFAULT_CLICK)
            end
        }
    }

    do
        local lastMainMainBarBtnDescriptor, lastSubBarBtnDescriptor
        local function backupDescriptor()
            if not lastMainMainBarBtnDescriptor then
                lastMainMainBarBtnDescriptor, lastSubBarBtnDescriptor = ZO_MenuBar_GetSelectedDescriptor(self.c_MainMenuBar), ZO_MenuBar_GetSelectedDescriptor(self.c_SubMenuBar)
            end
        end
        local function windowStateChange(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWN then
                PushActionLayerByName(GetString(SI_KEYBINDINGS_CATEGORY_WAYPOINTIT))
                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindButtonGroupMap)
            elseif newState == SCENE_HIDING then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindButtonGroupMap)
                RemoveActionLayerByName(GetString(SI_KEYBINDINGS_CATEGORY_WAYPOINTIT))
            end
            -- After its shown update the current POI's & Locations
            -- MapPins take a few ms to update once the map is shown
            if newState == SCENE_FRAGMENT_SHOWN then
                local mapMode = WORLD_MAP_MANAGER:GetMode()
                if mapMode == MAP_MODE_FAST_TRAVEL then
                    backupDescriptor()
                    self:SelectMainBarBtnDescriptor(1)
                    self:SelectSubBarBtnDescriptor(1)
                    self:DelayedUpdateAll()
                elseif mapMode == MAP_MODE_KEEP_TRAVEL then
                    backupDescriptor()
                    self:SelectMainBarBtnDescriptor(1)
                    self:SelectSubBarBtnDescriptor(2)
                    self:DelayedUpdateAll()
                elseif lastMainMainBarBtnDescriptor then
                    -- Selected button was changed, update filter info
                    self:SelectMainBarBtnDescriptor(lastMainMainBarBtnDescriptor)
                    if not self.c_SubMenuBar:IsHidden() then
                        self:SelectSubBarBtnDescriptor(lastSubBarBtnDescriptor)
                    end
                    lastMainMainBarBtnDescriptor, lastSubBarBtnDescriptor = nil, nil
                    self:DelayedUpdateAll()
                end
            end
        end

        self.FRAGMENT_WINDOW:RegisterCallback("StateChange", windowStateChange)
    end

	self.delayProcessing = true
	self.isListDirty = true

    WORLD_MAP_INFO_FRAGMENT:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			self.delayProcessing = newState ~= SCENE_FRAGMENT_SHOWN
		end
	)
	self.FRAGMENT_WINDOW:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				-- Update the scroll list so it has the new pin. Done on a slight delay to give the pin a chance to be created ingame & its information updated.
				self:DelayedUpdateAll()
			elseif newState == SCENE_FRAGMENT_HIDING then
				ClearTooltip(INFORMATION_TOOLTIP)
			end
		end
	)
end

-- Creates the waypoint list
function WaypointIt:CreateWaypointsList()
	local BUTTON_HEIGHT = 50
	local scrollList = self.scrollList
	-- Dummy category, gets overridden when the menuBar is shown
	-- the first button is selected & this is changed, only here
	-- to prevent nil errors if something gets called to soon
	scrollList.currentCategoryId = "fastTravelWayshrine"

	-- RowControl callback
	local function setupDataRow(rowControl, data, scrollList)
		local m_Pin = data.m_Pin
		local followingUnit = self.followingUnit
		local icon = rowControl:GetNamedChild("Texture")
		local nameLabel = rowControl:GetNamedChild("NameLabel")
		local levelLabel = rowControl:GetNamedChild("LevelLabel")
		local displayName = self.sv["WAYPOINT_WINDOW_NAME_DISTANCE"] and string.format("%s%s\n(%s)", data.name, self.color.yellow, self:GetDistanceText(data.distance)) or data.name

		local layoutData = ZO_MapPin.PIN_DATA[m_Pin:GetPinType()]

		local iconPath = data.iconPath or layoutData and layoutData.texture
		if type(iconPath) == "function" then
			iconPath = iconPath(m_Pin)
		end
		iconPath = iconPath or "esoui/art/icons/icon_missing.dds"
		rowControl.iconPath = iconPath

		icon:SetTexture(iconPath)
		nameLabel:SetText(displayName)

		local color = layoutData and layoutData.tint
		if type(color) == "function" then
			color = color(m_Pin)
		end
		color = color or ZO_DEFAULT_ENABLED_COLOR
		icon:SetColor(color:UnpackRGBA())

		if data.level then
			levelLabel:SetText(data.level)
			levelLabel:SetHidden(false)
		else
			levelLabel:SetHidden(true)
		end
		-- If this row is our current waypoint or
		-- if its unitTag is the same as the unitTag were following
		-- set it highlighted (it is the currently selected waypoint or
		-- group memeber we are following). Else set alpha to 0
		-- the mouseOver function will handle mouseOver highlights
		local unitName = GetUnitName(data.unitTag)
		self:HideRowHighlight(rowControl, not (self:IsLocCurrentWaypoint(data) or (followingUnit and followingUnit.unitTag == data.unitTag and followingUnit.name == unitName)))
	end

	ZO_ScrollList_AddDataType(self.scrollList, ROW_TYPE_ID, "WayPointButton", BUTTON_HEIGHT, setupDataRow)
end

function WaypointIt:RefreshIfVisible()
    if self.FRAGMENT_WINDOW:IsShowing() then
        ZO_ScrollList_RefreshVisible(self.scrollList)
    end
end

function WaypointIt:ShowCategoryId(iCategoryId, subFilterId)
	self.scrollList.currentCategoryId = iCategoryId
	self.scrollList.currentCategoryIdSubFilter = subFilterId

	self:UpdateScrollList()
end

function WaypointIt:ToggleCurrentSort()
	-- Distance calculations are not possible on the Cosmic Map
	-- No need to toggle, can only sort by name
	if GetMapType() == MAPTYPE_COSMIC then
		return
	end

	local scrollList = self.scrollList
	local currentCatId = scrollList.currentCategoryId
	local subFilterId = scrollList.currentCategoryIdSubFilter

	if scrollList.currentSortType == "name" then
		self:SortListByDistance()
		scrollList.currentSortType = "distance"
	else
		self:SortPinsByName()
		scrollList.currentSortType = "name"
	end
end

function WaypointIt:SortListByDistance()
	local scrollList = self.scrollList
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	table.sort(
		dataList,
		function(bvalue1, bvalue2)
			if bvalue1.data.distance < bvalue2.data.distance then
				return true
			elseif bvalue1.data.distance == bvalue2.data.distance then
				return bvalue1.data.name < bvalue2.data.name
			end
			return false
		end
	)
	ZO_ScrollList_Commit(scrollList)
end

function WaypointIt:SortPinsByName()
	local scrollList = self.scrollList
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	table.sort(
		dataList,
		function(bvalue1, bvalue2)
			return bvalue1.data.name < bvalue2.data.name
		end
	)
	ZO_ScrollList_Commit(scrollList)
end

function WaypointIt:SetSubMenuBar(tabFilter)
	local subBar = tabFilter.subBar
	local subMenuBar = self.c_SubMenuBar

	if subBar then
		self:UpdateButtons(subMenuBar, WAYPOINTIT_FILTER_DATA[subBar])
		-- Must unhide it first or following checks will fail
		subMenuBar:SetHidden(false)
		-- Set enabled/disabled states for btns on the new sub bar
		-- And set a selected btn
		self:EnableCheckSubBar()
		self:CheckSelectedSubBtn()
	else
		subMenuBar:SetHidden(true)
	end
end

-- Select the first enabled button from the main menu bar
function WaypointIt:SelectFirstEnabledMainBtn()
	local tBtns = self.c_MainMenuBar.m_object.m_buttons

	for btnKey = 1, #tBtns do
		if tBtns[btnKey][INDEX_BUTTON].m_object:GetState() ~= BSTATE_DISABLED then
			self:SelectMainBarBtnDescriptor(tBtns[btnKey][INDEX_DESCRIPTOR])
			return tBtns[btnKey][INDEX_BUTTON].m_object.m_buttonData
		end
	end
	-- If no btns have items to display just select the first button
	self:SelectMainBarBtnDescriptor(tBtns[1][INDEX_DESCRIPTOR])
	return tBtns[1][INDEX_BUTTON].m_object.m_buttonData
end

function WaypointIt:SelectFirstEnabledSubBtn()
	local tBtns = self.c_SubMenuBar.m_object.m_buttons
	for btnKey = 1, #tBtns do
		if tBtns[btnKey][INDEX_BUTTON].m_object:GetState() ~= BSTATE_DISABLED then
			self:SelectSubBarBtnDescriptor(tBtns[btnKey][INDEX_DESCRIPTOR])

			return tBtns[btnKey][INDEX_BUTTON].m_object.m_buttonData
		end
	end
	-- If no btns have items to display just select the first button
	self:SelectSubBarBtnDescriptor(tBtns[1][INDEX_DESCRIPTOR])
	return tBtns[1][INDEX_BUTTON].m_object.m_buttonData
end

-- Checks the currently selected btns on the main bar to make sure they have items under them if not it selects the first enabled button
function WaypointIt:CheckSelectedMainBtn()
	local m_clickedButtonMain = self.c_MainMenuBar.m_object.m_clickedButton

	if not m_clickedButtonMain or m_clickedButtonMain:GetState() == BSTATE_DISABLED then
		local selectedBtnData = self:SelectFirstEnabledMainBtn()
		local scrollList = self.scrollList

		scrollList.currentCategoryId = selectedBtnData.lookupType
		scrollList.currentCategoryIdSubFilter = selectedBtnData.subType

		-- No need to check if there is a subBar, this function will check that
		-- and hide the subBar if there isn't supposed to be one.
		self:SetSubMenuBar(selectedBtnData)
	end
end

-- If selected btn is not enabled, select first enabled btn
function WaypointIt:CheckSelectedSubBtn()
	if self.FRAGMENT_WINDOW:GetState() == SCENE_FRAGMENT_HIDDEN then
		return
	end
	if self.c_SubMenuBar:IsHidden() then
		return
	end

	local m_clickedButton = self.c_SubMenuBar.m_object.m_clickedButton

	if not m_clickedButton or m_clickedButton:GetState() == BSTATE_DISABLED then
		local selectedBtnData = self:SelectFirstEnabledSubBtn()
		local scrollList = self.scrollList

		-- Selected button was changed, update filter info
		scrollList.currentCategoryId = selectedBtnData.lookupType
		scrollList.currentCategoryIdSubFilter = selectedBtnData.subType
	end
end

-- Create a copy of the currently shown custom pins are start the follow mode
function WaypointIt:FollowCurrentCustomPins()
	local list = self.followList
	ZO_ClearNumericallyIndexedTable(list)
	local scrollList = self.scrollList
	local dataList = ZO_ScrollList_GetDataList(scrollList)
	if #dataList == 0 then
		return false
	end
	local function add(i)
		local data = dataList[i].data
		if data.m_Pin then
			data.gx, data.gy = gps:LocalToGlobal(data.m_Pin:GetNormalizedPosition())
			data.followed = false
			list[#list + 1] = data
		end
	end
	for i = 1, #dataList do
		add(i)
	end
	self.followSort = scrollList.currentSortType
	return self:TryFollowNextCustomPin()
end

-- Create a copy of the currently shown custom pins are start the follow mode
function WaypointIt:TryFollowNextCustomPin()
	self:CancelCurrentTask()
	CURRENT_TASK, lastWaypointBy = nil, nil

	local list = self.followList
	if #list == 0 then
		if self:HasWaypoint() then
			ZO_WorldMap_RemovePlayerWaypoint() -- Baertram, 2022-03-03, Fix WorldMap removal of waypoint so that the keybind will allow to add a new one (instead of remove a non existing)
		end
		return false
	end
	local function setIndex(i)
		local data = list[i]
		if not data then
			return false
		end
		table.remove(list, i)
		if self:IsWaypointOutsideOfRemovalDistance(gps:GlobalToLocal(data.gx, data.gy)) then
			nextWaypoint = {setBy = "follow", pinKey = data.pinKey, name = data.name, lookupType = data.lookupType, keyIndex = data.keyIndex, majorIndex = data.majorIndex}
			self:SetWaypoint(data.gx, data.gy)
			self:RunWaypointRemoveUpdates(true, true)
			return true
		end
	end
	local playerOffsetX, playerOffsetY = gps:LocalToGlobal(GetMapPlayerPosition("player"))
	repeat
		if self.followSort == "distance" then
			-- Get player coords for measuring distance

			local dist, dx, dy
			local minDist, minIndex = 1e99, 1
			for i = 1, #list do
				local data = list[i]
				dx, dy = data.gx - playerOffsetX, data.gy - playerOffsetY
				dist = dx * dx + dy * dy
				if dist < minDist then
					minDist, minIndex = dist, i
				end
			end
			if setIndex(minIndex) then
				return true
			end
		elseif setIndex(1) then
			return true
		end
	until #list == 0
	return false
end

do
	local identifier = "WAYPOINTIT_DELAY_UPDATE"
	local registered = false
	function WaypointIt:DelayedUpdateAll()
		if registered then
			em:UnregisterForUpdate(identifier)
			registered = false
		end
		if self.FRAGMENT_WINDOW:GetState() == SCENE_FRAGMENT_HIDDEN then
			return
		end

		local function DoUpdate()
			em:UnregisterForUpdate(identifier)
			registered = false
			self:UpdateAll()
		end
		em:RegisterForUpdate(identifier, 150, DoUpdate)
		registered = true
	end
end

do
	local identifier = "WAYPOINTIT_ENABLE_BUTTONS"

	-- Updates button states & scroll list
	function WaypointIt:UpdateAll()
		em:UnregisterForUpdate(identifier)
		if self.FRAGMENT_WINDOW:GetState() == SCENE_FRAGMENT_HIDDEN then
			return
		end

		if self.isListDirty then
			self.isListDirty = false

			for _, pin in pairs(self.pinManager:GetActiveObjects()) do
				if pin and pin.IsGroup and pin.SetData then
					self:AddPin(pin)
				end
			end
		end

		self:UpdateScrollList()

		-- Set enabled/disabled states for btns on main bar
		self:EnableCheckMainBar()
		if not self.c_SubMenuBar:IsHidden() then
			self:EnableCheckSubBar()
		end

		local function DelayCheckSelected()
			em:UnregisterForUpdate(identifier)
			self:CheckSelectedMainBtn()

			-- then make sure the selected btn is enabled or select the first enabled btn
			if not self.c_SubMenuBar:IsHidden() then
				self:CheckSelectedSubBtn()
			end
		end
		em:RegisterForUpdate(identifier, 1000, DelayCheckSelected)
	end
end

function WaypointIt:UpdateScrollList()
	if self.FRAGMENT_WINDOW:GetState() == SCENE_FRAGMENT_HIDDEN then
		return
	end
	local mapType = GetMapType()

	local scrollList = self.scrollList
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	local currentCatId = scrollList.currentCategoryId
	local subFilterId = scrollList.currentCategoryIdSubFilter
	local currentCategory = self.categories[currentCatId]
	if not currentCategory then
		ZO_ScrollList_Commit(scrollList)
		return
	end
	local tActivePins = currentCategory.pins

	ZO_ScrollList_Clear(scrollList)

	local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
	-- Populate the new dataList
	for pinKey, rowData in pairs(tActivePins) do
		if not subFilterId or subFilterId == rowData.subFilterId then
			dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, rowData, 1)
		end
	end

	-- Get player coords for measuring distance
	local playerOffsetX, playerOffsetY = gps:LocalToGlobal(GetMapPlayerPosition("player"))

	local normx, normy, dist
	-- Update distances to target
	for pinKey, rowData in pairs(dataList) do
		normx, normy = rowData.data.m_Pin:GetNormalizedPosition()
		dist = self:GetDistanceToLocalCoords(normx, normy, playerOffsetX, playerOffsetY)

		rowData.data.distance = dist
	end

	-- sort will commit
	-- ZO_ScrollList_Commit(scrollList)

	local bSortByDistance = false

	if subFilterId then
		bSortByDistance = self.sv["SORT_ORDER"][currentCatId][subFilterId] == "Distance"
	else
		bSortByDistance = self.sv["SORT_ORDER"][currentCatId] == "Distance"
	end

	if bSortByDistance and mapType ~= MAPTYPE_COSMIC then
		self:SortListByDistance()
		scrollList.currentSortType = "distance"
	else
		self:SortPinsByName()
		scrollList.currentSortType = "name"
	end

	KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindButtonGroupMap)
end

-- *******************************************************--
-- *********** Button Enable Check Functions *************--
-- *******************************************************--
do
	local function EnableButton(btn, enable)
		local btnObj = btn.m_object

		if enable then
			if btnObj.m_menuBar:GetSelectedDescriptor() == btnObj:GetDescriptor() then
				btnObj:SetState(BSTATE_PRESSED)
			else
				btnObj:SetState(BSTATE_NORMAL)
			end
		else
			btnObj:SetState(BSTATE_DISABLED)
		end
	end

	local function DoPinsExist(self, lookupType, subType)
		local pins = self.categories[lookupType].pins

		if subType then
			for k, pinData in pairs(pins) do
				if pinData.subFilterId == subType then
					return true
				end
			end
		else
			if next(pins) ~= nil then
				return true
			end
		end
		return false
	end

	local function DoesSubBarHavePins(self, subBar)
		local tabFilters = WAYPOINTIT_FILTER_DATA[subBar]

		for k, tabData in pairs(tabFilters) do
			if DoPinsExist(self, tabData.lookupType, tabData.subType) then
				return true
			end
		end
		return false
	end

	-- enable/disable buttons. Not every button on the main menu bar has a subfilter bar
	-- So I have to check both bars for enable/disabled states.
	function WaypointIt:EnableCheckMainBar()
		if self.FRAGMENT_WINDOW:GetState() == SCENE_FRAGMENT_HIDDEN then
			return
		end

		-- CheckMainButtons
		local tMainButtons = self.c_MainMenuBar.m_object.m_buttons
		for _, btnTable in pairs(tMainButtons) do
			local btn = btnTable[1]
			local btnData = btn.m_object.m_buttonData
			local btnLookupType = btnData.lookupType

			if btnLookupType then
				local btnSubType = btnData.subType
				if DoPinsExist(self, btnLookupType, btnSubType) then
					EnableButton(btn, true)
				else
					EnableButton(btn, false)
				end
			else
				local subBar = btnData.subBar
				if DoesSubBarHavePins(self, subBar) then
					EnableButton(btn, true)
				else
					EnableButton(btn, false)
				end
			end
		end
	end

	function WaypointIt:EnableCheckSubBar()
		if self.FRAGMENT_WINDOW:GetState() == SCENE_FRAGMENT_HIDDEN then
			return
		end
		if self.c_SubMenuBar:IsHidden() then
			return
		end

		-- Check current subFilter buttons
		local tSubButtons = self.c_SubMenuBar.m_object.m_buttons
		for _, btnTable in pairs(tSubButtons) do
			local btn = btnTable[1]
			local btnData = btnTable[1].m_object.m_buttonData

			if DoPinsExist(self, btnData.lookupType, btnData.subType) then
				EnableButton(btn, true)
			else
				EnableButton(btn, false)
			end
		end
	end
end

local function GetTooltip(mode)
	if mode == TOOLTIP_MODE.INFORMATION then
		return INFORMATION_TOOLTIP
	elseif mode == TOOLTIP_MODE.KEEP then
		return KEEP_TOOLTIP
	elseif mode == TOOLTIP_MODE.MAP_LOCATION then
		return MAP_LOCATION_TOOLTIP
	elseif mode == TOOLTIP_MODE.IMPERIAL_CITY then
		return IMPERIAL_CITY_TOOLTIP
	else
		error("Invalid tooltip mode type")
	end
end

function WaypointIt:IsLocCurrentWaypoint(data)
	local currentWaypoint = self.sv.currentWaypoint
	if not (currentWaypoint and data) then
		return false
	end

	if currentWaypoint.name ~= data.name then
		return false
	end
	if currentWaypoint.lookupType ~= data.lookupType then
		return false
	end
	if currentWaypoint.majorIndex ~= data.majorIndex then
		return false
	end

	local dKeyIndex = data.keyIndex
	local wpKeyIndex = currentWaypoint.keyIndex
	local isDataKeyIndexTable = type(dKeyIndex) == "table"
	local isCurrentWaypointKeyIndexTable = type(wpKeyIndex) == "table"
	if isDataKeyIndexTable and isCurrentWaypointKeyIndexTable then
		if wpKeyIndex[1] ~= dKeyIndex[1] or wpKeyIndex[2] ~= dKeyIndex[2] or wpKeyIndex[3] ~= dKeyIndex[3] then
			return false
		end
	elseif isDataKeyIndexTable ~= isCurrentWaypointKeyIndexTable then
		return false
	elseif currentWaypoint.keyIndex ~= data.keyIndex then
		return false
	end

	return true
end

-- Highlight row function for scrollList
function WaypointIt:HideRowHighlight(rowControl, hidden)
	local highlight = rowControl:GetNamedChild("Highlight")

	if (highlight) then
		if not highlight.animation then
			highlight.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
		end

		-- to prevent fast selections from messing up the highlighting
		-- Can't play another or change an animation while its running
		-- So stop the current animation if there is one running so we
		-- can play the new one.
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

-- Highlight row function for scrollList
function WaypointIt:UpdateTooltip(rowControl, hidden)
	if not (rowControl and rowControl.dataEntry) then
		return
	end
	if not (rowControl.dataEntry.data and rowControl.dataEntry.data.m_Pin) then
		return
	end

	local data = rowControl.dataEntry.data
	local m_Pin = data.m_Pin

	-- POI's do not have real tooltips, they only change the text at the top
	-- of the world map, so if its a POI return.
	if m_Pin:IsPOI() then
		return
	end

	-- Grab the tooltip & its creator function
	local pinTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[m_Pin.m_PinType]
	if not pinTooltipInfo then
		return
	end

	local tooltipFn = pinTooltipInfo.creator
	local tooltipMode = pinTooltipInfo.tooltip
	local tooltip = GetTooltip(tooltipMode)

	-- Clear/hide tooltips
	if hidden then
		-- Keeps work differently, must hide the control & clear a different tooltip
		if tooltipMode == TOOLTIP_MODE.KEEP then
			tooltip:SetHidden(true)
			ClearTooltip(MAP_LOCATION_TOOLTIP)
		else
			ClearTooltip(tooltip)
		end
	else
		if tooltipMode == TOOLTIP_MODE.KEEP then
			tooltip:SetKeep(m_Pin:GetKeepId(), m_Pin:GetBattlegroundContext(), 1)
			tooltip:RefreshKeepInfo()
			tooltip:ClearAnchors()
			tooltip:SetAnchor(RIGHT, rowControl, LEFT, -20, 0)
			tooltip:SetHidden(false)
		elseif tooltipMode == TOOLTIP_MODE.IMPERIAL_CITY then
			tooltip:SetHidden(false)
		else
			InitializeTooltip(tooltip, rowControl, RIGHT, -20, 0, LEFT)
			tooltipFn(m_Pin)
		end

		-- If its a quest pin, update the tooltip with quest data
		if m_Pin:IsQuest() then
			self:UpdateTooltipWithPinInfo(m_Pin, tooltip)
		elseif m_Pin:IsGroup() then
			-- Else if its a group member pin, update it with unit data
			self:UpdateTooltipWithGroupInfo(m_Pin, tooltip)
		end
	end
end

-- Mouse handler for scrollList
function WaypointIt:MouseRowEnter(rowControl)
	self:HideRowHighlight(rowControl, false)
	self:UpdateTooltip(rowControl, false)
end
function WaypointIt:MouseRowExit(rowControl)
	local hidden = true
	if (rowControl.dataEntry) then
		if (rowControl.dataEntry.data and rowControl.dataEntry.data.m_Pin) then
			local data = rowControl.dataEntry.data
			local unitTag = data.unitTag
			local name = data.name

			-- Only allow the highlight to be changed if its not the current waypoint
			-- and not the current unit were following
			if (not self:IsLocCurrentWaypoint(data)) and (not unitTag or not self.followingUnit or not (self.followingUnit and (self.followingUnit.unitTag == unitTag or self.followingUnit.name == GetUnitName(unitTag)))) then
				hidden = true
			else
				hidden = false
			end
		end
	end
	self:HideRowHighlight(rowControl, hidden)
	self:UpdateTooltip(rowControl, true)
end

-- Called when the user clicks a rowControl in the scrollList
function WaypointIt:SetWaypointByRowControl(rowControl)
	local data = ZO_ScrollList_GetData(rowControl)
	local m_Pin = data.m_Pin

	-- Make sure you update the location first
	m_Pin:UpdateLocation()

	--[[ Groups are handled differently. They do not set waypoints, they run a different RegisterUpdate and only update the directional arrow (inside the reticle) on updates. It is completely separate from everything else. Other waypoints & directional arrow (outside the reticle, for waypoints) is separate.
	--]]
	if m_Pin:IsGroup() then
		local unitTag = m_Pin:GetUnitTag()
		local unitName = GetUnitName(unitTag)
		local followingUnit = self.followingUnit

		-- if already following this group member, shut it off
		if followingUnit and followingUnit.unitTag == unitTag and followingUnit.name == unitName then
			-- remove the unit tag, were no longer following them.
			self.followingUnit = nil
			self:RunGroupWaypointUpdates(false)
		else
			-- set the unitTag so we know who were following
			self.followingUnit = {["unitTag"] = unitTag, ["name"] = unitName}
			self:RunGroupWaypointUpdates(true, m_Pin)

			local scrollList = self.scrollList
			ZO_ScrollList_RefreshVisible(scrollList)
		end
		-- don't set a waypoint
		return
	end

	--[[
	if m_Pin:IsAvARespawn() then
		-- I can't find any way to get the KeepId from the AvARespawnId/pin
	end
	--]]
	if m_Pin:IsForwardCamp() then
		-- if their dead then respawn there
		-- teleport them & return, else proceed & set a waypoint
		if IsUnitDead("player") then
			RespawnAtForwardCamp(m_Pin:GetForwardCampIndex())
			return
		end
	end
	-- Why didn't I use m_Pin:IsFastTravelKeep() ?? Speed ??
	if data.fastTravelKeepPin then
		-- they can never set a waypoint to this pinType
		-- Only seen when dead, so don't need to check if player is dead
		local keepId = m_Pin:GetKeepId()
		TravelToKeep(keepId)
		return
	end
	if data.lookupType == "fastTravelWayshrine" then
		if WORLD_MAP_MANAGER:GetMode() == MAP_MODE_FAST_TRAVEL then
			ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
			ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")
			local name = select(2, GetFastTravelNodeInfo(data.nodeIndex))
			ZO_Dialogs_ShowPlatformDialog("FAST_TRAVEL_CONFIRM", {nodeIndex = data.nodeIndex}, {mainTextParams = {data.name}})
			return
		end
	end

	-- if already have a waypoint here, shut it off
	if self:IsLocCurrentWaypoint(data) then
		ZO_WorldMap_RemovePlayerWaypoint() -- Baertram, 2022-03-03, Fix WorldMap removal of waypoint so that the keybind will allow to add a new one (instead of remove a non existing)
		--RemovePlayerWaypoint()
		-- do nothing else
		return
	end

	if m_Pin:IsQuest() then
		local questIndex = m_Pin:GetQuestIndex()
		self:ForceAssist(questIndex)
		self:PrintNextStepText(questIndex)
	end

	local normX, normY = m_Pin:GetNormalizedPosition()
	self:CancelCurrentTask()
	CURRENT_TASK = nil
	if self:IsWaypointOutsideOfRemovalDistance(normX, normY) then
		-- If a waypoint is set, save so we can compare it later to keep the scrollList row selection highlight turned on.
		-- Changed: See nextWaypoint definition for reason.
		-- self.sv.currentWaypoint = {name = data.name, lookupType = data.lookupType, majorIndex = data.majorIndex, keyIndex = data.keyIndex, setBy = "rowClick"}
		nextWaypoint = {name = data.name, lookupType = data.lookupType, majorIndex = data.majorIndex, keyIndex = data.keyIndex, setBy = "rowClick"}

		self:SetWaypoint(gps:LocalToGlobal(normX, normY))
	elseif self.sv["WAYPOINT_DISTANCE_WARNING"] then
		dw(string.format("%s%s", self.color.magenta, "Waypoint is within the waypoint removal distance. The waypoint will not be set."))
		db("Waypoint is within the waypoint removal distance. The waypoint will not be set.")
		if lastWaypointBy == "autoQuest" then
			ZO_WorldMap_RemovePlayerWaypoint() -- Baertram, 2022-03-03, Fix WorldMap removal of waypoint so that the keybind will allow to add a new one (instead of remove a non existing)
		end
	end
end

local function SetupButton(button, id, pool)
	button.m_object.pressedTexture = button:GetNamedChild("PressedTexture")
	button.m_object.highlightTexture = button:GetNamedChild("HighlightTexture")
	button.m_object.image = button:GetNamedChild("Image")

	ZO_PreHook(
		button.m_object,
		"SetState",
		function(btnObj, state, locked)
			if state == BSTATE_DISABLED then
				btnObj.image:SetColor(1, 0, 0, 1)
			else
				btnObj.image:SetColor(1, 1, 1, 1)
			end
			if state ~= BSTATE_NORMAL then
				btnObj.highlightTexture:SetHidden(true)
			end
			btnObj.pressedTexture:SetHidden(state ~= BSTATE_PRESSED)
		end
	)
end
local function SetButtonFactory(menuBar)
	assert(menuBar.m_object.m_pool, "Button pool renamed")
	menuBar.m_object.m_pool:SetCustomFactoryBehavior(SetupButton)
end

-- Creates all of the menu bars & adds a button to the world info ui menu bar
function WaypointIt:SetupMenuBar()
	if self.c_MainMenuBar then
		return
	end

	local tabData = {
		normal = "WaypointIt/Textures/WaypointIt_up.dds",
		pressed = "WaypointIt/Textures/WaypointIt_down.dds",
		highlight = "WaypointIt/Textures/WaypointIt_over.dds",
		disabled = "WaypointIt/Textures/WaypointIt.dds"
	}

	-- This shows/hides the fragment when selected in the menu bar.
	-- No need to add this fragment to any scene.
	WORLD_MAP_INFO.modeBar:Add(SI_BINDING_NAME_WAYPOINTIT, {self.FRAGMENT_WINDOW}, tabData)

	if self.sv["DEFAULTTO_WAYPOINT_WIN"] then
		WORLD_MAP_INFO.modeBar:SetStartingFragment(SI_BINDING_NAME_WAYPOINTIT)
	end

	SetButtonFactory(WaypointItWinMainMenuBar)
	SetButtonFactory(WaypointItWinSubMenuBar)

	-- bind references to the menu bars for later
	self.c_MainMenuBar = WaypointItWinMainMenuBar
	self.c_SubMenuBar = WaypointItWinSubMenuBar

	-- Setup the starting buttons for the menu bars:
	self:UpdateButtons(WaypointItWinMainMenuBar, WAYPOINTIT_FILTER_DATA["MAINBAR"])

	-- Select the first button on each menu bar
	-- Since the bar & sub bar are main & respawns, I can use direct numbers
	-- Only need special attention for custom subBar when every descriptor is not available
	self:SelectMainBarBtnDescriptor(1)
	self:SelectSubBarBtnDescriptor(1)
end

function WaypointIt:SelectMainBarBtnDescriptor(descriptor)
	local mainBarObject = self.c_MainMenuBar.m_object
	local buttonObject = mainBarObject:ButtonObjectForDescriptor(descriptor)
	if not buttonObject then
		return
	end
	local btn = buttonObject:GetControl()

	local btnData = buttonObject.m_buttonData
	self:SetSubMenuBar(btnData)
	if btnData.subBar then
		-- So we only need to call updateScrollList here
		self:UpdateScrollList()
	else
		-- Show categoryId calls UpdateScrollList on its own
		self:ShowCategoryId(btnData.lookupType, btnData.subType)
	end

	local buttonObject = mainBarObject:ButtonObjectForDescriptor(descriptor)
	mainBarObject:SetClickedButton(buttonObject, true)
end

function WaypointIt:SelectSubBarBtnDescriptor(descriptor)
	local subBarObject = self.c_SubMenuBar.m_object
	local buttonObject = subBarObject:ButtonObjectForDescriptor(descriptor)
	if not buttonObject then
		return
	end
	local btn = buttonObject:GetControl()

	subBarObject:SetClickedButton(buttonObject, true)

	local btnData = buttonObject.m_buttonData
	self:ShowCategoryId(btnData.lookupType, btnData.subType)
end

-- Menu bar button highlights on mouse enter
function WaypointIt_OnMouseEnter(_cButton)
	local btnObj = _cButton.m_object
	if btnObj:GetState() ~= BSTATE_NORMAL then
		return
	end

	btnObj.highlightTexture:SetHidden(false)
end

-- Menu bar button remove highlights on mouse exit
function WaypointIt_OnMouseExit(_cButton)
	local btnObj = _cButton.m_object
	-- changed because: Very quick clicking caused buttons to stay highlighted.
	if btnObj:GetState() == BSTATE_DISABLED then
		return
	end

	btnObj.highlightTexture:SetHidden(true)
end

-- *********************************************************************--
-- ********************  Quest Tooltip Code  ***************************--
-- *********************************************************************--
-- Adds the given line to the tooltip, padUp determines if we
-- want to remove vertical padding before inserting the line
local function AddTooltipLine(tooltip, line, padUp)
	if padUp then
		tooltip:AddVerticalPadding(-10)
	end
	tooltip:AddLine(line, "ZoFontGame", 1, 1, 1, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, true)
end

-- Grab the formatted repeatable text for a quest
local function GetRepeatableTooltipText(self, journalQuestIndex)
	local iRepeatType = GetJournalQuestRepeatType(journalQuestIndex)

	if iRepeatType == QUEST_REPEAT_DAILY then
		return self.color.green .. ZO_CachedStrFormat(SI_QUEST_JOURNAL_REPEATABLE_QUEST_TYPE, GetString(SI_QUEST_JOURNAL_REPEATABLE_TEXT), GetString(SI_QUESTREPEATABLETYPE2)) .. "|r"
	elseif iRepeatType == QUEST_REPEAT_REPEATABLE then
		return self.color.green .. GetString(SI_QUEST_JOURNAL_REPEATABLE_TEXT) .. "|r"
	end
end

-- Gets the instance tooltip text for a quest
local function GetInstanceTooltipText(self, journalQuestIndex)
	local instanceDisplayType = GetJournalInstanceDisplayType(journalQuestIndex)

	-- local sText = ZO_QuestJournalManager_GetInstanceDisplayTypeTooltipString(instanceDisplayType)
	-- Code change below: game version 100012 (they removed QUEST_JOURNAL
	-- local sText = QUEST_JOURNAL:GetTooltipText(instanceDisplayType)
	local sText = QUEST_JOURNAL_KEYBOARD:GetTooltipText(instanceDisplayType)

	if sText and sText ~= "" then
		return self.color.red .. sText .. "|r"
	end
end

--[[ returns a table of step indices organized by visibility so we can reorder how things are displayed in the tooltip. First required steps, then optional steps, then hints.
--]]
local function GetStepsByVisibility(journalQuestIndex)
	local numSteps = GetJournalQuestNumSteps(journalQuestIndex)

	local tStepIndices = {}
	tStepIndices[QUEST_STEP_VISIBILITY_HINT] = {}
	tStepIndices[QUEST_STEP_VISIBILITY_OPTIONAL] = {}
	tStepIndices[QUEST_STEP_VISIBILITY_HIDDEN] = {}

	for stepIndex = 1, numSteps do
		local stepText, visibility, stepType, trackerOverrideText, numConditions = GetJournalQuestStepInfo(journalQuestIndex, stepIndex)

		if not visibility then
			visibility = QUEST_STEP_VISIBILITY_HIDDEN
		end

		table.insert(tStepIndices[visibility], stepIndex)
	end
	return tStepIndices
end

-- Adds the condition texts for a given quest/step to the tooltip
local function AddStepConditionsToTooltip(tooltip, journalQuestIndex, stepIndex, numConditions, stepVisibility, conditionsAreOR, trackerOverrideText)
	--[[ This is when you have multiple choices but each have the same condition text. Use the override text to display it only once so it doesn't repeat the same condition text over & over.
	--]]
	if (trackerOverrideText and trackerOverrideText ~= "") then
		local fOverrideStepText = zo_strformat(SI_QUEST_HINT_STEP_FORMAT, trackerOverrideText)

		AddTooltipLine(tooltip, fOverrideStepText, false)
		return
	end

	-- Loop through the coditions & add them to their text to the tooltip
	for conditionIndex = 1, numConditions do
		local conditionText, current, max, isFailCondition, isComplete, isCreditShared = GetJournalQuestConditionInfo(journalQuestIndex, stepIndex, conditionIndex)

		if ((not isFailCondition) and (conditionText ~= "") and not isComplete) then
			if stepVisibility == QUEST_STEP_VISIBILITY_HINT then
				local fHintConditionText = zo_strformat(SI_QUEST_HINT_STEP_FORMAT, conditionText)
				AddTooltipLine(tooltip, fHintConditionText, true)
			elseif conditionsAreOR then
				-- No idea wtf This is for, couldn't figure it out so I'll just exclude it
				-- I'm guessing it has something to do with the quest being done & there are no more conditions.
				local fOrConditionText = zo_strformat(SI_QUEST_OR_CONDITION_FORMAT, conditionText)
				AddTooltipLine(tooltip, fOrConditionText, true)
			elseif conditionText ~= "TRACKER GOAL TEXT" then
				local fConditionText = conditionText
				AddTooltipLine(tooltip, fConditionText, true)
			end
		end
	end
end

-- Adds all step (and calls to add condition) text to the tooltip
local function AddStepsToTooltip(self, tooltip, journalQuestIndex, tStepsByVisibility, stepVisibility)
	local iQuestStepFormatSI = SI_QUEST_JOURNAL_TEXT
	local next = next

	-- no steps to complete, return
	if next(tStepsByVisibility[stepVisibility]) == nil then
		return
	end

	-- Setup headers for Hints & optional steps:
	if stepVisibility == QUEST_STEP_VISIBILITY_HINT then
		local fStepHintHeader = self.color.yellow .. GetString(SI_QUEST_HINT_STEP_HEADER) .. "|r"
		AddTooltipLine(tooltip, fStepHintHeader, false)

		iQuestStepFormatSI = SI_QUEST_HINT_STEP_FORMAT
	elseif stepVisibility == QUEST_STEP_VISIBILITY_OPTIONAL then
		local fOptionalStepHeader = self.color.yellow .. GetString(SI_QUEST_OPTIONAL_STEPS_DESCRIPTION) .. " |r"
		AddTooltipLine(tooltip, fOptionalStepHeader, false)
	end

	for k, stepIndex in pairs(tStepsByVisibility[stepVisibility]) do
		local stepText, visibility, stepType, trackerOverrideText, numConditions = GetJournalQuestStepInfo(journalQuestIndex, stepIndex)

		if stepText and stepText ~= "" then
			local fStepText = zo_strformat(iQuestStepFormatSI, stepText)
			AddTooltipLine(tooltip, fStepText, false)

			ZO_Tooltip_AddDivider(tooltip)
			tooltip:AddVerticalPadding(10)
		end

		local conditionsAreOR = stepType == QUEST_STEP_TYPE_OR and numConditions > 1

		-- Sets up the header for the or condition when you have multiple condition choices and only have to complete one.
		if conditionsAreOR then
			local fOrStepHeader = self.color.yellow .. GetString(SI_QUEST_OR_DESCRIPTION) .. "|r"
			AddTooltipLine(tooltip, fOrStepHeader, false)
		end

		-- Add all needed condition text for this step to the tooltip
		AddStepConditionsToTooltip(tooltip, journalQuestIndex, stepIndex, numConditions, stepVisibility, conditionsAreOR, trackerOverrideText)
		--[[
		-- If its the end of the quest nothing left, so display that.
		if stepType == QUEST_STEP_TYPE_END  then
			local fEndOfQuest = WAYPOINTIT.color.yellow.."End of quest|r"
			AddTooltipLine(tooltip, fEndOfQuest, true)
		end
		--]]
	end
end

--[[ Used to update the group member tooltip with unit info -- ]]
function WaypointIt:UpdateTooltipWithGroupInfo(m_Pin, tooltip)
	local unitTag = m_Pin:GetUnitTag()
	local level = GetUnitLevel(unitTag)
	local title = GetUnitTitle(unitTag)
	local gender = GetUnitGender(unitTag)
	local rank, subRank = GetUnitAvARank(unitTag)
	local classId = GetUnitClassId(unitTag)
	local classIcon = GetClassIcon(classId)
	local rankIcon = GetAvARankIcon(rank)

	-- Get data that requires formatting:
	local sName = ZO_CachedStrFormat(SI_UNIT_NAME, GetUnitName(unitTag))
	local className = ZO_CachedStrFormat(SI_CLASS_NAME, GetUnitClass(unitTag))
	local race = ZO_CachedStrFormat(SI_RACE_NAME, GetUnitRace(unitTag))
	local rankName = ZO_CachedStrFormat(SI_STAT_RANK_NAME_FORMAT, GetAvARankName(gender, rank))

	-- May use this later
	-- local healthState = GetUnitStealthState(unitTag)

	local green = WAYPOINTIT.color.green
	local red = WAYPOINTIT.color.red
	local yellow = WAYPOINTIT.color.yellow
	local darkOrange = WAYPOINTIT.color.darkOrange

	if IsUnitDead(unitTag) then
		sName = red .. ZO_CachedStrFormat(SI_TOOLTIP_UNIT_DEAD, sName) .. "|r"
	elseif IsUnitInCombat(unitTag) then
		sName = yellow .. sName .. " (in " .. GetString(SI_AUDIO_OPTIONS_COMBAT) .. ")|r"
	elseif IsUnitFriend(unitTag) then
		sName = green .. sName .. " (" .. GetString(SI_WINDOW_TITLE_FRIENDS_LIST) .. ")|r"
	end
	if IsUnitGroupLeader(unitTag) then
		sName = sName .. "\n" .. darkOrange .. " (" .. GetString(SI_GROUP_LEADER_TOOLTIP) .. ")|r"
	end

	ZO_Tooltip_AddDivider(tooltip)

	--[[
	if IsUnitGroupLeader(unitTag) then
		AddTooltipLine(tooltip, green..GetString(SI_GROUP_LEADER_TOOLTIP).."|r", true)
	end
	--]]
	-- sName is already formatted:
	AddTooltipLine(tooltip, yellow .. GetString(SI_ADDON_MANAGER_NAME) .. ":|r " .. sName, true)

	if title and title ~= "" then
		-- I could find no SI_ for formatting the title:
		AddTooltipLine(tooltip, yellow .. GetString(SI_STATS_TITLE) .. ":|r " .. title, true)
	end
	ZO_Tooltip_AddDivider(tooltip)

	-- className & race are already formatted:
	AddTooltipLine(tooltip, yellow .. GetString(SI_FRIENDS_LIST_PANEL_TOOLTIP_CLASS) .. ":|r " .. className, true)
	AddTooltipLine(tooltip, yellow .. GetString(SI_STAT_GAMEPAD_RACE_LABEL) .. ":|r " .. race, true)

	AddTooltipLine(tooltip, yellow .. GetString(SI_EXPERIENCE_LEVEL_LABEL) .. ":|r " .. level, true)
	if IsUnitVeteran(unitTag) then
		local vetRank = GetUnitVeteranRank(unitTag)
		AddTooltipLine(tooltip, yellow .. GetString(SI_EXPERIENCE_VETERAN_RANK_LABEL) .. "|r " .. vetRank, true)
	end
	ZO_Tooltip_AddDivider(tooltip)

	-- AddTooltipLine(tooltip, yellow.."Rank:|r ("..rank..") ".."|t35:35:"..rankIcon.."|t "..rankName, true)

	-- rankName already formatted
	AddTooltipLine(tooltip, yellow .. GetString(SI_QUESTTYPE7) .. " " .. GetString(SI_GUILD_TOOLTIP_RANK) .. ":|r (" .. rank .. ") " .. rankName, true)
	-- AddTooltipLine(tooltip, yellow.."Rank Name:|r "..rankName, true)
	AddTooltipLine(tooltip, yellow .. "SubRank:|r " .. subRank, true)
end

-- Makes calls to add all of the extra information to the tooltip for quests
-- It leaves the mapPin tooltip (objective name) at the top
function WaypointIt:UpdateTooltipWithPinInfo(m_Pin, tooltip)
	local journalQuestIndex = m_Pin:GetQuestIndex()
	local sQuestZoneName = GetJournalQuestLocationInfo(journalQuestIndex)
	local sQuestName, backgroundText, _, _, _, _, _, iLevel, _, _, _ = GetJournalQuestInfo(journalQuestIndex)

	-- Con Color Definition for formatting Questname & level
	local conColorDef = ZO_ColorDef:New(GetConColor(iLevel))

	-- The objective is already in the tooltip, start with a divider
	ZO_Tooltip_AddDivider(tooltip)

	-------------------------------------------------
	------- Basic Quest Info: Top section  ----------
	-------------------------------------------------
	local fQuestName = string.format("%sQuest Name:|r %s", WAYPOINTIT.color.yellow, conColorDef:Colorize(ZO_CachedStrFormat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, sQuestName)))
	AddTooltipLine(tooltip, fQuestName, false)

	local fZoneName = ZO_CachedStrFormat(SI_ZONE_NAME, sQuestZoneName)

	if not fZoneName or fZoneName == "" then
		fZoneName = WAYPOINTIT.color.yellow .. GetString(SI_WINDOW_TITLE_WORLD_MAP_NO_ZONE)
	else
		fZoneName = string.format("%s%s:|r %s", WAYPOINTIT.color.yellow, GetString(SI_CHAT_CHANNEL_NAME_ZONE), fZoneName)
	end
	AddTooltipLine(tooltip, fZoneName, true)

	local fLevel = conColorDef:Colorize(ZO_CachedStrFormat(SI_QUEST_JOURNAL_QUEST_LEVEL, tostring(iLevel)))
	AddTooltipLine(tooltip, fLevel, true)

	local fRepeatText = GetRepeatableTooltipText(self, journalQuestIndex)
	if fRepeatText then
		AddTooltipLine(tooltip, fRepeatText, true)
	end

	local fInstanceText = GetInstanceTooltipText(self, journalQuestIndex)
	if fInstanceText then
		AddTooltipLine(tooltip, fInstanceText, true)
	end

	-------------------------------------------------
	-- Add a divider before background text	---------
	-------------------------------------------------
	ZO_Tooltip_AddDivider(tooltip)

	-------------------------------------------------
	------------- Background text -------------------
	-------------------------------------------------
	local fBackgroundText = string.format("%sBackground: |r%s", WAYPOINTIT.color.yellow, zo_strformat(SI_QUEST_JOURNAL_MAIN_STORY_FORMAT, backgroundText))
	AddTooltipLine(tooltip, fBackgroundText, false)

	-------------------------------------------------
	-- No divider between background & step text
	-------------------------------------------------

	-------------------------------------------------
	-------- Add step & condition text --------------
	-------------------------------------------------
	-- Grab an organized table of step indices. It organizes steps
	-- based on visibility, so I can print out required steps first,
	-- then optional steps, then hints
	local tStepsByVisibility = GetStepsByVisibility(journalQuestIndex)
	local next = next

	-- Each also make a call to print their own condition
	-- no steps to complete, return
	if next(tStepsByVisibility[QUEST_STEP_VISIBILITY_HIDDEN]) ~= nil then
		ZO_Tooltip_AddDivider(tooltip)
		AddStepsToTooltip(self, tooltip, journalQuestIndex, tStepsByVisibility, QUEST_STEP_VISIBILITY_HIDDEN)
	end
	if next(tStepsByVisibility[QUEST_STEP_VISIBILITY_OPTIONAL]) ~= nil then
		ZO_Tooltip_AddDivider(tooltip)
		AddStepsToTooltip(self, tooltip, journalQuestIndex, tStepsByVisibility, QUEST_STEP_VISIBILITY_OPTIONAL)
	end
	if next(tStepsByVisibility[QUEST_STEP_VISIBILITY_HINT]) ~= nil then
		ZO_Tooltip_AddDivider(tooltip)
		AddStepsToTooltip(self, tooltip, journalQuestIndex, tStepsByVisibility, QUEST_STEP_VISIBILITY_HINT)
	end
end
