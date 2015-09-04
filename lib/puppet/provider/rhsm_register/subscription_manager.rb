#!/usr/bin/ruby
require 'puppet'
require 'puppet/type/rhsm_register'
require 'openssl'
require 'facter/rhsm_identity'

Puppet::Type.type(:rhsm_register).provide(:subscription_manager) do
  @doc = <<-EOS
    This provider registers a machine with cert-based RedHat Subscription
    Manager.  If a machine is already registered it does nothing unless the
    force parameter is set to true.
  EOS

  confine :osfamily => :redhat

  commands :subscription_manager => "subscription-manager"

  def build_config_parameters
    params = []
    params << "config"
    params << "--server.hostname" << @resource[:server_hostname] if ! @resource[:server_hostname].nil?
    params << "--server.prefix" << @resource[:server_prefix] if ! @resource[:server_prefix].nil?
    params << ["--server.insecure", "1"] if @resource[:server_insecure]
    params << "--rhsm.repo_ca_cert" << @resource[:rhsm_cacert] if ! @resource[:rhsm_cacert].nil?
    params << "--rhsm.baseurl" <<  @resource[:rhsm_baseurl] if ! @resource[:rhsm_baseurl].nil?

    return params
  end

  def build_register_parameters
    params = []
    if @resource[:username].nil? and @resource[:activationkeys].nil?
        self.fail("Either an activation key or username/password is required to register")
    end

    if @resource[:org].nil?
        self.fail("The 'org' paramater is required to register the system")
    end

    params << "register"
    params << "--username" << @resource[:username] if ! @resource[:username].nil?
    params << "--password" << @resource[:password] if ! @resource[:password].nil?
    params << "--activationkey" <<  @resource[:activationkeys] if ! @resource[:activationkeys].nil?
    params << "--force" if @resource[:force]
    params << "--autosubscribe" if @resource[:autosubscribe] and @resource[:activationkeys].nil?
    params << "--environment" << @resource[:environment] if ! @resource[:environment].nil?
    params << "--org" << @resource[:org]

    return params
  end

  def identity
    Facter::Util::Rhsm_identity.rhsm_identity
  end

  def certified
    if File.exists?('/etc/pki/consumer/cert.pem') or
      File.exists?('/etc/pki/consumer/key.pem')
        true
    else
        false
    end
  end

  # this leads to the possiblity that is provider could use
  # self.instances since name is actually a propety-like pseudo-parameter
  def ca_certified
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

  def config
    Puppet.debug("This server will be configered for rhsm")
    cmd = build_config_parameters
    subscription_manager(*cmd)
  end

  def register
    Puppet.debug("This server will be registered")
    if identity == nil or @resource[:force] == true
      cmd = build_register_parameters
      subscription_manager(*cmd)
      if ! @resource[:autosubscribe].nil? and ! @resource[:servicelevel].nil?
        subscription_manager(['attach', '--servicelevel',
          @resource[:servicelevel], '--auto'])
      end
    else
      self.fail("Require force => true to register already registered server")
    end
  end

  def unregister
    Puppet.debug("This server will be unregistered")
    subscription_manager(['clean'])
    subscription_manager(['unsubscribe','--all'])
    subscription_manager(['unregister'])
  end

  def create
    config
    register
  end

  def destroy
    unregister
  end

  def exists?
    Puppet.debug("Verifying if the server is already registered")
    if certified and identity
      return true
    else
      return false
    end
  end

  # No self.instances?  Have to manually make all parameters
  def provider=(value)
    @resource[:provider]  = value
  end
  def provider?(value)
    @resource[:provider]  = value
  end
  def name=(value)
    @resource[:name] = value
    @resource[:server_hostname] = value
  end
  def name?
    server_hostname?
  end
  def server_hostname=(value)
    @resource[:server_hostname] = value
  end
  def server_hostname?
    name = ca_certified
    if name
      name
    else
      @resource[:server_hostname]
    end
  end
  def server_insecure=(value)
    @resource[:server_insecure] = value
  end
  def server_insecure?
    @resource[:server_insecure]
  end
  def username=(value)
    @resource[:username] = value
  end
  def username?
    @resource[:username]
  end
  def password=(value)
    @resource[:password] = value
  end
  def password?
    @resource[:password]
  end
  def server_prefix=(value)
    @resource[:server_prefix] = value
  end
  def server_prefix?
    @resource[:server_prefix]
  end
  def rhsm_baseurl=(value)
    @resource[:rhsm_baseurl] = value
  end
  def rhsm_baseurl?
    @resource[:rhsm_baseurl]
  end
  def rhsm_cacert=(value)
    @resource[:rhsm_cacert] = value
  end
  def rhsm_cacert?
    @resource[:rhsm_cacert]
  end
  def username=(value)
    @resource[:username] = value
  end
  def username?
    @resource[:username]
  end
  def password=(value)
    @resource[:password] = value
  end
  def password?
    @resource[:password]
  end
  def activationkeys=(value)
    @resource[:activationkeys] = value
  end
  def activationkeys?
    @resource[:activationkeys]
  end
  def pool=(value)
    @resource[:pool] = value
  end
  def pool?
    @resource[:pool]
  end
  def servicelevel=(value)
    @resource[:pool] = value
  end
  def servicelevel?
    @resource[:pool]
  end
  def environment=(value)
    @resource[:environment] = value
  end
  def environment?
    @resource[:environment]
  end
  def autosubscribe=(value)
    @resource[:autosubscribe] = value
  end
  def autosubscribe?
    @resource[:autosubscribe]
  end
  def force=(value)
    @resource[:force] = value
  end
  def force?
    @resource[:force]
  end
  def org=(value)
    @resource[:org] = value
  end
  def org?
    @resource[:org]
  end
end
