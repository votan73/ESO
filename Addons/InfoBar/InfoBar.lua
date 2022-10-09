local InfoBarApp = {
	name = "InfoBar",
	BufferTable = {}
}

function InfoBarApp.AddOnLoaded(event, addonName)
	if (addonName ~= InfoBarApp.name) then
		return
	end
	EVENT_MANAGER:UnregisterForEvent(InfoBarApp.name, EVENT_ADD_ON_LOADED)
	InfoBarApp:Init()
end

function InfoBarApp:Init()
	self.inCombat = IsUnitInCombat("player")
	self.maxTutorial = GetNumTutorials()
	self.curTutorial = math.random(1, self.maxTutorial)
	InfoBarApp:CheckHide()
	self:ShowClock()
	self.ShowBagSpace()
	self.ShowRepairStatus()
	self.fragment = ZO_HUDFadeSceneFragment:New(InfoBarForm)
	self.fragment:SetHiddenForReason("combat", self.inCombat)
	self.fragment:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if (newState == SCENE_FRAGMENT_SHOWING) then
				self:ShowClock()
				self.ShowRepairStatus()
			end
		end
	)
	HUD_SCENE:AddFragment(self.fragment)
	LOOT_SCENE:AddFragment(self.fragment)
	if TRIBUTE_SCENE then
		TRIBUTE_SCENE:AddFragment(self.fragment)
	end
	EVENT_MANAGER:RegisterForUpdate(
		"InfoBarTick",
		5000,
		function(...)
			InfoBarApp:OnUpdate()
		end
	)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, self.OnPlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(
		self.name,
		EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
		function(eventCode, bagId, slotId, isNewItem, itemSoundCategory, updateReason)
			self.ShowBagSpace()
		end
	)
	EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INVENTORY_FULL_UPDATE, self.ShowBagSpace)
	EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_FULL_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INVENTORY_BOUGHT_BAG_SPACE, self.ShowBagSpace)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MOUNT_INFO_UPDATED, self.ShowBagSpace)
	FENCE_MANAGER:RegisterCallback("FenceUpdated", self.ShowBagSpace)

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_JUSTICE_BOUNTY_PAYOFF_AMOUNT_UPDATED, self.ShowRepairStatus)
	-- CALLBACK_MANAGER:RegisterCallback("PlayerIdleStateChanged", function(newState, oldState)
	--  InfoBarApp.idle = newState
	-- end)
	CALLBACK_MANAGER:RegisterCallback(
		"PlayerIdleHeartBeat",
		function(since)
			local emote = self.idlePlayList[since % 349]
			local cmd = SLASH_COMMANDS[emote]
			if cmd then
				cmd()
			end
		end
	)
end

function InfoBarApp:BufferReached(key, buffer)
	local data = self.BufferTable[key]
	if data == nil then
		data = {}
		self.BufferTable[key] = data
		data.now = GetFrameTimeSeconds()
		data.last = data.now
		return false
	end
	data.now = GetFrameTimeSeconds()
	if (data.now - data.last) >= buffer then
		data.last = data.now
		return true
	end
	return false
end

function InfoBarApp:OnUpdate()
	if self.fragment:IsHidden() then
		return
	end

	if self:BufferReached("Clock", 10) then
		self:ShowClock()
	end
	if self:BufferReached("Repair", 60) then
		self.ShowRepairStatus()
	end
end

function InfoBarApp.OnPlayerCombatState(event, inCombat)
	if inCombat ~= InfoBarApp.inCombat then
		InfoBarApp.inCombat = inCombat
		InfoBarApp.fragment:SetHiddenForReason("combat", inCombat)
		InfoBarApp:CheckHide()
		if (not inCombat) then
			InfoBarApp.ShowRepairStatus()
			InfoBarApp:OnUpdate()
		end
	end
end

function InfoBarApp:CheckHide()
	-- InfoBarForm:SetHidden(self.inCombat)
end

