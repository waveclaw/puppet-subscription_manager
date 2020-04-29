#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

#
#  Test the rhsm_disabled_pools fact
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'pool_tests'
require 'facter/rhsm_disabled_pools'

describe Facter::Util::RhsmDisabledPools, type: :fact do
  context 'on a supported platform' do
    before :each do
      Facter.clear
    end
    it_behaves_like 'consumed pools',
                    Facter::Util::RhsmDisabledPools, 'rhsm_disabled_pools', :disabled
  end

  context 'on an unsupported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
        '/usr/sbin/subscription-manager',
      ).and_return(false)
      allow(Puppet.features).to receive(:facter_cacheable?).and_return(false)
    end
    it 'returns nothing' do
      expect(Facter::Util::RhsmDisabledPools.rhsm_disabled_pools).to eq([])
    end
  end

  context 'when caching' do
    it_behaves_like 'cached pools',
                    Facter::Util::RhsmDisabledPools,
                    'rhsm_disabled_pools',
                    :rhsm_disabled_pools,
                    '/var/cache/rhsm/disabled_pools.yaml'
  end
end
