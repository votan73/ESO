local addon = {
	name = "VotansUIFixes"
}
local em = GetEventManager()

if GetCVar("language.2") == "de" then
	SafeAddString(SI_BINDTYPE2, "Beim Anlegen gebunden", 2)
	SafeAddString(SI_DUELRESULT0, "<<C:1>>\nhat bei dem Duell aufgegeben.", 1)
	SafeAddString(SI_DUELRESULT1, "<<C:1>>\nhat das Duell gewonnen.", 1)
end

SafeAddString(SI_INVENTORY_SORT_TYPE_ARMOR, "|t28:28:/esoui/art/icons/alchemy/crafting_alchemy_trait_increasearmor_match.dds:inheritColor|t", 1)
SafeAddString(SI_INVENTORY_SORT_TYPE_POWER, "|t28:28:/esoui/art/icons/alchemy/crafting_alchemy_trait_increaseweaponpower.dds:inheritColor|t", 3)
SafeAddString(SI_INVENTORY_SORT_TYPE_PRICE, "|t20:20:/esoui/art/currency/currency_gold.dds|t|t20:20:/esoui/art/tooltips/icon_bag.dds|t", 3)
SafeAddString(SI_STEALTH_HIDDEN, "", 2)
SafeAddString(SI_INVENTORY_MODE_CRAFT_BAG, "Handwerksbeutel", 0)

ItemTooltip:SetDimensionConstraints(532, 0, 532, 1440)
PopupTooltip:SetDimensionConstraints(532, 0, 532, 1440)
ComparativeTooltip1:SetDimensionConstraints(600, 0, 600, 8192)
ComparativeTooltip2:SetDimensionConstraints(600, 0, 600, 8192)

ComparativeTooltip1:SetScale(0.875)
ComparativeTooltip2:SetScale(0.875)

-- ZO_SharedRightPanelBackground:SetWidth(757)
-- ZO_PlayerInventory:SetWidth(747)
-- ZO_PlayerInventoryList:SetWidth(742)

do
	local self = COMPASS
	self.container:SetCardinalDirection("", "", CARDINAL_DIRECTION_NORTH)
	self.container:SetCardinalDirection("", "", CARDINAL_DIRECTION_EAST)
	self.container:SetCardinalDirection("", "", CARDINAL_DIRECTION_WEST)
	self.container:SetCardinalDirection("", "", CARDINAL_DIRECTION_SOUTH)
	ZO_CompassFrameLeft:SetAlpha(0)
	ZO_CompassFrameCenter:SetAlpha(0)
	ZO_CompassFrameRight:SetAlpha(0)
end

-- function addon:StartInteraction(...)
-- local action = GetGameCameraInteractableActionInfo()
-- local actionName = zo_strformat(SI_GAME_CAMERA_TARGET, action)
-- if actionName == GetString(SI_GAMECAMERAACTIONTYPE1) then
-- 	d("could be book")
-- end
-- end

-- local function HookStartInteraction(...)
-- addon:StartInteraction(...)
-- return addon.orgStartInteraction(...)
-- end

function GetBaseClass(class)
	return getmetatable(class).__index
end

local function FilterEvents()
	ZO_SmithingTopLevelDeconstructionPanelInventory:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
	ZO_SmithingTopLevelImprovementPanelInventory:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
	BUY_BACK_WINDOW.control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
	PROVISIONER.control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
	SMITHING.control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
	ZO_InventoryWallet:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
	if ZO_QuickSlot then
		ZO_QuickSlot:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
	end
	ZO_Character:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)
	ZO_Character:AddFilterForEvent(EVENT_UNIT_CREATED, REGISTER_FILTER_UNIT_TAG, "player")
	em:AddFilterForEvent("ZO_HUDEquipmentStatus", EVENT_INVENTORY_FULL_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)

	em:AddFilterForEvent("ZO_ActionBar", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
	em:AddFilterForEvent("ZO_Fence_Manager", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	SafeAddString(SI_STORE_SORT_TYPE_PRICE, "|t20:20:esoui/art/tooltips/icon_bag.dds|t|t16:16:esoui/art/currency/currency_gold.dds|t", 2)
	SafeAddString(SI_INVENTORY_SORT_TYPE_PRICE, "|t20:20:esoui/art/tooltips/icon_bag.dds|t|t16:16:esoui/art/currency/currency_gold.dds|t", 3)

	ZO_PlayerInventorySortByPriceName:SetText(GetString(SI_INVENTORY_SORT_TYPE_PRICE))
	ZO_PlayerBankSortByPriceName:SetText(GetString(SI_INVENTORY_SORT_TYPE_PRICE))
	ZO_InventoryWalletSortByAmountName:SetText(GetString(SI_INVENTORY_SORT_TYPE_PRICE))

	-- ZO_PlayerInventorySortByStatValueName:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
	-- ZO_PlayerBankSortByStatValueName:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

	ZO_UnitFrames:AddFilterForEvent(EVENT_RETICLE_TARGET_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")
	em:AddFilterForEvent("ZO_UnitAttributeVisualizerreticleover", EVENT_RETICLE_TARGET_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")

	-- em:UnregisterForEvent("AutoComplete", EVENT_RETICLE_TARGET_CHANGED)
	-- em:UnregisterForEvent("AutoComplete", EVENT_RETICLE_TARGET_PLAYER_CHANGED)

	FilterEvents()

	-- em:RegisterForEvent("HouseTest", EVENT_PLAYER_ACTIVATED, HouseTest)
	-- addon.orgStartInteraction = FISHING_MANAGER.StartInteraction
	-- -- This is called when interacting with things
	-- FISHING_MANAGER.StartInteraction = HookStartInteraction
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

do
	local manualPlayEmote = false
	local identifier = "NoSpinWhilePlayEmoteByIndex"
	local emotesFragments = {
		FRAME_PLAYER_FRAGMENT,
		FRAME_EMOTE_FRAGMENT_INVENTORY,
		FRAME_EMOTE_FRAGMENT_SKILLS,
		FRAME_EMOTE_FRAGMENT_JOURNAL,
		FRAME_EMOTE_FRAGMENT_MAP,
		FRAME_EMOTE_FRAGMENT_SOCIAL,
		FRAME_EMOTE_FRAGMENT_AVA,
		FRAME_EMOTE_FRAGMENT_SYSTEM,
		FRAME_EMOTE_FRAGMENT_LOOT,
		FRAME_EMOTE_FRAGMENT_CHAMPION
	}
	local scenes = {}
	local function backupScene(name, scene)
		if name:find("market") then
			return
		end
		local sceneToSave = true
		local fragmentToRemove
		for i = 1, #emotesFragments do
			fragmentToRemove = emotesFragments[i]
			if scene:HasFragment(fragmentToRemove) then
				scene:RemoveFragment(fragmentToRemove)
				if sceneToSave then
					sceneToSave = false
					scenes[name] = scene
					scenes[name].toRestore = {}
				end
				table.insert(scenes[name].toRestore, fragmentToRemove)
			end
		end
	end
	local function DontRotateGameCamera(noCameraSpin)
		if noCameraSpin then
			for name, scene in pairs(SCENE_MANAGER.scenes) do
				backupScene(name, scene)
			end
		else
			for name, scene in pairs(scenes) do
				if scene.toRestore then
					for index, fragment in ipairs(scene.toRestore) do
						scene:AddFragment(fragment)
					end
				end
			end
		end
	end
	local function CheckMoving()
		if manualPlayEmote and IsPlayerMoving() then
			manualPlayEmote = false
			DontRotateGameCamera(false)
		end
	end
	--GetCurrentZoneHouseId
	local function OnPlayerActivated(eventCode)
		em:UnregisterForEvent(identifier, EVENT_PLAYER_ACTIVATED)
		-- Nicht gut:
		-- local namespace = tostring(SHARED_INVENTORY)
		-- em:UnregisterForEvent(namespace, EVENT_PLAYER_ACTIVATED)
		em:RegisterForUpdate(identifier, 100, CheckMoving)
	end

	em:UnregisterForEvent(identifier, EVENT_PLAYER_ACTIVATED)
	em:RegisterForEvent(identifier, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

	local orgPlayEmoteByIndex = PlayEmoteByIndex
	local function NoSpinWhilePlayEmoteByIndex(...)
		DontRotateGameCamera(true)
		manualPlayEmote = true
		return orgPlayEmoteByIndex(...)
	end
	PlayEmoteByIndex = NoSpinWhilePlayEmoteByIndex
end

do
	local orgZO_GroupList_Manager_RegisterForEvents = ZO_GroupList_Manager.RegisterForEvents

	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_CREATED)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_DESTROYED)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_JOINED)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_LEFT)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_LEVEL_UPDATE)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_CHAMPION_POINT_UPDATE)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_ZONE_UPDATE)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ROLES_CHANGED)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_CONNECTED_STATUS)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_LEADER_UPDATE)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_UPDATE)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_PLAYER_ACTIVATED)
	em:UnregisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ACCOUNT_NAME_UPDATED)

	local identifier = "ZO_GroupList_Manager_Refresh"

	function ZO_GroupList_Manager:RegisterForEvents()
		--  During group invitation, we can receive a lot of event spam at once on a single invite when the
		-- involved players are at the same location. Add a delay so we only refresh once in cases like this.
		local playSound = nil
		local function DelayedRefreshData()
			em:UnregisterForUpdate(identifier)
			self:RefreshData()
			playSound = SOUNDS.GROUP_JOIN
		end

		local function RegisterDelayedRefresh()
			-- em:UnregisterForUpdate(identifier)
			em:RegisterForUpdate(identifier, 500, DelayedRefreshData)
		end

		local function RegisterDelayedRefreshOnUnitEvent(eventCode, unitTag)
			if ZO_Group_IsGroupUnitTag(unitTag) then
				RegisterDelayedRefresh()
			end
		end

		local function OnGroupMemberLeft(eventCode, characterName, reason, wasLocalPlayer, amLeader)
			if (wasLocalPlayer) then
				RegisterDelayedRefresh()
			end
		end

		local function OnGroupMemberJoined()
			-- EVENT_UNIT_CREATED will handle the major logic, this is just for the sound
			if playSound then
				PlaySound()
				playSound = nil
			end
		end

		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_CREATED, RegisterDelayedRefreshOnUnitEvent)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_DESTROYED, RegisterDelayedRefreshOnUnitEvent)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_LEVEL_UPDATE, RegisterDelayedRefreshOnUnitEvent)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_CHAMPION_POINT_UPDATE, RegisterDelayedRefreshOnUnitEvent)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_ZONE_UPDATE, RegisterDelayedRefreshOnUnitEvent)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ROLES_CHANGED, RegisterDelayedRefreshOnUnitEvent)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_CONNECTED_STATUS, RegisterDelayedRefreshOnUnitEvent)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_LEADER_UPDATE, RegisterDelayedRefresh)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_UPDATE, RegisterDelayedRefresh)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_PLAYER_ACTIVATED, RegisterDelayedRefresh)
		em:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ACCOUNT_NAME_UPDATED, RegisterDelayedRefresh)
	end
	GROUP_LIST_MANAGER:RegisterForEvents()
