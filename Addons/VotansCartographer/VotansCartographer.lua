local data = {
	name = "VotansCartographer",
	title = "Votan's Cartographer",
	lureInformerEnabled = false,
	lastInteraction = {
		action = "",
		interactableName = "",
		additionalInfo = ""
	},
	actions = {},
	categories = {},
	categoryById = {}
}

local function ParseInteraction(lastInteraction)
	data.lastCategory = nil
	if lastInteraction.action == nil or lastInteraction.action == "" then
		return nil
	end
	if lastInteraction.interactableName == nil or lastInteraction.interactableName == "" then
		return nil
	end

	local action = data.actions[lastInteraction.action]
	if action == nil or action.id == nil then
		-- d(zo_strjoin(nil, "action ", lastInteraction.action, " unknown"))
		return nil
	end
	local function GetCategory(name)
		local category = action[name]
		local matchLength = category and name:len() or 0
		for interactionName, mayCategory in pairs(action) do
			if name:find(interactionName) and interactionName:len() > matchLength then
				category = mayCategory
				matchLength = interactionName:len()
			end
		end
		if category == nil or type(category) ~= "table" or category.id == nil then
			-- d("action is ", action, zo_strjoin(" interaction ", lastInteraction.interactableName, " unknown"))
			return nil
		end
		return category
	end
	local category
	if lastInteraction.unitCaption and lastInteraction.unitCaption ~= "" then
		local extendedInteractable = string.format("%s %s", lastInteraction.unitCaption, lastInteraction.interactableName)
		category = GetCategory(extendedInteractable)
	else
		category = nil
	end
	if category == nil then
		category = GetCategory(lastInteraction.interactableName)
	end
	-- d("Identified as:", category.name)
	-- d("Predefined:", data.settings.categoryToPredefined[category.id] or "<default>")

	return category
end

local function ShowCategory(category)
	if category then
		local categoryToPredefined = data.settings.categoryToPredefined[category.id]
		local predefined
		if categoryToPredefined then
			predefined = data.customPOIs.predefined[categoryToPredefined]
		end
		local pinText
		if predefined then
			local icon = HarvensCustomMapPinsIconList[predefined.icon] or HarvensCustomMapPinsIconList[1]
			pinText = string.format("%s|t32:32:%s:inheritColor|t", categoryToPredefined, icon)
		else
			pinText = category.name
		end
		data.rememberKeyBind:SetText(ZO_CachedStrFormat(SI_BINDING_NAME_VOTANSCARTOGRAPHER_ADDPIN_WITH_CATEGORY, pinText))
		return false, predefined ~= nil
	else
		data.rememberKeyBind:SetText(GetString(SI_BINDING_NAME_VOTANSCARTOGRAPHER_ADDPIN))
	end
	return true, false
end

local lastAction = ""
local lastInteractableName = ""
local lastUnitName = ""
local fishingInteractableName
local GetGameCameraInteractableActionInfo, GetUnitName = GetGameCameraInteractableActionInfo, GetUnitName
local function NewInteraction()
	local action, interactableName, _, _, additionalInfo = GetGameCameraInteractableActionInfo()
	if action and interactableName then
		local unitName = GetUnitName("reticleover") or ""
		if lastAction == action and lastInteractableName == interactableName and (lastUnitName == unitName or lastUnitName == interactableName) then
			return
		end
		lastAction = action
		lastInteractableName = interactableName
		lastUnitName = unitName
		if additionalInfo == ADDITIONAL_INTERACT_INFO_FISHING_NODE and data.lureInformerEnabled then
			fishingInteractableName = interactableName
			data.rememberKeyBind:SetEnabled(false)
			data.rememberKeyBind:SetHidden(true)
			data.lastInteraction.action = ""
		else
			local isFishing = interactableName == fishingInteractableName
			if not isFishing then
				data.lastInteraction.action = action
				data.lastInteraction.interactableName = interactableName
				data.lastInteraction.additionalInfo = additionalInfo
				data.lastInteraction.unitCaption = (unitName == interactableName) and ZO_CachedStrFormat(SI_TOOLTIP_UNIT_CAPTION, GetUnitCaption("reticleover")) or nil
				local category = ParseInteraction(data.lastInteraction)
				local isDefault, isAssigned = ShowCategory(category)
				data.lastCategory = category
				isFishing = not isAssigned and data.settings.hideUnassigned
				if not isFishing then
					isFishing = isDefault and data.settings.hideDefault
				end
			end
			data.rememberKeyBind:SetHidden(isFishing)
			data.rememberKeyBind:SetEnabled(not isFishing)
		end
	else
		if lastAction == action then
			return
		end
		lastAction = action
		lastInteractableName = ""
		data.rememberKeyBind:SetEnabled(false)
		data.lastInteraction.action = ""
		data.lastInteraction.interactableName = ""
		data.lastInteraction.additionalInfo = ""
		data.lastInteraction.unitCaption = nil
		data.lastCategory = nil
	end
