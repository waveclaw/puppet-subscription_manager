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

module Facter::Util::Rhsm_disabled_repos
  @doc=<<EOF
  Disabled RHSM repos for this client.
EOF
  class << self
    def rhsm_disabled_repos
      value = []
      begin
        reponame = ''
        output = Facter::Util::Resolution.exec(
          '/usr/sbin/subscription-manager repos')
        output.split("\n").each { |line|
          if line =~ /Repo ID:\s+(\S+)/
            reponame = $1.chomp
          elsif line =~ /.*Enabled:\s+0/
            if reponame != ''
              value.push(reponame)
              reponame = ''
            end
          end
        }
      rescue Exception => e
          Facter.debug("#{e.backtrace[0]}: #{$!}.")
      end
      value
    end
  end
end

Facter.add(:rhsm_disabled_repos) do
  confine do
    File.exist? '/usr/sbin/subscription-manager'
    Puppet.features.facter_cacheable?
  end
  setcode do
    # TODO: use another fact to set the TTL in userspace
    # right now this can be done by removing the cache files
    cache = Facter::Util::Facter_cacheable.cached?(:rhsm_disabled_repos, 24 * 3600)
    if ! cache
      repos = Facter::Util::Rhsm_disabled_repos.rhsm_disabled_repos
      Facter::Util::Facter_cacheable.cache(:rhsm_disabled_repos, repos)
      repos
    else
      if cache.is_a? Array
        cache
      else
        cache["rhsm_disabled_repos"]
      end
    end
  end
end
