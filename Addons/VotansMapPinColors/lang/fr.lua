local strings = {
	["SI_VOTANS_MAPPIN_COLORS_PREFER_ASSISTED"] = "Utiliser la couleur de quête suivie",
	["SI_VOTANS_MAPPIN_COLORS_PREFER_ASSISTED_TOOLTIP"] = "Utilise la couleur de marqueur des quêtes suivies plutôt que celle des quêtes répétables pour l'affichage du marqueur de la quête répétable suivie.",
	["SI_VOTANS_MAPPIN_COLORS_SHOW_PLAYER_PIN"] = "Afficher le marqueur du joueur",
	["SI_VOTANS_MAPPIN_COLORS_SHOW_PLAYER_PIN_TOOLTIP"] = "Permet de cacher le marqueur de position du joueur sur la carte. Utile pour jouer en mode immersif.",
	["SI_VOTANS_MAPPIN_COLORS_PLAYER_PIN_VIBRATION"] = "Vibration du marqueur",
	["SI_VOTANS_MAPPIN_COLORS_PLAYER_PIN_VIBRATION_TOOLTIP"] = "Fait brièvement vibrer le marqueur du joueur à l'ouverture de la carte pour faciliter son repérage.",
}
for id, text in pairs(strings) do SafeAddString(_G[id], text, 0) end