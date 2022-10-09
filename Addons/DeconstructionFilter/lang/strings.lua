local strings = {
	["SI_DECONFILTER_STOLEN"] = "Stolen items",
	["SI_DECONFILTER_INTRICATE"] = "Intricate items only",
	["SI_DECONFILTER_TRASH"] = "Trash and useless traits",
	["SI_DECONFILTER_BACKSPACE"] = "In backspace only",
	["SI_DECONFILTER_EQUIPPED"] = "Equipped items only",
	["SI_DECONFILTER_BANK"] = "In bank only",
	["SI_DECONFILTER_CRAFTED"] = "Crafted items only",
	["SI_DECONFILTER_SETITEMS"] = "Set items only",
	["SI_DECONFILTER_KNOWN_SETITEMS"] = "Collected Set items only"
}
for id, text in pairs(strings) do ZO_CreateStringId(id, text) end
