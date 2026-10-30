# frozen_string_literal: true

Given(/^the following movies exist:$/) do |movies_table|
  movies_table.hashes.each do |movie|
    Movie.create!(movie)
  end
end

Then(/^(\d+) seed movies should exist$/) do |n_seeds|
  expect(Movie.count).to eq n_seeds.to_i
end

Then(/^I should see "([^"]*)" before "([^"]*)" in the movie list$/) do |first_movie, second_movie|
  titles = all("#movies tbody tr > td:first-child").map do |title|
    title.text.strip
  end

  expect(titles).to include(first_movie, second_movie)
  expect(titles.index(first_movie)).to be < titles.index(second_movie)
end

When(/^I check the following ratings: (.*)$/) do |rating_list|
  rating_list.split(",").each { |rating| check(rating.strip) }
end

Then(/^I should (not )?see the following movies: (.*)$/) do |negated, movie_list|
  within("#movies") do
    movie_list.split(",").each do |title|
      if negated
        expect(page).to have_no_content(title.strip)
      else
        expect(page).to have_content(title.strip)
      end
    end
  end
end

Then(/^I should see all the movies$/) do
  movie_ids = all("#movies tbody tr[id^='movie_']").map { |movie| movie[:id] }
  expect(movie_ids).to match_array(Movie.ids.map { |id| "movie_#{id}" })
end

# Utility steps supplied with the assignment.

Then(/^debug$/) do
  require "debug"
  binding.break # rubocop:disable Lint/Debugger -- This step explicitly requests an interactive debugging session.
end

Then(/^debug javascript$/) do
  # This utility is only used with a driver that supports JavaScript debugging.
  page.driver.debugger
end

Then(/complete the rest of of this scenario/) do
  raise "Remove this step from your .feature files"
end
