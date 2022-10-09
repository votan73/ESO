local TROUBLEMAKER = {
	version = "0.3",
	name = "Troublemaker",
	author = "@DeanGrey (US)",
	attackForReason = { },
}

--------------------------------------------------------------------------
------------------------   Default Settings   ----------------------------
--------------------------------------------------------------------------

local defaults = {
	lognotify = true,
	logpassive = true,
	kosoverride = true,
	bountypaid = true,
	alertpos = "Top Right",
}

--------------------------------------------------------------------------
----------------------------   LAM Menu   --------------------------------
--------------------------------------------------------------------------
local function BuildSettingsMenu()
	local panelData = {
		type = "panel",
		name = TROUBLEMAKER.name,
		displayName = ZO_HIGHLIGHT_TEXT:Colorize(TROUBLEMAKER.name),
		author = TROUBLEMAKER.author,
		version = TROUBLEMAKER.version,
		slashCommand = "/troublemaker",
		-- (optional) will register a keybind to open to this panel
		registerForRefresh = true,
		-- boolean (optional) (will refresh all options controls when a setting is changed and when the panel is shown)
		registerForDefaults = true,-- boolean (optional) (will set all options controls back to default values)
	}

	local combatState = { ["aggressive"] = 1, ["passive"] = 0 }

	local optionsTable = {
		{
			type = "header",
			name = ZO_HIGHLIGHT_TEXT:Colorize("Login"),
		},
		-- Login state aggressive notification
		{
			type = "checkbox",
			name = "Aggression alert on login",
			tooltip = "If you are aggressive towards innocents, display an alert.",
			getFunc = function() return TROUBLEMAKER.settings.lognotify end,
			setFunc = function(value) TROUBLEMAKER.settings.lognotify = value end,
			default = defaults.lognotify,
		},
		-- Login state change to passive
		{
			type = "checkbox",
			name = "Login as passive if not KOS",
			tooltip = "Upon login you will become passive if not kill on sight.",
			getFunc = function() return TROUBLEMAKER.settings.logpassive end,
			setFunc = function(value) TROUBLEMAKER.settings.logpassive = value end,
			default = defaults.logpassive,
		},
		{
			type = "header",
			name = ZO_HIGHLIGHT_TEXT:Colorize("Reactions"),
		},
		-- Override passive if kill on sight
		{
			type = "checkbox",
			name = "Aggressive when KOS",
			tooltip = "If you become kill on sight, disable being passive.",
			getFunc = function() return TROUBLEMAKER.settings.kosoverride end,
			setFunc = function(value) TROUBLEMAKER.settings.kosoverride = value end,
			default = defaults.kosoverride,
		},
		-- Become passive after paying off bounty
		{
			type = "checkbox",
			name = "Passive after bounty paid",
			tooltip = "If the bounty is paid then become passive.",
			getFunc = function() return TROUBLEMAKER.settings.bountypaid end,
			setFunc = function(value) TROUBLEMAKER.settings.bountypaid = value end,
			default = defaults.bountypaid,
		},
		{
			type = "header",
			name = ZO_HIGHLIGHT_TEXT:Colorize("Display"),
		},
		{
			type = "dropdown",
			name = "Alert location",
			tooltip = "Where alerts will appear on your screen.",
			choices = { "Center", "Top Right" },
			getFunc = function() return TROUBLEMAKER.settings.alertpos end,
			setFunc = function(value) TROUBLEMAKER.settings.alertpos = value end,
			default = defaults.alertpos,
		},
		{
			type = "header",
			name = ZO_HIGHLIGHT_TEXT:Colorize("Support and Suggestions"),
		},
		{
			type = "description",
			text = "Please submit all support related questions and suggestions to the Troublemaker page at esoui.com.",
		},
	}

	local LAM = LibStub("LibAddonMenu-2.0")
	local panel = LAM:RegisterAddonPanel("TroublemakerSettings", panelData)
	LAM:RegisterOptionControls("TroublemakerSettings", optionsTable)

	-- add logo
	panel.logo = WINDOW_MANAGER:CreateControl(nil, panel, CT_TEXTURE)
	panel.logo:SetAnchor(TOPLEFT, panel, TOPLEFT, 0, 0)
	panel.logo:SetDimensions(420, 60)
	panel.logo:SetTexture("Troublemaker/Art/troublemaker.dds")
	panel.logo:SetTextureCoords(0, 1, 0, 0.1429)
	panel.logo:SetScale(0.88)
	panel.label:SetHeight(50)
	panel.label:SetHidden(true)

end

--------------------------------------------------------------------------
--------------------------   State Toggle   ------------------------------
--------------------------------------------------------------------------

local function IsPrevented()
	return GetSetting_Bool(SETTING_TYPE_COMBAT, COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS)
end

local identifier = "TROUBLEMAKER_MESSAGE"

local function Passive()
	EVENT_MANAGER:UnregisterForUpdate(identifier)
	if TROUBLEMAKER.settings.alertpos == "Top Right" then
		--ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, "You are|c00FF0C passive|r towards innocents")
	else
		--CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_EVENT_SMALL_TEXT, nil, "You are|c00FF0C passive|r towards innocents")
	end
end