end

function ZO_InventoryManager:ClearNewStatusOnItemsThePlayerHasSeen(bagId)
end

do
	local orgSelectFragment = STORE_WINDOW.modeBar.SelectFragment
	function STORE_WINDOW.modeBar.SelectFragment(...)
		local self = STORE_WINDOW
		local mode = select(2, ...)
		if IsStoreEmpty() and mode == SI_STORE_MODE_SELL and not KEYBIND_STRIP:HasKeybindButtonGroup(self.keybindStripDescriptor) then
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
		end
		return orgSelectFragment(...)
	end
end

do
	local function SetInverseKinematics(value)
		SetSetting(SETTING_TYPE_IN_WORLD, IN_WORLD_UI_SETTING_FOOT_INVERSE_KINEMATICS, value and "1" or "0")
	end

	local identifier = "NoInverseKinematicsAtStation"
	local oldState = true
	em:RegisterForEvent(
		identifier,
		EVENT_CRAFTING_STATION_INTERACT,
		function()
			oldState = GetSetting_Bool(SETTING_TYPE_IN_WORLD, IN_WORLD_UI_SETTING_FOOT_INVERSE_KINEMATICS)
			SetInverseKinematics(false)
		end
	)

	em:RegisterForEvent(
		identifier,
		EVENT_END_CRAFTING_STATION_INTERACT,
		function()
			SetInverseKinematics(oldState)
		end
	)
end

do
	local cacheCount = 0
	local start = GetGameTimeSeconds()
	local worthToCache = {
		[""] = true,
		[GetString(SI_TOOLTIP_ITEM_NAME)] = true,
		[GetString(SI_GAME_CAMERA_ACTION_QUEST_ITEM)] = true,
		[GetString(SI_GAME_CAMERA_TARGET)] = true,
		[GetString(SI_FORMAT_BULLET_TEXT)] = true,
		[GetString(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO_BAIT)] = true,
		[GetString(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO)] = true,
		[GetString(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO_REQUIRES_KEY)] = true,
		[GetString(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO_WILL_CONSUME_KEY)] = true,
		[GetString(SI_PICKPOCKET_SUCCESS_CHANCE)] = true,
		[GetString(SI_ZONE_DOOR_RETICLE_INSTANCE_TYPE_FORMAT)] = true,
		[GetString(SI_EXIT_HIDEYHOLE)] = true,
		[SI_UNIT_NAME] = true,
		[SI_TOOLTIP_UNIT_NAME] = true,
		[SI_TOOLTIP_UNIT_NAME_AND_CAPTION] = true,
		["<<z:1>>"] = true,
		["<<Z:1>>"] = true
	}
	local orgformat, orgCached = zo_strformat, ZO_CachedStrFormat
	local inCacheFormatter
	function ZO_CachedStrFormat(formatter, ...)
		inCacheFormatter = true
		local result = orgCached(formatter, ...)
		inCacheFormatter = false
		return result
	end
	function zo_strformat(formatter, ...)
		if not inCacheFormatter then
			if worthToCache[formatter] or worthToCache[GetString(formatter)] then
				if type(formatter) == "number" then
					formatter = GetString(formatter)
				end
				cacheCount = cacheCount + 1
				return ZO_CachedStrFormat(formatter, ...)
			end
		end
		return orgformat(formatter, ...)
	end
	SLASH_COMMANDS["/cachecount"] = function()
		d(cacheCount, cacheCount / (GetGameTimeSeconds() - start))
	end
end

local CenterScreenAnnounce = getmetatable(CENTER_SCREEN_ANNOUNCE).__index

local function NoOp()
end

local orgAddMessageWithParams = CenterScreenAnnounce.AddMessageWithParams
CenterScreenAnnounce.AddMessageWithParams = NoOp

em:RegisterForEvent(
	"VotansUIFixesCSA",
	EVENT_PLAYER_DEACTIVATED,
	function()
		if orgAddMessageWithParams and CenterScreenAnnounce.AddMessageWithParams == NoOp then
			CenterScreenAnnounce.AddMessageWithParams = orgAddMessageWithParams
		end
		orgAddMessageWithParams = CenterScreenAnnounce.AddMessageWithParams
		CenterScreenAnnounce.AddMessageWithParams = NoOp
	end
)

em:RegisterForEvent(
	"VotansUIFixesCSA",
	EVENT_PLAYER_ACTIVATED,
	function()
		if orgAddMessageWithParams then
			CenterScreenAnnounce.AddMessageWithParams = orgAddMessageWithParams
		end
		orgAddMessageWithParams = nil
	end
)

local function OnAddonLoaded(event, name)
	if name ~= "LibGPS" then
		return
	end
	em:UnregisterForEvent("VotansUIAugvea", EVENT_ADD_ON_LOADED)
	local gps = LibGPS2
	if gps then
		local gx, gy = 0.071473936255883, 0.60917479135691
		local name = GetZoneNameByIndex(GetZoneIndex(267))

		local orgGetFastTravelNodeInfo = GetFastTravelNodeInfo
		function GetFastTravelNodeInfo(...)
			local result = {orgGetFastTravelNodeInfo(...)}
			if result[1] and result[2] == name then
				local x, y = gps:GlobalToLocal(gx, gy)
				if x and x > 0 and x < 1 and y > 0 and y < 1 then
					result[3], result[4] = x, y
					result[8] = true
				end
			end
			-- if not result[1] then
			-- 	result[1] = true
			-- 	result[5] = esoui/art/icons/poi/poi_wayshrine_glow.dds"
			-- end
			return unpack(result)
		end
	end
end

em:RegisterForEvent("VotansUIAugvea", EVENT_ADD_ON_LOADED, OnAddonLoaded)

