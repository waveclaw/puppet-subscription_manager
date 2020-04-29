#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

#
#  Test the rhsm_disabled_repos fact
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#
require 'spec_helper'
require 'repo_tests'
require 'facter/rhsm_disabled_repos'

describe Facter::Util::RhsmDisabledRepos, type: :fact do
  context 'on a supported platform' do
    before :each do
      Facter.clear
    end
    it_behaves_like 'rhsm repo command',
                    Facter::Util::RhsmDisabledRepos, 'rhsm_disabled_repos', :disabled
  end

  context 'on an unsupported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
        '/usr/sbin/subscription-manager',
      ) { false }
    end
    it 'returns nothing' do
      expect(Facter::Util::RhsmDisabledRepos.rhsm_disabled_repos).to eq([])
    end
  end

  context 'when caching' do
    before :each do
      Facter.clear
    end
    it_behaves_like 'cached rhsm repo command',
                    Facter::Util::RhsmDisabledRepos,
                    'rhsm_disabled_repos',
                    :rhsm_disabled_repos,
                    '/var/cache/rhsm/disabled_repos.yaml'
  end
end
