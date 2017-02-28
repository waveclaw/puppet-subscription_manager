# == Class: subscription_manager
#
# Setup to and register a Katello or RHN Satellite 6 client
#
# === Parameters
#
# [*package_names*]
#   Name of packages to install. Defaults to subscrition-manager to get minimal
#   client support working.
#
# [*ca_package_prefix*]
#   Override the prefix of the package name for CA consumer. This is needed to
#   inegrate with RedHat Subscription Access Manager (SAM) and is otherwise
#   set to a default of katello-ca-consumer-, (Please note the hyphen.)
#
# [*service_name*]
#   Name of the services to run or disable.  Defaults to the goferd
#   Katello orchestration daemon.
#
# [*service_status*]
#   Status of the services.  Defaults to running.
#
# [*subscription settings*]
#  Settings per the resource rhsm_config
#    * server_hostname
#    * server_insecure
#    * server_prefix
#    * rhsm_baseurl
#    * rhsm_cacert
#
# [*registration settings*]
#  Settings per the resource rhsm_register
#    * username
#    * password
#    * activationkeys
#    * pool
#    * smenvironment
#    * autosubscribe
#    * servicelevel
#    * force
#    * org
#
# [repo]
#  Optional repo class that will be invoked by the install step
#  as a dependency for every package to install.
#
#  Use this if the required packages don't exist in a default repo.
#
# == Variables
#
# [*osfamily*]
#   Will reject operation on unsupported platforms
#
# === Examples
#
#  class { subscription_manager:
#     activationkey = 'my-rhn-key',
#  }
#
# === Authors
#
# Gaël Chamoulaud <gchamoul@redhat.com>
# JD Powell <waveclaw@waveclaw.net>
#
# === Copyright
#
# Copyright 2015 Gaël Chamoulaud <gchamoul@redhat.com>
#
class subscription_manager (
  $package_names   = $::subscription_manager::defaults::package_names,
  $ca_package_prefix = $::subscription_manager::defaults::ca_package_prefix,
  $service_name    = $::subscription_manager::defaults::service_name,
  $service_status  = $::subscription_manager::defaults::service_status,
  $server_hostname = $::subscription_manager::defaults::server_hostname,
  $username        = $::subscription_manager::defaults::username,
  $password        = $::subscription_manager::defaults::password,
  $activationkey   = $::subscription_manager::defaults::activationkey,
  $pool            = $::subscription_manager::defaults::pool,
  $smenvironment     = $::subscription_manager::defaults::smenvironment,
  $autosubscribe   = $::subscription_manager::defaults::autosubscribe,
  $servicelevel    = $::subscription_manager::defaults::servicelevel,
  $force           = $::subscription_manager::defaults::force,
  $org             = $::subscription_manager::defaults::org,
  $repo            = $::subscription_manager::defaults::repo,
  $config_hash     = $::subscription_manager::defaults::config_hash,
) inherits ::subscription_manager::defaults {

  # validate_x() requires puppetlabs-stdlib and annoys some of the users

  # limit use to supported Operating Systems
  case $::osfamily {
    'RedHat', 'CentOS', 'Scientific', 'Fedora': {
      class { '::subscription_manager::install': } ->
      class { '::subscription_manager::config': } ~>
      class { '::subscription_manager::service': } ->
      Class['::subscription_manager']
    }
    default: {
      notify { "${::operatingsystem} not supported by subscription_manager": }
    }
  }
}
