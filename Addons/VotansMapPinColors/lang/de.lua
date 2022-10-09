local strings = {
	["SI_VOTANS_MAPPIN_COLORS_PREFER_ASSISTED"] = "Bevorzugte die Farbe für aktive Quests",
	["SI_VOTANS_MAPPIN_COLORS_PREFER_ASSISTED_TOOLTIP"] = "Wechselt bei aktivierten wiederholbaren Quests zur Farbe für aktive Quests.",
	["SI_VOTANS_MAPPIN_COLORS_SHOW_PLAYER_PIN"] = "Spieler Pin anzeigen",
	["SI_VOTANS_MAPPIN_COLORS_SHOW_PLAYER_PIN_TOOLTIP"] = "Erlaubt es den Spieler Pin unsichtbar zu machen. Für jene, die im Hardmode questen wollen.",
	["SI_VOTANS_MAPPIN_COLORS_PLAYER_PIN_VIBRATION"] = "Spieler Pin Vibration",
	["SI_VOTANS_MAPPIN_COLORS_PLAYER_PIN_VIBRATION_TOOLTIP"] = "Läßt den Spieler Pin kurz vibrieren, um ihn auf der Karte zu finden.",
}
for id, text in pairs(strings) do SafeAddString(_G[id], text, 0) end
