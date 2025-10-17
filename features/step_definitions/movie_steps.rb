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

# Order check: e.g., Then I should see "Aladdin" before "Amelie"
Then(/^I should see "(.*?)" before "(.*?)"(?: in the movie list)?$/) do |first, second|
  scope_text =
    if page.has_css?('table#movies')
      find('table#movies').text
    else
      page.body
    end

  i1 = scope_text.index(first)
  i2 = scope_text.index(second)

  expect(i1).not_to be_nil,  %Q{Expected to find "#{first}" on the page, but didn't.}
  expect(i2).not_to be_nil,  %Q{Expected to find "#{second}" on the page, but didn't.}
  expect(i1).to be < i2,     %Q{Expected "#{first}" to appear before "#{second}", but it did not.}
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

