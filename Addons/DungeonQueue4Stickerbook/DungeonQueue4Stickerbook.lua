DungeonQueue4Stickerbook = DungeonQueue4Stickerbook or {}
local ttq = DungeonQueue4Stickerbook
ttq = {
	name      = "DungeonQueue4Stickerbook",
	author    = "tim99",
	svChar    = {},
	firstCall = true,
	complSets = false,
	complQust = false,
	col_tim99 = ZO_ColorDef:New("9b30ff"),
}
ttq.svCharDef = {
	autoqueue	= true,
}
--todo: merge tables
local DungeonSets={ --ActivityId
	[2]	  = {sets={ 33, 61,297}}, --Fungal Grotto 1
	[3]	  = {sets={ 35, 55,296}}, --Spindleclutch 1
	[4]	  = {sets={110,197,295}}, --Banished Cells 1
	[5]	  = {sets={ 96,300,301}}, --Darkshade Caverns 1
	[6]	  = {sets={ 29,194,299}}, --Wayrest Sewers 1
	[7]	  = {sets={ 28,155,298}}, --Elden Hollow 1
	[8]	  = {sets={156,303,304}}, --Arx Corinium
	[9]   = {sets={122,134,302}}, --Crypt of Hearts 1
	[10]  = {sets={158,159,160}}, --City of Ash 1
	[11]  = {sets={ 53,103,307}}, --Direfrost Keep
	[12]  = {sets={ 77,102,305}}, --Volenfell
	[13]  = {sets={186,188,193}}, --Tempest Island
	[14]  = {sets={ 46, 72,310}}, --Blessed Crucible
	[15]  = {sets={157,308,309}}, --Blackheart Haven
	[16]  = {sets={ 19, 71,123}}, --Selene's Web
	[17]  = {sets={ 91,124,311}}, --Vaults of Madness
	[288] = {sets={184,185,198}}, --White-Gold Tower
	[289] = {sets={190,195,196}}, --Imperial City Prison
	[293] = {sets={258,259,260}}, --Ruins of Mazzatun
	[295] = {sets={261,262,263}}, --Cradle of Shadows
	[324] = {sets={338,339,340}}, --Bloodroot Forge
	[368] = {sets={335,336,337}}, --Falkreath Hold
	[420] = {sets={343,344,345}}, --Fang Lair
	[418] = {sets={346,347,348}}, --Scalecaller Peak
	[428] = {sets={399,400,401}}, --March of Sacrifices
	[426] = {sets={402,403,404}}, --Moon Hunter Keep
	[433] = {sets={429,430,431}}, --Frostvault
	[435] = {sets={433,434,435}}, --Depths of Malatar
	[496] = {sets={455,456,457}}, --Lair of Maarselok
	[494] = {sets={452,453,454}}, --Moongrave Fane
	[503] = {sets={471,472,473}}, --Icereach
	[505] = {sets={474,475,476}}, --Unhallowed Grave
	[507] = {sets={516,517,518}}, --Stone Garden
	[509] = {sets={513,514,515}}, --Castle Thorn
	[591] = {sets={569,570,571}}, --Black Drake Villa
	[593] = {sets={572,573,574}}, --Cauldron
	[595] = {sets={606,607,605}}, --Red Petal Bastion
	[597] = {sets={602,603,604}}, --The Dread Cellar
	[599] = {sets={621,619,620}}, --Korallenhort
	[601] = {sets={624,622,623}}, --Gram des Schiffsbauers
	[608] = {sets={660,661,662}}, --Erdwurz-Enklave
	[610] = {sets={663,664,665}}, --Kentertiefen
}
local DungeonQuest={ --QuestId
	[2]   = 3993, --FungalGrottoI
	[3]   = 4054, --SpindleclutchI
	[4]   = 4107, --BanishedCellsI
	[5]   = 4145, --DarkshadeCavernsI
	[6]   = 4246, --WayrestSewersI
	[7]   = 4336, --EldenHollowI
	[8]   = 4202, --ArxCorinium
	[9]   = 4379, --CryptOfHeartsI
	[10]  = 4778, --CityOfAshI
	[11]  = 4346, --DirefrostKeep
	[12]  = 4432, --Volenfell
	[13]  = 4538, --TempestIsland
	[14]  = 4469, --BlessedCrucible
	[15]  = 4589, --BlackheartHaven
	[16]  = 4733, --SelenesWeb
	[17]  = 4822, --VaultsOfMadness
	[18]  = 4303, --FungalGrottoII
	[22]  = 4813, --WayrestSewersII
	[293] = 5403, --RuinsOfMazzatun
	[295] = 5702, --CradleOfShadows
	[288] = 5342, --WhiteGoldTower
	[289] = 5136, --ImperialCityPrison
	[300] = 4597, --BanishedCellsII
	[303] = 4675, --EldenHollowII
	[308] = 4641, --DarkshadeCavernsII
	[316] = 4555, --SpindleclutchII
	[317] = 5113, --CryptOfHeartsII
	[322] = 5120, --CityOfAshII
	[324] = 5889, --BloodrootForge
	[368] = 5891, --FalkreathHold
	[418] = 6065, --ScalecallerPeak
	[420] = 6064, --FangLair
	[426] = 6186, --MoonHunterKeep
	[428] = 6188, --MarchOfSacrifices
	[433] = 6249, --Frostvault
	[435] = 6251, --DepthsOfMalatar
	[494] = 6349, --MoongraveFane
	[496] = 6351, --LairOfMaarselok
	[503] = 6414, --Icereach
	[505] = 6416, --UnhallowedGrave
	[507] = 6505, --StoneGarden
	[509] = 6507, --CastleThorn
	[591] = 6576, --BlackDrakeVilla
	[593] = 6578, --Cauldron
	[595] = 6683, --RedPetalBastion
	[597] = 6685, --DreadCellar
	[599] = 6740, --CoralAerie
	[601] = 6742, --ShipwrightsRegret
	[608] = 6835, --ErdwurzEnklave
	[610] = 6837, --Kentertiefen
}
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function ttq:GetTextColor()
	local b,c,d,e=self.normalColor:UnpackRGBA()
	if self.selected then return b,c,d,0.4 elseif self.mouseover then return b,c,d,0.7 end;
	return b,c,d,e 
