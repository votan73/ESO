-- authors: votan, sirinsidiator
-- thanks to: baertram & circonian

local MAJOR = "LibCustomMenu"
local lib = {}

local wm = WINDOW_MANAGER

----- Common -----
MENU_ADD_OPTION_HEADER = 100

local function SetupDivider(pool, control)
	local function GetTextDimensions(self)
		return 32, 7
	end
	local function Noop(self)
	end

	local label = wm:CreateControlFromVirtual("$(parent)Name", control, "ZO_BaseTooltipDivider")
	label:ClearAnchors()
	label:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 2)
	label:SetAnchor(TOPRIGHT, control, TOPRIGHT, 0, 2)
	-- First and last time the anchors are set
	label.ClearAnchors = Noop
	label.SetAnchor = Noop

	label.SetText = Noop
	label.SetFont = Noop
	label.GetTextDimensions = GetTextDimensions
	label.SetHorizontalAlignment = Noop
	label:SetHidden(false)
	control.nameLabel = label

	control.isDivider = true
	control.item = control
	control:SetMouseEnabled(false)
end

lib.DIVIDER = "-"

lib.headerFont = "ZoFontWinH3"

local function SetupHeader(pool, control)
	local label = control:GetNamedChild("Text")
	local divider = control:GetNamedChild("Divider")
	local orgGetTextDimensions = label.GetTextDimensions
	function label:GetTextDimensions()
		local w, h = orgGetTextDimensions(self)
		local hdivider = divider and (select(2, divider:GetDimensions()) + 9) or 0
		return w, h + hdivider
	end

	label:ClearAnchors()
	label:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 3)
	label:SetAnchor(TOPRIGHT, control, TOPRIGHT, 0, 3)
	label:SetMaxLineCount(1)

	label:SetHidden(false)
	control.nameLabel = label

	control.isHeader = true
	control.item = control
	control:SetMouseEnabled(false)

	if divider then
		divider:ClearAnchors()
		divider:SetAnchor(TOPLEFT, label, BOTTOMLEFT, 0, 3)
		divider:SetAnchor(RIGHT, control, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X)
	end
end

local function GetValueOrCallback(arg, ...)
	if type(arg) == "function" then
		return arg(...)
	else
		return arg
	end
end

local function runTooltip(control, inside)
	if control.tooltip then
		local text = GetValueOrCallback(control.tooltip, control, inside)
		if inside then
			if type(text) == "string" and text ~= "" then
				InitializeTooltip(InformationTooltip, control:GetParent(), BOTTOM, 0, -10)
				SetTooltipText(InformationTooltip, text)
			end
		elseif InformationTooltip:GetOwner() == control:GetParent() then
			ClearTooltip(InformationTooltip)
		end
	end
end

local function cleanupDivider(items)
	local wasDivider = true
	local height = 0
	for i = #items, 1, -1 do
		local menuEntry = items[i]
		local isDivider = menuEntry.isDivider
		if isDivider then
			if wasDivider or i == 1 then
				height = height + menuEntry.item.storedHeight
				menuEntry.item.storedHeight = 0
				menuEntry.item:SetHidden(true)
			else
				menuEntry.item:SetHidden(false)
			end
			wasDivider = isDivider
			isDivider = true
		else
			wasDivider = false
		end
	end
	return height
end

----- Sub Menu -----

local Submenu = ZO_Object:Subclass()

local SUBMENU_ITEM_MOUSE_ENTER = 1
local SUBMENU_ITEM_MOUSE_EXIT = 2
local SUBMENU_ITEM_MOUSE_CLICKED = 3
local SUBMENU_SHOW_TIMEOUT = 350
local SUBMENU_HIDE_TIMEOUT = 350

local submenuCallLaterHandle
local nextId = 1
local function ClearTimeout()
	if (submenuCallLaterHandle ~= nil) then
		EVENT_MANAGER:UnregisterForUpdate(submenuCallLaterHandle)
		submenuCallLaterHandle = nil
	end
end

local function SetTimeout(callback)
	if (submenuCallLaterHandle ~= nil) then
		ClearTimeout()
	end
	submenuCallLaterHandle = "LibCustomMenuSubMenuTimeout" .. nextId
	nextId = nextId + 1

	EVENT_MANAGER:RegisterForUpdate(
		submenuCallLaterHandle,
		SUBMENU_SHOW_TIMEOUT,
		function()
			ClearTimeout()
			if callback then
				callback()
			end
		end
	)
end

function Submenu:New(...)
	local object = ZO_Object.New(self)
	object:Initialize(...)
	return object
end

