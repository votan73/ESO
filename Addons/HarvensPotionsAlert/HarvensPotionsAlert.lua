local HarvensPotionsAlert = {
	PotionDialogName = "HARVENSPOTIONSALERT_DIALOG",
	PotionDialog = nil
}

local LibHarvensAddonSettings = LibHarvensAddonSettings
local EMPTY_SLOT = "esoui/art/icons/icon_potion_empty.dds"

local function AddLine(tooltip, text, color, alignment)
	local r, g, b = color:UnpackRGB()
	tooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, alignment, alignment ~= TEXT_ALIGN_LEFT)
end

local function AddLineCenter(tooltip, text, color)
	if not color then
		color = ZO_TOOLTIP_DEFAULT_COLOR
	end
	AddLine(tooltip, text, color, TEXT_ALIGN_CENTER)
end

local function AddLineTitle(tooltip, text, color)
	if not color then
		color = ZO_SELECTED_TEXT
	end
	local r, g, b = color:UnpackRGB()
	tooltip:AddLine(text, "ZoFontHeader3", r, g, b, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
end

local function AddLineSubTitle(tooltip, text, color)
	if not color then
		color = ZO_SELECTED_TEXT
	end
	local r, g, b = color:UnpackRGB()
	tooltip:AddLine(text, "ZoFontWinH5", r, g, b, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
end

local function CreatePotionTooltip(control, slotId)
	local itemLink = GetSlotItemLink(slotId)
	if itemLink ~= "" then
		InitializeTooltip(ItemTooltip, control, TOP, 0, 32, BOTTOM)
		ItemTooltip:SetLink(itemLink)
	end
end

function HarvensPotionsAlert.SetupSlot(slot)
	local buttonText
	if GetSlotType(slot.id, HOTBAR_CATEGORY_QUICKSLOT_WHEEL) ~= ACTION_TYPE_NOTHING and slot.id ~= 0 then
		local slotName = GetSlotName(slot.id, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
		local text = zo_strformat(SI_TOOLTIP_ITEM_NAME, slotName)
		buttonText = text
	else
		buttonText = GetString(SI_GAMEPAD_SELECT_OPTION)
	end
	return buttonText or ""
end

function HarvensPotionsAlert.SetupTooltip(settingsControl, slot, slotId)
	local id = settingsControl.settings.id
	if id ~= 0 then
		CreatePotionTooltip(settingsControl.control, id)
	end
end

function HarvensPotionsAlert.SaveSlot(control, slotId, slot)
	local slotName = GetSlotName(slotId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
	local text
	if #slotName > 0 then
		text = zo_strformat(SI_TOOLTIP_ITEM_NAME, slotName)
	else
		text = GetString(SI_GAMEPAD_SELECT_OPTION)
	end
	control:SetText(text)
end

------------------------------------------------------------------------
local PotionWheel = ZO_AssignableUtilityWheel_Keyboard:Subclass()
function PotionWheel:RegisterForEvents()
	ZO_AssignableUtilityWheel_Shared.RegisterForEvents(self)
end

function PotionWheel:PerformSlotLayout()
	local width, height = self.control:GetDimensions()
	local scale = self.control:GetScale()
	local halfWidth, halfHeight = width * scale * 0.5, height * scale * 0.5
	local numSlots = self.data.numSlots
	local actionBarOffset = self.data.startSlotIndex or 0
	local arcAnglePerSlotRadians, startingOffsetAngleRadians = self:GetArcAnglePerSlotAndStartingOffsetAngle()

	for i = 1, numSlots do
		local control = self.slots[i + actionBarOffset]
		local centerAngle = startingOffsetAngleRadians + (i - 1) * arcAnglePerSlotRadians
		local x = math.sin(centerAngle)
		local y = math.cos(centerAngle)

		if math.abs(x) < 0.01 then
			x = 0
		end

		if control.nameLabel then
			control.nameLabel:ClearAnchors()
			if x > 0 then
				control.nameLabel:SetAnchor(LEFT, control.icon, RIGHT, 15, 0)
			elseif x < 0 then
				control.nameLabel:SetAnchor(RIGHT, control.icon, LEFT, -15, 0)
			elseif y > 0 then
				control.nameLabel:SetAnchor(TOP, control.icon, BOTTOM, 0, 0)
			else
				control.nameLabel:SetAnchor(BOTTOM, control.icon, TOP, 0, -5)
			end
		end

		control:SetAnchor(CENTER, nil, CENTER, x * halfWidth, y * halfHeight)
		control:SetHidden(false)
	end
end
------------------------------------------------------------------------

-- Create on demand. Once configured, the dialog is not used frequently.
function HarvensPotionsAlert:CreatePotionDialog()
	if self.PotionDialog then
		return
	end

	self.PotionDialog = WINDOW_MANAGER:CreateControlFromVirtual("HarvensPotionsAlertRadial", nil, "ZO_CustomDialogBase")
	self.PotionDialog.Slots = WINDOW_MANAGER:CreateControlFromVirtual("HarvensPotionsAlertRadialMenu", self.PotionDialog, "ZO_RadialMenuTemplate")
	self.PotionDialog.Accept = WINDOW_MANAGER:CreateControlFromVirtual("HarvensPotionsAlertRadialButton1", self.PotionDialog, "ZO_DialogButton")
	self.PotionDialog.Reset = WINDOW_MANAGER:CreateControlFromVirtual("HarvensPotionsAlertRadialButton2", self.PotionDialog, "ZO_DialogButton")
	self.PotionDialog.Cancel = WINDOW_MANAGER:CreateControlFromVirtual("HarvensPotionsAlertRadialButton3", self.PotionDialog, "ZO_DialogButton")
	self.PotionDialog.wheel = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)QuickSlotCircle", self.PotionDialog, "ZO_AssignableUtilityWheel_Keyboard_Template")
	self.PotionDialog.wheel:SetAnchor(CENTER, nil, CENTER)
	local wheelData = {
		hotbarCategories = {HOTBAR_CATEGORY_QUICKSLOT_WHEEL},
		numSlots = ACTION_BAR_UTILITY_BAR_SIZE,
		showCategoryLabel = false
	}
	self.PotionDialog.Radial = PotionWheel:New(self.PotionDialog.wheel, wheelData)

	self.PotionDialog:SetResizeToFitDescendents(false)
	self.PotionDialog.Accept:SetAnchor(CENTER, self.PotionDialog, CENTER, 0, 40)
	self.PotionDialog.Reset:SetAnchor(BOTTOMLEFT, self.PotionDialog, BOTTONLEFT, 24, -24)
	self.PotionDialog.Cancel:SetAnchor(BOTTOMRIGHT, self.PotionDialog, BOTTOMRIGHT, -24, -24)
	self.PotionDialog:SetDimensions(432, 504)
	self.PotionDialog:SetAnchor(CENTER)
	self.PotionDialog:SetHidden(true)

	local bg = self.PotionDialog:GetNamedChild("BG")
	bg:SetEdgeTexture("EsoUI/Art/ChatWindow/chat_BG_edge.dds", 256, 256, 96, 0)
	bg:SetCenterTexture("EsoUI/Art/ChatWindow/chat_BG_center.dds")
	bg:SetInsets(96, 96, -96, -96)
	bg:SetAlpha(0.5)

	self.PotionDialog:SetHandler(
		"OnHide",
		function(dialog)
			dialog.Close()
		end
	)

	local emptyQuickslot = GetString(SI_QUICKSLOTS_EMPTY)
	self.PotionDialog:SetHandler(
		"OnEffectivelyShown",
		function(control)
			for i = 1, ACTION_BAR_UTILITY_BAR_SIZE do
				local slotType = GetSlotType(i, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
				local slot = control.Radial.slots[i]
				if slotType ~= ACTION_TYPE_NOTHING then
					local slotName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetSlotName(i, HOTBAR_CATEGORY_QUICKSLOT_WHEEL))
					local slotTexture = GetSlotTexture(i, HOTBAR_CATEGORY_QUICKSLOT_WHEEL) or ""
					ZO_ActionSlot_SetupSlot(slot.icon, slot.button, slotTexture)
					slot.nameLabel:SetText(slotName)
					local function select()
						self.PotionDialog.selectedSlot = i
					end
					slot.button:SetHandler("OnMouseEnter", select, "PotionDialog")
					slot.button:SetHandler("OnClicked", select)
				else
					ZO_ActionSlot_SetupSlot(slot.icon, slot.button, ZO_UTILITY_SLOT_EMPTY_TEXTURE)
					slot.nameLabel:SetText(ZO_UTILITY_SLOT_EMPTY_STRING)
					local function select()
						self.PotionDialog.selectedSlot = 0
					end
					slot.button:SetHandler("OnMouseEnter", select, "PotionDialog")
					slot.button:SetHandler("OnClicked", select)
				end
				slot.button:SetHandler("OnMouseDoubleClick", functio)
			end
			control.Radial:PerformSlotLayout()
		end
	)

	self.PotionDialog.ShowDialog = function(dialogTitle, setSlot)
		self.PotionDialog.info.title.text = dialogTitle
		self.PotionDialog.callback = setSlot
		PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_DIALOG))
		ZO_Dialogs_ShowDialog(HarvensPotionsAlert.PotionDialogName)
	end
	self.PotionDialog.Close = function()
		RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_DIALOG))
		LockCameraRotation(false)
		RETICLE:RequestHidden(false)
		ShowMouse()
	end

	local info = {
		customControl = self.PotionDialog,
		title = {text = "Select Potion"},
		buttons = {
			{
				control = self.PotionDialog.Accept,
				keybind = "DIALOG_PRIMARY",
				text = SI_DIALOG_ACCEPT,
				callback = function(dialog)
					dialog.Close()
					if self.PotionDialog.callback then
						self.PotionDialog.callback(self.PotionDialog.selectedSlot)
						self.PotionDialog.callback = nil
					end
				end
			},
			{
				control = self.PotionDialog.Reset,
				keybind = "DIALOG_SECONDARY",
				text = SI_QUICKSLOTS_EMPTY,
				callback = function(dialog)
					dialog.Close()
					if self.PotionDialog.callback then
						self.PotionDialog.callback(0)
						self.PotionDialog.callback = nil
					end
				end
			},
			{
				control = self.PotionDialog.Cancel,
				keybind = "DIALOG_NEGATIVE",
				text = SI_DIALOG_CANCEL,
				callback = function(dialog)
					dialog.Close()
				end
			}
		}
	}
	self.PotionDialog.info = info
	ZO_Dialogs_RegisterCustomDialog(HarvensPotionsAlert.PotionDialogName, info)
