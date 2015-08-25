# == Class subscription_manager::service
#
# This class is meant to be called from subscription_manager.
# It ensure the service is running.
#
class subscription_manager::service {

  service { $::subscription_manager::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
