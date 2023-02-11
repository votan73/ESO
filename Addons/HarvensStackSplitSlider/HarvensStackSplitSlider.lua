local savedVariables

local function CheckAndCallSecure(functionName, ...)
	if IsProtectedFunction(functionName) then
		CallSecureProtected(functionName, ...)
	else
		_G[functionName](...)
	end
end

local function HarvensStackSplitSlider_Initialize(eventType, addonName)
	if addonName ~= "HarvensStackSplitSlider" then
		return
	end

	local defaults = {
		lastValue = 0
	}
	savedVariables = ZO_SavedVars:NewAccountWide("HarvensStackSplitSlider_SavedVariables", 1, nil, defaults)

	local control = WINDOW_MANAGER:CreateControlFromVirtual("HarvensStackSplitSlider", ZO_StackSplit, "ZO_Slider")
	control:SetAnchor(TOPLEFT, ZO_StackSplitSource, BOTTOMLEFT, 0, 16)
	control:SetAnchor(TOPRIGHT, ZO_StackSplitDestination1, BOTTOMRIGHT, 0, 16)
	control:SetValue(savedVariables.lastValue)
	control:SetMinMax(1, savedVariables.lastValue)
	control:SetHandler(
		"OnMouseWheel",
		function(self, delta)
			local val = ZO_StackSplit.spinner.value
			val = val + delta
			if val > ZO_StackSplit.spinner.max then
				val = ZO_StackSplit.spinner.max
			end
			if val < ZO_StackSplit.spinner.min then
				val = ZO_StackSplit.spinner.min
			end

			local h = control:GetHandler("OnValueChanged")
			h(control, val)
		end
	)

	local checkbox = WINDOW_MANAGER:CreateControlFromVirtual("HarvensStackSplitCheckbox", ZO_StackSplit, "ZO_CheckButton")
	checkbox:SetAnchor(TOPLEFT, control, BOTTOMLEFT, 0, 16)
	ZO_CheckButton_SetLabelText(checkbox, "Multisplit")

	control:SetHandler(
		"OnValueChanged",
		function(control, value)
			ZO_StackSplit.spinner:SetValue(value)
		end
	)

	local setupOrg = ESO_Dialogs["SPLIT_STACK"].setup
	ESO_Dialogs["SPLIT_STACK"].setup = function(...)
		setupOrg(...)
		if savedVariables.lastValue ~= 0 then
			ZO_StackSplit.spinner:SetValue(savedVariables.lastValue)
		end
		control:SetMinMax(ZO_StackSplit.spinner.min, ZO_StackSplit.spinner.max)
		control:SetValue(ZO_StackSplit.spinner:GetValue())
		control:SetValueStep(ZO_StackSplit.spinner.step)
	end

	ZO_StackSplit.spinner:RegisterCallback(
		"OnValueChanged",
		function(spinner)
			control:SetValue(ZO_StackSplit.spinner.value)
		end
	)

	local function SaveLastValue(dialog)
		savedVariables.lastValue = dialog.spinner:GetValue()
	end

	local dialog = ESO_Dialogs["SPLIT_STACK"]
	local function addFreeSlot(freeSlots, bag)
		for i = 0, GetBagSize(bag) - 1 do
			if not GetItemInstanceId(bag, i) then
				freeSlots[#freeSlots + 1] = i
			end
		end
	end
	dialog.buttons[1].callback = function(control)
		local bag, index = ZO_Inventory_GetBagAndIndex(control.slotControl)
		local it = nil
		local emptySlotIndex
		local numStacks = 1

		SaveLastValue(control)

		if ZO_CheckButton_IsChecked(checkbox) then
			numStacks = math.floor(control.stackSize / control.spinner:GetValue())
			freeSlots = {}
			addFreeSlot(freeSlots, bag)
			if bag == BAG_BANK and IsESOPlusSubscriber() then
				addFreeSlot(freeSlots, BAG_SUBSCRIBER_BANK)
			elseif bag == BAG_SUBSCRIBER_BANK then
				addFreeSlot(freeSlots, BAG_BANK)
			end
		else
			emptySlotIndex = FindFirstEmptySlotInBag(bag)
			if not emptySlotIndex then
				if bag == BAG_BANK and IsESOPlusSubscriber() then
					emptySlotIndex = FindFirstEmptySlotInBag(BAG_SUBSCRIBER_BANK)
				elseif bag == BAG_SUBSCRIBER_BANK then
					emptySlotIndex = FindFirstEmptySlotInBag(BAG_BANK)
				end
			end
		end
		for i = 1, numStacks do
			CheckAndCallSecure("PickupInventoryItem", bag, index, control.spinner:GetValue())
			if ZO_CheckButton_IsChecked(checkbox) then
				it, emptySlotIndex = next(freeSlots, it)
			end
			if emptySlotIndex then
				CheckAndCallSecure("PlaceInInventory", bag, emptySlotIndex)
			else
				local errorStringId = (bag == BAG_BACKPACK) and SI_INVENTORY_ERROR_INVENTORY_FULL or SI_INVENTORY_ERROR_BANK_FULL
				ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, errorStringId)
				ClearCursor()
				break
			end
			ClearCursor()
		end
	end
	dialog.buttons[2].callback = SaveLastValue
	dialog.noChoiceCallback = SaveLastValue
end

EVENT_MANAGER:RegisterForEvent("HarvensStackSplitSliderInitialize", EVENT_ADD_ON_LOADED, HarvensStackSplitSlider_Initialize)
