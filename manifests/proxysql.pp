#Class for SUNET-Drive-Proxysql
class sunetdrive::proxysql (
  $bootstrap = undef,
  $location  = undef,
  $proxysql_container_name = 'proxysql_proxysql_1',
) {

  # Config from group.yaml
  $environment = sunetdrive::get_environment()
  $config = hiera_hash($environment)
  $db_ip = $config['db']
  $nextcloud_ip = $config['app']
  $proxysql_ok_num = length($nextcloud_ip)
  $proxysql_warn_num = $proxysql_ok_num - 1

  # Global config from common.yaml
  $proxysql_version = hiera('proxysql_version')
  $tug_office = hiera_array('tug_office')

  # Config from local.yaml and local.eyaml
  $admin_password = safe_hiera('admin_password')
  $cluster_admin_password = safe_hiera('cluster_admin_password')
  $monitor_password = safe_hiera('proxysql_password')
  $mysql_user_password = safe_hiera('mysql_user_password')
  $mysql_user = safe_hiera('mysql_user')

  $transaction_persistent = 1

  file { '/usr/local/bin/proxysql':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/proxysql/proxysql.erb.sh'),
    mode    => '0755',
  }
  file { '/opt/proxysql/insert_server_in_proxysql.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/proxysql/insert_server_in_proxysql.erb.sh'),
    mode    => '0755',
  }
  file {'/usr/lib/nagios/plugins/check_proxysql_server':
      ensure  => 'file',
      mode    => '0755',
      group   => 'nagios',
      require => Package['nagios-nrpe-server'],
      content => template('sunetdrive/proxysql/check_proxysql_server.erb'),
  }
  file {'/usr/lib/nagios/plugins/check_mysql_server_status':
      ensure  => 'file',
      mode    => '0755',
      group   => 'nagios',
      require => Package['nagios-nrpe-server'],
      content => template('sunetdrive/proxysql/check_mysql_server_status.erb'),
  }
  file { '/opt/proxysql/proxysql.cnf':
    ensure  => present,
    content => template('sunetdrive/proxysql/proxysql.cnf.erb'),
    mode    => '0644',
  }

  file { '/opt/proxysql/my.cnf':
    ensure  => present,
    content => template('sunetdrive/proxysql/my.cnf.erb'),
    mode    => '0644',
  }
  sunet::misc::ufw_allow { 'stats_ports':
    from => $tug_office,
    port => 6080,
  }
  sunet::nftables::docker_expose { 'stats_ports':
    from => $tug_office,
    port => 6080,
  }
  sunet::nftables::docker_expose { 'proxysql':
    from => ['any'],
    port => 6032,
  }

  sunet::docker_compose { 'drive_proxysql_docker_compose':
    content          => template('sunetdrive/proxysql/docker-compose_proxysql.yml.erb'),
    service_name     => 'proxysql',
    compose_dir      => '/opt/',
    compose_filename => 'docker-compose.yml',
    description      => 'Proxysql',
  }
  if $::fqdn[0,5] == 'node1' {
    sunet::scriptherder::cronjob { 'insert_server_in_proxysql':
      cmd           => '/opt/proxysql/insert_server_in_proxysql.sh',
      hour          => '*',
      minute        => '*/5',
      ok_criteria   => ['exit_status=0','max_age=1h'],
      warn_criteria => ['exit_status=1','max_age=3h'],
    }
  } else {
    sunet::scriptherder::cronjob { 'insert_server_in_proxysql':
      ensure        => 'absent',
      cmd           => '/opt/proxysql/insert_server_in_proxysql.sh',
      purge_results => true,
    }

  }


}

