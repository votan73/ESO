local FULL_ALPHA_VALUE = 1
local FADED_ALPHA_VALUE = 0.4

local HIDE_BAR_TEXT = 0
local SHOW_BAR_TEXT_MOUSE_OVER = 1
local SHOW_BAR_TEXT = 2

local UNIT_CHANGED, FORCE_INIT, UPDATE_BAR_TYPE, UPDATE_VALUE, INSTANT, FORCE_SHOW = true, true, true, true, true, true
local ANIMATED, DONT_COLOR_RANK_ICON, PREVENT_SHOW = false, false, false

local GROUP_UNIT_FRAME = "ZO_GroupUnitFrame"
local RAID_UNIT_FRAME = "ZO_RaidUnitFrame"
local TARGET_UNIT_FRAME = "UnitFramesRebirth_TargetUnitFrame"

local NUM_SUBGROUPS = GROUP_SIZE_MAX / SMALL_GROUP_SIZE_THRESHOLD

local GROUPINDEX_NONE = 4294967296

local KEYBOARD_CONSTANTS = {
	GROUP_LEADER_ICON = "EsoUI/Art/UnitFrames/groupIcon_leader.dds",

	GROUP_FRAMES_PER_COLUMN = SMALL_GROUP_SIZE_THRESHOLD,
	NUM_COLUMNS = NUM_SUBGROUPS,

	GROUP_STRIDE = NUM_SUBGROUPS,

	GROUP_FRAME_BASE_OFFSET_X = 28,
	GROUP_FRAME_BASE_OFFSET_Y = 100,

	RAID_FRAME_BASE_OFFSET_X = 28,
	RAID_FRAME_BASE_OFFSET_Y = 100,

	GROUP_FRAME_SIZE_X = ZO_KEYBOARD_GROUP_FRAME_WIDTH,
	GROUP_FRAME_SIZE_Y = ZO_KEYBOARD_GROUP_FRAME_HEIGHT,

	GROUP_FRAME_PAD_X = 2,
	GROUP_FRAME_PAD_Y = 0,

	RAID_FRAME_SIZE_X = ZO_KEYBOARD_RAID_FRAME_WIDTH,
	RAID_FRAME_SIZE_Y = ZO_KEYBOARD_RAID_FRAME_HEIGHT,

	RAID_FRAME_PAD_X = 2,
	RAID_FRAME_PAD_Y = 2,

	GROUP_BAR_FONT = "ZoFontGameOutline",
	RAID_BAR_FONT = "ZoFontGameOutline",

	SHOW_GROUP_LABELS = true,
}

local GAMEPAD_CONSTANTS = {
	GROUP_LEADER_ICON = "EsoUI/Art/UnitFrames/Gamepad/gp_Group_Leader.dds",

	GROUP_FRAMES_PER_COLUMN = 12,
	NUM_COLUMNS = GROUP_SIZE_MAX / 12,

	GROUP_STRIDE = 3,

	GROUP_FRAME_BASE_OFFSET_X = 70,
	GROUP_FRAME_BASE_OFFSET_Y = 55,

	RAID_FRAME_BASE_OFFSET_X = 100,
	RAID_FRAME_BASE_OFFSET_Y = 50,

	GROUP_FRAME_SIZE_X = ZO_GAMEPAD_GROUP_FRAME_WIDTH,
	GROUP_FRAME_SIZE_Y = ZO_GAMEPAD_GROUP_FRAME_HEIGHT,

	GROUP_FRAME_PAD_X = 2,
	GROUP_FRAME_PAD_Y = 9,

	RAID_FRAME_SIZE_X = ZO_GAMEPAD_RAID_FRAME_WIDTH,
	RAID_FRAME_SIZE_Y = ZO_GAMEPAD_RAID_FRAME_HEIGHT,

	RAID_FRAME_PAD_X = 4,
	RAID_FRAME_PAD_Y = 2,

	GROUP_BAR_FONT = "ZoFontGamepad34",
	RAID_BAR_FONT = "ZoFontGamepad18",

	SHOW_GROUP_LABELS = false,
}

local function GetPlatformConstants()
	return IsInGamepadPreferredMode() and GAMEPAD_CONSTANTS or KEYBOARD_CONSTANTS
end

local function CalculateDynamicPlatformConstants()
	local allConstants = { KEYBOARD_CONSTANTS, GAMEPAD_CONSTANTS }

	for _, constants in ipairs(allConstants) do
		constants.GROUP_FRAME_OFFSET_X = constants.GROUP_FRAME_SIZE_X + constants.GROUP_FRAME_PAD_X
		constants.GROUP_FRAME_OFFSET_Y = constants.GROUP_FRAME_SIZE_Y + constants.GROUP_FRAME_PAD_Y

		constants.RAID_FRAME_OFFSET_X = constants.RAID_FRAME_SIZE_X + constants.RAID_FRAME_PAD_X
		constants.RAID_FRAME_OFFSET_Y = constants.RAID_FRAME_SIZE_Y + constants.RAID_FRAME_PAD_Y

		constants.RAID_FRAME_ANCHOR_CONTAINER_WIDTH = constants.RAID_FRAME_SIZE_X
		constants.RAID_FRAME_ANCHOR_CONTAINER_HEIGHT =(constants.RAID_FRAME_SIZE_Y + constants.RAID_FRAME_PAD_Y) * constants.GROUP_FRAMES_PER_COLUMN
	end
end

local function GetPlatformBarFont()
	local constants = GetPlatformConstants()
	if GetGroupSize() > SMALL_GROUP_SIZE_THRESHOLD then
		return constants.RAID_BAR_FONT
	else
		return constants.GROUP_BAR_FONT
	end
end

local groupFrameAnchor = ZO_Anchor:New(TOPLEFT, GuiRoot, TOPLEFT, 0, 0)

local largeGroupAnchorFrames = { }

local function GetGroupFrameAnchor(groupIndex, groupSize)
	local constants = GetPlatformConstants()

	groupSize = groupSize or GetGroupSize()
	local column = zo_floor((groupIndex - 1) / constants.GROUP_FRAMES_PER_COLUMN)
	local row = zo_mod(groupIndex - 1, constants.GROUP_FRAMES_PER_COLUMN)

	if groupSize > SMALL_GROUP_SIZE_THRESHOLD then
		if IsInGamepadPreferredMode() then
			column = zo_mod(groupIndex - 1, constants.NUM_COLUMNS)
			row = zo_floor((groupIndex - 1) / 2)
		end
		groupFrameAnchor:SetTarget(largeGroupAnchorFrames[column + 1])
		groupFrameAnchor:SetOffsets(0, row * constants.RAID_FRAME_OFFSET_Y)
		return groupFrameAnchor
	else
		groupFrameAnchor:SetTarget(ZO_SmallGroupAnchorFrame)
		groupFrameAnchor:SetOffsets(0, row * constants.GROUP_FRAME_OFFSET_Y)
		return groupFrameAnchor
	end
end

local function GetGroupAnchorFrameOffsets(subgroupIndex, groupStride, constants)
	groupStride = groupStride or NUM_SUBGROUPS
	local zeroBasedIndex = subgroupIndex - 1
	local row = zo_floor(zeroBasedIndex / groupStride)
	local column = zeroBasedIndex -(row * groupStride)

	return constants.RAID_FRAME_BASE_OFFSET_X + column * constants.RAID_FRAME_OFFSET_X, constants.RAID_FRAME_BASE_OFFSET_Y + row * constants.RAID_FRAME_ANCHOR_CONTAINER_HEIGHT
end

local function IsPlayerGrouped()
	return IsUnitGrouped("player")
end

--[[
	Global object declarations
--]]

UNIT_FRAMES = nil

--[[
	Local object declarations
--]]

local UnitFrames, UnitFramesManager, UnitFrame, UnitFrameBar

--[[
	UnitFrames container object.  Used to manage the UnitFrame objects according to UnitTags ("group1", "group4pet", etc...)
--]]

UnitFramesManager = ZO_Object:Subclass()

function UnitFramesManager:New()
	local unitFrames = ZO_Object.New(self)
	unitFrames:Initialize()
	return unitFrames
end

function UnitFramesManager:Initialize()
	self.groupFrames = { }
	self.raidFrames = { }
	self.staticFrames = { }

	self.groupSize = 0
	self.targetOfTargetEnabled = true
	self.groupAndRaidHiddenReasons = ZO_HiddenReasons:New()
	self.firstDirtyGroupIndex = nil

	self.UnitFrameClass = UnitFrame
	self.UnitFrameBarClass = UnitFrameBar
	self.KEYBOARD_CONSTANTS = KEYBOARD_CONSTANTS
	self.GAMEPAD_CONSTANTS = GAMEPAD_CONSTANTS
	self.TargetUnitFrameTemplate = "UnitFramesRebirth_TargetUnitFrame"
	self.UnitFrameBarTextTemplate = "ZO_UnitFrameBarText"
	self.GroupFrameAnchor = "ZO_GroupFrameAnchor"
	self.RaidFrameAnchor = "ZO_RaidFrameAnchor"
	self.GroupUnitFrame = "ZO_GroupUnitFrame"
	self.RaidUnitFrame = "ZO_RaidUnitFrame"
end

do
	local function ApplyVisualStyleToAllFrames(frames, gamepadMode)
		for _, unitFrame in pairs(frames) do
			unitFrame:ApplyVisualStyle(gamepadMode)
		end
	end

	function UnitFramesManager:ApplyVisualStyle()
		self.gamepadMode = IsInGamepadPreferredMode()
		ApplyVisualStyleToAllFrames(self.staticFrames, self.gamepadMode)
		ApplyVisualStyleToAllFrames(self.groupFrames, self.gamepadMode)
		ApplyVisualStyleToAllFrames(self.raidFrames, self.gamepadMode)
	end
end

do
	local function SetWarnerToFrames(frames, isActive)
		local healthWarner
		for _, unitFrame in pairs(frames) do
			healthWarner = unitFrame.healthWarner
			if healthWarner then
				if isActive then
					healthWarner:SetPaused(false)
				else
					healthWarner:SetPaused(true)
				end
			end
		end
	end

	function UnitFramesManager:SetWarner(isActive)
		SetWarnerToFrames(self.groupFrames, isActive)
		SetWarnerToFrames(self.raidFrames, isActive)
	end
end

function UnitFramesManager:GetUnitFrameLookupTable(unitTag)
	if unitTag and ZO_Group_IsGroupUnitTag(unitTag) then
		return self.groupSize > SMALL_GROUP_SIZE_THRESHOLD and self.raidFrames or self.groupFrames
	end
	return self.staticFrames
end

function UnitFramesManager:GetFrame(unitTag)
	local unitFrameTable = self:GetUnitFrameLookupTable(unitTag)
	return unitFrameTable and unitFrameTable[unitTag]
end

function UnitFramesManager:CreateFrame(unitTag, anchors, showBarText, style)
	local unitFrame = self:GetFrame(unitTag)
	if not unitFrame then
		unitFrame = UnitFrame:New(unitTag, showBarText, style)

		local unitFrameTable = self:GetUnitFrameLookupTable(unitTag)
		if unitFrameTable then
			unitFrameTable[unitTag] = unitFrame
		end
	end
	return unitFrame
end

function UnitFramesManager:SetFrameHiddenForReason(unitTag, reason, hidden)
	local unitFrame = self:GetFrame(unitTag)
	if unitFrame then
		unitFrame:SetHiddenForReason(reason, hidden)
	end
