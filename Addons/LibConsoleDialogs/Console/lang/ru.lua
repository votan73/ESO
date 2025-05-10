local strings = {
	SI_LIB_CONSOLE_DIALOGS_MORE = "Больше",
	SI_LIB_CONSOLE_DIALOGS_TITLE = "выбирать"
}

for stringId, stringValue in pairs(strings) do
	SafeAddString(_G[stringId], stringValue, 2)
end
