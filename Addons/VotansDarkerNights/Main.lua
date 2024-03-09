local addon = {
	name = "VotansDarkerNights",
	defaults = {},
	accountDefaults = {
		gammaNewMoonNight = 60,
		gammaFullMoonNight = 75,
		daylightRatio = 150,
		["zones"] = {
			[3] = true,
			[101] = true,
			[643] = false,
			[750] = false,
			[117] = true,
			[888] = true,
			[535] = true,
			[104] = true,
			[41] = true,
			[181] = true,
			[19] = true,
			[684] = true,
			[381] = true,
			[382] = true,
			[383] = true
		}
	}
}
local em = GetEventManager()
local igSecondsPerDay = 20955
local pulseFactor = 3

local function GammaToLinear(gamma)
	if (gamma <= 0.04045) then
		return (gamma / 12.92)
	else
		return zo_pow(zo_abs(gamma + 0.055) / 1.055, 2.4)
	end
end

local function LinearToGamma(linear)
	if (linear <= 0.0031308) then
		return (linear * 12.92)
	else
		return (1.055 * zo_pow(zo_abs(linear), 1 / 2.4) - 0.055)
	end
end

local cos, twoPi = math.cos, 2 * math.pi
local lastGamma = 0

-- In-game time from: 0<=inGameTime<1
local function GetTimeOfDay(rlTimeStamp)
	local inGameTime = (rlTimeStamp % igSecondsPerDay) / igSecondsPerDay
	return inGameTime
end

local function GetMoonPhase(rlTimeStamp)
	local igTime = (rlTimeStamp / igSecondsPerDay) - 0.5
	return (1 + cos((igTime % 30) * twoPi * 0.03333333333333333333333333333333)) * 0.5
end

local function SetGamma(gamma)
	if lastGamma ~= gamma then
		SetCVar("GAMMA_ADJUSTMENT", gamma)
		lastGamma = gamma
	end
end

local function ResetGamma()
	SetGamma(addon.account.gammaDaylight)
end

function addon:GetMapIdenfier()
	if not ZO_WorldMap_IsWorldMapShowing() and not DoesCurrentMapMatchMapForPlayerLocation() then
		if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
			CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
		end
	end
	local mapId = GetCurrentMapId()
	local zoneId, pwx1, pwh1, pwy1 = GetUnitRawWorldPosition("player")
	local _, pwx2, pwh2, pwy2 = GetUnitWorldPosition("player")
	return string.format("%i:%i:%i:%i", mapId, zoneId, math.floor((pwx1 - pwx2) / 10000 + 0.5), math.floor((pwy1 - pwy2) / 10000 + 0.5))
end

function addon:Update()
	local mapShown = ZO_WorldMap_IsWorldMapShowing()
	local id
	if mapShown then
		id = self.settings.lastZoneId
	else
		id = self:GetMapIdenfier()
		self.settings.lastZoneId = id
	end
	local exterior = self.account.zones[id]
	if exterior == nil then
		if not mapShown then
			exterior = GetMapContentType() ~= MAP_CONTENT_DUNGEON and string.match(id, ":0:0$") ~= nil
			self.account.zones[id] = exterior
		else
			return
		end
	end

	if exterior then
		local rlTimeStamp = GetTimeStamp()
		local c = (1 + cos(twoPi * GetTimeOfDay(rlTimeStamp))) * 0.5
		c = zo_pow(c, pulseFactor)
		c = 1 - c

		local x = GetMoonPhase(rlTimeStamp)

		local gammaMax = GammaToLinear(addon.account.gammaDaylight)
		local gammaMin = GammaToLinear((1 - x) * addon.account.gammaNewMoonNight + x * addon.account.gammaFullMoonNight)
		c = (gammaMax - gammaMin) * c + gammaMin
		local gamma = zo_round(LinearToGamma(c) * 10) * 0.1

		-- d(string.format("zone %s: %.2f %.2f", addon.settings.lastZoneId, x, gamma))
		SetGamma(gamma)
	else
		-- d(string.format("full gamma %s: %.2f", addon.settings.lastZoneId, addon.account.gammaDaylight))
		ResetGamma()
	end
end

local function UpdateGamma()
	addon:Update()
end

function addon:OnZoneChanged()
	self.settings.lastZoneId = self:GetMapIdenfier()
	self:Update()
end

local function ShowNightMode()
	local self = addon

	local mapId, zoneId, subZone = self.settings.lastZoneId:match("([^:]+):([^:]+):([^:]+:[^:]+)")
	mapId, zoneId = tonumber(mapId), tonumber(zoneId)
	local mapName = GetMapNameById(mapId)
	local zoneName = GetZoneNameById(zoneId)
	local name
	if subZone == "0:0" then
		if mapName == zoneName then
			CHAT_ROUTER:AddSystemMessage(zo_strformat(SI_VOTANS_DARKER_NIGHT_MODE, self.account.zones[self.settings.lastZoneId] and 2 or 1, mapName))
		else
			CHAT_ROUTER:AddSystemMessage(zo_strformat(SI_VOTANS_DARKER_NIGHT_MODE2, self.account.zones[self.settings.lastZoneId] and 2 or 1, mapName, zoneName))
		end
	else
		CHAT_ROUTER:AddSystemMessage(zo_strformat(SI_VOTANS_DARKER_NIGHT_MODE3, self.account.zones[self.settings.lastZoneId] and 2 or 1, mapName, zoneName, subZone))
	end
end

local function ToggleNight()
	local self = addon
	self.account.zones[self.settings.lastZoneId] = not self.account.zones[self.settings.lastZoneId]
	self:Update()
	ShowNightMode()
