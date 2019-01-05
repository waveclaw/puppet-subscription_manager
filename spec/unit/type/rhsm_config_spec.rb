#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

#
#  Test the type interface of the rhsm_config type.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'spec_helper'

# Example:
# rhsm_config { 'katello.example.com':
#   server_insecure               => false,
#   server_port                   => 443,
#   server_prefix                 => '/rhsm',
#   server_ssl_verify_depth       => 3,
#   rhsm_baseurl                => 'https://katello.example.com/pulp/repos',
#   rhsm_ca_cert_dir            => '/etc/rhsm/ca/',
#   rhsm_consumercertdir        => '/etc/pki/consumer',
#   rhsm_entitlementcertdir     => '/etc/pki/entitlement',
#   rhsm_full_refresh_on_yum    => true,
#   rhsm_manage_repos           => true,
#   rhsm_pluginconfdir          => '/etc/rhsm/pluginconf_d',
#   rhsm_plugindir              => '/usr/share/rhsm-plugins',
#   rhsm_productcertdir         => '/etc/pki/product',
#   rhsm_repo_ca_cert           => '/etc/rhsm/ca/',
#   rhsm_report_package_profile => 1,
#   rhsmcertd_autoattachinterval => 1440,
# }

described_class = Puppet::Type.type(:rhsm_config)

describe described_class, '#rhsm_config.type' do
  it 'is ensurable' do
    expect(described_class.attrtype(:ensure)).to eq(:property)
  end

  described_class.text_options.keys.each do |params|
    context "for #{params}" do
      it 'is of type property' do
        expect(described_class.attrtype(params)).to eq(:property)
      end
      it 'is of class Property' do
        expect(described_class.attrclass(params).ancestors)
          .to include(Puppet::Property)
      end
      it 'has documentation' do
        expect(described_class.attrclass(params).doc.strip)
          .not_to be_empty
      end
    end
  end

  context 'for name' do
    namevar = :name
    it 'is a parameter' do
      expect(described_class.attrtype(namevar)).to eq(:param)
    end
    it 'has documentation' do
      expect(described_class.attrclass(namevar).doc.strip)
        .not_to be_empty
    end
    it 'is the namevar' do
      expect(described_class.key_attributes).to eq([namevar])
    end
    it 'returns a name equal to this parameter' do
      testvalue = '/foo/bar/y.conf'
      resource = described_class.new(namevar => testvalue)
      expect(resource[namevar]).to eq(testvalue)
      expect(resource[:name]).to eq(testvalue)
    end
    it 'rejects invalid values' do
      expect {
        described_class.new(
          namevar => '@#$%foooooo^!)',
        )
      }.to raise_error(
        Puppet::ResourceError,
        %r{.*},
      )
    end
  end

  described_class.binary_options.keys.each do |binary_property|
    context "for #{binary_property}" do
      it 'is a property' do
        expect(described_class.attrtype(binary_property)).to eq(:property)
        # expect(described_class.attrclass(binary_property).ancestors)
        #  .to include(Puppet::Property)
      end
      #      it "should have boolean class" do
      #        expect(described_class.attrclass(binary_property).ancestors).
      #          to include(Puppet::Property::Boolean)
      #      end
      it 'has documentation' do
        expect(described_class.attrclass(binary_property).doc.strip)
          .not_to be_empty
      end
      it 'accepts boolean values and turns them into binary' do
        resource = described_class.new(
          :name => '/foo/x.conf', binary_property => :true,
        )
        expect(resource[binary_property]).to eq(1)
        resource = described_class.new(
          :name => '/foo/x.conf', binary_property => :false,
        )
        expect(resource[binary_property]).to eq(0)
      end
      it 'rejects non-boolean / non-binary values' do
        expect {
          described_class.new(
            :name => '/foo/x.conf', binary_property => 'bad date',
          )
        }.to raise_error(
          Puppet::ResourceError, %r{.*}
        )
      end
    end
  end

  context 'for rhsm_baseurl' do
    it 'is a property' do
      expect(described_class.attrtype(:rhsm_baseurl)).to eq(:property)
    end
    it 'accepts url path values' do
      resource = described_class.new(
        name: '/foo/x.conf', rhsm_baseurl: 'http://foo:123/',
      )
      expect(resource[:rhsm_baseurl]).to eq('http://foo:123/')
      resource = described_class.new(
        name: '/foo/x.conf', rhsm_baseurl: 'https://a.b.c',
      )
      expect(resource[:rhsm_baseurl]).to eq('https://a.b.c')
      resource = described_class.new(
        name: '/foo/x.conf', rhsm_baseurl: 'file://a.b.c',
      )
      expect(resource[:rhsm_baseurl]).to eq('file://a.b.c')
    end
    it 'rejects path values' do
      expect {
        described_class.new(
          name: '/foo/x.conf', rhsm_baseurl: '$%,,_,..!#^@(((,,,...',
        )
      }.to raise_error(
        Puppet::ResourceError, %r{.*}
      )
    end
  end

  it 'supports enabled' do
    resource = described_class.new(
      name: '/foo/x.conf', ensure: :absent,
    )
    expect(resource[:ensure]).to eq(:absent)
  end
end
