local addon = {
	name = "VotansImprovedGroupFinder"
}
assert(GROUP_FINDER_KEYBOARD, "GROUP_FINDER_KEYBOARD not found")

local em = GetEventManager()
--local am = GetAnimationManager()

function addon:InitializeKeybindStripDescriptors()
	if self.keybindStripDescriptor then
		return
	end

	self.keybindStripDescriptor = {
		alignment = KEYBIND_STRIP_ALIGN_RIGHT,
		{
			name = GetString(SI_VOTANS_IMPROVED_GROUP_FINDER_RECENT),
			keybind = "UI_SHORTCUT_SECONDARY",
			callback = function()
				self:LoadGroupFinderSettings(self.settings.recent)
				PlaySound(SOUNDS.DEFAULT_CLICK)
			end,
			visible = function(keybindButtonDescriptor)
				return GROUP_FINDER_KEYBOARD.createGroupListingContent:GetFragment():IsShowing()
			end,
			enabled = function()
				return GROUP_FINDER_KEYBOARD.createGroupListingContent.userTypeData:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT and next(self.settings.recent) ~= nil
			end
		}
	}
end

function addon:LoadGroupFinderSettings(result)
	result = result or self.settings.recent
	if not result then
		return
	end

	local userTypeData = GROUP_FINDER_KEYBOARD.createGroupListingContent.userTypeData

	userTypeData:SetCategory(result.category)
	userTypeData:SetPrimaryOption(result.veteranDifficulty and 2 or 1)
	userTypeData:SetSecondaryOption(result.secondaryOption)

	userTypeData:SetSize(result.size)

	userTypeData:SetTitle(result.title)
	userTypeData:SetDescription(result.description or "")

	userTypeData:SetPlaystyle(result.playstyle)

	userTypeData:SetGroupRequiresChampion(result.requireChampion)
	userTypeData:SetChampionPoints(result.championPoints)

	userTypeData:SetGroupRequiresVOIP(result.requireVOIP)

	userTypeData:SetGroupRequiresInviteCode(result.requireInviteCode)
	userTypeData:SetInviteCode(result.inviteCode)

	userTypeData:SetGroupAutoAcceptRequests(result.autoAcceptRequests)

	userTypeData:SetGroupEnforceRoles(result.enforceRoles)
	local roleStatus = result.roleStatus
	userTypeData:SetDesiredRoleCountAtEdit(LFG_ROLE_DPS, roleStatus[LFG_ROLE_DPS])
	userTypeData:SetDesiredRoleCountAtEdit(LFG_ROLE_TANK, roleStatus[LFG_ROLE_TANK])
	userTypeData:SetDesiredRoleCountAtEdit(LFG_ROLE_HEAL, roleStatus[LFG_ROLE_HEAL])
	-- And again, due to some validations???
	userTypeData:SetDesiredRoleCountAtEdit(LFG_ROLE_DPS, roleStatus[LFG_ROLE_DPS])
	userTypeData:SetDesiredRoleCountAtEdit(LFG_ROLE_TANK, roleStatus[LFG_ROLE_TANK])
	userTypeData:SetDesiredRoleCountAtEdit(LFG_ROLE_HEAL, roleStatus[LFG_ROLE_HEAL])

	GROUP_FINDER_KEYBOARD.createGroupListingContent:Refresh()
	GROUP_FINDER_KEYBOARD.createGroupListingContent:UpdateRoles()
end

function addon:SaveGroupFinderSettings(result)
	result = result or {}
	local userTypeData = GROUP_FINDER_KEYBOARD.createGroupListingContent.userTypeData
	result.title = userTypeData:GetTitle()
	result.category = userTypeData:GetCategory()
	result.size = userTypeData:GetSize()
	result.description = userTypeData:GetDescription()
	result.playstyle = userTypeData:GetPlaystyle()

	local button = GROUP_FINDER_KEYBOARD.createGroupListingContent.difficultyRadioButtonGroup:GetClickedButton()
	if button then
		result.veteranDifficulty = button.dungeonDifficulty == 2
	end
	result.secondaryOption = GROUP_FINDER_KEYBOARD.createGroupListingContent.secondaryOptionDropdown:GetSelectedItemData().value

	result.roleStatusCount = userTypeData:GetRoleStatusCount()
	result.requireChampion = userTypeData:DoesGroupRequireChampion()
	result.requireVOIP = userTypeData:DoesGroupRequireVOIP()
	result.requireInviteCode = userTypeData:DoesGroupRequireInviteCode()
	result.autoAcceptRequests = userTypeData:DoesGroupAutoAcceptRequests()
	result.championPoints = userTypeData:GetChampionPoints()
	result.inviteCode = userTypeData:GetInviteCode()

	result.enforceRoles = userTypeData:DoesGroupEnforceRoles()
	local roleStatus = {}
	roleStatus[LFG_ROLE_DPS] = userTypeData:GetRoleStatusCount(LFG_ROLE_DPS)
	roleStatus[LFG_ROLE_TANK] = userTypeData:GetRoleStatusCount(LFG_ROLE_TANK)
	roleStatus[LFG_ROLE_HEAL] = userTypeData:GetRoleStatusCount(LFG_ROLE_HEAL)
	result.roleStatus = roleStatus

	return result
end

function addon:Initialize()
	VotansImprovedGroupFinder_Data = VotansImprovedGroupFinder_Data or {}
	local lang = GetCVar("language.2")
	VotansImprovedGroupFinder_Data[lang] = VotansImprovedGroupFinder_Data[lang] or {}

	self.settings = VotansImprovedGroupFinder_Data[lang]
	self.settings.recent = self.settings.recent or {}

	local fragment = GROUP_FINDER_KEYBOARD.createGroupListingContent:GetFragment()
	local function stateChange(oldState, newState)
		if newState == SCENE_SHOWING then
			--RebuildList()
		elseif newState == SCENE_SHOWN then
			self:InitializeKeybindStripDescriptors()
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
		elseif newState == SCENE_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
		end
	end
	fragment:RegisterCallback("StateChange", stateChange)

	local function saveGroupFinderSettings(groupfinder, result)
		if result == GROUP_FINDER_ACTION_RESULT_SUCCESS then
			self:SaveGroupFinderSettings(self.settings.recent)
		end
	end
	ZO_PreHook(ZO_GroupFinder_Keyboard, "OnGroupListingRequestCreateResult", saveGroupFinderSettings)
	ZO_PreHook(ZO_GroupFinder_Keyboard, "OnGroupListingRequestEditResult", saveGroupFinderSettings)

	--Preserve selection, if possible
	local orgPopulateSecondaryDropdown = GROUP_FINDER_KEYBOARD.createGroupListingContent.PopulateSecondaryDropdown
	function GROUP_FINDER_KEYBOARD.createGroupListingContent.PopulateSecondaryDropdown(groupfinder, ...)
		local textToFind
		local dropdown = groupfinder.secondaryOptionDropdown
		if dropdown then
			local selectedItem = dropdown:GetSelectedItemData()
			textToFind = selectedItem and selectedItem.name
		end
		orgPopulateSecondaryDropdown(groupfinder, ...)
		if not dropdown then
			return
		end
		for _, item in ipairs(dropdown.m_sortedItems) do
			if item.name == textToFind then
				dropdown:SetSelected(item.value)
				break
			end
		end
	end
end

local function OnAddOnLoaded(event, addonName)
	em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	addon:Initialize()
end

em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, OnAddOnLoaded)

VOTANS_IMPROVED_GROUP_FINDER = addon
