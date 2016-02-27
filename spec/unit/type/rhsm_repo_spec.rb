#!/usr/bin/ruby -S rspec
#
#  Test the rhsm_repo type
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'

#rhsm_repo { 'rhel-server6-epel':
# ensure    => present,
# id        => 'rhel-server6-epel',
# repo_name => 'RedHat Enterprise Linux 5 Server (RPMs)',
# url       => 'https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os',
#}

described_class = Puppet::Type.type(:rhsm_repo)

describe described_class, 'type' do
  [ :ensure, :repo_name, :url ].each { |property|
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

  context "for a Registration ID" do
      namevar = :id
      it "should be a parameter" do
        expect(described_class.attrtype(namevar)).to eq(:param)
      end
      it "should have documentation" do
        expect(described_class.attrclass(namevar).doc.strip).
          not_to be_empty
      end
      it "should be the namevar" do
        expect(described_class.key_attributes).to eq([namevar])
      end
      it "should return a name equal to this parameter" do
        @resource = described_class.new(
          namevar => '123')
        expect(@resource[namevar]).to eq('123')
        expect(@resource[:name]).to eq('123')
      end
#      it 'should reject invalid values' do
#        expect{ described_class.new(namevar => '@#_$)=')}.
#           to raise_error(Puppet::ResourceError, /.*/)
#      end
  end

  it 'should support enabled' do
    @resource = described_class.new(
      :id => 'foo', :ensure => :absent)
    expect(@resource[:ensure]).to eq(:absent)
  end

end
