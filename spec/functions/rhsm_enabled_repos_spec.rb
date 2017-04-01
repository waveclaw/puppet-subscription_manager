#!/usr/bin/ruby -S rspec
#
#  Test the rhsm_enabled_repos fact
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'repo_tests'
require 'facter/rhsm_enabled_repos'

describe Facter::Util::Rhsm_enabled_repos, :type => :fact do
  context 'on a supported platform' do
    before :each do
      Facter::Util::Loader.any_instance.stubs(:load_all)
      Facter.clear
      Facter.clear_messages
    end
    it_behaves_like 'rhsm repo command',
      Facter::Util::Rhsm_enabled_repos, 'rhsm_enabled_repos', :enabled
  end

  context 'on an unsupported platform' do
    before :each do
      Facter::Util::Loader.any_instance.stubs(:load_all)
      Facter.clear
      Facter.clear_messages
      allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager') { false }
    end
    it "should return nothing" do
      expect(Facter::Util::Rhsm_enabled_repos.rhsm_enabled_repos).to eq([])
    end
  end

  context 'when caching' do
    before :each do
      Facter::Util::Loader.any_instance.stubs(:load_all)
      Facter.clear
      Facter.clear_messages
    end
    it_behaves_like 'cached rhsm repo command',
      Facter::Util::Rhsm_enabled_repos,
      'rhsm_enabled_repos',
      :rhsm_enabled_repos,
      '/var/cache/rhsm/enabled_repos.yaml'
  end
end
