#!/usr/bin/ruby
#
# Provider for the rhsm_pool Puppet native ruby type based
# on the subscription_manager tool.
#
#   Copyright 2014-2016 Gaël Chamoulaud, James Laska,
#
#   See LICENSE for licensing.
#
require 'puppet'
require 'date'

Puppet::Type.type(:rhsm_pool).provide(:subscription_manager) do
  @doc = <<-EOS
    Manage attachment of a server to specific Entitlement Pools.
  EOS

  confine :osfamily => :redhat
  confine :feature => :json

  commands :subscription_manager => "subscription-manager"

mk_resource_methods

  # Attach to a pool based on the ID
  #  This will enable the consumption of repositories licensed
  #  through this pool.
  def create
    subscription_manager('attach','--pool',@resource[:id])
  end

  # Detach from a pool
  #  Given the serial number of our registration, remove the license
  def destroy
    subscription_manager('remove','--serial',@resource[:serial])
  end

  #  List the pools
  #    Given a valid registration exists, show all licensed pools
  def self.consumed_pools
    Puppet::debug("called subscription_manager with list --consumed")
    subscriptions = []
    subscription = {}
    keys =
    'Subscription Name|Provides|SKU|Contract|Account|Serial|Pool ID|Active' +
    '|Quantity Used|Service Level|Service Type|Status Details' +
    '|Subscription Type|Starts|Ends|System Type'
    subscription_manager('list','--consumed').each_line { |line|
      if line =~ /^\s*Subscription Name:\s*([^:]+)$/
        # this is the first item output
         subscription = {}
         subscription.store(:subscription_name, $1.strip)
         next
      end
      if line =~ /^\s*(Starts|Ends):\s*([0-9\/]+)$/
        key = $1.downcase.to_sym
        date = Date.strptime($2, "%m/%d/%Y") # TODO: test if sm uses Locale
        # I hate date math, don't you?
        if date.year < 100 # and (DateTime.now.year / 100 > 0)
          # Congratulations, you've stripped out the century.
          # Assume this is for _this_ century to fix it (or you have some
          # really, really nice support contracts and a horrible Locale.)
          centuries = ((Time.now.year / 100) * 100)
          date = Date.new(date.year + centuries, date.month, date.day)
        end
        subscription.store(key, date)
        next
      end
      if line =~ /^\s*(Quantity Used):\s*(\d+)$/
        value = $2.to_i
        key = $1.downcase.gsub(' ', '_').to_sym
        subscription.store(key, value)
        next
      end
      if line =~ /^\s*Pool ID:\s*([0-9a-fA-F]+)$/
        value = $1.strip
        subscription.store(:id, value)
        subscription.store(:name, value)
        next
      end
      if line =~ /^\s*Active:\s*(.+)$/
        value = $1.strip.match(/yes|true/i) ? true : false
        subscription.store(:active, value)
        next
      end
      if line =~ /^\s*System Type:\s*([^:]+)$/
        value = $1.strip.to_sym
        subscription.store(:system_type, value)
        # this is the last item output
        subscription.store(:provider, :subscription_manager)
        subscriptions << subscription
        next
      end
      if line =~ /^\s*(#{keys}):\s*([^:]+)$/
        value = $2.strip
        key = $1.downcase.gsub(' ', '_').to_sym
        subscription.store(key, value)
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
    pools = instances
    resources.keys.each do |name|
      if provider = pools.find{ |pool| pool.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

end
