#!/usr/bin/ruby

module Facter::Util::Rhsm_identity
  @doc=<<EOF
  Identity for this client.
EOF
  class << self
    def rhsm_identity
      value = nil
      begin
        #awk = Facter::Util::Resolution.exec('/usr/bin/which awk')
        sm = Facter::Util::Resolution.exec('/usr/bin/which subscription-manager')
        output = Facter::Util::Resolution.exec("#{sm} identity")
        output.split("\n").each { |line|
          if line =~ /.* identity(?: is)?: (\h{8}\-\h{4}\-\h{4}\-\h{4}\-\h{12}).*/
            value = $1
          end
        }
      rescue Exception => e
          Facter.debug("#{e.backtrace[0]}: #{$!}.")
      end
      value
    end
  end
end

Facter.add(:rhsm_identity) do
    confine :kernel => "Linux"
      setcode { Facter::Util::Rhsm_identity.rhsm_identity }
end
