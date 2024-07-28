local addon = {
	name = "VotansTamrielMap",
	pinType = "VotansTamrielMapPinType",
	locations = {
		-- [1] =
		{
			-- "Tamriel",
			alliance = 999,
			cosmic = true
		},
		-- [2] =
		{
			-- "Glenumbra",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 2,
			poi = 62
		},
		-- [3] =
		{
			-- "Kluftspitze",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 4,
			poi = 55
		},
		-- [4] =
		{
			-- "Sturmhafen",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 3,
			poi = 56
		},
		-- [5] =
		{
			-- "Alik'r-Wüste",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 5,
			poi = 43
		},
		-- [6] =
		{
			-- "Bangkorai",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 6,
			poi = 33
		},
		-- [7] =
		{
			-- "Grahtwald",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 3,
			poi = 214
		},
		-- [8] =
		{
			-- "Malabal Tor",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 5,
			poi = 102
		},
		-- [9] =
		{
			-- "Schattenfenn",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 4,
			poi = 48
		},
		-- [10] =
		{
			-- "Deshaan",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 3,
			poi = 28
		},
		-- [11] =
		{
			-- "Steinfälle",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 2,
			poi = 67
		},
		-- [12] =
		{
			-- "Rift",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 6,
			poi = 109
		},
		-- [13] =
		{
			-- "Ostmarsch",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 5,
			poi = 87
		},
		-- [14] =
		{
			-- "Cyrodiil",
			alliance = 100
		},
		-- [15] =
		{
			-- "Auridon",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 2,
			poi = 177
		},
		-- [16] =
		{
			-- "Grünschatten",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 4,
			poi = 143
		},
		-- [17] =
		{
			-- "Schnittermark",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 6,
			poi = 162
		},
		-- [18] =
		{
			-- "Bal Foyen",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 1,
			poi = 173,
			offsetX = -0.05,
			offsetY = -0.1
		},
		-- [19] =
		{
			-- "Stros M'Kai",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 1,
			poi = 138,
			offsetX = 0.1,
			offsetY = 0
		},
		-- [20] =
		{
			-- "Betnikh",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			zoneOrder = 1,
			poi = 181
		},
		-- [21] =
		{
			-- "Khenarthis Rast",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			zoneOrder = 1,
			poi = 142
		},
		-- [22] =
		{
			-- "Ödfels",
			alliance = ALLIANCE_EBONHEART_PACT,
			zoneOrder = 1,
			poi = 172,
			offsetX = 0,
			offsetY = 0.2
		},
		-- [23] =
		{
			-- "Kalthafen",
			alliance = 100,
			zoneLevel = 7,
			poi = 131,
			cosmic = true
		},
		-- [24] =
		{
			-- "Aurbis",
			alliance = 999
		},
		-- [25] =
		{
			-- "Kargstein",
			alliance = 100,
			poi = 220
		},
		-- [26] =
		{
			-- "Kaiserstadt",
			alliance = 100
		},
		-- [27] =
		{
			-- "Wrothgar",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			poi = 244
		},
		-- [28] =
		{
			-- "Abah's Landing",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			poi = 255,
			offsetX = 0.1,
			offsetY = 0
		},
		-- [29] =
		{
			-- "Gold Coast",
			alliance = 100,
			poi = 251
		},
		-- [30] =
		{
			-- "Vvardenfell",
			alliance = ALLIANCE_EBONHEART_PACT,
			poi = 284,
			offsetX = 0.005,
			offsetY = 0.005
		},
		-- [31] =
		{
			-- "Clockwork City",
			alliance = ALLIANCE_EBONHEART_PACT,
			poi = 337,
			cosmic = true
		},
		-- [32] =
		{
			-- "Summerset",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			poi = 355
		},
		-- [33] =
		{
			-- "Artaeum",
			alliance = 100,
			poi = 360,
			cosmic = true
		},
		-- [34] =
		{
			-- "Murkmire",
			alliance = ALLIANCE_EBONHEART_PACT,
			poi = 374
		},
		-- [35] =
		{
			-- "Norg-Tzel",
			alliance = ALLIANCE_EBONHEART_PACT,
			hidden = true
		},
		-- [36] =
		{
			-- "Northern Elswyer",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			poi = 382
		},
		-- [37] =
		{
			-- "Southern Elswyer",
			alliance = ALLIANCE_ALDMERI_DOMINION,
			poi = 402
		},
		-- [38] =
		{
			-- "Western Skyrim",
			alliance = ALLIANCE_EBONHEART_PACT,
			poi = 426,
			offsetX = 0.05,
			offsetY = -0.05
		},
		-- [39] =
		{
			-- "Blackreach: Greymoore",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [40] =
		{
			-- "Blackreach",
			alliance = 999
		},
		-- [41] =
		{
			-- "Blackreach: Arkthzand",
			alliance = ALLIANCE_EBONHEART_PACT
		},
		-- [42] =
		{
			-- "Reik",
			alliance = ALLIANCE_EBONHEART_PACT,
			poi = 449
		},
		-- [43] =
		{
			-- "Blackwood",
			alliance = 999,
			poi = 467
		},
		-- [44] =
		{
			-- "Fargrave",
			alliance = 999,
			cosmic = true
		},
		-- [45] =
		{
			-- "Deathlands",
			alliance = 999,
			cosmic = true
		},
		-- [46] =
		{
			-- "High Isle",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			poi = 513
		},
		-- [47] =
		{
			-- "Fargrave City"
			alliance = 999,
			hidden = true
		},
		-- [48] =
		{
			-- "Galen",
			alliance = ALLIANCE_DAGGERFALL_COVENANT,
			poi = 529
		},
		-- [49] =
		{
			-- "Telvani",
			alliance = ALLIANCE_EBONHEART_PACT,
			poi = 536
		},
		-- [50] =
		{
			-- "Apocrypha",
			alliance = 999,
			cosmic = true
		},
		-- [51] =
		{
			-- "Westauen",
			alliance = 999,
			poi = 558,
			cosmic = false
		},
		-- [52] =
		{
			-- "Augvea",
			alliance = 999,
			poi = 215,
			cosmic = true,
			blobX = 0.1367,
			blobY = 0.5579
		}
	},
	color = {
		[ALLIANCE_DAGGERFALL_COVENANT] = ZO_ColorDef:New(-1, 0.25, 1, 0.2),
		[ALLIANCE_ALDMERI_DOMINION] = ZO_ColorDef:New(1, 1, -1, 0.15),
		[ALLIANCE_EBONHEART_PACT] = ZO_ColorDef:New(1, -1, -1, 0.15)
	},
	defaultColor = ZO_ColorDef:New(0, 0, 0, 0.25),
	transparentColor = ZO_ColorDef:New(0, 0, 0, 0),
	baseGameColor = ZO_ColorDef:New(0.5, 1, 0.5, 0.25),
	dlcGameColor = ZO_ColorDef:New(0.25, 0.25, 0.75, 0.35)
}

local em = GetEventManager()
local am = GetAnimationManager()

local lookup = {
	fonts = {},
	fontSizes = {},
	colors = {}
}

function addon:ApplyOpacity()
	local opacity = self.account.color ~= "None" and (self.account.opacity / 250) or 0
	self.color[ALLIANCE_DAGGERFALL_COVENANT]:SetAlpha(opacity * 1.25)
	self.color[ALLIANCE_ALDMERI_DOMINION]:SetAlpha(opacity)
	self.color[ALLIANCE_EBONHEART_PACT]:SetAlpha(opacity)
	self.defaultColor:SetAlpha(opacity)
	self.transparentColor:SetAlpha(opacity)
	self.baseGameColor:SetAlpha(opacity)
	self.dlcGameColor:SetAlpha(opacity * 1.2)
end

function addon:ApplyColors()
	if self.account.color == "BaseGame" then
		self.GetColor = self.GetBaseGameColor
		self.GetDefaultColor = self.GetBaseGameColor
	elseif self.account.color == "None" then
		self.GetColor = self.GetNoColor
		self.GetDefaultColor = self.GetNoColor
	else
		self.GetColor = self.GetAllianceColor
		self.GetDefaultColor = self.AllianceDefaultColor
	end
end

function addon:InitSettings()
	local accountDefaults = {
		hidePins = true,
		titleFont = "ANTIQUE_FONT",
		color = "Alliance",
		opacity = 50,
		showCitiesNames = true
	}
	self.account = ZO_SavedVars:NewAccountWide("VotansTamrielMap_Data", 1, nil, accountDefaults)
	local LibHarvensAddonSettings = LibHarvensAddonSettings

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Tamriel Map")
	if not settings then
		return
	end
	addon.settingsControls = settings
	settings.allowDefaults = true
	settings.version = "1.2.2"
	settings.website = "https://www.esoui.com/downloads/info2672-VotansTamrielMap.html"

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANS_TAMRIEL_MAP_HIDE_TRAVEL_PINS),
		tooltip = "",
		default = accountDefaults.hidePins,
		getFunction = function()
			return self.account.hidePins
		end,
		setFunction = function(value)
			self.account.hidePins = value
		end
	}

	local function createFont()
		local size, sizeCity = unpack(lookup.fontSizes[self.account.titleFont])
		self.titleFont = string.format("$(%s)|%i|soft-shadow-thick", self.account.titleFont, size)
		self.cityFont = string.format("$(%s)|%i|soft-shadow-thick", self.account.titleFont, sizeCity)
	end
	lookup.nameToFont = {}
	for _, item in pairs(lookup.fonts) do
		lookup.nameToFont[item.data] = item
	end
	if not lookup.nameToFont[self.account.titleFont] then
		self.account.titleFont = accountDefaults.titleFont
	end
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = GetString(SI_VOTANS_TAMRIEL_MAP_FONT),
		items = lookup.fonts,
		default = lookup.nameToFont[accountDefaults.titleFont].name,
		getFunction = function()
			return lookup.nameToFont[self.account.titleFont].name
		end,
		setFunction = function(combobox, name, item)
			self.account.titleFont = item.data
			createFont()
		end
	}
	createFont()

	lookup.nameToColor = {}
	for _, item in pairs(lookup.colors) do
		lookup.nameToColor[item.data] = item
	end
	if not lookup.nameToColor[self.account.color] then
		self.account.color = accountDefaults.color
	end
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = GetString(SI_GUILD_HERALDRY_COLOR),
		items = lookup.colors,
		default = lookup.nameToColor[accountDefaults.color].name,
		getFunction = function()
			return lookup.nameToColor[self.account.color].name
		end,
		setFunction = function(combobox, name, item)
			self.account.color = item.data
			self:ApplyColors()
			self:ApplyOpacity()
		end
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = GetString(SI_COLOR_PICKER_ALPHA),
		tooltip = "",
		min = 10,
		max = 100,
		step = 1,
		format = "%f",
		unit = "",
		default = 50,
		getFunction = function()
			return self.account.opacity
		end,
		setFunction = function(value)
			self.account.opacity = value
			self:ApplyOpacity()
		end
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANS_TAMRIEL_MAP_SHOW_CITIES_NAME),
		tooltip = "",
		default = accountDefaults.showCitiesNames,
		getFunction = function()
			return self.account.showCitiesNames
		end,
		setFunction = function(value)
			self.account.showCitiesNames = value
		end
	}
