local addon = {
	name = "VotansSettingsMenu",
	accountDefaults = {
		ShowButton = true
	}
}

VOTANS_MENU_SETTINGS = {}

local VOTANS_MENU_SETTINGS = VOTANS_MENU_SETTINGS
local LAM2
local LMM2
local sm = SCENE_MANAGER
local gameMenuScene = "gameMenuInGame"

local function RememberSelectedPanel(panel)
	if panel and panel.data and panel.data.type == "panel" then
		addon.player.LastAddon = panel:GetName()
	end
end

local function HookOpenToPanel()
	local orgOpenToPanel = LAM2.OpenToPanel
	function LAM2:OpenToPanel(panel, ...)
		if panel and not panel:IsControlHidden() then
			CALLBACK_MANAGER:FireCallbacks("LAM-RefreshPanel", panel)
		elseif panel then
			addon.player.LastAddon = panel:GetName()
		end
		return orgOpenToPanel(self, panel, ...)
	end
end

local function ShowPanel(skip)
	local panel = WINDOW_MANAGER:GetControlByName(addon.player.LastAddon)

	LAM2.pendingAddonPanel = nil
	if not panel and skip ~= true then
		LAM2:OpenToPanel(nil)
	end
	if panel then
		LAM2:OpenToPanel(panel)
	end
end

local function SelectLastUsedAddon(oldState, newState)
	if newState == SCENE_FRAGMENT_SHOWN then
		LAM2:GetAddonSettingsFragment():UnregisterCallback("StateChange", SelectLastUsedAddon)
		ShowPanel(true)
	end
end

function addon:Initialize()
	LMM2 = LibMainMenu2
	LMM2:Init()
	LAM2 = LibAddonMenu2

	local descriptor = addon.name
	local callback
	if not LAM2 or not LAM2.OpenToPanel then
		callback = function(buttonData)
			sm:Show(gameMenuScene)
		end
	else
		callback = function(buttonData)
			addon:ToggleSettingsMenu()
		end
		CALLBACK_MANAGER:RegisterCallback("LAM-RefreshPanel", RememberSelectedPanel)
		self:InitSettings()
		if LAM2.OpenToPanel ~= nil then
			HookOpenToPanel()
			CALLBACK_MANAGER:RegisterCallback("LAM-PanelOpened", RememberSelectedPanel)
		end
	end
	SLASH_COMMANDS["/addonsettings"] = callback

	-- Add to main menu
	local categoryLayoutInfo = {
		binding = "VOTANS_SETTINGS_MENU",
		categoryName = SI_BINDING_NAME_VOTANS_SETTINGS_MENU,
		callback = callback,
		visible = function(buttonData)
			return addon.account.ShowButton
		end,
		normal = "esoui/art/inventory/inventory_tabicon_misc_up.dds",
		pressed = "esoui/art/inventory/inventory_tabicon_misc_down.dds",
		highlight = "esoui/art/inventory/inventory_tabicon_misc_over.dds",
		disabled = "esoui/art/inventory/inventory_tabicon_misc_disabled.dds"
	}
	local function deferMenu()
		EVENT_MANAGER:UnregisterForUpdate(addon.name)
		LMM2:AddMenuItem(descriptor, categoryLayoutInfo)
	end
	EVENT_MANAGER:RegisterForUpdate(addon.name, 0, deferMenu)

	if LAM2 and self.player.LastAddon and #self.player.LastAddon > 0 then
		LAM2:GetAddonSettingsFragment():RegisterCallback("StateChange", SelectLastUsedAddon)
	end
end

local max = 0
local normalLimit = 0

function addon:UpdateUsage()
	local current = math.floor(collectgarbage("count") / 1024 + 0.5)
	max = math.floor(math.max(current + 127, max) / 64) * 64
	local statusBar = addon.statusbar
	statusBar:SetMinMax(0, max)
	statusBar:SetValue(math.min(max, current))
	statusBar.progress:SetText(string.format("%i/%i MB", current, max))
	statusBar.warning:SetHidden(current < normalLimit)
end

local function AutoRefreshUsage()
	addon:UpdateUsage()
end

local function RegisterUpdateUsage()
	addon:UpdateUsage()
	EVENT_MANAGER:RegisterForUpdate(addon.name, 1000, AutoRefreshUsage)
end

local ROW_TYPE_ID = 1

