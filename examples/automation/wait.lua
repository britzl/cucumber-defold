local M = {}


local instances = {}

--- Wait until a function returns true when called
-- @param fn
function M.until_true(fn)
	local co = coroutine.running()
	assert(co, "You must call this function from within a coroutine")
	table.insert(instances, { co = co, update = true })
	local dt = 0
	while not fn(dt) do
		dt = coroutine.yield()
	end
end


function M.until_message(fn)
	local co = coroutine.running()
	assert(co, "You must call this function from within a coroutine")
	table.insert(instances, { co = co, message = true })
	local message_id, message, sender
	while not fn(message_id, message, sender) do
		message_id, message, sender = coroutine.yield()
	end
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

function M.load_proxy(url)
	url = msg.url(url)
	msg.post(url, "load")
	M.until_message(function(message_id, message, sender)
		return message_id == hash("proxy_loaded") and sender == url
	end)
	msg.post(url, "enable")
end

function M.unload_proxy(url)
	url = msg.url(url)
	msg.post(url, "disable")
	msg.post(url, "final")
	msg.post(url, "unload")
	M.until_message(function(message_id, message, sender)
		return message_id == hash("proxy_unloaded") and sender == url
	end)
end


function M.switch_context(url)
	url = msg.url(url)
	url = msg.url(url.socket, hash("/cucumber"), "script")
	msg.post(url, "switch_cucumber_context")
	M.until_message(function(message_id, message, sender)
		return message_id == hash("switch_cucumber_context")
	end)
end

function M.animate(url, property, playback, to, easing, duration, delay)
	local done = false
	M.switch_context(url)
	go.cancel_animations(url, property)
	go.animate(url, property, playback, to, easing, duration, delay, function()
		done = true
	end)
	M.until_true(function()
		return done
	end)
end

function M.update(dt)
	for k,v in pairs(instances) do
		if coroutine.status(v.co) == "dead" then
			instances[k] = nil
		elseif v.update then
			coroutine.resume(v.co, dt)
		end
	end
end

function M.on_message(message_id, message, sender)
	for k,v in pairs(instances) do
		if coroutine.status(v.co) == "dead" then
			instances[k] = nil
		elseif v.message then
			coroutine.resume(v.co, message_id, message, sender)
		end
	end
end


return setmetatable(M, { __call = function(self, fn)
	M.until_true(fn)
end })