#!/usr/bin/ruby
#
#  Report the repos disabled to this system
#  This will be empty if the registration is bad.
#
#   Copyright 2016 Pat Riehecky <riehecky@fnal.gov>
#
#   See LICENSE for licensing.
#
if Puppet.features.facter_cacheable?
  require 'facter/util/facter_cacheable'
end

module Facter::Util::Rhsm_disabled_pools
  @doc=<<EOF
  Disabled Subscription Pools for this client.
EOF
  class << self
    def get_output(input)
      lines = []
      input.split("\n").each { |line|
        if line =~ /^\s*Pool ID:\s*(\h+)$/
          tmp = $1.chomp
          next
        end
        if line =~ /Active:\s+False/ and !tmp.nil?
          lines.push(tmp)
          next
        end
        if line =~/Active:\s+True/
          tmp = ''
        end
      }
      lines
    end
    def rhsm_disabled_pools
      value = []
      begin
        available = Facter::Util::Resolution.exec(
          '/usr/sbin/subscription-manager list --available')
        consumed = Facter::Util::Resolution.exec(
            '/usr/sbin/subscription-manager list --consumed')
        value = get_output(available) + get_output(consumed)
      rescue Exception => e
          Facter.debug("#{e.backtrace[0]}: #{$!}.")
      end
      value
    end
  end
end

Facter.add(:rhsm_disabled_pools) do
  confine do
    File.exist? '/usr/sbin/subscription-manager'
    Puppet.features.facter_cacheable?
  end
  setcode do
    # TODO: use another fact to set the TTL in userspace
    # right now this can be done by removing the cache files
    cache = Facter::Util::Facter_cacheable.cached?(:rhsm_disabled_pools, 24 * 3600)
    if ! cache
      repos = Facter::Util::rhsm_disabled_pools.rhsm_disabled_pools
      Facter::Util::Facter_cacheable.cache(:rhsm_disabled_pools, repos)
      repos
    else
      if cache.is_a? Array
        cache
      else
        cache["rhsm_disabled_pools"]
      end
    end
  end
end
