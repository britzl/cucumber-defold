# cucumber-defold
This project contains a Defold version of the [cucumber-lua](https://github.com/cucumber/cucumber-lua) project. The main change from the original project is that the networking part of the project has been separated from the wire protocol handler. The project also provides a bootstrap collection to simplify setup of cucumber in a new Defold project.

Cucumber for Defold can be used to run tests written using the [Gherkin syntax](https://github.com/cucumber/cucumber/wiki/Gherkin). Example:

	Feature: Life handling

		Scenario: Losing a life when failing a level
			Given I have 3 lives
			When I start level 42
			And I fail to complete the level
			Then I should have 2 lives

And the corresponding step definitions in Lua:

	require "cucumber.cucumber"

	Given("I have (%d*) lives", function(count)
		lives_manager.set(tonumber(count))
	end)

	When("I start level (%d*)", function(level)
		level_controller.play(tonumber(level))
	end)

	When("I fail to complete the level", function()
		level_controller.set_moves_left(0)
	end)

	Then("I should have (%d*) lives", function(count)
		assert(lives_manager.get() == tonumber(count))
	end)

The above snippet of code should be seen as a simplified example. Cucumber tests should run much in the same way as a user would be running the test. This means that user interaction should be simulated as much as possible and the game should be running with animations, transitions, loading and unloading of content and so on.

# Installation
You can use the Cucumber for Defold in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your game.project file and in the dependencies field under project add:

https://github.com/britzl/cucumber-defold/archive/master.zip

You will also need a Cucumber test runner that supports the [cucumber wire protocol](https://github.com/cucumber/cucumber/wiki/Wire-Protocol). The [Ruby version of cucumber](https://github.com/cucumber/cucumber-ruby) does this, but there are probably more. Example setup on OSX (refer to official documentation for detailed setup instructions):

	$ brew update
	$ brew install rbenv ruby-build

	# Hook rbenv into your shell. Put in .bashrc or similar:
	$ echo 'eval "$(rbenv init -)"' >> ~/.bashrc

	# Install Ruby using rbenv:
	$ rbenv install 2.2.0

	# Use the installed ruby version (global, local or shell options exist):
	$ rbenv local 2.2.0

# Usage
Follow this step by step guide to setup cucumber in your own project:

1. Create a collection to use as bootstrap collection when running cucumber tests.
2. Add the ```cucumber/cucumber.collection``` to the collection created in step #1.
3. Expand the added ```cucumber.collection``` in the project outline and point the ```go#testsproxy``` collection proxy to the collection containing the code you wish to test. This is typically your normal bootstrap collection used when running your game, but it could also be another collection containing only the parts your wish to test.
4. Add a game object to the collection created in step #1.
5. Create a script file and add it to the game object created in step #4.
6. In the script file add ```require "cucumber.cucumber"``` and also ```require()``` any Lua modules containing step definitions. Refer to the examples folder to see this in practice.

This is the minimum required setup to run cucumber tests in Defold. Refer to the examples folder for an actual setup made according to the above steps.

# Running cucumber tests
Start your application with the bootstrap collection. This will start the wire server and the application is now ready to receive instructions from the test runner over the socket using the wire protocol.

Launch your test runner. Minimal Ruby command line example:

	cucumber path/to/feature/files/

Wait for the tests to complete and review the results.

## A note on running asynchronous tests
Cucumber tests should run the same way as if a user would have performed the tests manually (to the extent it is reasonable). This means that animations and transitions should be played and content should be loaded and unloaded. To facilitate asynchronous step definitions Cucumber for Defold provides the ```cucumber/utils/wait.lua``` module that can be used to wait for asynchronous operations to finish, certain messages to be received and time to elapse. Some examples:

	wait.seconds(2.5)

	wait.until_message(function(message_id, message, sender)
		return message_id == hash("level_completed") and message.level == 42
	end)

	wait.until_true(function(dt)
		return go.get_position(id) == vmath.vector3(100, 100, 0)
	end)

## A note on tests manipulating game objects
Most tests need to interact with game objects and their components in different ways, for instance to check a game objects position. When it comes to calling the go.* functions Defold only allows interaction with game objects from the same collection. This immediately becomes a problem when running cucumber tests since each step of a test is executed from the cucumber bootstrap collection and not from the collection that is being tested.

This problem can be solved by passing a message to a script in the collection under test and run the code in the step definition once the message is received. To facilitate this there's a ```cucumber/automation/automation.go``` game object that can be added a collection that is tested and the ```cucumber/utils/wait.lua``` module has a ```wait.switch_context()``` function that can be called before interacting with game objects. The function will send a message to the ```automation.go``` game object and wait until the message is received before continuing to run the step.
