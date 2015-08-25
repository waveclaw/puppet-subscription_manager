# == Class subscription_manager::install
#
# This class is called from subscription_manager for install.
#
class subscription_manager::install {

  package { $::subscription_manager::package_name:
    ensure => present,
  }
}
