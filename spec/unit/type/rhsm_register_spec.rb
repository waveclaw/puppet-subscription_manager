#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

#
#  Test the rhsm_register type
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'

# rhsm_register { 'example.com':
#  username        => 'registered_user',
#  password        => 'password123',
#  hostname        => 'example.com',
#  activationkey  => '1-my-activation-key',
#  autosubscribe   => true,
#  force           => true,
#  org             => 'the cool organization',
# }

described_class = Puppet::Type.type(:rhsm_register)

describe described_class, '#rhsm_register.type' do
  it 'is ensurable' do
    expect(described_class.attrtype(:ensure)).to eq(:property)
  end

  [:username, :password, :org, :activationkey, :lifecycleenv,
   :pool, :servicelevel, :release].each do |params|
    context "for #{params}" do
      it 'is of type paramter' do
        expect(described_class.attrtype(params)).to eq(:param)
      end
      it 'is of class Paramter' do
        expect(described_class.attrclass(params).ancestors)
          .to include(Puppet::Parameter)
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
      resource = described_class.new(
        namevar => 'foo',
      )
      expect(resource[namevar]).to eq('foo')
      expect(resource[:name]).to eq('foo')
    end
    it 'accepts names containing 0s' do
      resource = described_class.new(
        namevar => 'f00',
      )
      expect(resource[namevar]).to eq('f00')
      expect(resource[:name]).to eq('f00')
    end
    it 'rejects invalid values' do
      expect {
        described_class.new(
          namevar => '@#$%foooooo^!)',
        )
      }.to raise_error(
        Puppet::ResourceError, %r{.*}
      )
    end
  end

  [:autosubscribe, :force].each do |boolean_parameter|
    context "for #{boolean_parameter}" do
      it 'is a parameter' do
        expect(described_class.attrtype(boolean_parameter)).to eq(:param)
      end
      it 'has boolean class' do
        expect(described_class.attrclass(boolean_parameter).ancestors)
          .to include(Puppet::Parameter::Boolean)
      end
      it 'has documentation' do
        expect(described_class.attrclass(boolean_parameter).doc.strip)
          .not_to be_empty
      end
      it 'accepts boolean values' do
        resource = described_class.new(
          :name => 'foo', boolean_parameter => true,
        )
        expect(resource[boolean_parameter]).to eq(true)
        resource = described_class.new(
          :name => 'bar', boolean_parameter => false,
        )
        expect(resource[boolean_parameter]).to eq(false)
      end
      it 'rejects non-boolean values' do
        expect {
          described_class.new(
            :name => 'foo', boolean_parameter => 'bad date',
          )
        }.to raise_error(
          Puppet::ResourceError, %r{.*}
        )
      end
    end
  end

  it 'supports enabled' do
    resource = described_class.new(
      name: 'foo', ensure: :absent,
    )
    expect(resource[:ensure]).to eq(:absent)
  end
end
