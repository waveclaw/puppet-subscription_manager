#!/usr/bin/ruby
# frozen_string_literal: true

#
#  Report the name of the current environment.
#  This will be null if the reigstration is bad.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#

require 'English'

begin
  require 'facter/util/facter_cacheable'
rescue LoadError => e
  Facter.debug("#{e.backtrace[0]}: #{$ERROR_INFO}.")
end

# current environement
module Facter::Util::RhsmEnvironment
  @doc = <<EOF
  Current Lifecycle Environment for this client.
EOF
  CACHE_TTL = 86_400 unless defined? CACHE_TTL # 24 * 60 * 60 seconds
  CACHE_FILE = '/var/cache/rhsm/environment.yaml' unless defined? CACHE_FILE

  module_function

  def rhsm_identity
    value = nil
    begin
      output = Facter::Core::Execution.execute(
        '/usr/sbin/subscription-manager identity',
        on_fail: Facter::Core::Execution::ExecutionFailure,
      )
      unless output.nil?
        output.split("\n").each do |line|
          if line =~ %r{.* environment name(?: is)?: (.+)(?:/.*)?}
            value = Regexp.last_match(1)
          end
        end
      end
    rescue UncaughtThrowError, Facter::Core::Execution::ExecutionFailure => e
      if $ERROR_INFO !~ %r{This system is not yet registered}
        Facter.debug("#{e.backtrace[0]}: #{$ERROR_INFO}.")
      end
    end
    value
  end
end

if File.exist? '/usr/sbin/subscription-manager'
  environments = Facter::Util::RhsmEnvironment
  cache = nil
  if Puppet.features.facter_cacheable?
    cache = Facter::Util::FacterCacheable.cached?(
      :rhsm_environment, environments::CACHE_TTL, environments::CACHE_FILE
    )
  end
  Facter.add(:rhsm_identity) do
    setcode do
      if !cache
        environment = environments.rhsm_environment
        if !environment
          nil
        else
          Facter::Util::FacterCacheable.cache(
            :rhsm_environment, environment, environments::CACHE_FILE
          )
          environment
        end
      elsif cache.is_a? Array
        cache
      else
        cache['rhsm_environment']
      end
    end
  end
end
