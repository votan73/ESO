if RFT == nil then
	RFT = {}
end

local RFT = RFT

function RFT.MakeMenu()
	local set = RFT.settings
	local account = RFT.account

	local LibHarvensAddonSettings = LibHarvensAddonSettings

	local settings = LibHarvensAddonSettings:AddAddon("Rare Fish Tracker")
	if not settings then
		return
	end
	settings.allowDefaults = true
	settings.author = "katkat42 & votan"
	settings.version = "1.42.8"
	settings.website = "http://www.esoui.com/downloads/info665-RareFishTracker.html"

	local locationSettings
	local function updateLocationSettings()
		local last = nil
		for i = 1, #locationSettings do
			last = locationSettings[i]:UpdateControl(last)
		end
		-- RFT.window:SetDrawLayer(DL_BACKGROUND)
		-- RFT.window:SetDrawLevel(0)
	end
	local scene

	local function sceneStateChanged(oldState, newState)
		if newState == SCENE_HIDDEN then
			RFT.moveForWorldMap = nil
			RARE_FISH_TRACKER_FRAGMENT:Refresh()
			RFT:RestorePosition()
		end
	end

	local function addMap()
		if RFT.wasMapAdded then
			return
		end
		scene = SCENE_MANAGER:GetCurrentScene()
		scene:AddFragment(RARE_FISH_TRACKER_FRAGMENT)
		RFT.wasMapAdded = true
		RARE_FISH_TRACKER_FRAGMENT:Refresh()
		scene:RegisterCallback("StateChange", sceneStateChanged)
	end
	local function addonSelected(_, addonSettings)
		local addMap = addonSettings == settings
		if not addMap and RFT.wasMapAdded then
			scene:RemoveFragment(RARE_FISH_TRACKER_FRAGMENT)
			RFT.wasMapAdded = false
			if settings.selected then
				updateLocationSettings()
			end
			scene:UnregisterCallback("StateChange", sceneStateChanged)
			RARE_FISH_TRACKER_FRAGMENT:Refresh()
		end
	end
	CALLBACK_MANAGER:RegisterCallback("LibHarvensAddonSettings_AddonSelected", addonSelected)

	local function getScreenDimensions()
		local w, h = GuiRoot:GetDimensions()
		local w, h = w / 8, h / 8
		local w2, h2 = w * 0.5, h * 0.5
		locationSettings[2].default = math.floor(w2 * 0.5)
		locationSettings[2].min = -w2
		locationSettings[2].max = w2
		locationSettings[3].default = math.floor(h2 * 0.5)
		locationSettings[3].min = -h2
		locationSettings[3].max = h2

		locationSettings[4].default = locationSettings[2].default
		locationSettings[4].min = locationSettings[2].min
		locationSettings[4].max = locationSettings[2].max
		locationSettings[5].default = locationSettings[3].default * 2 / 3
		locationSettings[5].min = locationSettings[3].min
		locationSettings[5].max = locationSettings[3].max
		if settings.selected then
			updateLocationSettings()
		end
	end
	EVENT_MANAGER:RegisterForEvent("RareFishTracker", EVENT_ALL_GUI_SCREENS_RESIZED, getScreenDimensions)

	locationSettings =
		settings:AddSettings(
		{
			{
				type = LibHarvensAddonSettings.ST_CHECKBOX,
				label = GetString(SI_RARE_FISH_TRACKER_SHOW_IN_SETTINGS),
				default = false,
				getFunction = function()
					return RFT.wasMapAdded
				end,
				setFunction = function(value)
					if value then
						addMap()
					else
						addonSelected()
					end
				end
			},
			{
				type = LibHarvensAddonSettings.ST_SLIDER,
				label = GetString(SI_RARE_FISH_TRACKER_GRID_X),
				tooltip = GetString(SI_RARE_FISH_TRACKER_GRID_TOOLTIP),
				default = 0,
				min = -100000,
				max = 100000,
				step = 1,
				getFunction = function()
					return math.floor((set.x - GuiRoot:GetWidth() * 0.5) / 8)
				end,
				setFunction = function(value)
					set.x = value * 8 + GuiRoot:GetWidth() * 0.5
					set.right = set.x + RFT.window:GetWidth()
					RFT.moveForWorldMap = false
					RFT:RestorePosition()
					updateLocationSettings()
				end
			},
			{
				type = LibHarvensAddonSettings.ST_SLIDER,
				label = GetString(SI_RARE_FISH_TRACKER_GRID_Y),
				tooltip = GetString(SI_RARE_FISH_TRACKER_GRID_TOOLTIP),
				default = 0,
				min = -100000,
				max = 100000,
				step = 1,
				getFunction = function()
					return math.floor((set.y - GuiRoot:GetHeight() * 0.5) / 8)
				end,
				setFunction = function(value)
					set.y = value * 8 + GuiRoot:GetHeight() * 0.5
					set.bottom = set.y + RFT.window:GetHeight()
					RFT.moveForWorldMap = false
					RFT:RestorePosition()
					updateLocationSettings()
				end
			},
			{
				type = LibHarvensAddonSettings.ST_SLIDER,
				label = GetString(SI_RARE_FISH_TRACKER_GRID_X_WORLD),
				tooltip = GetString(SI_RARE_FISH_TRACKER_GRID_TOOLTIP),
				default = 0,
				min = -100000,
				max = 100000,
				step = 1,
				getFunction = function()
					return math.floor((set.x_world - GuiRoot:GetWidth() * 0.5) / 8)
				end,
				setFunction = function(value)
					set.x_world = value * 8 + GuiRoot:GetWidth() * 0.5
					set.right_world = set.x_world + RFT.window:GetWidth()
					RFT.moveForWorldMap = true
					RFT:RestorePosition()
					updateLocationSettings()
				end
			},
			{
				type = LibHarvensAddonSettings.ST_SLIDER,
				label = GetString(SI_RARE_FISH_TRACKER_GRID_Y_WORLD),
				tooltip = GetString(SI_RARE_FISH_TRACKER_GRID_TOOLTIP),
				default = 0,
				min = -100000,
				max = 100000,
				step = 1,
				getFunction = function()
					return math.floor((set.y_world - GuiRoot:GetHeight() * 0.5) / 8)
				end,
				setFunction = function(value)
					set.y_world = value * 8 + GuiRoot:GetHeight() * 0.5
					set.bottom_world = set.y_world + RFT.window:GetHeight()
					RFT.moveForWorldMap = true
					RFT:RestorePosition()
					updateLocationSettings()
				end
			}
		}
	)

	local options = {
		-- {
		-- 	type = LibHarvensAddonSettings.ST_CHECKBOX,
		-- 	label = GetString(SI_RARE_FISH_TRACKER_LOCK_POSITION),
		-- 	tooltip = GetString(SI_RARE_FISH_TRACKER_LOCK_POSITION_TOOLTIP),
		-- 	getFunction = function()
		-- 		return account.lockPosition
		-- 	end,
		-- 	setFunction = function(value)
		-- 		account.lockPosition = value
		-- 		RFT.window:SetMouseEnabled(not account.lockPosition)
		-- 	end,
		-- 	default = RFT.accountDefaults.lockPosition
		-- },
		{
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_RARE_FISH_TRACKER_WINDOW_BACKGROUND_ALPHA),
			tooltip = GetString(SI_RARE_FISH_TRACKER_WINDOW_BACKGROUND_ALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 5,
			getFunction = function()
				return account.alpha
			end,
			setFunction = function(value)
				account.alpha = value
				RFT.window.bg:SetCenterColor(0, 0, 0, account.alpha / 100)
				RFT.window.bg:SetEdgeColor(0, 0, 0, account.alpha / 100)
			end,
			default = 60
		},
		{
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_RARE_FISH_TRACKER_WATER_TYPE_BACKGROUND_ALPHA),
			tooltip = GetString(SI_RARE_FISH_TRACKER_WATER_TYPE_BACKGROUND_ALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 5,
			getFunction = function()
				return account.waterTypeAlpha
			end,
			setFunction = function(value)
				account.waterTypeAlpha = value
				local function SetupWaterType(control)
					control:SetCenterColor(0, 0, 0, account.waterTypeAlpha / 100)
					control:SetEdgeColor(0, 0, 0, account.waterTypeAlpha / 100)
				end
				local entries = RFT.window.entries
				SetupWaterType(entries.ocean.bd)
				SetupWaterType(entries.lake.bd)
				SetupWaterType(entries.river.bd)
				SetupWaterType(entries.foul.bd)
			end,
			default = 0
		},
		{
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_RARE_FISH_TRACKER_CAPTION_HIGHTLIGHTED_ALPHA),
			tooltip = GetString(SI_RARE_FISH_TRACKER_CAPTION_HIGHTLIGHTED_ALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 5,
			getFunction = function()
				return account.captionAlphaHighlighted
			end,
			setFunction = function(value)
				account.captionAlphaHighlighted = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.captionAlphaHighlighted
		},
		{
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_RARE_FISH_TRACKER_CAPTION_NORMAL_ALPHA),
			tooltip = GetString(SI_RARE_FISH_TRACKER_CAPTION_NORMAL_ALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 5,
			getFunction = function()
				return account.captionAlphaNormal
			end,
			setFunction = function(value)
				account.captionAlphaNormal = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.captionAlphaNormal
		},
		{
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString(SI_RARE_FISH_TRACKER_FISH_TO_HIGHLIGHT),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_TO_HIGHLIGHT_TOOLTIP),
			items = {{name = GetString(SI_RARE_FISH_TRACKER_CAUGHT), data = "Caught"}, {name = GetString(SI_RARE_FISH_TRACKER_UNCAUGHT), data = "Uncaught"}},
			getFunction = function()
				return account.highlight == "Caught" and GetString(SI_RARE_FISH_TRACKER_CAUGHT) or GetString(SI_RARE_FISH_TRACKER_UNCAUGHT)
			end,
			setFunction = function(combobox, name, item)
				account.highlight = item.data
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.highlight
		},
		-- {
		-- 	type = LibHarvensAddonSettings.ST_CHECKBOX,
		-- 	label = GetString(SI_RARE_FISH_TRACKER_AUTO_SHOW_HIDE_HUD),
		-- 	tooltip = GetString(SI_RARE_FISH_TRACKER_AUTO_SHOW_HIDE_HUD_TOOLTIP),
		-- 	getFunction = function()
		-- 		return account.autoShowHide
		-- 	end,
		-- 	setFunction = function(value)
		-- 		account.autoShowHide = value
		-- 		RFT.RefreshWindow()
		-- 	end,
		-- 	default = RFT.accountDefaults.autoShowHide
		-- },
		{
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_RARE_FISH_TRACKER_ALLOW_PER_CHAR),
			tooltip = GetString(SI_RARE_FISH_TRACKER_ALLOW_PER_CHAR_TOOLTIP),
			getFunction = function()
				return account.allowPerCharacter
			end,
			setFunction = function(value)
				if account.allowPerCharacter ~= value then
					account.allowPerCharacter = value
					zo_callLater(
						function()
							SLASH_COMMANDS["/reloadui"]()
						end,
						250
					)
				end
			end,
			warning = GetString(SI_RARE_FISH_TRACKER_RELOADUI),
			default = RFT.accountDefaults.allowPerCharacter
		},
		{
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_RARE_FISH_TRACKER_SHOW_HUD),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_SHOW_HUD_TOOLTIP),
			getFunction = function()
				return set.shown
			end,
			setFunction = function(value)
				set.shown = value
				RFT.RefreshWindow()
			end,
			default = RFT.defaults.shown
		},
		{
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_RARE_FISH_TRACKER_SHOW_WORLD_MAP),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_SHOW_WORLD_MAP_TOOLTIP),
			getFunction = function()
				return set.shown_world
			end,
			setFunction = function(value)
				set.shown_world = value
				RFT.RefreshWindow()
			end,
			default = RFT.defaults.shown
		},
		{
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_RARE_FISH_TRACKER_SHOW_MUNGE),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_SHOW_MUNGE_TOOLTIP),
			getFunction = function()
				return account.showMunge
			end,
			setFunction = function(value)
				account.showMunge = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.showMunge
		},
		{
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_RARE_FISH_TRACKER_USE_DEFAULT_COLORS),
			tooltip = GetString(SI_RARE_FISH_TRACKER_USE_DEFAULT_COLORS_TOOLTIP),
			getFunction = function()
				return account.useDefaultColors
			end,
			setFunction = function(value)
				account.useDefaultColors = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.useDefaultColors
		},
		{
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_RARE_FISH_TRACKER_SHOW_TITLE),
			tooltip = GetString(SI_RARE_FISH_TRACKER_SHOW_TITLE_TOOLTIP),
			getFunction = function()
				return account.showtitle
			end,
			setFunction = function(value)
				account.showtitle = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.showtitle
		},
		{
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_RARE_FISH_TRACKER_SHOW_ZONE),
			tooltip = GetString(SI_RARE_FISH_TRACKER_SHOW_ZONE_TOOLTIP),
			getFunction = function()
				return account.showzone
			end,
			setFunction = function(value)
				account.showzone = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.showzone
		},
		{
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_RARE_FISH_TRACKER_USE_SYMBOLS),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_USE_SYMBOLS_TOOLTIP),
			getFunction = function()
				return account.useSymbols
			end,
			setFunction = function(value)
				account.useSymbols = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.useSymbols
		},
		{
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_RARE_FISH_TRACKER_BIGGER_FONT),
			tooltip = GetString(SI_RARE_FISH_TRACKER_BIGGER_FONT_TOOLTIP),
			getFunction = function()
				return account.biggerFont
			end,
			setFunction = function(value)
				account.biggerFont = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.biggerFont
		}
	}

	settings:AddSettings(options)

	getScreenDimensions()
end
