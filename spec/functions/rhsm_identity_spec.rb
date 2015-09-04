#!/usr/bin/ruby -S rspec

require 'spec_helper'
require 'facter/rhsm_identity'

expected_data = '12345678-1234-1234-1234-0123456789ab'

raw_data =<<EOD
junk
Current identity is: 12345678-1234-1234-1234-0123456789ab/
junk
EOD

describe Facter::Util::Rhsm_identity, :type => :puppet_function do
  it "should return the expected data" do
    expect(Facter::Util::Resolution).to receive(:exec).
      with("subscription_manager identity") { raw_data }
    expect(Facter::Util::Rhsm_identity.identity).to eq(expected_data)
  end
  it "should return the nothing for no data" do
    expect(Facter::Util::Resolution).to receive(:exec).
      with("subscription_manager identity") { '' }
    expect(Facter::Util::Rhsm_identity.identity).to eq(nil)
  end
  it "should return the nothing for no command" do
    expect(Facter::Util::Resolution).to receive(:exec).
      with("subscription_manager identity") { throw Error }
    expect(Facter::Util::Rhsm_identity.identity).to eq(nil)
  end
end
