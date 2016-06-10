
require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    else
      install_puppet
    end
  end
end
UNSUPPORTED_PLATFORMS = [ 'Windows', 'Solars', 'AIX' ]

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # detect the situation where PUP-5016 is triggered and skip the idempotency tests in that case
  # also note how fact('puppetversion') is not available because of PUP-4359
  if fact('osfamily') == 'Debian' && fact('operatingsystemmajrelease') == '8' && shell('puppet --version').stdout =~ /^4\.2/
    c.filter_run_excluding :skip_pup_5016 => true
  end

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'subscription_manager')
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'waveclaw-facter_cachable'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppet-boolean'), { :acceptable_exit_codes => [0,1] }
    end
  end

  shared_examples "a idempotent resource" do
  it 'should apply with no errors' do
    apply_manifest(pp, :catch_failures => true)
  end

  it 'should apply a second time without changes', :skip_pup_5016 do
    apply_manifest(pp, :catch_changes => true)
  end
end
end
