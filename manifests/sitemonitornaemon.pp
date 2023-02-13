# Class for site monitor
class sunetdrive::sitemonitornaemon() {

  $sites = hiera_array('sites')
  $fullnodes = hiera_array('fullnodes')
  $tls_servers = flatten($sites,hiera_array('tls_servers'))
  $tls_servers_with_port = hiera_array('tls_servers_with_port')
  $nextcloud_version_prod = split(hiera('nextcloud_version_prod'),'[-]')[0]
  $nextcloud_version_test = split(hiera('nextcloud_version_test'),'[-]')[0]
  $monitorhost = $::fqdn
  $environment = sunetdrive::get_environment()
  $influx_passwd = safe_hiera('influx_passwd')
  $slack_url = safe_hiera('slack_url')

  file { '/usr/local/bin/slack_nagios.sh':
    ensure  => present,
    content => template('sunetdrive/monitor/notify_slack.erb.sh'),
    mode    => '0755',
  }
  file { '/etc/nagios-plugins/config/ping.cfg':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/monitor/ping.cfg.erb'),
    mode    => '0644',
  }
  #definition for check_nrpe_1arg
  file { '/etc/nagios-plugins/config/check_nrpe.cfg':
    ensure  => file,
    mode    => '0644',
    content => template('sunetdrive/monitor/check_nrpe.cfg.erb'),
  }
  file { '/etc/naemon/conf.d/sunetdrive_sites.cfg':
    ensure  => present,
    content => template('sunetdrive/monitor/sunetdrive_sites.cfg.erb'),
    mode    => '0644',
  }
  file { '/etc/naemon/conf.d/sunetdrive_ssl_checks.cfg':
    ensure  => present,
    content => template('sunetdrive/monitor/sunetdrive_ssl_checks.cfg.erb'),
    mode    => '0644',
  }
  file { '/etc/naemon/conf.d/sunetdrive_thruk_templates.conf':
    ensure  => present,
    owner   => 'naemon',
    group   => 'naemon',
    content => template('sunetdrive/monitor/sunetdrive_thruk_templates.conf.erb'),
    mode    => '0644',
  }
  nagioscfg::service {'check_galera_cluster':
    hostgroup_name => ['galera_monitor'],
    check_command  => 'check_nrpe_1arg!check_galera_cluster',
    description    => 'Galera Cluster Health',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_async_replication':
    hostgroup_name => ['sunetdrive::mariadb_backup'],
    check_command  => 'check_nrpe_1arg!check_async_replication',
    description    => 'MySQL Replication Health',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_backups':
    action_url     => '/grafana/dashboard/script/histou.js?host=$HOSTNAME$&service=$SERVICEDISPLAYNAME$&theme=light&annotations=true',
    hostgroup_name => ['sunetdrive::script'],
    check_command  => 'check_nrpe_1arg_to600!check_backups',
    check_interval => '720',
    retry_interval => '180',
    description    => 'Backup Status',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_proxysql_server':
    hostgroup_name => ['sunetdrive::proxysql'],
    check_command  => 'check_nrpe_1arg!check_proxysql_server',
    description    => 'Number of ProxySQL servers available',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_mysql_server_status':
    action_url     => '/grafana/dashboard/script/histou.js?host=$HOSTNAME$&service=$SERVICEDISPLAYNAME$&theme=light&annotations=true',
    hostgroup_name => ['sunetdrive::proxysql'],
    check_command  => 'check_nrpe_1arg!check_mysql_server_status',
    description    => 'Status of mysql servers',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_exabgp_announce':
    action_url     => '/grafana/dashboard/script/histou.js?host=$HOSTNAME$&service=$SERVICEDISPLAYNAME$&theme=light&annotations=true',
    hostgroup_name => ['sunetdrive::lb'],
    check_command  => 'check_nrpe_1arg!check_exabgp_announce',
    description    => 'Status of exabgp routes',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_sarimner':
    action_url     => '/grafana/dashboard/script/histou.js?host=$HOSTNAME$&service=$SERVICEDISPLAYNAME$&theme=light&annotations=true',
    hostgroup_name => ['sunetdrive::lb'],
    check_command  => 'check_nrpe_1arg_to300!check_sarimner',
    description    => 'Status of sarimner interface',
    contact_groups => ['alerts']
  }

}

