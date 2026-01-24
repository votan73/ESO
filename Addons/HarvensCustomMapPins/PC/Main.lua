local HarvensCustomMapPins = HarvensCustomMapPins

function HarvensCustomMapPins:ShowDialog(x, y)
	local tileName, currentFloor = HarvensCustomMapPins:GetTileAndFloorFromCurrentMap()

	local color = self.sv.lastUsedColor or {1, 1, 1, 1}

	local _, key = self:CreatePinSavedVariable(tileName, currentFloor, GetMapName(), x, y, "", 1, color)
	ZO_Dialogs_ShowDialog("HARVENS_CUSTOM_MAP_PINS_EDIT", {key = self:CreatePinKey(tileName, currentFloor, key), edit = false}, {})
end

function HarvensCustomMapPins_WorldMapPlacePin()
	local x, y = NormalizeMousePositionToControl(ZO_WorldMapContainer)
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
	ZO_WorldMap_MouseUp()
	ClearMenu()
	AddCustomMenuItem(
		GetString(SI_HARVEN_CMP_EDIT_PIN),
		function()
			HarvensCustomMapPins:EditPin(pin, pType, pTag)
		end
	)
	AddCustomMenuItem(
		GetString(SI_HARVEN_CMP_SHOW_IN_POPUP),
		function()
			local pin = HarvensCustomMapPins:GetPin(pTag)
			if not pin then
				return
			end
			PopupTooltip:SetHidden(false)
			PopupTooltip:ClearLines()
			PopupTooltip:AddLine(pin.description, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
		end
	)
	AddCustomMenuItem(
		GetString(SI_HARVEN_CMP_SHARE_PIN),
		function()
			HarvensCustomMapPins:SharePin(pTag)
		end
	)
	AddCustomMenuItem("-")
	AddCustomMenuItem(
		GetString(SI_HARVEN_CMP_DELETE_PIN),
		function()
			HarvensCustomMapPins:DeletePin(pTag)
		end
	)
	ShowMenu(pin:GetControl(), 1)

	-- dirty hack! because something calls ClearMenu after this function returns
	local backupfunc = ClearMenu
	ClearMenu = function(...)
		ClearMenu = backupfunc
	end
end

function HarvensCustomMapPins:InjectKeystrip()
	self.keybindStripDescriptor = {
		{
			alignment = KEYBIND_STRIP_ALIGN_CENTER,
			name = GetString(SI_HARVEN_CMP_PLACE_CUSTOM_PIN),
			keybind = "UI_SHORTCUT_NEGATIVE",
			callback = HarvensCustomMapPins_WorldMapPlacePin,
			order = -10000
		}
	}
	WORLD_MAP_SCENE:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_SHOWING then
				KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
			elseif newState == SCENE_HIDING then
				KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
			end
		end
	)
end
