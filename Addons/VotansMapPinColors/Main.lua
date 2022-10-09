local addon = {
	name = "VotansMapPinColors",
	accountDefaults = {
		showPlayerPin = true,
		vibratePlayerPin = false,
		questColor = "b76f6f",
		questAssistedColor = "6fb76f",
		playerColor = "6bf5f4",
		locationColor = "e2e2e2",
		questRepeatableColor = "6fb0b8",
		poiColor = "ffffff",
		questAssisted = "FFFFFF",
		preferAssisted = false,
		travelColor = "ffffff",
		houseColor = "ffffff",
		delveColor = "ffffff"
	}
}

local am = GetAnimationManager()
local em = GetEventManager()

function addon:ApplySettings()
	local settings = self.account

	if not self.VotansGroupPins then
		ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_PLAYER].tint = self.playerColor
	else
		settings.playerColor = VOTANS_GROUPPINS.account.simplePlayerColor
	end
	local pin = ZO_WorldMap_GetPinManager():GetPlayerPin()
	pin:SetData(pin:GetPinTypeAndTag())
end

do
	local updateIdentifier = "VOTANS_MAP_PIN_UPDATE"
	local function DelayedUpdate()
		em:UnregisterForUpdate(updateIdentifier)
		addon:ApplySettings()
	end

	function addon:InitDelayedUpdate()
		em:UnregisterForUpdate(updateIdentifier)
		em:RegisterForUpdate(updateIdentifier, 100, DelayedUpdate)
	end
end
function addon:UpdatePlayerPinAlpha()
	self.playerColor:SetAlpha(self.account.showPlayerPin and 1 or 0)
	self:ApplySettings()
end

function addon:InitializePlayerPin()
	local pin = ZO_WorldMap_GetPinManager():GetPlayerPin()

	local function createAnim()
		local control = pin:GetControl()
		local anim = am:CreateTimelineFromVirtual("ZO_RadialCountdownTimerPulse", control)
		pin.votanPulseTimeline = anim
		anim:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, 5)
		anim:GetAnimation(1):SetEndScale(1.8)
		anim:GetAnimation(2):SetStartScale(1.8)
		return anim
	end
	local function playPulse()
		if self.account.showPlayerPin and self.account.vibratePlayerPin then
			(pin.votanPulseTimeline or createAnim()):PlayFromStart()
		end
	end
	local function WorldMapStateChanged(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWN then
			playPulse()
		end
	end
	WORLD_MAP_SCENE:RegisterCallback("StateChange", WorldMapStateChanged)
	GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", WorldMapStateChanged)
	CALLBACK_MANAGER:RegisterCallback(
		"OnWorldMapChanged",
		function()
			if ZO_WorldMap_IsWorldMapShowing() then
				playPulse()
			end
		end
	)
	ZO_PreHook(
		pin,
		"PingMapPin",
		function(pin, anim)
			return not self.account.showPlayerPin
		end
	)
end

function addon:Initialize()
	local function GetColor(c)
		local r = ZO_ColorDef:New(c)
		r:SetAlpha(1)
		return r
	end
	self.account = ZO_SavedVars:NewAccountWide("VotansMapPinColors_Data", 1, nil, self.accountDefaults)

	self.poiColor = GetColor(self.account.poiColor)
	self.locationColor = GetColor(self.account.locationColor)
	self.questColor = GetColor(self.account.questColor)
	self.travelColor = GetColor(self.account.travelColor)
	self.houseColor = GetColor(self.account.houseColor)
	self.delveColor = GetColor(self.account.delveColor)

	self.questRepeatableColor = GetColor(self.account.questRepeatableColor)
	self.questAssistedColor = GetColor(self.account.questAssistedColor)

	-- HookGroupManager()

	if not addon.VotansGroupPins then
		self.playerColor = GetColor(self.account.playerColor)
		ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_PLAYER].texture = "VotansMapPinColors/art/Pointer1.dds"
	else
		self.account.playerColor = VOTANS_GROUPPINS.account.simplePlayerColor
		self.playerColor = GetColor(self.account.playerColor)
		VOTANS_GROUPPINS.simplePlayerColor = self.playerColor
		local orgInitDelayedUpdate = VOTANS_GROUPPINS.InitDelayedUpdate
		function VOTANS_GROUPPINS.InitDelayedUpdate(...)
			self.playerColor = VOTANS_GROUPPINS.simplePlayerColor
			self:UpdatePlayerPinAlpha()
			return orgInitDelayedUpdate(...)
		end
	end
	self:UpdatePlayerPinAlpha()

	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_LOCATION].tint = self.locationColor
	SetPinTint(MAP_PIN_TYPE_LOCATION, self.locationColor:UnpackRGB())

	self:SetPoiColor()
	self:SetQuestColor()
	self:SetQuestRepeatableColor()
	self:SetQuestAssistedRepeatableColor()
	self:SetAssistedQuestColor()
	self:SetFastTravelColor()
	self:InitializePlayerPin()
	self:ApplySettings()
