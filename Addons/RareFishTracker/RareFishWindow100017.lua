local wm = GetWindowManager()
if RFT == nil then
	RFT = {}
end

local RFT = RFT

RFT.KatKat42Colors = {
	ZO_ColorDef:New(.3, .5, .3, 1),
	ZO_ColorDef:New(.6, 1, .6, 1),
	ZO_ColorDef:New(.25, .25, 0.5, 1),
	ZO_ColorDef:New(.5, .5, 1, 1),
	ZO_ColorDef:New(.5, .25, 0.5, 1),
	ZO_ColorDef:New(1, .5, 1, 1)
}
RFT.KatKat42Default = ZO_ColorDef:New(.9, .9, .7, 1)
RFT.KatKat42Highlight = ZO_ColorDef:New(.8, .8, 1, 1)
RFT.ESODefault = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
RFT.ESOHighlight = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_ENABLED))

function RFT:RestorePosition()
	local rft = self.window
	local x, y, r, b = rft:GetLeft(), rft:GetTop(), rft:GetRight(), rft:GetBottom()
	local cx, cy = GuiRoot:GetCenter()
	local settings = self.settings

	local tx, ty, tr, tb
	if RFT.IsShowingWorldMap() then
		tx, ty, tr, tb = settings.x_world, settings.y_world, settings.right_world, settings.bottom_world
	else
		tx, ty, tr, tb = settings.x, settings.y, settings.right, settings.bottom
	end

	local isLeft, isTop = tx < cx, ty < cy
	rft:ClearAnchors()
	if isLeft and isTop then
		rft:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
		x, y = tx - x, ty - y
	elseif isLeft then
		rft:SetAnchor(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, x, b - GuiRoot:GetHeight())
		x, y = tx - x, tb - b
	elseif isTop then
		rft:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, r - GuiRoot:GetWidth(), y)
		x, y = tr - r, ty - y
	else
		rft:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, r - GuiRoot:GetWidth(), b - GuiRoot:GetHeight())
		x, y = tr - r, tb - b
	end

	local slide = rft.slide
	slide:SetDeltaOffsetX(x)
	slide:SetDeltaOffsetY(y)
	rft.slideAmin:PlayFromStart()
end

function RFT:SetIsFishing(isFishing)
	self.isFishing = isFishing
	RARE_FISH_TRACKER_FRAGMENT:Refresh(500, 500)
end

local orgGetCurrentMapZoneIndex = GetCurrentMapZoneIndex
local function GetCurrentMapZoneIndex()
	local zoneIndex = orgGetCurrentMapZoneIndex()
	-- some maps are bugged, i.e. vaults of madness returns the index of coldharbor
	if DoesCurrentMapMatchMapForPlayerLocation() then
		zoneIndex = GetUnitZoneIndex("player")
	end
	return zoneIndex
end

local function IsScreenRightHalf(sender)
	local x = GuiRoot:GetCenter()
	return sender:GetLeft() > x
end

local function IsScreenLowerHalf(sender)
	local _, y = GuiRoot:GetCenter()
	return sender:GetTop() > y
end

function RFT.ShowTooltip(resultButton, state)
	if state and resultButton.itemId then
		local itemLink = resultButton.itemLink
		if not itemLink then
			itemLink = string.format("|H1:item:%i:27:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0|h|h", resultButton.itemId)
			resultButton.itemLink = itemLink
		end

		if IsScreenRightHalf(resultButton) then
			if IsScreenLowerHalf(resultButton) then
				InitializeTooltip(ItemTooltip, resultButton, TOPRIGHT, 0, 0, BOTTOMLEFT)
			else
				InitializeTooltip(ItemTooltip, resultButton, TOPRIGHT, 0, 0, TOPLEFT)
			end
		else
			if IsScreenLowerHalf(resultButton) then
				InitializeTooltip(ItemTooltip, resultButton, BOTTOMLEFT, 0, 0, TOPRIGHT)
			else
				InitializeTooltip(ItemTooltip, resultButton, TOPLEFT, 0, 0, TOPRIGHT)
			end
		end
		ItemTooltip:SetLink(itemLink)
	else
		ClearTooltip(ItemTooltip)
	end
end

