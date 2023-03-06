
local LAM2 = LibAddonMenu2

local colorYellow = "|cFFFF00" 	-- yellow 
local colorRed = "|cFF0000" 	-- Red
local colorDrkOrange = "|cFFA500"	-- Dark Orange

do
	local style = {
		["Dot 1"] = "WaypointIt/Textures/ReticleArrow_Dot1.dds",
		["Dot 2"] = "WaypointIt/Textures/ReticleArrow_Dot2.dds",
		["Ring 1"] = "WaypointIt/Textures/ReticleArrow_Ring1.dds",
		["Rune 1"] = "WaypointIt/Textures/ReticleArrow_Rune1.dds",
	}

	function WaypointIt:ApplyArrowSettings()
		WaypointItReticleTexture:SetColor(self.pointerColor:UnpackRGBA())
		WaypointItGroupReticleTexture:SetColor(self.groupColor:UnpackRGBA())

		local texture = style[self.sv.ARROW_STYLE] or "WaypointIt/Textures/ReticleArrow_Pointer2.dds"
		WaypointItReticleTexture:SetTexture(texture)
	end
end

function WaypointIt:InitSettings()
	local defaultSavedVars = {
		["WAYPOINT_WINDOW"] = true,
		["WAYPOINT_WINDOW_OFFSETX"] = 100,
		["WAYPOINT_WINDOW_OFFSETY"] = 100,
		["WAYPOINT_DELTA_SCALE"] = 3,
		["WAYPOINT_DELTA_SCALE_MAX"] = 5000,
		["WAYPOINT_DIRECTIONAL_ARROW"] = true,

		["AUTO_REMOVE_WAYPOINT"] = true,
		["WAYPOINT_DISTANCE_WARNING"] = true,
		["WAYPOINT_MESSAGES_USER_DEFINED"] = true,
		["WAYPOINT_MESSAGES_AUTO_QUEST"] = false,
		["WAYPOINT_DIRECTIONAL_ARROW"] = true,
		["WAYPOINT_HIDE_ARROW_INCOMBAT"] = true,
		["WAYPOINT_HIDE_ARROW_GROUP"] = false,
		["WAYPOINT_HIDE_GROUP_ARROW_INCOMBAT"] = true,
		["WAYPOINT_RETICLE_DISTANCE"] = false,
		["WAYPOINT_WINDOW_NAME_DISTANCE"] = false,
		["WAYPOINT_DISTANCEIN_METERS"] = true,

		--Baertram, 2023-03-03 - Accessibility setings: Output as text to chat for Accessibility screen reader
		["WAYPOINT_DISTANCE_TO_CHAT"] = false,
		["WAYPOINT_DISTANCE_TO_CHAT_DELAY_SECONDS"] = 5,
		["WAYPOINT_MESSAGES_USER_DEFINED_TO_CHAT"] = false,
		["WAYPOINT_MESSAGES_AUTO_QUEST_TO_CHAT"] = false,


		["QUEST_PRINT_STEPS"] = true,
		["QUEST_FORCE_ASSIST"] = true,
		["QUEST_AUTOMARK_NEXT_WAYPOINT"] = "Closest Quest",
		["QUEST_AUTOMARK_NEAREST_STEP"] = true,
		["QUEST_CONSIDER_TRACKED_ONLY"] = false,
		["QUEST_AUTOMARK_ON_QUEST_COMPLETION"] = true,
		["QUEST_AUTOMARK_ON_QUEST_ACCEPT"] = true,
		["QUEST_AUTOMARK_CLOSEST_WARNING"] = true,
		["QUEST_ENABLE_DEBUG"] = false,
		["QUEST_ENABLE_GLOBAL_WAYPOINT"] = false,

		["DEFAULTTO_WAYPOINT_WIN"] = true,

		["SORT_ORDER"] =
		{
			["loc"] = "Name",
			["group"] = "Name",
			["fastTravelWayshrine"] = "Distance",
			["fastTravelKeep"] = "Distance",
			["forwardCamp"] = "Distance",
			["objective"] = "Distance",
			["keep"] =
			{
				[ALLIANCE_ALDMERI_DOMINION] = "Distance",
				[ALLIANCE_DAGGERFALL_COVENANT] = "Distance",
				[ALLIANCE_EBONHEART_PACT] = "Distance",
			},
			["killLocation"] = "Distance",
			["LBooksMapPin_unknown"] = "Distance",
			["LBooksMapPin_collected"] = "Distance",
			["SkySMapPin_unknown"] = "Distance",
			["SkySMapPin_collected"] = "Distance",
			["VotansFishermanPinType"] = "Distance",
			["HarvensCustomMapPinsType"] = "Distance",
			["HarvensHouseHunterPinType"] = "Distance",
			["LostTreasureMapTreasurePin"] = "Distance",
			["LostTreasureCompassSurveysPin"] = "Distance",
			["poi"] =
			{
				["darkanchors"] = "Distance",
				["groupbosses"] = "Distance",
				["dungeons"] = "Distance",
				["groupdungeons"] = "Distance",
				["mundus"] = "Distance",
				["delves"] = "Distance",
				["other"] = "Distance",
			},
			["quest"] =
			{
				["inzone"] = "Distance",
				["outofzone"] = "Distance",
			},
		},
		["POINTER_COLOR"] = "FFFFA500",
		["GROUP_COLOR"] = "FF00FF00",
		["ARROW_STYLE"] = "Arrow 1",
	}

	self.SavedVarVersion = 0.1
	self.account = ZO_SavedVars:NewAccountWide("WaypointItSavedVars", self.SavedVarVersion, nil, defaultSavedVars)
	self.player = ZO_SavedVars:NewCharacterIdSettings("WaypointItSavedVars", self.SavedVarVersion, nil, defaultSavedVars)
	self.sv = self.account.accountWide and self.account or self.player

	self.pointerColor = ZO_ColorDef:New(self.sv.POINTER_COLOR)
	self.groupColor = ZO_ColorDef:New(self.sv.GROUP_COLOR)