function InfoBarApp:ShowClock()
	InfoBarFormClock:SetText(FormatTimeSeconds(GetSecondsSinceMidnight(), TIME_FORMAT_STYLE_CLOCK_TIME, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR, TIME_FORMAT_DIRECTION_NONE))

	local igSecondsPerDay = 20955
	local rlTimeStamp = GetTimeStamp()
	local inGameTime = (rlTimeStamp % igSecondsPerDay) * 86400 / igSecondsPerDay
	InfoBarFormInGameTime:SetText(FormatTimeSeconds(inGameTime, TIME_FORMAT_STYLE_CLOCK_TIME, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR, TIME_FORMAT_DIRECTION_NONE))
end

function InfoBarApp.ShowBagSpace()
	local function Show()
		EVENT_MANAGER:UnregisterForUpdate("InfoBarShowBagSpace")
		local text = string.format("|t25:25:esoui/art/mainmenu/menubar_inventory_down.dds|t%i/%i\n|t25:25:esoui/art/vendor/vendor_tabicon_fence_down.dds|t%i/%i", GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK), FENCE_MANAGER:GetNumTransactionsUsed(ZO_MODE_STORE_SELL_STOLEN), FENCE_MANAGER:GetNumTotalTransactions(ZO_MODE_STORE_SELL_STOLEN))
		InfoBarFormBag:SetText(text)
		InfoBarFormBag:SetHeight(50)
	end
	EVENT_MANAGER:UnregisterForUpdate("InfoBarShowBagSpace")
	EVENT_MANAGER:RegisterForUpdate("InfoBarShowBagSpace", 250, Show)
end

do
	local text = {}
	function InfoBarApp.ShowRepairStatus()
		ZO_ClearNumericallyIndexedTable(text)
		local costs = GetRepairAllCost()
		if costs > 0 then
			local conditions = 0
			local numItems = 0
			local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(BAG_WORN)
			local cost = 0
			for _, itemData in pairs(bagCache) do
				if DoesItemHaveDurability(itemData.bagId, itemData.slotIndex) then
					conditions = conditions + itemData.condition
					 -- GetItemCondition(itemData.bagId, itemData.slotIndex)
					numItems = numItems + 1
				end
			end
			text[#text + 1] = "|t25:25:esoui/art/vendor/vendor_tabicon_repair_down.dds|t"
			text[#text + 1] = numItems > 0 and math.floor(conditions / numItems) or 0
			text[#text + 1] = "% |t16:16:esoui/art/currency/currency_gold.dds|t "
			text[#text + 1] = costs
		end
		costs = GetFullBountyPayoffAmount()
		if costs > 0 then
			if #text > 0 then
				text[#text + 1] = "\n"
				InfoBarFormRepair:SetHeight(50)
			end
			text[#text + 1] = "|t25:25:esoui/art/vendor/vendor_tabicon_fence_down.dds|t"
			text[#text + 1] = costs
			text[#text + 1] = " |t16:16:esoui/art/currency/currency_gold.dds|t "
		else
			InfoBarFormRepair:SetHeight(25)
		end
		InfoBarFormRepair:SetText(table.concat(text))
	end
end

-- function InfoBarApp:ShowTutorial()
-- if not AFK.idle then return end

-- local index = self.curTutorial
-- local tutorType, title, description
-- while (index >= 1) do
-- 	index = index - 1
-- 	if (index <= 0) then index = self.maxTutorial end
-- 	tutorType = GetTutorialType(index)
-- 	if (tutorType == TUTORIAL_TYPE_HUD_INFO_BOX or tutorType == TUTORIAL_TYPE_UI_INFO_BOX) then
-- 		title, description = GetTutorialInfo(index)
-- 		if (title ~= nil) then
-- 			d(zo_strjoin(nil, "\n|c2dc50e", title, "|r\n", description))
-- 		else
-- 			d(zo_strjoin(nil, "\n", description))
-- 		end
-- 		break
-- 	end
-- end
-- self.curTutorial = index
-- end

local function InvertFade(self, progress)
	InfoBarForm:SetAlpha(1 - progress)
end
ZO_PreHook(PLAYER_PROGRESS_BAR, "SetFadeAlpha", InvertFade)

EVENT_MANAGER:RegisterForEvent(InfoBarApp.name, EVENT_ADD_ON_LOADED, InfoBarApp.AddOnLoaded)
