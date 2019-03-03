#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

#  Test the subscrption_manager provider for rhsm_repo
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'puppet'
require 'date'
require 'stringio'
require 'spec_helper'
require 'puppet/type/rhsm_repo'

provider_class = Puppet::Type.type(:rhsm_repo).provider(:subscription_manager)

describe provider_class, '#rhsm_repo.provider' do
  # config_file is by default '/etc/rhsm/rhsm.conf'

  one_data = <<-EOD
  Repo ID:   rhel-5-server-rpms
  Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
  Enabled:   1
EOD

  two_data = <<-EOT
  Repo ID:   rhel-5-server-rpms
  Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
  Enabled:   0

  Repo ID:   rhel-5-epel-rpms
  Repo Name: Extra Packages for RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/epel/os
  Enabled:   1

EOT

  title1 = 'rhel-5-server-rpms'
  # title2 could be rhel-5-epel-rpms

  properties = {
    ensure: :present,
    id: title1,
    name: title1,
    repo_name: 'RedHat Enterprise Linux 5 Server (RPMs)',
    url: 'https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os',
    provider: :subscription_manager
  }

  let(:resource) do
    Puppet::Type.type(:rhsm_repo).new(properties)
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

  [:instances, :prefetch].each do |action|
    it { expect(provider.class).to respond_to(action) }
  end

  describe 'self.instances' do
    it { expect(provider.class).to respond_to(:instances) }
    context 'should parse the expected values for properties' do
      properties.keys.each do |key|
        it "such as the #{key} property" do
          # expect(provider.class).to receive(:read_channels) {[properties]}
          expect(provider.class).to receive(:subscription_manager).with('repos').and_return(one_data)
          pools = provider.class.instances
          pool = pools[0]
          expect(pool).to respond_to(key)
          expect(pool.public_send(key)).to eq(resource[key])
        end
      end
    end
    it 'returns just one repo for a single input' do
      expect(provider.class).to receive(:subscription_manager).with('repos').and_return(one_data)
      repos = provider.class.instances
      expect(repos.size).to eq(1)
    end
    it 'returns nothing for an empty list' do
      expect(provider.class).to receive(:subscription_manager).with('repos').and_return('')
      repos = provider.class.instances
      expect(repos.size).to eq(0)
    end
    it 'returns nothing for a blank list' do
      expect(provider.class).to receive(:subscription_manager).with('repos').and_return("\n\n")
      repos = provider.class.instances
      expect(repos.size).to eq(0)
    end
    it 'returns nothing for not subscribed' do
      data = 'This system has no repositories available through subscriptions.'
      expect(provider.class).to receive(:subscription_manager).with('repos').and_return(data)
      repos = provider.class.instances
      expect(repos.size).to eq(0)
    end
  end

  describe 'self.prefetch' do
    it { expect(provider.class).to respond_to(:prefetch) }
    it 'can be called on the provider' do
      expect(provider.class).to receive(:read_repos).and_return([properties])
      provider.class.prefetch(title1 => resource)
      expect(resource.provider).to eq(provider)
    end
  end

  describe 'read_repos' do
    it 'returns just two repos for a double input' do
      expect(provider.class).to receive(:subscription_manager).with('repos').and_return(two_data)
      repos = provider.class.read_repos
      expect(repos.size).to eq(2)
    end
    it 'returns just one repo for a single input' do
      expect(provider.class).to receive(:subscription_manager).with('repos').and_return(one_data)
      repos = provider.class.read_repos
      expect(repos.size).to eq(1)
    end
    it 'returns nothing for an empty list' do
      expect(provider.class).to receive(:subscription_manager).with('repos').and_return('')
      repos = provider.class.read_repos
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
      Puppet::Type.type(:rhsm_repo).new(name: title1, id: title1,
                                        ensure: :present, provider: provider)
      allow(provider).to receive(:exists?).and_return(true)
      provider.create
    end
    it "destroy should disable a repo that shouldn't exist" do
      expect(provider).to receive(:subscription_manager).with(
        'repos', '--disable', title1
      )
      Puppet::Type.type(:rhsm_repo).new(
        name: title1,
        id: title1,
        ensure: :absent,
        provider: provider,
      )
      allow(provider).to receive(:exists?).and_return(false)
      provider.destroy
    end
  end
end
