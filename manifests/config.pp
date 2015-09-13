# == Class subscription_manager::config
#
# This class is called from subscription_manager for service config.
#
class subscription_manager::config {
  $_settings = {
    'activationkey'  => $::subscription_manager::activationkey,
    'username'        => $::subscription_manager::username,
    'password'        => $::subscription_manager::password,
    'pool'            => $::subscription_manager::pool,
    'environment'     => $::subscription_manager::environment,
    'autosubscribe'   => $::subscription_manager::autosubscribe,
    'force'           => $::subscription_manager::force,
    'org'             => $::subscription_manager::org,
    'servicelevel'   => $::subscription_manager::servicelevel,
  }
  $_reg_params = { "${::subscription_manager::server_hostname}" => $_settings, }
  create_resources('rhsm_register', $_reg_params)

  if $::subscription_manager::config_hash['rhsm_baseurl'] == undef {
    $_baseurl = "https://${::subscription_manager::server_hostname}/pulp/repos"
  } else {
    $_baseurl = $::subscription_manager::config_hash['rhsm_baseurl']
  }
  $_conf_params = { "${::subscription_manager::server_hostname}" =>
  $::subscription_manager::config_hash, }
  create_resources('rhsm_config', $_conf_params)
}
