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
    'servicelevel'    => $::subscription_manager::servicelevel,
    'ensure'          => 'present',
  }
  $_reg_params = { "${::subscription_manager::server_hostname}" => $_settings, }
  create_resources('rhsm_register', $_reg_params)

  $_conf_params = { '/etc/rhsm/rhsm.conf' =>
    $::subscription_manager::config_hash, }
#  if $::subscription_manager::config_hash['rhsm_baseurl'] == undef {
#    $_conf_params['/etc/rhsm/rhsm.conf']['rhsm_baseurl'] =
#      "https://${::subscription_manager::server_hostname}/pulp/repos"
#  }
  create_resources('rhsm_config', $_conf_params)
}
