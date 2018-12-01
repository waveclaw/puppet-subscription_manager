#!/usr/bin/ruby
# frozen_string_literal: true

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

  confine osfamily: :redhat

  commands subscription_manager: 'subscription-manager'

  # (Re-)Write the configuration file for subscription-manager.
  #  This controls the target of registration and paths to features.
  def flush
    Puppet.debug('rhsm.flush: will sync to disk the configuration.')
    if exists?
      Puppet.debug('rhsm.flush: This server will be configured for rhsm.')
      config = :apply
    else
      Puppet.debug('rhsm.flush: The configuration will be completely set to default.')
      config = :remove
    end
    cmds = build_config_parameters(config)
    if (cmds[:remove]).nil?
      Puppet.debug('rhsm.flush: given nothing to remove.')
    else
      cmds[:remove].each do |parameter|
        subscription_manager('config', parameter)
      end
    end
    if (cmds[:apply]).nil?
      Puppet.debug('rhsm.flush: given nothing to configure.')
    else
      apply = cmds[:apply]
      subscription_manager(['config', apply].flatten)
    end
    @property_hash = self.class.on_disk_configuration
  end

  def create
    # setup properties
    # see https://groups.google.com/forum/#!topic/puppet-users/G3z41gFi0Dk
    resource.class.text_options.each do |property|
      value = resource.should(property)
      unless value.nil?
        @property_hash[property] = value
      end
    end
    resource.class.binary_options.each do |property|
      value = resource.should(property)
      unless value.nil?
        @property_hash[property] = value
      end
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def self.instances
    config = on_disk_configuration
    if config.nil? || config == ({})
      []
    else
      [new(config)]
    end
  end

  def self.prefetch(resources)
    x = instances
    resources.keys.each do |name|
      provider = x.find { |i| i.name == name }
      resources[name].provider = provider unless provider.nil?
    end
  end

  mk_resource_methods

  # Get the on disk config
  # @return [hash] the settings of the configuration and the identity
  # @api private
  def self.on_disk_configuration
    # Puppet.debug('Will parse the configuration')
    conf = {}
    data = subscription_manager(['config', '--list'])
    conf = ini_parse(data) unless data.nil?
    unless conf.nil? || conf == ({}) || !conf.is_a?(Hash)
      conf[:name] = '/etc/rhsm/rhsm.conf' # Puppet::Type.type(:rhsm_config).$default_filename
      conf[:provider] = :subscription_manager
      conf[:ensure] = :present
      conf[:rhsm_repo_ca_cert] = repo_cert(conf[:name])
    end
    Puppet.debug("Config was #{conf}")
    conf
  end

  # Get the rhsm sections ca certificate
  # @return String the setting string for the CA
  # @param {String} the filename to pull the name out of
  # @api private
  def self.repo_cert(configname)
    # config --list command typically has a variable expansion for repo_ca_cert
    value = nil
    begin
      on_disk = File.open(configname)
      on_disk.readlines.each do |line|
        m = line.match(%r{[^#]*repo_ca_cert = (.+)})
        unless m.nil?
          value = m[1].strip
        end
      end
      on_disk.close
    rescue StandardError => e
      Puppet.debug("on_disk_configuration failed to parse repo_ca_cert: #{e}")
    end
    value
  end

  # return a digit or boolean based on option type
  # @return [bootlean|integer] the value
  # @param [String] the section
  # @param [String] the title
  # @param [digit] the data
  # @api private
  def self.parse_digit(section, title, digit)
    value = if Puppet::Type.type(:rhsm_config).binary_options.key? "#{section}_#{title}".to_sym
              (digit == '1') ? true : false
            else
              digit.to_i
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
  class << self
    attr_writer :defaults_to
  end

  # Primitive parser for the ini-like output of subscription-manager
  # @return [hash] the parsed configuration data
  # @param [String] the raw data
  # @api private
  def self.ini_parse(input)
    @defaults_to = []
    output = {}
    title = nil
    section = nil
    input.split("\n").each do |line|
      # secdions look like ' [abc] '
      m = line.match(%r{^\s*\[(.+)\]})
      unless m.nil?
        section = m[1]
        next
      end
      # lines can be 'thing = [], thing = value or thing = [value]'
      # 'thing = [value]' is a default, they can either be skipped or noted later
      m = line.match(%r{^\s*([a-z_]+) = (.*)})
      unless m.nil?
        title = m[1]
        raw_value = m[2]
        case raw_value
        when %r{\[\]}
          # if nil is used here then puppet considers parameters set to
          # '' to be in need of sync at all time
          value = ''
          @defaults_to.push "#{section}_#{title}".to_sym
        when %r{\[(\d+)\]}
          @defaults_to.push "#{section}_#{title}".to_sym
          value = parse_digit(section, title, Regexp.last_match(1))
        when %r{^(\d+)$}
          value = parse_digit(section, title, Regexp.last_match(1))
        when %r{\[(.+)\]}
          @defaults_to.push "#{section}_#{title}".to_sym
          value = Regexp.last_match(1)
        when %r{(^[a-zA-Z_. /]+$)}
          value = Regexp.last_match(1)
        when %r{(\S+)}
          value = Regexp.last_match(1)
        else
          # same as above, avoid nil for undefined parameters
          value = ''
        end
      end
      # Puppet.debug("in section #{section} in title #{title} with value #{value}")
      unless value.nil? || section.nil? || title.nil?
        output["#{section}_#{title}".to_sym] = value
      end
      next
    end unless input.nil? or input == ''
    # Puppet.debug("Parsed out #{output.size} lines of data")
    output
  end

  # Build a config option string
  # @param removal Symbol :remove if to remove things
  # @return [Hash(Array(String))] the options for a config command
  #  split into :apply array of setter options and :remove array of removals
  # @api private
  def build_config_parameters(removal)
   setparams = []
   removeparams = []
   options =  Puppet::Type.type(:rhsm_config).binary_options.merge(
     Puppet::Type.type(:rhsm_config).text_options)
   # filter out praramters from properties, excluding any defaults
   arguments = @property_hash.select do |opt, value|
     if @defaults_to.nil?
       options.keys.include?(opt)
     else
       options.keys.include?(opt) && !@defaults_to.include?(opt)
     end
   end
   Puppet.debug("Updates to subscription configuration are '#{arguments}'")
   arguments.each do |opt, value|
     section = options[opt]
     param = resolve_value(removal, opt, value)
     if param.nil?
       removeparams.push("--remove=#{section}")
     else
       setparams.push("--#{section}=#{param}")
     end
   end
   setparams = nil if setparams == []
   removeparams = nil if removeparams == []
   { apply: setparams, remove: removeparams }
 end

  # Convert a value to nil if to remove, 1 or 0 or "string" if to set
  # @param config symbol state of the resource
  # @param opt symbol the current value's associated parameter
  # @param value String the parameter's value
  # @return String the option for a config command
  # raises Puppet:Error if the opt is not a valid resource paramter!
  # @api private
  def resolve_value(removal, opt, value)
      if removal == :remove
        # don't care, we are removing the entire configuration
        nil
      elsif @property_hash[opt] != @resource[opt] #@resource.should(opt)
        # resource and properties do not match for this setting, so update it
        if @property_hash[opt].nil? or value == ''
          # remove it
          nil
        elsif Puppet::Type.type(:rhsm_config).binary_options.key?(opt)
          # set it to a binary value
          convert_to_binary(value)
        elsif Puppet::Type.type(:rhsm_config).text_options.key?(opt)
          # set it to a textual value
           ['"', value, '"'].join('')
        else
           # pass value through
           value
        end
      else
        # we are setting a non-default value to the existing value, pass it
        value
      end
  end

  # Return 1 for true, 0 for everything else
  # @param value String the value to evaluate per Ruby Boolean rules
  # @return Int if true then 1 else 0
  # @api private
  def convert_to_binary(value)
    if [ 'true', 'True', true, 1 ].include? value
      1
    else
      0
    end
  end

end
