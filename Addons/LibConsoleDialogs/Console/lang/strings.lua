local strings = {
	SI_LIB_CONSOLE_DIALOGS_MORE = "More",
	SI_LIB_CONSOLE_DIALOGS_TITLE = "Select"
}

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
end
