# Class: subscription_manager
# ===========================
#
# Setup to and register a Katello or RHN Satellite 6 client
#
# Parameters
# ----------
#
# @param package_names packages to install
# * `package_names`
#   Name of packages to install. Defaults to subscrition-manager to get minimal
#   client support working.
#
# @param ca_package_prefix prefix for the certname of the CA consumer
# * `ca_package_prefix`
#   Override the prefix of the package name for CA consumer. This is needed to
#   inegrate with RedHat Subscription Access Manager (SAM) and is otherwise
#   set to a default of katello-ca-consumer-, (Please note the hyphen.)
#
# @param service_name services to manage
# * `service_name`
#   Name of the services to run or disable.  Defaults to the goferd, the
#   Katello orchestration daemon.
#
# @param service_status what status to apply to managed services?
# * `service_status`
#   Status of the services.  Defaults to running.
#
# @param server_hostname which server to register with?
# * `server_hostname`
#   The name of the server to register this agent to.
#
# @param username which username for registration?
# * `username`
#   The username for registration to a server.  Conflicts with activationkey.
#
# @param password which password for registration?
# * `password`
#   The password for the username for registration.  Conflicts with activationkey.
#
# @param activationkey an activation key for registering to a server
# * `activationkey`
#   An activation key to use for registration of the agent to the server.
#   Conflicts with the username and password registration method.
#
# @param pool a pool or RedHat Entitlement to automatically use
# * `pool`
#   A subscription pool or RedHat Entitlement to associate with this system.
#
# @param lifecycleenv the environment of a content view
# * `lifecycleenv`
#   Originally called `environment`, this setting continues to refer to the
#   Lifecycle Environment of a Content View such as library, development, test,
#   et cetera as setup within the server.  Typically this would be handled by
#   the activation key and conflicts with using a key to register.
#
# @param autosubscribe automatically subscribe to repositories?
# * `autosubscribe`
#   Should the option be provided to automatically subscribe *all* potentially
#   valid repositories offered by the server.
#
# @param servicelevel Override the service level during subscription
# * `servicelevel`
#   Applies to agents of a Satellite system with a valid RedHat Subscription.
#   Enables override of the default service level associated with an activation
#   key or control of this setting when using username and password registration.
#   Usually handled automatically by the activation key.
#
# @param force Should the registration be forced?
# * `force`
#    If the registration should be attempted with the `--force` option to enabled
#    re-subscription of potentially valid agents.  Useful in the case of mass
#    subscription repair or bootstrapping. Otherwise a nuisance to a working
#    service.
#
# @param org Which organization to subscribe to?
# * `org`
#   Organization to subscribe the system to.  Required for registration.
#
# @param repo replacement repository as a source of packages
# * `repo`
#  Optional repo class that will be invoked by the install step
#  as a dependency for every package to install.
#
#  Use this if the required packages don't exist in a default repo.
#
# @param config_hash
# * `config_hash`
#   All the various possible settings to override such as server_proxy_hostname
#   See the /data/defaults.yaml for an example of the default settings.
#
# Variables
# ---------
#
# * `::facts['os']['family']`
#   Reject unsupported platforms
#
# * `::facts['os']['description']`
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
# * Gaël Chamoulaud <gchamoul@redhat.com>
# * JD Powell <waveclaw@waveclaw.net>
#
# Copyright
# ---------
#
# Copyright 2015 Gaël Chamoulaud <gchamoul@redhat.com>
#
class subscription_manager (
  Array[String] $package_names = ['subscription-manager'],
  String $ca_package_prefix = 'katello-ca-consumer-',
  String $service_name = 'goferd',
  Enum['running','stopped', 'disabled', 'enabled'] $service_status = 'running',
  String $server_hostname = 'subscription.rhn.redhat.com',
  String $username = '',
  String $password = '',
  String $activationkey = '',
  String $pool = '',
  String $lifecycleenv = 'library',
  Variant[String, Boolean, Enum['yes','no']] $autosubscribe = false,
  String $servicelevel = 'Standard',
  Variant[String, Boolean, Enum['yes','no']] $force = false,
  String $org = 'Default_Organization',
  Variant[String, Class] $repo = '',
  Hash $config_hash = {},
) {

  # limit use to supported Operating Systems
  case $::facts['os']['family'] {
    'RedHat', 'CentOS', 'Scientific', 'Fedora': {
      class { '::subscription_manager::install': } ->
      class { '::subscription_manager::config': } ~>
      class { '::subscription_manager::service': } ->
      Class['::subscription_manager']
    }
    default: {
      notify { "${::facts['os']['description']} not supported by subscription_manager": }
    }
  }
}
