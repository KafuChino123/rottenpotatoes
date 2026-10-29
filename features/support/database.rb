# frozen_string_literal: true

# Rails fixtures can persist between separate test commands.
BeforeAll do
  DatabaseCleaner.clean_with(:truncation)
end
