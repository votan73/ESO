local strings = {
	["VOTANS_QUICKSLOTCOPY_SAVE_TEMPLATE"] = "Vorlage speichern",
	["VOTANS_QUICKSLOTCOPY_LOAD_TEMPLATE"] = "Vorlage laden"
}
local SafeAddString = SafeAddString
for id, text in pairs(strings) do
	SafeAddString(_G[id], text)
end
