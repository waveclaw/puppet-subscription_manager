#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

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

describe provider_class, '#rhsm_override.provider' do
  # the repo file is '/var/lib/rhsm/cache/content_overrides.json'

  one_data = <<-EOD
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

  two_data = <<-EOT
  [{"updated": "2015-07-17T14:26:35.064+0000", "contentLabel": "rhel-server6-epel", "name": "enabled", "value": "0", "created": "2015-07-17T14:26:35.064+0000"}, {"updated": "2015-07-17T14:26:35.060+0000", "contentLabel": "rhel-server5", "name": "enabled", "value": "1", "created": "2015-07-17T14:26:35.060+0000"}]
EOT

  title1 = 'rhel-server6-epel'
  # title2 could be 'rhel-server5'

  properties = {
    ensure: :present,
    updated: Date.parse('2015-07-17T14:26:35.064+0000'),
    created: Date.parse('2015-07-17T14:26:35.064+0000'),
    content_label: 'rhel-server6-epel',
    name: 'rhel-server6-epel',
    provider: :subscription_manager
  }

  let(:resource) do
    Puppet::Type.type(:rhsm_override).new(properties)
  end

  let(:provider) do
    resource.provider
  end

  before :each do
    allow(provider.class).to receive(:suitable?).and_return(true)
    allow(Puppet::Util).to receive(:which).with('subscription-manager').and_return('subscription-manager')
  end

  it 'generic resource can exist' do
    expect(resource).not_to eq(nil)
  end

  it 'generic provider instance can exist' do
    expect(provider).not_to eq(nil)
  end

  [:create, :destroy, :exists?].each do |action|
    it { expect(provider).to respond_to(action) }
  end

  describe 'self.instances' do
    it { expect(provider.class).to respond_to(:instances) }
    context 'should parse the expected values for properties' do
      properties.keys.each do |key|
        it "such as the #{key} property" do
          expect(provider.class).to receive(:read_cache) { [properties] }
          pools = provider.class.instances
          pool = pools[0]
          expect(pool).to respond_to(key)
          expect(pool.public_send(key)).to eq(resource[key])
        end
      end
    end
  end

  describe 'self.prefetch' do
    it { expect(provider.class).to respond_to(:prefetch) }
    it 'can be called on the provider' do
      expect(provider.class).to receive(:read_cache).and_return([properties])
      provider.class.prefetch(properties)
    end
  end

  describe 'read_cache' do
    it 'returns just two repos for a double input' do
      expect(provider.class).to receive(:content_overrides).and_return(two_data)
      repos = provider.class.read_cache
      expect(repos.size).to eq(2)
    end
    it 'returns just one repo for a single input' do
      expect(provider.class).to receive(:content_overrides).and_return(one_data)
      repos = provider.class.read_cache
      expect(repos.size).to eq(1)
    end
    it 'returns nothing for an empty list' do
      expect(provider.class).to receive(:content_overrides).and_return('[]')
      repos = provider.class.read_cache
      expect(repos.size).to eq(0)
    end
    it 'returns nothing for missing repo file' do
      allow(File).to receive(:exists?).and_return(false)
      repos = provider.class.read_cache
      expect(repos.size).to eq(0)
    end
  end

  context 'ensure' do
    it 'exists? should return false when the resource is absent' do
      provider.set(ensure: :absent)
      expect(provider).not_to be_exists
    end
    it 'exists? should return true when the resource is present' do
      provider.set(ensure: :present)
      expect(provider).to be_exists
    end
    it 'create should enable a repo that should exist' do
      expect(provider).to receive(:subscription_manager).with(
        'repos', '--enable', title1
      )
      Puppet::Type.type(:rhsm_override).new(name: title1,
                                            ensure: :present, provider: provider)
      allow(provider).to receive(:exists?).and_return(true)
      provider.create
    end
    it "destroy should disable a repo that shouldn't exist" do
      expect(provider).to receive(:subscription_manager).with(
        'repos', '--disable', title1
      )
      Puppet::Type.type(:rhsm_override).new(
        name: title1,
        ensure: :absent,
        provider: provider,
      )
      allow(provider).to receive(:exists?).and_return(false)
      provider.destroy
    end
  end
end
