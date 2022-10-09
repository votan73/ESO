-- Feel free to use this library --
-- but do not modify without sending a pm to me (votan at www.esoui.com) to avoid version conflicts --

-- Register with LibStub, if LibStub is loaded.
local MAJOR, MINOR = "LibEnchantingStation", 9999
local lib, oldminor = LibStub and LibStub:NewLibrary(MAJOR, MINOR)
if LibStub and lib then
	assert(MAJOR .. " still loaded via LibStub.")
end
lib = lib or {}

local function HideOtherTabs(tab)
	local content = lib.content
	for i = 1, content:GetNumChildren() do
		local child = content:GetChild(i)
		child:SetHidden(child ~= tab)
	end
end

local suspend
local function InitStationButton()
	local orgOnModeUpdated = ZO_Enchanting.OnModeUpdated
	ZO_Enchanting.OnModeUpdated = function(self, ...)
		if not suspend then
			local descriptor = ZO_MenuBar_GetSelectedDescriptor(self.modeBar)
			if descriptor == ENCHANTING_MODE_CREATION or descriptor == ENCHANTING_MODE_EXTRACTION or descriptor == ENCHANTING_MODE_RECIPES then
				-- mode matched selected descriptor = selected tab => original control
				lib.currentControl = ZO_EnchantingTopLevelInventory
			end
			HideOtherTabs(lib.currentControl)
		end
		return orgOnModeUpdated(self, ...)
	end

	local orgInventoryControlSetHidden = ENCHANTING.inventoryControl.SetHidden
	ENCHANTING.inventoryControl.SetHidden = function(self, hidden)
		local descriptor = ZO_MenuBar_GetSelectedDescriptor(ENCHANTING.modeBar)
		return orgInventoryControlSetHidden(self, hidden or(descriptor ~= ENCHANTING_MODE_CREATION and descriptor ~= ENCHANTING_MODE_EXTRACTION))
	end
end

function lib:Init()
	if not lib.content then
		local content = WINDOW_MANAGER:CreateControl("$(parent)Content", ZO_EnchantingTopLevel, CT_CONTROL)
		content:SetExcludeFromResizeToFitExtents(true)
		content:SetWidth(568)
		content:SetAnchor(TOPLEFT, ZO_SharedRightPanelBackground, TOPLEFT, 0, 63)
		content:SetAnchor(BOTTOMLEFT, ZO_SharedRightPanelBackground, BOTTOMLEFT, 0, -30)
		lib.content = content

		ZO_EnchantingTopLevelInventory:SetParent(content)
		InitStationButton()
	end
end

function lib:AddTab(tabData)
	local name = tabData.name
	local control = WINDOW_MANAGER:CreateControl("$(grandparent)" .. tabData.descriptor, lib.content, CT_CONTROL)
	control:SetAnchorFill()

	local creationData = {
		activeTabText = name,
		categoryName = name,
		descriptor = tabData.descriptor,
		normal = tabData.normal,
		pressed = tabData.pressed,
		highlight = tabData.highlight,
		disabled = tabData.disabled,
		callback = function(...)
			lib:SetText(GetString(name))
			lib.currentControl = control
			ENCHANTING.enchantingMode = tabData.descriptor
			ENCHANTING:OnModeUpdated()
			lib:HideSlotContainer()
			if tabData.callback then tabData.callback(...) end
		end,
	}
	ZO_MenuBar_AddButton(ENCHANTING.modeBar, creationData)
	control:SetHidden(true)
	return control
end

function lib:SelectTab(descriptor)
	ZO_MenuBar_SelectDescriptor(ENCHANTING.modeBar, descriptor, false)
end

function lib:SetText(text)
	ENCHANTING.modeBarLabel:SetText(text)
end

do
	local function FakeEnchantingMode(mode)
		suspend = true
		ENCHANTING.enchantingMode = mode
		ENCHANTING:OnModeUpdated()
		suspend = false
	end
	function lib:ShowRuneSlotContainer()
		FakeEnchantingMode(ENCHANTING_MODE_CREATION)
	end

	function lib:ShowExtractionSlotContainer()
		FakeEnchantingMode(ENCHANTING_MODE_EXTRACTION)
	end
end

function lib:HideSlotContainer()
	CRAFTING_RESULTS:SetCraftingTooltip(nil)
	ENCHANTING.runeSlotContainer:SetHidden(false)
	ENCHANTING.inventoryControl:SetHidden(true)
	ENCHANTING.extractionSlotContainer:SetHidden(true)
	ENCHANTING.resultTooltip:SetHidden(true)
	CRAFTING_RESULTS:SetTooltipAnimationSounds(nil)
end

LibEnchantingStation = lib
