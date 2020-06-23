# == Defined Type: bass::user
#
# Creates and configures a user
#
# === Parameters
#
# [*name*]
#   The name of the user
#
# [*ensure*]
#   The ensure status of the user/group
#
# [*uid*]
# [*gid*]
#   The uid/gid of the user
#
# [*password*]
#   The hashed password of the user
#
# [*home*]
#   The home directory of the user.
#   If not specified, it defaults to /home/user.
#   Unless it's root, then /root.
#
# [*managehome*]
#   Whether or not to create the home directory.
#
# [*shell*]
#   The shell of the user
#
# [*sudo*]
#   Whether the user should have sudo access. Options are:
#     * false: no sudo access
#     * full: full sudo access with no password
#     * limited: limited sudo access with no password
#
# [*sudo_commands*]
#   When `sudo` is set to `limited`, an array of commands must be specified.
#
# [*create_ssh_key*]
#   Whether or not to create an SSH key for the new user.
#
# [*ssh_authorized_keys*]
#   A list of stored public keys that will be placed in the `authorized_users` file.
#   These keys must be defined in hiera.
#
# [*ssh_unauthorized_keys*]
#   A list of stored public keys that must not be in the `authorized_users` file.
#   These keys must be defined in hiera.
#
# [*ssh_authorized_users*]
#   A list of authorized users managed by the `jtopjian/sshkeys` module.
#
# === Example:
#
# bass::user { 'sensu':
#   gid            => 980,
#   uid            => 980,
#   password       => '*',
#   home           => '/opt/sensu',
#   sudo           => 'limited',
#   sudo_commands  => ['/etc/sensu/plugins/*],
#   create_ssh_key => false,
# }
#
# bass::user { 'nova':
#   gid            => 999,
#   uid            => 999,
#   password       => '*',
#   home           => '/var/lib/nova',
#   managehome     => false,
#   create_ssh_key => false,
# }
#
# === Notes
#
# the `jtopjian/sshkeys` module is required to use ssh_authorized_users
#
define bass::user (
  $uid,
  $gid,
  $password,
  $ensure               = 'present',
  $groups               = [],
  $home                 = undef,
  $managehome           = true,
  $shell                = '/usr/sbin/nologin',
  $sudo                 = false,
  $sudo_commands        = [],
  $create_ssh_key       = false,
  $ssh_authorized_keys  = [],
  $ssh_authorized_users = [],
  $ssh_unauthorized_keys  = [],
) {

  group { $name:
    ensure => $ensure,
    gid    => $gid,
  }

  if $home {
    $home_real = $home
  } else {
    if $name == 'root' {
      $home_real = '/root'
    } else {
      $home_real = "/home/${name}"
    }
  }

  user { $name:
    ensure     => $ensure,
    uid        => $uid,
    gid        => $gid,
    password   => $password,
    groups     => $groups,
    managehome => $managehome,
    home       => $home_real,
    shell      => $shell,
    require    => Group[$name],
  }

  $homedir = getvar("::home_${name}")

  if $homedir == '' {
    notify { "homedir for ${name} is not ready yet. Skipping SSH configuration. ${homedir}": }
  } else {
    if $create_ssh_key {
      sshkeys::create_ssh_key { $name: }
    }

    $ssh_keys = hiera('site::ssh::keys', false)
    if is_hash($ssh_keys) {
      $ssh_authorized_keys.each |$key_name| {
        if has_key($ssh_keys, $key_name) {
          $key = $ssh_keys[$key_name]
          ssh_authorized_key { "${name}_${key['key']}":
            ensure => absent,
            user   => $name,
            type   => $key['type'],
            key    => $key['key'],
          }
          ssh_authorized_key { "${name}_${key_name}":
            user => $name,
            type => $key['type'],
            key  => $key['key'],
          }
        }
      }

      $ssh_unauthorized_keys.each |$key_name| {
        if has_key($ssh_keys, $key_name) {
          $key = $ssh_keys[$key_name]
          ssh_authorized_key { "${name}_${key_name}":
            ensure => absent,
            user => $name,
            type => $key['type'],
            key  => $key['key'],
          }
        }
      }
    }

    $ssh_authorized_users.each |$remote_user| {
      sshkeys::set_authorized_key { "${remote_user} to ${name}@${::fqdn}":
        local_user  => $name,
        remote_user => $remote_user,
      }
    }

  }

  if $sudo {

    if $sudo == 'full' {
      $content = "${name} ALL=(ALL) NOPASSWD:ALL\n"
    } elsif $sudo == 'limited' {
      $commands = join($sudo_commands, ', ')
      $content = "${name} ALL=(ALL) NOPASSWD:${commands}\n"
    }

    file { "/etc/sudoers.d/${name}":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0440',
      content => $content,
    }

  }

}
