# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  # Exclude bundled Gems in typical locations
  add_filter '/.vendor/'
  add_filter '/.bundle/'
end


ARGV.clear

require 'puppet'
require 'facter'
require 'mocha'
gem 'rspec', '>=2.0.0'
require 'rspec/expectations'

require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |config|
  # FIXME REVISIT - We may want to delegate to Facter like we do in
  # Puppet::PuppetSpecInitializer.initialize_via_testhelper(config) because
  # this behavior is a duplication of the spec_helper in Facter.
  config.before :each do
    # Ensure that we don't accidentally cache facts and environment between
    # test cases.  This requires each example group to explicitly load the
    # facts being exercised with something like
    # Facter.collection.loader.load(:ipaddress)
    # Facter::Util::Loader.any_instance.stubs(:load_all) # removed in 3
    Facter.clear
    #Facter.clear_messages # removed in facter 3
  end
  # config.pattern += ',spec/facter/**/*_spec.rb'
  config.mock_with :rspec
end
