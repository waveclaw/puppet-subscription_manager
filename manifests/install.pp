# Class subscription_manager::install
# ===================================
#
# This class is called from subscription_manager for install of packages and the
# setup of repositories for the certificate authority and other tools.
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
# Copyright 2016 JD Powell <waveclaw@waveclaw.net>
#
class subscription_manager::install {

  # any generic passed into the model
  package { $::subscription_manager::package_names:
    ensure => present,
  }

  # support a custom repository if provided
  $_version = $::puppetversion ? {
    undef   => '', # when was puppetversion added? (see PUP-4359)
    default => $::puppetversion,
  }
  if $::subscription_manager::repo != '' and
    $::subscription_manager::repo != undef {
    if versioncmp($_version, '3.4.1') > 0 {
      contain $::subscription_manager::repo
    } else {
      include $::subscription_manager::repo
    }
    Class[ $::subscription_manager::repo ] ->
      Package[ $::subscription_manager::package_names ]
  }

  $_prefix = $::subscription_manager::ca_package_prefix
  $_suffix = $::subscription_manager::server_hostname
  $_pkg = "${_prefix}${_suffix}" # 80-column puppet-lint limit workaround

  # four scenarios
  # I.  never registered
  #  - no ca_name
  #  - no identity
  #  - just install normally
  package { $_pkg:
    ensure   => 'present',
    provider => 'rpm',
    source   =>
  "http://${::subscription_manager::server_hostname}/pub/${::ca_package_prefix}latest.noarch.rpm",
  }

  # II. registered to correct server
  #  - ca_name == server_hostname
  #  - identity is set
  #  - do nothing new, let puppet idempotency handle it

  # III. registered to different server
  #  - ca_name != server_hostname
  #  - identity may or may not be set
  #  - remove old, install new
  if $::rhsm_ca_name != '' and $::rhsm_ca_name != undef {
    # an SSL Certificate Authority is detected
    if $::rhsm_ca_name != $::subscription_manager::server_hostname {
      # but CA is changing
      # remove the old package
      package { "${_prefix}${::rhsm_ca_name}": ensure => 'absent', }
      Package["${_prefix}${::rhsm_ca_name}"] -> Package[$_pkg]
    }
  }

  # IV. registered to same server but CA is bad
  #  - ca_name == server_hostname
  #  - identity is not set
  #  - reinstall (this requires a pupetlabs-transition)
  # This case is meant to prevent extra regitrations on pre-6.2 Satellite
  if ((($::rhsm_identity == '' or $::rhsm_identity == undef) and
    $::rhsm_ca_name == $::subscription_manager::server_hostname) or
    ($::rhsm_ca_name == $::subscription_manager::server_hostname and
    $::subscription_manager::force == true )) {
    $_attributes = {
      'ensure'          => 'absent',
      'provider'        => 'rpm',
      'install_options' => [ '--force', '--nodeps' ],
    }
    transition {'purge-bad-rhsm_ca-package':
      resource   => Package[$_pkg],
      attributes => $_attributes,
      prior_to   => Package[$_pkg],
    }
  }

}
