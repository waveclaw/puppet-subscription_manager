#!/usr/bin/ruby -S rspec
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

# stub facter_cacheable
module Facter::Util::Facter_cacheable
  class <<self
    def cached?
    end
  end
end

available_cases = {
  :one   => {
    :desc => 'a single active pool',
    :data => '

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
    :expected => ['402881af5354120801535494568c0003']
  },
  :two   => {
    :desc => 'two pools',
    :data => '
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
    :expected => ['402881af5354120801535494568c0003', '402881af53cc3cc00153d85560d4001a']
  },
  :three  => {
    :desc => 'no subscription pools available',
    :data => '',
    :expected => []
  }
}


describe Facter::Util::Rhsm_available_pools, :type => :puppet_function do
  context 'on a supported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager') { true }
      allow(Puppet.features).to receive(:facter_cacheable?) { true }
      allow(Facter::Util::Facter_cacheable).to receive(:cached?) { false }
    end
    it "should return nothing when there is an error" do
      expect(Facter::Util::Resolution).to receive(:exec).with(
        '/usr/sbin/subscription-manager list --available') { throw Error }
      expect(Facter::Util::Rhsm_available_pools.rhsm_available_pools).to eq([])
    end
    available_cases.keys.each { |key|
      desc = available_cases[key][:desc]
      it "should process with get_input #{desc}" do
        expect(Facter::Util::Rhsm_available_pools.get_output(available_cases[key][:data])).to  eq(
          available_cases[key][:expected] )
      end
      it "should return results for #{desc}" do
        expect(Facter::Util::Resolution).to receive(:exec).with(
          '/usr/sbin/subscription-manager list --available') {
            available_cases[key][:data]}
          expect(Facter::Util::Rhsm_available_pools.rhsm_available_pools).to eq(
            available_cases[key][:expected] )
      end
    }
  end

  context 'on a supported platform without caching' do
    before :each do
      allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager') { true }
      allow(Puppet.features).to receive(:facter_cacheable?) { false }
    end
    it "should return nothing when there is an error" do
      expect(Facter::Util::Resolution).to receive(:exec).with(
        '/usr/sbin/subscription-manager list --available') { throw Error }
      expect(Facter::Util::Rhsm_available_pools.rhsm_available_pools).to eq([])
    end
    available_cases.keys.each { |key|
      desc = available_cases[key][:desc]
      it "should process with get_input #{desc}" do
        expect(Facter::Util::Rhsm_available_pools.get_output(available_cases[key][:data])).to  eq(
          available_cases[key][:expected] )
      end
      it "should return results for #{desc}" do
        expect(Facter::Util::Resolution).to receive(:exec).with(
          '/usr/sbin/subscription-manager list --available') {
            available_cases[key][:data]}
          expect(Facter::Util::Rhsm_available_pools.rhsm_available_pools).to eq(
            available_cases[key][:expected] )
      end
    }
  end

  context 'on an unsupported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager') { false }
    end
    it "should return nothing" do
      expect(Facter::Util::Rhsm_available_pools.rhsm_available_pools).to eq([])
    end
  end

  context 'when caching' do
    it_behaves_like 'cached pools',
      Facter::Util::Rhsm_available_pools, 'rhsm_available_pools', :rhsm_available_pools
  end
end
