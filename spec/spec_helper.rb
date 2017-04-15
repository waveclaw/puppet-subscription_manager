# First line of spec/spec_helper.rb
require "simplecov"

SimpleCov.start do
  add_filter '/spec/'
  # Exclude bundled Gems in typical locations
  add_filter '/.vendor/'
  add_filter '/.bundle/'
end

require 'puppetlabs_spec_helper/module_spec_helper'
#require 'rspec-puppet-utils'
require 'rspec-puppet-facts'
include RspecPuppetFacts

RSpec.configure do |c|
    c.formatter = 'documentation'
    c.mock_with :rspec
end