function Submenu:Initialize(name)
	self.window = ZO_Menus

	local submenuControl = self.window:CreateControl(name, CT_CONTROL)
	submenuControl:SetClampedToScreen(true)
	submenuControl:SetMouseEnabled(true)
	submenuControl:SetHidden(true)
	-- OnMouseEnter: Stop hiding of submenu initiated by mouse exit of parent
	submenuControl:SetHandler("OnMouseEnter", ClearTimeout)

	local function RefreshSubMenu()
		if self.parent and self.parent.OnSelect then
			self.parent:OnSelect(SUBMENU_ITEM_MOUSE_ENTER)
		end
	end

	local function ExitSubMenu()
		if self.parent and self.parent.OnSelect then
			self.parent:OnSelect(SUBMENU_ITEM_MOUSE_EXIT)
		end
	end
	submenuControl:SetHandler(
		"OnMouseExit",
		function(control)
			SetTimeout(ExitSubMenu)
		end
	)

	submenuControl:SetHandler(
		"OnHide",
		function(control)
			ClearTimeout()
			self:Clear()
		end
	)
	submenuControl:SetDrawLayer(ZO_Menu:GetDrawLayer())
	submenuControl:SetDrawTier(ZO_Menu:GetDrawTier())
	submenuControl:SetDrawLevel(ZO_Menu:GetDrawLevel() + 1)

	local bg = submenuControl:CreateControl("$(parent)BG", CT_BACKDROP)
	-- bg:SetCenterColor(0, 0, 0, .93)
	bg:SetCenterTexture("EsoUI/Art/Tooltips/UI-TooltipCenter.dds")
	bg:SetEdgeTexture("EsoUI/Art/Tooltips/UI-Border.dds", 128, 16)
	bg:SetInsets(16, 16, -16, -16)
	bg:SetAnchorFill()

	local overlay = bg:CreateControl("$(parent)MungeOverlay", CT_TEXTURE)
	overlay:SetTexture("EsoUI/Art/Tooltips/munge_overlay.dds")
	overlay:SetAddressMode(TEX_MODE_WRAP)
	overlay:SetAnchor(TOPLEFT)
	overlay:SetAnchor(BOTTOMRIGHT)

	self.highlight = CreateControlFromVirtual("$(parent)Highlight", submenuControl, "ZO_SelectionHighlight")
	self.highlight:SetHidden(true)

	self.control = submenuControl

	local upInside = nil
	local function MouseEnter(control)
		upInside = control
		ClearTimeout()
		self:SetSelectedIndex(control.index)
		runTooltip(control, upInside)
	end
	local function MouseExit(control)
		upInside = nil
		if (self.selectedIndex == control.index) then
			self:SetSelectedIndex(nil)
		end
		runTooltip(control, upInside)
	end
	local function MouseUp(control, button)
		if upInside == control and button == MOUSE_BUTTON_INDEX_LEFT then
			ZO_Menu_SetLastCommandWasFromMenu(true)
			if control.checkbox then
				-- The checkbox click handler will handle it
				ZO_CheckButton_OnClicked(control.checkbox, button)
			else
				if not control.OnSelect() then
					ClearMenu()
				end
			end
		end
	end

	local function ItemFactory(pool)
		local control = CreateControlFromVirtual("ZO_SubMenuItem", submenuControl, "ZO_MenuItem", pool:GetNextControlId())
		control:SetDrawLevel(3)
		control.nameLabel = GetControl(control, "Name")

		control:SetHandler("OnMouseEnter", MouseEnter)
		control:SetHandler("OnMouseExit", MouseExit)
		control:SetHandler("OnMouseDown", IgnoreMouseDownEditFocusLoss)
		control:SetHandler("OnMouseUp", MouseUp)

		return control
	end

	local function ResetFunction(control)
		control:SetHidden(true)
		control:ClearAnchors()
		control.OnSelect = nil
		control.menuIndex = nil
	end

	local function DividerFactory(pool)
		local control = CreateControlFromVirtual("ZO_CustomSubMenuDivider", submenuControl, "ZO_NotificationsRowButton", pool:GetNextControlId())
		SetupDivider(pool, control)
		return control
	end

	local function HeaderFactory(pool)
		local control = CreateControlFromVirtual("ZO_CustomSubMenuHeader", submenuControl, "ZO_AddOnSectionHeaderRow", pool:GetNextControlId())
		SetupHeader(pool, control)
		return control
	end

	local function ResetCheckbox(checkbox)
		ResetFunction(checkbox)
	end

	local function CheckBoxMouseEnter(control)
		MouseEnter(control:GetParent())
	end
	local function CheckBoxMouseExit(control)
		MouseExit(control:GetParent())
	end
	local function CheckBoxMouseUp(control)
		self.refCount = (self.refCount or 0) + 1
		local parent = control:GetParent()
		parent.OnSelect(ZO_CheckButton_IsChecked(control))
		RefreshSubMenu()
		control:GetHandler("OnMouseEnter")(control)
	end
	local function CheckBoxFactory(pool)
		local control = CreateControlFromVirtual("ZO_CustomSubMenuItemCheckButton", submenuControl, "ZO_CheckButton", pool:GetNextControlId())
		control:SetDrawLevel(3)
		control.nameLabel = control

		control:SetHandler("OnMouseEnter", CheckBoxMouseEnter)
		control:SetHandler("OnMouseExit", CheckBoxMouseExit)

		ZO_CheckButton_SetToggleFunction(control, CheckBoxMouseUp)

		return control
	end

	self.itemPool = ZO_ObjectPool:New(ItemFactory, ResetFunction)
	self.dividerPool = ZO_ObjectPool:New(DividerFactory, ResetFunction)
	self.checkBoxPool = ZO_ObjectPool:New(CheckBoxFactory, ResetCheckbox)
	self.headerPool = ZO_ObjectPool:New(HeaderFactory, ResetFunction)
	self.items = {}

	EVENT_MANAGER:RegisterForEvent(
		name .. "_OnGlobalMouseUp",
		EVENT_GLOBAL_MOUSE_UP,
		function()
			if self.refCount ~= nil then
				local moc = wm:GetMouseOverControl()
				if (moc:GetOwningWindow() ~= submenuControl) then
					self.refCount = self.refCount - 1
					if self.refCount <= 0 then
						self:Clear()
					end
				end
			end
		end
	)
