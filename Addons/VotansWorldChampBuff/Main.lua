local addon = {
	name = "VotansWorldChampBuff"
}
local em = GetEventManager()

local PLAYER_UNIT_TAG = "player"
local effectStart = 1000000
local effectEnd = effectStart + 12
local container = BUFF_DEBUFF.containerObjectsByUnitTag[PLAYER_UNIT_TAG]
local orgZO_GetNextActiveArtificialEffectIdIter = ZO_GetNextActiveArtificialEffectIdIter
assert(orgZO_GetNextActiveArtificialEffectIdIter, "ZO_GetNextActiveArtificialEffectIdIter nil")

local isInCombat
local function nextSlot(state, index)
	if isInCombat or index >= 4 then
		return
	end

	local slot
	repeat
		index = index + 1
		slot = GetSlotType(index, HOTBAR_CATEGORY_CHAMPION) == ACTION_TYPE_CHAMPION_SKILL
	until index >= 4 or slot
	if slot then
		return index + effectStart
	end
end
function ZO_GetNextActiveArtificialEffectIdIter(state, lastActiveEffectId)
	if not lastActiveEffectId then
		-- start with original and directly continue, if original has nothing.
		return orgZO_GetNextActiveArtificialEffectIdIter(state, lastActiveEffectId) or nextSlot(state, 0)
	elseif lastActiveEffectId <= effectStart or lastActiveEffectId > effectEnd then
		-- Continue original and afterwards start with additional.
		return orgZO_GetNextActiveArtificialEffectIdIter(state, lastActiveEffectId) or nextSlot(state, 0)
	else
		-- Continue additional
		return nextSlot(state, lastActiveEffectId - effectStart)
	end
end

local idToIcon = {
	[0] = "/esoui/art/champion/actionbar/champion_bar_world_slotted.dds",
	[1] = "/esoui/art/icons/ability_mage_065.dds", -- Professional Upkeep
	[65] = "/esoui/art/icons/ability_mage_065.dds", -- Sustaining Shadows
	[66] = "/esoui/art/icons/ability_psijic_005.dds", -- Steed's Blessing
	[76] = "/esoui/art/icons/ability_mage_065.dds", -- Friends in Low Places
	[77] = "/esoui/art/icons/ability_mage_065.dds", -- Infamous
	[78] = "/esoui/art/icons/achievement_117.dds", -- Master Gatherer
	[79] = "/esoui/art/icons/costume_treasurehunter_01.dds", -- Treasure Hunter /esoui/art/icons/achievement_087.dds /esoui/art/icons/achievement_011.dds
	[80] = "/esoui/art/icons/ability_mage_065.dds", -- Shadowstrike
	[81] = "/esoui/art/icons/collectible_crafting_bag.dds", -- Plentiful Harvest /esoui/art/icons/achievement_064.dds
	[82] = "/esoui/art/icons/ability_rogue_049.dds", -- War Mount
	[83] = "/esoui/art/icons/achievement_housing_016.dds", -- Meticulous Disassembly /esoui/art/icons/achievement_028.dds
	[84] = "/esoui/art/icons/ability_thievesguild_passive_002.dds", -- Fade Away
	[85] = "/esoui/art/icons/store_tricolor_food_01.dds", -- Rationer
	[86] = "/esoui/art/icons/ability_mage_065.dds", -- Liquid Efficiency
	[88] = "/esoui/art/icons/ability_mage_065.dds", -- Reel Technique
	[89] = "/esoui/art/icons/ability_provisioner_004.dds", -- Angler's Instincts
	[90] = "/esoui/art/icons/ability_mage_065.dds", -- Cutpurse's Art
	[91] = "/esoui/art/icons/achievement_craft_mastercraftsman.dds", -- Homemaker
	[92] = "/esoui/art/icons/ability_buff_minor_gallop.dds" -- Gifted Rider
	-- Speed? /esoui/art/icons/ability_rogue_015.dds
}
local now = GetGameTimeSeconds() - 31
local orgGetArtificialEffectInfo = GetArtificialEffectInfo
function GetArtificialEffectInfo(artificialEffectId)
	if artificialEffectId > effectStart and artificialEffectId <= effectEnd then
		local championSkillId = GetSlotBoundId(artificialEffectId - effectStart, HOTBAR_CATEGORY_CHAMPION)
		local slot = CHAMPION_DATA_MANAGER:GetChampionSkillData(championSkillId)
		if slot then
			--df("%s %i", slot:GetFormattedName(), slot:GetId())
			local timeEnd = GetGameTimeSeconds() - now <= 30 and (now + 30) or (now - 0.01)
			return slot:GetFormattedName(), idToIcon[slot:GetId()] or idToIcon[0], BUFF_EFFECT_TYPE_BUFF, artificialEffectId, now, timeEnd
		else
			return "", "EsoUI/Art/Icons/icon_missing.dds", BUFF_EFFECT_TYPE_NOT_AN_EFFECT, 0, 0, 0
		end
	end
	return orgGetArtificialEffectInfo(artificialEffectId)
end
local orgGetArtificialEffectTooltipText = GetArtificialEffectTooltipText
function GetArtificialEffectTooltipText(artificialEffectId)
	if artificialEffectId > effectStart and artificialEffectId <= effectEnd then
		local championSkillId = GetSlotBoundId(artificialEffectId - effectStart, HOTBAR_CATEGORY_CHAMPION)
		local slot = CHAMPION_DATA_MANAGER:GetChampionSkillData(championSkillId)
		return slot and slot:GetCurrentBonusText() or ""
	end
	return orgGetArtificialEffectTooltipText(artificialEffectId)
end
local function MakeDirty()
	container.isDirty = true
end
local identifier = "VOTAN_CHAMPCOOLDOWN"
local function StopCooldown()
	em:UnregisterForUpdate(identifier)
	MakeDirty()
end
local function StartCooldown()
	now = GetGameTimeSeconds()
	em:UnregisterForUpdate(identifier)
	em:RegisterForUpdate(identifier, 30000, StopCooldown)
	MakeDirty()
end

local function changeCombatState(event, inCombat)
	isInCombat = inCombat
end
em:RegisterForEvent(identifier, EVENT_PLAYER_COMBAT_STATE, changeCombatState)

-- TEST = function()
-- 	-- for effectId in ZO_GetNextActiveArtificialEffectIdIter do
-- 	-- end
-- 	SLASH_COMMANDS["/zgoo"](CHAMPION_DATA_MANAGER)
--     for _, slot in pairs(CHAMPION_DATA_MANAGER.championSkillDataById) do
--         if slot:IsTypeSlottable() and slot:GetSkillIndices()==1 then
--             df("[%i]=\"%s\", -- %s", slot:GetId(), GetAbilityIcon(slot:GetAbilityId()), slot:GetFormattedName())
--         end
--     end
-- end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	CHAMPION_DATA_MANAGER:RegisterCallback("AllPointsChanged", StartCooldown)
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
