-- Feel free to use this library --
-- but do not modify without sending a pm to me (votan at www.esoui.com) to avoid version conflicts --

if LibMainMenu2 then return end
local MAJOR, MINOR = "LibMainMenu-2.0", 40400
local lib = {}
lib.name	= MAJOR
lib.version = MINOR

local function GetMainMenu()
	return MAIN_MENU_KEYBOARD
end

local function InitMenu(self)
	local menu = GetMainMenu()
	local MainMenu_Keyboard = getmetatable(menu).__index
	local orgRefreshCategoryIndicators = MainMenu_Keyboard.RefreshCategoryIndicators
	local function getCategories(...)
		MainMenu_Keyboard.RefreshCategoryIndicators = orgRefreshCategoryIndicators
		local _ipairs = ipairs
		function ipairs(categories)
			lib.CATEGORY_LAYOUT_INFO = categories
			ipairs = _ipairs
			return ipairs(categories)
		end
		return orgRefreshCategoryIndicators(...)
	end
	MainMenu_Keyboard.RefreshCategoryIndicators = getCategories
	menu:RefreshCategoryIndicators()

	menu.categoryBarFragment.duration = 250
	EVENT_MANAGER:UnregisterForEvent(MAJOR, EVENT_SECURE_RENDER_MODE_CHANGED)
	EVENT_MANAGER:RegisterForEvent(
		MAJOR,
		EVENT_SECURE_RENDER_MODE_CHANGED,
		function(eventCode, enabled)
			if not enabled and GetMainMenu().lastCategory == MENU_CATEGORY_MARKET then
				GetMainMenu().lastCategory = MENU_CATEGORY_INVENTORY
				ZO_MenuBar_ClearSelection(GetMainMenu().categoryBar)
			end
		end
	)

	local LMMXML = CreateTopLevelWindow("LMMXML")
	LMMXML:SetAnchor(CENTER, GuiRoot, nil, 0, 28)
	local categoryBar = CreateControlFromVirtual("$(parent)CategoryBar", LMMXML, "ZO_MenuBarTemplate")
	categoryBar:SetAnchor(TOP)
	local sceneGroupBar = CreateControlFromVirtual("$(parent)SceneGroupBar", LMMXML, "ZO_LabelButtonBar")
	sceneGroupBar:SetAnchor(RIGHT, GuiRoot, nil, -40, -340)

	local libMainMenuSubcategoryButton = CreateControl("libMainMenuSubcategoryButton", GuiRoot, CT_LABEL)
	libMainMenuSubcategoryButton:SetColor(ZO_CONTRAST_TEXT:UnpackRGBA())
	libMainMenuSubcategoryButton:SetFont("ZoFontHeader3")
	libMainMenuSubcategoryButton:SetHandler(
		"OnMouseEnter",
		function(self)
			self:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGBA())
		end
	)
	libMainMenuSubcategoryButton:SetHandler(
		"OnMouseExit",
		function(self)
			self:SetColor(ZO_CONTRAST_TEXT:UnpackRGBA())
		end
	)
	libMainMenuSubcategoryButton:SetMouseEnabled(true)

	self.control = LMMXML

	self.categoryBar = GetControl(self.control, "CategoryBar")
	self.categoryBarFragment = ZO_FadeSceneFragment:New(self.categoryBar)

	self.sceneGroupBar = GetControl(self.control, "SceneGroupBar")
	self.sceneGroupBarLabel = GetControl(self.control, "SceneGroupBarLabel")

	self.tabPressedCallback = function(ctrl)
		if ctrl.sceneGroupName then
			self:OnSceneGroupTabClicked(ctrl.sceneGroupName)
		end
	end

	self.sceneShowCallback = function(oldState, newState)
		if (newState == SCENE_SHOWING) then
			local sceneGroupInfo = self.sceneGroupInfo[self.sceneShowGroupName]
			self:SetupSceneGroupBar(sceneGroupInfo.category, self.sceneShowGroupName)
			local scene = SCENE_MANAGER:GetCurrentScene()
			scene:UnregisterCallback("StateChange", self.sceneShowCallback)
		end
	end

	menu.lastCategory = MENU_CATEGORY_INVENTORY

	self.categoryInfo = menu.categoryInfo
	self.sceneInfo = menu.sceneInfo
	self.sceneGroupInfo = menu.sceneGroupInfo
	self.categoryAreaFragments = menu.categoryAreaFragments
end

function lib:Init()
	if not self.initialized then
		self.initialized = true
		return InitMenu(self)
	end
end