end

function Submenu:SetSelectedIndex(index)
	if (index) then
		index = zo_max(zo_min(index, #self.items), 1)
	end

	if (self.selectedIndex ~= index) then
		self:UnselectItem(self.selectedIndex)
		self:SelectItem(index)
	end
end

function Submenu:UnselectItem(index)
	local item = self.items[index]
	if item then
		self.highlight:SetHidden(true)
		local nameControl = item.nameLabel
		nameControl:SetColor(nameControl.normalColor:UnpackRGBA())

		self.selectedIndex = nil
	end
end

function Submenu:SelectItem(index)
	local item = self.items[index]
	if item then
		local highlight = self.highlight

		highlight:ClearAnchors()

		highlight:SetAnchor(TOPLEFT, item, TOPLEFT, -2, -2)
		highlight:SetAnchor(BOTTOMRIGHT, item, BOTTOMRIGHT, 2, 2)

		highlight:SetHidden(false)

		local nameControl = item.nameLabel
		nameControl:SetColor(nameControl.highlightColor:UnpackRGBA())

		self.selectedIndex = index
	end
end

function Submenu:UpdateAnchors()
	local iconSize = self.iconSize
	local previousItem = self.control
	local items = self.items
	local width, height = 0, 0
	local padding = ZO_Menu.menuPad

	for i = 1, #items do
		local item = items[i]
		local textWidth, textHeight = item.nameLabel:GetTextDimensions()
		width = math.max(textWidth + padding * 2, width)
		height = height + textHeight
		item:ClearAnchors()
		if i == 1 then
			item:SetAnchor(TOPLEFT, previousItem, TOPLEFT, padding, padding)
			item:SetAnchor(TOPRIGHT, previousItem, TOPRIGHT, -padding, padding)
		else
			item:SetAnchor(TOPLEFT, previousItem, BOTTOMLEFT, 0, item.itemYPad)
			item:SetAnchor(TOPRIGHT, previousItem, BOTTOMRIGHT, 0, item.itemYPad)
		end

		item:SetHidden(false)
		item:SetDimensions(textWidth, textHeight)
		previousItem = item
	end

	self.control:SetDimensions(width + padding * 2, height + padding * 2)
end

function Submenu:Clear()
	self:UnselectItem(self.selectedIndex)
	self.items = {}
	self.itemPool:ReleaseAllObjects()
	self.dividerPool:ReleaseAllObjects()
	self.checkBoxPool:ReleaseAllObjects()
	self.headerPool:ReleaseAllObjects()
	self.control:SetHidden(true)
	self.refCount = nil
end

local DEFAULT_TEXT_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
local DEFAULT_TEXT_HIGHLIGHT = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_CONTEXT_HIGHLIGHT))

