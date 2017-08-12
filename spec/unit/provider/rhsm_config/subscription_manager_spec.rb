#!/usr/bin/ruby -S rspec
#
#  Test the subscrption_manager provider for rhsm_config
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'puppet'
require 'date'
require 'stringio'
require 'spec_helper'
require 'puppet/type/rhsm_register'

provider_class = Puppet::Type.type(:rhsm_config).provider(:subscrption_manager)

describe  provider_class, 'rhsm_config provider' do
  title = '/etc/rhsm/rhsm.conf' # type.$default_filename
  properties = {
  :name                         => title,
  :provider                     => :subscription_manager,
  :server_hostname              => 'katello.example.com',
  :server_insecure              => false,
  :server_port                  => 443,
  :server_prefix                => '/rhsm',
  :server_ssl_verify_depth      => 3,
  :rhsm_baseurl                 => 'https://katello.example.com/pulp/repos',
  :rhsm_ca_cert_dir             => '/etc/rhsm/ca/',
  :rhsm_consumercertdir         => '/etc/pki/consumer',
  :rhsm_entitlementcertdir      => '/etc/pki/entitlement',
  :rhsm_full_refresh_on_yum     => true,
  :rhsm_manage_repos            => true,
  :rhsm_pluginconfdir           => '/etc/rhsm/pluginconf.d',
  :rhsm_plugindir               => '/usr/share/rhsm-plugins',
  :rhsm_productcertdir          => '/etc/pki/product',
  :rhsm_repo_ca_cert            => '/etc/rhsm/ca/',
  :rhsm_report_package_profile  => true,
  :rhsmcertd_autoattachinterval => 1440,
  :server_proxy_hostname        => 'proxy.example.com',
  :server_proxy_user            => 'proxy_user',
  :server_proxy_password        => 'proxy_password',
  :server_proxy_port            => 4443,
 }

 config_file = '/etc/rhsm/rhsm.conf'

 raw_data =<<-EOD
 [server]
    hostname = katello.example.com
    insecure = [0]
    port = [443]
    prefix = /rhsm
    proxy_hostname = proxy.example.com
    proxy_password = proxy_password
    proxy_port = 4443
    proxy_user = proxy_user
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
    autoattachinterval = 1440

[] - Default value in use
EOD

raw_hostname01_data =<<-EOD
 [server]
    hostname = katello01.example.com
    insecure = [0]
    port = [443]
    prefix = /rhsm
    proxy_hostname = []
    proxy_password = []
    proxy_port = []
    proxy_user = []
    ssl_verify_depth = [3]

 [rhsm]
    baseurl = https://katello01.example.com/pulp/repos
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
    autoattachinterval = 1440

