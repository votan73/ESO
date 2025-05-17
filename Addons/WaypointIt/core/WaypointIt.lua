-- ToDo: auto-waypoint custom pins, if one was selected.
local gps = LibGPS3
local LMP = LibMapPing

WaypointIt = {}

local WaypointIt = WaypointIt
local ADDON_NAME = "WaypointIt"
local CODE_VERSION = "1.14.10"
-- Holds the requested taskID
local CURRENT_TASK
local ROW_TYPE_ID = 1

local INDEX_BUTTON = 1
local INDEX_POOL_KEY = 2
local INDEX_DESCRIPTOR = 3

-- Map Pin lookupTypes
local MPLTYPE_POI = "poi"
local MPLTYPE_LOCATION = "loc"
local MPLTYPE_QUEST = "quest"
local MPLTYPE_AVA = "objective"
local MPLTYPE_KEEP = "keep"
local MPLTYPE_PINGS = "pings"
local MPLTYPE_KILL_LOCATION = "killLocation"
local MPLTYPE_FAST_TRAVEL_KEEP = "fastTravelKeep"
local MPLTYPE_FAST_TRAVEL_WAYSHRINE = "fastTravelWayshrine"
local MPLTYPE_FORWARD_CAMP = "forwardCamp"
local MPLTYPE_AVA_RESPAWN = "AvARespawn"
local MPLTYPE_GROUP = "group"
local MPLTYPE_OTHER = "other"

local pinId = "waypoint"

local em = GetEventManager()

--[[
If a waypoint is already set & we try to set a new waypoint we have a problem.
We need to set the new waypointIt.sv.currentWaypoint data, but we cant do that until
after the old wp gets removed because that nils out the currentWaypoint data and we..shouldn't..change that.
When we set a waypoint, we will temporarily store the new wp data here, until the ping added event fires
then in the onPingAdded we will transfer this wp data to waypointIt.sv.currentWaypoint and
wipe out nextWaypoint.
--]]
local nextWaypoint
local lastWaypointBy, lastZoneId
local suspendAssistState = true
local lastMarkQuest = 0
local pingSuspendCount = 0

local LoreBookPins = {}
local AddonPins = {}

local newLookupType = {}

local tasks = {}

-------------------------------------------------
-----------   Debug Window   -----------------
-------------------------------------------------

local logger = LibDebugLogger and LibDebugLogger(ADDON_NAME)
-- colorized grey for debug messages
local function db(msg, ...)
	if not WAYPOINTIT.sv["QUEST_ENABLE_DEBUG"] or not logger then
		return
	end
	logger:Debug(msg, ...)
end

-- Prints to debug window without colorization. Colors are handled before
-- passed to this function. Will be used later as a quest step/instructions tracking window.
local function dw(msg)
	if not IsChatSystemAvailableForCurrentPlatform() then
		return
	end
	local self = CHAT_ROUTER
	local event = EVENT_CHAT_MESSAGE_CHANNEL
	self:FormatAndAddChatMessage(event, CHAT_CHANNEL_MONSTER_SAY, ADDON_NAME, msg, false, "")
end

local function isAccessibilitySettingEnabled(settingId)
	return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, settingId)
end

local function isAccessibilityModeEnabled()
	return isAccessibilitySettingEnabled(ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE)
end

local function addChatMessageForScreenReader(soundToPlay, chatText)
	if chatText ~= nil and chatText ~= "" then
		if soundToPlay ~= nil then
			PlaySound(soundToPlay)
			PlaySound(soundToPlay)
			PlaySound(soundToPlay)
		end
		d(chatText)
	end
end

function WaypointIt:ChatNarrationOutput(textToNarrate, soundToPlay)
	--Is the Chat narration enabled?
	if not isAccessibilityModeEnabled() or not isAccessibilitySettingEnabled(ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION) then
		return
	end
	soundToPlay = soundToPlay or SOUNDS.EDIT_CLICK
	addChatMessageForScreenReader(soundToPlay, textToNarrate)
end

function WaypointIt:GetDistanceToLocalCoords(locX, locY, playerOffsetX, playerOffsetY)
	-- if not on cosmic map or we reset it to player location
	if not self:CanProcessMap() then
		return 0, false
	end

	local useLocalDistance = self:IsNormalizedPointInsideMapBounds(locX, locY)
	locX, locY = gps:LocalToGlobal(locX, locY)
	if not playerOffsetX then
		playerOffsetX, playerOffsetY = gps:LocalToGlobal(GetMapPlayerPosition("player"))
	end

	local gameUnitDistance = useLocalDistance and gps:GetGlobalDistanceInMeters(locX, locY, playerOffsetX, playerOffsetY) or math.floor(zo_distance(locX, locY, playerOffsetX, playerOffsetY) * 25000)

	-- 11,000 steps per unit, stride length 3.5 feet per step -- No longer calculated this way
	-- Strike that, changing calculations to match ability grey out distance/range
	-- 15000 * 5.6 = 84000 and feet to meters: 84000 * 0.3048 = 25603.2
	return math.floor(gameUnitDistance * (self.sv["WAYPOINT_DISTANCEIN_METERS"] and 1 or 3.28084))
end
function WaypointIt:IsWaypointOutsideOfRemovalDistance(xLoc, yLoc)
	local pinDeltaMin, pinDeltaMax, distToCoords = self.sv.WAYPOINT_DELTA_SCALE, self.sv.WAYPOINT_DELTA_SCALE_MAX, self:GetDistanceToLocalCoords(xLoc, yLoc)

	return distToCoords > pinDeltaMin and distToCoords < pinDeltaMax
end
local function HasWaypoint()
	local offsetX, offsetY = GetMapPlayerWaypoint()
	return offsetX ~= 0 or offsetY ~= 0
end
local function GetQuestTracker()
	return FOCUSED_QUEST_TRACKER
end
local function GetCurrentZoneId()
	return GetZoneId(GetCurrentMapIndex())
