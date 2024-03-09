local addon = {
	name = "VotansImprovedProvisioner",
	defaults = {},
	accountDefaults = {}
}
local em = GetEventManager()
local PROVISIONER = PROVISIONER

--- Add pooled status bar to ItemTooltip --
function ItemTooltip:VotanAddIngredient()
	if not self.votanIngredientPool then
		local ingredientPool = ZO_ControlPool:New("ZO_ProvisionerSlotRow", self, "VotanIngredientRow")
		ingredientPool:SetCustomFactoryBehavior(
			function(control)
				control.m_object = ZO_ProvisionerRow:New(PROVISIONER, control)
				control:GetNamedChild("Bg"):SetHidden(true)

				local icon = control:GetNamedChild("Icon")
				icon:SetDimensions(40, 40)
				icon:SetDrawLevel(1)
				control:GetNamedChild("Name"):SetFont("ZoFontGame")
				control:SetDimensions(control:GetParent():GetWidth() * 0.67, ZO_PROVISIONER_SLOT_ROW_HEIGHT - 6)
			end
		)
		self.votanIngredientPool = ingredientPool
		ZO_PreHookHandler(
			ItemTooltip,
			"OnCleared",
			function(...)
				ItemTooltip:VotanClearIngredients()
				return false
			end
		)
	end

	local ingredient = self.votanIngredientPool:AcquireObject()

	if ingredient then
		self:AddControl(ingredient)
		ingredient:SetAnchor(CENTER)
	end
	return ingredient
end

function ItemTooltip:VotanClearIngredients()
	if self.votanIngredientPool then
		self.votanIngredientPool:ReleaseAllObjects()
	end
end

function addon:HookNavigationEntry()
	local orgZO_ProvisionerNavigationEntry_OnMouseEnter = ZO_ProvisionerNavigationEntry_OnMouseEnter
	local orgZO_ProvisionerNavigationEntry_OnMouseExit = ZO_ProvisionerNavigationEntry_OnMouseExit

	function ZO_ProvisionerNavigationEntry_OnMouseEnter(self)
		if self.enabled then
			local data = self.data
			if not data then
				return
			end

			InitializeTooltip(ItemTooltip, self, RIGHT, -15, 0)
			local recipeListIndex, recipeIndex = data.recipeListIndex, data.recipeIndex
			ItemTooltip:SetProvisionerResultItem(recipeListIndex, recipeIndex)
			if self.meetsLevelReq and self.meetsQualityReq then
				for ingredientIndex = 1, data.numIngredients do
					local control = ItemTooltip:VotanAddIngredient()
					ItemTooltip:AddVerticalPadding(-14)
					local ingredientSlot = control.m_object

					local name, icon, requiredQuantity, _, quality = GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, ingredientIndex)
					local ingredientCount = GetCurrentRecipeIngredientCount(recipeListIndex, recipeIndex, ingredientIndex)

					ingredientSlot:SetItem(name, icon, ingredientCount, quality, requiredQuantity)
					ingredientSlot:SetItemIndices(recipeListIndex, recipeIndex, ingredientIndex)
				end
			else
				if not self.meetsLevelReq then
					for tradeskill, levelReq in pairs(data.tradeskillsLevelReqs) do
						local level = GetNonCombatBonus(GetNonCombatBonusLevelTypeForTradeskillType(tradeskill))
						if level < levelReq then
							local levelPassiveAbilityId = GetTradeskillLevelPassiveAbilityId(tradeskill)
							local levelPassiveAbilityName = GetAbilityName(levelPassiveAbilityId)
							ItemTooltip:AddLine(zo_strformat(SI_RECIPE_REQUIRES_LEVEL_PASSIVE, levelPassiveAbilityName, levelReq), "", ZO_ERROR_COLOR:UnpackRGBA())
						end
					end
				end
				if not self.meetsQualityReq then
					ItemTooltip:AddLine(zo_strformat(SI_PROVISIONER_REQUIRES_RECIPE_QUALITY, data.qualityReq), "", ZO_ERROR_COLOR:UnpackRGBA())
				end
			end
		end
		return ZO_SelectableLabel_OnMouseEnter(self)
	end

	function ZO_ProvisionerNavigationEntry_OnMouseExit(self)
		ClearTooltip(ItemTooltip)
		return orgZO_ProvisionerNavigationEntry_OnMouseExit(self)
	end
end

