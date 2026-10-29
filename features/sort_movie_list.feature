Feature: display list of movies sorted by different criteria

  As an avid moviegoer
  So that I can quickly browse movies based on my preferences
  I want to see movies sorted by title or release date

Background: movies have been added to database

  Given the following movies exist:
  | title                   | rating | release_date |
  | Aladdin                 | G      | 25-Nov-1992  |
  | The Terminator          | R      | 26-Oct-1984  |
  | When Harry Met Sally    | R      | 21-Jul-1989  |
  | The Help                | PG-13  | 10-Aug-2011  |
  | Chocolat                | PG-13  | 5-Jan-2001   |
  | Amelie                  | R      | 25-Apr-2001  |
  | 2001: A Space Odyssey   | G      | 6-Apr-1968   |
  | The Incredibles         | PG     | 5-Nov-2004   |
  | Raiders of the Lost Ark | PG     | 12-Jun-1981  |
  | Chicken Run             | G      | 21-Jun-2000  |

  And I am on the RottenPotatoes home page
  Then 10 seed movies should exist

Scenario: sort movies alphabetically
  When I select "Release date" from "sort_by"
  And I press "Refresh"
  And I select "Title" from "sort_by"
  And I press "Refresh"
  Then I should see all the movies
  And I should see "2001: A Space Odyssey" before "Aladdin" in the movie list
  And I should see "Aladdin" before "Amelie" in the movie list
  And I should see "Amelie" before "Chicken Run" in the movie list
  And I should see "Chicken Run" before "Chocolat" in the movie list
  And I should see "Chocolat" before "Raiders of the Lost Ark" in the movie list
  And I should see "Raiders of the Lost Ark" before "The Help" in the movie list
  And I should see "The Help" before "The Incredibles" in the movie list
  And I should see "The Incredibles" before "The Terminator" in the movie list
  And I should see "The Terminator" before "When Harry Met Sally" in the movie list

Scenario: sort movies in increasing order of release date
  When I select "Title" from "sort_by"
  And I press "Refresh"
  And I select "Release date" from "sort_by"
  And I press "Refresh"
  Then I should see all the movies
  And I should see "2001: A Space Odyssey" before "Raiders of the Lost Ark" in the movie list
  And I should see "Raiders of the Lost Ark" before "The Terminator" in the movie list
  And I should see "The Terminator" before "When Harry Met Sally" in the movie list
  And I should see "When Harry Met Sally" before "Aladdin" in the movie list
  And I should see "Aladdin" before "Chicken Run" in the movie list
  And I should see "Chicken Run" before "Chocolat" in the movie list
  And I should see "Chocolat" before "Amelie" in the movie list
  And I should see "Amelie" before "The Incredibles" in the movie list
  And I should see "The Incredibles" before "The Help" in the movie list