if IsConsoleUI() then
	function RFT.IsShowingWorldMap()
		return GAMEPAD_WORLD_MAP_SCENE:IsShowing() or (LibHarvensAddonSettings.scene and LibHarvensAddonSettings.scene:IsShowing() and RFT.moveForWorldMap)
	end
else
	function RFT.IsShowingWorldMap()
		return WORLD_MAP_SCENE:IsShowing()
	end
end

function RFT.MakeWindow()
	local account = RFT.account

	local function SetupWaterType(control)
		local alpha = account.waterTypeAlpha / 100
		control:SetExcludeFromResizeToFitExtents(true)
		control:SetAnchor(TOPLEFT, nil, TOPLEFT, -10, -10)
		control:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, 10, 10)
		control:SetCenterColor(0, 0, 0, alpha)
		control:SetEdgeColor(0, 0, 0, alpha)
		control:SetEdgeTexture("esoui/art/chatwindow/chat_bg_edge.dds", 256, 256, 24)
		control:SetCenterTexture("esoui/art/chatwindow/chat_bg_center.dds")
		control:SetInsets(24, 24, -24, -24)
	end

	local function LabelFactory(pool)
		local id = pool:GetNextControlId()
		local lastControl = pool.parent:GetChild(pool.parent:GetNumChildren()) or pool.parent
		local item = wm:CreateControlFromVirtual("$(parent)Item" .. id, pool.parent, "RareFishTrackerItem")
		local label = item:GetNamedChild("Label")
		local bg = item:GetNamedChild("Bg")
		local icon = item:GetNamedChild("Icon")
		item.label = label
		item.backdrop = bg
		item.icon = icon
		item.index = id

		-- esoui/art/champion/champion_center_bg.dds
		item.backdrop:SetTexture("esoui/art/crafting/universalstyle_rowbackground.dds")
		item.icon:SetDesaturation(0.5)
		-- item.icon:SetColor(0.75, 0.75, 0.75)

		label:SetStyleColor(0, 0, 0, 1)

		item:SetHandler(
			"OnMouseEnter",
			function(sender)
				RFT.ShowTooltip(sender, true)
			end
		)
		item:SetHandler(
			"OnMouseExit",
			function(sender)
				RFT.ShowTooltip(sender, false)
			end
		)
		item:SetMouseEnabled(true)

		return item
	end

	-- our primary window
	RFT.window = wm:CreateTopLevelWindow("RareFishTracker")
	local rft = RFT.window
	rft:SetHidden(true)
	rft:SetMovable(true)
	rft:SetMouseEnabled(true)
	rft:SetClampedToScreen(true)
	rft:SetClampedToScreenInsets(16, 0, -16, 0)
	rft:SetDimensions(0, 0)
	rft:SetResizeToFitDescendents(true)

	local function GetPosition()
		return rft:GetLeft(), rft:GetTop(), rft:GetRight(), rft:GetBottom()
	end
	local function SetPosition(x, y, r, b)
		local cx, cy = GuiRoot:GetCenter()
		local isLeft, isTop = x < cx, y < cy
		rft:ClearAnchors()
		if isLeft and isTop then
			rft:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
		elseif isLeft then
			rft:SetAnchor(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, x, b - GuiRoot:GetHeight())
		elseif isTop then
			rft:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, r - GuiRoot:GetWidth(), y)
		else
			rft:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, r - GuiRoot:GetWidth(), b - GuiRoot:GetHeight())
		end
	end
	local function OnMoveStop()
		if account.lockPosition then
			return
		end
		local settings = RFT.settings
		if RFT.IsShowingWorldMap() then
			settings.x_world, settings.y_world, settings.right_world, settings.bottom_world = GetPosition()
			SetPosition(settings.x_world, settings.y_world, settings.right_world, settings.bottom_world)
		else
			settings.x, settings.y, settings.right, settings.bottom = GetPosition()
			SetPosition(settings.x, settings.y, settings.right, settings.bottom)
		end
	end
	rft:SetHandler("OnMoveStop", OnMoveStop)
	rft:SetDrawLayer(DL_CONTROLS)
	rft:SetDrawLevel(3)
	local am = GetAnimationManager()
	rft.slideAmin = am:CreateTimelineFromVirtual("ZO_LootSlideInAnimation", rft)
	rft.slide = rft.slideAmin:GetFirstAnimation()
	local function OnAnimStop()
		local settings = RFT.settings
		if RFT.IsShowingWorldMap() then
			SetPosition(settings.x_world, settings.y_world, settings.right_world, settings.bottom_world)
		else
			SetPosition(settings.x, settings.y, settings.right, settings.bottom)
		end
	end
	rft.slideAmin:SetHandler("OnStop", OnAnimStop)

	RFT.settings.right, RFT.settings.bottom = RFT.settings.right or (RFT.settings.x + rft:GetWidth()), RFT.settings.bottom or (RFT.settings.y + rft:GetHeight())
	RFT.settings.right_world, RFT.settings.bottom_world = RFT.settings.right_world or (RFT.settings.x_world + rft:GetWidth()), RFT.settings.bottom_world or (RFT.settings.y_world + rft:GetHeight())

	SetPosition(RFT.settings.x, RFT.settings.y, RFT.settings.right, RFT.settings.bottom)
	RFT:RestorePosition()

	rft:SetMouseEnabled(not account.lockPosition)

	-- give it a backdrop
	rft.bg = wm:CreateControl("RFTBackground", rft, CT_BACKDROP)
	rft.bg:SetDrawLayer(DL_BACKGROUND)
	rft.bg:SetAnchorFill(rft)
	rft.bg:SetCenterColor(0, 0, 0, account.alpha / 100)
	rft.bg:SetEdgeColor(0, 0, 0, account.alpha / 100)
	-- rft.bg:SetEdgeTexture("EsoUI/Art/ChatWindow/chat_BG_edge.dds", 256, 128, 16)
	-- rft.bg:SetCenterTexture("EsoUI/Art/ChatWindow/chat_BG_center.dds")
	rft.bg:SetInsets(16, 16, -16, -16)
	rft.bg:SetExcludeFromResizeToFitExtents(true)
	-- rft.bg:SetDrawLayer(DL_TEXT)

	rft.bgtex = wm:CreateControl("RFTBackgroundoverlay", rft.bg, CT_TEXTURE)
	rft.bgtex:SetTexture("/esoui/art/tooltips/munge_overlay.dds")
	rft.bgtex:SetAlpha(account.alpha / 100)
	rft.bgtex:SetAnchor(TOPLEFT, rft.bg, TOPLEFT, 8, 8)
	rft.bgtex:SetAnchor(BOTTOMRIGHT, rft.bg, BOTTOMRIGHT, -8, -8)
	rft.bgtex:SetDrawLayer(DL_BACKGROUND)

	-- give it a header
	rft.title = wm:CreateControl("RFTTitle", rft, CT_LABEL)
	rft.title:SetAnchor(TOP, rft, TOP, 0, 5)
	rft.title:SetStyleColor(0, 0, 0, 1)
	rft.title:SetText("Rare Fish Tracker")
	rft.title:SetHidden(not account.showtitle)

	-- Give it a zone label
	rft.zone = wm:CreateControl("RFTZone", rft, CT_LABEL)
	if (account.showtitle) then
		rft.zone:SetAnchor(TOP, rft.title, BOTTOM, 0, 5)
	else
		rft.zone:SetAnchor(TOP, rft, TOP, 0, 5)
	end
	rft.zone:SetStyleColor(0, 0, 0, 1)
	rft.zone:SetText("Zone Name")
	rft.zone:SetHidden(not account.showzone)

	-- make a container for the list entries
	rft.entries = wm:CreateControl("RFTEntries", rft, CT_CONTROL)
	-- rft.entries = wm:CreateControl("RFTEntries", rft, CT_TEXTURE)
	rft.entries:SetAnchor(TOP, rft.zone, BOTTOM, 0, 0)
	-- rft.entries:SetTexture([[/esoui/art/buttons/swatchframe_up.dds]])
	rft.entries:SetHidden(false)
	rft.entries:SetResizeToFitDescendents(true)

	-- make sub-containers for each water type
	-- Ocean fish
	rft.entries.ocean = wm:CreateControl("RFTOcean", rft.entries, CT_CONTROL)
	rft.entries.ocean:SetAnchor(TOPLEFT, rft.entries, TOPLEFT, 0, 0)
	rft.entries.ocean:SetHidden(false)
	rft.entries.ocean:SetResizeToFitDescendents(true)
	rft.entries.ocean:SetResizeToFitPadding(2, 0)

	rft.entries.ocean.bd = wm:CreateControl("$(parent)BD", rft.entries.ocean, CT_BACKDROP)
	SetupWaterType(rft.entries.ocean.bd)

	rft.entries.ocean.label = wm:CreateControl("RFTOceanLabel", rft.entries.ocean, CT_LABEL)
	rft.entries.ocean.label:SetAnchor(TOP, rft.entries.ocean, TOP, 0, 0)
	rft.entries.ocean.label:SetStyleColor(0, 0, 0, 1)
	rft.entries.ocean.label:SetText("Ocean")

	-- lake fish
	rft.entries.lake = wm:CreateControl("RFTLake", rft.entries, CT_CONTROL)
	rft.entries.lake:SetAnchor(TOPLEFT, rft.entries.ocean, TOPRIGHT, 5, 0)
	rft.entries.lake:SetHidden(false)
	rft.entries.lake:SetResizeToFitDescendents(true)
	rft.entries.lake:SetResizeToFitPadding(2, 0)

	rft.entries.lake.bd = wm:CreateControl("$(parent)BD", rft.entries.lake, CT_BACKDROP)
	SetupWaterType(rft.entries.lake.bd)

	rft.entries.lake.label = wm:CreateControl("RFTLakeLabel", rft.entries.lake, CT_LABEL)
	rft.entries.lake.label:SetAnchor(TOP, rft.entries.lake, TOP, 0, 0)
	rft.entries.lake.label:SetStyleColor(0, 0, 0, 1)
	rft.entries.lake.label:SetText("Lake")

	-- river fish
	rft.entries.river = wm:CreateControl("RFTRiver", rft.entries, CT_CONTROL)
	rft.entries.river:SetAnchor(TOPLEFT, rft.entries.lake, TOPRIGHT, 5, 0)
	rft.entries.river:SetHidden(false)
	rft.entries.river:SetResizeToFitDescendents(true)
	rft.entries.river:SetResizeToFitPadding(2, 0)

	rft.entries.river.bd = wm:CreateControl("$(parent)BD", rft.entries.river, CT_BACKDROP)
	SetupWaterType(rft.entries.river.bd)

	rft.entries.river.label = wm:CreateControl("RFTRiverLabel", rft.entries.river, CT_LABEL)
	rft.entries.river.label:SetAnchor(TOP, rft.entries.river, TOP, 0, 0)
	rft.entries.river.label:SetStyleColor(0, 0, 0, 1)
	rft.entries.river.label:SetText("River")

	-- foul water fish
	rft.entries.foul = wm:CreateControl("RFTFoul", rft.entries, CT_CONTROL)
	rft.entries.foul:SetAnchor(TOPLEFT, rft.entries.river, TOPRIGHT, 5, 0)
	rft.entries.foul:SetHidden(false)
	rft.entries.foul:SetResizeToFitDescendents(true)

	rft.entries.foul.bd = wm:CreateControl("$(parent)BD", rft.entries.foul, CT_BACKDROP)
	SetupWaterType(rft.entries.foul.bd)

	rft.entries.foul.label = wm:CreateControl("RFTFoulLabel", rft.entries.foul, CT_LABEL)
	rft.entries.foul.label:SetAnchor(TOP, rft.entries.foul, TOP, 0, 0)
	rft.entries.foul.label:SetStyleColor(0, 0, 0, 1)
	rft.entries.foul.label:SetText("Foul")

	-- add a bit of padding
	rft:SetResizeToFitPadding(30, 30)

	local function ControlReset(control, pool)
		control:SetHidden(true)
		control:ClearAnchors()
	end

	rft.column1 = ZO_ObjectPool:New(LabelFactory, ControlReset)
	rft.column1.parent = rft.entries.ocean
	rft.column2 = ZO_ObjectPool:New(LabelFactory, ControlReset)
	rft.column2.parent = rft.entries.lake
	rft.column3 = ZO_ObjectPool:New(LabelFactory, ControlReset)
	rft.column3.parent = rft.entries.river
	rft.column4 = ZO_ObjectPool:New(LabelFactory, ControlReset)
	rft.column4.parent = rft.entries.foul

	RFT.columns = {rft.entries.ocean, rft.entries.lake, rft.entries.river, rft.entries.foul}
	rft.labelPools = {rft.column1, rft.column2, rft.column3, rft.column4}

	local GetParentZoneId = GetZoneStoryZoneIdForZoneId or GetParentZoneId
	local function getPlayerZoneId()
		return GetZoneId(GetUnitZoneIndex("player"))
	end
	local function findZone(zone)
		local count = 4
		while not RFT.zoneToAchievement[zone] do
			if count == 0 or zone == 0 then
				break
			end
			zone = GetParentZoneId(zone)
			count = count - 1
		end
		return zone
	end
	local lastZoneId
	RARE_FISH_TRACKER_FRAGMENT = ZO_HUDFadeSceneFragment:New(rft, 500, 0)
	RARE_FISH_TRACKER_FRAGMENT:SetConditional(
		function()
			if RFT.IsShowingWorldMap() then
				if RFT.numFishes == nil or RFT.isAutoRefresh and RFT.numFishes == 0 then
					return false
				end
				return RFT.settings.shown_world
			else
				if RFT.numFishes == nil or IsUnitInCombat("player") then
					return false
				end
				if RFT.isFishing then
					return true
				end
				return RFT.settings.shown
			end
		end
	)
	local mapScene = IsConsoleUI() and GAMEPAD_WORLD_MAP_SCENE or WORLD_MAP_SCENE
	mapScene:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			-- If window is visible in both scenes, the state does not change => RestorePosition only
			if newState == SCENE_FRAGMENT_SHOWING then
				if RFT.settings.shown_world and not RFT.window:IsHidden() then
					RFT:RestorePosition()
				end
				RARE_FISH_TRACKER_FRAGMENT:Refresh()
			elseif newState == SCENE_FRAGMENT_HIDING then
				if (RFT.settings.shown or RFT.isFishing) and not RFT.window:IsHidden() then
					RFT:RestorePosition()
				end
			elseif newState == SCENE_FRAGMENT_HIDDEN then
				if not RFT.window:IsHidden() then
					RFT:RestorePosition()
				end
				RFT.RefreshWindowForZone(findZone(getPlayerZoneId()))
			end
		end
	)
	CALLBACK_MANAGER:RegisterCallback(
		"OnWorldMapChanged",
		function(navigateIn)
			if WORLD_MAP_FRAGMENT:IsShowing() then
				if navigateIn then
					-- from Cyrodiil down to IC?
					if GetCurrentMapIndex() == nil then
						return
					end
				end
				RFT.RefreshWindowForZone(findZone(GetZoneId(GetCurrentMapZoneIndex())))
			else
				RFT.RefreshWindowForZone(findZone(getPlayerZoneId()))
			end
		end
	)
	RARE_FISH_TRACKER_FRAGMENT:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				RFT:RestorePosition()
			end
		end
	)
	EVENT_MANAGER:RegisterForEvent(
		"RareFishTracker",
		EVENT_PLAYER_COMBAT_STATE,
		function()
			RARE_FISH_TRACKER_FRAGMENT:Refresh()
		end
	)

	HUD_SCENE:AddFragment(RARE_FISH_TRACKER_FRAGMENT)
	HUD_UI_SCENE:AddFragment(RARE_FISH_TRACKER_FRAGMENT)
	LOOT_SCENE:AddFragment(RARE_FISH_TRACKER_FRAGMENT)
	mapScene:AddFragment(RARE_FISH_TRACKER_FRAGMENT)

	RFT.MakeOrders()

	local colors = {}
	local function MakeColors(quality)
		local r, g, b = GetItemQualityColor(quality):UnpackRGB()
		colors[#colors + 1] = ZO_ColorDef:New(r * 0.5625, g * 0.5625, b * 0.5625)
		colors[#colors + 1] = ZO_ColorDef:New(r * 1.05, g * 1.05, b * 1.05)
	end
	MakeColors(ITEM_FUNCTIONAL_QUALITY_MAGIC)
	MakeColors(ITEM_FUNCTIONAL_QUALITY_ARCANE)
	MakeColors(ITEM_FUNCTIONAL_QUALITY_ARTIFACT)
	-- MakeColors(ITEM_FUNCTIONAL_QUALITY_LEGENDARY)
	colors[7] = RFT.KatKat42Colors[7]
	colors[8] = RFT.KatKat42Colors[8]
	RFT.ESOColors = colors
end

do
	local bigFont
	local normalFont

	if IsConsoleUI() then
		bigFont = "ZoFontGamepad22"
		normalFont = "ZoFontGamepad20"
	else
		bigFont = "ZoFontWinT2"
		normalFont = "ZoFontGameSmall"
	end

	function RFT.PopulateWindowForAchievement(achievement)
		local account = RFT.account

		local disp = account.highlight == "Caught" or false
		local numFishes = NonContiguousCount(RFT.progress[achievement])

		local numCaught = 0
		if numFishes > 0 then
			local smallFont = account.biggerFont and bigFont or normalFont
			local symbolSize = account.biggerFont and 40 or 32
			local itemSize = symbolSize + 8
			local backSize = itemSize + 8

			-- 0 = default fish order/quality
			local fishorder = RFT.orders[achievement] or RFT.orders[0]
			local fishquality = RFT.quality[achievement] or RFT.quality[0]
			local function AddColumn(index, fishName, icon)
				local caught = RFT.progress[achievement][fishName] == 1
				if caught then
					numCaught = numCaught + 1
				end
				-- WHY does lua not have an xor operator?!?!
				local normal = ((caught or disp) and not (caught and disp))
				local alpha = normal and account.captionAlphaNormal or account.captionAlphaHighlighted
				if alpha == 0 then
					return
				end

				alpha = alpha / 100

				local colorType = (fishquality[index] - ITEM_FUNCTIONAL_QUALITY_MAGIC) * 2 + 1
				local color = normal and RFT.Colors[colorType] or RFT.Colors[colorType + 1]
				local r, g, b = color:UnpackRGB()

				local item = fishorder[index]:AcquireObject()

				item:SetResizeToFitDescendents(false)
				item.itemId = RFT.achievementToItem[achievement][index]
				item.itemLink = nil
				item:SetMouseEnabled(item.itemId ~= nil)
				item.label:SetText("")
				item.icon:SetTexture("")
				item:SetDimensions(0, 0)

				if account.useSymbols then
					item.backdrop:SetColor(r, g, b, alpha * 0.7)
					item:SetAnchor(TOP, nil, TOP, 0, item.index * itemSize - 18)
					item.icon:SetDimensions(symbolSize, symbolSize)
					item.icon:SetTexture(icon)
					item.icon:SetAlpha(alpha)
					item.label:SetHidden(true)
					item.backdrop:SetDimensions(backSize, backSize)
					item.backdrop:SetHidden(false)
					item.icon:SetHidden(false)
				else
					item.label:SetFont(smallFont)
					item.label:SetColor(r, g, b, alpha)
					item.label:SetText(ZO_CachedStrFormat(SI_TOOLTIP_ITEM_NAME, fishName))
					item:SetAnchor(TOP, nil, TOP, 0, item.index * (item.label:GetHeight() + 5))
					item.label:SetHidden(false)
					item.backdrop:SetHidden(true)
					item.icon:SetHidden(true)
				end
				item:SetResizeToFitDescendents(true)
				item:SetHidden(false)
			end
			local fishes, icons = RFT.fishnames[achievement], RFT.fishIcons[achievement]
			for index, fishName in ipairs(fishes) do
				if (fishquality[index] == ITEM_FUNCTIONAL_QUALITY_ARCANE) then
					AddColumn(index, fishName, icons[index])
				end
			end
			for index, fishName in ipairs(fishes) do
				if (fishquality[index] == ITEM_FUNCTIONAL_QUALITY_MAGIC) then
					AddColumn(index, fishName, icons[index])
				end
			end
			for index, fishName in ipairs(fishes) do
				if (fishquality[index] == ITEM_FUNCTIONAL_QUALITY_ARTIFACT) then
					AddColumn(index, fishName, icons[index])
				end
			end
		else
			-- sub zones like dungeons
			numFishes = 0
		end
		return numCaught, numFishes
	end
end

do
	local bigFont
	local normalFont

	if IsConsoleUI() then
		bigFont = "ZoFontGamepad27"
		normalFont = "ZoFontGamepad22"
	else
		bigFont = "ZoFontWinT1"
		normalFont = "ZoFontWinT2"
	end

	function RFT.PopulateWindow(zone, achievements)
		local zoneIndex = GetZoneIndex(zone)
		if zoneIndex <= 1 then
			return 0, 0
		end

		local account = RFT.account

		local rft = RFT.window
		if account.showzone then
			rft.zone:SetText(ZO_CachedStrFormat(SI_ZONE_NAME, GetZoneNameByIndex(zoneIndex)))
			rft.zone:SetHidden(false)
		else
			rft.zone:SetText("")
			rft.zone:SetHidden(true)
		end
		local mediumFont = account.biggerFont and bigFont or normalFont
		rft.zone:SetFont(mediumFont)

		rft.column1:ReleaseAllObjects()
		rft.column2:ReleaseAllObjects()
		rft.column3:ReleaseAllObjects()
		rft.column4:ReleaseAllObjects()

		local title, head
		if account.useDefaultColors then
			RFT.Colors = RFT.ESOColors
			title = RFT.ESODefault
			head = RFT.ESOHighlight
		else
			RFT.Colors = RFT.KatKat42Colors
			title = RFT.KatKat42Default
			head = RFT.KatKat42Highlight
		end
		local r, g, b = title:UnpackRGB()
		rft.title:SetColor(r, g, b)
		rft.zone:SetColor(r, g, b)

		local r, g, b = head:UnpackRGB()
		rft.entries.ocean.label:SetColor(r, g, b)
		rft.entries.lake.label:SetColor(r, g, b)
		rft.entries.river.label:SetColor(r, g, b)
		rft.entries.foul.label:SetColor(r, g, b)

		local numCaught, numFishes = 0, 0
		if achievements ~= 0 then
			local caught, fishes
			for i = 1, #achievements do
				caught, fishes = RFT.PopulateWindowForAchievement(achievements[i])
				numCaught, numFishes = numCaught + caught, numFishes + fishes
			end

			local types = RFT.types[zone] or RFT.types[0]
			local column, waterType
			for i = 1, #RFT.columns do
				column, waterType = RFT.columns[i], types[i]
				local hidden = waterType == nil or rft.labelPools[i]:GetActiveObjectCount() == 0
				if hidden then
					column.label:SetText("")
					column:SetWidth(0)
				else
					column.label:SetFont(mediumFont)
					if account.useSymbols then
						column.label:SetText(RFT.typeSymbols[waterType])
					else
						column.label:SetText(GetString(waterType))
					end
				end
				column:SetHidden(hidden)
			end
		else
			for i = 1, #RFT.columns do
				RFT.columns[i]:SetHidden(true)
			end
		end

		RFT.window.bgtex:SetHidden(not account.showMunge)
		if account.showMunge then
			rft.bg:SetEdgeTexture("EsoUI/Art/ChatWindow/chat_BG_edge.dds", 256, 128, 16)
			rft.bg:SetCenterTexture("EsoUI/Art/ChatWindow/chat_BG_center.dds")
		else
			rft.bg:SetEdgeTexture(nil, 2, 2, 16)
			rft.bg:SetCenterTexture(nil)
		end
		rft.title:SetHidden(not account.showtitle)

		if account.showtitle then
			if IsConsoleUI() then
				rft.title:SetFont(account.biggerFont and "ZoFontGamepadBold27" or "ZoFontGamepadBold22")
			else
				rft.title:SetFont(account.biggerFont and "ZoFontWinH3SoftShadowThin" or "ZoFontWinT1")
			end
			rft.zone:SetAnchor(TOP, rft.title, BOTTOM, 0, 5)
		else
			rft.zone:SetAnchor(TOP, rft, TOP, 0, 5)
		end

		return numCaught, numFishes
	end
end

function RFT.ToggleWindow()
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then
		RARE_FISH_TRACKER_FRAGMENT:Refresh(500, 0)
		return
	end

	local ishidden = RFT.window:IsHidden()
	RFT.isAutoRefresh = false
	-- refresh the window if we're about to show it
	if ishidden then
		RFT.RefreshWindow()
	end
	if RFT.IsShowingWorldMap() then
		RFT.settings.shown_world = ishidden
	else
		RFT.settings.shown = ishidden
	end

	RARE_FISH_TRACKER_FRAGMENT:Refresh(500, 500)
end
