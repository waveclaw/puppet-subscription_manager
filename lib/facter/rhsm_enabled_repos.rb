#!/usr/bin/ruby
#
#  Report the repos enabled to this system
#  This will be empty if the registration is bad.
#
#   Copyright 2016 Pat Riehecky <riehecky@fnal.gov>
#
#   See LICENSE for licensing.
#

module Facter::Util::Rhsm_enabled_repos
  @doc=<<EOF
  Enabled RHSM repos for this client.
EOF
  class << self
    def rhsm_enabled_repos
      value = []
      begin
        reponame = ''
        output = Facter::Util::Resolution.exec(
          '/usr/sbin/subscription-manager repos')
        output.split("\n").each { |line|
          if line =~ /Repo ID:\s+(\S+)/
            reponame = $1.chomp
          elsif line =~ /.*Enabled:\s+1/
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

Facter.add(:rhsm_enabled_repos) do
  confine do
    File.exist? '/usr/sbin/subscription-manager'
  end
  setcode { Facter::Util::Rhsm_enabled_repos.rhsm_enabled_repos }
end
