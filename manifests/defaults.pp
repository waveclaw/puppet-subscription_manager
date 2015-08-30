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
      $server_hostname = 'https://rhn.redhat.com'
      $server_insecure = false
      $server_prefix = ''
      $rhsm_baseurl = ''
      $rhsm_cacert = ''
      $username = undef
      $password = undef
      $activationkeys = undef
      $pool = undef
      $environment = 'production'
      $autosubscribe = false
      $force = false
      $org = undef
      $repo = undef
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
