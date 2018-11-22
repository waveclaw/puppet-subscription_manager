#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

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
  'katellodefault' => '/etc/rhsm/ca/katello-default-ca.pem',
  'katello' => '/etc/rhsm/ca/katello-server-ca.pem',
  'sam' => '/etc/rhsm/ca/candlepin-local.pem'
}

# create fake intermediary objects to get detailed testing in each case
fake_cert = StringIO.new(' ', 'r')
cert = Class.new do
  def subject; end
end

describe Facter::Util::Rhsm_ca_name, type: :fact do
  shared_examples_for 'on a supported os' do |cafile|
    before :each do
      Facter::Util::Loader.stubs(:load_all)
      Facter.clear
      Facter.clear_messages
      allow(File).to receive(:exists?).and_return(false)
    end
    it 'returns nothing when there is an error' do
      expect(File).to receive(:exists?).with(cafile).and_return(true)
      expect(File).to receive(:open).with(cafile) { throw(Error) }
      expect(Facter::Util::Rhsm_ca_name.rhsm_ca_name(cafile)).to eq(nil)
    end
    it 'returns the expected domain from normal Certificate subjects' do
      expect(File).to receive(:exists?).with(cafile).and_return(true)
      expect(File).to receive(:open).with(cafile).and_return(fake_cert)
      expect(OpenSSL::X509::Certificate).to receive(:new).and_return(cert)
      expect(cert).to receive(:subject).and_return(
        '/C=US/ST=Main/L=Hobokeen/O=Your Mama/CN=example.net',
      )
      expect(Facter::Util::Rhsm_ca_name.rhsm_ca_name(cafile)).to eq('example.net')
    end
    it 'returns nothing for bad Certificate subjects' do
      expect(File).to receive(:exists?).with(cafile).and_return(true)
      expect(File).to receive(:open).with(cafile).and_return(fake_cert)
      expect(OpenSSL::X509::Certificate).to receive(:new).and_return(cert)
      expect(cert).to receive(:subject).and_return('random garbage')
      expect(Facter::Util::Rhsm_ca_name.rhsm_ca_name(cafile)).to eq(nil)
    end
  end

  shared_examples_for 'on an unsupported os' do |_cafile|
    before :each do
      Facter::Util::Loader.stubs(:load_all)
      Facter.clear
      Facter.clear_messages
      allow(File).to receive(:exists?).and_return(false)
    end
    it 'returns nothing' do
      expect(Facter.value(:rhsm_ca_name)).to eq(nil)
    end
  end
  cafiles.keys.each do |key|
    cafile = cafiles[key]
    context "with cafile #{cafile}" do
      it_behaves_like 'on a supported os', cafile
      it_behaves_like 'on an unsupported os', cafile
    end
  end
end
