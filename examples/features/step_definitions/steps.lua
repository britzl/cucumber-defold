require "examples.calculator.steps"
require "examples.animation.steps"
local wait = require "examples.automation.wait"

Before(function()
	wait.load_proxy("#mainproxy")
end)

After(function()
	wait.unload_proxy("#mainproxy")
end)