end;
----------------------------------------------------------------------------------------------------
function ttq.checkCompletedSets()
	for i, v in pairs(DungeonSets) do
		local numSetsDone = 0
		for j = 1, #v.sets do
			local itemSetCollectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(v.sets[j])
			local numUnlockedPieces, numPieces = itemSetCollectionData:GetNumUnlockedPieces(), itemSetCollectionData:GetNumPieces()
			if numUnlockedPieces == numPieces then numSetsDone = numSetsDone + 1 end
		end
		if numSetsDone == #v.sets then DungeonSets[i] = nil end
	end
	local next = next 
	if next(DungeonSets) == nil then ttq.complSets = true end
	--d("checkCompletedSets:complSets = "..tostring(ttq.complSets))
end
----------------------------------------------------------------------------------------------------
function ttq.checkCompletedQuests()
	for i, v in pairs(DungeonQuest) do
		if GetCompletedQuestInfo(v) ~= "" then DungeonQuest[i] = nil end
	end
	local next = next 
	if next(DungeonQuest) == nil then ttq.complQust = true end
	--d("checkCompletedQuests:complQust = "..tostring(ttq.complQust))
end
----------------------------------------------------------------------------------------------------
function ttq.markAndQueueNormalInis(DungeonTable)
	if IsUnitGrouped("player") and not IsUnitGroupLeader("player") then return end
	--init locs
	ZO_ACTIVITY_FINDER_ROOT_MANAGER:ClearAndUpdate()
	--select missing
	local parent = _G["ZO_DungeonFinder_KeyboardListSectionScrollChildContainer2"] --2=normal
	if parent then
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
		--start Queue
		if ttq.svChar.autoqueue and not ZO_DungeonFinder_KeyboardListSectionScrollChildZO_ActivityFinderTemplateNavigationHeader_Keyboard1:IsHidden() then
			ZO_ActivityFinderTemplateQueueButtonKeyboard_OnClicked(ZO_DungeonFinder_KeyboardQueueButton)
		end
	end
