if VOTANS_MINIMAP then
	return
end

local addon = {
	name = "VotansMiniMap",
	isSpecialZoom = false
}

local am = GetAnimationManager()
local em = GetEventManager()
local async = LibAsync

MAP_MODE_VOTANS_MINIMAP = 41

local MAP_MODE_VOTANS_MINIMAP = MAP_MODE_VOTANS_MINIMAP

local dbg
do
	local log = LibDebugLogger and LibDebugLogger(addon.name)

	dbg = log and function(...)
			log:Debug(...)
		end or df
end

local function NoOp()
end

local function GetScene()
	return IsInGamepadPreferredMode() and GAMEPAD_WORLD_MAP_SCENE or WORLD_MAP_SCENE
end

local function FakeIsInGamepadPreferredMode()
	return false
end

local function NoGamepad(func, ...)
	local orgIsInGamepadPreferredMode = IsInGamepadPreferredMode
	IsInGamepadPreferredMode = FakeIsInGamepadPreferredMode
	func(...)
	IsInGamepadPreferredMode = orgIsInGamepadPreferredMode
end

addon.pinManager = ZO_WorldMap_GetPinManager()
addon.panZoom = ZO_WorldMap_GetPanAndZoom()
function addon:GetCurrentZoom()
	return self.panZoom:GetCurrentNormalizedZoom()
end
function addon:SetCurrentZoom(zoom)
	return self.panZoom:SetCurrentNormalizedZoom(zoom)
end

function addon:InitTweaks()
	do
		local task = async:Create("VOTAN_RefreshAllPOIs")

		local zoneIndex
		local POI_TYPE_GROUP_DUNGEON, POI_TYPE_WAYSHRINE, MAP_PIN_TYPE_POI_SEEN = POI_TYPE_GROUP_DUNGEON, POI_TYPE_WAYSHRINE, MAP_PIN_TYPE_POI_SEEN

		local createTag
		local function DrawPin(poiIndex)
			local xLoc, zLoc, iconType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)

			if isShownInCurrentMap and (isDiscovered or isNearby) and ZO_MapPin.POI_PIN_TYPES[iconType] then
				local poiType = GetPOIType(zoneIndex, poiIndex)

				if iconType ~= MAP_PIN_TYPE_POI_SEEN then
					-- Seen Wayshines are POIs, discovered Wayshrines are handled by AddWayshrines()
					-- Request was made by design to have houses and dungeons behave like wayshrines.
					if poiType == POI_TYPE_WAYSHRINE or poiType == POI_TYPE_HOUSE or poiType == POI_TYPE_GROUP_DUNGEON then
						return
					end
				end

				local pinManager = addon.pinManager
				-- RefreshSinglePOI could be called inbetween
				pinManager:RemovePins("poi", zoneIndex, poiIndex)
				local worldEventInstanceId = GetPOIWorldEventInstanceId(zoneIndex, poiIndex)
				if worldEventInstanceId ~= 0 then
					pinManager:RemovePins("worldEventPOI", worldEventInstanceId)
				end

				local tag = createTag(zoneIndex, poiIndex, icon, linkedCollectibleIsLocked)
				pinManager:CreatePin(iconType, tag, xLoc, zLoc)

				if worldEventInstanceId ~= 0 then
					local worldEventTag = ZO_MapPin.CreateWorldEventPOIPinTag(worldEventInstanceId, zoneIndex, poiIndex)
					-- TODO: May need to add handling for additional event states
					pinManager:CreatePin(MAP_PIN_TYPE_WORLD_EVENT_POI_ACTIVE, worldEventTag, xLoc, zLoc)
				end
			end
		end

		local function RemovePins(task)
			addon.pinManager:RemovePins("poi")
			addon.pinManager:RemovePins("worldEventPOI")

			zoneIndex = GetCurrentMapZoneIndex()
			if zoneIndex <= 1 or zoneIndex >= 2147483648 then
				return
			end
			if not ZO_WorldMap_IsPinGroupShown(MAP_FILTER_OBJECTIVES) then
				return
			end
			task:For(1, GetNumPOIs(zoneIndex)):Do(DrawPin)
		end
		function ZO_WorldMap_RefreshAllPOIs()
			createTag = ZO_MapPin.CreatePOIPinTag
			task:Cancel():StopTimer():Call(RemovePins)
		end
	end

	do
		local task = async:Create("VOTAN_RefreshWayshrines")

		local function IsShowingCosmicMap()
			return GetMapType() == MAPTYPE_COSMIC
		end

		local function IsNormalizedPointInsideMapBounds(x, y)
			return x > 0 and x < 1 and y > 0 and y < 1
		end
		local orgZO_WorldMap_PanToWayshrine = ZO_WorldMap_PanToWayshrine
		local running = false
		local pendingWayshrineNode = nil
		local function GoPendingWayshrine()
			running = false
			if pendingWayshrineNode then
				orgZO_WorldMap_PanToWayshrine(pendingWayshrineNode)
				pendingWayshrineNode = nil
			end
		end

		local MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC = MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC
		local MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE = MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE
		local createTag, nodeInfo, g_fastTravelNodeIndex = ZO_MapPin.CreateTravelNetworkPinTag, GetFastTravelNodeInfo
		local function DrawPin(nodeIndex)
			local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked = nodeInfo(nodeIndex)

			if known and isLocatedInCurrentMap and IsNormalizedPointInsideMapBounds(normalizedX, normalizedY) then
				local isCurrentLoc = g_fastTravelNodeIndex == nodeIndex
				if isCurrentLoc then
					glowIcon = nil
				end

				local pinType = isCurrentLoc and MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC or MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE

				addon.pinManager:CreatePin(pinType, createTag(nodeIndex, icon, glowIcon, linkedCollectibleIsLocked), normalizedX, normalizedY)
			end
		end
		local function RemovePins(task)
			addon.pinManager:RemovePins("fastTravelWayshrine")
			-- Dungeons no longer show wayshrines of any kind (possibly pending some system rework)
			-- Design rule, don't show wayshrine pins on cosmic, even if they're in the map
			if IsShowingCosmicMap() or not ZO_WorldMap_IsPinGroupShown(MAP_FILTER_WAYSHRINES) then
				return
			end
			createTag, nodeInfo, g_fastTravelNodeIndex = ZO_MapPin.CreateTravelNetworkPinTag, GetFastTravelNodeInfo, ZO_Map_GetFastTravelNode()
			task:For(1, GetNumFastTravelNodes()):Do(DrawPin)
		end
		function ZO_WorldMap_RefreshWayshrines()
			running = true
			task:Cancel():Call(RemovePins):Then(GoPendingWayshrine)
		end
		function ZO_WorldMap_PanToWayshrine(nodeIndex)
			if running then
				pendingWayshrineNode = nodeIndex
			else
				pendingWayshrineNode = nil
				return orgZO_WorldMap_PanToWayshrine(nodeIndex)
			end
		end
		local orgZO_WorldMap_SetMapByIndex = WORLD_MAP_MANAGER.SetMapByIndex
		function WORLD_MAP_MANAGER.SetMapByIndex(self, mapIndex)
			running = running or GetCurrentMapIndex() ~= mapIndex
			return orgZO_WorldMap_SetMapByIndex(self, mapIndex)
		end
	end

	if ZO_MapLocationPins_Manager then
		local task = async:Create("VOTAN_RefreshLocations")

		local locations
		local function DrawPin(i)
			locations:AddLocation(i)
		end
		local function releaseAllObjects()
			locations:ReleaseAllObjects()
		end
		local function removePins(task)
			addon.pinManager:RemovePins("loc")
			task:For(1, GetNumMapLocations()):Do(DrawPin)
		end
		local function delayStart(task)
			task:Call(releaseAllObjects):Then(removePins)
		end
		local function start(task)
			if GetScene():IsShowing() then
				task:Delay(25, delayStart)
			else
				task:Delay(200, delayStart)
			end
		end
		function ZO_MapLocationPins_Manager:RefreshLocations()
			locations = self
			task:Cancel():Call(start)
		end
	end

	local function DeferRefresh(methodName, identifier, delay)
		local task = async:Create("VOTAN_" .. identifier)
		local orgMethod = _G[methodName]
		local function runRefresh(task)
			task:Call(orgMethod)
		end
		_G[methodName] = function()
			task:Cancel():Delay(GetScene():IsShowing() and 0 or (delay * 7), runRefresh)
		end
	end
	--DeferRefresh("ZO_WorldMap_RefreshWorldEvent", "MAP_RefreshWorldEvent", 50)
	DeferRefresh("ZO_WorldMap_RefreshWorldEvents", "MAP_RefreshWorldEvents", 50)
	DeferRefresh("ZO_WorldMap_RefreshObjectives", "MAP_RefreshObjectives", 50)
	DeferRefresh("ZO_WorldMap_RefreshKeeps", "MAP_RefreshKeeps", 30)
	DeferRefresh("ZO_WorldMap_RefreshKillLocations", "MAP_RefreshKillLocations", 60)
	DeferRefresh("ZO_WorldMap_RefreshWayshrines", "MAP_RefreshWayshrines", 10)
	DeferRefresh("ZO_WorldMap_RefreshForwardCamps", "MAP_RefreshForwardCamps", 70)
	DeferRefresh("ZO_WorldMap_RefreshAccessibleAvAGraveyards", "MAP_RefreshAccessibleAvAGraveyards", 80)

	do
		local task = async:Create("VOTANS_MAP_CUSTOM_PIN_UPDATE")
		local function OnError(err)
			d("Error in custom pin addon", err)
		end
		task:OnError(OnError)
		local refreshPinType = {}

		local GetFrameTimeSeconds, GetGameTimeSeconds = GetFrameTimeSeconds, GetGameTimeSeconds
		local pins
		local function drawPin(pinTypeId, pinData)
			-- self:RemovePins(pinData.pinTypeString)
			if pinData.enabled and refreshPinType[pinTypeId] then
				local runTime = GetGameTimeSeconds()
				refreshPinType[pinTypeId] = nil
				pinData.layoutCallback(pins)
				if async:GetDebug() then
					local start, now = GetFrameTimeSeconds(), GetGameTimeSeconds()
					local freezeTime = now - start
					runTime = now - runTime
					if freezeTime > 0.016 then
						dbg("%s Freeze!!! used %ims, new frametime %ims", pinData.pinTypeString, runTime * 1000, freezeTime * 1000)
					end
				end
			end
		end
		local function drawPins(self)
			task:For(pairs(refreshPinType)):Do(drawPin)
		end
		local function removePinType(pinTypeId, pinData)
			pins:RemovePins(pinData.pinTypeString)
			refreshPinType[pinTypeId] = pinData
		end
		local function startDrawPins()
			drawPins(pins)
		end

		function ZO_WorldMapPins_Manager:RefreshCustomPins(optionalPinType)
			pins = self
			if optionalPinType then
				local pinData = self.customPins[optionalPinType]
				if pinData then
					refreshPinType[optionalPinType] = pinData
				else
					return
				end
			else
				for pinTypeId, pinData in pairs(self.customPins) do
					refreshPinType[pinTypeId] = pinData
				end
			end
			task:Cancel():For(pairs(refreshPinType)):Do(removePinType):Then(startDrawPins)
		end
	end

	do
		local task = async:Create("VOTANS_MAP_UPDATE_MAP_SIZE_CHANGE")
		local orgUpdatePinsForMapSizeChange = ZO_WorldMapPins_Manager.UpdatePinsForMapSizeChange
		local lastW, lastH, lastZone = -1, -1, -1
		local pins, w, h
		local function updateLocationAndSize(pinKey, pin)
			pin:UpdateLocation()
			pin:UpdateSize()
		end
		local function callResizeCallback(pinTypeId, pinData)
			if (pinData.enabled and pinData.resizeCallback) then
				pinData.resizeCallback(pins, w, h)
			end
		end
		local function resizePins(task)
			local pinControls = pins:GetActiveObjects()
			task:For(pairs(pinControls)):Do(updateLocationAndSize):For(pairs(pins.customPins)):Do(callResizeCallback)
		end
		local function updatePlayerPinLevel()
			local control = addon.pinManager.playerPin:GetControl()
			local labelControl = control:GetNamedChild("Label")
			local overlayControl = control:GetNamedChild("Background")
			local highlightControl = control:GetNamedChild("Highlight")
			local pinLevel = zo_max(ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_PLAYER].level, 1)
			control:SetDrawLevel(pinLevel)
			overlayControl:SetDrawLevel(pinLevel)
			highlightControl:SetDrawLevel(pinLevel - 1)
			labelControl:SetDrawLevel(pinLevel + 1)
		end
		function ZO_WorldMapPins_Manager:UpdatePinsForMapSizeChange()
			w, h = ZO_WorldMapContainer:GetDimensions()
			local zone = GetMapTileTexture()
			if lastW ~= w or lastH ~= h or lastZone ~= zone then
				lastW, lastH, lastZone, pins = w, h, zone, self

				task:StopTimer():Cancel()

				updatePlayerPinLevel()

				if GetScene():IsShowing() then
					return orgUpdatePinsForMapSizeChange(self)
				end

				task:Call(resizePins):Delay(50)
			end
		end
	end

	---- Delaying ZO_WorldMap_UpdateMap is a bad idea, because it breaks zoom sliders.
	do
		local function roundGet(control, funcName)
			local org = control[funcName]
			control[funcName] = function(self)
				-- w and h jitter in decimals.
				local w, h = org(self)
				w, h = zo_round(w * 2 + 0.5) * 0.5, zo_round(h * 2 + 0.5) * 0.5
				return w, h
			end
		end
		local function roundSet(control, funcName)
			local org = control[funcName]
			control[funcName] = function(self, w, h)
				-- w and h jitter in decimals.
				w, h = zo_round(w * 2 + 0.5) * 0.5, zo_round(h * 2 + 0.5) * 0.5
				return org(self, w, h)
			end
		end
		roundGet(ZO_WorldMapContainer, "GetDimensions")
		roundSet(ZO_WorldMapContainer, "SetDimensions")
		roundGet(ZO_WorldMapScroll, "GetDimensions")
		roundSet(ZO_WorldMapScroll, "SetDimensions")
	end
