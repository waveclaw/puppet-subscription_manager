#!/usr/bin/ruby -S rspec
#
#  Test the subscrption_manager provider for rhsm_override
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'puppet'
require 'date'
require 'stringio'
require 'spec_helper'
require 'puppet/type/rhsm_override'

provider_class = Puppet::Type.type(:rhsm_override).provider(:subscription_manager)

describe provider_class, 'rhsm_override provider' do

  repo_file = '/var/lib/rhsm/cache/content_overrides.json'

  one_data =<<-EOD
[
  {
    "updated": "2015-07-17T14:26:35.064+0000",
    "contentLabel": "rhel-server6-epel",
    "name": "enabled",
    "value": "0",
    "created": "2015-07-17T14:26:35.064+0000"
  }
]
EOD

  two_data =<<-EOT
  [{"updated": "2015-07-17T14:26:35.064+0000", "contentLabel": "rhel-server6-epel", "name": "enabled", "value": "0", "created": "2015-07-17T14:26:35.064+0000"}, {"updated": "2015-07-17T14:26:35.060+0000", "contentLabel": "rhel-server5", "name": "enabled", "value": "1", "created": "2015-07-17T14:26:35.060+0000"}]
EOT

  title1 = 'rhel-server6-epel'
  title2 = 'rhel-server5'

  properties = {
    :ensure        => :present,
    :updated       => Date.parse('2015-07-17T14:26:35.064+0000'),
    :created       => Date.parse('2015-07-17T14:26:35.064+0000'),
    :content_label => 'rhel-server6-epel',
    :name          => 'rhel-server6-epel',
    :provider      => :subscription_manager
  }

  let(:resource) do
    Puppet::Type.type(:rhsm_override).new(properties)
  end

  let(:provider) do
    resource.provider
  end

  before :each do
    allow(provider.class).to receive(:suitable?) { true }
    allow(Puppet::Util).to receive(:which).with('subscription-manager') { 'subscription-manager' }
  end

  it "generic resource can exist" do
    expect(resource).to_not eq(nil)
  end

  it "generic provider instance can exist" do
    expect(provider).to_not eq(nil)
  end

  [ :create, :destroy, :exists? ].each { |action|
    it { expect(provider).to respond_to(action) }
  }

  describe 'self.instances' do
    it { expect(provider.class).to respond_to(:instances) }
    context 'should parse the expected values for properties' do
      properties.keys.each { |key|
         it "such as the #{key} property" do
            expect(provider.class).to receive(:read_cache) {[properties]}
            pools = provider.class.instances
            pool = pools[0]
            expect(pool).to respond_to(key)
            expect(pool.public_send(key)).to      eq(resource[key])
        end
      }
    end
  end

  describe 'self.prefetch' do
    it { expect(provider.class).to respond_to(:prefetch) }
    it 'can be called on the provider' do
      expect(provider.class).to receive(:read_cache) { [ properties ] }
      provider.class.prefetch(properties)
    end
  end

  describe "read_cache" do
    it 'should return just two repos for a double input' do
      expect(provider.class).to receive(:get_cache) { two_data }
      repos = provider.class.read_cache
      expect(repos.size).to eq(2)
    end
    it 'should return just one repo for a single input' do
      expect(provider.class).to receive(:get_cache) { one_data }
      repos = provider.class.read_cache
      expect(repos.size).to eq(1)
    end
    it 'should return nothing for an empty list' do
      expect(provider.class).to receive(:get_cache) { '[]' }
      repos = provider.class.read_cache
      expect(repos.size).to eq(0)
    end
    it 'should return nothing for missing repo file' do
      allow(File).to receive(:exists?) { false }
      repos = provider.class.read_cache
      expect(repos.size).to eq(0)
    end
  end

  context 'ensure' do
    it 'exists? should return false when the resource is absent' do
      provider.set(:ensure => :absent)
      expect(provider).to_not be_exists
    end
    it 'exists? should return true when the resource is present' do
      provider.set(:ensure => :present)
      expect(provider).to be_exists
    end
    it 'create should enable a repo that should exist' do
      expect(provider).to receive(:subscription_manager).with(
      'repos', '--enable', title1)
      res = Puppet::Type.type(:rhsm_override).new(:name => title1,
        :ensure => :present, :provider => provider)
      allow(provider).to receive(:exists?) { true }
      provider.create
    end
    it "destroy should disable a repo that shouldn't exist" do
      expect(provider).to receive(:subscription_manager).with(
      'repos', '--disable', title1)
      res = Puppet::Type.type(:rhsm_override).new(
        :name     => title1,
        :ensure   => :absent,
        :provider => provider)
      allow(provider).to receive(:exists?) { false }
      provider.destroy
    end
  end
end