end

local MapBlobManager = ZO_ObjectPool:Subclass()
addon.MapBlobManager = MapBlobManager

local function MapOverlayControlFactory(pool, controlNamePrefix, templateName, parent)
	local overlayControl = ZO_ObjectPool_CreateNamedControl(controlNamePrefix, templateName, pool, parent)
	overlayControl:SetAlpha(0) -- Because it's not shown yet and we want to fade in using current values
	ZO_AlphaAnimation:New(overlayControl) -- This control will always use this utility object to animate itself, this links the control to the anim, so we don't need the return.
	overlayControl.label = overlayControl:GetNamedChild("Location")
	overlayControl.city = overlayControl:GetNamedChild("City")
	overlayControl:SetInsets(4, 1, 1, 1, 1)
	overlayControl:SetInsets(3, -1, -1, -1, -1)
	overlayControl:SetInsets(1, 2, 2, 2, 2)
	return overlayControl
end

function MapBlobManager:New(blobContainer)
	local blobFactory = function(pool)
		return MapOverlayControlFactory(pool, "VotansTamrielMapBlob", "VotansTamrielBlobControl", blobContainer)
	end
	return ZO_ObjectPool.New(self, blobFactory, ZO_ObjectPool_DefaultResetControl)
end

local function NormalizedBlobDataToUI(blobWidth, blobHeight, blobXOffset, blobYOffset)
	local w, h = ZO_WorldMapContainer:GetDimensions()
	return blobWidth * w, blobHeight * h, blobXOffset * w, blobYOffset * h
