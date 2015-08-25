require 'spec_helper'

describe 'subscription_manager' do
  shared_examples_for 'on supported operating systems' do
    it { is_expected.to contain_class('subscription_manager::defaults') }
    it { is_expected.to contain_class('subscription_manager::install').that_comes_before('subscription_manager::config') }
    it { is_expected.to contain_class('subscription_manager::config') }
    it { is_expected.to contain_class('subscription_manager::service').that_subscribes_to('subscription_manager::config') }
    it { is_expected.to contain_service('subscription_manager') }
    it { is_expected.to contain_package('subscription_manager').with_ensure('present') }
  end

  context 'supported operating systems' do
    ['RedHat', 'CentOS', 'Fedora'].each do |osfamily|
      describe "subscription_manager class without any parameters on #{osfamily}" do
        let(:params) {{ }}
        let(:facts) {{ :osfamily => osfamily, }}
        it { is_expected.to compile.with_all_deps }
        it_behaves_like 'on supported operating systems'
      end
    end
  end

  context 'unsupported operating system' do
    describe 'subscription_manager class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}

      it { expect { is_expected.to contain_package('subscription_manager') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
  context 'unsupported operating system' do
    describe 'subscription_manager class without any parameters on Debian/Ubuntu' do
      let(:facts) {{
        :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu',
      }}

      it { expect { is_expected.to contain_package('subscription_manager') }.to raise_error(Puppet::Error, /Ubuntu not supported/) }
    end
  end
end
