local LIB_NAME = "LibVotansAddonList"
local addon = {}

local em = GetEventManager()
local AddOnManager = GetAddOnManager()

local function checkDependsOn(data)
	-- assume success to break recursion
	data.addOnState = ADDON_STATE_ENABLED

	local other
	for i = 1, #data.dependsOn do
		other = data.dependsOn[i]
		if other.addOnState ~= ADDON_STATE_ENABLED and not other.missing then
			checkDependsOn(other)
		end
	end
	AddOnManager:SetAddOnEnabled(data.addOnIndex, true)
	-- Verify success
	local enabled
	enabled, data.addOnState = select(5, AddOnManager:GetAddOnInfo(data.addOnIndex))
	data.hasDependencyError = enabled and data.addOnState ~= ADDON_STATE_ENABLED
	return data.addOnState == ADDON_STATE_ENABLED
end
local function checkDisableUnusedLibs(data)
	local other, enabled, dependency
	for i = 1, #data.dependsOn do
		other = data.dependsOn[i]
		if other.isLibrary and other.addOnState == ADDON_STATE_ENABLED then
			enabled = false
			local numDep = other.usedBy and #other.usedBy or 0
			if numDep > 0 then
				for j = 1, numDep do
					dependency = other.usedBy[j]
					enabled = enabled or (dependency ~= data and not dependency.isLibrary and dependency.addOnState == ADDON_STATE_ENABLED)
				end
				if not enabled then
					AddOnManager:SetAddOnEnabled(other.addOnIndex, enabled)
					other.addOnState = ADDON_STATE_DISABLED
				end
			end
		end
	end

	-- Verify success
	data.addOnState = select(6, AddOnManager:GetAddOnInfo(data.addOnIndex))
end
local function CheckPreRequirements(data)
	if data.addOnState ~= ADDON_STATE_ENABLED then
		return checkDependsOn(data)
	else
		checkDisableUnusedLibs(data)
		AddOnManager:SetAddOnEnabled(data.addOnIndex, false)
		data.addOnState = ADDON_STATE_DISABLED
		return true
	end
end

local DISABLED_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))

local function init(manager)
	-- SLASH_COMMANDS["/zgoo"](manager.keybindStripDescriptor)
	local function initKeybind(keybind)
		keybind.name = function()
			local selectedData = manager:GetSelectedData()
			if selectedData then
				local enabled = selectedData.addOnState == ADDON_STATE_ENABLED

				if enabled then
					return GetString(SI_GAMEPAD_ADDON_MANAGER_DISABLE_ADDON)
				else
					return GetString(SI_GAMEPAD_ADDON_MANAGER_ENABLE_ADDON)
				end
			end
			return ""
		end

		keybind.visible = function()
			local selectedData = manager:GetSelectedData()
			return selectedData and not selectedData.unloadable
		end
		keybind.callback = function()
			local selectedData = manager:GetSelectedData()
			if selectedData then
				CheckPreRequirements(selectedData)
				manager:MarkDirty()
				manager:RefreshVisible()
				manager:UpdateTooltip()
				manager:UpdateKeybinds()
				-- The enabled state has changed, so re-narrate
				SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self)
			end
		end
	end

	local keybinds = manager.keybindStripDescriptor
	for i = 1, #keybinds do
		if keybinds[i].keybind == "UI_SHORTCUT_PRIMARY" then
			initKeybind(keybinds[i])
			break
		end
	end
	local function initTooltip(tooltip)
		ZO_PostHook(
			tooltip,
			"LayoutAddOnTooltip",
			function(tooltip, data)
				if not data.usedBy then
					return
				end

				local numDep = data.usedBy and #data.usedBy or 0
				if numDep == 0 then
					return
				end

				-- SLASH_COMMANDS["/zgoo"]({tooltip, data})
				local dependencySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))

				dependencySection:AddLine(GetString(SI_VOTANS_ADDONLIST_USED_BY), tooltip:GetStyle("bodyHeader"))
				local dependencyText = {}
				local dependency, dependencyName, dependencyActive
				for j = 1, numDep do
					dependency = data.usedBy[j]
					dependencyName, dependencyActive = dependency.strippedAddOnName, dependency.addOnState == ADDON_STATE_ENABLED

					if not dependencyActive then
						dependencyName = DISABLED_COLOR:Colorize(dependencyName)
					end
					dependencyText[#dependencyText + 1] = dependencyName
				end
				table.sort(dependencyText)
				dependencySection:AddLine(table.concat(dependencyText, ", "), tooltip:GetStyle("bodyDescription"))
				tooltip:AddSection(dependencySection)
			end
		)
	end
	initTooltip(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP))
