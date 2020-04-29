#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

#
#  Test the rhsm_available_repos fact
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'pool_tests'
require 'facter/rhsm_available_pools'

available_cases = {
  one: {
    desc: 'a single active pool',
    data: '

    +-------------------------------------------+
        Available Subscriptions
    +-------------------------------------------+
    Subscription Name:   Puppet
    Provides:
    SKU:                 1457412916057
    Contract:
    Pool ID:             402881af5354120801535494568c0003
    Provides Management: No
    Available:           Unlimited
    Suggested:           1
    Service Level:
    Service Type:
    Subscription Type:   Standard
    Ends:                02/28/2046
    System Type:         Physical
    ',
    expected: ['402881af5354120801535494568c0003'],
  },
  two: {
    desc: 'two pools',
    data: '
    +-------------------------------------------+
        Available Subscriptions
    +-------------------------------------------+
    Subscription Name:   Puppet
    Provides:
    SKU:                 1457412916057
    Contract:
    Pool ID:             402881af5354120801535494568c0003
    Provides Management: No
    Available:           Unlimited
    Suggested:           1
    Service Level:
    Service Type:
    Subscription Type:   Standard
    Ends:                02/28/2046
    System Type:         Physical

    Subscription Name:   CentOS 7
    Provides:            CentOS 7
    SKU:                 1459623384080
    Contract:
    Account:
    Pool ID:             402881af53cc3cc00153d85560d4001a
    Provides Management: No
    Available:           Unlimited
    Suggested:           1
    Service Level:
    Service Type:
    Status Details:      Subscription is current
    Subscription Type:   Standard
    Ends:                03/26/2046
    System Type:         Physical
',
    expected: ['402881af5354120801535494568c0003',
               '402881af53cc3cc00153d85560d4001a'],
  },
  three: {
    desc: 'no subscription pools available',
    data: '',
    expected: [],
  },
}

describe Facter::Util::RhsmAvailablePools, type: :fact do
  context 'on a supported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
        '/usr/sbin/subscription-manager',
      ).and_return(true)
      allow(Puppet.features).to receive(:facter_cacheable?).and_return(true)
      allow(Facter::Util::FacterCacheable).to receive(:cached?).and_return(false)
    end
    it 'returns nothing when there is an error with subscription' do
      expect(Facter::Core::Execution).to receive(:execute).with(
        '/usr/sbin/subscription-manager list --available',
        on_fail: :raise,
      ) { throw Facter::Core::Execution::ExecutionFailure }
      expect(Facter).to receive(:debug)
      expect(Facter::Util::RhsmAvailablePools.rhsm_available_pools).to eq([])
    end
    it 'returns nothing when there is an error with output' do
      expect(Facter::Core::Execution).to receive(:execute).with(
        '/usr/sbin/subscription-manager list --available',
        on_fail: :raise,
      ).and_return(nil)
      expect(Facter::Util::RhsmAvailablePools).to receive(:get_output) { throw Facter::Core::Execution::ExecutionFailure }
      expect(Facter).to receive(:debug)
      expect(Facter::Util::RhsmAvailablePools.rhsm_available_pools).to eq([])
    end
    available_cases.keys.each do |key|
      desc = available_cases[key][:desc]
      it "should process with get_input #{desc}" do
        expect(Facter::Util::RhsmAvailablePools.get_output(available_cases[key][:data])).to eq(
          available_cases[key][:expected],
        )
      end
      it "should return results for #{desc}" do
        expect(Facter::Core::Execution).to receive(:execute).with(
          '/usr/sbin/subscription-manager list --available',
          on_fail: :raise,
        ).and_return(available_cases[key][:data])
        expect(Facter::Util::RhsmAvailablePools.rhsm_available_pools).to eq(
          available_cases[key][:expected],
        )
      end
    end
  end

  context 'on a supported platform without caching' do
    before :each do
      allow(File).to receive(:exist?).with(
        '/usr/sbin/subscription-manager',
      ).and_return(true)
      allow(Puppet.features).to receive(:facter_cacheable?).and_return(false)
    end
    it 'returns nothing when there is an error' do
      expect(Facter::Core::Execution).to receive(:execute).with(
        '/usr/sbin/subscription-manager list --available',
        on_fail: :raise,
      ) { throw Facter::Core::Execution::ExecutionFailure }
      expect(Facter::Util::RhsmAvailablePools.rhsm_available_pools).to eq([])
    end
    available_cases.keys.each do |key|
      desc = available_cases[key][:desc]
      it "should process with get_input #{desc}" do
        expect(Facter::Util::RhsmAvailablePools.get_output(available_cases[key][:data])).to eq(
          available_cases[key][:expected],
        )
      end
      it "should return results for #{desc}" do
        expect(Facter::Core::Execution).to receive(:execute).with(
          '/usr/sbin/subscription-manager list --available',
          on_fail: :raise,
        ).and_return(available_cases[key][:data])
        expect(Facter::Util::RhsmAvailablePools.rhsm_available_pools).to eq(
          available_cases[key][:expected],
        )
      end
    end
  end

  context 'on an unsupported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
        '/usr/sbin/subscription-manager',
      ).and_return(false)
    end
    it 'returns nothing' do
      expect(Facter::Util::RhsmAvailablePools.rhsm_available_pools).to eq([])
    end
  end

  context 'when caching' do
    it_behaves_like 'cached pools',
                    Facter::Util::RhsmAvailablePools,
                    'rhsm_available_pools',
                    :rhsm_available_pools,
                    '/var/cache/rhsm/available_pools.yaml'
  end
end
