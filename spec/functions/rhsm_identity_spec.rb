#!/usr/bin/ruby -S rspec
#
#  Test the rhsm_identity fact
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'facter/rhsm_identity'

expected_data = '12345678-1234-1234-1234-0123456789ab'

raw_data1 =<<EOD
junk
Current identity is: 12345678-1234-1234-1234-0123456789ab
junk
EOD

raw_data2 =<<EOD
system identity: 12345678-1234-1234-1234-0123456789ab
name: abcd
org name: DEV
org ID: default-org
environment name: Library
EOD


describe Facter::Util::Rhsm_identity, :type => :fact do
  before :each do
    Facter::Util::Loader.any_instance.stubs(:load_all)
    Facter.clear
    Facter.clear_messages
  end
  it "should return the expected data for old style return" do
    expect(Facter::Util::Resolution).to receive(:exec).
      with("/usr/sbin/subscription-manager identity") { raw_data1 }
    expect(subject.rhsm_identity).to eq(expected_data)
  end
  it "should return the expected data for new style" do
    expect(Facter::Util::Resolution).to receive(:exec).
      with("/usr/sbin/subscription-manager identity") { raw_data2 }
    expect(subject.rhsm_identity).to eq(expected_data)
  end
  it "should return the nothing for no data" do
    expect(Facter::Util::Resolution).to receive(:exec).
      with("/usr/sbin/subscription-manager identity") { '' }
    expect(subject.rhsm_identity).to eq(nil)
  end
  it "should return the nothing for no command" do
    expect(Facter::Util::Resolution).to receive(:exec).
      with("/usr/sbin/subscription-manager identity") { nil }
    expect(subject.rhsm_identity).to eq(nil)
  end
  it "should return the nothing for an error" do
    expect(Facter::Util::Resolution).to receive(:exec).
      with("/usr/sbin/subscription-manager identity") { throw Error }
    expect(Facter).to receive(:debug)
    expect(subject.rhsm_identity).to eq(nil)
  end
end