end
-------------------------------------------------
-----------   Event Callbacks   -----------------
-------------------------------------------------
function WaypointIt:SetupEvents()
	local function OnCombatStateChange(eventCode, inCombat)
		self.FRAGMENT_DIRECTION_ARROW:SetHiddenForReason("combat", inCombat and self.sv["WAYPOINT_HIDE_ARROW_INCOMBAT"])
		self.FRAGMENT_GROUP_DIRECTION_ARROW:SetHiddenForReason("combat", inCombat and self.sv["WAYPOINT_HIDE_GROUP_ARROW_INCOMBAT"])
	end

	local function OnGroupUpdate()
		self.FRAGMENT_DIRECTION_ARROW:SetHiddenForReason("group", self.sv["WAYPOINT_HIDE_ARROW_GROUP"] and IsUnitGrouped("player"))
		self.FRAGMENT_GROUP_DIRECTION_ARROW:SetHiddenForReason("group", not IsUnitGrouped("player"))
		-- groupN tags get changed around during loading screens, so make sure we follow the right one
		local followingUnit = self.followingUnit
		if followingUnit then
			local followingUnitName = followingUnit.name
			-- only search if tag has changed (group size can be up to 24)
			if followingUnitName ~= GetUnitName(followingUnit.unitTag) then
				for i = 1, GetGroupSize() do
					local unitTag = GetGroupUnitTagByIndex(i)
					local unitName = GetUnitName(unitTag)
					if followingUnitName == unitName then
						followingUnit.unitTag = unitTag -- this is the one to follow
						break -- stop looking
					end
				end
			end
		-- no need to stop updates if followed unit not found, RunGroupWaypointUpdates will wait
		-- and there will probably be another update with followed unit before it times out
		end
	end
	em:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, OnCombatStateChange)
	em:RegisterForEvent(self.name, EVENT_GROUP_MEMBER_LEFT, OnGroupUpdate)
	em:RegisterForEvent(self.name, EVENT_GROUP_MEMBER_JOINED, OnGroupUpdate)
	em:RegisterForEvent(self.name, EVENT_GROUP_UPDATE, OnGroupUpdate)

	local function OnPlayerActivatedQuest()
		if not lastWaypointBy or lastWaypointBy == "autoQuest" then
			self:RefreshQuestWaypoint()
		end
	end
	local function OnZoneChanged()
		local autoMark = self.sv["QUEST_AUTOMARK_NEXT_WAYPOINT"]
		if autoMark ~= "Closest Quest" or (GetTimeStamp() - lastMarkQuest) < 60 then
			return
		end

		self:RefreshQuestWaypoint()
	end

	local function OnPlayerActivated(eventCode)
		-- This needs to be unregistered here instead of in my OnAddonLoaded
		-- so it can catch any addons that load after mine
		em:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

		em:UnregisterForEvent(self.name, EVENT_PLAYER_ACTIVATED)
		em:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivatedQuest)
		em:RegisterForEvent(self.name, EVENT_ZONE_CHANGED, OnZoneChanged)

		newLookupType[MPLTYPE_POI] = MPLTYPE_POI
		newLookupType[MPLTYPE_LOCATION] = MPLTYPE_LOCATION
		newLookupType[MPLTYPE_QUEST] = MPLTYPE_QUEST
		newLookupType[MPLTYPE_AVA] = MPLTYPE_AVA
		newLookupType[MPLTYPE_KEEP] = MPLTYPE_KEEP
		newLookupType[MPLTYPE_PINGS] = MPLTYPE_PINGS
		newLookupType[MPLTYPE_KILL_LOCATION] = MPLTYPE_KILL_LOCATION
		newLookupType[MPLTYPE_FAST_TRAVEL_KEEP] = MPLTYPE_FAST_TRAVEL_KEEP
		newLookupType[MPLTYPE_FAST_TRAVEL_WAYSHRINE] = MPLTYPE_FAST_TRAVEL_WAYSHRINE
		newLookupType[MPLTYPE_FORWARD_CAMP] = MPLTYPE_FORWARD_CAMP
		newLookupType[MPLTYPE_AVA_RESPAWN] = MPLTYPE_AVA_RESPAWN
		newLookupType[MPLTYPE_GROUP] = MPLTYPE_GROUP
		newLookupType[MPLTYPE_OTHER] = MPLTYPE_OTHER

		local function AddPin(pinType, func)
			if pinType then
				AddonPins[pinType] = func
			end
		end
		if self.categories["LBooksMapPin_unknown"].info.display then
			newLookupType["LBooksMapPin_unknown"] = "LBooksMapPin_unknown"
			newLookupType["LBooksMapPin_collected"] = "LBooksMapPin_collected"
			newLookupType["LBooksMapPin_eidetic"] = "LBooksMapPin_unknown"
			newLookupType["LBooksMapPin_eideticCollected"] = "LBooksMapPin_collected"
			newLookupType["pinType_Lore_books"] = "LBooksMapPin_unknown"

			AddPin(LBooksMapPin_unknown, self.AddLorebookPin)
			AddPin(LBooksMapPin_collected, self.AddLorebookPin)
			AddPin(LBooksMapPin_eidetic, self.AddLorebookPin)
			AddPin(LBooksMapPin_eideticCollected, self.AddLorebookPin)
			AddPin(pinType_Lore_books, self.AddLorebookMapPins)
		end
		if self.categories["SkySMapPin_collected"].info.display then
			newLookupType["SkySMapPin_collected"] = "SkySMapPin_collected"
			newLookupType["SkySMapPin_unknown"] = "SkySMapPin_unknown"
			newLookupType["pinType_Skyshards"] = "SkySMapPin_unknown"
			newLookupType["pinType_Skyshards_done"] = "SkySMapPin_collected"

			AddPin(SkySMapPin_collected, self.AddSkyshardPin)
			AddPin(SkySMapPin_unknown, self.AddSkyshardPin)

			AddPin(pinType_Skyshards, self.AddSkyshardMapPins)
			AddPin(pinType_Skyshards_done, self.AddSkyshardMapPins)
		end
		if self.categories["HarvensCustomMapPinsType"].info.display then
			newLookupType["HarvensCustomMapPinsType"] = "HarvensCustomMapPinsType"
			AddPin(HarvensCustomMapPinsType, self.AddHarvensPin)
		end
		if self.categories["HarvensHouseHunterPinType"].info.display then
			newLookupType["HarvensHouseHunterPinType"] = "HarvensHouseHunterPinType"
			AddPin(HarvensHouseHunterPinType, self.AddHouseHunterPin)
		end
		if self.categories["VotansFishermanPinType"].info.display then
			newLookupType["VotansFishermanPinType"] = "VotansFishermanPinType"
			AddPin(VotansFishermanPinType, self.AddFisherman)
		end
		if self.categories["LostTreasureMapTreasurePin"].info.display then
			newLookupType["LostTreasure_TreasureMapPin"] = "LostTreasureMapTreasurePin"
			newLookupType["pinType_Treasure_Maps"] = "LostTreasureMapTreasurePin"
			AddPin(LostTreasure_TreasureMapPin, self.AddLostTreasureTreasure)
			AddPin(pinType_Treasure_Maps, self.AddLostTreasureTreasureMapPins)
		end
		if self.categories["LostTreasureCompassSurveysPin"].info.display then
			newLookupType["LostTreasure_SurveyReportPin"] = "LostTreasureCompassSurveysPin"
			AddPin(LostTreasure_SurveyReportPin, self.AddLostTreasureSurvey)
		end
		if self.categories[MPLTYPE_OTHER].info.display then
			local function addAchievement(pinTypeString)
				newLookupType[pinTypeString] = MPLTYPE_OTHER
				AddPin(_G[pinTypeString], self.AddAchievementMapPins)
			end
			addAchievement("pinType_Dungeon_bosses")
			addAchievement("pinType_Dungeon_bosses_done")
			addAchievement("pinType_This_One's_On_Me")
			addAchievement("pinType_Undaunted_Rescuer")
			addAchievement("pinType_I_like_M'aiq")
			addAchievement("pinType_Lightbringer")
			addAchievement("pinType_Peacemaker")
			addAchievement("pinType_One_Last_Brawl")
			addAchievement("pinType_Orsinium_world_event")
			addAchievement("pinType_Wrothgar_Relic_Hunter")
			addAchievement("pinType_A_Cutpurse_Above")
			addAchievement("pinType_Breaking_And_Entering")
			addAchievement("pinType_Vivec_Lessons")
			addAchievement("pinType_Ancestral_Tombs")
			addAchievement("pinType_Summerset_Relics")
			addAchievement("pinType_Message_in_Bottle")
			addAchievement("pinType_Summerset_world_event")

			newLookupType["pinType_Time_Rifts"] = MPLTYPE_OTHER
			AddPin(pinType_Time_Rifts, self.AddTimeRiftsMapPins)
		end
		if QuestMap then
			local function addQuestMap(pinTypeString)
				newLookupType[pinTypeString] = MPLTYPE_QUEST
				AddPin(_G[pinTypeString], self.AddQuestMapPins)
			end

			for pinType in pairs(QuestMap) do
				if string.find(pinType, "^PIN_TYPE_QUEST_") then
					addQuestMap(pinType)
				end
			end
		end
		if Destinations then
			local function addDestinations(pinTypeString)
				newLookupType[pinTypeString] = MPLTYPE_OTHER
				AddPin(_G[pinTypeString], self.AddDestinationsPins)
			end
			local function addDestinationsUnknown(pinTypeString)
				newLookupType[pinTypeString] = MPLTYPE_OTHER
				AddPin(_G[pinTypeString], self.AddDestinationsUnknownPins)
			end
			addDestinations("DEST_PinSet_FakeKnown")

			addDestinationsUnknown("DEST_PinSet_Unknown")

			addDestinations("DEST_PinSet_Other")
			addDestinations("DEST_PinSet_Maiq")
			addDestinations("DEST_PinSet_Peacemaker")
			addDestinations("DEST_PinSet_Nosediver")
			addDestinations("DEST_PinSet_Earthly_Possessions")
			addDestinations("DEST_PinSet_This_Ones_On_Me")
			addDestinations("DEST_PinSet_Last_Brawl")
			addDestinations("DEST_PinSet_Patron")
			addDestinations("DEST_PinSet_Wrothgar_Jumper")
			addDestinations("DEST_PinSet_Wrothgar_Relic_Hunter")
			addDestinations("DEST_PinSet_Breaking_Entering")
			addDestinations("DEST_PinSet_Cutpurse_Above")
			addDestinations("DEST_PinSet_Champion")

			addDestinations("DEST_PinSet_Other_Done")
			addDestinations("DEST_PinSet_Maiq_Done")
			addDestinations("DEST_PinSet_Peacemaker_Done")
			addDestinations("DEST_PinSet_Nosediver_Done")
			addDestinations("DEST_PinSet_Earthly_Possessions_Done")
			addDestinations("DEST_PinSet_This_Ones_On_Me_Done")
			addDestinations("DEST_PinSet_Last_Brawl_Done")
			addDestinations("DEST_PinSet_Patron_Done")
			addDestinations("DEST_PinSet_Wrothgar_Jumper_Done")
			addDestinations("DEST_PinSet_Wrothgar_Relic_Hunter_Done")
			addDestinations("DEST_PinSet_Breaking_Entering_Done")
			addDestinations("DEST_PinSet_Cutpurse_Above_Done")
			addDestinations("DEST_PinSet_Champion_Done")

			addDestinations("DEST_Compass_Achievements")

			addDestinations("DEST_PinSet_Ayleid")
			addDestinations("DEST_PinSet_Dwemer")
			addDestinations("DEST_Compass_Misc")

			addDestinations("DEST_PinSet_WWVamp")
			addDestinations("DEST_PinSet_Vampire_Alter")
			addDestinations("DEST_PinSet_Werewolf_Shrine")
			addDestinations("DEST_Compass_WWVamp")

			addDestinations("DEST_Pin_Quest_Giver")
			addDestinations("DEST_Pin_Quest_In_Progress")
			addDestinations("DEST_Pin_Quest_Done")
			addDestinations("DEST_Compass_Quest_Giver")
			addDestinations("DEST_Pin_Quest_Daily")
			addDestinations("DEST_Pin_Quest_Writ")
			addDestinations("DEST_Pin_Quest_Repeatable")
			addDestinations("DEST_Register_Quests")

			addDestinations("DEST_Pin_Collectibles")
			addDestinations("DEST_Compass_Collectibles")
			addDestinations("DEST_Pin_Collectibles_Done")
			addDestinations("DEST_Compass_Collectibles_Show_Item")
			addDestinations("DEST_Compass_Collectibles_Show_MobName")

			addDestinations("DEST_Pin_Fishing")
			addDestinations("DEST_Compass_Fishing")
			addDestinations("DEST_Pin_Fishing_Done")
			addDestinations("DEST_Compass_Fishing_Show_Bait")
			addDestinations("DEST_Compass_Fishing_Show_Bait_Left")
			addDestinations("DEST_Compass_Fishing_Show_Water")
			addDestinations("DEST_Compass_Fishing_Show_FishName")
		end
		if SimpleSkyshards then
			newLookupType["SIMPLE_SKYSHARDS_PIN_TYPE_SHARD_ON_MAP"] = "SkySMapPin_unknown"
			newLookupType["SIMPLE_SKYSHARDS_PIN_TYPE_SHARD_ON_MAP_NO_TOOLTIP"] = "SkySMapPin_unknown"
			newLookupType["SIMPLE_SKYSHARDS_PIN_TYPE_SHARD_DELVE_OR_DUNGEON"] = "SkySMapPin_unknown"
			newLookupType["SIMPLE_SKYSHARDS_PIN_TYPE_SHARD_DELVE_OR_DUNGEON_ACQUIRED"] = "SkySMapPin_collected"

			zo_callLater(
				function()
					AddPin(SIMPLE_SKYSHARDS_PIN_TYPE_SHARD_ON_MAP, self.AddSimpleSkyshardPin)
					AddPin(SIMPLE_SKYSHARDS_PIN_TYPE_SHARD_ON_MAP_NO_TOOLTIP, self.AddSimpleSkyshardPin)
					AddPin(SIMPLE_SKYSHARDS_PIN_TYPE_SHARD_DELVE_OR_DUNGEON, self.AddSimpleSkyshardDelvePin)
					AddPin(SIMPLE_SKYSHARDS_PIN_TYPE_SHARD_DELVE_OR_DUNGEON_ACQUIRED, self.AddSimpleSkyshardDelvePin)
				end,
				100
			)
		end

		OnGroupUpdate()
		OnPlayerActivatedQuest()
	end
	-- Handled by LibMapPing, see below. em:RegisterForEvent(self.name, EVENT_MAP_PING, OnMapPing)
	em:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

	local function refreshIfVisible()
		if self.FRAGMENT_WINDOW:IsShowing() then
			ZO_ScrollList_RefreshVisible(self.scrollList)
		end
	end
	-- Automatically remove waypoints
	local function OnMapPing(pingEventType, pingType, pingTag, offsetX, offsetY, isOwner)
		-- Check for libGPS, it sets waypoints to measure the map. We dont want events firing then.
		if gps:IsMeasuring() or not isOwner or pingType ~= MAP_PIN_TYPE_PLAYER_WAYPOINT then
			return
		end

		if (pingEventType == PING_EVENT_ADDED) and pingTag == pinId then
			if (pingSuspendCount > 0 and LMP:IsPingSuppressed(MAP_PIN_TYPE_PLAYER_WAYPOINT, pinId)) then
				LMP:UnsuppressPing(MAP_PIN_TYPE_PLAYER_WAYPOINT, pinId)
				pingSuspendCount = pingSuspendCount - 1
			end
			if LMP:IsPingSuppressed(MAP_PIN_TYPE_PLAYER_WAYPOINT, pinId) then
				return
			end

			-- Changed: See nextWaypoint definition for reason.
			-- local waypoint = WAYPOINTIT.sv.currentWaypoint
			-- nextWaypoint can be nil if the wp was set manually or by some other addon
			-- This is ok
			local waypoint = nextWaypoint
			self.sv.currentWaypoint = waypoint
			nextWaypoint = nil

			local setBy = waypoint and waypoint.setBy or "rowClick"
			if waypoint and waypoint.lookupType then
				LMP:UnmutePing(MAP_PIN_TYPE_PLAYER_WAYPOINT, pinId)
			end

			lastWaypointBy, lastZoneId = setBy, GetCurrentZoneId()

			db("waypoint set: mode %s", lastWaypointBy or "nil")
			if (waypoint and setBy == "rowClick") then
				if self.sv["WAYPOINT_MESSAGES_USER_DEFINED"] then
					CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_CATEGORY_SMALL_TEXT, SOUNDS.ACHIEVEMENT_AWARDED, GetString(SI_WAYPOINTIT_WAYPOINT_SET))
				end
				--Baertram, 2022-03-03,Accessibility chat messages for screen reader
				if self.sv["WAYPOINT_MESSAGES_USER_DEFINED_TO_CHAT"] then
					addChatMessageForScreenReader(SOUNDS.ACHIEVEMENT_AWARDED, GetString(SI_WAYPOINTIT_WAYPOINT_SET))
				end
			end
			self:RunWaypointRemoveUpdates(true, lastWaypointBy == "follow")
			self:RunHeadingUpdates(true)
			refreshIfVisible()
		elseif (pingEventType == PING_EVENT_REMOVED) and pingTag == pinId then
			if (not LMP:IsPingSuppressed(MAP_PIN_TYPE_PLAYER_WAYPOINT, pinId)) then
				self:RunWaypointRemoveUpdates(false)
				self:RunHeadingUpdates(false)
				self.sv.currentWaypoint = nil
				db("waypoint removed %s", lastWaypointBy or "nil")
				lastWaypointBy = "autoQuest"
				refreshIfVisible()
			end
		end
	end
	LMP:RegisterCallback(
		"AfterPingAdded",
		function(...)
			OnMapPing(PING_EVENT_ADDED, ...)
		end
	)
	LMP:RegisterCallback(
		"AfterPingRemoved",
		function(...)
			OnMapPing(PING_EVENT_REMOVED, ...)
		end
	)
end

