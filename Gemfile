source "https://rubygems.org"

# Use main development branch of Rails
gem "rails", github: "rails/rails", branch: "main"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem 'rspec-rails'
end


gem 'better_batch-active_record', path: '../better_batch-active_record'