end

function UnitFramesManager:SetGroupSize(groupSize)
	self.groupSize = groupSize or GetGroupSize()
end

function UnitFramesManager:GetFirstDirtyGroupIndex()
	return self.firstDirtyGroupIndex
end

function UnitFramesManager:GetIsDirty()
	return self.firstDirtyGroupIndex ~= nil
end

-- The update we call will update all unit frames after and including the one being modified
-- So we really just need to know what is the smallest groupIndex that is being changed
function UnitFramesManager:SetGroupIndexDirty(groupIndex)
	if not self.firstDirtyGroupIndex or groupIndex < self.firstDirtyGroupIndex then
		self.firstDirtyGroupIndex = groupIndex
	end
end

function UnitFramesManager:ClearDirty()
	self.firstDirtyGroupIndex = nil
end

function UnitFramesManager:SetGroupAndRaidFramesHiddenForReason(reason, hidden)
	UNIT_FRAMES_FRAGMENT:SetHiddenForReason(reason, hidden)
	self.groupAndRaidHiddenReasons:SetHiddenForReason(reason, hidden)
end

function UnitFramesManager:UpdateGroupAnchorFrames()
	-- Only the raid frame anchors need updates for now and it's only for whether or not the group name labels are showing and which one is highlighted
	if self.groupSize <= SMALL_GROUP_SIZE_THRESHOLD or self.groupAndRaidHiddenReasons:IsHidden() then
		-- Small groups never show the raid frame anchors
		for subgroupIndex = 1, NUM_SUBGROUPS do
			largeGroupAnchorFrames[subgroupIndex]:SetHidden(true)
		end
	else
		local unitTag, frameIsHidden, isLocalPlayerInSubgroup
		for subgroupIndex = 1, NUM_SUBGROUPS do
			frameIsHidden = true
			-- Label starts out hidden...
			isLocalPlayerInSubgroup = false
			for groupMemberIndex = 1, SMALL_GROUP_SIZE_THRESHOLD do
				unitTag = GetGroupUnitTagByIndex(((subgroupIndex - 1) * SMALL_GROUP_SIZE_THRESHOLD) + groupMemberIndex)
				if unitTag then
					frameIsHidden = false
					if AreUnitsEqual("player", unitTag) then
						isLocalPlayerInSubgroup = true
						break
						-- Found a reason to show the label, and determined if this is the local player's subgroup, so bail out
					end
				end
			end

			largeGroupAnchorFrames[subgroupIndex]:SetHidden(frameIsHidden)
		end
	end
end

function UnitFramesManager:IsTargetOfTargetEnabled()
	return self.targetOfTargetEnabled
end

function UnitFramesManager:SetEnableTargetOfTarget(enableFlag)
	if enableFlag ~= self.targetOfTargetEnabled then
		self.targetOfTargetEnabled = enableFlag
		CALLBACK_MANAGER:FireCallbacks("TargetOfTargetEnabledChanged", enableFlag)
	end
end

--[[
	UnitFrameBar class...defines one bar in the unit frame, including background/glass textures, statusbar and text
--]]

UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_ULTRA_FAST = 1
UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_SUPER_FAST = 2
UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_FASTER = 3
UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_FAST = 4
UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_DEFAULT = 5

-- A special flag that essentially acts like a wild card, accepting any mechanic
local ANY_POWER_TYPE = true

local UNITFRAME_BAR_STYLES =
{
	[TARGET_UNIT_FRAME] = {
		[POWERTYPE_HEALTH] = {
			textAnchors = {
				ZO_Anchor:New(TOP,nil,BOTTOM,0,- 22),
			},
			centered = true,
		},
	},

	[GROUP_UNIT_FRAME] = {
		[POWERTYPE_HEALTH] = {
			keyboard = {
				template = "UnitFramesRebirth_GroupUnitFrameStatus",
				barHeight = 14,
				barWidth = 180,
				barAnchors = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 36, 42) },
				warner = {
					texture = "ZO_PlayerAttributeHealthWarnerTexture",
					Left = "UnitFramesRebirth_PlayerAttributeWarnerLeft",
					Right = "UnitFramesRebirth_PlayerAttributeWarnerRightArrow",
					Center = "UnitFramesRebirth_PlayerAttributeWarnerCenter",
				},
			},

			gamepad = {
				template = "UnitFramesRebirth_GroupUnitFrameStatus",
				barHeight = 8,
				barWidth = ZO_GAMEPAD_GROUP_FRAME_WIDTH,
				barAnchors = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 0, 45) },
				hideBgIfOffline = true,
				warner = {
					texture = "ZO_PlayerAttributeHealthWarnerTexture",
					Left = "UnitFramesRebirth_PlayerAttributeWarnerLeft",
					Right = "UnitFramesRebirth_PlayerAttributeWarnerRight",
					Center = "UnitFramesRebirth_PlayerAttributeWarnerCenter",
				},
			},
		},
	},

	[RAID_UNIT_FRAME] = {
		[POWERTYPE_HEALTH] = {
			keyboard = {
				template = "ZO_UnitFrameStatus",
				barHeight = 34,
				barWidth = 90,
				barAnchors = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 2, 2) },
			},

			gamepad = {
				template = "ZO_UnitFrameStatus",
				barHeight = ZO_GAMEPAD_RAID_FRAME_HEIGHT - 2,
				barWidth = ZO_GAMEPAD_RAID_FRAME_WIDTH - 2,
				barAnchors = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 1, 1) },
			},
		},
	},
}

local function GetPlatformBarStyle(style, powerType)
	local styleData = UNITFRAME_BAR_STYLES[style] or UNITFRAME_BAR_STYLES.default
	local barData = styleData[powerType] or styleData[ANY_POWER_TYPE]
	if barData then
		-- Note: It is assumed that either all platforms are defined, or no platforms are defined.
		local platformKey = IsInGamepadPreferredMode() and "gamepad" or "keyboard"
		return barData[platformKey] or barData
	end
end

local function IsValidBarStyle(style, powerType)
	local styleData = UNITFRAME_BAR_STYLES[style] or UNITFRAME_BAR_STYLES.default
	return styleData and (styleData[powerType] ~= nil or styleData[ANY_POWER_TYPE] ~= nil)
end

local function CreateBarStatusControl(baseBarName, parent, style, mechanic, showBarText)
	local barData = GetPlatformBarStyle(style, mechanic)
	if barData then
		if barData.template then
			local barAnchor1, barAnchor2 = barData.barAnchors[1], barData.barAnchors[2]
			local barWidth, barHeight = barData.barWidth, barData.barHeight

			if barData.centered then
				local leftBar = CreateControlFromVirtual(baseBarName .. "Left", parent, barData.template)
				local rightBar = CreateControlFromVirtual(baseBarName .. "Right", parent, barData.template)

				if barAnchor1 then
					barAnchor1:Set(leftBar)
				end

				if barAnchor2 then
					barAnchor2:Set(rightBar)
				end

				leftBar:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
				local gloss = leftBar:GetNamedChild("Gloss")
				if gloss then
					gloss:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
				end

				if barWidth then
					leftBar:SetWidth(barData.barWidth / 2)
					rightBar:SetWidth(barData.barWidth / 2)
				end

				if barHeight then
					leftBar:SetHeight(barData.barHeight)
					rightBar:SetHeight(barData.barHeight)
				end

				rightBar:SetAnchor(TOPLEFT, leftBar, TOPRIGHT, 0, 0)

				return { leftBar, rightBar }
			else
				local statusBar = CreateControlFromVirtual(baseBarName, parent, barData.template)

				if barWidth then
					statusBar:SetWidth(barWidth)
				end

				if barHeight then
					statusBar:SetHeight(barHeight)
				end

				if barAnchor1 then
					barAnchor1:Set(statusBar)
				end

				if barAnchor2 then
					barAnchor2:AddToControl(statusBar)
				end

				return { statusBar }
			end
		else
			-- attempt to find the controls from XML
			local bar = parent:GetNamedChild("Bar")
			if bar then
				return { bar }
			end

			local barLeft = parent:GetNamedChild("BarLeft")
			local barRight = parent:GetNamedChild("BarRight")
			if barLeft and barRight then
				return { barLeft, barRight }
			end
		end
	end
	return nil
end

local function CreateBarTextControls(baseBarName, parent, style, mechanic)
	local barData = GetPlatformBarStyle(style, mechanic)
	local textAnchor1, textAnchor2 = barData.textAnchors[1], barData.textAnchors[2]

	local text1, text2
	local textTemplate = barData.textTemplate or UnitFrames.UnitFrameBarTextTemplate

	if textAnchor1 then
		text1 = CreateControlFromVirtual(baseBarName .. "Text1", parent, textTemplate)
		text1:SetFont(GetPlatformBarFont())
		textAnchor1:Set(text1)
	end

	if textAnchor2 then
		text2 = CreateControlFromVirtual(baseBarName .. "Text2", parent, textTemplate)
		text2:SetFont(GetPlatformBarFont())
		textAnchor2:Set(text2)
	end

	return text1, text2
end

UnitFrameBar = ZO_Object:Subclass()

function UnitFrameBar:New(baseBarName, parent, showFrameBarText, style, mechanic)
	local barControls = CreateBarStatusControl(baseBarName, parent, style, mechanic, showFrameBarText)
	if barControls then
		local newFrameBar = ZO_Object.New(self)
		newFrameBar.barControls = barControls
		newFrameBar.showBarText = showFrameBarText
		newFrameBar.style = style
		newFrameBar.mechanic = mechanic
		newFrameBar.resourceNumbersLabel = parent:GetNamedChild("ResourceNumbers")

		if showFrameBarText ~= HIDE_BAR_TEXT then
			newFrameBar.leftText, newFrameBar.rightText = CreateBarTextControls(baseBarName, parent, style, mechanic)
		end

		return newFrameBar
	end
end

do
	-- The health bar animation is pretty slow. We gonna make it a bit faster. This is very helpful in PvP.
	-- DEFAULT_ANIMATION_TIME_MS = 500
	local lookupApproachAmountMs = {
		[UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_ULTRA_FAST] = 100,
		[UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_SUPER_FAST] = 200,
		[UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_FASTER] = 300,
		[UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_FAST] = 400,
		[UNIT_FRAME_REBIRTH_APPROACH_AMOUNT_DEFAULT] = DEFAULT_ANIMATION_TIME_MS,
	}

	local function GetCustomApproachAmountMs()
		return lookupApproachAmountMs[UnitFrames.account.approachAmountMs] or DEFAULT_ANIMATION_TIME_MS
	end

	function UnitFrameBar:Update(barType, cur, max, forceInit)
		local numBarControls = #self.barControls
		local isBarCentered = numBarControls == 2

		local barCur = isBarCentered and cur / 2 or cur
		local barMax = isBarCentered and max / 2 or max

		for i = 1, numBarControls do
			ZO_StatusBar_SmoothTransition(self.barControls[i], barCur, barMax, forceInit, nil, GetCustomApproachAmountMs())
		end

		local updateBarType = false
		self.currentValue = cur
		self.maxValue = max

		if barType ~= self.barType then
			updateBarType = true
			self.barType = barType
			self.barTypeName = GetString("SI_COMBATMECHANICTYPE", self.barType)
		end

		self:UpdateText(updateBarType, cur ~= self.currentValue or self.maxValue ~= max)
	end
end

local function GetVisibility(self)
	if self.showBarText == SHOW_BAR_TEXT_MOUSE_OVER then
		return self.isMouseInside
	end
	return true
