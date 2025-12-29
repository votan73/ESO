DungeonQueue4Stickerbook = DungeonQueue4Stickerbook or {}
local ttq = DungeonQueue4Stickerbook
ttq = {
	name = "DungeonQueue4Stickerbook",
	author = "tim99, votan & Antisenil",
	svChar = {},
	firstCall = true,
	complSets = false,
	complQust = false,
	col_tim99 = ZO_ColorDef:New("9b30ff"),
	}
ttq.svCharDef = {
	autoqueue = true,
}
----------------------------------------------------------------------------------------------------
--need the copies as quest and set checks empty their tables 
function ttq.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[ttq.deepcopy(orig_key)] = ttq.deepcopy(orig_value)
        end
        setmetatable(copy, ttq.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local UndauntedPledges = ttq.deepcopy(ttq_DungeonData)
local UndauntedDLCPledges = ttq.deepcopy(ttq_DungeonData)
local DungeonQuest = ttq.deepcopy(ttq_DungeonData)
local DungeonSets = ttq.deepcopy(ttq_DungeonData)
local DungeonSetsVet = ttq.deepcopy(ttq_DungeonData)
----------------------------------------------------------------------------------------------------
function ttq:GetTextColor()
	local b, c, d, e = self.normalColor:UnpackRGBA()
	if self.selected then
		return b, c, d, 0.4
	elseif self.mouseover then
		return b, c, d, 0.7
	end
	return b, c, d, e
end
----------------------------------------------------------------------------------------------------
function ttq.checkCompletedSets()
	for i, v in pairs(DungeonSets) do
		local numSetsDone = 0
		for j = 1, #v.sets do
			local itemSetCollectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(v.sets[j])
			if itemSetCollectionData then
				local numUnlockedPieces, numPieces = itemSetCollectionData:GetNumUnlockedPieces(), itemSetCollectionData:GetNumPieces()
				if numUnlockedPieces == numPieces then
					numSetsDone = numSetsDone + 1
				end
			else
				numSetsDone = numSetsDone + 1 -- does not exist yet
			end
		end
		if numSetsDone == #v.sets then
			DungeonSets[i] = nil
		end
	end
	for i, v in pairs(DungeonSetsVet) do
		local HelmetID = v["helmet"]
		local numSetsDone = 0
		if HelmetID ~= nil then
			for j = 1, HelmetID do
				local itemSetCollectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(HelmetID)
				if itemSetCollectionData then
					local numUnlockedPieces = 0
					for _, pieceData in itemSetCollectionData:PieceIterator() do
						if pieceData:IsUnlocked() and GetItemLinkEquipType(pieceData:GetItemLink()) == EQUIP_TYPE_HEAD then
							numUnlockedPieces = numUnlockedPieces + 1
						end
					end
					if numUnlockedPieces >= 3 then
						numSetsDone = numSetsDone + 1
					end
				else
					numSetsDone = numSetsDone + 1 -- does not exist yet
				end
			end
			if numSetsDone == HelmetID then
				DungeonSetsVet[i] = nil
			end
		elseif HelmetID == nil then
			DungeonSetsVet[i] = nil
		end
	end
	local next = next
	if next(DungeonSets) == nil and next(DungeonSetsVet) == nil then
		ttq.complSets = true
	end
	--d("checkCompletedSets:complSets = "..tostring(ttq.complSets))
end
----------------------------------------------------------------------------------------------------
function ttq.checkCompletedQuests()
	for i, v in pairs(DungeonQuest) do
		local QstID = v["quest"]
		if GetCompletedQuestInfo(QstID) ~= "" then
			DungeonQuest[i] = nil
		end
	end
	if next(DungeonQuest) == nil then
		ttq.complQust = true
	end
	--d("checkCompletedQuests:complQust = "..tostring(ttq.complQust))
end
----------------------------------------------------------------------------------------------------
function ttq.markInis(DungeonTable, parent)
	if IsUnitGrouped("player") and not IsUnitGroupLeader("player") then
		return
	end
	--select missing
	if not parent then
		return
	end
	for i = 1, parent:GetNumChildren() do
		local obj = parent:GetChild(i)
		if obj then
			local id = obj.node.data.id
			if DungeonTable[id] then
				if obj.check:GetState() == 0 then
					obj.check:SetState(BSTATE_PRESSED, true)
					ZO_ACTIVITY_FINDER_ROOT_MANAGER:ToggleLocationSelected(obj.node.data)
				end
				ZO_SelectableLabel_SetNormalColor(obj.text, obj.node.data.isSelected and ttq.col_tim99 or ZO_NORMAL_TEXT)
				obj.text:RefreshTextColor()
			end
		end
	end
end
----------------------------------------------------------------------------------------------------
function ttq.markAndQueueNormalInis(DungeonTable)
	ttq.markInis(DungeonTable, ZO_DungeonFinder_KeyboardListSectionScrollChildContainer2) --2=normal
end
----------------------------------------------------------------------------------------------------
function ttq.markAndQueueVetInis(DungeonTable)
	ttq.markInis(DungeonTable, ZO_DungeonFinder_KeyboardListSectionScrollChildContainer3) --3=vet
end
----------------------------------------------------------------------------------------------------
function ttq.markAndQueueNormalInisSets()
	ttq.markAndQueueNormalInis(DungeonSets)
end
function ttq.markAndQueueVetInisSets()
	ttq.markAndQueueVetInis(DungeonSets)
	ttq.markAndQueueVetInis(DungeonSetsVet)
end
function ttq.markAndQueueNormalInisQust()
	ttq.markAndQueueNormalInis(DungeonQuest)
end
function ttq.markAndQueueVetInisQust()
	ttq.markAndQueueVetInis(DungeonQuest)
end
----------------------------------------------------------------------------------------------------
function ttq.createQueueButton()
	local icon = zo_iconFormat("/esoui/art/icons/collectible_memento_pumpkincarving.dds", 26, 31)

	local dropdown = CreateControlFromVirtual("TIM99_SearchingForMissing", ZO_SearchingForGroup, "ZO_ComboBox")
	dropdown:SetDimensions(220, ZO_DungeonFinder_KeyboardFilter:GetHeight())
	dropdown:ClearAnchors()
	dropdown:SetAnchor(TOPRIGHT, ZO_DungeonFinder_KeyboardFilter, TOPLEFT, -9, 0)
	dropdown:SetHidden(true)

	local comboBox = ZO_ComboBox_ObjectFromContainer(dropdown)
	comboBox:SetDisabledColor(ZO_DEFAULT_ENABLED_COLOR)
	comboBox:SetFont("ZoFontWinT1")
	comboBox:SetSortsItems(false)
	comboBox:SetSpacing(4)
	comboBox:SetNoSelectionText(string.format("%s   Select", icon))
	comboBox:SetMultiSelectionTextFormatter(string.format("%s   <<1>> <<1[Category/Categories]>>", icon))
	comboBox.m_enableMultiSelect = true
	comboBox.m_maxNumSelections = nil
	comboBox.m_multiSelectItemData = {}

	local inchanged
	ZO_PreHook(
		ZO_ACTIVITY_FINDER_ROOT_MANAGER,
		"ClearSelections",
		function(self)
			if not inchanged then
				ttq.comboBox:ClearAllSelections()
			end
		end
	)

	local function OnFiltersChanged(comboBox, entryText, entry)
		--init locs
		inchanged = true
		ZO_ACTIVITY_FINDER_ROOT_MANAGER:ClearAndUpdate()
		local selectedItems = comboBox:GetSelectedItemData()
		for _, item in ipairs(selectedItems) do
			item.filterValue()
		end
		inchanged = false
	end
	do
		local filterName = string.format("%s   Missing Sets Normal", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = ttq.markAndQueueNormalInisSets
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   Missing Sets Vet + Helmets", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = ttq.markAndQueueVetInisSets
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   Missing Quests Normal", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = ttq.markAndQueueNormalInisQust
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   Missing Quests Vet", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = ttq.markAndQueueVetInisQust
		comboBox:AddItem(entry)
	end
	
	local function QuestsToActivity(pledges, difficulty, dlc)
		local activities = {}
		for DngID, DngTbl in pairs(pledges) do
			local questId = DngTbl["pledge"]
			local dngmode = DngTbl["helmet"] -- nil = normal , value = true = veteran
			local dngdlc = DngTbl["dlc"]
			if HasQuest(questId) then
				local findName = GetQuestName(questId)
				for i = 1, MAX_JOURNAL_QUESTS do
					if IsValidQuestIndex(i) then
						local questName, _, _, activeStepType = GetJournalQuestInfo(i)
						if activeStepType == 1 and questName == findName and dlc == dngdlc and ( difficulty == dngmode or difficulty) then
							activities[DngID] = true
						end
					end
				end
			end
		end
		return activities
	end
	do
		local filterName = string.format("%s   My Pledges Normal", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = function()
			ttq.markAndQueueNormalInis(QuestsToActivity(UndauntedPledges, nil, false))
		end
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   My Pledges Vet", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = function()
			ttq.markAndQueueVetInis(QuestsToActivity(UndauntedPledges, true, false))
		end
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   My DLC Pledges Normal", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = function()
			ttq.markAndQueueNormalInis(QuestsToActivity(UndauntedDLCPledges, nil, true))
		end
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   My DLC Pledges Vet", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = function()
			ttq.markAndQueueVetInis(QuestsToActivity(UndauntedDLCPledges, true, true))
		end
		comboBox:AddItem(entry)
	end

	ttq.comboBox = comboBox
	
end
----------------------------------------------------------------------------------------------------
local function fragmentChange(oldState, newState)
	if ttq.fragment:IsShowing() and DUNGEON_FINDER_KEYBOARD.filterComboBox.m_selectedItemData and not DUNGEON_FINDER_KEYBOARD.filterComboBox.m_selectedItemData.data.singular then
		TIM99_SearchingForMissing:SetHidden(false)
	else
		TIM99_SearchingForMissing:SetHidden(true)
	end
end
----------------------------------------------------------------------------------------------------
function ttq.playerActivated()
	EVENT_MANAGER:UnregisterForEvent(ttq.name, EVENT_PLAYER_ACTIVATED)
	EVENT_MANAGER:RegisterForEvent(
		ttq.name,
		EVENT_ITEM_SET_COLLECTION_UPDATED,
		function()
			ttq.checkCompletedSets()
		end
	)
	EVENT_MANAGER:RegisterForEvent(
		ttq.name,
		EVENT_ITEM_SET_COLLECTIONS_UPDATED,
		function()
			ttq.checkCompletedSets()
		end
	)
	EVENT_MANAGER:RegisterForEvent(
		ttq.name,
		EVENT_ITEM_SET_COLLECTION_SLOT_NEW_STATUS_CLEARED,
		function()
			ttq.checkCompletedSets()
		end
	)
	EVENT_MANAGER:RegisterForEvent(
		ttq.name,
		EVENT_SKILL_POINTS_CHANGED,
		function()
			ttq.checkCompletedQuests()
		end
	)

	ttq.createQueueButton()
	ttq.checkCompletedSets()
	ttq.checkCompletedQuests()
	

	ttq.fragment = DUNGEON_FINDER_KEYBOARD:GetFragment()
	ttq.fragment:RegisterCallback("StateChange", fragmentChange)

	
	ZO_PostHook(
		DUNGEON_FINDER_KEYBOARD.navigationTree.templateInfo.ZO_ActivityFinderTemplateNavigationEntry_Keyboard,
		"setupFunction",
		function(node, control, data, open, userRequested, enabled)
			local n = data.isSelected and ttq.col_tim99 or ZO_NORMAL_TEXT
			ZO_SelectableLabel_SetNormalColor(control.text, n)
			if control.text.GetTextColor ~= ttq.GetTextColor then
				control.text.GetTextColor = ttq.GetTextColor
			end
			control.text:RefreshTextColor()
		end
	)

	--to avoid overlapping with tim99sColoredLists
	--ZO_PostHook("ZO_ActivityFinderTemplateNavigationEntryKeyboard_OnClicked", function(control, button)
	--	ZO_SelectableLabel_SetNormalColor(control.text, control.node.data.isSelected and ttq.col_tim99 or ZO_NORMAL_TEXT)
	--	control.text:RefreshTextColor()
	--end)

	ZO_PostHook(
		ZO_ActivityFinderTemplate_Keyboard,
		"OnFilterChanged",
		function(comboBox, entryText, entry)
			fragmentChange()
		end
	)
	
	-- ZO_PostHook(ZO_ActivityFinderTemplate_Keyboard, "RefreshJoinQueueButton", function()
	--	if ZO_DungeonFinder_KeyboardListSectionScrollChildZO_ActivityFinderTemplateNavigationHeader_Keyboard1 and not ZO_DungeonFinder_KeyboardListSectionScrollChildZO_ActivityFinderTemplateNavigationHeader_Keyboard1:IsHidden() then
	--		TIM99_SearchingForMissing:SetHidden(false)
	--	else
	--		TIM99_SearchingForMissing:SetHidden(true)
	--	end
	-- end)
end
----------------------------------------------------------------------------------------------------
function ttq.addonLoaded(event, addonName)
	if addonName ~= ttq.name then
		return
	end
	EVENT_MANAGER:UnregisterForEvent(ttq.name, EVENT_ADD_ON_LOADED)
	EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_PLAYER_ACTIVATED, ttq.playerActivated)

	ttq.svChar = ZO_SavedVars:NewAccountWide("DunQ4Stickerbook", 1, nil, ttq.svCharDef, GetWorldName())
	

	SLASH_COMMANDS["/dq"] = function(a)
		if a == nil or a == "" or a == " " then
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[DunQ4Stickerbook]  Usage-Help:|r", GetTimeString()))
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  1)|r   |cFFFFFF/dq miss|r |c666666= Prints all Dungeons with missing sets|r"))
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  2)|r   |cFFFFFF/dq all|r |c666666= Prints all Dungeons|r"))
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  3)|r   |cFFFFFF/dq done|r |c666666= Prints all pledge-id ever made|r"))
			--CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  3)|r   |cFFFFFF/tq auto|r |c666666= Toggle auto-queue after marking. now:|r |c9B30FF%s|r", tostring(ttq.svChar.autoqueue)))
			--CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  4)|r   |cFFFFFF/tq check|r |c666666= Recalculates the missing sets|r"))
			--CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  5)|r   |cFFFFFF/tq quest|r |c666666= Recalculates the missing quests|r"))
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  4)|r   |cFFFFFF/dq|r itemLINK |c666666= if|r |cFFFFFFitemLink|r |c666666is a from a valid set, it prints the setId|r"))
		
		elseif a == "miss" then
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[DunQ4Stickerbook]  Missing Sets from:|r", GetTimeString()))
			local b = 0
			for c, d in pairs(DungeonSets) do
				b = b + 1
				CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  %s)|r   %s", b, GetActivityName(c)))
			end
		
		elseif a == "all" then
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[DunQ4Stickerbook]  All Dungeons:|r (#%s)", GetTimeString(), GetNumActivitiesByType(LFG_ACTIVITY_DUNGEON)))
			local b = 0
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  normal:|r"))
			for c = 1, GetNumActivitiesByType(LFG_ACTIVITY_DUNGEON) do
				b = b + 1
				local d = GetActivityIdByTypeAndIndex(LFG_ACTIVITY_DUNGEON, c)
				CHAT_SYSTEM:AddMessage(string.format("|c9B30FF    %02d)|r   %03d - %s", b, d, GetActivityName(d)))
			end
			b = 0
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  vet:|r"))
			for c = 1, GetNumActivitiesByType(LFG_ACTIVITY_MASTER_DUNGEON) do
				b = b + 1
				local d = GetActivityIdByTypeAndIndex(LFG_ACTIVITY_MASTER_DUNGEON, c)
				CHAT_SYSTEM:AddMessage(string.format("|c9B30FF    %02d)|r   %03d - %s", b, d, GetActivityName(d)))
			end

		elseif a == "done" then
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[DunQ4Stickerbook]  Pledges done:|r", GetTimeString()))
			local activityToName = {}
			local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_DUNGEON)
			for i = 1, #locations do
				local activityId = locations[i]:GetId()
				local name = locations[i]:GetRawName():gsub("Der ", "")
				local list = activityToName[name] or {}
				list[#list + 1] = activityId
				activityToName[name] = list
			end
			local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_MASTER_DUNGEON)
			for i = 1, #locations do
				local activityId = locations[i]:GetId()
				local name = locations[i]:GetRawName():gsub("Der ", "")
				local list = activityToName[name] or {}
				list[#list + 1] = activityId
				activityToName[name] = list
			end

			local questId = nil
			while true do
				questId = GetNextCompletedQuestId(questId)
				if questId then
					local name, questType = GetCompletedQuestInfo(questId)
					if questType == QUEST_TYPE_UNDAUNTED_PLEDGE then
					--if questType == QUEST_TYPE_DUNGEON then
						name = name:gsub("Der ", "")
						local list = activityToName[name]
						if list then
							CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  pledge:|r %i |c9B30FF- (n=%i,v=%i)|r - %s", questId, list[1] or 0, list[2] or 0, name))
							--lines[#lines + 1] = string.format("[%i] = {n=%i,v=%i}, -- %s", questId, list[1] or 0, list[2] or 0, name)
						else
							CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  pledge:|r %i |c9B30FF- (n=%i,v=%i)|r - %s", questId, 0, 0, name))
							--lines[#lines + 1] = string.format("[%i] = {n=%i,v=%i}, -- %s", questId, 0, 0, name)
						end
					end
				else
					break
				end
			end
		
		--elseif a == "auto" then
		--	ttq.svChar.autoqueue = not ttq.svChar.autoqueue
		--	CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]  Auto-Queueing is now set to:|r |cFFFFFF%s|r", GetTimeString(), tostring(ttq.svChar.autoqueue)))
		
		--elseif a == "check" then
		--	ttq.checkCompletedSets()
		--	CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]  Set recalculation done.|r", GetTimeString()))
		
		--elseif a == "quest" then
		--	ttq.checkCompletedQuests()
		--	CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]  Quest recalculation done.|r", GetTimeString()))
		
		else --itemLINK from set-collection e.g.
			local e, f, f, f, f, g = GetItemLinkSetInfo(a, false)
			if e == true then
				CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[DunQ4Stickerbook]|r  |cFFFFFFSetId=%s  (%s)|r", GetTimeString(), tostring(g), tostring(a)))
			else
				CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[DunQ4Stickerbook]|r  WTF is  |cFFFFFF%s|r ???", GetTimeString(), tostring(a)))
			end
		end
	end
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_ADD_ON_LOADED, ttq.addonLoaded)

 --[[
 SLASH_COMMANDS["/dqtest"] = function()
 	-- local activityToName = {}
 	-- local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_DUNGEON)
 	-- for i = 1, #locations do
 	-- 	local activityId = locations[i]:GetId()
 	-- 	activityToName[activityId] = locations[i]:GetRawName():gsub("\194\160II", ""):gsub("\194\160I", "")
 	-- end
 	-- local setIdToActivity = {}
 	-- for _, collectionData in ITEM_SET_COLLECTIONS_DATA_MANAGER:ItemSetCollectionIterator() do
 	-- 	for _, pieceData in collectionData:PieceIterator() do
 	-- 		local quality = pieceData:GetDisplayQuality()
 	-- 		if quality < 4 then
 	-- 			local categoryData = collectionData:GetCategoryData()
 	-- 			for activityId, name in pairs(activityToName) do
 	-- 				if name == categoryData:GetFormattedName() then
 	-- 					local list = setIdToActivity[activityId] or {sets = {}}
 	-- 					list.sets[#list.sets + 1] = collectionData:GetId()
 	-- 					list.name = name
 	-- 					setIdToActivity[activityId] = list
 	-- 				end
 	-- 			end
 	-- 			break
 	-- 		end
 	-- 	end
 	-- end
 	-- 	local lines = {}
 	-- 	for activityId, list in pairs(setIdToActivity) do
 	-- 		lines[#lines + 1] = string.format("[%i] = {sets={%s}}, -- %s", activityId, table.concat(list.sets,","), GetActivityName(activityId))
 	-- 	end
 	-- 	DungeonQueue4Stickerbook.normal = lines

 	-- 	local activityToName = {}
 	-- 	local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_MASTER_DUNGEON)
 	--     for i = 1, #locations do
 	--         local activityId = locations[i]:GetId()
 	-- 		activityToName[activityId] = locations[i]:GetRawName():gsub("\194\160II", ""):gsub("\194\160I", "")
 	-- 	end
	-- 	local setIdToActivity = {}
 	-- 	for _, collectionData in ITEM_SET_COLLECTIONS_DATA_MANAGER:ItemSetCollectionIterator() do
	-- 		if collectionData:GetNumPieces() == 6 then
 	-- 			for _, pieceData in collectionData:PieceIterator() do
 	-- 				local quality = pieceData:GetDisplayQuality()
 	-- 				if quality == 4 then
 	-- 					if GetItemLinkEquipType(pieceData:GetItemLink()) == EQUIP_TYPE_HEAD then
	-- 						local categoryData = collectionData:GetCategoryData()
 	-- 						for activityId, name in pairs(activityToName) do
 	-- 							if name == categoryData:GetFormattedName() then
 	-- 								local list = setIdToActivity[activityId] or { sets={} }
 	-- 								list.sets[#list.sets+1] = collectionData:GetId()
 	-- 								list.name = name
 	-- 								setIdToActivity[activityId] = list
 	-- 							end
 	-- 						end
 	-- 						break
 	-- 					end
 	-- 				end
 	-- 			end
 	-- 		end
 	-- 	end
 	-- 	local lines = {}
 	-- 	for activityId, list in pairs(setIdToActivity) do
 	-- 		lines[#lines + 1] = string.format("[%i] = {sets={%s}}, -- %s", activityId, table.concat(list.sets,","), GetActivityName(activityId))
 	-- 	end
 	-- 	DungeonQueue4Stickerbook.vet = lines

 	local activityToName = {}
 	local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_DUNGEON)
 	for i = 1, #locations do
 		local activityId = locations[i]:GetId()
 		local name = locations[i]:GetRawName():gsub("Der ", "")
 		local list = activityToName[name] or {}
 		list[#list + 1] = activityId
 		activityToName[name] = list
 	end
 	local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_MASTER_DUNGEON)
 	for i = 1, #locations do
 		local activityId = locations[i]:GetId()
 		local name = locations[i]:GetRawName():gsub("Der ", "")
 		local list = activityToName[name] or {}
 		list[#list + 1] = activityId
 		activityToName[name] = list
 	end

 	local lines = {}
 	local questId = nil
 	while true do
 		questId = GetNextCompletedQuestId(questId)
 		if questId then
 			local name, questType = GetCompletedQuestInfo(questId)
 			if questType == QUEST_TYPE_UNDAUNTED_PLEDGE then
 			--if questType == QUEST_TYPE_DUNGEON then
 				name = name:gsub("Der ", "")
 				local list = activityToName[name]
 				if list then
 					lines[#lines + 1] = string.format("[%i] = {n=%i,v=%i}, -- %s", questId, list[1] or 0, list[2] or 0, name)
 				else
 					lines[#lines + 1] = string.format("[%i] = {n=%i,v=%i}, -- %s", questId, 0, 0, name)
				end
 			end
 		else
 			break
 		end
 	end
 	DungeonQueue4Stickerbook.pledges = lines
 end
 --]]