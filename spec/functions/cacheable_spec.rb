#!/usr/bin/ruby -S rspec
#
#  Test the cachable utility
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'facter/util/cacheable'

data = {
  :single => '---
something: tested',
  :list   => '---
  list_value:
    - thing1
    - thing2',
  :hash   => '---
hash_value:
  alpha: one
  beta: two
  tres: three',
}

expected = {
  :single => { :something => 'tested',
  :list   => { :list_value => [ 'thing1', 'thing2' ] }
  :hash   => { :hash_value => {
    :alpha => 'one',
    :beta  => 'two',
    :tres  => 'three'
  },
}

describe Facter::Util::Cachable.cached?, :type => :function do
data.keys.each { |testcase|
  context "for #{testcase.to_s} values when the cache is hot" do
    before :each do
      # allow(File).to receive(:exist?).with('something') { true }
    end
    it "for #{testcase.to_s} values should return the cached value" do
      # expect(YAML).to receive(:load_file) { x }
      # expect(Facter::Util::Cacheable.cached?('xyz')).to eq(exected)
    end
  end
  context "for #{testcase.to_s} values when the cache is cold" do
    before :each do
      # allow(File).to receive(:exist?).with('something') { true }
    end
    it "for #{testcase.to_s} values should return nothing" do
      # expect(YAML).to receive(:load_file) { x }
      # expect(Facter::Util::Cacheable.cached?('xyz')).to eq(exected)
    end
  end
  end
}
  context "for garbage values" do
    before :each do
      # allow(File).to receive(:exist?).with('something') { true }
    end
    it "should return nothing" do
      # expect(YAML).to receive(:load_file) { x }
      # expect(Facter::Util::Cacheable.cached?('xyz')).to eq(exected)
    end
  end
end

describe Facter::Util::Cachable.cache, :type => :function do
data.keys.each { |testcase|
  before :each do
    # allow(File).to receive(:exist?).with('something') { true }
  end
  it "should store a #{testcase.to_s} value in YAML" do
    # x = new StringIO
    # allow(File).to receive(:open).with('something','w') { x }
    # expect(Facter::Util::Cacheable.cache('xyz')).to eq(exected)
    # expect(x).to eq(expected)
  end
}
  context "for garbage values" do
    before :each do
      # allow(File).to receive(:exist?).with('something') { true }
    end
    it "should do nothing" do
      # expect(YAML).to receive(:load_file) { x }
      # expect(Facter::Util::Cacheable.cache('xyz')).to eq(exected)
    end
  end
end
