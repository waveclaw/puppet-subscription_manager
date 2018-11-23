#!/usr/bin/ruby
# frozen_string_literal: true

#
#  Report the pools (F/OSS repos) available to this system
#  This will be empty if the registration is bad.
#
#   Copyright 2016 Pat Riehecky <riehecky@fnal.gov>
#
#   See LICENSE for licensing.
#
require 'English'

begin
  require 'facter/util/facter_cacheable'
rescue LoadError => e
  Facter.debug("#{e.backtrace[0]}: #{$ERROR_INFO}.")
end

# Available Subscription Pools for this client.
module Facter::Util::RhsmAvailablePools
  @doc = <<EOF
  Available Subscription Pools for this client.
EOF
  CACHE_TTL = 86_400 unless defined? CACHE_TTL # 24 * 60 * 60 seconds
  CACHE_FILE = '/var/cache/rhsm/available_pools.yaml' unless defined? CACHE_FILE

  module_function

  def get_output(input)
    lines = []
    input.split("\n").each do |line|
      if line =~ %r{Pool ID:\s+(.+)$}
        lines.push(Regexp.last_match(1).chomp)
        next
      end
    end
    lines
  end

  def rhsm_available_pools
    value = []
    begin
      available = Facter::Core::Execution.execute(
        '/usr/sbin/subscription-manager list --available',
        on_fail: :raise,
      )
      value = get_output(available)
    rescue UncaughtThrowError, Facter::Core::Execution::ExecutionFailure => e
      if $ERROR_INFO !~ %r{This system is not yet registered}
        Facter.debug("#{e.backtrace[0]}: #{$ERROR_INFO}.")
      end
    end
    value
  end
end

if File.exist? '/usr/sbin/subscription-manager'
  pools = Facter::Util::RhsmAvailablePools
  if Puppet.features.facter_cacheable?
    Facter.add(:rhsm_available_pools) do
      setcode do
        # TODO: use another fact to set the TTL in userspace
        # right now this can be done by removing the cache files
        cache = Facter::Util::Facter_cacheable.cached?(
          :rhsm_available_pools,
          pools::CACHE_TTL,
          pools::CACHE_FILE,
        )
        if !cache
          pool = Facter::Util::RhsmAvailablePools.rhsm_available_pools
          Facter::Util::Facter_cacheable.cache(
            :rhsm_available_pools,
            pool,
            pools::CACHE_FILE,
          )
          pool
        elsif cache.is_a? Array
          cache
        else
          cache['rhsm_available_pools']
        end
      end
    end
  else
    Facter.add(:rhsm_available_pools) do
      setcode { pools.rhsm_available_pools }
    end
  end
end
