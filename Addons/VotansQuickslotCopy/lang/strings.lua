local strings = {
	["VOTANS_QUICKSLOTCOPY_SAVE_TEMPLATE"] = "Save Template",
	["VOTANS_QUICKSLOTCOPY_LOAD_TEMPLATE"] = "Load Template"
}
local ZO_CreateStringId = ZO_CreateStringId
for id, text in pairs(strings) do
	ZO_CreateStringId(id, text)
end
