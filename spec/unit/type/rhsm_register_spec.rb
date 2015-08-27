#!/usr/bin/ruby -S rspec
require 'spec_helper'

#rhsm_register { 'example.com':
#  server_insecure => false,
#  username        => 'registered_user',
#  password        => 'password123',
#  server_hostname => 'example.com',
#  server_prefix   => 'https',
#  rhsm_baseurl    => '/repos',
#  rhsm_cacert     => '/path/to/ca.pem',
#  username        => 'doej',
#  password        => 'password123',
#  activationkeys  => '1-my-activation-key',
#  pool            => 'my_awesome_subscription',
#  environment     => 'lab',
#  autosubscribe   => true,
#  force           => true,
#  org             => 'the cool organization',
# }

describe Puppet::Type.type(:rhsm_register), 'type' do

  [ :ensure, :username, :password, :server_prefix, :org,
    :rhsm_cacert, :username, :password, :activationkeys,
    :pool, :environment ].each { |property|
    it "should have a #{property} property" do
      expect(Puppet::Type.type(:rhsm_register).attrtype(property)).to eq(:property)
    end
  }

  context "for server_hostname" do
    it "should have a server_name parameter" do
      expect(Puppet::Type.type(:rhsm_register).attrtype(:server_hostname)).to eq(:param)
    end
    it 'should have a name equal too the server_hostname' do
      @resource = Puppet::Type.type(:rhsm_register).new(
        :server_hostname => 'foo')
      expect(@resource[:server_hostname]).to eq('foo')
      expect(@resource[:name]).to eq('foo')
    end
    it 'should reject non-hostname server_names' do
      expect{ Puppet::Type.type(:rhsm_register).new(
       :server_hostname => '@#$%foooooo^!)')}.to raise_error(
        Puppet::ResourceError, /.*/)
    end
  end

  [ :autosubscribe, :force ].each { |boolean_property|
    context "for #{boolean_property}" do
      it "should have an #{boolean_property} property" do
        expect(Puppet::Type.type(:rhsm_register).attrtype(boolean_property)).to eq(:property)
      end
      it 'should accept boolean values' do
        @resource = Puppet::Type.type(:rhsm_register).new(
         :server_hostname => 'foo', boolean_property => true)
        expect(@resource[boolean_property]).to eq(true)
        @resource = Puppet::Type.type(:rhsm_register).new(
         :server_hostname => 'bar', boolean_property => false)
        expect(@resource[boolean_property]).to eq(false)
      end
      it 'should reject non-boolean values' do
        expect{ Puppet::Type.type(:rhsm_register).new(
         :server_hostname => 'foo', boolean_property => 'bad date')}.to raise_error(
          Puppet::ResourceError, /.*/)
      end
    end
  }

  context "for server_insecure" do
    it "should have this parameter" do
      expect(Puppet::Type.type(:rhsm_register).attrtype(:server_insecure)).to eq(:param)
    end
    it 'should accept boolean values' do
      @resource = Puppet::Type.type(:rhsm_register).new(
       :server_hostname => 'foo', :server_insecure => true)
      expect(@resource[:server_insecure]).to eq(true)
      @resource = Puppet::Type.type(:rhsm_register).new(
       :server_hostname => 'bar', :server_insecure => false)
      expect(@resource[:server_insecure]).to eq(false)
    end
    it 'should reject non-boolean values' do
      expect{ Puppet::Type.type(:rhsm_register).new(
       :server_hostname => 'foo', :server_insecure => 'bad date')}.to raise_error(
        Puppet::ResourceError, /.*/)
    end
  end

  context "for rhsm_basueurl" do
    it "should have an rhsm_baseurl property" do
      expect(Puppet::Type.type(:rhsm_register).attrtype(:rhsm_baseurl)).to eq(:property)
    end
     it 'should accept url path values' do
       @resource = Puppet::Type.type(:rhsm_register).new(
        :server_hostname => 'foo', :rhsm_baseurl => '/')
       expect(@resource[:rhsm_baseurl]).to eq('/')
       @resource = Puppet::Type.type(:rhsm_register).new(
        :server_hostname => 'bar', :rhsm_baseurl => '/foo/bar')
       expect(@resource[:rhsm_baseurl]).to eq('/foo/bar')
     end
     it 'should reject path values' do
       expect{ Puppet::Type.type(:rhsm_register).new(
        :server_hostname => 'foo', :rhsm_baseurl => '@your_momma')}.to raise_error(
         Puppet::ResourceError, /.*/)
         expect{ Puppet::Type.type(:rhsm_register).new(
          :server_hostname => 'foo', :rhsm_baseurl => '$%!#^@(((')}.to raise_error(
           Puppet::ResourceError, /.*/)
     end
  end

  it 'should support enabled' do
    @resource = Puppet::Type.type(:rhsm_register).new(
      :server_hostname => 'foo', :ensure => :absent)
    expect(@resource[:ensure]).to eq(:absent)
  end
end
