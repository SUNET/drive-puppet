# Class for site monitor
class sunetdrive::sitemonitor() {

  $sites = hiera_array('sites')
  $tls_servers = flatten($sites,hiera_array('tls_servers'))
  $tls_servers_with_port = hiera_array('tls_servers_with_port')
  $nextcloud_version_prod = split(hiera('nextcloud_version_prod'),'[-]')[0]
  $nextcloud_version_test = split(hiera('nextcloud_version_test'),'[-]')[0]

  file { '/etc/nagios4/conf.d/sunetdrive_sites.cfg':
    ensure  => present,
    content => template('sunetdrive/monitor/sunetdrive_sites.cfg.erb'),
    mode    => '0644',
  }
  file { '/etc/nagios4/conf.d/sunetdrive_ssl_checks.cfg':
    ensure  => present,
    content => template('sunetdrive/monitor/sunetdrive_ssl_checks.cfg.erb'),
    mode    => '0644',
  }
  cron { 'restart_socket':
    command => 'test -S /var/cache/thruk/live.sock || systemctl restart nagios4',
    user    => root,
    minute  =>  '*/5',
  }

}

