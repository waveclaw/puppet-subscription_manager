#!/usr/bin/ruby -S rspec
#
#  Test the rhsm_enabled_repos fact
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'pool_tests'
require 'facter/rhsm_enabled_pools'

describe Facter::Util::Rhsm_enabled_pools, :type => :puppet_function do
  context 'on a supported platform' do
    it_behaves_like 'consumed pools',
      Facter::Util::Rhsm_enabled_pools, 'rhsm_enabled_pools', :enabled
  end

  context 'on an unsupported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager') { false }
      allow(Puppet.features).to receive(:facter_cacheable?) { false }
    end
    it "should return nothing" do
      expect(Facter::Util::Rhsm_enabled_pools.rhsm_enabled_pools).to eq([])
    end
  end

  context 'when caching' do
    it_behaves_like 'cached pools',
      Facter::Util::Rhsm_enabled_pools, 'rhsm_enabled_pools', :rhsm_enabled_pools
  end
end
