#!/usr/bin/ruby
# frozen_string_literal: true

#  Provide a mechanism to subscribe to a katello or Satellite 6
#  server.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'puppet'

Puppet::Type.type(:rhsm_repo).provide(:subscription_manager) do
  @doc = <<-EOS
    This provider registers a software repository via RedHat subscription manager.
  EOS

  confine osfamily: :redhat

  commands subscription_manager: 'subscription-manager'

  mk_resource_methods

  def create
    subscription_manager('repos', '--enable', @resource[:id])
    @resource[:ensure] = :present
  end

  def destroy
    subscription_manager('repos', '--disable', @resource[:id])
    @resource[:ensure] = :absent
  end

  def self.instances
    repos = read_repos
    if repos.nil? || repos == []
      []
    else
      repos.map do |repo|
        new(repo)
      end
    end
  end

  def self.prefetch(resources)
    repos = instances
    resources.keys.each do |name|
      resources[name].provider = repos.find { |repo| repo.name == name }
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  private

  # Convert a repository String configuration into a hash tables of settings
  # @return [hash] the settings of the repository
  # @api private
  def self.parse_repos(repo)
    new_repo = {}
    repo.split("\n").each do |line|
      m = %r{Repo ID:\s+(\S.*)}.match(line)
      unless m.nil?
        name = m[1].chomp
        new_repo[:id] = name
        new_repo[:name] = name
        new_repo[:provider] = :subscription_manager
        next
      end
      m = %r{Repo Name:\s+(\S.*)}.match(line)
      unless m.nil?
        new_repo[:repo_name] = m[1].chomp
        next
      end
      m = %r{Repo URL:\s+(\S.*)}.match(line)
      unless m.nil?
        new_repo[:url] = m[1].chomp
        next
      end
      m = %r{Enabled:\s+(\d)}.match(line)
      unless m.nil?
        value = Regexp.last_match[1].chomp.to_i
        new_repo[:ensure] = (value == 1) ? :present : :absent
      end
    end
    new_repo
  end

  # Get the list of repositories
  # @return [String] a list of repositories
  # @api private
  def self.read_repos
    repo_instances = []
    repos = subscription_manager('repos')
    unless repos.nil? || repos == "\n\n"
      repos.split("\n\n").each do |repo|
        repo_instances.push(parse_repos(repo))
      end
    end
    repo_instances
  end
end