end

-------------------------------------------------------------------------
--  Settings Menu --
-------------------------------------------------------------------------
function WaypointIt:CreateSettingsMenu()
	local panelData = {
		type = "panel",
		name = "WaypointIt",
		displayName = "|cFF0000 Circonians |c00FFFF WaypointIt",
		author = "Circonian & votan",
		version = self.CodeVersion,
		slashCommand = "/waypointIt",
		registerForRefresh = true,
		registerForDefaults = true,
		website = "http://www.esoui.com/downloads/info955-CirconiansWaypointIt.html",
	}
	local cntrlOptionsPanel = LAM2:RegisterAddonPanel("Circonians_WaypointIt_Options", panelData)

	local optionsData
	local function ReassignSettings()
		CALLBACK_MANAGER:FireCallbacks("LAM-RefreshPanel", cntrlOptionsPanel)
	end
	optionsData = {
		{
			type = "checkbox",
			name = "Account-Wide Settings",
			tooltip = "Use account-wide settings or per-character settings.",
			default = false,
			getFunc = function() return self.account.accountWide end,
			setFunc = function(bValue)
				self.account.accountWide = bValue
				self.sv = self.account.accountWide and self.account or self.player
				ReassignSettings()
			end
		},
		{
			type = "submenu",
			name = "General Settings",
			controls =
			{
				{
					type = "checkbox",
					name = "Default UI to WaypointIt",
					tooltip = "Sets WaypointIt as the default panel in the World Info UI (the window on the right of the map). WaypointIt will be the one you see first every time you open the map.",
					default = false,
					getFunc = function() return self.sv["DEFAULTTO_WAYPOINT_WIN"] end,
					setFunc = function(bValue)
						self.sv["DEFAULTTO_WAYPOINT_WIN"] = bValue
						if bValue then
							WORLD_MAP_INFO.modeBar:SetStartingFragment(SI_BINDING_NAME_WAYPOINTIT)
						else
							WORLD_MAP_INFO.modeBar:SetStartingFragment(SI_MAP_INFO_MODE_QUESTS)
						end
					end
				},
				{
					type = "checkbox",
					name = "Show Waypoint Directional Arrow",
					tooltip = "Displays an arrow that spins around the reticle pointing the direction to your waypoint.",
					default = false,
					getFunc = function() return self.sv["WAYPOINT_DIRECTIONAL_ARROW"] end,
					setFunc = function(bValue)
						self.sv["WAYPOINT_DIRECTIONAL_ARROW"] = bValue
						if bValue then
							self:RunHeadingUpdates(true)
						else
							self:RunHeadingUpdates(false)
						end
					end
				},
				{
					type = "checkbox",
					name = "Hide Waypoint Arrow In Combat",
					tooltip = "Hides the waypoint arrow whenever you are in combat.",
					default = false,
					getFunc = function() return self.sv["WAYPOINT_HIDE_ARROW_INCOMBAT"] end,
					setFunc = function(bValue)
						self.sv["WAYPOINT_HIDE_ARROW_INCOMBAT"] = bValue
					end
				},
				{
					type = "checkbox",
					name = "Hide Waypoint Arrow In Groups",
					tooltip = "Hides the waypoint arrow whenever you are in a group.",
					default = false,
					getFunc = function() return self.sv["WAYPOINT_HIDE_ARROW_GROUP"] end,
					setFunc = function(bValue)
						self.sv["WAYPOINT_HIDE_ARROW_GROUP"] = bValue
					end
				},
				{
					type = "checkbox",
					name = "Hide Group Arrow In Combat",
					tooltip = "Hides the group directional arrow whenever you are in combat.",
					default = false,
					getFunc = function() return self.sv["WAYPOINT_HIDE_GROUP_ARROW_INCOMBAT"] end,
					setFunc = function(bValue)
						self.sv["WAYPOINT_HIDE_GROUP_ARROW_INCOMBAT"] = bValue
					end
				},
				{
					type = "checkbox",
					name = "Show Distance to Waypoint",
					tooltip = "Displays the distance to your waypoint above the reticle.\n" .. self.color.darkOrange .. "Show Waypoint Directional Arrow must be on.",
					default = false,
					disabled = function() return not self.sv["WAYPOINT_DIRECTIONAL_ARROW"] end,
					getFunc = function() return self.sv["WAYPOINT_RETICLE_DISTANCE"] end,
					setFunc = function(bValue)
						self.sv["WAYPOINT_RETICLE_DISTANCE"] = bValue
						if bValue then
							local wpX, wpY = GetMapPlayerWaypoint()
							if wpX ~= 0 and wpY ~= 0 then
								self.reticleDistance:SetHidden(false)
							end
						else
							self.reticleDistance:SetHidden(true)
						end
					end
				},

				--Baertram, 2022-03-03,Accessibility chat messages for screen reader
				{
					type = "checkbox",
					name = "Accessibility: Write distance to chat",
					tooltip = "Write the distance to your waypoint to the chat, so that the Accessibility chat reader can read it.",
					default = false,
					disabled = function() return not self.sv["WAYPOINT_DIRECTIONAL_ARROW"] end,
					getFunc = function() return self.sv["WAYPOINT_DISTANCE_TO_CHAT"] end,
					setFunc = function(bValue)
						self.sv["WAYPOINT_DISTANCE_TO_CHAT"] = bValue
					end
				},
				{
					type = "slider",
					name = "Accessibility: Distance to chat delay (seconds)",
					tooltip = "Adjusts the distance to chat delay (in seconds) so that the chat is not spammed with the distance to the waypoint.",
					min = 1,
					max = 60,
					step = 1,
					clamp = true,
					readOnly = false,
					decimals = 0,
					default = 5,
					disabled = function() return not self.sv["WAYPOINT_DISTANCE_TO_CHAT"] or not self.sv["WAYPOINT_DIRECTIONAL_ARROW"] end,
					getFunc = function() return self.sv["WAYPOINT_DISTANCE_TO_CHAT_DELAY_SECONDS"] end,
					setFunc = function(iValue) self.sv["WAYPOINT_DISTANCE_TO_CHAT_DELAY_SECONDS"] = iValue end,
				},

				{
					type = "checkbox",
					name = "Show Distances in WaypointIt List",
					tooltip = "Displays the distance to each location in the WaypoinIt window.",
					default = false,
					getFunc = function() return self.sv["WAYPOINT_WINDOW_NAME_DISTANCE"] end,
					setFunc = function(bValue) self.sv["WAYPOINT_WINDOW_NAME_DISTANCE"] = bValue end
				},
				{
					type = "checkbox",
					name = "Show Distances in Meters",
					tooltip = "ON will estimate the distance in meters. OFF will be in estimated feet.\n" .. colorYellow .. "Distances are a rough estimate obtained by using ability ranges & the distance that they grey-out on the action bar.",
					default = false,
					getFunc = function() return self.sv["WAYPOINT_DISTANCEIN_METERS"] end,
					setFunc = function(bValue) self.sv["WAYPOINT_DISTANCEIN_METERS"] = bValue end
				},
				{
					type = "checkbox",
					name = "Waypoint Distance Warning",
					tooltip = "When you or WaypointIt (automatic waypoints) attempt to set a waypoint that is within the waypoint removal distance a chat message will be displayed telling you that the waypoint is to close to set a waypoint.",
					default = false,
					getFunc = function() return self.sv["WAYPOINT_DISTANCE_WARNING"] end,
					setFunc = function(bValue) self.sv["WAYPOINT_DISTANCE_WARNING"] = bValue end
				},
			},
		},
		{
			type = "submenu",
			name = "Automatic Waypoint Removal",
			controls =
			{
				{
					type = "checkbox",
					name = "Auto-Remove Waypoints",
					tooltip = "Automatically removes waypoints once you reach them.",
					default = false,
					getFunc = function() return self.sv["AUTO_REMOVE_WAYPOINT"] end,
					setFunc = function(bValue)
						self.sv["AUTO_REMOVE_WAYPOINT"] = bValue
						if bValue then
							self:RunWaypointRemoveUpdates(true)
						else
							self:RunWaypointRemoveUpdates(false)
						end
					end
				},
				{
					type = "checkbox",
					name = "Waypoints Messages",
					tooltip = "Displays a center screen announcement when you set and reach waypoints.\n" .. self.color.darkOrange .. "This setting is for waypoints you set manually.",
					width = "full",
					getFunc = function() return self.sv["WAYPOINT_MESSAGES_USER_DEFINED"] end,
					setFunc = function(bValue) self.sv["WAYPOINT_MESSAGES_USER_DEFINED"] = bValue end
				},

				--Baertram, 2022-03-03,Accessibility chat messages for screen reader
				{
					type = "checkbox",
					name = "Accessibility: Waypoint Message to chat",
					tooltip = "Displays a chat message when you set and reach waypoints, so that the Accessibility screen reader can read it.\n" .. self.color.darkOrange .. "This setting is for waypoints you set manually.",
					width = "full",
					getFunc = function() return self.sv["WAYPOINT_MESSAGES_USER_DEFINED_TO_CHAT"] end,
					setFunc = function(bValue) self.sv["WAYPOINT_MESSAGES_USER_DEFINED_TO_CHAT"] = bValue end
				},

				{
					type = "checkbox",
					name = "Auto-Waypoint Messages",
					tooltip = "Displays a center screen announcement when the auto-quest feature sets a waypoint for you & when you reach that waypoint.\n" .. self.color.darkOrange .. "This setting is for waypoints set for you by the auto-quest waypoints.",
					width = "full",
					getFunc = function() return self.sv["WAYPOINT_MESSAGES_AUTO_QUEST"] end,
					setFunc = function(bValue) self.sv["WAYPOINT_MESSAGES_AUTO_QUEST"] = bValue end
				},

				--Baertram, 2022-03-03,Accessibility chat messages for screen reader
				{
					type = "checkbox",
					name = "Accessibility: Auto-Waypoint Messages",
					tooltip = "Displays a chat message when the auto-quest feature sets a waypoint for you & when you reach that waypoint, so that the Accessibility screen reader can read it.\n" .. self.color.darkOrange .. "This setting is for waypoints set for you by the auto-quest waypoints.",
					width = "full",
					getFunc = function() return self.sv["WAYPOINT_MESSAGES_AUTO_QUEST_TO_CHAT"] end,
					setFunc = function(bValue) self.sv["WAYPOINT_MESSAGES_AUTO_QUEST_TO_CHAT"] = bValue end
				},
				{
					type = "slider",
					name = "Waypoint Removal Distance",
					tooltip = "Adjusts the distance you must be from a waypoint before it is removed. Automatic quest waypoints that are within the removal distance will NOT be created.\n " .. colorDrkOrange .. "A larger number means the waypoint gets removed sooner, a smaller number means you must be closer for the waypoint to be removed.",
					min = 1,
					max = 75,
					step = 1,
					default = 5,
					readOnly = false,
					clamped = true,
					decimals = 0,
					getFunc = function() return self.sv["WAYPOINT_DELTA_SCALE"] end,
					setFunc = function(iValue) self.sv["WAYPOINT_DELTA_SCALE"] = iValue end,
				},
				{
					type = "slider",
					name = "Waypoint Removal Max Distance",
					tooltip = "Adjusts the max distance you must be from a waypoint before it is removed. Automatic quest waypoints that are outside the max removal distance will NOT be created.\n " .. colorDrkOrange .. "A larger number means the waypoint gets removed later, a smaller number means you must be more far for the waypoint to be removed.",
					min = 100,
					max = 25000,
					step = 100,
					default = 5000,
					readOnly = false,
					clamped = true,
					decimals = 0,
					getFunc = function() return self.sv["WAYPOINT_DELTA_SCALE_MAX"] end,
					setFunc = function(iValue) self.sv["WAYPOINT_DELTA_SCALE_MAX"] = iValue end,
				},
			},
		},
		{
			type = "submenu",
			name = "Quest Settings",
			controls =
			{
				{
					type = "description",
					text = self.color.red .. "There are limitations to the automark quest waypoint features. It is not possible to find the location for every step of every quest by code. Sometimes the API returns a quest condition that has already been completed as the \"closest quest.\" When this happens WaypointIt will set a waypoint for the next step of the current quest.",
				},
				{
					type = "description",
					text = self.color.yellow .. "At some point you will run into a quest where it is not possible to find the location of the next step and no waypoint will get set. If you continue playing it will keep tracking your quests. It will start setting waypoints again as soon as you get to a quest step that is possible to find.",
				},
				{
					type = "description",
					text = self.color.red .. "Quest steps within the waypoint removal distance or outside of the current map will NOT get set!",
				},
				{
					type = "checkbox",
					name = "Print Quest Steps",
					tooltip = "Prints the next quest step instructions when: you set a quest waypoint, each time you complete a quest step, & whenever a quest automark waypoint is set for you.",
					default = false,
					getFunc = function() return self.sv["QUEST_PRINT_STEPS"] end,
					setFunc = function(bValue) self.sv["QUEST_PRINT_STEPS"] = bValue end,
				},
				{
					type = "checkbox",
					name = "Force Quest Assist",
					tooltip = "When a quest waypoint is set (in the WaypointIt window) and anytime a quest waypoint is automarked that quest  is automatically set as your currently focused quest" .. self.color.darkOrange .. " (highly recommended).",
					default = false,
					getFunc = function() return self.sv["QUEST_FORCE_ASSIST"] end,
					setFunc = function(bValue) self.sv["QUEST_FORCE_ASSIST"] = bValue end,
				},
				{
					type = "dropdown",
					name = "Automark Next Quest Waypoint",
					tooltip = "Each time you complete a quest step a waypoint for another quest step will be automatically set for you.\n" .. self.color.darkOrange .. "Current Quest:|r " .. self.color.yellow .. "Will automark a waypoint for the next step of the same quest you completed a step for.\n" .. self.color.magenta .. "Closest Quest:|r " .. self.color.yellow .. "Will \"attempt\" to automark a waypoint for the closest quest step, regardless of which quest it is for.",
					choices = { "Off", "Current Quest", "Closest Quest" },
					default = "Off",
					getFunc = function() return self.sv["QUEST_AUTOMARK_NEXT_WAYPOINT"] end,
					setFunc = function(bValue) self.sv["QUEST_AUTOMARK_NEXT_WAYPOINT"] = bValue end,
				},
				{
					type = "checkbox",
					name = "Closest Quest Warning",
					tooltip = "Sometimes the API returns a condition that has already been completed as the nearest quest condition. In these cases the next step of your current quest will be used to set a waypoint and it may not be the \"closest.\" When this setting is ON it will print a chat message letting you know that the waypoint set may not be the closest quest.",
					default = false,
					disabled = function() return self.sv["QUEST_AUTOMARK_NEXT_WAYPOINT"] ~= "Closest Quest" end,
					getFunc = function() return self.sv["QUEST_AUTOMARK_CLOSEST_WARNING"] end,
					setFunc = function(bValue) self.sv["QUEST_AUTOMARK_CLOSEST_WARNING"] = bValue end,
				},
				{
					type = "checkbox",
					name = "Automark On Completion",
					tooltip = "When a quest is completed the next closest quest will be marked with a waypoint.\n" .. self.color.darkOrange .. "This is separate from the other AutoMark features, this only marks a waypoint when you complete a quest.",
					default = false,
					getFunc = function() return self.sv["QUEST_AUTOMARK_ON_QUEST_COMPLETION"] end,
					setFunc = function(bValue) self.sv["QUEST_AUTOMARK_ON_QUEST_COMPLETION"] = bValue end,
				},
				{
					type = "checkbox",
					name = "Automark On Quest Accepted",
					tooltip = "When a new quest is accepted a waypoint for the quest will be automatically marked on your map.\n" .. self.color.darkOrange .. "This is separate from the other AutoMark features, this only marks a waypoint when you accept a new  quest. It will override any quest waypoints that are already set.",
					default = false,
					getFunc = function() return self.sv["QUEST_AUTOMARK_ON_QUEST_ACCEPT"] end,
					setFunc = function(bValue) self.sv["QUEST_AUTOMARK_ON_QUEST_ACCEPT"] = bValue end,
				},
				{
					type = "checkbox",
					name = "Waypoints Outside Current Map",
					tooltip = "This enables waypoints outside the current map. You may (may!) see a confused World Map with wrong pins. In this case disable this option again.",
					default = false,
					getFunc = function() return self.sv["QUEST_ENABLE_GLOBAL_WAYPOINT"] end,
					setFunc = function(bValue) self.sv["QUEST_ENABLE_GLOBAL_WAYPOINT"] = bValue end,
				},
				{
					type = "checkbox",
					name = "Debug Quest Marking",
					tooltip = "Prints debug info to the WaypointIt Debug Window.",
					default = false,
					getFunc = function() return self.sv["QUEST_ENABLE_DEBUG"] end,
					setFunc = function(bValue)
						self.sv["QUEST_ENABLE_DEBUG"] = bValue
					end,
				},
			},
		},
		{
			type = "submenu",
			name = "Sort Orders",
			controls =
			{
				{
					type = "description",
					text = self.color.yellow .. "Used to set the default sort order for the various location types.",
				},
				{
					type = "dropdown",
					name = "AvA",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["objective"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["objective"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Fast Travel Keeps",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["fastTravelKeep"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["fastTravelKeep"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Forward Camps",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["forwardCamp"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["forwardCamp"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Group",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["group"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["group"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Harvens Custom Pins",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["HarvensCustomMapPinsType"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["HarvensCustomMapPinsType"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Harvens House Hunter",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["HarvensHouseHunterPinType"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["HarvensHouseHunterPinType"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "KEEPS: Aldmeri Dominion",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["keep"][ALLIANCE_ALDMERI_DOMINION] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["keep"][ALLIANCE_ALDMERI_DOMINION] = bValue
					end
				},
				{
					type = "dropdown",
					name = "KEEPS: Daggerfall Covenant",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["keep"][ALLIANCE_DAGGERFALL_COVENANT] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["keep"][ALLIANCE_DAGGERFALL_COVENANT] = bValue
					end
				},
				{
					type = "dropdown",
					name = "KEEPS: Ebonheart Pact",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["keep"][ALLIANCE_EBONHEART_PACT] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["keep"][ALLIANCE_EBONHEART_PACT] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Kill Locations",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["killLocation"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["killLocation"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Locations",
					choices = { "Distance", "Name" },
					default = "Name",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["loc"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["loc"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "LoreBooks: Unknown",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["LBooksMapPin_unknown"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["LBooksMapPin_unknown"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "LoreBooks: Collected",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["LBooksMapPin_collected"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["LBooksMapPin_collected"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "LostTreasure: Treasure Maps",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["LostTreasureMapTreasurePin"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["LostTreasureMapTreasurePin"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "LostTreasure: Surveys",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["LostTreasureCompassSurveysPin"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["LostTreasureCompassSurveysPin"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "POI: Delves",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["poi"]["delves"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["poi"]["delves"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "POI: Mundus",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["poi"]["mundus"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["poi"]["mundus"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "POI: Dark Anchors",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["poi"]["darkanchors"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["poi"]["darkanchors"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "POI: Dungeons",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["poi"]["dungeons"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["poi"]["dungeons"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "POI: Group Bosses",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["poi"]["groupbosses"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["poi"]["groupbosses"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "POI: Group Dungeons",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["poi"]["groupdungeons"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["poi"]["groupdungeons"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "POI: Other",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["poi"]["other"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["poi"]["other"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Quests: In Zone",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["quest"]["inzone"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["quest"]["inzone"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Quests: Out of Zone",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["quest"]["outofzone"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["quest"]["outofzone"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "SkyShards: Unknown",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["SkySMapPin_unknown"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["SkySMapPin_unknown"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "SkyShards: Collected",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["SkySMapPin_collected"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["SkySMapPin_collected"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Votans Fisherman",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["VotansFishermanPinType"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["VotansFishermanPinType"] = bValue
					end
				},
				{
					type = "dropdown",
					name = "Wayshrines",
					choices = { "Distance", "Name" },
					default = "Distance",
					width = "half",
					getFunc = function() return self.sv["SORT_ORDER"]["fastTravelWayshrine"] end,
					setFunc = function(bValue)
						self.sv["SORT_ORDER"]["fastTravelWayshrine"] = bValue
					end
				},
			},
		},
		{
			type = "submenu",
			name = "Appearance",
			controls =
			{
				{
					type = "description",
					text = self.color.yellow .. "Change the color and style of the reticle pointer.",
				},
				{
					type = "colorpicker",
					name = "Pointer Color",
					default = "FFFFA500",
					width = "half",
					getFunc = function()
						return self.pointerColor:UnpackRGBA()
					end,
					setFunc = function(newR, newG, newB, newA)
						self.pointerColor = ZO_ColorDef:New(newR, newG, newB, newA)
						local c = self.pointerColor
						self.sv.POINTER_COLOR = string.format("%.2x%.2x%.2x%.2x", zo_floor(c.a * 255), zo_floor(c.r * 255), zo_floor(c.g * 255), zo_floor(c.b * 255))
						self:ApplyArrowSettings()
					end,
				},
				{
					type = "dropdown",
					name = "Pointer Style",
					choices = { "Arrow 1", "Dot 1", "Dot 2", "Ring 1", "Rune 1" },
					default = "Arrow 1",
					width = "half",
					getFunc = function() return self.sv["ARROW_STYLE"] end,
					setFunc = function(bValue)
						self.sv.ARROW_STYLE = bValue
						self:ApplyArrowSettings()
					end
				},
				{
					type = "colorpicker",
					name = "Group Pointer Color",
					default = "FF00FF00",
					width = "half",
					getFunc = function()
						return self.groupColor:UnpackRGBA()
					end,
					setFunc = function(newR, newG, newB, newA)
						self.groupColor = ZO_ColorDef:New(newR, newG, newB, newA)
						local c = self.groupColor
						self.sv.GROUP_COLOR = string.format("%.2x%.2x%.2x%.2x", zo_floor(c.a * 255), zo_floor(c.r * 255), zo_floor(c.g * 255), zo_floor(c.b * 255))
						self:ApplyArrowSettings()
					end,
				},
			}
		}
	}
	LAM2:RegisterOptionControls("Circonians_WaypointIt_Options", optionsData)
end