end

local function HookInteraction()
	local WINDOW_MANAGER = WINDOW_MANAGER

	data.rememberKeyBind = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)AddPinButton", RETICLE.interact, "ZO_KeybindButton")
	data.rememberKeyBind:SetAnchor(LEFT, RETICLE.interactKeybindButton, RIGHT, 48, 0)
	ZO_KeybindButtonTemplate_Setup(data.rememberKeyBind, "VOTANSCARTOGRAPHER_ADDPIN", nil, GetString(SI_BINDING_NAME_VOTANSCARTOGRAPHER_ADDPIN))
	data.rememberKeyBind:SetEnabled(false)
	data.rememberKeyBind:SetKeybindEnabled(true)

	ZO_PreHookHandler(RETICLE.interact, "OnEffectivelyShown", NewInteraction)
	ZO_PreHookHandler(RETICLE.interact, "OnHide", NewInteraction)
end

---- Custom POI ----
local lootRadius = 1 / 40000

function Votans_Cartographer_AddPin()
	if data.customPOIs == nil then
		return
	end
	if data.lastInteraction.action == "" then
		return
	end
	if RETICLE.interact:IsControlHidden() or RETICLE.control:IsControlHidden() then
		return
	end

	data.rememberKeyBind:SetEnabled(false)

	local pX, pY = GetMapPlayerPosition("player")
	if WORLD_MAP_FRAGMENT:IsHidden() and (pX <= 0 or pX >= 1 or pY <= 0 or pY >= 1) and SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
		CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
		pX, pY = GetMapPlayerPosition("player")
	end

	local map = GetMapName()
	local heading = GetPlayerCameraHeading()
	local headX = -math.sin(heading) * lootRadius
	local headY = -math.cos(heading) * lootRadius

	-- max focus point in heading direction
	local x = pX + headX
	local y = pY + headY

	if next(HarvensCustomMapPins:FindPinOnCurrentMap(x, y, 5 / 10000)) ~= nil then
		ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, SI_VOTANSCARTOGRAPHER_EXISTS)
		return
	end

	local category = data.lastCategory
	local description
	if category then
		local format = GetString("SI_VOTANSCARTOGRAPHER_FORMAT", category.id)
		if format == "" then
			format = "{catecory}: {name}"
		end
		description = format:gsub("{catecory}", category.name):gsub("{name}", data.lastInteraction.interactableName):gsub("{caption}", data.lastInteraction.unitCaption or "")
	else
		description = data.lastInteraction.interactableName
	end

	local predefined, categoryToPredefined = nil, nil
	if category then
		categoryToPredefined = category and data.settings.categoryToPredefined[category.id]
		if categoryToPredefined then
			predefined = data.customPOIs.predefined[categoryToPredefined]
		end
	end

	local color = predefined and predefined.color or data.customPOIs.lastUsedColor or {1, 1, 1, 1}
	local icon = predefined and predefined.icon or 1
	HarvensCustomMapPins:AddPinToCurrentMap(x, y, description, icon, color, categoryToPredefined)
	PlaySound(SOUNDS.DEFAULT_CLICK)
end

---- End POIs ----

