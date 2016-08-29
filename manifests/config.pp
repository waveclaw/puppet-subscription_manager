# == Class subscription_manager::config
#
# This class is called from subscription_manager for service config.
#
class subscription_manager::config {
  $_settings = {
    'activationkey'   => $::subscription_manager::activationkey,
    'username'        => $::subscription_manager::username,
    'password'        => $::subscription_manager::password,
    'pool'            => $::subscription_manager::pool,
    'smenvironment'   => $::subscription_manager::smenvironment,
    'autosubscribe'   => $::subscription_manager::autosubscribe,
    'force'           => $::subscription_manager::force,
    'org'             => $::subscription_manager::org,
    'servicelevel'    => $::subscription_manager::servicelevel,
    'ensure'          => 'present',
  }
  $_reg_params = { "${::subscription_manager::server_hostname}" => $_settings, }

  # Four cases
  # I.  never registered
  # II. registered to correct server but forcing it
  # III. registered to different server
  # IV. registered to same server but forcing it
  if ($::rhsm_identity == '' or $::rhsm_identity == undef or
      $::rhsm_ca_name != $::subscription_manager::server_hostname or
      $::subscription_manager::force == true ) {
      create_resources('rhsm_register', $_reg_params,
        {'require' => Rhsm_config['/etc/rhsm/rhsm.conf']})
  }

  $_conf_params = { '/etc/rhsm/rhsm.conf' =>
    $::subscription_manager::config_hash, }

# this part can be used with a pulp server used to 'init' new servers
#  if $::subscription_manager::config_hash['rhsm_baseurl'] == undef {
#    $_conf_params['/etc/rhsm/rhsm.conf']['rhsm_baseurl'] =
#      "https://${::subscription_manager::server_hostname}/pulp/repos"
#  }

  create_resources('rhsm_config', $_conf_params)
}
