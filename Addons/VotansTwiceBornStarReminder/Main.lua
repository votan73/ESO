local addon = {
	name = "VotansTwiceBornStarReminder",
}

local EVENT_MANAGER = EVENT_MANAGER

local mundusBoons = {
	[13940] = true,
	-- Boon: The Warrior
	[13943] = true,
	-- Boon: The Mage
	[13974] = true,
	-- Boon: The Serpent
	[13975] = true,
	-- Boon: The Thief
	[13976] = true,
	-- Boon: The Lady
	[13977] = true,
	-- Boon: The Steed
	[13978] = true,
	-- Boon: The Lord
	[13979] = true,
	-- Boon: The Apprentice
	[13980] = true,
	-- Boon: The Ritual
	[13981] = true,
	-- Boon: The Lover
	[13982] = true,
	-- Boon: The Atronach
	[13984] = true,
	-- Boon: The Shadow
	[13985] = true,
	-- Boon: The Tower
}

local itemLink = "|H1:item:58188:369:50:0:0:0:0:0:0:0:0:0:0:0:0:1:1:0:0:10000:0|h|h"
local function TwiceBornStarFullEquipped()
	local _, _, _, numEquipped = GetItemLinkSetInfo(itemLink, false)
	return numEquipped >= 5
end

local function NeedSecondBoon()
	local num = GetNumBuffs("player")
	local numMundus = 0
	local GetUnitBuffInfo = GetUnitBuffInfo
	for buffIndex = 1, num do
		local abilityId = select(11, GetUnitBuffInfo("player", buffIndex))
		if mundusBoons[abilityId] then numMundus = numMundus + 1 end
	end
	return numMundus < 2
end

local function UpdateMundusMainText(isTwiceBornStarEquipped)
	if isTwiceBornStarEquipped then
		local num = GetNumBuffs("player")
		local numMundus = 0
		local GetUnitBuffInfo = GetUnitBuffInfo
		local boonId, boonSlot = 0, 0

		for buffIndex = 1, num do
			local abilityId = select(11, GetUnitBuffInfo("player", buffIndex))
			if mundusBoons[abilityId] then
				local buffSlot = select(4, GetUnitBuffInfo("player", buffIndex))
				if boonSlot <= buffSlot then
					boonId = abilityId
					boonSlot = buffSlot
				end
				numMundus = numMundus + 1
			end
		end
		if numMundus == 1 then
			SafeAddString(SI_CONFIRM_MUNDUS_STONE_MAIN_TEXT, GetString(VOTANS_TBS_REMINDER_SECOND_BOON_NEW), 2)
		else
			SafeAddString(SI_CONFIRM_MUNDUS_STONE_MAIN_TEXT,
			zo_strjoin("\n\n", GetString(VOTANS_TBS_REMINDER_SECOND_BOON_NEW),
			zo_strformat(GetString(VOTANS_TBS_REMINDER_SECOND_BOON_REPLACE), GetAbilityName(boonId), GetAbilityDescription(boonId))), 2)
		end
	else
		SafeAddString(SI_CONFIRM_MUNDUS_STONE_MAIN_TEXT, addon.origMundusStoneMainText, 2)
	end
end

local lastReminder = 0
local lastTimeWasEquipped = false
local identifier = "VOTANS_TBS_REMINDER"

local OnPlayerActivated

local function CheckReminder()
	EVENT_MANAGER:UnregisterForUpdate(identifier)

	if lastTimeWasEquipped and NeedSecondBoon() then
		EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ZONE_CHANGED, OnPlayerActivated)
		local now = GetTimeStamp()
		if now - lastReminder >= 300 then
			lastReminder = now

			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.AVA_GATE_OPENED)
			messageParams:SetText(GetString(VOTANS_TBS_REMINDER_ANNOUNCEMENT))
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)

		end
	else
		UpdateMundusMainText(lastTimeWasEquipped)
		EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ZONE_CHANGED)
	end
end

-- is local, see above
function OnPlayerActivated()
	EVENT_MANAGER:UnregisterForUpdate(identifier)
	EVENT_MANAGER:RegisterForUpdate(identifier, 2000, CheckReminder)
end

local function OnEquipmentChanged()
	local isEquipped = TwiceBornStarFullEquipped()
	if lastTimeWasEquipped ~= isEquipped then
		lastReminder = 0
		lastTimeWasEquipped = isEquipped
	end
	UpdateMundusMainText(isEquipped)

	OnPlayerActivated()
end

local function OnPlayerActivatedFirstTime()
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
	OnEquipmentChanged()
end

local function AddonLoaded(event, name)
	if name ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivatedFirstTime)
	EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnEquipmentChanged)
	EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)

	addon.origMundusStoneMainText = GetString(SI_CONFIRM_MUNDUS_STONE_MAIN_TEXT)
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, AddonLoaded)