do
	local lastPrintedStep
	-- Print the active StepText in chat, Prints the active step text/condition or the text for the passed in step/condition Index (used when there are multiple steps/conditions and we are setting waypoints for the closest condition).
	function WaypointIt:PrintNextStepText(journalQuestIndex, stepIndex, conditionIndex)
		if not self.sv["QUEST_PRINT_STEPS"] then
			return
		end

		local sQuestName, stepText, conditionText

		if stepIndex and conditionIndex then
			local printStep = journalQuestIndex * 10000 + stepIndex * 100 + conditionIndex
			if lastPrintedStep == printStep then
				return
			end
			lastPrintedStep = printStep

			sQuestName = GetJournalQuestName(journalQuestIndex)
			stepText = GetJournalQuestStepInfo(journalQuestIndex, stepIndex)
			conditionText = GetJournalQuestConditionInfo(journalQuestIndex, stepIndex, conditionIndex)
		else
			local printStep = journalQuestIndex
			if lastPrintedStep == printStep then
				return
			end
			lastPrintedStep = printStep

			-- We only make it here if they clicked on a row to set a waypoint
			-- Theres no way to know which condition a map Pin belongs to, so we wont print
			-- the condition text through this path.
			local questName, _, activeStepText = GetJournalQuestInfo(journalQuestIndex)
			sQuestName = questName
			stepText = activeStepText
		end

		local fQuestName = ZO_CachedStrFormat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, sQuestName)
		local fStepText = ZO_CachedStrFormat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, stepText)
		local fText = string.format("%s%s: |r%s", self.color.darkOrange, fQuestName, fStepText)

		dw(fText)

		if conditionText and conditionText ~= "" and conditionText ~= "TRACKER GOAL TEXT" then
			dw(conditionText)
		end
	end
end

function WaypointIt:ForceAssist(journalQuestIndex)
	if self.sv["QUEST_FORCE_ASSIST"] then
		suspendAssistState = true
		if QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() ~= journalQuestIndex then
			GetQuestTracker():ForceAssist(journalQuestIndex)
			if QUEST_JOURNAL_KEYBOARD then
				QUEST_JOURNAL_KEYBOARD:FocusQuestWithIndex(journalQuestIndex)
			end
			if QUEST_JOURNAL_GAMEPAD then
				QUEST_JOURNAL_GAMEPAD:FocusQuestWithIndex(journalQuestIndex)
			end
		end
		suspendAssistState = false
	end
end

function WaypointIt:CancelCurrentTask()
	if CURRENT_TASK then
		CancelRequestJournalQuestConditionAssistance(CURRENT_TASK.taskId)
		ZO_ClearTable(tasks)
	end
end

function WaypointIt:SetupQuestEvents()
	-- Does not always fire. I think it only fires on step advances &
	-- not on condition advances, had to switch to OnQuestConditionCounterChanged
	-- Keep it, temporarily, in case condition coutner change doesn't work out
	local function OnQuestAdvanced(eventCode, journalQuestIndex, questName, isPushed, isComplete, mainStepChanged)
		db(self.color.yellow .. "Quest Advanced")
	end

	--[[ These are for debug testing. I don't yet know what will happen if a condition is completed that is only optional,
		and I don't know what a quest objective is, hoping to use this to find out when I can do further testing. --]]
	local function OnQuestOptionalStepAdvanced(eventCode, text)
		db(self.color.magenta .. "OnQuestOptionalStepAdvanced:" .. text)
	end
	local function OnQuestObjectivesUpdated(eventCode)
		db(self.color.magenta .. "OnQuestObjectivesUpdated")
	end
	local function OnQuestObjectiveCompleted(eventCode, zoneIndex, poiIndex, level, previousXP, currentXP, rank, previousPoints, currentPoints)
		db(self.color.magenta .. "OnQuestObjectiveCompleted")
	end

	--[[ Fires when my task request has finsished processing. It gives me the loc for a quest step/condition and sets a waypoint for it.
	--]]
	local function OnQuestPositionRequestComplete(eventCode, taskId, pinType, xLoc, yLoc, areaRadius, insideCurrentMapWorld, isBreadcrumb)
		if xLoc ~= 0 or yLoc ~= 0 then
			tasks[taskId] = {gps:LocalToGlobal(xLoc, yLoc)}
		end

		if not CURRENT_TASK then
			return
		end
		if lastWaypointBy == "rowClick" and lastZoneId == GetCurrentZoneId() then
			return
		end

		if taskId == CURRENT_TASK.taskId then
			if self:IsWaypointOutsideOfRemovalDistance(xLoc, yLoc) or self.sv["QUEST_ENABLE_GLOBAL_WAYPOINT"] then
				-- Changed: See nextWaypoint definition for reason.
				--[[
			WAYPOINTIT.sv.currentWaypoint = {
				["lookupType"] 	= CURRENT_TASK.lookupType,
				["majorIndex"] 	= CURRENT_TASK.majorIndex,
				["keyIndex"]	= CURRENT_TASK.keyIndex,
				["name"]		= CURRENT_TASK.name,
				["setBy"] 		= "autoQuest"
			}
			--]]
				if (lastWaypointBy ~= "autoQuest") then
					if self.sv["WAYPOINT_MESSAGES_AUTO_QUEST"] then
						CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_CATEGORY_SMALL_TEXT, SOUNDS.ACHIEVEMENT_AWARDED, GetString(SI_WAYPOINTIT_WAYPOINT_SET))
					end
					--Baertram, 2022-03-03,Accessibility chat messages for screen reader
					if self.sv["WAYPOINT_MESSAGES_AUTO_QUEST_TO_CHAT"] then
						addChatMessageForScreenReader(SOUNDS.ACHIEVEMENT_AWARDED, GetString(SI_WAYPOINTIT_WAYPOINT_SET))
					end
				end

				nextWaypoint = {
					["lookupType"] = CURRENT_TASK.lookupType,
					["majorIndex"] = CURRENT_TASK.majorIndex,
					["keyIndex"] = CURRENT_TASK.keyIndex,
					["name"] = CURRENT_TASK.name,
					["setBy"] = "autoQuest"
				}

				lastMarkQuest = GetTimeStamp()
				-- All quest coordinates are normalized to the PLAYERS current map (not ZO_WorldMaps current map)
				-- so we must set the map to the players location before setting the waypoint.
				-- to ensure that the waypoint gets set in the correct location.
				-- 		if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
				-- 			CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
				-- 		end
				if tasks[taskId] and self:SetWaypoint(unpack(tasks[taskId])) then
					return
				end
			elseif self.sv["WAYPOINT_DISTANCE_WARNING"] then
				local fText = GetString(SI_WAYPOINTIT_WAYPOINT_REMOVAL_DISTANCE)
				dw(fText)
				db(fText)
			end
			if lastWaypointBy == "autoQuest" and HasWaypoint() then
				ZO_WorldMap_RemovePlayerWaypoint() -- Baertram, 2022-03-03, Fix WorldMap removal of waypoint so that the keybind will allow to add a new one (instead of remove a non existing)
			end
		-- CURRENT_TASK = nil
		end
	end

	local function OnQuestConditionCounterChanged(eventCode, journalQuestIndex)
		CURRENT_TASK = nil
		self:TryAutoMarkNextQuest(journalQuestIndex)
	end

	local function OnQuestComplete()
		CURRENT_TASK = nil
		if not self.sv["QUEST_AUTOMARK_ON_QUEST_COMPLETION"] then
			return
		end

		local considerType = QUEST_ASSIST_CONSIDER_ALL_QUESTS
		local foundValidCondition, journalQuestIndex, stepIndex, conditionIndex = GetNearestQuestCondition(considerType)

		if not foundValidCondition then
			db("OnQuestComplete: Valid Condition Not Found for quest")
			if lastWaypointBy == "autoQuest" and HasWaypoint() then
				ZO_WorldMap_RemovePlayerWaypoint() -- Baertram, 2022-03-03, Fix WorldMap removal of waypoint so that the keybind will allow to add a new one (instead of remove a non existing)
			end
			return
		end
		self:TryAutoMarkNextQuest(journalQuestIndex)
	end

	local function OnQuestAdded(eventCode, journalQuestIndex)
		if not self.sv["QUEST_AUTOMARK_ON_QUEST_ACCEPT"] then
			return
		end

		self:TryAutoMarkNextQuest(journalQuestIndex, "Current Quest")
	end
	em:RegisterForEvent(self.name, EVENT_QUEST_POSITION_REQUEST_COMPLETE, OnQuestPositionRequestComplete)
	-- Only fires on step advances, switched to condition counter changed event
	-- em:RegisterForEvent(self.name, EVENT_QUEST_ADVANCED, OnQuestAdvanced)
	em:RegisterForEvent(self.name, EVENT_QUEST_CONDITION_COUNTER_CHANGED, OnQuestConditionCounterChanged)

	em:RegisterForEvent(self.name, EVENT_QUEST_COMPLETE, OnQuestComplete)
	em:RegisterForEvent(self.name, EVENT_QUEST_ADDED, OnQuestAdded)

	-- These are in here for testing, because I'm unsure what they do or how they affect everything else
	em:RegisterForEvent(self.name, EVENT_QUEST_OPTIONAL_STEP_ADVANCED, OnQuestOptionalStepAdvanced)
	-- em:RegisterForEvent(self.name, EVENT_OBJECTIVES_UPDATED, OnQuestObjectivesUpdated)
	em:RegisterForEvent(self.name, EVENT_OBJECTIVE_COMPLETED, OnQuestObjectiveCompleted)

	do
		-- Update pointer after using a door
		local identifier = "WAYPOINTIT_DOOR_ACTION"
		local function DelayDoorAction()
			em:UnregisterForUpdate(identifier)
			self:RefreshQuestWaypoint()
		end
		ZO_PreHook(
			INTERACTIVE_WHEEL_MANAGER,
			"StopInteraction",
			function()
				local actionName = GetGameCameraInteractableActionInfo()
				if actionName == GetString(SI_GAMECAMERAACTIONTYPE13) then
					em:UnregisterForUpdate(identifier)
					em:RegisterForUpdate(identifier, 2000, DelayDoorAction)
				end
			end
		)
	end

	-- Update pointer after selecting a new quest
	GetQuestTracker():RegisterCallback(
		"QuestTrackerAssistStateChanged",
		function(oldState, newState)
			if suspendAssistState then
				return
			end
			local autoMark = self.sv["QUEST_AUTOMARK_NEXT_WAYPOINT"]
			if not newState or autoMark == "Off" then
				return
			end

			self:TryAutoMarkNextQuest(newState:GetJournalIndex(), "Current Quest")
		end
	)
end

do
	local identifier = "WAYPOINTIT_QUEST_DELAY"

	function WaypointIt:RefreshQuestWaypoint()
		em:UnregisterForUpdate(identifier)

		local hasWaypoint = HasWaypoint()
		if hasWaypoint then
			self:RunWaypointRemoveUpdates(true)
			self:RunHeadingUpdates(true)
			if lastWaypointBy ~= "autoQuest" then
				db("keep waypoint %s", lastWaypointBy or "nil")
				return
			end
		end

		local autoMark = self.sv["QUEST_AUTOMARK_NEXT_WAYPOINT"]
		if autoMark == "Off" then
			return
		elseif autoMark == "Closest Quest" then
			self:TryAutoMarkNearestQuest()
		elseif autoMark == "Current Quest" then
			local tracker = GetQuestTracker()
			local tracked, journalQuestIndex
			for index = 1, tracker:GetNumTracked() do
				tracked = tracker:GetTrackedByIndex(index)
				journalQuestIndex = tracked:GetJournalIndex()
				if GetTrackedIsAssisted(TRACK_TYPE_QUEST, journalQuestIndex) then
					self:TryAutoMarkNextQuest(journalQuestIndex)
					break
				end
			end
		end
	end

	-- This was a requested feature. I should really combine this with the code below in OnQuestConditionCounterChanged
	-- so its mostly the same code, I don't have time though.
	function WaypointIt:TryAutoMarkNearestQuest()
		self:CancelCurrentTask()
		CURRENT_TASK, lastWaypointBy = nil, nil

		local considerType = QUEST_ASSIST_CONSIDER_ALL_QUESTS

		-- Apparently this returns conditions that are complete
		local foundValidCondition, journalQuestIndex, stepIndex, conditionIndex = GetNearestQuestCondition(considerType)
		local GetJournalQuestConditionInfo = GetJournalQuestConditionInfo
		local isNewConditionComplete = select(5, GetJournalQuestConditionInfo(journalQuestIndex, stepIndex, conditionIndex))

		if foundValidCondition and isNewConditionComplete then
			local numCondition = select(5, GetJournalQuestStepInfo(journalQuestIndex, stepIndex))
			for i = 1, numCondition do
				isNewConditionComplete = select(5, GetJournalQuestConditionInfo(journalQuestIndex, stepIndex, i))
				if not isNewConditionComplete then
					conditionIndex = i
					break
				end
			end
		end

		if not foundValidCondition or isNewConditionComplete then
			if GetNumJournalQuests() >= 1 then
				local fText = GetString(SI_WAYPOINTIT_NO_NEAREST_QUEST)
				db(fText)
				dw(string.format("%s%s|r", self.color.magenta, fText))
			end
			return
		end

		local function DelaySetWaypoint()
			em:UnregisterForUpdate(identifier)

			local debugText = string.format("** TryAutoMarkNearestQuest: Requesting QuestIndex: %i, StepIndex: %i, conditionIndex: %i", journalQuestIndex, stepIndex, conditionIndex)
			db(debugText)

			self:PrintNextStepText(journalQuestIndex, stepIndex, conditionIndex)

			local assisted = GetTrackedIsAssisted(TRACK_TYPE_QUEST, journalQuestIndex)
			local taskId = RequestJournalQuestConditionAssistance(journalQuestIndex, stepIndex, conditionIndex, assisted)
			if taskId then
				local sName = ZO_CachedStrFormat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, GetJournalQuestName(journalQuestIndex))
				local keyIndex = {
					[1] = journalQuestIndex,
					[2] = conditionIndex,
					[3] = stepIndex
				}
				CURRENT_TASK = {["taskId"] = taskId, ["lookupType"] = "quest", ["majorIndex"] = journalQuestIndex, ["keyIndex"] = keyIndex, ["name"] = sName}
				db("Requesting TaskId: %i", taskId)
				if tasks[taskId] then
					nextWaypoint = CURRENT_TASK
					nextWaypoint.setBy = "autoQuest"
					lastMarkQuest = GetTimeStamp()

					self:SetWaypoint(unpack(tasks[taskId]))
				end
			end

			self:ForceAssist(journalQuestIndex)
		end
		em:UnregisterForUpdate(identifier)
		em:RegisterForUpdate(identifier, 500, DelaySetWaypoint)
	end

	local function GetTaskId(self, journalQuestIndex, stepIndex, conditionIndex, assisted)
		local taskId = RequestJournalQuestConditionAssistance(journalQuestIndex, stepIndex, conditionIndex, assisted)
		if taskId then
			db("Requesting TaskId: %i", taskId)

			if CURRENT_TASK and CURRENT_TASK.setBy and CURRENT_TASK.setBy ~= "rowClick" then
				local keyIndex = CURRENT_TASK.keyIndex
				if keyIndex and keyIndex[1] == journalQuestIndex and keyIndex[2] == conditionIndex and keyIndex[3] == stepIndex then
					CURRENT_TASK.taskId = taskId
					db("New task %i", taskId)
					if HasWaypoint() then
						return taskId
					end
				end
			end

			self:PrintNextStepText(journalQuestIndex, stepIndex, conditionIndex)

			if self.sv["QUEST_AUTOMARK_NEXT_WAYPOINT"] == "Off" then
				return
			end

			local debugText = string.format("** Requesting QuestIndex: %i, StepIndex: %i, conditionIndex: %i", journalQuestIndex, stepIndex, conditionIndex)
			db(debugText)

			local sName = ZO_CachedStrFormat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, GetJournalQuestName(journalQuestIndex))
			local keyIndex = {journalQuestIndex, conditionIndex, stepIndex}
			CURRENT_TASK = {["taskId"] = taskId, ["lookupType"] = "quest", ["majorIndex"] = journalQuestIndex, ["keyIndex"] = keyIndex, ["name"] = sName}

			if tasks[taskId] then
				nextWaypoint = CURRENT_TASK
				nextWaypoint.setBy = "autoQuest"
				lastMarkQuest = GetTimeStamp()

				self:SetWaypoint(unpack(tasks[taskId]))
			end
			self:ForceAssist(journalQuestIndex)

			return taskId
		end
	end

	--[[ Used to Print out the next quest condition/step text & send a position request for the next quest step/condition location.
	--]]
	function WaypointIt:TryAutoMarkNextQuest(journalQuestIndex, mode)
		if not self.sv["QUEST_PRINT_STEPS"] and self.sv["QUEST_AUTOMARK_NEXT_WAYPOINT"] == "Off" then
			return
		end
		if gps:IsMeasuring() then
			local journalQuestIndex, mode = journalQuestIndex, mode
			local function WaitForLibGPS()
				CALLBACK_MANAGER:UnregisterCallback(gps.LIB_EVENT_STATE_CHANGED, WaitForLibGPS)
				self:TryAutoMarkNextQuest(journalQuestIndex, mode)
			end
			CALLBACK_MANAGER:RegisterCallback(gps.LIB_EVENT_STATE_CHANGED, WaitForLibGPS)
			return
		end

		self:CancelCurrentTask()

		mode = mode or self.sv["QUEST_AUTOMARK_NEXT_WAYPOINT"]

		local foundValidCondition, stepIndex, conditionIndex, newJournalQuestIndex

		if mode == "Closest Quest" then
			local considerType = QUEST_ASSIST_CONSIDER_ALL_QUESTS

			-- Apparently this returns conditions that are complete
			foundValidCondition, newJournalQuestIndex, stepIndex, conditionIndex = GetNearestQuestCondition(considerType)

			local _, _, _, _, isNewConditionComplete = GetJournalQuestConditionInfo(newJournalQuestIndex, stepIndex, conditionIndex)
			if foundValidCondition and not isNewConditionComplete then
				journalQuestIndex = newJournalQuestIndex
			else
				-- Fallback: Grab the next step in the given/current quest
				stepIndex, conditionIndex = 0, 0
			end
		else
			-- Setting must be set to mark current quest
			stepIndex, conditionIndex = 0, 0
		end

		--[[ For some reason ?? when a quest condition changes...sometimes multiple tasks get requested by the game which fires OnQuestPositionRequestComplete
			multiple times BEFORE the quest is actually updated by the game. In order to grab the correct step/condition info I MUST use a callLater to slow down
			my call so that when I request assistance It gives me the correct info instead of firing to quickly and giving me assistance on the old condition that has not yet been updated by the game.
		--]]
		local function DelaySetWaypoint()
			em:UnregisterForUpdate(identifier)

			local assisted = GetTrackedIsAssisted(TRACK_TYPE_QUEST, journalQuestIndex)
			if GetTaskId(self, journalQuestIndex, stepIndex, conditionIndex, assisted) then
				return
			end

			local numSteps = GetJournalQuestNumSteps(journalQuestIndex)
			local GetJournalQuestStepInfo = GetJournalQuestStepInfo
			for stepIndex = 1, numSteps do
				local stepText, visibility, stepType, trackerOverrideText, numConditions = GetJournalQuestStepInfo(journalQuestIndex, stepIndex)
				-- if visibility ~= QUEST_STEP_VISIBILITY_HIDDEN then
				if numConditions > 0 then
					local GetJournalQuestConditionInfo = GetJournalQuestConditionInfo
					for conditionIndex = 1, numConditions do
						local conditionText, current, max, isFailCondition, isComplete, isCreditShared = GetJournalQuestConditionInfo(journalQuestIndex, stepIndex, conditionIndex)

						if not isFailCondition and conditionText ~= "" and not isComplete then
							if GetTaskId(self, journalQuestIndex, stepIndex, conditionIndex, assisted) then
								return
							end
						end
					end
				else
					if GetTaskId(self, journalQuestIndex, stepIndex, 0, assisted) then
						return
					end
				end
				-- end
			end
			db("OnQuestConditionCounterChanged: Valid Condition not found for quest %i", journalQuestIndex)

			if HasWaypoint() then
				ZO_WorldMap_RemovePlayerWaypoint() -- Baertram, 2022-03-03, Fix WorldMap removal of waypoint so that the keybind will allow to add a new one (instead of remove a non existing)
			end
		end
		em:UnregisterForUpdate(identifier)
		em:RegisterForUpdate(identifier, 500, DelaySetWaypoint)
	end
