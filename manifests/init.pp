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
#    * environment
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
  $service_name    = $::subscription_manager::defaults::service_name,
  $service_status  = $::subscription_manager::defaults::service_status,
  $server_hostname = $::subscription_manager::defaults::server_hostname,
  $username        = $::subscription_manager::defaults::username,
  $password        = $::subscription_manager::defaults::password,
  $activationkey   = $::subscription_manager::defaults::activationkey,
  $pool            = $::subscription_manager::defaults::pool,
  $environment     = $::subscription_manager::defaults::environment,
  $autosubscribe   = $::subscription_manager::defaults::autosubscribe,
  $servicelevel    = $::subscription_manager::defaults::servicelevel,
  $force           = $::subscription_manager::defaults::force,
  $org             = $::subscription_manager::defaults::org,
  $repo            = $::subscription_manager::defaults::repo,
  $config_hash     = $::subscription_manager::defaults::config_hash,
) inherits ::subscription_manager::defaults {

  validate_array($package_names)
  validate_string($service_name)
  validate_re($service_status, '^(stopped|running)$')
  validate_string($server_hostname)
  if $username {
    validate_string($username)
  }
  if $password {
    validate_string($password)
  }
  if $activationkey {
    validate_string($activationkey)
  }
  if $pool {
    validate_string($pool)
  }
  if $environment {
    validate_string($environment)
  }
  validate_bool($autosubscribe)
  if $servicelevel {
    validate_string($servicelevel)
  }
  validate_bool($force)
  if $org {
    validate_string($org)
  }
  if $repo {
    validate_string($repo)
  }
  validate_hash($config_hash)
  validate_bool($config_hash['server_insecure'])
  validate_string($config_hash['server_perfix'])
  validate_numeric($config_hash['server_port'])
  validate_numeric($config_hash['server_ssl_verify_depth'])
  if $config_hash['server_proxy_hostname'] {
    validate_string($config_hash['server_proxy_hostname'])
  }
  if $config_hash['server_proxy_hostname'] {
    validate_numeric($config_hash['server_proxy_port'])
  }
  if $config_hash['server_proxy_user'] {
    validate_string($config_hash['server_proxy_user'])
  }
  if $config_hash['server_proxy_password'] {
    validate_string($config_hash['server_proxy_password'])
  }
  validate_string($config_hash['rhsm_baseurl'])
  validate_absolute_path($config_hash['rhsm_ca_cert_dir'])
  validate_string($config_hash['rhsm_repo_ca_cert'])
  validate_absolute_path($config_hash['rhsm_productcertdir'])
  validate_absolute_path($config_hash['rhsm_entitlementcertdir'])
  validate_absolute_path($config_hash['rhsm_consumercertdir'])
  validate_bool($config_hash['rhsm_manage_repos'])
  validate_numeric($config_hash['rhsmcertd_certcheckinterval'])
  validate_numeric($config_hash['rhsmcertd_autoattachinterval'])

  class { '::subscription_manager::install': } ->
  class { '::subscription_manager::config': } ~>
  class { '::subscription_manager::service': } ->
  Class['::subscription_manager']
}
