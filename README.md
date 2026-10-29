# RottenPotatoes

Movie browsing with remembered rating filters and sorting (CHIP 7.7), plus TMDb
search and import driven by RSpec tests (CHIP 8.5).

## Run

Requires Docker. Copy `.env.example` to `.env` and set your own `TMDB_API_KEY`.
The key is optional for automated tests; real searches require it.

```sh
docker build -t rottenpotatoes .
docker run --rm -it -v "$PWD:/app" -p 3000:3000 --env-file .env rottenpotatoes
```

Inside the container:

```sh
bundle install
bundle exec rails db:prepare
bundle exec rails db:seed
bundle exec rails server -b 0.0.0.0
```

Open `http://localhost:3000`, follow **Search TMDb**, enter a title, optionally
enter a release year, and choose **All Languages** or **English Only**. Search
results remain unsaved until **Add movie** is clicked. Existing movies are
matched by title and release date; different releases with the same title remain
available. English filtering uses TMDb's `original_language`, rather than the
language of translated metadata. Ratings default to `R` for imported movies.

## Verify

Run inside the container:

```sh
bundle exec rspec --require spec_helper
bundle exec rails test
bundle exec cucumber --strict
bundle exec rubocop Gemfile Guardfile app/controllers/movies_controller.rb app/models/movie.rb config/routes.rb spec features/step_definitions/movie_steps.rb features/support/database.rb
```

RSpec covers controller collaboration, API errors, query encoding, language and
duplicate filtering, and the full search/import flow. WebMock blocks real HTTP
requests during specs. The standard `spec_helper` entry point is supported,
and `tzinfo-data` supplies timezone data on Linux grading images. Both acceptance-test
suites clear the test database before starting so Rails fixtures cannot leak between test commands.

Use `bundle exec guard` to rerun specs on changes, or use `bundle exec rubocop -a`
with the paths above to format Ruby changes. JSON stays on 2.x and Minitest on 5.x
for Rails 7.1 compatibility.

## Deploy and submit

The `Procfile` runs migrations during release and starts Puma. Configure
`DATABASE_URL` for PostgreSQL, `SECRET_KEY_BASE`, and `TMDB_API_KEY` on the host.
Never commit `.env` or a real API key. Seed the deployed database with
`bundle exec rails db:seed`, then verify search and import on the live app.

After deployment, create `rottenpotatoes-url.txt` at the repository root containing
only the verified HTTPS application URL, commit it, and submit the relevant branch
to Gradescope. Its autograder adds movies to the deployed database, which can
affect subsequent submissions.

Assignment: [CHIP 8.5](https://github.com/NYU-CSE-Software-Engineering/hw-rspec-rails-intro).
