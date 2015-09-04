# == Class subscription_manager::config
#
# This class is called from subscription_manager for service config.
#
class subscription_manager::config {
  if $::subscription_manager::server_hostname {
    $_host = $::subscription_manager::server_hostname
    if $::subscription_manager::rhsm_baseurl == undef {
      $_baseurl = "https://${_host}/pulp/repos"
    } else {
      $_baseurl = $::subscription_manager::rhsm_baseurl
    }
    if $::subscription_manager::activationkeys {
      $_settings = {
        'server_hostname' => $_host,
        'server_insecure' => $::subscription_manager::server_insecure,
        'server_prefix'   => $::subscription_manager::server_prefix,
        'rhsm_baseurl'    => $_baseurl,
        'rhsm_cacert'     => $::subscription_manager::rhsm_cacert,
        'activationkeys'  => $::subscription_manager::activationkeys,
        'autosubscribe'   => $::subscription_manager::autosubscribe,
        'force'           => $::subscription_manager::force,
        'org'             => $::subscription_manager::org,
      }
    } elsif ($::subscription_manager::username and
      $::subscription_manager::password) {
      $_settings = {
        'server_hostname' => $_host,
        'server_insecure' => $::subscription_manager::server_insecure,
        'server_prefix'   => $::subscription_manager::server_prefix,
        'rhsm_baseurl'    => $_baseurl,
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
    $_params = { "${_host}" => $_settings, }
    create_resources('rhsm_register', $_params)
    package { "katello-ca-consumer-${_host}":
      ensure   => 'installed',
      provider => 'rpm',
      source   => "http://${_host}/pub/katello-ca-consumer-latest.noarch.rpm",
    }
    Package["katello-ca-consumer-${_host}"] ->
    Rhsm_register[$::subscription_manager::server_hostname]
  }
}
