local HarvensCustomMapPins = {}

local MAPPIN_LINK_TYPE = "hcmp"

function HarvensCustomMapPins:New()
	self:Initialize()
	return self
end

function HarvensCustomMapPins:GetKeyFromTag(pTag)
	local tileName, cfloor, key = string.match(pTag, "([^%s]+) ([^%s]+) ([^%s]+)")
	return tileName, tonumber(cfloor), tonumber(key)
end

do
	local tileNames = {}
	function HarvensCustomMapPins:GetTileAndFloorFromCurrentMap()
		local currentFloor, maxFloors = GetMapFloorInfo()
		if maxFloors == 0 then
			currentFloor = 1
		end

		local tileTexture = GetMapTileTexture(1)
		if tileNames[tileTexture] then
			return tileNames[tileTexture], currentFloor
		end

		local tileName = tileTexture:gsub("_0", ""):gsub("[_%-%s%p]", ""):lower()
		tileNames[tileTexture] = tileName

		local mapName = GetMapName()
		local toNewFormat = {}
		-- convert pins from old to new format

		for k, v in pairs(self.customPins) do
			if type(k) == "number" then
				if not self.customPins[k].color then
					self.customPins[k].color = "FFFFFFFF"
				end
				if mapName == v.map then
					toNewFormat[k] = v
					self.customPins[k] = nil
				end
			end
		end
		if next(toNewFormat) ~= nil then
			local pins = self:GetOrCreateMapPins(tileName, currentFloor)
			for k, v in pairs(toNewFormat) do
				pins[k] = v
			end
		end

		return tileName, currentFloor
	end
end

function HarvensCustomMapPins:CreatePinKey(tileName, currentFloor, key)
	return string.format("%s %i %i", tileName, currentFloor, key)
end

function HarvensCustomMapPins:GetPin(pTag)
	local tileName, cfloor, key = self:GetKeyFromTag(pTag)
	local pins = self:GetMapPins(tileName, cfloor)
	return pins and pins[key]
end

function HarvensCustomMapPins:CreatePinSavedVariable(tileName, currentFloor, mapName, x, y, description, icon, color, predefined)
	local pins = self:GetOrCreateMapPins(tileName, currentFloor)

	local key = string.format("%.f%.f", x * 10000, y * 10000)
	key = tonumber(key)

	if type(color) == "table" then
		color = ZO_ColorDef.ToARGBHexadecimal(unpack(color))
	end

	if predefined and self.sv.predefined[predefined] then
		pins[key] = {
			x = x,
			y = y,
			map = mapName,
			description = description,
			predefined = predefined
		}
	else
		pins[key] = {
			x = x,
			y = y,
			map = mapName,
			description = description,
			icon = icon,
			color = color
		}
	end
	return pins[key], key
end

function HarvensCustomMapPins:GetCurrentMapPins()
	local tileName, currentFloor = self:GetTileAndFloorFromCurrentMap()
	return self:GetMapPins(tileName, currentFloor)
end

function HarvensCustomMapPins:GetMapPins(tileName, currentFloor)
	if not self.customPins[tileName] then
		return
	end
	if not self.customPins[tileName][currentFloor] then
		return
	end

	return self.customPins[tileName][currentFloor], tileName, currentFloor
end

function HarvensCustomMapPins:GetOrCreateMapPins(tileName, currentFloor)
	if not self.customPins[tileName] then
		self.customPins[tileName] = {}
	end

	if not self.customPins[tileName][currentFloor] then
		self.customPins[tileName][currentFloor] = {}
	end
	return self.customPins[tileName][currentFloor], tileName, currentFloor
end

function HarvensCustomMapPins:AddPinToCurrentMap(x, y, description, icon, color, predefined)
	if type(x) ~= "number" or type(y) ~= "number" or type(description) ~= "string" or type(icon) ~= "number" then
		return
	end
	if type(color) ~= "table" and type(color) ~= "string" then
		return
	end
	if x < 0 or x > 1 or y < 0 or y > 1 then
		return
	end

	local tileName, currentFloor = self:GetTileAndFloorFromCurrentMap()
	if not tileName then
		d("no tileName")
		return
	end

	local pin, key = self:CreatePinSavedVariable(tileName, currentFloor, GetMapName(), x, y, description, icon, color, predefined)

	self:CreatePin(pin, self:CreatePinKey(tileName, currentFloor, key))
	return pin
end

