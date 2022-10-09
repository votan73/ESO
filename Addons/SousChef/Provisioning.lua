local SousChef = SousChef
local u = SousChef.Utility
local m = SousChef.Media
local str = SousChef.Strings[SousChef.lang]
local wm = GetWindowManager()

-- this is our "Mark Recipe" button definition
SousChef.ProvisioningButton =
{
	{
		name = str.KEY_MARK,
		keybind = "SC_MARK_RECIPE",
		callback = function(descriptor) SousChef:MarkRecipe() end,
		visible = function(descriptor) return PROVISIONER:GetSelectedRecipeIndex() ~= nil end,
		alignment = KEYBIND_STRIP_ALIGN_RIGHT,
	}
}
local bGroup = SousChef.ProvisioningButton

-- SousChef:HookRecipeTreeFunction() adds the "Mark Recipe" button to the keybind bar, and sets the provisioning window to display checkmarks by marked recipes
function SousChef:HookRecipeTreeFunction()
	-- now the keybind button
	if not KEYBIND_STRIP:HasKeybindButtonGroup(bGroup) then
		KEYBIND_STRIP:AddKeybindButtonGroup(bGroup)
	else
		KEYBIND_STRIP:UpdateKeybindButtonGroup(bGroup)
	end
	-- PROVISIONER:DirtyRecipeList()
end

-- SousChef:getMarkedIcon(row, marked) adds the checkmark next to each marked line in the provisioning window
function SousChef:getMarkedIcon(row, marked)
	local rankIcon = SousChef.slotLines[row:GetName()]
	-- then, if the recipe is marked by someone, show who, and set the checkmark's alpha accordingly
	if marked then
		rankIcon:SetHandler("OnMouseEnter", function()
			InitializeTooltip(InformationTooltip, rankIcon, RIGHT, -15, 0)
			InformationTooltip:AddLine(str.PROVISIONING_MARKED .. marked)
		end )
		if not marked:find(GetCurrentCharacterId(), 1, true) then
			rankIcon:SetColor(1, 1, 1, 0.2)
		else
			rankIcon:SetColor(1, 1, 1, 1)
		end
	end
	return rankIcon
end

-- SousChef:AddNotifier(control, marked) shows or hides the checkmark next to each recipe according to whether it's marked by anyone
function SousChef:AddNotifier(control, marked)
	local icon = self:getMarkedIcon(control, marked)
	icon:SetHidden(not marked)
end

do
	local charId = GetCurrentCharacterId()
	local function isInShoppingList(SousChef, resultLink)
		local v = u.GetItemID(resultLink)
		if type(SousChef.settings.shoppingList[v]) == "table" and next(SousChef.settings.shoppingList[v]) then
			if SousChef.settings.showAltShopping then
				return true
			else
				if SousChef.settings.mainChar == "(current)" then
					if SousChef.settings.shoppingList[v][charId] then
						return true
					end
				else
					if SousChef.settings.shoppingList[v][SousChef.settings.mainChar] then
						return true
					end
				end
			end
		end
	end
	function SousChef:IsOnShoppingList(itemId)
		for i, resultLink in ipairs(self.common.ReverseCookbook[itemId]) do
			if isInShoppingList(self, resultLink) then return true end
		end
		return false
	end
end

function SousChef:MarkRecipe()
	local link = GetRecipeResultItemLink(PROVISIONER:GetSelectedRecipeListIndex(), PROVISIONER:GetSelectedRecipeIndex())
	local itemId = u.GetItemID(link)
	if type(SousChef.settings.shoppingList[itemId]) ~= "table" then SousChef.settings.shoppingList[itemId] = { } end

	local playerName = GetCurrentCharacterId()
	if not SousChef.settings.shoppingList[itemId][playerName] then
		SousChef.settings.shoppingList[itemId][playerName] = true
		-- we're now marked
	else
		SousChef.settings.shoppingList[itemId][playerName] = nil
		-- we're now unmarked
		-- if that was the last mark we just got rid of, then nil out the entire recipe entry
		if NonContiguousCount(SousChef.settings.shoppingList[itemId]) == 0 then
			SousChef.settings.shoppingList[itemId] = nil
		end
	end

	PROVISIONER.recipeTree:RefreshVisible()