end

function addon:InitRequiredModifications()
	local orgUpdatePinsForMapSizeChange = ZO_WorldMapPins_Manager.UpdatePinsForMapSizeChange
	local lastW, lastH, lastZone = -1, -1, -1
	function ZO_WorldMapPins_Manager:UpdatePinsForMapSizeChange()
		local w, h = ZO_WorldMapContainer:GetDimensions()
		w, h = zo_round(w), zo_round(h)
		local zone = GetMapTileTexture()
		if lastW ~= w or lastH ~= h or lastZone ~= zone then
			lastW, lastH, lastZone = w, h, zone
			return orgUpdatePinsForMapSizeChange(self)
		end
	end
end

function addon:InitCameraAngle()
	if self.cameraAngleLeft then
		return
	end
	local playerPin = self.pinManager:GetPlayerPin()
	local playerControl = playerPin:GetControl()
	local parent = playerControl:GetParent()
	local function setupCameraAngle(control)
		control:SetTexture("VotansMiniMap/ViewLimit.dds")
		control:SetDimensions(4, 64)
		control:SetAnchor(BOTTOM, playerControl, CENTER)
		control:SetHidden(not self.account.showCameraAngle)
		control:SetPixelRoundingEnabled(true)
		control:SetDrawLayer(DL_TEXT)
	end
	local control
	control = CreateControl("$(parent)ViewLimitLeft", parent, CT_TEXTURE)
	setupCameraAngle(control)
	self.cameraAngleLeft = control
	control = CreateControl("$(parent)ViewLimitRight", parent, CT_TEXTURE)
	setupCameraAngle(control)
	self.cameraAngleRight = control

	self.cameraAngleRad = self.account.cameraAngle * 0.0174532925199 -- pi/180°
	local orgSetHidden = playerControl.SetHidden
	local function setHiddenPlayerPin(pin, hidden)
		local noViewLimit = hidden or not self.account.showCameraAngle
		self.cameraAngleLeft:SetHidden(noViewLimit)
		self.cameraAngleRight:SetHidden(noViewLimit)
		return orgSetHidden(pin, hidden)
	end
	playerControl.SetHidden = setHiddenPlayerPin
	local orgSetRotation = playerPin.SetRotation
	function playerPin.SetRotation(...)
		if self.account.showCameraAngle then
			local pin = ...
			local heading = select(3, GetMapPlayerPosition("player"))
			return orgSetRotation(pin, heading)
		else
			return orgSetRotation(...)
		end
	end
end

