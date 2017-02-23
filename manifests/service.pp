# Class: subscription_manager::service
# ====================================
#
# This class is meant to be called from subscription_manager.
# It ensure the service is running.
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
class subscription_manager::service {

  service { $::subscription_manager::service_name:
    ensure     => $::subscription_manager::service_status,
    hasstatus  => true,
    hasrestart => true,
  }

}
