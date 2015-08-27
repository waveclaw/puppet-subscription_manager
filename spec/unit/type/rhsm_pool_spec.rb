#!/usr/bin/ruby -S rspec
require 'spec_helper'

#  rhsm_pool { '1a2b3c4d5e6f1234567890abcdef12345':
#    name              => 'Extra Packages for Enterprise Linux',
#    ensure            => present,
#    provides          => 'EPEL',
#    sku               => 1234536789012,
#    contract          => 'Fancy Widgets, LTD',
#    account           => '1234-12-3456-0001',
#    serial            => '1234567890123456789',
#    id                => 1a2b3c4d5e6f1234567890abcdef12345,
#    active            => true,
#    quantity_used     => 1,
#    service_level     => 'STANDARD',
#    service_type      => 'EOL',
#    status_details    => 'expired',
#    subscription_type => 'permanent',
#    starts            => 06/01/2015,
#    ends              => 05/24/2045,
#    system_type       => physical,
#}

describe Puppet::Type.type(:rhsm_pool), 'type' do

    [ :name, :ensure, :provides, :sku, :contract, :account, :serial,
      :active, :quantity_used, :service_level, :service_type,
      :status_details, :subscription_type, :starts, :ends,:system_type,
    ].each { |property|
      it "should have a #{property} property" do
        expect(Puppet::Type.type(:rhsm_pool).attrtype(property)).to eq(:property)
      end
    }
    it "should have a content_labal parameter" do
      expect(Puppet::Type.type(:rhsm_pool).attrtype(:id)).to eq(:param)
    end
    it 'should accept a name' do
      @resource = Puppet::Type.type(:rhsm_pool).new(
        :id => '123abc')
      expect(@resource[:id]).to eq('123abc')
      expect(@resource[:name]).to eq('123abc')
    end
    it 'should reject non-hex names' do
      expect{ Puppet::Type.type(:rhsm_pool).new(
       :id => 'foobar')}.to raise_error(
        Puppet::ResourceError, /.*/)
    end

    it 'should support enabled' do
      @resource = Puppet::Type.type(:rhsm_pool).new(
        :id => '123abc', :ensure => :absent)
      expect(@resource[:ensure]).to eq(:absent)
    end
    it 'should accept date starts properties' do
      testdate = Date.parse('2000/01/01')
      @resource = Puppet::Type.type(:rhsm_pool).new(
       :id => '123abc', :starts => testdate)
      expect(@resource[:starts]).to eq(testdate)
    end
    it 'should reject non-date starts properties' do
      expect{ Puppet::Type.type(:rhsm_pool).new(
       :id => '123abc', :starts => 'bad date')}.to raise_error(
        Puppet::ResourceError, /.*/)
    end
    it 'should accept ends ends properties' do
      testdate = Date.parse('2000/01/01')
      @resource = Puppet::Type.type(:rhsm_pool).new(
       :id => '123abc', :ends => testdate)
      expect(@resource[:ends]).to eq(testdate)
    end
    it 'should reject non-date ends properties' do
      expect{ Puppet::Type.type(:rhsm_pool).new(
       :id => '123abc', :ends => 'bad date')}.to raise_error(
        Puppet::ResourceError, /.*/)
    end
end
