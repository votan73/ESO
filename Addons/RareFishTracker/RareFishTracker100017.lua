-- Rare Fish Tracker, an ESO plug-in by katkat42
-- This plug-in alerts you when you catch a new rare fish, so you know when this happens
-- even if you have auto-loot turned on. It also displays the rare fish for the zone
-- you are in, and whether you have caught them or not.
-- This is necessary because rare fish don't actually end up in your inventory, so they
-- don't even get caught by auto-loot announcer plug-ins.

-- define some variables
local wm = GetWindowManager()
local em = GetEventManager()

if RFT == nil then
	RFT = {}
end

local RFT = RFT

RFT.fishCat = nil
RFT.fishSubCat = nil
RFT.numFishAch = nil
RFT.progress = {
	[0] = {}
}
RFT.achnames = {}
RFT.fishnames = {
	[0] = {"None"}
}
RFT.fishIcons = {
	[0] = {""}
}
RFT.settings = {}
RFT.defaults = {
	x = 20,
	y = 20,
	shown = true,
	x_world = 20,
	y_world = 120,
	apiVersion = GetAPIVersion(),
	shown_world = true
}
RFT.accountDefaults = {
	alpha = 50,
	showtitle = true,
	showzone = true,
	highlight = "Caught",
	showMunge = false,
	waterTypeAlpha = 0,
	autoShowHide = false,
	useDefaultColors = false,
	useSymbols = false,
	captionAlphaHighlighted = 100,
	captionAlphaNormal = 100,
	lockPosition = false,
	biggerFont = false,
	allowPerCharacter = false
}
local iconSize = 30
RFT.zone = ""
RFT.zones = {}
RFT.trackedAchievements = {}

-- define some business logic stuff