end

function addon:SetPoiColor()
	local function GetPOIPinTint(pin)
		if pin:IsLockedByLinkedCollectible() then
			return LOCKED_COLOR
		else
			local pinType, pinTag = pin:GetPinTypeAndTag()
			local r, g, b = self.poiColor:UnpackRGB()
			local p1, p2, p3 = unpack(pinTag)
			SetPinTint(pinType, r, g, b, p1 - 1)
			return self.poiColor
		end
	end
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_POI_SEEN].tint = GetPOIPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_POI_COMPLETE].tint = GetPOIPinTint
end

local function SetQuestPinTint(pin, color)
	-- local pinType = pin:GetPinTypeAndTag()
	-- local r, g, b = color:UnpackRGB()
	-- local questIndex, stepIndex, conditionIndex = pin:GetQuestData()
	-- SetPinTint(pinType, r, g, b, questIndex, stepIndex, conditionIndex)
	-- SetPinTint(MAP_PIN_TYPE_QUEST_INTERACT, r, g, b, questIndex, stepIndex, conditionIndex)
	-- local container = COMPASS.container
	-- local value = container:GetMinVisibleAlpha(pinType)
	-- container:SetMinVisibleAlpha(pinType, value - 0.01)
	-- container:SetMinVisibleAlpha(pinType, value)
end

function addon:SetQuestColor()
	local function GetQuestPinTint(pin)
		SetQuestPinTint(pin, self.questColor)
		return self.questColor
	end

	if MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION then
		ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION].tint = GetQuestPinTint
		ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION].tint = GetQuestPinTint
		ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_ENDING].tint = GetQuestPinTint
	end

	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_TRACKED_QUEST_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_TRACKED_QUEST_ENDING].tint = GetQuestPinTint

	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_QUEST_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_QUEST_ENDING].tint = GetQuestPinTint
end

function addon:SetQuestRepeatableColor()
	local function GetQuestPinTint(pin)
		SetQuestPinTint(pin, self.questRepeatableColor)
		return self.questRepeatableColor
	end

	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_ENDING].tint = GetQuestPinTint

	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_QUEST_REPEATABLE_ENDING].tint = GetQuestPinTint
end

function addon:SetQuestAssistedRepeatableColor()
	local function GetQuestPinTint(pin)
		if self.account.preferAssisted then
			SetQuestPinTint(pin, self.questAssistedColor)
			return self.questAssistedColor
		else
			SetQuestPinTint(pin, self.questRepeatableColor)
			return self.questRepeatableColor
		end
	end

	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING].tint = GetQuestPinTint
end

function addon:SetAssistedQuestColor()
	local function GetQuestPinTint(pin)
		SetQuestPinTint(pin, self.questAssistedColor)
		return self.questAssistedColor
	end

	if MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION then
		ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION].tint = GetQuestPinTint
		ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION].tint = GetQuestPinTint
		ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING].tint = GetQuestPinTint
	end

	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION].tint = GetQuestPinTint
	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_ASSISTED_QUEST_ENDING].tint = GetQuestPinTint
end

