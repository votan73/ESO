local libswp = LibSwap
local libssp = LibSharedSkillsPanel
--local LIBLA = LibStub:GetLibrary("LibLoadedAddons")

local ADDON_NAME = "SetSwap"
local CODE_VERSION = 1.20

local SetSwap = ZO_Object:New()

local DEBUG_MODE = true

local SET_TYPE_FULL = 1
local SET_TYPE_EQUIPMENT = 2
local SET_TYPE_SKILLS = 3

local MAX_SETS = 100

local PRESET_TEXTURES = {
	[1] = "SetSwap/textures/preset1.dds",
	[2] = "SetSwap/textures/preset2.dds",
	[3] = "SetSwap/textures/preset3.dds",
	[4] = "SetSwap/textures/preset4.dds",
	[5] = "SetSwap/textures/preset5.dds",
	[6] = "SetSwap/textures/preset6.dds",
	[7] = "SetSwap/textures/preset7.dds",
	[8] = "SetSwap/textures/preset8.dds",
	[9] = "SetSwap/textures/preset9.dds"
}

-- =====================================================--
-- ======= DEBUG =========--
-- =====================================================--
local function debugMsg(msg, tableItem)
	if not DEBUG_MODE then
		return
	end
	if not SETSWAP_DEBUG_TABLE then
		SETSWAP_DEBUG_TABLE = {}
	end

	if msg and msg ~= "" then
		d(msg)
		table.insert(SETSWAP_DEBUG_TABLE, msg)
	end

	-- Used to save object references for later examination:
	if tableItem then
		table.insert(SETSWAP_DEBUG_TABLE, tableItem)
	end
end

-- =====================================================--
-- ======= SAVED VAR/UTILITY FUNCTIONS =========--
-- =====================================================--
-- Save the setInfoTable for a set
-- SetInfoTable: The table containing all information about the saved set
local function SetInfo_Save(setInfoTable, setType, setIndex)
	SetSwap.sv.sets[setType][setIndex] = setInfoTable
end

-- *** Functions dealing with data in setInfo tables ***--
-- Set Info setData functions
-- setData: the table containing the actual skills/equipment for the set
local function SetInfo_GetSetData(setType, setIndex)
	return SetSwap.sv.sets[setType][setIndex].setData
end

local function SetInfo_GetPresetIndex(setType, setIndex)
	return SetSwap.sv.sets[setType][setIndex].presetIndex
end
local function SetInfo_UpdatePresetIndex(setType, setIndex, presetIndex)
	SetSwap.sv.sets[setType][setIndex].presetIndex = presetIndex
end

local function SetInfo_UpdateName(name, setType, setIndex)
	SetSwap.sv.sets[setType][setIndex].name = name
end

-- Used to update skills setData for a skill, equipment, or full SetInfo table
local function SetInfo_UpdateSkillSetData(setType, setIndex)
	local validSkillSave, skillSetData = libswp:SaveSkillSet()
	if not validSkillSave then
		return
	end

	SetSwap.sv.sets[setType][setIndex].setData[SET_TYPE_SKILLS] = skillSetData
end
-- Used to update equipment setData for a skill, equipment, or full SetInfo table
local function SetInfo_UpdateEquipmentSetData(setType, setIndex)
	local validEquipmentSave, equipmentSetData = libswp:SaveEquipmentSet()
	if not validEquipmentSave then
		return
	end

	SetSwap.sv.sets[setType][setIndex].setData[SET_TYPE_EQUIPMENT] = equipmentSetData
end

-- *** PresetToSet functions ***--
local function PresetToSet_Get(presetIndex)
	return SetSwap.sv.presetToSet[presetIndex]
end
local function PresetToSet_Set(presetIndex, presetToSetTable)
	SetSwap.sv.presetToSet[presetIndex] = presetToSetTable
end
local function PresetToSet_GetSetType(presetIndex)
	return SetSwap.sv.presetToSet[presetIndex].setType
end

-- *** rowTypeId functions ***--
local function RowTypeId_Get(setType)
	return SetSwap.rowTypeId[setType]
end

-- Get the set table that contains all setInfoTables for a specific setType
local function Sets_GetSetTypeTable(setType)
	return SetSwap.sv.sets[setType]
end

-- =====================================================--
-- ======= LOCAL FUNCTIONS =========--
-- =====================================================--
local function HideSharedSkillsSaveBtn(shouldHide, setType)
	if not shouldHide then
		local btnText = zo_strformat("Save <<1>> Set", SetSwap.menuLabel[setType])
		SetSwap.sharedSkillsSaveBtn:SetText(btnText)
	end

	-- local stringWidth = sharedSkillsSaveBtnTlw.button:GetTextWidth()
	-- sharedSkillsSaveBtnTlw.button:SetWidth(stringWidth)
	SetSwap.sharedSkillsSaveBtn:SetHidden(shouldHide)