local async = LibAsync
do
	local task = async:Create("ZO_SharedFurnitureManager")

	function ZO_SharedFurnitureManager:CreateOrUpdateCollectibleCache()
		local collectibleCache = self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE]
		task:Call(
			function()
				ZO_ClearTable(collectibleCache)
			end
		):Then(
			function(task)
				local SORTED = true
				local filteredDataTable = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects({ZO_CollectibleCategoryData.IsStandardCategory}, {ZO_CollectibleData.IsPlaceableFurniture, ZO_CollectibleData.IsUnlocked}, SORTED)
				task:Then(
					function(task)
						task:For(pairs(filteredDataTable)):Do(
							function(_, collectibleData)
								self:CreateOrUpdateCollectibleDataEntry(collectibleData:GetId())
							end
						)
					end
				)
			end
		):Then(
			function()
				self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
			end
		):Then(
			function()
				self:RequestApplyPlaceableTextFilterToData()
			end
		)
	end

	function ZO_CollectibleDataManager:GetAllCollectibleDataObjects(categoryFilterFunctions, collectibleFilterFunctions, sorted)
		local foundCollectibleDataObjects = {}
		task:For(self:CategoryIterator(categoryFilterFunctions)):Do(
			function(_, categoryData)
				categoryData:AppendAllCollectibleDataObjects(foundCollectibleDataObjects, collectibleFilterFunctions, sorted)
			end
		)
		return foundCollectibleDataObjects
	end
end
do
	local task = async:Create("ZO_WorldMapQuestBreadcrumbs")
	function ZO_WorldMapQuestBreadcrumbs:RefreshAllQuests()
		task:Cancel()
		task:Call(
			function()
				self:CancelAllPendingTasks()
			end
		):For(pairs(self.activeQuests)):Do(
			function(questIndex)
				self:RemoveQuest(questIndex)
			end
		):For(1, MAX_JOURNAL_QUESTS):Do(
			function(questIndex)
				if IsValidQuestIndex(questIndex) then
					self:RefreshQuest(questIndex)
				end
			end
		)
	end
end
do
	local task = async:Create("CMapHandlers_RefreshAllQuestPins")
	local orgFireCallbacks = C_MAP_HANDLERS.FireCallbacks
	local running
	function C_MAP_HANDLERS.FireCallbacks(...)
		local self, name = ...
		if not running or name ~= "RefreshedAllQuestPins" then
			return orgFireCallbacks(...)
		end
	end
	function C_MAP_HANDLERS:RefreshAllQuestPins()
		running = true
		task:Cancel():StopTimer():Delay(
			1000,
			function(task)
				task:For(1, MAX_JOURNAL_QUESTS):Do(
					function(questIndex)
						if IsValidQuestIndex(questIndex) then
							self:RefreshSingleQuestPins(questIndex)
						end
					end
				):Then(
					function()
						running = false
						self:FireCallbacks("RefreshedAllQuestPins")
					end
				)
			end
		)
	end
	local orgShowOnMap = ZO_WorldMap_ShowQuestOnMap
	function ZO_WorldMap_ShowQuestOnMap(...)
		local args = {...}
		task:ThenDelay(
			50,
			function()
				orgShowOnMap(unpack(args))
			end
		)
		return orgShowOnMap(...)
	end
end
do
	local task = async:Create("CMapHandlers_RefreshZoneStory")
	local orgRefreshZoneStory = C_MAP_HANDLERS.RefreshZoneStory
	local running
	function C_MAP_HANDLERS:RefreshZoneStory()
		running = true
		task:Cancel():StopTimer():Delay(
			500,
			function(task)
				orgRefreshZoneStory(self)
				running = false
			end
		)
	end
end

-- SetCVar("SimultaneousCharacterLoadLimit.2", "1")
-- SetCVar("SimultaneousCharacterLoadLimitPerFrame", "1")
-- SetCVar("SimultaneousCharacterDestroyLimit", "1")
-- SetCVar("SimultaneousFixtureDeletionLimit", "500")
-- SetCVar("NetworkThreadPriority", "2")
-- SetCVar("GpuCharacterCompositingEnabled", "1")

LOOT_SCENE:AddFragment(INVENTORY_FRAGMENT)
-- LOOT_SCENE:AddFragment(BACKPACK_DEFAULT_LAYOUT_FRAGMENT)
LOOT_SCENE:AddFragment(RIGHT_PANEL_BG_FRAGMENT)

ZO_PreHook(
	"ZO_InventorySlot_DiscoverSlotActionsFromActionList",
	function(inventorySlot, slotActions)
		return not slotActions.m_contextMenuMode and LOOT_SCENE:IsShowing()
	end
)

function CHAT_MENU_GAMEPAD:AddMessage()
end

function CHAT_MENU_GAMEPAD:OnChatChannelChanged()
end

function MAIN_MENU_GAMEPAD:UpdateEntryEnabledStates()
end

function GAMEPAD_WORLD_MAP_LOCATIONS:UpdateSelectedMap()
end

function CAMPAIGN_EMPEROR_GAMEPAD:CommitScrollList()
end

function ZO_AntiquityJournalGamepad:RefreshData()
end

function ZO_MapAntiquities_Gamepad:RefreshList()
end

function MAIN_MENU_GAMEPAD:RefreshLists()
end

function MAIN_MENU_GAMEPAD:RefreshMainList()
end

function ZONE_STORIES_GAMEPAD:BuildZoneList()
end

function ZONE_STORIES_GAMEPAD:UpdateZoneStory()
end

function ZO_RetraitStation_Retrait_Gamepad:RefreshHeader()
end

function ZO_ACTIVITY_FINDER_ROOT_GAMEPAD.RefreshCategories()
end

EVENT_MANAGER:UnregisterForUpdate("DirectionalInput")

