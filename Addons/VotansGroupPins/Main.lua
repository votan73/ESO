local const = {
	Simple = "Simple",
	Class = "Class",
	Rank = "Rank",
	Role = "Role",
	Health = "Health",
}

local addon = {
	name = "VotansGroupPins",
	accountDefaults =
	{
		pveIcon = const.Simple,
		pveColor = const.Simple,
		avaIcon = const.Simple,
		avaColor = const.Simple,
		simpleLeaderColor = "FFFFFF",
		simpleMemberColor = "FFFFFF",
		simplePlayerColor = "6BF5F4",
		simpleFriendColor = "6B99F4",
		healthGood = "00CC00",
		healthWarn = "C0C000",
		healthBad = "CC0000",
		healthDead = "CCCCCC",
		showLeaderCrown = true,
		showFriendMarker = true,
		roleTank = "0000CC",
		roleHeal = "C000C0",
		roleDps = "C0C000",
	},
	compassPinType = "VOTANS_GROUP_COMPASS_PIN",
}

local am = GetAnimationManager()
local em = GetEventManager()

local g_activeGroupPins = { }
do
	local orgZO_WorldMap_RefreshGroupPins = ZO_WorldMap_RefreshGroupPins
	function ZO_WorldMap_RefreshGroupPins(...)
		ZO_ClearTable(g_activeGroupPins)
		-- COMPASS_PINS.pinManager:RemovePins(addon.compassPinType)
		return orgZO_WorldMap_RefreshGroupPins(...)
	end
end

local function GetUnitTag(pin)
	local unitTag = pin:GetUnitTag()
	if unitTag then g_activeGroupPins[unitTag] = pin end
	return unitTag
end

local iconLeader = "EsoUI/Art/Compass/groupLeader.dds"
local iconMember = "EsoUI/Art/MapPins/UI-WorldMapGroupPip.dds"
local iconFriend = "EsoUI/Art/MapPins/UI-WorldMapGroupPip.dds"
addon.IconLeaderSimple = function(pin) GetUnitTag(pin) return iconLeader end
addon.IconMemberSimple = function(pin) GetUnitTag(pin) return iconMember end

local function AddOverlayIcon(pin, unitTag)
	local labelControl = pin.m_Control:GetNamedChild("Label")
	local isLeader = addon.account.showLeaderCrown and IsUnitGroupLeader(unitTag)
	local isFriend = addon.account.showFriendMarker and IsUnitFriend(unitTag)

	if isLeader or isFriend then
		if labelControl:IsHidden() then
			labelControl:ClearAnchors()
			labelControl:SetAnchor(TOP, nil, TOP, 0, -3)
			labelControl:SetPixelRoundingEnabled(true)
			labelControl:SetHidden(false)
		end
		if isLeader then
			labelControl:SetText(addon:GetColoredLeaderIcon(pin))
		else
			labelControl:SetText(addon:GetColoredFriendIcon(pin))
		end
	else
		labelControl:SetPixelRoundingEnabled(false)
		labelControl:SetHidden(true)
	end
end

function addon.IconFromClass(pin)
	if not pin then return "" end
	local unitTag = GetUnitTag(pin)
	AddOverlayIcon(pin, unitTag)
	return unitTag and GetPlatformClassIcon(GetUnitClassId(unitTag)) or ""
end

function addon.IconFromRank(pin)
	if not pin then return "" end
	local unitTag = GetUnitTag(pin)
	AddOverlayIcon(pin, unitTag)
	return unitTag and GetLargeAvARankIcon(GetUnitAvARank(unitTag)) or ""
end

function addon.IconFromRole(pin)
	if not pin then return "" end
	local unitTag = GetUnitTag(pin)
	if not unitTag then return "" end

	AddOverlayIcon(pin, unitTag)

	local role = GetGroupMemberSelectedRole(unitTag)
	if role == LFG_ROLE_TANK then
		return "/esoui/art/lfg/gamepad/lfg_roleicon_tank.dds"
	elseif role == LFG_ROLE_HEAL then
		return "/esoui/art/lfg/gamepad/lfg_roleicon_healer.dds"
	else
		return "/esoui/art/lfg/gamepad/lfg_roleicon_dps.dds"
	end
end

