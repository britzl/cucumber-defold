local wait = require "examples.automation.wait"

Given("the (.*) collection is loaded", function(proxy_url)
	wait.load_proxy(proxy_url)
end)

Given("the game object (.*) is at position (%d*),(%d*)", function(url, x, y)
	wait.switch_context(url)
	go.set_position(vmath.vector3(x, y, 0), url)
end)

When("I wait (%d) seconds", function(seconds)
	wait.seconds(tonumber(seconds))
end)
When("I wait (%d) second$", function(seconds)
	wait.seconds(tonumber(seconds))
end)

When("I animate game object (.*) position to (%d*),(%d*) in (%d*) second", function(url, x, y, duration)
	wait.switch_context(url)
	go.cancel_animations(url, "position")
	go.animate(url, "position", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(x, y, 0), go.EASING_LINEAR, duration)
end)

Then("the game object (.*) should be at position (%d*),(%d*)", function (url, x, y)
	wait.switch_context(url)
	assert(go.get_position(url) == vmath.vector3(x, y, 0), "Expected position")
end)
