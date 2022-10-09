if GetAPIVersion() < 100026 then return end

function PotMaker:ApplyLanguageSpecific()
	local DoesItemLinkFulfillJournalQuestCondition = DoesItemLinkFulfillJournalQuestCondition
	local function matches(self, quests)
		for i = 1, #quests do
			if DoesItemLinkFulfillJournalQuestCondition(self.itemLink, unpack(quests[i])) then
				return true
			end
		end
	end
	function PotMaker.Potion:MatchesQuest()
		if #PotMaker.masterquests > 0 and self.numTraits >= 3 and self.solvent and self.solvent.level >= 50 then
			if matches(self, PotMaker.masterquests) then return true end
		end
		if #PotMaker.quests > 0 and self.ingredients and #self.ingredients == 2 and matches(self, PotMaker.quests) then return true end
		return false
	end

	---- for Japanese Translation ----
	if PotMaker.language.name == "jp" then
		local fontCommonSettings = "$(CHAT_FONT)|16|soft-shadow-thin"
		PotionMakerSearchButton:SetFont(fontCommonSettings)
		PotionMakerOutputCombinationLabel:SetFont(fontCommonSettings)
		PotionMakerOutputTraitLabel:SetFont(fontCommonSettings)
		PotionMakerOutputSearchButton:SetFont(fontCommonSettings)
		PotionMakerTraitLabel1:SetFont(fontCommonSettings)
		PotionMakerTraitLabel2:SetFont(fontCommonSettings)
		PotionMakerSolventLabel:SetFont(fontCommonSettings)
		PotionMakerReagentLabel:SetFont(fontCommonSettings)
		PotionMakerOnlyReagentText:SetFont(fontCommonSettings)
		PotionMakerOnly2Text:SetFont(fontCommonSettings)
		PotionMakerQuestPotionsText:SetFont(fontCommonSettings)
		PotionMakerFavorites:SetFont(fontCommonSettings)
		PotionMakerOutputFavorite:SetFont(fontCommonSettings)
		PotionMakerOutputPageLabel:SetFont(fontCommonSettings)
	end
	---- for Japanese Translation end ----
end

local GetJournalQuestInfo, GetJournalQuestNumSteps, GetJournalQuestConditionInfo = GetJournalQuestInfo, GetJournalQuestNumSteps, GetJournalQuestConditionInfo
local function ParseSteps(quests, questIndex, numSteps)
	for stepIndex = 1, numSteps do
		local numConditions = GetJournalQuestNumConditions(questIndex, stepIndex)
		if numConditions > 0 then
			for conditionIndex = 1, numConditions do
				quests[#quests + 1] = { questIndex, stepIndex, conditionIndex, true }
			end
		end
	end
end

function PotMaker.GetQuests()
	local numSteps, numConditions, questIndex, _
	local quests = { }
	local masterquests = { }

	-- quest text lines
	local questType
	for questIndex = 1, MAX_JOURNAL_QUESTS do
		if IsValidQuestIndex(questIndex) then
			questType = GetJournalQuestType(questIndex)
			if questType == QUEST_TYPE_CRAFTING then
				numSteps = GetJournalQuestNumSteps(questIndex)
				ParseSteps(numSteps < 4 and quests or masterquests, questIndex, numSteps)
			end
		end
	end

	return quests, masterquests
end

function PotMaker:InternalStartSearch(quests, masterquests)
	self.quests, self.masterquests = quests, masterquests

	self.resultsMaxIndex = 0
	PotionMakerOutput.title:SetText(self.language.search_results)
	self.restartSearch()
end