#!/usr/bin/ruby
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

  confine :osfamily => :redhat

  commands :subscription_manager => "subscription-manager"

  # Attach to a service level in Satellite.
  #  To receive package update and access repositories, a host needs to be
  #  subscribed to a product once registered.  This requires redhat products
  #  or subscriptions in the system.  If there are only custom ones, e.g. on a
  #  katello server there is no ability to define or use service levels.
  def subscription_attach
    if @resource[:autosubscribe] and ! @resource[:servicelevel].nil?
      Puppet.debug("This server will be attached to a service level")
      begin
        subscription_manager(['attach',
          "--servicelevel=#{@resource[:servicelevel]}", '--auto'])
      rescue Puppet::ExecutionFailure => e
        Puppet.debug("Auto-attach returned: #{e}")
      end
    end
  end

  # Attempt to (re-)register with a Katello or RHN Satellite 6 system.
  # This builds the command using a helper method and attempts to
  # deal with expected non-zero return codes from subscription-manager.
  def register
      Puppet.debug("This server will be registered")
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
    Puppet.debug("This server will be unregistered")
    unsub = [self.class.command(:subscription_manager),['unsubscribe','--all']]
    unreg = [self.class.command(:subscription_manager),['unregister']]
    clean = [self.class.command(:subscription_manager),['clean']]
    execute(unsub, { :failonfail => false, :combine => true})
    execute(unreg, { :failonfail => false, :combine => true})
    execute(clean, { :failonfail => false, :combine => true})
  end

  # trigger actions related to registration on update of the properties
  def flush
    if exists?
      if self.identity.nil? or self.identity == :absent
      # no valid registration
        register
        subscription_attach
      elsif @property_hash[:name] and @property_hash[:name] != @resource[:name]
        # changing servers
        unregister
        register
        subscription_attach
      else
        # trying to re-register
        if (@property_hash[:force].nil? or @property_hash[:force] == :absent or
            @property_hash[:force] == false) and
           (@resource[:force].nil? or @resource[:force] == :absent or
            @resource[:force] == false)
              self.fail("Require force => true to register already registered server")
        end
        register
        subscription_attach
      end
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
    registration = get_registration
    # test for == :absent is to handle a specific Ruby issue for Puppet 4
    # NOT to test if the :ensure field is :absent
    if registration.nil? or registration == :absent or registration == {}
      [  ]
    else
      [ new(registration) ]
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
  def self.get_registration
    Puppet.debug("Getting the registration settings as known to the system")
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
    elsif ! (registration[:name].nil? or registration == :absent)
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
    !(a.nil? or a == :absent or a == '') and !(b.nil? or b == :absent or b == '')
  end

  # Build a registration option string
  # @return [Array(String)] the options for a registration command
  # @api private
  def build_register_parameters
    params = []
    user = @resource[:username]
    key = @resource[:activationkey]
    if (user.nil? and key.nil?) or (user == :absent and key == :absent) or (user == '' and key == '')
         self.fail("Need an activation key or a username and password. Was given user '#{user}' and key '#{key}'")
     end
     if bothset(user, key)
       self.fail("Only provide an activation key or username and password not both. Was given user '#{user}' and key '#{key}'")
     end
    if (@resource[:org].nil? or @resource[:org] == :absent)
        self.fail("The 'org' paramater is required to register the system")
    end
    params << "register"
    params << "--force" if @resource[:force] and @resource[:force] != :absent
    if !user.nil? and !@resource[:password].nil? and
      user != :absent and @resource[:password] != :absent and
      user != '' and @resource[:password] != '' and
      params << "--username" << user
      params << "--password" << @resource[:password]
      params << "--autosubscribe" if @resource[:autosubscribe]
    else
      params << "--activationkey" <<  key
      # no autosubscribe with keys, see attach step instead
    end
    if ((!@resource[:lifecycleenv].nil? and !@resource[:lifecycleenv] == :absent) and
      (@resource[:activationkey].nil? or @resource[:activationkey] == :absent))
     params << "--environment" << @resource[:lifecycleenv]
    end
    params << "--org" << @resource[:org]
    return params
  end

  # Check for post-registration success certificates
  # @return [boolean] do we have certificates from a registration?
  # @api private
  def self.certified?
    if File.exists?('/etc/pki/consumer/cert.pem') or
      File.exists?('/etc/pki/consumer/key.pem')
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
    config = subscription_manager(['config','--list'])
    config.split("\n").each { |line|
      if line =~ /\bhostname = \[?([a-z0-9.\-_]+)\]?/
        host = $1.chomp
      end
    }
    host
  end

  # What host have we registered to?  (This is the candlepin certificate.)
  # @return [String] the real hostname of the Katello or Satellite service
  # or an nil if we failed to parse
  # @api private
  def self.ca_name
    Facter.value(:rhsm_ca_name)
    #Facter::Util::Rhsm_ca_name.ca_name
  end

  # What is our identity string? (Use the cached fact)
  # @return [String] the identity set by the Katello or Satellite service
  #  or an nil if we failed to parse
  # @api private
  def self.identity
    Facter.value(:rhsm_identity)
    #Facter::Util::Rhsm_identity.rhsm_identity
  end

end
