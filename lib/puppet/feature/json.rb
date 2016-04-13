#!/usr/bin/ruby
#
# Include a json implementation in Puppet
#
# === Authors
#
# Gaël Chamoulaud <gchamoul@redhat.com>
#
# === Copyright
#
# Copyright 2015 Gaël Chamoulaud <gchamoul@redhat.com>
#
Puppet.features.add(:json, :libs => ["json"])
