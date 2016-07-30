local addon = {
	name = "SetManager",
	playerDefaults =
	{
		sets = { },
		worn = { },
		mode = "INVENTORY",
		quality = ITEM_QUALITY_MAGIC,
	},
	accountDefaults =
	{
		sets = { },
		templates = { },
	},
	setCategory =
	{
		NonCraftable = "NON_CRAFTABLE",
		Craftable = "CRAFTABLE",
	}
}

-- local am = GetAnimationManager()
local wm = GetWindowManager()
local em = GetEventManager()

do
	local function OnSlotClicked(parent, control)
		for equipSlot, other in pairs(parent.slots) do
			local selected = other == control
			if other:GetState() ~= BSTATE_DISABLED then
				other:SetState(selected and BSTATE_PRESSED or BSTATE_NORMAL)
			end
			if selected then parent.selectedSlot = equipSlot end
		end
		if parent.OnSelectedChanged then parent.OnSelectedChanged(parent) end
	end

	local function UpdateSlot(self)
		local iconControl = self:GetNamedChild("Icon")
		if self.itemLink then
			local icon = GetItemLinkInfo(self.itemLink)
			iconControl:SetTexture(icon)
		else
			iconControl:SetTexture(ZO_Character_GetEmptyEquipSlotTexture(self.slotId))
		end
	end

	function addon:InitializeSlots(parent)
		if parent.slots then return end

		local slots =
		{
			[EQUIP_SLOT_HEAD] = parent:GetNamedChild("EquipmentSlotsHead"),
			[EQUIP_SLOT_NECK] = parent:GetNamedChild("EquipmentSlotsNeck"),
			[EQUIP_SLOT_CHEST] = parent:GetNamedChild("EquipmentSlotsChest"),
			[EQUIP_SLOT_SHOULDERS] = parent:GetNamedChild("EquipmentSlotsShoulder"),
			[EQUIP_SLOT_MAIN_HAND] = parent:GetNamedChild("EquipmentSlotsMainHand"),
			[EQUIP_SLOT_OFF_HAND] = parent:GetNamedChild("EquipmentSlotsOffHand"),
			[EQUIP_SLOT_POISON] = parent:GetNamedChild("EquipmentSlotsPoison"),
			[EQUIP_SLOT_WAIST] = parent:GetNamedChild("EquipmentSlotsBelt"),
			[EQUIP_SLOT_LEGS] = parent:GetNamedChild("EquipmentSlotsLeg"),
			[EQUIP_SLOT_FEET] = parent:GetNamedChild("EquipmentSlotsFoot"),
			[EQUIP_SLOT_COSTUME] = parent:GetNamedChild("EquipmentSlotsCostume"),
			[EQUIP_SLOT_RING1] = parent:GetNamedChild("EquipmentSlotsRing1"),
			[EQUIP_SLOT_RING2] = parent:GetNamedChild("EquipmentSlotsRing2"),
			[EQUIP_SLOT_HAND] = parent:GetNamedChild("EquipmentSlotsGlove"),
			[EQUIP_SLOT_BACKUP_MAIN] = parent:GetNamedChild("EquipmentSlotsBackupMain"),
			[EQUIP_SLOT_BACKUP_OFF] = parent:GetNamedChild("EquipmentSlotsBackupOff"),
			[EQUIP_SLOT_BACKUP_POISON] = parent:GetNamedChild("EquipmentSlotsBackupPoison"),
		}

		parent.slots = slots

		parent:GetNamedChild("PaperDoll"):SetTexture(GetUnitSilhouetteTexture("player"))

		parent.OnSlotClicked = OnSlotClicked
		local ZO_Character_GetEmptyEquipSlotTexture = ZO_Character_GetEmptyEquipSlotTexture
		for slotId, slotControl in pairs(slots) do
			slotControl.slotId = slotId
			slotControl.Update = UpdateSlot
			slotControl:SetHandler("OnClicked", function(control, ...) control:GetParent():OnSlotClicked(control, ...) end)
		end
	end
end

function addon:FakeEquippedItemTooltip(itemLink)
	-- SetLink uses original functions only. They protected it.
	-- Rewrite Tooltip???
	ItemTooltip:SetLink(itemLink, true)
	ZO_ItemTooltip_SetStolen(ItemTooltip, false)
end

function addon:Init()
	SLASH_COMMANDS["/setm"] = function(...) addon:cmdSetManager(...) end

	local LMM2 = LibStub("LibMainMenu-2.0")
	LMM2:Init()
	self.LMM2 = LMM2

	self.Designer:Init()
	self.Selector:Init()

	self:InitInventoryScan()
end

local function PlayerActivated()
	em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	-- reserved
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.player = ZO_SavedVars:New("SetManager_Data", 1, nil, addon.playerDefaults, nil)
	addon.account = ZO_SavedVars:NewAccountWide("SetManager_Data", 1, nil, addon.accountDefaults, nil)

	local templates = addon.account.templates
	if #templates == 0 then
		templates[#templates + 1] = { }
	end

	addon:Init()

	em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, PlayerActivated)
end

function addon:ToggleEditorScene()
	self.LMM2:SelectMenuItem(self.name)
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

SET_MANAGER = addon