
--*****************************************************************************************--
-- This library is for use with my own (Circonians) personal use. Using it in another 
-- addon could cause conflicts. If you wish to use the shared skills panel PM me and 
-- ask me about it so we can avoid problems.
--*****************************************************************************************--
-- Notes:
--[[
You cannot mix rowTypeIds in the scrollList, they must all use the same rowTypeId.

This must be fired in ALL menu button click callbacks. This is to notify all addons using the shared skills panel
that a button was clicked & which one it was (or more accurately if some other addons btn was clicked) this way if
they have made any changes to the panel/layout they know they need to reset it to default.
	CALLBACK_MANAGER:FireCallbacks("OnSharedSkillsPanelMenuBtnClick", RowTypeId_Get(setType), ADDON_NAME)

All menu bar buttons must have the rowTypeId assigned to it AND its buttonData so GetSelectedCategory() can
determine which category/rowTypeId is currently selected.
	menuBarBtn.rowTypeId = rowTypeId (used for that list)
	menuBarBtn.m_object.m_buttonData.rowTypeId (used for that list)
--]]

--Register LAM with LibStub
local MAJOR, MINOR = "LibSharedSkillsPanel", 1.2
local libssp = {}


local function GetSelectedCategory()
	local menuBar = libssp.tlw.menuBar
	local selectedDescriptor 	= ZO_MenuBar_GetSelectedDescriptor(menuBar)
	local selectedButton 		= ZO_MenuBar_GetButtonControl(menuBar, selectedDescriptor)
	local btnData				= ZO_MenuBarButtonTemplate_GetData(selectedButton)
	
	return btnData.rowTypeId
end

-- Its up to addons to only call this function when necessary
-- They are not allowed to update the panel when it is not visible. They must regsiter a callback for the
-- skills scene "StateChange" and update it then & when that addons menuBarBtn is selected.
-- addons are not allowed to use different rowTypeId's within a category
-- The following must be true: rowTypeId == categoryId
local function UpdateScrollListCategory(scrollList, dataTable, rowTypeId)
	if not SCENE_MANAGER.scenes["skills"]:IsShowing() then return end
	local selectedCategoryId = GetSelectedCategory()
	if selectedCategoryId ~= rowTypeId then return end
	
	local dataTableCopy = ZO_DeepTableCopy(dataTable)
	local dataList 		= ZO_ScrollList_GetDataList(scrollList)
	
	-- do NOT use ZO_ScrollList_Clear, were sharing this scrollList with
	-- other addons, calling Clear would also clear the dataTypes & categories
	-- we only want to clear the current data items.
	for dataIndex=#dataList, 1, -1 do
		dataList[dataIndex] = nil
	end
	
	-- Add data items to the list
	for k, dataItem in ipairs(dataTableCopy) do
		--local entry = ZO_ScrollList_CreateDataEntry(rowTypeId, dataItem, rowTypeId)
		local entry = ZO_ScrollList_CreateDataEntry(rowTypeId, dataItem)
		table.insert(dataList, entry)
	end
	
	local function SortList(item1, item2)
		if item1.data.name < item2.data.name then return true end
		return false
	end
	table.sort(dataList, SortList)
	
	ZO_ScrollList_Commit(scrollList)
end

local function AddDataType(scrollList, rowTemplate, rowHeight, setupCallback)
	local template = rowTemplate or "ZO_SelectableLabel"
	local rowHeight = rowHeight or 30
	local nextRowTypeId = #scrollList.dataTypes +1
	
	ZO_ScrollList_AddDataType(scrollList, nextRowTypeId, rowTemplate, rowHeight, setupCallback)
	ZO_ScrollList_AddCategory(scrollList, nextRowTypeId, nil)
	
	return nextRowTypeId
end

local function SetScrollListAnchors(scrollList, topOffsetY)
	scrollList:ClearAnchors()
	scrollList:SetAnchor(TOPLEFT, scrollList.menuBar, BOTTOMLEFT, 0, topOffsetY)
	scrollList:SetAnchor(BOTTOMRIGHT, scrollList.tlw, BOTTOMRIGHT, -10, -10)