do
	local function AddButton(descriptor, categoryLayoutInfo)
		-- descriptor does not need to be an integer
		categoryLayoutInfo.descriptor = descriptor
		ZO_MenuBar_AddButton(GetMainMenu().categoryBar, categoryLayoutInfo)
	end
	local function AddScene(descriptor, sceneName, categoryLayoutInfo, sceneGroupName)
		local menu = GetMainMenu()
		local subcategoryBar = CreateControlFromVirtual("ZO_MainMenuSubcategoryBar", menu.control, "ZO_MainMenuSubcategoryBar", descriptor)
		subcategoryBar:SetAnchor(TOP, menu.categoryBar, BOTTOM, 0, 7)

		local subcategoryBarFragment = ZO_FadeSceneFragment:New(subcategoryBar, false, 150)
		local categoryInfo = {
			barControls = {},
			subcategoryBar = subcategoryBar,
			subcategoryBarFragment = subcategoryBarFragment,
			sceneName = sceneName
		}

		local category = #lib.CATEGORY_LAYOUT_INFO + 1
		lib.CATEGORY_LAYOUT_INFO[category] = categoryLayoutInfo
		menu.categoryInfo[category] = categoryInfo
		menu.categoryInfo[descriptor] = categoryInfo

		local sceneInfo = {
			category = category,
			sceneName = sceneName,
			sceneGroupName = sceneGroupName
		}
		menu.sceneInfo[sceneName] = sceneInfo

		local scene = SCENE_MANAGER:GetScene(sceneName)
		scene:AddFragment(categoryInfo.subcategoryBarFragment)
		for i, categoryAreaFragment in ipairs(menu.categoryAreaFragments) do
			scene:AddFragment(categoryAreaFragment)
		end

		scene:RegisterCallback(
			"StateChange",
			function(oldState, newState)
				if newState == SCENE_SHOWING then
					menu.ignoreCallbacks = true

					local skipAnimation = not menu:IsShowing()
					ZO_MenuBar_SelectDescriptor(menu.categoryBar, descriptor, skipAnimation)
					menu.lastCategory = category

					if sceneGroupName then
						local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
						sceneGroup:SetActiveScene(sceneName)
					else
						menu:SetLastSceneName(categoryInfo, sceneName)
					end

					menu.ignoreCallbacks = false
				end
			end
		)
	end
	local function AddButtonWithScene(descriptor, sceneName, categoryLayoutInfo, sceneGroupName)
		AddButton(descriptor, categoryLayoutInfo)
		AddScene(descriptor, sceneName, categoryLayoutInfo, sceneGroupName)
	end
	function lib:AddMenuItem(a, b, c, d)
		if c then
			AddButtonWithScene(a, b, c, d)
		else
			AddButton(a, b)
		end
	end
end

function lib:SelectMenuItem(descriptor)
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then
		return
	end

	local categoryInfo = self.categoryInfo[descriptor]
	assert(categoryInfo ~= nil, "descriptor not found")

	local categoryBar = GetMainMenu().categoryBar
	local button = categoryBar.m_object:ButtonObjectForDescriptor(descriptor)
	if button == nil then
		return
	end
	local buttonData = button.m_buttonData

	local visible = buttonData.visible
	visible = visible ~= nil and visible(buttonData) or (visible == nil)

	if visible then
		if ZO_MenuBar_GetSelectedDescriptor(categoryBar) == descriptor then
			if buttonData.callback then
				buttonData.callback(buttonData)
			end
		else
			ZO_MenuBar_SelectDescriptor(categoryBar, descriptor, true)
		end
	else
		ZO_MenuBar_ClearSelection(categoryBar)
		if buttonData.callback then
			buttonData.callback(buttonData)
		end
	end
end

function lib:Refresh()
	ZO_MenuBar_UpdateButtons(GetMainMenu().categoryBar)
end

-- LibMainMenu 1 --

function lib:SetupSceneGroupBar(category, sceneGroupName)
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then
		return
	end

	if self.sceneGroupInfo[sceneGroupName] then
		-- This is a scene group
		ZO_MenuBar_ClearButtons(self.sceneGroupBar)

		local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
		local menuBarIconData = self.sceneGroupInfo[sceneGroupName].menuBarIconData
		for i, layoutData in ipairs(menuBarIconData) do
			local sceneName = layoutData.descriptor
			layoutData.callback = function()
				if not self.ignoreCallbacks then
					sceneGroup:SetActiveScene(sceneName)
					self:Update(category, sceneName)
				end
			end
			ZO_MenuBar_AddButton(self.sceneGroupBar, layoutData)
			ZO_MenuBar_SetDescriptorEnabled(self.sceneGroupBar, layoutData.descriptor, (layoutData.enabled == nil or layoutData.enabled == true))
		end

		local activeSceneName = sceneGroup:GetActiveScene()
		local layoutData
		for i = 1, #menuBarIconData do
			if (menuBarIconData[i].descriptor == activeSceneName) then
				layoutData = menuBarIconData[i]
				break
			end
		end

		self.ignoreCallbacks = true

		if (layoutData) then
			if not ZO_MenuBar_SelectDescriptor(self.sceneGroupBar, activeSceneName) then
				self.ignoreCallbacks = false
				ZO_MenuBar_SelectFirstVisibleButton(self.sceneGroupBar, true)
			end

			self.sceneGroupBarLabel:SetHidden(false)
			self.sceneGroupBarLabel:SetText(GetString(layoutData.categoryName))
		end

		self.ignoreCallbacks = false
	end