function addon:InitMiniMap()
	do
		local orgZO_WorldMap_GetMapDimensions = ZO_WorldMap_GetMapDimensions
		function ZO_WorldMap_GetMapDimensions()
			if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				return ZO_WorldMapContainer:GetDimensions()
			else
				return orgZO_WorldMap_GetMapDimensions()
			end
		end
	end
	-- Used by GoToWorldMapMode, too
	local orgUpdateSize = ZO_MapPin.UpdateSize

	local scale = 1
	local limitedScale = 1
	local blacklistedPins = {}
	for _, list in pairs({ZO_MapPin.UNIT_PIN_TYPES}) do
		for pinType in pairs(list) do
			blacklistedPins[pinType] = true
		end
	end
	function addon:CalculateScale(pinType)
		return not blacklistedPins[pinType] and scale or limitedScale
	end

	local orgzo_max, factor
	local function newMax(a, ...)
		return orgzo_max(a * factor, ...)
	end
	local function newUpdateSize(self)
		if self.radius and self.radius > 0 then
			return orgUpdateSize(self)
		end
		local pinType = self:GetPinType()
		local singlePinData = ZO_MapPin.PIN_DATA[pinType]
		if not singlePinData then
			return orgUpdateSize(self)
		end
		local orgSize, orgMinSize = singlePinData.size or 20, singlePinData.minSize
		local scale = addon:CalculateScale(pinType)
		singlePinData.size, singlePinData.minSize = orgSize * scale, orgMinSize and orgMinSize * scale or nil
		orgUpdateSize(self)
		singlePinData.size, singlePinData.minSize = orgSize, orgMinSize
	end

	function addon.ShowClock()
		local self = addon

		local account = self.account
		if account.showRealTimeClock then
			self.clockRealTime:SetText(FormatTimeSeconds(GetSecondsSinceMidnight(), TIME_FORMAT_STYLE_CLOCK_TIME, self.account.timeFormat, TIME_FORMAT_DIRECTION_NONE))
		else
			self.clockRealTime:SetText("")
		end

		if account.showInGameClock then
			local igSecondsPerDay = 20955
			local rlTimeStamp = GetTimeStamp()
			local inGameTime = (rlTimeStamp % igSecondsPerDay) * 86400 / igSecondsPerDay
			self.clockInGame:SetText(FormatTimeSeconds(inGameTime, TIME_FORMAT_STYLE_CLOCK_TIME, self.account.timeFormat, TIME_FORMAT_DIRECTION_NONE))
		else
			self.clockInGame:SetText("")
		end
	end

	local vars = addon.mapVars
	local myMode = vars[MAP_MODE_VOTANS_MINIMAP]
	if not myMode then
		myMode = ZO_DeepTableCopy(vars[MAP_MODE_SMALL_CUSTOM])
		vars[MAP_MODE_VOTANS_MINIMAP] = myMode
		myMode.width, myMode.height = 301, 363
	end
	myMode.mapSize = 2 -- CONSTANTS.WORLDMAP_SIZE_SMALL

	-- Map Pin Filter checked-state is the same
	local filters = vars[MAP_MODE_LARGE_CUSTOM].filters
	myMode.filters[1] = filters[1]
	myMode.filters[2] = filters[2]
	myMode.filters[3] = filters[3]

	self.modeData = myMode
	if self.account.keepSquare ~= nil then
		self.modeData.keepSquare = self.account.keepSquare
	else
		self.account.keepSquare = self.modeData.keepSquare
	end

	ZO_WorldMapTitleBarBG:SetColor(0, 0, 0, 0)
	ZO_WorldMapButtonsBG:SetColor(0, 0, 0, 0)
	ZO_WorldMapButtonsBG:SetHandler("OnDragStart", ZO_WorldMapTitleBar_OnDragStart)
	ZO_WorldMapButtonsBG:SetHandler(
		"OnMouseUp",
		function(self, button, upInside)
			ZO_WorldMapTitleBar_OnMouseUp(button, upInside)
		end
	)

	local wm = GetWindowManager()
	local control = wm:CreateControl("VotanMiniMapBg", ZO_WorldMap, CT_BACKDROP)
	control:SetAnchor(TOPLEFT, nil, TOPLEFT, -8, -4)
	control:SetAnchor(BOTTOMRIGHT, ZO_WorldMapButtons, BOTTOMRIGHT, 8, 4)
	control:SetExcludeFromResizeToFitExtents(true)
	self.background = control
	self:UpdateBorder()
	WORLD_MAP_FRAGMENT:SetAllowShowHideTimeUpdates(true)
	WORLD_MAP_FRAGMENT.alwaysAnimate = true
	WORLD_MAP_FRAGMENT.duration = 0

	ZO_WorldMap:SetClampedToScreenInsets(4, 29, -4, -40)

	control = CreateControl("$(parent)ClockRealTime", self.background, CT_LABEL)
	self.clockRealTime = control
	control:SetFont("ZoFontWindowTitle")
	control:SetDimensionConstraints(66, 37, 0, 0)
	control:SetAnchor(BOTTOMLEFT, nil, BOTTOMLEFT, 14, -4)

	control = CreateControl("$(parent)ClockInGame", self.background, CT_LABEL)
	self.clockInGame = control
	control:SetFont("ZoFontWindowSubtitle")
	control:SetDimensionConstraints(66, 32, 0, 0)
	control:SetAnchor(BOTTOMLEFT, self.clockRealTime, BOTTOMRIGHT, 6, -2)
	control:SetVerticalAlignment(BOTTOM)

	self.cameraAngleRad = 0

	if self.account.showCameraAngle then
		self:InitCameraAngle()
	end

	local function PlayerActivated()
		self:UpdateVisibility()
		addon.cameraAngle = 0
		addon:GoMiniMapMode(true)
	end
	local function PlayerDeactivated()
		addon:StopFollowPlayer()
	end
	em:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, PlayerActivated)
	em:RegisterForEvent(self.name, EVENT_PLAYER_DEACTIVATED, PlayerDeactivated)

	local function RestorePosition()
		-- Skip full update for just setting new position
		local orgZO_WorldMap_UpdateMap = ZO_WorldMap_UpdateMap
		ZO_WorldMap_UpdateMap = NoOp

		ZO_WorldMap_OnResizeStart(ZO_WorldMap)

		local sv = addon.modeData
		local UIWidth, UIHeight = GuiRoot:GetDimensions()

		ZO_WorldMap:ClearAnchors()
		ZO_WorldMap:SetDimensionConstraints(128, 144, UIWidth, UIHeight)
		ZO_WorldMap:SetAnchor(CENTER, nil, CENTER, self.account.x or (UIWidth / 2 - 300), self.account.y or (UIHeight / 2 - 363))
		ZO_WorldMap:SetDimensions(self.account.width or sv.width or 300, self.account.height or sv.height or 363)

		ZO_WorldMap_OnResizeStop(ZO_WorldMap)
		ZO_WorldMap_UpdateMap = orgZO_WorldMap_UpdateMap
	end

	local function SaveMapPosition()
		local cx, cy = GuiRoot:GetCenter()
		local x, y = ZO_WorldMap:GetCenter()
		x, y = x - cx, y - cy

		local sv = addon.modeData
		sv.x, sv.y = x, y
		sv.width, sv.height = ZO_WorldMap:GetDimensions()
		self.account.x, self.account.y = x, y
		self.account.width, self.account.height = ZO_WorldMap:GetDimensions()
	end

	local function StateChanged()
		self:UpdateVisibility()
	end
	em:RegisterForEvent(addon.name, EVENT_PLAYER_COMBAT_STATE, StateChanged)
	em:RegisterForEvent(addon.name, EVENT_MOUNTED_STATE_CHANGED, StateChanged)

	local lastZoom, lastW, lastH = -1, -1, -1
	em:RegisterForEvent(
		addon.name,
		EVENT_GAMEPAD_PREFERRED_MODE_CHANGED,
		function()
			lastZoom, lastW, lastH = -1, -1, -1
			ZO_WorldMap_InteractKeybindForceHidden(true)
			self:UpdateVisibility()
			self:UpdateBorder()
			if IsInGamepadPreferredMode() then
				RestorePosition()
				local ZO_MapPanAndZoom = ZO_WorldMap_GetPanAndZoom()
				NoGamepad(ZO_MapPanAndZoom.SetCurrentNormalizedZoomInternal, ZO_MapPanAndZoom, ZO_MapPanAndZoom.currentNormalizedZoom)
			end
		end
	)
	em:RegisterForEvent(
		addon.name,
		EVENT_SCREEN_RESIZED,
		function()
			if IsInGamepadPreferredMode() and not ZO_WorldMap_IsWorldMapShowing() then
				ZO_WorldMap_UpdateMap()
			end
		end
	)

	local MoveToPlayer = ZO_WorldMap_PanToPlayer
	local function AdjustZoom()
		local x, y = GetMapPlayerPosition("player")
		local numTiles = GetMapNumTiles()
		local tilePixelWidth = ZO_WorldMapContainer1 and ZO_WorldMapContainer1:GetTextureFileDimensions() or 1
		local totalPixels = numTiles * tilePixelWidth
		local w, h = ZO_WorldMapScroll:GetDimensions()
		w, h = zo_round(w), zo_round(h)
		local mapAreaUIUnits = zo_min(w, h)
		local mapAreaPixels = mapAreaUIUnits * GetUIGlobalScale()
		if mapAreaPixels < 1 then
			mapAreaPixels = 1
		end

		local mode, targetScale
		local mapType = GetMapContentType()
		if addon.isSpecialZoom then
			mode = "specialZoom"
			targetScale = addon.specialZoom
		elseif mapType == MAP_CONTENT_BATTLEGROUND then
			mode = "battlegroundZoom"
			targetScale = addon.account.battlegroundZoom
		elseif mapType == MAP_CONTENT_DUNGEON then
			mode = "dungeonZoom"
			targetScale = addon.account.dungeonZoom
		elseif GetMapType() == MAPTYPE_SUBZONE then
			mode = "subZoneZoom"
			targetScale = addon.account.subZoneZoom
		else
			mode = "zoom"
			targetScale = addon.account.zoom
		end
		if IsMounted() and addon.account.mountedZoom ~= 1 then
			targetScale = targetScale * addon.account.mountedZoom
			mode = "mountedZoom"
		end

		local r = zo_max(w, h) / mapAreaUIUnits
		local maxZoomToStayBelowNative = math.floor((totalPixels / mapAreaPixels - r) * 500 * targetScale) / 500 + r
		if lastZoom ~= maxZoomToStayBelowNative or addon.zoomMode ~= mode or w ~= lastW or h ~= lastH then
			addon.zoomMode = mode
			MoveToPlayer = ZO_WorldMap_JumpToPlayer
			scale = math.min(math.max(0.6, targetScale * 0.75), 1)
			limitedScale = math.max(scale, addon.account.unitPinScaleLimit)
			ZO_MapPin.UpdateSize = newUpdateSize

			self.modeData.mapZoom, self.scale, self.limitedScale = maxZoomToStayBelowNative, scale, limitedScale

			lastZoom, lastW, lastH = maxZoomToStayBelowNative, w, h
			self.panZoom:SetMapZoomMinMax(self.panZoom:ComputeMinZoom(), maxZoomToStayBelowNative)
		end
	end
	local orgGetMapCustomMaxZoom = GetMapCustomMaxZoom
	function GetMapCustomMaxZoom(...)
		if not WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
			lastW, lastH, lastZoom = -1, -1, -1
			return orgGetMapCustomMaxZoom(...)
		else
			if lastZoom < 0 then
				AdjustZoom()
			end
			return lastZoom
		end
	end
	local orgCanMapZoom = self.panZoom.CanMapZoom
	function self.panZoom.CanMapZoom(...)
		return orgCanMapZoom(...) or WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP)
	end

	local asyncCallbacks = async:Create("VOTANS_MAP_DO_CALLBACKS")
	local runningCallbacks
	local function StopCallbacks()
		if not runningCallbacks then
			asyncCallbacks:Cancel()
		end
		self.panZoom:ClearJumpToPinWhenAvailable()
	end
	CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", StopCallbacks)

	local isWaitingForTexture = false
	local function WaitForTexture()
		if not self.panZoom:CanInitializeMap() then
			asyncCallbacks:Suspend()
			isWaitingForTexture = true
		end
	end

	local function WaitForTextureLoaded()
		if isWaitingForTexture then
			isWaitingForTexture = false
			asyncCallbacks:Resume()
		end
	end
	local id = self.name .. "WaitForTextureLoaded"
	em:RegisterForUpdate(
		id,
		0,
		function()
			if not ZO_WorldMapContainer1 then
				return
			end
			ZO_PreHookHandler(ZO_WorldMapContainer1, "OnTextureLoaded", WaitForTextureLoaded)
			em:UnregisterForUpdate(id)
		end
	)

	local callbacks
	local function Callback(index)
		local callback = callbacks[index]
		if callback then
			local deleted = callback[3]
			if deleted then
				return
			end
			local argument = callback[2]
			callback = callback[1]

			if argument then
				pcall(callback, argument, false)
			else
				pcall(callback, false)
			end
		end
	end
	local function DoCallbacks(asyncCallbacks)
		callbacks = CALLBACK_MANAGER.callbackRegistry["OnWorldMapChanged"]
		if not callbacks or #callbacks == 0 then
			return
		end
		asyncCallbacks:For(1, #callbacks):Do(Callback)
	end
	local function AfterCallbacks()
		callbacks = nil
		runningCallbacks = false
		if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
			AdjustZoom()
			if DoesCurrentMapMatchMapForPlayerLocation() then
				local orgSetMapToPlayerLocation = SetMapToPlayerLocation
				SetMapToPlayerLocation = NoOp

				MoveToPlayer()
				SetMapToPlayerLocation = orgSetMapToPlayerLocation
			end
			if IsInGamepadPreferredMode() then
				RestorePosition()
			end
		end
	end
	asyncCallbacks:Finally(AfterCallbacks)
	-- ToDo: Scene StateChange
	local map, currentTime, running
	local lastUpdate, lastMapUpdate, lastMapId = 0, 0, GetMapTileTexture()
	local function UpdateMap(force)
		if runningCallbacks then
			return
		end

		if not force then
			if HUD_UI_SCENE:IsShowing() or not WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				return
			end
		end

		-- local stopwatch = GetGameTimeSeconds()

		local needChange, oldMapType, mapId
		if (currentTime - lastMapUpdate) >= 1 then
			lastMapUpdate = currentTime

			needChange, oldMapType, mapId = not DoesCurrentMapMatchMapForPlayerLocation(), GetMapType(), GetMapTileTexture()
			needChange = needChange or mapId ~= lastMapId
			if needChange then
				SetMapToPlayerLocation()
				if oldMapType ~= MAPTYPE_SUBZONE and DoesCurrentMapShowPlayerWorld() then
					local mapType = GetMapType()
					if mapType == MAPTYPE_SUBZONE and GetMapContentType() == MAP_CONTENT_NONE then
						local x, y = GetMapPlayerPosition("player")
						if x < 0.17 or x > 0.83 or y < 0.17 or y > 0.83 then
							MapZoomOut()
							local currentMapId = GetMapTileTexture()
							if mapId == currentMapId then
								-- df("skip %.2fx%.2f", x, y)
								needChange = currentMapId ~= lastMapId
								-- Compensate overhead: delay next check 1.5sec
								lastMapUpdate = lastMapUpdate + 1.5
							end
						end
					end
				end
			elseif oldMapType == MAPTYPE_SUBZONE and DoesCurrentMapShowPlayerWorld() then
				local x, y = GetMapPlayerPosition("player")
				if x < 0.10 or x > 0.90 or y < 0.10 or y > 0.90 then
					MapZoomOut()
					local mapType = GetMapType()
					if mapType == MAPTYPE_SUBZONE or GetMapTileTexture() ~= mapId then
						lastMapUpdate = lastMapUpdate + 1.5
						SetMapToPlayerLocation()
					else
						needChange = true
					end
				end
			end
		else
			needChange = lastMapId ~= GetMapTileTexture()
		end
		if needChange then
			runningCallbacks = true
			asyncCallbacks:Cancel():Call(DoCallbacks):Then(WaitForTexture)
			MoveToPlayer = ZO_WorldMap_JumpToPlayer
			lastMapId = GetMapTileTexture()
		elseif (currentTime - lastUpdate) >= 0.200 then
			lastUpdate = currentTime
			local orgZO_WorldMap_UpdateMap, orgSetMapToPlayerLocation = ZO_WorldMap_UpdateMap, SetMapToPlayerLocation
			ZO_WorldMap_UpdateMap, SetMapToPlayerLocation = NoOp, NoOp

			AdjustZoom()

			MoveToPlayer()
			MoveToPlayer = ZO_WorldMap_PanToPlayer

			ZO_WorldMap_UpdateMap, SetMapToPlayerLocation = orgZO_WorldMap_UpdateMap, orgSetMapToPlayerLocation
		end
		-- 	stopwatch = GetGameTimeSeconds() - stopwatch
		-- 	if stopwatch > 0.001 then
		-- 		df("check map change required took %.3fms needChange=%s", stopwatch * 1000, tostring(needChange))
		-- 	end
	end

	do
		local orgUpdate = ZO_WorldMap:GetHandler("OnUpdate")
		local orgSetMapToPlayerLocation = SetMapToPlayerLocation
		-- 	local orgIsShowing = SCENE_MANAGER.IsShowing
		-- 	local orgIsInGamepadPreferredMode = IsInGamepadPreferredMode
		-- 	local function isShowingFake(self, name) return name == "worldMap" or orgIsShowing(self, name) end
		local updateTask = async:Create("VotansMiniMapUpdateMap")

		local function asyncUpdate1()
			if SetMapToPlayerLocation ~= NoOp then
				orgSetMapToPlayerLocation = SetMapToPlayerLocation
			end
			return UpdateMap()
		end
		local function asyncUpdate2(task)
			SetMapToPlayerLocation = NoOp
			if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				NoGamepad(orgUpdate, map, currentTime)
			else
				orgUpdate(map, currentTime)
			end
			SetMapToPlayerLocation = orgSetMapToPlayerLocation
			running = false
		end
		local function updateHeading()
			local heading = GetPlayerCameraHeading()
			local angle = self.cameraAngleRad
			self.cameraAngleRad = angle
			self.cameraAngleLeft:SetTextureRotation(heading - angle, 0.5, 1)
			self.cameraAngleRight:SetTextureRotation(heading + angle, 0.5, 1)
		end
		local function minimapUpdate(...)
			map, currentTime = ...

			if self.account.showCameraAngle then
				updateHeading()
			end

			if self.account.asyncUpdate then
				if running then
					-- d("skip")
					return
				end
				running = true
				updateTask:Call(asyncUpdate1):Then(asyncUpdate2)
			else
				asyncUpdate1()
				asyncUpdate2()
			end
		end
		-- 	local function minimapUpdateWithTooltips(...)
		-- 		SetMapToPlayerLocation, SCENE_MANAGER.IsShowing, IsInGamepadPreferredMode = orgSetMapToPlayerLocation, orgIsShowing, orgIsInGamepadPreferredMode
		-- 		UpdateMap()
		-- 		if SetMapToPlayerLocation ~= NoOp then
		-- 			orgSetMapToPlayerLocation, orgIsShowing, orgIsInGamepadPreferredMode = SetMapToPlayerLocation, SCENE_MANAGER.IsShowing, IsInGamepadPreferredMode
		-- 		end
		-- 		SetMapToPlayerLocation, SCENE_MANAGER.IsShowing, IsInGamepadPreferredMode = NoOp, isShowingFake, NoOp
		-- 		orgUpdate(...)
		-- 		SetMapToPlayerLocation, SCENE_MANAGER.IsShowing, IsInGamepadPreferredMode = orgSetMapToPlayerLocation, orgIsShowing, orgIsInGamepadPreferredMode
		-- 	end
		ZO_WorldMap:SetHandler("OnUpdate", minimapUpdate)
	end

	do
		local function toggleMapPoint(pinTypeId, getPositionFunc, removeFunc)
			local x, y = NormalizeMousePositionToControl(ZO_WorldMapContainer)
			local cx, cy = getPositionFunc()
			if cx ~= 0 and cy ~= 0 then
				local distance = zo_distance3D(x, y, 0, cx, cy, 0) * self:GetCurrentZoom()
				if distance <= 0.023 then
					return removeFunc()
				end
			end
			PingMap(pinTypeId, MAP_TYPE_LOCATION_CENTERED, x, y)
		end
		local orgZO_WorldMap_MouseDown = ZO_WorldMap_MouseDown
		function ZO_WorldMap_MouseDown(...)
			if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				local button, ctrl, alt, shift = ...
				if button == MOUSE_BUTTON_INDEX_LEFT and not shift and not alt and ctrl then
					return toggleMapPoint(MAP_PIN_TYPE_PLAYER_WAYPOINT, GetMapPlayerWaypoint, ZO_WorldMap_RemovePlayerWaypoint)
				end
			end
			return orgZO_WorldMap_MouseDown(...)
		end
	end

	do
		function addon:StartFollowPlayer()
			MoveToPlayer = ZO_WorldMap_JumpToPlayer
		end

		function addon:StopFollowPlayer()
		end

		local isDirty = false
		local function RefreshVisibility()
			isDirty = false
			if GetScene():IsShowing() or not WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				return true
			end

			if not addon.player.showMap then
				return false
			end

			local settings = addon.account
			if IsMounted() then
				return settings.showMounted
			end
			if SIEGE_BAR_SCENE:IsShowing() then
				return settings.showSiege
			end
			if LOOT_SCENE:IsShowing() then
				return settings.showLoot
			end
			if IsUnitInCombat("player") then
				return settings.showCombat
			else
				return settings.showHUD
			end
		end
		WORLD_MAP_FRAGMENT:SetConditional(RefreshVisibility)

		function addon:UpdateVisibility()
			if not isDirty then
				isDirty = true
				WORLD_MAP_FRAGMENT:Refresh()
			end
			if WORLD_MAP_FRAGMENT:IsShowing() then
				self:StartFollowPlayer()
			else
				self:StopFollowPlayer()
			end
		end
	end

	local ZO_CachedStrFormat, SI_ZONE_NAME = ZO_CachedStrFormat, SI_ZONE_NAME
	local function IsPresentlyShowingKeeps()
		return GetMapFilterType() == MAP_FILTER_TYPE_AVA_CYRODIIL or GetMapFilterType() == MAP_FILTER_TYPE_AVA_IMPERIAL
	end

	local function SetMapTitle(zoneName, subZoneName)
		if subZoneName and #subZoneName > 0 then
			zoneName = subZoneName
		end
		if not zoneName or #zoneName == 0 then
			zoneName = GetMapName()
			if not zoneName or #zoneName == 0 then
				zoneName = GetZoneNameByIndex(GetUnitZoneIndex("player"))
			end
		end
		if self.account.showFullTitle then
			local dungeonDifficulty = ZO_WorldMap_GetMapDungeonDifficulty()
			local isInAvAMap = IsPresentlyShowingKeeps()
			if isInAvAMap then
				local campaignId = GetCurrentCampaignId()
				if campaignId ~= 0 then
					local campaignName = GetCampaignName(campaignId)
					zoneName = ZO_CachedStrFormat(SI_WINDOW_TITLE_WORLD_MAP_WITH_CAMPAIGN_NAME, zoneName, campaignName)
					return zoneName
				end
			elseif dungeonDifficulty ~= DUNGEON_DIFFICULTY_NONE then
				zoneName = ZO_CachedStrFormat(SI_WINDOW_TITLE_WORLD_MAP_WITH_DUNGEON_DIFFICULTY, zoneName, GetString("SI_DUNGEONDIFFICULTY", dungeonDifficulty))
				return zoneName
			end
		end
		zoneName = ZO_CachedStrFormat(SI_WINDOW_TITLE_WORLD_MAP, zoneName)
		return zoneName
	end
	local function SetMapTitleCurrentLocation()
		return SetMapTitle(GetPlayerLocationName(), GetPlayerActiveSubzoneName())
	end
	local function ZoneChanged(_, zoneName, subZoneName)
		if not WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
			return
		end
		ZO_WorldMapTitle:SetText(SetMapTitle(zoneName, subZoneName))
	end
	em:RegisterForEvent(addon.name, EVENT_ZONE_CHANGED, ZoneChanged)

	local orgZO_WorldMap_GetMapTitle = ZO_WorldMap_GetMapTitle
	function ZO_WorldMap_GetMapTitle(...)
		if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) and DoesCurrentMapMatchMapForPlayerLocation() then
			return SetMapTitleCurrentLocation(...)
		end

		return orgZO_WorldMap_GetMapTitle(...)
	end

	local function ClearMouseoverText()
		ZO_WorldMap_OnHide()
		ZO_WorldMap_HandlePinExit()
		ZO_WorldMapTitle:SetText(SetMapTitleCurrentLocation())
	end
	do
		local function DoIt(orgZO_WorldMap_UpdateMap, skipWorldMapUpdate)
			CALLBACK_MANAGER:UnregisterCallback("OnWorldMapModeChanged", DoIt, orgZO_WorldMap_UpdateMap, skipWorldMapUpdate)

			if WORLD_MAP_MANAGER.inSpecialMode then
				ZO_WorldMap_UpdateMap = NoOp
				-- Clear interaction, otherwise button does not get enabled again
				EndInteraction(INTERACTION_FAST_TRAVEL_KEEP)
				EndInteraction(INTERACTION_FAST_TRAVEL)
			end

			ZO_MapPin.UpdateSize = newUpdateSize
			ZO_WorldMap_UpdateMap = skipWorldMapUpdate and NoOp or orgZO_WorldMap_UpdateMap
			WORLD_MAP_MANAGER:SetToMode(MAP_MODE_VOTANS_MINIMAP)
			ZO_WorldMap_ClearCustomZoomLevels()
			ZO_WorldMap_UpdateMap = orgZO_WorldMap_UpdateMap

			self.background:SetHidden(false)

			ZO_WorldMap:StopMovingOrResizing()
			ZO_WorldMap_MouseUp()
			MoveToPlayer = ZO_WorldMap_JumpToPlayer
			RestorePosition()
			self:UpdateBorder()
			ClearMouseoverText()
			lastZoom = -1
		end
		function addon:GoMiniMapMode(skipWorldMapUpdate)
			local orgZO_WorldMap_UpdateMap = ZO_WorldMap_UpdateMap

			local mode = WORLD_MAP_MANAGER:GetMode()
			if mode ~= MAP_MODE_VOTANS_MINIMAP then
				if WORLD_MAP_MANAGER.inSpecialMode then
					if mode ~= MAP_MODE_KEEP_TRAVEL and mode ~= MAP_MODE_FAST_TRAVEL then
						ClearMouseoverText()

						ZO_WorldMap_UpdateMap = NoOp
						WORLD_MAP_MANAGER:SetToMode(MAP_MODE_VOTANS_MINIMAP)
						ZO_WorldMap_UpdateMap = orgZO_WorldMap_UpdateMap

						self.background:SetHidden(false)

						RestorePosition()
						self:UpdateBorder()
					else
						CALLBACK_MANAGER:RegisterCallback("OnWorldMapModeChanged", DoIt, orgZO_WorldMap_UpdateMap, skipWorldMapUpdate)
						-- ZO_WorldMap_UpdateMap = NoOp
						-- Needed to cause OnWorldMapModeChanged:
						EndInteraction(INTERACTION_FAST_TRAVEL_KEEP)
						EndInteraction(INTERACTION_FAST_TRAVEL)
					end
				else
					DoIt(orgZO_WorldMap_UpdateMap, skipWorldMapUpdate)
				end
			else
				SetMapTitleCurrentLocation()
			end
			WORLD_MAP_MANAGER:UpdateFloorAndLevelNavigation()

			self:StartFollowPlayer()
		end
	end
	function addon:GoWorldMapMode(skipPanToPlayer)
		self:StopFollowPlayer()
		if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
			lastZoom = -1
			MoveToPlayer = ZO_WorldMap_JumpToPlayer
			ZO_MapPin.UpdateSize = orgUpdateSize

			local orgZO_WorldMap_UpdateMap, orgSetMapToPlayerLocation = ZO_WorldMap_UpdateMap, SetMapToPlayerLocation
			SetMapToPlayerLocation, ZO_WorldMap_UpdateMap = NoOp, NoOp

			ZO_WorldMap_ClearCustomZoomLevels()
			WORLD_MAP_MANAGER:SetToMode(MAP_MODE_LARGE_CUSTOM)

			self:SetCurrentZoom(0)
			-- This triggers internal handlers. One of them would call ZO_WorldMap_UpdateMap, but not this time
			CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged", true)
			if self.account.zoomToPlayer and not skipPanToPlayer and DoesCurrentMapMatchMapForPlayerLocation() then
				ZO_WorldMap_JumpToPlayer()
			end

			SetMapToPlayerLocation, ZO_WorldMap_UpdateMap = orgSetMapToPlayerLocation, orgZO_WorldMap_UpdateMap

			self.background:SetHidden(true)
		else
			if WORLD_MAP_MANAGER:IsPreventingMapNavigation() then
				self.panZoom.pendingInitializeMap = nil
			end
		end
		self:UpdateBorder()
		WORLD_MAP_MANAGER:UpdateFloorAndLevelNavigation()
	end

	do
		local orgZO_WorldMap_OnResizeStop = ZO_WorldMap_OnResizeStop
		function ZO_WorldMap_OnResizeStop(...)
			orgZO_WorldMap_OnResizeStop(...)
			if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				SaveMapPosition()
			end
		end
	end

	do
		local orgZO_WorldMapTitleBar_OnMouseUp = ZO_WorldMapTitleBar_OnMouseUp
		function ZO_WorldMapTitleBar_OnMouseUp(...)
			orgZO_WorldMapTitleBar_OnMouseUp(...)
			SaveMapPosition()
			ZO_WorldMapContainer:SetDimensions(ZO_WorldMapContainer:GetDimensions())
			ZO_WorldMapScroll:SetDimensions(ZO_WorldMapScroll:GetDimensions())
			UpdateMap(true)
		end
	end

	do
		local function WorldMapStateChanged(oldState, newState)
			if (newState == SCENE_FRAGMENT_SHOWING) then
				addon:GoWorldMapMode()
			elseif (newState == SCENE_FRAGMENT_SHOWN) then
				-- Avoid "Access private ...":
				WORLD_MAP_FRAGMENT.duration = 100
			elseif (newState == SCENE_FRAGMENT_HIDING) then
				addon:GoMiniMapMode(WORLD_MAP_MANAGER:GetMode() <= MAP_MODE_LARGE_CUSTOM)
			elseif (newState == SCENE_FRAGMENT_HIDDEN) then
				WORLD_MAP_FRAGMENT.duration = 0
			end
		end
		WORLD_MAP_SCENE:RegisterCallback("StateChange", WorldMapStateChanged)
		GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", WorldMapStateChanged)
		SCRYING_SCENE:RegisterCallback("StateChange", WorldMapStateChanged)
	end
	do
		local function SiegeStateChanged(oldState, newState)
			if (newState == SCENE_FRAGMENT_SHOWING) then
				addon:GoMiniMapMode(WORLD_MAP_MANAGER:GetMode() <= MAP_MODE_LARGE_CUSTOM)
			end
		end
		SIEGE_BAR_SCENE:RegisterCallback("StateChange", SiegeStateChanged)
	end

	do
		local function WorldFragmentStateChanged(oldState, newState)
			if (newState == SCENE_FRAGMENT_SHOWING) then
				if addon.account.showClock then
					EVENT_MANAGER:RegisterForUpdate("VOTAN_MAP_CLOCK", 5000, addon.ShowClock)
					addon.ShowClock()
				end
			elseif (newState == SCENE_FRAGMENT_HIDING) then
				EVENT_MANAGER:UnregisterForUpdate("VOTAN_MAP_CLOCK")
			end
			local hidden = not addon.account.showClock
			addon.clockRealTime:SetHidden(hidden)
			addon.clockInGame:SetHidden(hidden)
		end
		WORLD_MAP_FRAGMENT:RegisterCallback("StateChange", WorldFragmentStateChanged)
	end

	do
		local orgZO_WorldMap_RefreshMapFrameAnchor = ZO_WorldMapManager.RefreshMapFrameAnchor
		function ZO_WorldMapManager.RefreshMapFrameAnchor(manager, ...)
			if addon.account and manager:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				RestorePosition()
				return
			end
			return orgZO_WorldMap_RefreshMapFrameAnchor(manager, ...)
		end
	end

	do
		local orgZO_WorldMap_PushSpecialMode = ZO_WorldMapManager.PushSpecialMode
		function ZO_WorldMapManager.PushSpecialMode(manager, mode, ...)
			if manager.inSpecialMode then
				return orgZO_WorldMap_PushSpecialMode(manager, mode, ...)
			end
			local zoomOut = mode == MAP_MODE_FAST_TRAVEL or mode == MAP_MODE_KEEP_TRAVEL
			local orgZO_WorldMap_UpdateMap = ZO_WorldMap_UpdateMap
			if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				ZO_WorldMap_UpdateMap = NoOp
				addon:GoWorldMapMode(zoomOut)
			end
			if zoomOut and GetMapType() == MAPTYPE_SUBZONE then
				asyncCallbacks:Cancel()
				MapZoomOut()

				ZO_WorldMap_UpdateMap = NoOp
				-- ZO_WorldMap_UpdateMap will be called in ZO_WorldMap_PushSpecialMode again, but not this time
				orgZO_WorldMap_PushSpecialMode(manager, mode, ...)

				ZO_WorldMap_UpdateMap = orgZO_WorldMap_UpdateMap
				CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged", true)
				return
			end
			ZO_WorldMap_UpdateMap = orgZO_WorldMap_UpdateMap
			return orgZO_WorldMap_PushSpecialMode(manager, mode, ...)
		end
	end

	do
		local orgZO_WorldMap_ShowWorldMap = ZO_WorldMap_ShowWorldMap
		function ZO_WorldMap_ShowWorldMap(...)
			if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				addon:GoWorldMapMode()
			end
			return orgZO_WorldMap_ShowWorldMap(...)
		end
	end

	do
		local function QuestTrackerRefreshedMapPins()
			if not ZO_WorldMap_IsWorldMapShowing() and not DoesCurrentMapMatchMapForPlayerLocation() then
				if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
					CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
				end
			end
		end
		FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerRefreshedMapPins", QuestTrackerRefreshedMapPins)
	end

	do
		local handlers = ZO_AlertText_GetHandlers()
		local orgZoneChange = handlers[EVENT_ZONE_CHANGED]
		handlers[EVENT_ZONE_CHANGED] = function(...)
			local mode = self.account.zoneAlertMode
			if mode == self.zoneAlertMode.Never then
				return
			end
			if mode == self.zoneAlertMode.MiniMapHidden and WORLD_MAP_FRAGMENT:IsShowing() then
				return
			end
			return orgZoneChange(...)
		end
	end

	local ZO_MapPanAndZoom = getmetatable(ZO_WorldMap_GetPanAndZoom()).__index
	local function IsNormalizedPointInsideMapBounds(x, y)
		return x > 0 and x < 1 and y > 0 and y < 1
	end
	local function FocusZoomAndOffset(self, normalizedX, normalizedY)
		local mapId = GetMapTileTexture()
		local fixed = addon.account and addon.account.fixedMaps[mapId]
		if fixed then
			normalizedX, normalizedY = unpack(fixed)
		end

		if normalizedX and normalizedY and IsNormalizedPointInsideMapBounds(normalizedX, normalizedY) then
			local targetNormalizedZoom = 1
			local curvedTargetZoom = self:ComputeCurvedZoom(targetNormalizedZoom)

			local zoomedNX, zoomedNY = normalizedX * curvedTargetZoom, normalizedY * curvedTargetZoom
			local borderSizeN = (curvedTargetZoom - 1) * 0.5
			local offsetNX, offsetNY = 0.5 + borderSizeN - zoomedNX, 0.5 + borderSizeN - zoomedNY

			if not self.allowPanPastMapEdge then
				offsetNX, offsetNY = zo_clamp(offsetNX, -borderSizeN, borderSizeN), zo_clamp(offsetNY, -borderSizeN, borderSizeN)
			end

			local units = zo_max(ZO_WorldMapScroll:GetDimensions())
			local offsetX, offsetY = offsetNX * units, offsetNY * units

			return targetNormalizedZoom, offsetX, offsetY
		end
	end
	local orgGetNormalizedPositionFocusZoomAndOffset = ZO_MapPanAndZoom.GetNormalizedPositionFocusZoomAndOffset
	function ZO_MapPanAndZoom:GetNormalizedPositionFocusZoomAndOffset(normalizedX, normalizedY, useCurrentZoom)
		if WORLD_MAP_MANAGER:GetMode() ~= MAP_MODE_VOTANS_MINIMAP then
			return orgGetNormalizedPositionFocusZoomAndOffset(self, normalizedX, normalizedY, useCurrentZoom)
		else
			return FocusZoomAndOffset(self, normalizedX, normalizedY)
		end
	end

	local function refreshFragment()
		WORLD_MAP_FRAGMENT:Refresh()
	end
	local function mountedStateChanged()
		async:Call(refreshFragment)
	end
	em:RegisterForEvent(addon.name, EVENT_MOUNTED_STATE_CHANGED, mountedStateChanged)