end

-- Setup WAYPOINTIT, create all constants.
function WaypointIt:New()
	local obj = ZO_Object.New(self)
	getmetatable(obj).__index = self

	obj.name = ADDON_NAME
	obj.CodeVersion = CODE_VERSION

	-- will hold the unitTag or name of waypoint when one is set
	-- Used for keeping rows highlighted if they are selected & for
	-- tracking group pin update positions
	obj.followingUnit = nil
	obj.currentWaypoint = nil

	obj.color = {}
	obj.color.yellow = "|cFFFF00"
	obj.color.lightYellow = "|cFFFFCC"
	obj.color.green = "|c00FF00"
	obj.color.magenta = "|cFF00FF"
	obj.color.red = "|cFF0000"
	obj.color.darkOrange = "|cFFA500"
	obj.color.iconYellow = "|cFFFF33"
	obj.color.iconOrange = "|cFF6600"
	obj.color.grey = "|c626255"
	obj.color.brightOrange = "|cE68A00"

	obj.categories = {
		[MPLTYPE_POI] = {
			info = {["name"] = "POIs", ["display"] = true},
			pins = {}
		},
		[MPLTYPE_LOCATION] = {
			info = {["name"] = "Locations", ["display"] = true},
			pins = {}
		},
		[MPLTYPE_QUEST] = {
			info = {["name"] = "Quests", ["display"] = true},
			pins = {}
		},
		[MPLTYPE_AVA] = {
			info = {["name"] = "AVA", ["display"] = true},
			pins = {}
		},
		[MPLTYPE_KEEP] = {
			info = {["name"] = "Keeps", ["display"] = true},
			pins = {}
		},
		-- 	[MPLTYPE_PINGS] =
		-- 	{
		-- 		info = { ["name"] = "Pings", ["display"] = true },
		-- 		pins = { }
		-- 	},
		[MPLTYPE_KILL_LOCATION] = {
			info = {["name"] = "Kill Locations", ["display"] = true},
			pins = {}
		},
		[MPLTYPE_FAST_TRAVEL_KEEP] = {
			info = {["name"] = "Fast Travel Keep", ["display"] = true},
			pins = {}
		},
		[MPLTYPE_FAST_TRAVEL_WAYSHRINE] = {
			info = {["name"] = "WayShrines", ["display"] = true},
			pins = {}
		},
		[MPLTYPE_FORWARD_CAMP] = {
			info = {["name"] = "Forward Camps", ["display"] = true},
			pins = {}
		},
		[MPLTYPE_AVA_RESPAWN] = {
			info = {["name"] = "AVA Respawn", ["display"] = true},
			pins = {}
		},
		[MPLTYPE_GROUP] = {
			info = {["name"] = "Group", ["display"] = true},
			pins = {}
		},
		["LBooksMapPin_collected"] = {
			info = {["name"] = "Lorebooks collected", ["display"] = false},
			pins = {}
		},
		["LBooksMapPin_unknown"] = {
			info = {["name"] = "Lorebooks unknown", ["display"] = false},
			pins = {}
		},
		["SkySMapPin_collected"] = {
			info = {["name"] = "SkyShards_collected", ["display"] = false},
			pins = {}
		},
		["SkySMapPin_unknown"] = {
			info = {["name"] = "SkyShards_unknown", ["display"] = false},
			pins = {}
		},
		["HarvensCustomMapPinsType"] = {
			info = {["name"] = "Harvens Custom Pins", ["display"] = false},
			pins = {}
		},
		["HarvensHouseHunterPinType"] = {
			info = {["name"] = "Harvens House Hunter", ["display"] = false},
			pins = {}
		},
		["VotansFishermanPinType"] = {
			info = {["name"] = "Votans Fisherman", ["display"] = false},
			pins = {}
		},
		["LostTreasureMapTreasurePin"] = {
			info = {["name"] = "LostTreasure Treasure Maps", ["display"] = false},
			pins = {}
		},
		["LostTreasureCompassSurveysPin"] = {
			info = {["name"] = "LostTreasure Surveys", ["display"] = false},
			pins = {}
		},
		[MPLTYPE_OTHER] = {
			info = {["name"] = "Other", ["display"] = false},
			pins = {}
		}
	}
	obj.AddonPins = AddonPins

	obj.followList = {}
	return obj
end

