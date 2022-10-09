-- This file holds all of the filter data for the filter buttons --

ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_USKYSHARDS", "Unknown SkyShards")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_CSKYSHARDS", "Collected SkyShards")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_ULOREBOOKS", "Unknown LoreBooks")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_CLOREBOOKS", "Collected LoreBooks")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_HARVENS", "Harvens")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_HARVENS_HOUSE_HUNTER", "House Hunter")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_CUSTOM", "Custom")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_LOSTTREASURE_MAPS", "Lost Treasure - Treasure Maps")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_LOSTTREASURE_SURVEYS", "Lost Treasure - Surveys")

ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_DARKANCHORS", "Dark Anchors")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_GROUPBOSSES", "Group Bosses")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_OTHER", "Other")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_UNKNOWN", "Unknown")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_INZONE", "Current Zone")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_OUTOFZONE", "Other Zone")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_DELVES", "Delves")

-- AvA SI's
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_KEEPORDISTRICT", "Keep Or District")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_FASTTRAVELKEEP", "Fast Travel Keep")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_KILLLOCATION", "Kill Location")
ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_AVARESPAWN", "AvA Respawn")

ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_GROUPDUNGEON", zo_strformat("<<1>> <<2>>", GetString(SI_QUESTTYPE1), GetString(SI_LFGACTIVITY2)))

local function OnMainButtonClick(data)
	-- SetSubMenuBar Handles changing the categoryId & subFilterId on its own
	WAYPOINTIT:SetSubMenuBar(data)
	if data.subBar then
		-- So we only need to call updateScrollList here
		WAYPOINTIT:UpdateScrollList()
	else
		-- Show categoryId calls UpdateScrollList on its own
		WAYPOINTIT:ShowCategoryId(data.lookupType, data.subType)
	end
end

local function OnSubButtonClick(data)
	WAYPOINTIT:ShowCategoryId(data.lookupType, data.subType)
	--[[
	-- SetSubMenuBar Handles changing the categoryId & subFilterId on its own
	WAYPOINTIT:SetSubMenuBar(data)
	if data.subBar then
		-- So we only need to call updateScrollList here
		WAYPOINTIT:UpdateScrollList()
	else
		-- Show categoryId calls UpdateScrollList on its own
		WAYPOINTIT:ShowCategoryId(data.lookupType, data.subType)
	end
	--]]
end

WAYPOINTIT_FILTER_DATA = {}

WAYPOINTIT_FILTER_DATA["MAINBAR"] = {
	[1] = {
		normal = "/esoui/art/icons/poi/poi_wayshrine_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_wayshrine_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_wayshrine_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_wayshrine_incomplete.dds",
		tooltip = SI_MAPFILTER8, -- Wayshrines
		descriptor = 1,
		subBar = "RESPAWNS",
		callback = OnMainButtonClick
	},
	[2] = {
		normal = "esoui/art/compass/quest_icon_assisted.dds",
		pressed = "esoui/art/compass/quest_icon_assisted.dds",
		highlight = "esoui/art/compass/quest_icon_assisted.dds",
		disabled = "esoui/art/compass/quest_icon.dds",
		tooltip = SI_MAP_INFO_MODE_QUESTS, -- Quest
		descriptor = 2,
		subBar = "QUESTBAR",
		callback = OnMainButtonClick
	},
	[3] = {
		normal = "/esoui/art/icons/poi/poi_areaofinterest_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_areaofinterest_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_areaofinterest_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_areaofinterest_incomplete.dds",
		-- Points of Interest
		tooltip = SI_WORLD_MAP_OPTION_FILTER_OBJECTIVES,
		descriptor = 3,
		subBar = "POIBAR",
		callback = OnMainButtonClick
	},
	[4] = {
		normal = "/esoui/art/icons/poi/poi_town_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_town_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_town_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_town_incomplete.dds",
		tooltip = SI_MAP_INFO_MODE_LOCATIONS, -- Locations
		descriptor = 4,
		lookupType = "loc",
		callback = OnMainButtonClick
	},
	[5] = {
		normal = "WaypointIt/Textures/Custom.dds",
		pressed = "WaypointIt/Textures/Custom.dds",
		highlight = "WaypointIt/Textures/Custom.dds",
		disabled = "WaypointIt/Textures/Custom.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_CUSTOM, -- custom
		descriptor = 5,
		subBar = "CUSTOMPINBAR",
		callback = OnMainButtonClick
	},
	[6] = {
		normal = "esoui/art/compass/ava_largekeep_neutral.dds",
		pressed = "esoui/art/compass/ava_largekeep_neutral.dds",
		highlight = "esoui/art/compass/ava_largekeep_neutral.dds",
		disabled = "esoui/art/compass/ava_largekeep_neutral.dds",
		tooltip = SI_QUESTTYPE7, -- AvA
		descriptor = 6,
		subBar = "AVABAR",
		callback = OnMainButtonClick
	},
	[7] = {
		normal = "WaypointIt/Textures/Group.dds",
		pressed = "WaypointIt/Textures/Group.dds",
		highlight = "WaypointIt/Textures/Group.dds",
		disabled = "WaypointIt/Textures/Group.dds",
		tooltip = SI_MAPFILTER9, -- Group Members
		descriptor = 7,
		lookupType = "group",
		callback = OnMainButtonClick
	}
}

