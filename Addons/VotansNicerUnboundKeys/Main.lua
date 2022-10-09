if GetAPIVersion() < 100030 then
	local orgZO_Keybindings_GenerateKeyMarkup = ZO_Keybindings_GenerateKeyMarkup
	function ZO_Keybindings_GenerateKeyMarkup(name)
		if name ~= GetString(SI_ACTION_IS_NOT_BOUND) then
			return orgZO_Keybindings_GenerateKeyMarkup(name)
		end
		return orgZO_Keybindings_GenerateKeyMarkup("\194\160\194\160")
	end
else
	local orgZO_Keybindings_GenerateTextKeyMarkup = ZO_Keybindings_GenerateTextKeyMarkup
	function ZO_Keybindings_GenerateTextKeyMarkup(name)
		if name ~= GetString(SI_ACTION_IS_NOT_BOUND) then
			return orgZO_Keybindings_GenerateTextKeyMarkup(name)
		end
		return orgZO_Keybindings_GenerateTextKeyMarkup("\194\160\194\160")
	end
end
