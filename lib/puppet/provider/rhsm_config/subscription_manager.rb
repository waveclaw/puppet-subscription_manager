#!/usr/bin/ruby
#
#  Provide a mechanism to configure subscription to a katello or Satellite 6
#  server.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'puppet'
require 'puppet/type/rhsm_config'

Puppet::Type.type(:rhsm_config).provide(:subscription_manager) do
  @doc = <<-EOS
    This provider registers a machine with cert-based RedHat Subscription
    Manager.  If a machine is already registered it does nothing unless the
    force parameter is set to true.
  EOS

  confine :osfamily => :redhat

  commands :subscription_manager => "subscription-manager"

  $config = '/etc/rhsm/rhsm.conf'

  # (Re-)Write the configuration file for subscription-manager.
  #  This controls the target of registration and paths to features.
  def flush
    if exists?
      Puppet.debug("This server will be configured for rhsm")
      config = :apply
    else
      Puppet.debug("The configuration will be destroyed.")
      config = :remove
    end
    cmd = build_config_parameters(config)
    subscription_manager(*cmd)
  end

  def create
    @resource[:ensure] = :present
  end

  def destroy
    @resource[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  # Override the name to pull from server_hostname
  # @return [String] the service hostname from server_hostname
  # @see #server_hostname?
  # @api public
  def name?
    server_hostname?
  end

  def self.instances
    [ new(get_configuration) ]
  end

  def self.prefetch(resources)
    config = instances
    resources.keys.each { |name|
      if provider = config.find{ |conf| conf.name == name }
        resources[name].provider = provider
      end
    }
  end

  def server_hostname=(value)
    @resource[:name] = value
    @resource[:server_hostname] = value
  end

  def name=(value)
    @resource[:name] = value
    @resource[:server_hostname] = value
  end

  mk_resource_methods


  def self.config?
     File.exists?($config)
  end

  # Get the on disk config
  # @return [hash] the settings of the configuration and the identity
  # @api private
  def self.get_configuration
    reg = {}
    if config?
      data = subscription_manager(['config','--list'])
      reg = ini_parse(data)
      if reg != {}
        reg[:name] = reg[:server_hostname] if reg.respond_to? :server_hostname
        reg[:provider] = :subscription_manager
      end
    end
    reg
  end

  # Primitive init parser for the strange output of subscription-manager
  # @return [hash] the parsed configuration data
  # @param [String] the raw data
  # @api private
  def self.ini_parse(input)
    output = {}
    title = nil
    section = nil
    input.split("\n").each { |line|
      if line =~/^\s+\[(.+)\]/
        section = $1
        next
      end
      # lines can be 'thing = [], thing = value or thing = [value]'
      if line =~ /\s+([a-z_]+) = (.*)/
          title = $1
          raw_value = $2.chomp
          case raw_value
          when /\[\]/
            value = nil
          when /\[(?<val>\d+)\]|(?<val>\d+)/
            value = $~[:val].to_i
          when /\[(?<val>.+)\]|(?<val>.+)/
            value = $~[:val]
          else
            value = nil
          end
          output["#{section}_#{title}".to_sym] = value unless raw_value.nil? or section.nil? or title.nil?
        next
      end
    }
    output
  end

    # Build a config option string
    # @return [Array(String)] the options for a config command
    # @api private
    def build_config_parameters(config)
      params = []
      params << "config"
      #FIXME: the code duplication this sections in nausia incuding
      if config == :remove
        @resource.class.regular_options.keys.each { |key|
          opt = @resource.class.regular_options[key]
          params << "--remove=#{opt}" unless @resource[key].nil? or key == :server_hostname
        }
        @resource.class.binary_options.keys.each { |key|
          opt = @resource.class.binary_options[key]
          params << "--remove=#{opt}" unless @resource[key].nil?
        }
      else
        @resource.class.regular_options.keys.each { |key|
          opt = @resource.class.regular_options[key]
          params << "--#{opt}" << @resource[key] unless @resource[key].nil?
        }
        @resource.class.binary_options.keys.each { |key|
          opt = @resource.class.binary_options[key]
          if @resource[key] == true
            value = 1
          else
            value = 0
          end
          params << ["--#{opt}", "#{value}"] unless @resource[key].nil?
        }
      end
      return params
    end
end
