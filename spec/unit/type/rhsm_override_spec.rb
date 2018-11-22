#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

#
#  Test the rhsm_override type
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'

# Example:
# rhsm_override { 'rhel-server6-epel':
#  ensure        => present,
#  enabled       => false,
#  updated       => 2015-07-17T14:26:35.064+0000,
#  created       => 2015-07-17T14:26:35.064+0000,
#  content_label => 'rhel-server6-epel'
# }

described_class = Puppet::Type.type(:rhsm_override)

describe described_class, '#rhsm_override.type' do
  [:ensure, :updated, :created].each do |property|
    context "for #{property}" do
      it 'is of type property' do
        expect(described_class.attrtype(property))
          .to eq(:property)
      end
      it 'is of class property' do
        expect(described_class.attrclass(property).ancestors)
          .to include(Puppet::Property)
      end
      it 'has documentation' do
        expect(described_class.attrclass(property).doc.strip)
          .not_to be_empty
      end
    end
  end

  context 'for a ContentLabel' do
    namevar = :content_label
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
        namevar => '123',
      )
      expect(resource[namevar]).to eq('123')
      expect(resource[:name]).to eq('123')
    end
    #      it 'should reject invalid values' do
    #        expect{ described_class.new(namevar => '@#_$)=')}.
    #           to raise_error(Puppet::ResourceError, /.*/)
    #      end
  end

  it 'supports enabled' do
    resource = described_class.new(
      content_label: 'foo', ensure: :absent,
    )
    expect(resource[:ensure]).to eq(:absent)
  end

  [:updated, :created].each do |dates|
    context "for #{dates}" do
      it 'has documentation for the property' do
        expect(described_class.attrclass(dates).doc.strip).not_to be_empty
      end
      it 'accepts date updated properties' do
        testdate = Date.parse('2000/01/01')
        resource = described_class.new(
          :content_label => 'foo', dates => testdate,
        )
        expect(resource[dates]).to eq(testdate)
      end
      it 'rejects non-date updated properties' do
        expect {
          described_class.new(
            :content_label => 'foo', dates => 'bad date',
          )
        }.to raise_error(
          Puppet::ResourceError, %r{.*}
        )
      end
    end
  end
end
