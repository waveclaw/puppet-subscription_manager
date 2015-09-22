#!/usr/bin/ruby
#
#  Provide a mechanism to subscribe to a katello or Satellite 6
#  server.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'puppet'
require 'puppet/type/rhsm_repo'

Puppet::Type.type(:rhsm_repo).provide(:subscription_manager) do
  @doc = <<-EOS
    This provider registers a software repository via RedHat subscription manager.
  EOS

  confine :osfamily => :redhat

  commands :subscription_manager => "subscription-manager"

  mk_resource_methods

  def create
    subscription_manager('repos','--enable',@resource[:id])
    @resource[:ensure] = :present
  end

  def destroy
    subscription_manager('repos','--disable',@resource[:id])
    @resource[:ensure] = :absent
  end

  def self.instances
    channels = read_channels
    if channels.nil? or channels == []
      [ ]
    else
      channels.collect { |channel| new(channel) }
    end
  end

  def self.prefetch(resources)
    instances.each { |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    }
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  private

  def self.parse_channel_repo(repo)
    new_repo = {}
    repo.split("\n").each { |line|
      if line =~ /Repo ID:\s+(\S.*)/
        name = $1.chomp
        new_repo[:id] = name
        new_repo[:name] = name
        new_repo[:provider] = :subscription_manager
        next
      end
      if line =~ /Repo Name:\s+(\S.*)/
        new_repo[:repo_name] = $1.chomp
        next
      end
      if line =~ /Repo URL:\s+(\S.*)/
        new_repo[:url] = $1.chomp
        next
      end
      if line =~ /Enabled:\s+(\d)/
        value = $1.chomp.to_i
        new_repo[:ensure] = ( value == 1 ) ? :present : :absent
        next
      end
    }
    new_repo
  end

  def self.read_channels
    repo_instances = []
    repos = subscription_manager('repos')
    repos.split("\n\n").each { |repo|
      repo_instances.push(parse_channel_repo(repo))
    } unless repos.nil? or repos == "\n\n"
    repo_instances
  end

end
