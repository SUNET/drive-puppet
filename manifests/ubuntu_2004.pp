# Class for Ubuntu 20.04
class sunetdrive::ubuntu_2004() {
  if $facts['os']['name'] == 'Ubuntu' and $facts['os']['distro']['release']['full'] == '20.04' {
    # Hide deprecation warnings for Ubuntu 2004
    file_line {'env_rubyopt':
      path => '/etc/environment',
      line => 'RUBYOPT=\'-W0\'',
    }
  }
}
