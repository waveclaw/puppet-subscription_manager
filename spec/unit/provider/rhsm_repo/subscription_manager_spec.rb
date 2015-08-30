#!/usr/bin/ruby -S rspec
require 'spec_helper'
require 'puppet'
require 'date'
require 'stringio'
require 'puppet/type/rhsm_repo'

provider_class = Puppet::Type.type(:rhsm_repo).provider(:subscrption_manager)

describe provider_class, 'provider' do

  repo_file = '/var/lib/rhsm/cache/content_overrides.json'

  raw_data =<<-EOD
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

  properties = {
    :ensure        => :present,
    :enabled       => false,
    :updated       => Date.parse('2015-07-17T14:26:35.064+0000'),
    :created       => Date.parse('2015-07-17T14:26:35.064+0000'),
    :content_label => 'rhel-server6-epel',
    :provider      => provider_class
  }

  title1 = 'rhel-server6-epel'
  title2 = 'rhel-server5'

  let(:resource) do
    Puppet::Type.type(:rhsm_repo).new(properties)
  end

  let(:provider) do
    provider_class
  end

  before :each do
    allow(provider.class).to receive(:suitable?) { true }
    allow(File).to receive(:exists).with(repo_file) { true }
    allow(Puppet::Util).to receive(:which).with("subscription-manager") { "subscription-manager" }
  end

  after :each do
  end

  let(:instance) { provider.class.instances.first }

  it 'should have a resource from a generic list of propeties' do
    expect(resource).to_not eq(nil)
  end

  it 'should have a provider for a generic resource' do
    expect(provider).to_not eq(nil)
  end
=begin
  [ :create, :destroy, :exists? ].each { |action|
    it "should respond to #{action}" do
      expect(provider).to respond_to(action)
    end
  }

  [ :instances, :prefetch, :exists? ].each { |action|
    it "should respond to #{action}" do
      expect(provider.class).to respond_to(action)
    end
  }

  describe 'when parsing instances' do
    it "instances should exist and be callable" do
      expect(provider.class).to respond_to(:instances)
    end
    it 'should return nothing for missing repo file' do
      expect(File).to receive(:exists).with(repo_file) { false }
      pools = provider.class.instances
      expect(pools.size).to eq(0)
    end
    it 'should return nothing for an empty list' do
      expect(File).to receive(:exists).with(repo_file) { true }
      expect(File).to receive(:open).with(repo_file) { StringIO.new('[]') }
      pools = provider.class.instances
      expect(pools.size).to eq(0)
    end
    it 'should return just one pool for a single input' do
      expect(File).to receive(:exists).with(repo_file) { true }
      expect(File).to receive(:open).with(repo_file) { StringIO.new(raw_data) }
      pools = provider.class.instances
      expect(pools.size).to eq(1)

    end
    it 'should correctly parse a list of pools' do
      expect(File).to receive(:exists).with(repo_file) { true }
      expect(File).to receive(:open).with(repo_file) { StringIO.new(two_data) }
      pools = provider.class.instances
      expect(pools.size).to eq(2)
      expect(pools[0]).to      be_exists
      expect(pools[0].name).to eq(title1)
      expect(pools[1]).to      be_exists
      expect(pools[1].name).to eq(title2)
    end
    context "should parse the expected values for properties" do
      properties.keys.each { |key|
         it "such as the #{key} property" do
            expect(File).to receive(:exists).with(repo_file) { true }
            expect(File).to receive(:open).
              with(repo_file) { StringIO.new(two_data) }
            pools = provider.class.instances
            pool = pools[0]
            expect(pool).to respond_to(key)
            expect(pool.public_send(key)).to      eq(resource[key])
        end
      }
    end
  end

  describe 'self.prefetch' do
    it 'exists as a method' do
      expect(provider.class).to respond_to(:prefetch)
    end
    it "can be called on the provider" do
      expect(provider.class).to receive(:subscription_manager).with(
        "list", "--consumed") { raw_data }
      provider.class.prefetch(properties)
    end
  end

  context "ensure" do
    it "exists? should return false when the resource is absent" do
      provider.set(:ensure => :absent)
      expect(provider).to_not be_exists
    end
    it "exists? should return true when the resource is present" do
      provider.set(:ensure => :present)
      expect(provider).to be_exists
    end
    it "create should enable a repo that should exist" do
      expect(provider).to receive(:subscription_manager).with(
      'enable', '--content_label', title1)
      res = Puppet::Type.type(:rhsm_repo).new(:name => title1,
        :ensure => :present, :provider => provider)
      allow(provider).to receive(:exists?) { true }
      provider.create
    end
    it "destroy should disable a repo that shouldn't exist" do
      expect(provider).to receive(:subscription_manager).with(
      'disable', '--content_label', title1)
      res = Puppet::Type.type(:rhsm_repo).new(
        :name     => title1,
        :ensure   => :absent,
        :provider => provider)
      allow(provider).to receive(:exists?) { false }
      provider.destroy
    end
  end
=end
end
