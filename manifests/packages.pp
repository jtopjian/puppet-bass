# == Class: bass::packages
#
# Installs a given set of packages, gems, and eggs
#
# === Parameters
#
# [*packages*]
#   A hash of packages to install:
#     packages:
#       tmux: 'latest'
#       git:  'present'
#
# [*gems*]
#   Similar to $packages, but ruby gems
#
# [*eggs*]
#   Similar to $packages, but python eggs
#
class bass::packages (
  $packages = {},
  $gems     = {},
  $eggs     = {},
) {

  # Configure each package type
  $packages.each |$package, $version| {
    package { $package:
      ensure => $version,
    }
  }

  $gems.each |$gem, $version| {
    package { $gem:
      ensure   => $version,
      provider => 'gem',
    }
  }

  $eggs.each |$egg, $version| {
    package { $egg:
      ensure   => $version,
      provider => 'pip',
    }
  }

}
