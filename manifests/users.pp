# == Class: bass::users
#
# Creates and configures a given set of users
#
# === Parameters
#
# [*users*]
#   A hash of users and their attributes:
#
#   users:
#     jdoe:
#       account:
#         uid: 999
#         password: 'password'
#       group:
#         gid: 999
#       ssh_authorized_keys:
#         jdoe.work:
#           ensure: 'present'
#           type: 'rsa'
#           key: '...'
#       ssh_authorized_users:
#         'root@puppet.example.com': 'present'
#         'root@mysql.example.com': 'present'
#       sudo: true
#
#
# === Notes
#
# the `jtopjian/sshkeys` module is required to use ssh_authorized_users
#
class bass::users (
  $users = {},
) {

  # Loop through users and configure them
  $users.each |$user, $user_info| {

    # Pull the user account info
    $account = $user_info['account']

    # Check the state of the user
    # present by default
    if has_key($account, 'ensure') {
      $ensure = $account['ensure']
    } else {
      $ensure = 'present'
    }

    # Check if the user is being removed
    if $ensure == 'absent' {
      user { $user:
        ensure => absent,
      }
      group { $user:
        ensure => absent,
      }
    } else {
      if has_key($user_info, 'group') and is_hash($user_info['group']) {
        ensure_resource(group, $user, $user_info['group'])
      } else {
        ensure_resource(group, $user, {})
      }

      # Create a final hash of the parameters for the user resource
      $account_to_create = merge($account, { 'require' => "Group[${user}]" })

      # Create the user
      ensure_resource(user, $user, $account_to_create)

      # If $::home_${user} is null, wait
      $homedir = getvar("::home_${user}")

      if $homedir == '' {
        notify { "homedir for ${user} is not ready yet. Skipping SSH configuration.": }
      } else {
        # Create an SSH key for the user
        if has_key($user_info, 'ssh_key') and is_hash($user_info['ssh_key']){
          sshkeys::create_ssh_key { $user: }
        }

        # For each given ssh key,
        # add that key to ~/.ssh/authorized_keys
        if has_key($user_info, 'ssh_authorized_keys') and is_hash($user_info['ssh_authorized_keys']) {
          $user_info['ssh_authorized_keys'].each |$ssh_key_name, $ssh_key_info| {
            ensure_resource(ssh_authorized_keys, "${user}: ${ssh_key_name}", $ssh_key_info)
          }
        }

        if has_key($user_info, 'ssh_authorized_users') and is_hash($user_info['ssh_authorized_users']) {
          $user_info['ssh_authorized_users'].each |$ssh_authorized_user, $ensure_key| {
            sshkeys::set_authorized_key { "${ssh_authorized_user} to ${user}@${::fqdn}":
              ensure      => $ensure_key,
              local_user  => $user,
              remote_user => $ssh_authorized_user,
            }
          }
        }

        if has_key($user_info, 'sudo') {
          if $user['sudo'] == true {
            file { "/etc/sudoers.d/${user}":
              ensure  => present,
              owner   => 'root',
              group   => 'root',
              mode    => '0440',
              content => "${user} ALL=(ALL) NOPASSWD:ALL\n",
            }
          }
        } else {
          file { "/etc/sudoers.d/${user}":
            ensure => absent,
          }
        }
      }

    }

  }

}
