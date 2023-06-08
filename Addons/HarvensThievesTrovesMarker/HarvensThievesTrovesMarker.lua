local HarvensThievesTrovesMarker = {}

function HarvensThievesTrovesMarker:GetSavedVariable()
	if not HarvensThievesTrovesMarker_SavedVariables then
		HarvensThievesTrovesMarker_SavedVariables = {}
	end
	
	if HarvensThievesTrovesMarker_SavedVariables[self.displayName] then
		return HarvensThievesTrovesMarker_SavedVariables[self.displayName]
	end
	
	HarvensThievesTrovesMarker_SavedVariables[self.displayName] = {
		pinSize = 24,
		pinLevel = 30,
		troves = {},
	}
	
	for charName,settings in pairs(HarvensThievesTrovesMarker_SavedVariables) do
		if string.sub(charName, 1, 1) ~= "@" then
			for k,v in pairs(settings) do
				if k ~= "pinSize" and k ~= "pinLevel" then
					HarvensThievesTrovesMarker_SavedVariables[self.displayName].troves[k] = v
				end
			end
		end
	end
	
	return HarvensThievesTrovesMarker_SavedVariables[self.displayName]
end

function HarvensThievesTrovesMarker:StoreTrove(tileName, currentFloor, key, x, y)
	self.sv.troves[tileName][currentFloor][key] = {x=x, y=y}
	if not self.pinManager then
		return
	end
	self.pinManager:RefreshCustomPins(self.pinTypeId)
end

function HarvensThievesTrovesMarker:LayoutPins(pinManager)
	--save pinManager for later use in other functions
	if pinManager.__index and pinManager.__index == ZO_WorldMapPins then
		self.pinManager = pinManager
	else
		return -- In ZO_WorldMapPins pinManager I trust
	end

	local tileName, currentFloor = self:GetTileAndFloorFromCurrentMap()
	
	if not self.sv.troves[tileName] then
		return
	end
	
	if not self.sv.troves[tileName][currentFloor] then
		return
	end
	
	for k,v in pairs(self.sv.troves[tileName][currentFloor]) do
		local key = HarvensThievesTrovesMarker:CreatePinKey(tileName,currentFloor,k)
		if pinManager:FindPin(self.pinTypeString, self.pinTypeId, key) == nil then
			self.pinManager:CreatePin(self.pinTypeId, key, v.x, v.y, 0)
		end
	end
end

function HarvensThievesTrovesMarker:DeletePin(pTag)
	local tileName, cfloor, key = self:GetKeyFromTag(pTag)
	self.sv.troves[tileName][cfloor][key] = nil
	if not self.pinManager then
		return
	end
	self.pinManager:RefreshCustomPins(self.pinTypeId)
end

local function ShowPinMenu(pin, button)
	local pType, pTag = pin:GetPinTypeAndTag()
	
	ClearMenu()
	AddMenuItem("Delete", function() HarvensThievesTrovesMarker:DeletePin(pTag) end)
	ShowMenu(pin:GetControl(), 1)
	
	--dirty hack! because something calls ClearMenu after this function returns
	local backupfunc = ClearMenu
	ClearMenu = function(...)
		ClearMenu = backupfunc
	end
end

function HarvensThievesTrovesMarker:SetupMapPins()
	local tooltipCreator = {
		creator = function(pin)
			InformationTooltip:AddLine(GetString(HARVENS_THIEVES_TROVE))
		end,
		tooltip = 1,
	}

	local layout = {
		level=self.sv.pinLevel,
		size=self.sv.pinSize,
		insetX=0,
		insetY=0,
		texture= "/esoui/art/icons/servicemappins/servicepin_bank.dds",
		tint = GetItemQualityColor(ITEM_QUALITY_LEGENDARY)
	}
	
	ZO_WorldMap_AddCustomPin(self.pinTypeString, function(...) self:LayoutPins(...) end, nil, layout, tooltipCreator)
	self.pinTypeId = _G[self.pinTypeString]
	ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, true)
	ZO_MapPin.PIN_CLICK_HANDLERS[1][self.pinTypeId] = {
		{
			name = function(pin) return tostring("Thieves Trove") end,
			show = function(...) return true end,
			callback = ShowPinMenu,
			duplicates = function(...) end,
		}
	}
end

function HarvensThievesTrovesMarker:GetKeyFromTag(pTag)
	local tileName,cfloor,key = string.match(pTag, "([^%s]+) ([^%s]+) ([^%s]+)")
	return tileName,tonumber(cfloor),tonumber(key)
end

function HarvensThievesTrovesMarker:GetTileAndFloorFromCurrentMap()
	local currentFloor, maxFloors = GetMapFloorInfo()
	if maxFloors == 0 then
		currentFloor = 1
	end
	
	local tileName = string.gsub(GetMapTileTexture(1), "[_%-%s%p%d]", "" ):lower()
	
	return tileName, currentFloor