function addon:SetFastTravelColor()
	local delves = function()
		return self.delveColor
	end
	local colors = {
		["/esoui/art/icons/poi/poi_wayshrine_complete.dds"] = function()
			return self.travelColor
		end,
		["/esoui/art/icons/poi/poi_group_house_owned.dds"] = function()
			return self.houseColor
		end,
		["/esoui/art/icons/poi/poi_group_house_unowned.dds"] = function()
			return self.houseColor
		end,
		["/esoui/art/icons/poi/poi_groupinstance_incomplete.dds"] = delves,
		["/esoui/art/icons/poi/poi_groupinstance_complete.dds"] = delves,
		["/esoui/art/icons/poi/poi_raiddungeon_incomplete.dds"] = delves,
		["/esoui/art/icons/poi/poi_raiddungeon_complete.dds"] = delves,
		["/esoui/art/icons/poi/poi_solotrial_incomplete.dds"] = delves,
		["/esoui/art/icons/poi/poi_solotrial_complete.dds"] = delves
	}
	local function fromTexture(pin)
		local texture = ZO_MapPin.PIN_DATA[pin:GetPinType()].texture(pin) or ""
		texture = colors[texture]
		return texture and texture()
	end
	local function hookTint(pinType)
		local org_tint = ZO_MapPin.PIN_DATA[pinType].tint
		local function GetTravelPinTint(pin)
			local orgColor = type(org_tint) == "function" and org_tint(pin) or org_tint
			return orgColor == LOCKED_COLOR and orgColor or fromTexture(pin) or orgColor
		end
		ZO_MapPin.PIN_DATA[pinType].tint = GetTravelPinTint
	end
	hookTint(MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE)
	hookTint(MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC)
