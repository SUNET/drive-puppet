include stdlib
class sunetdrive::thruk($location=undef) {


  $thruk_local_config = '# File managed by puppet
  <Component Thruk::Backend>
    <peer>
        name   = Core
        type   = livestatus
        <options>
            peer          = /var/cache/thruk/live.sock
            resource_file = /etc/nagios4/resource.cfg
       </options>
       <configtool>
            core_conf      = /etc/nagios4/nagios.cfg
            obj_check_cmd  = /usr/sbin/nagios4 -v /etc/nagios4/nagios.cfg
           obj_reload_cmd  = systemctl reload nagios4.service
       </configtool>
    </peer>
</Component>
cookie_auth_restricted_url = https://monitor.drive.sunet.se/thruk/cgi-bin/restricted.cgi
'

  file_line {'nagios_livestatus_conf':
    line => 'broker_module=/usr/local/lib/mk-livestatus/livestatus.o /var/cache/thruk/live.sock',
    path => '/etc/nagios4/nagios.cfg'
  }
  file_line {'nagiosadmin_cgi_conf':
    line    => 'authorized_for_admin=nagiosadmin',
    match   => '^authorized_for_admin=thrukadmin',
    path    => '/etc/thruk/cgi.cfg',
    require => Package['thruk'],
  }
  exec {'mk-livestatus-src':
      command => 'curl -s https://download.checkmk.com/checkmk/1.5.0p24/mk-livestatus-1.5.0p24.tar.gz --output /opt/mk-livestatus-1.5.0p24.tar.gz',
      unless  => 'ls /usr/local/lib/mk-livestatus/livestatus.o',
  }
  exec {'mk-livestatus-tar':
    command => 'cd /opt && tar xfv mk-livestatus-1.5.0p24.tar.gz',
    require => Exec['mk-livestatus-src'],
    unless  => 'ls /usr/local/lib/mk-livestatus/livestatus.o',
  }
  exec {'mk-livestatus-build':
    command => 'apt update && apt install -y make libboost-system1.71.0 clang librrd-dev libboost-dev libasio-dev libboost-system-dev && cd /opt/mk-livestatus-1.5.0p24 && ./configure --with-nagios4 && make && make install && apt -y remove clang librrd-dev libboost-dev libasio-dev libboost-system-dev make && apt autoremove -y',
    require => [Exec['mk-livestatus-tar'], File_line['nagios_livestatus_conf'], Exec['www-data_in_nagios_group']],
    unless  => 'ls /usr/local/lib/mk-livestatus/livestatus.o',
  }
  exec {'www-data_in_nagios_group':
    command => 'usermod -a -G nagios www-data && usermod -a -G www-data nagios',
    unless  => 'id www-data | grep nagios',
  }
  package {'thruk':
      ensure  => 'installed',
      require => Exec['mk-livestatus-build'],
  }
  package {'thruk-plugin-reporting':
      ensure  => 'installed',
      require => Package['thruk'],
  }
  file { 'thruk_repo' :
      ensure  => 'file',
      name    => '/etc/apt/sources.list.d/labs-consol-stable.list',
      mode    => '0644',
      content => 'deb http://labs.consol.de/repo/stable/ubuntu focal main',
      require =>  Exec['thruk_gpg_key'],
  }
  file { 'thruk_conf' :
      ensure  => 'file',
      name    => '/etc/thruk/thruk_local.conf',
      mode    => '0640',
      owner   => 'www-data',
      group   => 'www-data',
      content => $thruk_local_config,
      require => Package['thruk'],
  }
  exec { 'thruk_gpg_key':
      command => 'curl -s "https://labs.consol.de/repo/stable/RPM-GPG-KEY" | sudo apt-key add -',
      unless  => 'apt-key list 2> /dev/null | grep "F2F9 7737 B59A CCC9 2C23  F8C7 F8C1 CA08 A57B 9ED7"',
  }

}
