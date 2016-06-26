local addon = SET_MANAGER
local em = GetEventManager()

local S_REQUIRED = 1
local S_DESCRIPTION = 2

function addon:ClearItems()
  if (addon.sets ~= nil) then
    for set,information in pairs(addon.sets) do
      information.items = {}
    end
  end
end

function addon:ClearBoni()
  addon.sets = {}
end

function addon:dumpSetInfo(name, info)
  d(name .. " with " .. #info.items .. " items" .. (info.crafted and "(crafted)" or ""))
  for i=1,#info.boni do
    d(info.boni[i][S_REQUIRED] .. ":" .. info.boni[i][S_DESCRIPTION])
  end
end

function addon:getSortedKeys(dictionary, order)
  local keys = {}
  for k in pairs(dictionary) do
    keys[#keys+1] = k
  end
  table.sort(keys, function (a,b) return order(dictionary, a,b) end )
  
  return keys
end

function SortBoni(dict, a, b)
  local left = dict[a]
  local right = dict[b]
  return left[S_REQUIRED] < right[S_REQUIRED] and 1 or (left[S_DESCRIPTION] < right[S_DESCRIPTION]) 
end

function addon:dumpBoni()
  local keys = addon:getSortedKeys(addon.boni, SortBoni)
  for i=1,#keys do
    local boni = addon.boni[keys[i]]
    d(boni[S_REQUIRED] .. ":" .. boni[S_DESCRIPTION])
  end
end

function addon:registerSetInfo(link, setName, numberOfBonuses, numEquipped, maxWearable)
  if (addon.sets == nil) then addon.sets = {} end
  if (addon.sets[setName] == nil) then addon.sets[setName] = {} end
  local set = addon.sets[setName]
  set.numberOfBonuses = numberOfBonuses
  set.boni = {} -- remove if necessary
  if (addon.boni == nil) then addon.boni = {} end
  for i=1,numberOfBonuses do
    local numrequired, description = GetItemLinkSetBonusInfo(link, false, i)
    table.insert(set.boni, { numrequired, description })
    table.insert(addon.boni, { numrequired, description })
  end
  set.numEquipped = numEquipped
  set.maxWearable = maxWearable
  set.crafted = IsItemLinkCrafted(link)
  --d("Register set " .. setName .. " for item " .. GetItemLinkName(link))
  if set.items == nil then set.items = {} end
  table.insert(set.items, link)
end

function addon:DoCompleteProcess()
  addon.ClearItems()
  addon.ClearBoni()
  addon:ProcessList(addon.account.sets)
  addon:ProcessList(addon.player.sets)
  addon:ProcessList(addon.player.crafting)
end

function addon:ProcessList(list)
  if (list ~= nil) then
    for i=1,#list do
      --boolean hasSet, string setName, integer numberOfBonuses, integer numEquipped, integer maxWearable
      local hasSet, setName, numberOfBonuses, numEquipped, maxWearable = GetItemLinkSetInfo(list[i])
      if (hasSet) then
        addon:registerSetInfo(list[i], setName, numberOfBonuses, numEquipped, maxWearable)
      else
        --d(GetItemLinkName(list[i]) .. " is no set")
      end
    end
  end
end