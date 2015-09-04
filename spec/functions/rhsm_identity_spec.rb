#!/usr/bin/ruby -S rspec

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

awk='/usr/bin/awk'
sm='/bin/sm'

describe Facter::Util::Rhsm_identity, :type => :puppet_function do
  it "should return the expected data for old style return" do
#    expect(Facter::Util::Resolution).to receive(:exec).
#      with("/usr/bin/which awk") { awk }
    expect(Facter::Util::Resolution).to receive(:exec).
      with('/usr/bin/which subscription-manager') { sm }
    expect(Facter::Util::Resolution).to receive(:exec).
      with("/bin/sm identity") { raw_data1 }
    expect(Facter::Util::Rhsm_identity.rhsm_identity).to eq(expected_data)
  end
  it "should return the expected data for new style" do
#    expect(Facter::Util::Resolution).to receive(:exec).
#      with("/usr/bin/which awk") { awk }
    expect(Facter::Util::Resolution).to receive(:exec).
      with('/usr/bin/which subscription-manager') { sm }
    expect(Facter::Util::Resolution).to receive(:exec).
      with("/bin/sm identity") { raw_data2 }
    expect(Facter::Util::Rhsm_identity.rhsm_identity).to eq(expected_data)
  end
  it "should return the nothing for no data" do
#    expect(Facter::Util::Resolution).to receive(:exec).
#      with("/usr/bin/which awk") { awk }
    expect(Facter::Util::Resolution).to receive(:exec).
      with('/usr/bin/which subscription-manager') { sm }
    expect(Facter::Util::Resolution).to receive(:exec).
      with("#{sm} identity") { '' }
    expect(Facter::Util::Rhsm_identity.rhsm_identity).to eq(nil)
  end
  it "should return the nothing for no command" do
#    expect(Facter::Util::Resolution).to receive(:exec).
#      with("/usr/bin/which awk") { awk }
    expect(Facter::Util::Resolution).to receive(:exec).
      with('/usr/bin/which subscription-manager') { sm }
    expect(Facter::Util::Resolution).to receive(:exec).
      with("#{sm} identity") { throw Error }
    expect(Facter::Util::Rhsm_identity.rhsm_identity).to eq(nil)
  end
end
