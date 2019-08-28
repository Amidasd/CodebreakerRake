# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

ruby '2.5.5'

group :default do
  gem 'gem_codebreaker_amidasd', '~> 0.2.0'
  gem 'i18n', '~> 1.6'
  gem 'pry'
  gem 'rack', '~> 2.0', '>= 2.0.7'
end

group :development do
  gem 'fasterer', '~> 0.5.1'
  gem 'rubocop', '~> 0.70.0'
  gem 'rubocop-performance', '~> 1.3'
end

group :test do
  gem 'rack-test', '~> 1.1'
  gem 'rspec', '~> 3.8'
  gem 'rubocop-rspec', '~> 1.33'
  gem 'simplecov', '~> 0.16.1'
end
