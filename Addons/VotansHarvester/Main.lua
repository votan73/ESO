local addon = {
	name = "VotansHarvester",
	itemTypes = {
		["Style"] = {ITEMTYPE_STYLE_MATERIAL},
		["Alchemy"] = {ITEMTYPE_REAGENT, ITEMTYPE_ALCHEMY_BASE},
		["Blacksmithing"] = {
			ITEMTYPE_WEAPON_TRAIT,
			ITEMTYPE_ARMOR_TRAIT,
			ITEMTYPE_BLACKSMITHING_MATERIAL,
			ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
			ITEMTYPE_BLACKSMITHING_BOOSTER
		},
		["Clothier"] = {
			ITEMTYPE_CLOTHIER_MATERIAL,
			ITEMTYPE_ARMOR_TRAIT,
			ITEMTYPE_CLOTHIER_RAW_MATERIAL,
			ITEMTYPE_CLOTHIER_BOOSTER
		},
		["Enchant"] = {ITEMTYPE_ENCHANTING_RUNE_ASPECT, ITEMTYPE_ENCHANTING_RUNE_ESSENCE, ITEMTYPE_ENCHANTING_RUNE_POTENCY},
		["Woodwork"] = {
			ITEMTYPE_WEAPON_TRAIT,
			ITEMTYPE_WOODWORKING_MATERIAL,
			ITEMTYPE_WOODWORKING_RAW_MATERIAL,
			ITEMTYPE_WOODWORKING_BOOSTER
		},
		["Provisioning"] = {ITEMTYPE_INGREDIENT}
	},
	recentCells = {},
	recentCellsIndex = {},
	searchFor = true,
	pinType = "VotansHarvesterPinType",
	currentPins = {}
}

local am = GetAnimationManager()
local em = GetEventManager()
local gps
local minDistance = 0.0000002384185791015625
local minDistance2 = minDistance / 1.5

local async = LibAsync

addon.pinManager = ZO_WorldMap_GetPinManager()

local function GetCell(x)
	return math.floor(x * 256)
end

local function GetPlayerPosition()
	local playerX, playerY = GetMapPlayerPosition("player")

	if playerX == 0 or playerY == 0 then
		if ZO_WorldMap_IsWorldMapShowing() then
			return playerX, playerY
		end
		if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
			CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
		end
		playerX, playerY = GetMapPlayerPosition("player")
	end

	playerX, playerY = gps:LocalToGlobal(playerX, playerY)
	return playerX, playerY
end

local zones
function addon:GetZone(create)
	local zoneId = GetZoneId(GetUnitZoneIndex("player"))
	local zone = zones[zoneId]
	if not zone and create then
		zone = {}
		zones[zoneId] = zone
	end
	return zone
end

function addon:GetOrCreateCell(x, y)
	local zone = self:GetZone(true)
	local cellX = zone[x]
	if not cellX then
		cellX = {}
		zone[x] = cellX
	end
	local cellY = cellX[y]
	if not cellY then
		cellY = {}
		cellX[y] = cellY
	end
	return cellY
end

local function AsTable(items)
	items = {zo_strsplit(",", items)}
	for i = #items, 1, -1 do
		if items[i] == "" then
			table.remove(items, i)
		end
	end
	return items
end

