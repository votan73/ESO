local addon = VOTANS_IMPROVED_OUTFIT

addon.UndoBuffer = { }
addon.RedoBuffer = { }
local UndoBuffer = addon.UndoBuffer
local RedoBuffer = addon.RedoBuffer

local function ClearBuffer()
	ZO_ClearNumericallyIndexedTable(UndoBuffer)
	ZO_ClearNumericallyIndexedTable(RedoBuffer)
end

local suppressUndo
function addon:SuspendUndo()
	suppressUndo = true
end
function addon:ResumeUndo()
	suppressUndo = false
end

local function SheetSlotRefreshed()
	KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.keybindButtonGroupUndo)
end

local function NoOp() end
do

	local orgPlaySound = PlaySound
	local currentTransaction, currentBuffer
	local nestedCounter = 0
	function addon:BeginTransaction(buffer)
		if nestedCounter <= 0 then
			currentTransaction, currentBuffer = { }, buffer
			if PlaySound ~= NoOp then
				orgPlaySound = PlaySound
				PlaySound = NoOp
			end
		end
		assert(currentBuffer == buffer, "ups. wrong order")
		nestedCounter = nestedCounter + 1
		return currentTransaction
	end
	function addon:EndTransaction()
		if nestedCounter <= 0 then return end
		nestedCounter = nestedCounter - 1
		if nestedCounter == 0 then
			currentBuffer[#currentBuffer + 1] = currentTransaction
			currentTransaction = nil
			SheetSlotRefreshed()
			PlaySound = orgPlaySound
			PlaySound(SOUNDS.DYEING_SWATCH_SELECTED)
		end
	end
end

local function CreateEntry(restyleSlotData)
	return { data = { restyleSlotData:GetData() } }
end

local function CreateDye(buffer, restyleSlotData)
	local transaction = addon:BeginTransaction(buffer)
	local entry = CreateEntry(restyleSlotData)
	entry.dyes = { restyleSlotData:GetPendingDyes() }
	transaction[#transaction + 1] = entry
	addon:EndTransaction()
end

local function CreateDyeClassic(buffer, restyleMode, restyleSetIndex, restyleSlotType)
	if restyleMode == RESTYLE_MODE_OUTFIT then return end

	local transaction = addon:BeginTransaction(buffer)
	local entry = { data = { restyleMode, restyleSetIndex, restyleSlotType } }
	entry.dyes = { GetPendingSlotDyes(restyleMode, ZO_RESTYLE_DEFAULT_SET_INDEX, restyleSlotType) }
	transaction[#transaction + 1] = entry
	addon:EndTransaction()
end

local function CreateCollectible(buffer, restyleSlotData, collectibleId, itemMaterialIndex)
	local transaction = addon:BeginTransaction(buffer)
	local entry = CreateEntry(restyleSlotData)
	entry.collectible = { collectibleId, itemMaterialIndex }
	transaction[#transaction + 1] = entry
	addon:EndTransaction()
end

local function HookCallbacks()
	local orgSetPendingDyes = ZO_RestyleSlotData.SetPendingDyes
	function ZO_RestyleSlotData:GetDesiredDyes()
		if self.desiredDyes then
			return unpack(self.desiredDyes)
		else
			return INVALID_DYE_ID, INVALID_DYE_ID, INVALID_DYE_ID
		end
	end
	function ZO_RestyleSlotData:SetDesiredDyes(...)
		self.desiredDyes = self.desiredDyes or { INVALID_DYE_ID, INVALID_DYE_ID, INVALID_DYE_ID }
		local desiredDyes = self.desiredDyes
		desiredDyes[1], desiredDyes[2], desiredDyes[3] = ...
	end
	function ZO_RestyleSlotData.SetPendingDyes(...)
		if not suppressUndo then
			local restyleSlotData, d1, d2, d3 = ...
			CreateDye(UndoBuffer, restyleSlotData)
			ZO_ClearNumericallyIndexedTable(RedoBuffer)
			SheetSlotRefreshed()

			local outfitManipulator = restyleSlotData:GetRestyleMode() == RESTYLE_MODE_OUTFIT and ZO_OUTFIT_MANAGER:GetOutfitManipulator(restyleSlotData:GetRestyleSetIndex())
			local outfitSlotManipulator = outfitManipulator and outfitManipulator:GetSlotManipulator(restyleSlotData:GetRestyleSlotType())
			restyleSlotData = outfitSlotManipulator and outfitSlotManipulator:GetRestyleSlotData() or restyleSlotData

			restyleSlotData:SetDesiredDyes(d1, d2, d3)
		end
		return orgSetPendingDyes(...)
	end

	local orgSetPendingCollectibleIdAndItemMaterialIndex = ZO_OutfitSlotManipulator.SetPendingCollectibleIdAndItemMaterialIndex
	function ZO_OutfitSlotManipulator.SetPendingCollectibleIdAndItemMaterialIndex(...)
		local self, collectibleId, itemMaterialIndex, suppressCallbacks = ...
		local restyleSlotData = self:GetRestyleSlotData()
		if not suppressCallbacks and not suppressUndo and(self.pendingCollectibleId ~= collectibleId or self.pendingItemMaterialIndex ~= itemMaterialIndex) then
			CreateCollectible(UndoBuffer, restyleSlotData, self:GetPendingCollectibleId(), self:GetPendingItemMaterialIndex())
			ZO_ClearNumericallyIndexedTable(RedoBuffer)
			SheetSlotRefreshed()
		end
		if restyleSlotData.desiredDyes then
			orgSetPendingCollectibleIdAndItemMaterialIndex(...)
			local d1, d2, d3 = restyleSlotData:GetPendingDyes()
			local n1, n2, n3 = restyleSlotData:GetDesiredDyes()
			if d1 ~= n1 or d2 ~= n2 or d3 ~= n3 then
				orgSetPendingDyes(restyleSlotData, n1, n2, n3)
				self:OnPendingDataChanged()
			end
		end
		return orgSetPendingCollectibleIdAndItemMaterialIndex(...)
	end

	local function RefreshBuffer()
		ClearBuffer()
		return SheetSlotRefreshed()
	end
	ZO_PreHook(ZO_OUTFIT_CONFIRM_COST_DIALOG_KEYBOARD, "Confirm", RefreshBuffer)
	ZO_PreHook(ZO_RestyleSlotsSheet, "UndoPendingChanges", RefreshBuffer)
end

local function GetSlotManipulatorFromEntry(entry)
	local restyleMode, restyleSetIndex, restyleSlotType = unpack(entry.data)
	if restyleMode ~= RESTYLE_MODE_OUTFIT then return end
	local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(restyleSetIndex)
	return outfitManipulator and outfitManipulator:GetSlotManipulator(restyleSlotType)
end

do
	local function ApplyEntry(entry)
		suppressUndo = true
		local slotManipulator = GetSlotManipulatorFromEntry(entry)
		if slotManipulator then
			local restyleSlotData = slotManipulator:GetRestyleSlotData()
			local changed = false
			if entry.dyes then
				local d1, d2, d3 = restyleSlotData:GetPendingDyes()
				local n1, n2, n3 = unpack(entry.dyes)
				if d1 ~= n1 or d2 ~= n2 or d3 ~= n3 then
					restyleSlotData:SetDesiredDyes(n1, n2, n3)
					restyleSlotData:SetPendingDyes(n1, n2, n3)
					changed = true
				end
			end
			if entry.collectible then
				local c, m = slotManipulator:GetPendingCollectibleId(), slotManipulator:GetPendingItemMaterialIndex()
				local nc, nm = unpack(entry.collectible)
				if c ~= nc or m ~= nm then
					local orgUpdatePreview = slotManipulator.UpdatePreview
					slotManipulator.UpdatePreview = NoOp
					slotManipulator:SetPendingCollectibleIdAndItemMaterialIndex(nc, nm)
					slotManipulator.UpdatePreview = orgUpdatePreview
					slotManipulator.pendingCollectibleId = 0

					changed = true
				end
			end
			if changed then
				slotManipulator:OnPendingDataChanged(true)
				slotManipulator.owner:OnSlotPendingDataChanged(slotManipulator.outfitSlotIndex)
			end
		else
			local restyleMode, restyleSetIndex, restyleSlotType = unpack(entry.data)
			SetPendingSlotDyes(restyleMode, restyleSetIndex, restyleSlotType, unpack(entry.dyes))
			ZO_DYEING_KEYBOARD:OnPendingDyesChanged()
		end
		suppressUndo = false
	end

	local function ReplayTransaction(transaction, buffer)
		for _, entry in ipairs(transaction) do
			local slotManipulator = GetSlotManipulatorFromEntry(entry)
			if slotManipulator then
				local restyleSlotData = slotManipulator:GetRestyleSlotData()
				if entry.dyes then
					CreateDye(buffer, restyleSlotData)
				end
				if entry.collectible then
					CreateCollectible(buffer, restyleSlotData, slotManipulator:GetPendingCollectibleId(), slotManipulator:GetPendingItemMaterialIndex())
				end
			else
				CreateDyeClassic(buffer, unpack(entry.data))
			end

			ApplyEntry(entry)
		end
	end

	function addon:DoUndo()
		local index = #UndoBuffer
		if index > 0 then
			local transaction = UndoBuffer[index]
			table.remove(UndoBuffer, index)

			self:BeginTransaction(RedoBuffer)
			ReplayTransaction(transaction, RedoBuffer)
			self:EndTransaction()
		end
	end

	function addon:DoRedo()
		local index = #RedoBuffer
		if index > 0 then
			local transaction = RedoBuffer[index]
			table.remove(RedoBuffer, index)
			self:BeginTransaction(UndoBuffer)
			ReplayTransaction(transaction, UndoBuffer)
			self:EndTransaction()
		end
	end
end

function addon:AddUndoButtons()
	local layerName = GetString(SI_KEYBINDINGS_LAYER_OUTFIT_STATION)

	-- self.keybindButtonGroupUndo = {
	-- 	alignment = KEYBIND_STRIP_ALIGN_LEFT,
	-- 	{
	-- 		name = GetString(SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_UNDO),
	-- 		keybind = "VOTANS_IMPROVED_OUTFIT_UNDO",
	-- 		enabled = function() return #UndoBuffer > 0 end,
	-- 		visible = function() return true end,
	-- 		order = 100,
	-- 		callback = function() self:DoUndo() end,
	-- 	},
	-- 	{
	-- 		name = GetString(SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_REDO),
	-- 		keybind = "VOTANS_IMPROVED_OUTFIT_REDO",
	-- 		enabled = function() return #RedoBuffer > 0 end,
	-- 		visible = function() return true end,
	-- 		order = 100,
	-- 		callback = function() self:DoRedo() end,
	-- 	},
	-- }

	ZO_RESTYLE_SCENE:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_SHOWN then
			PushActionLayerByName(layerName)
			-- KEYBIND_STRIP:AddKeybindButtonGroup(addon.keybindButtonGroupUndo)
			-- addon:ResumeUndo()
		elseif newState == SCENE_HIDING then
			-- KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.keybindButtonGroupUndo)
			RemoveActionLayerByName(layerName)
			ClearBuffer()
		end
	end )
	ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:RegisterCallback("ModeSelectorDropdownChanged", function()
		ClearBuffer()
		-- SheetSlotRefreshed()
	end )

	-- HookCallbacks()
end