local function GetItems()
	local items = {{name = " ", data = ""}}
	for name in pairs(data.customPOIs.predefined) do
		items[#items + 1] = {name = name, data = name}
	end
	return items
end

local function InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Cartographer")
	if not settings then
		return
	end
	settings.version = "1.3.7"
	settings.website = "http://www.esoui.com/downloads/info917-VotansCartographerforHarvensCustomMapPins.html"

	local list = {}

	local function GetPredefined(categoryIndex)
		local predefined = data.settings.categoryToPredefined[categoryIndex]
		if predefined == nil then
			predefined = ""
		end
		return predefined
	end

	local category
	for categoryIndex = 1, #data.categoryById do
		category = {
			type = LibHarvensAddonSettings.ST_DROPDOWN,
			label = GetString("SI_VOTANSCARTOGRAPHER_CATEGORY", categoryIndex),
			items = GetItems,
			getFunction = function()
				local predefined = GetPredefined(categoryIndex)
				return predefined or ""
			end,
			setFunction = function(combobox, name, item)
				local predefined = GetPredefined(categoryIndex)
				if item.data == " " then
					predefined = ""
				else
					predefined = item.data
				end
				data.settings.categoryToPredefined[categoryIndex] = predefined
			end
		}
		list[#list + 1] = category
	end

	settings:AddSettings(list)

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANSCARTOGRAPHER_HIDE_UNASSIGNED),
		tooltip = GetString(SI_VOTANSCARTOGRAPHER_HIDE_UNASSIGNED_TOOLTIP),
		getFunction = function()
			return data.settings.hideUnassigned
		end,
		setFunction = function(value)
			data.settings.hideUnassigned = value
			lastAction = ""
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = GetString(SI_VOTANSCARTOGRAPHER_HIDE_DEFAULT),
		tooltip = GetString(SI_VOTANSCARTOGRAPHER_HIDE_DEFAULT_TOOLTIP),
		getFunction = function()
			return data.settings.hideDefault
		end,
		setFunction = function(value)
			data.settings.hideDefault = value
			lastAction = ""
		end
	}
end

local function InitInteraction()
	local join = zo_strjoin
	local GetString = GetString
	local actionIndex = 0
	local actions = data.actions
	local actionById = {}
	local action
	while true do
		actionIndex = actionIndex + 1
		local actionName = GetString("SI_VOTANSCARTOGRAPHER_ACTION", actionIndex)
		if actionName == "" then
			break
		end
		action = {id = actionIndex, action = actionName}
		actions[actionName] = action
		actionById[actionIndex] = action
	end
	local numActions = actionIndex

	local categoryIndex = 0
	local categories = data.categories
	local categoryById = data.categoryById
	local category
	while true do
		categoryIndex = categoryIndex + 1
		local categoryName = GetString("SI_VOTANSCARTOGRAPHER_CATEGORY", categoryIndex)
		if categoryName == "" then
			break
		end
		category = {id = categoryIndex, name = categoryName}
		categories[categoryName] = category
		categoryById[categoryIndex] = category
	end
	local numCategories = categoryIndex

	local itemIndex, stringId, itemName
	for actionIndex = 1, numActions do
		for categoryIndex = 1, numCategories do
			itemIndex = 0
			while true do
				itemIndex = itemIndex + 1
				stringId = join(nil, "SI_VOTANSCARTOGRAPHER_ACTION", actionIndex, "_CATEGORY", categoryIndex, "_ITEM")
				itemName = GetString(stringId, itemIndex)
				if itemName == "" then
					break
				end
				actionById[actionIndex][itemName] = categoryById[categoryIndex]
			end
		end
	end
end

local function InitPlatformStyle()
	function data:ApplyPlatformStyle(style)
		ApplyTemplateToControl(self.rememberKeyBind, style.keybindButtonTemplate)
		ShowCategory(data.lastCategory)
	end
	local KeyboardStyle = {
		keybindButtonTemplate = "ZO_KeybindButton_Keyboard_Template"
	}

	local GamepadStyle = {
		keybindButtonTemplate = "ZO_KeybindButton_Gamepad_Template"
	}

	ZO_PlatformStyle:New(
		function(...)
			data:ApplyPlatformStyle(...)
		end,
		KeyboardStyle,
		GamepadStyle
	)
end

local function OnAddOnLoaded(event, addonName)
	if addonName == data.name then
		EVENT_MANAGER:UnregisterForEvent(data.name, EVENT_ADD_ON_LOADED)

		local varGlobalDefaults = {hideUnassigned = false, hideDefault = false}
		local settings = ZO_SavedVars:NewAccountWide("VotansCartographer_Data", 1, nil, varGlobalDefaults)
		data.settings = settings
		if settings.categoryToPredefined == nil then
			settings.categoryToPredefined = {}
		end

		if HarvensCustomMapPins ~= nil then
			data.customPOIs = HarvensCustomMapPins.sv

			if not pcall(HookInteraction) then
				zo_callLater(data.title .. ": HookInteraction failed.", 2000)
			else
				InitInteraction()
				InitSettings()
				InitPlatformStyle()
			end
		end
	elseif addonName == "VotansFisherman" then
		data.lureInformerEnabled = true
	end
end

EVENT_MANAGER:RegisterForEvent(data.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

VOTANS_CARTOGRAPHER = data