function addon:SetupControls(panel)
	sm:GetScene(gameMenuScene):RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_SHOWN then
				if addon.player.LastAddon == addon.control:GetName() then
					RegisterUpdateUsage()
				end
			else
				EVENT_MANAGER:UnregisterForUpdate(addon.name, AutoRefreshUsage)
			end
		end
	)

	local control, last
	local wm = WINDOW_MANAGER
	local divider = wm:CreateControlFromVirtual(nil, panel.scroll, "ZO_Options_Divider")
	divider:SetAnchor(TOPLEFT, panel.scroll, TOPLEFT, 0, 32)

	control = wm:CreateControlFromVirtual("$(parent)LuaMemUsageBar", panel.scroll, "ZO_AchievementsStatusBar")
	control:SetWidth(440)
	ZO_StatusBar_SetGradientColor(control, ZO_XP_BAR_GRADIENT_COLORS)

	control.warning = wm:CreateControlFromVirtual(nil, control, "ZO_Options_WarningIcon")
	control.warning:SetAnchor(RIGHT, control, LEFT, -5, 0)
	control.warning.data = {tooltipText = GetString(SI_VOTANS_SETTINGS_MENU_MEM_TOO_LOW)}

	control:SetAnchor(TOP, divider, TOP, 0, 48)
	control.label = control:GetNamedChild("Label")
	control.progress = control:GetNamedChild("Progress")
	control.label:SetText(GetString(SI_VOTANS_SETTINGS_MENU_MEM_USAGE))
	addon.statusbar = control

	control = wm:CreateControl("$(parent)Ouroboros", panel, CT_TEXTURE)
	control:SetTexture("esoui/art/login/gamepad/console-ouroboros.dds")
	control:SetDimensions(448, 448)
	control:SetAnchor(TOP, addon.statusbar, BOTTOM, 0, 0)
	control:SetColor(1, 1, 1, 0.25)
	last = control

	local title, releaseType, version, release = GetESOVersionString():match("(%l+)%.(%l+)%.(%d+.%d+.%d+).(%d+)")
	releaseType = releaseType:gsub("rc", "release candidate")

	control = wm:CreateControl("$(parent)ESOTitle", panel, CT_LABEL)
	control:SetFont("$(ANTIQUE_FONT)|64")
	control:SetText("Elder Scrolls Online")
	control:SetDrawLevel(2)
	control:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
	control:SetAnchor(TOP, last, TOP, 0, 64)
	last = control

	control = wm:CreateControl("$(parent)ESORelease", panel, CT_LABEL)
	control:SetFont("$(GAMEPAD_MEDIUM_FONT)|$(GP_36)")
	control:SetText(zo_strformat("<<t:1>>", releaseType))
	control:SetDrawLevel(2)
	control:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
	control:SetAnchor(TOP, last, BOTTOM, 0, 0)
	last = control

	control = wm:CreateControl("$(parent)ESOVersion", panel, CT_LABEL)
	control:SetFont("$(GAMEPAD_MEDIUM_FONT)|$(GP_42)")
	control:SetText(string.format("Version %s", version))
	control:SetDrawLevel(2)
	control:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
	control:SetAnchor(TOP, last, BOTTOM, 0, 24)
	last = control

	control = wm:CreateControl("$(parent)ESORevision", panel, CT_LABEL)
	control:SetFont("$(GAMEPAD_MEDIUM_FONT)|$(GP_34)")
	control:SetText(string.format("Revision %s", release))
	control:SetDrawLevel(2)
	control:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HINT))
	control:SetAnchor(TOP, last, BOTTOM, 0, 0)
	last = control

	if GetESOFullVersionString then
		local year, month, day, hour, min, sec, platform = GetESOFullVersionString():match("%s(%d+)/(%d+)/(%d+)%s(%d+):(%d+):(%d+)%s%(%d+.(%l+)")

		platform = platform or ""
		platform = platform:gsub("win", "Windows®"):gsub("mac", "Macintosh®")

		local timestamp = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})

		control = wm:CreateControl("$(parent)ESOReleaseDate", panel, CT_LABEL)
		control:SetFont("$(GAMEPAD_MEDIUM_FONT)|$(GP_22)")
		control:SetText(os.date("%c", timestamp))
		control:SetDrawLevel(2)
		control:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HINT))
		control:SetAnchor(TOP, last, BOTTOM, 0, -4)
		last = control

		control = wm:CreateControl("$(parent)ESOPlatform", panel, CT_LABEL)
		control:SetFont("$(GAMEPAD_MEDIUM_FONT)|$(GP_34)")
		control:SetText(platform)
		control:SetDrawLevel(2)
		control:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
		control:SetAnchor(TOP, last, BOTTOM, 0, 72)
		last = control
	end

	RegisterUpdateUsage()
end

