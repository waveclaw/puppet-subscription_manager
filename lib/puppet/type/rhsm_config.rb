#!/usr/bin/ruby
#
#  Describe a client configuration for katello or Satellite 6.
#
# based on https://access.redhat.com/documentation/en-US/Red_Hat_Subscription_Management/1/html/RHSM/rhsm-config.html#tab.rhsm.conf-parameters
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'puppet/parameter/boolean'
require 'puppet/type'
require 'uri'


Puppet::Type.newtype(:rhsm_config) do
  @doc = <<-EOD
 Configure a system to user a Satellite or Spacewalk server.

 Example:

  rhsm_config { 'katello.example.com':
     insecure               => false,
     port                   => 443,
     prefix                 => '/rhsm',
     ssl_verify_depth       => 3,
     baseurl                => 'https://katello.example.com/pulp/repos',
     ca_cert_dir            => '/etc/rhsm/ca/',
     consumercertdir        => '/etc/pki/consumer',
     entitlementcertdir     => '/etc/pki/entitlement',
     full_refresh_on_yum    => true,
     manage_repos           => true,
     pluginconfdir          => '/etc/rhsm/pluginconf_d',
     plugindir              => '/usr/share/rhsm-plugins',
     productcertdir         => '/etc/pki/product',
     repo_ca_cert           => '/etc/rhsm/ca/ca.pem,'
     report_package_profile => 1,
     proxy_hostname         => 'proxy.example.com',
     proxy_port             => '44443',
  }

EOD

ensurable

# This type simulates a file but accesses it through an OS command
$default_filename = '/etc/rhsm/rhsm.conf'

def self.text_options
  {
  :server_hostname => 'server.hostname',
  :server_prefix => 'server.prefix',
  :server_port => 'server.port',
  :server_server_timeout => 'server.server_timeout',
  :server_ssl_verify_depth => 'server.ssl_verify_depth',
  :server_proxy_hostname => 'server.proxy_hostname',
  :server_proxy_port => 'server.proxy_port',
  :server_proxy_user => 'server.proxy_user',
  :server_proxy_password => 'server.proxy_password',
  :server_no_proxy => 'server.no_proxy',
  :rhsm_baseurl => 'rhsm.baseurl',
  :rhsm_ca_cert_dir => 'rhsm.ca_cert_dir',
  :rhsm_repo_ca_cert => 'rhsm.repo_ca_cert',
  :rhsm_productcertdir => 'rhsm.productcertdir',
  :rhsm_entitlementcertdir => 'rhsm.entitlementcertdir',
  :rhsm_consumercertdir => 'rhsm.consumercertdir',
  :rhsm_pluginconfdir => 'rhsm.pluginconfdir',
  :rhsm_plugindir => 'rhsm.plugindir',
  :rhsmcertd_certcheckinterval => 'rhsmcertd.certcheckinterval',
  :rhsmcertd_autoattachinterval => 'rhsmcertd.autoattachinterval',
  :logging_default_log_level => 'logging.default_log_level',
  :logging_subscription_manager => 'logging.subscription_manager',
  :logging_rhsm => 'logging.rhsm',
  :logging_rhsm_app => 'logging.rhsm-app'
  }
end

def self.binary_options
  {
  :server_insecure => 'server.insecure',
  :rhsm_manage_repos => 'rhsm.manage_repos',
  :rhsm_full_refresh_on_yum => 'rhsm.full_refresh_on_yum',
  :rhsm_report_package_profile => 'rhsm.report_package_profile'
  }
