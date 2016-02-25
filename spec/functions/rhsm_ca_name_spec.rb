#!/usr/bin/ruby -S rspec

require 'spec_helper'
require 'facter/rhsm_ca_name'

expected_data = ''

raw_data =<<EOD
test
data
here
EOD

describe Facter::Util::Rhsm_ca_name, :type => :puppet_function do
  it "should return the expected data for valid input" do
  end
  it "should return nothing for invalid input" do
  end
  it "should return the nothing for no data" do
  end
end