end

function HarvensPotionsAlert:AddSlotOption(settings, powerType, lastControl, attrNames)
	local slotControls

	local slotSelect = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = zo_strformat("<<t:2>> Slot", GetString(SI_LOW), GetString("SI_ATTRIBUTES", attrNames[powerType]))
	}

	slotSelect.buttonText = function()
		return HarvensPotionsAlert.SetupSlot(self.sv.slots[powerType])
	end
	slotSelect.tooltip = function(settingsControl)
		return HarvensPotionsAlert.SetupTooltip(settingsControl, slotSelect, self.sv.slots[powerType].id)
	end

	slotSelect.clickHandler = function(control)
		self:CreatePotionDialog()

		local function SetSlot1(slot)
			HarvensPotionsAlert.SaveSlot(control, slot, slotSelect)
			self.sv.slots[powerType].id = slot
			slotControls[1]:SetupControl(slotSelect)
		end

		self.PotionDialog.ShowDialog(slotSelect.label, SetSlot1)
	end

	local slotThreshold = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = zo_strformat("<<t:2>> Threshold", GetString(SI_LOW), GetString("SI_ATTRIBUTES", attrNames[powerType])),
		min = 0,
		max = 100,
		step = 1,
		format = "%d",
		unit = "%",
		getFunction = function()
			return self.sv.slots[powerType].threshold
		end,
		setFunction = function(value)
			self.sv.slots[powerType].threshold = value
		end
	}

	slotControls = settings:AddSettings({slotSelect, slotThreshold})
	slotControls[1].settings = self.sv.slots[powerType]
