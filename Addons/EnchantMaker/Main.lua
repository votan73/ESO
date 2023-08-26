-- art/fx/texture/naturesigilrunes.dds
-- art/fx/texture/sigil_ancestormothrunering.dds
-- art/fx/texture/sigil_daedricrune_02.dds
-- esoui/art/crafting/gamepad/crafting_enchanting_glyphslot_empty_round.dds

local addon = {
	name = "EnchantMaker",
	glyph_types = {
		{
			itemType = ITEMTYPE_GLYPH_ARMOR,
			icon = "esoui/art/icons/gear_imperial_heavy_chest_d.dds"
		},
		{
			itemType = ITEMTYPE_GLYPH_JEWELRY,
			icon = "esoui/art/icons/gear_imperial_ring_a.dds"
		},
		{
			itemType = ITEMTYPE_GLYPH_WEAPON,
			icon = "esoui/art/icons/gear_imperial_dagger_e.dds"
		}
	},
	power_runes = {
		-- Jora --
		[45855] = {bonus = 1, level = 1, power = 1},
		-- Porade --
		[45856] = {bonus = 1, level = 2, power = 1},
		-- Jera --
		[45857] = {bonus = 2, level = 3, power = 1},
		-- Jejora --
		[45806] = {bonus = 2, level = 4, power = 1},
		-- Odra --
		[45807] = {bonus = 3, level = 5, power = 1},
		-- Pojora --
		[45808] = {bonus = 3, level = 6, power = 1},
		-- Edora --
		[45809] = {bonus = 4, level = 7, power = 1},
		-- Jaera --
		[45810] = {bonus = 4, level = 8, power = 1},
		-- Pora --
		[45811] = {bonus = 5, level = 9, power = 1},
		-- Denara --
		[45812] = {bonus = 5, level = 10, power = 1},
		-- Rera --
		[45813] = {bonus = 6, level = 11, power = 1},
		-- Derado --
		[45814] = {bonus = 7, level = 12, power = 1},
		-- Rekura --
		[45815] = {bonus = 8, level = 13, power = 1},
		-- Kura --
		[45816] = {bonus = 9, level = 14, power = 1},
		-- Rejera --
		[64509] = {bonus = 10, level = 15, power = 1},
		-- Repora --
		[68341] = {bonus = 10, level = 16, power = 1},
		-- Jode --
		[45817] = {bonus = 1, level = 1, power = -1},
		-- Notade --
		[45818] = {bonus = 1, level = 2, power = -1},
		-- Ode --
		[45819] = {bonus = 2, level = 3, power = -1},
		-- Tade --
		[45820] = {bonus = 2, level = 4, power = -1},
		-- Jayde --
		[45821] = {bonus = 3, level = 5, power = -1},
		-- Edode --
		[45822] = {bonus = 3, level = 6, power = -1},
		-- Pojode --
		[45823] = {bonus = 4, level = 7, power = -1},
		-- Rekude --
		[45824] = {bonus = 4, level = 8, power = -1},
		-- Hade --
		[45825] = {bonus = 5, level = 9, power = -1},
		-- Idode --
		[45826] = {bonus = 5, level = 10, power = -1},
		-- Pode --
		[45827] = {bonus = 6, level = 11, power = -1},
		-- Kedeko --
		[45828] = {bonus = 7, level = 12, power = -1},
		-- Rede --
		[45829] = {bonus = 8, level = 13, power = -1},
		-- Kude --
		[45830] = {bonus = 9, level = 14, power = -1},
		-- Jehade --
		[64508] = {bonus = 10, level = 15, power = -1},
		-- Itade --
		[68340] = {bonus = 10, level = 16, power = -1}
	},
	essence_runes = {
		-- Oko --
		[45831] = {glyphTypePositive = ITEMTYPE_GLYPH_ARMOR, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON},
		-- Makko --
		[45832] = {glyphTypePositive = ITEMTYPE_GLYPH_ARMOR, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON},
		-- Deni --
		[45833] = {glyphTypePositive = ITEMTYPE_GLYPH_ARMOR, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON},
		-- Okoma --
		[45834] = {glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON},
		-- Makkoma --
		[45835] = {glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Denima --
		[45836] = {glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Kuoko --
		[45837] = {glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Rakeipa --
		[45838] = {glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Dakeipa --
		[45839] = {glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Meip --
		[45840] = {glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Haoko --
		[45841] = {glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Deteri --
		[45842] = {glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON},
		-- Okori --
		[45843] = {glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON},
		-- Jaedi --
		[45844] = {glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON},
		-- Lire --
		[45845] = {glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON},
		-- Oru --
		[45846] = {glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Taderi --
		[45847] = {glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Makderi --
		[45848] = {glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Kaderi --
		[45849] = {glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},
		-- Hakeijo --
		[68342] = {glyphTypePositive = ITEMTYPE_GLYPH_ARMOR, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON},
		-- Indeko --
		[166045] = {glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY}
	},
	aspect_runes = {
		-- Ta --
		[45850] = {bonus = 1, quality = 1},
		-- Jejota --
		[45851] = {bonus = 1, quality = 2},
		-- Denata --
		[45852] = {bonus = 2, quality = 3},
		-- Rekuta --
		[45853] = {bonus = 3, quality = 4},
		-- Kuta --
		[45854] = {bonus = 4, quality = 5}
	},
	result = {},
	byRawName = {}
}
local em = GetEventManager()
local LES = LibEnchantingStation
local async = LibAsync
local task

local function ShowAnnoucement(text)
	local message = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.QUEST_OBJECTIVE_INCREMENT)
	message:SetSound(SOUNDS.QUEST_OBJECTIVE_INCREMENT)
	message:SetText(text)
	message:MarkSuppressIconFrame()
	message:MarkShowImmediately()
	CENTER_SCREEN_ANNOUNCE:QueueMessage(message)
end

local function GetQuests()
	local numSteps, numConditions, questIndex, _
	local questType, activeStepText, stepOverrideText, stepIndex, conditionText, backgroundText
	local GetJournalQuestInfo, GetJournalQuestNumSteps, GetJournalQuestConditionInfo = GetJournalQuestInfo, GetJournalQuestNumSteps, GetJournalQuestConditionInfo
	local quests = {}
	local masterquests = {}
	local function ParseSteps(quests, questIndex, numSteps)
		for stepIndex = 1, numSteps do
			numConditions = GetJournalQuestNumConditions(questIndex, stepIndex)
			if numConditions == 0 then
				quests[#quests + 1] = addon:ParseQuest(stepOverrideText)
			else
				for conditionIndex = 1, numConditions do
					conditionText = GetJournalQuestConditionInfo(questIndex, stepIndex, conditionIndex)
					if conditionText and conditionText ~= "" then
						quests[#quests + 1] = addon:ParseQuest(conditionText)
					end
				end
			end
		end
	end

	-- quest text lines
	for questIndex = 1, MAX_JOURNAL_QUESTS do
		if IsValidQuestIndex(questIndex) then
			questType = GetJournalQuestType(questIndex)
			if questType == QUEST_TYPE_CRAFTING then
				_, backgroundText, activeStepText, _, stepOverrideText = GetJournalQuestInfo(questIndex)
				quests[#quests + 1] = addon:ParseQuest(activeStepText)

				numSteps = GetJournalQuestNumSteps(questIndex)
				ParseSteps(numSteps < 4 and quests or masterquests, questIndex, numSteps)
			end
		end
	end
	-- combine them at once
	quests = table.concat(quests, " ")
	masterquests = table.concat(masterquests, " ")

	return LocalizeString("<<Z:1>> ", quests), LocalizeString("<<Z:1>> ", masterquests)
end

local language = GetCVar("language.2")
if language == "fr" then
	function addon:ParseQuest(text)
		text = text:gsub("\194\160", " "):gsub("\r", ""):gsub("\n", " ")
		return string.format("%s %s", text, text:gsub("de Santé Superbe", "superbe vital"):gsub("de Magie Superbe", "superbe magique"):gsub("de Vigueur Superbe", "superbe vigoureux"))
	end
elseif language == "es" then
	function addon:ParseQuest(text)
		text = text:gsub("\194\160", " "):gsub("\r", ""):gsub("\n", " ")
		return text:gsub(" grande", " superior"):gsub(" del ", " "):gsub(" de ", " ")
	end
else
	function addon:ParseQuest(text)
		return text:gsub("\194\160", " "):gsub("\r", ""):gsub("\n", " ")
	end
end

if language == "es" then
	function addon:GetSearchTerm(name)
		return LocalizeString(" <<Z:1>> ", name):gsub(" DEL ", " "):gsub(" DE ", " ")
	end
else
	function addon:GetSearchTerm(name)
		return LocalizeString(" <<Z:1>> ", name)
	end
end

do
	local runes = {
		[ITEMTYPE_ENCHANTING_RUNE_ASPECT] = true,
		[ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = true,
		[ITEMTYPE_ENCHANTING_RUNE_POTENCY] = true
	}

	local function UpdateScrollList()
		local self = addon
		local scrollList = self.resultList
		local dataList = ZO_ScrollList_GetDataList(scrollList)

		ZO_ScrollList_Clear(scrollList)

		local list = self.result

		table.sort(
			list,
			function(a, b)
				return a[1] < b[1]
			end
		)

		local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
		for i = 1, #list do
			dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(1, list[i], 1)
		end

		ZO_ScrollList_Commit(scrollList)

		local isEmpty = #list == 0
		scrollList:SetHidden(isEmpty)
		scrollList.empty:SetHidden(not isEmpty)
	end

	local function EnchantItemsOnly(itemData)
		return runes[itemData.itemType]
	end

	local function filterAllowAll()
		return true
	end

	function addon:Search()
		local searchText = self.searchBox:GetText()
		if searchText ~= "" then
			searchText = zo_strlower(searchText)
			local unknown = GetString(SI_ENCHANTING_UNKNOWN_RESULT)
			filter = function(name)
				name = name ~= "" and name or unknown
				return zo_plainstrfind(ZO_CachedStrFormat("<<z:1>>", name), searchText)
			end
		else
			filter = filterAllowAll
		end

		local level, quality, glyphType = ZO_MenuBar_GetSelectedDescriptor(self.filterPanel.levelMenu), ZO_MenuBar_GetSelectedDescriptor(self.filterPanel.qualityMenu), ZO_MenuBar_GetSelectedDescriptor(self.filterPanel.typeMenu)
		glyphType = self.glyph_types[glyphType].itemType

		self.filterPanel:SetHidden(true)
		self.outputPanel:SetHidden(false)
		self.searchBox:SetHidden(false)

		local filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(EnchantItemsOnly, BAG_BACKPACK, BAG_BANK, BAG_VIRTUAL, BAG_SUBSCRIBER_BANK)

		local GetEnchantingResultingItemLink, GetItemLinkName = GetEnchantingResultingItemLink, GetItemLinkName
		local byRawName = self.byRawName
		local list = self.result
		ZO_ClearNumericallyIndexedTable(list)

		local processed = {}
		local power, aspect, essence
		local function getGlyph()
			local powerData = byRawName[power.rawName]
			local essenceData = byRawName[essence.rawName]
			if powerData.power == 1 then
				if essenceData.glyphTypePositive ~= glyphType then
					return
				end
			else
				if essenceData.glyphTypeNegative ~= glyphType then
					return
				end
			end
			local identifier = string.format("%s_%s", power.rawName, essence.rawName)
			if not processed[identifier] then
				local itemLink = GetEnchantingResultingItemLink(power.bagId, power.slotIndex, essence.bagId, essence.slotIndex, aspect.bagId, aspect.slotIndex)
				processed[identifier] = true
				local item = {GetItemLinkName(itemLink), itemLink, power, essence, aspect}
				if filter(unpack(item)) then
					list[#list + 1] = item
				end
			end
		end
		local function getEssenceRunes(itemData)
			if itemData.itemType ~= ITEMTYPE_ENCHANTING_RUNE_ESSENCE then
				return
			end
			essence = itemData
			getGlyph()
		end
		local function getAspectRunes(itemData)
			if itemData.itemType ~= ITEMTYPE_ENCHANTING_RUNE_ASPECT then
				return
			end
			local data = byRawName[itemData.rawName]
			if data.quality ~= quality then
				return
			end
			aspect = itemData
			for _, itemData in pairs(filteredDataTable) do
				getEssenceRunes(itemData)
			end
		end
		local function getPowerRunes(itemData)
			if itemData.itemType ~= ITEMTYPE_ENCHANTING_RUNE_POTENCY then
				return
			end
			local data = byRawName[itemData.rawName]
			if data.level ~= level then
				return
			end
			power = itemData
			for _, itemData in pairs(filteredDataTable) do
				getAspectRunes(itemData)
			end
		end
		for _, itemData in pairs(filteredDataTable) do
			getPowerRunes(itemData)
		end
		task:Call(UpdateScrollList)
	end
	function addon:SearchQuests()
		local level, quality, glyphType = ZO_MenuBar_GetSelectedDescriptor(self.filterPanel.levelMenu), ZO_MenuBar_GetSelectedDescriptor(self.filterPanel.qualityMenu), ZO_MenuBar_GetSelectedDescriptor(self.filterPanel.typeMenu)
		glyphType = self.glyph_types[glyphType].itemType

		self.filterPanel:SetHidden(true)
		self.outputPanel:SetHidden(false)
		self.searchBox:SetHidden(true)

		local filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(EnchantItemsOnly, BAG_BACKPACK, BAG_VIRTUAL)

		local GetEnchantingResultingItemLink, GetItemLinkName, LocalizeString, zo_plainstrfind = GetEnchantingResultingItemLink, GetItemLinkName, LocalizeString, zo_plainstrfind
		local byRawName = self.byRawName
		local list = self.result
		ZO_ClearNumericallyIndexedTable(list)

		local quests, masterquests = GetQuests()

		local rank = GetNonCombatBonus(NON_COMBAT_BONUS_ENCHANTING_LEVEL)

		-- d(quests, masterquests)
		local processed = {}
		local power, aspect, essence
		local function getGlyph()
			local powerData = byRawName[power.rawName]
			local essenceData = byRawName[essence.rawName]
			local identifier = string.format("%s_%s_%i", power.rawName, essence.rawName, aspect.quality)
			if not processed[identifier] then
				local itemLink = GetEnchantingResultingItemLink(power.bagId, power.slotIndex, essence.bagId, essence.slotIndex, aspect.bagId, aspect.slotIndex)
				if itemLink == "" then
					return
				end

				processed[identifier] = true
				local name = GetItemLinkName(itemLink)
				local searchTerm = self:GetSearchTerm(name)
				-- d(searchTerm)
				if aspect.quality == 1 and zo_plainstrfind(quests, searchTerm) then
					if not list[1] or #list[1][1] < #name then
						list[1] = {name, itemLink, power, essence, aspect}
					end
				end
				if aspect.quality > 1 and zo_plainstrfind(masterquests, searchTerm) then
					if not list[2] or #list[2][1] < #name then
						list[2] = {name, itemLink, power, essence, aspect}
					end
				end
			end
		end
		local function getEssenceRunes(itemData)
			if itemData.itemType ~= ITEMTYPE_ENCHANTING_RUNE_ESSENCE then
				return
			end
			essence = itemData
			getGlyph()
		end
		local function getPowerRunes(itemData)
			if itemData.itemType ~= ITEMTYPE_ENCHANTING_RUNE_POTENCY then
				return
			end
			if byRawName[itemData.rawName].bonus ~= rank then
				return
			end
			power = itemData
			for _, itemData in pairs(filteredDataTable) do
				getEssenceRunes(itemData)
			end
		end
		local function getAspectRunes(itemData)
			if itemData.itemType ~= ITEMTYPE_ENCHANTING_RUNE_ASPECT then
				return
			end
			local data = byRawName[itemData.rawName]
			if data.quality ~= 1 or #quests <= 1 then
				if #masterquests <= 1 or not zo_plainstrfind(masterquests, LocalizeString("<<Z:1>>", GetString("SI_ITEMQUALITY", data.quality))) then
					return
				end
			end
			aspect = itemData
			for _, itemData in pairs(filteredDataTable) do
				getPowerRunes(itemData)
			end
		end
		for _, itemData in pairs(filteredDataTable) do
			getAspectRunes(itemData)
		end
		if not list[1] then
			list[1] = list[2]
			list[2] = nil
		end
		task:Call(UpdateScrollList):Then(
			function()
				if list[1] then
					addon:AddToTable(list[1])
				end
			end
		)
	end
end

function addon:OpenFilter()
	self.filterPanel:SetHidden(false)
	self.outputPanel:SetHidden(true)
	ZO_ClearNumericallyIndexedTable(self.result)
end

function addon:Close()
	self:OpenFilter()
	collectgarbage()
end

function addon:InitTranslationLearned()
	local function HookDisplayTranslatedRunes(orgDialog)
		local orgDisplayTranslatedRunes = orgDialog.DisplayTranslatedRunes
		orgDialog.DisplayTranslatedRunes = function(...)
			-- ToDo: Settings
			if false then
				return orgDisplayTranslatedRunes(...)
			end
			for resultIndex = 1, GetNumLastCraftingResultLearnedTranslations() do
				local translationName, itemName, icon = GetLastCraftingResultLearnedTranslationInfo(resultIndex)
				local text = string.format("%s %s: %s", zo_iconFormat(icon, 32, 32), zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName), zo_strformat(SI_TOOLTIP_ITEM_NAME, translationName))
				ShowAnnoucement(text)
			end
		end
	end
	HookDisplayTranslatedRunes(CRAFTING_RESULTS)
end

do
	local function ReturnItemLink(itemLink)
		return itemLink:gsub("|H0", "|H1")
	end

	function addon:AddContextMenuGlyph(rowControl, rowData)
		AddCustomMenuItem(
			GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
			function()
				ZO_LinkHandler_InsertLink(ZO_LinkHandler_CreateChatLink(ReturnItemLink, rowData[2]))
			end
		)
	end
	function addon:AddContextMenuRune(rowControl, itemLink)
		AddCustomMenuItem(
			GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
			function()
				ZO_LinkHandler_InsertLink(ZO_LinkHandler_CreateChatLink(ReturnItemLink, itemLink))
			end
		)
	end
end

do
	local function UpdateTooltip()
		ENCHANTING:UpdateTooltip()
	end

	function addon:UpdateTranslations()
		local byRawName = self.byRawName
		local list = self.result
		local dirty = false

		for resultIndex = 1, GetNumLastCraftingResultLearnedTranslations() do
			local translationName, itemName, icon, sellPrice, meetsUsageRequirement = GetLastCraftingResultLearnedTranslationInfo(resultIndex)
			local data = byRawName[itemName]

			data.meetsUsageRequirement = meetsUsageRequirement
			for i = 1, #list do
				local rowData = list[i]
				local power, essence, aspect = rowData[3], rowData[4], rowData[5]

				if itemName == power.rawName or itemName == essence.rawName or itemName == aspect.rawName then
					if byRawName[power.rawName].meetsUsageRequirement and byRawName[essence.rawName].meetsUsageRequirement and byRawName[aspect.rawName].meetsUsageRequirement then
						local itemLink = GetEnchantingResultingItemLink(power.bagId, power.slotIndex, essence.bagId, essence.slotIndex, aspect.bagId, aspect.slotIndex)
						rowData[1] = GetItemLinkName(itemLink)
						rowData[2] = itemLink
						dirty = true
					end
				end
			end
		end
		if dirty then
			task:Call(UpdateTooltip)
		end
	end
end

do
	local function AddToSlot(bagId, slotIndex)
		local usedInCraftingType, _, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
		if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
			if DoesRunePassRequirements(runeType, rankRequirement, rarityRequirement) then
				local slot = ENCHANTING.runeSlots[runeType]
				local orgSound = slot.placeSound
				slot.placeSound = nil
				ENCHANTING:AddItemToCraft(bagId, slotIndex)
				slot.placeSound = orgSound
			end
		end
	end
	function addon:AddToTable(rowData)
		if not rowData then
			return
		end
		local power, essence, aspect = rowData[3], rowData[4], rowData[5]
		AddToSlot(power.bagId, power.slotIndex)
		AddToSlot(essence.bagId, essence.slotIndex)
		AddToSlot(aspect.bagId, aspect.slotIndex)
		PlaySound(SOUNDS.ENCHANTING_POTENCY_RUNE_PLACED)
	end
end

local function onMouseEnterGlyph(rowControl)
	local rowData = ZO_ScrollList_GetData(rowControl)
	if not rowData then
		return
	end
	if #rowData[2] > 0 then
		InitializeTooltip(ItemTooltip, rowControl, TOPRIGHT, -10, -96, TOPLEFT)
		ItemTooltip:SetLink(rowData[2])
	else
		-- unknown
	end
end

function addon:InitScrollList()
	local function getInBagString(itemLink)
		local inBag = ""
		if itemLink and itemLink ~= "" then
			local bagCount, bankCount = GetItemLinkStacks(itemLink)
			if bankCount > 0 then
				inBag = "|t28:28:esoui/art/icons/servicemappins/servicepin_bank.dds:inheritColor|t"
			elseif bagCount > 0 then
				inBag = "|t28:28:esoui/art/crafting/crafting_provisioner_inventorycolumn_icon.dds:inheritColor|t"
			end
		end
		return inBag
	end
	local function onMouseEnterRune(rowControl)
		local itemLink = rowControl.itemLink
		if not itemLink then
			return
		end
		if #itemLink > 0 then
			InitializeTooltip(ItemTooltip, rowControl, TOPRIGHT, -10, -96, TOPLEFT)
			ItemTooltip:SetLink(itemLink)
		else
			-- unkown
		end
	end
	local function onMouseExit(rowControl)
		ClearTooltip(ItemTooltip)
	end

	local function onClicked(rowControl, button)
		if not rowControl then
			return
		end
		local rowData = ZO_ScrollList_GetData(rowControl)
		if not rowData then
			return
		end
		if button == MOUSE_BUTTON_INDEX_RIGHT and IsChatSystemAvailableForCurrentPlatform() then
			ClearMenu()
			self:AddContextMenuGlyph(rowControl, rowData)
			ShowMenu(rowControl)
		elseif button == MOUSE_BUTTON_INDEX_LEFT then
			self:AddToTable(rowData)
		end
	end
	local function onRuneClicked(rowControl, button)
		if not rowControl.itemLink then
			return
		end
		if button == MOUSE_BUTTON_INDEX_RIGHT and IsChatSystemAvailableForCurrentPlatform() then
			ClearMenu()
			self:AddContextMenuRune(rowControl, rowControl.itemLink)
			ShowMenu(rowControl)
		end
	end

	local function setIcon(rowControl, rowControlName, itemData)
		local data = itemData and self.byRawName[itemData.rawName]
		local itemLink = data and data.itemLink or ""
		local icon = GetItemLinkIcon(itemLink)
		local control = rowControl:GetNamedChild(rowControlName)
		control:SetTexture(icon)
		control:SetHidden(#icon == 0)
		control.itemLink = itemLink
		control:SetHandler("OnMouseEnter", onMouseEnterRune)
		control:SetHandler("OnMouseExit", onMouseExit)
		control:SetHandler("OnMouseUp", onRuneClicked)
	end
	local SI_TOOLTIP_ITEM_NAME, zo_strformat = GetString(SI_TOOLTIP_ITEM_NAME), LocalizeString
	local unknown = GetString(SI_ENCHANTING_UNKNOWN_RESULT)
	local function setupDataRow(rowControl, rowData, scrollList)
		local textLabel = rowControl:GetNamedChild("Text")
		textLabel:SetText(#rowData[2] > 0 and zo_strformat(SI_TOOLTIP_ITEM_NAME, rowData[1]) or unknown)
		textLabel:SetColor(GetItemQualityColor(GetItemLinkQuality(rowData[2])):UnpackRGB())

		local power, essence, aspect = rowData[3], rowData[4], rowData[5]

		setIcon(rowControl, "Rune1", power)
		setIcon(rowControl, "Rune2", essence)
		setIcon(rowControl, "Rune3", aspect)
		rowControl:GetNamedChild("InBag"):SetText(getInBagString(rowData[2]))

		rowControl:SetHandler("OnMouseEnter", onMouseEnterGlyph)
		rowControl:SetHandler("OnMouseExit", onMouseExit)
		rowControl:SetHandler("OnClicked", onClicked)
	end
	ZO_ScrollList_AddDataType(self.resultList, 1, "EnchantMakerRowItem", 48, setupDataRow)

	ENCHANTING_SCENE:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_SHOWING then
				self:Refresh()
			end
		end
	)
	if ENCHANTING_SCENE:IsShowing() then
		self:Refresh()
	end
end

function addon:Refresh()
	self:UpdateData()
	self.filterPanel.levelMenu:PerformLayout()
	self.filterPanel.qualityMenu:PerformLayout()
end

do
	local byLevel = {}
	local byQuality = {}
	local function CreateNewTabFilterData(descriptor, texture, tooltip, callback)
		local tabData = {
			-- Menu bar data
			descriptor = descriptor,
			normal = texture,
			pressed = texture,
			highlight = texture,
			disabled = texture,
			tooltip = tooltip,
			callback = callback
		}

		return tabData
	end

	local function onMouseEnterRune(rowControl)
		local tooltip = ZO_MenuBarButtonTemplate_GetData(rowControl).tooltip
		if not tooltip then
			return
		end
		if #tooltip > 0 then
			InitializeTooltip(InformationTooltip, rowControl, BOTTOMRIGHT, 10, -10, TOPLEFT)
			SetTooltipText(InformationTooltip, tooltip)
		else
			-- unknown
		end
	end
	local function onMouseExit(rowControl)
		ClearTooltip(InformationTooltip)
	end
	local function onMenuEnter(self)
		onMouseEnterRune(self)
		return ZO_MenuBarButtonTemplate_OnMouseEnter(self)
	end
	local function onMenuExit(self)
		onMouseExit(self)
		return ZO_MenuBarButtonTemplate_OnMouseExit(self)
	end

	local function SetupButtonWithRequirement(button, data)
		local enabled = data.meetsUsageRequirement
		button.m_object:SetEnabled(enabled)
		button:GetNamedChild("Image"):SetColor((enabled and ZO_DEFAULT_ENABLED_COLOR or STAT_LOWER_COLOR):UnpackRGB())
		button:SetHandler("OnMouseEnter", onMenuEnter)
		button:SetHandler("OnMouseExit", onMenuExit)
		button:SetHitInsets(-16, -16, 16, 16)
	end
	local function SetupButtonWithRequirementByLevel(button, buttonData)
		local data = byLevel[buttonData.descriptor]
		SetupButtonWithRequirement(button, data)
	end
	local function SetupButtonWithRequirementByQuality(button, buttonData)
		local data = byQuality[buttonData.descriptor]
		SetupButtonWithRequirement(button, data)
	end

	local function SetupButtonWithTooltip(button)
		button:SetHandler("OnMouseEnter", onMenuEnter)
		button:SetHandler("OnMouseExit", onMenuExit)
		button:SetHitInsets(-16, -16, 16, 16)
	end

	function addon:InitControls()
		local wm = WINDOW_MANAGER
		LES:Init()
		local tabData = {
			name = SI_ENCHANT_MAKER,
			descriptor = self.name,
			disabled = "esoui/art/crafting/enchantment_tabicon_essence_disabled.dds",
			pressed = "esoui/art/crafting/enchantment_tabicon_essence_down.dds",
			highlight = "esoui/art/crafting/enchantment_tabicon_essence_over.dds",
			normal = "esoui/art/crafting/enchantment_tabicon_essence_up.dds",
			callback = function(tabData)
				LES:ShowRuneSlotContainer()
			end
		}

		local parent = LES:AddTab(tabData)

		parent:RegisterForEvent(
			EVENT_END_CRAFTING_STATION_INTERACT,
			function(eventCode, craftingType)
				if craftingType == CRAFTING_TYPE_ENCHANTING then
					self:Close()
				end
			end
		)

		local function refreshResultList()
			ZO_ScrollList_RefreshVisible(self.resultList)
		end
		local function refreshInventory()
			ENCHANTING.inventory:PerformFullRefresh()
		end

		CALLBACK_MANAGER:RegisterCallback(
			"CraftingAnimationsStopped",
			function()
				if GetCraftingInteractionType() ~= CRAFTING_TYPE_ENCHANTING then
					return
				end

				if GetNumLastCraftingResultLearnedTranslations() > 0 then
					self:UpdateTranslations()
				end
				task:Call(refreshResultList)

				if ZO_MenuBar_GetSelectedDescriptor(ENCHANTING.modeBar) ~= self.name then
					return
				end

				task:Call(refreshInventory)
			end
		)

		local function addPanel(panel)
			panel:SetParent(parent)
			panel:ClearAnchors()
			panel:SetAnchorFill()
			return panel
		end
		local panel = addPanel(EnchantMakerFilterPanel)
		self.filterPanel = panel

		self.qualityBackground = panel:GetNamedChild("QualityBackground")
		self.filterPanel.levelMenu = panel:GetNamedChild("Level")
		self.filterPanel.qualityMenu = panel:GetNamedChild("Quality")
		self.filterPanel.typeMenu = panel:GetNamedChild("Type")

		local control = panel:GetNamedChild("SearchButton")
		control:SetHandler(
			"OnClicked",
			function()
				self:Search()
			end
		)
		local control = panel:GetNamedChild("SearchQuestsButton")
		control:SetHandler(
			"OnClicked",
			function()
				self:SearchQuests()
			end
		)

		for _, data in pairs(self.power_runes) do
			byLevel[data.level] = data
		end
		for _, data in pairs(self.aspect_runes) do
			byQuality[data.quality] = data
		end

		self.filterPanel.levelMenu:SetSetupFunction(SetupButtonWithRequirementByLevel)
		self.filterPanel.qualityMenu:SetSetupFunction(SetupButtonWithRequirementByQuality)
		self.filterPanel.typeMenu:SetSetupFunction(SetupButtonWithTooltip)

		local function SetQualityColor(tabData)
			local quality = tabData.descriptor
			self.qualityBackground:SetColor(GetItemQualityColor(quality):UnpackRGB())
		end

		local ZO_MenuBar_AddButton = ZO_MenuBar_AddButton
		task:Call(
			function()
				local menu = self.filterPanel.levelMenu
				local highestUseableIndex = 0
				local byLevel2 = {}
				for _, data in pairs(self.power_runes) do
					if not byLevel2[data.level] then
						byLevel2[data.level] = data
					end
				end

				local zo_strformat, GetItemLinkGlyphMinLevels = LocalizeString, GetItemLinkGlyphMinLevels
				local SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_CHAMPION_POINTS = GetString(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_CHAMPION_POINTS)
				local SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_LEVEL = GetString(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_LEVEL)
				local function formatTooltip(itemLink, itemLink2)
					local minLevel, minChampionPoints = GetItemLinkGlyphMinLevels(itemLink)
					local text
					if minChampionPoints then
						text = zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_CHAMPION_POINTS, minChampionPoints)
					else
						text = zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_LEVEL, minLevel)
					end
					return string.format("%s / %s\n%s", itemLink, itemLink2, text)
				end
				for i = 1, 16 do
					ZO_MenuBar_AddButton(menu, CreateNewTabFilterData(i, byLevel[i].icon, formatTooltip(byLevel[i].itemLink, byLevel2[i].itemLink)))
					if byLevel[i].meetsUsageRequirement then
						highestUseableIndex = i
					end
				end
				ZO_MenuBar_SelectDescriptor(menu, highestUseableIndex)
			end
		):Then(
			function()
				local menu = self.filterPanel.qualityMenu
				for i = 1, 5 do
					ZO_MenuBar_AddButton(menu, CreateNewTabFilterData(i, byQuality[i].icon, string.format("%s\n%s", byQuality[i].itemLink, GetString("SI_ITEMQUALITY", byQuality[i].quality)), SetQualityColor))
				end
				ZO_MenuBar_SelectDescriptor(menu, 1)
			end
		):Then(
			function()
				local menu = self.filterPanel.typeMenu
				for i = 1, 3 do
					ZO_MenuBar_AddButton(menu, CreateNewTabFilterData(i, self.glyph_types[i].icon, GetString("SI_ITEMTYPE", self.glyph_types[i].itemType)))
				end
				ZO_MenuBar_SelectDescriptor(menu, 3)

				self.filterPanel.typeMenu:PerformLayout()

				local panel = addPanel(EnchantMakerOutput)
				self.outputPanel = panel
				local control = panel:GetNamedChild("Back")
				control:SetHandler(
					"OnClicked",
					function()
						self:OpenFilter()
					end
				)

				self.resultList = panel:GetNamedChild("List")
				self.resultList.empty = panel:GetNamedChild("Empty")
				self.resultList.empty:SetText(GetString(SI_ENCHANT_MAKER_EMPY_NORESULT))
			end
		):Then(
			function()
				self:InitScrollList()
			end
		)
	end
end

function addon:InitData()
	local byRawName = self.byRawName

	local linkTemplate = "|H0:item:%i:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
	local GetItemLinkInfo, GetItemLinkName = GetItemLinkInfo, GetItemLinkName
	local function GetMoreDetails(itemId, data)
		local itemLink = string.format(linkTemplate, itemId)
		data.itemLink = itemLink

		local icon, _, meetsUsageRequirement = GetItemLinkInfo(itemLink)
		local rawName = GetItemLinkName(itemLink)

		data.icon, data.meetsUsageRequirement = icon, meetsUsageRequirement
		data.rawName = rawName
		byRawName[rawName] = data
	end
	for itemId, data in pairs(self.power_runes) do
		GetMoreDetails(itemId, data)
	end
	for itemId, data in pairs(self.essence_runes) do
		GetMoreDetails(itemId, data)
	end
	for itemId, data in pairs(self.aspect_runes) do
		GetMoreDetails(itemId, data)
	end
end

function addon:UpdateData()
	local GetItemLinkInfo, GetItemLinkName = GetItemLinkInfo, GetItemLinkName
	local function GetMoreDetails(itemId, data)
		local itemLink = data.itemLink

		local meetsUsageRequirement = select(3, GetItemLinkInfo(itemLink))
		data.meetsUsageRequirement = meetsUsageRequirement
	end
	for itemId, data in pairs(self.power_runes) do
		GetMoreDetails(itemId, data)
	end
	for itemId, data in pairs(self.essence_runes) do
		GetMoreDetails(itemId, data)
	end
	for itemId, data in pairs(self.aspect_runes) do
		GetMoreDetails(itemId, data)
	end
end

local function HookEnchantSound()
	local newRuneStone = true
	local orgOnSlotChanged = ENCHANTING.OnSlotChanged
	function ENCHANTING.OnSlotChanged(...)
		newRuneStone = true
		return orgOnSlotChanged(...)
	end

	local orgGetLastRunestoneSoundParams = ENCHANTING.GetLastRunestoneSoundParams
	function ENCHANTING:GetLastRunestoneSoundParams()
		if newRuneStone then
			newRuneStone = false
			return orgGetLastRunestoneSoundParams(self)
		end

		local sound = ""
		return sound, self.potencyLength, sound, self.essenceLength, sound, self.aspectLength
	end
end

do
	local searchBoxWidth = 350
	local noSearchBoxWidth = 64
	local glass = "|t40:40:esoui/art/lfg/lfg_tabicon_grouptools_down.dds|t"

	local function VotanSearchBoxMouseDown(bagSearch, button)
		if not bagSearch:HasFocus() and button == MOUSE_BUTTON_INDEX_RIGHT then
			bagSearch:SetText("")
		end
	end

	local function StartSearch(control)
		control.addon:Search()
	end

	local setDefaultText
	if GetAPIVersion() <= 101034 then
		function setDefaultText(control, text)
			return ZO_EditDefaultText_Initialize(control, text)
		end
	else
		function setDefaultText(control, text)
			control:SetDefaultText(text)
		end
	end

	local function SetupControl(self, bagSearchBg)
		local bagSearch = bagSearchBg:GetNamedChild("Box")
		local bagSearchTx = bagSearch:GetNamedChild("Text")
		local closeButton = WINDOW_MANAGER:CreateControlFromVirtual(nil, bagSearchBg, "ZO_CloseButton")

		bagSearch.addon = self
		self.searchBox = bagSearch

		setDefaultText(bagSearch, glass)

		local function VotanSearchBoxFocusGained(control, ...)
			bagSearchBg:SetAlpha(0.25)
			bagSearchBg:SetWidth(searchBoxWidth)
			closeButton:SetHidden(false)
			setDefaultText(bagSearch, "")
			closeButton:SetDimensions(16, 16)
			closeButton:SetHidden(false)
		end
		local function VotanSearchBoxFocusLost(control, ...)
			if bagSearch:GetText() ~= "" then
				bagSearchBg:SetAlpha(0.25)
				bagSearchBg:SetWidth(searchBoxWidth)
				return
			else
				bagSearchBg:SetAlpha(0)
				bagSearchBg:SetWidth(noSearchBoxWidth)
				closeButton:SetHidden(true)
			end
			setDefaultText(bagSearch, glass)
		end
		local function VotanSearchBoxTextChanged(control, ...)
			if WINDOW_MANAGER:GetFocusControl() ~= bagSearch then
				return VotanSearchBoxFocusLost(control, ...)
			end
		end
		local function VotanSearchBoxCloseClick(control, ...)
			bagSearch:SetText("")
			VotanSearchBoxFocusLost()
		end

		closeButton:ClearAnchors()
		closeButton:SetAnchor(TOPLEFT, bagSearch, TOPRIGHT, 0, 4)
		closeButton:SetHidden(true)
		closeButton:SetHandler("OnMouseDown", VotanSearchBoxCloseClick)
		closeButton:SetDimensions(16, 16)
		closeButton:SetInheritAlpha(false)

		bagSearchBg:SetEdgeTexture("EsoUI/Art/Tooltips/UI-SliderBackdrop.dds", 32, 4)
		bagSearchBg:SetInsets(1, 1, 1, 1)
		bagSearch:ClearAnchors()
		bagSearch:SetAnchor(TOPLEFT, nil, TOPLEFT, 4, 4)
		bagSearch:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -20, -4)
		bagSearch:SetInheritAlpha(false)
		bagSearch:SetEditEnabled(true)
		if bagSearchTx then
			bagSearchTx:ClearAnchors()
			bagSearchTx:SetAnchorFill()
		end
		VotanSearchBoxFocusLost(bagSearch)

		bagSearch:SetHandler(
			"OnEnter",
			function(control)
				control:LoseFocus()
				VotanSearchBoxFocusLost()
			end
		)
		bagSearch:SetHandler("OnMouseDown", VotanSearchBoxMouseDown, self.name)
		bagSearch:SetHandler("OnFocusGained", VotanSearchBoxFocusGained, self.name)
		bagSearch:SetHandler("OnFocusLost", VotanSearchBoxFocusLost, self.name)
		bagSearch:SetHandler("OnTextChanged", StartSearch, self.name)
	end

	function addon:SetupSearchBox()
		SetupControl(self, EnchantMakerOutputSearch)
	end
end

function addon:Initialize()
	task = async:Create(addon.name)
	task:Call(
		function()
			self:InitData()
			self:InitTranslationLearned()
		end
	)
	HookEnchantSound()
	local scene = SCENE_MANAGER:GetScene("enchanting")
	local function deferControls(oldState, newState)
		if newState == SCENE_SHOWING then
			scene:UnregisterCallback("StateChange", deferControls)
			task:Call(
				function()
					self:InitControls()
				end
			):Then(
				function()
					self:SetupSearchBox()
				end
			)
		end
	end
	scene:RegisterCallback("StateChange", deferControls)
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:Initialize()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

ENCHANT_MAKER = addon
