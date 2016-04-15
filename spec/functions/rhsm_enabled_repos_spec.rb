#!/usr/bin/ruby -S rspec
#
#  Test the rhsm_enabled_repos fact
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'facter/rhsm_enabled_repos'

cases = {
  :one   => {
    :desc => 'a single enabled repository',
    :data => '
Repo ID:   rhel-5-server-rpms
Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
Enabled:   1
',
    :expected => ['rhel-5-server-rpms'],
  },
  :two   => {
    :desc => 'a single disabled repostiory',
    :data => '
Repo ID:   rhel-5-server-rpms
Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
Enabled:   0
',
    :expected => [],
  },
  :three => {
    :desc => 'two enabled repositories',
    :data => '
Repo ID:   rhel-5-server-rpms
Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
Enabled:   1

Repo ID:   rhel-5-epel-rpms
Repo Name: Extra Packages for RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/epel/os
Enabled:   1
',
    :expected => ['rhel-5-server-rpms', 'rhel-5-epel-rpms'],
  },
  :four  => {
    :desc => 'two repositories with one disabled',
    :data => '
Repo ID:   rhel-5-server-rpms
Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
Enabled:   0

Repo ID:   rhel-5-epel-rpms
Repo Name: Extra Packages for RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/epel/os
Enabled:   1
',
    :expected => ['rhel-5-epel-rpms'],
  },
  :five  => {
    :desc => 'two repositories with both disabled',
    :data => '
Repo ID:   rhel-5-server-rpms
Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
Enabled:   0

Repo ID:   rhel-5-epel-rpms
Repo Name: Extra Packages for RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/epel/os
Enabled:   0
',
    :expected => [],
  },
}


describe Facter::Util::Rhsm_enabled_repos, :type => :puppet_function do
  context 'on a supported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager') { true }
    end
    it "should return nothing when there is an error" do
      expect(Facter::Util::Resolution).to receive(:exec).with(
        '/usr/sbin/subscription-manager repos') { throw Error }
      expect(Facter::Util::Rhsm_enabled_repos.rhsm_enabled_repos).to eq([])
    end
    cases.keys.each { |key|
      desc = cases[key][:desc]
      it "should return results for #{desc}" do
        expect(Facter::Util::Resolution).to receive(:exec).with(
          '/usr/sbin/subscription-manager repos') {
            cases[key][:data]}
          expect(Facter::Util::Rhsm_enabled_repos.rhsm_enabled_repos).to eq(
            cases[key][:expected] )
      end
    }
  end

  context 'on an unsupported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager') { false }
    end
    it "should return nothing" do
      expect(Facter::Util::Rhsm_enabled_repos.rhsm_enabled_repos).to eq([])
    end
  end

  context 'when caching' do
    before :each do
      allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager') { true }
      allow(Puppet.features).to receive(:external_facts?) { true }
      Facter.clear
    end
    it 'should return and save a computed value with an empty cache' do
      expect(Facter::Util::Cacheable).to receive(:cached?).with(
      :rhsm_enabled_repos, 24 * 3600) { nil }
      expect(Facter::Util::Resolution).to receive(:exec).with(
      '/usr/sbin/subscription-manager repos') { "Repo ID: foo\nEnabled: 1" }
      expect(Facter::Util::Cacheable).to receive(:cache).with(
        :rhsm_enabled_repos, ['foo']) { nil }
      expect(Facter.value(:rhsm_enabled_repos)).to eq(['foo'])
    end
    it 'should return a cached value with a full cache' do
      expect(Facter::Util::Cacheable).to receive(:cached?).with(
      :rhsm_enabled_repos, 24 * 3600) { {"rhsm_enabled_repos"=>['bar']} }
      expect(Facter::Util::Rhsm_enabled_repos).to_not receive(
        :rhsm_enabled_repos)
      expect(Facter.value(:rhsm_enabled_repos)).to eq(['bar'])
    end
  end
end
