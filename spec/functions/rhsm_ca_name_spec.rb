#!/usr/bin/ruby -S rspec
#
#  Test the rhsm_ca_name fact
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'facter/rhsm_ca_name'

cafiles = {
  'katello' => '/etc/rhsm/ca/katello-server-ca.pem',
  'sam' => '/etc/rhsm/ca/candlepin-local.pem',
}

# create fake intermediary objects to get detailed testing in each case
fakeCert = StringIO.new(" ",'r')
subject = Class.new do
  def subject
  end
end

describe Facter::Util::Rhsm_ca_name, :type => :puppet_function do
  shared_examples_for 'on a supported os' do |cafile|
    before :each do
      allow(File).to receive(:exists?).with(cafile) { true }
    end
    it "should return nothing when there is an error" do
      expect(File).to receive(:exists?).with(cafile) { true }
      expect(File).to receive(:open).with(cafile) { throw Error }
      expect(Facter::Util::Rhsm_ca_name.rhsm_ca_name(cafile)).to eq(nil)
    end
    it "should return the expected domain from normal Certificate subjects" do
      expect(File).to receive(:exists?).with(cafile) { true }
      expect(File).to receive(:open).with(cafile) { fakeCert }
      expect(OpenSSL::X509::Certificate).to receive(:new) { subject }
      expect(subject).to receive(:subject) {
        '/C=US/ST=Main/L=Hobokeen/O=Your Mama/CN=example.net'}
      expect(Facter::Util::Rhsm_ca_name.rhsm_ca_name(cafile)).to eq('example.net')
    end
    it "should return nothing for bad Certificate subjects" do
      expect(File).to receive(:exists?).with(cafile) { true }
      expect(File).to receive(:open).with(cafile) { fakeCert }
      expect(OpenSSL::X509::Certificate).to receive(:new) { subject }
      expect(subject).to receive(:subject) { 'random garbage' }
      expect(Facter::Util::Rhsm_ca_name.rhsm_ca_name(cafile)).to eq(nil)
    end
  end

  shared_examples_for 'on an unsupported os' do |cafile|
    before :each do
      Facter.clear
      allow(File).to receive(:exists?) { false }
    end
    it "should return nothing" do
      expect(Facter.value(:rhsm_ca_name)).to eq(nil)
    end
  end
  cafiles.keys.each { |key|
    cafile = cafiles[key]
    context "with cafile #{cafile}" do
      it_behaves_like 'on a supported os', cafile
      it_behaves_like 'on an unsupported os', cafile
    end
  }
end