-- ScanAchievementsById() is run once, at load time, and scans the player's recorded fishing achievements so far.
-- cat is the number of the fishing achievements category, and num is the number of achievements in the category.
function RFT.ScanAchievementsById(id)
	RFT.progress[id] = {}
	RFT.fishnames[id] = {}
	RFT.fishIcons[id] = {}
	RFT.achnames[id] = GetAchievementInfo(id)
	local numCrit = GetAchievementNumCriteria(id)
	local giln = GetItemLinkName
	local GetItemLinkInfo = GetItemLinkInfo
	local strformat = string.format
	local progress, fishnames, itemLinks, fishIcons = RFT.progress[id], RFT.fishnames[id], RFT.achievementToItem[id], RFT.fishIcons[id]

	local desc, done, itemLink, icon
	for j = 1, numCrit, 1 do
		desc, done = RFT:GetAchievementCriterion(id, j)
		if itemLinks then
			itemLink = itemLinks[j]
			if itemLink then
				itemLink = strformat("|H1:item:%i:30:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h", itemLink)
				desc = giln(itemLink)
				icon = GetItemLinkInfo(itemLink)
			end
		end
		progress[desc] = done
		fishnames[#fishnames + 1] = desc
		fishIcons[#fishIcons + 1] = icon
	end
end

local function ShowAnnoucement(text)
	local message = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.QUEST_OBJECTIVE_INCREMENT)
	message:SetSound(SOUNDS.QUEST_OBJECTIVE_INCREMENT)
	message:SetText(text)
	message:MarkSuppressIconFrame()
	message:MarkShowImmediately()
	CENTER_SCREEN_ANNOUNCE:QueueMessage(message)
end

-- RecordProgress() is run each time a fishing achievement is updated. It figures out which
-- fish you caught within that achievement, and records it in the table.
function RFT.RecordProgress(achieveId)
	local _, _, _, icon = GetAchievementInfo(achieveId)
	local numCrit = GetAchievementNumCriteria(achieveId)

	local itemLinks, giln, GetItemLinkInfo = RFT.achievementToItem[achieveId], GetItemLinkName, GetItemLinkInfo
	local format = string.format
	for i = 1, numCrit, 1 do
		local desc, done = RFT:GetAchievementCriterion(achieveId, i)
		if itemLinks then
			local itemLink = itemLinks[i]
			if itemLink then
				itemLink = format("|H1:item:%i:30:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h", itemLink)
				desc = giln(itemLink)
				icon = GetItemLinkInfo(itemLink)
			end
		end
		if RFT.progress[achieveId][desc] ~= done then
			RFT.progress[achieveId][desc] = done
			-- Update: You can catch more than one fish (due to CPs?), even two for achievement.
			ShowAnnoucement(zo_strformat("<<1>> <<C:2>>", zo_iconFormat(icon, iconSize, iconSize), desc))
		end
	end
end

-- define some event callbacks
-- ProcessUpdate() is a callback for EVENT_ACHIEVEMENT_UDPATED, run whenever any achievement is updated.
function RFT.ProcessUpdate(event, achieveId)
	-- is the updated achievement a fishing achievement? If not, ignore.
	if RFT.trackedAchievements[achieveId] then
		-- record the results in our handy-dandy table
		RFT.RecordProgress(achieveId)
		-- update the window
		RFT.RefreshWindow()
	end
end

do
	local function getPlayerZoneId()
		return GetZoneId(GetUnitZoneIndex("player"))
	end
	local function findZoneSub(zone, searchFunc)
		local count = 4
		while not RFT.zoneToAchievement[zone] do
			if count == 0 or zone == 0 then
				return
			end
			zone = searchFunc(zone)
			count = count - 1
		end
		return zone
	end
	local function findZone(zone)
		return findZoneSub(zone, GetParentZoneId) or findZoneSub(zone, GetZoneStoryZoneIdForZoneId) or 0
	end

	function RFT.RefreshWindow()
		RFT.RefreshWindowForZone(WORLD_MAP_SCENE:IsShowing() and RFT.zone or findZone(getPlayerZoneId()))
	end

	function RFT.GetAchievementsByZoneId(zone)
		zone = findZone(zone)
		return zone, RFT.zoneToAchievement[zone] or {}
	end
	function RFT.RefreshWindowZoneChanged()
		local zone = findZone(getPlayerZoneId())
		RFT.isAutoRefresh = true
		if RFT.zone == zone then
			return
		end
		RFT.RefreshWindowForZone(zone)
	end
	function RFT.RefreshWindowMapChanged()
		local zone = findZone(WORLD_MAP_SCENE:IsShowing() and GetZoneId(GetCurrentMapZoneIndex()) or getPlayerZoneId())
		RFT.isAutoRefresh = true
		if RFT.zone == zone then
			return
		end
		RFT.RefreshWindowForZone(zone)
	end
end

do
	local identifier = "RareFishTrackerRefresh"
	local function RefreshDelay()
		em:UnregisterForUpdate(identifier, RefreshDelay)
		RFT.numCaught, RFT.numFishes = RFT.PopulateWindow(RFT.GetAchievementsByZoneId(RFT.zone))
		RARE_FISH_TRACKER_FRAGMENT:Refresh(500, 500)
	end
	function RFT.RefreshWindowForZone(zone)
		RFT.zone = zone
		-- Buffer multiple refresh requests and spread cpu load
		em:UnregisterForUpdate(identifier)
		em:RegisterForUpdate(identifier, 133, RefreshDelay)
	end
end

local function ZoneNameToIndex()
	local i = 2
	local zones = RFT.zones
	local zbn, format, GetZoneId = GetZoneNameByIndex, ZO_CachedStrFormat, GetZoneId
	local zone
	while true do
		zone = zbn(i)
		if zone == "" then
			break
		end
		zones[format("<<!A:1>>", zone)] = GetZoneId(i)
		i = i + 1
	end
end

function RFT:RescanAchievements()
	local tracked = self.trackedAchievements
	for _, achs in pairs(self.zoneToAchievement) do
		for _, ach in ipairs(achs) do
			tracked[ach] = true
			self.ScanAchievementsById(ach)
		end
	end
end

-- initialization stuff
function RFT.Init()
	-- load our saved variables
	RFT.settings = ZO_SavedVars:NewCharacterIdSettings("RareFishTrackerSavedVars", 1, nil, RFT.defaults)
	RFT.account = ZO_SavedVars:NewAccountWide("RareFishTrackerSavedVars", 1, nil, RFT.accountDefaults)
	local commonDefaults = {}
	RFT.common = ZO_SavedVars:New("RareFishTrackerSavedVars", GetAPIVersion(), nil, commonDefaults, "Default", "$Machine", "$UserProfileWide")

	RFT.common.subzoneToZone = nil

	RFT:InitCatchTracker()

	-- make our options menu
	RFT.MakeMenu()

	RFT:RescanAchievements()

	RFT.MakeWindow()

	-- and then let us know when those updates happen
	em:RegisterForEvent(
		"RareFishTracker",
		EVENT_ACHIEVEMENT_UPDATED,
		function(...)
			return RFT.ProcessUpdate(...)
		end
	)
	em:RegisterForEvent(
		"RareFishTracker",
		EVENT_ACHIEVEMENT_AWARDED,
		function(event, _, _, id)
			RFT.ProcessUpdate(event, id)
		end
	)
	CALLBACK_MANAGER:RegisterCallback(
		"OnWorldMapChanged",
		function()
			RFT.RefreshWindowMapChanged()
		end
	)

	-- also, do this last, to minimize the chance of problem zone transitions
	em:RegisterForEvent(
		"RareFishStart",
		EVENT_PLAYER_ACTIVATED,
		function()
			RFT.RefreshWindowZoneChanged(EVENT_PLAYER_ACTIVATED, nil, nil, false)
		end
	)
end

-- register to be initialized when we're ready
em:RegisterForEvent(
	"RareFishInitialize",
	EVENT_ADD_ON_LOADED,
	function(event, addon)
		if addon ~= "RareFishTracker" then
			return
		end
		em:UnregisterForEvent("RareFishInitialize", EVENT_ADD_ON_LOADED)
		RFT.Init()
	end
)
