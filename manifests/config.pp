# == Class subscription_manager::config
#
# This class is called from subscription_manager for service config.
#
class subscription_manager::config {
  if $::subscription_manager::server_hostname {
    if $::subscription_manager::activationkeys {
      $_settings = {
        'server_hostname' => $::subscription_manager::server_hostname,
        'server_insecure' => $::subscription_manager::server_insecure,
        'server_prefix'   => $::subscription_manager::server_prefix,
        'rhsm_baseurl'    => $::subscription_manager::rhsm_baseurl,
        'rhsm_cacert'     => $::subscription_manager::rhsm_cacert,
        'activationkeys'  => $::subscription_manager::activationkeys,
        'pool'            => $::subscription_manager::pool,
        'environment'     => $::subscription_manager::environment,
        'autosubscribe'   => $::subscription_manager::autosubscribe,
        'force'           => $::subscription_manager::force,
        'org'             => $::subscription_manager::org,
      }
    } elsif ($::subscription_manager::username and
      $::subscription_manager::password) {
      $_settings = {
        'server_hostname' => $::subscription_manager::server_hostname,
        'server_insecure' => $::subscription_manager::server_insecure,
        'server_prefix'   => $::subscription_manager::server_prefix,
        'rhsm_baseurl'    => $::subscription_manager::rhsm_baseurl,
        'rhsm_cacert'     => $::subscription_manager::rhsm_cacert,
        'username'        => $::subscription_manager::username,
        'password'        => $::subscription_manager::password,
        'pool'            => $::subscription_manager::pool,
        'environment'     => $::subscription_manager::environment,
        'autosubscribe'   => $::subscription_manager::autosubscribe,
        'force'           => $::subscription_manager::force,
        'org'             => $::subscription_manager::org,
      }
    } else {
      $_settings = undef
    }
  } else {
    $_settings = undef
  }
  if $_settings {
    $_params = { "${::subscription_manager::server_hostname}" => $_settings, }
    create_resources('rhsm_register', $_params)
    $http = $::subscription_manager::server_prefix
    $host = $::subscription_manager::server_hostname
    package {'katello-ca-consumer-latest':
      ensure   => 'installed',
      provider => 'rpm',
      source   => "${http}://${host}/pub/katello-ca-consumer-latest.noarch.rpm",
    }
    Package['katello-ca-consumer-latest'] ->
    Rhsm_register[$::subscription_manager::server_hostname]
  }
}
