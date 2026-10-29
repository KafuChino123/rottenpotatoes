# frozen_string_literal: true

require "rails_helper"

RSpec.describe MoviesController, type: :controller do
  describe "searching TMDb" do
    let(:terms) { { title: "Manhunter", release_year: "1986", language: "en" } }
    let(:fake_results) { [instance_double(Movie), instance_double(Movie)] }

    it "calls the model with the submitted search parameters" do
      expect(Movie).to receive(:find_in_tmdb).with(terms).and_return(fake_results)
      get :search_tmdb, params: terms
    end

    context "after a valid search" do
      before do
        allow(Movie).to receive(:find_in_tmdb).and_return(fake_results)
        get :search_tmdb, params: terms
      end

      it "renders the search results template" do
        expect(response).to render_template("search_tmdb")
      end

      it "makes the results available to the view" do
        expect(assigns(:movies)).to eq(fake_results)
      end
    end

    it "opens an empty search page without calling TMDb" do
      expect(Movie).not_to receive(:find_in_tmdb)
      get :search_tmdb
      expect(flash[:danger]).to be_nil
    end

    it "rejects a blank submitted title without calling TMDb" do
      expect(Movie).not_to receive(:find_in_tmdb)
      get :search_tmdb, params: terms.merge(title: "   ")
      expect(flash[:danger]).to eq("Please fill in all required fields!")
    end

    it "allows a missing release year" do
      expect(Movie).to receive(:find_in_tmdb).with({ title: "Manhunter", language: "all" }).and_return([])
      get :search_tmdb, params: { title: "Manhunter", language: "all" }
      expect(flash[:danger]).to eq("No movies found with given parameters!")
    end

    it "displays a model error without disguising it as no matches" do
      allow(Movie).to receive(:find_in_tmdb).and_raise(Movie::TmdbError, "TMDb rejected the API key.")
      get :search_tmdb, params: terms
      expect(flash[:danger]).to eq("TMDb rejected the API key.")
      expect(assigns(:movies)).to eq([])
    end
  end

  describe "adding a movie" do
    let(:attributes) do
      { title: "Manhunter", release_date: "1986-08-14", description: "An investigator.", rating: "R" }
    end

    it "saves the submitted movie and redirects to search with confirmation" do
      expect { post :add_movie, params: { movie: attributes } }.to change(Movie, :count).by(1)
      expect(response).to redirect_to(search_tmdb_path)
      expect(flash[:success]).to eq("Manhunter was successfully added to RottenPotatoes.")
      expect(Movie.last).to have_attributes(title: "Manhunter", rating: "R", description: "An investigator.")
    end

    it "does not add the same movie twice when the form is resubmitted" do
      post :add_movie, params: { movie: attributes }
      expect { post :add_movie, params: { movie: attributes } }.not_to change(Movie, :count)
    end
  end
end