end

function HarvensPotionsAlert:AddDefaultSlotOption(settings, powerType, lastControl)
	local slotControls

	local slotSelect = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Default Slot"
	}

	slotSelect.buttonText = function()
		return HarvensPotionsAlert.SetupSlot(self.sv.slots[powerType])
	end
	slotSelect.tooltip = function(settingsControl)
		return HarvensPotionsAlert.SetupTooltip(settingsControl, slotSelect, self.sv.slots[powerType].id)
	end

	slotSelect.clickHandler = function(control)
		self:CreatePotionDialog()

		local function SetSlotDefault(slot)
			HarvensPotionsAlert.SaveSlot(control, slot, slotSelect)
			self.sv.slots[powerType].id = slot
			slotControls[1]:SetupControl(slotSelect)
			HarvensPotionsAlert.Update()
		end

		self.PotionDialog.ShowDialog(slotSelect.label, SetSlotDefault)
	end
	slotControls = settings:AddSettings({slotSelect})
	slotControls[1].settings = self.sv.slots[powerType]
end

function HarvensPotionsAlert:SetupOptions()
	local settings = LibHarvensAddonSettings:AddAddon("Harven's Potions Alert")
	if not settings then
		return
	end
	settings.version = "2.1.1"

	local attrNames = {[POWERTYPE_HEALTH] = 1, [POWERTYPE_MAGICKA] = 2, [POWERTYPE_STAMINA] = 3}
	local lastControl
	local k
	for _, k in pairs(HarvensPotionsAlert.priority) do
		if k < 1000 then
			lastControl = self:AddSlotOption(settings, k, lastControl, attrNames)
		end
	end
	for _, k in pairs(HarvensPotionsAlert.priority) do
		if k >= 1000 then
			lastControl = self:AddDefaultSlotOption(settings, k, lastControl)
		end
	end

	local scale = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Popup Scale",
		min = 0.5,
		max = 8,
		step = 0.1,
		format = "%.1f",
		unit = "",
		getFunction = function()
			return self.sv.scale
		end,
		setFunction = function(value)
			self.sv.scale = value
			HarvensPotionsAlertTopLevel:SetScale(self.sv.scale)
		end
	}

	local testButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		buttonText = "Set Alert Position",
		clickHandler = function(control)
			if self.sv.cooldownAlert then
				HarvensPotionsAlertCooldownAlert:SetHidden(false)
				HarvensPotionsAlertCooldownAlert:SetAlpha(1.0)
				HarvensPotionsAlertCooldownAlert:SetMouseEnabled(true)
				HarvensPotionsAlertCooldownAlertClose:SetMouseEnabled(true)
				HarvensPotionsAlertCooldownAlertClose:SetHidden(false)
			end
			HarvensPotionsAlertTopLevel:SetHidden(false)
			HarvensPotionsAlertTopLevelClose:SetHidden(false)
		end
	}

	local cooldownAlertSection = {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = "Cooldown Alert"
	}

	local cooldownEnabled = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Enable Quickslot Cooldown Alert",
		tooltip = "If enabled an alert will appear when current quickslot item cooldown is over",
		getFunction = function()
			return self.sv.cooldownAlert
		end,
		setFunction = function(state)
			self.sv.cooldownAlert = state
		end
	}

	local cooldownFont = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Cooldown Alert Font",
		getFunction = function()
			return self.sv.cooldownAlertFont
		end,
		setFunction = function(value)
			self.sv.cooldownAlertFont = value
			HarvensPotionsAlertCooldownAlertLabel:SetFont(value)
		end
	}

	local cooldownIconSize = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Cooldown Alert Icon Size",
		getFunction = function()
			return self.sv.cooldownAlertIconSize
		end,
		setFunction = function(value)
			self.sv.cooldownAlertIconSize = value
			HarvensPotionsAlertCooldownAlertLabel:SetText(zo_iconTextFormat("EsoUI/Art/Icons/icon_missing.dds", value, value, " is |c00ff00Ready|r!"))
		end,
		format = "%d",
		min = 8,
		max = 256,
		step = 2
	}

	settings:AddSettings({scale, cooldownAlertSection, cooldownEnabled, cooldownFont, cooldownIconSize, testButton})