end
local function OnSkillsSceneStateChange(oldState, newState)
	if newState == SCENE_HIDING then
		ClearMenu()
		HideSharedSkillsSaveBtn(true)
	end
	if newState ~= SCENE_SHOWING then
		return
	end

	local selectedRowTypeId = SetSwap.scrollList:GetSelectedCategory()

	if selectedRowTypeId == RowTypeId_Get(SET_TYPE_SKILLS) then
		HideSharedSkillsSaveBtn(false, SET_TYPE_SKILLS)
		SetSwap:UpdateScrollList(SET_TYPE_SKILLS)
	elseif selectedRowTypeId == RowTypeId_Get(SET_TYPE_EQUIPMENT) then
		HideSharedSkillsSaveBtn(false, SET_TYPE_EQUIPMENT)
		SetSwap:UpdateScrollList(SET_TYPE_EQUIPMENT)
	elseif selectedRowTypeId == RowTypeId_Get(SET_TYPE_FULL) then
		HideSharedSkillsSaveBtn(false, SET_TYPE_FULL)
		SetSwap:UpdateScrollList(SET_TYPE_FULL)
	end
end
SCENE_MANAGER.scenes["skills"]:RegisterCallback("StateChange", OnSkillsSceneStateChange)

-- =====================================================--
-- ======= MENUBAR BUTTON FUNCTIONS =========--
-- =====================================================--
-- Used for all three buttons: skills, equipment, & full sets
local function MenuButton_OnClicked(btnData)
	local setType = btnData.setType
	local labelText = zo_strformat("<<1>> Sets", SetSwap.menuLabel[setType])

	CALLBACK_MANAGER:FireCallbacks("OnSharedSkillsPanelMenuBtnClick", RowTypeId_Get(setType), ADDON_NAME)

	SetSwap.skillPanel.label:SetText(labelText)
	HideSharedSkillsSaveBtn(false, setType)
	SetSwap:UpdateScrollList(setType)
end

local function CreateMenuBarButtons(menuBar)
	local skillsRowTypeId = RowTypeId_Get(SET_TYPE_SKILLS)
	local equipmentRowTypeId = RowTypeId_Get(SET_TYPE_EQUIPMENT)
	local fullSetsRowTypeId = RowTypeId_Get(SET_TYPE_FULL)

	local skillBtnTab = {
		descriptor = "SetSwap_Skills",
		normal = "/esoui/art/mainmenu/menubar_skills_up.dds",
		pressed = "/esoui/art/mainmenu/menubar_skills_down.dds",
		disabled = "/esoui/art/mainmenu/menubar_skills_disabled.dds",
		highlight = "/esoui/art/mainmenu/menubar_skills_over.dds",
		rowTypeId = skillsRowTypeId,
		setType = SET_TYPE_SKILLS,
		callback = MenuButton_OnClicked
	}
	local equipmentBtnTab = {
		descriptor = "SetSwap_Equipment",
		normal = "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
		pressed = "/esoui/art/inventory/inventory_tabicon_armor_down.dds",
		disabled = "/esoui/art/inventory/inventory_tabicon_armor_disabled.dds",
		highlight = "/esoui/art/inventory/inventory_tabicon_armor_over.dds",
		rowTypeId = equipmentRowTypeId,
		setType = SET_TYPE_EQUIPMENT,
		callback = MenuButton_OnClicked
	}
	local fullSetBtnTab = {
		descriptor = "SetSwap_FullSets",
		normal = "/esoui/art/mainmenu/menubar_champion_up.dds",
		pressed = "/esoui/art/mainmenu/menubar_champion_down.dds",
		disabled = "/esoui/art/menubar/gamepad/gp_playermenu_icon_champion.dds",
		highlight = "/esoui/art/mainmenu/menubar_champion_over.dds",
		rowTypeId = fullSetsRowTypeId,
		setType = SET_TYPE_FULL,
		callback = MenuButton_OnClicked
	}

	local skillButton = ZO_MenuBar_AddButton(menuBar, skillBtnTab)
	local equipmentButton = ZO_MenuBar_AddButton(menuBar, equipmentBtnTab)
	local fullSetButton = ZO_MenuBar_AddButton(menuBar, fullSetBtnTab)

	skillButton.rowTypeId = skillsRowTypeId
	equipmentButton.rowTypeId = equipmentRowTypeId
	fullSetButton.rowTypeId = fullSetsRowTypeId
end

-- =====================================================--
-- ======= SCROLLLIST ROW SETUP FUNCTIONS =========--
-- =====================================================--
-- Used for all three templates: skills, equipment, & full set rows
local function OnScrollListRowSetup(rowControl, data, scrollList)
	local presetIndex = data.presetIndex

	rowControl.label:SetText(data.name)

	if presetIndex then
		rowControl.icon:SetTexture(PRESET_TEXTURES[presetIndex])
		rowControl.icon:SetHidden(false)
	else
		rowControl.icon:SetHidden(true)
	end
