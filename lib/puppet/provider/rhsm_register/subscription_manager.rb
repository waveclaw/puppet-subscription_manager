#!/usr/bin/ruby
# frozen_string_literal: true

#
#  Provide a mechanism to subscribe to a katello or Satellite 6
#  server.
#
#   Copyright 2014-2015 Gaël Chamoulaud, James Laska
#
#   See LICENSE for licensing.
#
require 'puppet'
require 'facter'

Puppet::Type.type(:rhsm_register).provide(:subscription_manager) do
  @doc = <<-EOS
    This provider registers a machine with cert-based RedHat Subscription
    Manager.  If a machine is already registered it does nothing unless the
    force parameter is set to true.
  EOS

  confine osfamily: :redhat

  commands subscription_manager: 'subscription-manager'

  # Attach to a service level in Satellite.
  #  To receive package update and access repositories, a host needs to be
  #  subscribed to a product once registered.  This requires redhat products
  #  or subscriptions in the system.  If there are only custom ones, e.g. on a
  #  katello server there is no ability to define or use service levels.
  def subscription_attach
    if @resource[:autosubscribe]
      Puppet.debug('This server will be attached to a service level')
      begin
        params = []
        params << 'attach'
        unless @resource[:servicelevel].nil? || @resource[:servicelevel].empty?
          params << "--servicelevel=#{@resource[:servicelevel]}"
        end
        params << '--auto'
        subscription_manager(params)
      rescue Puppet::ExecutionFailure => e
        Puppet.debug("Auto-attach returned: #{e}")
      end
    else
      Puppet.debug('Skipping service level attachment')
    end
  end

  # Attempt to (re-)register with a Katello or RHN Satellite 6 system.
  # This builds the command using a helper method and attempts to
  # deal with expected non-zero return codes from subscription-manager.
  def register
    Puppet.debug('This server will be registered')
    # Command will fail with various return codes on re-registration
    # RETCODE 1 for new registrations to new servers with an old registration
    # RETCODE 2 for re-registrations to the same server after unregister
    begin
      subscription_manager(build_register_parameters)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Registration returned: #{e}")
    end
  end

  # Completely remove the registration locally and attempt to notify the server.
  def unregister
    Puppet.debug('This server will be unregistered')
    unsub = [self.class.command(:subscription_manager), ['unsubscribe', '--all']]
    unreg = [self.class.command(:subscription_manager), ['unregister']]
    clean = [self.class.command(:subscription_manager), ['clean']]
    execute(unsub, failonfail: false, combine: true)
    execute(unreg, failonfail: false, combine: true)
    execute(clean, failonfail: false, combine: true)
  end

  # trigger actions related to registration on update of the properties
  def flush
    if exists?
      if identity.nil? || identity == :absent
        # no valid registration
      elsif @property_hash[:name] && @property_hash[:name] != (@resource[:name])
        # changing servers
        unregister
      elsif (@property_hash[:force].nil? || @property_hash[:force] == :absent ||
            @property_hash[:force] == false) &&
            (@resource[:force].nil? || @resource[:force] == :absent ||
             @resource[:force] == false)
        # trying to re-register but need --force!
        raise('Require force => true to register already registered server')
      end
      register
      subscription_attach
    else
      # should unregister
      unregister
    end
  end

  def create
    @property_hash[:ensure] = :present
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def self.instances
    registration = registration_settings
    # test for == :absent is to handle a specific Ruby issue for Puppet 4
    # NOT to test if the :ensure field is :absent
    if registration.nil? || registration == :absent || registration == ({})
      []
    else
      [new(registration)]
    end
  end

  def self.prefetch(resources)
    resources.keys.each do |name|
      provider = instances.find { |instance| instance.name == name }
      if provider
        resources[name].provider = provider
      end
    end
  end

  mk_resource_methods

  # Get the on disk config
  # @return [hash] the settings of the configuration and the identity
  # @api private
  def self.registration_settings
    Puppet.debug('Getting the registration settings as known to the system')
    registration = {}
    config = config_hostname
    if config
      registration[:name] = config
    elsif certified?
      registration[:name] = ca_name
    end
    id = identity
    if id
      # propertly registered
      registration[:identity] = id
      registration[:ensure] = :present
    elsif !(registration[:name].nil? || registration == :absent)
      # registration went bad
      registration[:ensure] = :absent
    end
    registration
  end

  # Test that only one of two things and set and not both and not neighter
  # @return [bool] if these are different and not unset
  # @param [string] item 1
  # @param [string] item 2
  # @api private
  def bothset(a, b)
    !(a.nil? || a == :absent || a == '') && !(b.nil? || b == :absent || b == '')
  end

  # Build a registration option string
  # @return [Array(String)] the options for a registration command
  # @api private
  def build_register_parameters
    params = []
    user = @resource[:username]
    key = @resource[:activationkey]
    release = @resource[:release]
    if (user.nil? && key.nil?) || (user == :absent && key == :absent) || (user == '' && key == '')
      raise("Need an activation key or a username and password. Was given user '#{user}' and key '#{key}'")
    end
    if bothset(user, key)
      raise("Only provide an activation key or username and password not both. Was given user '#{user}' and key '#{key}'")
    end
    if @resource[:org].nil? || @resource[:org] == :absent
      raise("The 'org' paramater is required to register the system")
    end
    params << 'register'
    params << '--force' if @resource[:force] && @resource[:force] != :absent
    if !user.nil? && !@resource[:password].nil? &&
       user != :absent && @resource[:password] != :absent &&
       user != '' && @resource[:password] != '' &&
       params << '--username' << user
      params << '--password' << @resource[:password]
      params << '--autosubscribe' if @resource[:autosubscribe]
    else
      params << '--activationkey' << key
      # no autosubscribe with keys, see attach step instead
    end
    if (!@resource[:lifecycleenv].nil? && !@resource[:lifecycleenv] == :absent) &&
       (@resource[:activationkey].nil? || @resource[:activationkey] == :absent)
      params << '--environment' << @resource[:lifecycleenv]
    end
    params << '--org' << @resource[:org]
    unless release.nil?
      params << '--release' << release
    end
    params
  end

  # Check for post-registration success certificates
  # @return [boolean] do we have certificates from a registration?
  # @api private
  def self.certified?
    if File.exist?('/etc/pki/consumer/cert.pem') ||
       File.exist?('/etc/pki/consumer/key.pem')
      true
    else
      false
    end
  end

  # What host are we configured to register to?
  # @return [String] the hostname of the Katello or Satellite service
  # or a nil if nothing
  # @api private
  def self.config_hostname
    host = nil
    config = subscription_manager(['config', '--list'])
    config.split("\n").each do |line|
      m = %r{\bhostname = \[?([a-z0-9.\-_]+)\]?}.match(line)
      unless m.nil?
        host = m[1].chomp
      end
    end
    host
  end

  # What host have we registered to?  (This is the candlepin certificate.)
  # @return [String] the real hostname of the Katello or Satellite service
  # or an nil if we failed to parse
  # @api private
  def self.ca_name
    Facter.value(:rhsm_ca_name)
    # Facter::Util::Rhsm_ca_name.ca_name
  end

  # What is our identity string? (Use the cached fact)
  # @return [String] the identity set by the Katello or Satellite service
  #  or an nil if we failed to parse
  # @api private
  def self.identity
    Facter.value(:rhsm_identity)
    # Facter::Util::Rhsm_identity.rhsm_identity
  end
end
