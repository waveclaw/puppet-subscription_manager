#!/usr/bin/ruby -S rspec
require 'puppet'
require 'date'
require 'spec_helper'
require 'puppet/type/rhsm_register'

provider_class = Puppet::Type.type(:rhsm_register).provider(:subscrption_manager)

describe  provider_class, 'rhsm_register provider' do

  # this is a pure 'command' type which has no on-system representation
  # beyond that the result exists or not.
  #
  # The many parameters of registartion disapear down a one-sided
  # process like light and matter into a blackhole.
  #
  parameters = {
    :provider        => :subscription_manager,
    :name            => 'example.com',
    :server_hostname => 'example.com',
    :server_insecure => false,
    :username        => 'registered_user',
    :password        => 'password123',
    :server_prefix   => 'https',
    :rhsm_baseurl    => '/repos',
    :rhsm_cacert     => '/path/to/ca.pem',
    :username        => 'jdoe',
    :password        => 'password123',
    :activationkeys  => '1-my-activation-key',
    :pool            => 'my_awesome_subscription',
    :environment     => 'lab',
    :autosubscribe   => true,
    :force           => true,
    :org             => 'the cool organization',
    :servicelevel    => 'STANDARD',
  }

  title = 'example.com'
  fake_key = '1-my-activation-key'
  fake_id = '11111111-aaaa-bbbb-cccc-222222222222'

  let(:resource) do
    Puppet::Type.type(:rhsm_register).new(parameters)
  end

  let(:provider) do
    resource.provider
  end

  before :each do
    allow(provider.class).to receive(:suitable?) { true }
    allow(Puppet::Util).to receive(:which).with("subscription-manager") {
      "subscription-manager" }
      allow(provider.class).to receive(:command).with(:subscription_manager) {
        "subscription-manager" }
  end

  after :each do
  end

  it 'should have a resource from a generic list of parameters' do
    expect(resource).to_not eq(nil)
  end

  it 'should have a provider for a generic resource' do
    expect(provider).to_not eq(nil)
  end

  [ :config, :register, :unregister, :create, :destroy, :exists?
  ].each { |action|
    it "should respond to #{action}" do
      expect(provider).to respond_to(action)
    end
  }

  context "ensure" do
    it "exists? should return true when the resource is present" do
      expect(provider).to receive(:identity) { true }
      allow(File).to receive(:exists?).
        with("/etc/pki/consumer/cert.pem") { true }
      provider.set(:ensure => :present)
      expect(provider).to be_exists
    end
    it "exists? should return false when the resource is absent" do
      expect(provider).to receive(:identity) { false }
      allow(File).to receive(:exists?).
        with("/etc/pki/consumer/cert.pem") { true }
      provider.set(:ensure => :absent)
      expect(provider).to_not be_exists
    end
    it "create should require force when resource already exists" do
      expect(provider).to receive(:identity) { fake_id }
      expect(provider).to receive(:subscription_manager).with(
      'config', '--server.hostname', title)
      expect(provider).not_to receive(:subscription_manager).with(
      'register', '--activationkey', fake_key, '--org', 'foo')
      res = Puppet::Type.type(:rhsm_register).new(
        :name => title,
        :ensure => :present,
        :activationkeys => fake_key,
        :org => 'foo',
        :provider => provider)
        allow(provider).to receive(:exists?) { true }
        expect{ provider.create }.to raise_error(Puppet::Error, /.*force.*/)
    end
    it "should re-register when resource already exists" do
      expect(provider).to receive(:identity) { fake_id }
      expect(provider).to receive(:subscription_manager).with(
      'config', '--server.hostname', title)
      expect(provider).to receive(:execute).with(["subscription-manager",
        "register --activationkey #{fake_key} --force --org foo"],
        {:failonfail=>false, :combine=>true})
      expect(provider).to receive(:subscription_manager).with(
      ['attach', '--servicelevel=STANDARD', '--auto'])
      res = Puppet::Type.type(:rhsm_register).new(
        :name => title,
        :ensure => :present,
        :activationkeys => fake_key,
        :org => 'foo',
        :force => 'true',
        :servicelevel => 'STANDARD',
        :autosubscribe => true,
        :provider => provider)
        allow(provider).to receive(:exists?) { true }
        provider.create
    end
    it "destroy should unregister when resource shouldn't exist" do
      expect(provider).to receive(:subscription_manager).with(['clean'])
      expect(provider).to receive(:subscription_manager).
        with(['unsubscribe','--all'])
      expect(provider).to receive(:subscription_manager).with(['unregister'])
      res = Puppet::Type.type(:rhsm_register).new(
        :name     => title,
        :ensure   => :absent,
        :provider => provider)
        allow(provider).to receive(:exists?) { false }
        provider.destroy
    end
  end

end
