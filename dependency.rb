# frozen_string_literal: true

# require './app/codebreaker'
require 'rack'
require 'bundler/setup'

Bundler.require(:default)

Dir[Dir.pwd + '/app/**/*.rb'].sort.reverse_each { |f| require f }

I18n.config.load_path << Dir[File.expand_path('./app/config/locales') + '/*.yml']
I18n.config.available_locales = :en
I18n.default_locale = :en
