local addon = {
	name = "VotansVendorSetTooltip"
}
local em = GetEventManager()

local orgSetStoreItem = ItemTooltip.SetStoreItem

-- local setVendors = {
-- 	[153513] = "|H1:item:153513:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", --Maj
-- 	[153514] = "|H1:item:153514:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", --Glirion
-- 	[153515] = "|H1:item:153515:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" --Urgarlag
-- }
local function binominal(n, k)
	return fact(n) / (fact(k) * fact(n - k))
end
function ItemTooltip.SetStoreItem(...)
	orgSetStoreItem(...)

	local tooltip, entryIndex = ...
	if GetInteractionType() == INTERACTION_VENDOR then
		local text = {}

		local items = ZO_StoreManager_GetStoreItems()

		local itemLink = GetStoreItemLink(entryIndex, LINK_STYLE_DEFAULT)
		local numContainerSets = GetItemLinkNumContainerSetIds(itemLink)
		local collected, count = 0, 0
		for setIndex = 1, numContainerSets do
			local hasSet, setName, numBonuses, numNormalEquipped, maxEquipped, itemSetId, numPerfectedEquipped = GetItemLinkContainerSetInfo(itemLink, setIndex)
			if hasSet and itemSetId then
				local collectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(itemSetId)
				if collectionData then
					local setCollected, setCount = 0, 0
					for _, piece in collectionData:PieceIterator() do
						if GetItemLinkEquipType(piece:GetItemLink()) == EQUIP_TYPE_SHOULDERS then
							if piece:IsUnlocked() then
								collected = collected + 1
								setCollected = setCollected + 1
							end
							count = count + 1
							setCount = setCount + 1
						end
					end
					text[#text + 1] = string.format("%s: |cFFFFFF%i/%i|r.", zo_strformat(SI_TOOLTIP_ITEM_NAME, setName), setCollected, setCount)
				end
			end
		end

		if count > 0 then
			text[#text + 1] = string.format("%s |cFFFFFF%.0f%%|r.", GetString(SI_VOTAN_VENDOR_STORE_SET_MISSING), (1 - collected / count) * 100)
		end

		local collected, count = 0, 0
		for _, item in pairs(items) do
			local itemLink = GetStoreItemLink(item.slotIndex, LINK_STYLE_DEFAULT)
			local numContainerSets = GetItemLinkNumContainerSetIds(itemLink)
			for setIndex = 1, numContainerSets do
				local hasSet, setName, numBonuses, numNormalEquipped, maxEquipped, itemSetId, numPerfectedEquipped = GetItemLinkContainerSetInfo(itemLink, setIndex)
				if hasSet and itemSetId then
					local collectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(itemSetId)
					if collectionData then
						for _, piece in collectionData:PieceIterator() do
							if GetItemLinkEquipType(piece:GetItemLink()) == EQUIP_TYPE_SHOULDERS then
								if piece:IsUnlocked() then
									collected = collected + 1
								end
								count = count + 1
							end
						end
					end
				end
			end
		end
		if count > 0 then
			text[#text + 1] = string.format("%s%s |cFFFFFF%i/%i|r. %s |cFFFFFF%.0f%%|r.", #text > 0 and "\n" or "", GetString(SI_VOTAN_VENDOR_STORE_SET_TOTAL), collected, count, GetString(SI_VOTAN_VENDOR_STORE_SET_MISSING), (1 - collected / count) * 100) -- You can buy 5 for the price of the other
		end
		if #text > 0 then
			tooltip:SetVerticalPadding(8)
			local r, g, b = ZO_HINT_TEXT:UnpackRGB()
			tooltip:AddLine(table.concat(text, " "), "ZoFontGameMedium", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
		end
	end
end