local glass = " |t40:40:/esoui/art/tutorial/gamepad/gp_inventory_trait_not_researched_icon.dds|t"
local lastSearchTerm
local lastIsMulti
local lastSplit
local isQualityFiltered
local shownQualities = {
	[ITEM_QUALITY_NORMAL] = true,
	[ITEM_QUALITY_MAGIC] = true,
	[ITEM_QUALITY_ARCANE] = true,
	[ITEM_QUALITY_ARTIFACT] = true,
	[ITEM_QUALITY_LEGENDARY] = true
}

do
	local zo_plainstrfind = zo_plainstrfind
	function addon:ProcessInventoryItem(name, data, searchTerm)
		return zo_plainstrfind(name, searchTerm)
	end
end

local function VotanSearchBoxMouseDown(bagSearch, button)
	if not bagSearch:HasFocus() and button == MOUSE_BUTTON_INDEX_RIGHT then
		bagSearch:SetText("")
	end
end

local function HideLabel(hidden)
	ZO_SmithingTopLevelModeMenuBarLabel:SetHidden(hidden)
end

local function setDefaultText(control, text)
	control:SetDefaultText(text)
end

local function SetupControl(bagSearchBg, ...)
	local bagSearch = bagSearchBg:GetNamedChild("Box")
	local closeButton = WINDOW_MANAGER:CreateControlFromVirtual(nil, bagSearchBg, "ZO_CloseButton")

	local textWidth = 170
	local otherControls = {...}
	local othersVisibility = {}
	for i = #otherControls, 1, -1 do
		if not otherControls[i] then
			table.remove(otherControls, i)
		end
	end
	for i, control in ipairs(otherControls) do
		othersVisibility[control] = control:IsHidden()
	end

	local function VotanSearchBoxFocusGained(bagSearch, ...)
		setDefaultText(bagSearch, "")
		bagSearchBg:SetAlpha(0.25)
		bagSearchBg:SetWidth(textWidth)
		closeButton:SetDimensions(16, 16)
		closeButton:SetHidden(false)
		HideLabel(true)
		for _, control in pairs(otherControls) do
			othersVisibility[control] = control:IsHidden()
			control:SetHidden(true)
		end
		return false
	end
	local function VotanSearchBoxFocusLost(bagSearch)
		if bagSearch:GetText() ~= "" then
			bagSearchBg:SetAlpha(0.25)
			bagSearchBg:SetWidth(textWidth)
			HideLabel(true)
		else
			bagSearchBg:SetAlpha(0)
			bagSearchBg:SetWidth(64)
			closeButton:SetHidden(true)
			HideLabel(false)
			for _, control in pairs(otherControls) do
				control:SetHidden(othersVisibility[control])
			end
			setDefaultText(bagSearch, glass)
		end
		return false
	end
	local function VotanSearchBoxTextChanged(control, ...)
		ZO_EditDefaultText_OnTextChanged(control)
		if WINDOW_MANAGER:GetFocusControl() ~= bagSearch then
			return VotanSearchBoxFocusLost(control, ...)
		end
	end
	local function VotanSearchBoxCloseClick(control)
		if bagSearch:GetText() ~= "" then
			bagSearch:SetText("")
			PROVISIONER:DirtyRecipeList()
		end
		PlaySound(SOUNDS.DEFAULT_CLICK)
		bagSearch:LoseFocus()
	end

	closeButton:ClearAnchors()
	closeButton:SetAnchor(TOPLEFT, bagSearch, TOPRIGHT, 0, 4)
	closeButton:SetHidden(true)
	closeButton:SetHandler("OnMouseDown", VotanSearchBoxCloseClick)
	closeButton:SetInheritAlpha(false)

	bagSearchBg:SetHidden(false)
	bagSearchBg:SetEdgeTexture("EsoUI/Art/Tooltips/UI-SliderBackdrop.dds", 32, 4)
	bagSearchBg:SetInsets(1, 1, 1, 1)
	bagSearch:ClearAnchors()
	bagSearch:SetAnchor(TOPLEFT, nil, TOPLEFT, 4, 4)
	bagSearch:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -20, -4)
	bagSearch:SetInheritAlpha(false)
	bagSearch:SetEditEnabled(true)
	setDefaultText(bagSearch, glass)
	VotanSearchBoxFocusLost(bagSearch)

	ZO_PreHookHandler(bagSearch, "OnMouseDown", VotanSearchBoxMouseDown)
	bagSearch:SetHandler("OnFocusGained", VotanSearchBoxFocusGained)
	bagSearch:SetHandler("OnFocusLost", VotanSearchBoxFocusLost)
	bagSearch:SetHandler("OnTextChanged", VotanSearchBoxTextChanged)
	bagSearch:SetHandler("OnEscape", VotanSearchBoxCloseClick)
	bagSearch:SetHandler(
		"OnEnter",
		function(control)
			if control:GetText() ~= lastSearchTerm then
				PROVISIONER:DirtyRecipeList()
			end
			control:LoseFocus()
		end
	)
