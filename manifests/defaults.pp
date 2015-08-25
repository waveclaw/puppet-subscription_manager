# == Class subscription_manager::defaults
#
# This class is meant to be called from subscription_manager.
# It sets variables according to platform.
#
class subscription_manager::defaults {
  case $::osfamily {
    'RedHat', 'CentOS', 'Fedora': {
      $package_names = ['subscription-manager','katello-ca-consumer']
      $service_name = 'goferd'
      $service_status = 'running'
      $subscription_settings = {}
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
