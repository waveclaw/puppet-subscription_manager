#!/usr/bin/ruby -S rspec
#
#  Test the class structure of the module as used.
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'

shared_examples_for 'a supported operating system' do
  it { is_expected.to contain_class('subscription_manager') }
  it { is_expected.to contain_class('subscription_manager::defaults') }
  it { is_expected.to contain_class('subscription_manager::install').that_comes_before('subscription_manager::config') }
  it { is_expected.to contain_class('subscription_manager::config') }
  it { is_expected.to contain_class('subscription_manager::service').that_subscribes_to('subscription_manager::config') }
  it { is_expected.to contain_service('goferd').with_ensure('running') }
  it { is_expected.to contain_package('subscription-manager').with_ensure('present') }
end

shared_examples_for 'an unsupported operating system' do |os|
  it { is_expected.to contain_class('subscription_manager') }
  it { is_expected.to contain_notify("#{os} not supported by subscription_manager") }
  it { is_expected.to_not contain_class('subscription_manager::install') }
  it { is_expected.to_not contain_class('subscription_manager::config') }
  it { is_expected.to_not contain_class('subscription_manager::service') }
  it { is_expected.to_not contain_package('katello-ca-consumer-foo') }
  it { is_expected.to_not contain_rhsm_register('foo') }
  it { is_expected.to_not contain_rhsm_config('/etc/rhsm/rhsm.conf') }
end

bados = {
  'Solaris'  => 'Nexenta',
  'Debian'   => 'Ubuntu',
  'openSuSE' => 'openSUSE',
  'SLES'     => 'SLES'
}
badosfamily = bados.keys

describe 'subscription_manager' do

  context 'unsupported operating systems' do
    badosfamily.each { |os|
      describe "on unsupported operating system #{os}" do
          let(:facts) {{
            :osfamily        => os,
            :operatingsystem => bados[os],
          }}
          it_behaves_like 'an unsupported operating system', bados[os]
      end
    }
  end

  context 'supported operating systems' do
    ['RedHat', 'CentOS', 'Fedora'].each { |osfamily|
      describe "subscription_manager class without any parameters on #{osfamily}" do
        let(:params) {{ }}
        let(:facts) {{ :osfamily => osfamily, }}
        it { is_expected.to compile.with_all_deps }
        it_behaves_like 'a supported operating system'
        it { is_expected.to contain_package('katello-ca-consumer-subscription.rhn.redhat.com') }
        it { is_expected.to contain_rhsm_register('subscription.rhn.redhat.com').that_requires('Rhsm_config[/etc/rhsm/rhsm.conf]') }
        it { is_expected.to contain_rhsm_config('/etc/rhsm/rhsm.conf') }
      end
      describe "subscription_manager class with an activation key and server name on #{osfamily}" do
        let(:params) {{ :activationkey => 'foo-bar', :server_hostname => 'foo' }}
        let(:facts) {{ :osfamily => osfamily, }}
        it { is_expected.to compile.with_all_deps }
        it_behaves_like 'a supported operating system'
        it { is_expected.to contain_package('katello-ca-consumer-foo') }
        it { is_expected.to contain_rhsm_register('foo').that_requires('Rhsm_config[/etc/rhsm/rhsm.conf]') }
        it { is_expected.to contain_rhsm_config('/etc/rhsm/rhsm.conf') }
      end
    }
  end


  context 'when given a repo option' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'RedHat',
    }}
    let(:params) {{
     :repo => 'sm_repo',
    }}
    let(:pre_condition) {
      'class sm_repo {}'
    }
    it { is_expected.to contain_class('sm_repo') }
    it { is_expected.to contain_package('subscription-manager').
      with_ensure('present').that_requires('sm_repo') }
  end

  context 'when told to disable the service' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'RedHat',
    }}
    let(:params) {{
     :service_status => 'disabled',
    }}
    it { is_expected.to contain_service('goferd').with_ensure('disabled') }
  end

  context 'when the rhsm_ca_name is different' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'RedHat',
      :rhsm_ca_name    => 'foo',
      :rhsm_identity   => 'baz',
    }}
    let(:params) {{
      :server_hostname => 'bar',
    }}
    it { is_expected.to contain_package('katello-ca-consumer-foo').with_ensure('absent') }
    it { is_expected.to contain_package('katello-ca-consumer-bar').with_ensure('latest') }
    it { is_expected.to_not contain_transition('purge-bad-rhsm_ca-package') }
    it { is_expected.to contain_rhsm_register('bar') }
  end

  context "when registration is good but force is false (the default)" do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'RedHat',
      :rhsm_ca_name    => 'foo',
      :rhsm_identity   => 'x',
    }}
    let(:params) {{
      :server_hostname => 'foo',
    }}
    it { is_expected.to contain_package('katello-ca-consumer-foo').with_ensure('latest') }
    it { is_expected.to_not contain_transition('purge-bad-rhsm_ca-package') }
    it { is_expected.to_not contain_rhsm_register('foo') }
  end

  context "when registration is good but force is true" do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'RedHat',
      :rhsm_ca_name    => 'foo',
      :rhsm_identity   => 'x',
    }}
    let(:params) {{
      :server_hostname => 'foo',
            :force           => true,
    }}
    it { is_expected.to contain_package('katello-ca-consumer-foo').with_ensure('latest') }
    it { is_expected.to contain_transition('purge-bad-rhsm_ca-package') }
    it { is_expected.to contain_rhsm_register('foo') }
  end

  context "when registration is bad but force is true" do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'RedHat',
      :rhsm_ca_name    => 'foo',
      :rhsm_identity   => '',
    }}
    let(:params) {{
      :server_hostname => 'foo',
      :force           => true,
    }}
    it { is_expected.to contain_package('katello-ca-consumer-foo').with_ensure('latest') }
    it { is_expected.to contain_transition('purge-bad-rhsm_ca-package') }
    it { is_expected.to contain_rhsm_register('foo') }
  end

  context "without any parameters with nil puppetversion" do
    let(:params) {{ }}
    let(:facts) {{ :osfamily => 'RedHat', :puppetversion => nil }}
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('subscription_manager::install').that_comes_before('subscription_manager::config') }
  end

end
