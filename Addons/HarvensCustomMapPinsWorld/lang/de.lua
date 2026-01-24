local strings = {
    SI_HARVEN_CWP_WORLD_PIN_SIZE = "Welt Pin Größe",
    SI_HARVEN_CWP_DISTANCE = "Distanz",
    SI_HARVEN_CWP_DISTANCE_TOOLTIP = "Wenn Sie Leistungsprobleme haben, kann das Reduzieren der Distanz helfen. Hohe Distanz mit aktiviertem Tiefenpuffer ist manchmal etwas übertrieben.",
    SI_HARVEN_CWP_USE_DEPTH_BUFFER = "Tiefenpuffer verwenden",
    SI_HARVEN_CWP_USE_DEPTH_BUFFER_TOOLTIP = "Schalten Sie es aus, um durch Wände und Böden zu sehen. Sie werden Tricks und Anpassungen der Levelgestaltung sehen.",
    SI_HARVEN_CWP_ROTATE_PINS = "Pins drehen",
    SI_HARVEN_CWP_ROTATE_PINS_TOOLTIP ="Schalten Sie es ein, um die Pins für eine bessere Sichtbarkeit zu animieren.",
}

for stringId, stringValue in pairs(strings) do
	SafeAddString(_G[stringId], stringValue, 2)
end
