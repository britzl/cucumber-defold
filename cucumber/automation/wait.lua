--- This module will simplify automation of many common tasks such
-- as waiting for various asynchronous operations to finish.
-- All functions expect to be run inside a coroutine (this is what
-- cucumber already does in the wire server).
-- To use this module you need to make sure to call update() and
-- on_message().

local M = {}

-- stack of things we're waiting for
-- the top-most instance will be checked
local instance_stack = {}

local sequence_count = 0

local automation_scripts = {}

local function create_instance(timeout)
	local co = coroutine.running()
	assert(co, "You must call this function from within a coroutine")
	sequence_count = sequence_count + 1

	local instance = {
		id = sequence_count,
		co = co,
		timeout = socket.gettime() + timeout,
	}
	function instance.update(fn)
		instance.update_fn = true
		local dt = 0
		while not fn(dt) do
			dt = coroutine.yield()
		end
	end
	function instance.on_message(fn)
		instance.on_message_fn = true
		local message_id, message, sender
		while not fn(message_id, message, sender) do
			message_id, message, sender = coroutine.yield()
		end
	end
	
	table.insert(instance_stack, instance)
	return instance
end


local function remove_instance(instance)
	for k,v in pairs(instance_stack) do
		if v.id == instance.id then
			instance_stack[k] = nil
			return
		end
	end
end

--- Register an automation script
-- This will be done automatically by the automation.script
-- Required to be able to call switch_context to ensure that
-- certain steps are run in the correct collection
-- @param Optional url to register. Defaults to msg.url()
function M.register_automation_script(url)
	url = url or msg.url()
	automation_scripts[url.socket] = url
end

--- Wait until a function invokes a callback
-- @param fn Function that must accept a callback as first argument
-- @param timeout Optional timeout in seconds
function M.until_callback(fn, timeout)
	local instance = create_instance(timeout or 10)

	local yielded = false
	local done = false
	fn(function()
		done = true
		if yielded then
			coroutine.resume(instance.co)
		end
	end)
	if not done then
		yielded = true
		coroutine.yield()
	end
	
	remove_instance(instance)
end

--- Wait until a function returns true when called
-- @param fn Function that must return true, will receive dt as its only argument
-- @param timeout Optional timeout in seconds
function M.until_true(fn, timeout)
	local instance = create_instance(timeout or 10)
	instance.update(function(dt)
		if fn(dt) then
			return true
		end
	end)
	remove_instance(instance)
end

--- Wait until a message is received
-- @param fn Function that will receive message and return true if message is the correct one
-- @param timeout Optional timeout in seconds
function M.until_message(fn, timeout)
	local instance = create_instance(timeout or 10)
	instance.on_message(function(message_id, message, sender)
		if fn(message_id, message, sender) then
			return true
		end
	end)
	remove_instance(instance)
end

--- Wait until a certain number of seconds have elapsed
-- @param seconds Seconds to wait
function M.seconds(seconds)
	assert(seconds and seconds >= 0, "You must provide a positive number of seconds to wait")
	M.until_true(function(dt)
		seconds = seconds - dt
		return seconds <= 0
	end)
end

--- Wait a single frame
function M.one_frame()
	M.until_true(function(dt)
		return true
	end)
end

--- Load a collection proxy and wait until it is loaded
function M.load_proxy(url)
	url = msg.url(url)
	msg.post(url, "load")
	M.until_message(function(message_id, message, sender)
		return message_id == hash("proxy_loaded") and sender == url
	end)
	msg.post(url, "enable")
end

--- Unload a collection proxy and wait until it is unloaded
function M.unload_proxy(url)
	url = msg.url(url)
	msg.post(url, "disable")
	msg.post(url, "final")
	msg.post(url, "unload")
	M.until_message(function(message_id, message, sender)
		return message_id == hash("proxy_unloaded") and sender == url
	end)
end

--- Post a message to the specified URL and wait for an answer
-- Requires the automation.script somewhere in the collection
-- This is needed for some tests where game objects and components
-- need to be manipulated (you cannot call go.* functions from a script
-- outside the collection where the game object resides)
-- @param url
function M.switch_context(url)
	url = msg.url(url)
	local automation_script_url = automation_scripts[url.socket]
	assert(automation_script_url, ("No automation script registered for %s"):format(tostring(url)))
	msg.post(automation_script_url, "switch_cucumber_context")
	M.until_message(function(message_id, message, sender)
		return message_id == hash("switch_cucumber_context")
	end)
end

--- Update the current instance if it's waiting for an update.
-- If the instance is dead it will be removed and the next
-- instance in the stack will be updated instead.
function M.update(dt)
	for i=#instance_stack,1,-1 do
		local instance = instance_stack[i]
		if coroutine.status(instance.co) == "dead" then
			instance_stack[i] = nil
		else
			if instance.timeout and socket.gettime() > instance.timeout then
				instance_stack[i] = nil
			elseif instance.update_fn then
				local ok, err = coroutine.resume(instance.co, dt)
				if not ok then
					print(err)
					instance_stack[i] = nil
				end
			end
			return
		end
	end
end

--- Pass a message to the current instance if it's waiting
-- for a message. If the instance is dead it's removed
-- and the next one in the stack will be checked instead.
function M.on_message(message_id, message, sender)
	for i=#instance_stack,1,-1 do
		local instance = instance_stack[i]
		if coroutine.status(instance.co) == "dead" then
			instance_stack[i] = nil
		else
			if instance.on_message_fn then
				local ok, err = coroutine.resume(instance.co, message_id, message, sender)
				if not ok then
					print(err)
					instance_stack[i] = nil
				end
			end
			return
		end
	end
end


return M
