# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searching and adding TMDb movies", type: :feature do
  let(:endpoint) { "https://api.themoviedb.org/3/search/movie" }
  let(:body) { Rails.root.join("spec/fixtures/tmdb_movies.json").read }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("TMDB_API_KEY", nil).and_return("test-key")
    stub_request(:get, endpoint)
      .with(query: hash_including("api_key" => "test-key"))
      .to_return(status: 200, body: body)
  end

  it "searches, adds a result, displays it on the home page and filters it from a later search" do
    visit movies_path
    click_link "Search TMDb"
    expect(page).to have_css("form#tmdb_form")
    expect(page).to have_no_css("table#search_movies")
    fill_in "Movie Name", with: "Manhunter"
    click_button "Search"

    expect(page).to have_css("#search_movies tbody tr", count: 3)
    expect(page).to have_field("Movie Name", with: "Manhunter")
    expect(Movie.count).to eq(0)

    expect do
      within(first("#search_movies tbody tr")) { click_button "Add movie" }
    end.to change(Movie, :count).by(1)
    expect(page).to have_content("Manhunter was successfully added to RottenPotatoes.")
    expect(page).to have_no_css("table#search_movies")

    click_link "Back to movies"
    within("#movies") do
      expect(page).to have_content("Manhunter")
      expect(page).to have_content("R")
    end

    click_link "Search TMDb"
    fill_in "Movie Name", with: "Manhunter"
    click_button "Search"
    expect(page).to have_css("#search_movies tbody tr", count: 2)
    expect(page).to have_no_css("#search_movies tbody tr", text: "1986-08-14")
    expect(page).to have_css("#search_movies tbody tr", text: "2015-06-01")
  end

  it "shows only English-language movies when English Only is selected" do
    visit search_tmdb_path
    fill_in "Movie Name", with: "Manhunter"
    choose "English Only"
    click_button "Search"
    expect(page).to have_css("#search_movies tbody tr", count: 2)
    expect(page).to have_no_content("Le Film")
  end

  it "reports a blank title without displaying a results table" do
    visit search_tmdb_path
    click_button "Search"
    expect(page).to have_content("Please fill in all required fields!")
    expect(page).to have_no_css("table#search_movies")
    expect(a_request(:get, endpoint)).not_to have_been_made
  end

  it "reports no matches without displaying a results table" do
    stub_request(:get, endpoint).with(query: hash_including("api_key" => "test-key"))
                                .to_return(status: 200, body: '{"results":[]}')
    visit search_tmdb_path
    fill_in "Movie Name", with: "Nothing"
    click_button "Search"
    expect(page).to have_content("No movies found with given parameters!")
    expect(page).to have_no_css("table#search_movies")
  end
end
