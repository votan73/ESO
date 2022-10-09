local addon = ZO_SocialListKeyboard:Subclass()
addon.name = "VotansContactList"
addon.title = "Votan's Contact List"
addon.defaults =
{
}
addon.masterList = { }

function addon:New(...)
	return ZO_SocialListKeyboard.New(self, ...)
end

local ROW_ID = 1
local gps = LibGPS2
local async = LibAsync

local function GetData(rowControl)
	local item = ZO_ScrollList_GetData(rowControl)
	return item.dataEntry.data
end

local function stateChange(oldState, newState)
	if (newState == SCENE_SHOWN) then
		addon:RefreshData()
		addon:InitializeKeybindDescriptors()
		KEYBIND_STRIP:AddKeybindButtonGroup(addon.keybindStripDescriptor)
	elseif (newState == SCENE_HIDING) then
		KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.keybindStripDescriptor)
	end
end 

function addon:OnInitialized(control)
	-- FRIENDS_LIST_MANAGER:AddList(self)
	VOTANS_CONTACT_LIST_SCENE = ZO_Scene:New(addon.name, SCENE_MANAGER)
	VOTANS_CONTACT_LIST_FRAGMENT = ZO_FadeSceneFragment:New(control)

	VOTANS_CONTACT_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
	VOTANS_CONTACT_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
	VOTANS_CONTACT_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
	VOTANS_CONTACT_LIST_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
	VOTANS_CONTACT_LIST_SCENE:AddFragment(VOTANS_CONTACT_LIST_FRAGMENT)
	VOTANS_CONTACT_LIST_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
	VOTANS_CONTACT_LIST_SCENE:AddFragment(TITLE_FRAGMENT)
	VOTANS_CONTACT_LIST_SCENE:AddFragment(CONTACTS_TITLE_FRAGMENT)
	VOTANS_CONTACT_LIST_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
	VOTANS_CONTACT_LIST_SCENE:AddFragment(CONTACTS_WINDOW_SOUNDS)
	VOTANS_CONTACT_LIST_SCENE:AddFragment(FRIENDS_ONLINE_FRAGMENT)

	local sceneGroupName = "contactsSceneGroup"
	local sceneGroupInfo = MAIN_MENU_KEYBOARD.sceneGroupInfo[sceneGroupName]

	table.insert(sceneGroupInfo.menuBarIconData, 2, {
		categoryName = SI_VOTANS_CONTACT_LIST_TITLE,
		descriptor = addon.name,
		normal = "EsoUI/Art/MainMenu/menuBar_social_up.dds",
		pressed = "EsoUI/Art/MainMenu/menuBar_social_down.dds",
		-- disabled = "EsoUI/Art/MainMenu/menuBar_social_disabled.dds",
		highlight = "EsoUI/Art/MainMenu/menuBar_social_over.dds",
	} )

	local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
	sceneGroup:AddScene(addon.name)
	SCENE_MANAGER:AddSceneGroup(sceneGroupName, sceneGroup)
	MAIN_MENU_KEYBOARD:AddSceneGroup(sceneGroupInfo.category, sceneGroupName, sceneGroupInfo.menuBarIconData)

	VOTANS_CONTACT_LIST_SCENE:AddFragment(sceneGroupInfo.sceneGroupBarFragment)

	self:InitializeSortFilterList(control)

	ZO_ScrollList_AddDataType(self.list, ROW_ID, "Votans_ContactListRow", 30, function(control, data) self:SetupRow(control, data) end)
	ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

	self.searchBox = GetControl(control, "SearchBox")
	self.searchBox:SetHandler("OnTextChanged", function(control) self:OnSearchTextChanged(control:GetText()) end)

	self.sortFunction = function(a, b) return a.data.timestamp > b.data.timestamp end

	VOTANS_CONTACT_LIST_SCENE:RegisterCallback("StateChange", stateChange)

end

