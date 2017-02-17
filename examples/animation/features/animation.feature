Feature: go
  In order to avoid silly mistakes
  As a math idiot 
  I want to be told the sum of two numbers
	
	  Scenario: Animate game object
			Given the game object go is at position 400,400
			When I animate game object go position to 100,100 in 1 second
	    And I wait 1 seconds
	    Then the game object go should be at position 100,100
