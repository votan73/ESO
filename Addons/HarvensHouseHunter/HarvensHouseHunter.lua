local HarvensHouseHunter = {}

function HarvensHouseHunter:GetSavedVariable()
	if not HarvensHouseHunter_SavedVariables then
		HarvensHouseHunter_SavedVariables = {}
	end
	if not HarvensHouseHunter_SavedVariables[self.unitName] then
		HarvensHouseHunter_SavedVariables[self.unitName] = {}
	end
	return HarvensHouseHunter_SavedVariables[self.unitName]
end

function HarvensHouseHunter:StoreHouse(mapName, key, x, y, name)
	self.sv[mapName][key] = {x=x, y=y, n=name}
	self.pinManager:RefreshCustomPins(self.pinTypeId)
end

function HarvensHouseHunter:LayoutPins(pinManager)
	self.pinManager = pinManager
	local mapName = zo_strformat("<<1>>", GetMapName())
	if not self.sv[mapName] then
		return
	end
	
	for k,v in pairs(self.sv[mapName]) do
		local pin = pinManager:CreatePin(self.pinTypeId, { mapName, k }, v.x, v.y, 0)
		pin.harvensHouseHunterCustomText = v.n
	end
end

function HarvensHouseHunter:DeletePin(pTag)
	self.sv[pTag[1]][pTag[2]] = nil
	self.pinManager:RefreshCustomPins(self.pinTypeId)
end

local function ShowPinMenu(pin, button)
	local pType, pTag = pin:GetPinTypeAndTag()
	
	ClearMenu()
	AddMenuItem("Delete", function() HarvensHouseHunter:DeletePin(pTag) end)
	ShowMenu(pin:GetControl(), 1)
	
	--dirty hack! because something calls ClearMenu after this function returns
	local backupfunc = ClearMenu
	ClearMenu = function(...)
		ClearMenu = backupfunc
	end
end

function HarvensHouseHunter:SetupMapPins()
	local tooltipCreator = {
		creator = function(pin)
			InformationTooltip:AddLine(pin.harvensHouseHunterCustomText)
		end,
		tooltip = 1,
	}
	
	if not self.sv.pinSize then
		self.sv.pinSize = 36
	end
	
	if not self.sv.pinLevel then
		self.sv.pinLevel = 30
	end

	local layout = {
		level=self.sv.pinLevel,
		size=self.sv.pinSize,
		insetX=0,
		insetY=0,
		texture= "HarvensHouseHunter/Icon/woodendoor.dds",
	}
	
	ZO_WorldMap_AddCustomPin(self.pinTypeString, function(...) self:LayoutPins(...) end, nil, layout, tooltipCreator)
	self.pinTypeId = _G[self.pinTypeString]
	ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, true)
	ZO_MapPin.PIN_CLICK_HANDLERS[1][self.pinTypeId] = {
		{
			name = function(pin) return tostring(pin.harvensHouseHunterCustomText) end,
			show = function(...) return true end,
			callback = ShowPinMenu,
			duplicates = function(...) end,
		}
	}
end

--LOCK_QUALITY_ADVANCED = 3
--ADDITIONAL_INTERACT_INFO_LOCKED = 1

function HarvensHouseHunter:StartInteraction(...)
	local action, interactableName, interactionBlocked, isOwned, additionalInfo, context = GetGameCameraInteractableActionInfo()
	
	--d( action.."||"..interactableName.."||"..additionalInfo.."||"..context )
	
	if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
		CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
	end
	
	local minDistance = 0.03
	local zoneIndex = GetCurrentMapZoneIndex()
	local mapIndex = GetCurrentMapIndex()
	if mapIndex then
		minDistance = 0.003
	end
	local numPois = GetNumPOIs(zoneIndex)
	
	local mapName = zo_strformat("<<1>>", GetMapName())
	local actionName = zo_strformat(SI_GAME_CAMERA_TARGET, action)
	
	--It's "Open" when player is entering/exiting a house
	if actionName == GetString(SI_GAMECAMERAACTIONTYPE13) --[[and additionalInfo == ADDITIONAL_INTERACT_INFO_INSTANCE_TYPE and context and context == INSTANCE_TYPE_NONE--]] then
		interactableName = zo_strformat("<<1>>", interactableName)
		local poiName = ""
		
		if interactableName ~= mapName and self.lastOpenName then --check POIs if interactableName is different than mapName
			for i=1, numPois do
				poiName = zo_strformat("<<1>>", GetPOIInfo(zoneIndex, i))
				if string.find(poiName, interactableName) then--looks like the player is exiting a house
				--if poiName == interactableName then
					break
				end
			end
		end
		
		if ( interactableName == mapName or interactableName == poiName ) and self.lastOpenName then --looks like the player is exiting a house
			if not self.sv[mapName] then
				self.sv[mapName] = {}
			end
			if not self.sv[mapName][self.lastOpenName] then --no house stored under this name
				self:StoreHouse(mapName, self.lastOpenName, self.lastX, self.lastY, self.lastOpenName)
			else --house name already stored, check if it's the same house
				local key = self.lastOpenName
				local dist = 0
				for i=0,99 do
					if i > 0 then
						key = self.lastOpenName..i
					end
					if not self.sv[mapName][key] then
						break
					end
					local x = self.sv[mapName][key].x
					local y = self.sv[mapName][key].y
					dist = math.sqrt(((x-self.lastX)^2) + ((y-self.lastY)^2))
					if dist <= minDistance then --this door is closer than 0.003 map units to the stored door so it's probably the same door
						break
					end
				end
				if dist > minDistance then --this isn't the same house so store it
					self:StoreHouse(mapName, key, self.lastX, self.lastY, self.lastOpenName)
				end
			end
			self.lastOpenName = nil
		else --player is not exiting a house, so maybe he is entering it instead?
			--this may be a door interaction, but not sure now, save it for leter check
			self.lastOpenName = zo_strformat("<<1>>", interactableName)
			self.lastX, self.lastY = GetMapPlayerPosition("player")
		end
	end
	--d("action: "..tostring(action)..", name: "..tostring(interactableName)..", blocked: "..tostring(interactionBlocked)..", owned: "..tostring(isOwned)..", addi: "..tostring(additionalInfo)..", context: "..tostring(context))
	return self.fishingStartInteraction(...)