end

function lib:AddCategory(data)
	self:Init()

	table.insert(lib.CATEGORY_LAYOUT_INFO, data)
	lib.CATEGORY_LAYOUT_INFO[#lib.CATEGORY_LAYOUT_INFO].descriptor = #lib.CATEGORY_LAYOUT_INFO

	--[[
	local categoryBarData =
    {
        buttonPadding = 16,
        normalSize = 51,
        downSize = 64,
        animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
        buttonTemplate = "LibMainmenuCategoryBarButton",
    }
	]] local subcategoryBar =
		CreateControl("libMainMenuSubcategoryBar" .. #lib.CATEGORY_LAYOUT_INFO, self.control, CT_CONTROL)
	--subcategoryBar:SetAnchor(TOP, self.categoryBar, BOTTOM, 0, 7)
	local subcategoryBarFragment = ZO_FadeSceneFragment:New(subcategoryBar)
	self.categoryInfo[#lib.CATEGORY_LAYOUT_INFO] = {
		barControls = {},
		subcategoryBar = subcategoryBar,
		subcategoryBarFragment = subcategoryBarFragment
	}

	self:RefreshCategoryIndicators()
	self:AddCategoryAreaFragment(self.categoryBarFragment)

	return #lib.CATEGORY_LAYOUT_INFO
end

function lib:RefreshCategoryIndicators()
	for i, categoryLayoutData in ipairs(lib.CATEGORY_LAYOUT_INFO) do
		local indicators = categoryLayoutData.indicators
		if indicators then
			local buttonControl = ZO_MenuBar_GetButtonControl(self.categoryBar, categoryLayoutData.descriptor)
			if buttonControl then
				local indicatorTexture = buttonControl:GetNamedChild("Indicator")
				local textures
				if type(indicators) == "table" then
					textures = indicators
				elseif type(indicators) == "function" then
					textures = indicators()
				end
				if textures and #textures > 0 then
					indicatorTexture:ClearIcons()
					for _, texture in ipairs(textures) do
						indicatorTexture:AddIcon(texture)
					end
					indicatorTexture:Show()
				else
					indicatorTexture:Hide()
				end
			end
		end
	end
end

function lib:AddCategoryAreaFragment(fragment)
	self.categoryAreaFragments[#self.categoryAreaFragments + 1] = fragment
end

function lib:OnCategoryClicked(category)
	if (not self.ignoreCallbacks) then
		self:ShowCategory(category)
	end
end

function lib:ShowCategory(category)
	local categoryLayoutInfo = lib.CATEGORY_LAYOUT_INFO[category]
	local categoryInfo = self.categoryInfo[category]
	if (categoryInfo.lastSceneName) then
		self:ShowScene(categoryInfo.lastSceneName)
	else
		self:ShowSceneGroup(categoryInfo.lastSceneGroupName)
	end
end

function lib:ShowScene(sceneName)
	local sceneInfo = self.sceneInfo[sceneName]
	if sceneInfo.sceneGroupName then
		self:ShowSceneGroup(sceneInfo.sceneGroupName, sceneName)
	else
		self:Update(sceneInfo.category, sceneName)
	end
end

function lib:ShowSceneGroup(sceneGroupName, specificScene)
	local sceneGroupInfo = self.sceneGroupInfo[sceneGroupName]
	if (not specificScene) then
		local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
		specificScene = sceneGroup:GetActiveScene()
	end

	self:Update(sceneGroupInfo.category, specificScene)
end

function lib:Update(category, sceneName)
	self.ignoreCallbacks = true

	local categoryInfo = self.categoryInfo[category]

	-- This is a scene
	local sceneInfo = self.sceneInfo[sceneName]
	local skipAnimation = not self:IsShowing()
	ZO_MenuBar_SelectDescriptor(self.categoryBar, category, skipAnimation)
	GetMainMenu().lastCategory = category

	self:SetLastSceneName(categoryInfo, sceneName)

	if sceneInfo.sceneGroupName then
		-- This scene is part of a scene group, need to update the selected
		local scene = SCENE_MANAGER:GetScene(sceneName)
		self.sceneShowGroupName = sceneInfo.sceneGroupName
		scene:RegisterCallback("StateChange", self.sceneShowCallback)
		local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneInfo.sceneGroupName)
		sceneGroup:SetActiveScene(sceneName)
		self:SetLastSceneGroupName(categoryInfo, sceneInfo.sceneGroupName)
	end

	SCENE_MANAGER:Show(sceneName)

	self.ignoreCallbacks = false
end

function lib:SetLastSceneName(categoryInfo, sceneName)
	categoryInfo.lastSceneName = sceneName
	categoryInfo.lastSceneGroupName = nil
end

function lib:SetLastSceneGroupName(categoryInfo, sceneGroupName)
	categoryInfo.lastSceneGroupName = sceneGroupName
	categoryInfo.lastSceneName = nil
end

function lib:IsShowing()
	return self.categoryBarFragment:IsShowing()
end

function lib:AddSceneGroup(category, sceneGroupName, menuBarIconData)
	local categoryInfo = self.categoryInfo[category]
	local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)

	for i = 1, sceneGroup:GetNumScenes() do
		local sceneName = sceneGroup:GetSceneName(i)
		local scene = lib:AddRawScene(sceneName, category, categoryInfo, sceneGroupName)
	end

	if (not self:HasLast(categoryInfo)) then
		self:SetLastSceneGroupName(categoryInfo, sceneGroupName)
	end

	local sceneGroupBarFragment = ZO_FadeSceneFragment:New(self.sceneGroupBar)
	for i = 1, #menuBarIconData do
		local sceneName = menuBarIconData[i].descriptor
		local scene = SCENE_MANAGER:GetScene(sceneName)
		scene:AddFragment(sceneGroupBarFragment)
	end

	self.sceneGroupInfo[sceneGroupName] = {
		menuBarIconData = menuBarIconData,
		category = category,
		sceneGroupBarFragment = sceneGroupBarFragment
	}
end

function lib:HasLast(categoryInfo)
	return categoryInfo.lastSceneName ~= nil or categoryInfo.lastSceneGroupName ~= nil
end

function lib:AddRawScene(sceneName, category, categoryInfo, sceneGroupName)
	local scene = SCENE_MANAGER:GetScene(sceneName)
	--scene:AddFragment(categoryInfo.subcategoryBarFragment)

	local hideCategoryBar = self.categoryInfo[category].hideCategoryBar
	if hideCategoryBar == nil or hideCategoryBar == false then
		for i, categoryAreaFragment in ipairs(self.categoryAreaFragments) do
			scene:AddFragment(categoryAreaFragment)
		end
	end

	local sceneInfo = {
		category = category,
		sceneName = sceneName,
		sceneGroupName = sceneGroupName
	}

	self.sceneInfo[sceneName] = sceneInfo

	return scene
end

function lib:ToggleCategory(category)
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then
		return
	end
	local categoryLayoutInfo = self.CATEGORY_LAYOUT_INFO[category]
	local categoryInfo = self.categoryInfo[category]
	if (categoryInfo.lastSceneName) then
		self:ToggleScene(categoryInfo.lastSceneName)
	else
		self:ToggleSceneGroup(categoryInfo.lastSceneGroupName)
	end
end

function lib:ToggleSceneGroup(sceneGroupName, specificScene)
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then
		return
	end
	local sceneGroupInfo = self.sceneGroupInfo[sceneGroupName]
	if (not specificScene) then
		local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
		specificScene = sceneGroup:GetActiveScene()
	end

	if self:IsShowing() and GetMainMenu().lastCategory == sceneGroupInfo.category then
		SCENE_MANAGER:ShowBaseScene()
	else
		self:Update(sceneGroupInfo.category, specificScene)
	end
end

function lib:ShowSceneGroup(sceneGroupName, specificScene)
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then
		return
	end
	local sceneGroupInfo = self.sceneGroupInfo[sceneGroupName]
	if (not specificScene) then
		local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
		specificScene = sceneGroup:GetActiveScene()
	end

	self:Update(sceneGroupInfo.category, specificScene)
end

function lib:ShowScene(sceneName)
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then
		return
	end
	local sceneInfo = self.sceneInfo[sceneName]
	if sceneInfo.sceneGroupName then
		self:ShowSceneGroup(sceneInfo.sceneGroupName, sceneName)
	else
		self:Update(sceneInfo.category, sceneName)
	end
end

function lib:ToggleScene(sceneName)
	if WINDOW_MANAGER:IsSecureRenderModeEnabled() then
		return
	end
	local sceneInfo = self.sceneInfo[sceneName]
	if (SCENE_MANAGER:IsShowing(sceneName)) then
		SCENE_MANAGER:ShowBaseScene()
	else
		self:ShowScene(sceneName)
	end
end

function lib:GetControl()
	return self.control
end

LibMainMenu2 = lib
