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
require 'json'

Puppet::Type.type(:rhsm_override).provide(:subscription_manager) do
  @doc = <<-EOS
    This provider maps content overrides found in the JSON format cache file.
  EOS

  confine :osfamily => :redhat
  confine :feature => :json

  commands :subscription_manager => "subscription-manager"

  mk_resource_methods

  def create
    subscription_manager('repos','--enable',@resource[:content_label])
    @resource[:ensure] = :present
  end

  def destroy
    subscription_manager('repos','--disable',@resource[:content_label])
    @resource[:ensure] = :absent
  end

  def self.instances
    read_cache.collect { |repo| new(repo) }
  end

  def self.prefetch(resources)
    repos = instances
    resources.keys.each do |name|
      if provider = repos.find{ |repo| repo.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  private


  def self.parse_cache_repo(repo)
    new_repo = {}
    ensured = :absent
    if repo.has_key?('value') and repo['value'] == 1
      ensured = :present
    end
    new_repo = {:ensure => ensured }
    if repo.include? 'contentLabel' and repo['contentLabel'].nil? == false
      new_repo[:content_label] = repo['contentLabel']
    end
    new_repo[:updated] = Date.parse(repo['updated']) if
      repo.include? 'updated' and repo['updated'].nil? == false
    new_repo[:created] = Date.parse(repo['created']) if
      repo.include? 'created' and repo['created'].nil? == false
    new_repo[:provider] = :subscription_manager
    new_repo
  end

  def self.get_cache
    repo_file = '/var/lib/rhsm/cache/content_overrides.json'
    if File.exists?(repo_file)
      File.open(repo_file).read
    else
      '[]'
    end
  end

  def self.read_cache
    repo_instances = []
      repos = JSON.parse(get_cache)
      repos.each { |repo|
        repo_instances.push(parse_cache_repo(repo))
      }
    repo_instances
  end

end