end

local g_mapPanAndZoom = ZO_WorldMap_GetPanAndZoom()

local function ShowMapTexture(textureControl, textureName, width, height, offsetX, offsetY)
	textureControl:SetTexture(textureName)
	textureControl:SetDimensions(width, height)
	textureControl:SetSimpleAnchorParent(offsetX, offsetY)
	textureControl:SetAlpha(1)
	textureControl:SetHidden(false)
	--textureControl:SetBlendMode(TEX_BLEND_MODE_ALPHA)
end

local textureChanged
function MapBlobManager:Update(normalizedMouseX, normalizedMouseY)
	local locationName = ""
	local textureFile = ""
	local textureUIWidth, textureUIHeight, textureXOffset, textureYOffset

	local locXN, locYN, widthN, heightN
	locationName, textureFile, widthN, heightN, locXN, locYN = GetMapMouseoverInfo(normalizedMouseX, normalizedMouseY)
	textureUIWidth, textureUIHeight, textureXOffset, textureYOffset = NormalizedBlobDataToUI(widthN, heightN, locXN, locYN)

	if self.m_zoom ~= g_mapPanAndZoom:GetCurrentCurvedZoom() then
		self.m_zoom = g_mapPanAndZoom:GetCurrentCurvedZoom()
		textureChanged = true
	end

	if textureChanged then
		if textureFile ~= "" then
			local blob = self:AcquireObject(textureFile)
			if blob then
				ShowMapTexture(blob, textureFile, textureUIWidth, textureUIHeight, textureXOffset, textureYOffset)
				blob.label:SetFont(addon.titleFont)
				blob.label:SetText(ZO_CachedStrFormat(SI_WORLD_MAP_LOCATION_NAME, locationName))
				return blob
			end
		end
	end
