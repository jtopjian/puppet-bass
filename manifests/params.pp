# Not needed at the moment
class bass::params {

  case $::osfamily {
    'Debian': {
    }
    default: {
      notify { "Module 'bass' does not support ${::osfamily} yet.": }
    }
  }

}
