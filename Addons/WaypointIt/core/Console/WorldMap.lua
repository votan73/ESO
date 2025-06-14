local gps = LibGPS3

function WaypointIt:CreateWaypointsList()
	self.scrollList = LibConsoleDialogs:Create("Category")
	self.scrollListPins = LibConsoleDialogs:Create("Select")
end

function WaypointIt:CreateWaypointsWindow()
	LibConsoleDialogs:RegisterKeybind(
		GAMEPAD_WORLD_MAP_SCENE,
		{
			alignment = KEYBIND_STRIP_ALIGN_LEFT,
			name = GetString(SI_KEYBINDINGS_CATEGORY_WAYPOINTIT),
			callback = function(buttonInfo)
				self:UpdateScrollList()
				self.scrollList:Show()
			end,
			visible = true,
			enabled = true
		}
	)
	self.reticleDistance:SetFont("ZoFontGamepad20")
end

do
	local function EnableButton(btn, enable)
		local btnObj = btn.m_object

		if enable then
			if btnObj.m_menuBar:GetSelectedDescriptor() == btnObj:GetDescriptor() then
				btnObj:SetState(BSTATE_PRESSED)
			else
				btnObj:SetState(BSTATE_NORMAL)
			end
		else
			btnObj:SetState(BSTATE_DISABLED)
		end
	end

	local function DoPinsExist(self, lookupType, subType)
		local pins = self.categories[lookupType].pins

		if subType then
			for k, pinData in pairs(pins) do
				if pinData.subFilterId == subType then
					return true
				end
			end
		else
			if next(pins) ~= nil then
				return true
			end
		end
		return false
	end

	local function DoesSubBarHavePins(self, subBar)
		local tabFilters = WAYPOINTIT_FILTER_DATA[subBar]

		for k, tabData in pairs(tabFilters) do
			if DoPinsExist(self, tabData.lookupType, tabData.subType) then
				return true
			end
		end
		return false
	end

	local function showCategory(self, name)
		local dialog = self.scrollList
		dialog:Clear()
		for _, category in ipairs(WAYPOINTIT_FILTER_DATA[name]) do
			local hasPins
			if category.subBar then
				hasPins = DoesSubBarHavePins(self, category.subBar)
			else
				hasPins = DoPinsExist(self, category.lookupType, category.subType)
			end
			if hasPins then
				local button = {
					type = LibHarvensAddonSettings.ST_BUTTON,
					label = zo_iconFormat(category.normal, "150%", "150%"),
					tooltip = category.tooltip,
					clickHandler = function()
						if category.subBar then
							showCategory(self, category.subBar)
						else
							self:ShowCategoryId(category.lookupType, category.subType)
						end
					end
				}
				dialog:AddSetting(button)
			end
		end
		if #dialog.settings == 1 then
			dialog.settings[1]:clickHandler()
		else
			dialog:Show()
		end
	end

	function WaypointIt:UpdateScrollList()
		showCategory(self, "MAINBAR")
	end
end

function WaypointIt:SortListByDistance()
	local dataList = self.scrollListPins.list

	table.sort(
		dataList,
		function(bvalue1, bvalue2)
			if bvalue1.distance == bvalue2.distance then
				return bvalue1:label() < bvalue2:label()
			elseif bvalue1.distance < bvalue2.distance then
				return true
			end
			return false
		end
	)
end

function WaypointIt:SortPinsByName()
	local dataList = self.scrollListPins.list

	table.sort(
		dataList,
		function(bvalue1, bvalue2)
			return bvalue1:label() < bvalue2:label()
		end
	)
end

function WaypointIt:RefreshIfVisible()
end

function WaypointIt:ShowCategoryId(currentCatId, subFilterId)
	local currentCategory = self.categories[currentCatId]
	local dialog = self.scrollListPins
	dialog:Clear()

	-- Get player coords for measuring distance
	local playerOffsetX, playerOffsetY = gps:LocalToGlobal(GetMapPlayerPosition("player"))

	local tActivePins = currentCategory.pins
	local list = {}
	for _, data in pairs(tActivePins) do
		if not subFilterId or subFilterId == data.subFilterId then
			local m_Pin = data.m_Pin

			local followingUnit = self.followingUnit

			local layoutData = ZO_MapPin.PIN_DATA[m_Pin:GetPinType()]

			-- if data.level then
			-- 	levelLabel:SetText(data.level)
			-- 	levelLabel:SetHidden(false)
			-- else
			-- 	levelLabel:SetHidden(true)
			-- end

			local button = {
				type = LibHarvensAddonSettings.ST_BUTTON,
				label = function(buttonInfo)
					if buttonInfo.displayName then
						return buttonInfo.displayName
					end

					local displayName = self.sv["WAYPOINT_WINDOW_NAME_DISTANCE"] and string.format("%s%s\n(%s)", data.name, self.color.yellow, self:GetDistanceText(data.distance)) or data.name
					local iconPath = data.iconPath or layoutData and layoutData.texture
					if type(iconPath) == "function" then
						iconPath = iconPath(m_Pin)
					end
					iconPath = iconPath or "esoui/art/icons/icon_missing.dds"

					local color = layoutData and layoutData.tint
					if type(color) == "function" then
						color = color(m_Pin)
					end
					color = color or ZO_DEFAULT_ENABLED_COLOR

					local texture = color:Colorize(zo_iconFormatInheritColor(iconPath, "150%", "150%"))

					buttonInfo.displayName = texture .. displayName
					return buttonInfo.displayName
				end,
				--tooltip = category.tooltip,
				clickHandler = function()
					self:SetWaypointByData(data)
					SCENE_MANAGER:HideCurrentScene()
				end
			}
			local normx, normy = m_Pin:GetNormalizedPosition()
			data.distance = self:GetDistanceToLocalCoords(normx, normy, playerOffsetX, playerOffsetY)
			button.distance = data.distance

			list[#list + 1] = button
		end
	end
	dialog.list = list

	local bSortByDistance
	if subFilterId then
		bSortByDistance = self.sv["SORT_ORDER"][currentCatId][subFilterId] == "Distance"
	else
		bSortByDistance = self.sv["SORT_ORDER"][currentCatId] == "Distance"
	end
	if bSortByDistance and mapType ~= MAPTYPE_COSMIC then
		self:SortListByDistance()
		dialog.currentSortType = "distance"
	else
		self:SortPinsByName()
		dialog.currentSortType = "name"
	end
	dialog:AddSettings(list)
	dialog:Show()
end
