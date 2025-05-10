local strings = {
	SI_LIB_CONSOLE_DIALOGS_MORE = "Más",
	SI_LIB_CONSOLE_DIALOGS_TITLE = "Elegir"
}

for stringId, stringValue in pairs(strings) do
	SafeAddString(_G[stringId], stringValue, 2)
end
