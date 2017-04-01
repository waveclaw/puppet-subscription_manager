#!/usr/bin/ruby -S rspec
#
#  Test the subscrption_manager provider for rhsm_register
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'puppet'
require 'date'
require 'spec_helper'
require 'puppet/type/rhsm_register'

provider_class = Puppet::Type.type(:rhsm_register).provider(:subscrption_manager)

describe  provider_class, 'rhsm_register provider' do

  # this is a 'command' type which has limited on-system representation
  #
  parameters = {
    :provider      => :subscription_manager,
    :name          => 'example.com',
    :username      => 'registered_user',
    :password      => 'password123',
    :activationkey => '1-my-activation-key',
    :lifecycleenv  => 'lab',
    :autosubscribe => true,
    :force         => true,
    :org           => 'the cool organization',
    :servicelevel  => 'STANDARD',
  }

  title = 'example.com'
  fake_key = '1-my-activation-key'
  fake_id = '11111111-aaaa-bbbb-cccc-222222222222'

  config_data =<<-EOD
  [server]
     hostname = example.com
     insecure = [0]
     port = [443]
     prefix = /rhsm
     proxy_hostname = []
     proxy_password = []
     proxy_port = []
     proxy_user = []
     ssl_verify_depth = [3]

  [rhsm]
     baseurl = https://katello.example.com/pulp/repos
     ca_cert_dir = [/etc/rhsm/ca/]
     consumercertdir = [/etc/pki/consumer]
     entitlementcertdir = [/etc/pki/entitlement]
     full_refresh_on_yum = 1
     manage_repos = [1]
     pluginconfdir = [/etc/rhsm/pluginconf.d]
     plugindir = [/usr/share/rhsm-plugins]
     productcertdir = [/etc/pki/product]
     repo_ca_cert = /etc/rhsm/ca/
     report_package_profile = [1]

  [rhsmcertd]
     autoattachinterval = [1440]
  EOD


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

  [  :create, :destroy, :exists?, :flush ].each { |action|
    it "should respond to #{action}" do
      expect(provider).to respond_to(action)
    end
  }

  describe "create" do
    it "should update the property_hash" do
     @res = Puppet::Type.type(:rhsm_register).new(parameters)
     @res.provider.create()
     expect(@res.provider.exists?).to eq(true)
   end
  end

  describe 'self.flush' do
    it "when the does not exist and should" do
     @res = Puppet::Type.type(:rhsm_register).new(parameters)
     expect(@res.provider).to receive(:exists?) { true }
     expect(@res.provider).to receive(:register) { nil }
     expect(@res.provider).to receive(:subscription_attach) { nil }
     @res.provider.flush
    end
    it "when changing servers" do
     @res = Puppet::Type.type(:rhsm_register).new(parameters.merge({:identity => fake_id}))
     expect(@res.provider).to receive(:exists?) { true }
     expect(@res.provider).to receive(:register) { nil }
     expect(@res.provider).to receive(:subscription_attach) { nil }
     @res.provider.set(:name => 'not-example')
     @res.provider.flush
    end
    it "when removing-registinstration" do
      @res = Puppet::Type.type(:rhsm_register).new(parameters)
      expect(@res.provider).to receive(:exists?) { false }
      expect(@res.provider).to receive(:unregister) { nil }
      @res.provider.flush
    end

  end

  [  :instances, :prefetch ].each { |action|
    it "should respond to #{action}" do
      expect(provider.class).to respond_to(action)
    end
  }

  describe 'self.prefetch' do
    it { expect(provider.class).to respond_to(:prefetch) }
    it 'can be called on the provider' do
      expect(provider.class).to receive(:get_registration) { parameters }
      provider.class.prefetch({ title => resource })
      expect(resource.provider).to eq(provider)
    end
  end

  describe 'build_register_parameters' do
    it 'should respond to build_parameters' do
        expect(provider).to respond_to('build_register_parameters')
    end
    it 'should build a command with an activationkey' do
      res = Puppet::Type.type(:rhsm_register).new(
        :name => title,
        :ensure => :present,
        :activationkey => fake_key,
        :org => 'foo',
        :servicelevel => 'STANDARD',
        :autosubscribe => true,
        :provider => :subscription_manager,)
      expect(res.provider.build_register_parameters).to eq(
      ["register", "--activationkey", "1-my-activation-key", "--org", "foo"])
    end
    it 'should exclude lifecycle environment with an activation key' do
      res = Puppet::Type.type(:rhsm_register).new(
        :name => title,
        :ensure => :present,
        :activationkey => fake_key,
        :org => 'foo',
        :lifecycleenv => 'pants',
        :servicelevel => 'STANDARD',
        :autosubscribe => true,
        :provider => :subscription_manager,)
      expect(res.provider.build_register_parameters).to eq(
      ["register", "--activationkey", "1-my-activation-key", "--org", "foo"])
    end
    it 'should fail when an org is missing with an activation key' do
      res = Puppet::Type.type(:rhsm_register).new(
        :name => title,
        :ensure => :present,
        :activationkey => fake_key,
        #:org => 'foo',
        :servicelevel => 'STANDARD',
        :autosubscribe => true,
        :provider => :subscription_manager,)
      expect{ res.provider.build_register_parameters }.to raise_error(
        Puppet::Error, /.*org.*/)
    end
    it 'should fail with an activation key and username + password' do
      res = Puppet::Type.type(:rhsm_register).new(
        :name => title,
        :ensure => :present,
        :activationkey => fake_key,
        :username => 'foo',
        :password => 'bar',
        :provider => :subscription_manager,)
      expect{ res.provider.build_register_parameters }.to raise_error(
        Puppet::Error, /.*activation key or username.+password.*/)
    end
    it 'should build a command with a username and password' do
      res = Puppet::Type.type(:rhsm_register).new(
        :name => title,
        :ensure => :present,
        :org => 'foo',
        :username => 'foo',
        :password => 'bar',
        :servicelevel => 'STANDARD',
        :autosubscribe => true,
        :force => true,
        :provider => :subscription_manager,)
      expect(res.provider.build_register_parameters).to eq(
      ["register", "--force", "--username", "foo", "--password", "bar",
        "--autosubscribe", "--org", "foo"])
    end
  end

  describe 'self.instances' do
    it { expect(provider.class).to respond_to(:instances) }
    it "returns the name and identity properties" do
        expect(provider.class).to receive(:config_hostname) { title }
        expect(provider.class).to receive(:identity) { fake_id }

        registrations = provider.class.instances
        registration = registrations[0]

        expect(registration.ensure).to eq(:present)
        expect(registration.name).to eq(title)
        expect(registration.identity).to eq(fake_id)
    end
    it "falls back to ca_name for no configuration name" do
      expect(provider.class).to receive(:config_hostname) { nil }
      expect(provider.class).to receive(:certified?) { true }
      expect(provider.class).to receive(:ca_name) { title }
      expect(provider.class).to receive(:identity) { fake_id }

      registrations = provider.class.instances
      registration = registrations[0]

      expect(registration.ensure).to eq(:present)
      expect(registration.name).to eq(title)
      expect(registration.identity).to eq(fake_id)
    end
    it "parses subscription manager config --list with non-standard hostname" do
      expect(provider.class).to receive(:subscription_manager).with(
        ['config','--list']) { config_data }
      expect(provider.class).to receive(:identity) { fake_id }

      registrations = provider.class.instances
      registration = registrations[0]

      expect(registration.ensure).to eq(:present)
      expect(registration.name).to eq(title)
      expect(registration.identity).to eq(fake_id)
    end
    it "parses subscription manager config --list with [default value]" do
      expect(provider.class).to receive(:subscription_manager).with(
        ['config','--list']) { 'hostname = [subscription.rhn.redhat.com]\n'  }
      expect(provider.class).to receive(:identity) { fake_id }

      registrations = provider.class.instances
      registration = registrations[0]

      expect(registration.ensure).to eq(:present)
      expect(registration.name).to eq('subscription.rhn.redhat.com')
      expect(registration.identity).to eq(fake_id)
    end

    it "parses subscription manager config --list with hostname and proxy" do
      expect(provider.class).to receive(:subscription_manager).with(
        ['config','--list']) {
          'hostname = katello.example.com\nproxy_hostname = proxy.example.com' }
      expect(provider.class).to receive(:identity) { fake_id }

      registrations = provider.class.instances
      registration = registrations[0]

      expect(registration.ensure).to eq(:present)
      expect(registration.name).to eq('katello.example.com')
      expect(registration.identity).to eq(fake_id)
    end

    it "is absent for good name with bad identity" do
      expect(provider.class).to receive(:config_hostname) { title }
      expect(provider.class).to receive(:identity) { nil }

      registrations = provider.class.instances
      registration = registrations[0]
      expect(registration.ensure).to eq(:absent)
      expect(registration.name).to eq(title)
    end
    it "returns nothing for no data" do
      expect(provider.class).to receive(:config_hostname) { nil }
      expect(provider.class).to receive(:certified?) { false }
      expect(provider.class).to receive(:identity) { nil }
      expect(provider.class.instances).to eq([])
    end
  end

  context "ensure" do
    it "exists? should return true when the resource is present" do
      #exist_test = Puppet::Type.type(:rhsm_register)
      #allow(exist_test).to receive(:identity) { true }
      #allow(exist_test).to receive(:certifed?) { true }
      #expect(exist_test).to receive(:subscrption_manager).with(['config','--list']) { 'hostname = foo\n' }
      provider.set(:ensure => :present)
      expect(provider.exists?).to be(true)
    end
    it "exists? should return false when the resource is absent" do
      #exist_test = Puppet::Type.type(:rhsm_register)
      #allow(exist_test).to receive(:identity) { false }
      #allow(exist_test).to receive(:certifed?) { false }
      #expect(exist_test).to receive(:subscrption_manager).with(['config','--list']) { '' }
      provider.set(:ensure => :absent)
      expect(provider.exists?).to be(false)
    end
    it "create should require force when resource already exists" do
      expect(provider).to receive(:identity) { fake_id }
      res = Puppet::Type.type(:rhsm_register).new(
        :name => title,
        :ensure => :present,
        :activationkey => fake_key,
        :org => 'foo',
        :servicelevel => 'STANDARD',
        :autosubscribe => true,
        :provider => provider)
      allow(provider).to receive(:exists?) { true }
      expect(provider).to receive(:identity) { fake_id }
      expect{ provider.flush }.to raise_error(Puppet::Error, /.*force.*/)
    end
    it "should re-register when changing servers" do
      expect(provider).to receive(:identity) { fake_id }
      expect(provider).to receive(:execute).with(
      ['subscription-manager',['clean']],
      {:failonfail=>false, :combine=>true}) { true }
      expect(provider).to receive(:execute).with(
      ['subscription-manager',['unsubscribe','--all']],
      {:failonfail=>false, :combine=>true}) { true }
      expect(provider).to receive(:execute).with(
      ['subscription-manager',['unregister']],
      {:failonfail=>false, :combine=>true}) { true }
      expect(provider).to receive(:subscription_manager).with(
        ["register","--force","--activationkey","#{fake_key}","--org","foo"])
      expect(provider).to receive(:subscription_manager).with(
      ['attach', '--servicelevel=STANDARD', '--auto'])
      @res = Puppet::Type.type(:rhsm_register).new(
        :name => title,
        :ensure => :present,
        :activationkey => fake_key,
        :org => 'foo',
        :force => 'true',
        :servicelevel => 'STANDARD',
        :autosubscribe => true,
        :provider => provider)
        @res.provider.set(:name => 'bar')
      allow(provider).to receive(:exists?) { true }
      expect(provider).to receive(:identity) { fake_id }
      provider.flush
    end
    it "destroy should unregister when resource shouldn't exist" do
      expect(provider).to receive(:execute).with(
      ['subscription-manager',['clean']],
      {:failonfail=>false, :combine=>true}) { true }
      expect(provider).to receive(:execute).with(
      ['subscription-manager',['unsubscribe','--all']],
      {:failonfail=>false, :combine=>true}) { true }
      expect(provider).to receive(:execute).with(
      ['subscription-manager',['unregister']],
      {:failonfail=>false, :combine=>true}) { true }
      res = Puppet::Type.type(:rhsm_register).new(
        :name     => title,
        :ensure   => :absent,
        :provider => provider)
        allow(provider).to receive(:exists?) { false }
        provider.destroy
        provider.flush
    end
  end

end