end

function UnitFrameBar:UpdateText(updateBarType, updateValue)
	if self.showBarText == SHOW_BAR_TEXT or self.showBarText == SHOW_BAR_TEXT_MOUSE_OVER then
		local visible = GetVisibility(self)
		if self.leftText and self.rightText then
			self.leftText:SetHidden(not visible)
			self.rightText:SetHidden(not visible)
			if visible then
				if updateBarType then
					self.leftText:SetText(zo_strformat(SI_UNIT_FRAME_BARTYPE, self.barTypeName))
				end
				if updateValue then
					self.rightText:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, self.currentValue, self.maxValue))
				end
			end
		elseif self.leftText then
			if visible then
				self.leftText:SetHidden(false)
				if updateValue then
					self.leftText:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, self.currentValue, self.maxValue))
				end
			else
				self.leftText:SetHidden(true)
			end
		end
	end

	if self.resourceNumbersLabel then
		self.resourceNumbersLabel:SetText(ZO_FormatResourceBarCurrentAndMax(self.currentValue, self.maxValue))
	end
end

function UnitFrameBar:SetMouseInside(inside)
	self.isMouseInside = inside

	if self.showBarText == SHOW_BAR_TEXT_MOUSE_OVER then
		self:UpdateText(UPDATE_BAR_TYPE, UPDATE_VALUE)
	end
end

function UnitFrameBar:SetColor(barType)
	local colorFadeOut = GetInterfaceColor(INTERFACE_COLOR_TYPE_POWER_FADE_OUT, barType)
	local colorFadeIn = GetInterfaceColor(INTERFACE_COLOR_TYPE_POWER_FADE_IN, barType)

	for i = 1, #self.barControls do
		ZO_StatusBar_SetGradientColor(self.barControls[i], ZO_POWER_BAR_GRADIENT_COLORS[barType])
		self.barControls[i]:SetFadeOutLossColor(colorFadeOut)
		self.barControls[i]:SetFadeOutGainColor(colorFadeIn)
	end
end

function UnitFrameBar:Hide(hidden)
	for i = 1, #self.barControls do
		self.barControls[i]:SetHidden(hidden)
	end
end

function UnitFrameBar:SetAlpha(alpha)
	for i = 1, #self.barControls do
		self.barControls[i]:SetAlpha(alpha)
	end

	if self.leftText then
		self.leftText:SetAlpha(alpha)
	end

	if self.rightText then
		self.rightText:SetAlpha(alpha)
	end
end

function UnitFrameBar:GetBarControls()
	return self.barControls
end

function UnitFrameBar:SetBarTextMode(alwaysShow)
	self.showBarText = alwaysShow
	self:UpdateText(UPDATE_BAR_TYPE, UPDATE_VALUE)
end

--[[
	UnitFrame main class and update functions
--]]

local UNITFRAME_LAYOUT_DATA =
{
	[GROUP_UNIT_FRAME] = {
		keyboard = {
			nameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 35, 19),
			nameWidth = 215,
			nameWrapMode = TEXT_WRAP_MODE_ELLIPSIS,

			statusData = { anchor1 = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 36, 42), anchor2 = ZO_Anchor:New(TOPRIGHT, nil, TOPRIGHT, - 140, 42), height = 0, },

			leaderIconData = { width = 16, height = 16, offsetX = 5, offsetY = 5 },

			useHealthWarner = true,
		},

		gamepad = {
			nameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 0, 1),
			nameWidth = 306,
			nameWrapMode = TEXT_WRAP_MODE_ELLIPSIS,

			indentedNameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 25, 3),

			statusData = { anchor1 = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 0, 0), anchor2 = ZO_Anchor:New(TOPRIGHT, nil, TOPRIGHT, 0, 35), height = 0, },
			hideHealthBgIfOffline = true,

			leaderIconData = { width = 25, height = 25, offsetX = 0, offsetY = 12 },

			useHealthWarner = true,
		},
	},

	[RAID_UNIT_FRAME] = {
		keyboard = {
			highPriorityBuffHighlight = {
				left = { texture = "EsoUI/Art/UnitFrames/unitframe_raid_outline_left.dds", width = 64, height = 64, },
				right = { texture = "EsoUI/Art/UnitFrames/unitframe_raid_outline_right.dds", width = 32, height = 64, },
				icon = { width = 14, height = 14, customAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 76, 15) },
			},

			nameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 5, 4),
			nameWidth = 86,

			indentedNameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 19, 4),
			indentedNameWidth = 75,

			statusData = { anchor1 = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 5, 20), anchor2 = ZO_Anchor:New(TOPRIGHT, nil, TOPRIGHT, - 4, 20), height = 15, },

			leaderIconData = { width = 16, height = 16, offsetX = 5, offsetY = 5 }
		},

		gamepad = {
			highPriorityBuffHighlight = {
				left = { texture = "EsoUI/Art/UnitFrames/unitframe_raid_outline_left.dds", width = 54, height = 44, },
				right = { texture = "EsoUI/Art/UnitFrames/unitframe_raid_outline_right.dds", width = 32, height = 44, },
				icon = { width = 14, height = 14, customAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 66, 7) },
			},

			nameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 6, 2),
			nameWidth = ZO_GAMEPAD_RAID_FRAME_WIDTH - 6,
			indentedNameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 20, 3),
			indentedNameWidth = ZO_GAMEPAD_RAID_FRAME_WIDTH - 20 - 2,

			leaderIconData = { width = 18, height = 18, offsetX = 2, offsetY = 7 }
		},
	},

	[TARGET_UNIT_FRAME] = {
		neverHideStatusBar = true,
		showStatusInName = true,
		captionControlName = "Caption",
	},
}

local function GetPlatformLayoutData(style)
	local layoutData = UNITFRAME_LAYOUT_DATA[style]
	if layoutData then
		-- Note: It is assumed that either all platforms are defined, or no platforms are defined.
		local platformKey = IsInGamepadPreferredMode() and "gamepad" or "keyboard"
		return layoutData[platformKey] or layoutData
	end
end

local function SetUnitFrameTexture(frame, styleData, showOption)
	if frame and styleData then
		frame:SetTexture(styleData.texture)
		frame:SetDimensions(styleData.width, styleData.height)

		if styleData.customAnchor then
			styleData.customAnchor:Set(frame)
		end

		if showOption == FORCE_SHOW then
			frame:SetHidden(false)
			-- never toggles, this is the only chance this frame has of being shown
		end
	end
end

local function LayoutUnitFrameStatus(statusLabel, statusData, showStatus)
	if statusLabel then
		if statusData then
			statusData.anchor1:Set(statusLabel)
			statusData.anchor2:AddToControl(statusLabel)
			statusLabel:SetHeight(statusData.height)
		end
		statusLabel:SetHidden(not statusData)
	end
end

local function LayoutUnitFrameName(nameLabel, layoutData, indented)
	if nameLabel and layoutData then
		if layoutData.nameAnchor and not indented then
			layoutData.nameAnchor:Set(nameLabel)
		elseif layoutData.indentedNameAnchor and indented then
			layoutData.indentedNameAnchor:Set(nameLabel)
		end

		nameLabel:SetWrapMode(layoutData.nameWrapMode or TEXT_WRAP_MODE_TRUNCATE)

		local nameWidth = layoutData.nameWidth or 0

		if indented then
			nameLabel:SetWidth(layoutData.indentedNameWidth or nameWidth)
		else
			nameLabel:SetWidth(nameWidth)
		end
	end
end

local function DoUnitFrameLayout(unitFrame, style)
	local layoutData = GetPlatformLayoutData(style)
	if layoutData then
		unitFrame.neverHideStatusBar = layoutData.neverHideStatusBar

		if layoutData.highPriorityBuffHighlight then
			SetUnitFrameTexture(GetControl(unitFrame.frame, "HighPriorityBuffHighlight"), layoutData.highPriorityBuffHighlight.left, PREVENT_SHOW)
			SetUnitFrameTexture(GetControl(unitFrame.frame, "HighPriorityBuffHighlightRight"), layoutData.highPriorityBuffHighlight.right, PREVENT_SHOW)
			SetUnitFrameTexture(GetControl(unitFrame.frame, "HighPriorityBuffHighlightIcon"), layoutData.highPriorityBuffHighlight.icon, PREVENT_SHOW)

			-- These can't be created in XML because the OnInitialized handler doesn't run until the next frame, just initialize the animations here.
			ZO_AlphaAnimation:New(GetControl(unitFrame.frame, "HighPriorityBuffHighlight"))
			ZO_AlphaAnimation:New(GetControl(unitFrame.frame, "HighPriorityBuffHighlightIcon"))
		end

		LayoutUnitFrameName(unitFrame.nameLabel, layoutData)
		LayoutUnitFrameStatus(unitFrame.statusLabel, layoutData.statusData)

		-- NOTE: Level label is always custom and doesn't need to be managed with this anchoring system
	end
end

local function SwitchNames()
	return UnitFrames.account.switchNames
end

local function HideTitle()
	return UnitFrames.account.hideTitle
end

local function ShowHealthWarner()
	return UnitFrames.account.showHealthWarner
end

local function ShowIgnoreIcon()
	return UnitFrames.account.showIgnoredPlayers
end

local function ShowClassIcon()
	return UnitFrames.account.showClassIcon
end

local function ShowUnitChampionPoints()
	return UnitFrames.account.showRealChampionPoints
end

UnitFrame = ZO_Object:Subclass()

function UnitFrame:New(unitTag, showBarText, style)
	local newFrame = ZO_Object.New(self)
	local parent = ZO_Group_IsGroupUnitTag(unitTag) and ZO_UnitFramesGroups or ZO_UnitFrames

	local layoutData = GetPlatformLayoutData(style)
	if not layoutData then return end

	local frame = CreateControlFromVirtual(style .. unitTag, parent, style)
	frame:SetHidden(true)
	newFrame.style = style
	newFrame.frame = frame
	newFrame.fadeComponents = { }
	newFrame.hiddenReasons = ZO_HiddenReasons:New()
	newFrame.hidden = true

	local nameControlName = layoutData.nameControlName or "Name"
	newFrame.nameLabel = newFrame:AddFadeComponent(nameControlName)

	newFrame.levelLabel = newFrame:AddFadeComponent("Level")

	if layoutData.captionControlName then
		newFrame.captionLabel = newFrame:AddFadeComponent(layoutData.captionControlName)
	end

	local statusControlName = layoutData.statusControlName or "Status"
	newFrame.statusLabel = newFrame:AddFadeComponent(statusControlName)

	newFrame.rankIcon = newFrame:AddFadeComponent("RankIcon", DONT_COLOR_RANK_ICON)
	newFrame.assignmentIcon = newFrame:AddFadeComponent("AssignmentIcon", DONT_COLOR_RANK_ICON)
	newFrame.championIcon = newFrame:AddFadeComponent("ChampionIcon")
	newFrame.ignoreIcon = newFrame:AddFadeComponent("IgnoreIcon")
	newFrame.leftBracket = newFrame:AddFadeComponent("LeftBracket")
	newFrame.leftBracketGlow = GetControl(frame, "LeftBracketGlow")
	newFrame.leftBracketUnderlay = GetControl(frame, "LeftBracketUnderlay")
	newFrame.rightBracket = newFrame:AddFadeComponent("RightBracket")
	newFrame.rightBracketGlow = GetControl(frame, "RightBracketGlow")
	newFrame.rightBracketUnderlay = GetControl(frame, "RightBracketUnderlay")

	newFrame.healthBar = UnitFrameBar:New("$(parent)Hp", frame, showBarText, style, POWERTYPE_HEALTH)
	newFrame.healthBar:SetColor(POWERTYPE_HEALTH)

	newFrame.resourceBars = { }
	newFrame.resourceBars[POWERTYPE_HEALTH] = newFrame.healthBar

	newFrame.powerBars = { }

	if layoutData.useHealthWarner then
		newFrame.healthWarner = UnitFramesRebirth_HealthWarner:New(newFrame.healthBar, unitTag)
	end

	return newFrame