do
	local radius = 1 / 1024
	local playerX, playerY
	local list = {}
	local function GetContainer()
		local cellX, cellY = GetCell(playerX), GetCell(playerY)
		local cells = addon:GetOrCreateCell(cellX, cellY)
		local abs = math.abs
		for i = 1, #cells do
			local cell = cells[i]
			if (abs(cell.x - playerX) <= radius and abs(cell.y - playerY) <= radius) then
				return cell
			end
		end
		local cell = {x = playerX, y = playerY, items = ""}
		cells[#cells + 1] = cell
		addon:AddToRecent(cell)
		return cell
	end
	local function AddItem(container, item)
		assert(item and item ~= "", "empty item")
		d(item)
		if item and item ~= "" and not zo_plainstrfind(container.items, item) then
			local items = AsTable(container.items)
			local a = #items
			local b = a + 1
			items[#items + 1] = item
			container.items = table.concat(items, ",")
			container.x, container.y = (a * container.x + playerX) / b, (a * container.y + playerY) / b
		end
	end
	local GetItemLinkItemType = GetItemLinkItemType
	local function IsItemOfItemType(itemLink, types)
		local itemType = GetItemLinkItemType(itemLink)
		for i = 1, #types do
			if itemType == types[i] then
				return true
			end
		end
		return false
	end
	local function ProcessHarvest()
		local container = nil
		local added = false
		for key, types in pairs(addon.itemTypes) do
			for i = #list, 1, -1 do
				if IsItemOfItemType(list[i], types) then
					container = container or GetContainer()
					if not zo_plainstrfind(container.items, key) then
						added = true
						container.items = ((container.items and #container.items > 0) and string.format("%s,%s", container.items, key) or key):gsub("^,", ""):gsub("^,", "")
					end
					table.remove(list, i)
					break
				end
			end
		end
		if added then
			container.x, container.y = (container.x + playerX) / 2, (container.y + playerY) / 2
		end
		ZO_ClearNumericallyIndexedTable(list)
	end

	function addon.UpdateLootWindow(eventCode)
		local interactType = GetInteractionType()
		if interactType == INTERACTION_LOOT then
			local _, targetType, actionName, isOwned = GetLootTargetInfo()
			if isOwned and targetType == INTERACT_TARGET_TYPE_OBJECT and actionName == GetString(SI_GAMECAMERAACTIONTYPE19) then
				playerX, playerY = GetPlayerPosition()
				AddItem(GetContainer(), "Thief")
			elseif actionName and actionName ~= "" then
				local numLootItems = GetNumLootItems()
				if numLootItems == 0 then
					return
				end

				local GetLootItemLink = GetLootItemLink
				for i = 1, numLootItems do
					local lootId, name, icon, count, quality, value, isQuest, isStolen = GetLootItemInfo(i)
					if not isStolen and not isQuest then
						list[#list + 1] = GetLootItemLink(lootId)
					end
				end
			end
		end
	end

	function addon.OnLootReceived(eventCode, receivedBy, itemName, quantity, itemSound, lootType, yourself, isPickpocketLoot, questItemIcon)
		if not yourself then
			return
		end
		if #list > 0 then
			playerX, playerY = GetPlayerPosition()
			ProcessHarvest()
		end
	end
	-- function addon.OnInventorySlotUpdated(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason)
	-- 	d("OnInventorySlotUpdated")
	-- 	assert(updateReason == INVENTORY_UPDATE_REASON_DEFAULT, "stimmt nicht1")
	-- 	assert(bagId == BAG_BACKPACK or bagId == BAG_VIRTUAL, "stimmt nicht2")
	-- 	d("ok", GetInteractionType())
	-- 	list[#list + 1] = GetItemLink(bagId, slotIndex)
	-- end
	function addon.LockpickScene(oldState, newState)
		if newState ~= SCENE_SHOWN then
			return
		end
		if GetInteractionType() ~= INTERACTION_LOCKPICK then
			return
		end

		playerX, playerY = GetPlayerPosition()
		ZO_ClearNumericallyIndexedTable(list)
		local isStolen = select(4, GetLootTargetInfo())
		if not isStolen then
			AddItem(GetContainer(), "Treasure")
		end
	end

	local identifier = "VOTANS_HARVESTER_AUTOLOOT"
	local lastInteractionType
	local function resetInteractionType()
		if IsPlayerInteractingWithObject() or IsInteractionPending() and not IsPlayerMoving() then
			return
		end
		em:UnregisterForUpdate(identifier)
		lastInteractionType = false
	end
	ZO_PreHook(
		FISHING_MANAGER or INTERACTIVE_WHEEL_MANAGER,
		"StopInteraction",
		function()
			local action = GetGameCameraInteractableActionInfo()
			lastInteractionType = action and action ~= "" and INTERACTION_LOOT
			em:UnregisterForUpdate(identifier)
			em:RegisterForUpdate(identifier, 250, resetInteractionType)
		end
	)
	function addon.OnSlot(bagId, slotIndex, slotData)
		if lastInteractionType then
			list[#list + 1] = GetItemLink(bagId, slotIndex)
			playerX, playerY = GetPlayerPosition()
			ProcessHarvest()
		end
	end
end

local function FindClosest()
	local playerX, playerY = GetPlayerPosition()
	if not playerX or playerX == 0 or playerY == 0 then
		return
	end
	local cellX, cellY = GetCell(playerX), GetCell(playerY)

	local bestDistance = 1
	local index = 0
	local zone = addon:GetZone(false)
	local currentPins = addon.currentPins
	if zone then
		local recent = addon.recentCellsIndex
		local function BestMatch(cell, list, i)
			local dx, dy
			for key, required in pairs(addon.searchFor) do
				if required and zo_plainstrfind(cell.items, key) then
					dx, dy = playerX - cell.x, playerY - cell.y
					dx, dy = dx * dx, dy * dy
					dx = dx + dy

					index = index + 1
					local pinTag = currentPins[index]
					if not pinTag then
						pinTag = {}
						currentPins[index] = pinTag
					end
					pinTag.distance = dx
					pinTag.cell = cell
					pinTag.container = list
					pinTag.index = i
					if dx < bestDistance then
						bestDistance = dx
					end
					return
				end
			end
		end
		local function ScanCell(list)
			for i = 1, #list do
				if list[i] and not recent[list[i]] then
					BestMatch(list[i], list, i)
				end
			end
		end
		local cx, cy
		for x = cellX - 1, cellX + 1 do
			cx = zone[x]
			if cx then
				for y = cellY - 1, cellY + 1 do
					cy = cx[y]
					if cy then
						ScanCell(cy)
					end
				end
			end
		end
	end
	addon.pinCount = index
	for i = index + 1, #currentPins do
		currentPins[i].distance = 2
		currentPins[i].cell = nil
	end

	table.sort(
		currentPins,
		function(a, b)
			return a.distance < b.distance
		end
	)
	local bestCell = index >= 1 and currentPins[1].cell or nil
	if addon.bestCell ~= bestCell then
		addon.bestCell = bestCell
	end

	if bestCell and (index >= 2 and currentPins[2].cell) then
		if math.abs(currentPins[1].distance - currentPins[2].distance) < minDistance2 then
			local other = currentPins[2]
			local otherCell = other.cell
			local i1, i2 = AsTable(bestCell.items), AsTable(otherCell.items)
			local a, b = #i1, #i2
			local c = a + b
			if c > 0 then
				bestCell.x, bestCell.y = (a * bestCell.x + b * otherCell.x) / c, (a * bestCell.y + b * otherCell.y) / c
				for _, item in pairs(i2) do
					if item ~= "" and not zo_plainstrfind(bestCell.items, item) then
						i1[#i1 + 1] = item
					end
				end
				table.remove(other.container, other.index)
				table.remove(currentPins, 2)
				other.cell = nil
				other.distance = 2
				bestCell.items = table.concat(i1, ",")
			end
		end
	end

	if addon.pinManager then
		local pinManager = addon.pinManager
		local pins = pinManager.m_keyToPinMapping[addon.pinType][addon.pinTypeId]
		if pins then
			local x, y, pin, cell
			local shown = GetMapType()
			shown = shown ~= MAPTYPE_COSMIC and shown ~= MAPTYPE_WORLD
			-- 		local radius = gps:GlobalToLocal(playerX + 1 / 1024, playerY) - gps:GlobalToLocal(playerX, playerY)
			-- 		d(radius)
			for i = 1, 10 do
				cell = currentPins[i]
				if cell then
					cell = cell.cell
				end
				pin = pinManager:GetExistingObject(pins[i])
				if pin then
					if cell and shown then
						x, y = gps:GlobalToLocal(cell.x, cell.y)
						if pin.normalizedX ~= x or pin.normalizedY ~= y then
							pin:SetLocation(x, y)
						end
					else
						if pin.normalizedX ~= 0 or pin.normalizedY ~= 0 then
							pin:SetLocation(0, 0)
						end
					end
				end
			end
		end
	end

	VOTANS_HARVESTER_FRAGMENT:SetHiddenForReason("NoCell", bestCell == nil)
	local tooClose = bestDistance < minDistance
	if tooClose and bestCell then
		addon:AddToRecent(bestCell)
	end
	VOTANS_HARVESTER_FRAGMENT:SetHiddenForReason("TooClose", tooClose)
	-- addon.reachTargetAnim:PlayInstantlyToStart()

	-- VOTANS_HARVESTER_FRAGMENT:Refresh()
end

function addon:AddToRecent(cell)
	local recent, recentIndex = self.recentCells, self.recentCellsIndex
	if recentIndex[cell] then
		return
	end
	local lastCell = recent[self.account.maxRecent]
	if lastCell then
		recentIndex[lastCell] = nil
	end
	for i = math.min(self.account.maxRecent, #recent + 1), 2, -1 do
		recent[i] = recent[i - 1]
	end
	recent[1] = cell
	recentIndex[cell] = true
end

function addon:EnableHeadingUpdates(enabled)
	local identifier = "VOTANS_HEADING_UPDATE"
	local function HeadingUpdate()
		local cell = self.bestCell
		if not cell then
			return
		end

		local playerX, playerY = GetPlayerPosition()
		local heading = GetPlayerCameraHeading()
		local dy, dx = playerY - cell.y, cell.x - playerX
		local rads = math.atan2(dy, dx) - heading - math.pi / 2
		self.arrow:SetTextureRotation(rads)

		local distance = dx * dx + dy * dy
		local tooClose = distance < minDistance
		VOTANS_HARVESTER_FRAGMENT:SetHiddenForReason("TooClose", tooClose)
		if tooClose then
			self:AddToRecent(cell)
			-- addon.reachTargetAnim:PlayFromStart()
			VOTANS_HARVESTER_FRAGMENT:Refresh()
		end
	end
	em:UnregisterForUpdate(identifier)
	if enabled then
		em:RegisterForUpdate(identifier, 50, HeadingUpdate)
	end
end

do
	local identifier = "VOTANSHARVESTER_FIND_CLOSETS"
	function addon:EnableTracking(enabled)
		enabled = enabled and self.player.enabled
		VOTANS_HARVESTER_FRAGMENT:SetHiddenForReason("TrackingDisabled", not enabled)
		if enabled then
			em:UnregisterForUpdate(identifier)
			em:RegisterForUpdate(identifier, 3000, FindClosest)
		else
			em:UnregisterForUpdate(identifier)
		end
		return enabled
	end
end

do
	local lastEnabled = true
	function addon:RefreshTracking()
		local enabled = self:EnableTracking(not IsUnitInCombat("player"))
		local pinEnabled = ZO_WorldMap_IsCustomPinEnabled(self.pinTypeId)
		if pinEnabled ~= enabled then
			ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, enabled)
		end
		if lastEnabled ~= enabled then
			CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_BROADCAST, CSA_CATEGORY_SMALL_TEXT, nil, GetString(enabled and SI_HARVESTER_TRACKING_ON or SI_HARVESTER_TRACKING_OFF))
			lastEnabled = enabled
		end
	end
end

function addon:ToggleTracking()
	self.player.enabled = not self.player.enabled
	self:RefreshTracking()
	if addon.settingsControls.selected then
		addon.settingsControls:UpdateControls()
	end
end

function addon:InitControls()
	local control
	local wm = GetWindowManager()

	control = wm:CreateTopLevelWindow("VotansHarvesterTopLevel")
	control:SetMouseEnabled(false)
	control:SetMovable(false)
	control:SetHidden(true)
	control:SetDimensions(104, 104)
	control:SetAnchor(CENTER, ZO_ReticleContainerReticle, CENTER)
	self.window = control

	control = wm:CreateControl("$(parent)Arrow", self.window, CT_TEXTURE)
	control:SetTexture("VotansHarvester/Textures/ReticleArrow.dds")
	control:SetColor(ZO_ColorDef:New("00A318"):UnpackRGBA())
	control:SetAlpha(0.667)
	control:SetDrawLayer(1)
	control:SetDrawLevel(1)
	control:SetDrawTier(1)
	control:SetAnchorFill()
	self.arrow = control

	-- addon.reachTargetAnim = am:CreateTimelineFromVirtual("NotificationPulse", self.arrow)
	-- local anim = addon.reachTargetAnim:GetFirstAnimation()
	-- anim:SetDuration(2000)
	-- addon.reachTargetAnim:SetPlaybackType(ANIMATION_PLAYBACK_ONE_SHOT, 0)

	VOTANS_HARVESTER_FRAGMENT = ZO_HUDFadeSceneFragment:New(self.window, 500, 0)
	HUD_SCENE:AddFragment(VOTANS_HARVESTER_FRAGMENT)

	VOTANS_HARVESTER_FRAGMENT:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			self:EnableHeadingUpdates(newState == SCENE_FRAGMENT_SHOWING or newState == SCENE_FRAGMENT_SHOWN)
		end
	)
	VOTANS_HARVESTER_FRAGMENT:SetHiddenForReason("NoCell", true)
end

local function CombatChanged(eventCode, inCombat)
	VOTANS_HARVESTER_FRAGMENT:SetHiddenForReason("inCombat", inCombat)
	addon:EnableTracking(not inCombat)
end

function addon:PinClicked(pin)
	local identifier = "VOTANS_HARVESTER_CONTEXTMENU"

	local function Erase()
		local _, index = pin:GetPinTypeAndTag()
		local mapPin = self.currentPins[index]
		-- SLASH_COMMANDS["/zgoo"]()
		table.remove(mapPin.container, mapPin.index)
		FindClosest()
	end

	local function ShowContextMenu()
		em:UnregisterForUpdate(identifier)
		ClearMenu()
		-- 	AddCustomMenuItem(GetString(SI_WORLD_MAP_ACTION_SET_PLAYER_WAYPOINT), function() PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, pin.normalizedX, pin.normalizedY) end)
		-- 	AddCustomMenuItem("-")
		AddCustomSubMenuItem(
			GetString(SI_HARVESTER_DELETE),
			{
				{
					label = GetString(SI_DIALOG_CONFIRM),
					callback = Erase
				}
			}
		)
		ShowMenu(pin:GetControl())
	end
	em:RegisterForUpdate(identifier, 50, ShowContextMenu)
end

function addon:GetPinText(pin)
	local _, index = pin:GetPinTypeAndTag()
	pin = addon.currentPins[index]
	if not pin or not pin.cell or not pin.cell.items then
		return "?"
	end

	return pin.cell.items:gsub(",", ", ")
end

do
	local function LayoutPins(pinManager)
		local pinTypeId = addon.pinTypeId

		local pin
		for i = 1, 10 do
			pin = pinManager:FindPin(addon.pinType, pinTypeId, i) or pinManager:CreatePin(pinTypeId, i, 0, 0)
		end
	end

	local mystyle = {fontSize = 34, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1}
	local creator = {
		creator = function(pin)
			local text = addon:GetPinText(pin)
			if IsInGamepadPreferredMode() then
				local tooltip = ZO_MapLocationTooltip_Gamepad.tooltip
				tooltip:AddLine(text, mystyle, tooltip:GetStyle("bodySection"))
			else
				local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
				InformationTooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
			end
		end,
		tooltip = 1
	}
	function addon:AddPinType()
		self.layout = {
			level = 25,
			size = 24,
			insetX = 0,
			insetY = 0,
			texture = function(pin)
				return "EsoUI/Art/MapPins/map_areaPin_32.dds"
			end,
			tint = self.pinColor
		}

		ZO_WorldMap_AddCustomPin(self.pinType, LayoutPins, nil, self.layout, creator)
		self.pinTypeId = _G[self.pinType]
		ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, true)

		local contextmenu = {
			{
				name = function(pin)
					return self:GetPinText(pin)
				end,
				show = function(pin)
					return true
				end,
				callback = function(pin)
					self:PinClicked(pin)
				end,
				duplicates = function(pin1, pin2)
					return pin1 == pin2
				end,
				gamepadName = function(pinDatas)
					for i = 1, #pinDatas do
						local pin = pinDatas[i].pin
						local pinType, tag = pin:GetPinTypeAndTag()
						if pinType == addon.pinTypeId then
							d("----", pinDatas[i], "....", tag)
							return tag:GetText()
						end
					end
				end
			}
		}
		ZO_MapPin.PIN_CLICK_HANDLERS[1][self.pinTypeId] = contextmenu
	end
end

function addon:Initialize()
	gps = LibGPS2
	if not gps then
		return
	end

	self.player =
		ZO_SavedVars:NewCharacterIdSettings(
		"VotansHarvester_Data",
		1,
		nil,
		{
			enabled = true,
			searchFor = {
				["Style"] = true,
				["Alchemy"] = true,
				["Blacksmithing"] = true,
				["Clothier"] = true,
				["Enchant"] = true,
				["Woodwork"] = true,
				["Provisioning"] = true,
				["Treasure"] = true,
				["Thief"] = true
			}
		}
	)
	self.account =
		ZO_SavedVars:NewAccountWide(
		"VotansHarvester_Data",
		1,
		nil,
		{
			maxRecent = 12
		}
	)
	-- if not VotansHarvester_Zones and self.account.zones then
	-- 	VotansHarvester_Zones = self.account.zones
	-- 	self.account.zones = nil
	-- end
	if not VotansHarvester_Zones then
		VotansHarvester_Zones = {}
	end
	zones = VotansHarvester_Zones

	local ZO_ClearNumericallyIndexedTable = ZO_ClearNumericallyIndexedTable
	local list, node
	async:For(pairs(zones)):Do(
		function(id, x)
			async:For(pairs(x)):Do(
				function(k2, y)
					for k1, nodes in pairs(y) do
						for i = #nodes, 1, -1 do
							node = nodes[i]
							list = AsTable(node.items)
							if #list > 0 then
								node.items = table.concat(list, ",")
							else
								table.remove(nodes, i)
							end
						end
						if not next(nodes) then
							y[k1] = nil
						end
					end
					if not next(y) then
						x[k2] = nil
					end
				end
			):Then(
				function()
					if not next(zones) then
						zones[id] = nil
					end
				end
			)
		end
	)

	self.searchFor = self.player.searchFor

	self.pinColor = ZO_ColorDef:New("FFFFFF")

	SHARED_INVENTORY:RegisterCallback("SlotAdded", addon.OnSlot)
	SHARED_INVENTORY:RegisterCallback("SlotUpdated", addon.OnSlot)

	em:RegisterForEvent(self.name, EVENT_LOOT_UPDATED, addon.UpdateLootWindow)
	LOCK_PICK_SCENE:RegisterCallback("StateChange", addon.LockpickScene)
	-- em:RegisterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, addon.OnInventorySlotUpdated)
	-- if HasCraftBagAccess() then
	-- 	em:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_VIRTUAL)
	-- else
	-- 	em:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
	-- end
	-- em:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT, REGISTER_FILTER_IS_NEW_ITEM, true)

	em:RegisterForEvent(self.name, EVENT_LOOT_RECEIVED, addon.OnLootReceived)

	local function PlayerActivated()
		self:RefreshTracking()
	end
	em:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, PlayerActivated)

	local function PlayerDeactivated()
		self:EnableTracking(false)
	end
	em:RegisterForEvent(self.name, EVENT_PLAYER_DEACTIVATED, PlayerDeactivated)

	em:RegisterForEvent(addon.name, EVENT_PLAYER_COMBAT_STATE, CombatChanged)

	self:AddPinType()
