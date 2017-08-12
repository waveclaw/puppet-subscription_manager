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
    Puppet.debug("rhsm.flush: will sync to disk the configuration.")
    if exists?
      Puppet.debug("rhsm.flush: This server will be configured for rhsm.")
      config = :apply
    else
      Puppet.debug("rhsm.flush: The configuration will be completely set to default.")
      config = :remove
    end
    cmds = build_config_parameters(config)
    if (cmds[:remove]).nil?
      Puppet.debug("rhsm.flush: given nothing to remove.")
    else
      cmds[:remove].each { |parameter|
        subscription_manager(*['config', parameter])
      }
    end
    if (cmds[:apply]).nil?
      Puppet.debug("rhsm.flush: given nothing to configure.")
    else
      subscription_manager(*cmds[:apply])
    end
    @property_hash = self.class.get_configuration
  end

  def create
    # setup properties
    # see https://groups.google.com/forum/#!topic/puppet-users/G3z41gFi0Dk
       resource.class.text_options.each { |property|
         if value = resource.should(property)
           @property_hash[property] = value
         end
       }
       resource.class.binary_options.each { |property|
         if value = resource.should(property)
           @property_hash[property] = value
         end
       }
       @property_hash[:ensure] = :present
  end

  def destroy
    @property_hash[:ensure] = :absent
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
    Puppet.debug("Will parse the configuration")
    conf = {}
    data = subscription_manager(['config','--list'])
    #Puppet.debug("Recieved #{data.size} characters of configuration data.")
    unless data.nil?
      conf = ini_parse(data)
      unless (conf.nil? or conf == {})
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
            Puppet.debug("get_configuration failed to parse repo_ca_cert: #{e.to_s}")
        end
      end
    end
    conf
  end

  # return a digit or boolean based on option type
  # @return [bootlean|integer] the value
  # @param [String] the section
  # @param [String] the title
  # @param [digit] the data
  # @api private
  def self.parse_digit(section, title, digit)
    if Puppet::Type.type(:rhsm_config).binary_options.has_key? "#{section}_#{title}".to_sym
      value = (digit == '1') ? true : false
    else
      value = digit.to_i
    end
    value
  end

  # helper function for testing the defaults_to array
  # @return [array] the list of discovered default setting parameters
  # @api private
  def self.defaults_to?
    @defaults_to
  end

  # helper function for testing the defaults_to array
  # @return [array] the default list
  # @param [symbol] the default setting parameter to exclude
  # @api private
  def self.defaults_to=(value)
    @defaults_to = value
  end


  # Primitive init parser for the strange output of subscription-manager
  # @return [hash] the parsed configuration data
  # @param [String] the raw data
  # @api private
  def self.ini_parse(input)
    @defaults_to = []
    output = {}
    title = nil
    section = nil
    input.split("\n").each { |line|
      # secdions look like ' [abc] '
      if line =~/^\s*\[(.+)\]/
        section = $1
        next
      end
      # lines can be 'thing = [], thing = value or thing = [value]'
      # 'thing = [value]' is a default, they can either be skipped or noted later
      if line =~ /\s*([a-z_]+) = (.*)/
          title = $1
          raw_value = $2.chomp
          case raw_value
          when /\[\]/
            # if nil is used here then puppet considers parameters set to
            # '' to be in need of sync at all time
            value = ''
            @defaults_to.push "#{section}_#{title}".to_sym
          when /\[(\d+)\]/
            @defaults_to.push "#{section}_#{title}".to_sym
            value = parse_digit(section, title, $1)
          when /^(\d+)$/
            value = parse_digit(section, title, $1)
          when /\[(.+)\]/
            @defaults_to.push "#{section}_#{title}".to_sym
            value = $1
          when /(\S+)/
            value = $1
          else
            # same as above, avoid nil for undefined parameters
            value = ''
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
    # @return [Hash(Array(String))] the options for a config command
    #  split into :apply array of setter options and :remove array of removals
    # @api private
    def build_config_parameters(config)
      setparams = [ "config" ]
      removeparams = [ ]
      # only set non-empty non-equal values
      @property_hash.keys.each { |key|
        # skip meta parameters and default values
        unless [ :ensure, :title,  :tags, :name, :provider].include? key or
         (!@defaults_to.nil? and @defaults_to.include? key)
          section = key.to_s.sub('_','.')
          if config == :remove or
            (@property_hash[key] == '' and @property_hash[key] != @resource[key]) or
            (@property_hash[key] == nil and @property_hash[key] != @resource[key])
            removeparams << "--remove=#{section}"
          elsif config == :apply and (@property_hash[key] != '')
            setparams << "--#{section}"
          end
          if @resource.class.binary_options.has_key? key and @property_hash[key] != ''
            value = (@property_hash[key] == true ) ? 1 : 0
          else
            value = @property_hash[key]
          end
          unless config == :remove or @property_hash[key] == '' or value == '' or value.nil?
             setparams << value.to_s
          end
        end
      }
      setparams = nil if setparams == ['config']
      removeparams = nil if removeparams == []
      {:apply => setparams, :remove => removeparams}
    end

end