end

function addon:GetAllianceColor(location)
	return self.color[location.alliance] or self.defaultColor
end
function addon:AllianceDefaultColor()
	return self.defaultColor
end

function addon:GetNoColor(location)
	return self.transparentColor
end

function addon:GetBaseGameColor(location)
	return location and (location.index <= 27 or location.index == 30) and self.baseGameColor or self.dlcGameColor
end

function addon:RenderMap(isTamriel)
	local positions = self.positions
	local bm, gps = self.blobManager, LibGPS3
	for i, pos in pairs(positions) do
		local x, y = pos:GetOffset()
		local w, h = pos:GetScale()
		x, y = x + w / 2, y + h / 2
		x, y = gps:GlobalToLocal(x, y)
		if x > 0 and x < 1 and y > 0 and y < 1 then
			local location = self.locations[i]
			if location and (not location.cosmic) == isTamriel then
				local blob = bm:Update(location.blobX or x, location.blobY or y)
				if location and blob then
					local color = self:GetColor(location)
					local r, g, b, a = color:UnpackRGBA()
					blob:SetColor(1, 1, 1, 1, a)
					blob:SetColor(2, r, g, b, a)
					blob:SetColor(3, r, g, b, a)
					blob:SetColor(4, r, g, b, a)

					if location.hidden then
						blob.label:SetText("")
					end
					blob.city:SetFont(self.cityFont)
					blob.city:SetText(ZO_CachedStrFormat("<<!AC:1>>", location.locationName))

					if location.poi and self.account.showCitiesNames then
						local locationName, locXN, locYN = select(2, GetFastTravelNodeInfo(location.poi))
						x, y, locXN, locYN = NormalizedBlobDataToUI(x, y, locXN, locYN)
						local w, h1 = blob.label:GetDimensions()
						local h1, h2 = h1 * 2 / 3, h1 / 3
						if ((y - h1) < locYN and (y + h2) > locYN) and ((x - 64) < locXN and (x + 64) > locXN) then
							blob.city:SetAnchor(TOP, blob.label, BOTTOM, 0, -3)
						else
							blob.city:SetAnchor(TOP, ZO_WorldMapContainer, TOPLEFT, locXN, locYN, 0, -6)
						end
					else
						blob.city:ClearAnchors()
					end

					blob.city:SetHidden(not location.poi or not self.account.showCitiesNames)
				elseif blob then
					local color = self:GetDefaultColor(location)

					local r, g, b, a = color:UnpackRGBA()
					blob:SetColor(1, 1, 1, 1, a)
					blob:SetColor(2, r, g, b, a)
					blob:SetColor(3, r, g, b, a)
					blob:SetColor(4, r, g, b, a)
					blob.city:SetHidden(true)
				end
			end
		end
	end
end

function addon:Hide()
	self.blobManager:ReleaseAllObjects()
end

function addon:HookPOIPins()
	local lessVisible = ZO_ColorDef:New(1, 1, 1, 0.5)
	local GetCurrentMapIndex = GetCurrentMapIndex
	local function HookPinSize(data)
		local orgMetaTable = getmetatable(data)
		local orgSize = data.size or 40
		local orgTint = data.tint or ZO_DEFAULT_COLOR
		data.size, data.tint = nil, nil

		local newMetaTable = {}
		setmetatable(newMetaTable, orgMetaTable)
		local alter = {}
		alter.size = function()
			return GetCurrentMapIndex() == 1 and 1 or orgSize
		end
		alter.tint = function()
			return GetCurrentMapIndex() == 1 and lessVisible or orgTint
		end

		newMetaTable.__index = function(data, key)
			return alter[key] and alter[key](data) or newMetaTable[key]
		end
		newMetaTable.__newindex = function(data, key, value)
			if key == "size" then
				orgSize = value
				return
			elseif key == "tint" then
				orgTint = value
				return
			end
			return rawset(data, key, value)
		end
		setmetatable(data, newMetaTable)
	end
	HookPinSize(ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE])
	HookPinSize(ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC])