end

  newparam(:name, :namevar => true) do
    desc "The configuration file"
    defaultto $default_filename
    validate do |value|
      unless (value == File.expand_path(value) and
             value =~ /^\/.*/ and
             value.length > 1 and
             !File.directory?(value))
        fail("Require an absolute path ending in a filename.  Was given #{value} for name.")
      end
    end
  end

  newproperty(:server_hostname) do
    desc "The rhsm server hostname."
    validate do |value|
      fail("Require a valid hostname. Received #{value} instead") unless value =~ /^[.a-zA-Z\-\_0-9]+$/
    end
    munge do |value|
      value.downcase unless (value == :absent or value == :undef)
    end
  end

  newproperty(:server_proxy_hostname) do
    desc "The name of the proxy to connect through to reach the server."
    validate do |value|
      fail("Require a valid hostname. Received #{value} instead") unless value.nil? or value == '' or  value =~ /^\[?[.a-zA-Z\-\_0-9]*$\]?/
    end
    munge do |value|
      value.downcase unless (value == :absent or value == :undef or value.nil?)
    end

  end

  newproperty(:server_proxy_user) do
    desc "Proxy username"
  end

  newproperty(:server_ssl_verify_depth) do
    desc "How far up an intermediate chain should we check for SSL certificate signatures?"
    validate do |value|
      fail("Require a small positive number. Was given #{value}.") unless value.nil? or ( value.to_i and (value.to_i >= 0))
    end
  end

  newproperty(:server_proxy_password) do
    desc "Password for the proxy."
  end

  newproperty(:server_proxy_port) do
    desc "Proxy port to connect to"
    validate do |value|
      fail("Require a small positive number. Was given #{value}.") unless value.nil? or ( value.to_i and (value.to_i >= 0))
    end
  end
  
  newproperty(:server_no_proxy) do
    desc "Proxy exception list"
  end

  newproperty(:server_prefix) do
    desc "Path on the server for the Candlepin service."
    validate do |value|
      fail("Require a url-valid path.  Was given #{value}.") unless value =~ /^\/[_\-0-9a-zA-Z.\/]+/
    end
  end

  newproperty(:server_port) do
    desc "Port on the server for the RHSM service."
    validate do |value|
      fail("Require a small positive number. Was given #{value}.") unless value.to_i and (value.to_i >= 0)
    end
  end

  newproperty(:server_server_timeout) do
    desc "Server Timeout"
    validate do |value|
      fail("Require a small positive number. Was given #{value}.") unless value.to_i and (value.to_i >= 0)
    end
  end

  newproperty(:rhsm_entitlementcertdir) do
    desc "The certificate directory of the RHSM entitlements."
    validate do |value|
      fail("Require a valid aboslute UNIX path.  Was given #{value}.") unless value =~ /^\/[\/_\-0-9a-zA-Z.]*$/ or value =~ /.*\.\..*/
    end
  end

  newproperty(:rhsm_pluginconfdir) do
    desc "The RHN Plugin configuration directory."
    validate do |value|
      fail("Require a valid aboslute UNIX path.  Was given #{value}.") unless value =~ /^\/[\/_\-0-9a-zA-Z.]*$/ or value =~ /.*\.\..*/
    end
  end

  newproperty(:rhsm_baseurl) do
    desc "The content server.  Usually a full URL of the Pulp service endpoint."
    validate do |value|
      fail("Require a proper url to the Pulp instance.  Was given #{value}.") unless !!URI.parse(value)
    end
  end

  newproperty(:rhsm_plugindir) do
    desc "The RHN Plugin directory."
    validate do |value|
      fail("Require a valid aboslute UNIX path.  Was given #{value}.") unless value =~ /^\/[\/_\-0-9a-zA-Z.]*$/ or value =~ /.*\.\..*/
    end
  end

  newproperty(:rhsm_ca_cert_dir) do
    desc "The CA certificate directory."
    validate do |value|
      fail("Require a valid aboslute UNIX path.  Was given #{value}.") unless value =~ /^\/[\/_\-0-9a-zA-Z.]*$/ or value =~ /.*\.\..*/
    end
  end

  newproperty(:rhsm_productcertdir) do
    desc "The certificate directory of the RHSM Products."
    validate do |value|
      fail("Require a valid aboslute UNIX path.  Was given #{value}.") unless value =~ /^\/[\/_\-0-9a-zA-Z.]*$/ or value =~ /.*\.\..*/
    end
  end

  newproperty(:rhsm_consumercertdir) do
    desc "The Consumer certificate directory."
    validate do |value|
      fail("Require a valid aboslute UNIX path.  Was given #{value}.") unless value =~ /^\/[\/_\-0-9a-zA-Z.]*$/ or value =~ /.*\.\..*/
    end
  end

  newproperty(:logging_default_log_level) do
    desc "The default log level for all loggers."
    validate do |value|
      fail("Require a valid log level (DEBUG, INFO, WARNING, ERROR, or CRITICAL).  Was given #{value}.") unless value =~ /(DEBUG|INFO|WARNING|ERROR|CRITICAL)/
    end
  end


  newproperty(:logging_subscription_manager) do
    desc "The  log level for all subscription_manager modules. Not that sub-modules are not configurable by this."
    validate do |value|
      fail("Require a valid log level (DEBUG, INFO, WARNING, ERROR, or CRITICAL).  Was given #{value}.") unless value =~ /(DEBUG|INFO|WARNING|ERROR|CRITICAL)/
    end
  end


  newproperty(:logging_rhsm) do
    desc "The log level for rhsm itself."
    validate do |value|
      fail("Require a valid log level (DEBUG, INFO, WARNING, ERROR, or CRITICAL).  Was given #{value}.") unless value =~ /(DEBUG|INFO|WARNING|ERROR|CRITICAL)/
    end
  end

  newproperty(:logging_rhsm_app) do
    desc "The log level for the rhsm-app 'application.'"
    validate do |value|
      fail("Require a valid log level (DEBUG, INFO, WARNING, ERROR, or CRITICAL).  Was given #{value}.") unless value =~ /(DEBUG|INFO|WARNING|ERROR|CRITICAL)/
    end
  end

  newproperty(:server_insecure,  :boolean => true) do
    desc "Either use HTTP or do not verify the SSL ceriticate for HTTPS"
    defaultto false
    newvalues(true, false)
    munge do |value|
      case value
      when /yes/i, /true/i, '1', 1, true, :true, :yes
        true
      when /no/i, /false/i, '0', 0, false, :false, :no
        false
      else
        nil
      end
    end
  end

  newproperty(:rhsm_manage_repos,  :boolean => true) do
    desc "Create and use a redhat.repo yum file?"
    defaultto true
    newvalues(true, false)
    munge do |value|
      case value
      when /yes/i, /true/i, '1', 1, true, :true, :yes
        true
      when /no/i, /false/i, '0', 0, false, :false, :no
        false
      else
        nil
      end
    end
  end

  newproperty(:rhsm_full_refresh_on_yum, :boolean => true) do
    desc "Force a Full refresh when yum is run?"
    defaultto false
    newvalues(true, false)
    munge do |value|
      case value
      when /yes/i, /true/i, '1', 1, true, :true, :yes
        true
      when /no/i, /false/i, '0', 0, false, :false, :no
        false
      else
        nil
      end
    end
  end

  newproperty(:rhsm_report_package_profile,  :boolean => true) do
    desc "Should the package profile be reported?"
    defaultto true
    newvalues(true, false)
    munge do |value|
      case value
      when /yes/i, /true/i, '1', 1, true, :true, :yes
        true
      when /no/i, /false/i, '0', 0, false, :false, :no
        false
      else
        nil
      end
    end
  end

  newproperty(:rhsm_repo_ca_cert) do
    desc "Path to Repository CA certificates."
  end

  newproperty(:rhsmcertd_certcheckinterval) do
    desc "Minutes for rhsmcertd to wait between checking the certificates."
    validate do |value|
      fail("Require a small positive number. Was given #{value}.") unless value.to_i and (value.to_i >= 0)
    end
  end

  newproperty(:rhsmcertd_autoattachinterval) do
    desc "How long in minutes should rhsmcertd wait between checking for subscriptions to re-attach? 0 implies the default frequency of daily (1440 minutes)."
    validate do |value|
      fail("Require a small positive number. Was given #{value}.") unless value.to_i and (value.to_i >= 0)
    end
  end

end