end
SecurePostHook(ZO_AddOnManager_Gamepad, "OnDeferredInitialize", init)

local function StripText(text)
	return text:gsub("|[Rr]", "")
end

local function BuildMasterList(manager)
	local nameToLib = {}
	local function addToLookup(scrollData)
		for i = 1, #scrollData do
			local data = scrollData[i]
			nameToLib[data.addOnFileName] = data
			-- data.sortableName = data.strippedAddOnName:upper()
			data.addOnState = select(6, AddOnManager:GetAddOnInfo(data.addOnIndex))
		end
	end
	local function checkDependency(masterList)
		local data
		local name, i, dependency, depCount, isPatchFor, dependsOn, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion
		for index = 1, #masterList do
			data = masterList[index]
			i = data.addOnIndex
			name, depCount = nil, 0
			dependsOn = {}
			data.dependsOn = dependsOn
			data.strippedAddOnName = StripText(data.strippedAddOnName)
			data.unloadable = false
			for j = 1, AddOnManager:GetAddOnNumDependencies(i) do
				dependency, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion = AddOnManager:GetAddOnDependencyInfo(i, j)
				dependency = nameToLib[dependency]
				if dependency and not dependency.isLibrary and not dependency.missing then
					if not name then
						name = dependency.strippedAddOnName
						isPatchFor = dependency
					end
					depCount = depCount + 1
				end
				if dependency then
					dependsOn[#dependsOn + 1] = dependency
					dependency.hasReference = true
					dependency.usedBy = dependency.usedBy or {}
					dependency.usedBy[#dependency.usedBy + 1] = data
					local dependencyTooLowVersion = dependencyVersion < dependencyMinVersion
					data.unloadable = data.unloadable or dependencyTooLowVersion
				else
					local name = AddOnManager:GetAddOnDependencyInfo(i, j)
					local missing = {
						addOnName = name,
						-- sortableName = name:upper(),
						missing = true
					}
					nameToLib[name] = missing
					dependsOn[#dependsOn + 1] = missing
					data.unloadable = true
				end
			end

			data.isPatch = name and depCount >= 1
			if data.isPatch then
				data.isLibrary = false
				data.isPatchFor = isPatchFor
			-- data.sortableName = string.format("%s-%s", name, data.sortableName)
			-- elseif not data.isLibrary then
			-- 	local path = zo_strupper(AddOnManager:GetAddOnRootDirectoryPath(i))
			-- 	local expectedPath = zo_strupper(string.format("user:/AddOns/%s/", data.addOnFileName))
			-- 	if path ~= expectedPath then
			-- 		data.expectedPath = string.format("AddOns/%s", data.addOnFileName)
			-- 	end
			end
		end
	end
	addToLookup(manager.addonList)
	addToLookup(manager.libraryList)
	checkDependency(manager.addonList)
	checkDependency(manager.libraryList)
end

SecurePostHook(ZO_AddOnManager_Gamepad, "BuildMasterList", BuildMasterList)

SecurePostHook(
	ZO_AddOnManager_Gamepad,
	"SetupRow",
	function(manager, control, data)
		if data.unloadable then
			return -- red is correct
		end
		local enabled = data.addOnState == ADDON_STATE_ENABLED
		local color
		if not enabled and data.hasDependencyError then
			color = ZO_DEFAULT_DISABLED_COLOR -- is red, but can be just gray
		else
			return -- what ever state is correct
		end

		control.addonNameLabel:SetColor(color:UnpackRGBA())
		control.authorNameLabel:SetColor(color:UnpackRGBA())
		control.dependencyIcon:SetHidden(not data.unloadable)
	end
)