function Submenu:AddItem(entry, myfont, normalColor, highlightColor, itemYPad)
	local visible
	if entry.visible ~= nil then
		visible = entry.visible
	else
		visible = true
	end
	if not GetValueOrCallback(visible, ZO_Menu) then
		return
	end

	local item, key
	local itemType = entry.itemType or MENU_ADD_OPTION_LABEL
	if itemType == MENU_ADD_OPTION_LABEL then
		item, key = entry.label ~= lib.DIVIDER and self.itemPool:AcquireObject() or self.dividerPool:AcquireObject()
	elseif itemType == MENU_ADD_OPTION_CHECKBOX then
		item, key = self.itemPool:AcquireObject()
	elseif itemType == MENU_ADD_OPTION_HEADER then
		item, key = self.headerPool:AcquireObject()
	else
		error(string.format("Unknown menu entry itemType: %s", itemType))
	end

	item.OnSelect = entry.callback
	item.tooltip = entry.tooltip
	item.index = #self.items + 1
	self.items[item.index] = item

	local nameControl = item.nameLabel

	local entryFont = GetValueOrCallback(entry.myfont, ZO_Menu, item) or myfont
	local normColor = GetValueOrCallback(entry.normalColor, ZO_Menu, item) or normalColor
	local highColor = GetValueOrCallback(entry.highlightColor, ZO_Menu, item) or highlightColor
	if itemType == MENU_ADD_OPTION_HEADER then
		myfont = entryFont or lib.headerFont
		nameControl.normalColor = normColor or ZO_WHITE
	else
		myfont = entryFont or "ZoFontGame"
		nameControl.normalColor = normColor or DEFAULT_TEXT_COLOR
	end
	nameControl.highlightColor = highColor or DEFAULT_TEXT_HIGHLIGHT

	nameControl:SetFont(myfont)

	local text = GetValueOrCallback(entry.label, ZO_Menu, item)

	local checkboxItemControl = nil
	if itemType == MENU_ADD_OPTION_CHECKBOX then
		checkboxItemControl = self.checkBoxPool:AcquireObject()
		checkboxItemControl:SetParent(item)
		checkboxItemControl.menuIndex = item.index
		checkboxItemControl:ClearAnchors()
		checkboxItemControl:SetHidden(false)
		checkboxItemControl:SetAnchor(LEFT, nil, LEFT, 2, -1)
		text = string.format(" |u18:0::|u%s", text)
		ZO_CheckButton_SetCheckState(checkboxItemControl, GetValueOrCallback(entry.checked, ZO_Menu, item) or false)
	end
	item.checkbox = checkboxItemControl

	nameControl:SetText(text)
	local textWidth, textHeight = nameControl:GetTextDimensions()
	item.storedHeight = textHeight

	local enabled = not GetValueOrCallback(entry.disabled or false, ZO_Menu, item)
	nameControl:SetColor((enabled and nameControl.normalColor or ZO_DEFAULT_DISABLED_COLOR):UnpackRGBA())
	item:SetMouseEnabled(enabled)
	if checkboxItemControl then
		checkboxItemControl:SetMouseEnabled(enabled)
		checkboxItemControl:SetAlpha(enabled and 1 or 0.6)
	end
end

function Submenu:Show(parent)
	if not self.control:IsHidden() then
		self:Clear()
		return false
	end
	self:UpdateAnchors()

	local padding = ZO_Menu.menuPad
	local control = self.control
	control:ClearAnchors()
	-- If there is not enough space on the right side, use the left side. Like Windows.
	if (parent:GetRight() + control:GetWidth()) < GuiRoot:GetRight() then
		control:SetAnchor(TOPLEFT, parent, TOPRIGHT, -1, -padding)
	else
		control:SetAnchor(TOPRIGHT, parent, TOPLEFT, 1, -padding)
	end
	control:SetHidden(false)
	self.parent = parent
	self.refCount = 2

	return true
end

local function SubMenuItemFactory(pool)
	local control = CreateControlFromVirtual("ZO_CustomSubMenuItem", ZO_Menu, "ZO_NotificationsRowButton", pool:GetNextControlId())

	local arrowContainer = control:CreateControl("$(parent)Arrow", CT_CONTROL)
	-- we need this in order to control the menu with independently of the texture size
	arrowContainer:SetAnchor(RIGHT, control, RIGHT, 0, 0)
	arrowContainer:SetDimensions(32, 16)

	local arrow = arrowContainer:CreateControl("$(parent)Texture", CT_TEXTURE)
	arrow:SetAnchor(RIGHT, arrowContainer, RIGHT, 0, 0)
	arrow:SetDimensions(16, 20)
	arrow:SetTexture("EsoUI/Art/Miscellaneous/colorPicker_slider_vertical.dds")
	arrow:SetTextureCoords(0, 0.5, 0, 1)

	-- we assign the submenu arrow to checkbox because the context menu will add the desired width automatically that way
	control.checkbox = arrowContainer

	local clicked = false
	local function MouseEnter(control)
		ZO_Menu_EnterItem(control)
		clicked = false
		SetTimeout(
			function()
				if control.OnSelect then
					control:OnSelect(SUBMENU_ITEM_MOUSE_ENTER)
				end
			end
		)
	end
	local function MouseExit(control)
		ZO_Menu_ExitItem(control)
		if not clicked then
			SetTimeout(
				function()
					if control.OnSelect then
						control:OnSelect(SUBMENU_ITEM_MOUSE_EXIT)
					end
				end
			)
		end
	end
	local function MouseDown(control)
		IgnoreMouseDownEditFocusLoss()
		-- re-open sub menu on click
		clicked = true
		control:OnSelect(SUBMENU_ITEM_MOUSE_ENTER)
	end
	local function MouseUp(control, button, upInside)
		if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
			control:OnSelect(SUBMENU_ITEM_MOUSE_CLICKED)
		end
	end

	local label = wm:CreateControl("$(parent)Name", control, CT_LABEL)
	label:SetAnchor(TOPLEFT)
	control.nameLabel = label

	control:SetHandler("OnMouseEnter", MouseEnter)
	control:SetHandler("OnMouseExit", MouseExit)
	control:SetHandler("OnMouseDown", MouseDown)
	control:SetHandler("OnMouseUp", MouseUp)

	return control