addon.healthGood = ZO_ColorDef:New(0, 0.8, 0, 1)
addon.healthWarn = ZO_ColorDef:New(0.75, 0.75, 0, 1)
addon.healthBad = ZO_ColorDef:New(0.80, 0, 0, 1)
addon.healthDead = ZO_ColorDef:New(0.75, 0.75, .75, 1)
addon.roleTank = ZO_ColorDef:New(0, 0.8, 0, 1)
addon.roleHeal = ZO_ColorDef:New(0.75, 0.75, 0, 1)
addon.roleDps = ZO_ColorDef:New(0.80, 0, 0, 1)

function addon.tintFromHealth(pin)
	local unitTag = GetUnitTag(pin)

	AddOverlayIcon(pin, unitTag)

	if IsUnitDead(unitTag) then return addon.healthDead end

	local current, _, max = GetUnitPower(unitTag, POWERTYPE_HEALTH)
	local percent = current / max

	if percent >= 0.75 then
		return addon.healthGood
	elseif percent < 0.5 then
		return addon.healthBad
	else
		return addon.healthWarn
	end
end

function addon.tintFromRole(pin)
	if not pin then return "" end
	local unitTag = GetUnitTag(pin)
	if not unitTag then return "" end

	local role = GetGroupMemberSelectedRole(unitTag)
	if role == LFG_ROLE_TANK then
		return addon.roleTank
	elseif role == LFG_ROLE_HEAL then
		return addon.roleHeal
	else
		return addon.roleDps
	end
end

local function IsPlayerInGroup()
	return IsUnitGrouped("player")
end

local function OnPowerUpdate(event, unitTag)
	local pin = g_activeGroupPins[unitTag]
	if pin and pin.normalizedX and pin.normalizedY then
		pin:SetData(pin:GetPinTypeAndTag())
	end
end

function addon:ColorUpdate(enabled)
	if not enabled or not IsPlayerInGroup() then
		em:UnregisterForEvent(addon.name, EVENT_POWER_UPDATE)
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_POWER_UPDATE)
	em:RegisterForEvent(addon.name, EVENT_POWER_UPDATE, OnPowerUpdate)
	em:AddFilterForEvent(addon.name, EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH)
end

do
	local sizeCacheLeader = { }
	local zo_iconFormatInheritColor = zo_iconFormatInheritColor
	local function GetNewIconLeader(size)
		local icon = addon.simpleLeaderColor:Colorize(zo_iconFormatInheritColor(iconLeader, size, size))
		sizeCacheLeader[size] = icon
		return icon
	end
	function addon:GetColoredLeaderIcon(pin)
		local size = math.floor(pin.m_Control:GetWidth())
		return sizeCacheLeader[size] or GetNewIconLeader(size)
	end
	local sizeCacheFriend = { }
	local function GetNewIconFriend(size)
		local size2 = math.max(16, size * 0.75)
		local icon = addon.simpleFriendColor:Colorize(zo_iconFormatInheritColor(iconFriend, size2, size2))
		sizeCacheFriend[size] = icon
		return icon
	end
	function addon:GetColoredFriendIcon(pin)
		local size = math.floor(pin.m_Control:GetWidth())
		return sizeCacheFriend[size] or GetNewIconFriend(size)
	end
	function addon:ClearSizeCache()
		ZO_ClearTable(sizeCacheLeader)
		ZO_ClearTable(sizeCacheFriend)
	end
end

