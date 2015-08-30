# == Class: subscription_manager
#
# Setup to and register a Katello or RHN Satellite 6 client
#
# === Parameters
#
# [*package_names*]
#   Name of packages to install. Defaults to subscrition-manager and
#   katello-ca-consumer to get minimal client support working.
#
# [*service_name*]
#   Name of the services to run or disable.  Defaults to the goferd
#   Katello orchestration daemon.
#
# [*service_status*]
#   Status of the services.  Defaults to running.
#
# [*subscription settings*]
#  Settings per the resource rhsm_register
#    * server_hostname
#    * server_insecure
#    * server_prefix
#    * rhsm_baseurl
#    * rhsm_cacert
#    * username
#    * password
#    * activationkeys
#    * pool
#    * environment
#    * autosubscribe
#    * force
#    * org
#
# [repo]
#  Options repo class that will be invoked by the install step
#  as a dependency for every package to install.
#
#  Use this if the required packages don't exist in a default repo.
#
# === Examples
#
#  class { subscription_manager:
#
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
  $package_names = $::subscription_manager::defaults::package_names,
  $service_name = $::subscription_manager::defaults::service_name,
  $service_status = $::subscription_manager::defaults::service_status,
  $server_hostname = $::subscription_manager::defaults::server_hostname,
  $server_insecure = $::subscription_manager::defaults::server_insecure,
  $server_prefix = $::subscription_manager::defaults::server_prefix,
  $rhsm_baseurl = $::subscription_manager::defaults::rhsm_baseurl,
  $rhsm_cacert = $::subscription_manager::defaults::rhsm_cacert,
  $username = $::subscription_manager::defaults::username,
  $password = $::subscription_manager::defaults::password,
  $activationkeys = $::subscription_manager::defaults::activationkeys,
  $pool = $::subscription_manager::defaults::pool,
  $environment = $::subscription_manager::defaults::environment,
  $autosubscribe = $::subscription_manager::defaults::autosubscribe,
  $force = $::subscription_manager::defaults::force,
  $org = $::subscription_manager::defaults::org,
  $repo = $::subscription_manager::defaults::repo,
) inherits ::subscription_manager::defaults {

  # TODO: validate parameters here
  # validate_x() requires puppetlabs-stdlib

  class { '::subscription_manager::install': } ->
  class { '::subscription_manager::config': } ~>
  class { '::subscription_manager::service': } ->
  Class['::subscription_manager']
}
