require 'puppet'
require 'puppet/type/rhsm_repo'
require 'json'

Puppet::Type.type(:rhsm_repo).provide(:subscription_manager) do
  @doc = <<-EOS
    This provider registers a software repository via RedHat subscription manager.
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

  def self.parse_repo(repo)
    new_repo = {}
    ensured = :absent
    if repo.has_key?('value') and repo['value'] == 1
      ensured = :present
    end
    new_repo = {:ensure => ensured }
    if repo.include? 'contentLabel' and repo['contentLabel'].nil? == false
      new_repo[:content_label] = repo['contentLabel']
      new_repo[:name] = repo['contentLabel']
    end
    new_repo[:updated] = Date.parse(repo['updated']) if
      repo.include? 'updated' and repo['updated'].nil? == false
    new_repo[:created] = Date.parse(repo['created']) if
      repo.include? 'created' and repo['created'].nil? == false
    new_repo[:provider] = :subscription_manager
    new_repo
  end

  def self.read_cache
    repo_file = '/var/lib/rhsm/cache/content_overrides.json'
    repo_instances = []
    if File.exists?(repo_file)
      repos = JSON.parse(File.open(repo_file).read)
      repos.each { |repo|
        repo_instances.push(parse_repo(repo))
      }
    end
    repo_instances
  end

  def self.instances
    read_cache.collect do |repo|
      new(repo)
    end
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

end
