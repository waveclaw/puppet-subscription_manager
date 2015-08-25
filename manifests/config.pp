# == Class subscription_manager::config
#
# This class is called from subscription_manager for service config.
#
class subscription_manager::config {
  unless $::subscription_manager::subscription_settings == {} {
    create_resources('rhsm_register',
      $::subscription_manager::subscription_settings)
  }
}