end

-- =====================================================--
-- ======= UPDATE SCROLLLIST FUNCTIONS =========--
-- =====================================================--
function SetSwap:UpdateScrollList(setType)
	local setTypeRowTypeId = RowTypeId_Get(setType)
	local setsTable = Sets_GetSetTypeTable(setType)

	local scrollDataTable = {}

	for _, setData in pairs(setsTable) do
		table.insert(scrollDataTable, setData)
	end

	self.scrollList:UpdateScrollListCategory(scrollDataTable, setTypeRowTypeId)
end

-- =====================================================--
-- ======= PRESET CLEAR FUNCTIONS =========--
-- =====================================================--
-- Clear the setData.presetIndex for the presetIndex, then clear the presetIndex
-- Clear is seperated from DeletePreset because there are times that we want to
-- remove multiple presets & we don't want to fire the UpdateScrollList multiple times.
local function ClearPresetIndex(presetIndex)
	if not presetIndex then
		return
	end

	local setInfo = PresetToSet_Get(presetIndex)

	if setInfo then
		SetInfo_UpdatePresetIndex(setInfo.setType, setInfo.setIndex, nil)
	end

	PresetToSet_Set(presetIndex, nil)
end

-- =====================================================--
-- ======= PRESET DELETE FUNCTIONS =========--
-- =====================================================--
local function DeletePreset(presetIndex)
	local setType = PresetToSet_GetSetType(presetIndex)

	ClearPresetIndex(presetIndex)

	SetSwap:UpdateScrollList(setType)
end

-- =====================================================--
-- ======= PRESET ADD FUNCTIONS =========--
-- =====================================================--
local function AddSetPreset(newPresetIndex, setIndex, setType)
	local oldPresetIndex = SetInfo_GetPresetIndex(setType, setIndex)

	-- If the preset already has an item assigned to it, remove .presetIndex from that item
	ClearPresetIndex(newPresetIndex)

	-- If this set already has a prestIndex assigned to it, clear that [presetIndex]
	ClearPresetIndex(oldPresetIndex)

	-- set the new data for [newPresetIndex] and .presetIndex
	local newPresetToSetTable = {
		setIndex = setIndex,
		setType = setType
	}
	-- Save the new presetToSet table & update the sv setInfoTable with the new presetIndex
	PresetToSet_Set(newPresetIndex, newPresetToSetTable)
	SetInfo_UpdatePresetIndex(setType, setIndex, newPresetIndex)

	-- Update the list
	SetSwap:UpdateScrollList(setType)
end

-- =====================================================--
-- ======= BINDINGS.XML FUNCTIONS =========--
-- =====================================================--
function SetSwap_SaveSkillSet()
	SetSwap:SaveSkillSet()

	SetSwap:UpdateScrollList(SET_TYPE_SKILLS)
end
function SetSwap_SaveEquipmentSet()
	SetSwap:SaveEquipmentSet()

	SetSwap:UpdateScrollList(SET_TYPE_EQUIPMENT)
end
function SetSwap_SaveFullSet()
	SetSwap:SaveFullSet()

	SetSwap:UpdateScrollList(SET_TYPE_FULL)
end

function SetSwap_LoadPreSet(presetIndex)
	if IsUnitInCombat("player") then
		return
	end
	local presetInfo = PresetToSet_Get(presetIndex)

	if not presetInfo then
		return
	end

	SetSwap:LoadSet(presetInfo.setType, presetInfo.setIndex)
end

-- =====================================================--
-- ======= XML FUNCTIONS =========--
-- =====================================================--
function SetSwap_SaveSet()
	local selectedRowTypeId = SetSwap.scrollList:GetSelectedCategory()

	if selectedRowTypeId == RowTypeId_Get(SET_TYPE_SKILLS) then
		SetSwap_SaveSkillSet()
	elseif selectedRowTypeId == RowTypeId_Get(SET_TYPE_EQUIPMENT) then
		SetSwap_SaveEquipmentSet()
	elseif selectedRowTypeId == RowTypeId_Get(SET_TYPE_FULL) then
		SetSwap_SaveFullSet()
	end
end

-- =====================================================--
-- ======= SAVE SET FUNCTIONS =========--
-- =====================================================--
-- Used to create a setInfoTable for any setType
-- setInfoTable: the table containing all of the information about the set
local function PackSetInfoTable(skillSetData, equipmentSetData, setType, skillIndex)
	local setInfo = {
		name = zo_strformat("<<1>> Set <<2>>", SetSwap.menuLabel[setType], skillIndex),
		setIndex = skillIndex,
		setType = setType,
		setData = {
			[SET_TYPE_EQUIPMENT] = equipmentSetData,
			[SET_TYPE_SKILLS] = skillSetData
		}
	}
	return setInfo
end

