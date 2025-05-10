local strings = {
	SI_LIB_CONSOLE_DIALOGS_MORE = "Mehr",
	SI_LIB_CONSOLE_DIALOGS_TITLE = "Wähle"
}

for stringId, stringValue in pairs(strings) do
	SafeAddString(_G[stringId], stringValue)
end
