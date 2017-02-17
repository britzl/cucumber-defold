--- The code in this module comes from the cucumber-lua project
-- https://github.com/cucumber/cucumber-lua
--
-- The largest modification that has been made is that the networking part
-- has been moved to a separate module to make it easier to change the
-- network implementation without having to duplicate or even care about the
-- code that handles the wire protocol requests.

local M = {}


local step_definitions = {}
local before_hooks = {}
local after_hooks = {}
local before_step_hooks = {}
local after_step_hooks = {}

local pending_message = "PENDING"


local World = {}

local function find_args(str, pattern)
	local patternWithPositions = string.gsub(pattern, "%(", "()(")
	local matches = { string.find(str, patternWithPositions) }
	local args = {}
	for i = 3, #matches, 2 do
		table.insert(args, {
			["pos"] = matches[i] - 1,
			["val"] = matches[i + 1]
		})
	end
	return args
end

local function step_match(text, pattern)
	return {
		id = pattern,
		args = find_args(text, pattern),
		source = pattern,
		regexp = pattern
	}
end

--- Get a list of steps that matches a specific name
-- @params name_to_match
-- @return Wire response
local function step_matches(name_to_match)
	local matches = {}
	for pattern,func in pairs(step_definitions) do
		if type(func) == "function" and string.match(name_to_match, pattern) then
			table.insert(matches, step_match(name_to_match, pattern))
		end
	end
	return { "success", matches }
end


--- Begin a new scenario
-- This will invoke any before hooks
-- @return Wire response
local function begin_scenario()
	print("begin_scenario")
	_G["World"] = {}
	for _,hook in ipairs(before_hooks) do
		local ok, err = pcall(hook)
		if not ok then
			return { "fail", { message = err, exception = err } }
		end
	end
	return { "success" }
end

--- End the current scenario
-- This will invoke and after hooks
-- @return Wire response
local function end_scenario()
	for _,hook in ipairs(after_hooks) do
		local ok, err = pcall(hook)
		if not ok then
			return { "fail", { message = err, exception = err } }
		end
	end
	return { "success" }
end

--- Invoke a step
-- Before step hooks will be called before the step
-- After step hooks will be called after the step
-- @param args
-- @return Wire response
local function invoke(args)
	for _,hook in ipairs(before_step_hooks) do
		local ok, err = pcall(hook)
		if not ok then
			return { "fail", { message = err, exception = err } }
		end
	end

	local func = step_definitions[args["id"]]
	local ok, err = pcall(func, unpack(args["args"]))
	if not ok then
		if (err:match("M:Pending")) then
			return { "pending", pending_message }
		else
			return { "fail", { message = err, exception = err } }
		end
	end

	for _,hook in ipairs(after_step_hooks) do
		local ok, err = pcall(hook)
		if not ok then
			return { "fail", { message = err, exception = err } }
		end
	end
	return { "success" }
end

--- Get text for missing step
-- @param step_keyword
-- @param step_name
-- @return Text
local function snippet_text(step_keyword, step_name)
	return { "success", step_keyword .. "(\"" .. step_name .. "\", function ()\n\nend)" }
end


function M.respond_to_wire_request(request)
	local command = request[1]
	local args = request[2]
	local response

	if command == "step_matches" then
		response = step_matches(args.name_to_match)
	elseif command == "invoke" then
		response = invoke(args)
	elseif command == "begin_scenario" then
		response = begin_scenario(args)
	elseif command == "end_scenario" then
		response = end_scenario(args)
	elseif command == "snippet_text" then
		response = snippet_text(args.step_keyword, args.step_name)
	else
		print("Unknown command", command)
		response = { "fail", { message = "Unknown command" }}
	end
	return response
end


local function Pending(message)
	pending_message = message
	error("M:Pending")
end

local function DefineStep(text, fn)
	step_definitions[text] = fn
end

local function Before(func)
	table.insert(before_hooks, func)
end

local function After(func)
	table.insert(after_hooks, func)
end

local function BeforeStep(func)
	table.insert(before_step_hooks, func)
end

local function AfterStep(func)
	table.insert(after_step_hooks, func)
end

_G["Given"]		= DefineStep
_G["When"]		 = DefineStep
_G["Then"]		 = DefineStep
_G["Before"]	 = Before
_G["After"]		= After
_G["World"]		= World
_G["Pending"]	= Pending
_G["BeforeStep"]	= BeforeStep
_G["AfterStep"]	 = AfterStep

return M