WAYPOINTIT_FILTER_DATA["RESPAWNS"] = {
	[1] = {
		normal = "/esoui/art/icons/poi/poi_wayshrine_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_wayshrine_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_wayshrine_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_wayshrine_incomplete.dds",
		tooltip = SI_MAPFILTER8, -- Wayshrines
		descriptor = 1,
		lookupType = "fastTravelWayshrine",
		callback = OnSubButtonClick
	},
	[2] = {
		normal = "/esoui/art/icons/poi/poi_tower_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_tower_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_tower_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_tower_incomplete.dds",
		-- Points of Interest
		tooltip = SI_BINDING_NAME_WAYPOINTIT_FASTTRAVELKEEP,
		descriptor = 2,
		lookupType = "fastTravelKeep",
		callback = OnSubButtonClick
	},
	[3] = {
		normal = "WaypointIt/Textures/ForwardCamp.dds",
		pressed = "WaypointIt/Textures/ForwardCamp.dds",
		highlight = "WaypointIt/Textures/ForwardCamp.dds",
		disabled = "WaypointIt/Textures/ForwardCamp.dds",
		tooltip = SI_MAPFILTER7, -- Forward Camps
		descriptor = 3,
		lookupType = "forwardCamp",
		callback = OnSubButtonClick
	}
	--[[
	[4] = {
		normal 			= "/esoui/art/icons/poi/poi_tower_complete.dds",
		pressed 		= "/esoui/art/icons/poi/poi_tower_complete.dds",
		highlight	 	= "/esoui/art/icons/poi/poi_tower_complete.dds",
		disabled		= "/esoui/art/icons/poi/poi_tower_incomplete.dds",
		tooltip 		= SI_BINDING_NAME_WAYPOINTIT_AVARESPAWN, -- Wayshrines
		descriptor		= 4,
		lookupType		= "AvARespawn",
		subBar			= "RESPAWNS",
		deadOnly		= true,
		callback	 	= OnSubButtonClick,
	},
	--]]
}

