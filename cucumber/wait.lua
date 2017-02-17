local M = {}


local instances = {}

function M.until_true(fn)
	print("until_true", fn)
	local co = coroutine.running()
	assert(co)
	table.insert(instances, co)
	local dt = 0
	while not fn(dt) do
		dt = coroutine.yield()
		print(dt)
	end
	print("DONE")
end

function M.seconds(seconds)
	M.until_true(function(dt)
		seconds = seconds - dt
		return seconds <= 0
	end)
end

function M.animate(url, property, playback, to, easing, duration, delay)
	local done = false
	go.cancel_animations(url, property)
	go.animate(url, property, playback, to, easing, duration, delay, function()
		done = true
	end)
	M.until_true(function()
		return done
	end)
end

function M.update(dt)
	for k,co in pairs(instances) do
		if coroutine.status(co) == "dead" then
			instances[k] = nil
		else
			coroutine.resume(co, dt)
		end
	end
end


return setmetatable(M, { __call = function(self, fn)
	M.until_true(fn)
end })