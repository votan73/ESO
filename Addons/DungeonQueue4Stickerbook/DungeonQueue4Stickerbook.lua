DungeonQueue4Stickerbook = DungeonQueue4Stickerbook or {}
local ttq = DungeonQueue4Stickerbook
ttq = {
	name = "DungeonQueue4Stickerbook",
	author = "tim99 & votan",
	svChar = {},
	firstCall = true,
	complSets = false,
	complQust = false,
	col_tim99 = ZO_ColorDef:New("9b30ff")
}
ttq.svCharDef = {
	autoqueue = true
}
--todo: merge tables
local DungeonSets = {
	--ActivityId -> SetId
	[2] = {sets = {33, 61, 297}}, --Fungal Grotto 1
	[3] = {sets = {35, 55, 296}}, --Spindleclutch 1
	[4] = {sets = {110, 197, 295}}, --Banished Cells 1
	[5] = {sets = {96, 300, 301}}, --Darkshade Caverns 1
	[6] = {sets = {29, 194, 299}}, --Wayrest Sewers 1
	[7] = {sets = {28, 155, 298}}, --Elden Hollow 1
	[8] = {sets = {156, 303, 304}}, --Arx Corinium
	[9] = {sets = {122, 134, 302}}, --Crypt of Hearts 1
	[10] = {sets = {158, 159, 160}}, --City of Ash 1
	[11] = {sets = {53, 103, 307}}, --Direfrost Keep
	[12] = {sets = {77, 102, 305}}, --Volenfell
	[13] = {sets = {186, 188, 193}}, --Tempest Island
	[14] = {sets = {46, 72, 310}}, --Blessed Crucible
	[15] = {sets = {157, 308, 309}}, --Blackheart Haven
	[16] = {sets = {19, 71, 123}}, --Selene's Web
	[17] = {sets = {91, 124, 311}}, --Vaults of Madness
	[288] = {sets = {184, 185, 198}}, --White-Gold Tower
	[289] = {sets = {190, 195, 196}}, --Imperial City Prison
	[293] = {sets = {258, 259, 260}}, --Ruins of Mazzatun
	[295] = {sets = {261, 262, 263}}, --Cradle of Shadows
	[324] = {sets = {338, 339, 340}}, --Bloodroot Forge
	[368] = {sets = {335, 336, 337}}, --Falkreath Hold
	[420] = {sets = {343, 344, 345}}, --Fang Lair
	[418] = {sets = {346, 347, 348}}, --Scalecaller Peak
	[428] = {sets = {399, 400, 401}}, --March of Sacrifices
	[426] = {sets = {402, 403, 404}}, --Moon Hunter Keep
	[433] = {sets = {429, 430, 431}}, --Frostvault
	[435] = {sets = {433, 434, 435}}, --Depths of Malatar
	[496] = {sets = {455, 456, 457}}, --Lair of Maarselok
	[494] = {sets = {452, 453, 454}}, --Moongrave Fane
	[503] = {sets = {471, 472, 473}}, --Icereach
	[505] = {sets = {474, 475, 476}}, --Unhallowed Grave
	[507] = {sets = {516, 517, 518}}, --Stone Garden
	[509] = {sets = {513, 514, 515}}, --Castle Thorn
	[591] = {sets = {569, 570, 571}}, --Black Drake Villa
	[593] = {sets = {572, 573, 574}}, --Cauldron
	[595] = {sets = {606, 607, 605}}, --Red Petal Bastion
	[597] = {sets = {602, 603, 604}}, --The Dread Cellar
	[599] = {sets = {621, 619, 620}}, --Korallenhort
	[601] = {sets = {624, 622, 623}}, --Gram des Schiffsbauers
	[608] = {sets = {660, 661, 662}}, --Erdwurz-Enklave
	[610] = {sets = {663, 664, 665}}, --Kentertiefen
	[613] = {sets = {680, 681, 682}}, --Bal Sunnar
	[615] = {sets = {684, 685, 686}} --Halle der Schriftmeister
}
local DungeonSetsVet = {
	--ActivityId -> SetId
	[19] = {sets = {163}}, -- Spindeltiefen I
	[20] = {sets = {170}}, -- Verbannungszellen I
	[21] = {sets = {268}}, -- Dunkelschattenkavernen II
	[23] = {sets = {167}}, -- Eldengrund I
	[261] = {sets = {168}}, -- Krypta der Herzen I
	[267] = {sets = {272}}, -- Stadt der Asche II
	[268] = {sets = {164}}, -- Gefängnis der Kaiserstadt
	[287] = {sets = {183}}, -- Weißgoldturm
	[294] = {sets = {256}}, -- Ruinen von Mazzatun
	[296] = {sets = {257}}, -- Wiege der Schatten
	[299] = {sets = {162}}, -- Pilzgrotte I
	[301] = {sets = {265}}, -- Verbannungszellen II
	[302] = {sets = {269}}, -- Eldengrund II
	[304] = {sets = {276}}, -- Volenfell
	[305] = {sets = {271}}, -- Arx Corinium
	[306] = {sets = {165}}, -- Kanalisation von Wegesruh I
	[307] = {sets = {270}}, -- Kanalisation von Wegesruh II
	[309] = {sets = {166}}, -- Dunkelschattenkavernen I
	[310] = {sets = {169}}, -- Stadt der Asche I
	[311] = {sets = {275}}, -- Orkaninsel
	[312] = {sets = {266}}, -- Pilzgrotte II
	[313] = {sets = {279}}, -- Selenes Netz
	[314] = {sets = {280}}, -- Kammern des Wahnsinns
	[315] = {sets = {163}}, -- Spindeltiefen I
	[318] = {sets = {273}}, -- Krypta der Herzen II
	[319] = {sets = {274}}, -- Burg Grauenfrost
	[320] = {sets = {278}}, -- Gesegnete Feuerprobe
	[321] = {sets = {277}}, -- Schwarzherz-Unterschlupf
	[325] = {sets = {341}}, -- Blutquellschmiede
	[369] = {sets = {342}}, -- Falkenring
	[419] = {sets = {350}}, -- Gipfel der Schuppenruferin
	[421] = {sets = {349}}, -- Krallenhort
	[427] = {sets = {398}}, -- Mondjägerfeste
	[429] = {sets = {397}}, -- Marsch der Aufopferung
	[434] = {sets = {432}}, -- Frostgewölbe
	[436] = {sets = {436}}, -- Tiefen von Malatar
	[495] = {sets = {458}}, -- Mondgrab-Tempelstadt
	[497] = {sets = {459}}, -- Hort von Maarselok
	[504] = {sets = {478}}, -- Eiskap
	[506] = {sets = {479}}, -- Unheiliges Grab
	[508] = {sets = {534}}, -- Steingarten
	[510] = {sets = {535}}, -- Kastell Dorn
	[592] = {sets = {577}}, -- Schwarzdrachenvilla
	[594] = {sets = {578}}, -- Der Kessel
	[596] = {sets = {608}}, -- Rotblütenbastion
	[598] = {sets = {609}}, -- Schreckenskeller
	[600] = {sets = {632}}, -- Korallenhorst
	[602] = {sets = {633}}, -- Gram des Schiffbauers
	[609] = {sets = {666}}, -- Erdwurz-Enklave
	[611] = {sets = {667}}, -- Kentertiefen
	[614] = {sets = {683}}, -- Bal Sunnar
	[616] = {sets = {687}} -- Halle der Schriftmeister
}
local DungeonQuest = {
	-- ActivityId -> QuestId
	[2] = 3993, --FungalGrottoI
	[3] = 4054, --SpindleclutchI
	[4] = 4107, --BanishedCellsI
	[5] = 4145, --DarkshadeCavernsI
	[6] = 4246, --WayrestSewersI
	[7] = 4336, --EldenHollowI
	[8] = 4202, --ArxCorinium
	[9] = 4379, --CryptOfHeartsI
	[10] = 4778, --CityOfAshI
	[11] = 4346, --DirefrostKeep
	[12] = 4432, --Volenfell
	[13] = 4538, --TempestIsland
	[14] = 4469, --BlessedCrucible
	[15] = 4589, --BlackheartHaven
	[16] = 4733, --SelenesWeb
	[17] = 4822, --VaultsOfMadness
	[18] = 4303, --FungalGrottoII
	[22] = 4813, --WayrestSewersII
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
	[610] = 6837 --Kentertiefen
}
local UndauntedPledges = {
	[5244] = {n = 4, v = 20}, -- Verbannungszellen I
	[5246] = {n = 300, v = 301}, -- Verbannungszellen II
	[5247] = {n = 2, v = 299}, -- Pilzgrotte I
	[5248] = {n = 18, v = 312}, -- Pilzgrotte II
	[5260] = {n = 3, v = 315}, -- Spindeltiefen I
	[5273] = {n = 316, v = 19}, -- Spindeltiefen II
	[5274] = {n = 5, v = 309}, -- Dunkelschattenkavernen I
	[5275] = {n = 308, v = 21}, -- Dunkelschattenkavernen II
	[5276] = {n = 7, v = 23}, -- Eldengrund I
	[5277] = {n = 303, v = 302}, -- Eldengrund II
	[5278] = {n = 6, v = 306}, -- Kanalisation von Wegesruh I
	[5282] = {n = 22, v = 307}, -- Kanalisation von Wegesruh II
	[5283] = {n = 9, v = 261}, -- Krypta der Herzen I
	[5284] = {n = 317, v = 318}, -- Krypta der Herzen II
	[5288] = {n = 8, v = 305}, -- Arx Corinium
	[5290] = {n = 10, v = 310}, -- Stadt der Asche I
	[5291] = {n = 11, v = 319}, -- Burg Grauenfrost
	[5301] = {n = 13, v = 311}, -- Orkaninsel
	[5303] = {n = 12, v = 304}, -- Volenfell
	[5305] = {n = 15, v = 321}, -- Schwarzherz-Unterschlupf
	[5306] = {n = 14, v = 320}, -- Gesegnete Feuerprobe
	[5307] = {n = 16, v = 313}, -- Selenes Netz
	[5309] = {n = 17, v = 314}, -- Kammern des Wahnsinns
	[5381] = {n = 322, v = 267} -- Stadt der Asche II
}
local UndauntedDLCPledges = {
	[5382] = {n = 289, v = 268}, -- Gefängnis der Kaiserstadt
	[5431] = {n = 288, v = 287}, -- Weißgoldturm
	[5636] = {n = 293, v = 294}, -- Ruinen von Mazzatun
	[5780] = {n = 295, v = 296}, -- Wiege der Schatten
	[6053] = {n = 324, v = 325}, -- Blutquellschmiede
	[6054] = {n = 368, v = 369}, -- Falkenring
	[6154] = {n = 418, v = 419}, -- Gipfel der Schuppenruferin
	[6155] = {n = 420, v = 421}, -- Krallenhort
	[6187] = {n = 426, v = 427}, -- Mondjägerfeste
	[6189] = {n = 428, v = 429}, -- Marsch der Aufopferung
	[6250] = {n = 433, v = 434}, -- Frostgewölbe
	[6252] = {n = 435, v = 436}, -- Tiefen von Malatar
	[6350] = {n = 494, v = 495}, -- Mondgrab-Tempelstadt
	[6352] = {n = 496, v = 497}, -- Hort von Maarselok
	[6415] = {n = 503, v = 504}, -- Eiskap
	[6417] = {n = 505, v = 506}, -- Unheiliges Grab
	[6506] = {n = 507, v = 508}, -- Steingarten
	[6508] = {n = 509, v = 510}, -- Kastell Dorn
	[6577] = {n = 591, v = 592}, -- Schwarzdrachenvilla
	[6579] = {n = 593, v = 594}, -- Kessel
	[6684] = {n = 595, v = 596}, -- Rotblütenbastion
	[6686] = {n = 597, v = 598}, -- Schreckenskeller
	[6741] = {n = 599, v = 600}, -- Korallenhorst
	[6743] = {n = 601, v = 602}, -- Gram des Schiffbauers
	[6836] = {n = 608, v = 609}, -- Erdwurz-Enklave
	[6838] = {n = 610, v = 611}, -- Kentertiefen
	[6897] = {n = 613, v = 614}, -- Bal Sunnar
	[7028] = {n = 615, v = 616} -- Halle der Schriftmeister
}
----------------------------------------------------------------------------------------------------
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
		local numSetsDone = 0
		for j = 1, #v.sets do
			local itemSetCollectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(v.sets[j])
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
		if numSetsDone == #v.sets then
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
		if GetCompletedQuestInfo(v) ~= "" then
			DungeonQuest[i] = nil
		end
	end
	local next = next
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
function ttq.markAndQueueNormalInisQust()
	ttq.markAndQueueNormalInis(DungeonQuest)