end

function HarvensHouseHunter:SetupMapFilter()
	ZO_CreateStringId("SI_MAPFILTER9333", "Doors")
	WORLD_MAP_FILTERS.pvePanel:SetMapMode(MAP_MODE_LARGE_CUSTOM) --Cyrodiil map fix
	if not WORLD_MAP_FILTERS.pvePanel:GetPinFilter(9333) then
		WORLD_MAP_FILTERS.pvePanel:SetPinFilter(9333, true)
	end
	WORLD_MAP_FILTERS.pvePanel:AddPinFilterCheckBox(9333, function(...)
		ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, WORLD_MAP_FILTERS.pvePanel:GetPinFilter(9333))
		ZO_WorldMap_RefreshCustomPinsOfType(self.pinTypeId)
	end)
	WORLD_MAP_FILTERS.pvePanel:LoadInitialState()
end

function HarvensHouseHunter:SetupOptions()
	local settings = LibHarvensAddonSettings:AddAddon("Harven's House Hunter")
	
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

function HarvensHouseHunter:Initialize(eventType, addonName)
	if addonName ~= "HarvensHouseHunter" then
		return
	end
	
	self.pinTypeId = 0
	self.pinTypeString = "HarvensHouseHunterPinType"
	self.unitName = zo_strformat("<<1>>", GetUnitName("player"))
	self.sv = self:GetSavedVariable()
	
	self:SetupMapPins()
	self:SetupMapFilter()
	self:SetupOptions()
	
	self.fishingStartInteraction = FISHING_MANAGER.StartInteraction
	FISHING_MANAGER.StartInteraction = function(...) --this is called when interacting with things
		return HarvensHouseHunter:StartInteraction(...)
	end
	
	SLASH_COMMANDS["/importdoors"] = function(character)
		if not HarvensHouseHunter_SavedVariables[character] then
			CHAT_SYSTEM:AddMessage("Choosen character has no doors or doesn't exists.")
			return
		end
		
		local duplicate = 0
		local imported = 0
		for mapName,doors in pairs(HarvensHouseHunter_SavedVariables[character]) do
			for k,v in pairs(doors) do
				if not self.sv[mapName] then
					self.sv[mapName] = {}
				end
				if not self.sv[mapName][k] then
					self.sv[mapName][k] = {x=v.x, y=v.y, n=v.n}
					imported = imported + 1
				else
					duplicate = duplicate + 1
				end
			end
		end
		
		CHAT_SYSTEM:AddMessage("Import completed. "..imported.." imported, "..duplicate.." skipped (duplicate)")
		self.pinManager:RefreshCustomPins(self.pinTypeId)
	end
	
	SLASH_COMMANDS["/cleardoors"] = function(all)
		if all == "all" then
			for k,v in pairs(self.sv) do
				self.sv[k] = nil
			end
			CHAT_SYSTEM:AddMessage("All doors cleared.")
		elseif all == "map" then
			local mapName = zo_strformat("<<1>>", GetMapName())
			self.sv[mapName] = nil
			CHAT_SYSTEM:AddMessage("Doors on "..mapName.." cleared.")
		else
			CHAT_SYSTEM:AddMessage("Usage: /cleardoors <all/map>")
		end
		self.pinManager:RefreshCustomPins(self.pinTypeId)
	end
end

EVENT_MANAGER:RegisterForEvent("HarvensHouseHunter", EVENT_ADD_ON_LOADED, function(...) HarvensHouseHunter:Initialize(...) end)