local Dialog = {}

function Dialog:ShowAdvanced(show)
	self.sv.showAdvanced = show
	self.iconLabel:SetHidden(not show)
	self.iconChooser:SetHidden(not show)
	self.colorLabel:SetHidden(not show)
	self.colorChooser:SetHidden(not show)
	self.predefinedLabel:SetHidden(not show)
	self.predefinedDropdown:SetHidden(not show)
	self.predefinedNameLabel:SetHidden(not show)
	self.predefinedNameEdit:SetHidden(not show)
	self.deleteButton:SetHidden(not show)
end

function Dialog:OnColorClicked(control, upInside)
	if upInside then
		local dataBackup = self:GetData(self.control.data)
		PlaySound(SOUNDS.DEFAULT_CLICK)
		ZO_Dialogs_ReleaseDialog("HARVENS_CUSTOM_MAP_PINS_EDIT")
		local cancel = COLOR_PICKER.Cancel
		local confirm = COLOR_PICKER.Confirm
		COLOR_PICKER.Cancel = function()
			COLOR_PICKER.Cancel = cancel
			COLOR_PICKER.Confirm = confirm
			COLOR_PICKER:Cancel()
			ZO_Dialogs_ShowDialog("HARVENS_CUSTOM_MAP_PINS_EDIT", dataBackup)
		end
		COLOR_PICKER.Confirm = function()
			COLOR_PICKER.Cancel = cancel
			COLOR_PICKER.Confirm = confirm
			COLOR_PICKER:Confirm()
			ZO_Dialogs_ShowDialog("HARVENS_CUSTOM_MAP_PINS_EDIT", dataBackup)
		end
		COLOR_PICKER:Show(
			function(newR, newG, newB, newA)
				dataBackup.color = {newR, newG, newB, newA}
			end,
			unpack(dataBackup.color)
		)
	end
end

function Dialog:GetData(userData)
	local savedData = {}
	for k, v in pairs(userData) do
		savedData[k] = v
	end
	local re, gr, bl, al = self.colorTexture:GetColor()
	savedData.color = {re, gr, bl, al}
	savedData.icon = self.scrollList:GetSelectedData().index
	savedData.predefined = self.predefinedDropdown.m_comboBox:GetSelectedItem()
	savedData.description = self.descEdit:GetText()
	savedData.predefinedName = self.predefinedNameEdit:GetText()
	return savedData
end

function Dialog:SetupDialog(dialog, data)
	local function predefinedSelected(...)
		self:PredefinedSelected(...)
	end

	local dropdown = self.predefinedDropdown.m_comboBox
	dropdown:ClearItems()
	for k, v in pairs(self.sv.predefined) do
		local item = dropdown:CreateItemEntry(k, predefinedSelected)
		item.data = {name = k, color = v.color, icon = v.icon}
		dropdown:AddItem(item)
	end

	if data.color then
		-- restored dialog returning from color picker
		self.colorTexture:SetColor(HarvensCustomMapPins:GetColor(data.color):UnpackRGBA())
		self.descEdit:SetText(data.description)
		dropdown:SetSelectedItem(data.predefined)
		self.predefinedNameEdit:SetText(data.predefinedName)
		self.scrollList:SetSelectedDataIndex(data.icon or 1)
		self.scrollList:RefreshVisible()
	else
		if data.edit and data.pin then
			dialog.info.title.text = "CUSTOM MAP PIN (replace)"
		elseif data.edit then
			dialog.info.title.text = "CUSTOM MAP PIN (edit)"
		else
			dialog.info.title.text = "CUSTOM MAP PIN (new)"
		end
		ZO_Dialogs_UpdateDialogTitleText(dialog, dialog.info.title)

		self.predefinedNameEdit:SetText("")
		if not data.pin then
			local tileName, cfloor, key = HarvensCustomMapPins:GetKeyFromTag(data.key)
			data = HarvensCustomMapPins_Data[tileName][cfloor][key]
		else
			data = data.pin
		end
		if data then
			if data.description then
				self.descEdit:SetText(data.description)
			end
			if data.predefined then
				local predefined = HarvensCustomMapPins.sv.predefined[data.predefined]
				if predefined then
					dropdown:SetSelectedItem(data.predefined)
					self.predefinedNameEdit:SetText(data.predefined)
					data = predefined
				end
			end
			if data.color then
				self.colorTexture:SetColor(HarvensCustomMapPins:GetColor(data.color):UnpackRGBA())
			end
			self.scrollList:SetSelectedDataIndex(data.icon or 1)
			self.scrollList:RefreshVisible()
		end
	end
end

local function ClearBadChars(input)
	input = string.gsub(input, "%[", "")
	input = string.gsub(input, "%]", "")
	input = string.gsub(input, "'", "")
	input = string.gsub(input, '"', "")
	return input
end