end

function UnitFrame:SetData(unitTag, anchors, showBarText)
	self.unitTag = unitTag
	self.dirty = true
	self.animateShowHide = false
	self.isOnline = nil

	self.showBarText = showBarText

	self.lastPowerType = POWERTYPE_INVALID
	self.frame.m_unitTag = unitTag

	self:SetAnchor(anchors)
	self:ApplyVisualStyle(UnitFrames.gamepadMode)
	self:RefreshVisible()
end

function UnitFrame:IsOnline()
	if self.isOnline == nil then
		self.isOnline = IsUnitOnline(self.unitTag)
	end
	return self.isOnline
end

function UnitFrame:ApplyVisualStyle(gamepadMode)
	if self.currentGamepadMode == gamepadMode then return end
	self.currentGamepadMode = gamepadMode

	DoUnitFrameLayout(self, self.style)
	ApplyTemplateToControl(self.frame, ZO_GetPlatformTemplate(self.style))

	self:DoAlphaUpdate(IsUnitInGroupSupportRange(self.unitTag), IsUnitGroupLeader(self.unitTag))
	self:UpdateDifficulty(self.unitTag)

	local healthBar = self.healthBar
	local barData = GetPlatformBarStyle(healthBar.style, healthBar.mechanic)

	if barData.template then
		local barWidth, warnerControl, warner, warnerChild

		for i, control in ipairs(healthBar.barControls) do
			if self.style ~= TARGET_UNIT_FRAME then
				ApplyTemplateToControl(control, ZO_GetPlatformTemplate(barData.template))
			end

			barWidth = barData.centered and barData.barWidth / 2 or barData.barWidth

			barData.barAnchors[i]:Set(control)
			control:SetWidth(barWidth)
			control:SetHeight(barData.barHeight)

			warnerControl = control.warnerContainer
			warner = barData.warner
			if warnerControl and warner then
				for _, direction in pairs( { "Left", "Right", "Center" }) do
					warnerChild = warnerControl:GetNamedChild(direction)
					ApplyTemplateToControl(warnerChild, ZO_GetPlatformTemplate(warner.texture))
					ApplyTemplateToControl(warnerChild, ZO_GetPlatformTemplate(warner[direction]))
					self.healthWarner:SetPaused(not ShowHealthWarner())
				end
			end
		end

		if #healthBar.barControls == 1 then
			local barAnchor2 = barData.barAnchors[2]
			if barAnchor2 then
				barAnchor2:AddToControl(healthBar.barControls[1])
			end
		end

	end

	local statusBackground = self.frame:GetNamedChild("Background1")
	if statusBackground then
		statusBackground:SetHidden(not self:IsOnline() and barData.hideBgIfOffline)
	end

	local font = GetPlatformBarFont()
	if healthBar.leftText then
		healthBar.leftText:SetFont(font)
	end
	if healthBar.rightText then
		healthBar.rightText:SetFont(font)
	end

	if self.attributeVisualizer then
		self.attributeVisualizer:ApplyPlatformStyle()
	end

	self:RefreshControls()
end

function UnitFrame:SetAnimateShowHide(animate)
	self.animateShowHide = animate
end

