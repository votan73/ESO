local addon = {
	name = "SetManager",
	playerDefaults =
	{
		sets = { }
	},
	accountDefaults =
	{
		sets = { }
	},
}

local am = GetAnimationManager()
local wm = GetWindowManager()
local em = GetEventManager()

local function OnUnitCreated()
	em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	SetManager_CharacterPaperDoll:SetTexture(GetUnitSilhouetteTexture("player"))
	-- RefreshWornInventory()
	-- RefreshBackUpWeaponSlotStates()
end

local function PlayerDeactivated()
end

function addon:InitWindow()
	local control
	control = CreateControlFromVirtual("SetManager_Character", nil, "SetManager_Character_Template")
	control:SetAnchor(TOPLEFT, ZO_SharedWideLeftPanelBackground, TOPLEFT, 0, -40)
	control:SetAnchor(BOTTOMLEFT, ZO_SharedWideLeftPanelBackground, BOTTOMLEFT, 0, -30)

	addon.windowSet = control
	SETMANAGER_CHARACTER_FRAGMENT = ZO_FadeSceneFragment:New(addon.windowSet, false, 0)
	STATS_SCENE:AddFragment(THIN_LEFT_PANEL_BG_FRAGMENT)
	STATS_SCENE:AddFragment(SETMANAGER_CHARACTER_FRAGMENT)

	em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, OnUnitCreated)
	em:RegisterForEvent(addon.name, EVENT_PLAYER_DEACTIVATED, PlayerDeactivated)
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.player = ZO_SavedVars:New("SetManager_Data", 1, nil, addon.playerDefaults, nil)
	addon.account = ZO_SavedVars:NewAccountWide("SetManager_Data", 1, nil, addon.accountDefaults, nil)

	addon:InitWindow()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

SET_MANAGER = addon