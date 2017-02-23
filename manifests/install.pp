# Class subscription_manager::install
# ===================================
#
# This class is called from subscription_manager for install of packages and the
# setup of repositories for the certificate authority and other tools.
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
# Copyright 2016 JD Powell <waveclaw@waveclaw.net>
#
class subscription_manager::install {

  # the files for the Facts
  $_file_defaults = {
    'owner' => 0,
    'group' => 0,
    'mode'  => '0755',
  }
  file {
    default:
      * => $_file_defaults
    ;
    '/var/cache/rhsm':
      ensure => directory
    ;
  }

  # any generic passed into the model
  package { $::subscription_manager::package_names:
    ensure => present,
  }


  if $::subscription_manager::repo != '' and
    $::subscription_manager::repo != undef {
      contain $::subscription_manager::repo
      Class[ $::subscription_manager::repo ] ->
      Package[ $::subscription_manager::package_names ]
  }

  # shorten several really long names
  $_ca       = $::facts['rhsm_ca_name']
  $_id       = $::facts['rhsm_identity']
  $_prefix   = $::subscription_manager::ca_package_prefix
  $_hostname = $::subscription_manager::server_hostname
  $_pkg      = "${_prefix}${_hostname}" # 80-column puppet-lint limit workaround

  # four scenarios
  # I.  never registered
  #  - no ca_name
  #  - no identity
  #  - just install normally
  package { $_pkg:
    ensure   => 'present',
    provider => 'rpm',
    source   =>
  "http://${_hostname}/pub/${_prefix}latest.noarch.rpm",
  }

  # II. registered to correct server
  #  - ca_name == server_hostname
  #  - identity is set
  #  - do nothing new, let puppet idempotency handle it

  # III. registered to different server
  #  - ca_name != server_hostname
  #  - identity may or may not be set
  #  - remove old, install new
  if $_ca != '' and $_ca != undef {
    # an SSL Certificate Authority is detected
    # does it match server_hostname (aka _suffix for the package)
    if $_ca != $_hostname {
      # but CA is changing
      # remove the old package
      package { "${_prefix}${_ca}": ensure => 'absent', }
      Package["${_prefix}${_ca}"] -> Package[$_pkg]
    }
  }

  # IV. registered to same server but CA is bad
  #  - ca_name == server_hostname
  #  - identity is not set
  #  - reinstall (this requires a pupetlabs-transition)
  # This case is meant to prevent extra regitrations on pre-6.2 Satellite
  if ((($_id == '' or $_id == undef) and $_ca == $_hostname) or
    ($_ca == $_hostname and $::subscription_manager::force == true )) {
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
