# == Class: bass::firewall
#
# Creates and configures firewall rules
#
# === Parameters
#
# [*default_policy_ipv4*]
#   The default policy to use for ipv4 traffic
#
# [*default_policy_ipv6*]
#   The default policy to use for ipv6 traffic
#
# [*purge*]
#   Purge existing firewall rules
#
# [*trusted_ipv4*]
#   An array of trusted hosts/networks cidrs
#
# [*trusted_ipv6*]
#   An array of trusted hosts/networks cidrs
#
# [*untrusted_ipv4*]
#   An array of untrusted hosts/networks cidrs
#
# [*untrusted_ipv6*]
#   An array of untrusted hosts/networks cidrs
#
# [*rules*]
#   A hash of firewall rules to apply:
#
# === Example
#
#   bass::firewall:
#     default_policy_ipv4: drop
#     default_policy_ipv6: drop
#     purge: true
#     trusted_ipv4:
#       - '192.168.255.0/24'
#     trusted_ipv6:
#       - 'fe80::/64'
#     rules:
#       '100 accept http and https for ipv4'
#         port: [80, 443]
#         proto: 'tcp'
#         action: 'accept'
#       '100 accept http and https for ipv6'
#         port: [80, 443]
#         proto: 'tcp'
#         action: 'accept'
#         provider: 'ip6tables'
#       '100 accept ssh for ipv6'
#         port: 22
#         proto: 'tcp'
#         action: 'accept'
#       '100 accept ssh for ipv6'
#         port: 22
#         proto: 'tcp'
#         action: 'accept'
#         provider: 'ip6tables'
#
class bass::firewall (
  $default_policy_ipv4 = 'drop',
  $default_policy_ipv6 = 'drop',
  $purge               = true,
  $trusted_ipv4        = [],
  $trusted_ipv6        = [],
  $untrusted_ipv4      = [],
  $untrusted_ipv6      = [],
  $rules               = {},
) {

  include bass::params
  include firewall

  # Purge rules if configured to do so
  if $purge == true {
    resources { 'firewall':
      purge => true,
    }
  }

  # Configure local access
  firewall { '000 accept all icmp':
    proto   => 'icmp',
    action  => 'accept',
  } ->
  firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  } ->
  firewall { '003 accept related established rules':
    proto   => 'all',
    state => ['RELATED', 'ESTABLISHED'],
    action  => 'accept',
  }

  # Block untrusted hosts/networks
  $untrusted_ipv4.each |$cidr| {
    firewall { "010 block all traffic from ${cidr}":
      source => $cidr,
      proto  => 'all',
      action => 'deny',
    }
  }
  $untrusted_ipv6.each |$cidr| {
    firewall { "010 block all traffic from ${cidr}":
      source   => $cidr,
      proto    => 'all',
      action   => 'deny',
      provider => 'ip6tables',
    }
  }

  # Allow trusted hosts/networks
  $trusted_ipv4.each |$cidr| {
    firewall { "020 allow all traffic from ${cidr}":
      source => $cidr,
      proto  => 'all',
      action => 'accept',
    }
  }
  $trusted_ipv6.each |$cidr| {
    firewall { "020 accept all traffic from ${cidr}":
      source   => $cidr,
      proto    => 'all',
      action   => 'accept',
      provider => 'ip6tables',
    }
  }

  # Apply given rules
  create_resources(firewall, $rules)

  # Set a default policy
  firewall { '999 default policy for ipv4':
    proto  => 'all',
    action => $default_policy_ipv4,
  }
  firewall { '999 default policy for ipv6':
    proto    => 'all',
    action   => $default_policy_ipv6,
    provider => 'ip6tables',
  }

}