function addon:ApplySettings()
	local settings = self.account
	local leader = ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_GROUP_LEADER]
	local group = ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_GROUP]

	local isAva = IsInAvAZone()
	if isAva then
		if settings.avaIcon == const.Simple then
			leader.texture = addon.IconLeaderSimple
			group.texture = addon.IconMemberSimple
		elseif settings.avaIcon == const.Class then
			leader.texture = addon.IconFromClass
			group.texture = addon.IconFromClass
		elseif settings.avaIcon == const.Rank then
			leader.texture = addon.IconFromRank
			group.texture = addon.IconFromRank
		elseif settings.avaIcon == const.Role then
			leader.texture = addon.IconFromRole
			group.texture = addon.IconFromRole
		end

		if settings.avaColor == const.Simple then
			leader.tint = addon.simpleLeaderColor
			group.tint = addon.simpleMemberColor
		elseif settings.avaColor == const.Health then
			leader.tint = addon.tintFromHealth
			group.tint = addon.tintFromHealth
		elseif settings.avaColor == const.Role then
			leader.tint = addon.tintFromRole
			group.tint = addon.tintFromRole
		end
	else
		if settings.pveIcon == const.Simple then
			leader.texture = addon.IconLeaderSimple
			group.texture = addon.IconMemberSimple
		elseif settings.pveIcon == const.Class then
			leader.texture = addon.IconFromClass
			group.texture = addon.IconFromClass
		elseif settings.pveIcon == const.Rank then
			leader.texture = addon.IconFromRank
			group.texture = addon.IconFromRank
		elseif settings.pveIcon == const.Role then
			leader.texture = addon.IconFromRole
			group.texture = addon.IconFromRole
		end

		if settings.pveColor == const.Simple then
			leader.tint = addon.simpleLeaderColor
			group.tint = addon.simpleMemberColor
		elseif settings.pveColor == const.Health then
			leader.tint = addon.tintFromHealth
			group.tint = addon.tintFromHealth
		elseif settings.pveColor == const.Role then
			leader.tint = addon.tintFromRole
			group.tint = addon.tintFromRole
		end
	end

	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_PLAYER].tint = addon.simplePlayerColor
	local pin = ZO_WorldMap_GetPinManager():GetPlayerPin()
	pin:SetData(pin:GetPinTypeAndTag())
	-- g_activeGroupPins["player"] = pin

	self:ColorUpdate(true)
end

function addon.PlayerActivated()
	addon:ApplySettings()
end

function addon.PlayerDeactivated()
	addon:ColorUpdate(false)
end


do
	local updateIdentifier = "VOTANS_GROUP_PINS_UPDATE"
	local function DelayedUpdate()
		em:UnregisterForUpdate(updateIdentifier)
		addon:ApplySettings()
		ZO_WorldMap_RefreshGroupPins()
	end

	function addon:InitDelayedUpdate()
		em:UnregisterForUpdate(updateIdentifier)
		em:RegisterForUpdate(updateIdentifier, 100, DelayedUpdate)
	end
end

local function GroupUpdate()
	addon:InitDelayedUpdate()
end

-- local function HookGroupManager()
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_CREATED)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_DESTROYED)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_JOINED)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_LEFT)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_LEVEL_UPDATE)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_CHAMPION_POINT_UPDATE)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_ZONE_UPDATE)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ROLES_CHANGED)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_CONNECTED_STATUS)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_LEADER_UPDATE)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_UPDATE)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_PLAYER_ACTIVATED)
-- em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ACCOUNT_NAME_UPDATED)

-- function ZO_GroupList_Manager:RegisterForEvents()
-- 	local identifier = "ZO_GroupList_Manager_Refresh"

-- 	--  During group invitation, we can receive a lot of event spam at once on a single invite when the
-- 	-- involved players are at the same location. Add a delay so we only refresh once in cases like this.
-- 	local function DelayedRefreshData()
-- 		em:UnregisterForUpdate(identifier)
-- 		self:RefreshData()
-- 	end

-- 	local function RegisterDelayedRefresh()
-- 		em:UnregisterForUpdate(identifier)
-- 		em:RegisterForUpdate(identifier, 100, DelayedRefreshData)
-- 	end

-- 	local function RegisterDelayedRefreshOnUnitEvent(eventCode, unitTag)
-- 		if IsPlayerInGroup() and ZO_Group_IsGroupUnitTag(unitTag) then
-- 			RegisterDelayedRefresh()
-- 		end
-- 	end

-- 	local function OnGroupMemberLeft(eventCode, characterName, reason, wasLocalPlayer, amLeader)
-- 		if (wasLocalPlayer or amLeader) then
-- 			RegisterDelayedRefresh()
-- 		end
-- 	end

-- 	local function OnGroupMemberJoined()
-- 		-- EVENT_UNIT_CREATED will handle the major logic, this is just for the sound
-- 		PlaySound(SOUNDS.GROUP_JOIN)
-- 	end

