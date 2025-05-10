local strings = {
	SI_LIB_CONSOLE_DIALOGS_MORE = "Plus",
	SI_LIB_CONSOLE_DIALOGS_TITLE = "Choisir"
}

for stringId, stringValue in pairs(strings) do
	SafeAddString(_G[stringId], stringValue, 2)
end
