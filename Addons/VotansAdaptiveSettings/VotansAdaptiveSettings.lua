local addon = {
	name = "VotansAdaptiveSettings",
	fps_1 = 60,
	fps = 120,
	fps_stabilzed = 120,
	ui_hidden = false,
	inCombat = false,
	fps_target = 120,
	defaults = {
		normal = 58,
		combat = 59,
		hidden = 20,
		minDistanceCombat = 0.5625,
		minDistance = 0.725,
		maxDistance = 2,
		touchDistortion = true,
		touchGodRays = true,
		touchAntiAlias = true,
		touchParticleDistance = true,
		touchClutter = false,
		framedropWeight = 6,
		speed = 30,
		showViewDistance = true,
		activated = true,
		loadingBurstDelay = 4
	},
	viewDistance = tonumber(GetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_VIEW_DISTANCE)),
	suspended = true
}

local WINDOW_MANAGER = GetWindowManager()
local EVENT_MANAGER = GetEventManager()
local PERFORMANCE_METERS = PERFORMANCE_METERS
local GetSetting_Bool = GetSetting_Bool
local GetSetting = GetSetting
local SetSetting = SetSetting
local math = math

local function ViewDistance()
	return zo_round((addon.viewDistance - 0.4) * 62.5)
end

function addon:SetupMeter()
	local bg = PERFORMANCE_METERS.control:GetNamedChild("Bg")

	local frameString = GetString(SI_FRAMERATE_METER_FORMAT)
	local baseSetFramerate = PERFORMANCE_METERS.SetFramerate
	local stringActive, stringSuspended = {}, {}
	for viewDistance = 1, 100 do
		stringSuspended[viewDistance] = string.format("%s\194\160|t32:32:esoui/art/icons/poi/poi_areaofinterest_incomplete.dds:inheritColor|t|cffffff%i|r", frameString, viewDistance)
		stringActive[viewDistance] = string.format("%s\194\160|t32:32:esoui/art/icons/poi/poi_areaofinterest_complete.dds:inheritColor|t|cffffff%i|r", frameString, viewDistance)
	end
	function addon:GetViewDistanceText()
		local viewDistance = ViewDistance()
		return self.suspended and stringSuspended[viewDistance] or stringActive[viewDistance]
	end
	function PERFORMANCE_METERS:SetFramerate(...)
		if addon.lastDistance ~= addon.viewDistance then
			if addon.settings.showViewDistance and addon.viewDistance and addon.settings.activated then
				SafeAddString(SI_FRAMERATE_METER_FORMAT, addon:GetViewDistanceText(), 2)
			else
				SafeAddString(SI_FRAMERATE_METER_FORMAT, frameString, 2)
			end
			addon.lastDistance = addon.viewDistance
		end
		return baseSetFramerate(self, ...)
	end
	function PERFORMANCE_METERS:UpdateVisibility()
		local framerateOn = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_FRAMERATE)
		local latencyOn = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_LATENCY)
		local anyOn = framerateOn or latencyOn
		if anyOn then
			self.framerateControl:ClearAnchors()
			self.latencyControl:ClearAnchors()
			local active = addon.settings.showViewDistance and addon.settings.activated
			if active then
				self.framerateLabel:SetWidth(120)
				self.framerateControl:SetWidth(120)
			else
				self.framerateLabel:SetWidth(65)
				self.framerateControl:SetWidth(65)
			end

			if framerateOn and latencyOn then
				self.framerateControl:SetAnchor(TOPLEFT, self.control, TOPLEFT, 20, 15)
				self.latencyControl:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, -20, 15)
				self.control:SetWidth(self.framerateControl:GetWidth() + self.latencyControl:GetWidth() + 40)
			else
				self.framerateControl:SetAnchor(CENTER, self.control, CENTER, 0, 0)
				self.latencyControl:SetAnchor(CENTER, self.control, CENTER, 0, 0)
				self.control:SetWidth((framerateOn and self.framerateControl:GetWidth() or self.latencyControl:GetWidth()) + 40)
			end
			self.framerateControl:SetHidden(not framerateOn)
			self.latencyControl:SetHidden(not latencyOn)
			bg:SetWidth(self.control:GetWidth() * 1.48)
			bg:SetAnchor(CENTER, nil, CENTER)
		end
		PERFORMANCE_METER_FRAGMENT:SetHiddenForReason("AnyOn", not anyOn, 0, 0)
		self:OnUpdate()
	end
	function addon:UpdateVisibility()
		PERFORMANCE_METERS:UpdateVisibility()
	end