do
	local pattern = "^([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(.*)"
	function addon:GetParts(data)
		return data:match(pattern)
	end

	function addon:BuildMasterList()
		ZO_ClearNumericallyIndexedTable(self.masterList)

		local recentList = self.recentList
		for name, data in pairs(recentList.RecentInteractions) do
			local parts = { data:match(pattern) }
			local rowData = { displayName = name, timestamp = tonumber(parts[1]), parts = parts }
			self.masterList[#self.masterList + 1] = rowData
		end
	end
	function addon:CreateParts(timeStamp, alliance, level, cp, rank, race, classId, zone, playerX, playerY, count, note)
		return string.format("%i:%i:%i:%i:%i:%i:%i:%i:%f:%f:%i:%s", timeStamp, alliance, level, cp, rank, race, classId, zone, playerX, playerY, count, note)
	end
end

function addon:FilterScrollList()
	table.sort(self.masterList, function(a, b) return a.timestamp > b.timestamp end)

	self.list.now = GetTimeStamp()

	local scrollData = ZO_ScrollList_GetDataList(self.list)
	ZO_ClearNumericallyIndexedTable(scrollData)

	local searchTerm = self:GetSearchTerm()

	local count = 0
	if searchTerm == "" then
		for i = 1, #self.masterList do
			scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ROW_ID, self.masterList[i])
			count = count + 1
			if count > 24 then break end
		end
	else
		searchTerm = zo_strlower(searchTerm)
		for i = 1, #self.masterList do
			local rowData = self.masterList[i]
			if not rowData.searchName then rowData.searchName = zo_strlower(rowData.displayName) end
			if zo_plainstrfind(rowData.searchName, searchTerm) then
				scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ROW_ID, rowData)
				count = count + 1
				if count > 24 then break end
			end
		end
	end
end

