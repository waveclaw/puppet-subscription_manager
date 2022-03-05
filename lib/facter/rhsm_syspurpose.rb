#!/usr/bin/ruby
# frozen_string_literal: true

#
#  Report the syspurpose
#  This will be empty if undefined
#
#   Copyright 2020 Pat Riehecky <riehecky@fnal.gov>
#
#   See LICENSE for licensing.
#
require 'English'
require 'json'

begin
  require 'facter/util/facter_cacheable'
rescue LoadError => e
  Facter.debug("#{e.backtrace[0]}: #{$ERROR_INFO}.")
end

# purpose of this server
module Facter::Util::RhsmSyspurpose
  @doc = <<EOF
  RHSM defined syspurpose
EOF
  CACHE_TTL = 86_400 unless defined? CACHE_TTL # 24 * 60 * 60 seconds
  CACHE_FILE = '/var/cache/rhsm/syspurpose.yaml' unless defined? CACHE_FILE

  module_function

  def rhsm_syspurpose
    value = {}
    output = Facter::Core::Execution.execute(
      '/usr/sbin/syspurpose show',
      on_fail: :raise,
    )
    unless output.nil? || !output.is_a?(String)
      value = JSON.parse(output)
    end
    value
  end
end

# TODO: massive refactoring opportunity with facter_cacheable
if File.exist? '/usr/sbin/syspurpose'
  repos = Facter::Util::RhsmSyspurpose
  if Puppet.features.facter_cacheable?
    Facter.add(:rhsm_syspurpose) do
      setcode do
        # TODO: use another fact to set the TTL in userspace
        # right now this can be done by removing the cache files
        cache = Facter::Util::FacterCacheable.cached?(
          :rhsm_syspurpose, repos::CACHE_TTL, repos::CACHE_FILE
        )
        if !cache
          repo = repos.rhsm_syspurpose
          Facter::Util::FacterCacheable.cache(
            :rhsm_syspurpose, repo, repos::CACHE_FILE
          )
          repo
        else
          cache['rhsm_syspurpose']
        end
      end
    end
  else
    Facter.add(:rhsm_syspurpose) do
      setcode { repos.rhsm_syspurpose }
    end
  end
end