end

function addon:SetupMeterWithInfoPanel()
	local stringActive, stringSuspended = {}, {}
	for viewDistance = 1, 100 do
		stringSuspended[viewDistance] = string.format("|t32:32:esoui/art/icons/poi/poi_areaofinterest_incomplete.dds:inheritColor|t|cffffff%i|r", viewDistance)
		stringActive[viewDistance] = string.format("|t32:32:esoui/art/icons/poi/poi_areaofinterest_complete.dds:inheritColor|t|cffffff%i|r", viewDistance)
	end
	function addon:GetViewDistanceText()
		local viewDistance = ViewDistance()
		return self.suspended and stringSuspended[viewDistance] or stringActive[viewDistance]
	end
	function addon:UpdateVisibility()
	end
end

local function SetShowViewDistance(value)
	addon.settings.showViewDistance = value
	addon.lastDistance = -1
	addon:UpdateVisibility()
end

local function StartTimer(delay)
	local self = addon
	local function DelayMeasure()
		self.suspended = false
		EVENT_MANAGER:UnregisterForUpdate(self.FrameTimer)
		EVENT_MANAGER:RegisterForUpdate(self.FrameTimer, 100, self.Timer)
	end

	self.inCombat = IsUnitInCombat("player")
	SetShowViewDistance(self.settings.showViewDistance)
	EVENT_MANAGER:UnregisterForUpdate(self.FrameTimer)
	if self.settings.activated then
		self.lastDistance = -1
		local settings = self.settings
		self.viewDistance = math.min(math.max(1.2, (settings.minDistance + settings.maxDistance) * 0.5), settings.maxDistance)
		self:GetTargetFrameRate()
		self.fps_1 = self.fps_target
		self.fps = self.fps_target
		self.clutter = tonumber(GetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_CLUTTER_2D_QUALITY))
		self.clutter_1 = self.clutter
		self.AdaptSettings()
		EVENT_MANAGER:RegisterForUpdate(self.FrameTimer, delay, DelayMeasure)
	end
end

function addon.PlayerActivated()
	StartTimer(addon.settings.loadingBurstDelay * 1000)
end

function addon.PlayerDeactivated()
	local self = addon
	self.suspended = true
	self.lastDistance = -1
	-- EVENT_MANAGER:UnregisterForUpdate(self.FrameTimer)
end

local lastTime = 0
function addon.Timer(currentTime)
	local self = addon
	if self.suspended then
		return
	end
	if lastTime < currentTime then
		lastTime = currentTime
		self.MeasureFrameRate()
	end
	self.AdaptSettings()
end

do
	local useDoorAction = GetString(SI_GAMECAMERAACTIONTYPE13)
	local SI_GAME_CAMERA_TARGET = GetString(SI_GAME_CAMERA_TARGET)
	local rawActionToAction = {}
	local function AddAction(action)
		local newAction = LocalizeString(SI_GAME_CAMERA_TARGET, action)
		rawActionToAction[action] = newAction
		return newAction
	end

	function addon:StartInteraction(...)
		local action = GetGameCameraInteractableActionInfo()
		if action then
			local actionName = rawActionToAction[action] or AddAction(action)
			if actionName == useDoorAction then
				self.PlayerActivated()
			end
		end
	end
end

local function HookStartInteraction(...)
	addon:StartInteraction(...)
	return addon.orgStartInteraction(...)
end

function addon:Init()
	if self.InfoPanelLoaded then
		self:SetupMeterWithInfoPanel()
	else
		self:SetupMeter()
	end
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GUI_HIDDEN, self.UI_Hidden_Changed)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, self.PlayerCombatState_Changed)

	self.FrameTimer = addon.name .. "FPS"

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, self.PlayerActivated)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_DEACTIVATED, self.PlayerDeactivated)

	local manager = FISHING_MANAGER or INTERACTIVE_WHEEL_MANAGER
	self.orgStartInteraction = manager.StartInteraction
	-- This is called when interacting with things
	manager.StartInteraction = HookStartInteraction
	StartTimer(0)
end

function addon:GetTargetFrameRate()
	if self.inCombat then
		self.fps_target = self.settings.combat
	elseif self.ui_hidden then
		self.fps_target = self.settings.hidden
	else
		self.fps_target = self.settings.normal
	end
	self.fps_target = self.fps_target - 0.05
end