end

----- Standard Menu -----

local function ResetMenuItem(button)
	button:SetHidden(true)
	button:ClearAnchors()
	button.menuIndex = nil
	button.OnSelect = nil
	button.tooltip = nil
end

local function ResetCheckBox(checkBox)
	ResetMenuItem(checkBox)
	ZO_CheckButton_SetToggleFunction(checkBox, nil)
	ZO_CheckButton_SetUnchecked(checkBox)
end

local MenuItemFactory
do
	local upInside = nil
	local function MouseEnter(control)
		upInside = control
		ZO_Menu_EnterItem(control)
	end
	local function MouseExit(control)
		upInside = nil
		ZO_Menu_ExitItem(control)
	end
	local function MouseUp()
		if upInside then
			ZO_Menu_ClickItem(upInside, 1)
		end
	end

	function MenuItemFactory(pool)
		local control = CreateControlFromVirtual("ZO_CustomMenuItem", ZO_Menu, "ZO_MenuItem", pool:GetNextControlId())

		local label = control:GetNamedChild("Name")
		control.nameLabel = label

		control:SetHandler("OnMouseEnter", MouseEnter)
		control:SetHandler("OnMouseExit", MouseExit)
		control:SetHandler("OnMouseDown", IgnoreMouseDownEditFocusLoss)
		control:SetHandler("OnMouseUp", MouseUp)

		return control
	end
end

local function CheckBoxFactory(pool)
	return CreateControlFromVirtual("ZO_CustomMenuItemCheckButton", ZO_Menu, "ZO_MenuItemCheckButton", pool:GetNextControlId())
end

local function DividerFactory(pool)
	local control = CreateControlFromVirtual("ZO_CustomMenuDivider", ZO_Menu, "ZO_NotificationsRowButton", pool:GetNextControlId())
	SetupDivider(pool, control)
	return control
end

local function HeaderFactory(pool)
	local control = CreateControlFromVirtual("ZO_CustomMenuHeader", ZO_Menu, "ZO_AddOnSectionHeaderRow", pool:GetNextControlId())
	SetupHeader(pool, control)
	return control
end

---- Hook points for context menu -----
lib.enabledSpecialKeys = lib.enabledSpecialKeys or {}

local function HookContextMenu()
	local category, registry, inventorySlot, slotActions, entered
	local function Reset()
		category, registry, inventorySlot, slotActions = 0, nil, nil, nil
	end
	local function RemoveMouseOverKeybinds()
		if entered then
			entered = false
			lib.keybindRegistry:FireCallbacks("Exit")
		end
		Reset()
	end
	local function addCategory()
		category = category + 1
		registry:FireCallbacks(category, inventorySlot, slotActions)
	end
	local function AddSlots(...)
		Reset()
		inventorySlot, slotActions = ...
		if slotActions.m_contextMenuMode then
			local ctrl, alt, shift, command = lib.enabledSpecialKeys[KEY_CTRL] and IsControlKeyDown(), lib.enabledSpecialKeys[KEY_ALT] and IsAltKeyDown(), lib.enabledSpecialKeys[KEY_SHIFT] and IsShiftKeyDown(), lib.enabledSpecialKeys[KEY_COMMAND] and IsCommandKeyDown()
			if ctrl or alt or shift or command then
				registry = nil
				lib.contextMenuRegistry:FireCallbacks("Special", inventorySlot, slotActions, ctrl, alt, shift, command)
				slotActions:Show()
				Reset()
				return true
			else
				registry = lib.contextMenuRegistry
			end
		else
			entered = true
			registry = lib.keybindRegistry
		end
	end
	local function InsertToMenu()
		if registry and category < 4 and inventorySlot then
			addCategory()
		end
	end
	local function AppendToMenu()
		if registry then
			if inventorySlot then
				while category <= 6 do
					addCategory()
				end
			end
			Reset()
		end
	end
	Reset()

	local PreHook = ZO_PreHook
	PreHook("ZO_InventorySlot_RemoveMouseOverKeybinds", RemoveMouseOverKeybinds)
	PreHook("ZO_InventorySlot_OnMouseExit", RemoveMouseOverKeybinds)
	PreHook("ZO_InventorySlot_DiscoverSlotActionsFromActionList", AddSlots)
	PreHook(ZO_InventorySlotActions, "AddSlotAction", InsertToMenu)
	PreHook(ZO_InventorySlotActions, "Show", AppendToMenu)
	PreHook(ZO_InventorySlotActions, "GetPrimaryActionName", AppendToMenu)
end

----- Public API -----

