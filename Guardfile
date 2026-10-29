# frozen_string_literal: true

guard :rspec, cmd: "bundle exec rspec" do
  watch(%r{^spec/.*_spec\.rb$})
  watch(%r{^app/(models|controllers)/(.+)\.rb$}) { |match| "spec/#{match[1]}/#{match[2]}_spec.rb" }
  watch(%r{^app/views/}) { "spec/features" }
  watch(%r{^(config/routes\.rb|spec/rails_helper\.rb|spec/fixtures/)}) { "spec" }
end
