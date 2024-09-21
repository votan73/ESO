local name = "VotanSearchBox"
local glass = " |t40:40:/esoui/art/tutorial/gamepad/gp_inventory_trait_not_researched_icon.dds|t"

local templateName = "ZO_InventorySearchTemplate"

local wm = GetWindowManager()
local LTF = LibTextFilter

local function AddLowercase(lower, name)
	if name and type(name) == "string" then
		if name:find("^|[hH]") then
			name = GetItemLinkName(name)
		end
		lower[#lower + 1] = ZO_CachedStrFormat("<<z:1>>", name, 1)
	else
		lower[#lower + 1] = name
	end
end

local function VotanSearchBoxMouseDown(bagSearch, button)
	if not bagSearch:HasFocus() and button == MOUSE_BUTTON_INDEX_RIGHT then
		bagSearch:SetText("")
	end
end

local function FindMostRightControl(parent)
	local x = -1
	local control, result
	for i = 1, parent:GetNumChildren() do
		control = parent:GetChild(i)
		if x < control:GetRight() then
			result, x = control, control:GetRight()
		end
	end
	return result
end

local function setDefaultText(control, text)
	control:SetDefaultText(text)
end

local function SetupSearchBox(bagSearchBg)
	local bagSearch = bagSearchBg:GetNamedChild("Box")
	local bagSearchTx = bagSearch:GetNamedChild("Text")
	local closeButton = wm:CreateControlFromVirtual(nil, bagSearchBg, "ZO_CloseButton")
	bagSearch.background = bagSearchBg

	local textWidth = 170
	local function VotanSearchBoxFocusGained(bagSearch)
		setDefaultText(bagSearch, "")
		bagSearchBg:SetAlpha(0.25)
		bagSearchBg:SetWidth(textWidth)
		closeButton:SetHidden(false)
		return false
	end
	local function VotanSearchBoxFocusLost(bagSearch, ...)
		local text = bagSearch:GetText()
		if text ~= "" then
			bagSearchBg:SetAlpha(0.25)
			bagSearchBg:SetWidth(textWidth)
			closeButton:SetHidden(false)
		else
			bagSearchBg:SetAlpha(0)
			bagSearchBg:SetWidth(64)
			closeButton:SetHidden(true)
		end
		setDefaultText(bagSearch, glass)

		return false
	end
	local function VotanSearchBoxTextChanged(control, ...)
		if wm:GetFocusControl() ~= bagSearch then
			return VotanSearchBoxFocusLost(control, ...)
		end
		return false
	end
	local function VotanSearchBoxCloseClick(control, ...)
		bagSearch:SetText("")
		bagSearch:GetHandler("OnFocusLost")(bagSearch)
		PlaySound(SOUNDS.DEFAULT_CLICK)
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

	ZO_PreHookHandler(bagSearch, "OnMouseDown", VotanSearchBoxMouseDown)
	ZO_PreHookHandler(bagSearch, "OnFocusGained", VotanSearchBoxFocusGained)
	ZO_PreHookHandler(bagSearch, "OnFocusLost", VotanSearchBoxFocusLost)
	ZO_PreHookHandler(bagSearch, "OnTextChanged", VotanSearchBoxTextChanged)
end

---- Guild History Window ----

do
	local lowercaseParams = {}
	local lower = {}
	SecurePostHook(
		ZO_GuildHistoryEventData_Base,
		"InternalRefreshText",
		function(self, isGamepad, enumPrefix, ...)
			local eventInfo = self:GetEventInfo()
			if eventInfo.isRedacted then
				eventInfo.votanSearchText = ""
				return
			end

			local formatString = GetString(enumPrefix, eventInfo.eventType)

			ZO_ClearNumericallyIndexedTable(lower)
			local numArgs = select("#", ...)
			if numArgs > 0 then
				ZO_ClearNumericallyIndexedTable(lowercaseParams)
				for i = 1, numArgs do
					local param = select(i, ...)
					AddLowercase(lowercaseParams, param)
				end
				AddLowercase(lower, zo_strformat(formatString, unpack(lowercaseParams)))
			else
				AddLowercase(lower, formatString)
			end

			AddLowercase(lower, ZO_FormatDurationAgo(GetTimeStamp32() - self:GetEventTimestampS()))

			eventInfo.votanSearchText = table.concat(lower, " ")
		end
	)
end

local function AddGuildHistory()
	local GuildHistoryManager = GUILD_HISTORY_KEYBOARD

	local parent = GuildHistoryManager.control

	local bagSearch = wm:CreateControlFromVirtual("$(parent)VotanSearch", parent, templateName)
	local cachedSearchTerm = ""
	local function OnTextChanged(self)
		ZO_EditDefaultText_OnTextChanged(self)
		cachedSearchTerm = self:GetText():lower()
		if not parent:IsControlHidden() then
			return GuildHistoryManager:RefreshData()
		end
	end
	bagSearch:GetNamedChild("Box"):SetHandler("OnTextChanged", OnTextChanged)

	SetupSearchBox(bagSearch)
	bagSearch:ClearAnchors()
	bagSearch:SetAnchor(LEFT, FindMostRightControl(ZO_GuildSharedInfo), RIGHT, 5, 0)

	ZO_PreHook(
		ZO_GuildHistoryEventData_Base,
		"GetUISubcategoryIndex",
		function(self)
			if #cachedSearchTerm > 0 then
				local eventInfo = self:GetEventInfo()

				if not eventInfo.votanSearchText then
					self:GetText(false) -- Force creating text. Normally done for visible rows only.
				end
				return not LTF:Filter(eventInfo.votanSearchText, cachedSearchTerm)
			end
		end
	)
end

---- Guild Browser ----
local function AddGuildBrowser()
	local parent = ZO_GuildBrowser_GuildList_Keyboard_TopLevelList
	local bagSearch = wm:CreateControlFromVirtual("$(parent)VotanSearch", ZO_GuildBrowser_GuildList_Keyboard_TopLevel, templateName)
	local bagSearchBox = bagSearch:GetNamedChild("Box")
	local cachedSearchTerm, lastSearchTerm = "", ""
	local function OnTextChanged(self)
		ZO_EditDefaultText_OnTextChanged(self)
		cachedSearchTerm = self:GetText():lower()
	end
	ZO_PreHookHandler(
		bagSearchBox,
		"OnFocusLost",
		function(control)
			if cachedSearchTerm ~= lastSearchTerm then
				GUILD_BROWSER_GUILD_LIST_KEYBOARD:RefreshActivitiesFilter()
				GUILD_BROWSER_MANAGER:ExecuteSearch()
			end
		end
	)
	SetupSearchBox(bagSearch)
	bagSearchBox:SetHandler("OnTextChanged", OnTextChanged)
	bagSearch:ClearAnchors()
	bagSearch:SetAnchor(BOTTOMLEFT, parent, TOPLEFT, 0, -78)
	local orgCurrentFoundGuildsListIterator = GUILD_BROWSER_MANAGER.CurrentFoundGuildsListIterator
	function GUILD_BROWSER_MANAGER.CurrentFoundGuildsListIterator(...)
		lastSearchTerm = cachedSearchTerm
		local iterator, tab, i = orgCurrentFoundGuildsListIterator(...)
		return function(...)
			if cachedSearchTerm == "" then
				return iterator(...)
			end
			local guildId, searchText, guildData
			repeat
				i, guildId = iterator(tab, i)
				if not i then
					return i, guildId
				end
				guildData = GUILD_BROWSER_MANAGER:GetGuildData(guildId)
				searchText = zo_strlower(string.format("%s %s %s %s %s %s", guildData.guildName or "", ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(guildData.alliance)), guildData.recruitmentMessage or "", guildData.activitiesText or "", guildData.guildTraderText or "", guildData.headerMessage or ""))
			until LTF:Filter(searchText, cachedSearchTerm)
			return i, guildId
		end, tab, i
	end
end

---- Init ----

local identifier = "VotanSearchBoxGuildHistory"

local function Initialize(eventType, addonName)
	if addonName ~= name then
		return
	end

	SecurePostHook(
		ZO_GuildHistory_Keyboard,
		"OnDeferredInitialize",
		function()
			AddGuildHistory()
			AddGuildBrowser()
		end
	)
	EVENT_MANAGER:UnregisterForEvent(identifier, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(identifier, EVENT_ADD_ON_LOADED, Initialize)
