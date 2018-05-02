#!/usr/bin/ruby
#
#  Report the name of the client ID.
#  This will be null if the reigstration is bad.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
begin
    require 'facter/util/facter_cacheable'
  rescue LoadError => e
    Facter.debug("#{e.backtrace[0]}: #{$!}.")
end

module Facter::Util::Rhsm_identity
  @doc=<<EOF
  Identity for this client.
EOF
  CACHE_TTL = 86400 unless defined? CACHE_TTL # 24 * 60 * 60 seconds
  CACHE_FILE = '/var/cache/rhsm/identity.yaml' unless defined? CACHE_FILE
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
  identities = Facter::Util::Rhsm_identity
  if Puppet.features.facter_cacheable?
    Facter.add(:rhsm_identity) do
      setcode do
        # TODO: use another fact to set the TTL in userspace
        # right now this can be done by removing the cache files
        cache = Facter::Util::Facter_cacheable.cached?(
          :rhsm_identity, identities::CACHE_TTL, identities::CACHE_FILE)
        if ! cache
          identity = identities.rhsm_identity
          Facter::Util::Facter_cacheable.cache(
            :rhsm_identity, identity, identities::CACHE_FILE)
          identity
        else
          if cache.is_a? Array
            cache
          else
            cache["rhsm_identity"]
          end
        end
      end
    end
  else
    Facter.add(:rhsm_identity) do
      setcode { identities.rhsm_identity }
    end
  end
end