-- Initialize everything else
function WaypointIt:Initialize()
	self:InitSettings()
	self:ApplyArrowSettings()

	-----------------------------------------------------
	-- Initialize handler for default to waypoint window option
	-----------------------------------------------------
	if WORLD_MAP_INFO_FRAGMENT then
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
	end

	-----------------------------------------------------
	-- Intercept Pin Manager
	-----------------------------------------------------
	self.pinManager = ZO_WorldMap_GetPinManager()
	-----------------------------------------------------

	-----------------------------------------------------
	-- Create String Bindings
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT", "WaypointIt")
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_TOGGLE_DEBUGWIN", self.color.darkOrange .. "Toggle Debug Window|r " .. self.color.magenta .. "- Set a hotkey to toggle the debug window.")
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_AUTOMARK_NEAREST_QUEST", self.color.darkOrange .. "Mark Closest Quest|r " .. self.color.magenta .. "- Set a hotkey to set a waypoint for the closest quest.")
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_AUTOMARK_FOLLOW_NEXT", self.color.darkOrange .. "Follow Next Custom Pin|r " .. self.color.magenta .. "- Set a hotkey to set a waypoint for the next custom pin in the follow list.")
	ZO_CreateStringId("SI_BINDING_NAME_WAYPOINTIT_TOGGLE_SETTING_NEXT_QUEST", self.color.darkOrange .. "Toggle next quest setting|r " .. self.color.magenta .. "- Set a hotkey to toggle the setting 'Automark Next Quest Waypoint'.")
	-----------------------------------------------------

	-----------------------------------------------------
	-- Bind windows to obj
	self.reticleWin = WaypointItReticle
	self.reticleDistance = WaypointItReticleDistance
	self.reticleTexture = WaypointItReticleTexture
	self.reticleGroupWin = WaypointItGroupReticle
	self.reticleGroupTexture = WaypointItGroupReticleTexture
	self.waypointWin = WaypointItWin
	self.waypointWinBg = WaypointItWinBg
	self.scrollList = WaypointItWinScrollList
	-----------------------------------------------------

	-- Initialize Updates for waypoint & arrow, reinstates waypoint updates
	-- between reloadUI's
	if not IsConsoleUI() then
		self:CreateWaypointsList()
	end
	-- create WaypointIt Window
	self:CreateWaypointsWindow()
	-- Setup MenuBars & fragments
	self:InitRegisterUpdates()

	-------------------------
	-- Register for Events --
	-------------------------
	self:SetupEvents()
	self:SetupQuestEvents()

	-----------------------------------------------------
end

-----------------------------------------------------
function WaypointIt:EnableCustomPin(pinTypeName)
	local category = self.categories[pinTypeName]
	if category then
		category.info.display = true
	end
end

-----------------------------------------------------
function WaypointIt:ToggleDebugWin()
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
		if HasWaypoint() then
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

-- Only pins that are inside the map boundaries will be listed, this tells us
-- if the pins coordinates are in the map boundaries.
function WaypointIt:IsNormalizedPointInsideMapBounds(x, y)
	-- NOTE: This will NEVER show a point on the edge, assuming that icons displayed there would always hang outside the map.
	return (x > 0 and x < 1 and y > 0 and y < 1)
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

-- Sets a waypoint
do
	local isZoomingOut = false
	function WaypointIt:SetWaypoint(gblX, gblY)
		if isZoomingOut or not gblX or not gblY then
			return
		end

		local changedMap = false
		local normX, normY = gps:GlobalToLocal(gblX, gblY)

		if self.sv["QUEST_ENABLE_GLOBAL_WAYPOINT"] and not self:IsNormalizedPointInsideMapBounds(normX, normY) and not isZoomingOut then
			gps:PushCurrentMap()
			changedMap = true
			isZoomingOut = true
			gps:SetMapToRootMap(gblX, gblY)
			LMP:SuppressPing(MAP_PIN_TYPE_PLAYER_WAYPOINT, pinId)
			pingSuspendCount = pingSuspendCount + 1
			normX, normY = gps:GlobalToLocal(gblX, gblY)
		end
		isZoomingOut = false
		if not self:IsNormalizedPointInsideMapBounds(normX, normY) then
			if changedMap then
				gps:PopCurrentMap()
			end
			db("outside map %fx%f", normX, normY)
			return
		end

		LMP:MutePing(MAP_PIN_TYPE_PLAYER_WAYPOINT, pinId)
		PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, normX, normY)
		if changedMap then
			gps:PopCurrentMap()
		end
		return true
	end
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

--[[ This controls the updates for the group member directional arrow (the small one inside the reticle). It is completely independent from the other directional arrow that points towards waypoints.
Unfortunately it must be called often, 50ms, for the pointer to move smoothly & stay pointed at the group member.
--]]
function WaypointIt:RunGroupWaypointUpdates(_bOn, m_Pin)
	if _bOn and self.followingUnit then
		-- Start the updates
		em:RegisterForUpdate(
			"WaypointGroupUpdates",
			50,
			function()
				local followingUnit = self.followingUnit
				if not followingUnit then
					-- No longer following anyone, stop updates
					self:RunGroupWaypointUpdates(false)
					return
				end

				-- Check to see if they still exist & if its the same person
				local followingUnitTag = followingUnit.unitTag
				local followingUnitName = followingUnit.name
				local bDoesUnitExist = DoesUnitExist(followingUnitTag)
				local unitName = GetUnitName(followingUnitTag)
				-- If not stop updates
				if not bDoesUnitExist or followingUnitName ~= unitName then
					-- Group tags can get reassigned during loading screens:
					-- allow 0.5s for OnGroupUpdate to recover correct unitTag.
					-- OnGroupUpdate will search all group units to look for name,
					-- they may still be in the group but under a different unitTag.
					-- Can't do that here, because the group may not have updated yet.
					local waiting = followingUnit.waiting or 0
					if waiting < 10 then
						followingUnit.waiting = waiting + 1
						return -- don't cancel yet
					end
					-- We've waited long enough, give up now
					followingUnit.waiting = nil
					self:RunGroupWaypointUpdates(false)
					return
				end
				-- we may have been waiting for missing unit but all good now
				followingUnit.waiting = nil

				local normX, normY = GetMapPlayerPosition(followingUnitTag)
				local rads = self:GetWaypointHeading(normX, normY)
				local heading = GetPlayerCameraHeading()
				local rotateHeading = rads + ((2 * math.pi) - heading)
				self.reticleGroupTexture:SetTextureRotation(rotateHeading)
			end
		)
		self.FRAGMENT_GROUP_DIRECTION_ARROW:SetHiddenForReason("notInUse", false)
	else
		self.FRAGMENT_GROUP_DIRECTION_ARROW:SetHiddenForReason("notInUse", true)
		em:UnregisterForUpdate("WaypointGroupUpdates")
	end
end

--[[ This controls the updates to check if/when a waypoint gets automatically removed.
Unfortunately it must be called often or a user will have trouble with waypoints not being removed because they run over/past the waypoint location before an update ticks and it would not realize they were at the waypoint.
--]]
function WaypointIt:RunWaypointRemoveUpdates(bOn, forced)
	if bOn and (forced or self.sv["AUTO_REMOVE_WAYPOINT"]) then
		db("on")
		em:RegisterForUpdate(
			"WaypointItRemoveWaypoint",
			50,
			function()
				self:CheckWaypointLoc()
			end
		)
	else
		db("off", debug.traceback())
		em:UnregisterForUpdate("WaypointItRemoveWaypoint")
	end
end

function WaypointIt:CanProcessMap()
	if not DoesUnitExist("player") then
		return false
	end
	-- cant get coordinates from the cosmic map
	if ZO_WorldMap_IsWorldMapShowing() then
		return true
	end
	if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
		CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
	end
	return GetCurrentMapId() ~= 0
end

-- ============================================================--
-- ============================================================--
-- ==== I Need to update this and combine the to registered Updates ====--
-- == For headings & CheckLoc. Theres no need to run both, they have ==--
-- == a lot of calculations in common ==--
-- ============================================================--
-- ============================================================--

--[[ This controls the updates for the directional arrow that points towards waypoints
Unfortunately it must be called often, 50ms, for the pointer to move smoothly & stay pointed at the waypoint.
--]]
do
	local distanceText = {}
	local function newDistanceText(dist)
		local text = GetString(SI_WAYPOINTIT_WAYPOINT_DISTANCE):format(dist)
		distanceText[dist] = text
		return text
	end
	function WaypointIt:GetDistanceText(dist)
		return distanceText[dist] or newDistanceText(dist)
	end
end

do
	local lastWaypointToChatOutput, lastWaypointToChatText  -- Baertram, 2023-03-03, Accessibility features

	local RunHeadingUpdates
	function WaypointIt:RunHeadingUpdates(_bOn)
		if _bOn and self.sv["WAYPOINT_DIRECTIONAL_ARROW"] then
			RunHeadingUpdates =
				RunHeadingUpdates or
				function()
					if not self:CanProcessMap() or self.FRAGMENT_DIRECTION_ARROW:IsHidden() then
						return
					end

					local rads = self:GetWaypointHeading()
					local heading = GetPlayerCameraHeading()
					local rotateHeading = rads + ((2 * math.pi) - heading)

					self.reticleTexture:SetTextureRotation(rotateHeading)

					-- If the show distance isn't turned on, return, no need to update
					---v- Baertram, 2023-03-03, Accessibility features
					local waypointReticleDistance = self.sv["WAYPOINT_RETICLE_DISTANCE"]
					local waypointChatDistance = self.sv["WAYPOINT_DISTANCE_TO_CHAT"]
					if not waypointReticleDistance and not waypointChatDistance then
						return
					end

					local iWaypointOffsetX, iWaypointOffsetY = GetMapPlayerWaypoint()
					-- coordinates get converted to global, so distances are consistent
					-- accross all maps.
					local dist = self:GetDistanceToLocalCoords(iWaypointOffsetX, iWaypointOffsetY)

					if waypointReticleDistance and self.reticleDistance.lastDistance ~= dist then
						self.reticleDistance.lastDistance = dist
						self.reticleDistance:SetText(self:GetDistanceText(dist))
					end

					if waypointChatDistance then
						local now = GetGameTimeMilliseconds()
						local waypointChatDistanceDelay = self.sv["WAYPOINT_DISTANCE_TO_CHAT_DELAY_SECONDS"] * 1000 --transfer seconds to milliseconds
						if lastWaypointToChatOutput == nil or (now >= (lastWaypointToChatOutput + waypointChatDistanceDelay)) then
							lastWaypointToChatOutput = now
							local waypointDistanceText = string.format(GetString(SI_WAYPOINTIT_WAYPOINT) .. " " .. GetString(SI_WAYPOINTIT_WAYPOINT_DISTANCE), dist)
							if lastWaypointToChatText == nil or lastWaypointToChatText ~= waypointDistanceText then
								lastWaypointToChatText = waypointDistanceText
								addChatMessageForScreenReader(SOUNDS.EDIT_CLICK, waypointDistanceText)
							end
						end
					end
					---^- Baertram, 2023-03-03, Accessibility features
				end
			em:RegisterForUpdate("WaypointItUpdateHeadingArrow", 50, RunHeadingUpdates)

			-- Setup the new heading for the texture before showing it
			local rads = self:GetWaypointHeading()
			local heading = GetPlayerCameraHeading()
			local rotateHeading = rads + ((2 * math.pi) - heading)

			self.reticleTexture:SetTextureRotation(rotateHeading)

			self.FRAGMENT_DIRECTION_ARROW:SetHiddenForReason("notInUse", false)

			local hideDistance = not self.sv["WAYPOINT_RETICLE_DISTANCE"]
			self.reticleDistance:SetHidden(hideDistance)
		else
			em:UnregisterForUpdate("WaypointItUpdateHeadingArrow")
			self.FRAGMENT_DIRECTION_ARROW:SetHiddenForReason("notInUse", true)
			self.reticleDistance:SetHidden(true)
		end
	end
end

