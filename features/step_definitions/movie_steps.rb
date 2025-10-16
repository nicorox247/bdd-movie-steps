# features/step_definitions/movie_steps.rb
require 'set'
# Add a declarative step here for populating the DB with movies.

Given(/the following movies exist/) do |movies_table|
  movies_table.hashes.each do |movie|
    Movie.create!(movie)
  end
end

Then(/(.*) seed movies should exist/) do |n_seeds|
  expect(Movie.count).to eq n_seeds.to_i
end

# Make sure that one string (regexp) occurs before or after another one
#   on the same page

Then(/^I should see "(.*)" before "(.*)" in the movie list$/) do |e1, e2|
  # Restrict to the movies table if present; otherwise fall back to whole page
  html = if page.has_css?('table#movies')
           find('table#movies').text
         else
           page.body
         end
  re = /#{Regexp.escape(e1)}.*#{Regexp.escape(e2)}/m
  expect(html).to match(re)
end

# Make it easier to express checking or unchecking several boxes at once
#  "When I check the following ratings: PG, G, R"

When(/I check the following ratings: (.*)/) do |rating_list|
  rating_list.split(/\s*,\s*/).each do |rating|
    step %(I check "ratings_#{rating}")
  end
end

Then(/^I should (not )?see the following movies: (.*)$/) do |no, movie_list|
  titles = movie_list.split(/\s*,\s*/)
  titles.each do |title|
    if no
      step %(I should not see "#{title}")
    else
      step %(I should see "#{title}")
    end
  end
end

Then(/^I should see all the movies$/) do
  # Verify every movie title is visible
  Movie.pluck(:title).each { |title| expect(page).to have_content(title) }

  # If a table is present, also verify row count robustly
  if page.has_css?('table')
    rows =
      if page.has_css?('table#movies tbody tr')
        all('table#movies tbody tr').size
      elsif page.has_css?('table tbody tr')
        all('table tbody tr').size
      elsif page.has_css?('table#movies tr')
        [all('table#movies tr').size - 1, 0].max  # minus header
      else
        [all('table tr').size - 1, 0].max          # minus header
      end
    expect(rows).to eq(Movie.count)
  end
end



### Utility Steps Just for this assignment.

Then(/^debug$/) do
  require "byebug"
  byebug
  1 # intentionally force debugger context in this method
end

Then(/^debug javascript$/) do
  page.driver.debugger
  1
end




When(/^I uncheck the following ratings: (.*)$/) do |rating_list|
  rating_list.split(/\s*,\s*/).each { |r| step %(I uncheck "ratings_#{r}") }
end

When(/^I check only the following ratings: (.*)$/) do |rating_list|
  wanted = rating_list.split(/\s*,\s*/).to_set
  all = Movie.respond_to?(:all_ratings) ? Movie.all_ratings : %w[G PG PG-13 R NC-17]
  all.each do |r|
    if wanted.include?(r)
      step %(I check "ratings_#{r}")
    else
      step %(I uncheck "ratings_#{r}")
    end
  end
end