function Dialog:AcceptChanges(dialog)
	local newData = self:GetData({})

	local tileName, cfloor, key = HarvensCustomMapPins:GetKeyFromTag(dialog.data.key)

	local pins = HarvensCustomMapPins:GetOrCreateMapPins(tileName, cfloor)
	local edit = pins[key] ~= nil
	local data = pins[key] or newData
	data.description = ClearBadChars(newData.description)
	local predefinedName = ClearBadChars(self.predefinedNameEdit:GetText())
	if predefinedName and #predefinedName > 0 then
		if not self.sv.predefined[predefinedName] then
			self.sv.predefined[predefinedName] = {}
		end
		local re, gr, bl, al = self.colorTexture:GetColor()
		self.sv.predefined[predefinedName].color = ZO_ColorDef.ToARGBHexadecimal(re, gr, bl, al)
		self.sv.predefined[predefinedName].icon = self.scrollList:GetSelectedData().index
		HarvensCustomMapPins:UpdateLegend()
	end

	self.sv.lastUsedColor = newData.color
	data.predefined = predefinedName
	if not predefinedName or #predefinedName == 0 then
		data.color = ZO_ColorDef.ToARGBHexadecimal(unpack(newData.color))
		data.icon = newData.icon
	else
		data.color = nil
		data.icon = nil
	end
	data.predefinedName = nil
	if not edit and dialog.data.pin then
		local pin = dialog.data.pin
		data.x, data.y = pin.x, pin.y
	end

	pins[key] = data
	if HarvensCustomMapPins:GetTileAndFloorFromCurrentMap() == tileName then
		if edit then
			HarvensCustomMapPins:RefreshPins()
		else
			HarvensCustomMapPins:CreatePin(data, dialog.data.key)
		end
	end
end

function Dialog:PredefinedSelected(combobox, name, item)
	self.predefinedNameEdit:SetText(name)
	if not item or not item.data then
		return
	end
	self.colorTexture:SetColor(HarvensCustomMapPins:GetColor(item.data.color):UnpackRGBA())
	self.scrollList:SetSelectedDataIndex(item.data.icon)
	self.scrollList:RefreshVisible()
end

function Dialog:RebuildPredefined()
	local function predefinedSelected(...)
		self:PredefinedSelected(...)
	end
	self.predefinedDropdown.m_comboBox:ClearItems()
	for k, v in pairs(self.sv.predefined) do
		local item = self.predefinedDropdown.m_comboBox:CreateItemEntry(k, predefinedSelected)
		item.data = {name = k, color = v.color, icon = v.icon}
		self.predefinedDropdown.m_comboBox:AddItem(item)
	end
end

function Dialog:DeletePredefined(button, upInside)
	if not upInside then
		return
	end

	local toDelete = self.predefinedDropdown.m_comboBox:GetSelectedItem()
	if toDelete and #toDelete > 0 then
		if self.sv.predefined[toDelete] then
			self.sv.predefined[toDelete] = nil
			self.sv.showPredefined[toDelete] = nil
		end
		self:RebuildPredefined()
		HarvensCustomMapPins:UpdateLegend()
	end
end

function Dialog:Initialize(control, sv)
	self.sv = sv
	self.customPins = HarvensCustomMapPins_Data
	local function SetupIcon(control, data, selected, selectedDuringRebuild, enabled)
		control:SetTexture(data.filename)
	end

	self.control = control
	local content = GetControl(self.control, "Content")
	self.accept = GetControl(self.control, "Accept")
	self.cancel = GetControl(self.control, "Cancel")
	self.descEdit = GetControl(content, "Description")
	self.iconLabel = GetControl(content, "IconLabel")
	self.colorLabel = GetControl(content, "ColorLabel")
	self.colorChooser = GetControl(content, "Color")
	self.colorTexture = GetControl(self.colorChooser, "Texture")
	self.predefinedLabel = GetControl(content, "PredefinedSelectLabel")
	self.predefinedDropdown = GetControl(content, "PredefinedSelect")
	self.predefinedNameLabel = GetControl(content, "PredefinedNameLabel")
	self.predefinedNameEdit = GetControl(content, "PredefinedName")
	self.iconChooser = GetControl(content, "Icon")
	self.deleteButton = GetControl(content, "PredefinedDelete")
	local scrollList = GetControl(self.iconChooser, "Scroll")

	--self:RebuildPredefined()

	self.deleteButton:SetHandler(
		"OnMouseUp",
		function(...)
			self:DeletePredefined(...)
		end
	)

	self.scrollList = ZO_HorizontalScrollList:New(scrollList, "HarvensCustomMapPinsIcon", 5, SetupIcon)
	self.scrollList:SetScaleExtents(.6, 1)
	self.scrollList:Clear()
	for i = 1, #HarvensCustomMapPinsIconList do
		self.scrollList:AddEntry({filename = HarvensCustomMapPinsIconList[i], index = i})
	end
	self.scrollList:Commit()

	local advanced = GetControl(content, "Advanced")
	ZO_CheckButton_SetLabelText(advanced, "Advanced Options")
	ZO_CheckButton_SetCheckState(advanced, self.sv.showAdvanced)
	advanced.toggleFunction = function(control, state)
		self:ShowAdvanced(state)
	end

	local color = GetControl(content, "Color")
	color:SetHandler(
		"OnMouseUp",
		function(control, upInside)
			self:OnColorClicked(control, upInside)
		end
	)

	self:ShowAdvanced(self.sv.showAdvanced)

	ZO_Dialogs_RegisterCustomDialog(
		"HARVENS_CUSTOM_MAP_PINS_EDIT",
		{
			customControl = self.control,
			setup = function(dialog, data)
				self:SetupDialog(dialog, data)
			end,
			title = {text = "CUSTOM MAP PIN"},
			buttons = {
				{
					control = self.accept,
					text = SI_DIALOG_ACCEPT,
					keybind = "DIALOG_PRIMARY",
					callback = function(dialog)
						self:AcceptChanges(dialog)
					end
				},
				{
					control = self.cancel,
					text = SI_DIALOG_CANCEL,
					keybind = "DIALOG_NEGATIVE",
					callback = function(dialog)
						if dialog.data.edit == true then
							return
						end
						HarvensCustomMapPins:DeletePin(dialog.data.key)
					end
				}
			}
		}
	)
end

function HarvensCustomMapPinsEditDialog_Initialize(control, sv)
	Dialog:Initialize(control, sv)
end
