local strings = {
	[SI_DECONFILTER_STOLEN] = "Gestohlene Gegenstände",
	[SI_DECONFILTER_INTRICATE] = "Nur intrikate Gegenstände",
	[SI_DECONFILTER_TRASH] = "Plunder und nutzlose Eigenschaften",
	[SI_DECONFILTER_BACKSPACE] = "Nur Gegenstände im Inventar",
	[SI_DECONFILTER_EQUIPPED] = "Nur ausgerüstete Gegenstände",
	[SI_DECONFILTER_BANK] = "Nur Gegenstände in der Bank",
	[SI_DECONFILTER_CRAFTED] = "Nur selber hergestellte Gegenstände",
	[SI_DECONFILTER_SETITEMS] = "Nur Gegenstände von Sets",
	[SI_DECONFILTER_KNOWN_SETITEMS] = "Nur Gegenstände von gesammelten Sets"
}
for id, text in pairs(strings) do SafeAddString(id, text, 0) end