function AddCustomMenuItem(mytext, myfunction, itemType, myFont, normalColor, highlightColor, itemYPad, horizontalAlignment)
	local orgItemPool = ZO_Menu.itemPool
	local orgCheckboxItemPool = ZO_Menu.checkBoxPool

	local isDivider = itemType ~= MENU_ADD_OPTION_HEADER and mytext == lib.DIVIDER
	ZO_Menu.itemPool = isDivider and lib.dividerPool or lib.itemPool
	ZO_Menu.checkBoxPool = lib.checkBoxPool

	if itemType == MENU_ADD_OPTION_CHECKBOX then
		mytext = string.format(" |u16:0::|u%s", mytext)
		itemYPad = (itemYPad or 0) + 2
	elseif itemType == MENU_ADD_OPTION_HEADER then
		myFont = myFont or lib.headerFont
		normalColor = normalColor or ZO_WHITE
		ZO_Menu.itemPool = lib.headerPool
		itemType = MENU_ADD_OPTION_LABEL
	end

	local index = AddMenuItem(mytext, myfunction or function() end, itemType, myFont, normalColor, highlightColor, itemYPad, horizontalAlignment)

	local lastAdded = ZO_Menu.items[index]
	if itemType == MENU_ADD_OPTION_CHECKBOX then
		lastAdded.item:SetAnchor(TOPLEFT, lastAdded.checkbox, TOPLEFT, 0, -2)
	end
	lastAdded.isDivider = isDivider

	ZO_Menu.itemPool = orgItemPool
	ZO_Menu.checkBoxPool = orgCheckboxItemPool

	return index
end

