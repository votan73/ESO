local QUEST_LINK_TYPE = "HarvensQuestJournalQuest"
local QUEST_CATEGORY_LINK_TYPE = "HarvensQuestJournalCategory"
local NPC_LINK_TYPE = "HarvensQuestJournalNPC"

local tableInsert = table.insert
local tableConcat = table.concat
local tableSort = table.sort
local mathFloor = math.floor

local zo_strformat = zo_strformat
local zo_strjoin = zo_strjoin

local GetTrackedIsAssisted = GetTrackedIsAssisted

local QUEST_CATEGORY_MAIN_STORY = 1
local QUEST_CATEGORY_GUILD = 2
local QUEST_CATEGORY_ZONE = 3
local QUEST_CATEGORY_MISC = 4

--SavedVariable quest structure
local QS_NAME = 1
local QS_LEVEL = 2
local QS_BACKGROUND = 3
local QS_STARTTIME = 4
local QS_BESTOWER = 5
local QS_TYPE = 7
local QS_ZONE = 8
local QS_STEPS = 9
local QS_TERMINATOR = 10
local QS_REWARD = 11
local QS_COMPLETEDTIME = 12
local QS_REPEAT = 13

--QS_BESTOWER and QS_TERMINATOR
local QS_NPCPOSX = 1
local QS_NPCPOSY = 2
local QS_NPCLOCATION = 3
local QS_NPCCONVERSATION = 4
local QS_NPCNAME = 5
local QS_NPCZONE = 6
local QS_NPCDIALOG = 7

--QS_NPCCONVERSATION
local QS_ME = 1
local QS_THEM = 2

--QS_STEPS
local QS_TEXT = 1
local QS_TIME = 2

--QS_REWARD
local QS_ITEMS = 1
local QS_GOLD = 2
local QS_EXPERIENCE = 3
local QS_CHAMPION_POINTS = 4

local DEFAULT_PAGE_HEIGHT = 660

--journal sections
local JS_CURRENT = 1
local JS_COMPLETED = 2
local JS_CURRENT_QUEST = 3
local JS_COMPLETED_QUEST = 4
local JS_CONVERSATION = 5
local JS_COMPLETED_QUEST_CATEGORY = 6

local SORT_ALPHABETICALLY = 0
local SORT_TIMEOFCOMPLETION = 1
local SORT_TIMEOFSTART = 2
local SORT_LEVEL = 3

local HarvensQuestJournal = {}

local categoryIdToName = {
	[QUEST_CATEGORY_MAIN_STORY] = zo_strformat("<<1>>", GetString("SI_QUESTTYPE", QUEST_TYPE_MAIN_STORY)),
	[QUEST_CATEGORY_GUILD] = zo_strformat("<<1>>", GetString("SI_QUESTTYPE", QUEST_TYPE_GUILD)),
	[QUEST_CATEGORY_MISC] = zo_strformat("<<1>>", GetString(SI_QUEST_JOURNAL_GENERAL_CATEGORY)),
	[QUEST_CATEGORY_ZONE] = SI_QUEST_JOURNAL_ZONE_FORMAT
}

local function GetTimeZoneOffset()
	local ssm = GetSecondsSinceMidnight()
	local now = GetTimeStamp()
	local diff = ssm - (now % (60 * 60 * 24))
	return diff
end

local function CreateLink(text, color, type, ...)
	return ("|c%s|H0:%s|h%s|h|r"):format(color:ToHex(), zo_strjoin(":", type, ...), text)
end