end

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Map Pin Colors")
	if not settings then
		return
	end
	addon.settingsControls = settings
	settings.version = "1.2.3"
	settings.allowDefaults = true
	settings.website = "http://www.esoui.com/downloads/info1843-VotansMapPinColors.html"

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANS_MAPPIN_COLORS_SHOW_PLAYER_PIN),
		tooltip = GetString(SI_VOTANS_MAPPIN_COLORS_SHOW_PLAYER_PIN_TOOLTIP),
		default = true,
		getFunction = function()
			return self.account.showPlayerPin
		end,
		setFunction = function(value)
			self.account.showPlayerPin = value
			self:UpdatePlayerPinAlpha()
			self:InitDelayedUpdate()
		end
	}
	if not self.VotansGroupPins then
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_COLOR,
			label = " |u12:0::|u" .. GetString(SI_PLAYER_MENU_PLAYER),
			getFunction = function()
				return self.playerColor:UnpackRGB()
			end,
			setFunction = function(newR, newG, newB, newA)
				self.playerColor = ZO_ColorDef:New(newR, newG, newB, 1)
				self:UpdatePlayerPinAlpha()
				self.account.playerColor = self.playerColor:ToHex()
				self:InitDelayedUpdate()
			end,
			default = {ZO_ColorDef:New(self.accountDefaults.playerColor):UnpackRGB()}
		}
	else
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_COLOR,
			label = string.format(" |u12:0::|u%s (Votan's Group Pins)", GetString(SI_PLAYER_MENU_PLAYER)),
			getFunction = function()
				self.account.playerColor = VOTANS_GROUPPINS.account.simplePlayerColor
				return VOTANS_GROUPPINS.simplePlayerColor:UnpackRGB()
			end,
			setFunction = function(newR, newG, newB, newA)
				self.playerColor = ZO_ColorDef:New(newR, newG, newB, 1)
				self.account.playerColor = self.playerColor:ToHex()
				self:UpdatePlayerPinAlpha()
				VOTANS_GROUPPINS.simplePlayerColor = ZO_ColorDef:New(newR, newG, newB, 1)
				VOTANS_GROUPPINS.account.simplePlayerColor = VOTANS_GROUPPINS.simplePlayerColor:ToHex()
				VOTANS_GROUPPINS:InitDelayedUpdate()
			end,
			default = {ZO_ColorDef:New(VOTANS_GROUPPINS.account.simplePlayerColor):UnpackRGB()}
		}
	end
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = " |u12:0::|u" .. GetString(SI_VOTANS_MAPPIN_COLORS_PLAYER_PIN_VIBRATION),
		tooltip = GetString(SI_VOTANS_MAPPIN_COLORS_PLAYER_PIN_VIBRATION_TOOLTIP),
		default = false,
		getFunction = function()
			return self.account.vibratePlayerPin
		end,
		setFunction = function(value)
			self.account.vibratePlayerPin = value
		end
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = "POI",
		getFunction = function()
			return addon.poiColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.poiColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.poiColor = addon.poiColor:ToHex()
			ZO_WorldMap_UpdateMap()
		end,
		default = {ZO_ColorDef:New(self.accountDefaults.poiColor):UnpackRGB()}
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_MAP_INFO_MODE_LOCATIONS),
		getFunction = function()
			return addon.locationColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.locationColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.locationColor = addon.locationColor:ToHex()
			ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_LOCATION].tint = self.locationColor
			ZO_WorldMap_UpdateMap()
		end,
		default = {ZO_ColorDef:New(self.accountDefaults.locationColor):UnpackRGB()}
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_MAPFILTER8),
		getFunction = function()
			return addon.travelColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.travelColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.travelColor = addon.travelColor:ToHex()
			ZO_WorldMap_RefreshWayshrines()
		end,
		default = {ZO_ColorDef:New(self.accountDefaults.travelColor):UnpackRGB()}
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES604),
		getFunction = function()
			return addon.houseColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.houseColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.houseColor = addon.houseColor:ToHex()
			ZO_WorldMap_RefreshWayshrines()
		end,
		default = {ZO_ColorDef:New(self.accountDefaults.houseColor):UnpackRGB()}
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKCATEGORIES10),
		getFunction = function()
			return addon.delveColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.delveColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.delveColor = addon.delveColor:ToHex()
			ZO_WorldMap_RefreshWayshrines()
		end,
		default = {ZO_ColorDef:New(self.accountDefaults.delveColor):UnpackRGB()}
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_MAP_INFO_MODE_QUESTS)
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_COMPASSACTIVEQUESTSCHOICE2),
		getFunction = function()
			return addon.questAssistedColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.questAssistedColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.questAssistedColor = addon.questAssistedColor:ToHex()
			self:InitDelayedUpdate()
		end,
		default = {ZO_ColorDef:New(self.accountDefaults.questAssistedColor):UnpackRGB()}
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_FURNITURETHEMETYPE1),
		getFunction = function()
			return addon.questColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.questColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.questColor = addon.questColor:ToHex()
			self:InitDelayedUpdate()
		end,
		default = {ZO_ColorDef:New(self.accountDefaults.questColor):UnpackRGB()}
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_QUEST_JOURNAL_REPEATABLE_TEXT),
		getFunction = function()
			return addon.questRepeatableColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.questRepeatableColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.questRepeatableColor = addon.questRepeatableColor:ToHex()
			self:InitDelayedUpdate()
		end,
		default = {ZO_ColorDef:New(self.accountDefaults.questRepeatableColor):UnpackRGB()}
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANS_MAPPIN_COLORS_PREFER_ASSISTED),
		tooltip = GetString(SI_VOTANS_MAPPIN_COLORS_PREFER_ASSISTED_TOOLTIP),
		default = false,
		getFunction = function()
			return self.account.preferAssisted
		end,
		setFunction = function(value)
			self.account.preferAssisted = value
		end
	}
end

-- do
-- local function UpdateControls()
-- 	if addon.settingsControls.selected then
-- 		addon.settingsControls:UpdateControls()
-- 	end
-- end
-- function addon.ToggleShowHUD()
-- 	local self = addon
-- 	self.account.showHUD = not self.account.showHUD
-- 	self:UpdateVisibility()
-- 	UpdateControls()
-- end
-- function addon.ToggleShowCombat()
-- 	local self = addon
-- 	self.account.showCombat = not self.account.showCombat
-- 	self:UpdateVisibility()
-- 	UpdateControls()
-- end
-- end

local function OnAddonLoaded(event, name)
	if name == "VotansGroupPins" then
		addon.VotansGroupPins = true
	end
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:Initialize()
	addon:InitSettings()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_MAP_PIN_COLORS = addon
