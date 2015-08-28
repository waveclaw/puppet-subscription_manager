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

described_class = Puppet::Type.type(:rhsm_pool)

describe described_class, 'type' do

    [ :name, :ensure, :provides, :sku, :contract, :account, :serial,
      :active, :quantity_used, :service_level, :service_type,
      :status_details, :subscription_type, :starts, :ends,:system_type,
    ].each { |property|
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
    it "should have an id parameter" do
      expect(described_class.attrtype(:id)).to eq(:param)
      expect(described_class.attrclass(:id).ancestors).to include(Puppet::Parameter)
    end
    it "should have documentation for the id parameter" do
      expect(described_class.attrclass(:id).doc.strip).not_to be_empty
    end
    it 'should get a name from the id' do
      @resource = described_class.new(
        :id => '123abc')
      expect(@resource[:id]).to eq('123abc')
      expect(@resource[:name]).to eq('123abc')
    end
    it 'should reject non-hex names' do
      expect{ described_class.new(:id => 'foobar')}.
         to raise_error(Puppet::ResourceError, /.*/)
    end
    it 'should support enabled' do
      @resource = described_class.new(
        :id => '123abc', :ensure => :absent)
      expect(@resource[:ensure]).to eq(:absent)
    end
    [:starts, :ends].each { |dates|
    context "for #{dates}" do
      it "should have documentation for the property" do
        expect(described_class.attrclass(dates).doc.strip).not_to be_empty
      end
      it 'should accept dates' do
        testdate = Date.parse('2000/01/01')
        @resource = described_class.new(:id => '123abc', dates => testdate)
        expect(@resource[dates]).to eq(testdate)
      end
      it 'should reject non-dates' do
        expect{ described_class.new(:id => '123abc', dates => 'bad date')}.
          to raise_error(Puppet::ResourceError, /.*/)
      end
    end
    }
end