local function Aggressive()
	-- SOUNDS.ACHIEVEMENT_AWARDED
	EVENT_MANAGER:UnregisterForUpdate(identifier)
	if TROUBLEMAKER.settings.alertpos == "Top Right" then
		--ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, "You are|cFF002A aggressive|r towards innocents")
	else
		--CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_EVENT_SMALL_TEXT, nil, "You are|cFF002A aggressive|r towards innocents")
	end
end

function TROUBLEMAKER:Refresh()
	local attack = false
	for _, should in pairs(self.attackForReason) do
		if should then
			attack = true
			break
		end
	end
	if attack == IsPrevented() then
		SetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS, not attack and 1 or 0)
		EVENT_MANAGER:UnregisterForUpdate(identifier)
		if GetUnitDisguiseState("player") > DISGUISE_STATE_DANGER then return end
		if attack then
			EVENT_MANAGER:RegisterForUpdate(identifier, 250, Aggressive)
		else
			EVENT_MANAGER:RegisterForUpdate(identifier, 250, Passive)
		end
	end
end

--------------------------------------------------------------------------
-------------------------   Event handlers   -----------------------------
--------------------------------------------------------------------------
local function KOSchange()
	TROUBLEMAKER.attackForReason["IsKillOnSight"] = TROUBLEMAKER.settings.kosoverride and IsKillOnSight()
	TROUBLEMAKER:Refresh()
end

local function BountyPayoffUpdated(event, oldBounty, newBounty)
	TROUBLEMAKER.attackForReason["BountyPayoff"] = TROUBLEMAKER.settings.bountypaid and newBounty > 0
	TROUBLEMAKER:Refresh()
end

local function InfamyUpdated()
	TROUBLEMAKER.attackForReason["Trespassing"] = IsTrespassing()
	TROUBLEMAKER:Refresh()
end

-- local BladeOfWoeName = GetAbilityName(78219)
local _, _, _, BladeOfWoeIcon = GetAchievementInfo(1435)
local lastSynergyName
local function SynergyChanged()
	local synergyName, iconFilename = GetSynergyInfo()

	if lastSynergyName ~= synergyName then
		TROUBLEMAKER.attackForReason["BladeOfWoe"] = iconFilename == BladeOfWoeIcon
		TROUBLEMAKER:Refresh()

		lastSynergyName = synergyName
	end
end

local function ReticleUpdate()
	TROUBLEMAKER.attackForReason["Hostile"] = DoesUnitExist("reticleover") and GetUnitReaction("reticleover") == UNIT_REACTION_HOSTILE
	TROUBLEMAKER:Refresh()
end

--------------------------------------------------------------------------
-----------------------------   On Load   --------------------------------
--------------------------------------------------------------------------

local function OnLoad(event, addonName)
	if (TROUBLEMAKER.name ~= addonName) then
		return
	end

	EVENT_MANAGER:UnregisterForEvent(TROUBLEMAKER.name, EVENT_ADD_ON_LOADED)

	TROUBLEMAKER.settings = ZO_SavedVars:NewAccountWide("Troublemaker_SavedVariables", 1, nil, defaults)

	ZO_CreateStringId("SI_BINDING_NAME_TROUBLEMAKER", "Troublemaker")

	BuildSettingsMenu()

	-- Change to passive on login
	if TROUBLEMAKER.settings.logpassive and not IsKillOnSight() then
		SetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS, 1)
	end

	-- Notify of aggressive status on login
	local state = GetSetting_Bool(SETTING_TYPE_COMBAT, COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS)
	if TROUBLEMAKER.settings.lognotify and not state then
		zo_callLater( function() Aggressive() end, 5000)
	end

	-- KOS override check
	EVENT_MANAGER:RegisterForEvent(TROUBLEMAKER.name, EVENT_JUSTICE_NOW_KOS, KOSchange)

	-- Passive if bounty paid
	EVENT_MANAGER:RegisterForEvent(TROUBLEMAKER.name, EVENT_JUSTICE_BOUNTY_PAYOFF_AMOUNT_UPDATED, BountyPayoffUpdated)

	-- Infamy
	EVENT_MANAGER:RegisterForEvent(TROUBLEMAKER.name, EVENT_JUSTICE_INFAMY_UPDATED, InfamyUpdated)

	-- Blade of Woe
	EVENT_MANAGER:RegisterForEvent(TROUBLEMAKER.name, EVENT_SYNERGY_ABILITY_CHANGED, SynergyChanged)

	EVENT_MANAGER:RegisterForEvent(TROUBLEMAKER.name, EVENT_RETICLE_TARGET_CHANGED, ReticleUpdate)
end

--------------------------------------------------------------------------
------------------------   Toggle Innocents   ----------------------------
--------------------------------------------------------------------------	

local function Troublemaker()
	local newState = 1 - GetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS)
	SetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS, newState)

	if newState == 1 then
		Passive()
	else
		Aggressive()
	end
end

--------------------------------------------------------------------------
-------------------------   Slash Commands   -----------------------------
--------------------------------------------------------------------------

SLASH_COMMANDS["/trouble"] = Troublemaker
SLASH_COMMANDS["/tm"] = Troublemaker

--------------------------------------------------------------------------
--------------------------   Registration   ------------------------------
--------------------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent(TROUBLEMAKER.name, EVENT_ADD_ON_LOADED, OnLoad)