end

do
	local orgGetLeft = GAMEPAD_WORLD_MAP_TOOLTIP_FRAGMENT.control.GetLeft
	function GAMEPAD_WORLD_MAP_TOOLTIP_FRAGMENT.control:GetLeft()
		if WORLD_MAP_MANAGER:GetMode() ~= MAP_MODE_VOTANS_MINIMAP then
			return orgGetLeft(self)
		else
			local right = GAMEPAD_WORLD_MAP_INFO_FRAGMENT.control:GetRight()
			local padding = 50
			local width = addon.account.width or addon.modeData.width or 301
			return width + right + padding
		end
	end
	local orgGetHeight = ZO_KeybindStripGamepadBackgroundTexture.GetHeight
	function ZO_KeybindStripGamepadBackgroundTexture:GetHeight()
		if WORLD_MAP_MANAGER:GetMode() ~= MAP_MODE_VOTANS_MINIMAP then
			return orgGetHeight(self)
		else
			return -100
		end
	end

	do
		local ZO_MapPanAndZoom = addon.panZoom
		local orgZO_MapPanAndZoomUpdate = ZO_MapPanAndZoom.Update
		function ZO_MapPanAndZoom.Update(...)
			if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				return NoGamepad(orgZO_MapPanAndZoomUpdate, ...)
			end
			return orgZO_MapPanAndZoomUpdate(...)
		end
		local orgZO_MapPanAndZoomSetCurrentZoom = ZO_MapPanAndZoom.SetCurrentNormalizedZoom
		function ZO_MapPanAndZoom.SetCurrentNormalizedZoom(...)
			if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				return NoGamepad(orgZO_MapPanAndZoomSetCurrentZoom, ...)
			end
			return orgZO_MapPanAndZoomSetCurrentZoom(...)
		end

		local orgZO_WorldMap_UpdateMap = ZO_WorldMap_UpdateMap
		function ZO_WorldMap_UpdateMap(...)
			if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
				return NoGamepad(orgZO_WorldMap_UpdateMap, ...)
			end
			return orgZO_WorldMap_UpdateMap(...)
		end
	end
	do
		local function ApplyModeStyle()
			ApplyTemplateToControl(ZO_WorldMapMapFrame, ZO_GetPlatformTemplate("ZO_WorldMapFrame"))
		end

		ZO_PreHook(
			WORLD_MAP_MANAGER,
			"UpdateFloorAndLevelNavigation",
			function()
				if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_VOTANS_MINIMAP) then
					ZO_WorldMapButtonsFloors_Keyboard:SetHidden(true)
					ZO_WorldMapButtonsFloors_Gamepad:SetHidden(true)
					ZO_WorldMapButtonsLevels_Gamepad:SetHidden(true)
					return true
				end
			end
		)
		function addon:UpdateBorder()
			local control = self.background
			local inMiniMap = not GetScene():IsShowing()
			if inMiniMap then
				if self.lastTitleFont ~= self.account.titleFont then
					self.lastTitleFont = self.account.titleFont
					if self.account.titleFont and #self.account.titleFont > 0 then
						local font, scale
						if self.fontFaces[self.account.titleFont] then
							font, scale = unpack(self.fontFaces[self.account.titleFont])
						else
							font, scale = self.account.titleFont, 1
						end
						ZO_WorldMapTitle:SetFont(string.format("%s|%i|soft-shadow-thick", font, math.floor(self.account.titleFontSize * scale)))
					end
				end
				local item = self:GetFontSizeBySizeName(self.account.titleFontSize)
				ZO_WorldMapTitle:ClearAnchors()
				if self.account.titleAtTop then
					ZO_WorldMapTitle:SetAnchor(TOP, nil, TOP, 0, item and item.data.offsetY or 0)
				else
					ZO_WorldMapTitle:SetAnchor(TOP, ZO_WorldMapMapFrame, BOTTOM, 0, item and item.data.offsetY or 0)
				end
				ZO_WorldMapButtons:ClearAnchors()
				if self.account.titleAtTop then
					ZO_WorldMapButtons:SetAnchor(BOTTOMLEFT, nil, BOTTOMLEFT, 4, -4)
					ZO_WorldMapButtons:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -4, -4)
				else
					local offsetY = addon.account.showClock and ZO_WorldMapTitle:GetHeight() or 0
					ZO_WorldMapButtons:SetAnchor(TOPLEFT, ZO_WorldMapMapFrame, BOTTOMLEFT, 0, offsetY)
					ZO_WorldMapButtons:SetAnchor(TOPRIGHT, ZO_WorldMapMapFrame, BOTTOMRIGHT, 0, offsetY)
				end

				ZO_WorldMapTitle:SetColor(self.titleColor:UnpackRGB())
				ZO_WorldMapTitle:SetHidden(not (self.account.titleFont and #self.account.titleFont > 0))
				local enable = not (self.account.lockWindow or IsInGamepadPreferredMode())
				ZO_WorldMapButtonsBG:SetMouseEnabled(enable)
				ZO_WorldMapTitleBar:SetMouseEnabled(enable)
				ZO_WorldMap:SetMouseEnabled(enable)

				self:UpdateCompass()
				if IsInGamepadPreferredMode() then
					NoGamepad(ApplyModeStyle)
				end
				self:UpdateDrawLevel()

				local style = self:GetStyleByName(self.account.frameStyle)
				if style and style.data.setup then
					style.data.setup(self.account, control, ZO_WorldMapMapFrame)
					return
				end
			else
				ZO_WorldMapTitle:SetHidden(false)
				local style = self:GetStyleByName(self.account.frameStyle)
				if style and style.data.reset then
					style.data.reset(self.account, control, ZO_WorldMapMapFrame)
				end
				ApplyModeStyle()
				ZO_WorldMap:SetMouseEnabled(true)
				ZO_WorldMap:SetDrawLayer(DL_BACKGROUND)
				ZO_WorldMap:SetDrawLevel(10000)
			end
			control:SetCenterColor(0, 0, 0, 0)
			control:SetEdgeColor(0, 0, 0, 0)
			control:SetCenterTexture("")
			control:SetInsets(0, 0, 0, 0)
			ZO_WorldMapMapFrame:SetEdgeTexture("/esoui/art/worldmap/worldmap_frame_edge.dds", 128, 16)
			ZO_WorldMapMapFrame:SetAlpha(1)
			ZO_WorldMapMapFrame:SetHidden(false)
			ZO_WorldMapTitle:SetHidden(true)
		end
	end
	function addon:UpdateCompass()
		if self.account.enableCompass ~= self.compassMode.Untouched then
			local hidden = self.account.showHUD and self.account.enableCompass ~= self.compassMode.Shown

			ZO_CompassCenterOverPinLabel:SetHidden(hidden)
			ZO_CompassContainer:SetHidden(hidden)
			ZO_CompassFrameLeft:SetHidden(hidden)
			ZO_CompassFrameCenter:SetHidden(hidden)
			ZO_CompassFrameRight:SetHidden(hidden)
		end
	end
	function addon:UpdateDrawLevel()
		ZO_WorldMap:SetDrawLayer(self.account.showOnTop and DL_CONTROLS or DL_BACKGROUND)
		ZO_WorldMap:SetDrawLevel(self.account.showOnTop and 1000 or 0)
	end
end

function addon:Initialize()
	local accountDefaults = {
		enableTweaks = true,
		enableMap = true,
		zoom = 1.3,
		mountedZoom = 1,
		subZoneZoom = 1,
		dungeonZoom = 0.7,
		battlegroundZoom = 0,
		zoomOut = 0.15,
		zoomIn = 2,
		zoomToPlayer = false,
		frameStyle = "ESO",
		borderAlpha = 100,
		titleFont = "BOLD_FONT",
		titleFontSize = 16,
		titleColor = {GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL)},
		showClock = true,
		showRealTimeClock = true,
		showInGameClock = true,
		lockWindow = false,
		showFullTitle = false,
		showCameraAngle = false,
		cameraAngle = 45,
		zoneAlertMode = self.zoneAlertMode.MiniMapHidden,
		timeFormat = TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR,
		debug = false,
		asyncUpdate = false,
		enableCompass = self.compassMode.Untouched,
		showOnTop = false,
		titleAtTop = true,
		unitPinScaleLimit = 0.8,
		showHUD = true,
		showLoot = true,
		showMounted = true,
		showCombat = false,
		showSiege = false,
		fixedMaps = {}
	}
	self.accountDefaults = accountDefaults

	self.account = ZO_SavedVars:NewAccountWide("VotansMiniMap_Data", 1, nil, accountDefaults)

	local defaults = {
		showMap = true
	}
	self.defaults = defaults

	self.player = ZO_SavedVars:NewCharacterIdSettings("VotansMiniMap_Data", 1, nil, defaults)

	if self.account.enableTweaks then
		self:InitTweaks()
	elseif self.account.enableMap then
		self:InitRequiredModifications()
	end
	if self.account.enableMap then
		self:InitMapSettings()

		self.titleColor = ZO_ColorDef:New(unpack(type(self.account.titleColor) == "table" and self.account.titleColor or accountDefaults.titleColor))
		self.titleColor:SetAlpha(1)

		self:InitMiniMap()
		HUD_UI_SCENE:RemoveFragment(MOUSE_UI_MODE_FRAGMENT)
		HUD_SCENE:AddFragment(WORLD_MAP_FRAGMENT)
		HUD_UI_SCENE:AddFragment(WORLD_MAP_FRAGMENT)
		SIEGE_BAR_SCENE:AddFragment(WORLD_MAP_FRAGMENT)
		SIEGE_BAR_UI_SCENE:AddFragment(WORLD_MAP_FRAGMENT)
		LOOT_SCENE:AddFragment(WORLD_MAP_FRAGMENT)
		HUD_UI_SCENE:AddFragment(MOUSE_UI_MODE_FRAGMENT)

		async:SetDebug(self.account.debug)
	end
end

CALLBACK_MANAGER:RegisterCallback(
	"OnWorldMapSavedVarsReady",
	function(vars)
		addon.mapVars = vars
	end
)

do
	local function UpdateControls()
		if addon.settingsControls.selected then
			addon.settingsControls:UpdateControls()
		end
	end
	function addon:ToggleShowMap()
		self.player.showMap = not self.player.showMap
		CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_BROADCAST, CSA_CATEGORY_SMALL_TEXT, nil, string.format("%s: %s", GetString(SI_VOTANSMINIMAP_SHOW_MAP), GetString(self.player.showMap and SI_CHECK_BUTTON_ON or SI_CHECK_BUTTON_OFF)))
		self:UpdateVisibility()
		UpdateControls()
	end
	function addon:ToggleShowHUD()
		if IsMounted() then
			self.account.showMounted = not self.account.showMounted
		else
			self.account.showHUD = not self.account.showHUD
		end
		self:UpdateVisibility()
		self:UpdateCompass()
		UpdateControls()
	end
	function addon:ToggleShowCombat()
		self.account.showCombat = not self.account.showCombat
		self:UpdateVisibility()
		UpdateControls()
	end
	function addon:ToggleShowSiege()
		self.account.showSiege = not self.account.showSiege
		self:UpdateVisibility()
		UpdateControls()
	end
	function addon:ToogleZoom(enabled, zoom)
		self.isSpecialZoom = enabled
		if enabled then
			self.specialZoom = zoom or 1
		end
	end
	function addon:StepZoom(add)
		if WORLD_MAP_MANAGER:GetMode() ~= MAP_MODE_VOTANS_MINIMAP or WORLD_MAP_FRAGMENT:IsHidden() or addon.isSpecialZoom or not self.account[self.zoomMode] then
			PlaySound(SOUNDS.NEGATIVE_CLICK)
			return
		end

		local step = -0.05
		if add then
			step = -step
		end
		if IsShiftKeyDown() then
			step = step * 5
		end

		self.account[self.zoomMode] = math.max(0, math.min(2, self.account[self.zoomMode] + step))
		UpdateControls()
	end
	local function IsMouseOverMap()
		if IsInGamepadPreferredMode() then
			return SCENE_MANAGER:IsShowing("gamepad_worldMap")
		else
			return not ZO_WorldMapScroll:IsHidden() and MouseIsOver(ZO_WorldMapScroll) and SCENE_MANAGER:IsShowing("worldMap")
		end
	end
	local function NormalizePreferredMousePositionToMap()
		if IsInGamepadPreferredMode() then
			local x, y = ZO_WorldMapScroll:GetCenter()
			return NormalizePointToControl(x, y, ZO_WorldMapContainer)
		else
			return NormalizeMousePositionToControl(ZO_WorldMapContainer)
		end
	end
	local function distanceSq(x1, y1, x2, y2)
		local dx, dy = x2 - x1, y2 - y1
		return dx * dx + dy * dy
	end
	function addon:ToggleFixedOffset()
		local mapId = GetMapTileTexture()
		local isNotFixed = not self.account.fixedMaps[mapId]
		local isMouseOverMap = IsMouseOverMap()
		if isNotFixed and not isMouseOverMap then
			PlaySound(SOUNDS.NEGATIVE_CLICK)
			return
		end
		if isMouseOverMap then
			local offsetX, offsetY = NormalizePreferredMousePositionToMap()
			if isNotFixed or distanceSq(offsetX, offsetY, unpack(self.account.fixedMaps[mapId])) > 0.0001 then
				self.account.fixedMaps[mapId] = {offsetX, offsetY}
				PlaySound(SOUNDS.MAP_PING)
			else
				self.account.fixedMaps[mapId] = nil
				PlaySound(SOUNDS.MAP_PING_REMOVE)
			end
		else
			self.account.fixedMaps[mapId] = nil
			PlaySound(SOUNDS.MAP_PING_REMOVE)
		end
	end
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:Initialize()
	addon:InitSettings()
	-- addon:InitPinLevels()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_MINIMAP = addon