end

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Darker Nights")
	if not settings then
		return
	end
	addon.settingsControls = settings
	settings.allowDefaults = true
	settings.version = "1.1.0"
	settings.website = "http://www.esoui.com/downloads/info1558-VotansDarkerNights.html"

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = GetString(SI_VOTANS_DARKER_NIGHT_DAYLIGHT_GAMMA),
		tooltip = GetString(SI_VOTANS_DARKER_NIGHT_DAYLIGHT_GAMMA_INFO),
		min = 1,
		max = 200,
		step = 1,
		default = self.account.gamma,
		format = "%f",
		unit = "",
		getFunction = function()
			return self.account.gammaDaylight
		end,
		setFunction = function(value)
			self.account.gammaDaylight = value
			UpdateGamma()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = GetString(SI_VOTANS_DARKER_NIGHT_FULL_MOON_GAMMA),
		tooltip = GetString(SI_VOTANS_DARKER_NIGHT_FULL_MOON_GAMMA_INFO),
		min = 1,
		max = 200,
		step = 1,
		default = zo_round(self.account.gamma * 0.67),
		format = "%f",
		unit = "",
		getFunction = function()
			return self.account.gammaFullMoonNight
		end,
		setFunction = function(value)
			self.account.gammaFullMoonNight = value
			UpdateGamma()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = GetString(SI_VOTANS_DARKER_NIGHT_NEW_MOON_GAMMA),
		tooltip = GetString(SI_VOTANS_DARKER_NIGHT_NEW_MOON_GAMMA_INFO),
		min = 1,
		max = 200,
		step = 1,
		default = zo_round(self.account.gamma * 0.4),
		format = "%f",
		unit = "",
		getFunction = function()
			return self.account.gammaNewMoonNight
		end,
		setFunction = function(value)
			self.account.gammaNewMoonNight = value
			UpdateGamma()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = GetString(SI_VOTANS_DARKER_NIGHT_DAYLIGHT_TRANSITION),
		tooltip = GetString(SI_VOTANS_DARKER_NIGHT_DAYLIGHT_TRANSITION_TOOLTIP),
		min = 100,
		max = 600,
		step = 1,
		default = self.accountDefaults.daylightRatio,
		format = "%f",
		unit = "",
		getFunction = function()
			return self.account.daylightRatio
		end,
		setFunction = function(value)
			self.account.daylightRatio = value
			pulseFactor = self:SetDaylightTransitionFactor(value)
			UpdateGamma()
		end
	}
end

local function StartUpdate()
	em:RegisterForUpdate(addon.name, 15 * 1000, UpdateGamma)
end

local function StopUpdate()
	em:UnregisterForUpdate(addon.name)
end

local function HookQuit()
	local orgQuit = Quit
	function Quit()
		StopUpdate()
		ResetGamma()
		return orgQuit()
	end
end

local function HookLogout()
	local orgLogout = Logout
	function Logout()
		StopUpdate()
		ResetGamma()
		return orgLogout()
	end
	local orgCancelLogout = CancelLogout
	function CancelLogout()
		StartUpdate()
		return orgCancelLogout()
	end
end

function addon:SetDaylightTransitionFactor(daylightRatio)
	return daylightRatio * 0.02
end

function addon:Init()
	self.accountDefaults.gamma = tonumber(GetCVar("GAMMA_ADJUSTMENT"))
	self.accountDefaults.gammaDaylight = self.accountDefaults.gamma
	self.accountDefaults.gammaNewMoonNight = zo_round(self.accountDefaults.gamma * 0.55)
	self.accountDefaults.gammaFullMoonNight = zo_round(self.accountDefaults.gamma * 0.75)

	self.settings = ZO_SavedVars:NewCharacterIdSettings("VotansDarkerNights_Data", 1, nil, self.defaults)
	self.account = ZO_SavedVars:NewAccountWide("VotansDarkerNights_Data", 1, nil, self.accountDefaults)
	pulseFactor = self:SetDaylightTransitionFactor(self.account.daylightRatio)

	HookQuit()
	HookLogout()

	for zoneId, exterior in pairs(self.account.zones) do
		if tonumber(zoneId) then
			local mapId = GetMapIdByZoneId(zoneId)
			self.account.zones[zoneId] = nil
			if mapId > 0 then
				local id = string.format("%i:%i:0:0", mapId, zoneId)
				self.account.zones[id] = exterior
			end
		end
	end

	StartUpdate()

	em:RegisterForEvent(
		addon.name,
		EVENT_PLAYER_ACTIVATED,
		function()
			self.settings.lastZoneId = self:GetMapIdenfier()
			self:Update()
		end
	)
	em:RegisterForEvent(addon.name, EVENT_PLAYER_DEACTIVATED, ResetGamma)

	em:RegisterForEvent(
		addon.name,
		EVENT_ZONE_CHANGED,
		function(event, ...)
			self:OnZoneChanged(...)
		end
	)

	local delayIdentifier = self.name .. "_DelayCheck"
	local function delayCheck()
		em:UnregisterForUpdate(delayIdentifier)
		self:Update()
	end

	CALLBACK_MANAGER:RegisterCallback(
		"OnWorldMapChanged",
		function()
			em:UnregisterForUpdate(delayIdentifier)
			em:RegisterForUpdate(delayIdentifier, 50, delayCheck)
		end
	)

	SLASH_COMMANDS["/togglenight"] = ToggleNight
	SLASH_COMMANDS["/darkernightmode"] = ShowNightMode
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon:Init()
	addon:InitSettings()
end

VOTANS_DARKER_NIGHTS = addon

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
