local lib = {name = "LibConsoleDialogs"}

local em = GetEventManager()
local sm = SCENE_MANAGER

local internal = {}

lib.internal = internal

-----------------------------
local dialogSettings = LibHarvensAddonSettings.AddonSettings:Subclass()

local orgSelect = dialogSettings.Select
function dialogSettings:Select()
	if not LibHarvensAddonSettings.initialized then
		LibHarvensAddonSettings:Initialize()
	end
	if #LibHarvensAddonSettings.addons == 0 and LibHarvensAddonSettings.scene == nil then
		LibHarvensAddonSettings:CreateAddonSettingsPanel()
		LibHarvensAddonSettings:CreateControlPools()
	end
	if self.container == nil then
		self.container = LibHarvensAddonSettings.container
		self:InitHandlers()
	end
	orgSelect(self)

	ZO_GamepadGenericHeader_RefreshData(LibHarvensAddonSettings.scrollList.header, self.headerData)

	sm:Push(LibHarvensAddonSettings.scene:GetName())
end

function dialogSettings:Show()
	return self:Select()
end

--------- Public API -----------

function lib:Create(title)
	local options = {
		allowDefaults = false,
		allowRefresh = true
	}
	local dialog = dialogSettings:New(title, options)
	dialog.headerData = {titleText = title}
	return dialog
end

