
--[[
 A library to notify users about  common errors
--]]

local MAJOR, MINOR = "LibDAU", 1
local lib = _G[MAJOR] or {}
if lib.minor and lib.minor >= MINOR then return end

_G[MAJOR] = lib
lib.minor = MINOR

if lib.Unload then
	lib:Unload()
end

function lib:Unload()
	ESO_Dialogs[MAJOR] = nil
end

function lib:Load()
	local errorDialog = {
		title = { text = GetString(SI_PROMPT_TITLE_ERROR) },
		mainText = { text = [[The AddOn <<1>> was installed incorrectly.
The AddOn must be installed as:
'<<2>>'
instead of
'<<3>>']] },
		buttons = {
			[1] = {
				text = GetString(SI_DIALOG_CLOSE),
			},
		}
	}
	ZO_Dialogs_RegisterCustomDialog(MAJOR, errorDialog)
end


function lib:VerifyAddon(addOnName, desiredPath)
	desiredPath = desiredPath or addOnName
	desiredPath = zo_strformat("AddOns/<<1>>/", desiredPath)
	local addOnManager = GetAddOnManager()
	for id = 1, addOnManager:GetNumAddOns() do
		local name, displayName = addOnManager:GetAddOnInfo(id)
		if name == addOnName then
			local path = addOnManager:GetAddOnRootDirectoryPath(id)
			path = path:gsub("user:/", "")
			if path ~= desiredPath then
				ZO_Dialogs_ShowDialog(MAJOR, {}, { mainTextParams = { displayName, desiredPath, path } } )
			end
		end
	end
end

lib:Load()
