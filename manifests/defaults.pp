# == Class subscription_manager::defaults
#
# This class is meant to be called from subscription_manager.
# It sets variables according to platform.
# These defaults are for registration with the RedHat Network.
# For an examaple with a katello server, see README.md
class subscription_manager::defaults {
  case $::osfamily {
    'RedHat', 'CentOS', 'Scientific', 'Fedora': {
      $server_hostname = 'subscription.rhn.redhat.com'
      $package_names = ['subscription-manager']
      $service_name = 'goferd'
      $service_status = 'running'
      $config_hash = {
        'server_insecure'               => false,
        'server_prefix'                 => '/subscription',
        'server_port'                   => 443,
        'server_ssl_verify_depth'       => 3,
        'server_proxy_hostname'         => '',
        'server_proxy_port'             => '',
        'server_proxy_user'             => '',
        'server_proxy_password'         => '',
        'rhsm_baseurl'                  => 'https://cdn.redhat.com',
        'rhsm_ca_cert_dir'              => '/etc/rhsm/ca',
        'rhsm_repo_ca_cert'             => '%(ca_cert_dir)/redhat-uep.pem',
        'rhsm_productcertdir'           => '/etc/pki/product',
        'rhsm_entitlementcertdir'       => '/etc/pki/entitlement',
        'rhsm_consumercertdir'          => '/etc/pki/consumer',
        'rhsm_manage_repos'             => true,
        'rhsmcertd_certcheckinterval'   => 240,
        'rhsmcertd_autoattachinterval'  => 1440,
      }
      $username = undef
      $password = undef
      $activationkey = undef
      $pool = undef
      $servicelevel = undef
      $environment = undef # cannot use with an activation key!
      $autosubscribe = false
      $force = false
      $org = 'Default_Organization'
      $repo = undef
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
