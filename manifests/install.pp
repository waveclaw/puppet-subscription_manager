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
}
