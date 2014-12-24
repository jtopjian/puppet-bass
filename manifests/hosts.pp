# == Class: bass:hosts
#
# Helps manage /etc/hosts entries
#
# === Parameters
#
# [*ip_address*]
#   The IP address of the host entry
#
# [*is_global*]
#   Whether the host entry should be added to all hosts
#   or only hosts in a specific region
#
# [*static_hosts*]
#   A hash of staticly defined host entries
#
# === Example:
#
#  site::hosts::ip: "%{::ipaddress6_eth0}"
#  site::hosts::global: false
#  site::hosts::static_hosts:
#    www.example.com:
#      ip: '192.168.255.10'
#      host_aliases: ['www', 'www2.example.com', 'www2']
#
class bass::hosts (
  $ip,
  $is_global    = false,
  $static_hosts = {},
) {

  if $is_global {
    $tags = ['global']
  } else {
    $tags = [$::location]
  }

  # Create the static host entries
  create_resources(host, $static_hosts)

  # Export this host's /etc/hosts entry
  @@host { $::fqdn:
    host_aliases => [$::hostname],
    ip           => $ip,
    tag          => $tags,
  }

  # Import matching /etc/hosts entries
  Host<<| tag == $::location and title != $::fqdn |>>
  Host<<| tag == 'global' and title != $::fqdn |>>

}
