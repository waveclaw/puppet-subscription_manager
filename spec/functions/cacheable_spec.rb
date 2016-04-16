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
require 'stringio'
require 'yaml'
require 'time'

data = {
  :single => "--- \n  string_value: tested",
  :list_like   => "--- \n  list_value: \n    - thing1\n    - thing2",
  :hash_like   =>
    "--- \n  hash_value: \n    alpha: one\n    beta: two\n    tres: three",
}

# YAML.load* does not return symbols as hash keys!
expected = {
  :single => { "string_value" => 'tested' },
  :list_like   => { "list_value" => [ 'thing1', 'thing2' ] },
  :hash_like   => { "hash_value" => {
    'alpha' => 'one', 'beta'  => 'two', 'tres'  => 'three' } }
}

describe "Facter::Util::Cacheable.cached?", :type => :function do

context "when the cache is hot" do
data.keys.each { |testcase|
    cache = "/tmp/#{testcase.to_s}.yaml"
    rawdata = StringIO.new(data[testcase])
    it "for #{testcase.to_s} values should return the cached value" do
      expect(Puppet.features).to receive(:external_facts?) { true }
      expect(Facter).to receive(:search_external_path) { ['/tmp'] }
      expect(File).to receive(:exist?).with(cache) { true }
      expect(YAML).to receive(:load_file).with(cache) {
        YAML.load_stream(rawdata)
      }
      expect(File).to receive(:mtime).with(cache) { Time.now }
      expect(Facter::Util::Cacheable.cached?(testcase)).to eq(
        expected[testcase])
    end
  }
  end

  context "when the cache is cold" do
    data.keys.each { |testcase|
        cache = "/tmp/#{testcase.to_s}.yaml"
        rawdata = StringIO.new(data[testcase])
        it "for #{testcase.to_s} values should return nothing" do
          expect(Puppet.features).to receive(:external_facts?) { true }
          expect(Facter).to receive(:search_external_path) { ['/tmp'] }
          expect(File).to receive(:exist?).with(cache) { true }
          expect(YAML).to receive(:load_file).with(cache) {
            YAML.load_stream(rawdata)
          }
          expect(File).to receive(:mtime).with(cache) { Time.at(0) }
          expect(Facter::Util::Cacheable.cached?(testcase)).to eq(nil)
        end
    }
  end

  context "when the cache is missing" do
    data.keys.each { |testcase|
        cache = "/tmp/#{testcase.to_s}.yaml"
        rawdata = StringIO.new(data[testcase])
        it "for #{testcase.to_s} values should return nothing" do
          expect(Puppet.features).to receive(:external_facts?) { true }
          expect(Facter).to receive(:search_external_path) { ['/tmp'] }
          expect(File).to receive(:exist?).with(cache) { false }
          expect(YAML).to_not receive(:load_file).with(cache)
          expect(File).to_not receive(:mtime).with(cache)
          expect(Facter::Util::Cacheable.cached?(testcase)).to eq(nil)
        end
    }
  end

  context "for garbage values" do
    cache = "/tmp/garbage.yaml"
    rawdata = StringIO.new('random non-yaml garbage')
    it "should return nothing" do
      expect(Puppet.features).to receive(:external_facts?) { true }
      expect(Facter).to receive(:search_external_path) { ['/tmp'] }
      expect(File).to receive(:exist?).with(cache) { true }
      expect(YAML).to receive(:load_file).with(cache) {
          YAML.load_stream(rawdata)
      }
      expect(File).to receive(:mtime).with(cache) { Time.now }
      expect(Facter::Util::Cacheable.cached?('garbage')).to eq(nil)
    end
  end
end

describe "Facter::Util::Cacheable.cache", :type => :function do
data.keys.each { |testcase|
  result = StringIO.new('')
  key = (expected[testcase].keys)[0]
  value = expected[testcase][key]
  cache = "/tmp/#{key}.yaml"
  it "should store a #{testcase.to_s} value in YAML" do
    expect(Puppet.features).to receive(:external_facts?) { true }
    expect(Facter).to receive(:search_external_path) { ['/tmp'] }
    expect(File).to receive(:exist?).with('/tmp') { true }
    # cannot do this test with a lambda like the File.open block passed in
    expect(File).to receive(:open).with(cache, 'w') { result }
    # WTF? called 785 times?
    #expect(YAML).to receive(:dump).with({ key => value }, result) {
    #    YAML.dump({ key => value }, result)
    #}
    Facter::Util::Cacheable.cache(key, value)
    expect(result.string).to eq(data[testcase])
  end
}
  context "for garbage values" do
    it "should output nothing" do
      result = StringIO.new('')
      cache = "/tmp/.yaml"
      expect(Puppet.features).to_not receive(:external_facts?) { true }
      expect(Facter).to_not receive(:search_external_path) { ['/tmp'] }
      expect(File).to_not receive(:exist?).with('/tmp') { true }
      expect(File).to_not receive(:open).with(cache, 'w') { result }
      Facter::Util::Cacheable.cache(nil, nil)
      expect(result.string).to eq('')
    end
  end
end