-- Can't use #setTable because users can remove them at will. The numerically indexed
-- table will most likely be missing key entries.
local function GetFirstFreeSetIndex(setType)
	local setTypeSets = Sets_GetSetTypeTable(setType)

	for setIndex = 1, MAX_SETS do
		if not setTypeSets[setIndex] then
			return setIndex
		end
	end
	return 101
end

-- Call necessary save functions to get the needed setData, then pack the info into a
-- setInfoTable & return it.
local function CreateSkillSetInfoTable(setIndex)
	local validSkillSave, skillSetData = libswp:SaveSkillSet()
	if not validSkillSave then
		return
	end

	return PackSetInfoTable(skillSetData, nil, SET_TYPE_SKILLS, setIndex)
end
local function CreateEquipmentSetInfoTable(setIndex)
	local validEquipmentSave, equipmentSetData = libswp:SaveEquipmentSet()
	if not validEquipmentSave then
		return
	end

	return PackSetInfoTable(nil, equipmentSetData, SET_TYPE_EQUIPMENT, setIndex)
end
local function CreateFullSetInfoTable(setIndex)
	local validEquipmentSave, equipmentSetData = libswp:SaveEquipmentSet()
	local validSkillSave, skillSetData = libswp:SaveSkillSet()
	if not (validEquipmentSave and validSkillSave) then
		return
	end

	return PackSetInfoTable(skillSetData, equipmentSetData, SET_TYPE_FULL, setIndex)
end

-- Used to update sets of any setType
-- rather than recreating the setInfo table from scratch, update only the setData
local function UpdateSet(setType, setIndex)
	if setType == SET_TYPE_SKILLS then
		SetInfo_UpdateSkillSetData(SET_TYPE_SKILLS, setIndex)
		SetSwap:UpdateScrollList(SET_TYPE_SKILLS)
	elseif setType == SET_TYPE_EQUIPMENT then
		SetInfo_UpdateEquipmentSetData(SET_TYPE_EQUIPMENT, setIndex)
		SetSwap:UpdateScrollList(SET_TYPE_EQUIPMENT)
	else
		-- SET_TYPE_FULL
		SetInfo_UpdateSkillSetData(SET_TYPE_FULL, setIndex)
		SetInfo_UpdateEquipmentSetData(SET_TYPE_FULL, setIndex)
		SetSwap:UpdateScrollList(SET_TYPE_FULL)
	end
end

function SetSwap:SaveSkillSet()
	local setIndex = GetFirstFreeSetIndex(SET_TYPE_SKILLS)
	local setInfoTable = CreateSkillSetInfoTable(setIndex)

	SetInfo_Save(setInfoTable, SET_TYPE_SKILLS, setIndex)
end
function SetSwap:SaveEquipmentSet()
	local setIndex = GetFirstFreeSetIndex(SET_TYPE_EQUIPMENT)
	local setInfoTable = CreateEquipmentSetInfoTable(setIndex)

	SetInfo_Save(setInfoTable, SET_TYPE_EQUIPMENT, setIndex)
end
function SetSwap:SaveFullSet()
	local setIndex = GetFirstFreeSetIndex(SET_TYPE_FULL)
	local setInfoTable = CreateFullSetInfoTable(setIndex)

	SetInfo_Save(setInfoTable, SET_TYPE_FULL, setIndex)
end

-- =====================================================--
-- ======= LOAD SET FUNCTIONS =========--
-- =====================================================--
function SetSwap:LoadSet(setType, setIndex)
	local setData = SetInfo_GetSetData(setType, setIndex)

	if setType == SET_TYPE_SKILLS then
		libswp:LoadSkillSet(setData[SET_TYPE_SKILLS])
		self:ResetRapidManeuverToggledAbilityIds()
	elseif setType == SET_TYPE_EQUIPMENT then
		libswp:LoadEquipmentSet(setData[SET_TYPE_EQUIPMENT])
	else
		-- SET_TYPE_FULL
		libswp:LoadEquipmentSet(setData[SET_TYPE_EQUIPMENT])
		libswp:LoadSkillSet(setData[SET_TYPE_SKILLS])
		self:ResetRapidManeuverToggledAbilityIds()
	end
end

-- =====================================================--
-- ======= DELETE SET FUNCTIONS =========--
-- =====================================================--
function SetSwap:DeleteSet(setIndex, setType)
	local presetIndex = SetInfo_GetPresetIndex(setType, setIndex)

	ClearPresetIndex(presetIndex)
	SetInfo_Save(nil, setType, setIndex)

	self:UpdateScrollList(setType)
end

