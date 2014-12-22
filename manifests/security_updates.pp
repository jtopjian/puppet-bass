# == Class: base::security_updates
#
# Enables automatic security updates
#
class bass::security_updates {

  case $::lsbdistid {

    'Ubuntu': {
      file { '/etc/apt/apt.conf.d/20auto-upgrades':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "APT::Periodic::Update-Package-Lists \"1\";\nAPT::Periodic::Unattended-Upgrade \"1\";\n",
      }
    }

  }

}
