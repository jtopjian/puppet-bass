class bass::params {

  case $::osfamily {
    'Debian': {
      $iptables_packages = ['iptables', 'iptables-persistent']
    }
    default: {
      notify { "Module 'bass' does not support ${::osfamily} yet.": }
    }
  }

}