-- =============================================================--
-- ======= EQUIPMENT CHARACTER WINDOW PREVIEW FUNCTION =========--
-- =============================================================--
function SetSwap:LoadEquipmentSetPreviewTextures(setData)
	local charPrevWin = self.characterPreviewWin
	local setIndex = setData.setIndex
	local setType = setData.setType

	if charPrevWin.setIndex == setIndex and charPrevWin.setType == setType then
		return
	end

	charPrevWin.setIndex = setIndex
	charPrevWin.setType = setType

	local title = setData.name
	local equipment = setData.setData[SET_TYPE_EQUIPMENT]
	local slotTextures = charPrevWin.slotTextures

	for slotIndex, textureControl in pairs(slotTextures) do
		local equipmentData = equipment[slotIndex]

		if equipmentData and equipmentData.texture then
			textureControl:SetTexture(equipmentData.texture)
		else
			textureControl:SetTexture(ZO_Character_GetEmptyEquipSlotTexture(slotIndex))
		end
	end

	local buttons = charPrevWin.skillBar.buttons
	local skillSet = setData.setData[SET_TYPE_SKILLS]

	for btnIndex, skillBtn in pairs(buttons) do
		if skillSet then
			skillBtn:SetHidden(false)
			local skillData = skillSet[btnIndex]

			if skillData.doesAbilityExist then
				skillBtn.icon:SetTexture(skillData.texture)
				skillBtn.icon:SetHidden(false)
			else
				skillBtn.icon:SetHidden(true)
			end
		else
			skillBtn:SetHidden(true)
		end
	end

	return true
end

-- ================================================--
-- ======= HANLDER FUNCTIONS ONMOUSEENTER =========--
-- ================================================--
local function SetSwap_FullRow_OnMouseEnter(self)
	local fullSets = Sets_GetSetTypeTable(SET_TYPE_FULL)
	local setIndex = self.dataEntry.data.setIndex
	local setData = fullSets[setIndex]

	SetSwap:LoadEquipmentSetPreviewTextures(setData)
	SetSwap.characterPreviewWin:SetHidden(false)
end
local function SetSwap_EquipmentRow_OnMouseEnter(self)
	local equipmentSets = Sets_GetSetTypeTable(SET_TYPE_EQUIPMENT)
	local setIndex = self.dataEntry.data.setIndex
	local setData = equipmentSets[setIndex]

	SetSwap:LoadEquipmentSetPreviewTextures(setData)
	SetSwap.characterPreviewWin:SetHidden(false)
end
local function SetSwap_SkillRow_OnMouseEnter(self)
	local skillPreviewBar = SetSwap.skillPreviewBar
	local buttons = skillPreviewBar.skillBar.buttons
	local skillsData = self.dataEntry.data.setData[SET_TYPE_SKILLS]

	for btnIndex, btn in pairs(buttons) do
		local skillData = skillsData[btnIndex]
		if skillData.doesAbilityExist then
			btn.icon:SetTexture(skillData.texture)
			btn.icon:SetHidden(false)
		else
			btn.icon:SetHidden(true)
		end
	end

	skillPreviewBar:ClearAnchors()
	skillPreviewBar:SetAnchor(TOPLEFT, self, TOPRIGHT, 60, 0)
	skillPreviewBar:SetHidden(false)
end

-- ===============================================--
-- ======= HANLDER FUNCTIONS ONMOUSEEXIT =========--
-- ===============================================--
local function SetSwap_EquipmentRow_OnMouseExit(self)
	SetSwap.characterPreviewWin:SetHidden(true)
end
local function SetSwap_FullRow_OnMouseExit(self)
	SetSwap.characterPreviewWin:SetHidden(true)
end
local function SetSwap_SkillRow_OnMouseExit(self)
	SetSwap.skillPreviewBar:SetHidden(true)
end

-- ============================================================--
-- ======= GLOBAL HANLDER FUNCTION ON SET NAME CHANGE =========--
-- ============================================================--
function SetSwap_OnSetNameChange(rowControl, newName)
	local data = rowControl.dataEntry.data
	local setType = data.setType
	local setIndex = data.setIndex

	if newName and newName ~= "" then
		data.name = newName
		SetInfo_UpdateName(newName, setType, setIndex)
	end

	SetSwap:UpdateScrollList(setType)
end

-- =============================================--
-- ======= HANLDER FUNCTIONS ONMOUSEUP =========--
-- =============================================--
local function OnRenameSet(self, data)
	local nameEdit = self.label
	local nameEditBackdrop = self.labelBackdrop

	nameEditBackdrop:SetHidden(false)
	nameEdit:SetMouseEnabled(true)
	nameEdit:TakeFocus()
	nameEdit:SelectAll()
end