end

local function SharedSkillsPanel_CreateWindow()
	local winName = "SharedSkillsPanel"
	local dividerTexture = "EsoUI/Art/Miscellaneous/horizontalDivider.dds"
	local BTN_DOWN_SIZE		= 40
	local BTN_NORMAL_SIZE	= 32
	local BTN_PADDIGN		= 10
	
	local tlw = WINDOW_MANAGER:CreateTopLevelWindow(winName)
	tlw:SetMouseEnabled(false)
	tlw:SetMovable(false)
	tlw:SetHidden(true)
	tlw:SetClampedToScreen(true)
	tlw:ClearAnchors()
	tlw:SetAnchor(TOPLEFT, ZO_SharedThinLeftPanelBackground, TOPLEFT, 0, 0)
	tlw:SetAnchor(BOTTOMRIGHT, ZO_SharedThinLeftPanelBackground, BOTTOMRIGHT, 75, 0)
	libssp.tlw = tlw
	
	-- Create backdrop
	local backdropName = zo_strformat("<<1>><<2>>", winName, "Backdrop")
	local backdrop = CreateControlFromVirtual(backdropName, tlw, "ZO_ThinLeftPanelBG")
	backdrop:SetMouseEnabled(false)
	backdrop:SetMovable(false)
	backdrop:SetHidden(false)
	backdrop:SetClampedToScreen(true)
	backdrop:SetDrawLayer(BACKGROUND)
	backdrop:ClearAnchors()
	backdrop:SetAnchorFill()
	tlw.backdrop = backdrop
	
	-- Create header
	local labelName = zo_strformat("<<1>><<2>>", winName, "Label")
	local label = CreateControl(labelName, tlw, CT_LABEL)
	label:SetMouseEnabled(false)
	label:SetMovable(false)
	label:SetHidden(false)
	label:SetClampedToScreen(true)
	label:SetFont("ZoFontWinH3")
	label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
	label:SetVerticalAlignment(TEXT_ALIGN_CENTER) 
	label:SetHorizontalAlignment(TEXT_ALIGN_CENTER) 
	label:ClearAnchors()
	label:SetAnchor(TOPLEFT, tlw, TOPLEFT, 0, 0)
	label:SetAnchor(BOTTOMRIGHT, tlw, TOPRIGHT, -10, 30)
	tlw.label = label
	
	-- Top Divider
	local topDividerName = zo_strformat("<<1>><<2>>", winName, "TopDivider")
	local topDivider = CreateControl(topDividerName, tlw, CT_TEXTURE)
	topDivider:SetMouseEnabled(false)
	topDivider:SetMovable(false)
	topDivider:SetHidden(false)
	topDivider:SetClampedToScreen(true)
	topDivider:SetTexture(dividerTexture)
	topDivider:ClearAnchors()
	topDivider:SetAnchor(BOTTOMLEFT, label, BOTTOMLEFT, 0, 0)
	topDivider:SetAnchor(BOTTOMRIGHT, label, BOTTOMRIGHT, 0, 4)
	topDivider:SetHeight(4)
	
	
	-- Menu Bar
	local menuBarName = zo_strformat("<<1>><<2>>", winName, "MenuBar")
	local menuBar = CreateControlFromVirtual(menuBarName, tlw, "ZO_MenuBarTemplate")
	menuBar:SetMouseEnabled(true)
	menuBar:SetMovable(false)
	menuBar:SetHidden(false)
	menuBar:SetClampedToScreen(true)
	menuBar:ClearAnchors()
	menuBar:SetAnchor(TOPLEFT, label, BOTTOMLEFT, 10, 5)
	menuBar:SetAnchor(BOTTOMRIGHT, label, BOTTOMRIGHT, 0, 5+BTN_DOWN_SIZE)
	tlw.menuBar = menuBar
	
	local barData =
	{
		buttonPadding 		= BTN_PADDIGN,
		normalSize 			= BTN_NORMAL_SIZE,
		downSize 			= BTN_DOWN_SIZE,
		animationDuration 	= DEFAULT_SCENE_TRANSITION_TIME,
		buttonTemplate 		= "ZO_MenuBarButtonTemplateWithTooltip",
	}
	ZO_MenuBar_SetData(menuBar, barData)
	
	
	-- Bottom Divider
	local bottomDividerName = zo_strformat("<<1>><<2>>", winName, "BottomDivider")
	local bottomDivider 	= CreateControl(bottomDividerName, tlw, CT_TEXTURE)
	bottomDivider:SetMouseEnabled(false)
	bottomDivider:SetMovable(false)
	bottomDivider:SetHidden(false)
	bottomDivider:SetClampedToScreen(true)
	bottomDivider:SetTexture(dividerTexture)
	bottomDivider:ClearAnchors()
	bottomDivider:SetAnchor(TOPLEFT, menuBar, BOTTOMLEFT, 0, 5)
	bottomDivider:SetAnchor(BOTTOMRIGHT, menuBar, BOTTOMRIGHT, 0, 9)
	bottomDivider:SetHeight(4)
	
	
	local scrollListName 	= zo_strformat("<<1>><<2>>", winName, "ScrollList")
	local scrollList 		= WINDOW_MANAGER:CreateControlFromVirtual(scrollListName, tlw, "ZO_ScrollList")
	scrollList.menuBar		= menuBar
	scrollList.tlw			= tlw
	
	scrollList.GetSelectedCategory = GetSelectedCategory
	scrollList.SetScrollListAnchors = SetScrollListAnchors
	-- Used by setSwap to move the top of the scroll list to make room for save a save set button.
	scrollList:SetScrollListAnchors(25)
	
	tlw.scrollList = scrollList
	
	--ZO_ScrollList_EnableSelection(scrollList, "ZO_ThinListHighlight", selectCallback)
	
	scrollList.UpdateScrollListCategory = UpdateScrollListCategory
	scrollList.AddDataType		= AddDataType
	
	return tlw