end
----------------------------------------------------------------------------------------------------
function ttq.markAndQueueNormalInisSets() ttq.markAndQueueNormalInis(DungeonSets) end
function ttq.markAndQueueNormalInisQust() ttq.markAndQueueNormalInis(DungeonQuest) end
----------------------------------------------------------------------------------------------------
function ttq.createQueueButton()
	local button = WINDOW_MANAGER:CreateControlFromVirtual("TIM99_SearchingForMissingSetsQueueButton", ZO_SearchingForGroup, "ZO_DefaultButton")
	button:SetDimensions(206, 28)
	button:SetAnchor(BOTTOM, ZO_SearchingForGroupStatus, TOP, 0, -45) --dont overlay BUI_AutoQueue
	button:SetFont("ZoFontGameBold")
	button:SetText(string.format("|u1:17::|u%s   Missing Sets", zo_iconFormat("/esoui/art/icons/collectible_memento_pumpkincarving.dds",26,31)))
	button:SetClickSound("Click")
	button:SetVerticalAlignment(TEXT_ALIGN_CENTER)
	button:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
	button:SetHidden(true)
	button:SetHandler("OnClicked", ttq.markAndQueueNormalInisSets)
	
	local button = WINDOW_MANAGER:CreateControlFromVirtual("TIM99_SearchingForMissingQuestQueueButton", ZO_SearchingForGroup, "ZO_DefaultButton")
	button:SetDimensions(206, 28)
	button:SetAnchor(BOTTOM, ZO_SearchingForGroupStatus, TOP, 0, -88)
	button:SetFont("ZoFontGameBold")
	button:SetText(string.format("|u1:17::|u%s   Missing Quests", zo_iconFormat("/esoui/art/icons/collectible_memento_pumpkincarving.dds",26,31)))
	button:SetClickSound("Click")
	button:SetVerticalAlignment(TEXT_ALIGN_CENTER)
	button:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
	button:SetHidden(true)
	button:SetHandler("OnClicked", ttq.markAndQueueNormalInisQust)
end
----------------------------------------------------------------------------------------------------
local function sceneChange(oldState, newState)
    if newState ~= SCENE_SHOWN then
		if TIM99_SearchingForMissingSetsQueueButton then TIM99_SearchingForMissingSetsQueueButton:SetHidden(true) end
		if TIM99_SearchingForMissingQuestQueueButton then TIM99_SearchingForMissingQuestQueueButton:SetHidden(true) end
    end
end
----------------------------------------------------------------------------------------------------
local function fragmentChange(oldState, newState)
	if newState == SCENE_FRAGMENT_SHOWN then
		if TIM99_SearchingForMissingSetsQueueButton then TIM99_SearchingForMissingSetsQueueButton:SetHidden(true) end
		if TIM99_SearchingForMissingQuestQueueButton then TIM99_SearchingForMissingQuestQueueButton:SetHidden(true) end
	end
