#!/usr/bin/ruby -S rspec
require 'puppet'
require 'date'
require 'spec_helper'
require 'puppet/type/rhsm_register'

provider_class = Puppet::Type.type(:rhsm_config).provider(:subscrption_manager)

describe  provider_class, 'rhsm_config provider' do
  title = '/etc/rhsm/rhsm.conf' # type.$default_filename
  properties = {
  :name                        => title,
  :provider                    => :subscription_manager,
  :server_hostname             => 'katello.example.com',
  :server_insecure             => false,
  :server_port                 => 443,
  :server_prefix               => '/rhsm',
  :server_ssl_verify_depth     => 3,
  :rhsm_baseurl                => 'https://katello.example.com/pulp/repos',
  :rhsm_ca_cert_dir            => '/etc/rhsm/ca/',
  :rhsm_consumercertdir        => '/etc/pki/consumer',
  :rhsm_entitlementcertdir     => '/etc/pki/entitlement',
  :rhsm_full_refresh_on_yum    => true,
  :rhsm_manage_repos           => true,
  :rhsm_pluginconfdir          => '/etc/rhsm/pluginconf.d',
  :rhsm_plugindir              => '/usr/share/rhsm-plugins',
  :rhsm_productcertdir         => '/etc/pki/product',
  :rhsm_repo_ca_cert           => '/etc/rhsm/ca/',
  :rhsm_report_package_profile => true,
  :rhsmcertd_autoattachinterval => 1440,
 }

 config_file = '/etc/rhsm/rhsm.conf'

 raw_data =<<-EOD
 [server]
    hostname = katello.example.com
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
    autoattachinterval = 1440
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
    context 'should parse the expected values for properties' do
      properties.keys.each { |key|
         it "such as the #{key} property" do
            expect(provider.class).to receive(:config?) { true }
            expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { raw_data }
            pools = provider.class.instances
            pool = pools[0]
            expect(pool).to respond_to(key)
            # testing the raw parser output, not Puppetlab's munging support
            testvalue = resource[key]
            testvalue = 1 if testvalue == true
            testvalue = 0 if testvalue == false
            expect(pool.public_send(key)).to eq(testvalue)
        end
      }
    end
  end

  describe 'self.prefetch' do
    it { expect(provider.class).to respond_to(:prefetch) }
    it 'can be called on the provider' do
      props = properties.merge({ :name => title, })
      expect(provider.class).to receive(:get_configuration) {  props  }
      expect(provider.class.prefetch(props)).to be_truthy
    end
  end


  context 'ensure' do
    it { expect(provider).to respond_to(:exists?) }
    it 'exists? should return false when the resource is absent' do
      @res = Puppet::Type.type(:rhsm_config).new(
        :name            => title,
        :ensure          => :present,
        :server_hostname => 'foo',
        :server_insecure => false,
        :server_port     => 443,
        :provider        => provider)
      @res.provider.destroy
      expect(@res.provider.exists?).to eq(false)
    end
    it 'exists? should return true when the resource is present' do
      @res = Puppet::Type.type(:rhsm_config).new(
        :name            => title,
        :ensure          => :absent,
        :server_hostname => 'foo',
        :server_insecure => false,
        :server_port     => 443,
        :provider        => provider)
      @res.provider.set(:ensure => :present) # ensure is funny this way
      expect(@res.provider.exists?).to eq(true)
    end
    it 'create should configure options that should exist' do
      @res = Puppet::Type.type(:rhsm_config).new(
        :name            => title,
        :ensure          => :present,
        :server_hostname => 'foo',
        :server_insecure => false,
        :server_port     => 443,
        :provider        => provider)
      expect(@res.provider).to receive(:build_config_parameters) { ['foo'] }
      expect(@res.provider).to receive(:subscription_manager).with('foo')
      allow(@res.provider).to receive(:exists?) { true }
      @res.provider.flush
    end
    it "destroy should try to remove the config when it shouldn't exist" do
      @res = Puppet::Type.type(:rhsm_config).new(
      :name            => title,
      :ensure          => :absent,
      :server_insecure => false,
      :server_port     => 443,
      :provider        => provider)
      expect(@res.provider.class).to receive(:subscription_manager).with(
        "config", "--remove=server.port", "--remove=server.insecure"
      )
      allow(@res.provider).to receive(:exists?) { false }
      @res.provider.flush
    end
  end


    describe 'get_configuration' do
      it 'returns nothing for a missing file' do
        expect(provider.class).to receive(:config?) { false }
        expect(provider.class).to_not receive(:subscription_manager)
        config = provider.class.get_configuration
        expect(config.size).to eq(0)
      end
      it 'returns nothing for an empty configuration' do
        expect(provider.class).to receive(:config?) { true }
        expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { '' }
        config = provider.class.get_configuration
        expect(config.size).to eq(0)
      end
      it 'returns nothing for an garbage' do
        expect(provider.class).to receive(:config?) { true }
        expect(provider.class).to receive(:subscription_manager).with(['config','--list']) { 'asdlk;j12349567[[]]' }
        config = provider.class.get_configuration
        expect(config.size).to eq(0)
      end
    end

    describe 'build_config_parameters' do
      it 'returns nothing for missing parameters' do
        @resource = Puppet::Type.type(:rhsm_config).new({ :provider => provider, :name => title })
        expect(@resource.provider.build_config_parameters(:apply)).to be(nil)
      end
        properties.keys.each { |key|
          if key == :provider or key == :name
            # provider is irrelevant to the operating system command
            # name is always passed in as name of the type
            next
          end
          it "returns the correct options for #{key}" do
          @resource = Puppet::Type.type(:rhsm_config).new({ :provider => provider, :name => title, key => properties[key] })
          if @resource.class.binary_options.include?(key)
            opt = @resource.class.binary_options[key]
            value = (properties[key] == true ) ? 1 : 0
            expect(@resource.provider.build_config_parameters(:apply)).to eq([
              'config', ["--#{opt}", "#{value}"]
              ])
            expect(@resource.provider.build_config_parameters(:remove)).to eq([
                'config', "--remove=#{opt}" ])
          else
            opt = @resource.class.regular_options[key]
            expect(@resource.provider.build_config_parameters(:apply)).to eq([
              'config', "--#{opt}", properties[key]
              ])
            expect(@resource.provider.build_config_parameters(:remove)).to eq([
              'config', "--remove=#{opt}" ])
          end
        end
        }
        it "correctly combines several options into a command" do
          @resource = Puppet::Type.type(:rhsm_config).new({
            :provider         => provider,
            :name             => title,
            :server_insecure  => false,
            :server_port      => 443,
            :rhsm_ca_cert_dir => '/etc/rhsm/ca/'
              })
          expect(@resource.provider.build_config_parameters(:apply)).to eq([
            'config',
            "--server.port", 443, "--rhsm.ca_cert_dir", "/etc/rhsm/ca/", ["--server.insecure", "0"]
            ])
          expect(@resource.provider.build_config_parameters(:remove)).to eq([
              'config',  "--remove=server.port", "--remove=rhsm.ca_cert_dir", "--remove=server.insecure" ])
        end
    end
end
