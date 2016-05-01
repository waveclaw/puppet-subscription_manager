#!/usr/bin/ruby
#
#  Register or unreister a system to Katello or Satellite 6 servers using
#  the RedHat Subscription Manager.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'puppet/parameter/boolean'
require 'puppet/type'
require 'uri'

# Handle special cases for default values provided by subscription Manager
# @option [string] is - the current appearance of the property on system
# @option [string] should - the property from the puppet catalog
# @return [boolean] if the is matches the should
def check_sync(is, should)
  if is == :absent or is == :undef or is.nil? or is == '' or is == '[]' or is == []
    if should == :absent or should == :undef or should.nil? or should == '' or
      should == '[]' or should == []
        true
      else
        false
      end
    else
      if should == :absent or should == :undef or should.nil? or should == '' or
        should == '[]' or should == []
        false
      else
        is.downcase == should.downcase
      end
    end
end

Puppet::Type.newtype(:rhsm_register) do
  @doc = <<-EOD
 Register a system to a Satellite or Spacewalk server.

 Example:

  rhsm_register { 'rhn.redhat.com':
    server_insecure => false,
    username        => 'registered_user',
    password        => 'password123',
  }

EOD
  ensurable

  newparam(:name, :namevar => true) do
    desc "The rhsm server hostname."
    validate do |value|
      fail("Require a valid hostname. Received #{value} instead") unless value =~ /^[.a-zA-Z\-\_0-9]+$/
    end
    munge do |value|
      value.downcase unless value == :undef
    end
    def insync?(is)
      check_sync(is, should)
    end
  end

  newproperty(:identity) do
    desc "The identity from the sever"
  end

  # Note the warning from upstream The Forman project on bug #10208
  #  When Auto Attach is enabled, registering systems will be attached to all
  #  associated __custom products__ and __only__ associated RedHat subscriptions
  #  required to satisfy the system's installed products.
  newparam(:autosubscribe, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Automatically attach this system to compatible subscriptions."
    defaultto false
#    munge do |value|
#       @resource.munge_boolean(value)
#     end
  end

  newparam(:force, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Should the registration be forced. Use this option with caution,
          setting it true will cause the subscription-manager command to be run
          every time runs."
    defaultto false
#    munge do |value|
#       @resource.munge_boolean(value)
#     end
  end

  newparam(:username) do
    desc "The username to use when registering the system"
  end

  newparam(:password) do
    desc "The password to use when registering the system"
  end

  newparam(:activationkey) do
    desc "The activation key to use when registering the system (cannot be used with username and password)"
  end

  newparam(:pool) do
    desc "The license pool to attach to after registering the system"
  end

  newparam(:environment) do
    desc "The environment to subscribe to in the case of using katello."
  end

  newparam(:servicelevel) do
    desc "A service level for automatic attachement with Satellite servers."
  end

  newparam(:org) do
    desc "The organization the system should be assigned to."
    validate do |value|
      if value.empty?
        raise ArgumentError,
          "org paramater may not be empty"
      end
    end
  end

end