end
----------------------------------------------------------------------------------------------------
function ttq.playerActivated()
	--just once at login
	--if ttq.firstCall==true then
	--	ttq.firstCall=false

		EVENT_MANAGER:UnregisterForEvent(ttq.name, EVENT_PLAYER_ACTIVATED)
		EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_ITEM_SET_COLLECTION_UPDATED, function() ttq.checkCompletedSets() end)
		EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_ITEM_SET_COLLECTIONS_UPDATED, function() ttq.checkCompletedSets() end)
		EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_ITEM_SET_COLLECTION_SLOT_NEW_STATUS_CLEARED, function() ttq.checkCompletedSets() end)
		--EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_QUEST_COMPLETE_DIALOG, function() ttq.checkCompletedQuests() end)
		EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_SKILL_POINTS_CHANGED, function() ttq.checkCompletedQuests() end)
		
		SCENE_MANAGER:GetScene("groupMenuKeyboard"):RegisterCallback("StateChange", sceneChange)
		
		GROUP_LIST_FRAGMENT:RegisterCallback("StateChange", fragmentChange)
		TIMED_ACTIVITIES_FRAGMENT:RegisterCallback("StateChange", fragmentChange)
		ZONE_STORIES_FRAGMENT:RegisterCallback("StateChange", fragmentChange)
		
		ttq.createQueueButton()
		ttq.checkCompletedSets()
		ttq.checkCompletedQuests()
		
		ZO_PostHook(DUNGEON_FINDER_KEYBOARD.navigationTree.templateInfo.ZO_ActivityFinderTemplateNavigationEntry_Keyboard, "setupFunction", function(node, control, data, open, userRequested, enabled)
			local n = data.isSelected and ttq.col_tim99 or ZO_NORMAL_TEXT;
			ZO_SelectableLabel_SetNormalColor(control.text, n)
			if control.text.GetTextColor~=ttq.GetTextColor then control.text.GetTextColor=ttq.GetTextColor end;
			control.text:RefreshTextColor()
		end)
		
		--to avoid overlapping with tim99sColoredLists
		--ZO_PostHook("ZO_ActivityFinderTemplateNavigationEntryKeyboard_OnClicked", function(control, button)
		--	ZO_SelectableLabel_SetNormalColor(control.text, control.node.data.isSelected and ttq.col_tim99 or ZO_NORMAL_TEXT)
		--	control.text:RefreshTextColor()
		--end)

		ZO_PostHook(ZO_ActivityFinderTemplate_Keyboard, "OnFilterChanged", function(comboBox, entryText, entry)
			if DUNGEON_FINDER_KEYBOARD.filterComboBox.m_selectedItemData and not DUNGEON_FINDER_KEYBOARD.filterComboBox.m_selectedItemData.data.singular then
				TIM99_SearchingForMissingSetsQueueButton:SetHidden(false)
				TIM99_SearchingForMissingQuestQueueButton:SetHidden(false)
			else
				TIM99_SearchingForMissingSetsQueueButton:SetHidden(true)
				TIM99_SearchingForMissingQuestQueueButton:SetHidden(true)
			end
		end)
		
		ZO_PostHook(ZO_ActivityFinderTemplate_Keyboard, "RefreshJoinQueueButton", function()
			if ZO_DungeonFinder_KeyboardListSectionScrollChildZO_ActivityFinderTemplateNavigationHeader_Keyboard1 and not ZO_DungeonFinder_KeyboardListSectionScrollChildZO_ActivityFinderTemplateNavigationHeader_Keyboard1:IsHidden() then
				TIM99_SearchingForMissingSetsQueueButton:SetHidden(false)
				TIM99_SearchingForMissingQuestQueueButton:SetHidden(false)
				TIM99_SearchingForMissingSetsQueueButton:SetEnabled(not ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetIsCurrentlyInQueue() and ttq.complSets==false)
				TIM99_SearchingForMissingQuestQueueButton:SetEnabled(not ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetIsCurrentlyInQueue() and ttq.complQust==false)
			else
				TIM99_SearchingForMissingSetsQueueButton:SetHidden(true)
				TIM99_SearchingForMissingQuestQueueButton:SetHidden(true)
			end
		end)
	--end

	--each loading screen
	--ttq.checkCompletedSets()
	
