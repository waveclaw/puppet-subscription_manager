# Puppet-Subscription_manager

 [![Build Status](https://travis-ci.org/waveclaw/puppet-subscription_manager.svg?branch=master)](https://travis-ci.org/waveclaw/puppet-subscription_manager) [![Code Climate](https://codeclimate.com/github/waveclaw/puppet-subscription_manager/badges/gpa.svg)](https://codeclimate.com/github/waveclaw/puppet-subscription_manager)  [![Test Coverage](https://codeclimate.com/github/waveclaw/puppet-subscription_manager/badges/coverage.svg)](https://codeclimate.com/github/waveclaw/puppet-subscription_manager/coverage)

This module provides Custom Puppet Provider to handle registration and
consumption of RedHat subscriptions using subscription-manager.

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
* Satellite, unlike Katello, will require attachment to such subscriptions
  whenever paid-for RedHat Network Channels are made available through a
  repository view.

## License

Apache License, Version 2.0. Read the LICENSE file for details of the licensing.

## Requirements
* [puppet-boolean](https://forge.puppet.com/adrien/boolean) [on GitHub](https://github.com/adrienthebo/puppet-boolean)
* [puppetlabs-transition](https://forge.puppet.com/puppetlabs/transition) [on GitHub](https://github.com/puppetlabs/puppetlabs-transition)
* A good source for subscription-manager and its dependencies like [EPEL](http://repos.fedorapeople.org/repos/candlepin/subscription-manager/epel-subscription-manager.repo).

## Authors
* Gaël Chamoulaud (gchamoul at redhat dot com)
* James Laska (jlaska at redhat dot com)
* JD Powell (waveclaw at hotmail dot com)

See CONTRIBUTORS for others that have code consumed by this fork.

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
operations in involving subscription management.
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
Satellite 6.

```puppet
class { 'subscription_manager':
   org           => 'My_Company_Org_in_RHN',
   username      => 'some_rhn_special_user',
   password      => 'password123',
   autosubscribe => true,
   servicelevel  => 'STANDARD',
}
```
Putting the explicit password in the code is a *bad* idea. Using hiera-gpg or
hiera-eyaml back-ends is strongly encouraged for this example.

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

One of either the activation key or a username and password combination is needed
to register.  Both cannot be provided and will cause an error.

- **activationkey**: The activation key to use when registering the system (cannot be used with username and password)
- **password**: The password to use when registering the system
- **username**: The username to use when registering the system

##### Optional

- **pool**: A specific license pool to attach the system to. Can include a default view using the formant pool-name/view-name.
- **environment**: which environment to join at registration time
- **autosubscribe**: Enable automatic subscription to repositories based on default Pool settings. Must be false when using an activation key unless specifying a service level.
- **servicelevel**: provide automatic attachment to a service level in Satellite. Not applicable to katello installations.
- **force**: Should the registration be forced. Use this option with caution, setting it true will cause the system to be unregistered before running 'subscription-manager register'. Default value `false`.

### rhsm_register Examples

Register clients to RedHat Subscription Management using an activation key:

```puppet
rhsm_register { 'satellite.example.com':
  server_hostname => 'my-satellite.example.com',
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

##### rhsm_config options

See the documentation at [RedHat Support](https://access.redhat.com/documentation/en-US/Red_Hat_Subscription_Management/1/html/RHSM/rhsm-config.html#tab.rhsm.conf-parameters) for details on the `/etc/rhsm/rhsm.conf` file.

The most important settings are given bellow

- **server_hostname**: Same as the title or name of the resource
- **server_insecure**: If HTTP is used or HTTPS with an untrusted certificate
- **server_prefix**: The subscription path.  Usually `/subscription` for RHN and `/rhsm` for a Katello installation.
- **rhsm_baseurl**: The Content base URL in case the registration server has no content. An example would be [https://cdn.redhat.com](https://cdn.redhat.com) or [https://katello.example.com/pulp/repos](https://katello.example.com/pulp/repos)

Note: rhsmcertd is not the same as Katello's goferd.

##### rhsm_config Examples

As a resource.

```puppet
rhsm_config { 'katello.example.com':
    server_hostname             => 'katello.example.com',
    server_insecure             => false,
    server_port                 => 443,
    server_prefix               => '/rhsm',
    server_ssl_verify_depth     => 3,
    rhsm_baseurl                => 'https://katello.example.com/pulp/repos',
    rhsm_ca_cert_dir            => '/etc/rhsm/ca/',
    rhsm_consumercertdir        => '/etc/pki/consumer',
    rhsm_entitlementcertdir     => '/etc/pki/entitlement',
    rhsm_full_refresh_on_yum    => true,
    rhsm_manage_repos           => true,
    rhsm_pluginconfdir          => '/etc/rhsm/pluginconf_d',
    rhsm_plugindir              => '/usr/share/rhsm-plugins',
    rhsm_productcertdir         => '/etc/pki/product',
    rhsm_repo_ca_cert           => '/etc/rhsm/ca/katello-server-ca.pem',
    rhsm_report_package_profile => 1,
    rhsmcertd_autoattachinterval => 1440,
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

Users should only need to provide the settings in hiera that differ from any of
the defaults which are used in the module.  If you are using the resource you
will have to provide everything you want to set.

### rhsm\_repo

#### rhsm\_repo Parameters

If absolutely necessary the individual yum repositories can be filtered.

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

For released version the module can be installed with the Puppet module tool from the Puppet Forge.

```
  puppet module install waveclaw-subscription_manager
```
This will install *adrian-boolean* and *puppetlabs-transition* as dependencies.

### Development Version

For pre-release code the GitHub repository can be cloned.

In your puppet modules directory:
```
    git clone https://github.com/waveclaw/puppet-subscription_manager.git
```
Ensure the module is present in your puppetmaster's own environment (it doesn't
have to use it) and that the master has pluginsync enabled.  Run the agent on
the puppetmaster to cause the custom types to be synced to its local libdir
(`puppet master --configprint libdir`) and then restart the puppetmaster so it
loads them.

### Acceptance Tests

Acceptance tests require a working katello system, RedHat Satellite server or
just a repo of pre-built dependant packages.

Customization of the spec/spec_acceptance_helper.rb and specific tests is needed to
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

For a bug report please include or link:

* Code that triggers the error
* Output of ```facter -p``` from the system where the error occurs
* _Relevant_ error logs
* Any other information needed to understand the error
- What did you do (terminal session logs, etc)?
- What was expected?
- What actually happened?
- When did it start happening?
- Is it _still_ happening or happening all the time?

None of this guarantees a solution but at the least it can warn others.
