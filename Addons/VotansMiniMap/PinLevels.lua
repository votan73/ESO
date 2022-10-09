local addon = VOTANS_MINIMAP

local settingsControls

local function UpdateControls()
	if settingsControls.selected then
		settingsControls:UpdateControls()
	end
end

function addon:InitPinLevels()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")
	if not LibHarvensAddonSettings then return end

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Mini Map Pin Levels")
	if not settings then return end
	settingsControls = settings
	settings.allowDefaults = true;

	local function UpdatePin(pinType, pin)
		local control = pin:GetControl()
		local singlePinData = ZO_MapPin.PIN_DATA[pinType]
		if singlePinData then
			local labelControl = GetControl(control, "Label")
			local overlayControl = GetControl(control, "Background")
			local highlightControl = GetControl(control, "Highlight")

			local pinLevel = zo_max(singlePinData.level, 1)
			control:SetDrawLevel(pinLevel)

			overlayControl:SetDrawLevel(pinLevel)
			highlightControl:SetDrawLevel(pinLevel - 1)
			labelControl:SetDrawLevel(pinLevel + 1)
		end
	end
	local function UpdateDrawLevel(pinType)
		for _, pin in pairs(addon.pinManager:GetActiveObjects()) do
			if pinType == pin:GetPinType() then UpdatePin(pinType, pin) end
		end
	end

	local function UpdateDrawLevels(pins)
		for _, pin in pairs(addon.pinManager:GetActiveObjects()) do
			local pinType = pin:GetPinType()
			if pins[pinType] then UpdatePin(pinType, pin) end
		end
	end

	local function AddPin(pinType, caption)
		local pinData = ZO_MapPin.PIN_DATA[pinType]
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = caption,
			min = 2,
			max = 240,
			step = 1,
			default = pinData.level,
			unit = "",
			getFunction = function() return pinData.level end,
			setFunction = function(value)
				pinData.level = value
				self.account.pinLevels[pinType] = value
				UpdateControls()
				UpdateDrawLevel(pinType)
			end,
		}
		pinData.level = self.account.pinLevels[pinType] or pinData.level
		UpdateDrawLevel(pinType)
	end

	local function AddPins(pins, caption)
		local pinType = next(pins)
		local first = ZO_MapPin.PIN_DATA[pinType]

		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = caption,
			min = 2,
			max = 240,
			step = 1,
			default = first.level,
			unit = "",
			getFunction = function() return first.level end,
			setFunction = function(value)
				for pinType in pairs(pins) do
					local pinData = ZO_MapPin.PIN_DATA[pinType]
					pinData.level = value
					self.account.pinLevels[pinType] = value
				end
				UpdateControls()
				UpdateDrawLevels(pins)
			end,
		}
		for pinType in pairs(pins) do
			local pinData = ZO_MapPin.PIN_DATA[pinType]
			if first.level ~= pinData.level then
				d("ups", caption)
			end
			pinData.level = self.account.pinLevels[pinType] or pinData.level
		end
		UpdateDrawLevels(pins)

	end

	AddPin(MAP_PIN_TYPE_PLAYER, "Player")
	AddPin(MAP_PIN_TYPE_GROUP, "Group Member")
	AddPin(MAP_PIN_TYPE_GROUP_LEADER, "Group Leader")
	AddPin(MAP_PIN_TYPE_LOCATION, "Locations")

	AddPins(ZO_MapPin.FAST_TRAVEL_WAYSHRINE_PIN_TYPES, "Wayshrine")
	AddPins(ZO_MapPin.POI_PIN_TYPES, "Objectives")

	AddPins(ZO_MapPin.QUEST_PIN_TYPES, "Quest")
	AddPins(ZO_MapPin.MAP_PING_PIN_TYPES, "Waypoints")
	AddPins(ZO_MapPin.FAST_TRAVEL_KEEP_PIN_TYPES, "Keep Fast Travel")

	--AddPins(ZO_MapPin.AVA_OBJECTIVE_PIN_TYPES, "AvA Objectives")
	--AddPins(ZO_MapPin.KEEP_PIN_TYPES, "Keeps")
	AddPins(ZO_MapPin.IMPERIAL_CITY_GATE_TYPES, "Imperial City Gates")
	-- AddPins(ZO_MapPin.DISTRICT_PIN_TYPES, "Districts")
	AddPins(ZO_MapPin.KILL_LOCATION_PIN_TYPES, "Kill Locations")
	AddPins(ZO_MapPin.FORWARD_CAMP_PIN_TYPES, "Forward Camps")
	AddPins(ZO_MapPin.AVA_RESPAWN_PIN_TYPES, "Ava Respawn")
	AddPins(ZO_MapPin.AVA_RESTRICTED_LINK_PIN_TYPES, "AvA Restricted Links")
end

