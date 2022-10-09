local addon = {
	name = "VotansImprovedMulticraft",
	defaults = {
		creationSpinner = {},
		autoMaxRefinement = false,
		nonCrafterProtect = false
	}
}
local em = GetEventManager()

local function GetCurrentCraftingExtractLevel()
	local craftingType = GetCraftingInteractionType()
	if craftingType == CRAFTING_TYPE_BLACKSMITHING then
		return GetNonCombatBonus(NON_COMBAT_BONUS_BLACKSMITHING_EXTRACT_LEVEL)
	elseif craftingType == CRAFTING_TYPE_CLOTHIER then
		return GetNonCombatBonus(NON_COMBAT_BONUS_CLOTHIER_EXTRACT_LEVEL)
	elseif craftingType == CRAFTING_TYPE_WOODWORKING then
		return GetNonCombatBonus(NON_COMBAT_BONUS_WOODWORKING_EXTRACT_LEVEL)
	elseif craftingType == CRAFTING_TYPE_JEWELRYCRAFTING then
		return GetNonCombatBonus(NON_COMBAT_BONUS_JEWELRYCRAFTING_EXTRACT_LEVEL)
	end
end

function addon:HookRefinement()
	local function showAlert()
		ZO_Alert(EVENT_UI_ERROR, SOUNDS.GENERAL_ALERT_ERROR, GetString(VOTANS_IMPROVED_MULTICRAFT_PASSIVE_NOT_MAXED))
	end
	local spinner = SMITHING.refinementPanel.multiRefineSpinner
	local modified = false
	local function setModified()
		modified = true
		local isCrafter = GetCurrentCraftingExtractLevel() >= 3
		if not isCrafter and addon.sv.nonCrafterProtect then
			showAlert()
			return true
		end
	end
	local orgModifyValue = spinner.ModifyValue
	function spinner.ModifyValue(...)
		if not setModified() then
			return orgModifyValue(...)
		end
	end
	ZO_PreHookHandler(spinner.minMaxButton, "OnClicked", setModified)
	local orgSetRefineIterationsToMax = ZO_SmithingRefinement.SetRefineIterationsToMax
	function ZO_SmithingRefinement.SetRefineIterationsToMax(...)
		local orgSetValue = spinner.SetValue
		function spinner:SetValue(value)
			local isCrafter = GetCurrentCraftingExtractLevel() >= 3
			if not isCrafter and addon.sv.nonCrafterProtect then
				value = 1
			end
			if addon.sv.autoMaxRefinement then
				value = zo_clamp(value, self:GetMin(), value)
			else
				value = zo_clamp(addon.sv.refinementSpinner or 1, self:GetMin(), value)
			end
			return orgSetValue(self, value)
		end
		orgSetRefineIterationsToMax(...)
		spinner.SetValue = orgSetValue
	end
	local orgConfirmRefine = ZO_SmithingRefinement.ConfirmRefine
	local function checkCrafterProtection(panel)
		local isCrafter = GetCurrentCraftingExtractLevel() >= 3
		if not isCrafter and addon.sv.nonCrafterProtect and panel:IsMultiExtract() then
			showAlert()
			return true
		end
		if modified then
			addon.sv.refinementSpinner = spinner:GetValue()
			modified = false
		end
	end
	function ZO_SmithingRefinement.ConfirmRefine(...)
		if not checkCrafterProtection(...) then
			return orgConfirmRefine(...)
		end
	end
end