[] - Default value in use
EOD


  let(:resource) do
    Puppet::Type.type(:rhsm_config).new(properties)
  end

  let(:provider) do
    resource.provider
  end

  before :each do
    allow(provider.class).to receive(:suitable?) { true }
    allow(Puppet::Util).to receive(:which).with('subscription-manager') { 'subscription-manager' }
  end

  after :each do
  end

  it 'should have a resource from a generic list of parameters' do
    expect(resource).to_not eq(nil)
  end

  it 'should have a provider for a generic resource' do
    expect(provider).to_not eq(nil)
  end

  [ :create, :destroy ].each { |action|
    it "should respond to #{action}" do
      expect(provider).to respond_to(action)
    end
  }

  describe 'self.instances' do
    it { expect(provider.class).to respond_to(:instances) }
    context 'for expected values of properties' do
      properties.keys.each { |key|
        it "should be able to set the #{key} property" do
          expect(provider.class).to receive(:get_configuration) {
              {:name => title, :provider => provider, :ensure => :present} }
           configs = provider.class.instances
           config = configs[0]
           expect(config).to respond_to(key)
           # testing the raw parser output, not Puppetlab's munging support
           config.set( key => resource[key] )
           expect(config.public_send(key)).to eq(resource[key])
       end
      }
    end
    it "returns nothing for no data" do
      expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { '' }
      expect(provider.class.instances).to eq([])
    end

  end

  describe 'self.prefetch' do
    it { expect(provider.class).to respond_to(:prefetch) }
    it 'can be called on the provider' do
      expect(provider.class).to receive(:get_configuration) {  properties  }
      expect(provider.class.prefetch(properties)).to be_truthy
    end
  end


  context 'ensure' do
    it { expect(provider).to respond_to(:exists?) }
    it 'exists? should return false when the resource is absent' do
      @res = Puppet::Type.type(:rhsm_config).new(
      :name => title, :provider => provider, :ensure => :present)
      @res.provider.set(:server_insecure => false)
      @res.provider.set(:server_port     => 443)
      @res.provider.destroy
      expect(@res.provider.exists?).to eq(false)
    end
    it 'exists? should return true when the resource is present' do
      @res = Puppet::Type.type(:rhsm_config).new(:name => title, :provider => provider)
      @res.provider.set(:ensure          => :absent)
      @res.provider.set(:server_insecure => false)
      @res.provider.set(:server_port     => 443)
      @res.provider.set(:ensure => :present) # ensure is funny this way
      expect(@res.provider.exists?).to eq(true)
    end
    it 'create should configure options that should exist' do
      @res = Puppet::Type.type(:rhsm_config).new(:name => title, :provider => provider)
      @res.provider.set(:ensure          => :present)
      @res.provider.set(:server_insecure => false)
      @res.provider.set(:server_port     => 443)
      expect(@res.provider).to receive(:build_config_parameters) { { :apply => ['foo'], :remove => nil } }
      expect(@res.provider).to receive(:subscription_manager).with('foo')
      expect(@res.provider.class).to receive(:subscription_manager).with(["config","--list"]) {}
      allow(@res.provider).to receive(:exists?) { true }
      @res.provider.flush
    end
    it "destroy should try to remove the config when it shouldn't exist" do
      @res = Puppet::Type.type(:rhsm_config).new(:name => title, :provider => provider)
      @res.provider.set(:ensure => :absent)
      @res.provider.set(:server_insecure => false)
      @res.provider.set(:server_port     => 443)
      expect(@res.provider.class).to receive(:subscription_manager).with(
        'config', '--remove=server.insecure' )
      expect(@res.provider.class).to receive(:subscription_manager).with(
        'config', '--remove=server.port')
      expect(@res.provider.class).to receive(:subscription_manager).with(["config","--list"]) {}
      allow(@res.provider).to receive(:exists?) { false }
      @res.provider.flush
    end
  end


    describe 'get_configuration' do
      it 'returns nothing for an empty configuration' do
        expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { '' }
        config = provider.class.get_configuration
        expect(config.size).to eq(0)
      end
      it 'returns nothing for an garbage' do
        expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { 'asdlk;j12349567[[]]' }
        config = provider.class.get_configuration
        expect(config.size).to eq(0)
      end
      it 'returns as expected for example values' do
        expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { raw_data }
        config = provider.class.get_configuration
        expect(config.size).to_not eq(0)
        expect(config[:name]).to eq('/etc/rhsm/rhsm.conf')
        expect(config[:server_hostname]).to eq('katello.example.com')
        expect(config[:server_proxy_hostname]).to eq('proxy.example.com')
        expect(config[:provider]).to eq(:subscription_manager)
      end
      it 'accepts hostnames with numbers in them' do
        expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { raw_hostname01_data }
        config = provider.class.get_configuration
        expect(config.size).to_not eq(0)
        expect(config[:name]).to eq('/etc/rhsm/rhsm.conf')
        expect(config[:provider]).to eq(:subscription_manager)
        expect(config[:server_hostname]).to eq('katello01.example.com')
        expect(config[:rhsm_baseurl]).to eq('https://katello01.example.com/pulp/repos')
      end
      properties.keys.each { |key|
        next if key == :rhsm_repo_ca_cert
         it "should parse the #{key} property" do
            expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { raw_data }
            configs = provider.class.instances
            config = configs[0]
            expect(config.public_send(key)).to eq(resource[key])
        end
      }
      it "should parse the rhsm_repo_ca_cert property" do
         expect(File).to receive(:open).with('/etc/rhsm/rhsm.conf') { StringIO.new(raw_data) }
         expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { raw_data }
         configs = provider.class.instances
         config = configs[0]
         expect(config.public_send(:rhsm_repo_ca_cert)).to eq(resource[:rhsm_repo_ca_cert])
     end
     it "detects default options" do
       @resource = Puppet::Type.type(:rhsm_config).new(
         {:provider => provider, :name => title })
       expect(@resource.provider.class).to receive(:subscription_manager).with(['config','--list']) { raw_hostname01_data }
       config = @resource.provider.class.get_configuration
       expect(config.size).to_not eq(0)
       expect(@resource.provider.class.defaults_to?).to include(:server_port)
     end
    end

    describe 'build_config_parameters' do
      it 'returns nothing when provider or title are the only parameters' do
        @resource = Puppet::Type.type(:rhsm_config).new(
          {:provider => provider, :name => title })
        expect(@resource.provider.build_config_parameters(:apply)).to eq(
         { :apply => nil, :remove => nil})
      end
      it "skips empty options" do
        @resource = Puppet::Type.type(:rhsm_config).new(
          {:provider => provider, :name => title })
        @resource.provider.set(:server_port      => '')
        @resource[:server_port] = ''
        expect(@resource.provider.build_config_parameters(:apply)).to eq(
         { :apply => nil, :remove => nil})
      end
      it "removes set options using empty parameters" do
        @resource = Puppet::Type.type(:rhsm_config).new(
          {:provider => provider, :name => title })
        @resource.provider.set(:server_insecure  => '')
        @resource[:server_insecure] = 'false'
        @resource.provider.set(:server_port      => '')
        @resource[:server_port] = '8080'
        @resource.provider.set(:rhsm_ca_cert_dir => '')
        @resource[:rhsm_ca_cert_dir] = '/bin/foo'
        expect((@resource.provider.build_config_parameters(:apply)[:remove]).sort!).to eq(
        ["--remove=server.insecure", "--remove=server.port", "--remove=rhsm.ca_cert_dir"].sort!)
      end
      properties.keys.each { |key|
          if key == :provider or key == :name
            # provider is irrelevant to the operating system command
            # name is always passed in as name of the type
            next
          end
          it "returns the correct options for #{key}" do
          @resource = Puppet::Type.type(:rhsm_config).new(
            { :provider => provider, :name => title })
          @resource.provider.set(key => properties[key])
          if @resource.class.binary_options.include?(key)
            opt = @resource.class.binary_options[key]
            value = (properties[key] == true ) ? 1 : 0
            expect(@resource.provider.build_config_parameters(:apply)[:apply]).to eq([
              'config', "--#{opt}", "#{value}" ])
            expect(@resource.provider.build_config_parameters(:remove)[:remove]).to eq([
                "--remove=#{opt}" ])
          else
            opt = @resource.class.text_options[key]
            expect(@resource.provider.build_config_parameters(:apply)[:apply]).to eq([
              'config', "--#{opt}", properties[key].to_s
              ])
            expect(@resource.provider.build_config_parameters(:remove)[:remove]).to eq(
              [ "--remove=#{opt}" ])
          end
        end
      }
      it "correctly splits mixes of remove and create options into two commands" do
        @resource = Puppet::Type.type(:rhsm_config).new(
          {:provider => provider, :name => title, :server_port => 999,
            :rhsm_ca_cert_dir => '/foo'})
        @resource.provider.set(:server_insecure  => false)
        @resource.provider.set(:server_port      => nil)
        @resource.provider.set(:rhsm_ca_cert_dir => "/etc/rhsm/ca/")
        combo = @resource.provider.build_config_parameters(:apply)
        apply_expected = [ "config", "--rhsm.ca_cert_dir", "/etc/rhsm/ca/",
          "--server.insecure", "0"].sort!
        remove_expected = [ "--remove=server.port"].sort!
        expect((combo[:apply]).sort!).to eq(apply_expected)
        expect((combo[:remove]).sort!).to eq(remove_expected)
      end
      it "correctly combines several options into a command" do
        @resource = Puppet::Type.type(:rhsm_config).new(
          {:provider => provider, :name => title })
        @resource.provider.set(:server_insecure  => false)
        @resource.provider.set(:server_port      => 443)
        @resource.provider.set(:rhsm_ca_cert_dir => '/etc/rhsm/ca/')
        apply = @resource.provider.build_config_parameters(:apply)
        expect(apply[:apply].sort!).to eq([
          'config',
          "--server.port", "443", "--rhsm.ca_cert_dir", "/etc/rhsm/ca/", "--server.insecure", "0"
        ].sort!)
        expect(apply[:remove]).to eq(nil)
        remove = @resource.provider.build_config_parameters(:remove)
        expect(remove[:apply]).to eq(nil)
        expect(remove[:remove].sort!).to eq([
            "--remove=server.port", "--remove=rhsm.ca_cert_dir", "--remove=server.insecure" ].sort!)
      end
      it "skips default options" do
        @resource = Puppet::Type.type(:rhsm_config).new(
          {:provider => provider, :name => title })
        @resource.provider.set(:server_insecure  => false)
        @resource.provider.set(:server_port      => 443)
        @resource.provider.set(:rhsm_ca_cert_dir => '/etc/rhsm/ca/')
        @resource.provider.class.defaults_to = [ :server_port ]
        apply = @resource.provider.build_config_parameters(:apply)
        expect(apply).to_not include(:server_port)
      end
    end
end
