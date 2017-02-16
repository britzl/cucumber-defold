local M = {
	step_definitions = {},
	before_hooks = {},
	after_hooks = {},
	before_step_hooks = {},
	after_step_hooks = {},
	pending_message = "PENDING"
}

local World = {}
local Pending = function(message)
	M.pending_message = message
	error("M:Pending")
end

function M.step_matches(args)
	local text = args["name_to_match"]
	local matches = {}
	for pattern,func in pairs(M.step_definitions) do
		if type(func) == "function" and string.match(text, pattern) then
			table.insert(matches, M.StepMatch(text, pattern))
		end
	end
	return { "success", matches }
end
	
function M.begin_scenario(_)
	_G["World"] = {}
	for _,hook in ipairs(M.before_hooks) do
		local ok, err = pcall(hook)
		if not ok then
				return { "fail", { message = err, exception = err } }
		end
	end
	return { "success" }
end

function M.end_scenario(_)
	for _,hook in ipairs(M.after_hooks) do
		local ok, err = pcall(hook)
		if not ok then
				return { "fail", { message = err, exception = err } }
		end
	end
	return { "success" }
end

function M.invoke(args)
	for _,hook in ipairs(M.before_step_hooks) do
		local ok, err = pcall(hook)
		if not ok then
			return { "fail", { message = err, exception = err } }
		end
	end

	local func = M.step_definitions[args["id"]]
	local ok, err = pcall(func, unpack(args["args"]))
	if not ok then
		if (err:match("M:Pending")) then
			return { "pending", M.pending_message }
		else
			return { "fail", { message = err, exception = err } }
		end
	end

	for _,hook in ipairs(M.after_step_hooks) do
			local ok, err = pcall(hook)
			if not ok then
					return { "fail", { message = err, exception = err } }
			end
	end
	return { "success" }
end

function M.ReloadSteps()
	M.step_definitions = {}
	dofile("./features/step_definitions/steps.lua")
end
	
function M.snippet_text (args)
	return { "success", args["step_keyword"] .. "(\"" .. args["step_name"] .. "\", function ()\n\nend)" }
end

function M.FindArgs(str, pattern)
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

function M.StepMatch(text, pattern)
	return {
		id = pattern,
		args = M.FindArgs(text, pattern),
		source = pattern,
		regexp = pattern
	}
end

function M.RespondToWireRequest (request)
	local command = request[1]
	local args = request[2]
	local response = { "success" }
	if M[command] then
		response = M[command](args)
	end
	return response
end

local DefineStep = function(text, fn)
	M.step_definitions[text] = fn
end

local Before = function(func)
	table.insert(M.before_hooks, func)
end

local After = function(func)
	table.insert(M.after_hooks, func)
end

local BeforeStep = function(func)
		table.insert(M.before_step_hooks, func)
end

local AfterStep = function(func)
		table.insert(M.after_step_hooks, func)
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