-- Shared row OnMouseUp for skills, equipment, & full set row templates
local function SetSwap_SharedRow_OnMOuseUp(self, button, upInside)
	if not upInside then
		return
	end

	local data = self.dataEntry.data
	local presetIndex = data.presetIndex
	local setIndex = data.setIndex
	local setType = data.setType

	if button == MOUSE_BUTTON_INDEX_LEFT then
		SetSwap:LoadSet(setType, setIndex)
	elseif button == MOUSE_BUTTON_INDEX_RIGHT then
		ClearMenu()

		if presetIndex then
			local presetText = zo_strformat("<<1>> <<2>>", "Clear Preset", presetIndex)
			AddCustomMenuItem(
				presetText,
				function()
					DeletePreset(presetIndex)
				end
			)
		end

		local function CreatePresetEntries(currentPresetIndex)
			local menuEntries = {}
			for presetIndex = 1, #PRESET_TEXTURES do
				if currentPresetIndex ~= presetIndex then
					local entry = {
						label = zo_strformat("<<1>> <<2>>", "Preset", presetIndex),
						callback = function()
							AddSetPreset(presetIndex, setIndex, setType)
						end
					}
					table.insert(menuEntries, entry)
				end
			end
			return menuEntries
		end
		local menuEntries = CreatePresetEntries(presetIndex)
		AddCustomSubMenuItem("Assign Preset", menuEntries)

		AddCustomMenuItem(
			"Rename Set",
			function()
				OnRenameSet(self, data)
			end
		)

		AddCustomMenuItem(
			"Update Set",
			function()
				UpdateSet(setType, setIndex)
			end
		)
		AddCustomMenuItem(
			"Delete Set",
			function()
				SetSwap:DeleteSet(setIndex, setType)
			end
		)
		ShowMenu()
	end
end

-- =====================================================--
-- ======= TOGGLE RAPID MANEUVER FUNCTIONS =========--
-- =====================================================--
-- called when a skill set is loaded to wipe the saved/toggled abilityIds
function SetSwap:ResetRapidManeuverToggledAbilityIds()
	local activeWeaponPair = GetActiveWeaponPairInfo()
	-- When could this possibly happen ??
	if activeWeaponPair == ACTIVE_WEAPON_PAIR_NONE then
		return
	end

	-- Only reset the bar that just changed
	self.sv.rapidManeuverToggledAbilityIds[activeWeaponPair] = {}
end

function SetSwap_ToggleRapidManuever()
	if IsUnitInCombat("player") then
		return
	end
	local sv = SetSwap.sv
	if sv.rapidManeuverSlot == "Off" then
		return
	end

	local activeWeaponPair = GetActiveWeaponPairInfo()
	-- When could this possibly happen ??
	if activeWeaponPair == ACTIVE_WEAPON_PAIR_NONE then
		return
	end

	local skillType, skillLineIndex, skillLineAbilityIndex = GetSpecificSkillAbilityKeysByAbilityId(40211)

	local _, _, _, _, _, purchased, progressionIndex =
		GetSkillAbilityInfo(skillType, skillLineIndex, skillLineAbilityIndex)
	-- If they dont have the skill abort.
	if not purchased then
		return
	end

	-- slot nums are displayed on the hud as 1-5, but they are really 3-7
	local USER_DISPLAYED_SLOTNUM_OFFSET = 2
	local SLOT_NUM = sv.rapidManeuverSlot + USER_DISPLAYED_SLOTNUM_OFFSET

	local slotNum = GetAssignedSlotFromSkillAbility(skillType, skillLineIndex, skillLineAbilityIndex)
	-- if the skill is already on the bar in a different slot then abort.
	if slotNum and slotNum ~= SLOT_NUM then
		return
	end

	local RAPID_MANEUVER_ABILITYID = GetSkillAbilityId(skillType, skillLineIndex, skillLineAbilityIndex, false)
	local slotAbilityId = GetSlotBoundId(SLOT_NUM)

	local function GetAbilityIndex(abilityId)
		local hasProgression, progressionIndex = GetAbilityProgressionXPInfoFromAbilityId(abilityId)
		local unMorphedName, morphChoice, rank = GetAbilityProgressionInfo(progressionIndex)
		local morphedName, texture, abilityIndex = GetAbilityProgressionAbilityInfo(progressionIndex, morphChoice, rank)

		return abilityIndex
	end

	-- If its not already the correct ability, select it
	if slotAbilityId == RAPID_MANEUVER_ABILITYID then
		local TOGGLED_ABILITYID = sv.rapidManeuverToggledAbilityIds[activeWeaponPair][SLOT_NUM]

		if TOGGLED_ABILITYID then
			local toggledAbilityIndex = GetAbilityIndex(TOGGLED_ABILITYID)

			CallSecureProtected("SelectSlotAbility", toggledAbilityIndex, SLOT_NUM)
			sv.rapidManeuverToggledAbilityIds[activeWeaponPair][SLOT_NUM] = nil
		end
	else
		-- Only save it if there was an ability
		if DoesAbilityExist(slotAbilityId) then
			sv.rapidManeuverToggledAbilityIds[activeWeaponPair][SLOT_NUM] = slotAbilityId
		end

		local RAPID_MANEUVER_ABILITY_INDEX = GetAbilityIndex(RAPID_MANEUVER_ABILITYID)
		CallSecureProtected("SelectSlotAbility", RAPID_MANEUVER_ABILITY_INDEX, SLOT_NUM)
	end