local CLOCK_FORMAT = (GetCVar("Language.2") == "en") and TIME_FORMAT_PRECISION_TWELVE_HOUR or TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR
function HarvensQuestJournal:ShowQuest()
	local quest = self:GetQuestSavedVariable(self.currentQuestType, self.currentQuestZone, self.currentQuest, (self.currentSection == JS_COMPLETED_QUEST and true or false))
	if not quest then
		return
	end

	self.title:SetText(zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, quest[QS_NAME]))

	local text = {}
	text[#text + 1] = GetDateStringFromTimestamp(quest[QS_STARTTIME])
	text[#text + 1] = " "
	text[#text + 1] = FormatTimeSeconds(quest[QS_STARTTIME] + GetTimeZoneOffset(), TIME_FORMAT_STYLE_CLOCK_TIME, CLOCK_FORMAT, TIME_FORMAT_DIRECTION_NONE)
	if quest[QS_BESTOWER] then
		text[#text + 1] = " "
		text[#text + 1] = zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, quest[QS_BESTOWER][QS_NPCLOCATION])
		if quest[QS_BESTOWER][QS_NPCLOCATION] ~= quest[QS_BESTOWER][QS_NPCZONE] then
			text[#text + 1] = ", "
			text[#text + 1] = zo_strformat(SI_COMPASS_LOCATION_NAME_FORMAT, quest[QS_BESTOWER][QS_NPCZONE])
		end
		text[#text + 1] = zo_strformat(GetString(HARVEN_QUEST_JOURNAL_DONE_BY_NAME), CreateLink(quest[QS_BESTOWER][QS_NPCNAME], self.npcColor, NPC_LINK_TYPE, (self.currentSection == JS_COMPLETED_QUEST and 1 or 0), self.currentQuestType, self.currentQuest, self.currentQuestZone))
	end
	text[#text + 1] = "\n("
	text[#text + 1] = zo_strformat(SI_QUEST_JOURNAL_QUEST_LEVEL, quest[QS_LEVEL])
	text[#text + 1] = ")\n\n"
	text[#text + 1] = quest[QS_BACKGROUND]
	for i = 1, #quest[QS_STEPS] do
		text[#text + 1] = "\n\n"
		if quest[QS_STEPS][i][QS_TIME] then
			text[#text + 1] = GetDateStringFromTimestamp(quest[QS_STEPS][i][QS_TIME])
			text[#text + 1] = " "
			text[#text + 1] = FormatTimeSeconds(quest[QS_STEPS][i][QS_TIME] + GetTimeZoneOffset(), TIME_FORMAT_STYLE_CLOCK_TIME, CLOCK_FORMAT, TIME_FORMAT_DIRECTION_NONE)
			text[#text + 1] = "\n"
		end
		text[#text + 1] = quest[QS_STEPS][i][QS_TEXT]
	end
	if self.currentSection == JS_COMPLETED_QUEST then
		text[#text + 1] = "\n\n"
		text[#text + 1] = zo_strformat(GetString(HARVEN_QUEST_JOURNAL_COMPLETED_AT_TIME), GetDateStringFromTimestamp(quest[QS_COMPLETEDTIME]), FormatTimeSeconds(quest[QS_COMPLETEDTIME] + GetTimeZoneOffset(), TIME_FORMAT_STYLE_CLOCK_TIME, CLOCK_FORMAT, TIME_FORMAT_DIRECTION_NONE))
		if quest[QS_TERMINATOR] then
			text[#text + 1] = " "
			local location, zone = zo_strformat(SI_WORLD_MAP_LOCATION_NAME, quest[QS_TERMINATOR][QS_NPCLOCATION]), zo_strformat(SI_WORLD_MAP_LOCATION_NAME, quest[QS_TERMINATOR][QS_NPCZONE])
			text[#text + 1] = zo_strformat(HARVEN_QUEST_JOURNAL_COMPLETED_AT_LOCATION, quest[QS_TERMINATOR][QS_NPCLOCATION])
			if location ~= zone then
				text[#text + 1] = ", "
				text[#text + 1] = zone
			end
			text[#text + 1] = zo_strformat(GetString(HARVEN_QUEST_JOURNAL_DONE_BY_NAME), CreateLink(quest[QS_TERMINATOR][QS_NPCNAME], self.npcColor, NPC_LINK_TYPE, (self.currentSection == JS_COMPLETED_QUEST and 1 or 0), self.currentQuestType, self.currentQuest, self.currentQuestZone))
		end
		text[#text + 1] = GetString(HARVEN_QUEST_JOURNAL_SENTENCE_END)
		if quest[QS_REWARD] then
			text[#text + 1] = "\n\n"
			text[#text + 1] = GetString(SI_TIMED_ACTIVITIES_REWARD_HEADER)
			text[#text + 1] = ":"
			if quest[QS_REWARD][QS_EXPERIENCE] then
				text[#text + 1] = "\n- "
				text[#text + 1] = zo_strformat(HARVEN_QUEST_JOURNAL_REWARD_XP, quest[QS_REWARD][QS_EXPERIENCE])
			end
			if quest[QS_REWARD][QS_CHAMPION_POINTS] then
				text[#text + 1] = "\n- "
				text[#text + 1] = zo_strformat(HARVEN_QUEST_JOURNAL_REWARD_CP, quest[QS_REWARD][QS_CHAMPION_POINTS])
			end
			if quest[QS_REWARD][QS_ITEMS] then
				for i = 1, #quest[QS_REWARD][QS_ITEMS] do
					text[#text + 1] = "\n- "
					text[#text + 1] = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(quest[QS_REWARD][QS_ITEMS][i]))
				end
			end
			if quest[QS_REWARD][QS_GOLD] then
				text[#text + 1] = "\n- "
				text[#text + 1] = zo_strformat(HARVEN_QUEST_JOURNAL_REWARD_GOLD, quest[QS_REWARD][QS_GOLD])
			end
		end
	end
	self:ShowText(tableConcat(text))
end

function HarvensQuestJournal:ShowConversation()
	local quest = self:GetQuestSavedVariable(self.currentQuestType, self.currentQuestZone, self.currentQuest, self.currentQuestCompleted)
	if not quest then
		return
	end

	self.title:SetText(self.currentQuestNPC)

	local text = {}

	if quest[QS_BESTOWER] and self.currentQuestNPC == quest[QS_BESTOWER][QS_NPCNAME] then
		for i = 1, #quest[QS_BESTOWER][QS_NPCCONVERSATION][QS_THEM] do
			text[#text + 1] = "- "
			text[#text + 1] = quest[QS_BESTOWER][QS_NPCCONVERSATION][QS_THEM][i]
			text[#text + 1] = "\n\n"
			text[#text + 1] = "- "
			text[#text + 1] = quest[QS_BESTOWER][QS_NPCCONVERSATION][QS_ME][i]
			text[#text + 1] = "\n\n"
		end
	end

	if self.currentQuestCompleted and quest[QS_TERMINATOR] and self.currentQuestNPC == quest[QS_TERMINATOR][QS_NPCNAME] then
		text[#text + 1] = "- "
		text[#text + 1] = quest[QS_TERMINATOR][QS_NPCDIALOG]
	end

	self:ShowText(tableConcat(text))
end

function HarvensQuestJournal:ShowText(text)
	self.leftPage.body:SetText(text)
	self.rightPage.body:SetText(text)

	self.leftPage.body:ClearAnchors()

	self.bodyFontHeight = self.leftPage.body:GetFontHeight()
	self.pageHeight = mathFloor(DEFAULT_PAGE_HEIGHT / self.bodyFontHeight) * self.bodyFontHeight

	self.leftPage:SetHeight(self.pageHeight)
	self.rightPage:SetHeight(self.pageHeight)

	local titleHeight = self.title:GetTextHeight()
	local bodyLength = self.leftPage.body:GetTextHeight()

	local bodyOffset = self.bodyFontHeight - (titleHeight % self.bodyFontHeight)

	self.leftPage.body:SetAnchor(TOP, self.title, BOTTOM, 0, bodyOffset)
	self.rightPage.offset = self.pageHeight - titleHeight - bodyOffset
	self.rightPage:SetVerticalScroll(self.rightPage.offset)
	self.numPages = zo_ceil(((titleHeight + bodyLength) / self.pageHeight) / 2)
end

local function DarkenColor(r, g, b)
	return ZO_ColorDef:New(r * 0.6, g * 0.6, b * 0.6, 0.8)
end

function HarvensQuestJournal:AppendQuest(quest, zone)
	local text
	--local color = DarkenColor(GetConColor(quest[QS_LEVEL]))
	local completed = (self.currentSection == JS_CURRENT and 0 or 1)

	name = CreateLink(zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, quest[QS_NAME]), self.questColor, QUEST_LINK_TYPE, completed, quest[QS_TYPE], zone)
	local isAssisted = false
	if completed == 0 then
		isAssisted = GetTrackedIsAssisted(TRACK_TYPE_QUEST, self.activeQuests[quest[QS_NAME]])
	end
	if isAssisted then
		text = string.format("\n  - %s |t32:32:EsoUI/Art/Quest/questJournal_trackedQuest_icon.dds|t", name)
	else
		text = string.format("\n  - %s", name)
	end
	return text
end

local function QuestComparator(quest1, quest2)
	local q1, q2
	if HarvensQuestJournal.sv.sortAscending then
		q1 = quest1
		q2 = quest2
	else
		q1 = quest2
		q2 = quest1
	end

	if HarvensQuestJournal.sv.sort == SORT_ALPHABETICALLY then
		return q1.name < q2.name
	elseif HarvensQuestJournal.sv.sort == SORT_TIMEOFCOMPLETION then
		if q1.finished == q2.finished then
			return q1.name < q2.name
		end
		return (q1.finished or 0) < (q2.finished or 0)
	elseif HarvensQuestJournal.sv.sort == SORT_TIMEOFSTART then
		if q1.started == q2.started then
			return q1.name < q2.name
		end
		return q1.started < q2.started
	elseif HarvensQuestJournal.sv.sort == SORT_LEVEL then
		if q1.level == q2.level then
			return q1.name < q2.name
		end
		return q1.level < q2.level
	end
end

function HarvensQuestJournal:CreateSortedList(svtable)
	local list = {}

	for i = 1, #categoryIdToName do
		if next(svtable[i]) then
			list[i] = {}

			for k, v in pairs(svtable[i]) do
				if i == QUEST_CATEGORY_ZONE and next(v) then
					tableInsert(list[i], {})

					for questName, quest in pairs(v) do
						tableInsert(
							list[i][#list[i]],
							{
								name = questName,
								started = quest[QS_STARTTIME],
								level = quest[QS_LEVEL],
								zone = k
							}
						)

						if self.currentSection ~= JS_CURRENT then
							list[i][#list[i]][#list[i][#list[i]]].finished = quest[QS_COMPLETEDTIME]
						else
							list[i][#list[i]][#list[i][#list[i]]].finished = quest[QS_STARTTIME]
						end
					end
					tableSort(list[i][#list[i]], QuestComparator)
				elseif i ~= QUEST_CATEGORY_ZONE then
					tableInsert(
						list[i],
						{
							name = k,
							started = v[QS_STARTTIME],
							level = v[QS_LEVEL]
						}
					)

					if self.currentSection ~= JS_CURRENT then
						list[i][#list[i]].finished = v[QS_COMPLETEDTIME]
					else
						list[i][#list[i]].finished = v[QS_STARTTIME]
					end
				end
			end

			if i ~= QUEST_CATEGORY_ZONE then
				tableSort(list[i], QuestComparator)
			end
		end
	end

	return list
end

function HarvensQuestJournal:ShowIndexPage()
	local svtable
	if self.currentSection == JS_CURRENT then
		self.title:SetText(GetString(HARVEN_QUEST_JOURNAL_CURRENT_QUESTS_TITLE))
		svtable = self.sv.quests
		if not self.sortedListCurrent then
			self.sortedListCurrent = self:CreateSortedList(svtable)
		end
	else
		self.title:SetText(GetString(HARVEN_QUEST_JOURNAL_COMPLETED_QUESTS_TITLE))
		svtable = self.sv.completed
		if not self.sortedListCompleted then
			self.sortedListCompleted = self:CreateSortedList(svtable)
		end
	end

	local sortedList = self.currentSection == JS_CURRENT and self.sortedListCurrent or self.sortedListCompleted

	local startPos = self.bodyFontHeight
	local link

	if self.currentSection == JS_COMPLETED and self.sv.showCompletedByCategory then
		local text = {}
		for i, v in pairs(sortedList) do
			if i ~= QUEST_CATEGORY_ZONE then
				text[#text + 1] = "\n"
				text[#text + 1] = categoryIdToName[i]
				self.clickMap[mathFloor(startPos)] = CreateLink(categoryIdToName[i], self.questColor, QUEST_CATEGORY_LINK_TYPE, i)
				startPos = startPos + self.bodyFontHeight --assume that category name fits in one line
			end

			for j = 1, #sortedList[i] do
				if i == QUEST_CATEGORY_ZONE then
					local zoneName = sortedList[i][j][1].zone
					text[#text + 1] = "\n"
					text[#text + 1] = zo_strformat(categoryIdToName[i], zoneName)
					self.clickMap[mathFloor(startPos)] = CreateLink(zo_strformat(categoryIdToName[i], zoneName), self.questColor, QUEST_CATEGORY_LINK_TYPE, i, j)
					startPos = startPos + self.bodyFontHeight --assume that zone name fits in one line
				end
			end
		end
		self:ShowText(tableConcat(text))
		return
	end

	local text = {}

	for i, v in pairs(sortedList) do
		if i ~= QUEST_CATEGORY_ZONE then
			text[#text + 1] = "\n"
			text[#text + 1] = categoryIdToName[i]
			startPos = startPos + self.bodyFontHeight --assume that category name fits in one line
		end

		for j = 1, #sortedList[i] do
			if i == QUEST_CATEGORY_ZONE then
				local zoneName = ""
				for k = 1, #sortedList[i][j] do
					if #zoneName == 0 then
						zoneName = sortedList[i][j][k].zone
						text[#text + 1] = "\n"
						text[#text + 1] = zo_strformat(categoryIdToName[i], zoneName)
						startPos = startPos + self.bodyFontHeight --assume that zone name fits in one line
					end
					link = self:AppendQuest(svtable[i][sortedList[i][j][k].zone][sortedList[i][j][k].name], sortedList[i][j][k].zone)
					text[#text + 1] = link
					self.clickMap[mathFloor(startPos)] = link
					startPos = startPos + self.bodyFontHeight --assume that quest name fits in one line
				end
			elseif i ~= QUEST_CATEGORY_ZONE then
				link = self:AppendQuest(svtable[i][sortedList[i][j].name], nil)
				text[#text + 1] = link
				self.clickMap[mathFloor(startPos)] = link
				startPos = startPos + self.bodyFontHeight --assume that quest name fits in one line
			end
		end
	end
	self:ShowText(tableConcat(text))
end

function HarvensQuestJournal:ShowIndexCategoryPage()
	local svtable
	self.title:SetText(self.currentCategoryName)
	svtable = self.sv.completed
	if not self.sortedListCompleted then
		self.sortedListCompleted = self:CreateSortedList(svtable)
	end

	local sortedList = self.sortedListCompleted

	local startPos = self.bodyFontHeight
	local text = ""
	local link

	local i = self.currentCategory
	if i == QUEST_CATEGORY_ZONE then
		local j = self.currentZoneKey
		for k = 1, #sortedList[i][j] do
			link = self:AppendQuest(svtable[i][sortedList[i][j][k].zone][sortedList[i][j][k].name], sortedList[i][j][k].zone)
			text = text .. link
			self.clickMap[mathFloor(startPos)] = link
			startPos = startPos + self.bodyFontHeight --assume that quest name fits in one line
		end
	else
		for j = 1, #sortedList[i] do
			link = self:AppendQuest(svtable[i][sortedList[i][j].name], nil)
			text = text .. link
			self.clickMap[mathFloor(startPos)] = link
			startPos = startPos + self.bodyFontHeight --assume that quest name fits in one line
		end
	end
	self:ShowText(text)
end

function HarvensQuestJournal:UpdateJournal(silence)
	if not silence then
		PlaySound(SOUNDS.BOOK_PAGE_TURN)
	end
	self.leftPage:SetVerticalScroll(0)
	self.currentPage = 1
	self.clickMap = nil
	self.clickMap = {}
	self.sortControl:SetHidden(true)
	if self.currentSection == JS_CURRENT or self.currentSection == JS_COMPLETED then
		if not (self.currentSection == JS_COMPLETED and self.sv.showCompletedByCategory) then
			self.sortControl:SetHidden(false)
		end
		self:ShowIndexPage()
	elseif self.currentSection == JS_COMPLETED_QUEST_CATEGORY then
		self.sortControl:SetHidden(false)
		self:ShowIndexCategoryPage()
	elseif self.currentSection == JS_CURRENT_QUEST or self.currentSection == JS_COMPLETED_QUEST then
		self.keybindStripDescriptor[5].name = self.currentSection == JS_CURRENT_QUEST and GetString(SI_QUEST_JOURNAL_ABANDON) or GetString(HARVEN_QUEST_JOURNAL_DELETE)
		self:ShowQuest()
		self.keybindStripDescriptor[1].name = GetString(HARVEN_QUEST_JOURNAL_BACK)
	elseif self.currentSection == JS_CONVERSATION then
		self:ShowConversation()
		self.keybindStripDescriptor[1].name = GetString(HARVEN_QUEST_JOURNAL_BACK)
	end
	KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function HarvensQuestJournal:OpenAtFocused()
	for k, v in pairs(self.activeQuests) do
		if GetTrackedIsAssisted(TRACK_TYPE_QUEST, v) then
			local quest, zoneName = self:FindQuest(k)
			if quest then
				self.currentSection = JS_CURRENT_QUEST
				self.currentQuest = quest[QS_NAME]
				self.currentQuestType = quest[QS_TYPE]
				self.currentQuestZone = zoneName
				return
			end
		end
	end

	self.currentSection = JS_CURRENT
end

function HarvensQuestJournal:OpenJournal()
	PlaySound(SOUNDS.BOOK_OPEN)
	self.activeQuests = {}
	for i = 1, MAX_JOURNAL_QUESTS do
		if IsValidQuestIndex(i) then
			self.activeQuests[zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, GetJournalQuestName(i))] = i
		end
	end

	self.keybindStripDescriptor[1].name = GetString(HARVEN_QUEST_JOURNAL_COMPLETED_QUESTS_KEYBIND)

	if self.sv.openAtTracked then
		self:OpenAtFocused()
	else
		self.currentSection = JS_CURRENT
	end

	self:UpdateJournal()
	if self.sv.openAtTracked then
		self:SwitchPage(self.numPages - 1)
	end
end

function HarvensQuestJournal:HandleLinkClick(control, linkData, linkText, button)
	local _, _, type = ZO_LinkHandler_ParseLink(linkText)
	if type == QUEST_LINK_TYPE then
		return
	end

	if not self:HandleLink(button, ZO_LinkHandler_ParseLink(linkText)) then
		ZO_LinkHandler_OnLinkClicked(linkText, button)
	end
end

function HarvensQuestJournal:HandleQuestClick(control, button)
	local _, y = GetUIMousePosition()
	y = y - control:GetTop()
	local key = mathFloor(mathFloor(y / self.bodyFontHeight) * self.bodyFontHeight)
	if self.clickMap[key] then
		self:HandleLink(button, ZO_LinkHandler_ParseLink(self.clickMap[key]))
	end
end

function HarvensQuestJournal:SortChanged(control, selectedText, selectedItem)
	self.sv.sort = selectedItem.sortID
	self.sortedListCurrent = nil
	self.sortedListCompleted = nil
	self:UpdateJournal()
end

function HarvensQuestJournal:InitJournal(control)
	self.journal = control:GetNamedChild("Journal")

	--local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_BOOK_MEDIUM, BOOK_MEDIUM_YELLOWED_PAPER)
	self.questColor = ZO_ColorDef:New(self.sv.layout.questR, self.sv.layout.questG, self.sv.layout.questB, self.sv.layout.questA)
	self.npcColor = ZO_ColorDef:New(self.sv.layout.npcR, self.sv.layout.npcG, self.sv.layout.npcB, self.sv.layout.npcA)

	self.background = GetControl(self.journal, "Bg")
	self.background:SetTexture(self.skinsToTextures[self.sv.layout.skin])

	self.leftPage = GetControl(self.journal, "LeftPage")
	self.leftPage.container = GetControl(self.leftPage, "Container")
	self.title = GetControl(self.leftPage.container, "Title")
	self.title:SetFont(self.sv.layout.titleFont)
	self.title:SetColor(self.sv.layout.fontR, self.sv.layout.fontG, self.sv.layout.fontB, self.sv.layout.fontA)
	self.title:SetStyleColor(0, 0, 0, 1)
	self.leftPage.body = GetControl(self.leftPage.container, "Body")
	self.leftPage.body:SetFont(self.sv.layout.bodyFont)
	self.leftPage.body:SetColor(self.sv.layout.fontR, self.sv.layout.fontG, self.sv.layout.fontB, self.sv.layout.fontA)
	self.leftPage.body:SetStyleColor(0, 0, 0, 1)
	self.leftPage.body:SetMouseEnabled(true)
	self.leftPage.body:SetHandler(
		"OnLinkClicked",
		function(...)
			self:HandleLinkClick(...)
		end
	)
	self.leftPage.body:SetHandler(
		"OnMouseDown",
		function(...)
			self:HandleQuestClick(...)
		end
	)

	self.rightPage = GetControl(self.journal, "RightPage")
	self.rightPage.container = GetControl(self.rightPage, "Container")
	self.rightPage.body = GetControl(self.rightPage.container, "Body")
	self.rightPage.body:SetFont(self.sv.layout.bodyFont)
	self.rightPage.body:SetColor(self.sv.layout.fontR, self.sv.layout.fontG, self.sv.layout.fontB, self.sv.layout.fontA)
	self.rightPage.body:SetStyleColor(0, 0, 0, 1)
	self.rightPage.body:SetMouseEnabled(true)
	self.rightPage.body:SetHandler(
		"OnLinkClicked",
		function(...)
			self:HandleLinkClick(...)
		end
	)
	self.rightPage.body:SetHandler(
		"OnMouseDown",
		function(...)
			self:HandleQuestClick(...)
		end
	)

	self.leftPage.body:SetText("TEST")
	self.bodyFontHeight = self.leftPage.body:GetFontHeight()

	self.clickMap = {}

	self.sortControl = GetControl(self.journal, "Sort")
	self.sortControl.combobox = GetControl(self.sortControl, "Dropdown").m_comboBox
	local sortItems = {
		[SORT_ALPHABETICALLY] = GetString(HARVEN_QUEST_JOURNAL_SORT_ALPHABETICALLY),
		[SORT_TIMEOFCOMPLETION] = GetString(HARVEN_QUEST_JOURNAL_SORT_TIMEOFCOMPLETION),
		[SORT_TIMEOFSTART] = GetString(HARVEN_QUEST_JOURNAL_SORT_TIMEOFSTART),
		[SORT_LEVEL] = GetString(HARVEN_QUEST_JOURNAL_SORT_LEVEL)
	}
	local item
	for k, v in pairs(sortItems) do
		item =
			self.sortControl.combobox:CreateItemEntry(
			v,
			function(...)
				self:SortChanged(...)
			end
		)
		item.sortID = k
		self.sortControl.combobox:AddItem(item)
	end
	self.sortControl.combobox:SetSelectedItem(sortItems[self.sv.sort])

	local ascCheckbox = GetControl(self.sortControl, "Ascending")
	ZO_CheckButton_SetLabelText(ascCheckbox, GetString(HARVEN_QUEST_JOURNAL_SORT_ASC))
	ZO_CheckButton_SetCheckState(ascCheckbox, self.sv.sortAscending)
	ZO_CheckButton_SetToggleFunction(
		ascCheckbox,
		function()
			self.sv.sortAscending = ZO_CheckButton_IsChecked(ascCheckbox)
			self.sortedListCurrent = nil
			self.sortedListCompleted = nil
			self:UpdateJournal()
		end
	)
end

function HarvensQuestJournal:HandleLink(button, text, color, linkType, completed, ...)
	if linkType == QUEST_LINK_TYPE then
		local type, zone = ...
		if tonumber(completed) == 0 then
			if button == 2 then
				FOCUSED_QUEST_TRACKER:ForceAssist(self.activeQuests[text])
				self:UpdateJournal(true)
				return true
			end
			self.currentSection = JS_CURRENT_QUEST
		else
			self.currentSection = JS_COMPLETED_QUEST
		end

		self.currentQuest = text
		self.currentQuestType = tonumber(type)
		self.currentQuestZone = zone
		self:UpdateJournal()
		return true
	elseif linkType == NPC_LINK_TYPE then
		local type, quest, zone = ...
		self.currentSection = JS_CONVERSATION
		self.currentQuestCompleted = tonumber(completed) == 1 and true or false
		self.currentQuest = quest
		self.currentQuestType = tonumber(type)
		self.currentQuestZone = zone
		self.currentQuestNPC = text
		self:UpdateJournal()
		return true
	elseif linkType == QUEST_CATEGORY_LINK_TYPE then
		self.currentSection = JS_COMPLETED_QUEST_CATEGORY
		self.currentCategoryName = text
		self.currentCategory = tonumber(completed)
		if self.currentCategory == QUEST_CATEGORY_ZONE then
			self.currentZoneKey = tonumber(select(1, ...))
		end
		self:UpdateJournal()
		return true
	end
	return false
end

function HarvensQuestJournal:GetQuestCategory(type, zone)
	local category = QUEST_CATEGORY_MISC

	if type == QUEST_TYPE_MAIN_STORY then
		category = QUEST_CATEGORY_MAIN_STORY
	elseif type == QUEST_TYPE_GUILD then
		category = QUEST_CATEGORY_GUILD
	elseif zone and #zone > 0 then
		category = QUEST_CATEGORY_ZONE
	else
		category = QUEST_CATEGORY_MISC
	end
	return category
end

function HarvensQuestJournal:FindQuest(name)
	for i = 1, #self.sv.quests do
		if i == QUEST_CATEGORY_ZONE then
			for zoneName, quests in pairs(self.sv.quests[i]) do
				if quests[name] then
					return quests[name], zoneName
				end
			end
		else
			if self.sv.quests[i] and self.sv.quests[i][name] then
				return self.sv.quests[i][name]
			end
		end
	end
	return nil
end

function HarvensQuestJournal:FindCompletedQuest(name)
	for i = 1, #self.sv.completed do
		if i == QUEST_CATEGORY_ZONE then
			for zoneName, quests in pairs(self.sv.completed[i]) do
				if quests[name] then
					return quests[name], zoneName
				end
			end
		else
			if self.sv.completed[i][name] then
				return self.sv.completed[i][name]
			end
		end
	end
	return nil
end

function HarvensQuestJournal:SetCompletedSavedVariable(quest, zone)
	local category = self:GetQuestCategory(quest[QS_TYPE], zone)
	local ret

	if not self.sv.completed[category] then
		self.sv.completed[category] = {}
	end

	if category == QUEST_CATEGORY_ZONE then
		if not self.sv.completed[category][zone] then
			self.sv.completed[category][zone] = {}
		end
		self.sv.completed[category][zone][quest[QS_NAME]] = quest
	else
		self.sv.completed[category][quest[QS_NAME]] = quest
	end
end

function HarvensQuestJournal:GetQuestSavedVariable(type, zone, name, completed)
	local category = self:GetQuestCategory(type, zone)
	local ret
	if completed then
		ret = self.sv.completed
	else
		ret = self.sv.quests
	end

	if not ret[category] then
		ret[category] = {}
	end

	if category == QUEST_CATEGORY_ZONE then
		if not ret[category][zone] then
			ret[category][zone] = {[name] = {}}
		elseif not ret[category][zone][name] then
			ret[category][zone][name] = {}
		end
		return ret[category][zone][name]
	else
		if not ret[category][name] then
			ret[category][name] = {}
		end
		return ret[category][name]
	end
end

function HarvensQuestJournal:DeleteCompletedQuest(type, zone, name)
	local category = self:GetQuestCategory(type, zone)
	if category == QUEST_CATEGORY_ZONE and self.sv.completed[category] and self.sv.completed[category][zone] and self.sv.completed[category][zone][name] then
		self.sv.completed[category][zone][name] = nil
	elseif category ~= QUEST_CATEGORY_ZONE and self.sv.completed[category] and self.sv.completed[category][name] then
		self.sv.completed[category][name] = nil
	end
end

function HarvensQuestJournal:DeleteQuest(type, zone, name)
	local category = self:GetQuestCategory(type, zone)
	if category == QUEST_CATEGORY_ZONE and self.sv.quests[category] and self.sv.quests[category][zone] and self.sv.quests[category][zone][name] then
		self.sv.quests[category][zone][name] = nil
	elseif category ~= QUEST_CATEGORY_ZONE and self.sv.quests[category] and self.sv.quests[category][name] then
		self.sv.quests[category][name] = nil
	end

	self.sortedListCurrent = nil
	self.sortedListCompleted = nil
end

function HarvensQuestJournal:AddQuest(questIndex)
	local name, backgroundText, activeStepText, _, _, _, _, level, _, type = GetJournalQuestInfo(questIndex)
	zoneName = GetJournalQuestLocationInfo(questIndex)
	if zoneName and #zoneName > 0 then
		zoneName = zo_strformat("<<1>>", zoneName)
	end

	local sv = self:GetQuestSavedVariable(type, zoneName, name)

	if sv[QS_NAME] and #sv[QS_NAME] > 0 then
		return sv
	end

	sv[QS_REPEAT] = GetJournalQuestRepeatType(questIndex)
	sv[QS_TYPE] = type
	sv[QS_ZONE] = zoneName
	sv[QS_NAME] = zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, name)
	sv[QS_BACKGROUND] = backgroundText
	sv[QS_STEPS] = {}
	sv[QS_STARTTIME] = GetTimeStamp()
	sv[QS_LEVEL] = level
	tableInsert(sv[QS_STEPS], {[QS_TEXT] = activeStepText})
	return sv
end

function HarvensQuestJournal:SetupChatter()
	HarvensQuestJournal.chatter = {}
	HarvensQuestJournal.chatter[QS_NPCNAME] = zo_strformat(SI_UNIT_NAME, GetUnitName("interact"))
	HarvensQuestJournal.chatter[QS_NPCZONE] = GetUnitZone("interact")
	if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
		CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
	end
	HarvensQuestJournal.chatter[QS_NPCLOCATION] = GetMapName()
	HarvensQuestJournal.chatter[QS_NPCPOSX], HarvensQuestJournal.chatter[QS_NPCPOSY] = GetMapPlayerPosition("interact")
end

function HarvensQuestJournal:SwitchPage(direction)
	if (direction < 0 and self.currentPage <= 1) or (direction > 0 and self.currentPage >= self.numPages) then
		return
	end
	PlaySound(SOUNDS.BOOK_PAGE_TURN)
	self.currentPage = self.currentPage + direction
	self.rightPage:SetVerticalScroll(self.rightPage.offset + (self.pageHeight * (2 * self.currentPage - 2)))
	self.leftPage:SetVerticalScroll(self.pageHeight * (2 * self.currentPage - 2))
	KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

local deleteConfirmationDialog = {
	title = {
		text = GetString(HARVEN_QUEST_JOURNAL_DELETE_QUEST)
	},
	mainText = {
		text = GetString(HARVEN_QUEST_JOURNAL_DELETE_QUEST_CONFIRM)
	},
	buttons = {
		[1] = {
			text = SI_NOTIFICATIONS_DELETE,
			callback = function(dialog)
				HarvensQuestJournal.DeleteCompletedQuest(HarvensQuestJournal, dialog.data.questType, dialog.data.questZone, dialog.data.questName)
				HarvensQuestJournal.currentSection = JS_COMPLETED
				HarvensQuestJournal.sortedListCompleted = nil
				HarvensQuestJournal.UpdateJournal(HarvensQuestJournal)
			end
		},
		[2] = {
			text = SI_DIALOG_CANCEL
		}
	}
}

ZO_Dialogs_RegisterCustomDialog("HarvensDeleteQuestConfirmationDialog", deleteConfirmationDialog)

function HarvensQuestJournal:InitKeybindStripDescriptor()
	self.keybindStripDescriptor = {
		{
			alignment = KEYBIND_STRIP_ALIGN_LEFT,
			order = 0,
			name = GetString(HARVEN_QUEST_JOURNAL_COMPLETED_QUESTS_KEYBIND),
			keybind = "UI_SHORTCUT_QUATERNARY",
			callback = function(keyUp)
				descriptor = self.keybindStripDescriptor[1]
				if self.currentSection == JS_COMPLETED or self.currentSection == JS_CURRENT_QUEST then
					descriptor.name = GetString(HARVEN_QUEST_JOURNAL_COMPLETED_QUESTS_KEYBIND)
					self.currentSection = JS_CURRENT
				elseif self.currentSection == JS_CURRENT or self.currentSection == JS_COMPLETED_QUEST then
					descriptor.name = GetString(HARVEN_QUEST_JOURNAL_CURRENT_QUESTS_KEYBIND)
					if self.sv.showCompletedByCategory and self.currentSection == JS_COMPLETED_QUEST then
						self.currentSection = JS_COMPLETED_QUEST_CATEGORY
					else
						self.currentSection = JS_COMPLETED
					end
				elseif self.currentSection == JS_CONVERSATION and self.currentQuestCompleted then
					descriptor.name = GetString(HARVEN_QUEST_JOURNAL_BACK)
					self.currentSection = JS_COMPLETED_QUEST
				elseif self.currentSection == JS_CONVERSATION and not self.currentQuestCompleted then
					descriptor.name = GetString(HARVEN_QUEST_JOURNAL_BACK)
					self.currentSection = JS_CURRENT_QUEST
				elseif self.currentSection == JS_COMPLETED_QUEST_CATEGORY then
					descriptor.name = GetString(HARVEN_QUEST_JOURNAL_CURRENT_QUESTS_KEYBIND)
					self.currentSection = JS_COMPLETED
				end
				self:UpdateJournal()
			end
		},
		{
			alignment = KEYBIND_STRIP_ALIGN_LEFT,
			order = 1,
			name = GetString(SI_LORE_READER_PREVIOUS_PAGE),
			keybind = "UI_SHORTCUT_PRIMARY",
			callback = function(keyUp)
				self:SwitchPage(-1)
			end,
			visible = function(descriptor)
				return (self.numPages > 1 and true or false)
			end
		},
		{
			alignment = KEYBIND_STRIP_ALIGN_LEFT,
			order = 2,
			name = GetString(SI_LORE_READER_NEXT_PAGE),
			keybind = "UI_SHORTCUT_SECONDARY",
			callback = function(keyUp)
				self:SwitchPage(1)
			end,
			visible = function(descriptor)
				return (self.numPages > 1 and true or false)
			end
		},
		{
			alignment = KEYBIND_STRIP_ALIGN_RIGHT,
			order = 1,
			keybind = "UI_SHORTCUT_SHOW_QUEST_ON_MAP",
			name = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
			callback = function(keyUp)
				ZO_WorldMap_ShowQuestOnMap(self.activeQuests[self.currentQuest])
			end,
			visible = function(descriptor)
				if self.currentSection == JS_CURRENT_QUEST then
					return true
				end
				return false
			end
		},
		{
			alignment = KEYBIND_STRIP_ALIGN_RIGHT,
			order = 0,
			name = GetString(SI_QUEST_JOURNAL_ABANDON),
			keybind = "UI_SHORTCUT_NEGATIVE",
			callback = function(keyUp)
				if self.currentSection == JS_CURRENT_QUEST then
					QUEST_JOURNAL_MANAGER:ConfirmAbandonQuest(self.activeQuests[self.currentQuest])
				else
					local quest = self:GetQuestSavedVariable(self.currentQuestType, self.currentQuestZone, self.currentQuest, (self.currentSection == JS_COMPLETED_QUEST and true or false))
					if not quest then
						return
					end

					ZO_Dialogs_ShowDialog("HarvensDeleteQuestConfirmationDialog", {questType = self.currentQuestType, questZone = self.currentQuestZone, questName = self.currentQuest}, {mainTextParams = {zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, quest[QS_NAME])}})
				end
			end,
			visible = function(descriptor)
				if (self.currentSection == JS_CURRENT_QUEST and self.currentQuestType ~= QUEST_TYPE_MAIN_STORY) or self.currentSection == JS_COMPLETED_QUEST then
					return true
				end
				return false
			end
		},
		{
			alignment = KEYBIND_STRIP_ALIGN_CENTER,
			order = 0,
			name = GetString(HARVEN_QUEST_JOURNAL_SET_FOCUS),
			callback = function(keyUp)
				FOCUSED_QUEST_TRACKER:ForceAssist(self.activeQuests[self.currentQuest])
				KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
			end,
			keybind = "UI_SHORTCUT_REPORT_PLAYER",
			visible = function(descriptor)
				if self.currentSection == JS_CURRENT_QUEST then
					local isAssisted = GetTrackedIsAssisted(TRACK_TYPE_QUEST, self.activeQuests[self.currentQuest])
					if not isAssisted then
						return true
					end
				end
				return false
			end
		},
		{
			alignment = KEYBIND_STRIP_ALIGN_RIGHT,
			order = 1,
			keybind = "UI_SHORTCUT_TERTIARY",
			name = GetString(SI_QUEST_JOURNAL_SHARE),
			callback = function(keyUp)
				QUEST_JOURNAL_MANAGER:ShareQuest(self.activeQuests[self.currentQuest])
			end,
			visible = function(descriptor)
				if self.currentSection == JS_CURRENT_QUEST and GetIsQuestSharable(self.activeQuests[self.currentQuest]) and IsUnitGrouped("player") then
					return true
				end
				return false
			end
		}
	}
end

function HarvensQuestJournal:ToggleJournal()
	if not SCENE_MANAGER:IsShowing("HarvensQuestJournal") then
		SCENE_MANAGER:Show("HarvensQuestJournal")
	else
		SCENE_MANAGER:Hide("HarvensQuestJournal")
	end
end

function HarvensQuestJournal:SetupOptions()
	local settings = LibHarvensAddonSettings:AddAddon("Harven's Quest Journal")
	settings.version = "2.9.2"

	local skin = {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = GetString(HARVEN_QUEST_JOURNAL_BOOK_SKIN),
		items = {
			{
				name = "Paper"
			},
			{
				name = "Skin"
			},
			{
				name = "Rubbing"
			}
		},
		getFunction = function()
			return self.sv.layout.skin
		end,
		setFunction = function(combobox, name)
			self.sv.layout.skin = name
			self.background:SetTexture(HarvensQuestJournal.skinsToTextures[name])
		end
	}

	local bodyFont = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = GetString(HARVEN_QUEST_JOURNAL_BODY_FONT),
		getFunction = function()
			return self.sv.layout.bodyFont
		end,
		setFunction = function(newValue)
			self.sv.layout.bodyFont = newValue
			self.leftPage.body:SetFont(self.sv.layout.bodyFont)
			self.rightPage.body:SetFont(self.sv.layout.bodyFont)
			self.leftPage.body:SetText("TEST")
			self.bodyFontHeight = self.leftPage.body:GetFontHeight()
		end
	}

	local titleFont = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = GetString(HARVEN_QUEST_JOURNAL_TITLE_FONT),
		getFunction = function()
			return self.sv.layout.titleFont
		end,
		setFunction = function(newValue)
			self.sv.layout.titleFont = newValue
			self.title:SetFont(self.sv.layout.titleFont)
		end
	}

	local fontColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(HARVEN_QUEST_JOURNAL_FONT_COLOR),
		getFunction = function()
			return self.sv.layout.fontR, self.sv.layout.fontG, self.sv.layout.fontB, self.sv.layout.fontA
		end,
		setFunction = function(...)
			self.sv.layout.fontR, self.sv.layout.fontG, self.sv.layout.fontB, self.sv.layout.fontA = ...
			self.title:SetColor(...)
			self.rightPage.body:SetColor(...)
			self.leftPage.body:SetColor(...)
		end
	}

	local questColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(HARVEN_QUEST_JOURNAL_QUEST_NAME_COLOR),
		getFunction = function()
			return self.sv.layout.questR, self.sv.layout.questG, self.sv.layout.questB, self.sv.layout.questA
		end,
		setFunction = function(...)
			self.sv.layout.questR, self.sv.layout.questG, self.sv.layout.questB, self.sv.layout.questA = ...
			self.questColor = nil
			self.questColor = ZO_ColorDef:New(...)
		end
	}

	local npcNamesColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(HARVEN_QUEST_JOURNAL_NPC_NAME_COLOR),
		getFunction = function()
			return self.sv.layout.npcR, self.sv.layout.npcG, self.sv.layout.npcB, self.sv.layout.npcA
		end,
		setFunction = function(...)
			self.sv.layout.npcR, self.sv.layout.npcG, self.sv.layout.npcB, self.sv.layout.npcA = ...
			self.npcColor = nil
			self.npcColor = ZO_ColorDef:New(...)
		end
	}

	local showCompletedByCategory = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(HARVEN_QUEST_JOURNAL_LIST_COMPLETED_QUESTS_CATEGORYIES),
		tooltip = GetString(HARVEN_QUEST_JOURNAL_LIST_COMPLETED_QUESTS_CATEGORYIES_TOOLTIP),
		getFunction = function()
			return self.sv.showCompletedByCategory
		end,
		setFunction = function(state)
			self.sv.showCompletedByCategory = state
		end
	}

	local openAtTracked = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(HARVEN_QUEST_JOURNAL_OPEN_FOCUSED_QUEST),
		getFunction = function()
			return self.sv.openAtTracked
		end,
		setFunction = function(state)
			self.sv.openAtTracked = state
		end
	}

	local saveDailyQuests = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(HARVEN_QUEST_JOURNAL_SAVED_COMPLETED_DAILIES),
		getFunction = function()
			return self.sv.saveDaily
		end,
		setFunction = function(state)
			self.sv.saveDaily = state
		end
	}

	local saveRepeatableQuests = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(HARVEN_QUEST_JOURNAL_COMPLETED_REPEATABLE),
		getFunction = function()
			return self.sv.saveRepeatable
		end,
		setFunction = function(state)
			self.sv.saveRepeatable = state
		end
	}

	local playEmote = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(HARVEN_QUEST_JOURNAL_PLAY_EMOTE),
		getFunction = function()
			return self.sv.playEmote
		end,
		setFunction = function(state)
			self.sv.playEmote = state
		end
	}

	settings:AddSettings({openAtTracked, skin, titleFont, bodyFont, fontColor, questColor, npcNamesColor, showCompletedByCategory, saveDailyQuests, saveRepeatableQuests, playEmote})
	if LibMainMenu2 then
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = GetString(HARVEN_QUEST_JOURNAL_SHOW_MAIN_MENU),
			getFunction = function()
				return self.sv.showInMainMenu
			end,
			setFunction = function(state)
				self.sv.showInMainMenu = state
			end
		}
	end
end

function HarvensQuestJournal:ConvertItemLinks(items)
	for i = 1, #items do
		local itemLink = items[i]
		itemLink = string.gsub(itemLink, "^|H[%w][%w][%w][%w][%w][%w]", "|H1")
		--itemLink = string.gsub(itemLink, "|h.*|h", "|h|h")
		items[i] = itemLink
	end
end

function HarvensQuestJournal:ConvertLinks()
	for k, v in pairs(self.sv.completed) do
		if k == QUEST_CATEGORY_ZONE then
			for zone, quests in pairs(v) do
				for name, quest in pairs(quests) do
					if quest[QS_REWARD] and quest[QS_REWARD][QS_ITEMS] then
						self:ConvertItemLinks(quest[QS_REWARD][QS_ITEMS])
					end
				end
			end
		else
			for name, quest in pairs(v) do
				if quest[QS_REWARD] and quest[QS_REWARD][QS_ITEMS] then
					self:ConvertItemLinks(quest[QS_REWARD][QS_ITEMS])
				end
			end
		end
	end
	self.sv.linksConverted = true
end

function HarvensQuestJournal:FixZones()
	local zones = {}

	for zone, quests in pairs(self.sv.completed[QUEST_CATEGORY_ZONE]) do
		if next(quests) then
			table.insert(zones, zone)
		end
	end
	for i = 1, #zones do
		for name, quest in pairs(self.sv.completed[QUEST_CATEGORY_ZONE][zones[i]]) do
			local zoneName = zo_strformat("<<1>>", quest[QS_ZONE])
			if not self.sv.completed[QUEST_CATEGORY_ZONE][zoneName] then
				self.sv.completed[QUEST_CATEGORY_ZONE][zoneName] = {}
			end
			self.sv.completed[QUEST_CATEGORY_ZONE][zoneName][name] = quest
			self.sv.completed[QUEST_CATEGORY_ZONE][zones[i]][name] = nil
			quest = nil
		end
	end

	zones = {}
	for zone, quests in pairs(self.sv.quests[QUEST_CATEGORY_ZONE]) do
		if next(quests) then
			table.insert(zones, zone)
		end
	end
	for i = 1, #zones do
		for name, quest in pairs(self.sv.quests[QUEST_CATEGORY_ZONE][zones[i]]) do
			local zoneName = zo_strformat("<<1>>", quest[QS_ZONE])
			if not self.sv.quests[QUEST_CATEGORY_ZONE][zoneName] then
				self.sv.quests[QUEST_CATEGORY_ZONE][zoneName] = {}
			end
			self.sv.quests[QUEST_CATEGORY_ZONE][zoneName][name] = quest
			self.sv.quests[QUEST_CATEGORY_ZONE][zones[i]][name] = nil
			quest = nil
		end
	end
	self.sv.zonesFixed = true
end

function HarvensQuestJournal.AddonLoaded(eventType, addonName)
	if addonName ~= "HarvensQuestJournal" then
		return
	end

	local re, gr, bl = GetInterfaceColor(INTERFACE_COLOR_TYPE_BOOK_MEDIUM, BOOK_MEDIUM_YELLOWED_PAPER)
	local defaults = {
		zonesFixed = false,
		linksConverted = false,
		layout = {
			openAtTracked = false,
			skin = "Paper",
			bodyFont = "ZoFontBookPaper",
			titleFont = "ZoFontBookPaperTitle",
			fontR = re,
			fontG = gr,
			fontB = bl,
			fontA = 0.8,
			questR = 0.34,
			questG = 0.05,
			questB = 0.05,
			questA = 0.8,
			npcR = 0.05,
			npcG = 0.37,
			npcB = 0.06,
			npcA = 0.8
		},
		saveDaily = true,
		saveRepeatable = true,
		sort = SORT_ALPHABETICALLY,
		sortAscending = true,
		showCompletedByCategory = false,
		playEmote = true,
		showInMainMenu = true
	}

	HarvensQuestJournal.sv = ZO_SavedVars:New("HarvensQuestJournal_SavedVariables", 1, nil, defaults)

	if not HarvensQuestJournal.sv.quests and not HarvensQuestJournal.sv.completed then
		HarvensQuestJournal.sv.quests = {
			[QUEST_CATEGORY_MAIN_STORY] = {},
			[QUEST_CATEGORY_GUILD] = {},
			[QUEST_CATEGORY_ZONE] = {},
			[QUEST_CATEGORY_MISC] = {}
		}

		HarvensQuestJournal.sv.completed = {
			[QUEST_CATEGORY_MAIN_STORY] = {},
			[QUEST_CATEGORY_GUILD] = {},
			[QUEST_CATEGORY_ZONE] = {},
			[QUEST_CATEGORY_MISC] = {}
		}
		HarvensQuestJournal.sv.zonesFixed = true
	end

	HarvensQuestJournalTopLevel:SetHandler(
		"OnHide",
		function()
			PlaySound(SOUNDS.BOOK_CLOSE)
		end
	)

	HarvensQuestJournal.numPages = 1
	HarvensQuestJournal.currentPage = 1
	HarvensQuestJournal.currentSection = JS_CURRENT
	HarvensQuestJournal.currentQuest = ""
	HarvensQuestJournal.skinsToTextures = {
		["Paper"] = "EsoUI/Art/LoreLibrary/loreLibrary_paperBook.dds",
		["Skin"] = "EsoUI/Art/LoreLibrary/loreLibrary_skinBook.dds",
		["Rubbing"] = "EsoUI/Art/LoreLibrary/loreLibrary_rubbingBook.dds"
	}

	local fragment = ZO_FadeSceneFragment:New(HarvensQuestJournalTopLevel)

	local sceneName = "HarvensQuestJournal"
	local scene = ZO_Scene:New(sceneName, SCENE_MANAGER)
	if FRAGMENT_GROUP.UI_WINDOW then
		scene:AddFragmentGroup(FRAGMENT_GROUP.UI_WINDOW)
	else
		scene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
	end
	scene:AddFragment(fragment)
	scene:AddFragment(UNIFORM_BLUR_FRAGMENT)

	HarvensQuestJournal:InitKeybindStripDescriptor()

	local function doEmote(name)
		if not HarvensQuestJournal.sv.playEmote then
			return
		end
		local emote = SLASH_COMMANDS[name]
		if type(emote) == "function" then
			emote()
		end
	end
	scene:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_SHOWING then
				KEYBIND_STRIP:AddKeybindButtonGroup(HarvensQuestJournal.keybindStripDescriptor)
				HarvensQuestJournal:OpenJournal()
			elseif newState == SCENE_SHOWN then
				doEmote("/read")
			elseif newState == SCENE_HIDING then
				doEmote("/idle")
			elseif newState == SCENE_HIDDEN then
				KEYBIND_STRIP:RemoveKeybindButtonGroup(HarvensQuestJournal.keybindStripDescriptor)
			end
		end
	)

	local LMM2 = LibMainMenu2
	if LMM2 then
		LMM2:Init()

		ZO_CreateStringId("SI_HARVENS_QUEST_JOURNAL", "Harven's Quest Journal")
		-- Add to main menu
		local categoryLayoutInfo = {
			binding = "TOGGLE_HARVENSQUESTJOURNAL",
			categoryName = SI_HARVENS_QUEST_JOURNAL,
			callback = function(buttonData)
				if not SCENE_MANAGER:IsShowing(sceneName) then
					SCENE_MANAGER:Show(sceneName)
				end
			end,
			visible = function(buttonData)
				return HarvensQuestJournal.sv.showInMainMenu
			end,
			normal = "/esoui/art/tradinghouse/tradinghouse_racial_style_motif_book_up.dds",
			pressed = "/esoui/art/tradinghouse/tradinghouse_racial_style_motif_book_down.dds",
			highlight = "/esoui/art/tradinghouse/tradinghouse_racial_style_motif_book_over.dds",
			disabled = "/esoui/art/tradinghouse/tradinghouse_racial_style_motif_book_disabled.dds"
		}
		LMM2:AddMenuItem(sceneName, sceneName, categoryLayoutInfo, nil)
	end

	SLASH_COMMANDS["/journal"] = function()
		HarvensQuestJournal:ToggleJournal()
	end

	HarvensQuestJournal:InitJournal(HarvensQuestJournalTopLevel)

	local GetOfferedQuestInfoOrg = GetOfferedQuestInfo
	GetOfferedQuestInfo = function(...)
		local ret = {GetOfferedQuestInfoOrg(...)}

		if not HarvensQuestJournal.chatter then
			HarvensQuestJournal:SetupChatter()
		end
		if not HarvensQuestJournal.chatter[QS_NPCCONVERSATION] then
			HarvensQuestJournal.chatter[QS_NPCCONVERSATION] = {[QS_THEM] = {}, [QS_ME] = {}}
		end
		tableInsert(HarvensQuestJournal.chatter[QS_NPCCONVERSATION][QS_THEM], ret[1])
		tableInsert(HarvensQuestJournal.chatter[QS_NPCCONVERSATION][QS_ME], ret[2])

		return unpack(ret)
	end

	--[[ CAUSED LIPSYNC ISSUES
	EVENT_MANAGER:RegisterForEvent("HarvensQuestJournal", EVENT_QUEST_OFFERED, function(eventType, ...)

		--EVENT_MANAGER:RegisterForUpdate("HarvensQuestJournalQuestOfferedDelay"

		d("No args: "..tostring(select('#',...)))
		for i=1,select('#',...) do
			d("Arg"..i.." "..tostring((select(i,...))))
		end

		--d("EVENT_QUEST_OFFERED")
		local text, response = GetOfferedQuestInfo()
		local _, farewell = GetChatterFarewell()
		if not HarvensQuestJournal.chatter then
			HarvensQuestJournal:SetupChatter()
		end
		if not HarvensQuestJournal.chatter[QS_NPCCONVERSATION] then
			HarvensQuestJournal.chatter[QS_NPCCONVERSATION] = {[QS_THEM] = {}, [QS_ME] = {}}
		end
		table.insert(HarvensQuestJournal.chatter[QS_NPCCONVERSATION][QS_THEM], text)
		table.insert(HarvensQuestJournal.chatter[QS_NPCCONVERSATION][QS_ME], response)
	end)
	--]]
	EVENT_MANAGER:RegisterForEvent(
		"HarvensQuestJournal",
		EVENT_QUEST_REMOVED,
		function(eventType, isCompleted, journalIndex, questName, zoneIndex, poiIndex)
			--d("EVENT_QUEST_REMOVED: "..journalIndex)

			local quest, zoneName = HarvensQuestJournal:FindQuest(zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, questName))
			if not quest then
				return
			end

			if quest[QS_REPEAT] then
				if quest[QS_REPEAT] == QUEST_REPEAT_DAILY and not HarvensQuestJournal.sv.saveDaily then
					isCompleted = false
				elseif quest[QS_REPEAT] == QUEST_REPEAT_REPEATABLE and not HarvensQuestJournal.sv.saveRepeatable then
					isCompleted = false
				else
					quest[QS_REPEAT] = nil
				end
			end

			if isCompleted then
				quest[QS_COMPLETEDTIME] = GetTimeStamp()
				quest[QS_TERMINATOR] = HarvensQuestJournal.chatter
				quest[QS_REWARD] = HarvensQuestJournal.reward
				HarvensQuestJournal:SetCompletedSavedVariable(quest, zoneName)
			end
			HarvensQuestJournal:DeleteQuest(quest[QS_TYPE], zoneName, quest[QS_NAME])
			quest = nil

			if (HarvensQuestJournal.currentSection == JS_CURRENT_QUEST or HarvensQuestJournal.currentSection == JS_CONVERSATION) and HarvensQuestJournal.activeQuests[HarvensQuestJournal.currentQuest] == journalIndex then
				HarvensQuestJournal.currentSection = JS_CURRENT
				HarvensQuestJournal:UpdateJournal()
			end
		end
	)

	EVENT_MANAGER:RegisterForEvent(
		"HarvensQuestJournal",
		EVENT_QUEST_COMPLETE,
		function(eventType, questName, level, lastXP, currentXP, championPoints)
			--d("EVENT_QUEST_COMPLETE")

			local quest = HarvensQuestJournal:FindCompletedQuest(zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, questName))
			if not quest then
				return
			end

			if not quest[QS_REWARD] then
				quest[QS_REWARD] = {}
			end

			if currentXP - lastXP > 0 then
				quest[QS_REWARD][QS_EXPERIENCE] = currentXP - lastXP
			end
			if championPoints and championPoints > 0 then
				quest[QS_REWARD][QS_CHAMPION_POINTS] = championPoints
			end
		end
	)

	EVENT_MANAGER:RegisterForEvent(
		"HarvensQuestJournal",
		EVENT_QUEST_COMPLETE_DIALOG,
		function(eventType, journalIndex)
			--d("EVENT_QUEST_COMPLETE_DIALOG: "..journalIndex)
			HarvensQuestJournal:SetupChatter()
			local _, dialog = GetJournalQuestEnding(journalIndex)
			HarvensQuestJournal.reward = {}
			HarvensQuestJournal.chatter[QS_NPCDIALOG] = dialog
			HarvensQuestJournal.reward[QS_ITEMS] = {}

			for i = 1, GetJournalQuestNumRewards(journalIndex) do
				local type, name, amount = GetJournalQuestRewardInfo(journalIndex, i)
				--d("Type: "..tostring(type)..", name: "..tostring(name)..", amount: "..tostring(amount))
				if type == REWARD_TYPE_AUTO_ITEM then
					table.insert(HarvensQuestJournal.reward[QS_ITEMS], GetQuestRewardItemLink(i, LINK_STYLE_DEFAULT))
				elseif type == REWARD_TYPE_MONEY then
					HarvensQuestJournal.reward[QS_GOLD] = amount
				end
			end
		end
	)

	EVENT_MANAGER:RegisterForEvent(
		"HarvensQuestJournal",
		EVENT_QUEST_ADDED,
		function(eventType, journalIndex, questName, objectiveName)
			--d("EVENT_QUEST_ADDED")
			quest = HarvensQuestJournal:AddQuest(journalIndex)
			quest[QS_BESTOWER] = HarvensQuestJournal.chatter
			HarvensQuestJournal.sortedListCurrent = nil
		end
	)

	EVENT_MANAGER:RegisterForEvent(
		"HarvensQuestJournal",
		EVENT_QUEST_ADVANCED,
		function(eventType, journalIndex, questName, isPushed, isComplete, mainStepChanged)
			--d("EVENT_QUEST_ADVANCED")

			local quest = HarvensQuestJournal:FindQuest(zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, questName))
			if not quest then
				quest = HarvensQuestJournal:AddQuest(journalIndex)
			end

			local found = false
			if mainStepChanged then
				local _, _, step = GetJournalQuestInfo(journalIndex)
				if step and #step > 0 then
					for i = 1, #quest[QS_STEPS] do
						if quest[QS_STEPS][i][QS_TEXT] == step then
							found = true
							break
						end
					end
					if not found then
						tableInsert(quest[QS_STEPS], {[QS_TEXT] = step, [QS_TIME] = GetTimeStamp()})
					end
				end
			else
				for i = 1, GetJournalQuestNumSteps(journalIndex) do
					local text = GetJournalQuestStepInfo(journalIndex, i)
					found = false
					if text and #text > 0 then
						for i = 1, #quest[QS_STEPS] do
							if quest[QS_STEPS][i][QS_TEXT] == text then
								found = true
								break
							end
						end

						if not found then
							tableInsert(quest[QS_STEPS], {[QS_TEXT] = text, [QS_TIME] = GetTimeStamp()})
						end
					end
				end
			end
		end
	)

	EVENT_MANAGER:RegisterForEvent(
		"HarvensQuestJournal",
		EVENT_CHATTER_END,
		function(eventType, ...)
			--d("EVENT_CHATTER_END")
			HarvensQuestJournal.chatter = nil
			HarvensQuestJournal.reward = nil
		end
	)

	--[[
	EVENT_MANAGER:RegisterForEvent("HarvensQuestJournal", EVENT_CHATTER_BEGIN, function(eventType,...)
		d("EVENT_CHATTER_BEGIN")
		--local text = GetNameOfGameCameraQuestToolTarget()
		HarvensQuestJournal.chatterName = GetUnitName("interact")
		HarvensQuestJournal.chatterZone = GetUnitZone("interact")
		if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
			CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
		end
		HarvensQuestJournal.chatterLocation = GetMapName()
		HarvensQuestJournal.chatterX, HarvensQuestJournal.chatterY = GetMapPlayerPosition("interact")
		d(HarvensQuestJournal.chatterName.." "..tostring(HarvensQuestJournal.chatterZone).." "..HarvensQuestJournal.chatterLocation)
		d(tostring(HarvensQuestJournal.chatterX).." "..tostring(HarvensQuestJournal.chatterY))
	end)
	EVENT_MANAGER:RegisterForEvent("HarvensQuestJournal", EVENT_OBJECTIVES_UPDATED, function(eventType, ...)
		d("EVENT_OBJECTIVES_UPDATED")
		for i=1, select('#', ...) do
			d(i.." "..tostring(select(1,...)))
		end
	end)
--]]
	EVENT_MANAGER:RegisterForEvent(
		"HarvensQuestJournal",
		EVENT_PLAYER_ACTIVATED,
		function(eventCode, initial)
			EVENT_MANAGER:UnregisterForEvent("HarvensQuestJournal", EVENT_PLAYER_ACTIVATED)

			HarvensQuestJournal.activeQuests = {}

			for i = 1, MAX_JOURNAL_QUESTS do
				if IsValidQuestIndex(i) then
					HarvensQuestJournal.activeQuests[zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, GetJournalQuestName(i))] = i
				end
			end

			--check for completed quests when the addon was disabled
			for category, v in pairs(HarvensQuestJournal.sv.quests) do
				if category == QUEST_CATEGORY_ZONE then
					for zone, quests in pairs(v) do
						for name, quest in pairs(quests) do
							if not HarvensQuestJournal.activeQuests[name] then
								quest[QS_COMPLETEDTIME] = GetTimeStamp()
								HarvensQuestJournal:SetCompletedSavedVariable(quest, quest[QS_ZONE])
								HarvensQuestJournal:DeleteQuest(quest[QS_TYPE], quest[QS_ZONE], quest[QS_NAME])
								quest = nil
							end
						end
					end
				else
					for name, quest in pairs(v) do
						if not HarvensQuestJournal.activeQuests[name] then
							quest[QS_COMPLETEDTIME] = GetTimeStamp()
							HarvensQuestJournal:SetCompletedSavedVariable(quest, nil)
							HarvensQuestJournal:DeleteQuest(quest[QS_TYPE], nil, quest[QS_NAME])
							quest = nil
						end
					end
				end
			end

			for i = 1, MAX_JOURNAL_QUESTS do
				if IsValidQuestIndex(i) then
					HarvensQuestJournal:AddQuest(i)
				end
			end

			if not HarvensQuestJournal.sv.linksConverted then
				HarvensQuestJournal:ConvertLinks()
			end

			if not HarvensQuestJournal.sv.zonesFixed then
				HarvensQuestJournal:FixZones()
			end
		end
	)

	HarvensQuestJournal:SetupOptions()

	HARVENS_QUEST_JOURNAL = HarvensQuestJournal
end

EVENT_MANAGER:RegisterForEvent("HarvensQuestJournal", EVENT_ADD_ON_LOADED, HarvensQuestJournal.AddonLoaded)