end


local function SharedSkillsPanel_Initialize(self)
	local skillsScene 	= SCENE_MANAGER.scenes["skills"]
	local SHARED_SKILLS_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(self.sharedSkillsPanel)
	
	self.SHARED_SKILLS_PANEL_FRAGMENT = SHARED_SKILLS_PANEL_FRAGMENT
	skillsScene:AddFragment(SHARED_SKILLS_PANEL_FRAGMENT)
end

local function SharedSkillsPanel_New(self)
	local sharedSkillsPanel_TLW = SharedSkillsPanel_CreateWindow()
	self.sharedSkillsPanel 		= sharedSkillsPanel_TLW
	
	SharedSkillsPanel_Initialize(self)

	return sharedSkillsPanel_TLW
end


function libssp:CreateSharedSkillsPanel()
	if SHARED_SKILLS_PANEL then return SHARED_SKILLS_PANEL end
	
	SHARED_SKILLS_PANEL = SharedSkillsPanel_New(libssp)
	return SHARED_SKILLS_PANEL
end

-- Only to be used ONE time after adding buttons to the menu bar
-- to select a starting button
function libssp:SelectInitialMenuBarButton()
	if libssp.initialMenuBtnSelected then return end
	libssp.initialMenuBtnSelected = true
	
	local BTN_BUTTON_INDEX 		= 1
	local BTN_DESCRIPTOR_INDEX 	= 3
		
	local menuBarObj 	= libssp.tlw.menuBar.m_object
	local m_buttons 	= menuBarObj.m_buttons
	local btn 			= menuBarObj.m_buttons[1][BTN_BUTTON_INDEX]
	local btnDescriptor = menuBarObj.m_buttons[1][BTN_DESCRIPTOR_INDEX]
	
	menuBarObj:SelectDescriptor(btnDescriptor)

	--libssp.tlw.scrollList.selectedCategory = btn.rowTypeId
end

LibSharedSkillsPanel = libssp