-- RegisterUpdate function to check current loc vs waypoint loc
-- Used for Automatically removing waypoints local function CheckWaypointLoc()
function WaypointIt:CheckWaypointLoc()
	-- if not on cosmic map or we reset it to player location
	if not self:CanProcessMap() then
		return
	end

	--[[ If somehow the waypoint no longer exists...but it was not caught in the OnMapPing remove event, remove it now & stop the updates.
	There was a particular instance when this was happening, which is why I added it...but I don't remember what it was now. Maybe it was just a bug...better safe than sorry though.
	--]]
	local iWaypointOffsetX, iWaypointOffsetY = GetMapPlayerWaypoint()

	if iWaypointOffsetX == 0 and iWaypointOffsetY == 0 then
		self:RunWaypointRemoveUpdates(false)
		self:RunHeadingUpdates(false)
		self.sv.currentWaypoint = nil
		return
	end

	-- coordinates get converted to global, so distances are consistent
	-- accross all maps.
	if not self:IsWaypointOutsideOfRemovalDistance(iWaypointOffsetX, iWaypointOffsetY) then
		local waypoint = self.sv.currentWaypoint
		local setBy = waypoint and waypoint.setBy or "rowClick"

		if (setBy == "rowClick" or setBy == "autoQuest") then
			if self.sv["WAYPOINT_MESSAGES_USER_DEFINED"] or self.sv["WAYPOINT_MESSAGES_AUTO_QUEST"] then
				CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_CATECORY_SMALL_TEXT, SOUNDS.ACHIEVEMENT_AWARDED, GetString(SI_WAYPOINTIT_WAYPOINT_REACHED))
			end

			--Baertram, 2022-03-03,Accessibility chat messages for screen reader
			if self.sv["WAYPOINT_MESSAGES_USER_DEFINED_TO_CHAT"] or self.sv["WAYPOINT_MESSAGES_AUTO_QUEST_TO_CHAT"] then
				addChatMessageForScreenReader(SOUNDS.ACHIEVEMENT_AWARDED, GetString(SI_WAYPOINTIT_WAYPOINT_REACHED))
			end
		end
		if lastWaypointBy ~= "follow" or (lastWaypointBy == "follow" and not self:TryFollowNextCustomPin()) then
			ZO_WorldMap_RemovePlayerWaypoint() -- Baertram, 2022-03-03, Fix WorldMap removal of waypoint so that the keybind will allow to add a new one (instead of remove a non existing)
		end
	end
end

---- Required to get the correct heading towards waypoint.
-- function WaypointIt:UpdatePlayerPin()
-- local x, y = GetMapPlayerPosition("player")
-- local heading = GetPlayerCameraHeading()

-- self.pinManager.playerPin:SetLocation(x, y)
-- self.pinManager.playerPin:SetRotation(heading)
-- end

-- Be aware if you ever add a feature to save waypoints between maps
-- you will have trouble with saved waypoint coordinates.
-- Get the radian heading toward either the passed in coordinates or the set waypoint
function WaypointIt:GetWaypointHeading(destNormX, destNormY)
	if not destNormX then
		destNormX, destNormY = GetMapPlayerWaypoint()
	end

	-- Why did I update the player Pin & do this, instead of using GetMapPlayerPosition?
	-- I think the heading was not getting updated quick enough.
	-- What ever forced Circonian to do that in the past, it causes player pin flicker on some maps.
	-- self:UpdatePlayerPin()
	-- local playerNormX, playerNormY = self.pinManager.playerPin:GetNormalizedPosition()
	local playerNormX, playerNormY = GetMapPlayerPosition("player")

	local opp = playerNormY - destNormY
	local adj = destNormX - playerNormX
	local rads = math.atan2(opp, adj)

	rads = rads - math.pi / 2

	if rads < 0 then
		rads = rads + 2 * math.pi
	end

	return rads
end

-- Register for updates for waypoint removal and directional arrow if needed
-- Must be done to register a new RegisterForUpdate to persist through reloadUI's
function WaypointIt:InitRegisterUpdates()
	CURRENT_TASK = self.sv.currentWaypoint
	if CURRENT_TASK then
		lastWaypointBy = CURRENT_TASK.setBy
	end
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

-- Used to determine the subFilterID for POI's
local function GetSubFilterId(iZonIndex, iPOIIndex, sIconPath)
	local iCategoryId = "other"
	local poiType = GetPOIType(iZonIndex, iPOIIndex)

	if poiType == POI_TYPE_WAYSHRINE then
		iCategoryId = "fastTravelWayshrines"
	elseif poiType == POI_TYPE_GROUP_DUNGEON then
		-- this does not work:
		-- elseif IsPOIPublicDungeon(iZonIndex, iPOIIndex) then
		iCategoryId = "groupdungeons"
	elseif poiType == POI_TYPE_PUBLIC_DUNGEON then
		iCategoryId = "dungeons"
	elseif sIconPath:find("poi_portal") then
		iCategoryId = "darkanchors"
	elseif sIconPath:find("poi_groupboss") then
		iCategoryId = "groupbosses"
	elseif sIconPath:find("poi_mundus") then
		iCategoryId = "mundus"
	elseif sIconPath:find("poi_delve") then
		iCategoryId = "delves"
	end
	return iCategoryId
end

---------------------------------------------------------------
-- This section contains the AddXXXX functions which add the
-- pin data to my pin tables. It would have been quicker to only
-- do this during the rowControl setupCallback, but I need to do
-- it here because I first need to determine which subFilter/category
-- the pin belongs to (if any). While grabbing that information theres
-- no need to do it again later during the setupCallback for the rowControl
-- All data is formatted (if possible) before being stored in the table --
---------------------------------------------------------------
function WaypointIt:AddPOIPin(m_Pin)
	local majorIndex = m_Pin:GetPOIZoneIndex()
	local keyIndex = m_Pin:GetPOIIndex()
	local sIconPath = m_Pin:GetPOIIcon()
	local pinKey = self:GetPinKey(MPLTYPE_POI, majorIndex, keyIndex)
	if not pinKey then
		return
	end
	local sName, iLevel, sStartDescription, sFinishDescription = GetPOIInfo(majorIndex, keyIndex)
	local subFilterId = GetSubFilterId(majorIndex, keyIndex, sIconPath)

	sName = ZO_CachedStrFormat(SI_WORLD_MAP_LOCATION_NAME, sName)

	if iLevel == 0 then
		iLevel = nil
	end

	self.categories[MPLTYPE_POI].pins[pinKey] = {
		["m_Pin"] = m_Pin,
		["iconPath"] = sIconPath,
		["name"] = sName,
		["level"] = iLevel,
		["subFilterId"] = subFilterId,
		["pinKey"] = pinKey,
		["lookupType"] = MPLTYPE_POI,
		["poiIndex"] = keyIndex,
		["keyIndex"] = keyIndex,
		["zoneIndex"] = majorIndex,
		["majorIndex"] = majorIndex
	}
end

function WaypointIt:AddQuestPin(m_Pin)
	-- function ZO_MapPin.CreateQuestPinTag(questIndex, stepIndex, conditionIndex)
	-- return { questIndex, conditionIndex, stepIndex }
	local sIconPath = m_Pin:GetQuestIcon()
	local keyIndex = m_Pin.m_PinTag
	local iQuestIndex = keyIndex[1]
	local conditionIndex = keyIndex[2]
	local stepIndex = keyIndex[3]
	local majorIndex = iQuestIndex
	local sName = GetJournalQuestName(iQuestIndex)
	local iLevel = GetJournalQuestLevel(iQuestIndex)
	local sZoneName, objectiveName, iZoneIndex, iPoiIndex = GetJournalQuestLocationInfo(iQuestIndex)
	local pinKey = self:GetPinKey(MPLTYPE_QUEST, majorIndex, keyIndex)
	local curZoneName = ZO_CachedStrFormat(SI_ZONE_NAME, GetUnitZone("player"))
	local questZoneName = ZO_CachedStrFormat(SI_ZONE_NAME, sZoneName)
	local subFilterId = "inzone"
	local distance = nil

	sName = ZO_CachedStrFormat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, sName)

	if curZoneName ~= questZoneName then
		sName = string.format("%s%s\nQuest zone: %s|r", sName, WAYPOINTIT.color.yellow, questZoneName)
		subFilterId = "outofzone"
	end

	if iLevel == 0 then
		iLevel = nil
	end

	self.categories[MPLTYPE_QUEST].pins[pinKey] = {
		["m_Pin"] = m_Pin,
		["iconPath"] = sIconPath,
		["name"] = sName,
		["level"] = iLevel,
		["distance"] = distance,
		["subFilterId"] = subFilterId,
		["pinKey"] = pinKey,
		["questIndex"] = iQuestIndex,
		["stepIndex"] = stepIndex,
		["conditionIndex"] = conditionIndex,
		["lookupType"] = MPLTYPE_QUEST,
		["keyIndex"] = keyIndex,
		["majorIndex"] = majorIndex
	}
end

function WaypointIt:AddFastTravelWayshrinePin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local majorIndex = pinType
	local keyIndex = pinTag
	-- local bKnown, sName	 = GetFastTravelNodeInfo(pinTag[1])
	local sIconPath = pinTag[2]
	local nodeIndex = m_Pin:GetFastTravelNodeIndex()
	local bKnown, sName = GetFastTravelNodeInfo(nodeIndex)
	local pinKey = self:GetPinKey(MPLTYPE_FAST_TRAVEL_WAYSHRINE, majorIndex, keyIndex)

	sName = ZO_CachedStrFormat(SI_WORLD_MAP_LOCATION_NAME, sName)

	self.categories[MPLTYPE_FAST_TRAVEL_WAYSHRINE].pins[pinKey] = {
		["m_Pin"] = m_Pin,
		["iconPath"] = sIconPath,
		["name"] = sName,
		["pinKey"] = pinKey,
		["nodeIndex"] = nodeIndex,
		["lookupType"] = MPLTYPE_FAST_TRAVEL_WAYSHRINE,
		["keyIndex"] = keyIndex,
		["majorIndex"] = majorIndex
	}
end

function WaypointIt:AddLocationPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local sName = GetMapLocationTooltipHeader(pinTag[1])
	local iLocationIndex = m_Pin:GetLocationIndex()
	local majorIndex = iLocationIndex
	local keyIndex = iLocationIndex
	-- normalizedZ is the same thing as normalizedY...I don't know why
	-- they called it that, but I'll follow suit
	local sIconPath, normalizedX, normalizedZ = GetMapLocationIcon(iLocationIndex)

	sName = ZO_CachedStrFormat(SI_WORLD_MAP_LOCATION_NAME, sName)

	local pinKey = self:GetPinKey(MPLTYPE_LOCATION, majorIndex, keyIndex)

	self.categories[MPLTYPE_LOCATION].pins[pinKey] = {
		["m_Pin"] = m_Pin,
		["iconPath"] = sIconPath,
		["name"] = sName,
		["pinKey"] = pinKey,
		["locationIndex"] = iLocationIndex,
		["lookupType"] = MPLTYPE_LOCATION,
		["keyIndex"] = iLocationIndex,
		["majorIndex"] = iLocationIndex
	}
end

