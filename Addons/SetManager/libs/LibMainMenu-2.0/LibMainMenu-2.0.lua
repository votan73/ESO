-- Feel free to use this library --
-- but do not modify without sending a pm to me (votan at www.esoui.com) to avoid version conflicts --

-- Register with LibStub
local MAJOR, MINOR = "LibMainMenu-2.0", 3
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end -- the same or newer version of this lib is already loaded into memory

local function GetMainMenu()
	return GetAPIVersion() <= 100012 and MAIN_MENU or MAIN_MENU_KEYBOARD
end

local function InitMenu()
	GetMainMenu().categoryBarFragment.duration = 250
	EVENT_MANAGER:UnregisterForEvent(MAJOR, EVENT_SECURE_RENDER_MODE_CHANGED)
	EVENT_MANAGER:RegisterForEvent(MAJOR, EVENT_SECURE_RENDER_MODE_CHANGED, function(eventCode, enabled)
		if not enabled and GetMainMenu().lastCategory == MENU_CATEGORY_MARKET then
			GetMainMenu().lastCategory = MENU_CATEGORY_INVENTORY
			ZO_MenuBar_ClearSelection(GetMainMenu().categoryBar)
		end
	end )
end

function lib:Init()
	if not lib.initialized then
		lib.initialized = true
		InitMenu()
	end
end

function lib:AddMenuItem(a, b, c, d)
	local function AddButton(descriptor, categoryLayoutInfo)
		-- descriptor does not need to be an integer -- #(MAIN_MENU.categoryInfo) + 1
		categoryLayoutInfo.descriptor = descriptor
		ZO_MenuBar_AddButton(GetMainMenu().categoryBar, categoryLayoutInfo)
	end
	local function AddScene(descriptor, sceneName, categoryLayoutInfo, optionalSceneGroupName)
		local subcategoryBar = CreateControlFromVirtual("ZO_MainMenuSubcategoryBar", GetMainMenu().control, "ZO_MainMenuSubcategoryBar", descriptor)
		subcategoryBar:SetAnchor(TOP, GetMainMenu().categoryBar, BOTTOM, 0, 7)
		-- No animation => instant hide is important, otherwise you get "access private function StopAllMovement" :)
		local subcategoryBarFragment = ZO_FadeSceneFragment:New(subcategoryBar, false, 0)
		GetMainMenu().categoryInfo[descriptor] =
		{
			barControls = { },
			subcategoryBar = subcategoryBar,
			subcategoryBarFragment = subcategoryBarFragment,
			sceneName = sceneName,
		}

		-- category must be known => choose a best matching => MENU_CATEGORY_MAIL
		GetMainMenu():AddRawScene(sceneName, MENU_CATEGORY_MAIL, GetMainMenu().categoryInfo[descriptor], optionalSceneGroupName)
	end
	local function AddButtonWithScene(descriptor, sceneName, categoryLayoutInfo, optionalSceneGroupName)
		AddButton(descriptor, categoryLayoutInfo)
		AddScene(descriptor, sceneName, categoryLayoutInfo, optionalSceneGroupName)
	end
	if c then
		AddButtonWithScene(a, b, c, d)
	else
		AddButton(a, b)
	end
end

function lib:SelectMenuItem(descriptor)
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then return end

	local categoryInfo = GetMainMenu().categoryInfo[descriptor]
	assert(categoryInfo ~= nil, "descriptor not found")

	local button = GetMainMenu().categoryBar.m_object:ButtonObjectForDescriptor(descriptor)
	if button == nil then return end
	local buttonData = button.m_buttonData

	local visible = buttonData.visible
	visible = visible ~= nil and visible(buttonData) or(visible == nil)

	if visible then
		if ZO_MenuBar_GetSelectedDescriptor(GetMainMenu().categoryBar) == descriptor then
			if buttonData.callback then buttonData.callback(buttonData) end
		else
			ZO_MenuBar_SelectDescriptor(GetMainMenu().categoryBar, descriptor)
		end
	else
		ZO_MenuBar_ClearSelection(GetMainMenu().categoryBar)
		if buttonData.callback then buttonData.callback(buttonData) end
	end
end

function lib:Refresh()
	ZO_MenuBar_UpdateButtons(GetMainMenu().categoryBar)
end