end

-- =====================================================--
-- ======= XML INITIALIZE FUNCTIONS =========--
-- =====================================================--
function SetSwap_EquipmentSet_RowTemplate_Initialize(self)
	-- do not try to change this & use SetHandler !!
	self.OnMouseUp = SetSwap_SharedRow_OnMOuseUp
	self.OnMouseEnter = SetSwap_EquipmentRow_OnMouseEnter
	self.OnMouseExit = SetSwap_EquipmentRow_OnMouseExit
end
function SetSwap_SkillSet_RowTemplate_Initialize(self)
	-- do not try to change this & use SetHandler !!
	self.OnMouseUp = SetSwap_SharedRow_OnMOuseUp
	self.OnMouseEnter = SetSwap_SkillRow_OnMouseEnter
	self.OnMouseExit = SetSwap_SkillRow_OnMouseExit
end
function SetSwap_FullSet_RowTemplate_Initialize(self)
	-- do not try to change this & use SetHandler !!
	self.OnMouseUp = SetSwap_SharedRow_OnMOuseUp
	self.OnMouseEnter = SetSwap_FullRow_OnMouseEnter
	self.OnMouseExit = SetSwap_FullRow_OnMouseExit
end

function SetSwap_InitializeCharacterPreview(self)
	local slotTextures = {}

	slotTextures[EQUIP_SLOT_HEAD] = self:GetNamedChild("EquipmentSlotsHead")
	slotTextures[EQUIP_SLOT_SHOULDERS] = self:GetNamedChild("EquipmentSlotsShoulder")
	slotTextures[EQUIP_SLOT_HAND] = self:GetNamedChild("EquipmentSlotsGlove")
	slotTextures[EQUIP_SLOT_LEGS] = self:GetNamedChild("EquipmentSlotsLeg")
	slotTextures[EQUIP_SLOT_CHEST] = self:GetNamedChild("EquipmentSlotsChest")
	slotTextures[EQUIP_SLOT_WAIST] = self:GetNamedChild("EquipmentSlotsBelt")
	slotTextures[EQUIP_SLOT_FEET] = self:GetNamedChild("EquipmentSlotsFoot")
	slotTextures[EQUIP_SLOT_COSTUME] = self:GetNamedChild("EquipmentSlotsCostume")
	slotTextures[EQUIP_SLOT_NECK] = self:GetNamedChild("EquipmentSlotsNeck")
	slotTextures[EQUIP_SLOT_RING1] = self:GetNamedChild("EquipmentSlotsRing1")
	slotTextures[EQUIP_SLOT_RING2] = self:GetNamedChild("EquipmentSlotsRing2")
	slotTextures[EQUIP_SLOT_MAIN_HAND] = self:GetNamedChild("EquipmentSlotsMainHand")
	slotTextures[EQUIP_SLOT_OFF_HAND] = self:GetNamedChild("EquipmentSlotsOffHand")
	slotTextures[EQUIP_SLOT_BACKUP_MAIN] = self:GetNamedChild("EquipmentSlotsBackupMain")
	slotTextures[EQUIP_SLOT_BACKUP_OFF] = self:GetNamedChild("EquipmentSlotsBackupOff")

	self.slotTextures = slotTextures
end

-- =====================================================--
-- ======= INITIALIZE FUNCTIONS =========--
-- =====================================================--
local function CreateStringIds()
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_SAVE_FULL_SET", "Save Full Set")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_SAVE_EQUIPMENT_SET", "Save Equipment Set")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_SAVE_SKILL_SET", "Save Skill Set")

	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_LOAD_PRESET1", "Load Preset 1")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_LOAD_PRESET2", "Load Preset 2")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_LOAD_PRESET3", "Load Preset 3")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_LOAD_PRESET4", "Load Preset 4")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_LOAD_PRESET5", "Load Preset 5")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_LOAD_PRESET6", "Load Preset 6")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_LOAD_PRESET7", "Load Preset 7")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_LOAD_PRESET8", "Load Preset 8")
	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_LOAD_PRESET9", "Load Preset 9")

	ZO_CreateStringId("SI_BINDING_NAME_SETSWAP_TOGGLE_RAPID_MANUEVER", "Toggle Rapid Manuever")
end

function SetSwap:ClearAllSets()
	d("SetSwap: Reloading the ui in 5 seconds to clear sets.")
	zo_callLater(
		function()
			self.sv.sets = {
				[SET_TYPE_EQUIPMENT] = {},
				[SET_TYPE_SKILLS] = {},
				[SET_TYPE_FULL] = {}
			}
			self.sv.presetToSet = {}
			ReloadUI("ingame")
		end,
		5000
	)
end

