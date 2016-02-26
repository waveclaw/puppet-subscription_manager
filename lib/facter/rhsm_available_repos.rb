#!/usr/bin/ruby
#
#  Report the repos available to this system
#  This will be empty if the registration is bad.
#
#   Copyright 2016 Pat Riehecky <riehecky@fnal.gov>
#
#   See LICENSE for licensing.
#

module Facter::Util::Rhsm_available_repos
  @doc=<<EOF
  Available RHSM repos for this client.
EOF
  class << self
    def rhsm_available_repos
      value = []
      begin
        output = Facter::Util::Resolution.exec(
          '/usr/sbin/subscription-manager repos')
        output.split("\n").each { |line|
          if line =~ /.*Repo ID:\s(.*)/
            value.push($1)
          end
        }
      rescue Exception => e
          Facter.debug("#{e.backtrace[0]}: #{$!}.")
      end
      value
    end
  end
end

Facter.add(:rhsm_available_repos) do
  confine do
    File.exist?('/usr/sbin/subscription-manager')
  end
  setcode { Facter::Util::Rhsm_available_repos.rhsm_available_repos }
end
