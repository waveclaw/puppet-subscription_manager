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
    This provider manages a configuration for a client with cert-based
    RedHat Subscription Manager subscription to a Katello or Satellite 6 server.
  EOS

  confine :osfamily => :redhat

  commands :subscription_manager => "subscription-manager"

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
    if cmd.nil?
      Puppet.debug("rhsm.flush given nothing to configure")
    else
      subscription_manager(*cmd)
    end
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


  def self.instances
    config = get_configuration
    if config.nil? or config == {}
      [ ]
    else
      [ new(config) ]
    end
  end

  def self.prefetch(resources)
    instances.each { |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    }
  end


  mk_resource_methods

  # Get the on disk config
  # @return [hash] the settings of the configuration and the identity
  # @api private
  def self.get_configuration
    #Puppet.debug("Will parse the configuration")
    conf = {}
    data = subscription_manager(['config','--list'])
    #Puppet.debug("Recieved #{data.size} characters of configuration data.")
    unless data.nil?
      conf = ini_parse(data)
      unless conf.nil? or conf == {}
        conf[:name] = '/etc/rhsm/rhsm.conf' #Puppet::Type.type(:rhsm_config).$default_filename
        conf[:provider] = :subscription_manager
        conf[:ensure] = :present
        # bypass the config --list command for this since it typically has a variable expansion
        begin
          value = nil
          config = File.open(conf[:name])
          config.each { |line|
              if line =~ /^repo_ca_cert = (.+)/
                value = $1.strip
              end
          }
          config.close()
          if value
            conf[:rhsm_repo_ca_cert] = value
          end
        rescue Exception => e
            Puppet.debug("get_configuration failed to bypass for repo_ca_cert: #{e.to_s}")
        end
      end
    end
    conf
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
      if line =~/^\s*\[(.+)\]/
        section = $1
        next
      end
      # lines can be 'thing = [], thing = value or thing = [value]'
      if line =~ /\s*([a-z_]+) = (.*)/
          title = $1
          raw_value = $2.chomp
          case raw_value
          when /\[\]/
            value = nil
          when /\[(\d+)\]/, /^(\d+)$/
            digit = $1
            if Puppet::Type.type(:rhsm_config).binary_options.has_key? "#{section}_#{title}".to_sym
              value = (digit == '1') ? true : false
            else
              value = digit.to_i
            end
          when /\[(.+)\]/, /(\S+)/
            value = $1
          else
            value = nil
          end
          #Puppet.debug("in section #{section} in title #{title} with value #{value}")
          unless value.nil? or section.nil? or title.nil?
            output["#{section}_#{title}".to_sym] = value
          end
        next
      end
    }
    #Puppet.debug("Parsed out #{output.size} lines of data")
    output
  end

    # Build a config option string
    # @return [Array(String)] the options for a config command
    # @api private
    def build_config_parameters(config)
      params = []
      params << "config"
      #FIXME: code duplication in this section
      if config == :remove
        @resource.class.regular_options.keys.each { |key|
          opt = @resource.class.regular_options[key]
          params << "--remove=#{opt}" unless @property_hash[key].nil? or key == :name
        }
        @resource.class.binary_options.keys.each { |key|
          opt = @resource.class.binary_options[key]
          params << "--remove=#{opt}" unless @property_hash[key].nil?
        }
      else
        @resource.class.regular_options.keys.each { |key|
          opt = @resource.class.regular_options[key]
          params << "--#{opt}" << @property_hash[key] unless @property_hash[key].nil?
        }
        @resource.class.binary_options.keys.each { |key|
          opt = @resource.class.binary_options[key]
          if @property_hash[key] == true
            value = 1
          else
            value = 0
          end
          params << ["--#{opt}", "#{value}"] unless @property_hash[key].nil?
        }
      end
      if params == ['config']
        nil
      else
        params
      end
    end

end