WAYPOINTIT_FILTER_DATA["AVABAR"] = {
	[1] = {
		normal = "esoui/art/compass/ava_largekeep_neutral.dds",
		pressed = "esoui/art/compass/ava_largekeep_neutral.dds",
		highlight = "esoui/art/compass/ava_largekeep_neutral.dds",
		disabled = "esoui/art/compass/ava_largekeep_neutral.dds",
		--normal 			= "EsoUI/Art/MainMenu/menuBar_ava_up.dds",
		tooltip = SI_QUESTTYPE7, -- AvA
		descriptor = 1,
		lookupType = "objective",
		callback = OnSubButtonClick
	},
	[2] = {
		--normal 			= "/esoui/art/ava/ava_allianceflag_aldmeri.dds",
		--pressed 		= "/esoui/art/mappins/ava_borderkeep_pin_aldmeri.dds",
		normal = "WaypointIt/Textures/Aldmeri_Alliance.dds",
		pressed = "WaypointIt/Textures/Aldmeri_Alliance.dds",
		highlight = "WaypointIt/Textures/Aldmeri_Alliance.dds",
		disabled = "WaypointIt/Textures/Aldmeri_Alliance.dds",
		tooltip = SI_ALLIANCE1, -- custom
		descriptor = 2,
		lookupType = "keep",
		subType = ALLIANCE_ALDMERI_DOMINION,
		callback = OnSubButtonClick
	},
	[3] = {
		--normal 			= "/esoui/art/ava/ava_allianceflag_daggerfall2.dds",
		normal = "WaypointIt/Textures/DaggerFall_Alliance.dds",
		pressed = "WaypointIt/Textures/DaggerFall_Alliance.dds",
		highlight = "WaypointIt/Textures/DaggerFall_Alliance.dds",
		disabled = "WaypointIt/Textures/DaggerFall_Alliance.dds",
		tooltip = SI_ALLIANCE3, -- custom
		descriptor = 3,
		lookupType = "keep",
		subType = ALLIANCE_DAGGERFALL_COVENANT,
		callback = OnSubButtonClick
	},
	[4] = {
		--normal 			= "/esoui/art/ava/ava_allianceflag_ebonheart.dds",
		normal = "WaypointIt/Textures/Ebonheart_Alliance.dds",
		pressed = "WaypointIt/Textures/Ebonheart_Alliance.dds",
		highlight = "WaypointIt/Textures/Ebonheart_Alliance.dds",
		disabled = "WaypointIt/Textures/Ebonheart_Alliance.dds",
		tooltip = SI_ALLIANCE2, -- custom
		descriptor = 4,
		lookupType = "keep",
		subType = ALLIANCE_EBONHEART_PACT,
		callback = OnSubButtonClick
	},
	[5] = {
		normal = "/esoui/art/icons/poi/poi_battlefield_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_battlefield_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_battlefield_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_battlefield_incomplete.dds",
		--normal 			= "EsoUI/Art/MapPins/AvA_EbonheartVDaggerfall.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_KILLLOCATION, -- Quest
		descriptor = 5,
		lookupType = "killLocation",
		callback = OnSubButtonClick
	}
}

