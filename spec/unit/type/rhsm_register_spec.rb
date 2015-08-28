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

described_class = Puppet::Type.type(:rhsm_register)

describe described_class, 'type' do

  [ :ensure, :username, :password, :server_prefix, :org,
    :rhsm_cacert, :username, :password, :activationkeys,
    :pool, :environment ].each { |property|
      context "for #{property}" do
        it "should be of type property" do
          expect(described_class.attrtype(property)).
            to eq(:property)
        end
        it "should be of class property" do
          expect(described_class.attrclass(property).ancestors).
            to include(Puppet::Property)
        end
        it "should have documentation" do
          expect(described_class.attrclass(property).doc.strip).
            not_to be_empty
        end
      end
      }

  context "for server_hostname" do
    it "should have a server_name parameter" do
      expect(described_class.attrtype(:server_hostname)).to eq(:param)
    end
    it "should have documentation" do
      expect(described_class.attrclass(:server_hostname).doc.strip).
        not_to be_empty
    end
    it 'should have a name equal too the server_hostname' do
      @resource = described_class.new(
        :server_hostname => 'foo')
      expect(@resource[:server_hostname]).to eq('foo')
      expect(@resource[:name]).to eq('foo')
    end
    it 'should reject non-hostname server_names' do
      expect{ described_class.new(
       :server_hostname => '@#$%foooooo^!)')}.to raise_error(
        Puppet::ResourceError, /.*/)
    end
  end

  [ :server_insecure, :autosubscribe, :force ].each { |boolean_parameter|
    context "for #{boolean_parameter}" do
      it "should be a parameter" do
        expect(described_class.attrtype(boolean_parameter)).to eq(:param)
      end
      it "should have boolean class" do
        expect(described_class.attrclass(boolean_parameter).ancestors).
          to include(Puppet::Parameter::Boolean)
      end
      it "should have documentation" do
        expect(described_class.attrclass(boolean_parameter).doc.strip).
          not_to be_empty
      end
      it 'should accept boolean values' do
        @resource = described_class.new(
         :server_hostname => 'foo', boolean_parameter => true)
        expect(@resource[boolean_parameter]).to eq(true)
        @resource = described_class.new(
         :server_hostname => 'bar', boolean_parameter => false)
        expect(@resource[boolean_parameter]).to eq(false)
      end
      it 'should reject non-boolean values' do
        expect{ described_class.new(
         :server_hostname => 'foo', boolean_parameter => 'bad date')}.to raise_error(
          Puppet::ResourceError, /.*/)
      end
    end
  }

  context "for rhsm_basueurl" do
    it "should have an rhsm_baseurl property" do
      expect(described_class.attrtype(:rhsm_baseurl)).to eq(:property)
    end
     it 'should accept url path values' do
       @resource = described_class.new(
        :server_hostname => 'foo', :rhsm_baseurl => '/')
       expect(@resource[:rhsm_baseurl]).to eq('/')
       @resource = described_class.new(
        :server_hostname => 'bar', :rhsm_baseurl => '/foo/bar')
       expect(@resource[:rhsm_baseurl]).to eq('/foo/bar')
     end
     it 'should reject path values' do
       expect{ described_class.new(
        :server_hostname => 'foo', :rhsm_baseurl => '@your_momma')}.to raise_error(
         Puppet::ResourceError, /.*/)
         expect{ described_class.new(
          :server_hostname => 'foo', :rhsm_baseurl => '$%!#^@(((')}.to raise_error(
           Puppet::ResourceError, /.*/)
     end
  end

  it 'should support enabled' do
    @resource = described_class.new(
      :server_hostname => 'foo', :ensure => :absent)
    expect(@resource[:ensure]).to eq(:absent)
  end
end
