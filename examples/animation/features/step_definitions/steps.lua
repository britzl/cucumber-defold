local wait = require "cucumber.wait"

Before(function()
end)

After(function()
  print("I will be called after each scenario")
end)

Given("the game object (.*) is at position (%d*),(%d*)", function(url, x, y)
	go.set_position(vmath.vector3(x, y, 0), url)
end)

Given("I am animating game object (.*) position to (%d*),(%d*) in (%d*) seconds", function(url, x, y, duration)
	go.cancel_animations(url, "position")
	go.animate(url, "position", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(x, y, 0), go.EASING_LINEAR, duration)
end)

When("I wait (%d) seconds", function(seconds)
	print("wait seconds", seconds)
	wait.seconds(seconds)
end)

When("I animate game object (.*) position to (%d*),(%d*) in (%d*) second", function(url, x, y, duration)
	go.cancel_animations(url, "position")
	go.animate(url, "position", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(x, y, 0), go.EASING_LINEAR, duration)
	--wait.animate(url, "position", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(x, y, 0), go.EASING_LINEAR, duration, 0)
end)
When("I animate game object (.*) position to (%d*),(%d*) in (%d*) seconds", function(url, x, y, duration)
	go.cancel_animations(url, "position")
	go.animate(url, "position", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(x, y, 0), go.EASING_LINEAR, duration)
	--wait.animate(url, "position", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(x, y, 0), go.EASING_LINEAR, duration, 0)
end)

Then("the game object (.*) should be at position (%d*),(%d*)", function (url, x, y)
	assert(go.get_position(url) == vmath.vector3(x, y, 0), "Expected position")
end)