do
	local lastDistance, lastClutter = -1, -1
	local function applySetting(settingId, distance, threshold, onValue)
		if distance < threshold then
			if GetSetting(SETTING_TYPE_GRAPHICS, settingId) ~= "0" then
				SetSetting(SETTING_TYPE_GRAPHICS, settingId, "0", DONT_SAVE_CURRENT_VALUES)
			end
		else
			threshold = (1.45 + threshold) * 0.5
			if distance >= threshold then
				if GetSetting(SETTING_TYPE_GRAPHICS, settingId) ~= onValue then
					SetSetting(SETTING_TYPE_GRAPHICS, settingId, onValue, DONT_SAVE_CURRENT_VALUES)
				end
			end
		end
	end
	local function restoreSetting(settingId, distance, threshold)
		if distance < threshold then
			local value = GetSetting(SETTING_TYPE_GRAPHICS, settingId)
			if value ~= "0" then
				addon.previousValues[settingId] = value
				SetSetting(SETTING_TYPE_GRAPHICS, settingId, "0", DONT_SAVE_CURRENT_VALUES)
			end
		else
			threshold = (1.45 + threshold) * 0.5
			if distance >= threshold then
				local value = GetSetting(SETTING_TYPE_GRAPHICS, settingId)
				local onValue = value == "0" and addon.previousValues[settingId] or value
				if value ~= onValue then
					SetSetting(SETTING_TYPE_GRAPHICS, settingId, onValue, DONT_SAVE_CURRENT_VALUES)
				end
			end
		end
	end
	function addon.AdaptSettings()
		-- if WINDOW_MANAGER:IsSecureRenderModeEnabled() then return end

		local self = addon

		local distance = self.viewDistance

		local diff = 1 + (math.min(0, (self.fps - self.fps_1) * self.settings.framedropWeight * 0.5) + self.fps - self.fps_target) / self.settings.speed
		local newdistance = distance * diff
		if newdistance > distance then
			-- 32 = 1024/32
			newdistance = math.floor((distance * 31 + newdistance) * 32 + 0.5) / 1024
		else
			-- 250 = 1000/4
			newdistance = math.floor((distance * 3 + newdistance) * 250 + 0.5) / 1000
		end
		local min = self.inCombat and self.settings.minDistanceCombat or self.settings.minDistance
		local max = self.settings.maxDistance
		newdistance = math.max(min, math.min(max, newdistance))
		self.viewDistance = newdistance
		newdistance = math.floor(newdistance * 256) / 256

		if newdistance ~= lastDistance then
			lastDistance = newdistance
			distance = newdistance

			SetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_VIEW_DISTANCE, newdistance, DONT_SAVE_CURRENT_VALUES)
			if self.settings.touchParticleDistance then
				newdistance = newdistance - 0.4
				newdistance = math.floor(newdistance * newdistance * newdistance * 18.310546875 + 25)
				SetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_PFX_SUPPRESS_DISTANCE, newdistance, DONT_SAVE_CURRENT_VALUES)
			end

			if self.settings.touchDistortion then
				applySetting(GRAPHICS_SETTING_DISTORTION, distance, 1.4, "1")
			end
			if self.settings.touchGodRays then
				applySetting(GRAPHICS_SETTING_GOD_RAYS, distance, 1.0, "1")
			end
			if self.settings.touchAntiAlias then
				applySetting(GRAPHICS_SETTING_ANTI_ALIASING, distance, 0.8, "1")
			end
		end
		if self.settings.touchClutter then
			self.clutter_1 = self.clutter
			local quality = distance * 2
			self.clutter = self.clutter_1 * 0.995 + quality * 0.005
			quality = math.min(4, math.floor(self.clutter + 0.5))
			if lastClutter ~= quality then
				SetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_CLUTTER_2D_QUALITY, quality, DONT_SAVE_CURRENT_VALUES)
				lastClutter = quality
			end
		end
	end
end

-- Mode relevant functions --
function addon.UI_Hidden_Changed(eventCode, guiName, hidden)
	if guiName == "ingame" then
		addon.ui_hidden = hidden
		addon:GetTargetFrameRate()
	end
end

function addon.PlayerCombatState_Changed(event, inCombat)
	addon.inCombat = inCombat
	addon:GetTargetFrameRate()
	addon.AdaptSettings()
end

function addon.MeasureFrameRate()
	addon.fps_1 = addon.fps
	local fps = GetFramerate()
	fps = math.floor(fps * 1000 - 0.5) / 1000
	addon.fps = fps
end

----------------------------------------
local function ToggleShowViewDistance()
	SetShowViewDistance(not addon.settings.showViewDistance)
	if addon.settingsControls.selected then
		addon.settingsControls:UpdateControls()
	end