end
----------------------------------------------------------------------------------------------------
function ttq.addonLoaded(event, addonName)
	if addonName ~= ttq.name then return end
	EVENT_MANAGER:UnregisterForEvent(ttq.name, EVENT_ADD_ON_LOADED)
	EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_PLAYER_ACTIVATED, ttq.playerActivated)

	ttq.svChar = ZO_SavedVars:NewAccountWide("DungeonQueue4Stickerbook", 1, nil, ttq.svCharDef, GetWorldName())
	
	SLASH_COMMANDS['/tq']=function(a)
		if a==nil or a==""or a==" "then 
			CHAT_SYSTEM:AddMessage(string.format('|c666666[%s]|r |c9B30FF[TimSetQueue]  Usage-Help:|r',GetTimeString()))
			CHAT_SYSTEM:AddMessage(string.format('|c9B30FF  1)|r   |cFFFFFF/tq miss|r |c666666= Prints all missing Dungeons|r'))
			CHAT_SYSTEM:AddMessage(string.format('|c9B30FF  2)|r   |cFFFFFF/tq all|r |c666666= Prints all Dungeons|r'))
			CHAT_SYSTEM:AddMessage(string.format('|c9B30FF  3)|r   |cFFFFFF/tq auto|r |c666666= Toggle auto-queue after marking. now:|r |c9B30FF%s|r',tostring(ttq.svChar.autoqueue)))
			CHAT_SYSTEM:AddMessage(string.format('|c9B30FF  4)|r   |cFFFFFF/tq check|r |c666666= Recalculates the missing sets|r'))
			CHAT_SYSTEM:AddMessage(string.format('|c9B30FF  5)|r   |cFFFFFF/tq|r itemLINK |c666666= if|r |cFFFFFFitemLink|r |c666666is a from a valid set, it prints the setId|r'))
		elseif a=="miss"then CHAT_SYSTEM:AddMessage(string.format('|c666666[%s]|r |c9B30FF[TimSetQueue]  Missing Sets from:|r',GetTimeString()))local b=0;for c,d in pairs(DungeonSets)do b=b+1;CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  %s)|r   %s",b,GetActivityName(c)))end 
		elseif a=="all"then CHAT_SYSTEM:AddMessage(string.format('|c666666[%s]|r |c9B30FF[TimSetQueue]  All Dungeons:|r (%s)',GetTimeString(),GetNumActivitiesByType(LFG_ACTIVITY_DUNGEON)))local b=0;for c=1,GetNumActivitiesByType(2)do b=b+1;local d=GetActivityIdByTypeAndIndex(2,c)CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  %s)|r   %03d - %s",b,d,GetActivityName(d)))end 
		elseif a=="auto"then ttq.svChar.autoqueue=not ttq.svChar.autoqueue;CHAT_SYSTEM:AddMessage(string.format('|c666666[%s]|r |c9B30FF[TimSetQueue]  Auto-Queueing is now set to:|r |cFFFFFF%s|r',GetTimeString(),tostring(ttq.svChar.autoqueue)))
		elseif a=="check" then ttq.checkCompletedSets();CHAT_SYSTEM:AddMessage(string.format('|c666666[%s]|r |c9B30FF[TimSetQueue]  Set recalculation done.|r',GetTimeString()))
		elseif a=="quest" then ttq.checkCompletedQuests();CHAT_SYSTEM:AddMessage(string.format('|c666666[%s]|r |c9B30FF[TimSetQueue]  Quest recalculation done.|r',GetTimeString()))
		else local e,f,f,f,f,g=GetItemLinkSetInfo(a,false)if e==true then CHAT_SYSTEM:AddMessage(string.format('|c666666[%s]|r |c9B30FF[TimSetQueue]|r  |cFFFFFFSetId=%s  (%s)|r',GetTimeString(),tostring(g),tostring(a)))else CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]|r  WTF is  |cFFFFFF%s|r ???",GetTimeString(),tostring(a)))end 
		end
	end
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_ADD_ON_LOADED, ttq.addonLoaded)