end

local function ClearRecipeTooltip()
	ClearTooltip(InformationTooltip)
end
function SousChef:HookRecipeTree(...)
	local eventId, craftingTable = ...
	if craftingTable ~= CRAFTING_TYPE_PROVISIONING then return end
	-- add a space for the checkmark, and hook the entry function to show/hide the checkmark as needed
	if not SousChef.hookedProvisioningFunction then
		local ref = PROVISIONER.recipeTree.templateInfo.ZO_ProvisionerNavigationEntry
		if ref then
			self.hookedProvisioningFunction = ref.setupFunction
			ref.setupFunction = function(...)
				local node, row, data, open, userRequested, enabled = ...
				self.hookedProvisioningFunction(...)
				-- first, if the control for the checkmark doesn't exist, create it
				local rankIcon = row:GetNamedChild("SousChef")
				if rankIcon == nil then
					rankIcon = wm:CreateControl("$(parent)SousChef", row, CT_TEXTURE)
					SousChef.slotLines[row:GetName()] = rankIcon
					rankIcon:SetTexture(m.CANLEARN)
					rankIcon:SetDimensions(20, 20)
					rankIcon:SetAnchor(RIGHT, row, LEFT, -10)
					rankIcon:SetMouseEnabled(true)
					rankIcon:SetHandler("OnMouseExit", ClearRecipeTooltip)
				end
				local link = u.GetItemID(GetRecipeResultItemLink(data.recipeListIndex, data.recipeIndex))
				if link > 0 then
					self:AddNotifier(row, type(SousChef.settings.shoppingList[link]) == "table" and u.TableKeyConcat(SousChef.settings.shoppingList[link]))
				end
			end
		end
	end
	SousChef:HookRecipeTreeFunction()
end

function SousChef:UnhookRecipeTree()
	if KEYBIND_STRIP:HasKeybindButtonGroup(bGroup) then
		KEYBIND_STRIP:RemoveKeybindButtonGroup(bGroup)
	end
end

function SousChef:HookGetRecipeInfo()
	-- first, add the pretty colors to the recipe tree if they aren't there already
	if SousChef.OldZO_ProvisionerRow_GetTextColor == nil then
		SousChef.OldZO_ProvisionerRow_GetTextColor = ZO_ProvisionerRow_GetTextColor
		ZO_ProvisionerRow_GetTextColor = function(self)
			return SousChef.ZO_ProvisionerRow_GetTextColor(self)
		end
	end
end

local function CalculateHowManyCouldBeCreated(recipeListIndex, recipeIndex, numIngredients)
	local minCount

	local GetRecipeIngredientItemInfo, GetCurrentRecipeIngredientCount, zo_min, zo_floor = GetRecipeIngredientItemInfo, GetCurrentRecipeIngredientCount, zo_min, zo_floor
	for ingredientIndex = 1, numIngredients do
		local _, _, requiredQuantity = GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, ingredientIndex)
		local ingredientCount = GetCurrentRecipeIngredientCount(recipeListIndex, recipeIndex, ingredientIndex)

		minCount = zo_min(zo_floor(ingredientCount / requiredQuantity), minCount or math.huge)
		if minCount == 0 then
			return 0
		end
	end

	return minCount or 0
end

local function Lighten(...)
	local r, g, b = ...
	return r + 0.1, g + 0.1, b + 0.1
end

local function Lightest(...)
	local r, g, b = ...
	return r + 0.3, g + 0.3, b + 0.3
end

function SousChef:ZO_ProvisionerRow_GetTextColor()
	if not self.enabled then return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED) end

	if self.selected then
		if self.data.qualityReq > 1 then return Lightest(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, self.data.qualityReq + 1)) end
		return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)
	end

	if self.mouseover then
		if self.data.qualityReq > 1 then return Lighten(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, self.data.qualityReq + 1)) end
		return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)
	end

	if self.meetsLevelReq and self.meetsQualityReq then
		if self.data.qualityReq > 1 then return GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, self.data.qualityReq + 1) end
		return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL)
	end

	return ZO_ERROR_COLOR:UnpackRGBA()
end