function AddCustomMenuTooltip(tooltip, index)
	index = index or #ZO_Menu.items
	assert(index > 0 and index <= #ZO_Menu.items, "no menu item")
	ZO_Menu.items[index].item.tooltip = tooltip
end

function AddCustomSubMenuItem(mytext, entries, myfont, normalColor, highlightColor, itemYPad, callback)
	local function CreateSubMenu(control, state)
		if state == SUBMENU_ITEM_MOUSE_ENTER then
			lib.submenu:Clear()
			local currentEntries = GetValueOrCallback(entries, ZO_Menu, control)
			for i = 1, #currentEntries do
				lib.submenu:AddItem(currentEntries[i], myfont, normalColor, highlightColor, itemYPad)
			end
			lib.submenu:Show(control)
		elseif state == SUBMENU_ITEM_MOUSE_EXIT then
			lib.submenu:Clear()
		elseif state == SUBMENU_ITEM_MOUSE_CLICKED then
			if callback and type(callback) == "function" then
				lib.submenu:Clear()
				ClearMenu()
				callback(control)
			end
		end
	end

	local orgItemPool = ZO_Menu.itemPool
	local orgCheckboxItemPool = ZO_Menu.checkBoxPool

	ZO_Menu.itemPool = lib.submenuPool
	ZO_Menu.checkBoxPool = lib.checkBoxPool

	mytext = string.format("%s |u16:0::|u", mytext)
	local index = AddMenuItem(mytext, CreateSubMenu, MENU_ADD_OPTION_LABEL, myfont, normalColor, highlightColor, itemYPad)

	ZO_Menu.itemPool = orgItemPool
	ZO_Menu.checkBoxPool = orgCheckboxItemPool

	return index
end

local function HookClearMenu()
	local orgClearMenu = ClearMenu
	function ClearMenu()
		ClearTimeout()
		orgClearMenu()
		lib.itemPool:ReleaseAllObjects()
		lib.submenuPool:ReleaseAllObjects()
		lib.checkBoxPool:ReleaseAllObjects()
		lib.dividerPool:ReleaseAllObjects()
		lib.headerPool:ReleaseAllObjects()
		lib.submenu:Clear()
	end
end

local function HookShowMenu()
	local orgShowMenu = ShowMenu
	function ShowMenu(...)
		ZO_Menu.height = ZO_Menu.height - cleanupDivider(ZO_Menu.items)
		return orgShowMenu(...)
	end
end

local function HookMenuEnter()
	local orgZO_Menu_EnterItem = ZO_Menu_EnterItem
	function ZO_Menu_EnterItem(...)
		local control = ...
		runTooltip(control, true)
		return orgZO_Menu_EnterItem(...)
	end
	local orgZO_Menu_ExitItem = ZO_Menu_ExitItem
	function ZO_Menu_ExitItem(...)
		local control = ...
		runTooltip(control, false)
		return orgZO_Menu_ExitItem(...)
	end
end

local function HookAddSlotAction()
	function ZO_InventorySlotActions:AddCustomSlotAction(...)
		local orgItemPool = ZO_Menu.itemPool
		local orgCheckboxItemPool = ZO_Menu.checkBoxPool

		ZO_Menu.itemPool = lib.itemPool
		ZO_Menu.checkBoxPool = lib.checkBoxPool

		self:AddSlotAction(...)

		ZO_Menu.itemPool = orgItemPool
		ZO_Menu.checkBoxPool = orgCheckboxItemPool
	end
end

function lib:RegisterContextMenu(func, category, ...)
	category = zo_clamp(category or self.CATEGORY_LATE, self.CATEGORY_EARLY, self.CATEGORY_LATE)
	self.contextMenuRegistry:RegisterCallback(category, func, ...)
end

function lib:RegisterSpecialKeyContextMenu(func, ...)
	self.contextMenuRegistry:RegisterCallback("Special", func, ...)
end

function lib:RegisterPlayerContextMenu(func, category, ...)
	category = zo_clamp(category or self.CATEGORY_LATE, self.CATEGORY_EARLY, self.CATEGORY_LATE)
	self.playerContextMenuRegistry:RegisterCallback(category, func, ...)
end

function lib:RegisterGuildRosterContextMenu(func, category, ...)
	category = zo_clamp(category or self.CATEGORY_LATE, self.CATEGORY_EARLY, self.CATEGORY_LATE)
	self.guildRosterContextMenuRegistry:RegisterCallback(category, func, ...)
end

function lib:RegisterFriendsListContextMenu(func, category, ...)
	category = zo_clamp(category or self.CATEGORY_LATE, self.CATEGORY_EARLY, self.CATEGORY_LATE)
	self.friendsListContextMenuRegistry:RegisterCallback(category, func, ...)
end

function lib:RegisterGroupListContextMenu(func, category, ...)
	category = zo_clamp(category or self.CATEGORY_LATE, self.CATEGORY_EARLY, self.CATEGORY_LATE)
	self.groupListContextMenuRegistry:RegisterCallback(category, func, ...)
end

function lib:RegisterKeyStripEnter(func, category, ...)
	category = zo_clamp(category or self.CATEGORY_LATE, self.CATEGORY_EARLY, self.CATEGORY_LATE)
	self.keybindRegistry:RegisterCallback(category, func, ...)
end

function lib:RegisterKeyStripExit(func, ...)
	self.keybindRegistry:RegisterCallback("Exit", func, ...)
end

function lib:EnableSpecialKeyContextMenu(key)
	assert(key == KEY_CTRL or key == KEY_ALT or key == KEY_SHIFT or key == KEY_COMMAND, "supported keys are: KEY_CTRL, KEY_ALT, KEY_SHIFT, KEY_COMMAND")
	lib.enabledSpecialKeys[key] = true
end

local function OneTimeHook(method, hook)
	local org = _G[method]
	_G[method] = function(...)
		_G[method] = org
		hook()
		return org(...)
	end
end

local function HookShowPlayerContextMenu()
	local registry, category, playerName, rawName

	local function addCategory()
		category = category + 1
		registry:FireCallbacks(category, playerName, rawName)
	end
	local function appendEntries()
		while category < lib.CATEGORY_LATE do
			addCategory()
		end
	end
	local function insertEntries()
		while category < lib.CATEGORY_SECONDARY do
			addCategory()
		end
		OneTimeHook("ZO_Menu_GetNumMenuItems", appendEntries)
	end
	local orgShowPlayerContextMenu = SharedChatSystem.ShowPlayerContextMenu
	function SharedChatSystem.ShowPlayerContextMenu(...)
		playerName, rawName = select(2, ...)
		registry, category = lib.playerContextMenuRegistry, 0
		OneTimeHook("IsGroupModificationAvailable", insertEntries)
		return orgShowPlayerContextMenu(...)
	end
end

local function HookGuildRosterContextMenu()
	local registry, category, rowData, showing

	local function addCategory()
		category = category + 1
		registry:FireCallbacks(category, rowData)
	end
	local function appendEntries()
		while category < lib.CATEGORY_LATE do
			addCategory()
		end
	end
	local function insertEntries()
		while category < lib.CATEGORY_SECONDARY do
			addCategory()
		end
	end
	local orgGuildRosterRow_OnMouseUp = GUILD_ROSTER_KEYBOARD.GuildRosterRow_OnMouseUp
	function GUILD_ROSTER_KEYBOARD.GuildRosterRow_OnMouseUp(...)
		local manager, control, button, upInside = ...

		registry, rowData, showing = nil, nil, false
		if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
			local data = ZO_ScrollList_GetData(control)
			showing = data ~= nil
			if data then
				rowData = data
				registry, category = lib.guildRosterContextMenuRegistry, 0
				OneTimeHook("GetPlayerGuildMemberIndex", insertEntries)
			end
		end
		return orgGuildRosterRow_OnMouseUp(...)
	end
	local orgShowMenu = GUILD_ROSTER_KEYBOARD.ShowMenu
	function GUILD_ROSTER_KEYBOARD.ShowMenu(...)
		if showing then
			appendEntries()
			showing = false
		end
		return orgShowMenu(...)
	end
end

local function HookFriendsListContextMenu()
	local registry, category, rowData, showing

	local function addCategory()
		category = category + 1
		registry:FireCallbacks(category, rowData)
	end
	local function appendEntries()
		while category < lib.CATEGORY_LATE do
			addCategory()
		end
	end
	local function insertEntries()
		while category < lib.CATEGORY_SECONDARY do
			addCategory()
		end
	end
	local orgFriendsListRow_OnMouseUp = FRIENDS_LIST.FriendsListRow_OnMouseUp
	function FRIENDS_LIST.FriendsListRow_OnMouseUp(...)
		local manager, control, button, upInside = ...

		registry, rowData, showing = nil, nil, false
		if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
			local data = ZO_ScrollList_GetData(control)
			showing = data ~= nil
			if data then
				if #ZO_Menu.items > 0 then
					ClearMenu()
				end
				rowData = data
				registry, category = lib.friendsListContextMenuRegistry, 0
				OneTimeHook("ZO_ScrollList_GetData", insertEntries)
			end
		end
		return orgFriendsListRow_OnMouseUp(...)
	end
	local orgShowMenu = FRIENDS_LIST.ShowMenu
	function FRIENDS_LIST.ShowMenu(...)
		if showing then
			appendEntries()
			showing = false
		end
		return orgShowMenu(...)
	end
end

local function HookGroupListContextMenu()
	local registry, category, rowData, showing

	local function addCategory()
		category = category + 1
		registry:FireCallbacks(category, rowData)
	end
	local function appendEntries()
		while category < lib.CATEGORY_LATE do
			addCategory()
		end
	end
	local function insertEntries()
		while category < lib.CATEGORY_SECONDARY do
			addCategory()
		end
	end
	local orgGroupListRow_OnMouseUp = GROUP_LIST.GroupListRow_OnMouseUp
	function GROUP_LIST.GroupListRow_OnMouseUp(...)
		local manager, control, button, upInside = ...

		registry, rowData, showing = nil, nil, false
		if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
			local data = ZO_ScrollList_GetData(control)
			showing = data ~= nil
			if data then
				if #ZO_Menu.items > 0 then
					ClearMenu()
				end
				rowData = data
				registry, category = lib.groupListContextMenuRegistry, 0
				OneTimeHook("ZO_ScrollList_GetData", insertEntries)
			end
		end
		return orgGroupListRow_OnMouseUp(...)
	end
	local orgShowMenu = GROUP_LIST.ShowMenu
	function GROUP_LIST.ShowMenu(...)
		if showing then
			appendEntries()
			showing = false
		end
		return orgShowMenu(...)
	end
end

---- Init -----

local identifier = MAJOR .. tostring(GetTimeStamp())

local function OnAddonLoaded(event, name)
	if name:find("^ZO_") then
		return
	end
	EVENT_MANAGER:UnregisterForEvent(identifier, EVENT_ADD_ON_LOADED)
	lib.itemPool = ZO_ObjectPool:New(MenuItemFactory, ResetMenuItem)
	lib.submenuPool = ZO_ObjectPool:New(SubMenuItemFactory, ResetMenuItem)
	lib.checkBoxPool = ZO_ObjectPool:New(CheckBoxFactory, ResetCheckBox)
	lib.dividerPool = ZO_ObjectPool:New(DividerFactory, ResetMenuItem)
	lib.headerPool = ZO_ObjectPool:New(HeaderFactory, ResetMenuItem)
	lib.submenu = Submenu:New("LibCustomMenuSubmenu")
	HookClearMenu()
	HookShowMenu()
	HookMenuEnter()
	HookAddSlotAction()
	HookContextMenu()
	HookShowPlayerContextMenu()
	HookFriendsListContextMenu()
	HookGroupListContextMenu()

	-- for ShissuContextMenu. Little hook war.
	EVENT_MANAGER:RegisterForEvent(
		identifier,
		EVENT_PLAYER_ACTIVATED,
		function()
			EVENT_MANAGER:UnregisterForEvent(identifier, EVENT_PLAYER_ACTIVATED)
			zo_callLater(HookGuildRosterContextMenu, 200)
		end
	)
end

lib.contextMenuRegistry = lib.contextMenuRegistry or ZO_CallbackObject:New()
lib.keybindRegistry = lib.keybindRegistry or ZO_CallbackObject:New()
lib.playerContextMenuRegistry = lib.playerContextMenuRegistry or ZO_CallbackObject:New()
lib.guildRosterContextMenuRegistry = lib.guildRosterContextMenuRegistry or ZO_CallbackObject:New()
lib.friendsListContextMenuRegistry = lib.friendsListContextMenuRegistry or ZO_CallbackObject:New()
lib.groupListContextMenuRegistry = lib.groupListContextMenuRegistry or ZO_CallbackObject:New()

lib.CATEGORY_EARLY = 1
lib.CATEGORY_PRIMARY = 2
lib.CATEGORY_SECONDARY = 3
lib.CATEGORY_TERTIARY = 4
lib.CATEGORY_QUATERNARY = 5
lib.CATEGORY_LATE = 6

EVENT_MANAGER:UnregisterForEvent(MAJOR, EVENT_ADD_ON_LOADED)
EVENT_MANAGER:RegisterForEvent(identifier, EVENT_ADD_ON_LOADED, OnAddonLoaded)

LibCustomMenu = lib
