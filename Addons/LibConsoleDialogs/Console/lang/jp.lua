local strings = {
	SI_LIB_CONSOLE_DIALOGS_MORE = "その他の",
	SI_LIB_CONSOLE_DIALOGS_TITLE = "選ぶ"
}

for stringId, stringValue in pairs(strings) do
	SafeAddString(_G[stringId], stringValue, 2)
end
