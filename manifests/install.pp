# == Class subscription_manager::install
#
# This class is called from subscription_manager for install.
#
class subscription_manager::install {

  package { $::subscription_manager::package_names:
    ensure => present,
  }
  if $::subscription_manager::repo {
    if versioncmp($::puppetversion, '3.4.1') > 0 {
      contain $::subscription_manager::repo
    } else {
      include $::subscription_manager::repo
    }
    Class[ $::subscription_manager::repo ] ->
      Package[ $::subscription_manager::package_names ]
  }

  if $::rhsm_ca_name {
    if $::rhsm_ca_name != $::subscription_manager::server_hostname {
      package { "katello-ca-consumer-${::rhsm_ca_name}": ensure => 'absent', }
      Package["katello-ca-consumer-${::rhsm_ca_name}"] ->
      Package["katello-ca-consumer-${::subscription_manager::server_hostname}"]
    }
  }

  package { "katello-ca-consumer-${::subscription_manager::server_hostname}":
    ensure   => 'installed',
    provider => 'rpm',
    source   =>
  "http://${::subscription_manager::server_hostname}/pub/katello-ca-consumer-latest.noarch.rpm",
  }
}