do
	local GetLoreBookInfo = GetLoreBookInfo
	function WaypointIt:AddLorebookPin(m_Pin)
		local pinType, pinTag = m_Pin:GetPinTypeAndTag()
		local lookupType = self.pinManager.customPins[pinType].pinTypeString
		local fakeLookupType = newLookupType[lookupType]

		local sTitle, sIconPath, bKnown
		if fakeLookupType == lookupType then
			-- lore book
			sTitle, sIconPath, bKnown = GetLoreBookInfo(1, pinTag[3], pinTag[4])
		else
			-- eidetic memory
			sTitle, sIconPath, bKnown = GetLoreBookInfo(3, pinTag.c, pinTag.b)
		end

		local majorIndex = pinType
		local keyIndex = pinTag
		local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

		self.categories[fakeLookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["iconPath"] = sIconPath, ["name"] = sTitle, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
		return sIconPath, sTitle, nil, nil
	end
	function WaypointIt:AddLorebookMapPins(m_Pin)
		local pinType, pinTag = m_Pin:GetPinTypeAndTag()
		local lookupType = self.pinManager.customPins[pinType].pinTypeString
		local fakeLookupType = newLookupType[lookupType]

		local categoryIndex, collectionIndex, bookIndex = unpack(pinTag)

		local sTitle, sIconPath, bKnown = GetLoreBookInfo(1, collectionIndex, bookIndex)

		local majorIndex = pinType
		local keyIndex = pinTag
		local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

		self.categories[fakeLookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["iconPath"] = sIconPath, ["name"] = sTitle, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
		return sIconPath, sTitle, nil, nil
	end
end

function WaypointIt:AddSkyshardPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local iSkyShardIndex = pinTag[4]
	local sDescription, iNumCompleted = GetAchievementCriterion(pinTag[3], iSkyShardIndex)
	local sText = zo_strformat("(<<1>>) <<2>>", iSkyShardIndex, sDescription)

	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[lookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sText, ["skyShardIndex"] = iSkyShardIndex, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = pinTag, ["majorIndex"] = pinType}
end

function WaypointIt:AddSkyshardMapPins(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local iSkyShardIndex, achievementId, criterionIndex = unpack(pinTag)

	local sDescription, iNumCompleted = GetAchievementCriterion(achievementId, criterionIndex)
	local sText = zo_strformat("(<<1>>) <<2>>", criterionIndex, sDescription)
	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[newLookupType[lookupType]].pins[pinKey] = {
		["m_Pin"] = m_Pin,
		["name"] = sText,
		["skyShardIndex"] = iSkyShardIndex,
		["pinKey"] = pinKey,
		["lookupType"] = lookupType,
		["keyIndex"] = pinTag,
		["majorIndex"] = pinType
	}
end

function WaypointIt:AddSimpleSkyshardPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local iSkyShardId = pinTag.skyId

	local sDescription = GetSkyshardHint(iSkyShardId)
	local sText = zo_strformat("<<C:1>>", sDescription)

	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[newLookupType[lookupType]].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = pinTag, ["majorIndex"] = pinType}
end
function WaypointIt:AddSimpleSkyshardDelvePin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local zoneIndex, poiIndex = unpack(pinTag)
	local iSkyShardId = GetPOISkyshardId(zoneIndex, poiIndex)
	local sDescription = GetSkyshardHint(iSkyShardId)

	local sText = zo_strformat("<<C:2>>: <<C:1>>", sDescription, GetPOIInfo(zoneIndex, poiIndex))

	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[newLookupType[lookupType]].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = pinTag, ["majorIndex"] = pinType}
end

function WaypointIt:AddHarvensPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local pinData = HarvensCustomMapPins:GetPin(pinTag)

	local sText = pinData.description

	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[lookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddHouseHunterPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local sText = pinTag[2]

	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[lookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddFisherman(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local sText = pinTag:GetText()

	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[lookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddLostTreasureTreasure(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local itemLink = LostTreasure_GetItemLinkFromItemId(pinTag.itemId)
	local sText = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))

	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local fakeLookupType = newLookupType[lookupType]
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[fakeLookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddLostTreasureSurvey(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local itemLink = LostTreasure_GetItemLinkFromItemId(pinTag.itemId)
	local sText = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))

	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local fakeLookupType = newLookupType[lookupType]
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[fakeLookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddLostTreasureTreasureMapPins(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local fakeLookupType = newLookupType[lookupType]
	local sIconPath = pinTag.texture
	local slotIndex = pinTag[2]
	local sText = ZO_CachedStrFormat(SI_TOOLTIP_ITEM_NAME, GetItemName(BAG_BACKPACK, slotIndex))
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)

	self.categories[fakeLookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["iconPath"] = sIconPath, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddAchievementMapPins(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local fakeLookupType = newLookupType[lookupType]
	local sIconPath = pinTag.texture or m_Pin.PIN_DATA[pinType].texture
	local i, achievementId, criterionIndex = unpack(pinTag)

	local sDescription, iNumCompleted = GetAchievementCriterion(achievementId, criterionIndex)
	local sText = zo_strformat("(<<1>>) <<2>> |c808080<<3>>|r", criterionIndex, sDescription, string.format("%.2fx%.2f", m_Pin.normalizedX * 100, m_Pin.normalizedY * 100))

	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)
	self.categories[fakeLookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["iconPath"] = sIconPath, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddTimeRiftsMapPins(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local fakeLookupType = newLookupType[lookupType]
	local sIconPath = m_Pin.PIN_DATA[pinType].texture
	local sText = zo_strformat("Time Rift |c808080<<1>>|r", string.format("%.2fx%.2f", m_Pin.normalizedX * 100, m_Pin.normalizedY * 100))

	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)
	self.categories[fakeLookupType].pins[pinKey] = {["m_Pin"] = m_Pin, ["iconPath"] = sIconPath, ["name"] = sText, ["pinKey"] = pinKey, ["lookupType"] = lookupType, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddQuestMapPins(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local fakeLookupType = newLookupType[lookupType]

	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)
	self.categories[fakeLookupType].pins[pinKey] = {
		["m_Pin"] = m_Pin,
		["name"] = pinTag.pinName,
		["pinKey"] = pinKey,
		["lookupType"] = lookupType,
		["keyIndex"] = keyIndex,
		["majorIndex"] = majorIndex,
		["subFilterId"] = "other"
	}
end

function WaypointIt:AddDestinationsPins(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local fakeLookupType = newLookupType[lookupType]

	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)
	self.categories[fakeLookupType].pins[pinKey] = {
		["m_Pin"] = m_Pin,
		["name"] = pinTag.objectiveName or pinTag[1] or "?",
		["iconPath"] = pinTag.texture,
		["pinKey"] = pinKey,
		["lookupType"] = lookupType,
		["keyIndex"] = keyIndex,
		["majorIndex"] = majorIndex,
		["subFilterId"] = "other"
	}
end

function WaypointIt:AddDestinationsUnknownPins(m_Pin)
	if m_Pin.normalizedX == 0 or m_Pin.normalizedY == 0 then
		return
	end

	local pinType, pinTag = m_Pin:GetPinTypeAndTag()

	local sText = pinTag.objectiveName or pinTag[1]
	if not sText or #sText == 0 then
		return
	end
	local lookupType = self.pinManager.customPins[pinType].pinTypeString
	local fakeLookupType = newLookupType[lookupType]

	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(lookupType, majorIndex, keyIndex)
	self.categories[fakeLookupType].pins[pinKey] = {
		["m_Pin"] = m_Pin,
		["name"] = string.format("%s|ca8a8a8 (%ix%i)|r", sText, m_Pin.normalizedX * 100, m_Pin.normalizedY * 100),
		["iconPath"] = pinTag.texture,
		["pinKey"] = pinKey,
		["lookupType"] = lookupType,
		["keyIndex"] = keyIndex,
		["majorIndex"] = majorIndex,
		["subFilterId"] = "other"
	}
end

function WaypointIt:AddAvAPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local majorIndex = m_Pin:GetObjectiveKeepId()
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(MPLTYPE_AVA, majorIndex, keyIndex)
	local sIconPath = m_Pin["PIN_DATA"][pinType]["texture"]
	local artifactName = GetObjectiveInfo(m_Pin:GetObjectiveKeepId(), m_Pin:GetObjectiveObjectiveId(), m_Pin:GetBattlegroundContext())

	artifactName = ZO_CachedStrFormat(SI_AVA_OBJECTIVE_DISPLAY_NAME_TOOLTIP, artifactName)

	self.categories[MPLTYPE_AVA].pins[pinKey] = {["m_Pin"] = m_Pin, ["iconPath"] = sIconPath, ["name"] = artifactName, ["pinKey"] = pinKey, ["lookupType"] = MPLTYPE_AVA, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddKeepOrDistrictPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local majorIndex = m_Pin:GetKeepId()
	local keyIndex = m_Pin:IsUnderAttackPin()
	local pinKey = self:GetPinKey(MPLTYPE_KEEP, majorIndex, keyIndex)
	local sIconPath = m_Pin["PIN_DATA"][pinType]["texture"]
	local keepId = m_Pin:GetKeepId()
	local keepName = GetKeepName(keepId)
	local alliance = GetKeepAlliance(keepId, m_Pin:GetBattlegroundContext())
	local allianceName = GetAllianceName(alliance)

	keepName = ZO_CachedStrFormat(SI_TOOLTIP_KEEP_NAME, keepName)
	allianceName = ZO_CachedStrFormat(SI_ALLIANCE_NAME, allianceName)

	self.categories["keep"].pins[pinKey] = {
		["m_Pin"] = m_Pin,
		["iconPath"] = sIconPath,
		["name"] = keepName,
		["allianceName"] = allianceName,
		["subFilterId"] = alliance,
		["keepId"] = keepId,
		["pinKey"] = pinKey,
		["lookupType"] = MPLTYPE_KEEP,
		["keyIndex"] = keyIndex,
		["majorIndex"] = majorIndex
	}
end

function WaypointIt:AddGroupPin(m_Pin)
	local majorIndex = m_Pin.m_PinType
	local keyIndex = m_Pin.m_PinTag
	local pinKey = self:GetPinKey(MPLTYPE_GROUP, majorIndex, keyIndex)
	local unitTag = m_Pin:GetUnitTag()
	local classId = GetUnitClassId(unitTag)
	local sIconPath = GetClassIcon(classId)
	local sName = GetUnitName(unitTag)
	local bIsGroupLeader = IsUnitGroupLeader(unitTag)
	local bDoesUnitExist = DoesUnitExist(unitTag)
	local bIsUnitOnline = IsUnitOnline(unitTag)

	sName = ZO_CachedStrFormat(SI_UNIT_NAME, sName)
	if bIsGroupLeader then
		sName = string.format("%s%s|r", self.color.green, sName)
	end

	--[[ Prevents offline users from being added to the group. There is an issue where some of their data will become inaccessable sometimes if they are offline (mainly if they go offline & then you go offline and come back before they do)...so we'll just exclude them if they are offline.
	--]]
	if bDoesUnitExist and bIsUnitOnline then
		self.categories["group"].pins[pinKey] = {
			["m_Pin"] = m_Pin,
			["iconPath"] = sIconPath,
			["unitTag"] = unitTag,
			["name"] = sName,
			["isGroupLeader"] = bIsGroupLeader,
			["pinKey"] = pinKey,
			["lookupType"] = MPLTYPE_GROUP,
			["keyIndex"] = keyIndex,
			["majorIndex"] = majorIndex
		}
	end
end

-- I should remove this, its not included/used, was for some testing
function WaypointIt:AddMapPingPin(m_Pin)
	local majorIndex = m_Pin.m_PinType
	local keyIndex = m_Pin.m_PinTag
	local pinKey = self:GetPinKey(MPLTYPE_PINGS, majorIndex, keyIndex)

	local sIconPath = "esoui/art/miscellaneous/help_icon.dds"
	local sName = "Unknown"

	self.categories["pings"].pins[pinKey] = {["m_Pin"] = m_Pin, ["iconPath"] = sIconPath, ["name"] = sName, ["pinKey"] = pinKey, ["lookupType"] = MPLTYPE_PINGS, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddKillLocationPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local majorIndex = pinType
	local keyIndex = pinTag
	local pinKey = self:GetPinKey(MPLTYPE_KILL_LOCATION, majorIndex, keyIndex)
	local sIconPath = m_Pin["PIN_DATA"][pinType]["texture"]

	local sName = "Kill Location"

	self.categories["killLocation"].pins[pinKey] = {["m_Pin"] = m_Pin, ["iconPath"] = sIconPath, ["name"] = sName, ["pinKey"] = pinKey, ["lookupType"] = MPLTYPE_KILL_LOCATION, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

function WaypointIt:AddFastTravelKeepPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local majorIndex = m_Pin:GetFastTravelKeepId()
	local keyIndex = m_Pin:GetFastTravelKeepId()
	local pinKey = self:GetPinKey(MPLTYPE_FAST_TRAVEL_KEEP, majorIndex, keyIndex)

	-- Must be done on a delay because the FastTravelKeep MapPins get created before
	-- the actual Keep mapPins
	zo_callLater(
		function()
			local keepName = GetKeepName(keyIndex)
			local notUnderAttackPin = false
			local existingKeepPin = self.pinManager:FindPin("keep", keyIndex, notUnderAttackPin)
			if not existingKeepPin then
				return
			end

			local battlegroundContext = existingKeepPin:GetBattlegroundContext()
			local keepPinType = GetKeepPinInfo(keyIndex, battlegroundContext)

			-- All fastTravelKeep pins can only be seen while accessing the
			keepName = ZO_CachedStrFormat(SI_TOOLTIP_KEEP_NAME, keepName)
			-- keep/wayshrine thing with the map open for selecting a place
			-- to travel to. so theres no setting waypoints. The only option is
			-- to travel to it:
			keepName = string.format("%s\n%s%s|r", keepName, self.color.darkOrange, GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_KEEP))

			self.categories["fastTravelKeep"].pins[pinKey] = {
				["m_Pin"] = existingKeepPin,
				["fastTravelKeepPin"] = m_Pin,
				["name"] = keepName,
				["pinKey"] = pinKey,
				["lookupType"] = MPLTYPE_FAST_TRAVEL_KEEP,
				["keyIndex"] = keyIndex,
				["majorIndex"] = majorIndex
			}
		end,
		50
	)
end

function WaypointIt:AddForwardCampPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local majorIndex = m_Pin.m_PinType
	local keyIndex = m_Pin.m_PinTag
	local pinKey = self:GetPinKey(MPLTYPE_FORWARD_CAMP, majorIndex, keyIndex)

	local sName = GetString(SI_TOOLTIP_FORWARD_CAMP)

	-- If they are dead, then add test that they can respawn there:
	if IsUnitDead("player") then
		sName = string.format("%s\n%s%s|r", sName, self.color.darkOrange, GetString(SI_TOOLTIP_FORWARD_CAMP_RESPAWN))
	end

	self.categories["forwardCamp"].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sName, ["pinKey"] = pinKey, ["lookupType"] = MPLTYPE_FORWARD_CAMP, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

-- I should remove this, its not included/used anymore. I could not find
-- a way to get the keepId from the AvARespawnId/pin so its useless
function WaypointIt:AddAvARespawnPin(m_Pin)
	local pinType, pinTag = m_Pin:GetPinTypeAndTag()
	local majorIndex = m_Pin.m_PinType
	local keyIndex = m_Pin.m_PinTag
	local pinKey = self:GetPinKey(MPLTYPE_AVA_RESPAWN, majorIndex, keyIndex)

	local sName = GetString(SI_WORLD_MAP_ACTION_RESPAWN_AT_KEEP)
	sName = string.format("%s\n%s%s|r", sName, self.color.darkOrange, GetString(SI_TOOLTIP_KEEP_RESPAWNABLE))

	self.categories["AvARespawn"].pins[pinKey] = {["m_Pin"] = m_Pin, ["name"] = sName, ["pinKey"] = pinKey, ["lookupType"] = MPLTYPE_AVA_RESPAWN, ["keyIndex"] = keyIndex, ["majorIndex"] = majorIndex}
end

-- Called when a mapPin is created, decides which AddXXX pin function to call
function WaypointIt:AddPin(m_Pin)
	local addPin = AddonPins[m_Pin.m_PinType]
	if addPin then
		addPin(self, m_Pin)
		return true
	elseif (m_Pin:IsPOI()) then
		self:AddPOIPin(m_Pin)
		return true
	elseif (m_Pin:IsLocation()) then
		self:AddLocationPin(m_Pin)
		return true
	elseif (m_Pin:IsQuest()) then
		self:AddQuestPin(m_Pin)
		return true
	elseif (m_Pin:IsAvAObjective()) then
		self:AddAvAPin(m_Pin)
		return true
	elseif (m_Pin:IsKeep()) then
		self:AddKeepOrDistrictPin(m_Pin)
		return true
	elseif (m_Pin:IsMapPing()) then
		-- 	self:AddMapPingPin(m_Pin)
		return false
	elseif (m_Pin:IsKillLocation()) then
		self:AddKillLocationPin(m_Pin)
		return true
	elseif (m_Pin:IsFastTravelKeep()) then
		self:AddFastTravelKeepPin(m_Pin)
		return true
	elseif (m_Pin:IsFastTravelWayShrine()) then
		self:AddFastTravelWayshrinePin(m_Pin)
		return true
	elseif (m_Pin:IsForwardCamp()) then
		self:AddForwardCampPin(m_Pin)
		return true
	elseif (m_Pin:IsAvARespawn()) then
		self:AddAvARespawnPin(m_Pin)
		return true
	elseif (m_Pin:IsGroup()) then
		self:AddGroupPin(m_Pin)
		return true
	else
		--[[ -- I'm not handling other "unknown" pins, would cause to many problems.
		--self:AddCustomPin(m_Pin)
		local majorIndex 	= self.customPins[m_Pin.m_PinType].pinTypeString
		local keyIndex 		= m_Pin.m_PinTag
		local pinKey 		= self:GetPinKey(MPLTYPE_OTHER, majorIndex, keyIndex)
		--self.categories[MPLTYPE_OTHER].pins[pinKey] = {["m_Pin"] = m_Pin, ["GetData"] = GetOtherData}
		--]]
		return false
	end
end

-- Gets the pinKey or table of keys given a lookupType, majorIndex, keyIndex
-- Used to store the mapPins in my table by the mapPin Key so when the game
-- removes a pin I can index it by pin key (not the same as keyIndex)
function WaypointIt:GetPinKey(lookupType, majorIndex, keyIndex)
	local lookupTable = self.pinManager.m_keyToPinMapping[lookupType]
	local keys = lookupTable and lookupTable[majorIndex]

	if keys then
		return keyIndex and keys[keyIndex] or keys
	end
end

-- Called from a hook on the pinManagers removePin to remove the pin(s) from
-- my own pin table.
function WaypointIt:RemovePin(lookupType, majorIndex, keyIndex)
	local lookupTable = self.categories[newLookupType[lookupType]].pins

	if majorIndex then
		local keys = self:GetPinKey(lookupType, majorIndex, keyIndex)
		if type(keys) == "table" then
			for _, pinKey in pairs(keys) do
				lookupTable[pinKey] = nil
			end
		elseif type(keys) == "number" then
			lookupTable[keys] = nil
		end
	else
		for key, pinData in pairs(lookupTable) do
			if pinData.lookupType == lookupType then
				lookupTable[key] = nil
			end
		end
	end
	if self.delayProcessing then
		self.isListDirty = true
	else
		-- Update the scrollList after pin/pins have been removed. Done on a slight delay to give the game a chance to remove all of the pins & update information. Sometimes a LOT of pins are removed (like switching maps) and it takes a few ms
		self:DelayedUpdateAll()
	end
end

function WaypointIt:HookCreatePins()
	-- Hook CreatePin so I can add the pin to my own table as well.
	local OrigCreatePin = ZO_WorldMapPins_Manager.CreatePin
	function ZO_WorldMapPins_Manager.CreatePin(...)
		local pin = OrigCreatePin(...)
		-- It can return nil for AvA pins
		if not pin then
			return
		end

		if self.delayProcessing then
			self.isListDirty = true
		else
			-- Added extra check to see if pin.SetData exists because MiniMap does
			-- not always return a mapPin. When it does this the object/pin it returns
			-- does not have SetData, but all other pins do, so if it doesn't exist it must be a call from miniMap
			if pin.IsGroup and pin.SetData then
				if self:AddPin(pin) then
					-- Update the scroll list so it has the new pin. Done on a slight delay to give the pin a chance to be created ingame & its information updated.
					self:DelayedUpdateAll()
				end
			end
		end
		return pin
	end

	-- Hook RemovePins so I can remove the pins from my pin table as well.
	local OrigRemovePins = ZO_WorldMapPins_Manager.RemovePins
	function ZO_WorldMapPins_Manager.RemovePins(pinManager, lookupType, majorIndex, keyIndex, ...)
		if self.categories[newLookupType[lookupType]] then
			self:RemovePin(lookupType, majorIndex, keyIndex)
		end
		return OrigRemovePins(pinManager, lookupType, majorIndex, keyIndex, ...)
	end

	if IsConsoleUI() then
		return
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

-- ********************************************************--
-- ********************************************************--
-- *********** Creating Menu Bars *************************--
-- ********************************************************--
-- ********************************************************--
-- Clears and adds buttons to a menu bar based on the tabFilter data passed in
-- Used to change the buttons on the menuBar
function WaypointIt:UpdateButtons(menuBar, tabFilters)
	local descriptor = ZO_MenuBar_GetSelectedDescriptor(menuBar) or 1
	ZO_MenuBar_ClearButtons(menuBar)

	for _, filterInfo in ipairs(tabFilters) do
		if not filterInfo.lookupType or self.categories[filterInfo.lookupType].info.display then
			local btn = ZO_MenuBar_AddButton(menuBar, filterInfo)
			local image = btn:GetNamedChild("Image")
			image:SetResizeToFitFile(false)
			image:SetDimensionConstraints(32, 32, 32, 32)
		end
	end
	ZO_MenuBar_SelectDescriptor(menuBar, descriptor, true, false)
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

-- Creates the actual waypoint window
function WaypointIt:CreateWaypointsWindow()
	-- This one does not need to be added to the WORLD_MAP_INFO UI scene.
	-- It gets automatically shown/hidden when you press buttons on the menu bar
	self.FRAGMENT_WINDOW = ZO_FadeSceneFragment:New(self.waypointWin, false, 0)
	-- self.FRAGMENT_WINDOW:SetAllowShowHideTimeUpdates(true)

	-- self.FRAGMENT_DIRECTION_ARROW = ZO_FadeSceneFragment:New(self.reticleWin)
	-- self.FRAGMENT_GROUP_DIRECTION_ARROW = ZO_FadeSceneFragment:New(self.reticleGroupWin)

	self.FRAGMENT_DIRECTION_ARROW = ZO_HUDFadeSceneFragment:New(self.reticleWin)
	self.FRAGMENT_GROUP_DIRECTION_ARROW = ZO_HUDFadeSceneFragment:New(self.reticleGroupWin)

	HUD_SCENE:AddFragment(self.FRAGMENT_DIRECTION_ARROW)
	HUD_SCENE:AddFragment(self.FRAGMENT_GROUP_DIRECTION_ARROW)

	self.FRAGMENT_GROUP_DIRECTION_ARROW:SetHiddenForReason("notInUse", true)
	self.FRAGMENT_DIRECTION_ARROW:SetHiddenForReason("notInUse", true)

	self:HookCreatePins()

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

-------------------------------------------------------------------
--  OnAddOnLoaded  --
-------------------------------------------------------------------
local function OnAddOnLoaded(event, addonName)
	-- These (below) are both done because I have no way of knowing which addon
	-- will be loaded first, mine or theirs.This way it doesn't matter.
	if addonName == "SkyShards" or addonName == "SimpleSkyshards" then
		WAYPOINTIT:EnableCustomPin("SkySMapPin_collected")
		WAYPOINTIT:EnableCustomPin("SkySMapPin_unknown")
	end
	if addonName == "LoreBooks" then
		WAYPOINTIT:EnableCustomPin("LBooksMapPin_collected")
		WAYPOINTIT:EnableCustomPin("LBooksMapPin_unknown")
	end
	if addonName == "HarvensCustomMapPins" then
		WAYPOINTIT:EnableCustomPin("HarvensCustomMapPinsType")
	end
	if addonName == "VotansFisherman" then
		WAYPOINTIT:EnableCustomPin("VotansFishermanPinType")
	end
	if addonName == "HarvensHouseHunter" then
		WAYPOINTIT:EnableCustomPin("HarvensHouseHunterPinType")
	end
	if addonName == "LostTreasure" then
		WAYPOINTIT:EnableCustomPin("LostTreasureMapTreasurePin")
		WAYPOINTIT:EnableCustomPin("LostTreasureCompassSurveysPin")
	end
	if addonName == "MapPins" then
		WAYPOINTIT:EnableCustomPin("LBooksMapPin_unknown")
		WAYPOINTIT:EnableCustomPin("SkySMapPin_collected")
		WAYPOINTIT:EnableCustomPin("SkySMapPin_unknown")
		WAYPOINTIT:EnableCustomPin("LostTreasureMapTreasurePin")
		WAYPOINTIT:EnableCustomPin(MPLTYPE_OTHER)
	end
	if addonName == "Destinations" then
		WAYPOINTIT:EnableCustomPin(MPLTYPE_OTHER)
	end
	if addonName == "QuestMap" then
		WAYPOINTIT_FILTER_DATA:EnableQuestMap()
	end
	if addonName == ADDON_NAME then
		WAYPOINTIT:Initialize()
		WAYPOINTIT:CreateSettingsMenu()
	end
end

WAYPOINTIT = WaypointIt:New()

ZO_CreateStringId("SI_KEYBINDINGS_CATEGORY_WAYPOINTIT", "WaypointIt")

---------------------------------------------------------------------
--  Register Events --
---------------------------------------------------------------------
em:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
