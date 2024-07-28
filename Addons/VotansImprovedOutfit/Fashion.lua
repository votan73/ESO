local addon = VOTANS_IMPROVED_OUTFIT

local ZO_RESTYLE_SHEET_CONTAINER = ZO_RESTYLE_SHEET_CONTAINER

local UndoBuffer = addon.UndoBuffer
local RedoBuffer = addon.RedoBuffer

local version = 1

local slotGridData = {
	[RESTYLE_MODE_EQUIPMENT] = {
		[ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = {
			[EQUIP_SLOT_HEAD] = {row = 1, column = 1, controlName = "Head"},
			[EQUIP_SLOT_SHOULDERS] = {row = 2, column = 1, controlName = "Shoulders"},
			[EQUIP_SLOT_CHEST] = {row = 2, column = 2, controlName = "Chest"},
			[EQUIP_SLOT_HAND] = {row = 3, column = 1, controlName = "Hands"},
			[EQUIP_SLOT_WAIST] = {row = 3, column = 2, controlName = "Waist"},
			[EQUIP_SLOT_LEGS] = {row = 4, column = 1, controlName = "Legs"},
			[EQUIP_SLOT_FEET] = {row = 4, column = 2, controlName = "Feet"}
		},
		[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = {
			-- Switches with Shield on show based on ActiveWeaponPair
			[EQUIP_SLOT_MAIN_HAND] = {row = 1, column = 1, controlName = "Right"},
			[EQUIP_SLOT_OFF_HAND] = {row = 1, column = 2, controlName = "Left"},
			[EQUIP_SLOT_BACKUP_MAIN] = {row = 2, column = 1, controlName = "RightB"},
			[EQUIP_SLOT_BACKUP_OFF] = {row = 2, column = 2, controlName = "LeftB"}
		}
	},
	[RESTYLE_MODE_COLLECTIBLE] = {
		[ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = {
			[COLLECTIBLE_CATEGORY_TYPE_HAT] = {row = 1, column = 1, controlName = "Head"},
			[COLLECTIBLE_CATEGORY_TYPE_COSTUME] = {row = 1, column = 2, controlName = "Chest"}
		}
	},
	[RESTYLE_MODE_OUTFIT] = {
		[ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = {
			[OUTFIT_SLOT_HEAD] = {row = 1, column = 1, controlName = "Head"},
			[OUTFIT_SLOT_SHOULDERS] = {row = 2, column = 1, controlName = "Shoulders"},
			[OUTFIT_SLOT_CHEST] = {row = 2, column = 2, controlName = "Chest"},
			[OUTFIT_SLOT_HANDS] = {row = 3, column = 1, controlName = "Hands"},
			[OUTFIT_SLOT_WAIST] = {row = 3, column = 2, controlName = "Waist"},
			[OUTFIT_SLOT_LEGS] = {row = 4, column = 1, controlName = "Legs"},
			[OUTFIT_SLOT_FEET] = {row = 4, column = 2, controlName = "Feet"}
		},
		[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = {
			-- Switches with Shield on show based on ActiveWeaponPair and equipped weapon type
			[OUTFIT_SLOT_WEAPON_TWO_HANDED] = {row = 1, column = 1, controlName = "Right"},
			[OUTFIT_SLOT_SHIELD] = {row = 1, column = 2, controlName = "Left"},
			[OUTFIT_SLOT_WEAPON_MAIN_HAND] = {row = 1, column = 1, controlName = "Right"},
			[OUTFIT_SLOT_WEAPON_OFF_HAND] = {row = 1, column = 2, controlName = "Left"},
			[OUTFIT_SLOT_WEAPON_BOW] = {row = 1, column = 1, controlName = "Right"},
			[OUTFIT_SLOT_WEAPON_STAFF] = {row = 1, column = 1, controlName = "Right"},
			[OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP] = {row = 2, column = 1, controlName = "RightB"},
			[OUTFIT_SLOT_SHIELD_BACKUP] = {row = 2, column = 2, controlName = "LeftB"},
			[OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP] = {row = 2, column = 1, controlName = "RightB"},
			[OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = {row = 2, column = 2, controlName = "LeftB"},
			[OUTFIT_SLOT_WEAPON_BOW_BACKUP] = {row = 2, column = 1, controlName = "RightB"},
			[OUTFIT_SLOT_WEAPON_STAFF_BACKUP] = {row = 2, column = 1, controlName = "RightB"}
		}
	},
	[RESTYLE_MODE_COMPANION_EQUIPMENT] = {
		[ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = {
			-- [EQUIP_SLOT_HEAD] = {row = 1, column = 1, controlName = "Head"},
			[EQUIP_SLOT_SHOULDERS] = {row = 2, column = 1, controlName = "Shoulders"},
			[EQUIP_SLOT_CHEST] = {row = 2, column = 2, controlName = "Chest"},
			[EQUIP_SLOT_HAND] = {row = 3, column = 1, controlName = "Hands"},
			[EQUIP_SLOT_WAIST] = {row = 3, column = 2, controlName = "Waist"},
			[EQUIP_SLOT_LEGS] = {row = 4, column = 1, controlName = "Legs"},
			[EQUIP_SLOT_FEET] = {row = 4, column = 2, controlName = "Feet"}
		},
		[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = {
			-- Switches with Shield on show based on ActiveWeaponPair
			[EQUIP_SLOT_MAIN_HAND] = {row = 1, column = 1, controlName = "Right"},
			[EQUIP_SLOT_OFF_HAND] = {row = 1, column = 2, controlName = "Left"}
			-- [EQUIP_SLOT_BACKUP_MAIN] = {row = 2, column = 1, controlName = "RightB"},
			-- [EQUIP_SLOT_BACKUP_OFF] = {row = 2, column = 2, controlName = "LeftB"}
		}
	},
	[RESTYLE_MODE_COMPANION_COLLECTIBLE] = {
		[ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = {
			--[COLLECTIBLE_CATEGORY_TYPE_HAT] = {row = 1, column = 1, controlName = "Head"},
			[COLLECTIBLE_CATEGORY_TYPE_COSTUME] = {row = 1, column = 2, controlName = "Chest"}
		}
	},
	[RESTYLE_MODE_COMPANION_OUTFIT] = {
		[ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = {
			--[OUTFIT_SLOT_HEAD] = {row = 1, column = 1, controlName = "Head"},
			[OUTFIT_SLOT_SHOULDERS] = {row = 2, column = 1, controlName = "Shoulders"},
			[OUTFIT_SLOT_CHEST] = {row = 2, column = 2, controlName = "Chest"},
			[OUTFIT_SLOT_HANDS] = {row = 3, column = 1, controlName = "Hands"},
			[OUTFIT_SLOT_WAIST] = {row = 3, column = 2, controlName = "Waist"},
			[OUTFIT_SLOT_LEGS] = {row = 4, column = 1, controlName = "Legs"},
			[OUTFIT_SLOT_FEET] = {row = 4, column = 2, controlName = "Feet"}
		},
		[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = {
			-- Switches with Shield on show based on ActiveWeaponPair and equipped weapon type
			[OUTFIT_SLOT_WEAPON_TWO_HANDED] = {row = 1, column = 1, controlName = "Right"},
			[OUTFIT_SLOT_SHIELD] = {row = 1, column = 2, controlName = "Left"},
			[OUTFIT_SLOT_WEAPON_MAIN_HAND] = {row = 1, column = 1, controlName = "Right"},
			[OUTFIT_SLOT_WEAPON_OFF_HAND] = {row = 1, column = 2, controlName = "Left"},
			[OUTFIT_SLOT_WEAPON_BOW] = {row = 1, column = 1, controlName = "Right"},
			[OUTFIT_SLOT_WEAPON_STAFF] = {row = 1, column = 1, controlName = "Right"}
			-- [OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP] = {row = 2, column = 1, controlName = "RightB"},
			-- [OUTFIT_SLOT_SHIELD_BACKUP] = {row = 2, column = 2, controlName = "LeftB"},
			-- [OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP] = {row = 2, column = 1, controlName = "RightB"},
			-- [OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = {row = 2, column = 2, controlName = "LeftB"},
			-- [OUTFIT_SLOT_WEAPON_BOW_BACKUP] = {row = 2, column = 1, controlName = "RightB"},
			-- [OUTFIT_SLOT_WEAPON_STAFF_BACKUP] = {row = 2, column = 1, controlName = "RightB"}
		}
	}
}

local emptyCollectible = {
	[COLLECTIBLE_CATEGORY_TYPE_COSTUME] = "EsoUI/Art/Dye/dye_costume.dds",
	[COLLECTIBLE_CATEGORY_TYPE_HAT] = "EsoUI/Art/Dye/dye_hat.dds"
}

local isNotWeapon = {
	[EQUIP_SLOT_HEAD] = true,
	[EQUIP_SLOT_SHOULDERS] = true,
	[EQUIP_SLOT_CHEST] = true,
	[EQUIP_SLOT_HAND] = true,
	[EQUIP_SLOT_WAIST] = true,
	[EQUIP_SLOT_LEGS] = true,
	[EQUIP_SLOT_FEET] = true
}

local oppositeOutfitSlot = {
	[OUTFIT_SLOT_WEAPON_TWO_HANDED] = OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP,
	[OUTFIT_SLOT_SHIELD] = OUTFIT_SLOT_SHIELD_BACKUP,
	[OUTFIT_SLOT_WEAPON_MAIN_HAND] = OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP,
	[OUTFIT_SLOT_WEAPON_OFF_HAND] = OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP,
	[OUTFIT_SLOT_WEAPON_BOW] = OUTFIT_SLOT_WEAPON_BOW_BACKUP,
	[OUTFIT_SLOT_WEAPON_STAFF] = OUTFIT_SLOT_WEAPON_STAFF_BACKUP,
	[OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP] = OUTFIT_SLOT_WEAPON_TWO_HANDED,
	[OUTFIT_SLOT_SHIELD_BACKUP] = OUTFIT_SLOT_SHIELD,
	[OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP] = OUTFIT_SLOT_WEAPON_MAIN_HAND,
	[OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = OUTFIT_SLOT_WEAPON_OFF_HAND,
	[OUTFIT_SLOT_WEAPON_BOW_BACKUP] = OUTFIT_SLOT_WEAPON_BOW,
	[OUTFIT_SLOT_WEAPON_STAFF_BACKUP] = OUTFIT_SLOT_WEAPON_STAFF
}

local function IsEquipmentMode(mode)
	return mode == RESTYLE_MODE_EQUIPMENT or mode == RESTYLE_MODE_COMPANION_EQUIPMENT
end

local function IsCollectibleMode(mode)
	return mode == RESTYLE_MODE_COLLECTIBLE or mode == RESTYLE_MODE_COMPANION_COLLECTIBLE
end

local function IsOutfitMode(mode)
	return mode == RESTYLE_MODE_OUTFIT or mode == RESTYLE_MODE_COMPANION_OUTFIT
end

local function SlotCurrentlyUseable(restyleMode, slotType)
	if not IsOutfitMode(restyleMode) then
		return true
	end
	local equipSlot = GetEquipSlotForOutfitSlot(slotType)
	local actorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(restyleMode)
	return isNotWeapon[equipSlot] or CanEquippedItemBeShownInOutfitSlot(actorCategory, equipSlot, slotType)
end

local function UpdateKeybind()
	KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.keybindButtonGroupFashion)
end

function addon:EnumerateFashionSlots(data)
	return string.gmatch(data, ":(%d+)/(%d+),(%d+),(%d+)([^:]*)")
end

local function GetFashionStyles(data)
	local style = {}
	for slotType, d1, d2, d3, collectibleId in addon:EnumerateFashionSlots(data) do
		style[tonumber(slotType)] = {tonumber(d1), tonumber(d2), tonumber(d3), tonumber(collectibleId)}
	end
	return style
end

local function BetterSwapBars(restyleMode, style)
	if not IsOutfitMode(restyleMode) then
		return false
	end

	local betterSwap = 0
	local CanEquippedItemBeShownInOutfitSlot, GetEquipSlotForOutfitSlot = CanEquippedItemBeShownInOutfitSlot, GetEquipSlotForOutfitSlot
	for slotType, item in pairs(style) do
		local oppositeSlotType = oppositeOutfitSlot[slotType]
		if oppositeSlotType then
			if CanEquippedItemBeShownInOutfitSlot(GetEquipSlotForOutfitSlot(slotType), slotType) then
				betterSwap = betterSwap - 1
			elseif CanEquippedItemBeShownInOutfitSlot(GetEquipSlotForOutfitSlot(oppositeSlotType), oppositeSlotType) then
				betterSwap = betterSwap + 1
			end
		end
	end
	return betterSwap > 0
end

local function GetFashionName(link)
	return string.match(link, ":([^%d][^:]-)$") or ""
end

local function FindInMasterList(self, link)
	if not link then
		return
	end

	for index, entry in ipairs(self.masterList) do
		if entry == link then
			return index
		end
	end
end

local function GetSelected(self)
	local selected = ZO_ScrollList_GetSelectedData(self.list)
	local link = selected and selected.link
	local index = FindInMasterList(self, link)
	return index, selected
end

local function CreateFashionFilter(result, name, filter)
	result = result or {}
	local sheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
	local restyleMode = sheet:GetRestyleMode()
	local slots = sheet:GetSlots()
	result[#result + 1] = "VOF"
	result[#result + 1] = version
	result[#result + 1] = ":"
	result[#result + 1] = restyleMode
	result[#result + 1] = ":"
	local hasData = false
	for slotType, slotData in pairs(slots) do
		if SlotCurrentlyUseable(restyleMode, slotType) then
			local restyleSlotData = slotData:GetRestyleSlotData()

			local d1, d2, d3 = restyleSlotData:GetPendingDyes()
			local collectibleData = filter and filter(slotType, slotData) or restyleSlotData:GetPendingCollectibleData()

			if collectibleData or d1 ~= 0 or d2 ~= 0 or d3 ~= 0 then
				result[#result + 1] = slotType
				result[#result + 1] = "/"
				result[#result + 1] = d1
				result[#result + 1] = ","
				result[#result + 1] = d2
				result[#result + 1] = ","
				result[#result + 1] = d3

				if collectibleData and collectibleData.collectibleId and collectibleData.collectibleId > 0 then
					result[#result + 1] = "+"
					result[#result + 1] = collectibleData.collectibleId
				end

				result[#result + 1] = ":"

				hasData = true
			end
		end
	end
	if hasData then
		if name then
			result[#result + 1] = name
		elseif IsCollectibleMode(restyleMode) then
			local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_COSTUME)) or ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_HAT))
			if collectibleData then
				result[#result + 1] = collectibleData:GetFormattedName()
			end
		else
			if restyleMode == RESTYLE_MODE_OUTFIT then
				result[#result + 1] = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD.modeSelectorDropdown:GetSelectedItem()
				result[#result + 1] = "@"
			end
			if restyleMode ~= RESTYLE_MODE_COMPANION_OUTFIT then
				result[#result + 1] = GetUnitName("player")
			else
				local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_COMPANION, GAMEPLAY_ACTOR_CATEGORY_PLAYER))
				result[#result + 1] = zo_strformat("<<C:1>>", collectibleData:GetName())
			end
		end
	end
	return hasData and table.concat(result) or ""
end

local function fromPreviewFilter(slotType, slotData)
	return ZO_OUTFIT_STYLES_PANEL_KEYBOARD.currentSlotPreviews[slotType]
end

local function CreateFashion(result, name)
	if ZO_OUTFIT_STYLES_BOOK_SCENE:IsShowing() then
		return CreateFashionFilter(result, name, fromPreviewFilter)
	else
		return CreateFashionFilter(result, name)
	end
end

do
	local function GetFashion()
		local result = {}
		StartChatInput(CreateFashion(result))
	end
	SLASH_COMMANDS["/getfashion"] = GetFashion
end

-- SLASH_COMMANDS["/zgoo"](slots)

---------------------- Select Fashion ----------------------
local cooldown = 0
local customData = {}
local ProcessFashionData
local atOutfitStation

local identifier = "VOTANS_IMPROVED_OUTFIT_COLLECTIBLE_COOLDOWN"

local function CancelCooldown()
	EVENT_MANAGER:UnregisterForUpdate(identifier)
	customData[1], customData[2], customData[3] = nil, nil, nil
end

local function waitForCooldown()
	local sheet, restyleMode, data = unpack(customData)
	CancelCooldown()
	if sheet then
		ProcessFashionData(sheet, restyleMode, data)
	end
end
local function restart()
	if customData[1] then
		EVENT_MANAGER:RegisterForUpdate(identifier, cooldown, waitForCooldown)
	end
end

local function StartSwapCollectible(sheet, restyleMode, data, collectibleId)
	customData[1], customData[2], customData[3] = sheet, restyleMode, data
	addon:SuspendUndo()
	UseCollectible(collectibleId)
	return true
end

-- declared local above
function ProcessFashionData(sheet, restyleMode, data)
	local slots = sheet:GetSlots()

	if IsCollectibleMode(restyleMode) then
		local processed = {}
		-- Check all right collectibles are equipped
		local function checkCollectibles(slotType, collectibleId)
			slotType = tonumber(slotType)
			if not SlotCurrentlyUseable(restyleMode, slotType) then
				return
			end

			local slotData = slots[slotType]
			if not slotData then
				return
			end

			processed[slotType] = true

			local restyleSlotData = slotData:GetRestyleSlotData()
			local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)

			collectibleId = tonumber(collectibleId) or 0
			local activeCollectibleId = GetActiveCollectibleByType(slotType)
			if activeCollectibleId ~= collectibleId then
				if collectibleId > 0 then
					local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
					if collectibleData and collectibleData:IsOwned() and collectibleData:IsShownInCollection() then
						return StartSwapCollectible(sheet, restyleMode, data, collectibleId)
					else
						return false
					end
				elseif activeCollectibleId > 0 then
					return StartSwapCollectible(sheet, restyleMode, data, activeCollectibleId)
				end
			end
		end
		cooldown = 1000
		for slotType, _, _, _, collectibleId in addon:EnumerateFashionSlots(data) do
			local result = checkCollectibles(slotType, collectibleId)
			if result == true then
				return
			end
			if result == false then
				ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, "Collectible not unlocked.")
				return
			end
			cooldown = 0
		end
		for slotType in pairs(slots) do
			if not processed[slotType] then
				local result = checkCollectibles(slotType, 0, 0, 0, 0)
				if result == true then
					return
				end
				if result == false then
					return
				end
				cooldown = 0
			end
		end

		-- Passed though here: All collectibles equipped
		addon:BeginTransaction(UndoBuffer)
		sheet:UndoPendingChanges()
	elseif IsOutfitMode(restyleMode) then
		local selectedFashion = {}
		local colors = GetFashionStyles(data)
		for _, slot in pairs(colors) do
			if slot[4] then
				selectedFashion[slot[4]] = slot
				slot[4] = nil
			end
		end
		addon.selectedFashion = selectedFashion
		return
	else
		addon.selectedFashion = nil
		addon:BeginTransaction(UndoBuffer)
	end

	addon:ResumeUndo()

	local withCollectible = IsOutfitMode(restyleMode)
	local style = GetFashionStyles(data)
	if withCollectible and BetterSwapBars(restyleMode, style) then
		for slotType in pairs(slots) do
			local otherSlotType = oppositeOutfitSlot[slotType]
			if otherSlotType and slotType < otherSlotType then
				style[otherSlotType], style[slotType] = style[slotType], style[otherSlotType]
			end
		end
	end

	local processed = {}
	local function processSlot(slotType, item)
		if not SlotCurrentlyUseable(restyleMode, slotType) then
			return
		end

		local slotData = slots[slotType]
		if not slotData then
			return
		end

		local d1, d2, d3, collectibleId = unpack(item)
		processed[slotType] = true

		local restyleSlotData = slotData:GetRestyleSlotData()
		local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)

		if withCollectible then
			local currentCollectibleId = slotManipulator:GetPendingCollectibleId()
			if currentCollectibleId ~= collectibleId then
				if collectibleId and collectibleId > 0 then
					local materialIndex = slotManipulator:GetPendingItemMaterialIndex() or slotManipulator:GetCurrentItemMaterialIndex() or ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX
					slotManipulator:SetPendingCollectibleIdAndItemMaterialIndex(collectibleId, materialIndex)
				else
					slotManipulator:ClearPendingChanges()
				end
			end
		end

		restyleSlotData = slotData:GetRestyleSlotData()

		restyleSlotData:SetPendingDyes(d1, d2, d3)

		slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)
		if slotManipulator then
			slotManipulator:OnPendingDataChanged()
		end

		local actorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(restyleMode) or GAMEPLAY_ACTOR_CATEGORY_PLAYER
		local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(actorCategory, restyleSlotData:GetRestyleSetIndex())
		outfitManipulator:OnSlotPendingDataChanged(restyleSlotData:GetRestyleSetIndex())

		if not withCollectible then
			local station = IsInGamepadPreferredMode() and ZO_RESTYLE_STATION_GAMEPAD or ZO_RESTYLE_STATION_KEYBOARD
			station:OnPendingDyesChanged(restyleSlotData)
		end
	end
	local function clearSlot(slotData, withCollectible)
		local restyleSlotData = slotData:GetRestyleSlotData()
		local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)
		local changed = false
		if withCollectible then
			local currentCollectibleId = slotManipulator:GetPendingCollectibleId()
			if currentCollectibleId and currentCollectibleId ~= 0 then
				slotManipulator:ClearPendingChanges()
				changed = true
			end
		end
		local d1, d2, d3 = restyleSlotData:GetPendingDyes()
		if d1 ~= 0 or d2 ~= 0 or d3 ~= 0 then
			restyleSlotData:SetPendingDyes(0, 0, 0)
			changed = true
		end
		if changed then
			slotManipulator:OnPendingDataChanged()
		end
	end

	for slotType, item in pairs(style) do
		processSlot(slotType, item)
	end

	for slotType, slotData in pairs(slots) do
		if not processed[slotType] and SlotCurrentlyUseable(restyleMode, slotType) then
			clearSlot(slotData, withCollectible)
		end
	end

	if not IsOutfitMode(restyleMode) then
		local station = IsInGamepadPreferredMode() and ZO_RESTYLE_STATION_GAMEPAD or ZO_DYEING_KEYBOARD
		station:OnPendingDyesChanged()
	end

	addon:EndTransaction()
end

local function SetFashion(text)
	local ZO_RESTYLE_SHEET_WINDOW_KEYBOARD, ZO_RESTYLE_STATION_KEYBOARD = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD, ZO_RESTYLE_STATION_KEYBOARD

	local version, restyleMode, data = string.match(text, "^VOF(%d+):(%d+)(:.+)")
	if not version then
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, "No outfit fashion data")
		return
	end
	version, restyleMode = tonumber(version), tonumber(restyleMode)
	if version ~= 1 then
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, string.format("Unsupported version: %i", version))
		return
	end
	local sheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
	if sheet:GetRestyleMode() ~= restyleMode then
		if IsCollectibleMode(restyleMode) and not CanUseCollectibleDyeing() then
			ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, "you can not dye collectibles")
			return
		end
		ZO_RESTYLE_STATION_KEYBOARD:SelectTabDescriptor(IsCollectibleMode(restyleMode) and ZO_RESTYLE_STATION_KEYBOARD.collectiblesTabDescriptor or ZO_RESTYLE_STATION_KEYBOARD.equipmentTabDescriptor)
		ZO_RESTYLE_STATION_KEYBOARD:InitializeModeData()
		if not IsCollectibleMode(restyleMode) then
			local defaultEntry = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD.equipmentGearModeEntry
			local selector = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD.modeSelectorDropdown
			if IsEquipmentMode(restyleMode) then
				if selector:GetSelectedItemData() ~= defaultEntry then
					selector:SelectItem(defaultEntry)
				end
			elseif IsOutfitMode(restyleMode) then
				if selector:GetSelectedItemData() == defaultEntry then
					selector:SelectItemByIndex(2)
				end
			end
		end
		sheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetSheetByMode(restyleMode)
	end
	ProcessFashionData(sheet, restyleMode, data)
end

SLASH_COMMANDS["/setfashion"] = SetFashion

function addon:SelectFashion(previouslySelectedData, selectedData, reselectingDuringRebuild)
	UpdateKeybind()
	self.selectedFashion = nil
	if reselectingDuringRebuild then
		return
	end
	local link = selectedData and selectedData.link
	if link then
		SetFashion(link)
	end
end

function addon:InitFashionFilter()
	local filteredCollections = COLLECTIONS_BOOK_SINGLETON
	local baseGetSearchResults = filteredCollections.GetSearchResults
	function filteredCollections:GetSearchResults()
		if not atOutfitStation or not addon.selectedFashion or zo_strlen(self.searchString) > 1 then
			return baseGetSearchResults(self)
		end

		local selectedFashion = addon.selectedFashion

		local ZO_COLLECTIBLE_DATA_MANAGER = ZO_COLLECTIBLE_DATA_MANAGER

		local function filter(data)
			if not data then
				return false
			end
			return selectedFashion[data.collectibleId] ~= nil
		end

		local function buildSubCategory(categoryIndex)
			local categoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex)
			local list, collectibles, sublist
			for subCategoryIndex = 1, categoryData:GetNumSubcategories() do
				collectibles = categoryData:GetSubcategoryData(subCategoryIndex)
				for collectibleIndex = 1, collectibles:GetNumCollectibles() do
					if filter(collectibles:GetCollectibleDataByIndex(collectibleIndex)) then
						list = list or {}
						sublist = list[subCategoryIndex] or {}
						list[subCategoryIndex] = sublist
						sublist[collectibleIndex] = true
					end
				end
			end
			return list
		end
		result = {}
		result[addon.categoryIndexArmor] = buildSubCategory(addon.categoryIndexArmor)
		result[addon.categoryIndexWeapon] = buildSubCategory(addon.categoryIndexWeapon)
		return result
	end

	local orgSetPendingOutfitStyleInCurrentOutfit = ZO_OutfitStylesPanel_Keyboard.SetPendingOutfitStyleInCurrentOutfit
	function ZO_OutfitStylesPanel_Keyboard.SetPendingOutfitStyleInCurrentOutfit(...)
		local panel, collectibleData, itemMaterialIndex, preferredOutfitSlot = ...
		if self.selectedFashion and panel.currentOutfitManipulator then
			preferredOutfitSlot = preferredOutfitSlot or ZO_OUTFIT_MANAGER:GetPreferredOutfitSlotForStyle(collectibleData)

			if preferredOutfitSlot then
				local slotManipulator = panel.currentOutfitManipulator:GetSlotManipulator(preferredOutfitSlot)
				local collectibleId = collectibleData.clearAction and 0 or collectibleData:GetId()
				local colors = self.selectedFashion[collectibleId]
				if colors then
					local self = panel.restyleSlotData
					SetPendingSlotDyes(self.restyleMode, self.restyleSetIndex, self.restyleSlotType, unpack(colors))
				end
			end
		end
		return orgSetPendingOutfitStyleInCurrentOutfit(...)
	end
end

---------------------------------------------------------

local ROW_ID = 1

function addon:SetupFashionList()
	ZO_ScrollList_AddDataType(
		self.list,
		ROW_ID,
		"VotansFashionRowTemplate",
		520,
		function(control, data)
			self:SetupRow(control, data)
		end
	)
	ZO_ScrollList_SetTypeSelectable(self.list, ROW_ID, true)
	ZO_ScrollList_SetDeselectOnReselect(self.list, true)
	ZO_ScrollList_EnableSelection(
		self.list,
		"VotansFashionHighlight",
		function(...)
			self:SelectFashion(...)
		end
	)
	ZO_ScrollList_EnableHighlight(self.list, "VotansFashionHighlight")

	local pool = ZO_ScrollList_GetDataTypeTable(self.list, ROW_ID).pool
	local orgFactory = pool.m_Factory
	local function factory(...)
		local control = orgFactory(...)
		local CreateControlFromVirtual = CreateControlFromVirtual
		local container = control:GetNamedChild("Container")
		control.container = container

		control:SetMouseEnabled(true)
		container:SetMouseEnabled(false)

		control.headers = {
			[ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = container:GetNamedChild("PrimaryHeader"),
			[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = container:GetNamedChild("SecondaryHeader")
		}

		control.slotContainers = {
			[ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = container:GetNamedChild("PrimarySlots"),
			[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = container:GetNamedChild("SecondarySlots")
		}

		control.slots = {}
		control.slotNames = {}

		return control
	end
	pool.m_Factory = factory

	local orgOnSearchTextChanged = ZO_RESTYLE_STATION_KEYBOARD.OnSearchTextChanged
	function ZO_RESTYLE_STATION_KEYBOARD.OnSearchTextChanged(...)
		if addon.fragment:IsShowing() then
			local self = ...
			ZO_EditDefaultText_OnTextChanged(self.contentSearchEditBox)
			addon:MarkFashionListDirty()
			return addon:BuildFashionList()
		end
		return orgOnSearchTextChanged(...)
	end

	local function ClearCache()
		if self.fragment:IsShowing() then
			local scrollData = ZO_ScrollList_GetDataList(self.list)
			for _, row in pairs(scrollData) do
				row.data.style = nil
			end
			ZO_ScrollList_RefreshVisible(self.list)
		else
			self:MarkFashionListDirty()
		end
	end

	local function RegisterEvents()
		self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, ClearCache)
		self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, ClearCache)
		self.control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)
	end

	local function UnregisterEvents()
		self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
		self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
	end

	ZO_RESTYLE_SCENE:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_SHOWN then
				atOutfitStation = true
				RegisterEvents()
			elseif newState == SCENE_HIDING then
				atOutfitStation = false
				UnregisterEvents()
			end
		end
	)
end

do
	local GRID_PADDING_X = 30
	local GRID_PADDING_Y = 12

	local function AreDyeChannelsDyeable(restyleMode, restyleSetIndex, restyleSlotType, collectibleId)
		if IsOutfitMode(restyleMode) then
			return AreDyeChannelsDyeableForOutfitSlotData(restyleSlotType, collectibleId)
		elseif IsCollectibleMode(restyleMode) then
			if not collectibleId or collectibleId == 5002 then
				return false, false, false
			else
				return true, true, true
			end
		else
			return AreRestyleSlotDyeChannelsDyeable(restyleMode, restyleSetIndex, restyleSlotType)
		end
	end

	local function SetupDyeControls(slotControl, restyleMode, restyleSetIndex, dyeableSlot, collectibleId, ...)
		local isDyeable = not IsOutfitMode(restyleMode) or IsRestyleSlotDataDyeable(restyleMode, restyleSetIndex, dyeableSlot)

		local ZO_DyeingUtils_SetSlotDyeSwatchDyeId = ZO_DyeingUtils_SetSlotDyeSwatchDyeId
		local isChannelDyeableTable = isDyeable and {AreDyeChannelsDyeable(restyleMode, restyleSetIndex, dyeableSlot, collectibleId)}
		for dyeChannel, dyeControl in ipairs(slotControl.dyeControls) do
			if isDyeable then
				dyeControl:SetHidden(false)
				local currentDyeId = select(dyeChannel, ...)
				ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeControl, currentDyeId, isChannelDyeableTable[dyeChannel])
			else
				dyeControl:SetHidden(true)
			end
		end
	end

	local function CreateSlotItem(container, gridData)
		local item = CreateControlFromVirtual("$(parent)" .. gridData.controlName, container, "ZO_RestyleOutfitStyleSlotsSheet_Slot_Keyboard")
		item:SetMouseEnabled(false)
		local itemSlot = item:GetNamedChild("ItemSlot")
		itemSlot:SetMouseEnabled(false)
		local dyes = item:GetNamedChild("Dyes")
		for _, dyeControl in pairs(dyes.dyeControls) do
			dyeControl:SetMouseEnabled(false)
		end
		return item
	end

	local slots, slotNames
	local function CreateSlot(control, containerKey, slotsData)
		local container = control.slotContainers[containerKey]
		for restyleSlotType, gridData in pairs(slotsData) do
			local slot = control.slotNames[gridData.controlName] or CreateSlotItem(container, gridData)
			slots[restyleSlotType] = slot
			slotNames[gridData.controlName] = slot

			slot:ClearAnchors()
			local offsetX = (ZO_RESTYLE_SLOT_WIDTH + GRID_PADDING_X) * (gridData.column - 1) + 35
			local offsetY = (ZO_RESTYLE_SLOT_HEIGHT + GRID_PADDING_Y) * (gridData.row - 1)
			slot:SetAnchor(TOPLEFT, nil, TOPLEFT, offsetX, offsetY)
		end
	end

	local function process(restyleMode, slotType, setIndex, collectibleId, d1, d2, d3)
		local slot = slots[slotType]
		if not slot then
			return false
		end

		slot:SetHidden(false)

		local itemSlot = slot:GetNamedChild("ItemSlotIcon")
		if collectibleId then
			local icon = select(3, GetCollectibleInfo(collectibleId))
			itemSlot:SetTexture(icon)
		else
			if IsEquipmentMode(restyleMode) then
				local icon, stack = GetItemInfo(BAG_WORN, slotType)
				icon = stack > 0 and icon or ZO_Character_GetEmptyEquipSlotTexture(slotType)
				itemSlot:SetTexture(icon)
			elseif IsCollectibleMode(restyleMode) then
				local icon = emptyCollectible[slotType]
				itemSlot:SetTexture(icon)
			else
				local slotIndex = GetEquipSlotForOutfitSlot(slotType)
				local icon = ZO_Character_GetEmptyEquipSlotTexture(slotIndex)
				itemSlot:SetTexture(icon)
			end
		end

		SetupDyeControls(slot:GetNamedChild("Dyes"), restyleMode, setIndex, slotType, collectibleId, d1, d2, d3)
		return true
	end

	function addon:SetupRow(control, rowData)
		local restyleMode, data = string.match(rowData.link, "^VOF%d+:(%d+)(:.+)")
		restyleMode = tonumber(restyleMode)
		slots, slotNames = control.slots, control.slotNames
		ZO_ClearTable(slots)

		local isSmall = IsCollectibleMode(restyleMode)
		control:SetHeight(isSmall and 130 or 520)
		control.container:GetNamedChild("PrimaryDivider"):SetHidden(isSmall)

		local slotGridData = slotGridData[restyleMode]
		for containerKey, slotsData in pairs(slotGridData) do
			CreateSlot(control, containerKey, slotsData)
		end
		for _, slot in pairs(slotNames) do
			slot:SetHidden(true)
		end

		local sheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
		local setIndex = sheet:GetRestyleSetIndex()

		if not rowData.style then
			rowData.style = GetFashionStyles(data)
		end
		rowData.swapBars = BetterSwapBars(restyleMode, rowData.style)

		local processed = {}
		for slotType, item in pairs(rowData.style) do
			local d1, d2, d3, collectibleId = unpack(item)
			if rowData.swapBars and oppositeOutfitSlot[slotType] then
				slotType = oppositeOutfitSlot[slotType]
			end
			if SlotCurrentlyUseable(restyleMode, slotType) then
				processed[slotType] = process(restyleMode, slotType, setIndex, collectibleId, d1, d2, d3)
			end
		end
		for slotType in pairs(slots) do
			if not processed[slotType] and slots[slotType]:IsHidden() then
				process(restyleMode, slotType, setIndex, nil, 0, 0, 0)
			end
		end

		local name = GetFashionName(data)
		name = name or GetString(SI_RESTYLE_SHEET_EQUIPMENT_APPAREL)
		control.headers[ZO_RESTYLE_SHEET_CONTAINER.PRIMARY]:SetText(name)

		slots, slotNames = nil, nil
	end
end

do
	local zo_plainstrfind, zo_strlower = zo_plainstrfind, zo_strlower
	local lastMode, searchtext

	local function sortFashion(a, b)
		return (a.data.name == b.data.name) and (a.data.link < b.data.link) or (a.data.name < b.data.name)
	end

	local function noFilter()
		return true
	end
	local function filterName(name)
		return zo_plainstrfind(zo_strlower(name), searchtext)
	end

	local compatibleStyle = {
		[RESTYLE_MODE_EQUIPMENT] = RESTYLE_MODE_COMPANION_EQUIPMENT,
		[RESTYLE_MODE_COLLECTIBLE] = RESTYLE_MODE_COMPANION_COLLECTIBLE,
		[RESTYLE_MODE_OUTFIT] = RESTYLE_MODE_COMPANION_OUTFIT,
		[RESTYLE_MODE_COMPANION_EQUIPMENT] = RESTYLE_MODE_EQUIPMENT,
		[RESTYLE_MODE_COMPANION_COLLECTIBLE] = RESTYLE_MODE_COLLECTIBLE,
		[RESTYLE_MODE_COMPANION_OUTFIT] = RESTYLE_MODE_OUTFIT
	}

	function addon:BuildFashionList()
		local sheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
		local currentRestyleMode = sheet:GetRestyleMode()
		if currentRestyleMode == lastMode then
			return
		end

		local scrollData = ZO_ScrollList_GetDataList(self.list)
		ZO_ClearNumericallyIndexedTable(scrollData)
		if lastMode ~= currentRestyleMode then
			ZO_ScrollList_UpdateDataTypeHeight(self.list, ROW_ID, IsCollectibleMode(currentRestyleMode) and 130 or 520)
		end
		lastMode = currentRestyleMode

		searchtext = ZO_RESTYLE_STATION_KEYBOARD.contentSearchEditBox:GetText()
		if #searchtext > 0 then
			searchtext = zo_strlower(searchtext)
		end
		local filter = #searchtext == 0 and noFilter or filterName

		local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
		local function addItem(link)
			local restyleMode = string.match(link, "^VOF%d+:(%d+):")
			restyleMode = tonumber(restyleMode)
			if currentRestyleMode == restyleMode or compatibleStyle[currentRestyleMode] == restyleMode then
				local name = GetFashionName(link)
				if filter(name) then
					scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ROW_ID, {link = link, name = name})
				end
			end
		end
		for _, link in pairs(self.masterList) do
			addItem(link)
		end

		table.sort(scrollData, sortFashion)
		ZO_ScrollList_Commit(self.list)
	end
	function addon:MarkFashionListDirty()
		lastMode = nil
	end
end

-- A property like "visible" can be nil, static true/false or a function.
local function HookFunctionOrValue(class, member, hook)
	local value = class[member]

	if value ~= nil then
		if type(value) == "function" then
			local function newF(...)
				return hook(value(...), ...)
			end
			class[member] = newF
		else
			local function newF(...)
				return hook(value, ...)
			end
			class[member] = newF
		end
	else
		class[member] = hook
	end
end

local function HideRandomize(value)
	return not addon.fragment:IsShowing() and value
end

local function RenameOutfitOrFashion(value)
	return addon.fragment:IsShowing() and GetString(SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_RENAME) or value
end

local function RenameIsVisible(value)
	return addon.fragment:IsShowing() or value
end

local function RenameFashion()
	if addon.fragment:IsShowing() then
		local index, selected = GetSelected(addon)
		if index and selected then
			ZO_Dialogs_ShowDialog("VOTAN_RENAME_FASHION", {index = index, selected = selected}, {initialEditText = GetFashionName(selected.link)})
		end
		return true
	end
end

function addon:HookCategoryTree()
	local orgCategoryCommit = ZO_RESTYLE_STATION_KEYBOARD.categoryTree.Commit
	local categoryData = {}
	local function AddFashionNode(owner, autoselectNode)
		local node =
			owner:AddCategory(
			"VotansFashionTreeNode",
			nil,
			GetString(SI_VOTANS_IMPROVED_OUTFIT_FASHION),
			categoryData,
			"esoui/art/collections/collections_tabicon_outfitstyles_up.dds",
			"esoui/art/collections/collections_tabicon_outfitstyles_down.dds",
			"esoui/art/collections/collections_tabicon_outfitstyles_over.dds",
			"esoui/art/collections/collections_tabicon_outfitstyles_disabled.dds",
			true
		)
		self.fashionNode = node

		if self.fragment:IsShowing() then
			autoselectNode = node
			self:BuildFashionList()
		end
		return autoselectNode
	end

	local function getCommitText()
		return GetString(SI_DYEING_COMMIT)
	end
	local function getDiscardText()
		return GetString(SI_DYEING_UNDO)
	end

	for _, strip in ipairs(ZO_RESTYLE_STATION_KEYBOARD.keybindStripDescriptor) do
		if strip.keybind == "UI_SHORTCUT_TERTIARY" then
			HookFunctionOrValue(strip, "visible", HideRandomize)
		elseif strip.keybind == "UI_SHORTCUT_QUATERNARY" then
			HookFunctionOrValue(strip, "name", RenameOutfitOrFashion)
			HookFunctionOrValue(strip, "visible", RenameIsVisible)
			ZO_PreHook(strip, "callback", RenameFashion)
		elseif strip.keybind == "UI_SHORTCUT_SECONDARY" then
			HookFunctionOrValue(strip, "name", getCommitText)
		elseif strip.keybind == "UI_SHORTCUT_NEGATIVE" then
			HookFunctionOrValue(strip, "name", getDiscardText)
		end
	end

	local function hideFashion()
		if VOTANS_IMPROVED_OUTFIT_FRAGMENT:IsShowing() then
			VOTANS_IMPROVED_OUTFIT_FRAGMENT:Hide()
			SCENE_MANAGER:RemoveFragment(VOTANS_IMPROVED_OUTFIT_FRAGMENT)
		end
	end

	function ZO_RESTYLE_STATION_KEYBOARD.categoryTree.Commit(categoryTree, autoselectNode)
		autoselectNode = AddFashionNode(ZO_RESTYLE_STATION_KEYBOARD, autoselectNode)
		return orgCategoryCommit(categoryTree, autoselectNode)
	end

	local function EqualityFunction(leftData, rightData)
		return leftData == rightData
	end

	local function BaseTreeHeaderIconSetup(control, data, open)
		local enabled = data.enabled ~= false
		open = open and enabled

		local iconTexture
		if enabled then
			iconTexture = open and data.pressedIcon or data.normalIcon
		else
			iconTexture = data.disabledIcon
		end

		if not iconTexture then
			iconTexture = ZO_NO_TEXTURE_FILE
		end

		local mouseoverTexture = data.mouseoverIcon or ZO_NO_TEXTURE_FILE

		control.icon:SetTexture(iconTexture)
		control.iconHighlight:SetTexture(mouseoverTexture)

		ZO_IconHeader_Setup(control, open, enabled)
	end

	local function FashionTreeNodeSetup(node, control, data, open)
		control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
		control.text:SetText(data.name)
		BaseTreeHeaderIconSetup(control, data, open)
	end

	local function FashionTreeNodeOnSelected(control, data, selected, reselectingDuringRebuild)
		BaseTreeHeaderIconSetup(control, data, selected)
		if reselectingDuringRebuild then
			return
		end

		if selected then
			if KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:IsShowing() then
				ZO_OUTFIT_STYLES_PANEL_KEYBOARD:UnregisterCallback("MouseTargetChanged", ZO_RESTYLE_STATION_KEYBOARD.updateKeybindCallback)
				SCENE_MANAGER:RemoveFragment(KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT)
			end
			SCENE_MANAGER:RemoveFragment(KEYBOARD_DYEING_FRAGMENT)
			SCENE_MANAGER:AddFragment(VOTANS_IMPROVED_OUTFIT_FRAGMENT)
			self:BuildFashionList()
			VOTANS_IMPROVED_OUTFIT_FRAGMENT:Show()
			ZO_RESTYLE_STATION_KEYBOARD:UpdateKeybind()
			UpdateKeybind()
		else
			hideFashion()
		end
	end
	ZO_RESTYLE_STATION_KEYBOARD.categoryTree:AddTemplate("VotansFashionTreeNode", FashionTreeNodeSetup, FashionTreeNodeOnSelected, EqualityFunction)

	local function RestyleSearchBoxMouseDown(bagSearch, button)
		if not bagSearch:HasFocus() and button == MOUSE_BUTTON_INDEX_RIGHT then
			bagSearch:SetText("")
		end
	end
	ZO_PreHookHandler(ZO_RESTYLE_STATION_KEYBOARD.contentSearchEditBox, "OnMouseDown", RestyleSearchBoxMouseDown)
end

function addon:AddFashion(link)
	local version, restyleMode, data = string.match(link, "^VOF(%d+):(%d+)(:.+)")
	if version and data then
		version, restyleMode = tonumber(version), tonumber(restyleMode)
		if version == 1 and restyleMode >= RESTYLE_MODE_MIN_VALUE and restyleMode <= RESTYLE_MODE_MAX_VALUE then
			self.masterList[#self.masterList + 1] = link
			if self.fragment:IsShowing() then
				local sheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
				if sheet:GetRestyleMode() == restyleMode then
					local rowData = {link = link}
					local scrollData = ZO_ScrollList_GetDataList(self.list)
					local selected = ZO_ScrollList_CreateDataEntry(ROW_ID, rowData)
					scrollData[#scrollData + 1] = selected
					ZO_ScrollList_Commit(self.list)
					return true, rowData
				end
			end
			PlaySound(SOUNDS.DEFAULT_CLICK)
			return
		end
	end
	PlaySound(SOUNDS.NEGATIVE_CLICK)
end

function addon:NewFashion()
	local link = CreateFashion()
	if link == "" then
		return
	end

	local success, rowData = self:AddFashion(link)
	if success then
		ZO_ScrollList_SelectDataAndScrollIntoView(self.list, rowData)
	end
end

do
	local function AddFashion(link)
		addon:AddFashion(link)
	end
	SLASH_COMMANDS["/addfashion"] = AddFashion
end

local function UpdateFashion(self, index, selected)
	local link = CreateFashion(nil, selected.name)
	if link == "" then
		return
	end
	self.masterList[index] = link

	selected.link, selected.style = link, nil

	ZO_ScrollList_RefreshVisible(self.list, selected)
	PlaySound(SOUNDS.DEFAULT_CLICK)
end

function addon:UpdateFashion()
	local index, selected = GetSelected(self)
	if not index then
		return
	end
	UpdateFashion(self, index, selected)
end

function addon:DeleteFashion()
	local index, selected = GetSelected(self)
	if not index then
		return
	end
	local scrollData = ZO_ScrollList_GetDataList(self.list)
	table.remove(scrollData, self.list.selectedDataIndex)
	ZO_ScrollList_Commit(self.list)
	table.remove(self.masterList, index)
	PlaySound(SOUNDS.INVENTORY_ITEM_JUNKED)
end

function addon:ShowFashionContextMenu(control)
	ClearMenu()
	AddCustomMenuItem(
		GetString(SI_OUTFIT_STYLE_EQUIP_BIND),
		function()
			local rowData = ZO_ScrollList_GetData(control)
			if rowData and rowData.link then
				if ZO_ScrollList_IsDataSelected(self.list, rowData) then
					self:SelectFashion(rowData, rowData, false)
				else
					ZO_ScrollList_MouseClick(self.list, control)
				end
			end
		end
	)
	if IsChatSystemAvailableForCurrentPlatform() then
		AddCustomMenuItem(
			GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
			function()
				local rowData = ZO_ScrollList_GetData(control)
				if rowData and rowData.link then
					StartChatInput(rowData.link)
				end
			end
		)
	end
	AddCustomMenuItem(
		GetString(SI_WORLD_MAP_FILTERS_SHOW_DETAILS),
		function()
			local rowData = ZO_ScrollList_GetData(control)
			if rowData and rowData.link then
				ZO_Dialogs_ShowDialog(
					"VOTANS_OUTFIT_CLIPBOARD_DIALOG",
					{
						displayName = rowData.name,
						link = rowData.link
					}
				)
			end
		end
	)
	AddCustomMenuItem(
		GetString(SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_UPDATE),
		function()
			local rowData = ZO_ScrollList_GetData(control)
			if rowData and rowData.link then
				local index = FindInMasterList(self, rowData.link)
				UpdateFashion(self, index, rowData)
				ZO_ScrollList_SelectData(self.list, rowData, control, true, true)
			end
		end
	)
	AddCustomMenuItem("-")
	AddCustomMenuItem(
		GetString(SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_DELETE),
		function()
			local rowData = ZO_ScrollList_GetData(control)
			if rowData and rowData.link then
				ZO_ScrollList_SelectData(self.list, rowData, control, true, true)
				self:DeleteFashion()
			end
		end
	)
	ShowMenu(control)
end

function addon:AddFashionKeybind()
	self.keybindButtonGroupFashion = {
		alignment = KEYBIND_STRIP_ALIGN_RIGHT,
		{
			name = GetString(SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_NEW),
			keybind = "VOTANS_IMPROVED_OUTFIT_NEW",
			order = 100,
			callback = function()
				self:NewFashion()
			end
		},
		{
			name = GetString(SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_UPDATE),
			keybind = "VOTANS_IMPROVED_OUTFIT_UPDATE",
			enabled = function()
				return ZO_ScrollList_GetSelectedData(self.list) ~= nil
			end,
			order = 100,
			callback = function()
				self:UpdateFashion()
			end
		},
		{
			name = GetString(SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_DELETE),
			keybind = "VOTANS_IMPROVED_OUTFIT_DELETE",
			enabled = function()
				return ZO_ScrollList_GetSelectedData(self.list) ~= nil
			end,
			order = 100,
			callback = function()
				self:DeleteFashion()
			end
		}
	}
	self.fragment:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				KEYBIND_STRIP:AddKeybindButtonGroup(addon.keybindButtonGroupFashion)
			elseif newState == SCENE_FRAGMENT_SHOWN then
				ZO_ScrollList_RefreshVisible(self.list)
			elseif newState == SCENE_HIDING then
				addon:ResumeUndo()
				CancelCooldown()
				KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.keybindButtonGroupFashion)
			end
		end
	)

	local function KeysForBookScene(oldState, newState)
		if not ZO_OUTFIT_STYLES_BOOK_SCENE:IsShowing() then
			return
		end
		if newState == SCENE_FRAGMENT_SHOWN then
			PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_OUTFIT_STATION))
		elseif newState == SCENE_HIDING then
			RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_OUTFIT_STATION))
		end
	end
	self.fragment:RegisterCallback("StateChange", KeysForBookScene)

	local function clearChanges(oldState, newState)
		if newState == SCENE_HIDING then
			if ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:AreChangesPending() then
				ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:UndoPendingChanges()
				ApplyChangesToPreviewCollectionShown()
			end
		end
	end

	ZO_OUTFIT_STYLES_BOOK_SCENE:RegisterCallback("StateChange", clearChanges)
end

function addon:RegisterRenameFashionDialog()
	local function IsValidFashionName(name)
		local result = {}
		if not name then
			result[#result + 1] = 3
		else
			if #name < 2 then
				result[#result + 1] = 3
			end
			if not string.find(name, "^[^%d]") then
				result[#result + 1] = 12
			end
			if string.find(name, "^%s") then
				result[#result + 1] = 9
			end
			if string.find(name, "%s$") then
				result[#result + 1] = 5
			end
			if zo_plainstrfind(name, ":") then
				result[#result + 1] = 13
			end
		end
		return unpack(result)
	end
	local dialogName = "VOTAN_RENAME_FASHION"
	local function RenameFashion(dialog)
		local inputText = ZO_Dialogs_GetEditBoxText(dialog)
		local violations = IsValidFashionName(inputText)
		if violations then
			return
		end

		local index, selected = dialog.data.index, dialog.data.selected
		if not index then
			return
		end

		local link = selected.link
		local pos = string.find(link, ":([^%d][^:]-)$")
		if not pos then
			return
		end
		link = link:sub(1, pos) .. inputText

		self.masterList[index] = link
		selected.link = link
		ZO_ScrollList_RefreshVisible(self.list, selected)

		ZO_Dialogs_ReleaseDialog(dialogName)
	end
	ZO_Dialogs_RegisterCustomDialog(
		dialogName,
		{
			title = {
				text = SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_RENAME
			},
			mainText = {
				text = SI_OUTFIT_RENAME_DESCRIPTION
			},
			editBox = {
				defaultText = "",
				maxInputCharacters = 50,
				textType = TEXT_TYPE_ALL,
				specialCharacters = {"'", "-", " "},
				validatesText = true,
				validator = IsValidFashionName,
				selectAll = true
			},
			buttons = {
				[1] = {
					requiresTextInput = true,
					text = SI_OK,
					noReleaseOnClick = true,
					callback = RenameFashion
				},
				[2] = {
					text = SI_DIALOG_CANCEL
				}
			}
		}
	)
end

function addon:InitClipboardDialog()
	local function setupColor(line, num, dyeId)
		if dyeId > 0 then
			line[#line + 1] = "  "
			line[#line + 1] = num
			line[#line + 1] = ": "
			line[#line + 1] = GetDyeInfoById(dyeId)
			line[#line + 1] = "\n"
		end
	end
	local function ProcessFashionData(restyleMode, data)
		local selectedFashion = {}
		local slots = GetFashionStyles(data)
		local slotType = {}
		for t in pairs(slots) do
			slotType[#slotType + 1] = t
		end
		local line = {}
		local namePrefix = IsCollectibleMode(restyleMode) and "SI_COLLECTIBLECATEGORYTYPE" or "SI_OUTFITSLOT"
		if IsCollectibleMode(restyleMode) then
		elseif IsOutfitMode(restyleMode) then
			table.sort(slotType)
		end

		for i = 1, #slotType do
			ZO_ClearNumericallyIndexedTable(line)
			line[#line + 1] = GetString(namePrefix, slotType[i])
			line[#line + 1] = ": "

			local slot = slots[slotType[i]]
			if slot[4] then
				local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(slot[4])
				line[#line + 1] = collectibleData:GetFormattedName()
			else
				line[#line + 1] = "-"
			end
			line[#line + 1] = "\n"
			for i = 1, 3 do
				setupColor(line, i, slot[i])
			end
			selectedFashion[#selectedFashion + 1] = table.concat(line)
		end
		return table.concat(selectedFashion, "\n")
	end
	local function decodeFashion(text)
		local version, restyleMode, data = string.match(text, "^VOF(%d+):(%d+)(:.+)")
		if not version then
			ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, "No outfit fashion data")
			return
		end
		version, restyleMode = tonumber(version), tonumber(restyleMode)
		if version ~= 1 then
			ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, string.format("Unsupported version: %i", version))
			return
		end

		return ProcessFashionData(restyleMode, data)
	end

	local function dialogSetup(dialog, data)
		GetControl(dialog, "DisplayName"):SetText(data.displayName)
		GetControl(dialog, "NoteEdit"):SetText(decodeFashion(data.link))
	end

	local dialog = VotansImprovedOutfitToClipboard
	ZO_Dialogs_RegisterCustomDialog(
		"VOTANS_OUTFIT_CLIPBOARD_DIALOG",
		{
			customControl = dialog,
			setup = dialogSetup,
			title = {
				text = SI_VOTANS_IMPROVED_OUTFIT_FASHION
			},
			buttons = {
				{
					control = GetControl(dialog, "Close"),
					text = SI_DIALOG_CLOSE
				}
			}
		}
	)
end
function addon:InitializeFashion()
	self.control = VotansImprovedOutfitTopLevel
	self.list = self.control:GetNamedChild("List")
	self.fragment = ZO_FadeSceneFragment:New(self.control, true, 150)
	VOTANS_IMPROVED_OUTFIT_FRAGMENT = self.fragment

	local function initFashion()
		self:HookCategoryTree()
		self:SetupFashionList()
		self:AddFashionKeybind()
		self:RegisterRenameFashionDialog()
		self:InitFashionFilter()
		self:InitClipboardDialog()
	end
	if ZO_RESTYLE_STATION_KEYBOARD.categoryTree then
		initFashion()
	else
		SecurePostHook(ZO_RESTYLE_STATION_KEYBOARD, "InitializeKeybindStripDescriptors", initFashion)
	end

	ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", restart)
end