end

function addon:HookTravelInfo()
	local orgGetFastTravelNodeInfo = GetFastTravelNodeInfo
	function GetFastTravelNodeInfo(...)
		if addon.account.hidePins then
			local result = {orgGetFastTravelNodeInfo(...)}
			result[8] = result[8] and GetCurrentMapIndex() ~= 1
			return unpack(result)
		else
			return orgGetFastTravelNodeInfo(...)
		end
	end
end
function addon:Initialize()
	self:InitSettings()
	local gps = LibGPS3

	local positions = {}
	gps:PushCurrentMap()
	for i = 1, GetNumMaps() do
		SetMapToMapListIndex(i)
		local measurement = gps:GetCurrentMapMeasurement()
		if measurement then
			positions[i] = measurement
			local location = self.locations[i]
			if location and location.poi then
				local normalizedMouseX, normalizedMouseY = select(3, GetFastTravelNodeInfo(location.poi))
				local locationName = GetMapMouseoverInfo(normalizedMouseX, normalizedMouseY)
				if locationName ~= "" then
					location.locationName = locationName
				elseif location.offsetX then
					locationName = GetMapMouseoverInfo(normalizedMouseX + location.offsetX, normalizedMouseY + location.offsetY)
					if locationName ~= "" then
						location.locationName = locationName
					end
				end
			end
			if location then
				location.index = i
			end
		end
	end
	self.positions = positions

	gps:PopCurrentMap()

	self:ApplyOpacity()
	self:ApplyColors()

	--self:HookPOIPins()
	self:HookTravelInfo()

	local blobContainer = ZO_WorldMapContainer
	self.blobManager = MapBlobManager:New(blobContainer)

	self.layout = {
		level = 30,
		size = 32,
		insetX = 4,
		insetY = 4,
		texture = ""
		-- tint = function(pin)
		-- 	local _, tag = pin:GetPinTypeAndTag()
		-- 	if tag then
		-- 		return tag:GetColor()
		-- 	end
		-- end
	}

	local TAMRIEL_MAP_INDEX = GetMapIndexById(27)
	local AURBIS_MAP_INDEX = GetMapIndexById(439)

	local function LayoutPins(pinManager)
		self:Hide()
		local mapIndex = GetCurrentMapIndex()
		if mapIndex == TAMRIEL_MAP_INDEX or mapIndex == AURBIS_MAP_INDEX then
			textureChanged = true
			self:RenderMap(mapIndex == TAMRIEL_MAP_INDEX)
			textureChanged = false
		end
	end

	ZO_WorldMap_AddCustomPin(self.pinType, LayoutPins, LayoutPins, self.layout)
	self.pinTypeId = _G[self.pinType]
	ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, true)
end

function addon:AddFont(font, displayText, size, sizeCity)
	lookup.fonts[#lookup.fonts + 1] = {name = displayText, data = font}
	lookup.fontSizes[font] = {size or 18, sizeCity or 14}
end

addon:AddFont("", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_NONE))

addon:AddFont("MEDIUM_FONT", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_MEDIUM))
addon:AddFont("BOLD_FONT", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_BOLD))
addon:AddFont("CHAT_FONT", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_CHAT))

addon:AddFont("GAMEPAD_LIGHT_FONT", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_GAMEPAD_LIGHT), 22, 18)
addon:AddFont("GAMEPAD_MEDIUM_FONT", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_GAMEPAD_MEDIUM), 22, 18)
addon:AddFont("GAMEPAD_BOLD_FONT", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_GAMEPAD_BOLD), 22, 18)

addon:AddFont("ANTIQUE_FONT", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_ANTIQUE))
addon:AddFont("HANDWRITTEN_FONT", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_HANDWRITTEN), 16, 12)
addon:AddFont("STONE_TABLET_FONT", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_STONE_TABLET), 14, 10)

local function AddColor(color, displayText)
	lookup.colors[#lookup.colors + 1] = {name = displayText, data = color}
end

AddColor("Alliance", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_ALLIANCE))
AddColor("BaseGame", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_BASE_DLC))
AddColor("None", GetString(SI_VOTANS_TAMRIEL_MAP_FONT_NO_COLOR))

local function OnAddOnLoaded(event, addonName)
	em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	addon:Initialize()
end

em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, OnAddOnLoaded)

VOTANS_TAMRIEL_MAP = addon