WAYPOINTIT_FILTER_DATA["CUSTOMPINBAR"] = {
	[1] = {
		normal = "WaypointIt/Textures/Book_incomplete.dds",
		pressed = "WaypointIt/Textures/Book_incomplete.dds",
		highlight = "WaypointIt/Textures/Book_incomplete.dds",
		disabled = "WaypointIt/Textures/Book_incomplete.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_ULOREBOOKS, -- LoreBooks
		descriptor = 1,
		lookupType = "LBooksMapPin_unknown",
		callback = OnSubButtonClick
	},
	[2] = {
		normal = "WaypointIt/Textures/Book_complete.dds",
		pressed = "WaypointIt/Textures/Book_complete.dds",
		highlight = "WaypointIt/Textures/Book_complete.dds",
		disabled = "WaypointIt/Textures/Book_complete.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_CLOREBOOKS, -- LoreBooks
		descriptor = 2,
		lookupType = "LBooksMapPin_collected",
		callback = OnSubButtonClick
	},
	[3] = {
		normal = "SkyShards/Icons/Skyshard-unknown.dds",
		pressed = "SkyShards/Icons/Skyshard-unknown.dds",
		highlight = "SkyShards/Icons/Skyshard-unknown.dds",
		disabled = "SkyShards/Icons/Skyshard-unknown.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_USKYSHARDS, -- SkyShards
		descriptor = 3,
		lookupType = "SkySMapPin_unknown",
		callback = OnSubButtonClick
	},
	[4] = {
		normal = "SkyShards/Icons/Skyshard-collected.dds",
		pressed = "SkyShards/Icons/Skyshard-collected.dds",
		highlight = "SkyShards/Icons/Skyshard-collected.dds",
		disabled = "SkyShards/Icons/Skyshard-collected.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_CSKYSHARDS, -- SkyShards
		descriptor = 4,
		lookupType = "SkySMapPin_collected",
		callback = OnSubButtonClick
	},
	[5] = {
		normal = "WaypointIt/Textures/Harvens.dds",
		pressed = "WaypointIt/Textures/Harvens.dds",
		highlight = "WaypointIt/Textures/Harvens.dds",
		disabled = "WaypointIt/Textures/Harvens.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_HARVENS, -- Harvens Custom Map Pins
		descriptor = 5,
		lookupType = "HarvensCustomMapPinsType",
		callback = OnSubButtonClick
	},
	[6] = {
		normal = "WaypointIt/Textures/LostTreasure/Map_White.dds",
		pressed = "WaypointIt/Textures/LostTreasure/Map_White.dds",
		highlight = "WaypointIt/Textures/LostTreasure/Map_White.dds",
		disabled = "WaypointIt/Textures/LostTreasure/Map_White.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_LOSTTREASURE_MAPS, -- LostTreasure Treasure Maps
		descriptor = 6,
		lookupType = "LostTreasureMapTreasurePin",
		callback = OnSubButtonClick
	},
	[7] = {
		normal = "WaypointIt/Textures/LostTreasure/x_red.dds",
		pressed = "WaypointIt/Textures/LostTreasure/x_red.dds",
		highlight = "WaypointIt/Textures/LostTreasure/x_red.dds",
		disabled = "WaypointIt/Textures/LostTreasure/x_red.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_LOSTTREASURE_SURVEYS, -- LostTreasure Surveys
		descriptor = 7,
		lookupType = "LostTreasureCompassSurveysPin",
		callback = OnSubButtonClick
	},
	[8] = {
		normal = "esoui/art/icons/achievements_indexicon_fishing_down.dds",
		pressed = "esoui/art/icons/achievements_indexicon_fishing_down.dds",
		highlight = "esoui/art/icons/achievements_indexicon_fishing_down.dds",
		disabled = "esoui/art/icons/achievements_indexicon_fishing_down.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_FISHERMAN, -- Votans
		descriptor = 8,
		lookupType = "VotansFishermanPinType",
		callback = OnSubButtonClick
	},
	[9] = {
		normal = "WaypointIt/Textures/Harvens.dds",
		pressed = "WaypointIt/Textures/Harvens.dds",
		highlight = "WaypointIt/Textures/Harvens.dds",
		disabled = "WaypointIt/Textures/Harvens.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_HARVENS_HOUSE_HUNTER, -- Harvens
		descriptor = 9,
		lookupType = "HarvensHouseHunterPinType",
		callback = OnSubButtonClick
	},
	[10] = {
		normal = "WaypointIt/Textures/Other.dds",
		pressed = "WaypointIt/Textures/Other.dds",
		highlight = "WaypointIt/Textures/Other.dds",
		disabled = "WaypointIt/Textures/Other.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_OTHER, -- Other
		descriptor = 10,
		lookupType = "other",
		callback = OnSubButtonClick
	}
}

