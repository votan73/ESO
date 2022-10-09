local addon = VOTANS_MINIMAP
local em = GetEventManager()
local async = LibAsync

local settingsControls

local function UpdateControls()
	if settingsControls.selected then
		settingsControls:UpdateControls()
	end
end

local pinScales, pinSizes

function addon:InitPinSizes()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Mini Map Pin Sizes")
	if not settings then return end
	settingsControls = settings
	settings.allowDefaults = true;

	self.account.pinSizes = self.account.pinSizes or { }
	pinSizes = self.account.pinSizes
	pinScales = { }
	self.pinScales = pinScales

	local othersScale = 1

	local orgCalculateScale = self.CalculateScale
	function self:CalculateScale(pinType)
		return orgCalculateScale(self) *(pinScales[pinType] or othersScale)
	end

	local function UpdatePin(pinType, pin)
		pin:UpdateSize()
	end
	local function UpdateDrawLevel(pinType)
		for _, pin in pairs(addon.pinManager:GetActiveObjects()) do
			if pinType == pin:GetPinType() then UpdatePin(pinType, pin) end
		end
	end

	local function UpdateDrawLevels(pins)
		for _, pin in pairs(addon.pinManager:GetActiveObjects()) do
			local pinType = pin:GetPinType()
			if pins[pinType] then UpdatePin(pinType, pin) end
		end
	end

	local function AddPin(pinType, caption, stringId)
		local pinData = ZO_MapPin.PIN_DATA[pinType]
		if not pinData then return end

		local task = async:Create("VotanPinSize" .. caption)
		local function updatePinSize()
			UpdateDrawLevel(pinType)
		end
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(stringId),
			min = 2,
			max = 200,
			step = 1,
			default = 100,
			unit = "%",
			getFunction = function() return pinSizes[caption] or 100 end,
			setFunction = function(value)
				pinSizes[caption] = value
				pinScales[pinType] = value * 0.01
				UpdateControls()
				task:Cancel():Call(updatePinSize)
			end,
		}
		pinScales[pinType] =(pinSizes[caption] or 100) * 0.01
	end

	local function AddPins(pins, caption, stringId)
		if not pins then return end
		local task = async:Create("VotanPinSize" .. caption)
		local function updatePinSize()
			UpdateDrawLevels(pins)
		end
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = stringId and GetString(stringId) or caption,
			min = 2,
			max = 200,
			step = 1,
			default = 100,
			unit = "%",
			getFunction = function() return pinSizes[caption] or 100 end,
			setFunction = function(value)
				pinSizes[caption] = value
				local scale = value * 0.01
				for pinType in pairs(pins) do
					pinScales[pinType] = scale
				end
				UpdateControls()
				task:Cancel():Call(updatePinSize)
			end,
		}
		local scale =(pinSizes[caption] or 100) * 0.01
		for pinType in pairs(pins) do
			pinScales[pinType] = scale
		end
	end
	local function AddCustomPin(pinType, caption)
		if not pinType then return end
		AddPin(pinType, caption, _G["SI_MAPFILTER" .. pinType])
	end

	AddPin(MAP_PIN_TYPE_PLAYER, "Player", SI_BATTLEGROUND_YOU)
	AddPin(MAP_PIN_TYPE_GROUP, "Group Member", SI_MAPFILTER9)
	AddPin(MAP_PIN_TYPE_GROUP_LEADER, "Group Leader", SI_GROUP_LEADER_TOOLTIP)
	AddPin(MAP_PIN_TYPE_LOCATION, "Locations", SI_MAP_INFO_MODE_LOCATIONS)

	AddPins(ZO_MapPin.FAST_TRAVEL_WAYSHRINE_PIN_TYPES, "Wayshrine", SI_MAPFILTER8)
	AddPins(ZO_MapPin.POI_PIN_TYPES, "Objectives", SI_MAPFILTER1)

	AddPins(ZO_MapPin.QUEST_PIN_TYPES, "Quest", SI_MAPFILTER4)
	AddPins(ZO_MapPin.MAP_PING_PIN_TYPES, "Waypoints", SI_TOOLTIP_UNIT_MAP_PLAYER_WAYPOINT)
	AddPins(ZO_MapPin.FAST_TRAVEL_KEEP_PIN_TYPES, "Keep Fast Travel", SI_VOTANSMINIMAP_PINSIZE_KEEP_FAST_TRAVEL)

	AddPins(ZO_MapPin.OBJECTIVE_PIN_TYPES, "AvA Objectives", SI_MAPFILTER2)
	AddPins(ZO_MapPin.KEEP_PIN_TYPES, "Keeps", SI_VOTANSMINIMAP_PINSIZE_KEEPS)
	AddPins(ZO_MapPin.IMPERIAL_CITY_GATE_TYPES, "Imperial City Gates", SI_MAPFILTER12)
	AddPins(ZO_MapPin.DISTRICT_PIN_TYPES, "Districts", SI_VOTANSMINIMAP_PINSIZE_DISTRICTS)
	AddPins(ZO_MapPin.KILL_LOCATION_PIN_TYPES, "Kill Locations", SI_MAPFILTER3)
	AddPins(ZO_MapPin.FORWARD_CAMP_PIN_TYPES, "Forward Camps", SI_TOOLTIP_FORWARD_CAMP)
	-- AddPins(ZO_MapPin.AVA_RESPAWN_PIN_TYPES, "Ava Respawn")
	-- AddPins(ZO_MapPin.AVA_RESTRICTED_LINK_PIN_TYPES, "AvA Restricted Links")

	if HarvensCustomMapPinsType then
		AddCustomPin(HarvensCustomMapPinsType, "Harvens Custom Map Pins", "SI_MAPFILTER" .. HarvensCustomMapPinsType)
	end

	local function AddAddonPins(mapPins, caption, strId)
		local pins = { }
		local name
		for i = 1, #mapPins do
			name = mapPins[i]
			if _G[name] then pins[_G[name]] = true end
		end
		if next(pins) then
			AddPins(pins, caption, strId)
		end
	end

	if LBooksMapPin_unknown or pinType_Lore_books then
		local mapPins = {
			"LBooksMapPin_unknown",
			"LBooksMapPin_collected",
			"LBooksMapPin_eidetic",
			"LBooksMapPin_eideticCollected",
			"pinType_Lore_books",
		}
		AddAddonPins(mapPins, "Lore Books", LBOOKS_TITLE)
	end

	if LostTreasureMapTreasurePin then
		local mapPins = {
			"LostTreasureMapTreasurePin",
			"LostTreasureCompassSurveysPin",
		}
		AddAddonPins(mapPins, "Lost Treasure")
	end

	if pinType_Chronic_Chronogler then
		local mapPins = {
			"pinType_Dungeon_bosses",
			"pinType_Dungeon_bosses_done",
			"pinType_Treasure_Maps",
			"pinType_Treasure_Chests",
			"pinType_Unknown_POI",
			"pinType_This_One's_On_Me",
			"pinType_Undaunted_Rescuer",
			"pinType_I_like_M'aiq",
			"pinType_Lightbringer",
			"pinType_Peacemaker",
			"pinType_One_Last_Brawl",
			"pinType_Orsinium_world_event",
			"pinType_Wrothgar_Relic_Hunter",
			"pinType_A_Cutpurse_Above",
			"pinType_Breaking_And_Entering",
			"pinType_Vivec_Lessons",
			"pinType_Ancestral_Tombs",
			"pinType_Pilgrim's_Path",
			"pinType_Summerset_Relics",
			"pinType_Message_in_Bottle",
			"pinType_Summerset_world_event",
			"pinType_Time_Rifts",
			"pinType_Shrines",
			"pinType_Fishing_Nodes",
			"pinType_Precursor_Maker",
			"pinType_Chronic_Chronogler",
			"pinType_Poems_of_Nothing",
			"pinType_Achievement_quests",
			"pinType_Surreptitiously_Shadowed",
			"pinType_Swamp_Rescuer",
			"pinType_Vine-Tongue_Traveler",
		}
		AddAddonPins(mapPins, "Map Pins")
	end

	if SkySMapPin_unknown or pinType_Skyshards then
		local mapPins = {
			"SkySMapPin_unknown",
			"SkySMapPin_collected",
			"pinType_Skyshards",
			"pinType_Skyshards_done",
		}
		AddAddonPins(mapPins, "Sky Shards", SKYS_TITLE)
	end

	AddCustomPin(VotansFishermanPinType, "Votan's Fisherman Pins")

	local task = async:Create("VotanPinSizeOthers")
	local function updatePin(_, pin)
		local pinType = pin:GetPinType()
		if not pinScales[pinType] then UpdatePin(pinType, pin) end
	end
	local function updatePinSize(task)
		task:For(pairs(addon.pinManager:GetActiveObjects())):Do(updatePin)
	end
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = GetString(SI_FURNITURETHEMETYPE1),
		min = 2,
		max = 200,
		step = 1,
		default = 100,
		unit = "%",
		getFunction = function() return pinSizes["Others"] or 100 end,
		setFunction = function(value)
			pinSizes["Others"] = value
			othersScale = value * 0.01
			UpdateControls()
			task:Cancel():Call(updatePinSize)
		end,
	}
	othersScale =(pinSizes["Others"] or 100) * 0.01

end

local function PlayerActivated()
	em:UnregisterForEvent("VOTAN_MINI_MAP_PINSIZES", EVENT_PLAYER_ACTIVATED)
	if addon.account.enableMap then
		addon:InitPinSizes()
	end
end
em:RegisterForEvent("VOTAN_MINI_MAP_PINSIZES", EVENT_PLAYER_ACTIVATED, PlayerActivated)