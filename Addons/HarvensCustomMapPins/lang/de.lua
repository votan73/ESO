local strings = {
    SI_HARVEN_CMP_EDIT_PIN = "Bearbeiten",
    SI_HARVEN_CMP_SHOW_IN_POPUP = "In Popup anzeigen",
    SI_HARVEN_CMP_SHARE_PIN = "Teilen",
    SI_HARVEN_CMP_DELETE_PIN = "Löschen",
    SI_HARVEN_CMP_PLACE_CUSTOM_PIN = "Pin platzieren",
    SI_HARVEN_CMP_NO_IMPORT_SECTION = "Kein Importabschnitt in der SavedVariable-Datei. Melden Sie sich ab und stellen Sie sicher, dass der Abschnitt vorhanden ist.",
    SI_HARVEN_CMP_PIN_MALFORMED = "Pin '<<1>>' scheint fehlerhaft zu sein, wird ignoriert.",
    SI_HARVEN_CMP_IMPORTED_PIN = "Importierter Pin '<<1>>' auf Karte '<<2>>' Position <<3>>, <<4>>",
    SI_HARVEN_CMP_PIN_ALREADY_PRESENT = "Ein Pin ist bereits an dieser Position vorhanden: <<1>>, <<2>> <<3>>",
    SI_HARVEN_CMP_IMPORT_COMPLETED = "Import abgeschlossen!",
    SI_HARVEN_CMP_PIN_SIZE = "Pin Größe",
    SI_HARVEN_CMP_PIN_DRAW_LEVEL = "Pin Zeichenebene",
    SI_HARVEN_CMP_PIN_DRAW_LEVEL_TOOLTIP = "Je höher die Zahl, desto weiter oben wird ein Pin gezeichnet.",
    SI_HARVEN_CMP_SPREAD_PIN_RENDERING = "Verteile Pin Rendering",
    SI_HARVEN_CMP_SPREAD_PIN_RENDERING_TOOLTIP = "Verteile Pin Rendering über Zeit, um die CPU-Auslastung pro Frame zu reduzieren.",
    SI_HARVEN_CMP_ALLOW_PIN_SUB_FILTER = "Erlaube Pin-Unterfilter",
    SI_HARVEN_CMP_ALLOW_PIN_SUB_FILTER_TOOLTIP = "Erlaubt das Ein-/Ausblenden von Vorlagen (Kartenfilter-Registerkarte). Lädt die Benutzeroberfläche neu!",
    SI_HARVEN_CMP_ENTER_PIN_DESCRIPTION = "Pin-Beschreibung eingeben:",
    SI_HARVEN_CMP_TITLE_REPLACE = "CUSTOM MAP PIN (Ersetzen)",
    SI_HARVEN_CMP_TITLE_EDIT = "CUSTOM MAP PIN (Bearbeiten)",
    SI_HARVEN_CMP_TITLE_NEW = "CUSTOM MAP PIN (Neu)",
    SI_HARVEN_CMP_ADVANCED_OPTIONS = "Erweiterte Optionen",
    SI_HARVEN_CMP_SELECT_ICON = "Symbol auswählen:",
    SI_HARVEN_CMP_SELECT_COLOR = "Farbe auswählen:",
    SI_HARVEN_CMP_APPLY_PREDEFINED = "Vorlage:",
    SI_HARVEN_CMP_PREDEFINED_NAME = "Vorlagenname:"
}

for stringId, stringValue in pairs(strings) do
	SafeAddString(_G[stringId], stringValue, 2)
end
