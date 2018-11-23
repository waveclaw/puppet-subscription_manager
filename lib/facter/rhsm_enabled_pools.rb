#!/usr/bin/ruby
# frozen_string_literal: true

#
#  Report the Active pools (F/OSS repos) available to this system
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

# Consumed available Subscription Pools for this client
module Facter::Util::RhsmEnabledPools
  @doc = <<EOF
  Consumed available Subscription Pools for this client.
EOF
  CACHE_TTL = 86_400 unless defined? CACHE_TTL # 24 * 60 * 60 seconds
  CACHE_FILE = '/var/cache/rhsm/enabled_pools.yaml' unless defined? CACHE_FILE

  module_function

  def get_output(input)
    lines = []
    tmp = nil
    input.split("\n").each do |line|
      if line =~ %r{Pool ID:\s*(.+)$}
        tmp = Regexp.last_match(1).chomp
        next
      end
      if line =~ %r{Active:.+True} && !tmp.nil?
        tmpcopy = tmp
        lines.push(tmpcopy) # pointer math ahoy
        next
      end
      if line.match?(%r{Active:.+False})
        tmp = ''
      end
    end
    lines
  end

  def rhsm_enabled_pools
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
  pools = Facter::Util::RhsmEnabledPools
  if Puppet.features.facter_cacheable?
    Facter.add(:rhsm_enabled_pools) do
      setcode do
        # TODO: use another fact to set the TTL in userspace
        # right now this can be done by removing the cache files
        cache = Facter::Util::Facter_cacheable.cached?(
          :rhsm_enabled_pools, pools::CACHE_TTL, pools::CACHE_FILE
        )
        if !cache
          pool = pools.rhsm_enabled_pools
          Facter::Util::Facter_cacheable.cache(
            :rhsm_enabled_pools, pool, pools::CACHE_FILE
          )
          pool
        elsif cache.is_a? Array
          cache
        else
          cache['rhsm_enabled_pools']
        end
      end
    end
  else
    Facter.add(:rhsm_enabled_pools) do
      setcode { pools.rhsm_enabled_pools }
    end
  end
end