end
function ttq.markAndQueueVetInisQust()
	ttq.markAndQueueVetInis(DungeonSetsVet)
end
----------------------------------------------------------------------------------------------------
function ttq.createQueueButton()
	local icon = zo_iconFormat("/esoui/art/icons/collectible_memento_pumpkincarving.dds", 26, 31)

	local dropdown = CreateControlFromVirtual("TIM99_SearchingForMissing", ZO_SearchingForGroup, "ZO_MultiselectComboBox")
	dropdown:SetDimensions(200, ZO_DungeonFinder_KeyboardFilter:GetHeight())
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
		local filterName = string.format("%s   Missing Sets", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = ttq.markAndQueueNormalInisSets
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   Missing Quests", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = ttq.markAndQueueNormalInisQust
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   Missing Helmets", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = ttq.markAndQueueVetInisQust
		comboBox:AddItem(entry)
	end

	local function QuestsToActivity(pledges, difficulty)
		local activities = {}
		for questId, a in pairs(pledges) do
			if HasQuest(questId) then
				local findName = GetQuestName(questId)
				for i = 1, MAX_JOURNAL_QUESTS do
					if IsValidQuestIndex(i) then
						local questName, _, _, activeStepType = GetJournalQuestInfo(i)
						if activeStepType == 1 and questName == findName then
							activities[a[difficulty]] = true
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
			ttq.markAndQueueNormalInis(QuestsToActivity(UndauntedPledges, "n"))
		end
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   My Pledges Vet", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = function()
			ttq.markAndQueueVetInis(QuestsToActivity(UndauntedPledges, "v"))
		end
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   My DLC Pledges Normal", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = function()
			ttq.markAndQueueNormalInis(QuestsToActivity(UndauntedDLCPledges, "n"))
		end
		comboBox:AddItem(entry)
	end
	do
		local filterName = string.format("%s   My DLC Pledges Vet", icon)
		local entry = comboBox:CreateItemEntry(filterName, OnFiltersChanged)
		entry.filterValue = function()
			ttq.markAndQueueVetInis(QuestsToActivity(UndauntedDLCPledges, "v"))
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

	ttq.svChar = ZO_SavedVars:NewAccountWide("DungeonQueue4Stickerbook", 1, nil, ttq.svCharDef, GetWorldName())

	SLASH_COMMANDS["/tq"] = function(a)
		if a == nil or a == "" or a == " " then
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]  Usage-Help:|r", GetTimeString()))
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  1)|r   |cFFFFFF/tq miss|r |c666666= Prints all missing Dungeons|r"))
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  2)|r   |cFFFFFF/tq all|r |c666666= Prints all Dungeons|r"))
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  3)|r   |cFFFFFF/tq auto|r |c666666= Toggle auto-queue after marking. now:|r |c9B30FF%s|r", tostring(ttq.svChar.autoqueue)))
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  4)|r   |cFFFFFF/tq check|r |c666666= Recalculates the missing sets|r"))
			CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  5)|r   |cFFFFFF/tq|r itemLINK |c666666= if|r |cFFFFFFitemLink|r |c666666is a from a valid set, it prints the setId|r"))
		elseif a == "miss" then
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]  Missing Sets from:|r", GetTimeString()))
			local b = 0
			for c, d in pairs(DungeonSets) do
				b = b + 1
				CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  %s)|r   %s", b, GetActivityName(c)))
			end
		elseif a == "all" then
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]  All Dungeons:|r (%s)", GetTimeString(), GetNumActivitiesByType(LFG_ACTIVITY_DUNGEON)))
			local b = 0
			for c = 1, GetNumActivitiesByType(2) do
				b = b + 1
				local d = GetActivityIdByTypeAndIndex(2, c)
				CHAT_SYSTEM:AddMessage(string.format("|c9B30FF  %s)|r   %03d - %s", b, d, GetActivityName(d)))
			end
		elseif a == "auto" then
			ttq.svChar.autoqueue = not ttq.svChar.autoqueue
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]  Auto-Queueing is now set to:|r |cFFFFFF%s|r", GetTimeString(), tostring(ttq.svChar.autoqueue)))
		elseif a == "check" then
			ttq.checkCompletedSets()
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]  Set recalculation done.|r", GetTimeString()))
		elseif a == "quest" then
			ttq.checkCompletedQuests()
			CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]  Quest recalculation done.|r", GetTimeString()))
		else
			local e, f, f, f, f, g = GetItemLinkSetInfo(a, false)
			if e == true then
				CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]|r  |cFFFFFFSetId=%s  (%s)|r", GetTimeString(), tostring(g), tostring(a)))
			else
				CHAT_SYSTEM:AddMessage(string.format("|c666666[%s]|r |c9B30FF[TimSetQueue]|r  WTF is  |cFFFFFF%s|r ???", GetTimeString(), tostring(a)))
			end
		end
	end
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
EVENT_MANAGER:RegisterForEvent(ttq.name, EVENT_ADD_ON_LOADED, ttq.addonLoaded)

