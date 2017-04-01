#!/usr/bin/ruby
#
#  Report the name of the client ID.
#  This will be null if the reigstration is bad.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#

module Facter::Util::Rhsm_identity
  @doc=<<EOF
  Identity for this client.
EOF
  extend self
  def rhsm_identity
    value = nil
    begin
      output = Facter::Util::Resolution.exec(
        '/usr/sbin/subscription-manager identity')
      output.split("\n").each { |line|
        if line =~ /.* identity(?: is)?: (\S{8}\-\S{4}\-\S{4}\-\S{4}\-\S{12}).*/
          value = $1
        end
      }
    rescue Exception => e
        Facter.debug("#{e.backtrace[0]}: #{$!}.") unless $! =~ /This system is not yet registered/
    end
    value
  end
end

if File.exist? '/usr/sbin/subscription-manager'
  Facter.add(:rhsm_identity) do
      setcode { Facter::Util::Rhsm_identity.rhsm_identity }
  end
end
