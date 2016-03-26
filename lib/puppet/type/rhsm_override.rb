#!/usr/bin/ruby
#
#  Describe the yum repository over-ride cach for RedHat Subscription Manager.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'puppet/property/boolean'
require 'puppet/type'

Puppet::Type.newtype(:rhsm_override) do
  @doc = <<-EOD
  An on-disk cache over-ride of a channel.

  Example of a repository from an override of a content cache

  rhsm_repo { 'rhel-server6-epel':
    ensure        => present, # equal to the enabled property
    updated       => 2015-07-17T14:26:35.064+0000,
    created       => 2015-07-17T14:26:35.064+0000,
    content_label => 'rhel-server6-epel'
}

EOD

  ensurable  # provides for the enable property

  newparam(:content_label, :namevar => true) do
    desc "The rhsm channel override."
    validate do |value|
     fail("Updated should be a string.  Given #{value}") unless value.is_a? String
    end
  end


  newproperty(:updated) do
    desc "The last time this repostory was updated."
    validate do |value|
     fail("Updated should be a date.  Given #{value}") unless value.is_a? Date
    end
  end

  newproperty(:created) do
    desc "The time when this repostory was created."
    validate do |value|
     fail("Created should be a date.  Given #{value}") unless value.is_a? Date
    end
  end

end
