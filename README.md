bass
====

This module contains common configurations that can easily be applied to different environments.

It's tuned very specifically to environments that I create, but you might be able to use it in your environment.

Example
-------

### Hiera

```yaml
# Base

## Firewall

site::firewall::policy::ipv4: 'drop'
site::firewall::policy::ipv6: 'drop'
site::firewall::trusted::ipv4:
  - '10.1.0.0/20'
site::firewall::trusted::ipv6:
  - '2605:fd00:4:1000::/64'

## Hosts
site::hosts::ip: "%{::ipaddress6_eth0}"
site::hosts::global: false
site::hosts::static_hosts:
  www.example.com:
    ip: '192.168.255.10'
    host_aliases: ['www', 'www2.example.com', 'www2']

## Packages

site::packages:
  tmux: 'latest'
  git: 'latest'

## Users
site::users:
  root:
    account:
      uid: 0
      gid: 0
      password: '*'
      home: '/root'
    ssh_authorized_users:
      root@puppet.example.com: 'present'
      root@cloud.example.com: 'present'
    ssh_key:
      type: 'rsa'
  jdoe:
    group:
      ensure: 'present'
      gid: 999
    account:
      ensure: 'present'
      managehome: true
      uid: 999
      gid: 999
    ssh_key:
      type: 'rsa'
```

### Puppet

```puppet
class site::profiles::base {

  # Hiera
  $users                         = hiera_hash('site::users', {})
  $hosts_ip                      = hiera('site::hosts::ip', $::ipaddress_eth0)
  $hosts_global                  = hiera('site::hosts::global', false)
  $hosts_static_hosts            = hiera('site::hosts::static_hosts', {})
  $packages                      = hiera_hash('site::packages', {})
  $packages_gems                 = hiera_hash('site::packages::gems', {})
  $packages_eggs                 = hiera_hash('site::packages::eggs', {})
  $firewall_default_policy_ipv4  = hiera('site::firewall::policy::ipv4', 'drop')
  $firewall_default_policy_ipv6  = hiera('site::firewall::policy::ipv6', 'drop')
  $firewall_purge                = hiera('site::firewall::purge', true)
  $firewall_trusted_ipv4         = hiera_array('site::firewall::trusted::ipv4', [])
  $firewall_trusted_ipv6         = hiera_array('site::firewall::trusted::ipv6', [])
  $firewall_untrusted_ipv4       = hiera_array('site::firewall::untrusted::ipv4', [])
  $firewall_untrusted_ipv6       = hiera_array('site::firewall::untrusted::ipv6', [])
  $firewall_rules:               = hiera_hash('site::firewall::rules', {})
  $sysctl_ip_local_reserve_ports = hiera_array('site::network::local_reserve_ports', [])
  $sysctl_settings               = hiera_hash('site::sysctl::settings', {})

  anchor { 'site::profiles::base::begin': } ->
  class { 'bass::users':
    users => $users,
  } ->
  class { 'bass::hosts':
    ip           => $hosts_ip,
    is_global    => $hosts_global,
    static_hosts => $hosts_static_hosts,
  } ->
  class { 'bass::packages':
    packages => $packages,
    gems     => $packages_gems,
    eggs     => $packages_eggs,
  } ->
  class { 'bass::firewall':
    default_policy_ipv4 => $firewall_default_policy_ipv4,
    default_policy_ipv6 => $firewall_default_policy_ipv6,
    purge               => $firewall_purge,
    trusted_ipv4        => $firewall_trusted_ipv4,
    trusted_ipv6        => $firewall_trusted_ipv6,
    untrusted_ipv4      => $firewall_untrusted_ipv4,
    untrusted_ipv6      => $firewall_untrusted_ipv6,
    rules               => $firewall_rules,
  } ->
  class { 'bass::sysctl':
    ip_local_reserve_ports => $sysctl_ip_local_reserve_ports,
    settings               => $sysctl_settings,
  } ->
  class { 'bass::security_updates': } ->
  anchor { 'site::profiles::base::end': }

}
```
