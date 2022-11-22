--Register LAM with LibStub
local MAJOR, MINOR = "LibSwap", 1.1
local libswp = {}

local DEBUG_MODE = false

libswp.skillSetAllowLoad = true
libswp.skillSetAllowSave = true

-- Used to limit server calls to help prevent msg spam
local BUFFER_TIME_ALLOW_SKILL_LOAD = 200
local BUFFER_TIME_UNEQUIP_LOAD_DELAY = 500

local LAST_EQUIP_SLOT = EQUIP_SLOT_BACKUP_OFF
local FIRST_EQUIP_SLOT = EQUIP_SLOT_HEAD

--========================================================--
--======= LOCAL FUNCTIONS: UNEQUIP, FIND & EQUIP =========--
--========================================================--
local function FindAndEquipItems(itemsToFindAndEquip)
	EVENT_MANAGER:UnregisterForUpdate("LIBSWAP_FindAndEquipItems")

	if next(itemsToFindAndEquip) == nil then
		return
	end

	local backpackSlots = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)
	 -- PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].slots
	local next = next

	for _, slotData in pairs(backpackSlots) do
		local uniqueIdString = Id64ToString(GetItemUniqueId(BAG_BACKPACK, slotData.slotIndex))
		local itemToEquipData = itemsToFindAndEquip[uniqueIdString]

		if itemToEquipData then
			EquipItem(BAG_BACKPACK, slotData.slotIndex, itemToEquipData.equipSlotIndex)
			itemsToFindAndEquip[uniqueIdString] = nil -- done with it, remove it from the table

			if next(itemsToFindAndEquip) == nil then
				return true
			end
		end
	end
	return false
end

local function UnequipUnusedSlots(equipSlotsToUnequip, itemsToFindAndEquip)
	local equipSlot = equipSlotsToUnequip[1]

	local _, slotHasItem = GetEquippedItemInfo(equipSlot)
	if slotHasItem then
		-- check each item for space in case they received a reward or
		-- picked something up or else we could end up in an infinite loop.
		if CheckInventorySpaceSilently(1) then
			-- do NOT remove from table here. Due to slow unequips the equip may fail
			-- This forces another loop but guarantees the item is unequipped before being removed
			-- from the table.
			UnequipItem(equipSlot)
		else
			EVENT_MANAGER:UnregisterForUpdate("LIBSWAP_UnequipUnusedSlots")
			EVENT_MANAGER:RegisterForUpdate(
				"LIBSWAP_FindAndEquipItems",
				BUFFER_TIME_UNEQUIP_LOAD_DELAY,
				function()
					FindAndEquipItems(itemsToFindAndEquip)
				end
			)

			libswp.equipProcessInProgress = false
			return false
		end
	else
		table.remove(equipSlotsToUnequip, 1)
	end

	if next(equipSlotsToUnequip) == nil then
		EVENT_MANAGER:UnregisterForUpdate("LIBSWAP_UnequipUnusedSlots")
		EVENT_MANAGER:RegisterForUpdate(
			"LIBSWAP_FindAndEquipItems",
			BUFFER_TIME_UNEQUIP_LOAD_DELAY,
			function()
				FindAndEquipItems(itemsToFindAndEquip)
			end
		)

		libswp.equipProcessInProgress = false
		return true
	end
end

--========================================================--
--======= LIBRARY FUNCTIONS: SAVE EQUIPMENT SET =========--
--========================================================--
function libswp:SaveEquipmentSet()
	if libswp.equipProcessInProgress then
		return false
	end
	libswp.equipProcessInProgress = true

	local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(BAG_WORN)
	local equipmentSet = {}

	for equipSlotIndex, slotData in pairs(bagCache) do
		local uniqueIdString = Id64ToString(slotData.uniqueId)

		local itemData = {
			name = slotData.name,
			texture = slotData.iconFile,
			equipType = slotData.equipType,
			itemType = slotData.itemType,
			uniqueId = slotData.uniqueId,
			uniqueIdString = uniqueIdString,
			equipSlotIndex = equipSlotIndex
		}

		equipmentSet[equipSlotIndex] = itemData
	end

	libswp.equipProcessInProgress = false
	return true, equipmentSet
end

