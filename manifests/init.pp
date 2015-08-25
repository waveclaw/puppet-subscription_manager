# == Class: subscription_manager
#
# Full description of class subscription_manager here.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
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
  $package_name = $::subscription_manager::defaults::package_name,
  $service_name = $::subscription_manager::defaults::service_name,
) inherits ::subscription_manager::defaults {

  # validate parameters here

  class { '::subscription_manager::install': } ->
  class { '::subscription_manager::config': } ~>
  class { '::subscription_manager::service': } ->
  Class['::subscription_manager']
}
