#!/usr/bin/ruby
#
# Control enablement of specific repositories.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'puppet/property/boolean'
require 'puppet/type'
require 'uri'


Puppet::Type.newtype(:rhsm_repo) do
  @doc = <<-EOD
  A software channel subscribed to by the server.

  Example of a repository from an override

Example of a repository from the Server

rhsm_repo { 'rhel-6-server-java-rpms':
  ensure        => present, # equal to the enabled property
  url           => 'https://katello.example.com/pulp/repos/abc-corp/production/reg-key-1/content/dist/rhel/server/6/6Server/$basearch/java-repo/os',
  content_label => 'rhel-6-java-rpms',
  id            => 'rhel-6-java-rpms',
  name          => 'RedHat Enterprise Linux 6 Server - Java (RPMs)',
  repo_type     => 'channel',
}

EOD

  ensurable  # provides for the enable property

  newparam(:id, :namevar => true) do
    desc "The rhsm channel subscribed to via the server."
    validate do |value|
     fail("ID should be a string.  Given #{value}") unless value.is_a? String
    end
  end

  newproperty(:repo_name, :namevar => false) do
    desc "The human readable name of the repository."
    validate do |value|
     fail("Updated should be a string.  Given #{value}") unless value.is_a? String
    end
  end

  newproperty(:url) do
    desc "The yum repo url."
    validate do |value|
      fail("Must be a valid url") unless !!URI.parse(value)
    end
  end

  newparam(:repo_type) do 
    desc "What kind of repostiory is this"
    validate do |value|
     fail("Updated should be a string.  Given #{value}") unless value.is_a? String
    end
  end

  newparam(:content_label) do
    desc "Label, usually identital to ID"
    validate do |value|
     fail("Updated should be a string.  Given #{value}") unless value.is_a? String
    end
  end

end
