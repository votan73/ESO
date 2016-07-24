local addon = {
	name = "SetManager",
	playerDefaults =
	{
		sets = { },
		worn = { },
		mode = "INVENTORY",
		quality = ITEM_QUALITY_MAGIC,
	},
	accountDefaults =
	{
		sets = { },
		templates = { },
	},
	setCategory =
	{
		NonCraftable = "NON_CRAFTABLE",
		Craftable = "CRAFTABLE",
	}
}

-- local am = GetAnimationManager()
local wm = GetWindowManager()
local em = GetEventManager()

function addon:Init()
	SLASH_COMMANDS["/setm"] = function(...) addon:cmdSetManager(...) end

	local LMM2 = LibStub("LibMainMenu-2.0")
	LMM2:Init()
	self.LMM2 = LMM2

	self.Designer:Init()
	self:InitInventoryScan()
end

local function PlayerActivated()
	em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	-- reserved
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.player = ZO_SavedVars:New("SetManager_Data", 1, nil, addon.playerDefaults, nil)
	addon.account = ZO_SavedVars:NewAccountWide("SetManager_Data", 1, nil, addon.accountDefaults, nil)

	local templates = addon.account.templates
	if #templates == 0 then
		templates[#templates + 1] = { }
	end

	addon:Init()

	em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, PlayerActivated)
end

function addon:ToggleEditorScene()
	self.LMM2:SelectMenuItem(self.name)
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

SET_MANAGER = addon