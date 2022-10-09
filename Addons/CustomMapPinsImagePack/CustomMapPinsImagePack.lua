local data = {
  name = "CustomMapPinsImagePack",
  images = {
    "alchemy.dds",
    "chest.dds",
    "clothing.dds",
    "enchanting.dds",
    "fish.dds",
    "mining.dds",
    "solvent.dds",
    "wood.dds",
  }
}

function data.AddOnLoaded(event, addonName)
  if (addonName ~= data.name) then return end
  EVENT_MANAGER:UnregisterForEvent(data.name, EVENT_ADD_ON_LOADED)
  data:Init()
end

function data:Init()
  local i
  local list = HarvensCustomMapPinsIconList
  local images = self.images
  for i=1,#images do
    list[#list+1] = zo_strjoin(nil, self.name, "/img/", images[i])
  end
end

--EVENT_MANAGER:RegisterForEvent(data.name, EVENT_ADD_ON_LOADED, data.AddOnLoaded)
data:Init()