function HarvensCustomMapPins:FindPinOnCurrentMap(x, y, radius)
	if type(x) ~= "number" or type(y) ~= "number" or type(radius) ~= "number" then
		return
	end

	local ret = {}
	local pins = self:GetCurrentMapPins()
	if not pins then
		return ret
	end
	for k, v in pairs(pins) do
		if v.x <= x + radius and v.x >= x - radius and v.y <= y + radius and v.y >= y - radius then
			ret[#ret + 1] = v
		end
	end
	return ret
end

function HarvensCustomMapPins:SharePin(pTag)
	local data = self:GetPin(pTag)
	if not data then
		return
	end

	local predefined = data.predefined
	predefined = self.sv.predefined[predefined]

	local text = {}
	text[#text + 1] = "|H1:"
	text[#text + 1] = MAPPIN_LINK_TYPE
	text[#text + 1] = ":"
	text[#text + 1] = zo_round(data.x * 10000)
	text[#text + 1] = ":"
	text[#text + 1] = zo_round(data.y * 10000)
	text[#text + 1] = ":"
	text[#text + 1] = predefined and predefined.icon or data.icon or 1
	text[#text + 1] = ":"
	text[#text + 1] = predefined and predefined.color or data.color or "ffffff"
	text[#text + 1] = ":"
	text[#text + 1] = pTag
	text[#text + 1] = "|h["
	text[#text + 1] = data.description:gsub("\r", ""):gsub("\n", "\194\160")
	text[#text + 1] = "]|h"

	CHAT_SYSTEM:StartTextEntry(table.concat(text))
end

function HarvensCustomMapPins:DeletePin(pTag)
	if not self.pinManager then
		return
	end
	local tileName, cfloor, key = self:GetKeyFromTag(pTag)
	local pins = self:GetMapPins(tileName, cfloor)
	if not pins then
		return
	end
	pins[key] = nil
	--[[
		I think this is only way to delete a pin
		pinManager will destroy all custom pins
		and recreate them by calling LayoutPins
	--]]
	self.pinManager:RefreshCustomPins(self.pinTypeId)
end

function HarvensCustomMapPins:EditPin(pin, pType, pTag)
	ZO_Dialogs_ShowDialog("HARVENS_CUSTOM_MAP_PINS_EDIT", {key = pTag, edit = true})
end

function HarvensCustomMapPins:RefreshPins()
	ZO_WorldMap_RefreshCustomPinsOfType(self.pinTypeId)
end

function HarvensCustomMapPins:SetColor(pin, pTag)
	if not pin or not pin.__index or pin.__index ~= ZO_MapPin then
		return
	end
	local tileName, cfloor, key = self:GetKeyFromTag(pTag)
	local pins = self:GetOrCreateMapPins(tileName, cfloor)
	if not pins or not pins[key] then
		return
	end
	COLOR_PICKER:Show(
		function(newR, newG, newB, newA)
			if not self.pinManager then
				return
			end
			pins[key].color = {newR, newG, newB, newA}
			self.sv.lastUsedColor = {newR, newG, newB, newA}
			self.pinManager:RefreshCustomPins(self.pinTypeId)
		end,
		unpack(pins[key].color)
	)
	COLOR_PICKER:UpdateColors(unpack(pins[key].color))
end

local function ShowPinMenu(pin, button)
	if not pin or not pin.__index or pin.__index ~= ZO_MapPin then
		return
	end
	local pType, pTag = pin:GetPinTypeAndTag()

	ZO_WorldMap:StopMovingOrResizing()
	ZO_WorldMap_MouseUp()
	ClearMenu()
	AddCustomMenuItem(
		"Edit",
		function()
			HarvensCustomMapPins:EditPin(pin, pType, pTag)
		end
	)
	AddCustomMenuItem(
		"Show in Popup",
		function()
			local pin = HarvensCustomMapPins:GetPin(pTag)
			if not pin then
				return
			end
			PopupTooltip:SetHidden(false)
			PopupTooltip:ClearLines()
			PopupTooltip:AddLine(pin.description, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
		end
	)
	AddCustomMenuItem(
		"Share",
		function()
			HarvensCustomMapPins:SharePin(pTag)
		end
	)
	AddCustomMenuItem("-")
	AddCustomMenuItem(
		"Delete",
		function()
			HarvensCustomMapPins:DeletePin(pTag)
		end
	)
	ShowMenu(pin:GetControl(), 1)

	-- dirty hack! because something calls ClearMenu after this function returns
	local backupfunc = ClearMenu
	ClearMenu = function(...)
		ClearMenu = backupfunc
	end
end

function HarvensCustomMapPins:CreatePin(cpin, key)
	if not self.pinManager then
		return
	end
	local pin = self.pinManager:CreatePin(self.pinTypeId, key, cpin.x, cpin.y, 0)
	return pin
end

local function LayoutPinsAtOnce(pinManager)
	local self = HarvensCustomMapPins
	local currentPins, tileName, currentFloor = self:GetCurrentMapPins()
	if not currentPins then
		return
	end

	if self.sv.allowSubFilter then
		local showPredefined = self.sv.showPredefined
		for k, v in pairs(currentPins) do
			local key = self:CreatePinKey(tileName, currentFloor, k)
			if showPredefined[v.predefined or ""] ~= false then
				self:CreatePin(v, key)
			end
		end
	else
		for k, v in pairs(currentPins) do
			local key = self:CreatePinKey(tileName, currentFloor, k)
			self:CreatePin(v, key)
		end
	end
end

local async = LibAsync

local task = async:Create("HARVENS_CUSTOMPINS_LAYOUT")
do
	local orgRemovePins = ZO_WorldMapPins.RemovePins
	function ZO_WorldMapPins:RemovePins(lookupType, majorIndex, keyIndex)
		if lookupType == HarvensCustomMapPins.pinTypeString then
			task:Cancel()
		end
		return orgRemovePins(self, lookupType, majorIndex, keyIndex)
	end
end

local function LayoutPinsSpread(pinManager)
	local self = HarvensCustomMapPins
	local currentPins, tileName, currentFloor = self:GetCurrentMapPins()
	if not currentPins then
		return
	end

	if self.sv.allowSubFilter then
		local showPredefined = self.sv.showPredefined
		local function DrawPin(k, v)
			if showPredefined[v.predefined or ""] ~= false then
				local key = self:CreatePinKey(tileName, currentFloor, k)
				self:CreatePin(v, key)
			end
		end
		task:Cancel():For(pairs(currentPins)):Do(DrawPin)
	else
		local function DrawPin(k, v)
			local key = self:CreatePinKey(tileName, currentFloor, k)
			self:CreatePin(v, key)
		end
		task:Cancel():For(pairs(currentPins)):Do(DrawPin)
	end
end

-- This function is called by wordmap when changing map or after calling RefreshCustomPins
local function LayoutPins(pinManager)
	if not pinManager.__index == ZO_WorldMapPins then
		-- In ZO_WorldMapPins pinManager I trust
		return
	end
	task:Cancel()
	if HarvensCustomMapPins.sv.alternateRenderer then
		LayoutPinsSpread(pinManager)
	else
		LayoutPinsAtOnce(pinManager)
	end
end

function HarvensCustomMapPins:ShowDialog(x, y)
	local tileName, currentFloor = HarvensCustomMapPins:GetTileAndFloorFromCurrentMap()

	local color = self.sv.lastUsedColor or {1, 1, 1, 1}

	local _, key = self:CreatePinSavedVariable(tileName, currentFloor, GetMapName(), x, y, "", 1, color)
	ZO_Dialogs_ShowDialog("HARVENS_CUSTOM_MAP_PINS_EDIT", {key = self:CreatePinKey(tileName, currentFloor, key), edit = false}, {})
end

function HarvensCustomMapPins_WorldMapPlacePin()
	local x, y = NormalizeMousePositionToControl(ZO_WorldMapContainer)
	if (x > 0 and x < 1 and y > 0 and y < 1) then
		HarvensCustomMapPins:ShowDialog(x, y)
	end
end

function HarvensCustomMapPins_CustomPinCommand()
	local x, y = GetMapPlayerPosition("player")
	HarvensCustomMapPins:ShowDialog(x, y)
end

function HarvensCustomMapPins:InjectKeystrip()
	local orgBackup = KEYBIND_STRIP.AddKeybindButtonGroup

	KEYBIND_STRIP.AddKeybindButtonGroup = function(keybindStripManager, strip, ...)
		if not SCENE_MANAGER:IsShowing("worldMap") then
			return orgBackup(keybindStripManager, strip, ...)
		end

		local found = false
		for i = 1, #strip do
			if strip[i] == nil then
				break
			end

			if type(strip[i].name) == "string" and strip[i].name == zo_strformat(SI_WORLD_MAP_CURRENT_LOCATION) then
				found = true
				break
			end
		end

		if found then
			table.insert(strip, {name = "Place custom pin", keybind = "UI_SHORTCUT_NEGATIVE", callback = HarvensCustomMapPins_WorldMapPlacePin})
			KEYBIND_STRIP.AddKeybindButtonGroup = orgBackup
			return KEYBIND_STRIP.AddKeybindButtonGroup(keybindStripManager, strip, ...)
		else
			return orgBackup(keybindStripManager, strip, ...)
		end
	end
end

function HarvensCustomMapPins:ImportPinsToAccountWide()
	if self.sv_old.exported then
		return
	end

	for k, v in pairs(self.sv_old.pins) do
		if not self.customPins[k] then
			self.customPins[k] = {
				map = v.map,
				description = v.description,
				x = v.x,
				y = v.y,
				icon = v.icon
			}
		end
	end
	self.sv_old.exported = true
end

function HarvensCustomMapPins:ImportFromImportSection()
	if not HarvensCustomMapPins_SavedVariables or not HarvensCustomMapPins_SavedVariables["import"] then
		CHAT_SYSTEM:AddMessage("No import section in the SavedVariable file. Logout and make sure that the section is present.")
		return
	end
	for k, v in pairs(HarvensCustomMapPins_SavedVariables["import"]) do
		if type(k) == "number" then
			-- old format
			if not self.customPins[k] then
				if type(v) ~= "table" or not v.map or not v.description or not v.x or not v.y or not v.color or type(v.color) ~= "table" then
					CHAT_SYSTEM:AddMessage("Pin " .. k .. " seems to be malformed, ignoring.")
				else
					self.customPins[k] = {
						map = v.map,
						description = v.description,
						x = v.x,
						y = v.y,
						color = {
							v.color[1],
							v.color[2],
							v.color[3],
							v.color[4]
						},
						icon = v.icon
					}
					CHAT_SYSTEM:AddMessage("Imported pin '" .. v.description .. "' on map '" .. zo_strformat("<<1>>", v.map) .. "' location " .. v.x .. ", " .. v.y)
				end
			else
				CHAT_SYSTEM:AddMessage("A pin is already present at that location: " .. v.x .. ", " .. v.y .. " " .. v.description)
			end
		else
			-- new format
			if not self.customPins[k] then
				self.customPins[k] = {}
			end
			for cfloor, floorPins in pairs(v) do
				if not self.customPins[k][cfloor] then
					self.customPins[k][cfloor] = {}
				end
				for key, pinData in pairs(floorPins) do
					if not self.customPins[k][cfloor][key] then
						self.customPins[k][cfloor][key] = {
							map = v.map,
							description = v.description,
							x = v.x,
							y = v.y,
							color = {
								v.color[1],
								v.color[2],
								v.color[3],
								v.color[4]
							},
							icon = v.icon
						}
					else
						CHAT_SYSTEM:AddMessage("A pin is already present at that location: " .. pinData.x .. ", " .. pinData.y .. " " .. pinData.description)
					end
				end
			end
		end
	end
	CHAT_SYSTEM:AddMessage("Import completed!")
	HarvensCustomMapPins_SavedVariables["import"] = nil
end

function HarvensCustomMapPins:OnLinkClicked(link, button, description, color, linkType, linkStyle, ...)
	if linkType ~= MAPPIN_LINK_TYPE then
		return false
	end

	local x, y, icon, color, pTag = ...
	if not pTag then
		pTag = color
		color = "FFFFFF"
	end
	x, y = tonumber(x) / 10000, tonumber(y) / 10000
	icon = tonumber(icon)
	description = description:gsub("\194\160", "\n"):match("^.(.*).$")

	local pin = {}
	pin.x = x
	pin.y = y
	pin.description = description
	pin.icon = icon
	pin.color = color

	local tileName, cfloor, key = self:GetKeyFromTag(pTag)
	local pins = self:GetMapPins(tileName, cfloor)
	local data = pins and pins[key]
	ZO_Dialogs_ShowDialog("HARVENS_CUSTOM_MAP_PINS_EDIT", {key = pTag, edit = data ~= nil, pin = pin})

	return true
end

function HarvensCustomMapPins:UpdateLegend()
	GAMEPAD_WORLD_MAP_KEY.dirty = true
	WORLD_MAP_KEY.dirty = true
	GAMEPAD_WORLD_MAP_KEY:RefreshKey()
	WORLD_MAP_KEY:RefreshKey()
end

function HarvensCustomMapPins:InitLegend()
	local function reset(control)
		control:SetColor(1, 1, 1, 1)
	end
	local function sort(a, b)
		return a[1] < b[1]
	end
	local function hook(orginal, refresh)
		local orgRefreshKey = orginal.RefreshKey
		function orginal.RefreshKey(legend, ...)
			local dirty = legend.fragment:IsShowing() and legend.dirty
			orgRefreshKey(legend, ...)
			if dirty then
				refresh(legend, ...)
			end
		end
		local orgReset = orginal.symbolPool.customResetBehavior
		orginal.symbolPool:SetCustomResetBehavior(
			orgReset and function(...)
					reset(...)
					return orgReset(...)
				end or reset
		)
	end
	local function getSymbols()
		local symbolInfo = {}
		for name, predefined in pairs(self.sv.predefined) do
			symbolInfo[#symbolInfo + 1] = {name, self.UsedIconIndex[predefined.icon], "", predefined.color}
		end
		table.sort(symbolInfo, sort)
		return symbolInfo
	end
	hook(
		WORLD_MAP_KEY,
		function(legend)
			if #legend.symbols == 0 then
				return
			end

			local symbolInfo = getSymbols()

			local params = legend.symbolParams
			local lastLeftMostSymbol = legend.symbols[#legend.symbols]
			lastLeftMostSymbol = lastLeftMostSymbol and lastLeftMostSymbol[1]

			local header = legend.headerPool:AcquireObject()
			header:SetText(GetString("SI_MAPFILTER", self.pinTypeId)) -- "Custom Map Pins"
			if lastLeftMostSymbol then
				header:SetAnchor(TOPLEFT, lastLeftMostSymbol, BOTTOMLEFT, -params.SYMBOL_SECTION_OFFSET_X + params.HEADER_SECTION_OFFSET_X, params.BETWEEN_SECTION_PADDING_Y)
			else
				header:SetAnchor(TOPLEFT, nil, TOPLEFT, params.HEADER_SECTION_OFFSET_X)
			end

			local symbolList
			local symbols = legend.symbols

			for symbolIndex = 1, #symbolInfo do
				local symbol = legend.symbolPool:AcquireObject()
				symbol:SetDimensions(params.SYMBOL_SIZE, params.SYMBOL_SIZE)
				local name, icon, tooltip, color = unpack(symbolInfo[symbolIndex])
				symbol:SetTexture(icon)
				symbol:SetColor(self:GetColor(color):UnpackRGB())
				symbol.name = name
				symbol.tooltip = tooltip

				local symbolRow = zo_floor((symbolIndex - 1) / params.NUM_SYMBOLS_PER_ROW) + 1
				local symbolCol = (symbolIndex - 1) % params.NUM_SYMBOLS_PER_ROW + 1

				if symbolCol == 1 then
					lastLeftMostSymbol = symbol
					symbolList = {}
					symbols[#symbols + 1] = symbolList
				end

				local offsetX = params.SYMBOL_SECTION_OFFSET_X + (params.SYMBOL_SIZE + params.SYMBOL_PADDING) * (symbolCol - 1)
				local offsetY = params.SYMBOL_SECTION_OFFSET_Y + (params.SYMBOL_SIZE + params.SYMBOL_PADDING) * (symbolRow - 1)
				symbol:SetAnchor(TOPLEFT, header, BOTTOMLEFT, offsetX - params.HEADER_SECTION_OFFSET_X, offsetY)

				symbolList[#symbolList + 1] = symbol
			end
		end
	)
	hook(
		GAMEPAD_WORLD_MAP_KEY,
		function(legend)
		end
	)
	self:UpdateLegend()
end

function HarvensCustomMapPins:SetupOptions()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")
	local settings = LibHarvensAddonSettings:AddAddon("Harven's Custom Map Pins")
	settings.version = "3.2.4"

	local pinSize = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Pin Size",
		min = 10,
		max = 100,
		step = 1,
		format = "%d",
		getFunction = function()
			return self.sv.pinSize
		end,
		setFunction = function(value)
			self.sv.pinSize = value
			ZO_MapPin.PIN_DATA[self.pinTypeId].size = value
		end
	}

	local pinLevel = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Pin Draw Level",
		min = 2,
		max = 200,
		step = 10,
		format = "%d",
		tooltip = "The greater the number then more top level a pin would be.",
		getFunction = function()
			return self.sv.pinLevel
		end,
		setFunction = function(value)
			self.sv.pinLevel = value
			ZO_MapPin.PIN_DATA[self.pinTypeId].level = value
		end
	}

	settings:AddSettings({pinSize, pinLevel})

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Spread Pin Rendering",
		tooltip = "Spread pin rendering over time to reduce CPU load per frame.",
		getFunction = function()
			return self.sv.alternateRenderer
		end,
		setFunction = function(value)
			self.sv.alternateRenderer = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Allow pin sub-filter" .. zo_iconFormat("esoui/art/miscellaneous/eso_icon_warning.dds", 28, 28),
		tooltip = "Allow to show/hide predefines (map filter tab). Reloads UI!",
		getFunction = function()
			return self.sv.allowSubFilter
		end,
		setFunction = function(value)
			self.sv.allowSubFilter = value
			SLASH_COMMANDS["/reloadui"]()
		end
	}
end

local function migrate(self, oldIconToNewIndex)
	for name, predefined in pairs(self.sv.predefined) do
		predefined.icon = oldIconToNewIndex[predefined.icon] or 1
		if type(predefined.color) == "table" then
			predefined.color = ZO_ColorDef.ToARGBHexadecimal(unpack(predefined.color))
		end
	end
	local function checkPin(pin)
		pin.icon = oldIconToNewIndex[pin.icon] or 1
		if type(pin.color) == "table" then
			local hex = ZO_ColorDef.ToARGBHexadecimal(unpack(pin.color))
			local color = self.hexToColorDef[hex]
			if not color then
				color = ZO_ColorDef:New(unpack(pin.color))
				self.hexToColorDef[hex] = color
			end
			pin.color = hex
		end
		pin.map = nil
	end
	local function checkFloor(floor)
		for key, pin in pairs(floor) do
			if key < 0 then
				floor[key] = nil
			else
				checkPin(pin)
			end
		end
	end
	for tile, floors in pairs(self.customPins) do
		if not type(floors) == "table" then
			self.customPins[tile] = nil
		elseif floors.icon then
			-- very old data. Will be migrated upon opening the right map
		else
			for level, floor in pairs(floors) do
				checkFloor(floor)
				if not next(floor) then
					floors[level] = nil
				end
			end
			if next(floors) == nil then
				self.customPins[tile] = nil
			end
		end
	end
end

local function assignPredefined(self)
	local icons = {}

	for name, predefined in pairs(self.sv.predefined) do
		local list = icons[predefined.icon] or {}
		icons[predefined.icon] = list
		list[predefined.color] = name
	end
	local function checkPin(pin)
		if icons[pin.icon] then
			local predefined = icons[pin.icon][pin.color]
			if predefined then
				pin.predefined = predefined
				pin.color = nil
				pin.icon = nil
			end
		end
	end
	for tile, floors in pairs(self.customPins) do
		if floors.icon then
			-- very old data. Will be migrated upon opening the right map
		else
			for level, floor in pairs(floors) do
				for key, pin in pairs(floor) do
					checkPin(pin)
				end
			end
		end
	end
end

function HarvensCustomMapPins:Initialize()
	local defaults = {
		predefined = {},
		showPredefined = {},
		point = CENTER,
		x = 0,
		y = 0,
		relPoint = CENTER,
		showAdvanced = false,
		pinSize = 40,
		pinLevel = 30,
		legendPos = {
			point = TOPRIGHT,
			x = -38,
			y = 20,
			relPoint = TOPLEFT
		},
		alternatePinRenderer = false,
		showPins = true,
		pinVersion = 1,
		allowSubFilter = true
	}
	self.sv = ZO_SavedVars:NewAccountWide("HarvensCustomMapPins_SavedVariables", 1, nil, defaults)
	self.pinTypeId = 0
	-- this is important variable it will be set by ZO_WorldMap_AddCustomPin
	self.pinTypeString = "HarvensCustomMapPinsType"
	self.requests = {}
	self.hexToColorDef = {}
	self.pinManager = ZO_WorldMap_GetPinManager()

	if self.sv.pins and next(self.sv.pins) == nil then
		self.sv_old = ZO_SavedVars:New("HarvensCustomMapPins_SavedVariables", 1, nil, defaults)
		self:ImportPinsToAccountWide()
	end
	self.sv.pins_backup_1 = nil
	if self.sv.pins then
		HarvensCustomMapPins_Data = self.sv.pins
	end
	self.customPins = HarvensCustomMapPins_Data or {}
	HarvensCustomMapPins_Data = self.customPins
	self.sv.pins = nil
	self.sv.pinVersion = self.sv.pinVersion or 1.1

	local oldIconIndex = HarvensCustomMapPins_SavedVariables.UsedIconIndex or HarvensCustomMapPinsIconList

	local newImages = HarvensCustomMapPinsIconList
	local newIconToIndex = {}
	for i = 1, #newImages do
		newIconToIndex[newImages[i]] = i
	end

	local indexChanged = false
	local oldIconToNewIndex = {}
	for i = 1, #oldIconIndex do
		oldIconToNewIndex[i] = newIconToIndex[oldIconIndex[i]] or 1
		indexChanged = indexChanged or oldIconToNewIndex[i] ~= i
	end

	if indexChanged or self.sv.pinVersion < 1.2 then
		migrate(self, oldIconToNewIndex)
		if self.sv.pinVersion < 1.2 then
			assignPredefined(self)
		end
	end
	self.sv.pinVersion = 1.2

	HarvensCustomMapPins_SavedVariables.UsedIconIndex = newImages
	self.UsedIconIndex = newImages

	HarvensCustomMapPinsEditDialog_Initialize(HarvensCustomMapPinsEditDialog, self.sv)

	self:InitLegend()

	-- this creator creates a tooltip
	local creator = {
		creator = function(pin)
			if not pin or pin.__index ~= ZO_MapPin then
				return
			end
			local _, pTag = pin:GetPinTypeAndTag()
			pin = self:GetPin(pTag)
			if pin and pin.description or pin.predefined then
				InformationTooltip:AddLine(pin.description and #pin.description > 0 and pin.description or pin.predefined)
			end
		end,
		tooltip = 1
		-- 1 = TOOLTIP_MODE.INFORMATION
	}

	local function newHexColor(hex)
		local color = ZO_ColorDef:New(hex)
		self.hexToColorDef[hex] = color
		return color
	end

	function self:GetColor(hex)
		if type(hex) == "table" then
			hex = ZO_ColorDef.ToARGBHexadecimal(unpack(hex))
		end
		return self.hexToColorDef[hex] or newHexColor(hex)
	end

	local layout = {
		level = self.sv.pinLevel,
		size = self.sv.pinSize,
		insetX = 8,
		insetY = 8,
		texture = function(pin)
			if not pin or not pin.GetPinTypeAndTag then
				return
			end
			local _, pTag = pin:GetPinTypeAndTag()
			local data = self:GetPin(pTag)
			if data and data.predefined then
				local icon = self.sv.predefined[data.predefined]
				icon = icon and icon.icon
				if icon then
					return HarvensCustomMapPinsIconList[icon]
				end
			end
			return data and data.icon and HarvensCustomMapPinsIconList[data.icon] or "HarvensCustomMapPins/pinflag.dds"
		end,
		tint = function(pin)
			if not pin or not pin.GetPinTypeAndTag then
				return
			end
			local _, pTag = pin:GetPinTypeAndTag()
			local data = self:GetPin(pTag)
			if data and data.predefined then
				local color = self.sv.predefined[data.predefined]
				color = color and color.color
				if color then
					return self:GetColor(color)
				end
			end

			local hex = data and data.color or "FFFFFF"
			return self:GetColor(hex)
		end
	}

	-- define our custom pins
	ZO_WorldMap_AddCustomPin(self.pinTypeString, LayoutPins, nil, layout, creator)
	self.pinTypeId = _G[self.pinTypeString]

	ZO_CreateStringId("SI_MAPFILTER" .. self.pinTypeId, "Harven's Custom Map Pin")

	ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, self.sv.showPins)
	ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_LEFT][self.pinTypeId] = {
		{
			name = function(pin)
				if not pin or not pin.__index or pin.__index ~= ZO_MapPin then
					return
				end
				local _, pTag = pin:GetPinTypeAndTag()
				local data = self:GetPin(pTag)
				return tostring(data and data.description)
			end,
			show = function(...)
				return true
			end,
			callback = ShowPinMenu,
			duplicates = function(...)
			end
		}
	}
	ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_RIGHT][self.pinTypeId] = ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_LEFT][self.pinTypeId]

	SLASH_COMMANDS["/custompin"] = HarvensCustomMapPins_CustomPinCommand
	SLASH_COMMANDS["/importpins"] = function()
		HarvensCustomMapPins:ImportFromImportSection()
	end

	HarvensCustomMapPins:InjectKeystrip()

	local function reformatter(linkStyle, linkType, data, displayText)
		return ZO_LinkHandler_CreateLink(displayText:match(".(.*)."), nil, linkType, linkStyle, data)
	end
	LibChatMessage:RegisterCustomChatLink(MAPPIN_LINK_TYPE, reformatter)

	LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, self.OnLinkClicked, self)
	LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.OnLinkClicked, self)

	self:SetupOptions()
	self:SetupMapFilter()
end

do
	local pinIdToPredefined = {}
	local function AddPinFilterCheckBox(self, mapPinGroup, refreshFunction, header)
		if not self.checkBoxPool then
			self.checkBoxPool = ZO_ControlPool:New("ZO_CheckButton", self.control, "HCPCheckBox")
		end

		local checkBox = self.checkBoxPool:AcquireObject()
		local predefined = pinIdToPredefined[mapPinGroup]
		predefined = predefined and HarvensCustomMapPins.sv.predefined[predefined]
		if predefined then
			local color = HarvensCustomMapPins:GetColor(predefined.color)
			local icon = HarvensCustomMapPinsIconList[predefined.icon] or HarvensCustomMapPinsIconList[1]

			ZO_CheckButton_SetLabelText(checkBox, string.format(" |u12:0::|u|c%s|t%d:%d:%s:inheritColor|t|r%s", color:ToHex(), 28, 28, icon, header))
		else
			ZO_CheckButton_SetLabelText(checkBox, " |u12:0::|u" .. header)
		end
		ZO_CheckButton_SetToggleFunction(
			checkBox,
			function(button, checked)
				self:SetPinFilter(mapPinGroup, checked)
				self:RefreshDependentComboBox(checkBox)
				if refreshFunction then
					refreshFunction(header)
				end
			end
		)
		checkBox.mapPinGroup = mapPinGroup
		checkBox.refreshFunction = refreshFunction

		self.pinFilterCheckBoxes[#self.pinFilterCheckBoxes + 1] = checkBox
		self:AnchorControl(checkBox)
	end
	function HarvensCustomMapPins:SetupMapFilter()
		local pinTypeId = self.pinTypeId
		local function GetPinId(name)
			return string.format("%i_%s", pinTypeId, name)
		end
		local names = {}
		for name in pairs(self.sv.predefined) do
			names[#names + 1] = name
			local id = GetPinId(name)
			pinIdToPredefined[id] = name
		end
		table.sort(names)
		local id = GetPinId("")
		pinIdToPredefined[id] = ""

		local orgGetPinFilter = ZO_WorldMapFilterPanel_Shared.GetPinFilter
		function ZO_WorldMapFilterPanel_Shared.GetPinFilter(...)
			local current, mapPinGroup = ...
			if mapPinGroup == self.pinTypeId then
				return self.sv.showPins
			elseif pinIdToPredefined[mapPinGroup] then
				return self.sv.showPredefined[pinIdToPredefined[mapPinGroup]] ~= false
			else
				return orgGetPinFilter(...)
			end
		end
		local orgSetPinFilter = ZO_WorldMapFilterPanel_Shared.SetPinFilter
		function ZO_WorldMapFilterPanel_Shared.SetPinFilter(...)
			local current, mapPinGroup, shown = ...
			if mapPinGroup == self.pinTypeId then
				self.sv.showPins = shown
			elseif pinIdToPredefined[mapPinGroup] then
				self.sv.showPredefined[pinIdToPredefined[mapPinGroup]] = shown
			else
				return orgSetPinFilter(...)
			end
		end
		local function FilterCallback(name)
			ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, self.sv.showPins)
			self:RefreshPins()
		end
		local function FilterCallbackSub(name)
			self:RefreshPins()
		end
		local function addPredefined(panel, name)
			local id = GetPinId(name)
			AddPinFilterCheckBox(panel, id, FilterCallback, name)
			panel:SetPinFilter(id, self.sv.showPredefined[name] ~= false)
		end
		local function AddCheckBox(panel)
			panel:AddPinFilterCheckBox(pinTypeId, FilterCallback)
			panel:SetPinFilter(pinTypeId, self.sv.showPins)
			if self.sv.allowSubFilter then
				local id = GetPinId("")
				panel:SetPinFilter(id, self.sv.showPredefined[""] ~= false)
				for _, name in ipairs(names) do
					addPredefined(panel, name)
				end
				AddPinFilterCheckBox(panel, id, FilterCallback, GetString(SI_FURNITURETHEMETYPE1))
			end
		end

		local self = WORLD_MAP_FILTERS
		AddCheckBox(self.pvePanel, "pve")
		AddCheckBox(self.pvpPanel, "pvp")
		AddCheckBox(self.imperialPvPPanel, "imperialPvP")
		AddCheckBox(self.battlegroundPanel, "battleground")
		local self = GAMEPAD_WORLD_MAP_FILTERS
		AddCheckBox(self.pvePanel, "pve")
		AddCheckBox(self.pvpPanel, "pvp")
		AddCheckBox(self.imperialPvPPanel, "imperialPvP")
		AddCheckBox(self.battlegroundPanel, "battleground")
	end
end

local function HarvensCustomMapPins_Initialize(eventCode, addOnName)
	if addOnName ~= "HarvensCustomMapPins" then
		return
	end

	EVENT_MANAGER:UnregisterForEvent("HarvensCustomMapPinsLoadHandler", EVENT_ADD_ON_LOADED)

	_G["HarvensCustomMapPins"] = HarvensCustomMapPins:New()
end

EVENT_MANAGER:RegisterForEvent("HarvensCustomMapPinsLoadHandler", EVENT_ADD_ON_LOADED, HarvensCustomMapPins_Initialize)
