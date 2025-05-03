if RFT == nil then
	RFT = {}
end

local RFT = RFT

function RFT.MakeMenu()
	local menu = LibAddonMenu2
	local set = RFT.settings
	local account = RFT.account

	local panel = {
		type = "panel",
		name = "Rare Fish Tracker",
		displayName = "Rare Fish Tracker",
		author = "katkat42 & votan",
		version = "1.42.6",
		registerForRefresh = true,
		registerForDefaults = true,
		slashCommand = "/rft",
		website = "http://www.esoui.com/downloads/info665-RareFishTracker.html"
	}

	local options = {
		-- {
		-- 	type = "header",
		-- 	name = GetString(SI_RARE_FISH_TRACKER_WINDOW_SETTINGS),
		-- },
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_LOCK_POSITION),
			tooltip = GetString(SI_RARE_FISH_TRACKER_LOCK_POSITION_TOOLTIP),
			getFunc = function()
				return account.lockPosition
			end,
			setFunc = function(value)
				account.lockPosition = value
				RFT.window:SetMouseEnabled(not account.lockPosition)
			end,
			default = RFT.accountDefaults.lockPosition
		},
		{
			type = "slider",
			name = GetString(SI_RARE_FISH_TRACKER_WINDOW_BACKGROUND_ALPHA),
			tooltip = GetString(SI_RARE_FISH_TRACKER_WINDOW_BACKGROUND_ALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 5,
			getFunc = function()
				return account.alpha
			end,
			setFunc = function(value)
				account.alpha = value
				RFT.window.bg:SetCenterColor(0, 0, 0, account.alpha / 100)
				RFT.window.bg:SetEdgeColor(0, 0, 0, account.alpha / 100)
			end,
			default = 60
		},
		{
			type = "slider",
			name = GetString(SI_RARE_FISH_TRACKER_WATER_TYPE_BACKGROUND_ALPHA),
			tooltip = GetString(SI_RARE_FISH_TRACKER_WATER_TYPE_BACKGROUND_ALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 5,
			getFunc = function()
				return account.waterTypeAlpha
			end,
			setFunc = function(value)
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
			type = "slider",
			name = GetString(SI_RARE_FISH_TRACKER_CAPTION_HIGHTLIGHTED_ALPHA),
			tooltip = GetString(SI_RARE_FISH_TRACKER_CAPTION_HIGHTLIGHTED_ALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 5,
			getFunc = function()
				return account.captionAlphaHighlighted
			end,
			setFunc = function(value)
				account.captionAlphaHighlighted = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.captionAlphaHighlighted
		},
		{
			type = "slider",
			name = GetString(SI_RARE_FISH_TRACKER_CAPTION_NORMAL_ALPHA),
			tooltip = GetString(SI_RARE_FISH_TRACKER_CAPTION_NORMAL_ALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 5,
			getFunc = function()
				return account.captionAlphaNormal
			end,
			setFunc = function(value)
				account.captionAlphaNormal = value
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.captionAlphaNormal
		},
		{
			type = "dropdown",
			name = GetString(SI_RARE_FISH_TRACKER_FISH_TO_HIGHLIGHT),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_TO_HIGHLIGHT_TOOLTIP),
			choices = {GetString(SI_RARE_FISH_TRACKER_CAUGHT), GetString(SI_RARE_FISH_TRACKER_UNCAUGHT)},
			getFunc = function()
				return account.highlight == "Caught" and GetString(SI_RARE_FISH_TRACKER_CAUGHT) or GetString(SI_RARE_FISH_TRACKER_UNCAUGHT)
			end,
			setFunc = function(value)
				account.highlight = value == GetString(SI_RARE_FISH_TRACKER_CAUGHT) and "Caught" or "Uncaught"
				RFT.RefreshWindow()
			end,
			default = RFT.accountDefaults.highlight
		},
		-- {
		-- 	type = "checkbox",
		-- 	name = GetString(SI_RARE_FISH_TRACKER_AUTO_SHOW_HIDE_HUD),
		-- 	tooltip = GetString(SI_RARE_FISH_TRACKER_AUTO_SHOW_HIDE_HUD_TOOLTIP),
		-- 	getFunc = function()
		-- 		return account.autoShowHide
		-- 	end,
		-- 	setFunc = function(value)
		-- 		account.autoShowHide = value
		-- 		RFT.RefreshWindow()
		-- 	end,
		-- 	width = "half",
		-- 	default = RFT.accountDefaults.autoShowHide
		-- },
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_ALLOW_PER_CHAR),
			tooltip = GetString(SI_RARE_FISH_TRACKER_ALLOW_PER_CHAR_TOOLTIP),
			getFunc = function()
				return account.allowPerCharacter
			end,
			setFunc = function(value)
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
			width = "half",
			warning = GetString(SI_RARE_FISH_TRACKER_RELOADUI),
			default = RFT.accountDefaults.allowPerCharacter
		},
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_SHOW_HUD),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_SHOW_HUD_TOOLTIP),
			getFunc = function()
				return set.shown
			end,
			setFunc = function(value)
				set.shown = value
				RFT.RefreshWindow()
			end,
			width = "half",
			default = RFT.defaults.shown
		},
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_SHOW_WORLD_MAP),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_SHOW_WORLD_MAP_TOOLTIP),
			getFunc = function()
				return set.shown_world
			end,
			setFunc = function(value)
				set.shown_world = value
				RFT.RefreshWindow()
			end,
			width = "half",
			default = RFT.defaults.shown
		},
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_SHOW_MUNGE),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_SHOW_MUNGE_TOOLTIP),
			getFunc = function()
				return account.showMunge
			end,
			setFunc = function(value)
				account.showMunge = value
				RFT.RefreshWindow()
			end,
			width = "half",
			default = RFT.accountDefaults.showMunge
		},
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_USE_DEFAULT_COLORS),
			tooltip = GetString(SI_RARE_FISH_TRACKER_USE_DEFAULT_COLORS_TOOLTIP),
			getFunc = function()
				return account.useDefaultColors
			end,
			setFunc = function(value)
				account.useDefaultColors = value
				RFT.RefreshWindow()
			end,
			width = "half",
			default = RFT.accountDefaults.useDefaultColors
		},
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_SHOW_TITLE),
			tooltip = GetString(SI_RARE_FISH_TRACKER_SHOW_TITLE_TOOLTIP),
			getFunc = function()
				return account.showtitle
			end,
			setFunc = function(value)
				account.showtitle = value
				RFT.RefreshWindow()
			end,
			width = "half",
			default = RFT.accountDefaults.showtitle
		},
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_SHOW_ZONE),
			tooltip = GetString(SI_RARE_FISH_TRACKER_SHOW_ZONE_TOOLTIP),
			getFunc = function()
				return account.showzone
			end,
			setFunc = function(value)
				account.showzone = value
				RFT.RefreshWindow()
			end,
			width = "half",
			default = RFT.accountDefaults.showzone
		},
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_USE_SYMBOLS),
			tooltip = GetString(SI_RARE_FISH_TRACKER_FISH_USE_SYMBOLS_TOOLTIP),
			getFunc = function()
				return account.useSymbols
			end,
			setFunc = function(value)
				account.useSymbols = value
				RFT.RefreshWindow()
			end,
			width = "half",
			default = RFT.accountDefaults.useSymbols
		},
		{
			type = "checkbox",
			name = GetString(SI_RARE_FISH_TRACKER_BIGGER_FONT),
			tooltip = GetString(SI_RARE_FISH_TRACKER_BIGGER_FONT_TOOLTIP),
			getFunc = function()
				return account.biggerFont
			end,
			setFunc = function(value)
				account.biggerFont = value
				RFT.RefreshWindow()
			end,
			width = "half",
			default = RFT.accountDefaults.biggerFont
		}
	}

	menu:RegisterAddonPanel("RareFish", panel)
	menu:RegisterOptionControls("RareFish", options)
end
