local addon = {
	name = "VotansAdvancedSettings",
	defaults = {
		AmbientOcclusion = true,
		CharacterLighting = true,
		RainWetness = true,
		LensFlare = true,
		SimpleShaders = false,
		HighResolutionShadows = true,
		PlayerStandInsEnabled = true,
		PlayerStandInsMaxPerFrame = 8,
		SkipPregameVideos = false,
		ScreenshotFormat = "PNG",
		HorizonBasedAmbientOcclusion = false,
		TerrainShadows = true,
		Overlays = true,
		PPFXOverlays = true,
		RLS = false,
		ColorPicker = false,
		BlobShadows = true
	}
}

local WINDOW_MANAGER = GetWindowManager()
local EVENT_MANAGER = GetEventManager()
local GetSetting_Bool = GetSetting_Bool
local GetSetting = GetSetting
local SetSetting = SetSetting
local math = math

----------------------------------------
TEX_RES_CHOICE_ULTRA = -1
TEX_RES_CHOICE_ULTRA_HIGH = -2
TEX_RES_CHOICE_SUPREME = -3
TEX_RES_CHOICE_MIN_VALUE = TEX_RES_CHOICE_SUPREME

do
	local function CheckEnableApplyButton(oldValue, currentValue)
		if oldValue ~= currentValue then
			GetControl(ZO_OptionsWindow, "ApplyButton"):SetHidden(false)
		end
	end
	local function GetSettingFromControl(control)
		local data = control.data
		if data.GetSettingOverride then
			return data.GetSettingOverride(control)
		end
		return GetSetting(data.system, data.settingId)
	end
	function addon:AddTextureOptions()
		local control = Options_Video_Texture_Resolution
		local dropdownControl = GetControl(control, "Dropdown")
		local dropdown = ZO_ComboBox_ObjectFromContainer(dropdownControl)
		local valid = control.data.valid

		local function AddOption(optionTextId, optionValue)
			local optionLine =
				ZO_ComboBox:CreateItemEntry(
				GetString(optionTextId),
				function()
					local data = control.data
					local oldValueString = GetSettingFromControl(control)

					local value = data.valid[optionValue]
					local valueString = tostring(value)
					if data.SetSettingOverride then
						data.SetSettingOverride(control, valueString)
					end

					SetSetting(data.system, data.settingId, valueString)

					if data.events and data.events[value] then
						CALLBACK_MANAGER:FireCallbacks(data.events[value])
					end

					CheckEnableApplyButton(oldValueString, valueString)
				end
			)
			dropdown:AddItem(optionLine, ZO_COMBOBOX_SUPRESS_UPDATE)
		end
		valid[#valid + 1] = TEX_RES_CHOICE_ULTRA
		AddOption(SI_TEXTURERESOLUTIONCHOICE_1, #valid)
		valid[#valid + 1] = TEX_RES_CHOICE_ULTRA_HIGH
		AddOption(SI_TEXTURERESOLUTIONCHOICE_2, #valid)
		valid[#valid + 1] = TEX_RES_CHOICE_SUPREME
		AddOption(SI_TEXTURERESOLUTIONCHOICE_3, #valid)
		dropdown:UpdateItems()
	end

	ZO_CreateStringId("SI_TEXTURERESOLUTIONCHOICE_1", "Ultra")
	ZO_CreateStringId("SI_TEXTURERESOLUTIONCHOICE_2", "Ultra High")
	ZO_CreateStringId("SI_TEXTURERESOLUTIONCHOICE_3", "Supreme")
end

function addon:Init()
	self:AddTextureOptions()
end

local UserSettings = {
	MinFrameRate = "MinFrameTime.2",
	GPUSmoothingFrames = "GPUSmoothingFrames",
	HighResolutionShadows = "HIGH_RESOLUTION_SHADOWS",
	ParticleDensity = "PARTICLE_DENSITY",
	CharacterLighting = "CHARACTER_LIGHTING",
	RainWetness = "RAIN_WETNESS",
	LensFlare = "LENS_FLARE",
	PlayerStandInsEnabled = "PlayerStandInsEnabled.2",
	PlayerStandInsMaxPerFrame = "PlayerStandInsMaxPerFrame",
	SkipPregameVideos = "SkipPregameVideos",
	AmbientOcclusion = "AMBIENT_OCCLUSION",
	Bloom = "BLOOM",
	DepthOfField = "DEPTH_OF_FIELD",
	SimpleShaders = "SIMPLE_SHADERS",
	MaxAnisotropy = "MAX_ANISOTROPY",
	ScreenshotFormat = "ScreenshotFormat.2",
	HorizonBasedAmbientOcclusion = "HORIZON_BASED_AMBIENT_OCCLUSION",
	--MaxRenderObjects = "MaxRenderObjects",
	TerrainShadows = "TerrainShadowsEnabled",
	Overlays = "OverlaysEnabled",
	PPFXOverlays = "PPFXOverlaysEnabled",
	RLS = "RLSEnabled",
	ColorPicker = "COLOR_PICKER",
	BlobShadows = "BlobShadowsEnabled"
}

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Advanced Settings")
	if not settings then
		return
	end
	addon.settingsControls = settings
	settings.allowDefaults = true
	settings.version = "1.2.5"
	settings.website = "http://www.esoui.com/downloads/info1482-VotansAdvancedSettings.html"

	local function AddCheckBox(option, labelId, tooltipId)
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = labelId and GetString(labelId) or option,
			tooltip = tooltipId and GetString(tooltipId) or nil,
			default = self.defaults[option],
			getFunction = function()
				return GetCVar(UserSettings[option]) ~= "0"
			end,
			setFunction = function(value)
				SetCVar(UserSettings[option], value and "1" or "0")
			end
		}
	end

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY)
	}
	do
		local density = {}
		for i = PARTICLE_DENSITY_MIN_VALUE, PARTICLE_DENSITY_MAX_VALUE do
			density[i + 1] = {name = string.format("(%i) %s", i, GetString("SI_PARTICLEDENSITY", i)), data = i}
		end
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_PARTICLE_DENSITY),
			items = density,
			default = density[PARTICLE_DENSITY_MAX_VALUE].name,
			getFunction = function()
				return density[math.max(PARTICLE_DENSITY_MIN_VALUE, math.min(PARTICLE_DENSITY_MAX_VALUE, tonumber(GetCVar(UserSettings.ParticleDensity)))) + 1].name
			end,
			setFunction = function(combobox, name, item)
				SetCVar(UserSettings.ParticleDensity, item.data)
			end
		}
	end

	do
		local anisotropy = {}
		anisotropy[#anisotropy + 1] = {name = GetString(SI_CHECK_BUTTON_OFF), data = 0}
		for i = 1, 3 do
			anisotropy[#anisotropy + 1] = {name = string.format("x%i", i), data = i}
		end
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_MAX_ANISOTROPY),
			items = anisotropy,
			default = anisotropy[3].name,
			getFunction = function()
				return anisotropy[1 + math.max(0, math.min(3, tonumber(GetCVar(UserSettings.MaxAnisotropy))))].name
			end,
			setFunction = function(combobox, name, item)
				SetCVar(UserSettings.MaxAnisotropy, item.data)
			end
		}
	end

	do
		local function PlayerStandInsEnabled()
			return GetCVar(UserSettings.PlayerStandInsEnabled) ~= "0"
		end

		local slider
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_PLAYER_STAND_INS),
			tooltip = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_PLAYER_STAND_INS_TOOLTIP),
			default = self.defaults.PlayerStandInsEnabled,
			getFunction = PlayerStandInsEnabled,
			setFunction = function(value)
				SetCVar(UserSettings.PlayerStandInsEnabled, value and "1" or "0")
				slider:SetEnabled(not slider:IsDisabled())
			end
		}
		slider =
			settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = " |u12:0::|u" .. GetString(SI_VOTANS_ADAPTIVE_SETTINGS_STAND_INS_PER_FRAME),
			tooltip = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_STAND_INS_PER_FRAME_TOOLTIP),
			min = 1,
			max = 32,
			step = 1,
			default = self.defaults.PlayerStandInsMaxPerFrame,
			format = "%f",
			unit = "",
			getFunction = function()
				return tonumber(GetCVar(UserSettings.PlayerStandInsMaxPerFrame))
			end,
			setFunction = function(value)
				SetCVar(UserSettings.PlayerStandInsMaxPerFrame, value)
			end,
			disable = function()
				return not PlayerStandInsEnabled()
			end
		}
	end

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_FRAMERATE_LIMIT),
		tooltip = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_FRAMERATE_LIMIT_TOOLTIP),
		min = 30,
		max = 200,
		step = 1,
		default = 100,
		format = "%f",
		unit = "",
		getFunction = function()
			return zo_round(1 / tonumber(GetCVar(UserSettings.MinFrameRate)))
		end,
		setFunction = function(value)
			SetCVar(UserSettings.MinFrameRate, 1 / value)
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_GPU_SMOOTHING_FRAMES),
		tooltip = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_GPU_SMOOTHING_FRAMES_TOOLTIP),
		min = 0,
		max = 10,
		step = 1,
		default = 10,
		format = "%f",
		unit = "",
		getFunction = function()
			return tonumber(GetCVar(UserSettings.GPUSmoothingFrames))
		end,
		setFunction = function(value)
			SetCVar(UserSettings.GPUSmoothingFrames, value)
		end
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS)
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_ADVANCED_SHADERS),
		tooltip = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_ADVANCED_SHADERS_TOOLTIP),
		default = not self.defaults.SimpleShaders,
		getFunction = function()
			return GetCVar(UserSettings.SimpleShaders) ~= "1"
		end,
		setFunction = function(value)
			SetCVar(UserSettings.SimpleShaders, value and "0" or "1")
		end
	}
	-- settings:AddSetting {
	-- 	type = LibHarvensAddonSettings.ST_CHECKBOX,
	-- 	label = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_AMBIENT_OCCLUSION),
	-- 	tooltip = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_AMBIENT_OCCLUSION_TOOLTIP),
	-- 	default = self.defaults.AmbientOcclusion,
	-- 	getFunction = function() return GetCVar(UserSettings.AmbientOcclusion) ~= "0" end,
	-- 	setFunction = function(value) SetCVar(UserSettings.AmbientOcclusion, value and "1" or "0") end,
	-- }
	AddCheckBox("CharacterLighting", SI_VOTANS_ADAPTIVE_SETTINGS_CHARACTER_LIGHTING, SI_VOTANS_ADAPTIVE_SETTINGS_CHARACTER_LIGHTING_TOOLTIP)
	AddCheckBox("HighResolutionShadows", SI_VOTANS_ADAPTIVE_SETTINGS_HIGH_RESOLUTION_SHADOWS, SI_VOTANS_ADAPTIVE_SETTINGS_HIGH_RESOLUTION_SHADOWS_TOOLTIP)
	AddCheckBox("TerrainShadows", SI_VOTANS_ADAPTIVE_SETTINGS_TERRAIN_SHADOWS, SI_VOTANS_ADAPTIVE_SETTINGS_TERRAIN_SHADOWS_TOOLTIP)
	AddCheckBox("BlobShadows", SI_VOTANS_ADAPTIVE_SETTINGS_BLOB_SHADOWS, SI_VOTANS_ADAPTIVE_SETTINGS_BLOB_SHADOWS_TOOLTIP)
	AddCheckBox("LensFlare", SI_VOTANS_ADAPTIVE_SETTINGS_LENS_FLARE, SI_VOTANS_ADAPTIVE_SETTINGS_LENS_FLARE_TOOLTIP)
	AddCheckBox("RainWetness", SI_VOTANS_ADAPTIVE_SETTINGS_RAIN_WETNESS, SI_VOTANS_ADAPTIVE_SETTINGS_RAIN_WETNESS_TOOLTIP)
	--AddCheckBox(UserSettings.Overlays)
	AddCheckBox("PPFXOverlays", SI_VOTANS_ADAPTIVE_SETTINGS_PPFX_OVERLAYS, SI_VOTANS_ADAPTIVE_SETTINGS_PPFX_OVERLAYS_TOOLTIP)
	AddCheckBox("RLS", SI_VOTANS_ADAPTIVE_SETTINGS_RLS, SI_VOTANS_ADAPTIVE_SETTINGS_RLS_TOOLTIP)
	AddCheckBox("ColorPicker", SI_VOTANS_ADAPTIVE_SETTINGS_COLOR_PICKER, SI_VOTANS_ADAPTIVE_SETTINGS_COLOR_PICKER_TOOLTIP)

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_PLAYER_MENU_MISC)
	}
	AddCheckBox("SkipPregameVideos", SI_VOTANS_ADAPTIVE_SETTINGS_SKIP_PREGAME_VIDEOS, SI_VOTANS_ADAPTIVE_SETTINGS_SKIP_PREGAME_VIDEOS_TOOLTIP)
	do
		local format = {}
		local lookup = {}
		format[#format + 1] = {name = "PNG (lossless)", data = "PNG"}
		lookup["PNG"] = format[#format]
		format[#format + 1] = {name = "JPG (compressed)", data = "JPG"}
		lookup["JPG"] = format[#format]
		format[#format + 1] = {name = "BMP (lossless)", data = "BMP"}
		lookup["JPG"] = format[#format]
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_SCREENSHOT_FORMAT),
			items = format,
			default = lookup[self.defaults.ScreenshotFormat].name,
			getFunction = function()
				return (lookup[GetCVar(UserSettings.ScreenshotFormat):upper()] or lookup["PNG"]).name
			end,
			setFunction = function(combobox, name, item)
				SetCVar(UserSettings.ScreenshotFormat, item.data)
			end
		}
	end

	-- settings:AddSetting {
	-- 	type = LibHarvensAddonSettings.ST_SLIDER,
	-- 	label = UserSettings.MaxRenderObjects,
	-- 	--tooltip = GetString(SI_VOTANS_ADAPTIVE_SETTINGS_FRAMERATE_LIMIT_TOOLTIP),
	-- 	min = 0,
	-- 	max = 20000,
	-- 	step = 1,
	-- 	default = 0,
	-- 	format = "%f",
	-- 	unit = "",
	-- 	getFunction = function()
	-- 		return tonumber(GetCVar(UserSettings.MaxRenderObjects))
	-- 	end,
	-- 	setFunction = function(value)
	-- 		SetCVar(UserSettings.MaxRenderObjects, value)
	-- 	end
	-- }
end

----------------------------------------
local function Loaded(event, addOn)
	if addOn ~= addon.name then
		return
	end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon:InitSettings()
	addon:Init()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, Loaded)

VOTANS_ADVANCED_SETTINGS = addon
