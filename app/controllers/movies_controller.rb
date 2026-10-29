# frozen_string_literal: true

# Handles local movies and searches offered for import.
class MoviesController < ApplicationController
  before_action :set_movie, only: %i[show edit update destroy]

  def index
    @all_ratings = Movie.all_ratings
    @ratings_to_show = selected_ratings
    @sort_by = params[:sort_by].presence_in(%w[title release_date]) || session[:sort_by] || "title"
    session[:ratings] = @ratings_to_show
    session[:sort_by] = @sort_by
    @movies = Movie.with_ratings(@ratings_to_show, @sort_by)
  end

  def search_tmdb
    @movies = []
    return unless search_submitted?
    return search_error("Please fill in all required fields!") if params[:title].blank?

    @movies = Movie.find_in_tmdb(tmdb_params)
    search_error("No movies found with given parameters!") if @movies.empty?
  rescue Movie::TmdbError => e
    search_error(e.message)
  end

  def add_movie
    candidate = Movie.new(movie_params)
    @movie = Movie.find_or_create_by!(title: candidate.title, release_date: candidate.release_date) do |movie|
      movie.assign_attributes(movie_params)
    end
    redirect_to search_tmdb_path, flash: { success: "#{@movie.title} was successfully added to RottenPotatoes." }
  end

  # GET /movies/1 or /movies/1.json
  def show; end

  # GET /movies/new
  def new
    @movie = Movie.new
  end

  # GET /movies/1/edit
  def edit; end

  # POST /movies or /movies.json
  def create
    @movie = Movie.new(movie_params)

    respond_to do |format|
      if @movie.save
        format.html { redirect_to @movie, notice: "Movie was successfully created." }
        format.json { render :show, status: :created, location: @movie }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /movies/1 or /movies/1.json
  def update
    respond_to do |format|
      if @movie.update(movie_params)
        format.html { redirect_to @movie, notice: "Movie was successfully updated." }
        format.json { render :show, status: :ok, location: @movie }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /movies/1 or /movies/1.json
  def destroy
    @movie.destroy!

    respond_to do |format|
      format.html { redirect_to movies_path, status: :see_other, notice: "Movie was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def selected_ratings
    ratings = params[:ratings]
    ratings = ratings.keys if ratings.respond_to?(:keys)
    return session[:ratings] || @all_ratings if ratings.blank?

    Array(ratings).reject(&:blank?)
  end

  def search_submitted?
    params.key?(:title) || params.key?(:release_year) || params.key?(:language)
  end

  def tmdb_params
    params.permit(:title, :release_year, :language).to_h.symbolize_keys
  end

  def search_error(message)
    flash.now[:danger] = message
  end

  def set_movie
    @movie = Movie.find(params[:id])
  end

  def movie_params
    params.require(:movie).permit(:title, :rating, :description, :release_date)
  end
end