function UnitFrame:AddFadeComponent(name, setColor)
	local control = self.frame:GetNamedChild(name)
	if control then
		control.setColor = setColor ~= false
		self.fadeComponents[#self.fadeComponents + 1] = control
	end
	return control
end

function UnitFrame:SetTextIndented(isIndented)
	local layoutData = GetPlatformLayoutData(self.style)
	if layoutData then
		LayoutUnitFrameName(self.nameLabel, layoutData, isIndented)
		LayoutUnitFrameStatus(self.statusLabel, layoutData.statusData, isIndented)
	end
end

function UnitFrame:SetAnchor(anchors)
	self.frame:ClearAnchors()

	if type(anchors) == "table" and #anchors >= 2 then
		anchors[1]:Set(self.frame)
		anchors[2]:AddToControl(self.frame)
	else
		anchors:Set(self.frame)
	end
end

function UnitFrame:SetHiddenForReason(reason, hidden)
	if self.hiddenReasons:SetHiddenForReason(reason, hidden) then
		self:RefreshVisible(INSTANT)
	end
end

function UnitFrame:SetHasTarget(hasTarget)
	self.hasTarget = hasTarget
	self:RefreshVisible(ANIMATED)
end

function UnitFrame:ComputeHidden()
	if not self.hasTarget then
		return true
	end
	return self.hiddenReasons:IsHidden()
end

function UnitFrame:RefreshVisible(instant)
	local hidden = self:ComputeHidden()
	if hidden ~= self.hidden then
		self.hidden = hidden
		if self.animateShowHide and not instant then
			if not self.showHideTimeline then
				self.showHideTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_UnitFrameFadeAnimation", self.frame)
			end
			if hidden then
				if self.showHideTimeline:IsPlaying() then
					self.showHideTimeline:PlayBackward()
				else
					self.showHideTimeline:PlayFromEnd()
				end
			else
				if self.showHideTimeline:IsPlaying() then
					self.showHideTimeline:PlayForward()
				else
					self.showHideTimeline:PlayFromStart()
				end
			end
		else
			if self.showHideTimeline then
				self.showHideTimeline:Stop()
			end
			self.frame:SetHidden(hidden)
		end
	end
	if not hidden then
		self:RefreshControls()
	end
end

function UnitFrame:RefreshControls()
	if self.hidden then
		self.dirty = true
	else
		if self.hasTarget and self.dirty then
			self.dirty = false
			local unitTag = self:GetUnitTag()
			self:UpdateName(unitTag)
			self:UpdateUnitReaction(unitTag)
			self:UpdateLevel(unitTag)
			self:UpdateCaption(unitTag)

			local health, maxHealth = GetUnitPower(unitTag, POWERTYPE_HEALTH)
			self.healthBar:Update(POWERTYPE_HEALTH, health, maxHealth, FORCE_INIT)

			local powerType, cur, max
			for i = 1, NUM_POWER_POOLS do
				powerType, cur, max = GetUnitPowerInfo(unitTag, i)
				self:UpdatePowerBar(i, powerType, cur, max, FORCE_INIT)
			end

			self:UpdateStatus(IsUnitDead(unitTag), self:IsOnline())
			self:UpdateRank(unitTag)
			self:UpdateAssignment(unitTag)
			self:UpdateDifficulty(unitTag)
			self:DoAlphaUpdate(IsUnitInGroupSupportRange(unitTag), IsUnitGroupLeader(unitTag))
		end
	end
end

function UnitFrame:RefreshUnit(unitChanged, validTarget)
	if validTarget == nil then
		-- validTarget is not false or true
		validTarget = DoesUnitExist(self.unitTag)
	end
	if validTarget and self.unitTag == "reticleovertarget" then
		-- AreUnitsEqual may not executed at all
		validTarget = UnitFrames:IsTargetOfTargetEnabled() and not AreUnitsEqual("player", "reticleover")
	end

	if unitChanged or self.hasTarget ~= validTarget then
		self.dirty = true
		MenuOwnerClosed(self.frame)
	end

	-- SetHasTarget calls RefreshControls
	self:SetHasTarget(validTarget)
end

function UnitFrame:SetBarsHidden(hidden)
	self.healthBar:Hide(hidden)
end

function UnitFrame:IsHidden()
	return self.hidden
end

function UnitFrame:GetUnitTag()
	return self.frame.m_unitTag
end

function UnitFrame:GetPrimaryControl()
	return self.frame
end

-- Don't fade out just the frame, because that needs to appear correctly (along with BG, etc...)
-- Just make the status bars and any text on the frame fade out.
-- The vanilla code has isOnline as argument, but it wasn't in use. So we deleted it.
function UnitFrame:DoAlphaUpdate(isNearby, isLeader)
	local color
	if self.unitTag == "reticleover" then
		color = ZO_SELECTED_TEXT
	elseif isLeader then
		color = ZO_HIGHLIGHT_TEXT
	else
		color = ZO_NORMAL_TEXT
	end

	local alphaValue = isNearby and FULL_ALPHA_VALUE or FADED_ALPHA_VALUE
	self.healthBar:SetAlpha(alphaValue)

	local fadeComponent
	for i = 1, #self.fadeComponents do
		fadeComponent = self.fadeComponents[i]
		if fadeComponent.setColor then
			fadeComponent:SetColor(color:UnpackRGBA())
		end
		fadeComponent:SetAlpha(alphaValue)
	end
end

function UnitFrame:UpdatePowerBar(index, powerType, cur, max, forceInit)
	if IsValidBarStyle(self.style, powerType) then
		local currentBar = self.powerBars[index]

		if not currentBar then
			self.powerBars[index] = UnitFrameBar:New("$(parent)PowerBar" .. index, self.frame, self.showBarText, self.style, powerType)
			currentBar = self.powerBars[index]
			currentBar:SetColor(powerType)
			self.resourceBars[powerType] = currentBar
		end

		if currentBar then
			currentBar:Update(powerType, cur, max, forceInit)
			currentBar:Hide(powerType == POWERTYPE_INVALID)
		end
	end
end

do
	local HIDE_LEVEL_TYPES =
	{
		[UNIT_TYPE_SIEGEWEAPON] = true,
		[UNIT_TYPE_INTERACTFIXTURE] = true,
		[UNIT_TYPE_INTERACTOBJ] = true,
		[UNIT_TYPE_SIMPLEINTERACTFIXTURE] = true,
		[UNIT_TYPE_SIMPLEINTERACTOBJ] = true,
	}

	-- show level for players and non-friendly NPCs
	function UnitFrame:ShouldShowLevel(unitTag)
		if IsUnitPlayer(unitTag) and (not HIDE_LEVEL_TYPES[GetUnitType(unitTag)] or ZO_UNIT_FRAMES_SHOW_LEVEL_REACTIONS[GetUnitReaction(unitTag)]) then
			return true
		else
			return false
		end
	end
end

function UnitFrame:UpdateIgnore(unitTag, showLevel, hiddenChampionIcon)
	if IsUnitIgnored(unitTag) and showLevel and ShowIgnoreIcon() then
		self.ignoreIcon:SetHidden(false)
		if hiddenChampionIcon then
			self.ignoreIcon:SetAnchor(RIGHT, self.levelLabel, LEFT)
		else
			self.ignoreIcon:SetAnchor(RIGHT, self.championIcon, LEFT)
		end
	else
		self.ignoreIcon:SetHidden(true)
	end
end

do
	local function GetPreferedChampionPoints(unitTag)
		return ShowUnitChampionPoints() and GetUnitChampionPoints(unitTag) or GetUnitEffectiveChampionPoints(unitTag)
	end

	local function GetChampionPointsOrLevel(unitTag)
		return IsUnitChampion(unitTag) and GetPreferedChampionPoints(unitTag) or GetUnitLevel(unitTag)
	end

	function UnitFrame:UpdateLevel(unitTag)
		local showLevel = self:ShouldShowLevel(unitTag)

		if self.levelLabel then
			local unitLevel = GetChampionPointsOrLevel(unitTag)
			if showLevel and unitLevel > 0 then
				self.levelLabel:SetHidden(false)
				self.levelLabel:SetText(tostring(unitLevel))
				self.nameLabel:SetAnchor(TOPLEFT, self.levelLabel, TOPRIGHT, 10, 0)
			else
				self.levelLabel:SetHidden(true)
				self.nameLabel:SetAnchor(TOPLEFT)
			end
		end

		local showChampionIcon
		if self.championIcon then
			if showLevel and IsUnitChampion(unitTag) then
				showChampionIcon = true
			else
				showChampionIcon = false
			end
			self.championIcon:SetHidden(not showChampionIcon)
		end

		if self.ignoreIcon then
			self:UpdateIgnore(unitTag, showLevel, not showChampionIcon)
		end

	end
end

function UnitFrame:UpdateRank(unitTag)
	if self.rankIcon then
		local rank = GetUnitAvARank(unitTag)
		local showRank = rank ~= 0 or IsUnitPlayer(unitTag)
		if showRank then
			self.rankIcon:SetTexture(GetAvARankIcon(rank))
			self.rankIcon:SetColor(GetAllianceColor(GetUnitAlliance(unitTag)):UnpackRGBA())
		end
		self.rankIcon:SetHidden(not showRank)
	end
end

function UnitFrame:UpdateAssignment(unitTag)
	if self.assignmentIcon then
		-- local unitTag = self:GetUnitTag()
		local assignmentTexture = nil

		if IsActiveWorldBattleground() then
			local battlegroundAlliance = GetUnitBattlegroundAlliance(unitTag)
			if battlegroundAlliance ~= BATTLEGROUND_ALLIANCE_NONE then
				assignmentTexture = GetBattlegroundTeamIcon(battlegroundAlliance)
			end
		else
			local selectedRole = GetGroupMemberSelectedRole(unitTag)
			if selectedRole ~= LFG_ROLE_INVALID then
				assignmentTexture = GetRoleIcon(selectedRole)
			end
		end

		if assignmentTexture then
			self.assignmentIcon:SetTexture(assignmentTexture)
		end

		self.assignmentIcon:SetHidden(assignmentTexture == nil)
	end
end

do
	local DIFFICULTY_BRACKET_LEFT_TEXTURE = {
		[MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level2_left.dds",
		[MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level3_left.dds",
		[MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level4_left.dds",
	}

	local DIFFICULTY_BRACKET_RIGHT_TEXTURE = {
		[MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level2_right.dds",
		[MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level3_right.dds",
		[MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level4_right.dds",
	}

	local DIFFICULTY_BRACKET_GLOW_LEFT_TEXTURE = {
		[MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level2_left.dds",
		[MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level3_left.dds",
		[MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level4_left.dds",
	}

	local DIFFICULTY_BRACKET_GLOW_RIGHT_TEXTURE = {
		[MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level2_right.dds",
		[MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level3_right.dds",
		[MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level4_right.dds",
	}

	local GAMEPAD_DIFFICULTY_BRACKET_TEXTURE = {
		[MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/Gamepad/gp_targetUnitFrame_bracket_level2.dds",
		[MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/Gamepad/gp_targetUnitFrame_bracket_level3.dds",
		[MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/Gamepad/gp_targetUnitFrame_bracket_level4.dds",
	}

	function UnitFrame:SetPlatformDifficultyTextures(difficulty)
		if IsInGamepadPreferredMode() then
			local texture = GAMEPAD_DIFFICULTY_BRACKET_TEXTURE[difficulty]
			self.leftBracket:SetTexture(texture)
			self.rightBracket:SetTexture(texture)
			self.leftBracketGlow:SetHidden(true)
			self.rightBracketGlow:SetHidden(true)
		else
			self.leftBracket:SetTexture(DIFFICULTY_BRACKET_LEFT_TEXTURE[difficulty])
			self.rightBracket:SetTexture(DIFFICULTY_BRACKET_RIGHT_TEXTURE[difficulty])
			self.leftBracketGlow:SetTexture(DIFFICULTY_BRACKET_GLOW_LEFT_TEXTURE[difficulty])
			self.rightBracketGlow:SetTexture(DIFFICULTY_BRACKET_GLOW_RIGHT_TEXTURE[difficulty])
			self.leftBracketGlow:SetHidden(false)
			self.rightBracketGlow:SetHidden(false)
		end
	end
end

function UnitFrame:UpdateDifficulty(unitTag)
	if self.leftBracket then
		local difficulty = GetUnitDifficulty(unitTag)

		-- show difficulty for neutral and hostile NPCs
		local unitReaction = GetUnitReaction(unitTag)
		local showsDifficulty = difficulty > MONSTER_DIFFICULTY_EASY and(unitReaction == UNIT_REACTION_NEUTRAL or unitReaction == UNIT_REACTION_HOSTILE)

		self.leftBracket:SetHidden(not showsDifficulty)
		self.rightBracket:SetHidden(not showsDifficulty)
		self.leftBracketUnderlay:SetHidden(true)
		self.rightBracketUnderlay:SetHidden(true)

		if showsDifficulty then
			self:SetPlatformDifficultyTextures(difficulty)

			if difficulty == MONSTER_DIFFICULTY_DEADLY and not IsInGamepadPreferredMode() then
				self.leftBracketUnderlay:SetHidden(false)
				self.rightBracketUnderlay:SetHidden(false)
			end

			if unitReaction == UNIT_REACTION_HOSTILE then
				TriggerTutorial(TUTORIAL_TRIGGER_COMBAT_MONSTER_DIFFICULTY)
			end
		end
	end
end

function UnitFrame:UpdateUnitReaction(unitTag)
	if self.nameLabel then
		if ZO_Group_IsGroupUnitTag(unitTag or self:GetUnitTag()) then
			local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)
			self.nameLabel:SetColor(r, g, b, self.nameLabel:GetControlAlpha())
		end
	end
end

do
	local TARGET_FRAME_UNITS = {
		["reticleover"] = true,
		["reticleovertarget"] = true,
	}

	function UnitFrame:UpdateName(unitTag)
		if self.nameLabel then
			local name
			-- local unitTag = self.unitTag
			if IsUnitPlayer(unitTag) then
				if TARGET_FRAME_UNITS[unitTag] then
					name = SwitchNames() and ZO_GetSecondaryPlayerNameFromUnitTag(unitTag) or ZO_GetPrimaryPlayerNameFromUnitTag(unitTag)
				else
					name = ZO_GetPrimaryPlayerNameFromUnitTag(unitTag)
				end
			else
				name = GetUnitName(unitTag)
			end
			self.nameLabel:SetText(name)
		end
	end
end

do
	-- Will this fill up the memory? And if so, who cares in an x64 env?
	-- Caching localization result is 10x faster, less garbage.
	local function UpdatePlayerCaptionName(unitTag)
		local name = SwitchNames() and ZO_GetPrimaryPlayerNameFromUnitTag(unitTag) or ZO_GetSecondaryPlayerNameFromUnitTag(unitTag)
		local title = GetUnitTitle(unitTag)
		if title ~= "" and not HideTitle() then
			return ZO_CachedStrFormat(SI_PLAYER_NAME_WITH_TITLE_FORMAT, name, title)
		else
			return name
		end
	end

	local function GetPlatformClassIconResized(unitTag)
		local iconSize = IsInGamepadPreferredMode() and "90%" or "130%"
		return zo_iconFormat(GetPlatformClassIcon(GetUnitClassId(unitTag)), iconSize, iconSize)
	end

	function UnitFrame:UpdatePlayerCaption(unitTag)
		if ShowClassIcon() then
			return ZO_CachedStrFormat(SI_UNITFRAMESREBIRTH_CLASS_WITH_NAME, GetPlatformClassIconResized(unitTag), UpdatePlayerCaptionName(unitTag))
		end
		return UpdatePlayerCaptionName(unitTag)
	end
end

do
	-- Caching localization result is 100x faster, less garbage.
	local function UpdateNPCCaptionName(unitTag)
		return ZO_CachedStrFormat(SI_TOOLTIP_UNIT_CAPTION, GetUnitCaption(unitTag))
	end

	-- still set the caption text when empty so we collapse the label for anything anchoring off the bottom of it
	function UnitFrame:UpdateCaption(unitTag)
		local captionLabel = self.captionLabel
		if captionLabel then
			local caption
			unitTag = unitTag or self:GetUnitTag()
			if IsUnitPlayer(unitTag) then
				caption = self:UpdatePlayerCaption(unitTag)
			else
				caption = UpdateNPCCaptionName(unitTag)
			end

			captionLabel:SetHidden(caption == nil)
			captionLabel:SetText(caption)
		end
	end
end

function UnitFrame:UpdateStatus(isDead, isOnline)
	local statusLabel = self.statusLabel
	if statusLabel then
		local hideBars = isOnline == false or isDead == true
		self:SetBarsHidden(hideBars and not self.neverHideStatusBar)
		local layoutData = GetPlatformLayoutData(self.style)
		statusLabel:SetHidden(not hideBars or not layoutData.statusData)

		local statusBackground = GetControl(self.frame, "Background1")
		if statusBackground then
			statusBackground:SetHidden(not isOnline and layoutData.hideHealthBgIfOffline)
		end

		if layoutData and layoutData.showStatusInName then
			if not isOnline then
				statusLabel:SetText(string.format("(%s)", GetString(SI_UNIT_FRAME_STATUS_OFFLINE)))
			elseif isDead then
				statusLabel:SetText(string.format("(%s)", GetString(SI_UNIT_FRAME_STATUS_DEAD)))
			else
				statusLabel:SetText("")
			end
		else
			if not isOnline then
				statusLabel:SetText(GetString(SI_UNIT_FRAME_STATUS_OFFLINE))
			elseif isDead then
				statusLabel:SetText(GetString(SI_UNIT_FRAME_STATUS_DEAD))
			else
				statusLabel:SetText("")
			end
		end
	end
end

function UnitFrame:SetBarMouseInside(inside)
	self.healthBar:SetMouseInside(inside)
	for powerIndex, powerBar in pairs(self.powerBars) do
		powerBar:SetMouseInside(inside)
	end
end

function UnitFrame:HandleMouseEnter()
	self:SetBarMouseInside(true)
end

function UnitFrame:HandleMouseExit()
	self:SetBarMouseInside(false)
end

function UnitFrame:SetBarTextMode(alwaysShow)
	self.healthBar:SetBarTextMode(alwaysShow)
	for powerIndex, powerBar in pairs(self.powerBars) do
		powerBar:SetBarTextMode(alwaysShow)
	end
end

function UnitFrame:CreateAttributeVisualizer(soundTable)
	if not self.attributeVisualizer then
		self.frame.barControls = self.healthBar:GetBarControls()
		self.attributeVisualizer = ZO_UnitAttributeVisualizer:New(self:GetUnitTag(), soundTable, self.frame)
	end
	return self.attributeVisualizer
end

--[[
	UnitFrame Utility functions
--]]

function ZO_UnitFrames_UpdateWindow(unitTag, unitChanged, unitFrame, validTarget)
	unitFrame = unitFrame or UnitFrames:GetFrame(unitTag)
	if unitFrame then
		unitFrame:RefreshUnit(unitChanged, validTarget)
	end
end

local function CreateGroupAnchorFrames()
	local constants = GetPlatformConstants()

	-- Create small group anchor frame
	local smallFrame = CreateControlFromVirtual("ZO_SmallGroupAnchorFrame", ZO_UnitFramesGroups, UnitFrames.GroupFrameAnchor)
	smallFrame:SetDimensions(constants.GROUP_FRAME_SIZE_X,(constants.GROUP_FRAME_SIZE_Y + constants.GROUP_FRAME_PAD_Y) * SMALL_GROUP_SIZE_THRESHOLD)
	smallFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, constants.GROUP_FRAME_BASE_OFFSET_X, constants.GROUP_FRAME_BASE_OFFSET_Y)

	-- Create raid group anchor frames, these are positioned at the default locations
	local raidFrame, x, y
	for i = 1, NUM_SUBGROUPS do
		raidFrame = CreateControlFromVirtual("ZO_LargeGroupAnchorFrame" .. i, ZO_UnitFramesGroups, UnitFrames.RaidFrameAnchor)
		raidFrame:SetDimensions(constants.RAID_FRAME_ANCHOR_CONTAINER_WIDTH, constants.RAID_FRAME_ANCHOR_CONTAINER_HEIGHT)
		raidFrame:SetHidden(true)
		largeGroupAnchorFrames[i] = raidFrame

		GetControl(raidFrame, "GroupName"):SetText(zo_strformat(SI_GROUP_SUBGROUP_LABEL, i))

		x, y = GetGroupAnchorFrameOffsets(i, constants.GROUP_STRIDE, constants)
		raidFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
	end
end

local function UpdateLeaderIndicator(frames)
	ZO_UnitFrames_Leader:SetHidden(true)

	-- Just one call to GetGroupLeaderUnitTag instead of multiple calls to IsUnitGroupLeader
	local leaderUnitTag = GetGroupLeaderUnitTag()
	if not frames then
		frames = ZO_Group_IsGroupUnitTag(leaderUnitTag) and UnitFrames:GetUnitFrameLookupTable(leaderUnitTag)
		if not frames then return end
	end
	for unitTag, unitFrame in pairs(frames) do
		if unitTag == leaderUnitTag then
			ZO_UnitFrames_Leader:ClearAnchors()
			local layoutData = GetPlatformLayoutData(unitFrame.style)
			if layoutData.leaderIconData then
				local data = layoutData.leaderIconData
				ZO_UnitFrames_Leader:SetDimensions(data.width, data.height)
				ZO_UnitFrames_Leader:SetAnchor(TOPLEFT, unitFrame.frame, TOPLEFT, data.offsetX, data.offsetY)
				unitFrame:SetTextIndented(true)
			else
				unitFrame:SetTextIndented(false)
			end

			ZO_UnitFrames_Leader:SetParent(unitFrame.frame)
			ZO_UnitFrames_Leader:SetHidden(not layoutData.leaderIconData)
		else
			unitFrame:SetTextIndented(false)
		end

		if unitFrame.hasTarget then
			unitFrame:UpdateUnitReaction()
		end
	end
end

local unitTypesWhoUseCastInfo = {
	[UNIT_REACTION_HOSTILE] = true,
	[UNIT_REACTION_NEUTRAL] = true,
}

local TARGET_ATTRIBUTE_VISUALIZER_SOUNDS = {
	[STAT_HEALTH_MAX] = {
		[ATTRIBUTE_BAR_STATE_NORMAL] = SOUNDS.UAV_MAX_HEALTH_NORMAL_TARGET,
		[ATTRIBUTE_BAR_STATE_EXPANDED] = SOUNDS.UAV_MAX_HEALTH_INCREASED_TARGET,
		[ATTRIBUTE_BAR_STATE_SHRUNK] = SOUNDS.UAV_MAX_HEALTH_DECREASED_TARGET,
	},
	[STAT_MAGICKA_MAX] = {
		[ATTRIBUTE_BAR_STATE_NORMAL] = SOUNDS.UAV_MAX_MAGICKA_NORMAL_TARGET,
		[ATTRIBUTE_BAR_STATE_EXPANDED] = SOUNDS.UAV_MAX_MAGICKA_INCREASED_TARGET,
		[ATTRIBUTE_BAR_STATE_SHRUNK] = SOUNDS.UAV_MAX_MAGICKA_DECREASED_TARGET,
	},
	[STAT_STAMINA_MAX] = {
		[ATTRIBUTE_BAR_STATE_NORMAL] = SOUNDS.UAV_MAX_STAMINA_NORMAL_TARGET,
		[ATTRIBUTE_BAR_STATE_EXPANDED] = SOUNDS.UAV_MAX_STAMINA_INCREASED_TARGET,
		[ATTRIBUTE_BAR_STATE_SHRUNK] = SOUNDS.UAV_MAX_STAMINA_DECREASED_TARGET,
	},
	[STAT_HEALTH_REGEN_COMBAT] = {
		[STAT_STATE_INCREASE_GAINED] = SOUNDS.UAV_INCREASED_HEALTH_REGEN_ADDED_TARGET,
		[STAT_STATE_INCREASE_LOST] = SOUNDS.UAV_INCREASED_HEALTH_REGEN_LOST_TARGET,
		[STAT_STATE_DECREASE_GAINED] = SOUNDS.UAV_DECREASED_HEALTH_REGEN_ADDED_TARGET,
		[STAT_STATE_DECREASE_LOST] = SOUNDS.UAV_DECREASED_HEALTH_REGEN_LOST_TARGET,
	},
	[STAT_MAGICKA_REGEN_COMBAT] = {
		[STAT_STATE_INCREASE_GAINED] = SOUNDS.UAV_INCREASED_MAGICKA_REGEN_ADDED_TARGET,
		[STAT_STATE_INCREASE_LOST] = SOUNDS.UAV_INCREASED_MAGICKA_REGEN_LOST_TARGET,
		[STAT_STATE_DECREASE_GAINED] = SOUNDS.UAV_DECREASED_MAGICKA_REGEN_ADDED_TARGET,
		[STAT_STATE_DECREASE_LOST] = SOUNDS.UAV_DECREASED_MAGICKA_REGEN_LOST_TARGET,
	},
	[STAT_STAMINA_REGEN_COMBAT] = {
		[STAT_STATE_INCREASE_GAINED] = SOUNDS.UAV_INCREASED_STAMINA_REGEN_ADDED_TARGET,
		[STAT_STATE_INCREASE_LOST] = SOUNDS.UAV_INCREASED_STAMINA_REGEN_LOST_TARGET,
		[STAT_STATE_DECREASE_GAINED] = SOUNDS.UAV_DECREASED_STAMINA_REGEN_ADDED_TARGET,
		[STAT_STATE_DECREASE_LOST] = SOUNDS.UAV_DECREASED_STAMINA_REGEN_LOST_TARGET,
	},
	[STAT_ARMOR_RATING] = {
		[STAT_STATE_INCREASE_GAINED] = SOUNDS.UAV_INCREASED_ARMOR_ADDED_TARGET,
		[STAT_STATE_INCREASE_LOST] = SOUNDS.UAV_INCREASED_ARMOR_LOST_TARGET,
		[STAT_STATE_DECREASE_GAINED] = SOUNDS.UAV_DECREASED_ARMOR_ADDED_TARGET,
		[STAT_STATE_DECREASE_LOST] = SOUNDS.UAV_DECREASED_ARMOR_LOST_TARGET,
	},
	[STAT_POWER] = {
		[STAT_STATE_INCREASE_GAINED] = SOUNDS.UAV_INCREASED_POWER_ADDED_TARGET,
		[STAT_STATE_INCREASE_LOST] = SOUNDS.UAV_INCREASED_POWER_LOST_TARGET,
		[STAT_STATE_DECREASE_GAINED] = SOUNDS.UAV_DECREASED_POWER_ADDED_TARGET,
		[STAT_STATE_DECREASE_LOST] = SOUNDS.UAV_DECREASED_POWER_LOST_TARGET,
	},
	[STAT_MITIGATION] = {
		[STAT_STATE_IMMUNITY_GAINED] = SOUNDS.UAV_IMMUNITY_ADDED_TARGET,
		[STAT_STATE_IMMUNITY_LOST] = SOUNDS.UAV_IMMUNITY_LOST_TARGET,
		[STAT_STATE_SHIELD_GAINED] = SOUNDS.UAV_DAMAGE_SHIELD_ADDED_TARGET,
		[STAT_STATE_SHIELD_LOST] = SOUNDS.UAV_DAMAGE_SHIELD_LOST_TARGET,
		[STAT_STATE_POSSESSION_APPLIED] = SOUNDS.UAV_POSSESSION_APPLIED_TARGET,
		[STAT_STATE_POSSESSION_REMOVED] = SOUNDS.UAV_POSSESSION_REMOVED_TARGET,
		[STAT_STATE_TRAUMA_GAINED] = SOUNDS.UAV_TRAUMA_ADDED_TARGET,
		[STAT_STATE_TRAUMA_LOST] = SOUNDS.UAV_TRAUMA_LOST_TARGET,
	},
}

local function CreateTargetFrame()
	local targetFrameAnchor = ZO_Anchor:New(TOP, GuiRoot, TOP, 0, 88)
	local targetFrame = UnitFrames:CreateFrame("reticleover", targetFrameAnchor, HIDE_BAR_TEXT, UnitFrames.TargetUnitFrameTemplate)
	if targetFrame then
		targetFrame:SetData("reticleover", targetFrameAnchor, HIDE_BAR_TEXT)
		targetFrame.hasTarget = false
		targetFrame:SetAnimateShowHide(true)
	end
	local visualizer = targetFrame:CreateAttributeVisualizer(TARGET_ATTRIBUTE_VISUALIZER_SOUNDS)

	visualizer:AddModule(ZO_UnitVisualizer_ArrowRegenerationModule:New())

	VISUALIZER_ANGLE_NORMAL_WIDTH = 281
	VISUALIZER_ANGLE_EXPANDED_WIDTH = 362
	VISUALIZER_ANGLE_SHRUNK_WIDTH = 180
	visualizer:AddModule(ZO_UnitVisualizer_ShrinkExpandModule:New(VISUALIZER_ANGLE_NORMAL_WIDTH, VISUALIZER_ANGLE_EXPANDED_WIDTH, VISUALIZER_ANGLE_SHRUNK_WIDTH))

	VISUALIZER_ANGLE_ARMOR_DAMAGE_LAYOUT_DATA = {
		type = "Angle",
		increasedArmorBgContainerTemplate = "ZO_IncreasedArmorBgContainerAngle",
		increasedArmorFrameContainerTemplate = "ZO_IncreasedArmorFrameContainerAngle",
		decreasedArmorOverlayContainerTemplate = "ZO_DecreasedArmorOverlayContainerAngle",
		increasedPowerGlowTemplate = "ZO_IncreasedPowerGlowAngle",
		increasedArmorOffsets =
		{
			keyboard = {
				top = - 7,
				bottom = 8,
				left = - 15,
				right = 15,
			},
			gamepad = {
				top = - 8,
				bottom = 9,
				left = - 12,
				right = 12,
			}
		}
	}

	visualizer:AddModule(ZO_UnitVisualizer_ArmorDamage:New(VISUALIZER_ANGLE_ARMOR_DAMAGE_LAYOUT_DATA))

	VISUALIZER_ANGLE_UNWAVERING_LAYOUT_DATA = {
		overlayContainerTemplate = "ZO_UnwaveringOverlayContainerAngle",
		overlayOffsets = {
			keyboard = {
				top = 2,
				bottom = - 3,
				left = 6,
				right = - 7,
			},
			gamepad = {
				top = 4,
				bottom = - 2,
				left = 8,
				right = - 8,
			}
		}

	}
	visualizer:AddModule(ZO_UnitVisualizer_UnwaveringModule:New(VISUALIZER_ANGLE_UNWAVERING_LAYOUT_DATA))

	VISUALIZER_ANGLE_POSSESSION_LAYOUT_DATA = {
		type = "Angle",
		overlayContainerTemplate = "ZO_PossessionOverlayContainerAngle",
		possessionHaloGlowTemplate = "ZO_PossessionHaloGlowAngle",
		overlayLeftOffset = 8,
		overlayTopOffset = 3,
		overlayRightOffset = - 8,
		overlayBottomOffset = - 3,
	}
	visualizer:AddModule(ZO_UnitVisualizer_PossessionModule:New(VISUALIZER_ANGLE_POSSESSION_LAYOUT_DATA))

	VISUALIZER_ANGLE_POWER_SHIELD_LAYOUT_DATA = {
		barLeftOverlayTemplate = "ZO_PowerShieldBarLeftOverlayAngle",
		barRightOverlayTemplate = "ZO_PowerShieldBarRightOverlayAngle",
	}
	visualizer:AddModule(ZO_UnitVisualizer_PowerShieldModule:New(VISUALIZER_ANGLE_POWER_SHIELD_LAYOUT_DATA))

	ZO_UnitFrames_UpdateWindow("reticleover", UNIT_CHANGED)

	CALLBACK_MANAGER:FireCallbacks("TargetFrameCreated", targetFrame)
end

local function HideFrames(frames)
	for unitTag, unitFrame in pairs(frames) do
		-- calls RefreshVisible(ANIMATED)
		unitFrame:SetHasTarget(false)
		unitFrame.index = GROUPINDEX_NONE
	end
end

local function ForceChange(frames)
	for unitTag, unitFrame in pairs(frames) do
		unitFrame.rawName = ""
	end
end

-- Utility to update the style of the current group frames creating a new frame for the unitTag if necessary,
-- hiding frames that are no longer applicable, and creating new frames of the correct style if the group size
-- goes above or below the "small group" or "raid group" thresholds.
function UnitFramesManager:UpdateGroupFrames()
	local groupSize = GetGroupSize()
	local groupIndex = self:GetFirstDirtyGroupIndex()
	local oldGroupSize = self.groupSize or 0

	local oldLargeGroup = oldGroupSize > SMALL_GROUP_SIZE_THRESHOLD
	local newLargeGroup = groupSize > SMALL_GROUP_SIZE_THRESHOLD

	self:SetGroupSize(groupSize)

	-- In cases where no UI has been setup, the group changes between large and small group sizes, or when
	-- members are removed, we need to run a full update of the UI. These could also be optimized to only
	-- run partial updates if more performance is needed.
	if oldLargeGroup ~= newLargeGroup or groupSize == 0 then
		-- Create all the appropriate frames for the new group member, or in the case of a unit_destroyed
		-- create the small group versions.

		if oldLargeGroup or groupSize == 0 then
			-- Disable the raid frames
			HideFrames(self.raidFrames)
			ForceChange(self.groupFrames)
		end
		if newLargeGroup or groupSize == 0 then
			-- Disable the group frames
			HideFrames(self.groupFrames)
			ForceChange(self.raidFrames)
		end
		groupIndex = 1
	end

	if IsPlayerGrouped() then
		-- Only update the frames of the unit being changed, and those after it in the list for performance
		-- reasons.
		local frames
		if newLargeGroup then
			-- Build the raid frames
			frames = self.raidFrames
		else
			-- Build the group frames
			frames = self.groupFrames
		end

		local style = groupSize > SMALL_GROUP_SIZE_THRESHOLD and self.RaidUnitFrame or self.GroupUnitFrame
		local unitTag
		-- Create new frames based on index
		for i = groupIndex, groupSize do
			unitTag = GetGroupUnitTagByIndex(i)
			if not frames[unitTag] then
				frames[unitTag] = UnitFrame:New(unitTag, HIDE_BAR_TEXT, style)
			end
		end
		-- But sync index of all frames with those of API
		local newIndex, rawName, anchor, hasTarget, isOnline
		for unitTag, unitFrame in pairs(frames) do
			newIndex = GetGroupIndexByUnitTag(unitTag)
			hasTarget = newIndex < GROUPINDEX_NONE
			rawName = hasTarget and GetRawUnitName(unitTag) or ""
			-- While zoning of local player unitTag and index can swap, but are effectively the same position. => just the controls are swapping.
			if unitFrame.index ~= newIndex or unitFrame.rawName ~= rawName then
				-- For OnUnitDestroyed
				unitFrame.index = newIndex

				if hasTarget then
					anchor = GetGroupFrameAnchor(newIndex, groupSize)
					if unitFrame.rawName ~= rawName then
						unitFrame:SetData(unitTag, anchor, HIDE_BAR_TEXT)
					else
						-- just anchor at new index position
						unitFrame:SetAnchor(anchor)
					end
				end
				unitFrame.rawName = rawName
				-- Is a hook-point and calls RefreshUnit, which calls SetHasTarget, which calls RefreshVisible(ANIMATED)
				ZO_UnitFrames_UpdateWindow(unitTag, UNIT_CHANGED, unitFrame, hasTarget)
			elseif hasTarget and unitFrame.dirty and newIndex >= groupIndex then
				unitFrame:UpdateStatus(IsUnitDead(unitTag), unitFrame:IsOnline())
				unitFrame:DoAlphaUpdate(IsUnitInGroupSupportRange(unitTag), IsUnitGroupLeader(unitTag))
				unitFrame.dirty = false
			end
		end
		UpdateLeaderIndicator(frames)
		self:UpdateGroupAnchorFrames()

	elseif oldGroupSize > 0 then
		self:UpdateGroupAnchorFrames()
	end
end

local function SetAnchorOffsets(control, offsetX, offsetY)
	local isValid, point, target, relPoint = control:GetAnchor(0)
	if isValid then
		control:SetAnchor(point, target, relPoint, offsetX, offsetY)
	end
end

local function UpdateGroupFramesVisualStyle()
	local constants = GetPlatformConstants()

	-- Note: Small group anchor frame is currently the same for all platforms.
	local groupFrame = ZO_SmallGroupAnchorFrame
	groupFrame:SetDimensions(constants.GROUP_FRAME_SIZE_X,(constants.GROUP_FRAME_SIZE_Y + constants.GROUP_FRAME_PAD_Y) * SMALL_GROUP_SIZE_THRESHOLD)
	SetAnchorOffsets(groupFrame, constants.GROUP_FRAME_BASE_OFFSET_X, constants.GROUP_FRAME_BASE_OFFSET_Y)

	-- Raid group anchor frames.
	local raidFrame, groupNameControl, x, y
	for i = 1, NUM_SUBGROUPS do
		raidFrame = largeGroupAnchorFrames[i]
		ApplyTemplateToControl(raidFrame, ZO_GetPlatformTemplate("ZO_RaidFrameAnchor"))

		-- For some reason, the ModifyTextType attribute on the template isn't being applied to the existing text on the label.
		-- Clearing and setting the text again seems to reapply the ModifyTextType attribute.
		groupNameControl = GetControl(raidFrame, "GroupName")
		if constants.SHOW_GROUP_LABELS then
			groupNameControl:SetText(zo_strformat(SI_GROUP_SUBGROUP_LABEL, i))
		else
			groupNameControl:SetText("")
		end

		raidFrame:SetDimensions(constants.RAID_FRAME_ANCHOR_CONTAINER_WIDTH, constants.RAID_FRAME_ANCHOR_CONTAINER_HEIGHT)
		x, y = GetGroupAnchorFrameOffsets(i, constants.GROUP_STRIDE, constants)
		SetAnchorOffsets(raidFrame, x, y)
	end

	-- Update all UnitFrame anchors.
	local groupSize = UnitFrames.groupSize or GetGroupSize()
	local unitTag, unitFrame
	for i = 1, GROUP_SIZE_MAX do
		unitTag = GetGroupUnitTagByIndex(i)
		if unitTag then
			unitFrame = UnitFrames:GetFrame(unitTag)
			if unitFrame then
				-- For OnUnitDestroyed
				unitFrame.index = i
				unitFrame:SetAnchor(GetGroupFrameAnchor(i, groupSize))
			end
		end
	end

	-- Update the Group Leader Icon Texture
	ZO_UnitFrames_LeaderIcon:SetTexture(constants.GROUP_LEADER_ICON)
end

function UnitFrame_HandleMouseReceiveDrag(frame)
	if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
		PlaceInUnitFrame(frame.m_unitTag)
	end
end

function UnitFrame_HandleMouseUp(frame, button, upInside)
	if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
		-- dropped something with left click
		if button == MOUSE_BUTTON_INDEX_LEFT then
			PlaceInUnitFrame(frame.m_unitTag)
		else
			ClearCursor()
		end
		-- Same deal here...no unitFrame related clicks like targeting or context menus should take place at this point
		return
	end
end

function UnitFrame_HandleMouseEnter(frame)
	local unitFrame = UnitFrames:GetFrame(frame.m_unitTag)
	if unitFrame then
		unitFrame:HandleMouseEnter()
	end
end

function UnitFrame_HandleMouseExit(frame)
	local unitFrame = UnitFrames:GetFrame(frame.m_unitTag)
	if unitFrame then
		unitFrame:HandleMouseExit()
	end
end

local function UpdateStatus(unitTag, isDead, isOnline)
	local unitFrame = UnitFrames:GetFrame(unitTag)
	if unitFrame then
		if isOnline == nil then
			isOnline = unitFrame:IsOnline()
		else
			unitFrame.isOnline = isOnline
		end

		-- unitFrame.index is not available for static frames
		if unitFrame.index then
			unitFrame.dirty = true
			UnitFrames:SetGroupIndexDirty(unitFrame.index)
		end
	end
	if AreUnitsEqual(unitTag, "reticleover") then
		unitFrame = UnitFrames:GetFrame("reticleover")
		if unitFrame then
			unitFrame:UpdateStatus(isDead, isOnline)
		end
	end
end

function ZO_UnitFrames_GetUnitFrame(unitTag)
	return UnitFrames:GetFrame(unitTag)
end

function ZO_UnitFrames_SetEnableTargetOfTarget(enabled)
	UnitFrames:SetEnableTargetOfTarget(enabled)
end

function ZO_UnitFrames_IsTargetOfTargetEnabled()
	return UnitFrames:IsTargetOfTargetEnabled()
end

local function RegisterForEvents()

	-- updates for every unit zoning (via wayshrine).
	local function RequestFullRefresh()
		UnitFrames.firstDirtyGroupIndex = 1
	end

	local function OnTargetChanged(eventCode, unitTag)
		ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)
	end

	local function OnUnitCharacterNameChanged(eventCode, unitTag)
		ZO_UnitFrames_UpdateWindow(unitTag)
	end

	local function OnReticleTargetChanged()
		ZO_UnitFrames_UpdateWindow("reticleover", UNIT_CHANGED)
		ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)
	end

	local function OnPowerUpdate(eventCode, unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
		local unitFrame = UnitFrames:GetFrame(unitTag)
		if unitFrame then
			if powerType == POWERTYPE_HEALTH then
				unitFrame.healthBar:Update(POWERTYPE_HEALTH, powerPool, powerPoolMax)

				local oldHealth = unitFrame.healthBar.currentValue
				if oldHealth and oldHealth == 0 then
					-- Unit went from dead to non dead...update reaction
					unitFrame:UpdateUnitReaction(unitTag)
				end
			else
				unitFrame:UpdatePowerBar(powerPoolIndex, powerType, powerPool, powerPoolMax)
			end
		end
	end

	local function OnUnitCreated(eventCode, unitTag)
		if ZO_Group_IsGroupUnitTag(unitTag) then
			UnitFrames:SetGroupIndexDirty(GetGroupIndexByUnitTag(unitTag))
		else
			ZO_UnitFrames_UpdateWindow(unitTag, UNIT_CHANGED)
		end
	end

	-- OnUnitDestroyed is called, if a joining unit replaces a previous one.
	-- In this case GetGroupIndexByUnitTag is working.
	-- But for a leaving unit GetGroupIndexByUnitTag returns 4294967296.
	-- The trick is to store the last used index in the unitFrame.
	local function OnUnitDestroyed(eventCode, unitTag)
		if ZO_Group_IsGroupUnitTag(unitTag) then
			local unitFrame = UnitFrames:GetFrame(unitTag)
			if unitFrame then
				if unitFrame.index < GROUPINDEX_NONE then
					UnitFrames:SetGroupIndexDirty(unitFrame.index)
					unitFrame.dirty = true
				end
			end
		else
			ZO_UnitFrames_UpdateWindow(unitTag)
		end
	end

	local function OnLevelUpdate(eventCode, unitTag, level)
		local unitFrame = UnitFrames:GetFrame(unitTag)
		if unitFrame then
			unitFrame:UpdateLevel(unitTag)
		end
	end

	local function OnIgnoreUpdate()
		ZO_UnitFrames_UpdateWindow("reticleover", UNIT_CHANGED)
		ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)
	end

	local function OnLeaderUpdate()
		UpdateLeaderIndicator()
	end

	local function OnDispositionUpdate(eventCode, unitTag)
		local unitFrame = UnitFrames:GetFrame(unitTag)
		if unitFrame then
			unitFrame:UpdateUnitReaction(unitTag)
		end
	end

	local function OnGroupSupportRangeUpdate(eventCode, unitTag, isNearby)
		local unitFrame = UnitFrames:GetFrame(unitTag)
		if unitFrame then
			local isLeader = IsUnitGroupLeader(unitTag)
			unitFrame:DoAlphaUpdate(isNearby, isLeader)

			if AreUnitsEqual(unitTag, "reticleover") then
				UnitFrames:GetFrame("reticleover"):DoAlphaUpdate(isNearby, isLeader)
			end

			if AreUnitsEqual(unitTag, "reticleovertarget") then
				local targetOfTarget = UnitFrames:GetFrame("reticleovertarget")
				if targetOfTarget then
					targetOfTarget:DoAlphaUpdate(isNearby, isLeader)
				end
			end
		end
	end

	local function OnGroupMemberLeft(eventCode, characterName, reason, wasLocalPlayer, amLeader)
		if wasLocalPlayer then
			RequestFullRefresh()
		else
			local frames = UnitFrames.groupSize > SMALL_GROUP_SIZE_THRESHOLD and UnitFrames.raidFrames or UnitFrames.groupFrames
			for unitTag, unitFrame in pairs(frames) do
				if characterName == unitFrame.rawName then
					UnitFrames:SetGroupIndexDirty(unitFrame.index)
					unitFrame.dirty = true
					break
				end
			end
		end
	end

	local function OnGroupMemberConnectedStateChanged(eventCode, unitTag, isOnline)
		UpdateStatus(unitTag, IsUnitDead(unitTag), isOnline)
	end

	local function OnGroupMemberRoleChanged(eventCode, unitTag, role)
		local unitFrame = UnitFrames:GetFrame(unitTag)
		if unitFrame then
			unitFrame:UpdateAssignment(unitTag)
		end
	end

	local function OnUnitDeathStateChanged(eventCode, unitTag, isDead)
		UpdateStatus(unitTag, isDead, nil)
	end

	local function OnRankPointUpdate(eventCode, unitTag)
		local unitFrame = UnitFrames:GetFrame(unitTag)

		if unitFrame then
			unitFrame:UpdateRank(unitTag)
		end
	end

	local function OnChampionPointsUpdate(eventCode, unitTag)
		local unitFrame = UnitFrames:GetFrame(unitTag)
		if unitFrame then
			unitFrame:UpdateLevel(unitTag)
		end
	end

	local function OnTitleUpdated(eventCode, unitTag)
		local unitFrame = UnitFrames:GetFrame(unitTag)
		if unitFrame then
			unitFrame:UpdateCaption(unitTag)
		end
	end

	-- Clear cache first and do a full update because we probably missed events while loading
	local function OnPlayerActivated(eventCode)
		ZO_ResetCachedStrFormat(SI_PLAYER_NAME_WITH_TITLE_FORMAT)
		ZO_ResetCachedStrFormat(SI_UNITFRAMESREBIRTH_CLASS_WITH_NAME)
		ZO_ResetCachedStrFormat(SI_TOOLTIP_UNIT_CAPTION)

		ZO_UnitFrames_UpdateWindow("reticleover", UNIT_CHANGED)
		ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)

		if IsPlayerGrouped() or UnitFrames.groupSize > 0 then
			ForceChange(UnitFrames.raidFrames)
			ForceChange(UnitFrames.groupFrames)
			RequestFullRefresh()
		end
	end

	local function OnTargetOfTargetEnabledChanged(enabled)
		ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)
	end

	-- Groups do not update every frame (they wait for events), so refresh if the primary name option may have changed
	local function OnInterfaceSettingChanged(eventCode)
		RequestFullRefresh()
	end

	-- only reticle over can show a guild name in a caption
	local function OnGuildNameAvailable()
		local unitFrame = UnitFrames:GetFrame("reticleover")
		if unitFrame then
			unitFrame:UpdateCaption()
		end
	end

	-- this is filtered to only fire on reticle over unit tag
	local function OnGuildIdChanged()
		local unitFrame = UnitFrames:GetFrame("reticleover")
		if unitFrame then
			unitFrame:UpdateCaption()
		end
	end

	-- Register events
	ZO_UnitFrames:RegisterForEvent(EVENT_TARGET_CHANGED, OnTargetChanged)
	ZO_UnitFrames:RegisterForEvent(EVENT_UNIT_CHARACTER_NAME_CHANGED, OnUnitCharacterNameChanged)
	ZO_UnitFrames:RegisterForEvent(EVENT_RETICLE_TARGET_CHANGED, OnReticleTargetChanged)
	ZO_UnitFrames:RegisterForEvent(EVENT_POWER_UPDATE, OnPowerUpdate)
	ZO_UnitFrames:RegisterForEvent(EVENT_UNIT_CREATED, OnUnitCreated)
	ZO_UnitFrames:RegisterForEvent(EVENT_UNIT_DESTROYED, OnUnitDestroyed)
	ZO_UnitFrames:RegisterForEvent(EVENT_IGNORE_ADDED, OnIgnoreUpdate)
	ZO_UnitFrames:RegisterForEvent(EVENT_IGNORE_REMOVED, OnIgnoreUpdate)
	ZO_UnitFrames:RegisterForEvent(EVENT_LEVEL_UPDATE, OnLevelUpdate)
	ZO_UnitFrames:RegisterForEvent(EVENT_LEADER_UPDATE, OnLeaderUpdate)
	ZO_UnitFrames:RegisterForEvent(EVENT_DISPOSITION_UPDATE, OnDispositionUpdate)
	ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_SUPPORT_RANGE_UPDATE, OnGroupSupportRangeUpdate)
	ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_UPDATE, RequestFullRefresh)
	ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
	ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_MEMBER_CONNECTED_STATUS, OnGroupMemberConnectedStateChanged)
	ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_MEMBER_ROLE_CHANGED, OnGroupMemberRoleChanged)
	ZO_UnitFrames:RegisterForEvent(EVENT_UNIT_DEATH_STATE_CHANGED, OnUnitDeathStateChanged)
	ZO_UnitFrames:RegisterForEvent(EVENT_RANK_POINT_UPDATE, OnRankPointUpdate)
	ZO_UnitFrames:RegisterForEvent(EVENT_CHAMPION_POINT_UPDATE, OnChampionPointsUpdate)
	ZO_UnitFrames:RegisterForEvent(EVENT_TITLE_UPDATE, OnTitleUpdated)
	ZO_UnitFrames:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
	ZO_UnitFrames:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)
	ZO_UnitFrames:RegisterForEvent(EVENT_GUILD_NAME_AVAILABLE, OnGuildNameAvailable)
	ZO_UnitFrames:RegisterForEvent(EVENT_GUILD_ID_CHANGED, OnGuildIdChanged)

	-- Filter events
	ZO_UnitFrames:AddFilterForEvent(EVENT_TARGET_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")
	ZO_UnitFrames:AddFilterForEvent(EVENT_UNIT_CHARACTER_NAME_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")
	ZO_UnitFrames:AddFilterForEvent(EVENT_GUILD_ID_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")
	ZO_UnitFrames:AddFilterForEvent(EVENT_UNIT_CREATED, REGISTER_FILTER_UNIT_TAG_PREFIX, "group")
	ZO_UnitFrames:AddFilterForEvent(EVENT_UNIT_DESTROYED, REGISTER_FILTER_UNIT_TAG_PREFIX, "group")
	ZO_UnitFrames:AddFilterForEvent(EVENT_DISPOSITION_UPDATE, REGISTER_FILTER_UNIT_TAG_PREFIX, "group")

	CALLBACK_MANAGER:RegisterCallback("TargetOfTargetEnabledChanged", OnTargetOfTargetEnabledChanged)
end

do
	local function OnAddOnLoaded(event, name)
		if name ~= "ZO_Ingame" then return end
		EVENT_MANAGER:UnregisterForEvent("UnitFrames_OnAddOnLoaded", EVENT_ADD_ON_LOADED)

		CalculateDynamicPlatformConstants()

		UnitFrames = UnitFramesManager:New()
		UnitFrames.UNITFRAME_BAR_STYLES = UNITFRAME_BAR_STYLES
		UnitFrames.LAYOUT_DATA = UNITFRAME_LAYOUT_DATA

		UNIT_FRAMES = UnitFrames
		CALLBACK_MANAGER:FireCallbacks("UnitFramesPreInit", UnitFrames)

		RegisterForEvents()
		CreateGroupAnchorFrames()
		CreateTargetFrame()

		local function OnGamepadPreferredModeChanged()
			UnitFrames:ApplyVisualStyle()
			UpdateGroupFramesVisualStyle()
			UpdateLeaderIndicator()
		end
		ZO_PlatformStyle:New(OnGamepadPreferredModeChanged)

		CALLBACK_MANAGER:FireCallbacks("UnitFramesCreated", UnitFrames)
	end

	EVENT_MANAGER:UnregisterForEvent("UnitFrames_OnAddOnLoaded", EVENT_ADD_ON_LOADED)
	EVENT_MANAGER:RegisterForEvent("UnitFrames_OnAddOnLoaded", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ZO_UnitFrames_OnUpdate()
	if UnitFrames and UnitFrames:GetIsDirty() then
		UnitFrames:UpdateGroupFrames()
		UnitFrames:ClearDirty()
	end
end