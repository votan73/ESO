local sv = {}

function HarvensAliases_DoCommandInClosure(alias, cmd)
	local args = nil
	if type(cmd) == "table" then
		args = cmd[2]
		cmd = cmd[1]
	end

	local slashCommand = "/" .. cmd
	SLASH_COMMANDS["/" .. alias] = function(userArgs)
		if SLASH_COMMANDS[slashCommand] ~= nil and type(SLASH_COMMANDS[slashCommand]) == "function" then
			if args then
				if #userArgs > 0 then
					SLASH_COMMANDS[slashCommand](args .. " " .. userArgs)
				else
					SLASH_COMMANDS[slashCommand](args)
				end
			else
				SLASH_COMMANDS[slashCommand](userArgs)
			end
		else
			CHAT_ROUTER:AddSystemMessage("Command /" .. cmd .. " doesn't exists")
		end
	end
end

function HarvensAliases_ListAliases(...)
	CHAT_ROUTER:AddSystemMessage("Defined aliases:")
	for k, v in pairs(sv.aliases) do
		if type(v) == "table" then
			CHAT_ROUTER:AddSystemMessage(string.format("%s -> %s(%s)", k, v[1], table.concat(v, ", ", 2)))
		else
			CHAT_ROUTER:AddSystemMessage(string.format("%s -> %s", k, v))
		end
	end
end

function HarvensAliases_AddAlias(arguments)
	local args = {}
	local i = 1
	for w in string.gmatch(arguments, "[%w_%-]+") do
		args[i] = w
		i = i + 1
	end

	if args[1] == nil or args[2] == nil then
		CHAT_ROUTER:AddSystemMessage("Usage: /addalias <alias> <command> <default arguments>")
		CHAT_ROUTER:AddSystemMessage("Example: /addalias rl reloadui")
		return
	end

	local alias = args[1]
	local cmd = args[2]
	if SLASH_COMMANDS["/" .. alias] ~= nil then
		CHAT_ROUTER:AddSystemMessage("Command /" .. alias .. " already exists.")
		return
	end

	if cmd == alias then
		CHAT_ROUTER:AddSystemMessage("Alias name and command cannot be the same.")
		return
	end

	local aliasArgs = table.concat(args, " ", 3)

	sv.aliases[alias] = {cmd, aliasArgs}
	HarvensAliases_DoCommandInClosure(alias, sv.aliases[alias])
	CHAT_ROUTER:AddSystemMessage("Alias /" .. alias .. " added.")
end

function HarvensAliases_DelAlias(arguments)
	local args = {}
	local i = 1
	for w in string.gmatch(arguments, "[%w_%-]+") do
		args[i] = w
		i = i + 1
	end

	if args[1] == nil then
		CHAT_ROUTER:AddSystemMessage("Usage: /delalias <alias>")
		CHAT_ROUTER:AddSystemMessage("Example: /delalias rl")
		return
	end

	if sv.aliases[args[1]] == nil then
		CHAT_ROUTER:AddSystemMessage("Alias /" .. args[1] .. " does not exists.")
		return
	end

	SLASH_COMMANDS["/" .. args[1]] = nil
	sv.aliases[args[1]] = nil
	CHAT_ROUTER:AddSystemMessage("Alias /" .. args[1] .. " deleted.")
end

function HarvensAliasesInitialize(eventCode, name)
	if name ~= "HarvensAliases" then
		return
	end

	local defaults = {aliases = {}}
	sv = ZO_SavedVars:New("HarvensAliases_SavedVariables", 1, nil, nil)
	if sv.aliases then
		defaults.aliases = sv.aliases
		sv.aliases = nil
	end
	sv = ZO_SavedVars:NewAccountWide("HarvensAliases_SavedVariables", 1, nil, defaults)

	for k, v in pairs(sv.aliases) do
		HarvensAliases_DoCommandInClosure(k, v)
	end

	SLASH_COMMANDS["/addalias"] = HarvensAliases_AddAlias
	SLASH_COMMANDS["/listaliases"] = HarvensAliases_ListAliases
	SLASH_COMMANDS["/delalias"] = HarvensAliases_DelAlias
end

EVENT_MANAGER:RegisterForEvent("HarvensAliasesOnLoaded", EVENT_ADD_ON_LOADED, HarvensAliasesInitialize)