WAYPOINTIT_FILTER_DATA["POIBAR"] = {
	[1] = {
		normal = "/esoui/art/icons/poi/poi_portal_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_portal_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_portal_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_portal_incomplete.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_DARKANCHORS, -- Dark Anchors
		descriptor = 1,
		lookupType = "poi",
		subType = "darkanchors",
		callback = OnSubButtonClick
	},
	[2] = {
		normal = "/esoui/art/icons/poi/poi_groupboss_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_groupboss_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_groupboss_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_groupboss_incomplete.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_GROUPBOSSES, -- Group Bosses
		descriptor = 2,
		lookupType = "poi",
		subType = "groupbosses",
		callback = OnSubButtonClick
	},
	[3] = {
		normal = "/esoui/art/icons/poi/poi_mundus_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_mundus_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_mundus_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_mundus_complete.dds",
		tooltip = SI_CONFIRM_MUNDUS_STONE_TITLE, -- Mundus Stone
		descriptor = 3,
		lookupType = "poi",
		subType = "mundus",
		callback = OnSubButtonClick
	},
	[4] = {
		normal = "/esoui/art/icons/poi/poi_delve_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_delve_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_delve_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_delve_complete.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_DELVES, -- Delves
		descriptor = 4,
		lookupType = "poi",
		subType = "delves",
		callback = OnSubButtonClick
	},
	[5] = {
		normal = "/esoui/art/icons/poi/poi_dungeon_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_dungeon_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_dungeon_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_dungeon_incomplete.dds",
		tooltip = SI_LFGACTIVITY2, -- Dungeon
		descriptor = 5,
		lookupType = "poi",
		subType = "dungeons",
		callback = OnSubButtonClick
	},
	[6] = {
		normal = "/esoui/art/icons/poi/poi_groupinstance_complete.dds",
		pressed = "/esoui/art/icons/poi/poi_groupinstance_complete.dds",
		highlight = "/esoui/art/icons/poi/poi_groupinstance_complete.dds",
		disabled = "/esoui/art/icons/poi/poi_groupinstance_incomplete.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_GROUPDUNGEON, -- Unknown
		descriptor = 6,
		lookupType = "poi",
		subType = "groupdungeons",
		callback = OnSubButtonClick
	},
	[7] = {
		normal = "WaypointIt/Textures/Other.dds",
		pressed = "WaypointIt/Textures/Other.dds",
		highlight = "WaypointIt/Textures/Other.dds",
		disabled = "WaypointIt/Textures/Other.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_OTHER, -- Other
		descriptor = 7,
		lookupType = "poi",
		subType = "other",
		callback = OnSubButtonClick
	}
}

WAYPOINTIT_FILTER_DATA["QUESTBAR"] = {
	{
		normal = "/esoui/art/floatingmarkers/quest_icon_assisted.dds",
		pressed = "/esoui/art/floatingmarkers/quest_icon_assisted.dds",
		highlight = "/esoui/art/floatingmarkers/quest_icon_assisted.dds",
		disabled = "/esoui/art/floatingmarkers/quest_icon.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_INZONE, -- Current Zone
		descriptor = 1,
		lookupType = "quest",
		subType = "inzone",
		callback = OnSubButtonClick
	},
	{
		normal = "/esoui/art/floatingmarkers/quest_icon_door_assisted.dds",
		pressed = "/esoui/art/floatingmarkers/quest_icon_door_assisted.dds",
		highlight = "/esoui/art/floatingmarkers/quest_icon_door_assisted.dds",
		disabled = "/esoui/art/floatingmarkers/quest_icon_door.dds",
		tooltip = SI_BINDING_NAME_WAYPOINTIT_OUTOFZONE, -- Other Zone
		descriptor = 2,
		lookupType = "quest",
		subType = "outofzone",
		callback = OnSubButtonClick
	}
}

function WAYPOINTIT_FILTER_DATA:EnableQuestMap()
	table.insert(
		WAYPOINTIT_FILTER_DATA["QUESTBAR"],
		{
			normal = "QuestMap/icons/eso_inverted_completed.dds",
			pressed = "QuestMap/icons/eso_inverted_completed.dds",
			highlight = "QuestMap/icons/eso_inverted_completed.dds",
			disabled = "QuestMap/icons/eso_inverted_completed.dds",
			tooltip = QUESTMAP_QUESTS, -- Other
			descriptor = 3,
			lookupType = "quest",
			subType = "other",
			callback = OnSubButtonClick
		}
	)
end
