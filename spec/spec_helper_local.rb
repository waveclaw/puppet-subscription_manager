# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  # Exclude bundled Gems in typical locations
  add_filter '/.vendor/'
  add_filter '/.bundle/'
end

RSpec.configure do |c|
  c.mock_with :rspec
  # c.pattern += ',spec/facter/**/*_spec.rb'
end