-- SLASH_COMMANDS["/test"] = function()
-- 	-- local activityToName = {}
-- 	-- local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_DUNGEON)
-- 	-- for i = 1, #locations do
-- 	-- 	local activityId = locations[i]:GetId()
-- 	-- 	activityToName[activityId] = locations[i]:GetRawName():gsub("\194\160II", ""):gsub("\194\160I", "")
-- 	-- end
-- 	-- local setIdToActivity = {}
-- 	-- for _, collectionData in ITEM_SET_COLLECTIONS_DATA_MANAGER:ItemSetCollectionIterator() do
-- 	-- 	for _, pieceData in collectionData:PieceIterator() do
-- 	-- 		local quality = pieceData:GetDisplayQuality()
-- 	-- 		if quality < 4 then
-- 	-- 			local categoryData = collectionData:GetCategoryData()
-- 	-- 			for activityId, name in pairs(activityToName) do
-- 	-- 				if name == categoryData:GetFormattedName() then
-- 	-- 					local list = setIdToActivity[activityId] or {sets = {}}
-- 	-- 					list.sets[#list.sets + 1] = collectionData:GetId()
-- 	-- 					list.name = name
-- 	-- 					setIdToActivity[activityId] = list
-- 	-- 				end
-- 	-- 			end
-- 	-- 			break
-- 	-- 		end
-- 	-- 	end
-- 	-- end
-- 	-- 	local lines = {}
-- 	-- 	for activityId, list in pairs(setIdToActivity) do
-- 	-- 		lines[#lines + 1] = string.format("[%i] = {sets={%s}}, -- %s", activityId, table.concat(list.sets,","), GetActivityName(activityId))
-- 	-- 	end
-- 	-- 	DungeonQueue4Stickerbook.normal = lines

-- 	-- 	local activityToName = {}
-- 	-- 	local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_MASTER_DUNGEON)
-- 	--     for i = 1, #locations do
-- 	--         local activityId = locations[i]:GetId()
-- 	-- 		activityToName[activityId] = locations[i]:GetRawName():gsub("\194\160II", ""):gsub("\194\160I", "")
-- 	-- 	end
-- 	-- 	local setIdToActivity = {}
-- 	-- 	for _, collectionData in ITEM_SET_COLLECTIONS_DATA_MANAGER:ItemSetCollectionIterator() do
-- 	-- 		if collectionData:GetNumPieces() == 6 then
-- 	-- 			for _, pieceData in collectionData:PieceIterator() do
-- 	-- 				local quality = pieceData:GetDisplayQuality()
-- 	-- 				if quality == 4 then
-- 	-- 					if GetItemLinkEquipType(pieceData:GetItemLink()) == EQUIP_TYPE_HEAD then
-- 	-- 						local categoryData = collectionData:GetCategoryData()
-- 	-- 						for activityId, name in pairs(activityToName) do
-- 	-- 							if name == categoryData:GetFormattedName() then
-- 	-- 								local list = setIdToActivity[activityId] or { sets={} }
-- 	-- 								list.sets[#list.sets+1] = collectionData:GetId()
-- 	-- 								list.name = name
-- 	-- 								setIdToActivity[activityId] = list
-- 	-- 							end
-- 	-- 						end
-- 	-- 						break
-- 	-- 					end
-- 	-- 				end
-- 	-- 			end
-- 	-- 		end
-- 	-- 	end
-- 	-- 	local lines = {}
-- 	-- 	for activityId, list in pairs(setIdToActivity) do
-- 	-- 		lines[#lines + 1] = string.format("[%i] = {sets={%s}}, -- %s", activityId, table.concat(list.sets,","), GetActivityName(activityId))
-- 	-- 	end
-- 	-- 	DungeonQueue4Stickerbook.vet = lines

-- 	local activityToName = {}
-- 	local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_DUNGEON)
-- 	for i = 1, #locations do
-- 		local activityId = locations[i]:GetId()
-- 		local name = locations[i]:GetRawName():gsub("Der ", "")
-- 		local list = activityToName[name] or {}
-- 		list[#list + 1] = activityId
-- 		activityToName[name] = list
-- 	end
-- 	local locations = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(LFG_ACTIVITY_MASTER_DUNGEON)
-- 	for i = 1, #locations do
-- 		local activityId = locations[i]:GetId()
-- 		local name = locations[i]:GetRawName():gsub("Der ", "")
-- 		local list = activityToName[name] or {}
-- 		list[#list + 1] = activityId
-- 		activityToName[name] = list
-- 	end

-- 	local lines = {}
-- 	local questId = nil
-- 	while true do
-- 		questId = GetNextCompletedQuestId(questId)
-- 		if questId then
-- 			local name, questType = GetCompletedQuestInfo(questId)
-- 			if questType == QUEST_TYPE_UNDAUNTED_PLEDGE then
-- 				name = name:gsub("Der ", "")
-- 				local list = activityToName[name]
-- 				if list then
-- 					lines[#lines + 1] = string.format("[%i] = {n=%i,v=%i}, -- %s", questId, list[1] or 0, list[2] or 0, name)
-- 				else
-- 					lines[#lines + 1] = string.format("[%i] = {n=%i,v=%i}, -- %s", questId, 0, 0, name)
-- 				end
-- 			end
-- 		else
-- 			break
-- 		end
-- 	end
-- 	DungeonQueue4Stickerbook.pledges = lines
-- end
