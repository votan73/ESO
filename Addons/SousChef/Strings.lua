SousChef.Strings = {
	en = {
		-- for slash commands
		SC_NUM_RECIPES_KNOWN = "Number of recipes known: ",
		SC_NUM_INGREDIENTS_TRACKED = "Number of ingredients tracked: ",
		SC_NOT_FOUND = " not found in ignore list",
		SC_ADDING1 = "Adding ",
		SC_ADDING2 = " to ignored recipes",
		SC_REMOVING1 = "Removed ",
		SC_REMOVING2 = " from ignored recipes",
		SC_IGNORED = "Ignoring:",
		
		-- Menu items
		MENU_MAIN_CHAR = "Main Provisioner Character",
		MENU_MAIN_CHAR_TOOLTIP = "Select the character whose knowledge you want shown by the indicators",
		MENU_RECIPE_HEADER = "Recipe Indicators",
		MENU_PROCESS_RECIPES = "Display Recipe Indicators",
		MENU_PROCESS_RECIPES_TOOLTIP = "Do you want Sous Chef to display indicators for recipes in the inventory view?",
		MENU_KNOWN = "known",
		MENU_UNKNOWN = "unknown",
		MENU_MARK_IF_KNOWN = "Mark recipe if it is ",
		MENU_MARK_IF_KNOWN_TOOLTIP = "When do you want Sous Chef to display an indicator by a recipe?", 
		MENU_MARK_IF_ALT_KNOWS = "Fade Indicator if Alt Knows",
		MENU_MARK_IF_ALT_KNOWS_TOOLTIP = "Fade the indicator for unknown recipes if an alt knows the recipe.",
		
		MENU_RECIPE_TOOLTIP_HEADER = "Recipe Tooltips",
		MENU_TOOLTIP_IF_ALT_KNOWS = "List Characters Who Know Recipe",
		MENU_TOOLTIP_IF_ALT_KNOWS_TOOLTIP = "Show in tooltips which characters know a recipe",

		MENU_TOOLTIP_HEADER = "Ingredient Tooltips",
		MENU_TOOLTIP_CLICK = "Require Mouse Click to Show Sous Chef Data",
		MENU_TOOLTIP_CLICK_TOOLTIP = "Only show Sous Chef information in ingredient tooltips after a mouse click, to save space",
		MENU_RESULT_COUNTS = "Show Recipe Result Counts",
		MENU_RESULT_COUNTS_TOOLTIP = "Show how many of each recipe can be made in the Ingredient tooltip, next to the recipe's name",
		MENU_ALT_USE = "Use Alts' Ingredient Knowledge",
		MENU_ALT_USE_TOOLTIP = "If the main character doesn't know how to use an ingredient, but an alt does, use the alt's knowledge",

		MENU_INDICATOR_HEADER = "Ingredient Indicators",
		MENU_INDICATOR_COLOR = "Indicator Colour",
		MENU_INDICATOR_COLOR_TOOLTIP = "Allows you to set the colour of the ingredient's indicator",
		MENU_SHOPPING_COLOR = "Shopping List Indicator Colour",
		MENU_SHOPPING_COLOR_TOOLTIP = "Allows you to set the colour of the indicator for ingredients in your Shopping List",
		MENU_SHOW_ALT_SHOPPING = "Shop for Alts' Shopping Lists?",
		MENU_SHOW_ALT_SHOPPING_TOOLTIP = "Shop for ingredients on all characters' shopping lists, or just the main character?",
		MENU_ONLY_MARK_SHOPPING = "Only Mark Shopping List Ingredients",
		MENU_ONLY_MARK_SHOPPING_TOOLTIP = "Only mark ingredients on your Shopping List",
		MENU_AUTO_JUNK = "Auto-junk ingredients not on Shopping List",
		MENU_AUTO_JUNK_TOOLTIP = "Automatically mark looted ingredients as junk if they're not on the Shopping List",
		MENU_AUTO_JUNK_WARNING = "Caution: Auto-junking ingredients should be used with care!",
		MENU_SORT_INGREDIENTS = "Sort Ingredients in Inventory",
		MENU_SORT_INGREDIENTS_TOOLTIP = "Will sort known ingredients by rank",

		MENU_DELETE_CHAR = "Delete a Character",
		MENU_DELETE_CHAR_TOOLTIP = "Select a character to delete from Sous Chef's records, then press the \"Delete Character\" button.",
		MENU_DELETE_CHAR_BUTTON = "Delete Character",
		MENU_DELETE_CHAR_WARNING = "You are about to delete a character from Sous Chef's records. This can only be undone by logging into the deleted character!",

		MENU_RELOAD = "Requires UI Reload",
		
		-- keybinding label
		KEY_MARK = "Mark Recipe",
		
		-- provisioning window
		PROVISIONING_QUALITY = "Hide Green Recipes",
		PROVISIONING_MARKED = "Marked by: ",
		
		-- tooltip
		TOOLTIP_KNOWN_BY = "Known by ",
		TOOLTIP_USED_IN = "Used in:",
		TOOLTIP_CREATES = "Creates a Level <<1>> <<t:2>>", -- where <<1>> is the level and <<2>> is the result name
		TOOLTIP_INGREDIENT_TYPES = {
			"Food Spice",
			"Drink Flavoring",
			"Meat",
			"Fruit",
			"Vegetable",
			"Alcohol",
			"Tea",
			"Tonic",
			"Food Ingredient",
			"Drink Ingredient",
		},
	},

	-- Thanks to sirinsidiator for the German translations here!
	de = {
		-- for slash commands
		SC_NUM_RECIPES_KNOWN = "Anzahl bekannter Rezepte: ",
		SC_NUM_INGREDIENTS_TRACKED = "Anzahl beobachteter Zutaten: ",
		SC_NOT_FOUND = " wird nicht ignoriert",
		SC_ADDING1 = "",
		SC_ADDING2 = " wird jetzt ignoriert",
		SC_REMOVING1 = "",
		SC_REMOVING2 = " wird nicht mehr ignoriert",
		SC_IGNORED = "Ignoriert:",
		
		-- Menu items
		MENU_MAIN_CHAR = "Main Provisioner Character",
		MENU_MAIN_CHAR_TOOLTIP = "Select the character whose recipe knowledge you want shown by the indicators",
		MENU_RECIPE_HEADER = "Rezept Einstellungen",
		MENU_PROCESS_RECIPES = "Rezeptsinfos anzeigen",
		MENU_PROCESS_RECIPES_TOOLTIP = "Soll Sous Chef Rezepts markieren?",
		MENU_MARK_IF_KNOWN = "Rezept markieren wenn?",
		MENU_KNOWN = "bekannt",
		MENU_UNKNOWN = "unbekannt",
		MENU_MARK_IF_KNOWN_TOOLTIP = "Wann soll Sous Chef ein Symbol beim Rezept anzeigen?",
		MENU_MARK_IF_ALT_KNOWS = "Alternative Charakter Markierung",
		MENU_MARK_IF_ALT_KNOWS_TOOLTIP = "Markierung f\195\188r unbekannte Rezepte ausblenden, wenn ein anderer Charakter dieses Rezept bereits kennt.",
		MENU_TOOLTIP_IF_ALT_KNOWS = "Charakter Rezeptsammlung in Kurzinfos auflisten",
		MENU_TOOLTIP_IF_ALT_KNOWS_TOOLTIP = "Zeige in den Kurzinfos welche Spielfiguren ein Rezept kennen",

		MENU_TOOLTIP_HEADER = "Zutatenkurzinfo Einstellungen",
		MENU_TOOLTIP_CLICK = "Sous Chef Daten nur durch Mausklick anzeigen",
		MENU_TOOLTIP_CLICK_TOOLTIP = "Zeige Sous Chef Informationen in Zutatenkurzinfos erst nach einem Mausklick, um Platz zu sparen",
		MENU_RESULT_COUNTS = "Zeige Anzahl produzierbarer Gerichte",
		MENU_RESULT_COUNTS_TOOLTIP = "Zeige in den Zutatenkurzinfos, wieviele Gerichte mit einem Rezept gekocht werden k\195\182nnen",
		MENU_ALT_USE = "Zutatenverbrauch anderer Spielfiguren",
		MENU_ALT_USE_TOOLTIP = "Anzeigen wenn ein anderer Charakter eine Zutat verwendet",

		MENU_INDICATOR_HEADER = "Markierungs Einstellungen",
		MENU_ICON_SET = "Fettere Symbole verwenden",
		MENU_ICON_SET_TOOLTIP = "Ersetzt die Rangsymbole mit besser sichtbaren Versionen",
		MENU_SPECIAL_ICONS = "Spezielle Symbole f\195\188r spezielle Zutaten",
		MENU_SPECIAL_ICONS_TOOLTIP = "Wenn eine Zutat ein Gew\195\188rz (S) oder Geschmackstr\195\164ger (F) ist, zeige ein entsprechendes Symbol, anstelle des h\195\182chsten Rezeptranges welches sie verwendet.",
		MENU_SPECIAL_TYPES = "Spezialzutaten Typen anzeigen",
		MENU_SPECIAL_TYPES_TOOLTIP = "Verwende Symbole f\195\188r den Rezepttyp f\195\188r den es eine Spezialzutat ist (z.B. Gegrilltes)",
		MENU_INDICATOR_COLOR = "Symbolfarbe",
		MENU_INDICATOR_COLOR_TOOLTIP = "Erm\195\182glicht es die Farbe der Markierungen zu setzen",
		MENU_SHOPPING_COLOR = "Einkauflisten Symbolfarbe",
		MENU_SHOPPING_COLOR_TOOLTIP = "Erm\195\182glicht es die Farbe f\195\188r Markierungen von Zutaten auf der Einkaufsliste zu setzen",
		MENU_SHOW_ALT_SHOPPING = "Shop for Alts' Shopping Lists?",
		MENU_SHOW_ALT_SHOPPING_TOOLTIP = "Shop for ingredients on all characters' shopping lists, or just the main character?",
		MENU_ONLY_MARK_SHOPPING = "Nur Zutaten auf der Einkaufsliste markieren",
		MENU_ONLY_MARK_SHOPPING_TOOLTIP = "Es werden nur Zutaten von Rezepten auf der Einkaufsliste markiert",
		MENU_AUTO_JUNK = "Auto-junk ingredients not on Shopping List",
		MENU_AUTO_JUNK_TOOLTIP = "Automatically mark looted ingredients as junk if they're not on the Shopping List",
		MENU_AUTO_JUNK_WARNING = "Caution: Auto-junking ingredients should be used with care!",
		MENU_SORT_INGREDIENTS = "Zutaten im Inventar sortieren",
		MENU_SORT_INGREDIENTS_TOOLTIP = "Zutaten im Inventar werden nach Rang sortiert",

		MENU_DELETE_CHAR = "Delete a Character",
		MENU_DELETE_CHAR_TOOLTIP = "Select a character to delete from Sous Chef's records, then press the \"Delete Character\" button.",
		MENU_DELETE_CHAR_BUTTON = "Delete Character",

		MENU_RELOAD = "Ben\195\182tigt das Neuladen der Benutzeroberfl\195\164che (/reloadui)",
		
		-- keybinding label
		KEY_MARK = "Rezept markieren",
		
		-- provisioning window
		PROVISIONING_QUALITY = "Gr\195\188ne Rezepte verstecken",
		PROVISIONING_MARKED = "Markiert von: ",

		-- tooltip
		TOOLTIP_KNOWN_BY = "Gelernt von ",
		TOOLTIP_USED_IN = "Verwendet in:",
		TOOLTIP_CREATES = "Creates a Level <<1>> <<t:2>>", -- where <<1>> is the level and <<2>> is the result name
		TOOLTIP_INGREDIENT_TYPES = {
			"Gew\195\188rz ",
			"Geschmackstr\195\164ger",
			"Fleisch",
			"Frucht",
			"Gem\195\188se",
			"Alkohol",
			"Tee",
			"Tonik",
			"Nahrungsmaterial",
			"Getr\195\164nksmaterial",
		},
	},

	--Thanks to Ayantir for the French translations here!
	fr = {
		-- for slash commands
		SC_NUM_RECIPES_KNOWN = "Nombre de recettes connues: ",
		SC_NUM_INGREDIENTS_TRACKED = "Nombre d'ingrédients suivis: ",
		SC_NOT_FOUND = " n'a pas été trouvée dans les éléments ignorés",
		SC_ADDING1 = "Ajout de ",
		SC_ADDING2 = " aux recettes ignorées",
		SC_REMOVING1 = "Suppression de ",
		SC_REMOVING2 = " des recettes ignorées",
		SC_IGNORED = "Recettes ignorées:",
		
		-- Menu items
		MENU_MAIN_CHAR = "Main Provisioner Character",
		MENU_MAIN_CHAR_TOOLTIP = "Select the character whose recipe knowledge you want shown by the indicators",
		MENU_RECIPE_HEADER = "Recettes",
		MENU_PROCESS_RECIPES = "Afficher des infos complémentaires aux recettes",
		MENU_PROCESS_RECIPES_TOOLTIP = "Si votre jeu n'est pas en anglais, il faudra peut-être désactiver cette option si la reconnaissance des recettes ne fonctionne pas correctement",
		MENU_MARK_IF_KNOWN = "Indiquer si la recette est ",
		MENU_KNOWN = "connue",
		MENU_UNKNOWN = "inconnue",
		MENU_MARK_IF_KNOWN_TOOLTIP = "Quand voulez-vous que Sous Chef affiche une coche sur une recette?",
		MENU_MARK_IF_ALT_KNOWS = "Vérification des autres personnages",
		MENU_MARK_IF_ALT_KNOWS_TOOLTIP = "Masque la coche indiquant qu'une recette est inconnue si un de vos autres personnages la connait déjà",
		MENU_TOOLTIP_IF_ALT_KNOWS = "Recettes connues dans les info-bulles",
		MENU_TOOLTIP_IF_ALT_KNOWS_TOOLTIP = "Affiche dans les info-bulles quel personnage connait quelle recette",

		MENU_TOOLTIP_HEADER = "Options pour les ingrédients",
		MENU_TOOLTIP_CLICK = "Cliquer pour afficher les infos de Sous Chef",
		MENU_TOOLTIP_CLICK_TOOLTIP = "N'affichera seulement les informations additionnelles de Sous Chef sur les info-bulles des ingrédients qu'après avoir cliqué dessus pour économiser de l'espace",
		MENU_RESULT_COUNTS = "Nombre de fabrications possibles",
		MENU_RESULT_COUNTS_TOOLTIP = "Affiche combien de fois chaque recette peut être cuisinée dans l'info-bulle des ingrédients",
		MENU_ALT_USE = "Vérification des autres personnages",
		MENU_ALT_USE_TOOLTIP = "Indique si un autre personnage sait utiliser l'ingrédient",

		MENU_INDICATOR_HEADER = "Interface",
		MENU_ICON_SET = "Utiliser des icônes plus foncées",
		MENU_ICON_SET_TOOLTIP = "Utiliser des icônes plus lissées que par défaut",
		MENU_SPECIAL_ICONS = "Icônes pour les ingrédients spéciaux",
		MENU_SPECIAL_ICONS_TOOLTIP = "Si un ingrédient est considéré comme une Epice (S) ou un assaisonnement (F), afficher une icône particulière plutôt que le tiers le plus élevé de la recette qui l'utilise",
		MENU_SPECIAL_TYPES = "Afficher les types d'ingrédients spéciaux",
		MENU_SPECIAL_TYPES_TOOLTIP = "Utiliser l'icône du type de recette dans laquelle entre en composition les ingrédients spéciaux (ex: Bière)",
		MENU_INDICATOR_COLOR = "Couleur des marques",
		MENU_INDICATOR_COLOR_TOOLTIP = "Vous permet de modifier la couleur des marques indiquant le rang des recettes utilisant l'ingrédient",
		MENU_SHOPPING_COLOR = "Couleur des ingrédients marqués",
		MENU_SHOPPING_COLOR_TOOLTIP = "Vous permet de modifier la couleur des marques indiquant le rang des recettes marquées utilisant l'ingrédient",
		MENU_SHOW_ALT_SHOPPING = "Shop for Alts' Shopping Lists?",
		MENU_SHOW_ALT_SHOPPING_TOOLTIP = "Shop for ingredients on all characters' shopping lists, or just the main character?",
		MENU_ONLY_MARK_SHOPPING = "N'afficher que les ingrédients marqués",
		MENU_ONLY_MARK_SHOPPING_TOOLTIP = "N'afficher que les ingrédients marqués",
		MENU_AUTO_JUNK = "Auto-junk ingredients not on Shopping List",
		MENU_AUTO_JUNK_TOOLTIP = "Automatically mark looted ingredients as junk if they're not on the Shopping List",
		MENU_AUTO_JUNK_WARNING = "Caution: Auto-junking ingredients should be used with care!",
		MENU_SORT_INGREDIENTS = "Trier les ingrédients dans les sacs",
		MENU_SORT_INGREDIENTS_TOOLTIP = "Cette option activée, les ingrédients seront triés par rang dans les sacs",

		MENU_DELETE_CHAR = "Delete a Character",
		MENU_DELETE_CHAR_TOOLTIP = "Select a character to delete from Sous Chef's records, then press the \"Delete Character\" button.",
		MENU_DELETE_CHAR_BUTTON = "Delete Character",

		MENU_RELOAD = "Nécessite de recharger l'interface (ReloadUI)",
		
		-- keybinding label
		KEY_MARK = "Marquer la recette",
		
		-- provisioning window
		PROVISIONING_QUALITY = "Masquer les recettes Vertes",
		PROVISIONING_MARKED = "Marqué par : ",

		-- tooltip
		TOOLTIP_KNOWN_BY = "Connue par ",
		TOOLTIP_USED_IN = "Utilisé par :",
		TOOLTIP_CREATES = "Creates a Level <<1>> <<t:2>>", -- where <<1>> is the level and <<2>> is the result name
		TOOLTIP_INGREDIENT_TYPES = {
			"Food Spice",
			"Drink Flavoring",
			"Meat",
			"Fruit",
			"Vegetable",
			"Alcohol",
			"Tea",
			"Tonic",
			"Food Ingredient",
			"Drink Ingredient",
		},
	},
}