function addon:SortScrollList()
	-- if (self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
	-- local scrollData = ZO_ScrollList_GetDataList(self.list)
	-- table.sort(scrollData, self.sortFunction)
	-- end
end

function addon:GetRowColors(data, mouseIsOver)
	local color = data.color
	return color, color
end

function addon:GetQualityFromCount(count)
	local contactQuality
	if count <= 4 then
		contactQuality = ITEM_QUALITY_TRASH
	elseif count <= 8 then
		contactQuality = ITEM_QUALITY_NORMAL
	elseif count <= 16 then
		contactQuality = ITEM_QUALITY_MAGIC
	elseif count <= 32 then
		contactQuality = ITEM_QUALITY_ARCANE
	elseif count < 64 then
		contactQuality = ITEM_QUALITY_ARTIFACT
	else
		contactQuality = ITEM_QUALITY_LEGENDARY
	end
	return contactQuality
end

function addon:SetupRow(control, rowData)
	local ctlStatus = GetControl(control, "StatusIcon")
	local ctlDisplayName = GetControl(control, "DisplayName")
	local ctlZone = GetControl(control, "Zone")
	local ctlClass = GetControl(control, "ClassIcon")
	local ctlAlliance = GetControl(control, "AllianceIcon")
	local ctlLevel = GetControl(control, "Level")
	local ctlChampion = GetControl(control, "Champion")

	-- , playerX, playerY
	local now = self.list.now
	if rowData.parts then
		local parts = rowData.parts
		for i = 1, 11 do parts[i] = tonumber(parts[i]) end
		rowData.parts = nil
		rowData.data = parts
	end
	local timeStamp, alliance, level, cp, rank, race, classId, zone, playerX, playerY, count, note = unpack(rowData.data)
	rowData.note = note

	local contactQuality = self:GetQualityFromCount(count)
	rowData.color = GetItemQualityColor(contactQuality)

	ZO_SortFilterList.SetupRow(self, control, rowData)

	ctlDisplayName:SetText(rowData.displayName)

	local lastSeen = now - timeStamp
	if lastSeen < 60 then
		lastSeen = string.format("%is", lastSeen)
	elseif lastSeen < 3600 then
		lastSeen = string.format("%im", zo_floor(lastSeen / 60))
	elseif lastSeen < 86400 then
		lastSeen = string.format("%ih", zo_floor(lastSeen / 3600))
	elseif lastSeen < 604800 then
		lastSeen = string.format("%id", zo_floor(lastSeen / 86400))
	else
		lastSeen = string.format("%iw", zo_floor(lastSeen / 604800))
	end
	ctlStatus:SetText(lastSeen)

	ctlZone:SetText(zo_strformat(SI_ZONE_NAME, GetZoneNameByIndex(GetZoneIndex(zone))))

	ctlLevel:SetText(GetLevelOrChampionPointsStringNoIcon(level, cp))

	if cp and cp > 0 then
		ctlChampion:SetTexture(GetChampionPointsIconSmall())
	else
		ctlChampion:SetHidden(true)
	end

	local allianceTexture = GetAllianceSymbolIcon(alliance)
	if allianceTexture then
		ctlAlliance:SetTexture(allianceTexture)
	else
		ctlAlliance:SetHidden(true)
	end

	local classTexture = GetClassIcon(classId)
	if classTexture then
		ctlClass:SetTexture(classTexture)
	else
		ctlClass:SetHidden(true)
	end

	local ctlNote = GetControl(control, "Note")
	if ctlNote then
		ctlNote:SetHidden(not note or #note == 0)
	end
end

function addon:GetSearchTerm()
	return self.searchBox:GetText()
end

function addon:OnSearchTextChanged()
	ZO_EditDefaultText_OnTextChanged(self.searchBox)
	self:RefreshFilters()
end

do
	local rowdata
	local function noteEditedFunction(self, displayName, note)
		local timeStamp, alliance, level, cp, rank, race, classId, zone, playerX, playerY, count, oldnote = self:GetParts(self.recentList.RecentInteractions[displayName])
		if oldnote ~= note then
			self.recentList.RecentInteractions[displayName] = self:CreateParts(timeStamp, alliance, level, cp, rank, race, classId, zone, playerX, playerY, count, note)
			rowdata.parts = { timeStamp, alliance, level, cp, rank, race, classId, zone, playerX, playerY, count, note }
			rowdata.data = nil
			self:RefreshVisible()
		end
	end
	function addon:GetNoteEditedFunction(control)
		rowdata = ZO_ScrollList_GetData(control:GetParent())
		return function(displayName, note) return noteEditedFunction(self, displayName, note) end
	end
end

function addon:UnlockSelection()
	ZO_SortFilterList.UnlockSelection(self)
	self:RefreshVisible()
end

local charNameToDisplayName = { }
addon.charNameToDisplayName = charNameToDisplayName
local needResolveName

do
	local lastRawUnitName
	local lastContact = { }
	function addon:GetPlayerInfo(unitTag)
		local unitType = GetUnitType(unitTag)
		if unitType ~= UNIT_TYPE_PLAYER then return false end

		local name = GetUnitDisplayName(unitTag)
		if name == "" or name == lastRawUnitName then return false end
		lastRawUnitName = name
		charNameToDisplayName[GetRawUnitName(unitTag)] = name

		local timeStamp = GetTimeStamp()
		if (timeStamp -(lastContact[name] or 0)) < 60 then return false end

		lastContact[name] = timeStamp

		local level = GetUnitLevel(unitTag)
		local cp = GetUnitChampionPoints(unitTag)
		local alliance = GetUnitAlliance(unitTag)
		local zone = GetZoneId(GetUnitZoneIndex(unitTag))
		local rank = GetUnitAvARank(unitTag)
		local race = GetUnitRaceId(unitTag)
		local classId = GetUnitClassId(unitTag)

		local playerX, playerY = gps:LocalToGlobal(GetMapPlayerPosition("player"))

		return timeStamp, alliance, name, level, cp, rank, race, classId, zone, playerX, playerY
	end
	EVENT_MANAGER:RegisterForEvent(addon.name .. "LastContact", EVENT_PLAYER_ACTIVATED, function() ZO_ClearNumericallyIndexedTable(lastContact) end)
end

local function WatchReticle()
	local unitTag = "reticleover"
	local function OnReticleChanged()
		local timeStamp, alliance, name, level, cp, rank, race, classId, zone, playerX, playerY = addon:GetPlayerInfo(unitTag)
		if not timeStamp then
			return
		end
		local note, count
		local prevData = addon.recentList.RecentInteractions[name]
		local sourceName = GetRawUnitName(unitTag)
		if prevData then
			local p_timestamp, _, _, _, _, _, _, p_zone, p_playerX, p_playerY, p_count, p_note = addon:GetParts(prevData)

			p_timestamp = tonumber(p_timestamp)
			-- contact less then one minute ago
			if (timeStamp - p_timestamp) < 60 then return end

			-- keep more interesting zone
			-- if GetMapContentType() == MAP_CONTENT_NONE or GetMapType() == MAPTYPE_SUBZONE then
			-- 	zone, playerX, playerY = tonumber(p_zone), tonumber(p_playerX), tonumber(p_playerY)
			-- end
			note, count = p_note, tonumber(p_count) + 1
			if needResolveName[sourceName] then
				if not note or note == "" then note = "PvP Arsch" end
				needResolveName[sourceName] = nil
			end
		else
			count = 1
			note = needResolveName[sourceName] and "PvP Arsch" or ""
			needResolveName[sourceName] = nil
		end
		addon.recentList.RecentInteractions[name] = addon:CreateParts(timeStamp, alliance, level, cp, rank, race, classId, zone, playerX, playerY, count, note)
	end
	EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_RETICLE_TARGET_CHANGED, OnReticleChanged)

--	local myName = GetRawUnitName("player")
--	local function OnCombatEvent(event, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
--		d(result, sourceName, targetName, myName)
--		if not sourceName or sourceName == "" or targetName ~= myName then return end
--		--if result ~= ACTION_RESULT_TARGET_DEAD and result ~= ACTION_RESULT_KILLING_BLOW then return end
--		local displayName = charNameToDisplayName[sourceName]
--		if not displayName then
--			needResolveName[sourceName] = true
--			df("%s queued for name resolve", sourceName)
--			return
--		end
--		local info = addon.recentList.RecentInteractions[displayName]
--		if not info then
--			d("not added nil")
--			return
--		end
--		if info[#info] == ":" then
--			addon.recentList.RecentInteractions[displayName] = info .. "PvP Arsch"
--			df("ass detected: %s", displayName)
--		else
--			d("not added", info[#info])
--		end
--	end

--	local id1 = "VotansContactListCombat1"
--	local id2 = "VotansContactListCombat2"
--	EVENT_MANAGER:RegisterForEvent(id1, EVENT_COMBAT_EVENT, OnCombatEvent)
--	EVENT_MANAGER:AddFilterForEvent(id1, EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_TARGET_DEAD)
--	--EVENT_MANAGER:AddFilterForEvent(id1, EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_TARGET_DEAD, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
--	EVENT_MANAGER:RegisterForEvent(id2, EVENT_COMBAT_EVENT, OnCombatEvent)
--	EVENT_MANAGER:AddFilterForEvent(id2, EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_KILLING_BLOW)
--	--EVENT_MANAGER:AddFilterForEvent(id2, EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_KILLING_BLOW, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)

	local reticleUnitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
	local parent = reticleUnitFrame:GetPrimaryControl()
	local control = WINDOW_MANAGER:CreateControl("$(parent)ContactNote", parent, CT_LABEL)
	control:SetAnchor(TOP, nil, BOTTOM, 0, 300)
	control:SetFont("ZoFontGamepadBold27")
	control:SetDimensionConstraints(0, 0, 400, 200)

	local orgUpdateName = reticleUnitFrame.UpdateName
	function reticleUnitFrame:UpdateName()
		orgUpdateName(self)
		if self.nameLabel then
			local tag = self.unitTag
			if tag and IsUnitPlayer(tag) then
				local displayName = GetUnitDisplayName(tag)
				local data = addon.recentList.RecentInteractions[displayName]
				if data then
					local count, note = select(11, addon:GetParts(data))
					local contactQuality = addon:GetQualityFromCount(tonumber(count))
					local name = self.nameLabel:GetText()
					name = GetItemQualityColor(contactQuality):Colorize(name)
					self.nameLabel:SetText(name)
					control:SetText(note)
					return
				end
			end
			control:SetText("")
		end
	end
end

local function RemoveOldData(task)
	local limit = GetTimeStamp() -30 * 24 * 60 * 60
	local pattern = "^([^:]+)"
	local recent = addon.recentList.RecentInteractions
	task:For(pairs(recent)):Do( function(name, data)
		local timestamp = tonumber(data:match(pattern))
		if timestamp < limit then recent[name] = nil end
	end )
end

----------------- Settings -----------------------
function addon:SetupSettings()
	-- local LAM2 = LibStub("LibAddonMenu-2.0")
	-- if not LAM2 then return end

	-- local panelData = {
	-- 	type = "panel",
	-- 	name = addon.title,
	-- 	displayName = addon.title,
	-- 	author = "votan",
	-- 	version = "1.0.11",
	-- 	-- slashCommand = "",
	-- 	-- registerForRefresh = true,
	-- 	registerForDefaults = true,
	-- }
	-- LAM2:RegisterAddonPanel(addon.name, panelData)

	-- local optionsTable = {

	-- }
	-- LAM2:RegisterOptionControls(addon.name, optionsTable)
end

function addon:InitializeKeybindDescriptors()
	if self.keybindStripDescriptor then return end

	self.keybindStripDescriptor =
	{
		alignment = KEYBIND_STRIP_ALIGN_CENTER,

		-- Whisper
		{
			name = GetString(SI_SOCIAL_LIST_PANEL_WHISPER),
			keybind = "UI_SHORTCUT_PRIMARY",

			callback = function()
				local data = GetData(self.mouseOverRow)
				StartChatInput("", CHAT_CHANNEL_WHISPER, data.displayName)
			end,

			visible = function()
				if self.mouseOverRow and IsChatSystemAvailableForCurrentPlatform() then
					local data = GetData(self.mouseOverRow)
					return data.displayName
				end
				return false
			end
		},

		-- Invite to Group
		{
			name = GetString(SI_FRIENDS_LIST_PANEL_INVITE),
			keybind = "UI_SHORTCUT_SECONDARY",

			callback = function()
				local data = ZO_ScrollList_GetData(self.mouseOverRow)
				local NOT_SENT_FROM_CHAT = false
				local DISPLAY_INVITED_MESSAGE = true
				TryGroupInviteByName(data.characterName, NOT_SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE)
			end,

			visible = function()
				if IsGroupModificationAvailable() and self.mouseOverRow then
					local data = ZO_ScrollList_GetData(self.mouseOverRow)
					if data.hasCharacter and data.online then
						return true
					end
				end
				return false
			end
		},
		-- Add Friend
		{
			name = GetString(SI_FRIENDS_LIST_PANEL_ADD_FRIEND),
			keybind = "UI_SHORTCUT_TERTIARY",

			callback = function()
				local rowData = GetData(self.mouseOverRow)
				if rowData.displayName ~= "" then
					RequestFriend(rowData.displayName, "")
				end
			end,

			visible = function()
				if self.mouseOverRow then
					return true
				end
				return false
			end,
		},
		-- Show On Map
		{
			name = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
			keybind = "UI_SHORTCUT_SHOW_QUEST_ON_MAP",

			callback = function()
				if self.mouseOverRow then
					local rowData = GetData(self.mouseOverRow)
					local playerX, playerY = select(9, unpack(rowData.data))

					local function ClickToPosition()
						playerX, playerY = tonumber(playerX), tonumber(playerY)

						gps:SetPlayerChoseCurrentMap()

						local result = gps:MapZoomInMax(playerX, playerY)
						CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
						local x, y = gps:GlobalToLocal(playerX, playerY)
						PingMap(MAP_PIN_TYPE_RALLY_POINT, MAP_TYPE_LOCATION_CENTERED, x, y)
					end
					if not ZO_WorldMap_IsWorldMapShowing() then
						if IsInGamepadPreferredMode() then
							local name = GAMEPAD_WORLD_MAP_SCENE:GetName()
							SCENE_MANAGER:CallWhen(name, SCENE_SHOWN, ClickToPosition)
							SCENE_MANAGER:Push(name)
						else
							local name = WORLD_MAP_SCENE:GetName()
							SCENE_MANAGER:CallWhen(name, SCENE_SHOWN, ClickToPosition)
							MAIN_MENU_KEYBOARD:ShowCategory(MENU_CATEGORY_MAP)
						end
					else
						ClickToPosition()
					end

				end
			end,

			visible = function() return self.mouseOverRow end
		},

	}
end

--------------- End Settings ---------------------

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	-- addon.settings = ZO_SavedVars:NewAccountWide("VotansTakeOne_Data", 1, nil, addon.defaults)

	-- addon:SlashCommand()
	-- addon:AddKeyBind()
	-- addon:SetupSettings()

	local defaults = { itemFormatVersion = 1, NeedResolveName = { }, RecentInteractions = { } }
	addon.recentList = ZO_SavedVars:New("VotansContactList_Data", 1, nil, defaults, GetWorldName(), "$Machine", "$UserProfileWide")

	needResolveName = addon.recentList.NeedResolveName

	async:Call(RemoveOldData):Then(WatchReticle)
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_CONTACT_LIST = addon