end

function HarvensThievesTrovesMarker:CreatePinKey(tileName, currentFloor, key)
	return tileName.." "..currentFloor.." "..key
end

function HarvensThievesTrovesMarker:StartInteraction(...)
	local action, interactableName, interactionBlocked, isOwned, additionalInfo, context = GetGameCameraInteractableActionInfo()
	
	if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
		CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
	end
	
	local minDistance = 0.03
	local mapIndex = GetCurrentMapIndex()
	if mapIndex then
		minDistance = 0.003
	end

	local tileName, currentFloor = self:GetTileAndFloorFromCurrentMap()	
	local actionName = zo_strformat(SI_GAME_CAMERA_TARGET, action)
	
	if actionName == GetString(SI_GAMECAMERAACTIONTYPE20) then
		interactableName = zo_strformat("<<1>>", interactableName)
		if string.lower(interactableName) ~= string.lower(GetString(HARVENS_THIEVES_TROVE)) then
			return self.fishingStartInteraction(...)
		end
		
		local posx, posy = GetMapPlayerPosition("player")
				
		if not self.sv.troves[tileName] then
			self.sv.troves[tileName] = {}
		end
		
		if not self.sv.troves[tileName][currentFloor] then
			self.sv.troves[tileName][currentFloor] = {}
		end
		
		local found = false
		for k,v in pairs(self.sv.troves[tileName][currentFloor]) do
			if v.x <= posx+minDistance and v.x >= posx-minDistance and v.y <= posy+minDistance and v.y >= posy-minDistance then
				found = true
				break
			end
		end
		
		if not found then
			local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.ACHIEVEMENT_AWARDED)
			params:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_POI_DISCOVERED)
			params:SetText(GetString(HARVENS_THIEVES_TROVE_DISCOVERED))
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
			local key=string.format("%.f", posx*10000)..string.format("%.f", posy*10000)
			key = tonumber(key)
			self:StoreTrove(tileName, currentFloor, key, posx, posy)
		end
	end
	return self.fishingStartInteraction(...)
end

function HarvensThievesTrovesMarker:SetupMapFilter()
	ZO_CreateStringId("SI_MAPFILTER9334", "Thieves Troves")
	WORLD_MAP_FILTERS.pvePanel:SetMapMode(MAP_MODE_LARGE_CUSTOM) --Cyrodiil map fix
	if not WORLD_MAP_FILTERS.pvePanel:GetPinFilter(9334) then
		WORLD_MAP_FILTERS.pvePanel:SetPinFilter(9334, true)
	end
	WORLD_MAP_FILTERS.pvePanel:AddPinFilterCheckBox(9334, function(...)
		ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, WORLD_MAP_FILTERS.pvePanel:GetPinFilter(9334))
		ZO_WorldMap_RefreshCustomPinsOfType(self.pinTypeId)
	end)
	WORLD_MAP_FILTERS.pvePanel:LoadInitialState()
end

function HarvensThievesTrovesMarker:SetupOptions()
	local settings = LibHarvensAddonSettings:AddAddon("Harven's Thiever Troves Marker")
	
	local pinSize = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Pin Size",
		min = 10,
		max = 100,
		step = 1,
		format = "%d",
		getFunction = function() return self.sv.pinSize end,
		setFunction = function(value)
			self.sv.pinSize = value
			ZO_MapPin.PIN_DATA[self.pinTypeId].size = value
		end,
	}
	
	local pinLevel = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Pin Draw Level",
		min = 2,
		max = 200,
		step = 10,
		format = "%d",
		tooltip = "The greater the number then more top level a pin would be.",
		getFunction = function() return self.sv.pinLevel end,
		setFunction = function(value)
			self.sv.pinLevel = value
			ZO_MapPin.PIN_DATA[self.pinTypeId].level = value
		end,
	}
	
	settings:AddSettings({pinSize, pinLevel})
end

function HarvensThievesTrovesMarker:Initialize(eventType, addonName)
	if addonName ~= "HarvensThievesTrovesMarker" then
		return
	end
	
	self.pinTypeId = 0
	self.pinTypeString = "HarvensThievesTrovesPinType"
	self.displayName = GetUnitDisplayName("player")
	self.sv = self:GetSavedVariable()
	
	self:SetupMapPins()
	self:SetupMapFilter()
	self:SetupOptions()
	
	self.fishingStartInteraction = INTERACTIVE_WHEEL_MANAGER.StartInteraction
	INTERACTIVE_WHEEL_MANAGER.StartInteraction = function(...) --this is called when interacting with things
		return HarvensThievesTrovesMarker:StartInteraction(...)
	end
end

EVENT_MANAGER:RegisterForEvent("HarvensThievesTrovesMarker", EVENT_ADD_ON_LOADED, function(...) HarvensThievesTrovesMarker:Initialize(...) end)