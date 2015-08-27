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
  end

  def destroy
    subscription_manager('repos','--disable',@resource[:content_label])
  end

  def self.instances
    repo_file = '/var/lib/rhsm/cache/content_overrides.json'
    repo_instances = []
    if File.exists?(repo_file)
      repos = JSON.parse(File.open(repo_file).read)
      repos.each { |repo|
        ensured = :absent
        if repo.has_key?('value') and repo['value'] == 1
          ensured = :present
        end
        new_repo = {
          :ensure        => ensured,
          :updated       => Date.parse(repo['updated']),
          :created       => Date.parse(repo['created']),
          :content_label => repo['contentLabel']
        }
        repo_instances.push(new(new_repo))
      }
    end
    repo_instances
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
