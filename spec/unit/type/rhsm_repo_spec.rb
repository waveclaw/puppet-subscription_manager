#!/usr/bin/ruby -S rspec
require 'spec_helper'

#rhsm_repo { 'rhel-server6-epel':
#  ensure        => present,
#  enabled       => false,
#  updated       => 2015-07-17T14:26:35.064+0000,
#  created       => 2015-07-17T14:26:35.064+0000,
#  content_label => 'rhel-server6-epel'
#}

describe Puppet::Type.type(:rhsm_repo), 'type' do
  [ :ensure, :updated, :created].each { |property|
    it "should have a #{property} property" do
      expect(Puppet::Type.type(:rhsm_repo).attrtype(property)).to eq(:property)
    end
  }
  it "should have a content_labal parameter" do
    expect(Puppet::Type.type(:rhsm_repo).attrtype(:content_label)).to eq(:param)
  end
  it 'should accept a name' do
    @resource = Puppet::Type.type(:rhsm_repo).new(
      :content_label => 'foo')
    expect(@resource[:content_label]).to eq('foo')
    expect(@resource[:name]).to eq('foo')
  end
  it 'should support enabled' do
    @resource = Puppet::Type.type(:rhsm_repo).new(
      :content_label => 'foo', :ensure => :absent)
    expect(@resource[:ensure]).to eq(:absent)
  end
  it 'should accept date updated properties' do
    testdate = Date.parse('2000/01/01')
    @resource = Puppet::Type.type(:rhsm_repo).new(
     :content_label => 'foo', :updated => testdate)
    expect(@resource[:updated]).to eq(testdate)
  end
  it 'should reject non-date updated properties' do
    expect{ Puppet::Type.type(:rhsm_repo).new(
     :content_label => 'foo', :updated => 'bad date')}.to raise_error(
      Puppet::ResourceError, /.*/)
  end
  it 'should accept date created properties' do
    testdate = Date.parse('2000/01/01')
    @resource = Puppet::Type.type(:rhsm_repo).new(
     :content_label => 'foo', :created => testdate)
    expect(@resource[:created]).to eq(testdate)
  end
  it 'should reject non-date created properties' do
    expect{ Puppet::Type.type(:rhsm_repo).new(
     :content_label => 'foo', :created => 'bad date')}.to raise_error(
      Puppet::ResourceError, /.*/)
  end
end
