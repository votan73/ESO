local addon = VOTANS_MINIMAP
local async = LibAsync

addon.zoneAlertMode = {
	Always = "ALWAYS",
	MiniMapHidden = "MINIMAPHIDDEN",
	Never = "NEVER"
}
addon.compassMode = {
	Untouched = "UNTOUCHED",
	Hidden = "HIDDEN",
	Shown = "SHOWN"
}
addon.fontFaces = {
	["MEDIUM_FONT"] = {"$(MEDIUM_FONT)", 1},
	["BOLD_FONT"] = {"$(BOLD_FONT)", 1},
	["CHAT_FONT"] = {"$(CHAT_FONT)", 1},
	["GAMEPAD_LIGHT_FONT"] = {"$(GAMEPAD_LIGHT_FONT)", 1.3},
	["GAMEPAD_MEDIUM_FONT"] = {"$(GAMEPAD_MEDIUM_FONT)", 1.3},
	["GAMEPAD_BOLD_FONT"] = {"$(GAMEPAD_BOLD_FONT)", 1.3},
	["ANTIQUE_FONT"] = {"$(ANTIQUE_FONT)", 1},
	["HANDWRITTEN_FONT"] = {"$(HANDWRITTEN_FONT)", 0.95},
	["STONE_TABLET_FONT"] = {"$(STONE_TABLET_FONT)", 0.9}
}

local lookup = {
	frameStyles = {},
	fonts = {},
	fontSizes = {}
}

function addon:GetFontSizeBySizeName(sizeName)
	return lookup.nameToFontSize[sizeName]
end

function addon:GetStyleByName(name)
	return lookup.frameToFile[name]
end

function addon:AddBorderStyle(name, displayText, setupFunction, resetFunction)
	lookup.frameStyles[#lookup.frameStyles + 1] = {
		name = displayText,
		data = {value = name, setup = setupFunction, reset = resetFunction}
	}
end

