# frozen_string_literal: true

# Stores local movies and builds unsaved records from TMDb search results.
class Movie < ApplicationRecord
  # A TMDb search failed before usable results were returned.
  class TmdbError < StandardError; end

  class << self
    def all_ratings
      %w[G PG PG-13 R]
    end

    def with_ratings(ratings, sort_by)
      if ratings.nil?
        all.order sort_by
      else
        where(rating: ratings.map(&:upcase)).order sort_by
      end
    end

    def find_in_tmdb(search_terms, api_key = ENV.fetch("TMDB_API_KEY", nil))
      raise TmdbError, "TMDB_API_KEY is not configured." if api_key.blank?

      terms = search_terms.to_h.symbolize_keys
      results = request_tmdb(terms, api_key)
      results = results.select { |movie| movie.fetch("original_language") == "en" } if terms[:language] == "en"
      unsaved_movies(results)
    end

    private

    def request_tmdb(terms, api_key)
      response = Faraday.get("https://api.themoviedb.org/3/search/movie", tmdb_query(terms, api_key)) do |request|
        request.options.open_timeout = 5
        request.options.timeout = 10
      end
      check_tmdb_response(response)
      parse_tmdb_response(response.body)
    rescue Faraday::Error
      raise TmdbError, "TMDb could not be reached. Please try again."
    end

    def tmdb_query(terms, api_key)
      query = { api_key: api_key, query: terms.fetch(:title).strip }
      query[:year] = terms[:release_year] if terms[:release_year].present?
      query
    end

    def check_tmdb_response(response)
      raise TmdbError, "TMDb rejected the API key." if response.status == 401
      return if response.success?

      raise TmdbError, "TMDb search failed (HTTP #{response.status}). Please try again."
    end

    def parse_tmdb_response(body)
      JSON.parse(body).fetch("results")
    rescue JSON::ParserError, KeyError
      raise TmdbError, "TMDb returned an invalid response. Please try again."
    end

    def unsaved_movies(results)
      movies = results.map { |result| new(tmdb_attributes(result)) }
      saved = where(title: movies.map(&:title)).pluck(:title, :release_date)
                                               .to_set { |title, date| [title, date&.to_date] }
      movies.reject { |movie| saved.include?([movie.title, movie.release_date&.to_date]) }
    end

    def tmdb_attributes(result)
      {
        title: result.fetch("title"), description: result.fetch("overview"),
        release_date: result["release_date"].presence, rating: "R"
      }
    end
  end
end
