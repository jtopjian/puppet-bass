# == Class: bass::sysctl
#
# Configures sysctl on a system
#
# === Parameters:
#
# [*ip_local_reserve_ports*]
#   An array of local ports to reserve
#
# [*settings*]
#   A generic list of sysctl settings
#
# === Example:
#
#   bass::sysctl
#     ip_local_reserve_ports:
#       - 8774
#       - 8775
#       - 8776
#     settings:
#       net.ipv4.ip_forward: 1
#       vm.nr_hugepages: 1583
#
class bass::sysctl (
  $ip_local_reserve_ports = [],
  $settings               = {}
) {

  # join local ports
  if $ip_local_reserve_ports != [] {
    $local_ports = join($ip_local_local_reserve_ports, ',')
    sysctl::value { 'net.ipv4.ip_local_reserve_ports':
      value => $local_ports,
    }
  }

  # Set all other rules
  $settings.each |$sysctl_setting, $sysctl_value| {
    sysctl::value { $sysctl_setting:
      value => $sysctl_value,
    }
  }

}
