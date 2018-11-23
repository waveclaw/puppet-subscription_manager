#!/usr/bin/ruby
# frozen_string_literal: true

#
#  Report the name of the Katello Certificate Authority.
#  This will be the Candlepin instance for the server the agent registered to.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'English'
require 'openssl'

# Client Identity from the SSL certificate
module Facter::Util::RhsmCaName
  @doc = <<EOF
  Identity for this client.
EOF

  module_function

  def rhsm_ca_name(cafile)
    ca = nil
    if File.exist?(cafile)
      begin
        cert = OpenSSL::X509::Certificate.new(File.open(cafile, 'r').read)
        if cert.subject.to_s =~ %r{.+CN=(.+)}
          ca = Regexp.last_match(1).chomp
        end
      rescue StandardError => e
        Facter.debug("#{e.backtrace[0]}: #{$ERROR_INFO}.") unless $ERROR_INFO.nil?
      end
    end
    ca
  end
end

cafile = nil
if File.exist?('/etc/rhsm/ca/katello-default-ca.pem')
  # Katello or Satellite with custom CA cert
  cafile = '/etc/rhsm/ca/katello-default-ca.pem'
elsif File.exist?('/etc/rhsm/ca/katello-server-ca.pem')
  # Katello or Satellite
  cafile = '/etc/rhsm/ca/katello-server-ca.pem'
elsif File.exist?('/etc/rhsm/ca/candlepin-local.pem')
  # RedHat SAM
  cafile = '/etc/rhsm/ca/candlepin-local.pem'
end
unless cafile.nil?
  Facter.add(:rhsm_ca_name) do
    setcode { Facter::Util::RhsmCaName.rhsm_ca_name(cafile) }
  end
end
