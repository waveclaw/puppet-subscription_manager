# Class subscription_manager::config
# ==================================
#
# This class is called from subscription_manager for service config.
#
# Authors
# -------
#
# * Gaël Chamoulaud <gchamoul@redhat.com>
# * JD Powell <waveclaw@waveclaw.net>
#
# Copyright
# ---------
#
# Copyright 2016 JD Powell <waveclaw@waveclaw.net>
#
class subscription_manager::config {

  # prefer activation keys to username.  Then fail when neither are provided
  if  $::subscription_manager::activationkey != undef and
      $::subscription_manager::activationkey != '' {
        $_settings = {
          'pool'            => $::subscription_manager::pool,
          'autosubscribe'   => $::subscription_manager::autosubscribe,
          'force'           => $::subscription_manager::force,
          'org'             => $::subscription_manager::org,
          'servicelevel'    => $::subscription_manager::servicelevel,
          'activationkey'   => $::subscription_manager::activationkey,
        }
  } else {
    if  $::subscription_manager::username != undef and
        $::subscription_manager::username !='' and
        $::subscription_manager::password != undef and
        $::subscription_manager::password != '' {
          $_settings = {
            'pool'          => $::subscription_manager::pool,
            'autosubscribe' => $::subscription_manager::autosubscribe,
            'force'         => $::subscription_manager::force,
            'org'           => $::subscription_manager::org,
            'servicelevel'  => $::subscription_manager::servicelevel,
            'username'      => $::subscription_manager::username,
            'password'      => $::subscription_manager::password,
            'lifecycleenv'  => $::subscription_manager::lifecycleenv, }
    } else {
      $_settings = {}
    }
  }

  # this part can be used with a pulp server used to 'init' new servers
  #  if $::subscription_manager::config_hash['rhsm_baseurl'] == undef {
  #    $_conf_params['/etc/rhsm/rhsm.conf']['rhsm_baseurl'] =
  #      "https://${::subscription_manager::server_hostname}/pulp/repos"
  #  }
    rhsm_config { '/etc/rhsm/rhsm.conf':
      ensure => present,
      *      => $::subscription_manager::config_hash
    }

  # Four cases
  # I.  never registered
  # II. registered to correct server but forcing it
  # III. registered to different server
  # IV. registered to same server but forcing it
  if ($::facts['rhsm_identity'] == '' or $::facts['rhsm_identity'] == undef or
      $::facts['rhsm_ca_name'] != $::subscription_manager::server_hostname or
      $::subscription_manager::force == true ) {
      rhsm_register { $::subscription_manager::server_hostname:
        ensure  => present,
        require => Rhsm_config['/etc/rhsm/rhsm.conf'],
        *       =>  $_settings
      }
  }

}
