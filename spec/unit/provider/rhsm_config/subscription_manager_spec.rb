#!/usr/bin/ruby -S rspec
# frozen_string_literal: false

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

describe  provider_class, '#rhsm_config.provider' do
  title = '/etc/rhsm/rhsm.conf' # type.$default_filename
  properties = {
    name: title,
    provider: :subscription_manager,
    server_hostname: 'katello.example.com',
    server_insecure: false,
    server_port: 443,
    server_prefix: '/rhsm',
    server_ssl_verify_depth: 3,
    rhsm_baseurl: 'https://katello.example.com/pulp/repos',
    rhsm_ca_cert_dir: '/etc/rhsm/ca/',
    rhsm_consumercertdir: '/etc/pki/consumer',
    rhsm_entitlementcertdir: '/etc/pki/entitlement',
    rhsm_full_refresh_on_yum: 1,
    rhsm_manage_repos: 1,
    rhsm_pluginconfdir: '/etc/rhsm/pluginconf.d',
    rhsm_plugindir: '/usr/share/rhsm-plugins',
    rhsm_productcertdir: '/etc/pki/product',
    rhsm_repo_ca_cert: '/etc/rhsm/ca/',
    rhsm_report_package_profile: 1,
    rhsmcertd_autoattachinterval: 1440,
    server_proxy_hostname: 'proxy.example.com',
    server_proxy_user: 'proxy_user',
    server_proxy_password: 'proxy_password',
    server_proxy_port: 4443
  }

  # config_file is '/etc/rhsm/rhsm.conf'

  raw_data = <<-EOD
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

  raw_values = {
    server_hostname: 'katello.example.com',
    server_insecure: 0,
    server_port: 443,
    server_prefix: '/rhsm',
    server_proxy_hostname: 'proxy.example.com',
    server_proxy_password: 'proxy_password',
    server_proxy_port: 4443,
    server_proxy_user: 'proxy_user',
    server_ssl_verify_depth: 3,
    rhsm_baseurl: 'https://katello.example.com/pulp/repos',
    rhsm_ca_cert_dir: '/etc/rhsm/ca/',
    rhsm_consumercertdir: '/etc/pki/consumer',
    rhsm_entitlementcertdir: '/etc/pki/entitlement',
    rhsm_full_refresh_on_yum: 1,
    rhsm_manage_repos: 1,
    rhsm_pluginconfdir: '/etc/rhsm/pluginconf.d',
    rhsm_plugindir: '/usr/share/rhsm-plugins',
    rhsm_productcertdir: '/etc/pki/product',
    rhsm_repo_ca_cert: '/etc/rhsm/ca/',
    rhsm_report_package_profile: 1,
    rhsmcertd_autoattachinterval: 1440
  }

  raw_hostname01_data = <<-EOD
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

  raw_hostname01_values = {
    server_hostname: 'katello01.example.com',
    rhsm_baseurl: 'https://katello01.example.com/pulp/repos'
  }

  let(:resource) do
    Puppet::Type.type(:rhsm_config).new(properties)
  end

  let(:provider) do
    resource.provider
  end

  before :each do
    allow(provider.class).to receive(:suitable?).and_return(true)
    allow(Puppet::Util).to receive(:which).with('subscription-manager').and_return('subscription-manager')
  end

  after :each do
  end

  it 'has a resource from a generic list of parameters' do
    expect(resource).not_to eq(nil)
  end

  it 'has a provider for a generic resource' do
    expect(provider).not_to eq(nil)
  end

  [:create, :destroy].each do |action|
    it "should respond to #{action}" do
      expect(provider).to respond_to(action)
    end
  end

  describe 'self.instances' do
    it { expect(provider.class).to respond_to(:instances) }
    context 'for expected values of properties' do
      properties.keys.each do |key|
        it "should be able to set the #{key} property" do
          expect(provider.class).to receive(:on_disk_configuration).and_return(
            name: title, provider: provider, ensure: :present,
          )
          configs = provider.class.instances
          config = configs[0]
          expect(config).to respond_to(key)
          # testing the raw parser output, not Puppetlab's munging support
          config.set(key => resource[key])
          expect(config.public_send(key)).to eq(resource[key])
        end
      end
    end
    it 'returns nothing for no data' do
      expect(provider.class).to receive(:subscription_manager).with(['config', '--list']).and_return('')
      expect(provider.class.instances).to eq([])
    end
  end

  describe 'self.prefetch' do
    it { expect(provider.class).to respond_to(:prefetch) }
    it 'can be called on the provider' do
      expect(provider.class).to receive(:on_disk_configuration).and_return(properties)
      expect(provider.class.prefetch(properties)).to be_truthy
    end
  end

  context 'ensure' do
    it { expect(provider).to respond_to(:exists?) }
    it 'exists? should return false when the resource is absent' do
      res = Puppet::Type.type(:rhsm_config).new(
        name: title, provider: provider, ensure: :present,
      )
      res.provider.set(server_insecure: false)
      res.provider.set(server_port: 443)
      res.provider.destroy
      expect(res.provider.exists?).to eq(false)
    end
    it 'exists? should return true when the resource is present' do
      res = Puppet::Type.type(:rhsm_config).new(name: title, provider: provider)
      res.provider.set(ensure: :absent)
      res.provider.set(server_insecure: false)
      res.provider.set(server_port: 443)
      res.provider.set(ensure: :present) # ensure is funny this way
      expect(res.provider.exists?).to eq(true)
    end
    it 'create should configure options that should exist' do
      res = Puppet::Type.type(:rhsm_config).new(name: title, provider: provider)
      res.provider.set(ensure: :present)
      res.provider.set(server_insecure: false)
      res.provider.set(server_port: 443)
      expect(res.provider).to receive(:build_config_parameters).with(:apply).and_return(apply: ['foo'], remove: nil)
      expect(res.provider).to receive(:subscription_manager).with(['config', 'foo'])
      expect(res.provider.class).to receive(:subscription_manager).with(['config', '--list']).and_return(nil)
      allow(res.provider).to receive(:exists?).and_return(true)
      res.provider.flush
    end
    it "destroy should try to remove the config when it shouldn't exist" do
      res = Puppet::Type.type(:rhsm_config).new(name: title, provider: provider)
      res.provider.set(ensure: :absent)
      res.provider.set(server_insecure: false)
      res[:server_insecure] = true
      res.provider.set(server_port: 443)
      res[:server_port] = 8080
      expect(res.provider).to receive(:exists?).and_call_original
      expect(res.provider).to receive(:build_config_parameters).with(:remove).and_call_original
      expect(res.provider).to receive(:subscription_manager).with(
        'config', '--remove=server.insecure'
      )
      expect(res.provider).to receive(:subscription_manager).with(
        'config', '--remove=server.port'
      )
      expect(res.provider.class).to receive(:subscription_manager).with(['config', '--list']) {}
      res.provider.flush
    end
  end

  #
  # Test the helper methods
  #
  describe 'on_disk_configuration' do
    it 'returns nothing for an empty configuration' do
      expect(provider.class).to receive(:subscription_manager).with(['config', '--list']).and_return('')
      expect(provider.class).to receive(:ini_parse).with('').and_return('')
      expect(provider.class.on_disk_configuration.size).to eq(0)
    end
    it 'returns nothing for garbage' do
      expect(provider.class).to receive(:subscription_manager).with(['config', '--list']).and_return('asdlk;j12349567[[]]')
      expect(provider.class).to receive(:ini_parse).with('asdlk;j12349567[[]]').and_return('')
      expect(provider.class.on_disk_configuration.size).to eq(0)
    end
    it 'returns as expected for example values' do
      expect(provider.class).to receive(:subscription_manager).with(['config', '--list']).and_return(raw_data)
      expect(provider.class).to receive(:ini_parse).and_return(raw_values)
      expect(provider.class).to receive(:repo_cert).with('/etc/rhsm/rhsm.conf').and_return('/etc/rhsm/ca/')
      config = provider.class.on_disk_configuration
      # expect(config.size).not_to eq(0)
      expect(config[:name]).to eq('/etc/rhsm/rhsm.conf')
      expect(config[:server_hostname]).to eq('katello.example.com')
      expect(config[:server_proxy_hostname]).to eq('proxy.example.com')
      expect(config[:server_insecure]).to eq(0)
      expect(config[:provider]).to eq(:subscription_manager)
      expect(config[:rhsm_repo_ca_cert]).to eq('/etc/rhsm/ca/')
    end
    it 'accepts hostnames with numbers in them' do
      expect(provider.class).to receive(:subscription_manager).with(['config', '--list']).and_return(raw_hostname01_data)
      expect(provider.class).to receive(:ini_parse).and_return(raw_hostname01_values)
      expect(provider.class).to receive(:repo_cert).with('/etc/rhsm/rhsm.conf').and_return('/etc/rhsm/ca/')
      config = provider.class.on_disk_configuration
      # expect(config.size).not_to eq(0)
      expect(config[:name]).to eq('/etc/rhsm/rhsm.conf')
      expect(config[:provider]).to eq(:subscription_manager)
      expect(config[:server_hostname]).to eq('katello01.example.com')
      expect(config[:rhsm_baseurl]).to eq('https://katello01.example.com/pulp/repos')
      expect(config[:rhsm_repo_ca_cert]).to eq('/etc/rhsm/ca/')
    end
  end

  describe 'repo_cert' do
    it 'returns nothing for an empty configuration' do
      expect(provider.class.repo_cert('')).to eq(nil)
    end
    it 'returns nothing for garbage' do
      expect(provider.class.repo_cert('asdlk;j12349567[[]]')).to eq(nil)
    end
    it 'returns nothing if reading the file read fails' do
      expect(File).to receive(:open).with('foo') { throw IOError }
      expect(provider.class.repo_cert('foo')).to eq(nil)
    end
    it 'returns a reopsitory certificate' do
      expect(File).to receive(:open).with('foo').and_return(StringIO.new(raw_data))
      expect(provider.class.repo_cert('foo')).to eq('/etc/rhsm/ca/')
    end
  end

  describe 'ini_parse' do
    it 'returns nothing for an empty configuration' do
      expect(provider.class.ini_parse('')).to eq({})
    end
    it 'returns nothing for garbage' do
      expect(provider.class.ini_parse('asdlk;j12349567[[]]')).to eq({})
    end
    properties.keys.each do |key|
      next if [:rhsm_repo_ca_cert, :name, :provider].include? key
      it "parse the #{key} property" do
        expect(provider.class.ini_parse(raw_data)[key]).to eq(raw_values[key])
      end
    end
  end

  describe 'convert_to_binary' do
    it 'returns 0 for empty values' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      expect(resource.provider.convert_to_binary(nil)).to eq(0)
      expect(resource.provider.convert_to_binary('')).to eq(0)
    end
    it 'returns 0 for false values' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      expect(resource.provider.convert_to_binary(false)).to eq(0)
      expect(resource.provider.convert_to_binary('false')).to eq(0)
      expect(resource.provider.convert_to_binary(0)).to eq(0)
    end
    it 'returns 1 for true values' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      expect(resource.provider.convert_to_binary(true)).to eq(1)
      expect(resource.provider.convert_to_binary('true')).to eq(1)
      expect(resource.provider.convert_to_binary(1)).to eq(1)
    end
  end

  describe 'resolve_value' do
    it 'returns nil during removal' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      expect(resource.provider.resolve_value(:remove, 'foo', 'bar')).to eq(nil)
    end
    # moved into build_parameters
    # it 'has an error if the parameter is not valid' do
    #  resource = Puppet::Type.type(:rhsm_config).new(
    #    provider: provider, name: title,
    #  )
    #  expect { resource.provider.resolve_value(:not_remove,
    #    'foo', 'bar') }.to raise_error(Puppet::Error)
    # end
    it 'returns original value when we did not have a any resource param' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      expect(resource.provider.resolve_value(:not_remove, :rhsm_repo_ca_cert,
                                             'bar')).to eq('bar')
      expect(resource.provider.resolve_value(:not_remove, :rhsm_repo_ca_cert,
                                             1)).to eq(1)
      expect(resource.provider.resolve_value(:not_remove, :rhsm_repo_ca_cert,
                                             false)).to eq(false)
    end
    it 'returns same value when we did not have a difference in string param' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(rhsm_repo_ca_cert: '/bin/foo')
      resource[:rhsm_repo_ca_cert] = '/bin/foo'
      expect(resource.provider.resolve_value(:not_remove, :rhsm_repo_ca_cert,
                                             'bar')).to eq('bar')
      expect(resource.provider.resolve_value(:not_remove, :rhsm_repo_ca_cert,
                                             1)).to eq(1)
      expect(resource.provider.resolve_value(:not_remove, :rhsm_repo_ca_cert,
                                             false)).to eq(false)
    end
    it 'returns int value when we did not have a difference in boolean param' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(server_insecure: 'true')
      resource[:server_insecure] = 'true'
      expect(resource.provider.resolve_value(:not_remove, :server_insecure,
                                             true)).to eq(1)
      expect(resource.provider.resolve_value(:not_remove, :server_insecure,
                                             1)).to eq(1)
      expect(resource.provider.resolve_value(:not_remove, :server_insecure,
                                             false)).to eq(0)
    end
    it 'returns String value when we did have a differing text resource param' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(rhsm_repo_ca_cert: '')
      resource[:rhsm_repo_ca_cert] = '/bin/foo'
      expect(resource.provider.resolve_value(:not_remove, :rhsm_repo_ca_cert,
                                             'bar')).to eq('bar')
    end
    it 'returns int value when we did have a difference in boolean param' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(server_insecure: 'true')
      resource[:server_insecure] = 'false'
      expect(resource.provider).to receive(:convert_to_binary).with(false).and_return(0)
      expect(resource.provider.resolve_value(:not_remove, :server_insecure,
                                             false)).to eq(0)
    end
    it 'returns quoted numeric value when we did have a differing text resource param' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(server_proxy_port: 42)
      resource[:server_proxy_port] = 12_346
      expect(resource.provider.resolve_value(:not_remove, :server_proxy_port,
                                             69)).to eq(69)
    end
    it 'returns 1 for true boolean parameters' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(rhsm_full_refresh_on_yum: true)
      resource[:rhsm_full_refresh_on_yum] = false
      expect(resource.provider.resolve_value(:not_remove, :rhsm_full_refresh_on_yum,
                                             true)).to eq(1)
    end
    it 'returns 0 for false boolean parameters' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(rhsm_full_refresh_on_yum: false)
      resource[:rhsm_full_refresh_on_yum] = true
      expect(resource.provider.resolve_value(:not_remove, :rhsm_full_refresh_on_yum,
                                             false)).to eq(0)
    end
  end

  describe 'build_config_parameters' do
    it 'returns nothing when provider or title are the only parameters' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      expect(resource.provider.build_config_parameters(:apply)).to eq(
        apply: nil, remove: nil,
      )
    end
    it 'removes set options using empty parameters' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(server_insecure: '')
      resource[:server_insecure] = 'false'
      resource.provider.set(server_port: '')
      resource[:server_port] = '8080'
      resource.provider.set(rhsm_ca_cert_dir: '')
      resource[:rhsm_ca_cert_dir] = '/bin/foo'
      expect(resource.provider).to receive(:resolve_value).with(:remove, :server_insecure, '').and_return(nil)
      expect(resource.provider).to receive(:resolve_value).with(:remove, :server_port, '').and_return(nil)
      expect(resource.provider).to receive(:resolve_value).with(:remove, :rhsm_ca_cert_dir, '').and_return(nil)
      result = resource.provider.build_config_parameters(:remove)
      expect(result).not_to eq(nil)
      expect(result.keys.sort).to eq([:apply, :remove])
      expect(result[:remove]).not_to eq(nil)
      expect(result[:remove].sort).to eq(
        ['--remove=server.insecure', '--remove=server.port', '--remove=rhsm.ca_cert_dir'].sort,
      )
    end
    properties.keys.each do |key|
      if [:provider, :name].include? key
        # provider is irrelevant to the operating system command
        # name is always passed in as name of the type
        next
      end
      it "returns the correct options for #{key}" do
        resource = Puppet::Type.type(:rhsm_config).new(
          provider: provider, name: title,
        )
        resource.provider.set(key => properties[key])
        if Puppet::Type.type(:rhsm_config).binary_options.key?(key)
          binary_opt = Puppet::Type.type(:rhsm_config).binary_options[key]
          value = (properties[key] == true) ? 1 : 0
          expect(resource.provider).to receive(:resolve_value).and_return(value)
          expect(resource.provider.build_config_parameters(:apply)[:apply]).to eq([
                                                                                    "--#{binary_opt}=#{value}"
                                                                                  ])
          expect(resource.provider).to receive(:resolve_value).and_return(nil)
          expect(resource.provider.build_config_parameters(:remove)[:remove]).to eq(["--remove=#{binary_opt}"])
        else
          text_opt = resource.class.text_options[key]
          value = properties[key].to_s
          expect(resource.provider).to receive(:resolve_value).and_call_original
          expect(resource.provider.build_config_parameters(:apply)[:apply]).to eq(["--#{text_opt}=#{value}"])
          expect(resource.provider).to receive(:resolve_value).and_return(nil)
          expect(resource.provider.build_config_parameters(:remove)[:remove]).to eq(["--remove=#{text_opt}"])
        end
      end
    end
    it 'correctly splits mixes of remove and create options into two commands' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title, server_port: 999,
        rhsm_ca_cert_dir: '/foo'
      )
      resource.provider.set(server_insecure: false)
      resource[:server_insecure] = 'true'
      resource.provider.set(server_port: nil)
      resource.provider.set(rhsm_ca_cert_dir: '/etc/rhsm/ca/')
      combo = resource.provider.build_config_parameters(:apply)
      apply_expected = ['--rhsm.ca_cert_dir=/etc/rhsm/ca/',
                        '--server.insecure=0'].sort
      remove_expected = ['--remove=server.port']
      expect((combo[:apply]).sort!).to eq(apply_expected)
      expect((combo[:remove]).sort!).to eq(remove_expected)
    end
    it 'correctly combines several options into a command' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(server_insecure: false)
      resource.provider.set(server_port: 443)
      resource.provider.set(rhsm_ca_cert_dir: '/etc/rhsm/ca/')
      apply = resource.provider.build_config_parameters(:apply)
      expect(apply[:apply].sort!).to eq([
        '--server.port=443', '--rhsm.ca_cert_dir=/etc/rhsm/ca/', '--server.insecure=0'
      ].sort!)
      expect(apply[:remove]).to eq(nil)
      remove = resource.provider.build_config_parameters(:remove)
      expect(remove[:apply]).to eq(nil)
      expect(remove[:remove].sort!).to eq([
        '--remove=server.port', '--remove=rhsm.ca_cert_dir', '--remove=server.insecure'
      ].sort!)
    end
    it 'does not skip default options' do
      resource = Puppet::Type.type(:rhsm_config).new(
        provider: provider, name: title,
      )
      resource.provider.set(server_insecure: false)
      resource.provider.set(server_port: 443)
      resource.provider.set(rhsm_ca_cert_dir: '/etc/rhsm/ca/')
      resource.provider.class.defaults_to = [:server_port]
      apply = resource.provider.build_config_parameters(:apply)[:apply]
      expect(apply).to include('--server.insecure=0')
    end
  end
end
