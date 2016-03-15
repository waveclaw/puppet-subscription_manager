# == Class subscription_manager::install
#
# This class is called from subscription_manager for install.
#
class subscription_manager::install {

  # any generic passed into the model
  package { $::subscription_manager::package_names:
    ensure => present,
  }

  if ($::subscription_manager::service_status in ['running', 'true']) {
    # 'true' is another value for running per
    #   https://docs.puppetlabs.com/puppet/latest/reference/type.html#service-attribute-ensure
    package { $::subscription_manager::service_packages:
      ensure  => present,
      require => Package[ $::subscription_manager::package_names ]
    }
  }

  # support a custom repository if procided
  if $::subscription_manager::repo != '' and
    $::subscription_manager::repo != undef {
    if versioncmp($::puppetversion, '3.4.1') > 0 {
      contain $::subscription_manager::repo
    } else {
      include $::subscription_manager::repo
    }
    Class[ $::subscription_manager::repo ] ->
      Package[ $::subscription_manager::package_names ]
  }

  $_pkg = "katello-ca-consumer-${::subscription_manager::server_hostname}"
  # four scenarios
  # I.  never registered
  #  - no ca_name
  #  - no identity
  #  - just install normally
  package { $_pkg:
    ensure   => 'installed',
    provider => 'rpm',
    source   =>
  "http://${::subscription_manager::server_hostname}/pub/katello-ca-consumer-latest.noarch.rpm",
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
      package { "katello-ca-consumer-${::rhsm_ca_name}": ensure => 'absent', }
      Package["katello-ca-consumer-${::rhsm_ca_name}"] -> Package[$_pkg]
    }
  }

  # IV. registered to same server but CA is bad
  #  - ca_name == server_hostname
  #  - identity is not set
  #  - reinstall (this requires a pupetlabs-transition)
  if $::rhsm_identity == '' or $::rhsm_identity == undef and
    $::rhsm_ca_name == $::subscription_manager::server_hostname {
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
