#!/usr/bin/ruby
# frozen_string_literal: true

#
#  Report the repos disabled to this system
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

# Disabled Subscroption Pools for this client.
module Facter::Util::RhsmDisabledPools
  @doc = <<EOF
  Disabled Subscription Pools for this client.
EOF
  CACHE_TTL = 86_400 unless defined? CACHE_TTL # 24 * 60 * 60 seconds
  CACHE_FILE = '/var/cache/rhsm/disabled_pools.yaml' unless defined? CACHE_FILE

  module_function

  def get_output(input)
    lines = []
    tmp = nil
    input.split("\n").each do |line|
      if line =~ %r{Pool ID:\s*(.+)$}
        tmp = Regexp.last_match(1).chomp
        next
      end
      if line =~ %r{Active:.+False} && !tmp.nil?
        tmpcopy = tmp
        lines.push(tmpcopy) # pointer math ahoy
        next
      end
      if line.match?(%r{Active:.+True})
        tmp = nil
      end
    end
    lines
  end

  def rhsm_disabled_pools
    value = []
    begin
      consumed = Facter::Core::Execution.execute(
        '/usr/sbin/subscription-manager list --consumed',
        on_fail: :raise,
      )
      value = get_output(consumed)
    rescue UncaughtThrowError, Facter::Core::Execution::ExecutionFailure => e
      if $ERROR_INFO !~ %r{This system is not yet registered}
        Facter.debug("#{e.backtrace[0]}: #{$ERROR_INFO}.")
      end
    end
    value
  end
end

# TODO: massive refactoring opportunity with facter_cacheable
if File.exist? '/usr/sbin/subscription-manager'
  pools = Facter::Util::RhsmDisabledPools
  if Puppet.features.facter_cacheable?
    Facter.add(:rhsm_disabled_pools) do
      setcode do
        # TODO: use another fact to set the TTL in userspace
        # right now this can be done by removing the cache files
        cache = Facter::Util::FacterCacheable.cached?(
          :rhsm_disabled_pools, pools::CACHE_TTL, pools::CACHE_FILE
        )
        if !cache
          pool = pools.rhsm_disabled_pools
          Facter::Util::FacterCacheable.cache(
            :rhsm_disabled_pools, pool, pools::CACHE_FILE
          )
          pool
        elsif cache.is_a? Array
          cache
        else
          cache['rhsm_disabled_pools']
        end
      end
    end
  else
    Facter.add(:rhsm_disabled_pools) do
      setcode { pools.rhsm_disabled_pools }
    end
  end
end