--========================================================--
--======= LIBRARY FUNCTIONS: LOAD EQUIPMENT =========--
--========================================================--
-- All of this was done to limit msgs to prevent the client msg spam problem.
-- check to make sure we really need to unequip an item before unequipping it. Same for equipping.
function libswp:LoadEquipmentSet(equipmentSet)
	if libswp.equipProcessInProgress then
		return false
	end
	libswp.equipProcessInProgress = true

	-- or {} allows us to pass in nil to unequip everything
	local equipmentSet = equipmentSet or {}
	local itemsToFindAndEquip = {}

	-- Problem Slots: Slots that hold items that could go in more than one slot
	-- If an item is already equipped & a set is loaded using that item in a different slot
	-- it will not get loaded because the item is not in the inventory, its still equipped.
	-- so we must unequip these slots if they are not the correct items for the new set were loading.
	-- even if a new item will be loaded into that slot.
	local problemSlots = {
		[EQUIP_SLOT_MAIN_HAND] = true,
		[EQUIP_SLOT_OFF_HAND] = true,
		[EQUIP_SLOT_RING1] = true,
		[EQUIP_SLOT_RING2] = true,
		[EQUIP_SLOT_BACKUP_MAIN] = true,
		[EQUIP_SLOT_BACKUP_OFF] = true
	}

	-- equipSlotsToUnequip represents slots that do not have an item saved for that slot in the set
	-- Slots that DO have an item saved for the slot are not "unequiped", they get
	-- unequipped automatically when the new item is equipped.
	-- Split into two tables so we can buffer unequips, no need to buffer equips.
	local equipSlotsToUnequip = {} -- represents slots that will be empty
	local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(BAG_WORN)
	local next = next

	for equipSlotIndex = FIRST_EQUIP_SLOT, LAST_EQUIP_SLOT do
		local itemToEquipData = equipmentSet[equipSlotIndex]

		-- If the saved slot is empty & the slot is not empty now, unequip
		if not itemToEquipData and bagCache[equipSlotIndex] then
			-- if the set does have an item to equip
			table.insert(equipSlotsToUnequip, equipSlotIndex)
		elseif itemToEquipData then
			if not bagCache[equipSlotIndex] then
				-- if the set does have something to equip & the slot is empty,
				-- add it to the list of items to equip
				itemsToFindAndEquip[itemToEquipData.uniqueIdString] = itemToEquipData
			else
				-- The slot is not empty. Check to see if its already the correct item
				local uniqueIdString = Id64ToString(bagCache[equipSlotIndex].uniqueId)

				-- If the correct item is not already equipped, add
				-- the item to the list of items to find & equip
				if uniqueIdString ~= itemToEquipData.uniqueIdString then
					-- save the data for the item to equip indexed by uniqueStringId so when we search
					-- the inventory it will be faster, we wont have to loop through both tables.
					itemsToFindAndEquip[itemToEquipData.uniqueIdString] = itemToEquipData

					-- if its also a problem slot, add it to the items to unequip table
					if problemSlots[equipSlotIndex] then
						table.insert(equipSlotsToUnequip, equipSlotIndex)
					end
				end
			end
		end
	end

	if next(equipSlotsToUnequip) ~= nil then
		-- equipProcessInProgress flag will be set to false in UnequipUnusedSlots, once it
		-- finishes unequipping all items.
		EVENT_MANAGER:RegisterForUpdate(
			"LIBSWAP_UnequipUnusedSlots",
			150,
			function()
				UnequipUnusedSlots(equipSlotsToUnequip, itemsToFindAndEquip)
			end
		)
	else
		EVENT_MANAGER:RegisterForUpdate(
			"LIBSWAP_FindAndEquipItems",
			BUFFER_TIME_UNEQUIP_LOAD_DELAY,
			function()
				FindAndEquipItems(itemsToFindAndEquip)
			end
		)
		libswp.equipProcessInProgress = false
	end
end

--********************************************************************************--
--********************************************************************************--
--********************************************************************************--
--****************************** SKILLS ******************************************--
--********************************************************************************--
--********************************************************************************--
--********************************************************************************--

