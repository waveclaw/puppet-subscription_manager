# Class: subscription_manager
# ===========================
#
# Setup to and register a Katello or RHN Satellite 6 client
#
# === Parameters
#
# @param [Array[String]] package_names packages to install
# * `package_names`
#   Name of packages to install. Defaults to subscrition-manager to get minimal
#   client support working.
#
# @param [String] ca_package_prefix prefix for the certname of the CA consumer
# * `ca_package_prefix`
#   Override the prefix of the package name for CA consumer. This is needed to
#   inegrate with RedHat Subscription Access Manager (SAM) and is otherwise
#   set to a default of katello-ca-consumer-, (Please note the hyphen.)
#
# @param [Array[String]] service_name services to manage
# * `service_name`
#   Name of the services to run or disable.  Defaults to the goferd, the
#   Katello orchestration daemon.
#
# @param [String] service_status what status to apply to managed services?
# * `service_status`
#   Status of the services.  Defaults to running.
#
# @param [String] server_hostname which server to register with?
# * `server_hostname`
#   The name of the server to register this agent to.
#
# @param [String] username which username for registration?
# * `username`
#   The username for registration to a server.  Conflicts with activationkey.
#
# @param [String] password which password for registration?
# * `password`
#   The password for the username for registration.  Conflicts with activationkey.
#
# @param [String] activationkey an activation key for registering to a server
# * `activationkey`
#   An activation key to use for registration of the agent to the server.
#   Conflicts with the username and password registration method.
#
# @param [String] pool a pool or RedHat Entitlement to automatically use
# * `pool`
#   A subscription pool or RedHat Entitlement to associate with this system.
#
# @param [String] lifecycleenv the environment of a content view
# * `lifecycleenv`
#   Originally called `environment`, this setting continues to refer to the
#   Lifecycle Environment of a Content View such as library, development, test,
#   et cetera as setup within the server.  Typically this would be handled by
#   the activation key.
#
# @param [Optional[String, Boolean, Enum['yes', 'no']]] autosubscribe automatically subscribe to repositories?
# * `autosubscribe`
#   Should the option be provided to automatically subscribe *all* potentially
#   valid repositories offered by the server.
#
# @param [String] servicelevel Override the service level during subscription
# * `servicelevel`
#   Applies to agents of a Satellite system with a valid RedHat Subscription.
#   Enables override of the default service level associated with an activation
#   key or control of this setting when using username and password registration.
#   Usually handled automatically by the activation key.
#
# @param [Optional[String, Boolean, Enum['yes', 'no']]] force Should the registration be forced?
# * `force`
#    If the registration should be attempted with the `--force` option to enabled
#    re-subscription of potentially valid agents.  Useful in the case of mass
#    subscription repair or bootstrapping. Otherwise a nuisance to a working
#    service.
#
# @param [String] org Which organization to subscribe to?
# * `org`
#   Organization to subscribe the system to.  Required for registration.
#
# @param [String] config_hash
# * `config_hash`
#   All the various possible settings to override such as server_proxy_hostname
#
# @param [Class] repo replacement repository as a source of packages
# * `repo`
#  Optional repo class that will be invoked by the install step
#  as a dependency for every package to install.
#
#  Use this if the required packages don't exist in a default repo.
#
# Variables
# ---------
#
# * `::osfamily`
#   Reject unsupported platforms
#
# * `::operatingsystem`
#   Label for a rejected plaform to use when notifying about rejection
#
# @example
#
#  class { subscription_manager:
#     activationkey = 'my-rhn-key',
#  }
#
# Authors
# -------
#
# Gaël Chamoulaud <gchamoul@redhat.com>
# JD Powell <waveclaw@waveclaw.net>
#
# Copyright
# ---------
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
  $lifecycleenv    = $::subscription_manager::defaults::lifecycleenv,
  $autosubscribe   = $::subscription_manager::defaults::autosubscribe,
  $servicelevel    = $::subscription_manager::defaults::servicelevel,
  $force           = $::subscription_manager::defaults::force,
  $org             = $::subscription_manager::defaults::org,
  $repo            = $::subscription_manager::defaults::repo,
  $config_hash     = $::subscription_manager::defaults::config_hash,
) inherits ::subscription_manager::defaults {

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
