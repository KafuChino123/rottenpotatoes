# frozen_string_literal: true

require "rails_helper"

RSpec.describe Movie, type: :model do
  describe ".find_in_tmdb" do
    let(:terms) { { title: "Manhunter", language: "all", release_year: "" } }
    let(:endpoint) { "https://api.themoviedb.org/3/search/movie" }
    let(:results) { JSON.parse(Rails.root.join("spec/fixtures/tmdb_movies.json").read).fetch("results") }
    def stub_tmdb_request
      stub_request(:get, endpoint).with(query: hash_including("api_key" => "test-key"))
    end

    before do
      stub_tmdb_request.to_return(status: 200, body: { results: results }.to_json)
    end

    def search(parameters = terms)
      described_class.find_in_tmdb(parameters, "test-key")
    end

    it "encodes the movie title and omits an empty release year" do
      search(terms.merge(title: "This Life + 10"))
      expect(a_request(:get, endpoint).with(query: {
                                              "api_key" => "test-key", "query" => "This Life + 10"
                                            })).to have_been_made.once
    end

    it "passes an optional release year to TMDb" do
      search(terms.merge(release_year: "1986"))
      expect(a_request(:get, endpoint).with(query: {
                                              "api_key" => "test-key", "query" => "Manhunter", "year" => "1986"
                                            })).to have_been_made.once
    end

    it "accepts string keys from form parameters" do
      expect(search(terms.stringify_keys).size).to eq(3)
    end

    it "returns unsaved movies with their title, overview, release date and rating" do
      movies = nil
      expect { movies = search }.not_to change(described_class, :count)
      expect(movies).to all(be_new_record)
      expect(movies.first.attributes).to include(
        "title" => "Manhunter", "description" => results.first.fetch("overview"), "rating" => "R"
      )
      expect(movies.first.release_date.to_date).to eq(Date.new(1986, 8, 14))
    end

    it "keeps all original languages when All Languages is selected" do
      expect(search.map(&:title)).to include("Le Film")
    end

    it "filters English Only by original language" do
      expect(search(terms.merge(language: "en")).map(&:title)).to eq(%w[Manhunter Manhunter])
    end

    it "excludes an existing movie while retaining a same-title movie from another date" do
      described_class.create!(title: "Manhunter", release_date: "1986-08-14", rating: "R")
      dates = search.select { |movie| movie.title == "Manhunter" }.map { |movie| movie.release_date.to_date }
      expect(dates).to eq([Date.new(2015, 6, 1)])
    end

    it "handles an unreleased movie without a release date" do
      stub_tmdb_request.to_return(status: 200, body: { results: [results.first.merge("release_date" => "")] }.to_json)
      expect(search.first.release_date).to be_nil
    end

    it "returns an empty collection when TMDb finds nothing" do
      stub_tmdb_request.to_return(status: 200, body: { results: [] }.to_json)
      expect(search).to eq([])
    end

    it "reports a missing API key before making an HTTP request" do
      expect { described_class.find_in_tmdb(terms, nil) }
        .to raise_error(Movie::TmdbError, /not configured/)
      expect(a_request(:get, endpoint)).not_to have_been_made
    end

    it "reports an invalid API key" do
      stub_tmdb_request.to_return(status: 401, body: '{"status_message":"Invalid API key"}')
      expect { search }.to raise_error(Movie::TmdbError, /API key/)
    end

    it "reports a service error instead of treating it as an empty result" do
      stub_tmdb_request.to_return(status: 503, body: "{}")
      expect { search }.to raise_error(Movie::TmdbError, /503/)
    end

    it "reports a timeout" do
      stub_tmdb_request.to_timeout
      expect { search }.to raise_error(Movie::TmdbError, /could not be reached/)
    end

    it "reports an invalid JSON response" do
      stub_tmdb_request.to_return(status: 200, body: "not JSON")
      expect { search }.to raise_error(Movie::TmdbError, /invalid response/)
    end
  end
end
