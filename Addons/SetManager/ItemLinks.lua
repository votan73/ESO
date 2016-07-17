local addon = SET_MANAGER

-- Each update has its own definition of the lower bits
-- Classic: Lower bits code quality and have "reducer" bits
function addon:CreateSubItemId(level, champ, quality)
	quality = quality or 1
	quality = math.max(0, quality - 1)
	level = math.max(1, math.min(50, level))
	local subId
	if level < 50 or champ == nil then
		if level < 4 then
			subId = 30
		elseif level < 6 then
			subId = 25
		else
			subId = 20
		end
		subId = subId + quality
	else
		if champ < 110 then
			champ = math.max(10, champ)
			-- introduce of vet silver and gold
			subId = 124 + math.floor(champ / 10) + quality * 10
		elseif champ < 130 then
			-- Craglorn
			subId = 236 + math.floor((champ - 110) / 10) * 18 + quality
		elseif champ < 150 then
			-- Upper Craglorn
			subId = 272 + math.floor((champ - 130) / 10) * 18 + quality
		else
			champ = math.min(GetChampionPointsPlayerProgressionCap(), champ)
			subId = 308 + math.floor((champ - 150) / 10) * 58 + quality
		end
	end
	return subId
end

function addon:CreateCraftedItemLink(baseItemId, level, champ, quality, style, trait)
	local subId = self:CreateSubItemId(level, champ, quality)
	local items = self.allSets[baseItemId]
	if not items then return "" end
	local itemId = items[trait * 35]
	if not itemId then itemId = baseItemId end
	local itemLink = createLink("|H1:item:%i:%i:%i:0:0:0:0:0:0:0:0:0:0:0:0:%i:1:0:0:10000:0|h|h", itemId, subId, level, style)
	return itemLink
end
