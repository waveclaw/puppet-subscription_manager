# == Class: subscription_manager
#
# Full description of class subscription_manager here.
#
# === Parameters
#
# [*package_names*]
#   Name of packages to install.
#
# [*service_name*]
#   Name of the services to run or disable.
#
# [*service_status*]
#   Status of the services.  Defaults to running.
#
# [*subscription_settings*]
#   Hash of configuration settings to apply (e.g. to register the system)
#
# === Examples
#
#  class { subscription_manager:
#
#  }
#
# === Authors
#
# Gaël Chamoulaud <gchamoul@redhat.com>
#
# === Copyright
#
# Copyright 2013 Gaël Chamoulaud <gchamoul@redhat.com>

class subscription_manager (
  $package_names = $::subscription_manager::defaults::package_names,
  $service_name = $::subscription_manager::defaults::service_name,
  $service_status = $::subscription_manager::defaults::service_status,
  $subscription_settings =
    $::subscription_manager::defaults::subscription_settings,
) inherits ::subscription_manager::defaults {

  # validate parameters here

  class { '::subscription_manager::install': } ->
  class { '::subscription_manager::config': } ~>
  class { '::subscription_manager::service': } ->
  Class['::subscription_manager']
}
