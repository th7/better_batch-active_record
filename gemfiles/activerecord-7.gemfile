# frozen_string_literal: true

source 'https://rubygems.org'

gemspec path: '..'

# Use main development branch of Rails
gem 'rails'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
end

gem 'activerecord', '~> 7'
