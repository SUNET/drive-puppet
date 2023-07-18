# Mariadb cluster class for SUNET Drive
define sunetdrive::db_type(
  $tag_mariadb=undef,
  $bootstrap=undef,
  $location=undef,
  $override_config = undef,
  $override_compose = undef,
)
{

  # Config from group.yaml
  $environment = sunetdrive::get_environment()
  $mariadb_version = hiera("mariadb_version_${environment}")
  $is_multinode = (($override_config != undef) and ($override_compose != undef))
  if $is_multinode {
    $config = $override_config
    $mysql_root_password = $config['mysql_root_password']
    $mysql_user_password = $config['mysql_user_password']
    $backup_password = $config['backup_password']
    $mariadb_dir = $config['mariadb_dir']
    $mycnf_path = $config['mycnf_path']
    $server_id = '1000'
  } else {
    $config = hiera_hash($environment)
    $mysql_root_password = safe_hiera('mysql_root_password')
    $backup_password = safe_hiera('backup_password')
    $proxysql_password = safe_hiera('proxysql_password')
    $mysql_user_password = safe_hiera('mysql_user_password')
    $mariadb_dir = '/etc/mariadb'
    $mycnf_path = 'sunetdrive/mariadb/my.cnf.erb'
    $server_id = 1000 + Integer($facts['networking']['hostname'][-1])
    ensure_resource('file',$mariadb_dir, { ensure => directory, recurse => true } )
    $dirs = ['datadir', 'init', 'conf', 'backups', 'scripts' ]
    $dirs.each |$dir| {
      ensure_resource('file',"${mariadb_dir}/${dir}", { ensure => directory, recurse => true } )
    }
  }

  $nextcloud_ip = $config['app']

  unless $is_multinode {
    $db_ip = $config['db']
    $db_ipv6 = $config['db_v6']
    $backup_ip = $config['backup']
    $backup_ipv6 = $config['backup_v6']
    $ports = [3306, 4444, 4567, 4568]

    sunet::misc::ufw_allow { 'mariadb_ports':
      from => $db_ip + $nextcloud_ip + $backup_ip + $backup_ipv6 + $db_ipv6,
      port => $ports,
    }
    sunet::system_user {'mysql': username => 'mysql', group => 'mysql' }
  }


  if $location =~ /^lookup/ {
    $sql_files = ['02-backup_user.sql', '03-proxysql.sql', '05-lookup.sql']
  } else {
    $sql_files = ['02-backup_user.sql', '03-proxysql.sql', '04-nextcloud.sql']
  }
  $sql_files.each |$sql_file|{
    file { "${mariadb_dir}/init/${sql_file}":
      ensure  => present,
      content => template("sunetdrive/mariadb/${sql_file}.erb"),
      mode    => '0744',
    }
  }
  file { "${mariadb_dir}/conf/credentials.cnf":
    ensure  => present,
    content => template('sunetdrive/mariadb/credentials.cnf.erb'),
    mode    => '0744',
  }
  file { "${mariadb_dir}/conf/my.cnf":
    ensure  => present,
    content => template($mycnf_path),
    mode    => '0744',
  }
  file { '/usr/local/bin/purge-binlogs':
    ensure  => present,
    content => template('sunetdrive/mariadb/purge-binlogs.erb.sh'),
    mode    => '0744',
  }
  file { "${mariadb_dir}/scripts/run_manual_backup_dump.sh":
    ensure  => present,
    content => template('sunetdrive/mariadb/run_manual_backup_dump.erb.sh'),
    mode    => '0744',
  }
  file { "${mariadb_dir}/scripts/rename-docker.sh":
    ensure  => present,
    content => template('sunetdrive/mariadb/rename-docker.sh'),
    mode    => '0744',
  }
  sunet::scriptherder::cronjob { 'purge_binlogs':
    cmd           => '/usr/local/bin/purge-binlogs',
    hour          => '6',
    minute        => '0',
    ok_criteria   => ['exit_status=0','max_age=2d'],
    warn_criteria => ['exit_status=1','max_age=3d'],
  }
  if $is_multinode {
    $docker_compose = $override_compose
  } else {
    file { '/usr/local/bin/size-test':
      ensure  => present,
      content => template('sunetdrive/mariadb/size-test.erb'),
      mode    => '0744',
    }
    file { '/usr/local/bin/status-test':
      ensure  => present,
      content => template('sunetdrive/mariadb/status-test.erb'),
      mode    => '0744',
    }
    file { '/etc/sudoers.d/99-size-test':
      ensure  => file,
      content => "script ALL=(root) NOPASSWD: /usr/local/bin/size-test\n",
      mode    => '0440',
      owner   => 'root',
      group   => 'root',
    }
    file { '/etc/sudoers.d/99-status-test':
      ensure  => file,
      content => "script ALL=(root) NOPASSWD: /usr/local/bin/status-test\n",
      mode    => '0440',
      owner   => 'root',
      group   => 'root',
    }
    $docker_compose = sunet::docker_compose { 'drive_mariadb_docker_compose':
      content          => template('sunetdrive/mariadb/docker-compose_mariadb.yml.erb'),
      service_name     => 'mariadb',
      compose_dir      => '/opt/',
      compose_filename => 'docker-compose.yml',
      description      => 'Mariadb server',
    }
  }
}
