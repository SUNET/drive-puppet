# This is a asyncronous replica of the Maria DB Cluster for SUNET Drive
class sunetdrive::mariadb_backup($tag_mariadb=undef,  $location=undef) {
  $dirs = [ 'datadir', 'init', 'conf', 'backups' ]
  $dirs.each | $dir | {
    ensure_resource('file',"/opt/mariadb_backup/${dir}", { ensure => directory, recurse => true } )
  }
  # Config from group.yaml
  $environment = sunetdrive::get_environment()
  $config = hiera_hash($environment)
  $first_db = $config['first_db']

  # Secrets from local.eyaml
  $mysql_root_password = safe_hiera('mysql_root_password')
  $backup_password = safe_hiera('backup_password')
  $mysql_user_password = safe_hiera('mysql_user_password')
  $statistics_secret = safe_hiera('statistics_secret')

  sunet::system_user {'mysql': username => 'mysql', group => 'mysql' }

  $sql_files = ['02-backup_user.sql']
  $sql_files.each |$sql_file|{
    file { "/opt/mariadb_backup/init/${sql_file}":
      ensure  => present,
      content => template("sunetdrive/mariadb_backup/${sql_file}.erb"),
      mode    => '0744',
    }
  }
  $conf_files = ['credentials.cnf', 'my.cnf']
  $conf_files.each |$conf_file|{
    file { "/opt/mariadb_backup/conf/${conf_file}":
      ensure  => present,
      content => template("sunetdrive/mariadb_backup/${conf_file}.erb"),
      mode    => '0744',
    }
  }
  file { '/opt/mariadb_backup/start_replica_from_init.sh':
    ensure  => present,
    content => template('sunetdrive/mariadb_backup/start_replica_from_init.erb.sh'),
    mode    => '0744',
  }
  file { '/opt/mariadb_backup/do_backup.sh':
    ensure  => present,
    content => template('sunetdrive/mariadb_backup/do_backup.erb.sh'),
    mode    => '0744',
  }
  file { '/opt/mariadb_backup/check_replication.sh':
    ensure  => absent,
  }
  file { '/etc/sudoers.d/99-check_replication':
    ensure  => absent,
  }
  file { '/usr/local/bin/check_replication':
    ensure  => present,
    content => template('sunetdrive/mariadb_backup/check_replication.erb'),
    mode    => '0744',
  }
  file { '/usr/local/bin/status-test':
    ensure  => present,
    content => template('sunetdrive/mariadb_backup/status-test.erb'),
    mode    => '0744',
  }
  file { '/etc/sudoers.d/99-status-test':
    ensure  => file,
    content => "script ALL=(root) NOPASSWD: /usr/local/bin/status-test\n",
    mode    => '0440',
    owner   => 'root',
    group   => 'root',
  }
  sunet::docker_compose { 'mariadb_backup':
    content          => template('sunetdrive/mariadb_backup/docker-compose_mariadb_backup.yml.erb'),
    service_name     => 'mariadb_backup',
    compose_dir      => '/opt/',
    compose_filename => 'docker-compose.yml',
    description      => 'Mariadb replica',
  }

  # Rclone stuff
  $rclone_url = 'https://downloads.rclone.org/rclone-current-linux-amd64.deb'
  $local_path = '/tmp/rclone-current-linux-amd64.deb'
  exec { 'rclone_deb':
    command => "/usr/bin/wget -q ${rclone_url} -O ${local_path}",
    creates => $local_path,
  }
  package { 'rclone':
    ensure   => installed,
    provider => dpkg,
    source   => $local_path,
    require  => Exec['rclone_deb'],
  }

  file { '/root/.rclone.conf':
    ensure  => file,
    content => template('sunetdrive/mariadb_backup/rclone.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  file { '/opt/mariadb_backup/listusers.sh':
    ensure  => file,
    content => template('sunetdrive/mariadb_backup/listusers.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/opt/mariadb_backup/find_disabled_sharing.sh':
    ensure  => file,
    content => template('sunetdrive/mariadb_backup/find_disabled_sharing.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  sunet::scriptherder::cronjob { 'listusers':
    cmd           => '/opt/mariadb_backup/listusers.sh',
    minute        => '*/5',
    ok_criteria   => ['exit_status=0','max_age=30m'],
    warn_criteria => ['exit_status=1', 'max_age=60m'],
  }
  sunet::scriptherder::cronjob { 'disabledsharing':
    cmd           => '/opt/mariadb_backup/find_disabled_sharing.sh',
    minute        => '5',
    hour          => '3',
    ok_criteria   => ['exit_status=0','max_age=2d'],
    warn_criteria => ['exit_status=1','max_age=3d'],
  }

}
