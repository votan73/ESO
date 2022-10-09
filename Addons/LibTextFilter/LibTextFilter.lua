local LIB_IDENTIFIER = "LibTextFilter"

assert(not _G[LIB_IDENTIFIER], LIB_IDENTIFIER .. " is already loaded")

local lib = {}
_G[LIB_IDENTIFIER] = lib

local function Log(message, ...)
	df("[%s] %s", LIB_IDENTIFIER, message:format(...))
end

--lib.debug = true --TODO

lib.RESULT_OK = 1
lib.RESULT_INVALID_ARGUMENT_COUNT = 2
lib.RESULT_INVALID_VALUE_COUNT = 3
lib.RESULT_INVALID_INPUT = 4

lib.cache = lib.cache or {}

local function ValueToString(value)
	if(type(value) == "table" and value.token) then
		return "'" .. value.token .. "'"
	elseif(type(value) == "string") then
		return "\"" .. value .. "\""
	else
		return tostring(value)
	end
end

local function ArrayToString(array)
	if(#array > 0) then
		local output = {}
		for i = 1, #array do
			output[i] = ValueToString(array[i])
		end
		return "{" .. table.concat(output, ", ") .. "}"
	else
		return "{}"
	end
end

local function Convert(input, value)
	if(type(value) == "string") then
		local _, linkData = value:match("|[Hh](.-):(.-)|h(.-)|h") -- not 100% okay, but otherwise putting the input into lower case won't work
		if(linkData and linkData ~= "") then
			value = linkData
		end
		return (input:find(value) ~= nil)
	end
	return value
end

local function AndOperation(input, a, b)
	local a_ = Convert(input, a)
	local b_ = Convert(input, b)
	if(lib.debug) then
		Log("And(%s, %s, %s); %s AND %s = %s", ValueToString(input), ValueToString(a), ValueToString(b), ValueToString(a_), ValueToString(b_), ValueToString(a_ and b_))
	end
	return (a_ and b_)
end

local function AndNotOperation(input, a, b)
	local a_ = Convert(input, a)
	local b_ = Convert(input, b)
	if(lib.debug) then
		Log("AndNot(%s, %s, %s); NOT %s AND %s = %s", ValueToString(input), ValueToString(a), ValueToString(b), ValueToString(a_), ValueToString(b_), ValueToString(not a_ and b_))
	end
	return (not a_ and b_)
end

local function OrOperation(input, a, b)
	local a_ = Convert(input, a)
	local b_ = Convert(input, b)
	if(lib.debug) then
		Log("Or(%s, %s, %s); %s OR %s = %s", ValueToString(input), ValueToString(a), ValueToString(b), ValueToString(a_), ValueToString(b_), ValueToString(a_ or b_))
	end
	return (a_ or b_)
end

local function NotOperation(input, a)
	local a_ = Convert(input, a)
	if(lib.debug) then
		Log("Not(%s, %s); NOT %s = %s", ValueToString(input), ValueToString(a), ValueToString(a_), ValueToString(not a_))
	end
	return not a_
end

local function LinkGeneralizationOperation(input, a)
	local a_ = a
	local h, linkData = a_:match("(|[Hh].-):(.-)|h(.-)|h")
	if(linkData and linkData ~= "") then
		local data = {zo_strsplit(":", linkData)}
		if(data[1] == "item") then
			a_ = table.concat({h, ":", data[1], ":", data[2], "|h|h"})
		end
	end
	if(lib.debug) then
		Log("LinkGeneralization(%s, %s); %s", ValueToString(input), ValueToString(a), ValueToString(a_))
	end
	return a_
end

local function Sanitize(value)
	return value:gsub("[-*+?^$().[%]%%]", "%%%0") -- escape meta characters
end

local LEFT_ASSOCIATIVE = 1
local RIGHT_ASSOCIATIVE = 2
local NON_ASSOCIATIVE = 3

local OPERATORS = {
	[" "] = { precedence = 2, association = LEFT_ASSOCIATIVE, numArguments = 2, operation = AndOperation, defaultArgument = true },
	["&"] = { precedence = 2, association = LEFT_ASSOCIATIVE, numArguments = 2, operation = AndOperation, defaultArgument = true },
	["+"] = { precedence = 3, association = LEFT_ASSOCIATIVE, numArguments = 2, operation = OrOperation, defaultArgument = false },
	["/"] = { precedence = 3, association = LEFT_ASSOCIATIVE, numArguments = 2, operation = OrOperation, defaultArgument = false },
	["-"] = { precedence = 3, association = LEFT_ASSOCIATIVE, numArguments = 2, operation = AndNotOperation, defaultArgument = true },
	["^"] = { precedence = 3, association = LEFT_ASSOCIATIVE, numArguments = 2, operation = AndNotOperation, defaultArgument = true },
	["!"] = { precedence = 4, association = NON_ASSOCIATIVE, numArguments = 1, operation = NotOperation },
	["~"] = { precedence = 5, association = NON_ASSOCIATIVE, numArguments = 1, operation = LinkGeneralizationOperation },
	["*"] = { precedence = 5, association = NON_ASSOCIATIVE, numArguments = 1, operation = LinkGeneralizationOperation },
	["("] = { isLeftParenthesis = true }, -- control operator
	[")"] = { isRightParenthesis = true }, -- control operator
	["\""] = {}, -- control operator, will be filtered before parsing
}
local OPERATOR_PATTERN = {}
for token, data in pairs(OPERATORS) do
	data.token = token
	OPERATOR_PATTERN[#OPERATOR_PATTERN + 1] = Sanitize(token)
end
OPERATOR_PATTERN = table.concat(OPERATOR_PATTERN, "")
local TOKEN_DUPLICATION_PATTERN = string.format("([%s])", OPERATOR_PATTERN)
local TOKEN_MATCHING_PATTERN = string.format("([%s])(.-)[%s]", OPERATOR_PATTERN, OPERATOR_PATTERN)
lib.OPERATORS = OPERATORS
local DEFAULT_OPERATOR = "+"

function lib:Tokenize(input)
	input = DEFAULT_OPERATOR .. input:gsub(TOKEN_DUPLICATION_PATTERN, "%1%1") .. DEFAULT_OPERATOR -- the matching pattern eats one of each token, so we duplicate them and add one to the beginning and end
	if(lib.debug) then
		Log(input)
	end

	local tokens = {}
	local quoteStack, quoteTerm = {}, ""
	local inQuotes = false
	local lastOperator

	for operator, term in (input):gmatch(TOKEN_MATCHING_PATTERN) do
		if(lib.debug) then
			Log("value: %s, term: %s, last: %s, tokens: %s", ValueToString(operator), ValueToString(term), ValueToString(lastOperator), ArrayToString(tokens))
		end
		if(operator == "\"") then
			inQuotes = not inQuotes
			if(inQuotes) then -- start a new stack for all input value we encounter
				quoteStack = {term}
			else
				-- combine all values on the stack and add them as a single token
				if(#quoteStack > 0) then
					quoteTerm = table.concat(quoteStack, "")
					if(quoteTerm ~= "") then
						if(lastOperator) then -- if we have a pending operator, we put it on the stack now
							tokens[#tokens + 1] = lastOperator
							lastOperator = nil
						elseif(not OPERATORS[tokens[#tokens]]) then -- if there is no operator in front of the quote we supply a space
							tokens[#tokens + 1] = " "
						end
						tokens[#tokens + 1] = quoteTerm
					end
				end

				if(term ~= "") then -- if the quotes are followed by another term, we put a space in between
					tokens[#tokens + 1] = " "
					tokens[#tokens + 1] = term
				end
			end
		elseif(inQuotes) then -- collect all terms and operators inside the quotes
			quoteStack[#quoteStack + 1] = operator
			quoteStack[#quoteStack + 1] = term
		else
			if(operator == "(" or operator == ")") then
				tokens[#tokens + 1] = lastOperator
				lastOperator = nil
				if(term == "") then -- if the parenthesis have another operator inside, we just push them on the output
					tokens[#tokens + 1] = operator
					operator = nil
				end
			end

			if(operator ~= nil) then
				if(term ~= "") then
					if(operator == "-" and #tokens > 0 and not lastOperator and tokens[#tokens] ~= "(") then
						-- allow dash to be used in terms like "some-item-name"
						tokens[#tokens] = tokens[#tokens] .. operator .. term
					else
						if(tokens[#tokens] == "(" and operator == "-") then
							-- the user tried to negate the first term inside the parentheses, so we replace it with the actual negate operator
							operator = "!"
						end

						if(OPERATORS[operator].numArguments == 1) then
							-- unary operators don't replace a binary operator
							if(not lastOperator and tokens[#tokens] ~= "(") then
								-- if we don't have an operator and are not at the beginning of a parentheses, we supply a space
								tokens[#tokens + 1] = " "
							else
								tokens[#tokens + 1] = lastOperator
							end
							tokens[#tokens + 1] = operator
							lastOperator = nil
						elseif(tokens[#tokens] == "(" and OPERATORS[operator].numArguments == 2) then
						-- binary operators at the beginning of parenthesis are ignored because they would cause the evaluation to fail
						else
							tokens[#tokens + 1] = operator
						end
						tokens[#tokens + 1] = term

						if(lastOperator and OPERATORS[lastOperator].numArguments == 2) then
							-- drop binary operator if there is another one already
							lastOperator = nil
						end
					end
				elseif(OPERATORS[operator].numArguments == 1) then
					-- if there is no term, we just push them
					tokens[#tokens + 1] = lastOperator
					tokens[#tokens + 1] = operator
					lastOperator = nil
				else
					-- we store the operator for later use
					lastOperator = operator
				end
			end
		end
	end

	if(inQuotes) then -- if the quotes didn't get closed, we do that now
		tokens[#tokens + 1] = lastOperator
		if(#quoteStack > 0) then
			quoteTerm = table.concat(quoteStack, "")
			if(quoteTerm ~= "") then
				tokens[#tokens + 1] = quoteTerm
			end
		end
	elseif(lastOperator == ")") then -- push it for completeness sake
		tokens[#tokens + 1] = lastOperator
	end

	if(tokens[1] == DEFAULT_OPERATOR) then
		table.remove(tokens, 1) -- the first token was just added to get the pattern to work correctly
	end

	if(lib.debug) then
		Log("result: %s", ArrayToString(tokens))
	end

	return tokens
end

function lib:Parse(tokens)
	local output, stack = {}, {}
	for i = 1, #tokens do
		local token = tokens[i]
		if(lib.debug) then
			Log("token: %s, output: %s, stack: %s", ValueToString(token), ArrayToString(output), ArrayToString(stack))
		end
		if(OPERATORS[token]) then
			local operator = OPERATORS[token]
			if(operator.isRightParenthesis) then
				while true do
					local popped = table.remove(stack)
					if(not popped or popped.isLeftParenthesis) then
						break
					else
						output[#output + 1] = popped
					end
				end
			elseif(operator.isLeftParenthesis) then
				stack[#stack + 1] = OPERATORS[token]
			elseif(#stack > 0) then
				local top = stack[#stack]
				if(lib.debug) then
					Log("top: %s (%s), operator: %s (%s) %s", ValueToString(top), tostring(top.precedence), ValueToString(operator), tostring(operator.precedence), tostring(operator.association))
				end
				if(top.precedence ~= nil
					and ((operator.association == LEFT_ASSOCIATIVE and operator.precedence <= top.precedence)
					or (operator.association == RIGHT_ASSOCIATIVE and operator.precedence < top.precedence))) then
					output[#output + 1] = table.remove(stack)
				end
				stack[#stack + 1] = OPERATORS[token]
			else
				stack[#stack + 1] = OPERATORS[token]
			end
		else
			output[#output + 1] = token
		end
	end
	while true do
		local popped = table.remove(stack)
		if(not popped) then
			break
		elseif(popped.isLeftParenthesis or popped.isRightParenthesis) then
		--ignore misplaced parentheses
		else
			output[#output + 1] = popped
		end
	end
	if(lib.debug) then
		Log("parsed: %s", ArrayToString(output))
	end
	return output
end

function lib:Evaluate(haystack, parsedTokens)
	local stack = {}
	for i = 1, #parsedTokens do
		local current = parsedTokens[i]
		if(type(current) == "table" and current.operation ~= nil) then
			if(#stack < current.numArguments and current.defaultArgument ~= nil) then
				-- synthesize an argument to prevent the operation from failing
				table.insert(stack, 1, current.defaultArgument)
			end
			if(#stack < current.numArguments) then
				if(lib.debug) then
					Log("Invalid argument count")
				end
				return false, lib.RESULT_INVALID_ARGUMENT_COUNT
			else
				local args = {}
				for j = 1, current.numArguments do
					args[#args + 1] = table.remove(stack)
				end
				stack[#stack + 1] = current.operation(haystack, unpack(args))
			end
		else
			stack[#stack + 1] = (type(current) == "string") and Sanitize(current) or current
		end
	end

	if(#stack == 1) then
		local result = stack[1]
		if(type(result) ~= "boolean") then
			-- if there is only one term and no operators, we just search it directly
			result = Convert(haystack, result)
		end
		return result, lib.RESULT_OK
	else
		if(lib.debug) then
			Log("Invalid value count")
		end
		return false, lib.RESULT_INVALID_VALUE_COUNT
	end
end

function lib:Filter(haystack, needle)
	if(#needle:gsub("[-*+?^$().[%]%% ]", "") == 0) then
		return false, lib.RESULT_INVALID_INPUT
	end

	local parsedTokens = lib:GetCachedTokens(needle)
	if(not parsedTokens) then
		parsedTokens = lib:Parse(lib:Tokenize(needle))
		lib:SetCachedTokens(needle, parsedTokens)
	end
	return lib:Evaluate(haystack, parsedTokens)
end

function lib:GetCachedTokens(needle)
	return lib.cache[needle]
end

function lib:SetCachedTokens(needle, parsedTokens)
	lib.cache[needle] = parsedTokens
end

function lib:ClearCachedTokens()
	lib.cache = {}
end