local function CreateOwnControls(panel)
	if panel ~= addon.control then
		return
	end
	CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", CreateOwnControls)
	CALLBACK_MANAGER:RegisterCallback(
		"LAM-RefreshPanel",
		function(control)
			if control == addon.control then
				RegisterUpdateUsage()
			end
		end
	)

	addon:SetupControls(panel)
end

function addon:InitSettings()
	local addonName = "Settings Menu  "
	local panelData = {
		type = "panel",
		name = addonName,
		displayName = addonName,
		author = "votan",
		version = "1.6.0",
		registerForRefresh = true,
		registerForDefaults = true
	}
	addon.control = LAM2:RegisterAddonPanel(addonName, panelData)

	local optionsTable = {
		------------GENERAL--------------
		{
			-- ShowButton
			type = "checkbox",
			name = GetString(SI_VOTANS_SETTINGS_MENU_SHOW_BUTTON),
			tooltip = nil,
			getFunc = function()
				return VOTANS_MENU_SETTINGS:IsMenuButtonEnabled()
			end,
			setFunc = function(value)
				VOTANS_MENU_SETTINGS:SetMenuButtonEnabled(value)
			end,
			width = "full",
			default = addon.accountDefaults.ShowButton
		}
	}
	LAM2:RegisterOptionControls(addonName, optionsTable)

	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", CreateOwnControls)

	EVENT_MANAGER:RegisterForEvent(
		addon.name,
		EVENT_PLAYER_ACTIVATED,
		function()
			EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
			normalLimit = math.floor(collectgarbage("count") / 1024 + 0.5) * 4
			normalLimit = math.min(normalLimit, 8192)
			max = math.floor((normalLimit + 63) / 64) * 64
		end
	)
end

local identifier = "VOTANS_MENU_SETTINGS_SHOW_MENU"
local function Show()
	EVENT_MANAGER:UnregisterForUpdate(identifier)
	ShowPanel()
end
local function DelayShow()
	EVENT_MANAGER:UnregisterForUpdate(identifier)
	EVENT_MANAGER:RegisterForUpdate(identifier, 250, Show)
end

function addon:ToggleSettingsMenu()
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then
		return
	end
	local isMenu
	if LAM2 then
		isMenu = LAM2:GetAddonSettingsFragment():IsShowing()
	else
		isMenu = sm:IsShowing(gameMenuScene)
	end
	if isMenu then
		sm:ShowBaseScene()
	else
		if addon.player.LastAddon and #addon.player.LastAddon > 0 then
			-- has2lam support: panels created on showing
			if LAM2 and LAM2.OpenToPanel then
				if sm:IsShowing(gameMenuScene) then
					ShowPanel()
					return
				else
					sm:CallWhen(gameMenuScene, SCENE_SHOWN, DelayShow)
				end
			end
			sm:Show(gameMenuScene)
		elseif LAM2 and LAM2.OpenToPanel then
			LAM2:OpenToPanel(nil)
		end
	end
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.account = ZO_SavedVars:NewAccountWide("VotansSettingsMenu_Data", 1, nil, addon.accountDefaults)
	addon.player = ZO_SavedVars:NewCharacterIdSettings("VotansSettingsMenu_Data", 1, nil, nil)

	EVENT_MANAGER:RegisterForEvent(
		addon.name,
		EVENT_PLAYER_ACTIVATED,
		function()
			EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
			addon:Initialize()
		end
	)
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

function VOTANS_MENU_SETTINGS:GetLuaMemoryMB()
	return max
end

function VOTANS_MENU_SETTINGS:IsMenuButtonEnabled()
	if addon.account then
		return addon.account.ShowButton
	else
		return addon.accountDefaults.ShowButton
	end
end

function VOTANS_MENU_SETTINGS:SetMenuButtonEnabled(enabled)
	if addon.account then
		if addon.account.ShowButton ~= enabled then
			addon.account.ShowButton = enabled
			if LMM2 then
				LMM2:Refresh()
			end
			CALLBACK_MANAGER:FireCallbacks("VOTANS_MENU_SETTINGS_MENU_BUTTON_CHANGED", enabled)
		end
	else
		addon.accountDefaults.ShowButton = enabled
	end
end

function VOTANS_MENU_SETTINGS:GetLastUsedAddOn()
	if addon.player then
		return (addon.player.LastAddon and #addon.player.LastAddon > 0) and addon.player.LastAddon or ""
	else
		return ""
	end
end

function VOTANS_MENU_SETTINGS:Is32BitClient()
	return false
end

function VOTANS_MENU_SETTINGS:Is64BitClient()
	return true
end
