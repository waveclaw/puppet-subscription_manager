# Puppet-Subscription\_manager

 [![Build Status](https://travis-ci.org/waveclaw/puppet-subscription_manager.svg?branch=master)](https://travis-ci.org/waveclaw/puppet-subscription_manager) [![Code Climate](https://codeclimate.com/github/waveclaw/puppet-subscription_manager/badges/gpa.svg)](https://codeclimate.com/github/waveclaw/puppet-subscription_manager)  [![Test Coverage](https://codeclimate.com/github/waveclaw/puppet-subscription_manager/badges/coverage.svg)](https://codeclimate.com/github/waveclaw/puppet-subscription\_manager/coverage)

This module provides Custom Puppet Provider to handle registration and
consumption of RedHat subscriptions using subscription-manager as part of Katello
or RedHat Satellite 6.

> This module can be used with RedHat Subscription Access Manager (SAM) but is
> not primarily designed to inter-operate with SAM separate from a Katello or
> Satellite service.
>
> You cannot use this module to switch between SAM and other products or
> to SAM from a different product because of the changes in the internal name
> for the CA certificates.

This module is a fork of the [puppet-subscription_manager](https://github.com/jlaska/puppet-subscription_manager)
module by James Laska that was in turn derived from [puppet-rhnreg_ks module](https://github.com/strider/puppet-rhnreg_ks)
 by Gaël Chamoulaud.  This fork provides an incompatible dedicated rhsm\_config
 resource and separates repository management from control of the Yum overrides.

## Notice

Due to various terminology differences between RHN Satellite, the upstream
Katello project and the further upstream component projects of Candlepin, The
Foreman, Puppet and Dogtag the names of properties and resources may be
confusing.
* Katello Pools and Satellite Subscriptions are different things presented
  through the same underlying system resources.  This module calls both 'pools.'
* Satellite, unlike Katello, will require attachment to subscriptions
  whenever paid-for RedHat Network Channels are made available through a
  repository view.   This module does not manage those certificates.
* RedHat SAM is an installable RedHat supported version of the Candlepin service
  which uses "candlepin-cert-consumer-" package name instead of of the package
  name "katello-ca-consumer-".  Options are provided to select this.

## License

Apache License, Version 2.0. Read the LICENSE file for details of the licensing.

## Requirements
* puppet-boolean [on GitHub](https://github.com/adrienthebo/puppet-boolean)
* [puppetlabs-transition](https://forge.puppet.com/puppetlabs/transition) [on GitHub](https://github.com/puppetlabs/puppetlabs-transition)
* A good source for subscription-manager and its dependencies like [EPEL](http://repos.fedorapeople.org/repos/candlepin/subscription-manager/epel-subscription-manager.repo).

## Authors

See CONTRIBUTORS.

## Classes and Defines

This module provides the standard install-config-service pattern. It also wraps
the provided native resources with a convenience class to enable simple or complex
deployment.

It is expected that any users not making use of default top-level import of the
module will be interested in the native types for customization.

#### Facts

Some custom facts are provided.

A family of facts, similar to the rhsm\_repo type, summarize the subscription
state. These can return lists of data under facter 2.0.
* rhsm\_available\_repos
* rhsm\_disabled\_repos
* rhsm\_enabled\_repos

The repo facts make use of a simple caching mechanism using the facts.d
directory to limit connections to the Katello or Satellite server.  Like the
katello-agent these only pull data once a day.

The once-per day schedule is currently a hard-coded value. However the cache can
be invalidated by finding and removing the cache files.

The cache files should appear as normal YAML format external fact files. These
facts may actually linger on after removing the rhsm module itself.  Beware that
the location of external fact files is different between Puppet and facter for
older versions of Puppet like 2 or 3 and facter 1.x.

The certificate authority is part of the rhsm_config type but is very useful for
operations in involving subscription management.  This differs slightly between
Katelo, RedHat Satellte and RedHat SAM.
* rhsm\_ca\_name

Of course, a fact exists about the identity of the client as known locally.
* rhsm\_identity

## Examples

Setup to and register one CentOS 6 client to a Katello server using a public
repository to obtain the agent.

```puppet
# (Optionally) Place this code in a .pp file some where on your Puppet's modulepath
# such as a file named subscription_manager.pp in a module named repo.
# The autoloader will be triggered by the rhsm module to search for this class.
class repo::subscription_manager {
  yumrepo { 'dgoodwin-subscription-manager':
  ensure              => 'present',
  baseurl             => 'https://copr-be.cloud.fedoraproject.org/results/dgoodwin/subscription-manager/epel-6-$basearch/',
  descr               => 'Copr repo for subscription-manager owned by dgoodwin',
  enabled             => '1',
  gpgcheck            => '1',
  gpgkey              =>  'https://copr-be.cloud.fedoraproject.org/results/dgoodwin/subscription-manager/pubkey.gpg',
    skip_if_unavailable => 'True',
  }
}

# Place this this in either a raw .pp manifest, a profile-like module or
# classify the node to require subscription_manager with these parameters in
# your ENC.
# Notice the explict call for the optional package repository to include.
class { 'subscription_manager':
    repo            => 'repo::subscription_manager',
    server_hostname => 'my_katello.example.com',
    activationkey   => '1-2-3-example.com-key',
    force           => true,
    org             => 'My_Example_Org',
  }
}
```

Register a RedHat Enterprise 7 or CentOS 7 node to the RedHat Network with
Satellite 6 using a password and username.

```puppet
class { 'subscription_manager':
   org           => 'My_Company_Org_in_RHN',
   username      => 'some_rhn_special_user',
   password      => 'password123',
   autosubscribe => true,
   servicelevel  => 'STANDARD',
}

Putting the explicit password in the code is a *bad* idea. Using hiera-gpg or
hiera-eyaml back-ends is strongly encouraged for this example.

```
Register a RedHat Enterprise 7 or CentOS 7 node to Satellite 6 using an activation key.

```puppet
  class { 'subscription_manager':
     server_hostname => 'satellite.example.com',
     org             => 'My_Company_Org',
     activationkey   => '1234-key',
     autosubscribe   => true,
     servicelevel    => 'STANDARD',
     config_hash     => {
       server_prefix          => '/rhsm',
       rhsm_baseurl           => "https://satellite.example.com/pulp/repos",
       rhsm_repo_ca_cert      => '%(ca_cert_dir)s/katello-server-ca.pem',
     },
     service_name    =>'rhsmcertd',
     force           => true,
  }
```
> Notice that the `rhsm_repo_ca_cert` must change to match the certificate provided
> by the katello-ca-consumer package on the Satellite server.  This can be
> contained in the files searched by the `rhsm_ca_cert` fact. These are SSL
> certificates which do not take into account Subject Alternative Names. Only
> the primary name in the certificate is used to check if the client is
> registered to the correct server.


Register to a local RedHat SAM server.

```puppet
  class { 'subscription_manager':
     server_hostname   => 'sam.example.com',
     org               => 'My_Company_Org',
     activationkey     => '1234-key',
     ca_package_prefix => 'candlepin-cert-consumer-', # note the trailing hypen
     autosubscribe     => true,
     servicelevel      => 'PREMIUM',
     config_hash       => {
       rhsm_repo_ca_cert      => '/etc/rhsm/ca/candlepin-local.pem',
     },
     service_name      =>'rhsmcertd',
     force             => true,
  }
```

> For this example one can see that the `config_hash` only needs customized entries
> so there is no need to provide every default.

## Types and Providers

The module adds the following new types:

* `rhsm_register` for managing RedHat Subscriptions
* `rhsm_config`   for configurating RedHat Subscriptions
* `rhsm_repo`     for managing RedHat Subscriptions to Repositories
* `rhsm_override` for managing the Subscrption yumrepo override cache
* `rhsm_pool`     for managing RedHat Entitlement Pools (Satellite Subscription Collections)

### rhsm_register

#### Parameters

##### Mandatory

- **server_hostname**: Specify a registration server hostname such as subscription.rhn.redhat.com.
- **org**: provide an organization to join (defaults to the Default_Organization
)

Either an activation key or a username and password combination is needed to
register.  Both cannot be provided and will cause an error.

- **activationkey**: The activation key to use when registering the system (cannot be used with username and password)
- **password**: The password to use when registering the system
- **username**: The username to use when registering the system

##### Optional

- **pool**: A specific license pool to attach the system to. Can include a default view using the formant pool-name/view-name.
- **lifecycleenv**: which lifecycle environment to join at registration time (incompatible with using activation keys)
- **autosubscribe**: Enable automatic subscription to repositories based on default Pool settings. Must be false when using an activation key unless specifying a service level.
- **servicelevel**: provide automatic attachment to a service level in Satellite. Not applicable to katello installations.
- **force**: Should the registration be forced. Use this option with caution, setting it true will cause the system to be unregistered before running 'subscription-manager register'. Default value `false`.

### rhsm_register Examples

Register clients to RedHat Subscription Management using an activation key:

```puppet
rhsm_register { 'satellite.example.com':
  server_hostname => 'satellite.example.com',
  activationkey   => '1-myactivationkey',
}
```

Register clients to RedHat Subscription management using a username and password:

```puppet
rhsm_register { 'subscription.rhn.example.com':
  username        => 'myusername',
  password        => 'mypassword',
  autosubscribe   => true,
  force           => true,
}
```

Register clients to RedHat Subscription management and attach to a specific license pool:

```puppet
rhsm_register { 'subscription.rhn.example.com':
  username  => 'myusername',
  password  => 'mypassword',
  pool      => 'mypoolid',
}
```

### rhsm_config

Please see man(5) RHSM.CONF for your locally supported options.  There are quite
 a few and they require specific inputs.

##### rhsm_config options

See the documentation at [RedHat Support](https://access.redhat.com/documentation/en-US/Red_Hat_Subscription_Management/1/html/RHSM/rhsm-config.html#tab.rhsm.conf-parameters) for RedHat provided details on the `/etc/rhsm/rhsm.conf` file.

The most important settings are as follows.  Specific support is made for them.

- **server_hostname**: Same as the title or name of the resource
- **server_insecure**: If HTTP is used or HTTPS with an untrusted certificate
- **server_prefix**: The subscription path.  Usually `/subscription` for RHN and `/rhsm` for a Katello installation.
- **rhsm_baseurl**: The Content base URL in case the registration server has no content. An example would be [https://cdn.redhat.com](https://cdn.redhat.com) or [https://katello.example.com/pulp/repos](https://katello.example.com/pulp/repos)

> rhsmcertd is not the same as Katello's goferd.

Other options can be rolled into a configuration hash and fed to the module as a
whole. See init.pp and the following YAML example for details.

##### rhsm_config Examples

As a resource.

```puppet
rhsm_config { 'katello.example.com':
    server_hostname              => 'katello.example.com',
    server_insecure              => false,
    server_port                  => 443,
    server_prefix                => '/rhsm',
    server_ssl_verify_depth      => 3,
    rhsm_baseurl                 => 'https://katello.example.com/pulp/repos',
    rhsm_ca_cert_dir             => '/etc/rhsm/ca/',
    rhsm_consumercertdir         => '/etc/pki/consumer',
    rhsm_entitlementcertdir      => '/etc/pki/entitlement',
    rhsm_full_refresh_on_yum     => true,
    rhsm_manage_repos            => true,
    rhsm_pluginconfdir           => '/etc/rhsm/pluginconf_d',
    rhsm_plugindir               => '/usr/share/rhsm-plugins',
    rhsm_productcertdir          => '/etc/pki/product',
    rhsm_repo_ca_cert            => '/etc/rhsm/ca/katello-server-ca.pem',
    rhsm_report_package_profile  => 1,
    rhsmcertd_autoattachinterval => 1440,
    server_proxy_hostname        => 'proxy.example.com',
    server_proxy_user            => 'proxy_user',
    server_proxy_password        => 'proxy_password',
    server_proxy_port            => 4443,    
}
```

As a hiera data source.

```yaml
---
subscription_manager::config_hash:
 server_hostname: 'katello.example.com'
 server_insecure:  false
 server_prefix:  '/rhsm'
 server_port:  443
 server_ssl_verify_depth:  3
 rhsm_baseurl:  'https://katello.example.com/pulp/repos'
 rhsm_ca_cert_dir:  '/etc/rhsm/ca'
 rhsm_repo_ca_cert:  '%(ca_cert_dir)s/katello-server-ca.pem'
 rhsm_productcertdir:  '/etc/pki/product'
 rhsm_entitlementcertdir:  '/etc/pki/entitlement'
 rhsm_consumercertdir:  '/etc/pki/consumer'
 rhsm_manage_repos:  true
 rhsmcertd_certcheckinterval:  240
 rhsmcertd_autoattachinterval:  1440

```

Users should only need to provide the settings in `config_hash` _that differ_
from any of the defaults which are used in the module.

If you are using the resource you will have to provide everything you want to set.

Un-setting a required default by providing a blank option will make the a
subscription stop working.

The `default_log_level` and basic *module_name* logging settings are available.
None of the sub-modules are available.  A suggestion for those would be to ship
customized file-line resources to not conflict with changes created through the
`subscription-manager` command.

### rhsm\_repo

#### rhsm\_repo Parameters

If absolutely necessary the individual yum repositories can be filtered.

> This cannot add new repositories, only filter existing subscribed repositories.
> If you require more repositories, edit your Content View(s) or Pool(s).
> Or just use the `yumrepo` native type that ships with Puppet.

- **ensure**: Valid values are `present`, `absent`. Default value is `present`.
- **name**: The name of the repository registration to filter.


#### rhsm\_repo Examples

Example of a repository from the Server

```puppet
rhsm_repo { 'rhel-6-server-java-rpms':
  ensure        => present, # equal to the enabled property
  url           => 'https://katello.example.com/pulp/repos/abc-corp/production/reg-key-1/content/dist/rhel/server/6/6Server/$basearch/java-repo/os',
  content_label => 'rhel-6-java-rpms',
  id            => 'rhel-6-java-rpms',
  name          => 'RedHat Enterprise Linux 6 Server - Java (RPMs)',
  repo_type     => channel,
}
```

### rhsm\_override

## rhsm\_override Example

This is returned by the Puppet resource command but it not manageable in a
meaningful way through the type.

```puppet
rhsm_repo { 'rhel-server6-epel':
  ensure        => present, # equal to the enabled property
  updated       => 2015-07-17T14:26:35.064+0000,
  created       => 2015-07-17T14:26:35.064+0000,
  content_label => 'rhel-server6-epel'
  repo_type     => override,
}
```

### rhsm\_pool

Subscriptions to use RHN are sold as either individual entitlements or a pools of
entitlements.  A given server registered to a Satellite 6 or Katello system will
consume at least 1 entitlement from a Pool.

This subscription to the Pool is what enables the set of repositories to be made
available on the server for further subscription.

While this type is mostly useful for exporting the registration information in detail
it can also be used to force switch registrations for selected clients.

### rhsm\_pool Parameters
- **name**: Unique Textual description of the Pool
- **ensure**: Is this pool absent or present?
- **provides**: Textual information about the Pool, usually same as the name.
- **sku**: Stock Keeping Unit, usually for inventory tracking
- **account**: Account number for this Pool of Subscriptions
- **contract**: Contract details, if known
- **serial**: Any serial number that is associated with the pool
- **id**: ID Hash of the Pool
- **active**: Is this subscription in use at the moment?
- **quantity\_used**: How many is used?  Often licenses are sold by CPU or core so
is it possible for a single server to consume several subscriptions.
- **service\_type**: type of service, usually relevant to official RedHat Channels
- **service\_level**: level of service such as STANDARD, PREMIUM or SELF-SUPPORT
- **status_details**: Status detail string
- **subscription\_type**: Subscription - type
- **starts**: Earliest date and time the subscription is valid for
- **ends**: When does this subscription expire
- **system\_type**: Is this a physical, container or virtual system?

### rhsm\_pool Example

```puppet
rhsm_pool { '1a2b3c4d5e6f1234567890abcdef12345':
  name              => 'Extra Packages for Enterprise Linux',
  ensure            => present,
  provides          => 'EPEL',
  sku               => 1234536789012,
  contract          => 'Fancy Widgets, LTD',
  account           => '1234-12-3456-0001',
  serial            => 1234567890123456789,
  id                => 1a2b3c4d5e6f1234567890abcdef12345,
  active            => true,
  quantity_used     => 1,
  service_level     => 'STANDARD',
  service_type      => 'EOL',
  status_details    => 'expired',
  subscription_type => 'permanent',
  starts            => 06/01/2015,
  ends              => 05/24/2045,
  system_type       => physical,
}
```

## Installing

### Release Version

For released version the module can be installed with the Puppet module tool
from the Puppet Forge.  Or even added as a Puppetfile source with Puppet
Enterprise or r10k or Puppet Librarian.

```
  puppet module install waveclaw-subscription_manager
```
This will install *adrian-boolean* and *puppetlabs-transition* as dependencies.

### Development Version

For pre-release code the GitHub repository can be cloned.

In your puppet modules directory:

For the original module:
```
    git clone https://github.com/jlaska/puppet-subscription_manager.git
```

For this module:
```
    git clone https://github.com/waveclaw/puppet-subscription_manager.git
```

Ensure the module is present in your puppetmaster's own environment.  The Puppet
Master node doesn't have to use the module or Satellite itself. Ensure that the
target node to register has pluginsync enabled.  Run the agent on the target node
to cause the custom types to be synced to the local libdir
(`puppet master --configprint libdir`).

### Deprication Warnings

Support for Ruby 1.8.7 and older is ad-hoc at best. Modern `rake` and
`json_pure` require newer releases.

The caching functions were pushed to a difference module on the forge,
`waveclaw-facter_cachable`. Some of the tests do not run properly under
Travis CI.  These are commended out in the code but can be run locally.

### Acceptance Tests

Acceptance tests require a working katello system, RedHat Satellite server or
just a repo of pre-built dependent packages.

Customization of the `spec/spec_acceptance_helper.rb` and specific tests is needed to
point the full tests at working servers.  Otherwise some of the tests must fail.

## Issues

Please file any issues or suggestions on [on GitHub](https://github.com/waveclaw/puppet-subscription_manager/issues)

### Guidelines

Please follow the example42 development guidelines.

Pull requests and bug reports via GitHub are welcomed.

For Pull Requests please:

* puppet-lint code
* provide rSpec tests if possible: code that sets tests on fire won't be merged
* Follow the module style naming standards
* Add your name to CONTRIBUTORS if you are new

For a bug report please include or link:

* Code that triggers the error
* Output of ```facter -p``` from the system where the error occurs
* _Relevant_ error logs (e.g. from RHSM parts or `subscription-manager` output)
* Of course, the basic 'how to ask a good question' information.
- What did you do (terminal session logs, etc)?
- What was expected?
- What actually happened?
- When did it start happening?
- Is it _still_ happening?
- Does it happen all the time?
* Any other information needed to understand the error

None of this guarantees a solution. At the least a good bug report can warn others.