--========================================================--
--======= LIBRARY FUNCTIONS: SAVE SKILL BAR =========--
--========================================================--
function libswp:SaveSkillSet()
	if not libswp.skillSetAllowSave then
		return false
	end
	libswp.skillSetAllowLoad = false
	libswp.skillSetAllowSave = false

	local skillBar = {}
	local skillBarSet = {}
	local realFirstActionBarSlot = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1
	local realUltimateSlotIndex = ACTION_BAR_ULTIMATE_SLOT_INDEX + 1
	local activeWeaponPair, locked = GetActiveWeaponPairInfo()

	for slotNum = realFirstActionBarSlot, realUltimateSlotIndex do
		local slotSkillData = {}
		slotSkillData.slotNum = slotNum

		if IsSlotUsed(slotNum) then
			slotSkillData.isSlotUsed = true
			local abilityId = GetSlotBoundId(slotNum)

			if DoesAbilityExist(abilityId) then
				slotSkillData.doesAbilityExist = true

				local hasProgression, progressionIndex = GetAbilityProgressionXPInfoFromAbilityId(abilityId)
				local unMorphedName, morphChoice, rank = GetAbilityProgressionInfo(progressionIndex)
				local morphedName, texture, abilityIndex = GetAbilityProgressionAbilityInfo(progressionIndex, morphChoice, rank)

				--[[
				-- Don't bother saving these, they change when you morph or level the skill.
				-- Must get it again when we want to reload the skill
				slotSkillData.progressionIndex 	= progressionIndex
				slotSkillData.morph				= morphChoice
				slotSkillData.rank				= rank
				--]]
				local name = GetAbilityName(abilityId)

				slotSkillData.name = zo_strformat(SI_ABILITY_NAME, morphedName)
				slotSkillData.activeWeaponPair = activeWeaponPair
				slotSkillData.texture = texture
				slotSkillData.abilityId = abilityId
				slotSkillData.isUltimate = slotNum == realUltimateSlotIndex
			else
				slotSkillData.doesAbilityExist = false
			end
		else
			slotSkillData.isSlotUsed = false
		end
		--skillBarSet[slotNum] = slotSkillData
		table.insert(skillBarSet, slotSkillData)
	end

	libswp.skillSetAllowLoad = true
	libswp.skillSetAllowSave = true
	return true, skillBarSet
end

--========================================================--
--======= LIBRARY FUNCTIONS: LOAD SKILL BAR =========--
--========================================================--
local function BufferAllowLoad()
	EVENT_MANAGER:UnregisterForUpdate("LIBSWAP_BufferAllowLoad")
	libswp.skillSetAllowLoad = true
end

local function BufferLoadSkillBar(skillBarData)
	local skillData = skillBarData[1]

	if skillData then
		if skillData.doesAbilityExist then
			local slotNum = skillData.slotNum
			local slotAbilityId = GetSlotBoundId(slotNum)
			local skillAbilityId = skillData.abilityId

			-- If its not already the correct ability, select it
			if skillAbilityId ~= slotAbilityId then
				local hasProgression, progressionIndex = GetAbilityProgressionXPInfoFromAbilityId(skillAbilityId)
				local unMorphedName, morphChoice, rank = GetAbilityProgressionInfo(progressionIndex)
				local morphedName, texture, abilityIndex = GetAbilityProgressionAbilityInfo(progressionIndex, morphChoice, rank)

				--local _, _, abilityIndex = GetAbilityProgressionAbilityInfo(skillData.progressionIndex, skillData.morph, skillData.rank)
				CallSecureProtected("SelectSlotAbility", abilityIndex, skillData.slotNum)
			end
		else
			CallSecureProtected("ClearSlot", skillData.slotNum)
		end
		table.remove(skillBarData, 1)
	else
		EVENT_MANAGER:UnregisterForUpdate("LIBSWAP_BufferLoadSkillBar")
		EVENT_MANAGER:RegisterForUpdate("LIBSWAP_BufferAllowLoad", BUFFER_TIME_ALLOW_SKILL_LOAD, BufferAllowLoad)
		--libswp.skillSetAllowLoad = true
		libswp.skillSetAllowSave = true
		return
	end
end

function libswp:LoadSkillSet(skillBarData)
	if type(skillBarData) ~= "table" then
		return false
	end
	if not libswp.skillSetAllowLoad then
		return false
	end
	libswp.skillSetAllowLoad = false
	libswp.skillSetAllowSave = false

	-- Since we remove skills from the table as they are loaded, we must make a copy to use
	local skillBarDataCopy = ZO_ShallowTableCopy(skillBarData)

	EVENT_MANAGER:RegisterForUpdate(
		"LIBSWAP_BufferLoadSkillBar",
		50,
		function()
			BufferLoadSkillBar(skillBarDataCopy)
		end
	)
	return true
end

LibSwap = libswp