function SetSwap:Initialize()
	-- Registers addon to loadedAddon library
	--LIBLA:RegisterAddon(ADDON_NAME, CODE_VERSION)

	local characerPreviewWin = SetSwap_Character_Preview_Window
	local sharedSkillsSaveBtn = SetSwap_SharedSkills_SaveSetBtn

	local defaultSV = {
		rapidManeuverSlot = "Off",
		rapidManeuverToggledAbilityIds = {
			[ACTIVE_WEAPON_PAIR_MAIN] = {},
			[ACTIVE_WEAPON_PAIR_BACKUP] = {}
		},
		sets = {
			[SET_TYPE_EQUIPMENT] = {},
			[SET_TYPE_SKILLS] = {},
			[SET_TYPE_FULL] = {}
		},
		presetToSet = {}
	}
	self.sv = ZO_SavedVars:New("SetSwapSavedVars", 1.2, nil, defaultSV)

	self.codeVersion = CODE_VERSION
	self.characterPreviewWin = characerPreviewWin
	self.characterPreviewWin.title = SetSwap_Character_Preview_WindowTitle
	self.skillPreviewBar = SetSwap_Skill_Preview_Bar
	self.sharedSkillsSaveBtn = sharedSkillsSaveBtn

	self.menuLabel = {
		[SET_TYPE_EQUIPMENT] = "Equipment",
		[SET_TYPE_SKILLS] = "Skill",
		[SET_TYPE_FULL] = "Full"
	}

	CreateStringIds()
end

-------------------------------------------------------------------
--  OnPlayerActivated  --
-------------------------------------------------------------------
function SetSwap:InitializeSharedSkillsPanel()
	local skillPanel = libssp:CreateSharedSkillsPanel()
	local scrollList = skillPanel.scrollList
	local menuBar = skillPanel.menuBar
	local rowHeight = 40

	-- Using different templates because they have different mouseEnter handlers
	local skillRowTypeId = scrollList:AddDataType("SetSwap_SkillSet_Preview_RowTemplate", rowHeight, OnScrollListRowSetup)
	local equipmentRowTypeId =
		scrollList:AddDataType("SetSwap_EquipmentSet_Preview_RowTemplate", rowHeight, OnScrollListRowSetup)
	local fullSetRowTypeId = scrollList:AddDataType("SetSwap_FullSet_Preview_RowTemplate", rowHeight, OnScrollListRowSetup)

	--[[ This kills two birds with one stone. I can track which rowTypeId to use when adding items to the scrollList and I can tell which items are displayed by the rowTypeId used.
	--]]
	self.rowTypeId = {
		[SET_TYPE_EQUIPMENT] = equipmentRowTypeId,
		[SET_TYPE_SKILLS] = skillRowTypeId,
		[SET_TYPE_FULL] = fullSetRowTypeId
	}

	self.skillPanel = skillPanel
	self.scrollList = scrollList
	self.menuBar = menuBar

	self.characterPreviewWin:ClearAnchors()
	self.characterPreviewWin:SetAnchor(TOPLEFT, skillPanel.backdrop, TOPRIGHT, 20, 0)

	self.sharedSkillsSaveBtn:ClearAnchors()
	-- self.sharedSkillsSaveBtnTlw:SetAnchor(BOTTOM, scrollList, TOP, 0, 0)
	self.sharedSkillsSaveBtn:SetAnchor(TOPLEFT, menuBar, BOTTOMLEFT, 0, 5)
	self.sharedSkillsSaveBtn:SetAnchor(BOTTOMRIGHT, scrollList, TOPRIGHT, 0, -5)
	self.sharedSkillsSaveBtn:SetParent(skillPanel)

	CreateMenuBarButtons(menuBar)

	CALLBACK_MANAGER:RegisterCallback(
		"OnSharedSkillsPanelMenuBtnClick",
		function(rowTypeId, addonName)
			if addonName == ADDON_NAME then
				SetSwap.scrollList:SetScrollListAnchors(40)
				return
			end
			SetSwap.scrollList:SetScrollListAnchors(20)

			HideSharedSkillsSaveBtn(true, nil)
		end
	)

	libssp:SelectInitialMenuBarButton()
end

local function OnPlayerActivated()
	if not SetSwap.skillPanel then
		SetSwap:InitializeSharedSkillsPanel()
	end
end
-------------------------------------------------------------------
--  OnAddOnLoaded  --
-------------------------------------------------------------------
local function OnAddOnLoaded(event, addonName)
	if addonName ~= ADDON_NAME then
		return
	end

	SetSwap:Initialize()
	SetSwap_CreateSettingsMenu(SetSwap)

	if DEBUG_MODE then
		SETSWAP = SetSwap
	end

	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

	-- Unregister
	EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
end

---------------------------------------------------------------------
--  Register Events --
---------------------------------------------------------------------
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

---------------------------------------------------------------------
--  Slash Commands  --
---------------------------------------------------------------------
SLASH_COMMANDS["/clearsetswap"] = function()
	SetSwap:ClearAllSets()
end