function addon:AddFont(font, displayText)
	if zo_plainstrfind(font, "/") then
		self.fontFaces[font] = font
	else
		if not self.fontFaces[font] then
			self.fontFaces[font] = string.format("$(%s)", font)
		end
	end
	lookup.fonts[#lookup.fonts + 1] = {name = displayText, data = font}
end

function addon:AddFontSize(fontSize, displayText, offsetY)
	lookup.fontSizes[#lookup.fontSizes + 1] = {name = displayText, data = {size = fontSize, offsetY = offsetY}}
end

function addon:InitMapSettings()
	lookup.frameToFile = {}
	for _, item in pairs(lookup.frameStyles) do
		lookup.frameToFile[item.data.value] = item
	end
	if not lookup.frameToFile[self.account.frameStyle] then
		self.account.frameStyle = "Default"
	end

	lookup.nameToFont = {}
	for _, item in pairs(lookup.fonts) do
		lookup.nameToFont[item.data] = item
	end
	if not lookup.nameToFont[self.account.titleFont] then
		self.account.titleFont = "BOLD_FONT"
	end

	lookup.nameToFontSize = {}
	for _, item in pairs(lookup.fontSizes) do
		lookup.nameToFontSize[item.data.size] = item
	end
	if type(self.account.titleFontSize) == "string" then
		CreateFont("VOTAN_MINIMAP_FONT", "$(MEDIUM_FONT)|" .. self.account.titleFontSize)
		local _, fontSize = VOTAN_MINIMAP_FONT:GetFontInfo()
		self.account.titleFontSize = fontSize
	end
	if not lookup.nameToFontSize[self.account.titleFontSize] then
		self.account.titleFontSize = 16
	end
end

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Mini Map")
	if not settings then
		return
	end
	self.settingsControls = settings
	settings.allowDefaults = true
	settings.version = "2.0.8"
	settings.website = "http://www.esoui.com/downloads/info1399-VotansMiniMap.html"

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANSMINIMAP_WORLD_MAP_TWEAKS),
		tooltip = GetString(SI_VOTANSMINIMAP_WORLD_MAP_TWEAKS_TOOLTIP),
		default = self.accountDefaults.enableTweaks,
		getFunction = function()
			return self.account.enableTweaks
		end,
		setFunction = function(value)
			self.account.enableTweaks = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_KEYBINDINGS_CATEGORY_VOTANS_MINIMAP),
		tooltip = GetString(SI_VOTANSMINIMAP_MINI_MAP_TOOLTIP),
		default = self.accountDefaults.enableMap,
		getFunction = function()
			return self.account.enableMap
		end,
		setFunction = function(value)
			self.account.enableMap = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_LABEL,
		label = ""
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "",
		tooltip = nil,
		buttonText = GetString(SI_VOTANSMINIMAP_APPLY_BUTTON),
		clickHandler = function()
			SLASH_COMMANDS["/reloadui"]()
		end
	}

	if self.account.enableMap then
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_LABEL,
			label = GetString(SI_KEYBINDINGS_CATEGORY_VOTANS_MINIMAP)
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_VOTANSMINIMAP_ZOOM),
			tooltip = GetString(SI_VOTANSMINIMAP_ZOOM_TOOLTIP),
			min = 0.0,
			max = 2,
			step = 0.05,
			default = self.accountDefaults.zoom,
			format = "%f",
			unit = "",
			getFunction = function()
				return self.account.zoom
			end,
			setFunction = function(value)
				self.account.zoom = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_VOTANSMINIMAP_SUB_ZONE_ZOOM),
			tooltip = GetString(SI_VOTANSMINIMAP_SUB_ZONE_ZOOM_TOOLTIP),
			min = 0.0,
			max = 2,
			step = 0.05,
			default = self.accountDefaults.subZoneZoom,
			format = "%f",
			unit = "",
			getFunction = function()
				return self.account.subZoneZoom
			end,
			setFunction = function(value)
				self.account.subZoneZoom = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_VOTANSMINIMAP_DUNGEON_ZOOM),
			tooltip = GetString(SI_VOTANSMINIMAP_DUNGEON_ZOOM_TOOLTIP),
			min = 0.0,
			max = 2,
			step = 0.05,
			default = self.accountDefaults.dungeonZoom,
			format = "%f",
			unit = "",
			getFunction = function()
				return self.account.dungeonZoom
			end,
			setFunction = function(value)
				self.account.dungeonZoom = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_VOTANSMINIMAP_MOUNTED_ZOOM),
			tooltip = GetString(SI_VOTANSMINIMAP_MOUNTED_ZOOM_TOOLTIP),
			min = 0.0,
			max = 2,
			step = 0.05,
			default = self.accountDefaults.mountedZoom,
			format = "%f",
			unit = "",
			getFunction = function()
				return self.account.mountedZoom
			end,
			setFunction = function(value)
				self.account.mountedZoom = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_VOTANSMINIMAP_BG_ZOOM),
			tooltip = GetString(SI_VOTANSMINIMAP_BG_ZOOM_TOOLTIP),
			min = 0.0,
			max = 2,
			step = 0.05,
			default = self.accountDefaults.battlegroundZoom,
			format = "%f",
			unit = "",
			getFunction = function()
				return self.account.battlegroundZoom
			end,
			setFunction = function(value)
				self.account.battlegroundZoom = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_VOTANSMINIMAP_UNIT_PINS_MINIMUM_SIZE),
			tooltip = GetString(SI_VOTANSMINIMAP_UNIT_PINS_MINIMUM_SIZE_TOOLTIP),
			min = 0.65,
			max = 1,
			step = 0.01,
			default = self.accountDefaults.unitPinScaleLimit,
			format = "%f",
			unit = "",
			getFunction = function()
				return self.account.unitPinScaleLimit
			end,
			setFunction = function(value)
				self.account.unitPinScaleLimit = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANSMINIMAP_SHOW_MAP),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_MAP_TOOLTIP),
			default = self.defaults.showMap,
			getFunction = function()
				return self.player.showMap
			end,
			setFunction = function(value)
				self.player.showMap = value
				self:UpdateVisibility()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = " |u12:0::|u" .. GetString(SI_VOTANSMINIMAP_SHOW_HUD),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_HUD_TOOLTIP),
			default = self.accountDefaults.showHUD,
			getFunction = function()
				return self.account.showHUD
			end,
			setFunction = function(value)
				self.account.showHUD = value
				self:UpdateVisibility()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = " |u12:0::|u" .. GetString(SI_VOTANSMINIMAP_SHOW_LOOTING),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_LOOTING_TOOLTIP),
			default = self.accountDefaults.showLoot,
			getFunction = function()
				return self.account.showLoot
			end,
			setFunction = function(value)
				self.account.showLoot = value
				self:UpdateVisibility()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = " |u12:0::|u" .. GetString(SI_VOTANSMINIMAP_SHOW_MOUNTED),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_MOUNTED_TOOLTIP),
			default = self.accountDefaults.showMounted,
			getFunction = function()
				return self.account.showMounted
			end,
			setFunction = function(value)
				self.account.showMounted = value
				self:UpdateVisibility()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = " |u12:0::|u" .. GetString(SI_VOTANSMINIMAP_SHOW_COMBAT),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_COMBAT_TOOLTIP),
			default = self.accountDefaults.showCombat,
			getFunction = function()
				return self.account.showCombat
			end,
			setFunction = function(value)
				self.account.showCombat = value
				self:UpdateVisibility()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = " |u12:0::|u" .. GetString(SI_VOTANSMINIMAP_SHOW_SIEGE),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_SIEGE_TOOLTIP),
			default = self.accountDefaults.showSiege,
			getFunction = function()
				return self.account.showSiege
			end,
			setFunction = function(value)
				self.account.showSiege = value
				self:UpdateVisibility()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANSMINIMAP_ASYNC_UPDATE),
			tooltip = GetString(SI_VOTANSMINIMAP_ASYNC_UPDATE_TOOLTIP),
			default = self.accountDefaults.asyncUpdate,
			getFunction = function()
				return self.account.asyncUpdate
			end,
			setFunction = function(value)
				self.account.asyncUpdate = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SECTION,
			label = GetString(SI_VOTANSMINIMAP_KEYBINDINGS_ZOOM)
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANSMINIMAP_ZOOM_TO_PLAYER),
			tooltip = GetString(SI_VOTANSMINIMAP_ZOOM_TO_PLAYER_TOOLTIP),
			default = self.accountDefaults.zoomToPlayer,
			getFunction = function()
				return self.account.zoomToPlayer
			end,
			setFunction = function(value)
				self.account.zoomToPlayer = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_VOTANSMINIMAP_ZOOM_OUT),
			tooltip = GetString(SI_VOTANSMINIMAP_ZOOM_OUT_TOOLTIP),
			min = 0.0,
			max = 1,
			step = 0.05,
			default = self.accountDefaults.zoomOut,
			format = "%f",
			unit = "",
			getFunction = function()
				return self.account.zoomOut
			end,
			setFunction = function(value)
				self.account.zoomOut = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_VOTANSMINIMAP_ZOOM_IN),
			tooltip = GetString(SI_VOTANSMINIMAP_ZOOM_IN_TOOLTIP),
			min = 1,
			max = 2,
			step = 0.05,
			default = self.accountDefaults.zoomIn,
			format = "%f",
			unit = "",
			getFunction = function()
				return self.account.zoomIn
			end,
			setFunction = function(value)
				self.account.zoomIn = value
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SECTION,
			label = GetString(SI_VOTANSMINIMAP_APPEARANCE)
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANSMINIMAP_LOCK_POSITION),
			tooltip = GetString(SI_VOTANSMINIMAP_LOCK_POSITION_TOOLTIP),
			default = self.accountDefaults.lockWindow,
			getFunction = function()
				return self.account.lockWindow
			end,
			setFunction = function(value)
				self.account.lockWindow = value
				self:UpdateBorder()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString(SI_VOTANSMINIMAP_BORDER_STYLE),
			items = lookup.frameStyles,
			default = lookup.frameToFile[self.accountDefaults.frameStyle].name,
			getFunction = function()
				return lookup.frameToFile[self.account.frameStyle].name
			end,
			setFunction = function(combobox, name, item)
				if self.account.frameStyle ~= item.data.value then
					local style = lookup.frameToFile[self.account.frameStyle]
					if style and style.data.reset then
						style.data.reset(self.account, self.background, ZO_WorldMapMapFrame)
					end
					self.account.frameStyle = item.data.value
					self:UpdateBorder()
				end
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = GetString(SI_VOTANSMINIMAP_BORDER_OPACITY),
			tooltip = GetString(SI_VOTANSMINIMAP_BORDER_OPACITY_TOOLTIP),
			min = 0,
			max = 100,
			step = 1,
			default = self.accountDefaults.borderAlpha,
			unit = "%",
			getFunction = function()
				return self.account.borderAlpha
			end,
			setFunction = function(value)
				self.account.borderAlpha = value
				self:UpdateBorder()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString(SI_VOTANSMINIMAP_TITLE_FONT),
			items = lookup.fonts,
			default = lookup.nameToFont[self.accountDefaults.titleFont].name,
			getFunction = function()
				return lookup.nameToFont[self.account.titleFont].name
			end,
			setFunction = function(combobox, name, item)
				self.account.titleFont = item.data
				self:UpdateBorder()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString(SI_VOTANSMINIMAP_TITLE_FONT_SIZE),
			items = lookup.fontSizes,
			default = lookup.nameToFontSize[self.accountDefaults.titleFontSize].name,
			getFunction = function()
				return lookup.nameToFontSize[self.account.titleFontSize].name
			end,
			setFunction = function(combobox, name, item)
				self.account.titleFontSize = item.data.size
				self.lastTitleFont = ""
				self:UpdateBorder()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_COLOR,
			label = GetString(SI_VOTANSMINIMAP_TITLE_COLOR),
			default = self.accountDefaults.titleColor,
			getFunction = function()
				return self.titleColor:UnpackRGB()
			end,
			setFunction = function(newR, newG, newB, newA)
				self.titleColor:SetRGB(newR, newG, newB)
				self.account.titleColor = {self.titleColor:UnpackRGB()}
				self:UpdateBorder()
			end
		}
		do
			local items = {
				{name = "Top", data = true},
				{name = "Bottom", data = false}
			}
			settings:AddSetting {
				type = LibHarvensAddonSettings.ST_DROPDOWN,
				label = GetString(SI_VOTANSMINIMAP_TITLE_POSITION),
				items = items,
				default = items[self.accountDefaults.titleAtTop and 1 or 2].name,
				getFunction = function()
					return items[self.account.titleAtTop and 1 or 2].name
				end,
				setFunction = function(combobox, name, item)
					self.account.titleAtTop = item.data
					self:UpdateBorder()
				end
			}
		end
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANSMINIMAP_SHOW_FULL_TITLE),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_FULL_TITLE_TOOLTIP),
			default = self.accountDefaults.showFullTitle,
			getFunction = function()
				return self.account.showFullTitle
			end,
			setFunction = function(value)
				self.account.showFullTitle = value
				ZO_WorldMapTitle:SetText(ZO_WorldMap_GetMapTitle(GetPlayerLocationName(), GetPlayerActiveSubzoneName()))
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANSMINIMAP_KEEP_SQUARE),
			tooltip = GetString(SI_VOTANSMINIMAP_KEEP_SQUARE_TOOLTIP),
			default = true,
			getFunction = function()
				return self.modeData.keepSquare
			end,
			setFunction = function(value)
				self.account.keepSquare = value
				self.modeData.keepSquare = value
			end
		}
		do
			local Modes = {
				{name = GetString(SI_VOTANSMINIMAP_SHOW_CLOCK0), data = {false, false}},
				{name = GetString(SI_VOTANSMINIMAP_SHOW_CLOCK1), data = {true, false}},
				{name = GetString(SI_VOTANSMINIMAP_SHOW_CLOCK2), data = {false, true}},
				{name = GetString(SI_VOTANSMINIMAP_SHOW_CLOCK3), data = {true, true}}
			}
			local ModeToData = {}
			for i = 1, #Modes do
				ModeToData[i] = Modes[i]
			end
			settings:AddSetting {
				type = LibHarvensAddonSettings.ST_DROPDOWN,
				label = GetString(SI_VOTANSMINIMAP_SHOW_CLOCK),
				tooltip = GetString(SI_VOTANSMINIMAP_SHOW_CLOCK_TOOLTIP),
				items = Modes,
				default = ModeToData[4].name,
				getFunction = function()
					local mode = 0
					if self.account.showRealTimeClock then
						mode = mode + 1
					end
					if self.account.showInGameClock then
						mode = mode + 2
					end
					return (ModeToData[mode + 1] or ModeToData[4]).name
				end,
				setFunction = function(combobox, name, item)
					local account = self.account
					account.showRealTimeClock = item.data[1]
					account.showInGameClock = item.data[2]
					account.showClock = account.showRealTimeClock or account.showInGameClock
					self:UpdateBorder()
				end
			}
		end
		do
			local Modes = {
				{name = "12h", data = TIME_FORMAT_PRECISION_TWELVE_HOUR},
				{name = "24h", data = TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR}
			}
			local ModeToData = {}
			for i = 1, #Modes do
				ModeToData[Modes[i].data] = Modes[i]
			end
			settings:AddSetting {
				type = LibHarvensAddonSettings.ST_DROPDOWN,
				label = GetString(SI_VOTANSMINIMAP_TIME_FORMAT),
				items = Modes,
				default = ModeToData[self.accountDefaults.timeFormat].name,
				getFunction = function()
					return (ModeToData[self.account.timeFormat] or ModeToData[self.accountDefaults.timeFormat]).name
				end,
				setFunction = function(combobox, name, item)
					self.account.timeFormat = item.data
				end
			}
		end
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANSMINIMAP_SHOW_CAMERA_HEADING),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_CAMERA_HEADING_TOOLTIP),
			default = self.accountDefaults.showCameraAngle,
			getFunction = function()
				return self.account.showCameraAngle
			end,
			setFunction = function(value)
				self.account.showCameraAngle = value
				if value then
					self:InitCameraAngle()
				end
				self.cameraAngle = 0
				if self.cameraAngleLeft then
					self.cameraAngleLeft:SetHidden(not value)
					self.cameraAngleRight:SetHidden(not value)
				end
				settings:UpdateControls()
			end
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = " |u12:0::|u" .. GetString(SI_VOTANSMINIMAP_CAMERA_HEADING_ANGLE),
			tooltip = GetString(SI_VOTANSMINIMAP_CAMERA_HEADING_ANGLE_TOOLTIP),
			min = 20,
			max = 70,
			step = 1,
			default = self.accountDefaults.cameraAngle,
			unit = "°",
			getFunction = function()
				return self.account.cameraAngle
			end,
			setFunction = function(value)
				self.account.cameraAngle = value
				self.cameraAngleRad = value * 0.0174532925199 -- pi/180°
			end,
			disable = function()
				return not self.account.showCameraAngle
			end
		}
		do
			local Modes = {
				{name = GetString(SI_VOTANSMINIMAP_ZONEALERTMODE_ALWAYS), data = self.zoneAlertMode.Always},
				{name = GetString(SI_VOTANSMINIMAP_ZONEALERTMODE_MAP_HIDDEN), data = self.zoneAlertMode.MiniMapHidden},
				{name = GetString(SI_VOTANSMINIMAP_ZONEALERTMODE_NEVER), data = self.zoneAlertMode.Never}
			}
			local ModeToData = {}
			for i = 1, #Modes do
				ModeToData[Modes[i].data] = Modes[i]
			end
			settings:AddSetting {
				type = LibHarvensAddonSettings.ST_DROPDOWN,
				label = GetString(SI_VOTANSMINIMAP_ZONE_CHANGE_ALERT),
				items = Modes,
				default = ModeToData[self.accountDefaults.zoneAlertMode].name,
				getFunction = function()
					return (ModeToData[self.account.zoneAlertMode] or ModeToData[self.accountDefaults.zoneAlertMode]).name
				end,
				setFunction = function(combobox, name, item)
					self.account.zoneAlertMode = item.data
				end
			}
		end
		do
			local Modes = {
				{name = GetString(SI_VOTANSMINIMAP_COMPASSMODE_UNTOUCHED), data = self.compassMode.Untouched},
				{name = GetString(SI_VOTANSMINIMAP_COMPASSMODE_HIDDEN), data = self.compassMode.Hidden},
				{name = GetString(SI_VOTANSMINIMAP_COMPASSMODE_SHOWN), data = self.compassMode.Shown}
			}
			local ModeToData = {}
			for i = 1, #Modes do
				ModeToData[Modes[i].data] = Modes[i]
			end
			settings:AddSetting {
				type = LibHarvensAddonSettings.ST_DROPDOWN,
				label = GetString(SI_VOTANSMINIMAP_SHOW_COMPASS),
				tooltip = GetString(SI_VOTANSMINIMAP_SHOW_COMPASS_TOOLTIP),
				items = Modes,
				default = ModeToData[self.accountDefaults.enableCompass].name,
				getFunction = function()
					return (ModeToData[self.account.enableCompass] or ModeToData[self.accountDefaults.enableCompass]).name
				end,
				setFunction = function(combobox, name, item)
					self.account.enableCompass = item.data
					self:UpdateCompass()
				end
			}
		end

		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANSMINIMAP_SHOW_ON_TOP),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_ON_TOP_TOOLTIP),
			default = self.accountDefaults.showOnTop,
			getFunction = function()
				return self.account.showOnTop
			end,
			setFunction = function(value)
				self.account.showOnTop = value
				self:UpdateDrawLevel()
			end
		}

		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SECTION,
			label = GetString(SI_VOTANSMINIMAP_FRAMEDROP_DEBUG)
		}
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(SI_VOTANSMINIMAP_SHOW_FREEZE_WARNING),
			tooltip = GetString(SI_VOTANSMINIMAP_SHOW_FREEZE_WARNING_TOOLTIP),
			default = false,
			getFunction = function()
				return async:GetDebug()
			end,
			setFunction = function(value)
				self.account.debug = value
				async:SetDebug(value)
			end
		}
	end
end
