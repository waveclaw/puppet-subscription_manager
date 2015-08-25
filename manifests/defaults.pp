# == Class subscription_manager::defaults
#
# This class is meant to be called from subscription_manager.
# It sets variables according to platform.
#
class subscription_manager::defaults {
  case $::osfamily {
    'RedHat', 'CentOS', 'Fedora': {
      $package_name = 'subscription_manager'
      $service_name = 'subscription_manager'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
