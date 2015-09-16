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
require 'openssl'
require 'puppet/type/rhsm_register'
require 'facter/rhsm_identity'

Puppet::Type.type(:rhsm_register).provide(:subscription_manager) do
  @doc = <<-EOS
    This provider registers a machine with cert-based RedHat Subscription
    Manager.  If a machine is already registered it does nothing unless the
    force parameter is set to true.
  EOS

  confine :osfamily => :redhat

  commands :subscription_manager => "subscription-manager"

public

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
        Puppet.debug("Auto-attach did not succeed: #{e}")
      end
    end
  end

  # Attempt to (re-)register with a Katello or RHN Satellite 6 system.
  def register
    if self.identity == nil or  @resource[:force] == true
      Puppet.debug("This server will be registered")
      # Command will fail with various return codes on re-registration
      # RETCODE 1 for new registrations to new servers with an old registration
      # RETCODE 2 for re-registrations to the same server after unregister
      cmd = [self.class.command(:subscription_manager),
        build_register_parameters.join(' ')]
      execute(cmd, { :failonfail => false, :combine => true})
    else
      self.fail("Require force => true to register already registered server")
    end
  end

  # Completely remove the registration locally and attempt to notify the server.
  def unregister
    Puppet.debug("This server will be unregistered")
    subscription_manager(['unsubscribe','--all'])
    subscription_manager(['unregister'])
    subscription_manager(['clean'])
  end

  def flush
    if exists?
      register
      subscription_attach
    else
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

  # Override the name to pull from server_hostname
  # @return [String] the service hostname from server_hostname
  # @see #hostname?
  # @api public
  def name?
    hostname?
  end

  # Override the server_hostname field to pull from the on-disk certificates
  # @return [String] the service hostname to which the server is registered
  # @see #name?
  # @api public
  def hostname?
    name = self.ca_hostname
    if name
      name
    else
      @resource[:hostname]
    end
  end

  def self.instances
    [ new(get_registration) ]
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def name=(value)
    @resource[:name] = value
    @resource[:hostname] = value
  end

  mk_resource_methods

  private

  # Get the on disk config
  # @return [hash] the settings of the configuration and the identity
  # @api private
  def self.get_registration
    reg = {}
    if certified?
      reg[:hostname] = config_hostname
      if ! identity.nil?
        reg[:ensure] = :present
      else
        reg[:ensure] = :absent
      end
    end
    reg
  end

  # Build a registration option string
  # @return [Array(String)] the options for a registration command
  # @api private
  def build_register_parameters
    params = []
    if (@resource[:username].nil? and @resource[:activationkey].nil?) or (!@resource[:username].nil? and !@resource[:activationkey].nil?)
        self.fail("Either an activation key or username+password is required to register")
    end
    if @resource[:org].nil?
        self.fail("The 'org' paramater is required to register the system")
    end
    params << "register"
    params << "--force" if @resource[:force]
    if !@resource[:username].nil? and !@resource[:username].nil?
      params << "--username" << @resource[:username]
      params << "--password" << @resource[:password]
      params << "--autosubscribe" if @resource[:autosubscribe]
    else
      params << "--activationkey" <<  @resource[:activationkey]
      # no autosubscribe with keys, see attach step instead
    end
    params << "--environment" << @resource[:environment] unless @resource[:environment].nil?
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
    config = subscrption_manager(['config','--list'])
    config.split("\n").each { |line|
      if line =~ /hostname = ([a-z0-9.\-_]+)/
        host = $1.chomp
      end
    }
    if host.nil?
      # fall back to the CA subject name
      host = ca_hostname
    end
    host
  end

  # What host have we registered to?  (This is the candlepin certificate.)
  # @return [String] the real hostname of the Katello or Satellite service
  # or an nil if we failed to parse
  # @api private
  def self.ca_hostname
    cafile = '/etc/rhsm/ca/katello-server-ca.pem'
    ca = nil
    if File.exists?(cafile)
      begin
        cert = OpenSSL::X509::Certificate.new(File.open(cafile).read)
        if cert.subject.to_s =~ /.+CN=(.+)/
          ca = $1
        end
      rescue Exception => e
        Puppet.debug("Unable to guess server name with available certs: #{e}")
        ca
      end
    end
    ca
  end

  # What is our identity string? (Don't use the cached fact!)
  # @return [String] the identity set by the Katello or Satellite service
  #  or an nil if we failed to parse
  # @api private
  def self.identity
    Facter::Util::Rhsm_identity.rhsm_identity
  end

end