end

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Harvester")
	if not settings then
		return
	end
	settings.version = "1.1.8"
	addon.settingsControls = settings

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Tracking",
		tooltip = "Enable or disabled tracking at all.",
		getFunction = function()
			return self.player.enabled
		end,
		setFunction = function(value)
			self.player.enabled = value
			self:RefreshTracking()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Max Recent Nodes",
		tooltip = "Number of recent nodes been skipped after reaching them.",
		min = 2,
		max = 50,
		step = 1,
		default = 12,
		format = "%f",
		unit = "",
		getFunction = function()
			return self.account.maxRecent
		end,
		setFunction = function(value)
			self.account.maxRecent = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = "Track"
	}

	local sorted = {}
	local displayText = {}
	self.displayText = displayText
	for key in pairs(self.searchFor) do
		local text = GetString(_G["SI_HARVESTER_CATEGORY_" .. key:upper()]) or key
		displayText[key] = text
		sorted[#sorted + 1] = key
	end
	table.sort(
		sorted,
		function(a, b)
			return displayText[a] < displayText[b]
		end
	)
	for i = 1, #sorted do
		local key = sorted[i]
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = displayText[key],
			tooltip = "",
			getFunction = function()
				return self.searchFor[key]
			end,
			setFunction = function(value)
				self.searchFor[key] = value
			end
		}
	end
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:InitControls()
	addon:Initialize()
	addon:InitSettings()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_HARVESTER = addon