-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_CREATED, RegisterDelayedRefreshOnUnitEvent)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_DESTROYED, RegisterDelayedRefreshOnUnitEvent)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_LEVEL_UPDATE, RegisterDelayedRefreshOnUnitEvent)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_CHAMPION_POINT_UPDATE, RegisterDelayedRefreshOnUnitEvent)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_ZONE_UPDATE, RegisterDelayedRefreshOnUnitEvent)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ROLES_CHANGED, RegisterDelayedRefreshOnUnitEvent)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_CONNECTED_STATUS, RegisterDelayedRefreshOnUnitEvent)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_LEADER_UPDATE, RegisterDelayedRefresh)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_UPDATE, RegisterDelayedRefresh)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_PLAYER_ACTIVATED, RegisterDelayedRefresh)
-- 	em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ACCOUNT_NAME_UPDATED, RegisterDelayedRefresh)
-- end
-- GROUP_LIST_MANAGER:RegisterForEvents()
-- end


function addon:Initialize()
	local function GetColor(c)
		local r = ZO_ColorDef:New(c)
		r:SetAlpha(1)
		return r
	end
	-- self.player = ZO_SavedVars:NewCharacterIdSettings("VotansGroupPins_Data", 1, nil, nil)
	self.account = ZO_SavedVars:NewAccountWide("VotansGroupPins_Data", 1, nil, addon.accountDefaults)

	self.simpleLeaderColor = GetColor(self.account.simpleLeaderColor)
	self.simpleMemberColor = GetColor(self.account.simpleMemberColor)
	self.healthGood = GetColor(self.account.healthGood)
	self.healthWarn = GetColor(self.account.healthWarn)
	self.healthBad = GetColor(self.account.healthBad)
	self.healthDead = GetColor(self.account.healthDead)
	self.simplePlayerColor = GetColor(self.account.simplePlayerColor)
	self.simpleFriendColor = GetColor(self.account.simpleFriendColor)
	self.roleTank = GetColor(self.account.roleTank)
	self.roleHeal = GetColor(self.account.roleHeal)
	self.roleDps = GetColor(self.account.roleDps)

	-- HookGroupManager()

	ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_PLAYER].texture = "VotansGroupPins/art/Pointer1.dds"

	CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function(navigateIn) self:ApplySettings() end)
	EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_GROUP_UPDATE, GroupUpdate)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, self.PlayerActivated)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_DEACTIVATED, self.PlayerDeactivated)
