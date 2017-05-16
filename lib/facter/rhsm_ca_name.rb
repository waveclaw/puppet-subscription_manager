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
  extend self
  def rhsm_ca_name(cafile)
    ca = nil
    if File.exists?(cafile)
      begin
        cert = OpenSSL::X509::Certificate.new(File.open(cafile).read)
        if cert.subject.to_s =~ /.+CN=(.+)/
          ca = $1.chomp
        end
      rescue Exception => e
        Facter.debug("#{e.backtrace[0]}: #{$!}.") unless $! =~ /This system is not yet registered/
      end
      ca
    end
  end
end

cafile = nil
if File.exists?('/etc/rhsm/ca/katello-default-ca.pem')
  # Katello or Satellite with custom CA cert
  cafile = '/etc/rhsm/ca/katello-default-ca.pem'
elsif File.exists?('/etc/rhsm/ca/katello-server-ca.pem')
  # Katello or Satellite
  cafile = '/etc/rhsm/ca/katello-server-ca.pem'
elsif File.exists?('/etc/rhsm/ca/candlepin-local.pem')
  # RedHat SAM
  cafile = '/etc/rhsm/ca/candlepin-local.pem'
end
if !(cafile.nil?)
    Facter.add(:rhsm_ca_name) do
      setcode { Facter::Util::Rhsm_ca_name.rhsm_ca_name(cafile) }
    end
end