end

function addon:HookProvisionerRefreshRecipeList()
	local function DoSearch(name, data, searchTerm)
		if lastSearchTerm ~= searchTerm then
			-- Do split once per run, only
			lastSearchTerm = searchTerm
			lastIsMulti = string.find(searchTerm, "+", 1, true)
			if lastIsMulti then
				lastSplit = {zo_strsplit("+", searchTerm)}
			end
		end
		if lastIsMulti then
			for i = 1, #lastSplit do
				if self:ProcessInventoryItem(name, data, lastSplit[i]) then
					return true
				end
			end
			return false
		end
		return self:ProcessInventoryItem(name, data, searchTerm)
	end

	local lastResult
	local orgPROVISIONER_MANAGERGetRecipeListData
	local function MyGetRecipeData(...)
		PROVISIONER_MANAGER.GetRecipeListData = orgPROVISIONER_MANAGERGetRecipeListData
		local recipeData = orgPROVISIONER_MANAGERGetRecipeListData(...)
		local searchTerm = self.searchBox:GetText():lower()
		if not lastResult or searchTerm ~= lastSearchTerm then
			local filteredRecipeData = {}
			local ZO_ShallowTableCopy = ZO_ShallowTableCopy
			for _, recipeList in pairs(recipeData) do
				local recipes = nil
				for _, recipe in ipairs(recipeList.recipes) do
					local name = recipe.searchName
					if not name then
						name = recipe.name:lower()
						recipe.searchName = name
					end
					if shownQualities[recipe.quality] and DoSearch(name, recipe, searchTerm) then
						recipes = recipes or {}
						recipes[#recipes + 1] = recipe
					end
				end
				if recipes then
					local newRecipeList = ZO_ShallowTableCopy(recipeList)
					newRecipeList.recipes = recipes
					filteredRecipeData[#filteredRecipeData + 1] = newRecipeList
				end
			end
			lastSearchTerm = searchTerm
			lastResult = filteredRecipeData
			return filteredRecipeData
		else
			return lastResult
		end
	end
	local orgRefreshRecipeList = PROVISIONER.RefreshRecipeList
	function PROVISIONER:RefreshRecipeList()
		if addon.searchBox:GetText() ~= "" or isQualityFiltered then
			orgPROVISIONER_MANAGERGetRecipeListData = PROVISIONER_MANAGER.GetRecipeListData
			PROVISIONER_MANAGER.GetRecipeListData = MyGetRecipeData
		else
			lastSearchTerm = ""
			lastResult = nil
		end
		return orgRefreshRecipeList(self)
	end

	ZO_PreHook(
		PROVISIONER,
		"EmbedInCraftingScene",
		function()
			self.searchBoxBg:ClearAnchors()
			self.searchBoxBg:SetAnchor(TOPLEFT, ZO_SharedRightPanelBackground, TOPLEFT, -12, 6)
		end
	)
	local RemoveFromCraftingScene
	if GetAPIVersion() < 101038 then
		function RemoveFromCraftingScene()
			self.searchBoxBg:ClearAnchors()
			self.searchBoxBg:SetAnchor(BOTTOMLEFT, ZO_ProvisionerTopLevelNavigationDivider, TOPLEFT, 0, -84)
		end
	else
		function RemoveFromCraftingScene()
			self.searchBoxBg:ClearAnchors()
			self.searchBoxBg:SetAnchor(TOPLEFT, ZO_SharedRightPanelBackground, TOPLEFT, -12, 6)
		end
	end
	ZO_PreHook(PROVISIONER, "RemoveFromCraftingScene", RemoveFromCraftingScene)
	PROVISIONER_SCENE:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_SHOWING then
				RemoveFromCraftingScene()
			end
		end
	)
	em:RegisterForEvent(
		addon.name,
		EVENT_CRAFTING_STATION_INTERACT,
		function(_, _, isCraftingSameAsPrevious)
			if not isCraftingSameAsPrevious then
				lastResult = nil
			end
		end
	)
end

do
	local barData = {
		initialButtonAnchorPoint = LEFT,
		buttonTemplate = "ZO_MenuBarTooltipButton",
		normalSize = 28,
		downSize = 32,
		buttonPadding = -11,
		animationDuration = DEFAULT_SCENE_TRANSITION_TIME
	}

	function addon:InitQualityBar()
		if GetAPIVersion() < 101038 then
			self.qualityBar = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Quality", ZO_ProvisionerTopLevel, "ZO_MenuBarTemplate")
			self.qualityBar:SetAnchor(TOPLEFT, ZO_ProvisionerTopLevelHaveIngredients, BOTTOMLEFT, -8.5, 5)
		else
			self.qualityBar = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Quality", ZO_ProvisionerTopLevelProvisioningFilters, "ZO_MenuBarTemplate")
			self.qualityBar:SetAnchor(TOPLEFT, ZO_ProvisionerTopLevelProvisioningFiltersHaveIngredients, BOTTOMLEFT, -8.5, 5)
		end

		ZO_MenuBar_OnInitialized(self.qualityBar)
		ZO_MenuBar_SetClickSound(self.qualityBar, SOUNDS.DEFAULT_CLICK)
		ZO_MenuBar_SetData(self.qualityBar, barData)

		local function newRelease(button)
			local orgRelease = button.m_object.Release
			function button.m_object.Release(...)
				local self, upInside, skipAnimation, playerDriven = ...
				if self.m_locked then
					self:SetLocked(false)
					local buttonData = self.m_buttonData
					if buttonData.callback then
						buttonData:callback(playerDriven)
					end

					local clickSound = buttonData.clickSound or self.m_menuBar:GetClickSound()
					if clickSound and playerDriven then
						PlaySound(clickSound)
					end
				elseif playerDriven then
					return orgRelease(...)
				end
			end
		end
		assert(self.qualityBar.m_object.m_pool.customFactoryBehavior == nil, "ZO_MenuBarTemplate customFactoryBehavior hooked already")
		self.qualityBar.m_object.m_pool:SetCustomFactoryBehavior(newRelease)
		local function CreateButtonData(name, quality)
			return {
				activeTabText = name,
				categoryName = name,
				descriptor = quality,
				normal = "/esoui/art/buttons/gamepad/gp_checkbox_up.dds",
				pressed = "/esoui/art/buttons/gamepad/gp_checkbox_downover.dds",
				highlight = "/esoui/art/buttons/gamepad/gp_checkbox_upover.dds",
				disabled = "/esoui/art/buttons/gamepad/gp_checkbox_disabled.dds",
				callback = function(tabData)
					for q = ITEM_QUALITY_NORMAL, ITEM_QUALITY_LEGENDARY do
						shownQualities[q] = false
					end
					local selected = ZO_MenuBar_GetSelectedDescriptor(self.qualityBar)
					for i = 1, #selected do
						shownQualities[selected[i]] = true
					end
					lastSearchTerm = nil
					isQualityFiltered = #selected < 5
					PROVISIONER:DirtyRecipeList()
				end
			}
		end
		local function AddButton(data)
			local button = ZO_MenuBar_AddButton(self.qualityBar, data)
			button:GetNamedChild("Image"):SetColor(GetItemQualityColor(data.descriptor):UnpackRGB())
			button.m_object:Press(true)
		end
		function self.qualityBar.m_object.SetClickedButton(bar, buttonObject, skipAnimation)
			if not buttonObject then
				return
			end

			local currentState = buttonObject:GetState()
			buttonObject:SetLocked(true)
			if currentState == BSTATE_PRESSED then
				buttonObject:UnPress(skipAnimation)
			else
				buttonObject:Press(skipAnimation)
			end
		end
		function self.qualityBar.m_object:GetSelectedDescriptor()
			local result = {}
			for i, button in ipairs(self.m_buttons) do
				local buttonObject = button[1].m_object
				if buttonObject:GetState() == BSTATE_PRESSED then
					result[#result + 1] = buttonObject:GetDescriptor()
				end
			end
			return result
		end
		function self.qualityBar.m_object:SelectDescriptor()
		end

		AddButton(CreateButtonData(SI_ITEMQUALITY2, ITEM_QUALITY_NORMAL))
		AddButton(CreateButtonData(SI_ITEMQUALITY2, ITEM_QUALITY_MAGIC))
		AddButton(CreateButtonData(SI_ITEMQUALITY3, ITEM_QUALITY_ARCANE))
		AddButton(CreateButtonData(SI_ITEMQUALITY4, ITEM_QUALITY_ARTIFACT))
		AddButton(CreateButtonData(SI_ITEMQUALITY5, ITEM_QUALITY_LEGENDARY))
	end
end

function addon:Init()
	ZO_ProvisionerTopLevelDetailsDivider:SetHidden(true)
	ZO_ProvisionerTopLevelDetails:SetHidden(true)
	if GetAPIVersion() < 101038 then
		ZO_ProvisionerTopLevelNavigationContainer:ClearAnchors()
		ZO_ProvisionerTopLevelNavigationDivider:SetAnchor(TOPLEFT, ZO_ProvisionerTopLevelMenuBarDivider, BOTTOMLEFT, 0, ZO_ProvisionerTopLevelMenuBarDivider:GetTop() + 24)
		ZO_ProvisionerTopLevelNavigationContainer:SetAnchor(TOPLEFT, ZO_ProvisionerTopLevelNavigationDivider, BOTTOMLEFT, 40, 0)
		ZO_ProvisionerTopLevelNavigationContainer:SetAnchor(BOTTOMLEFT, ZO_ProvisionerTopLevelInfoBar, TOPLEFT, 0, -12)
	else
		ZO_ProvisionerTopLevelNavigationContainer:ClearAnchors()
		ZO_ProvisionerTopLevelProvisioningFiltersNavigationDivider:SetAnchor(TOPLEFT, ZO_ProvisionerTopLevelMenuBarDivider, BOTTOMLEFT, 0, ZO_ProvisionerTopLevelMenuBarDivider:GetTop() + 24)
		ZO_ProvisionerTopLevelNavigationContainer:SetAnchor(TOPLEFT, ZO_ProvisionerTopLevelProvisioningFiltersNavigationDivider, BOTTOMLEFT, 40, 0)
		ZO_ProvisionerTopLevelNavigationContainer:SetAnchor(BOTTOMLEFT, ZO_ProvisionerTopLevelInfoBar, TOPLEFT, 0, -12)
		ZO_ProvisionerTopLevelDetailsIngredientsLabel:SetHidden(true)
		ZO_ProvisionerTopLevelDetailsDivider.SetHidden = function()
		end
	end

	local wm = GetWindowManager()

	local offsetY = -108
	local slotContainer = wm:CreateControl("$(parent)SlotContainer", ZO_ProvisionerTopLevel, CT_CONTROL)
	self.slotContainer = slotContainer
	slotContainer:SetDimensions(720, 160)
	slotContainer:SetAnchor(BOTTOM, GuiRoot, BOTTOM, 32, offsetY)
	slotContainer:SetDrawLayer(DL_BACKGROUND)
	-- local bg = wm:CreateControl("$(parent)Bg", slotContainer, CT_TEXTURE)
	-- bg:SetTexture("EsoUI/Art/Crafting/crafting_alchemy_slottingBG.dds")
	-- bg:SetDimensions(720, 512)
	-- bg:SetAnchor(BOTTOM, nil, BOTTOM, -32, 320)

	ZO_ProvisionerTopLevelDetailsIngredients:SetParent(slotContainer)
	ZO_ProvisionerTopLevelDetailsIngredients:ClearAnchors()
	ZO_ProvisionerTopLevelDetailsIngredients:SetAnchor(TOP)

	local function setupSlot(slot)
		slot:SetDimensions(ZO_PROVISIONER_SLOT_ROW_WIDTH - 66, ZO_PROVISIONER_SLOT_ROW_HEIGHT - 6)

		local bg = slot:GetNamedChild("Bg")
		bg:SetTexture("esoui/art/performance/statusmetermunge.dds")
		bg:SetColor(1, 1, 1, 0.75)
		bg:ClearAnchors()
		bg:SetAnchor(TOPLEFT, nil, TOPLEFT, -70, -70)
		bg:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, 70, 70)

		local icon = slot:GetNamedChild("Icon")
		icon:SetDimensions(40, 40)
		icon:SetDrawLevel(1)
		local name = slot:GetNamedChild("Name")
		name:SetFont("ZoFontGame")
		name:SetDimensionConstraints(0, 0, ZO_PROVISIONER_SLOT_ROW_WIDTH - 106, ZO_PROVISIONER_SLOT_ROW_HEIGHT - 6)
		local count = slot:GetNamedChild("Count")
		count:GetNamedChild("Numerator"):SetHidden(true)
		count:GetNamedChild("Divider"):SetHidden(true)
		local dom = count:GetNamedChild("Denominator")
		dom:ClearAnchors()
		dom:SetAnchor(BOTTOMRIGHT, icon, BOTTOMRIGHT, 0, 4)
	end

	CRAFTING_PREVIEW_OPTIONS_FRAGMENT:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				slotContainer:SetAnchor(BOTTOM, GuiRoot, BOTTOM, 32, -108)
			elseif newState == SCENE_FRAGMENT_HIDING then
				slotContainer:SetAnchor(BOTTOM, GuiRoot, BOTTOM, 32, offsetY)
			end
		end
	)

	local ingredientAnchor = ZO_Anchor:New(TOPLEFT, PROVISIONER.ingredientRowsContainer, TOPLEFT, 0, 0)

	local ingredientRows = PROVISIONER.ingredientRows
	for i = 1, #ingredientRows do
		local itemSlot = ingredientRows[i]
		local control = itemSlot.control
		setupSlot(control)
		ZO_Anchor_BoxLayout(ingredientAnchor, control, i - 1, 3, 0, 0, ZO_PROVISIONER_SLOT_ROW_WIDTH - 64, ZO_PROVISIONER_SLOT_ROW_HEIGHT - 4, 0, 18)
	end

	ZO_ProvisionerTopLevelMultiCraftContainerBg:SetDimensions(720, 512)
	ZO_ProvisionerTopLevelMultiCraftContainerSpinner:ClearAnchors()
	ZO_ProvisionerTopLevelMultiCraftContainerSpinner:SetParent(slotContainer)
	ZO_ProvisionerTopLevelMultiCraftContainerSpinner:SetAnchor(BOTTOMLEFT, nil, BOTTOM, 40, 7)
	ZO_ProvisionerTopLevelMultiCraftContainerSpinner:SetDimensions(256, 32)
	ZO_ProvisionerTopLevelMultiCraftContainerSpinnerDecrease:ClearAnchors()
	ZO_ProvisionerTopLevelMultiCraftContainerSpinnerDecrease:SetAnchor(LEFT, nil, LEFT, 0, 0)
	ZO_ProvisionerTopLevelMultiCraftContainerSpinnerIncrease:ClearAnchors()
	ZO_ProvisionerTopLevelMultiCraftContainerSpinnerIncrease:SetAnchor(RIGHT, nil, CENTER, 0, 0)
	ZO_ProvisionerTopLevelMultiCraftContainerSpinnerMinMax:ClearAnchors()
	ZO_ProvisionerTopLevelMultiCraftContainerSpinnerMinMax:SetAnchor(RIGHT, nil, RIGHT, 0, 0)

	local orgGetMultiCraftNumIterations = ZO_Provisioner.GetMultiCraftNumIterations
	function ZO_Provisioner.GetMultiCraftNumIterations(...)
		local self = ...
		if self.multiCraftContainer:IsControlHidden() and not slotContainer:IsControlHidden() then
			return self.multiCraftSpinner:GetValue()
		end
		return orgGetMultiCraftNumIterations(...)
	end

	if GetAPIVersion() >= 101038 then
		SecurePostHook(
			ZO_Provisioner,
			"OnTabFilterChanged",
			function(provisioner)
				slotContainer:SetHidden(provisioner.filterType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FILLET)
			end
		)
	end
	local searchBoxBg = wm:CreateControlFromVirtual("$(parent)VotanSearch", GetAPIVersion() < 101038 and ZO_ProvisionerTopLevel or ZO_ProvisionerTopLevelProvisioningFilters, "ZO_InventorySearchTemplate")
	self.searchBoxBg = searchBoxBg
	self.searchBox = searchBoxBg:GetNamedChild("Box")
	SetupControl(searchBoxBg)

	self:HookNavigationEntry()
	self:HookProvisionerRefreshRecipeList()
	self:InitQualityBar()
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon:Init()
	-- addon:InitSettings()
end

VOTANS_IMPROVED_PROVISIONER = addon

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