do
	local sharedNumeric, owner
	local function lostFocus(control)
		if not owner then
			return
		end
		owner.display:SetHidden(false)
		control:SetHidden(true)
		owner = nil
	end
	local function textChanged(control)
		if not owner then
			return
		end
		local value = tonumber(control:GetText()) or 0
		value = zo_clamp(value, owner:GetMin(), owner:GetMax())
		value = value - owner:GetValue()
		if value ~= 0 then
			owner:ModifyValue(value)
		end
	end
	local function buttonClick(control, direction)
		owner:OnButtonDown(direction)
		owner:OnButtonUp()

		control:SetText(owner:GetValue())
	end

	local function downArrow(control)
		buttonClick(control, -1)
	end
	local function upArrow(control)
		buttonClick(control, 1)
	end
	local function downPage(control)
		buttonClick(control, -10)
	end
	local function upPage(control)
		buttonClick(control, 10)
	end

	local function createNumeric()
		local num = WINDOW_MANAGER:CreateControlFromVirtual("VotansImprovedMulticraftSharedNumeric", GuiRoot, "ZO_DefaultEditForBackdrop")
		num:SetFont("ZoFontWinH2")
		num:SetTextType(TEXT_TYPE_NUMERIC_UNSIGNED_INT)
		num:SetDrawLayer(DL_CONTROLS)
		num:SetDrawLevel(100)
		num:SetExcludeFromResizeToFitExtents(true)
		num:SetMaxInputChars(4)
		num:SetAllowMarkupType(ALLOW_MARKUP_TYPE_NONE)
		num:SetHandler("OnFocusLost", lostFocus)
		num:SetHandler("OnTextChanged", textChanged)
		num:SetHandler("OnDownArrow", downArrow)
		num:SetHandler("OnUpArrow", upArrow)
		num:SetHandler("OnPageDown", downPage)
		num:SetHandler("OnPageUp", upPage)

		sharedNumeric = num
		return num
	end
	local function onMouseUp(control, spinner, upInside)
		local num = sharedNumeric or createNumeric()
		if owner then
			lostFocus(num)
		end
		if not upInside or not (spinner.increaseButton:GetState() == BSTATE_NORMAL or spinner.decreaseButton:GetState() == BSTATE_NORMAL) then
			return
		end

		owner = spinner
		spinner.display:SetHidden(true)
		num:SetParent(control:GetParent())
		num:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
		num:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, 0, 0)
		num:SetHidden(false)
		num:SetText(spinner:GetValue())
		num:TakeFocus()
	end
	function addon:HookSpinner()
		local function setup(spinner)
			local display = spinner.display
			display:SetMouseEnabled(true)
			ZO_PreHookHandler(
				display,
				"OnMouseUp",
				function(control, button, upInside)
					onMouseUp(control, spinner, upInside)
				end
			)

			local orgOnButtonDown = spinner.OnButtonDown
			function spinner:OnButtonDown(direction, ...)
				if IsControlKeyDown() then
					direction = direction * 10
				end
				return orgOnButtonDown(self, direction, ...)
			end
		end
		setup(SMITHING.refinementPanel.multiRefineSpinner)
		setup(SMITHING.creationPanel.multiCraftSpinner)
		setup(PROVISIONER.multiCraftSpinner)
		setup(ALCHEMY.multiCraftSpinner)
		setup(ENCHANTING.multiCraftSpinner)
	end
end

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Improved Multicraft")
	if not settings then
		return
	end
	addon.settingsControls = settings
	settings.version = "1.0.0"
	settings.website = "https://www.esoui.com/downloads/info2445-VotansImprovedMulticraft.html"
	settings.allowDefaults = true

	self.defaults.nonCrafterProtect = GetNumCharacters() > 1
	-- local function UpdateControls()
	-- 	if settings.selected then
	-- 		settings:UpdateControls()
	-- 	end
	-- end
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(VOTANS_IMPROVED_MULTICRAFT_AUTO_MAX_REFINEMENT),
		tooltip = GetString(VOTANS_IMPROVED_MULTICRAFT_AUTO_MAX_REFINEMENT_TOOLTIP),
		default = self.defaults.autoMaxRefinement,
		getFunction = function()
			return self.sv.autoMaxRefinement
		end,
		setFunction = function(value)
			self.sv.autoMaxRefinement = value
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(VOTANS_IMPROVED_MULTICRAFT_NON_CRAFTER_PROTECT),
		tooltip = GetString(VOTANS_IMPROVED_MULTICRAFT_NON_CRAFTER_PROTECT_TOOLTIP),
		default = self.defaults.nonCrafterProtect,
		getFunction = function()
			return self.sv.nonCrafterProtect
		end,
		setFunction = function(value)
			self.sv.nonCrafterProtect = value
		end
		-- disable = function()
		-- 	return not self.sv.autoMaxRefinement
		-- end
	}
end

function addon:Initialize()
	self.sv = ZO_SavedVars:NewAccountWide("VotansImprovedMulticraft_Data", 1, nil, self.defaults)
	self:HookRefinement()
	self:HookSpinner()
	self:InitSettings()
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:Initialize()
end
em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