function lib:RegisterKeybind(sceneOrName, buttonInfo)
	if type(sceneOrName) == "string" then
		sceneOrName = sm:GetScene(sceneOrName)
	end
	local registry = internal.registeredScenes[sceneOrName]
	if not registry then
		registry = {}
		internal.registeredScenes[sceneOrName] = registry
		sceneOrName:RegisterCallback(
			"StateChange",
			function(...)
				internal:OnStateChange(...)
			end
		)
	end
	registry[#registry + 1] = buttonInfo
end

function lib:Close()
	if LibHarvensAddonSettings.scene and LibHarvensAddonSettings.scene:IsShowing() and internal.dialog.selected then
		sm:HideCurrentScene()
	end
end

----------- Internal -------------

internal.keybinds = {
	"UI_SHORTCUT_PRIMARY",
	"UI_SHORTCUT_SECONDARY",
	"UI_SHORTCUT_TERTIARY",
	"UI_SHORTCUT_QUATERNARY",
	"UI_SHORTCUT_QUINARY",
	"UI_SHORTCUT_NEGATIVE",
	"UI_SHORTCUT_EXIT",
	"UI_SHORTCUT_LEFT_SHOULDER",
	"UI_SHORTCUT_RIGHT_SHOULDER",
	"UI_SHORTCUT_LEFT_TRIGGER",
	"UI_SHORTCUT_RIGHT_TRIGGER",
	"UI_SHORTCUT_LEFT_STICK",
	"UI_SHORTCUT_RIGHT_STICK",
	"UI_SHORTCUT_INPUT_UP",
	"UI_SHORTCUT_INPUT_DOWN",
	"UI_SHORTCUT_INPUT_LEFT",
	"UI_SHORTCUT_INPUT_RIGHT"
}

internal.registeredScenes = {}

function internal:GetRegistry()
	local scene = sm:GetCurrentScene()
	return self.registeredScenes[scene]
end

local function getValue(name, buttonInfo)
	local value = buttonInfo[name]
	if type(value) == "function" then
		value = value(buttonInfo)
	end
	return value
end

local function callback()
	local registry = internal:GetRegistry()
	internal:ShowSelectionDialog(registry)
end

internal.keybindStripDescriptorMore = {
	alignment = KEYBIND_STRIP_ALIGN_RIGHT,
	{
		keybind = "UI_SHORTCUT_INPUT_RIGHT",
		name = GetString(SI_LIB_CONSOLE_DIALOGS_MORE),
		callback = callback,
		visible = function()
			return true
		end,
		--sound = SOUNDS.GAMEPAD_MENU_FORWARD
		order = -100000
	}
}

function internal:ShowSelectionDialog(registry)
	local dialog = self.dialog
	if dialog.registry ~= registry then
		dialog.selected = false
		dialog:Clear()
		for _, buttonInfo in ipairs(self.additionalKeybinds) do
			local button = {
				type = LibHarvensAddonSettings.ST_BUTTON,
				label = getValue("name", buttonInfo),
				tooltip = getValue("tooltip", buttonInfo),
				disable = function()
					return getValue("enabled", buttonInfo) == false
				end,
				clickHandler = function()
					buttonInfo:callback()
				end
			}
			dialog:AddSetting(button)
		end
		dialog.registry = registry
	end
	dialog:Show()
end

function internal:AssignKeybinds()
	local usedKeybinds = {}
	local visibleButtons = 0
	for _, descriptor in pairs(KEYBIND_STRIP.keybindGroups) do
		for _, button in ipairs(descriptor) do
			usedKeybinds[button.keybind] = true
			if not button.ethereal then
				visibleButtons = visibleButtons + 1
			end
		end
	end
	if not DIRECTIONAL_INPUT:IsAvailable(ZO_DI_LEFT_STICK) then
		usedKeybinds["UI_SHORTCUT_LEFT_STICK"] = true
	end
	if not DIRECTIONAL_INPUT:IsAvailable(ZO_DI_RIGHT_STICK) then
		usedKeybinds["UI_SHORTCUT_RIGHT_STICK"] = true
	end
	if not DIRECTIONAL_INPUT:IsAvailable(ZO_DI_DPAD) then
		usedKeybinds["UI_SHORTCUT_INPUT_UP"] = true
		usedKeybinds["UI_SHORTCUT_INPUT_DOWN"] = true
		usedKeybinds["UI_SHORTCUT_INPUT_LEFT"] = true
		usedKeybinds["UI_SHORTCUT_INPUT_RIGHT"] = true
	end

	local registry = self:GetRegistry()
	table.sort(
		registry,
		function(a, b)
			return (a.order or 1000) < (b.order or 1000)
		end
	)
	local usedKeybindsCount = NonContiguousCount(usedKeybinds)
	local maxButtons = math.min(#registry, #self.keybinds - usedKeybindsCount, 7 - visibleButtons)
	local index = 1
	if maxButtons > 1 or #registry == 1 then
		for i = 1, #self.keybinds do
			local keybind = self.keybinds[i]
			if not usedKeybinds[keybind] then
				local descriptor = self.keybindStripDescriptors[i]
				local buttonInfo = registry[index]
				local button = descriptor[1]
				descriptor.alignment = buttonInfo.alignment or KEYBIND_STRIP_ALIGN_RIGHT
				button.name = function()
					return getValue("name", buttonInfo)
				end
				button.callback = buttonInfo.callback
				button.visible = function()
					return getValue("visible", buttonInfo)
				end
				button.enabled = function()
					return getValue("enabled", buttonInfo)
				end
				button.order = buttonInfo.order or (-1000 - i)

				KEYBIND_STRIP:AddKeybindButtonGroup(descriptor)
				index = index + 1
				if index > maxButtons then
					break
				end
			end
		end
	end
	if #registry >= index then
		self.additionalKeybinds = {}
		for i = index, #registry do
			local buttonInfo = registry[i]
			if getValue("visible", buttonInfo) then
				self.additionalKeybinds[#self.additionalKeybinds + 1] = buttonInfo
			end
		end
		if #self.additionalKeybinds == 0 then
			return
		end
		for i = #self.keybinds, 1, -1 do
			local keybind = self.keybinds[i]
			if not usedKeybinds[keybind] then
				self.keybindStripDescriptorMore[1].keybind = keybind
				KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptorMore)
				return
			end
		end
		error("No keybind available!")
	end
end

function internal:OnStateChange(oldState, newState)
	if newState == SCENE_SHOWN then -- Add late
		self:AssignKeybinds()
	elseif newState == SCENE_HIDING then -- Remove early
		for _, descriptor in ipairs(self.keybindStripDescriptors) do
			KEYBIND_STRIP:RemoveKeybindButtonGroup(descriptor)
		end
		KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptorMore)
	end
end

---- Init ----

function internal:Initialize()
	-- Use own logic to create a keybind overflow dialog
	local dialog = lib:Create(GetString(SI_LIB_CONSOLE_DIALOGS_TITLE))
	self.dialog = dialog
	local keybindStripDescriptors = {}
	for _, keybind in ipairs(self.keybinds) do
		keybindStripDescriptors[#keybindStripDescriptors + 1] = {
			alignment = KEYBIND_STRIP_ALIGN_RIGHT,
			{
				keybind = keybind,
				name = ""
			}
		}
	end
	self.keybindStripDescriptors = keybindStripDescriptors
end

local function OnAddonLoaded(event, name)
	if name ~= lib.name then
		return
	end
	em:UnregisterForEvent(lib.name, EVENT_ADD_ON_LOADED)
	internal:Initialize()
end

em:RegisterForEvent(lib.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

LibConsoleDialogs = lib
