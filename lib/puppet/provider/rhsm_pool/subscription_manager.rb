Puppet::Type.type(:rhsm_pool).provide(:subscription_manager) do
  @doc = <<-EOS
    Manage attachment of a server to specific Entitlement Pools.
  EOS

  confine :osfamily => :redhat
  confine :feature => :json

  commands :subscription_manager => "subscription-manager"

mk_resource_methods

  def create
    subscription_manager('attach','--pool',@resource[:id])
  end

  def destroy
    subscription_manager('remove','--serial',@resource[:serial])
  end

  def self.consumed_pools
    Puppet::debug(subscription_manager('list','--consumed').split("\n"))
    subscriptions = []
    subscription = {}
    subscription_manager('list','--consumed').each_line { |line|
      if line =~ /Subscription Name:\s+([^:]+)/
         subscription = {}
         subscription.store(:name, $1)
         next
      end
      if line =~ /(Starts|Ends):\s+([0-9\/]+)/
        key = $1.downcase.to_sym
        date = Date.parse($2)
        subscription.store(key, date)
        next
      end
      if line =~ /(SKU|Serial|Quantity Used):\s+(\d+)/
        key = $1.downcase.gsub(' ', '_').to_sym
        value = $2.to_i
        subscription.store(key, value)
        next
      end
      if line =~ /Pool ID:\s+(\h+)/
        base = 16
        value = $2.to_i(base)
        subscription.store(:id, value)
        next
      end
      if line =~ /System Type:\s+([^:]+)/
        value = $1.downcase.to_sym
        subscription.merge!(:system_type, value)
        subscriptions << subscription
        next
      end
      if line =~ /([^:]+):\s+([^:]+)/
        key = $1.downcase.gsub(' ', '_')
        subscription.store(key.to_sym, $2)
        next
      end
    }
    subscriptions
  end

  def self.instances
    consumed_pools.collect do |pool|
      pool.store(:ensure, :present)
      new(pool)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

end
