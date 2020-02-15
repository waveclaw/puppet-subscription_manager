#!/usr/bin/ruby
# frozen_string_literal: true

#
#  Report the repos available to this system
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

# Available RHSM repos for this client.
module Facter::Util::RhsmAvailableRepos
  @doc = <<EOF
  Available RHSM repos for this client.
EOF
  CACHE_TTL = 86_400 unless defined? CACHE_TTL # 24 * 60 * 60 seconds
  CACHE_FILE = '/var/cache/rhsm/available_repos.yaml' unless defined? CACHE_FILE

  module_function

  def rhsm_available_repos
    value = nil
    begin
      output = Facter::Core::Execution.execute(
        '/usr/sbin/subscription-manager repos',
        on_fail: :raise,
      )
      unless output.nil? || !output.is_a?(String)
        output.split("\n").each do |line|
          if line =~ %r{Repo ID:\s+(\S+)}
            value.push(Regexp.last_match(1).chomp)
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

# TODO: massive refactoring opportunity with facter_cacheable
if File.exist? '/usr/sbin/subscription-manager'
  repos = Facter::Util::RhsmAvailableRepos
  if Puppet.features.facter_cacheable?
    Facter.add(:rhsm_available_repos) do
      setcode do
        # TODO: use another fact to set the TTL in userspace
        # right now this can be done by removing the cache files
        cache = Facter::Util::FacterCacheable.cached?(
          :rhsm_available_repos, repos::CACHE_TTL, repos::CACHE_FILE
        )
        if !cache
          repo = repos.rhsm_available_repos
          Facter::Util::FacterCacheable.cache(
            :rhsm_available_repos, repo, repos::CACHE_FILE
          ) unless repo.nil?
          repo
        elsif cache.is_a? Array
          cache
        else
          cache['rhsm_available_repos']
        end
      end
    end
  else
    Facter.add(:rhsm_available_repos) do
      setcode { repos.rhsm_available_repos }
    end
  end
end
