Feature: go
	
	  Scenario: Animate game object
			Given the main:/go#animationproxy collection is loaded
			And the game object animation:/go is at position 400,400
			When I animate game object animation:/go position to 100,100 in 1 second
	    And I wait 2 seconds
	    Then the game object animation:/go should be at position 100,100