end

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")
	if not LibHarvensAddonSettings then return end

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Group Pins")
	if not settings then return end
	addon.settingsControls = settings
	settings.version = "1.2.19"
	settings.website = "http://www.esoui.com/downloads/info1619-VotansGroupPins.html"

	local SI_TOOLTIP_ITEM_NAME = GetString(SI_TOOLTIP_ITEM_NAME)
	local simple = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetString(SI_LOCKQUALITY1))
	local class = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetString(SI_LEADERBOARDS_HEADER_CLASS))
	local rank = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetString(SI_STATS_ALLIANCE_RANK))
	local role = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetString(SI_ABILITY_TOOLTIP_ROLE_LABEL))
	local health = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetString(SI_ATTRIBUTES1))

	local icon = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetString(SI_INTERFACE_OPTIONS_INDICATORS))

	local keyToValue = {
		[const.Simple] = simple,
		[const.Class] = class,
		[const.Rank] = rank,
		[const.Role] = role,
		[const.Health] = health,
	}
	local iconItems = {
		{ name = simple, data = const.Simple },
		{ name = class, data = const.Class },
		{ name = rank, data = const.Rank },
		{ name = role, data = const.Role },
	}
	local colorItems = {
		{ name = simple, data = const.Simple },
		{ name = health, data = const.Health },
		{ name = role, data = const.Role },
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_PLAYER_MENU_PLAYER),
		getFunction = function()
			return addon.simplePlayerColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.simplePlayerColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.simplePlayerColor = addon.simplePlayerColor:ToHex()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_COLOR_FRIEND),
		getFunction = function()
			return addon.simpleFriendColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.simpleFriendColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.simpleFriendColor = addon.simpleFriendColor:ToHex()
			addon:ClearSizeCache()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANS_GROUPPINS_SHOW_FRIENDS),
		tooltip = GetString(SI_VOTANS_GROUPPINS_SHOW_FRIENDS_TOOLTIP),
		default = addon.accountDefaults.showFriendMarker,
		getFunction = function() return addon.account.showFriendMarker end,
		setFunction = function(value) addon.account.showFriendMarker = value end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANS_GROUPPINS_SHOW_CROWN),
		tooltip = GetString(SI_VOTANS_GROUPPINS_SHOW_CROWN_TOOLTIP),
		default = addon.accountDefaults.showLeaderCrown,
		getFunction = function() return addon.account.showLeaderCrown end,
		setFunction = function(value) addon.account.showLeaderCrown = value end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_VOTANS_GROUPPINS_PVE),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = icon,
		items = iconItems,
		getFunction = function() return keyToValue[self.account.pveIcon or const.Simple] end,
		setFunction = function(combobox, name, item)
			self.account.pveIcon = item.data
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = GetString(SI_GUILD_HERALDRY_COLOR),
		items = colorItems,
		getFunction = function() return keyToValue[self.account.pveColor or const.Simple] end,
		setFunction = function(combobox, name, item)
			self.account.pveColor = item.data
			self:InitDelayedUpdate()
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_VOTANS_GROUPPINS_PVP),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = icon,
		items = iconItems,
		getFunction = function() return keyToValue[self.account.avaIcon or const.Simple] end,
		setFunction = function(combobox, name, item)
			self.account.avaIcon = item.data
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = GetString(SI_GUILD_HERALDRY_COLOR),
		items = colorItems,
		getFunction = function() return keyToValue[self.account.avaColor or const.Simple] end,
		setFunction = function(combobox, name, item)
			self.account.avaColor = item.data
			self:InitDelayedUpdate()
		end,
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_SIMPLE),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_COLOR_LEADER),
		getFunction = function()
			return addon.simpleLeaderColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.simpleLeaderColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.simpleLeaderColor = addon.simpleLeaderColor:ToHex()
			addon:ClearSizeCache()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_COLOR_MEMBER),
		getFunction = function()
			return addon.simpleMemberColor:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.simpleMemberColor = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.simpleMemberColor = addon.simpleMemberColor:ToHex()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_HEALTH),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_HEALTHY),
		getFunction = function()
			return addon.healthGood:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.healthGood = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.healthGood = addon.healthGood:ToHex()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_TROUBLE),
		getFunction = function()
			return addon.healthWarn:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.healthWarn = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.healthWarn = addon.healthWarn:ToHex()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_WOUNDED),
		getFunction = function()
			return addon.healthBad:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.healthBad = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.healthBad = addon.healthBad:ToHex()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_DEAD),
		getFunction = function()
			return addon.healthDead:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			self.healthDead = ZO_ColorDef:New(newR, newG, newB, 1)
			self.account.healthDead = self.healthDead:ToHex()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_ROLE),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_TANK),
		getFunction = function()
			return addon.roleTank:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.roleTank = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.roleTank = addon.roleTank:ToHex()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_HEAL),
		getFunction = function()
			return addon.roleHeal:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.roleHeal = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.roleHeal = addon.roleHeal:ToHex()
			self:InitDelayedUpdate()
		end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = GetString(SI_VOTANS_GROUPPINS_MODE_DAMAGE),
		getFunction = function()
			return addon.roleDps:UnpackRGB()
		end,
		setFunction = function(newR, newG, newB, newA)
			addon.roleDps = ZO_ColorDef:New(newR, newG, newB, 1)
			addon.account.roleDps = addon.roleDps:ToHex()
			self:InitDelayedUpdate()
		end,
	}
end


-- do
-- local function UpdateControls()
-- 	if addon.settingsControls.selected then
-- 		addon.settingsControls:UpdateControls()
-- 	end
-- end
-- function addon.ToggleShowHUD()
-- 	local self = addon
-- 	self.account.showHUD = not self.account.showHUD
-- 	self:UpdateVisibility()
-- 	UpdateControls()
-- end
-- function addon.ToggleShowCombat()
-- 	local self = addon
-- 	self.account.showCombat = not self.account.showCombat
-- 	self:UpdateVisibility()
-- 	UpdateControls()
-- end
-- end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:Initialize()
	addon:InitSettings()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_GROUPPINS = addon
