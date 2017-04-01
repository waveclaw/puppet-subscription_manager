#!/usr/bin/ruby
#
#  Report the repos disabled to this system
#  This will be empty if the registration is bad.
#
#   Copyright 2016 Pat Riehecky <riehecky@fnal.gov>
#
#   See LICENSE for licensing.
#
begin
    require 'facter/util/facter_cacheable'
rescue LoadError => e
    Facter.debug("#{e.backtrace[0]}: #{$!}.")
end

module Facter::Util::Rhsm_disabled_pools
  @doc=<<EOF
  Disabled Subscription Pools for this client.
EOF
  CACHE_TTL = 86400 unless defined? CACHE_TTL # 24 * 60 * 60 seconds
  CACHE_FILE = '/var/cache/rhsm/disabled_pools.yaml' unless defined? CACHE_FILE
  extend self
  def get_output(input)
    lines = []
    tmp = nil
    input.split("\n").each { |line|
      if line =~ /Pool ID:\s*(.+)$/
        tmp = $1.chomp
        next
      end
      if line =~ /Active:.+False/ and !tmp.nil?
        tmpcopy = tmp
        lines.push(tmpcopy) # pointer math ahoy
        next
      end
      if line =~/Active:.+True/
        tmp = nil
      end
    }
    lines
  end
  def rhsm_disabled_pools
    value = []
    begin
      consumed = Facter::Util::Resolution.exec(
          '/usr/sbin/subscription-manager list --consumed')
      value = get_output(consumed)
    rescue Exception => e
        Facter.debug("#{e.backtrace[0]}: #{$!}.") unless $! =~ /This system is not yet registered/
    end
    value
  end
end

# TODO: massive refactoring opportunity with facter_cacheable
if File.exist? '/usr/sbin/subscription-manager'
  pools = Facter::Util::Rhsm_disabled_pools
  if Puppet.features.facter_cacheable?
    Facter.add(:rhsm_disabled_pools) do
      setcode do
        # TODO: use another fact to set the TTL in userspace
        # right now this can be done by removing the cache files
        cache = Facter::Util::Facter_cacheable.cached?(
          :rhsm_disabled_pools, pools::CACHE_TTL, pools::CACHE_FILE)
        if ! cache
          pool = pools.rhsm_disabled_pools
          Facter::Util::Facter_cacheable.cache(
            :rhsm_disabled_pools, pool, pools::CACHE_FILE)
          pool
        else
          if cache.is_a? Array
            cache
          else
            cache["rhsm_disabled_pools"]
          end
        end
      end
    end
  else
    Facter.add(:rhsm_disabled_pools) do
      setcode { pools.rhsm_disabled_pools }
    end
  end
end
