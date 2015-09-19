#!/usr/bin/ruby
#
#  Report the name of the Katello Certificate Authority.
#  This will be the Candlepin instance for the server the agent registered to.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'openssl'

module Facter::Util::Rhsm_ca_name
  @doc=<<EOF
  Identity for this client.
EOF
  class << self
    def rhsm_ca_name
      cafile = '/etc/rhsm/ca/katello-server-ca.pem'
      ca = nil
      if File.exists?(cafile)
        begin
          cert = OpenSSL::X509::Certificate.new(File.open(cafile).read)
          if cert.subject.to_s =~ /.+CN=(.+)/
            ca = $1
          end
        rescue Exception => e
          Facter.debug("#{e.backtrace[0]}: #{$!}.")
        end
        ca
      end
    end
  end
end

Facter.add(:rhsm_ca_name) do
    confine :kernel => "Linux"
      setcode { Facter::Util::Rhsm_ca_name.rhsm_ca_name }
end
