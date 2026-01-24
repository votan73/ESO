if IsConsoleUI() then
	return -- Not yet
end

local HarvensCustomMapPins = HarvensCustomMapPins

function HarvensCustomMapPins:ShowDialog(x, y)
	local tileName, currentFloor = HarvensCustomMapPins:GetTileAndFloorFromCurrentMap()

	local color = self.sv.lastUsedColor or {1, 1, 1, 1}

	local _, key = self:CreatePinSavedVariable(tileName, currentFloor, GetMapName(), x, y, "", 1, color)
	self.dialog.description = ""
	self.dialog.color = color
	self.dialog.icon = 1
	self.dialog.predefined = ""
	self.dialog.acceptCallback = function(dialog)
		local pin, key = self:CreatePinSavedVariable(tileName, currentFloor, GetMapName(), x, y, dialog.description, dialog.icon, dialog.color, dialog.predefined)
		self:CreatePin(pin, self:CreatePinKey(tileName, currentFloor, key))
	end
	self.dialog:Show()
end

function HarvensCustomMapPins_WorldMapPlacePin()
	local x, y = ZO_WorldMapScroll:GetCenter()
	x, y = NormalizePointToControl(x, y, ZO_WorldMapContainer)
	if (x > 0 and x < 1 and y > 0 and y < 1) then
		HarvensCustomMapPins:ShowDialog(x, y)
	end
end

function HarvensCustomMapPins_CustomPinCommand()
	local x, y = GetMapPlayerPosition("player")
	HarvensCustomMapPins:ShowDialog(x, y)
end

function HarvensCustomMapPins:ShowPinMenu(pin, button)
	local pType, pTag = pin:GetPinTypeAndTag()

	ZO_WorldMap:StopMovingOrResizing()
end

function HarvensCustomMapPins:InjectKeystrip()
	self.keybindStripDescriptor = {
		{
			alignment = KEYBIND_STRIP_ALIGN_CENTER,
			name = GetString(SI_HARVEN_CMP_PLACE_CUSTOM_PIN),
			callback = HarvensCustomMapPins_WorldMapPlacePin,
			order = -10000,
			visible = true
		}
	}
	LibConsoleDialogs:RegisterKeybind(GAMEPAD_WORLD_MAP_SCENE, self.keybindStripDescriptor[1])
end
