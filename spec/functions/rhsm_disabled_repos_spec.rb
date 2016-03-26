#!/usr/bin/ruby -S rspec
#
#  Test the rhsm_disabled_repos fact 
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'facter/rhsm_disabled_repos'

cases = {
  :one   => {
    :desc => 'a single enabled repository',
    :data => '
Repo ID:   rhel-5-server-rpms
Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
Enabled:   1
',
    :expected => [],
  },
  :two   => {
    :desc => 'a single disabled repostiory',
    :data => '
Repo ID:   rhel-5-server-rpms
Repo Name: RedHat Enterprise Linux 5 Server (RPMs)
Repo URL:  https://katello.example.com/pulp/repos/myorg/production/myview/content/dist/rhel/server/5/5Server/$basearch/rhel/os
Enabled:   0
',
    :expected => ['rhel-5-server-rpms'],
  },
  :three => {
    :desc => 'two disabled repositories',
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
    :expected => ['rhel-5-server-rpms'],
  },
  :five  => {
    :desc => 'two repositories with both enabled',
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
    :expected => [],
  },
}


describe Facter::Util::Rhsm_disabled_repos, :type => :puppet_function do
  context 'on a supported platform' do
    before :each do
      allow(File).to receive(:exist?).with(
      '/usr/sbin/subscription-manager') { true }
    end
    it "should return nothing when there is an error" do
      expect(Facter::Util::Resolution).to receive(:exec).with(
        '/usr/sbin/subscription-manager repos') { throw Error }
      expect(Facter::Util::Rhsm_disabled_repos.rhsm_disabled_repos).to eq([])
    end
    cases.keys.each { |key|
      desc = cases[key][:desc]
      it "should return results for #{desc}" do
        expect(Facter::Util::Resolution).to receive(:exec).with(
          '/usr/sbin/subscription-manager repos') {
            cases[key][:data]}
          expect(Facter::Util::Rhsm_disabled_repos.rhsm_disabled_repos).to eq(
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
      expect(Facter::Util::Rhsm_disabled_repos.rhsm_disabled_repos).to eq([])
    end
  end
end