do
	ZO_CreateStringId("SI_BINDING_NAME_NOTIFYLIGHTATTACK", "Light Attack")

	local unitTagPlayer = "player"
	local unitTagTarget = "reticleover"

	local isInCombat, doNotStartCooldown
	local playerStamia, playerMagicka, playerStamiaPercent, playerMagickaPercent = 0, 0, 0, 0

	local function HasTarget()
		return GetUnitNameHighlightedByReticle() ~= "" and GetUnitReaction(unitTagTarget) == UNIT_REACTION_COLOR_HOSTILE
	end
	local function TargetIsInRange()
		return HasTarget() and IsUnitInGroupSupportRange(unitTagTarget)
	end
	local function IsAbilityCasted(abilityIdToCheck)
		local abilityId, _, castByPlayer
		for buffIndex = 1, GetNumBuffs(unitTagPlayer) do
			abilityId, _, castByPlayer = select(11, GetUnitBuffInfo(unitTagPlayer, buffIndex))
			--local name = GetUnitBuffInfo(unitTagPlayer, buffIndex)
			--df("buff %i %s", abilityId, name)
			if castByPlayer and abilityId == abilityIdToCheck then
				return true
			end
		end
		--d("---")
		return false
	end
	local function IsAbilityCastedByAnyone(abilityIdToCheck)
		local abilityId
		for buffIndex = 1, GetNumBuffs(unitTagPlayer) do
			abilityId = select(11, GetUnitBuffInfo(unitTagPlayer, buffIndex))
			--local name = GetUnitBuffInfo(unitTagPlayer, buffIndex)
			--df("buff %i %s", abilityId, name)
			if abilityId == abilityIdToCheck then
				return true
			end
		end
		--d("---")
		return false
	end
	local function IsTargetBuffedWithAbility(abilityIdToCheck)
		local abilityId, _, castByPlayer
		for buffIndex = 1, GetNumBuffs(unitTagTarget) do
			abilityId, _, castByPlayer = select(11, GetUnitBuffInfo(unitTagTarget, buffIndex))
			--local name = GetUnitBuffInfo(unitTagTarget, buffIndex)
			--df("buff %i %s", abilityId, name)
			if castByPlayer and abilityId == abilityIdToCheck then
				return true
			end
		end
		--d("---")
		return false
	end
	local function PlayerHealthPercent()
		local playerHealth, max = GetUnitPower(unitTagPlayer, POWERTYPE_HEALTH)
		return max > 0 and (playerHealth / max) or 0
	end
	local function PlayerMagickaPercent()
		return playerMagickaPercent
	end
	local function PlayerStamiaPercent()
		return playerStamiaPercent
	end
	local function PlayerHealth()
		local playerHealth = GetUnitPower(unitTagPlayer, POWERTYPE_HEALTH)
		return playerHealth
	end
	local function PlayerStamia()
		return playerStamia
	end
	local function PlayerMagicka()
		return playerMagicka
	end
	local function PlayerUltimate()
		return GetUnitPower(unitTagPlayer, POWERTYPE_ULTIMATE)
	end
	local function TargetHealth()
		local current = GetUnitPower(unitTagTarget, POWERTYPE_HEALTH)
		return current
	end
	local function TargetHealthPercent()
		local current, max = GetUnitPower(unitTagTarget, POWERTYPE_HEALTH)
		return max > 0 and (current / max) or 0
	end
	local orgZO_ActionBar_CanUseActionSlots = ZO_ActionBar_CanUseActionSlots
	local stackToActionButton = {}
	local keyWasDown = {}
	local wasAllowed = {}
	local abilityBar = {}
	local processAbility
	local lastAllowedAction = 0
	local lastAllowActionTime = 0
	local needBarSwap = ACTIVE_WEAPON_PAIR_BACKUP
	local currentBar = GetActiveWeaponPairInfo()

	local lastAutoAttack = 0
	SLASH_COMMANDS["/lightattack"] = function()
		lastAllowActionTime = GetGameTimeMilliseconds()
		lastAllowedAction = 0
		currentBar = GetActiveWeaponPairInfo()
		df("lightattack start. Interval: %ims", lastAllowActionTime - lastAutoAttack)
		lastAutoAttack = lastAllowActionTime --GetGameTimeMilliseconds()
		local max
		playerStamia, max = GetUnitPower(unitTagPlayer, POWERTYPE_STAMINA)
		playerStamiaPercent = max > 0 and (playerStamia / max) or 0
		playerMagicka, max = GetUnitPower(unitTagPlayer, POWERTYPE_MAGICKA)
		playerMagickaPercent = max > 0 and (playerMagicka / max) or 0
	end
	local function IsAutoAttack()
		return (GetGameTimeMilliseconds() - lastAutoAttack) <= 700
	end

	local function IsDummy()
		return GetCurrentZoneHouseId() ~= 0
	end

	local orgZO_ActionBar_OnActionButtonDown = ZO_ActionBar_OnActionButtonDown
	function ZO_ActionBar_OnActionButtonDown(...)
		local actionButton = ...
		keyWasDown[actionButton] = true
		return orgZO_ActionBar_OnActionButtonDown(...)
	end
	local orgZO_ActionBar_OnActionButtonUp = ZO_ActionBar_OnActionButtonUp
	function ZO_ActionBar_OnActionButtonUp(...)
		local actionButton = ...
		keyWasDown[actionButton] = false
		if wasAllowed[actionButton] then
			return orgZO_ActionBar_OnActionButtonUp(...)
		end
	end

	--MAP_PIN_TYPE_ANTIQUITY_DIG_SITE
	local function showAction(actionId)
		lastAllowedAction = actionId
		--df("action %i %ims %s", actionId, GetGameTimeMilliseconds() - lastAllowActionTime, GetAbilityName(actionId))
		return true
	end
	local function checkAbility(actionId)
		--df("action %i %s", actionId, GetAbilityName(actionId))
		local action = processAbility[actionId]
		if action then
			return action()
		end
		df("action unknown %i %s", actionId, GetAbilityName(actionId))
		return isInCombat and not IsAutoAttack()
	end
	local function checkAction(actionButton, hotbarCategory)
		local actionId = GetSlotBoundId(actionButton, hotbarCategory)
		return checkAbility(actionId) and showAction(actionId)
	end

	local cooldown = {}
	local recast = {}
	local function CooldownRunning(abilityId, milliseconds)
		local lastTime = cooldown[abilityId] or -100000
		return (GetGameTimeMilliseconds() - milliseconds - 50) < lastTime
	end
	local function StartCooldown(abilityId)
		if not doNotStartCooldown then
			cooldown[abilityId] = GetGameTimeMilliseconds()
		end
		return true
	end
	local function ClearCooldown(abilityId)
		cooldown[abilityId] = 0
		return true
	end
	local function RegisterRecast(abilityId, milliseconds)
		if not isInCombat then
			return not IsAutoAttack()
		end
		if not doNotStartCooldown and currentBar ~= ACTIVE_WEAPON_PAIR_MAIN then
			recast[abilityId] = GetGameTimeMilliseconds() + milliseconds
			abilityBar[abilityId] = currentBar
		end
		return true
	end
	local function NeedRecast(abilityId)
		doNotStartCooldown = true
		if recast[abilityId] and recast[abilityId] < GetGameTimeMilliseconds() and checkAbility(abilityId) then
			doNotStartCooldown = false
			return true
		end
		doNotStartCooldown = false
		return false
	end
	do
		local id = "VOTANUITRACKABILITY"
		em:RegisterForEvent(
			id,
			EVENT_COMBAT_EVENT,
			function(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId, overflow)
				if abilityActionSlotType == ACTION_SLOT_TYPE_LIGHT_ATTACK then
					if result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_CRITICAL_DAMAGE or result == ACTION_RESULT_HEAL or result == ACTION_RESULT_CRITICAL_HEAL or result == ACTION_RESULT_EFFECT_GAINED then
						d(lastAllowedAction ~= 0 and "lightattack hit: good" or "lightattack hit: bad")
					elseif isInCombat then
						d(result == ACTION_RESULT_QUEUED and "queued lightattack hit" or "no lightattack hit")
					end
				else
					--df("event %s %i %i", abilityName, result, abilityActionSlotType)
					--if abilityId == lastAllowedAction then
					--	df("action done %i", result)
					--end
					if abilityId and abilityId > 0 and result == ACTION_RESULT_FAILED or result == ACTION_RESULT_INTERRUPT or result == ACTION_RESULT_FAILED_REQUIREMENTS or result == ACTION_RESULT_BAD_TARGET then
						cooldown[abilityId] = nil
						if lastAllowedAction == abilityId then
							d("happens!")
							lastAllowedAction = 0
						end
					end
				end
			end
		)
		em:AddFilterForEvent(id, EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
	end

	--do
	--	local id = "VOTANUITRACKLA"
	--	em:RegisterForEvent(
	--		id,
	--		EVENT_GLOBAL_MOUSE_UP,
	--		function(eventCode, button)
	--			if button == MOUSE_BUTTON_INDEX_LEFT then
	--				lastAllowActionTime = GetGameTimeMilliseconds()
	--				lastAllowedAction = 0
	--				d("lightattack start")
	--			end
	--		end
	--	)
	--end

	-- local function RegisterCooldown(abilityId)
	-- 	local identifier = "VOTANUITRACK" .. abilityId
	-- 	em:RegisterForEvent(
	-- 		identifier,
	-- 		EVENT_COMBAT_EVENT,
	-- 		function(event, result, isError, _abilityName_, _abilityGraphic_, _abilityActionSlotType_, _sourceName_, _sourceType_, _targetName_, _targetType_, _hitValue_, _powerType_, _damageType_, _log_, _sourceUnitId_, _targetUnitId_, _abilityId_, _overflow_)
	-- 			if result == ACTION_RESULT_EFFECT_GAINED and not isError then
	-- 				d("soso")
	-- 				StartCooldown(abilityId)
	-- 			--hasLightAttack = false
	-- 			end
	-- 			d(result)
	-- 		end
	-- 	)
	-- 	em:AddFilterForEvent(identifier, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, abilityId, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
	-- end
	--RegisterCooldown(26797)
	--RegisterCooldown(46348)

	processAbility = {
		[0] = function(actionButton)
			--local remain, _, _, slotType = GetSlotCooldownInfo(actionButton)
			--return remain <= 0 and (not isInCombat and actionButton >= 9)
			return not IsAutoAttack()
		end,
		[5] = function()
			local current, max = GetUnitPower(unitTagPlayer, POWERTYPE_HEALTH)
			return not IsMounted() or current / max <= 0.5
		end,
		[19123] = function()
			if not HasTarget() then
				return false
			end
			local current, max = GetUnitPower(unitTagPlayer, POWERTYPE_MAGICKA)
			if current < 2284 then
				return false
			end
			return TargetHealthPercent() <= 0.25
		end,
		-- [19123] = function()
		-- 	return TargetHealthPercent() <= 0.25
		-- end,
		[21729] = function()
			--Fluch des Vampirs
			return HasTarget() and PlayerMagicka() >= 2970 and not CooldownRunning(21729, 24000) and StartCooldown(21729)
		end,
		[21765] = function()
			-- reinigendes Licht
			if CooldownRunning(63046, 2000) then
				return false
			end
			return RegisterRecast(21765, 6000) and HasTarget() and not IsTargetBuffedWithAbility(21765)
		end,
		[22178] = function()
			--Sonnenschild
			return (isInCombat or GetUnitReaction(unitTagTarget) == UNIT_REACTION_HOSTILE) and not IsAbilityCasted(22179)
		end,
		[22240] = function()
			--konzentrierter Fokus
			return isInCombat and not IsAbilityCastedByAnyone(37009)
		end,
		[22253] = function()
			--Ehrung der Toten
			return (not IsAutoAttack() and not IsMounted()) or PlayerHealthPercent() <= 0.5
		end,
		[22256] = function()
			--Hauch des Lebens
			if IsAutoAttack() then
				return PlayerHealthPercent() <= 0.5
			else
				return not IsMounted() or PlayerHealthPercent() <= 0.5
			end
		end,
		[22262] = function()
			--verlängertes Ritual
			return not IsAbilityCastedByAnyone(77082) and not IsDummy() and PlayerHealthPercent() <= 0.5 and not CooldownRunning(22262, 18000) and StartCooldown(22262)
		end,
		[23231] = function()
			--Orkan
			return isInCombat and not CooldownRunning(23231, 19000) and StartCooldown(23231) and RegisterRecast(23231, 20000)
		end,
		[23678] = function()
			--kritische Woge
			return (not IsAutoAttack() or not IsAbilityCasted(23678)) and RegisterRecast(23678, 32000)
		end,
		[24165] = function()
			--gebundene Wehr
			return isInCombat and not IsAbilityCasted(24165) and StartCooldown(24165)
		end,
		[26804] = function()
			--bindender Wurfspeer
			return IsTargetBuffedWithAbility(38254) and ((TargetHealthPercent() >= 0.95) or (TargetHealthPercent() <= 0.10))
		end,
		[130291] = function()
			-- (aktive) gebundene Wehr
			return isInCombat and not CooldownRunning(24165, 8000) and HasTarget() and TargetHealth() > 20000
		end,
		[24330] = function()
			return HasTarget() and not IsTargetBuffedWithAbility(89491) and not CooldownRunning(24330, 8550) and StartCooldown(24330)
		end,
		[24595] = function()
			return PlayerHealthPercent() <= 0.9
		end,
		[26797] = function()
			-- Durchschlagender Schwung
			if CooldownRunning(63046, 2000) then
				return false
			end
			if HasTarget() then
				return not IsBlockActive() and TargetHealth() > 4000 and not CooldownRunning(26797, 800) and StartCooldown(26797)
			else
				return isInCombat and not IsBlockActive() and not CooldownRunning(26797, 800) and StartCooldown(26797)
			end
		end,
		[26869] = function()
			--lodernder Speer
			if CooldownRunning(63046, 2000) then
				return false
			end
			return not IsAutoAttack() or (RegisterRecast(26869, 8000) and not CooldownRunning(26869, 8000) and StartCooldown(26869)) and RegisterRecast(26869, 12000)
		end,
		[29338] = function()
			--neutralisierende Magie
			return not IsAbilityCasted(29338) and not IsDummy()
		end,
		[31271] = function()
			--Pfeilfächer
			return isInCombat
		end,
		[35750] = function()
			--Bestienfalle
			return HasTarget() and TargetHealth() > 100000 and not CooldownRunning(35750, 12000) and StartCooldown(35750) and RegisterRecast(35750, 12000)
		end,
		[35762] = function()
			-- Meisterjäger
			return false
		end,
		[40161] = function()
			--makelloser Dämmerbrecher
			return not IsAutoAttack() or PlayerUltimate() >= 119 and TargetHealth() > 300000 and currentBar == ACTIVE_WEAPON_PAIR_MAIN and TargetIsInRange()
		end,
		[40420] = function()
			--Seelenangriff
			return not IsAutoAttack() or PlayerUltimate() >= 175 and TargetHealth() > 300000
		end,
		[40223] = function()
			--aggressives Signal
			d("aggressives Signal")
			return not IsAutoAttack() or PlayerUltimate() >= 237 and TargetHealth() > 300000 and IsAbilityCastedByAnyone(40223)
		end,
		[40382] = function()
			--Stachelfalle
			return HasTarget() and TargetHealth() > 100000 and not CooldownRunning(40382, 12000) and StartCooldown(40382)
		end,
		[35737] = function()
			--Zirkel des Schutzes
			return not IsAutoAttack()
		end,
		[38563] = function()
			return isInCombat and not IsAbilityCastedByAnyone(38564)
		end,
		[38573] = function()
			--Barriere
			return isInCombat and not IsAutoAttack() -- PlayerUltimate() >= 237
		end,
		[38689] = function()
			--endloser Hagel
			return isInCombat
		end,
		[38701] = function()
			local current = PlayerStamia()
			if current < 2562 then
				return false
			end
			if HasTarget() then
				return not IsTargetBuffedWithAbility(38703)
			end
			return not CooldownRunning(38701, 1000) and StartCooldown(38701)
		end,
		[38754] = function()
			-- Schläger
			return isInCombat and not CooldownRunning(38754, 2000) and StartCooldown(38754)
		end,
		[38823] = function()
			-- Umkehrschlag
			local current, max = GetUnitPower(unitTagPlayer, POWERTYPE_STAMINA)
			if current < 1773 then
				return false
			end
			return isInCombat and not CooldownRunning(38823, 3000) and HasTarget() and StartCooldown(38823)
		end,
		[38845] = function()
			--Blutwahn
			return (isInCombat or HasTarget()) and not CooldownRunning(38845, 10000) and StartCooldown(38845)
		end,
		[28607] = function()
			--Unruhe
			return isInCombat and not CooldownRunning(28607, 800) and StartCooldown(28607)
		end,
		[38857] = function()
			--schnelle Stöße
			return isInCombat and not CooldownRunning(38857, 800) and StartCooldown(38857)
		end,
		[38807] = function()
			-- vernichtender Schlag
			return isInCombat and not CooldownRunning(38807, 3000) and HasTarget() and TargetHealth() > 10000 and StartCooldown(38807)
		end,
		[38901] = function()
			--Flinkmantel
			return (isInCombat or HasTarget()) and not CooldownRunning(38901, 14000) and StartCooldown(38901)
		end,
		[39012] = function()
			-- Feuerblockade
			return (isInCombat or HasTarget()) and not CooldownRunning(39012, 12000) and StartCooldown(39012) and RegisterRecast(39012, 20000)
		end,
		[39018] = function()
			--Sturmblockade
			return not IsAutoAttack() or ((isInCombat or HasTarget()) and not CooldownRunning(39018, 12000) and StartCooldown(39018) and RegisterRecast(39018, 20000))
		end,
		[28854] = function()
			--Sturmwand
			return not IsAutoAttack() or ((isInCombat or HasTarget()) and not CooldownRunning(28854, 12000) and StartCooldown(28854) and RegisterRecast(28854, 20000))
		end,
		[39073] = function()
			--instabile Sturmwand
			return not IsAutoAttack() or ((isInCombat or HasTarget()) and not CooldownRunning(39073, 12000) and StartCooldown(39073) and RegisterRecast(39073, 20000))
		end,
		[39095] = function()
			--elementarer Entzug
			return HasTarget() and TargetHealth() > 40000 and TargetHealthPercent() > 0.15 and not IsTargetBuffedWithAbility(61743) and RegisterRecast(39095, 24000)
		end,
		[39089] = function()
			--elementare Anfälligkeit
			return HasTarget() and TargetHealth() > 40000 and TargetHealthPercent() > 0.15 and not IsTargetBuffedWithAbility(61743) and RegisterRecast(39089, 24000)
		end,
		[40317] = function()
			--erholende Seelenfalle
			return HasTarget() and not IsTargetBuffedWithAbility(126897) --and not CooldownRunning(40317, 8550) and StartCooldown(40317)
		end,
		[40328] = function()
			--trennende Seelenfalle
			return HasTarget() and not IsTargetBuffedWithAbility(126897) and not IsTargetBuffedWithAbility(87416) --and not CooldownRunning(40328, 8550) and StartCooldown(40328)
		end,
		[39182] = function()
			-- absorbierende Magie
			return not IsAbilityCasted(39182) and not IsDummy() and PlayerHealthPercent() <= 0.67
			--not CooldownRunning(39182, 5900) and StartCooldown(39182)
		end,
		[39298] = function()
			--Kugel
			return not CooldownRunning(39298, 8000) and StartCooldown(39298)
		end,
		[40194] = function()
			return false
		end,
		[40195] = function()
			--getarnter Jäger
			return false
		end,
		[40242] = function()
			--geschärfte Krähenfüße
			return isInCombat and not CooldownRunning(40242, 8000) and StartCooldown(40242)
		end,
		[28567] = function()
			--Entropie
			return isInCombat and HasTarget() and not CooldownRunning(28567, 12000) and StartCooldown(28567) and RegisterRecast(28567, 24000)
		end,
		[40457] = function()
			--Degeneration
			return RegisterRecast(40457, 6000) and not IsAutoAttack() or isInCombat and HasTarget() and not IsAbilityCasted(61687) and not CooldownRunning(40457, 12000) and StartCooldown(40457) and RegisterRecast(40457, 24000)
			-- not CooldownRunning(40457, 10000) and StartCooldown(40457)
		end,
		[40478] = function()
			return false
		end,
		[42028] = function()
			--mystische Kugel
			return not CooldownRunning(42028, 8000) and not IsDummy() and StartCooldown(42028) and RegisterRecast(42028, 12000)
		end,
		[45227] = function(actionButton) --Magiekraft Potion
			return not IsAutoAttack() or isInCombat and PlayerMagickaPercent() <= 0.70 and TargetHealth() > 1000000 and not IsAbilityCasted(61747)
		end,
		[45221] = function(actionButton) --Leben wiederherstellen
			return not IsAutoAttack() or isInCombat and PlayerMagickaPercent() <= 0.20 -- and TargetHealth() > 20000
		end,
		[45228] = function(actionButton) --Waffenkraft Potion
			return not IsAutoAttack() or isInCombat and PlayerStamiaPercent() <= 0.20 -- and TargetHealth() > 20000
		end,
		[45460] = function(actionButton) --Verschwinden
			return not IsAutoAttack()
		end,
		[45237] = function(actionButton) -- Verschwinden
			return not IsAutoAttack()
		end,
		[46348] = function()
			--zermalmender Schlag
			if CooldownRunning(63046, 2000) then
				return false
			end
			return HasTarget()
		end,
		[63046] = function()
			--strahlende Unterdrückung
			return TargetHealthPercent() <= 0.15 and TargetHealth() > 12000 and StartCooldown(63046)
		end,
		[61505] = function()
			--widerhallender Elan
			if IsAutoAttack() then
				return PlayerHealthPercent() <= 0.5
			else
				return not IsMounted() or PlayerHealthPercent() <= 0.5
			end
		end,
		[61507] = function()
			--auflösender Elan
			if IsAutoAttack() then
				return PlayerHealthPercent() <= 0.5
			else
				return not IsMounted() or PlayerHealthPercent() <= 0.5
			end
		end,
		[68401] = function(actionButton) --Dreifach Wiederherstellung Potion
			--d( isInCombat , GetSlotCooldownInfo(actionButton) , PlayerMagickaPercent())
			return isInCombat and PlayerMagickaPercent() <= 0.33 and TargetHealth() > 20000
		end,
		[85126] = function()
			-- feuriger Zorn
			return not IsAutoAttack() or PlayerUltimate() >= 237 and TargetHealth() > 300000
		end,
		[85130] = function()
			-- donnernder Zorn
			return not IsAutoAttack() or PlayerUltimate() >= 237 and TargetHealth() > 300000
		end,
		[86003] = function()
			--kreischender Klippenläufer
			return not IsAutoAttack() or not CooldownRunning(86003, 2000) and StartCooldown(86003)
		end,
		[86015] = function()
			--tiefer Riss
			return not IsAutoAttack() or not CooldownRunning(86015, 3000) and StartCooldown(86015)
		end,
		[86027] = function()
			--Schwarminfektion
			return not IsAutoAttack() or isInCombat and not CooldownRunning(86027, 10000) and StartCooldown(86027)
		end,
		[86045] = function()
			--Raubvogel
			return not IsAutoAttack() or isInCombat and not CooldownRunning(86045, 6000) and StartCooldown(86045)
		end,
		[86143] = function()
			--schimmernder Schild
			return not IsAutoAttack() or not CooldownRunning(86143, 6000) and StartCooldown(86143)
		end,
		[86130] = function()
			--Eisbollwerk
			return not IsAutoAttack() or isInCombat and not CooldownRunning(86130, 30000) and StartCooldown(86130)
		end,
		[28306] = function()
			--Durchstoß
			return not IsAutoAttack() or isInCombat and not CooldownRunning(28306, 15000) and StartCooldown(28306)
		end,
		[38250] = function()
			--Durchschlag
			return HasTarget() and not IsTargetBuffedWithAbility(38254) --not CooldownRunning(38250, 15000) and StartCooldown(38250)
		end,
		[85850] = function()
			--auslaugende Ranken
			return not IsAutoAttack() or not CooldownRunning(85850, 10000) and StartCooldown(85850)
		end,
		[86058] = function()
			--Netchbulle
			return not IsAutoAttack() or not CooldownRunning(86058, 22000) and StartCooldown(86058)
		end,
		[86054] = function()
			--blaue Netchkuh
			return not IsAbilityCasted(86054)
		end,
		[85862] = function()
			--verbessertes Wachstum
			return not IsAutoAttack() or PlayerHealthPercent() <= 0.5
		end,
		[92163] = function()
			--Wildheit des Wächters
			return not IsAutoAttack() or PlayerUltimate() >= 75 and TargetHealth() > 300000
		end,
		[86682] = function(actionButton) --Goldküsten Zauberelixier Potion
			return isInCombat and PlayerMagickaPercent() <= 0.20 and TargetHealth() > 20000
		end,
		[86692] = function(actionButton) --Kronen-Kriegerelixier
			return isInCombat and PlayerStamiaPercent() <= 0.20 and TargetHealth() > 20000
		end,
		[92414] = function(actionButton) --Kronen-Überlebenselixier
			return isInCombat and PlayerStamiaPercent() <= 0.33 and TargetHealth() > 20000
		end,
		[103483] = function()
			--Waffe erfüllen
			return isInCombat and not CooldownRunning(103483, 4000) and StartCooldown(103483)
		end,
		[103571] = function()
			--elementare Waffe
			return isInCombat and not CooldownRunning(103571, 2000) and StartCooldown(103571)
		end,
		[103706] = function()
			--Beschleunigung
			return not CooldownRunning(103706, 36000) and StartCooldown(103706)
		end,
		[117805] = function()
			--aufreibender Friedhof
			return (isInCombat or HasTarget()) and not CooldownRunning(117805, 10000) and StartCooldown(117805) and RegisterRecast(117805, 20000)
		end,
		[117749] = function()
			--nachstellende Sprengknochen
			return isInCombat and not CooldownRunning(117749, 2800) and StartCooldown(117749) and RegisterRecast(117749, 8800)
		end,
		[118008] = function()
			--mystischer Siphon
			return isInCombat and HasTarget() and not CooldownRunning(118008, 20000) and StartCooldown(118008)
		end,
		[117773] = function()
			--nachstellender Sprengknochen
			return isInCombat and not CooldownRunning(117773, 2800) and StartCooldown(117773) and RegisterRecast(117773, 8800)
		end,
		[118223] = function()
			--Sense
			return PlayerHealthPercent() <= 0.5 --or not CooldownRunning(118223, 6000) and StartCooldown(118223)
		end,
		[117637] = function()
			-- Querschlagschädel
			return isInCombat and not CooldownRunning(117637, 800) and StartCooldown(117637)
		end,
		[123718] = function()
			-- Querschlagschädel
			return isInCombat and not CooldownRunning(123718, 800) and StartCooldown(123718)
		end,
		[123719] = function()
			-- Querschlagschädel
			return isInCombat and not CooldownRunning(123718, 800) and StartCooldown(123718)
		end,
		[38705] = function()
			-- Bombarde
			return not CooldownRunning(38705, 2000) and StartCooldown(38705)
		end,
		[38687] = function()
			-- gezielter Schuss
			return not CooldownRunning(38687, 2000) and StartCooldown(38687)
		end,
		[113518] = function()
			--Energie absorbieren
			return not IsAutoAttack()
		end,
		--Werkzeuge:
		[8006] = function()
			--Auge des Antiquars
			return not IsAutoAttack()
		end,
		[5884] = function()
			--Fackel
			return not IsAutoAttack()
		end,
		[16723] = function()
			--Reparaturmaterial
			return not IsAutoAttack()
		end,
		[85840] = function()
			--sprießende Saat
			return not CooldownRunning(85840, 6000) and StartCooldown(85840)
		end,
		[40058] = function()
			--erhabene Heilung
			return not CooldownRunning(40058, 9000) and StartCooldown(40058)
		end,
		[28849] = function()
			--Frostwand
			return (isInCombat or HasTarget()) and not CooldownRunning(28849, 12000) and StartCooldown(28849) and RegisterRecast(28849, 12000)
		end,
		[85990] = function()
			--wilder Wächter
			return not IsAutoAttack()
		end,
		[13853] = function()
			--Reparatur
			return not IsAutoAttack()
		end,
		[38906] = function()
			--Todesmantel
			return (isInCombat or HasTarget()) and not CooldownRunning(38906, 10000) and StartCooldown(38906) and RegisterRecast(38906, 10000)
		end,
		[26792] = function()
			--harsche Hiebe
			if CooldownRunning(63046, 2000) then
				return false
			end
			if HasTarget() then
				return not IsBlockActive() and TargetHealth() > 4000 and not CooldownRunning(26792, 800) and StartCooldown(26792)
			else
				return isInCombat and not IsBlockActive() and not CooldownRunning(26792, 800) and StartCooldown(26792)
			end
		end,
		[21763] = function()
			--Macht des Lichts
			return isInCombat and not CooldownRunning(21763, 6000) and StartCooldown(21763)
		end,
		[28448] = function()
			--kritisches Stürmen
			return not IsAutoAttack() or (HasTarget() and PlayerStamiaPercent() >= 0.5 and not CooldownRunning(28448, 8000)) and StartCooldown(28448) and RegisterRecast(28448, 16000)
		end,
		[38788] = function()
			--kritisches Toben
			return not IsAutoAttack() or (HasTarget() and PlayerStamiaPercent() >= 0.5 and not CooldownRunning(38788, 8000)) and StartCooldown(38788) and RegisterRecast(38788, 16000)
		end,
		[22237] = function()
			--wiederherstellender Fokus
			return (isInCombat or HasTarget()) and not CooldownRunning(22237, 10000) and StartCooldown(22237) and RegisterRecast(22237, 20000)
		end,
		[22259] = function()
			--Ritual der Vergeltung
			return (isInCombat or HasTarget()) and not CooldownRunning(22259, 6000) and StartCooldown(22259) and RegisterRecast(22259, 12000)
		end,
		[20919] = function()
			--Trennen
			return (isInCombat or HasTarget()) and not CooldownRunning(20919, 6000) and StartCooldown(20919) and RegisterRecast(20919, 12000)
		end,
		[38745] = function()
			--Schnitzen
			return (isInCombat or HasTarget()) and not CooldownRunning(38745, 6000) and StartCooldown(38745) and RegisterRecast(38745, 12000)
		end,
		[29552] = function()
			--sicherer Stand
			return HasTarget() and TargetHealth() > 2000000 and not CooldownRunning(29552, 6000) and StartCooldown(29552) and RegisterRecast(29552, 20000)
		end,
		[28304] = function()
			--niederer Schnit
			return HasTarget() and not CooldownRunning(28304, 12000) and StartCooldown(28304) and RegisterRecast(28304, 12000)
		end,
		[29556] = function()
			--Ausweichen
			return not IsAutoAttack() or ((isInCombat or HasTarget()) and PlayerHealthPercent() <= 0.5 and not CooldownRunning(29556, 17000) and StartCooldown(29556) and RegisterRecast(29556, 18000))
		end,
		[39192] = function()
			--Entrinnen
			return not IsAutoAttack() or ((isInCombat or HasTarget()) and PlayerHealthPercent() <= 0.5 and not CooldownRunning(39192, 17000) and StartCooldown(39192) and RegisterRecast(39192, 18000))
		end,
		[38264] = function()
			--heroischer Schnit
			return HasTarget() and not CooldownRunning(38264, 12000) and StartCooldown(38264) and RegisterRecast(38264, 12000)
		end,
		[21776] = function()
			--Eklipse
			return HasTarget() and not CooldownRunning(21776, 6000) and StartCooldown(21776) and RegisterRecast(21776, 12000)
		end,
		[22223] = function()
			--Ritus des Übergangs
			return PlayerUltimate() >= 123 and PlayerStamiaPercent() <= 0.5 and not CooldownRunning(22223, 4000) and StartCooldown(22223) and RegisterRecast(22223, 12000)
		end,
		[22229] = function()
			--Gedenken
			return PlayerUltimate() >= 123 and PlayerHealthPercent() <= 0.5 and not CooldownRunning(22223, 4000) and StartCooldown(22223) and RegisterRecast(22223, 12000)
		end,
		[26821] = function()
			--Buße
			return isInCombat and PlayerStamiaPercent() <= 0.5 and not CooldownRunning(26821, 4000) and StartCooldown(26821) and RegisterRecast(22223, 24000)
		end,
		[21157] = function()
			--geborgene Klinge
			return isInCombat and HasTarget() and not CooldownRunning(21157, 6000) and StartCooldown(21157) and RegisterRecast(21157, 20000)
		end,
		[38914] = function()
			--verhüllte Dolche
			return isInCombat and HasTarget() and not CooldownRunning(38914, 6000) and StartCooldown(38914) and RegisterRecast(38914, 20000)
		end,
		[46331] = function()
			--Kristallwaffe
			return not IsAutoAttack() or (isInCombat and HasTarget() and not CooldownRunning(46331, 3000) and StartCooldown(46331) and RegisterRecast(46331, 6000))
		end,
		[24636] = function()
			--Zwielichtquälerin beschwören
			return not IsAutoAttack()
		end,
		[23316] = function()
			--explosiven Begleiter beschwören
			return not IsAutoAttack()
		end,
		[77182] = function()
			--explosiven Begleiter beschwören
			return not IsAutoAttack()
		end,
		[77140] = function()
			--erzürnte Zwielichtquälerin
			return not IsAutoAttack() or (HasTarget() and PlayerHealthPercent() > 0.5 and not CooldownRunning(77140, 20000) and StartCooldown(77140) and RegisterRecast(46331, 20000))
		end,
		[24328] = function()
			--daedrische Beute
			return HasTarget() and PlayerMagicka() >= 2070 and not CooldownRunning(24328, 6000) and StartCooldown(24328)
		end,
		[23492] = function()
			--größerer Sturmatronach
			return HasTarget() and PlayerUltimate() >= 150 and TargetHealth() > 300000 and currentBar == ACTIVE_WEAPON_PAIR_MAIN and TargetIsInRange()
		end,
		[40489] = function()
			--Eiskomet
			return HasTarget() and PlayerUltimate() >= 190 and TargetHealth() > 300000 and currentBar == ACTIVE_WEAPON_PAIR_MAIN and TargetIsInRange()
		end,
		[22095] = function()
			--solarer Ausbruch
			return not IsAutoAttack() or ((isInCombat and HasTarget()) and not CooldownRunning(22095, 6000) and StartCooldown(22095) and RegisterRecast(22095, 7000))
		end,
		[86156] = function()
			--Arktisstoß
			return not IsAutoAttack() or ((isInCombat and HasTarget()) and not CooldownRunning(86156, 19000) and StartCooldown(86156) and RegisterRecast(86156, 20000))
		end
	}
	local function doNotKillMaelstromHealer()
		local name = GetUnitNameHighlightedByReticle()
		return name ~= "Argonier-Pflegerin" and name ~= "Argonier-Pfleger"
	end

	function ZO_ActionBar_CanUseActionSlots(...)
		local stack = debug.traceback(nil, 2)
		local actionButton = stackToActionButton[stack]
		if not actionButton then
			actionButton = tonumber(stack:match("ACTION_BUTTON_(%d+)"))
			stackToActionButton[stack] = actionButton
		end
		if actionButton == 9 then -- 9 is the quickslot button. Will be translated to the current quickslot
			local hotbarCategory = HOTBAR_CATEGORY_QUICKSLOT_WHEEL
			actionButton = GetCurrentQuickslot()
			local latency = math.min(GetLatency() / 2, 200)
			local allow = not ActionSlotHasCostFailure(actionButton, hotbarCategory) and not ActionSlotHasNonCostStateFailure(actionButton, hotbarCategory) -- lastAllowedAction == 0 or not IsAutoAttack()
			allow = allow and GetSlotCooldownInfo(actionButton, hotbarCategory) <= latency and checkAction(actionButton, hotbarCategory)
			if allow then
				return orgZO_ActionBar_CanUseActionSlots(...)
			end
		else
			local isKeyDown = not keyWasDown[actionButton]
			--df("button %i keydown %s", actionButton, tostring(isKeyDown))
			--df("button %i auto %s", actionButton, tostring(IsAutoAttack()))
			if isKeyDown then
				keyWasDown[actionButton] = true
				local lastAction = GetGameTimeMilliseconds() - lastAllowActionTime
				local latency = GetLatency() / 2
				local allow = lastAction >= latency and (not g_activeWeaponSwapInProgress or not IsAutoAttack())
				if allow then
					local hotbarCategory = currentBar == ACTIVE_WEAPON_PAIR_MAIN and HOTBAR_CATEGORY_PRIMARY or HOTBAR_CATEGORY_BACKUP
					local noCooldown = GetSlotCooldownInfo(actionButton, hotbarCategory) <= latency
					allow = noCooldown and not ActionSlotHasCostFailure(actionButton, hotbarCategory) and not ActionSlotHasNonCostStateFailure(actionButton, hotbarCategory)
					--allow = allow and lastAction >= latency and doNotKillMaelstromHealer() and checkAction(actionButton)
					allow = allow and lastAction >= latency and (lastAllowedAction == 0 or not IsAutoAttack()) and doNotKillMaelstromHealer() and checkAction(actionButton)
				end
				wasAllowed[actionButton] = allow
				if allow then
					-- if lastAction >= (latency * 2) then
					-- 	d("zum langsam")
					-- end
					return orgZO_ActionBar_CanUseActionSlots(...)
				else
					-- ZO_ActionBar_CanUseActionSlots will be called twice for actionButton 1-8, only.
					if lastAllowedAction ~= 0 then
						--d("skip because other action choosen")
					elseif lastAction < latency then
						--d("skip because latency")
					elseif currentBar == ACTIVE_WEAPON_PAIR_BACKUP and lastAllowedAction == 0 and actionButton == 4 then --Backbar
						--d("Go Front Bar!")
						needBarSwap = ACTIVE_WEAPON_PAIR_MAIN
					end
				end
			elseif wasAllowed[actionButton] then
				keyWasDown[actionButton] = false
				return orgZO_ActionBar_CanUseActionSlots(...)
			else
				keyWasDown[actionButton] = false
			end
		end
	end

	local orgIsShowingSkills = SKILLS_FRAGMENT.IsShowing
	function SKILLS_FRAGMENT.IsShowing(...)
		if not IsAutoAttack() then
			return orgIsShowingSkills(...)
		end
		return true
	end

	local selfHealBar
	local orgCanCycleHotbars = ZO_ActionBarAssignmentManager.CanCycleHotbars
	function ZO_ActionBarAssignmentManager.CanCycleHotbars(...)
		if not IsAutoAttack() then
			return orgCanCycleHotbars(...)
		end
		if PlayerHealthPercent() <= 0.5 then
			needBarSwap = selfHealBar
		elseif TargetIsInRange() and TargetHealth() < 30000 then
			needBarSwap = ACTIVE_WEAPON_PAIR_MAIN
		else
			for ability, bar in pairs(abilityBar) do
				if currentBar ~= bar and NeedRecast(ability) then
					df("NeedRecast %i", ability)
					needBarSwap = bar
					if not g_activeWeaponSwapInProgress and recast[abilityId] then
						recast[abilityId] = recast[abilityId] + 6000
					end
					break
				end
			end
		end
		if not g_activeWeaponSwapInProgress and GetActiveWeaponPairInfo() ~= needBarSwap then
			--d("Do bar swap")
			return true
		else
			return false
		end
	end

	local function OnCombatStateChange(eventCode, inCombat)
		if inCombat and TargetHealth() >= 200000 then
			needBarSwap = ACTIVE_WEAPON_PAIR_BACKUP
		end
		if not inCombat then
			needBarSwap = ACTIVE_WEAPON_PAIR_BACKUP
		end
		isInCombat = inCombat
		SetCurrentQuickslot(isInCombat and 8 or 4)

		if not inCombat then
			ClearCooldown(22262)
			ClearCooldown(26869)
			ClearCooldown(38845)
			ClearCooldown(39012)
			ClearCooldown(39018)
			ClearCooldown(35750)
			ClearCooldown(21763)
			ClearCooldown(38788)
			ClearCooldown(86130)
			ClearCooldown(38250)
			ClearCooldown(28304)
			ClearCooldown(39073)
			ClearCooldown(117805)
		end
	end
	em:RegisterForEvent("VOTANS_COMBAT_HELPER", EVENT_PLAYER_COMBAT_STATE, OnCombatStateChange)
	OnCombatStateChange(0, false)

	local function OnWeaponBarSwap(event, activeBar)
		currentBar = activeBar
	end
	em:RegisterForEvent("VOTANS_COMBAT_HELPER", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnWeaponBarSwap)

	local orgStartInteraction = ZO_UtilityWheel_Manager.StartInteraction
	function ZO_UtilityWheel_Manager.StartInteraction(...)
		if not IsAutoAttack() then
			return orgStartInteraction(...)
		end
	end
	local orgStopInteraction = ZO_UtilityWheel_Manager.StopInteraction
	function ZO_UtilityWheel_Manager.StopInteraction(...)
		if not IsAutoAttack() then
			return orgStopInteraction(...)
		end
		return false --We do not use the menu
	end

	local selfHeals = {
		[61505] = true,
		[61507] = true,
		[22253] = true,
		[22256] = true
	}
	local function OnPlayerActivated()
		local currentBar = GetActiveWeaponPairInfo()
		local found = false
		for actionButton = 3, 8 do
			local actionId = GetSlotBoundId(actionButton)
			if selfHeals[actionId] then
				found = true
				break
			end
		end
		if found then
			selfHealBar = currentBar
		else
			selfHealBar = currentBar == ACTIVE_WEAPON_PAIR_MAIN and ACTIVE_WEAPON_PAIR_BACKUP or ACTIVE_WEAPON_PAIR_MAIN
		end
		df("SelfHealBar %i", selfHealBar)
		em:UnregisterForEvent("VOTANS_COMBAT_HELPER_FIND_SELFHEAL", EVENT_PLAYER_ACTIVATED)
	end
	em:RegisterForEvent("VOTANS_COMBAT_HELPER_FIND_SELFHEAL", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

-- do
-- 	local DeathType = DEATH.types["Death"]
-- 	local orgGetButtonByKeybind = DeathType.GetButtonByKeybind
-- 	function DeathType:GetButtonByKeybind(keybind)
-- 		if (keybind == "DEATH_PRIMARY") then
-- 			return self.buttons[1]
-- 		elseif (keybind == "DEATH_SECONDARY") then
-- 			return self.buttons[1].enabled and self.buttons[1] or self.buttons[2]
-- 		end
-- 	end
-- end

--do
--	for _, keybindDescriptor in pairs(ANTIQUITY_JOURNAL_KEYBOARD.keybindStripDescriptor) do
--		local orgName = keybindDescriptor.name
--		keybindDescriptor.name = function()
--			if ANTIQUITY_JOURNAL_KEYBOARD:GetMouseOverTile() then
--				return orgName()
--			end
--			d("ohoh!!")
--			return ""
--		end
--	end
--end

--do
--	local orgUpdateChatterOptions = INTERACTION.UpdateChatterOptions
--	function INTERACTION.UpdateChatterOptions(...)
--		local self, chatterOptionCount = ...
--		if chatterOptionCount and (chatterOptionCount < 0 or chatterOptionCount > 10) then
--			df("ohoh! %i", chatterOptionCount)
--			return
--		end
--		return orgUpdateChatterOptions(...)
--	end
--end

-- local itemSet
-- local firstCall
-- local orgClearLines = ItemTooltip.ClearLines
-- function ItemTooltip.ClearLines(...)
-- 	itemSet = false
-- 	return orgClearLines(...)
-- end
-- local orgSetLink = ItemTooltip.SetLink
-- function ItemTooltip.SetLink(...)
-- 	if itemSet then
-- 		error(firstCall)
-- 	else
-- 		firstCall = debug.traceback()
-- 	end
-- 	itemSet = true
-- 	return orgSetLink(...)
-- end
-- local orgSetBagItem = ItemTooltip.SetBagItem
-- function ItemTooltip.SetBagItem(...)
-- 	if itemSet then
-- 		d(firstCall)
-- 		return
-- 	else
-- 		firstCall = debug.traceback()
-- 	end
-- 	itemSet = true
-- 	return orgSetBagItem(...)
-- end

-- local orgMouseEnter = ZO_InventorySlot_OnMouseEnter
-- function ZO_InventorySlot_OnMouseEnter(...)
-- 	InitializeTooltip(ItemTooltip)
-- 	InitializeTooltip(InformationTooltip)
-- 	return orgMouseEnter(...)
-- end

-- ZO_PostHook(
-- 	DUNGEON_FINDER_KEYBOARD.navigationTree.templateInfo.ZO_ActivityFinderTemplateNavigationEntry_Keyboard,
-- 	"setupFunction",
-- 	function(node, control, data, open, userRequested, enabled)
-- 		--SLASH_COMMANDS["/zgoo"]({node, control, data, open, userRequested, enabled})
-- 		-- control.text.selected = data.isSelected
-- 		-- control.text.GetTextColor = function(control)
-- 		-- 	SLASH_COMMANDS["/zgoo"](control)
-- 		-- 	return ZO_ERROR_COLOR:UnpackRGB()
-- 		-- end
-- 		ZO_SelectableLabel_SetNormalColor(control.text, data.isSelected and ZO_ERROR_COLOR or ZO_NORMAL_TEXT)

-- 		control.text:RefreshTextColor()
-- 	end
-- )
-- ZO_PostHook(
-- 	_G,
-- 	"ZO_ActivityFinderTemplateNavigationEntryKeyboard_OnClicked",
-- 	function(control, button)
-- 		ZO_SelectableLabel_SetNormalColor(control.text, control.node.data.isSelected and ZO_ERROR_COLOR or ZO_NORMAL_TEXT)
-- 		--control.text.selected = control.node.data.isSelected

-- 		control.text:RefreshTextColor()
-- 	end
-- )

SLASH_COMMANDS["/craft"] = function()
	JumpToHouse("@Gratozen")
end

SLASH_COMMANDS["/guildhall"] = function()
	JumpToHouse("@SanchoPansa")
end
