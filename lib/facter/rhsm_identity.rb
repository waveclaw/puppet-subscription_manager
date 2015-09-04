#!/usr/bin/ruby

module Facter::Util::Rhsm_identity
  @doc=<<EOF
  Identity for this client.
EOF
  class << self
    def identity
      identity = nil
      begin
        sm_identity =  Facter::Util::Resolution.exec("subscription_manager identity")
        sm_identity.split('\n').each { |line|
            if line =~ /.*Current identity is: (\h{8}(?>-\h{4}){3}-\h{12}).*/
              identity = $1
            end
        }
      rescue Exception => e
          Facter.debug("#{e.backtrace[0]}: #{$!}.")
      end
      identity
    end
  end
end

Facter.add("rhsm_identity") do
    confine :kernel => "Linux"
      setcode { Facter:Util::Rhsm_identity.identity }
end