end
-- For key-binding
addon.ToggleShowViewDistance = ToggleShowViewDistance

function addon.SetAdjustViewDistance(value)
	local self = addon
	self.settings.activated = value
	if value then
		StartTimer(500)
	else
		self.PlayerDeactivated()
		self.lastDistance = -1
		addon:UpdateVisibility()
	end
end

function addon.ToggleAdjustViewDistance()
	addon.SetAdjustViewDistance(not addon.settings.activated)
	if addon.settingsControls.selected then
		addon.settingsControls:UpdateControls()
	end
end

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Adaptive Settings")
	if not settings then
		return
	end
	addon.settingsControls = settings
	settings.version = "1.5.7"
	settings.website = "http://www.esoui.com/downloads/info1239-VotansAdaptiveVideo-Settings.html"
	settings.allowDefaults = true

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Auto View Distance",
		tooltip = "Enable/disable automation without reloading UI.",
		default = self.defaults.activated,
		getFunction = function()
			return self.settings.activated
		end,
		setFunction = self.SetAdjustViewDistance
	}
	settings:AddSettings(
		{
			{
				type = LibHarvensAddonSettings.ST_SLIDER,
				label = "Normal Minimum Framerate",
				tooltip = "Try to keep framerate above this value during normal activity.",
				min = 2,
				max = 150,
				step = 1,
				format = "%f",
				unit = "fps",
				default = self.defaults.normal,
				getFunction = function()
					return self.settings.normal
				end,
				setFunction = function(value)
					self.settings.normal = value
					self:GetTargetFrameRate()
				end
			},
			{
				type = LibHarvensAddonSettings.ST_SLIDER,
				label = "Combat Minimum Framerate",
				tooltip = "Try to keep framerate above this value during combat.",
				min = 2,
				max = 150,
				step = 1,
				format = "%f",
				unit = "fps",
				default = self.defaults.combat,
				getFunction = function()
					return self.settings.combat
				end,
				setFunction = function(value)
					self.settings.combat = value
					self:GetTargetFrameRate()
				end
			}
		},
		{
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = "UI Hidden Minimum Framerate",
			tooltip = "Try to keep framerate above this value while UI is hidden, e.g. for nice screenshots.",
			min = 2,
			max = 100,
			step = 1,
			format = "%f",
			unit = "fps",
			default = self.defaults.hidden,
			getFunction = function()
				return self.settings.hidden
			end,
			setFunction = function(value)
				self.settings.hidden = value
				self:GetTargetFrameRate()
			end
		}
	)
	local sliders
	local function sliderUpdate(index, value)
		local slider = sliders[index]
		if slider.control then
			slider.control:GetNamedChild("Slider"):SetValue(value)
		end
	end
	sliders =
		settings:AddSettings(
		{
			{
				type = LibHarvensAddonSettings.ST_SLIDER,
				label = "Minimum View Distance",
				tooltip = "View distance is not reduced below this minimum.",
				min = 1,
				max = 100,
				step = 1,
				format = "%f",
				unit = "",
				default = zo_floor(((self.defaults.minDistance - 0.4) * 62.5) + 0.5),
				getFunction = function()
					return zo_round((self.settings.minDistance - 0.4) * 62.5)
				end,
				setFunction = function(value)
					self.settings.minDistance = zo_round((value / 62.5 + 0.4) * 1000 + 0.5) / 1000
					if self.settings.maxDistance < self.settings.minDistance then
						self.settings.maxDistance = self.settings.minDistance
						sliderUpdate(3, (self.settings.maxDistance - 0.4) * 62.5)
					end
					self:GetTargetFrameRate()
				end
			},
			{
				type = LibHarvensAddonSettings.ST_SLIDER,
				label = "Minimum View Distance Combat",
				tooltip = "View distance is not reduced below this minimum during combat.",
				min = 1,
				max = 100,
				step = 1,
				format = "%f",
				unit = "",
				default = zo_floor(((self.defaults.minDistanceCombat - 0.4) * 62.5) + 0.5),
				getFunction = function()
					return zo_round((self.settings.minDistanceCombat - 0.4) * 62.5)
				end,
				setFunction = function(value)
					self.settings.minDistanceCombat = zo_round((value / 62.5 + 0.4) * 1000 + 0.5) / 1000
					if self.settings.maxDistance < self.settings.minDistanceCombat then
						self.settings.maxDistance = self.settings.minDistanceCombat
						sliderUpdate(3, (self.settings.maxDistance - 0.4) * 62.5)
					end
					self:GetTargetFrameRate()
				end
			},
			{
				type = LibHarvensAddonSettings.ST_SLIDER,
				label = "Maximum View Distance",
				tooltip = "View distance is not raised above this maximum.",
				min = 1,
				max = 100,
				step = 1,
				format = "%f",
				unit = "",
				default = zo_floor(((self.defaults.maxDistance - 0.4) * 62.5) + 0.5),
				getFunction = function()
					return zo_round((self.settings.maxDistance - 0.4) * 62.5)
				end,
				setFunction = function(value)
					self.settings.maxDistance = zo_round((value / 62.5 + 0.4) * 1000 + 0.5) / 1000
					if self.settings.minDistance > self.settings.maxDistance then
						self.settings.minDistance = self.settings.maxDistance
						sliderUpdate(1, (self.settings.minDistance - 0.4) * 62.5)
					end
					self:GetTargetFrameRate()
				end
			}
		}
	)
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = "Behavior"
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Adjustment Speed",
		tooltip = "At higher speed, the system may overreact to short drops. At lower speed, the system may react too late, but less dramatic.",
		min = 10,
		max = 60,
		step = 1,
		format = "%f",
		unit = "",
		default = self.defaults.speed,
		getFunction = function()
			return 60 - self.settings.speed
		end,
		setFunction = function(value)
			self.settings.speed = 60 - value
			self:GetTargetFrameRate()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Framedrop Weight",
		tooltip = "To prevend falling below threshold before adjusting view distance, the algorithm can react to changing framerate as an indicator of upcoming graphic load.\n0 = off\n1 = very gentle\n8 = aggressive\n12 = very aggressive",
		min = 0,
		max = 12,
		step = 1,
		format = "%f",
		unit = "",
		default = self.defaults.framedropWeight,
		getFunction = function()
			return self.settings.framedropWeight
		end,
		setFunction = function(value)
			self.settings.framedropWeight = value
			self:GetTargetFrameRate()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Loading Burst Suspend Delay",
		tooltip = "Suspend operation after loading screen to overcome activity burst.",
		min = 1,
		max = 20,
		step = 1,
		default = self.defaults.loadingBurstDelay,
		unit = "s",
		getFunction = function()
			return self.settings.loadingBurstDelay
		end,
		setFunction = function(value)
			self.settings.loadingBurstDelay = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Show view distance in frame meter",
		tooltip = "Shows the current view distance (12-100) beside current frame rate.",
		getFunction = function()
			return self.settings.showViewDistance
		end,
		setFunction = SetShowViewDistance
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Touch Particle Distance",
		tooltip = "Allow to change particle distance.",
		default = true,
		getFunction = function()
			return self.settings.touchParticleDistance
		end,
		setFunction = function(value)
			self.settings.touchParticleDistance = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Touch Distorsion",
		tooltip = "Allow to change Distorsion. (Hot air above flames)",
		default = true,
		getFunction = function()
			return self.settings.touchDistortion
		end,
		setFunction = function(value)
			self.settings.touchDistortion = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Touch God Rays",
		tooltip = "Allow to change God Rays. (Beams from sun and other bright light sources)",
		default = true,
		getFunction = function()
			return self.settings.touchGodRays
		end,
		setFunction = function(value)
			self.settings.touchGodRays = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Touch Antialiasing",
		tooltip = "Allow to change Antialiasing. (Smoothing edges)",
		default = true,
		getFunction = function()
			return self.settings.touchAntiAlias
		end,
		setFunction = function(value)
			self.settings.touchAntiAlias = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Touch Grass",
		tooltip = "Allow to change grass quality.",
		default = false,
		getFunction = function()
			return self.settings.touchClutter
		end,
		setFunction = function(value)
			self.settings.touchClutter = value
		end
	}
end

----------------------------------------
local function Loaded(event, addOn)
	if addOn ~= addon.name then
		if addOn == "InfoPanel" then
			addon.InfoPanelLoaded = true
		end
		return
	end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.settings = ZO_SavedVars:NewAccountWide("VotansAdaptiveSettings_Data", 1, nil, addon.defaults)
	VotansAdaptiveSettings_Data.previousValues = VotansAdaptiveSettings_Data.previousValues or {}
	addon.previousValues = VotansAdaptiveSettings_Data.previousValues

	addon:InitSettings()
	addon:Init()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, Loaded)

VOTANS_ADAPTIVE_SETTINGS = addon
