#!/usr/bin/ruby -S rspec
# frozen_string_literal: true

#
# Common tests for repositories
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

# stub facter_cacheable
module Facter::Util::FacterCacheable
  class <<self
    def cached?; end
  end
end

shared_examples_for 'rhsm repo command' do |mod, function, label|
  repo_cases = {
    one: {
      desc: 'a single enabled repository',
      data: '
  Repo ID:   rhel-5-server-rpms
  Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
  Enabled:   1
  ',
      expected: {
        enabled: ['rhel-5-server-rpms'],
        disabled: [],
        available: ['rhel-5-server-rpms']
      }
    },
    two: {
      desc: 'a single disabled repostiory',
      data: '
  Repo ID:   rhel-5-server-rpms
  Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
  Enabled:   0
  ',
      expected: {
        enabled: [],
        disabled: ['rhel-5-server-rpms'],
        available: ['rhel-5-server-rpms']
      }
    },
    three: {
      desc: 'two enabled repositories',
      data: '
  Repo ID:   rhel-5-server-rpms
  Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
  Enabled:   1

  Repo ID:   rhel-5-epel-rpms
  Repo Name: Extra Packages for RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/epel/os
  Enabled:   1
  ',
      expected: {
        enabled: ['rhel-5-server-rpms', 'rhel-5-epel-rpms'],
        disabled: [],
        available: ['rhel-5-server-rpms', 'rhel-5-epel-rpms']
      }
    },
    four: {
      desc: 'two repositories with one disabled',
      data: '
  Repo ID:   rhel-5-server-rpms
  Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
  Enabled:   0

  Repo ID:   rhel-5-epel-rpms
  Repo Name: Extra Packages for RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/epel/os
  Enabled:   1
  ',
      expected: {
        enabled: ['rhel-5-epel-rpms'],
        disabled: ['rhel-5-server-rpms'],
        available: ['rhel-5-server-rpms', 'rhel-5-epel-rpms']
      }
    },
    five: {
      desc: 'two repositories with both disabled',
      data: '
  Repo ID:   rhel-5-server-rpms
  Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
  Enabled:   0

  Repo ID:   rhel-5-epel-rpms
  Repo Name: Extra Packages for RedHat Enterprise Linux 5 Server (RPMs)
  Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/epel/os
  Enabled:   0
  ',
      expected: {
        enabled: [],
        disabled: ['rhel-5-server-rpms', 'rhel-5-epel-rpms'],
        available: ['rhel-5-server-rpms', 'rhel-5-epel-rpms']
      }
    }
  }

  before :each do
    allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager',
    ).and_return(true)
    allow(Facter::Util::FacterCacheable).to receive(:cached?).and_return(false)
  end
  it 'returns nothing when there is an error' do
    expect(Facter::Core::Execution).to receive(:execute).with(
      '/usr/sbin/subscription-manager repos',
      on_fail: :raise,
    ) { throw Facter::Core::Execution::ExecutionFailure }
    expect(mod.send(function)).to eq([])
  end
  repo_cases.keys.each do |key|
    desc = repo_cases[key][:desc]
    it "should return results for #{desc}" do
      expect(Facter::Core::Execution).to receive(:execute).with(
        '/usr/sbin/subscription-manager repos',
        on_fail: :raise,
      ).and_return(repo_cases[key][:data])
      expect(mod.send(function)).to eq(
        repo_cases[key][:expected][label],
      )
    end
  end
end

shared_examples_for 'cached rhsm repo command' do |mod, function, label, _source|
  data = {
    rhsm_disabled_repos: "Repo ID: foo\nEnabled: 0",
    rhsm_available_repos: 'Repo ID: bar',
    rhsm_enabled_repos: "Repo ID: baz\nEnabled: 1"
  }
  results = {
    rhsm_disabled_repos: { 'rhsm_disabled_repos' => ['foo'] },
    rhsm_available_repos: { 'rhsm_available_repos' => ['bar'] },
    rhsm_enabled_repos: { 'rhsm_enabled_repos' => ['baz'] }
  }
  let(:fake_class) { Class.new }

  before :each do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager',
    ).and_return(true)
    allow(Puppet.features).to receive(:facter_cacheable?).and_return(true)
    Facter.clear
  end
  it 'returns and save a computed value with an empty cache' do
    stub_const('Facter::Util::FacterCacheable', fake_class)
    expect(Facter::Util::FacterCacheable).to receive(:cached?).with(
      label, mod::CACHE_TTL, mod::CACHE_FILE
    ).and_return(nil)
    expect(Facter::Core::Execution).to receive(:execute).with(
      '/usr/sbin/subscription-manager repos',
      on_fail: :raise,
    ).and_return(data[label])
    expect(Facter::Util::FacterCacheable).to receive(:cache).with(
      label, results[label][function], mod::CACHE_FILE
    ).and_return(nil)
    expect(Facter.value(label)).to eq(results[label][function])
  end
  it 'returns a cached value with a full cache' do
    stub_const('Facter::Util::FacterCacheable', fake_class)
    expect(Facter::Util::FacterCacheable).to receive(:cached?).with(
      label, mod::CACHE_TTL, mod::CACHE_FILE
    ).and_return(results[label])
    expect(mod).not_to receive(label)
    expect(Facter.value(label)).to eq(results[label][function])
  end
end
