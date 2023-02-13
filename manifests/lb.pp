class sunetdrive::lb($location=undef) {
  $nodenumber = $::fqdn[2,1]

  sunet::nagios::nrpe_command {'check_exabgp_announce':
    command_line => '/usr/lib/nagios/plugins/check_exabgp_announce -w 1 -c 10',
    require      => File['/usr/lib/nagios/plugins/check_exabgp_announce'],
  }
  sunet::nagios::nrpe_command {'check_sarimner':
    command_line => '/usr/lib/nagios/plugins/check_sarimner',
    require      => File['/usr/lib/nagios/plugins/check_sarimner'],
  }

  file { '/etc/sudoers.d/99-docker-logs':
    ensure  => file,
    content => "nagios ALL=(root) NOPASSWD: /usr/bin/docker logs*\n",
    mode    => '0440',
    owner   => 'root',
    group   => 'root',
  }
  file { '/usr/lib/nagios/plugins/check_exabgp_announce':
    ensure  => 'file',
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/lb/check_exabgp_announce.erb'),
  }
  file { '/usr/lib/nagios/plugins/check_sarimner':
    ensure  => 'file',
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/lb/check_sarimner.erb'),
  }
  file { '/opt/frontend/errorfiles':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }
  -> file { '/opt/frontend/errorfiles/503.http':
    ensure  => 'file',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/lb/503.http.erb'),
  }
}