end

function HarvensPotionsAlert:InitialState()
	HarvensPotionsAlertTopLevel:SetHidden(true)
	HarvensPotionsAlertTopLevel:SetAlpha(1)
	self.isAlertHidden = true
end

function HarvensPotionsAlert.PowerUpdate(eventType, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
	if unitTag ~= "player" or not HarvensPotionsAlert.sv.slots[powerType] then
		return
	end

	local val = 100 * powerValue / powerMax
	HarvensPotionsAlert.sv.slots[powerType].value = val
	HarvensPotionsAlert.Update()
end

function HarvensPotionsAlert.Update()
	-- find most important critical powerType based on current values
	local k, v, p
	local powerType = 1000
	-- Assume default slot
	for p, k in pairs(HarvensPotionsAlert.priority) do
		v = HarvensPotionsAlert.sv.slots[k]
		if v.value < v.threshold and v.threshold > 0 then
			if (v.id ~= 0 and GetSlotItemCount(v.id, HOTBAR_CATEGORY_QUICKSLOT_WHEEL) ~= 0) then
				powerType = k
				break
			end
		end
	end

	local slot = HarvensPotionsAlert.sv.slots[powerType]
	local slotId = slot.id
	if powerType ~= 1000 and GetSlotItemCount(slotId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL) == 0 then
		return
	end

	local minRemain
	local remain, duration = GetSlotCooldownInfo(slotId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
	minRemain = remain
	if minRemain > 0 then
		zo_callLater(HarvensPotionsAlert.Update, minRemain + 10)
		return
	end

	-- Critical or alert invisible. Update is called on anim end
	if GetCurrentQuickslot() ~= slotId then
		HarvensPotionsAlert.isAutoSwitch = true
		SetCurrentQuickslot(slotId)
		HarvensPotionsAlertTopLevelIcon:SetTexture(GetSlotTexture(slotId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL))
	end

	if powerType < 1000 then
		-- Critical: Show alert
		if HarvensPotionsAlert.isAlertHidden and HarvensPotionsAlert.isInCombat then
			HarvensPotionsAlertTopLevel:SetHidden(false)
			HarvensPotionsAlert.isAlertHidden = false
		end

		if HarvensPotionsAlert.alertPowerType ~= powerType then
			HarvensPotionsAlertTopLevelMsg:SetText(zo_strformat("<<t:2>>: <<t:1>>!", GetString(SI_LOW), GetString("SI_ATTRIBUTES", HarvensPotionsAlert.powerTypes[powerType])))
			HarvensPotionsAlertTopLevelBackdrop:SetEdgeColor(ZO_POWER_BAR_GRADIENT_COLORS[powerType][2]:UnpackRGBA())
			HarvensPotionsAlert.alertPowerType = powerType
		end

		if HarvensPotionsAlert.isInCombat then
			HarvensPotionsAlertTopLevel:SetAlpha(1)
			HarvensPotionsAlert.alertFadeTimeline:PlayFromStart()
		end
	else
		HarvensPotionsAlert.isAutoSwitch = false
	end
end

function HarvensPotionsAlert.CheckCooldown()
	local slotId = GetCurrentQuickslot()
	local remain, duration, isGlobal = GetSlotCooldownInfo(slotId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
	if HarvensPotionsAlert.prevRemain > 0 and not HarvensPotionsAlert.prevGlobal and remain == 0 then
		HarvensPotionsAlertCooldownAlertLabel:SetText("|t" .. HarvensPotionsAlert.sv.cooldownAlertIconSize .. ":" .. HarvensPotionsAlert.sv.cooldownAlertIconSize .. ":" .. GetSlotTexture(slotId) .. "|t is |c00ff00Ready|r!")
		HarvensPotionsAlertCooldownAlert:SetHidden(false)
		HarvensPotionsAlertCooldownAlert:SetAlpha(1.0)
		HarvensPotionsAlert.cooldownFadeTimeline:PlayFromStart()
	end
	HarvensPotionsAlert.prevRemain = remain
	HarvensPotionsAlert.prevGlobal = isGlobal
end

function HarvensPotionsAlert.CombatState(eventType, inCombat)
	HarvensPotionsAlert.isInCombat = inCombat
	if not inCombat and not HarvensPotionsAlert.isAlertHidden then
		HarvensPotionsAlert.alertFadeTimeline:PlayForward()
	-- give animation a final kick
	end
	if inCombat and HarvensPotionsAlert.sv.cooldownAlert then
		HarvensPotionsAlert.prevRemain, _, HarvensPotionsAlert.prevGlobal = GetSlotCooldownInfo(GetCurrentQuickslot(), HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
		EVENT_MANAGER:RegisterForUpdate("HarvensPotionsAlertCooldown", 100, HarvensPotionsAlert.CheckCooldown)
	else
		EVENT_MANAGER:UnregisterForUpdate("HarvensPotionsAlertCooldown")
	end
end

function HarvensPotionsAlert.TestCooldown()
	HarvensPotionsAlert.prevRemain = GetSlotCooldownInfo(GetCurrentQuickslot(), HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
	EVENT_MANAGER:RegisterForUpdate("HarvensPotionsAlertCooldown", 100, HarvensPotionsAlert.CheckCooldown)
end

function HarvensPotionsAlert:Initialize()
	HarvensPotionsAlert.powerTypes = {[POWERTYPE_HEALTH] = 1, [POWERTYPE_STAMINA] = 3, [POWERTYPE_MAGICKA] = 2, [1000] = 4}
	HarvensPotionsAlert.priority = {}
	for k, v in pairs(HarvensPotionsAlert.powerTypes) do
		-- reverse lookup for priority
		HarvensPotionsAlert.priority[v] = k
	end

	local defaults = {
		pos = {point = CENTER, relPoint = CENTER, x = 0, y = 0},
		scale = 1.0,
		slots = {},
		pos2 = {point = CENTER, relPoint = CENTER, x = 0, y = 0},
		cooldownAlert = true,
		cooldownAlertFont = "$(BOLD_FONT)|36|thick-outline",
		cooldownAlertIconSize = 48
	}

	for k, v in pairs(HarvensPotionsAlert.powerTypes) do
		defaults.slots[k] = {id = 0, threshold = 0, value = 100}
	end

	HarvensPotionsAlert.sv = ZO_SavedVars:New("HarvensPotionsAlert_SavedVariables", 1, nil, defaults)
	HarvensPotionsAlert.isAlertHidden = true
	HarvensPotionsAlert.alertPowerType = POWERTYPE_INVALID
	HarvensPotionsAlert.isInCombat = IsUnitInCombat("player")
	HarvensPotionsAlert.isAutoSwitch = false

	HarvensPotionsAlert.cooldownFadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("HarvensPotionsAlertFade", HarvensPotionsAlertCooldownAlert)
	HarvensPotionsAlertCooldownAlertLabel:SetFont(HarvensPotionsAlert.sv.cooldownAlertFont)
	HarvensPotionsAlertCooldownAlert:SetAnchor(HarvensPotionsAlert.sv.pos2.point, GuiRoot, HarvensPotionsAlert.sv.pos2.relPoint, HarvensPotionsAlert.sv.pos2.x, HarvensPotionsAlert.sv.pos2.y)
	HarvensPotionsAlertCooldownAlert:SetHandler(
		"OnMoveStop",
		function()
			local _, point, _, relPoint, x, y = HarvensPotionsAlertCooldownAlert:GetAnchor(0)
			HarvensPotionsAlert.sv.pos2 = nil
			HarvensPotionsAlert.sv.pos2 = {point = point, relPoint = relPoint, x = x, y = y}
		end
	)

	HarvensPotionsAlertCooldownAlertClose:SetHandler(
		"OnClicked",
		function()
			HarvensPotionsAlertCooldownAlertClose:SetMouseEnabled(false)
			HarvensPotionsAlertCooldownAlert:SetAlpha(0)
			HarvensPotionsAlertCooldownAlert:SetMouseEnabled(false)
		end
	)

	HarvensPotionsAlert.alertFadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("HarvensPotionsAlertFade", HarvensPotionsAlertTopLevel)
	HarvensPotionsAlert.alertFadeTimeline:SetHandler(
		"OnStop",
		function(...)
			HarvensPotionsAlert:InitialState()
			zo_callLater(HarvensPotionsAlert.Update, 20)
			-- A last check
		end
	)

	HarvensPotionsAlertTopLevel:ClearAnchors()
	HarvensPotionsAlertTopLevel:SetAnchor(HarvensPotionsAlert.sv.pos.point, GuiRoot, HarvensPotionsAlert.sv.pos.relPoint, HarvensPotionsAlert.sv.pos.x, HarvensPotionsAlert.sv.pos.y)
	HarvensPotionsAlertTopLevel:SetScale(HarvensPotionsAlert.sv.scale or 1.0)
	HarvensPotionsAlertTopLevel:SetHandler(
		"OnMoveStop",
		function()
			local _, point, _, relPoint, x, y = HarvensPotionsAlertTopLevel:GetAnchor(0)
			HarvensPotionsAlert.sv.pos = nil
			HarvensPotionsAlert.sv.pos = {point = point, relPoint = relPoint, x = x, y = y}
		end
	)

	HarvensPotionsAlertTopLevel:SetHandler(
		"OnMouseWheel",
		function(control, delta, ...)
			local scale = HarvensPotionsAlert.sv.scale or 1.0
			if delta > 0 then
				scale = math.min(8.0, scale + 0.05)
			else
				scale = math.max(0.5, scale - 0.05)
			end
			HarvensPotionsAlert.sv.scale = scale
			control:SetScale(scale)
		end
	)

	HarvensPotionsAlertTopLevelClose:SetHandler(
		"OnClicked",
		function()
			HarvensPotionsAlertTopLevelClose:SetHidden(true)
			HarvensPotionsAlert:InitialState()
		end
	)

	local keyBind = HarvensPotionsAlertTopLevelKeyBind:GetNamedChild("Bind")
	ZO_Keybindings_RegisterLabelForBindingUpdate(keyBind, "ACTION_BUTTON_9", HIDE_UNBOUND)
	ZO_KeyMarkupLabel_OnNewUserAreaCreated(keyBind, "key", nil, 0, 0, 0, 0, true)
	local bg = keyBind.keyBackdrops[1]
	bg:ClearAnchors()
	bg:SetAnchor(TOPLEFT, keyBind, TOPLEFT, -1, -1)
	bg:SetAnchor(BOTTOMRIGHT, keyBind, BOTTOMRIGHT, 2, 2)

	HarvensPotionsAlert:SetupOptions()
	EVENT_MANAGER:RegisterForEvent("HarvensPotionsAlertCombatState", EVENT_PLAYER_COMBAT_STATE, HarvensPotionsAlert.CombatState)
	EVENT_MANAGER:RegisterForEvent("HarvensPotionsAlertPowerUpdate", EVENT_POWER_UPDATE, HarvensPotionsAlert.PowerUpdate)
	EVENT_MANAGER:RegisterForEvent(
		"HarvensPotionsAlertQuickSlotUpdate",
		EVENT_ACTIVE_QUICKSLOT_CHANGED,
		function(eventId, slotId)
			if (slotId > 0 and slotId <= ACTION_BAR_UTILITY_BAR_SIZE) and not HarvensPotionsAlert.isAutoSwitch then
				HarvensPotionsAlert.sv.slots[1000].id = slotId
			end
		end
	)
end

function HarvensPotionsAlert.AddOnLoaded(eventType, addonName)
	if addonName ~= "HarvensPotionsAlert" then
		return
	end
	EVENT_MANAGER:UnregisterForEvent("HarvensPotionsAlertAddOnLoaded", EVENT_ADD_ON_LOADED)

	HarvensPotionsAlert:Initialize()
	HARVENS_POTIONS_ALERT = HarvensPotionsAlert
end

EVENT_MANAGER:RegisterForEvent("HarvensPotionsAlertAddOnLoaded", EVENT_ADD_ON_LOADED, HarvensPotionsAlert.AddOnLoaded)
